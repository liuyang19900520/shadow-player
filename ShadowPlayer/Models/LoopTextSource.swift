import AVFoundation
import Photos
import Speech
import os
import PhraseKit

let captureLog = Logger(subsystem: "com.liuyang19900520.shadowplayer", category: "LoopCapture")

/// Where the words of a looped section come from. Speech recognition is the
/// only source for now; reading burned-in subtitles can be added behind the
/// same shape later, with a setting to choose between the two.
protocol LoopTextSource: Sendable {
    /// Recognised words covering `range` and a little either side, timed in
    /// seconds from the start of the video.
    /// - Parameter asset: The player's copy of the video, reused so it isn't
    ///   fetched a second time. Nil falls back to asking Photos for it.
    func words(
        videoID: String,
        asset: AVAsset?,
        range: ClosedRange<Double>,
        language: TranslationLanguage
    ) async throws -> [TimedToken]
}

enum LoopTextSourceError: Error {
    case videoUnavailable
    case languageUnsupported
    case exportFailed
}

enum LoopCaptureAvailability {
    /// The source this device can use, or nil when capture isn't possible.
    ///
    /// Only Apple's on-device speech model qualifies. The older dictation
    /// recogniser runs on more devices, but it can't be shown to keep audio on
    /// the device, and the app promises that nothing leaves it — so devices
    /// without the on-device model simply don't get the feature.
    static func makeSource() -> LoopTextSource? {
        if #available(iOS 26.0, *), SpeechTranscriber.isAvailable {
            return SpeechLoopTextSource()
        }
        return nil
    }
}

@available(iOS 26.0, *)
struct SpeechLoopTextSource: LoopTextSource {
    /// Audio kept either side of the loop, so a word straddling A or B is
    /// heard whole and can be judged by how much of it falls inside.
    private let margin: Double = 1.0

    func words(
        videoID: String,
        asset: AVAsset?,
        range: ClosedRange<Double>,
        language: TranslationLanguage
    ) async throws -> [TimedToken] {
        guard let locale = await SpeechTranscriber.supportedLocale(equivalentTo: language.speechLocale) else {
            throw LoopTextSourceError.languageUnsupported
        }
        try await Self.installModelIfNeeded(for: locale)

        let video: AVAsset
        if let asset {
            video = asset
        } else {
            video = try await Self.loadAsset(videoID: videoID)
        }
        let start = max(0, range.lowerBound - margin)
        let clip = try await Self.exportAudio(of: video, from: start, to: range.upperBound + margin)
        defer { try? FileManager.default.removeItem(at: clip) }
        try Task.checkCancellation()

        captureLog.info("Transcribing with SpeechTranscriber, locale \(locale.identifier(.bcp47), privacy: .public)")
        do {
            return try await Self.transcribe(clip, locale: locale, offset: start)
        } catch let error where !(error is CancellationError) && !Task.isCancelled
            && SFSpeechRecognizer.authorizationStatus() == .notDetermined {
            // It isn't documented whether analysing a file needs the speech
            // permission. Ask only when the analysis itself fails — never for a
            // cancelled loop or a failed download or export — so the prompt
            // appears only when it is genuinely needed.
            captureLog.info("Analysis failed (\(error.localizedDescription, privacy: .public)); asking for speech permission")
            guard await Self.requestAuthorization() == .authorized, !Task.isCancelled else { throw error }
            return try await Self.transcribe(clip, locale: locale, offset: start)
        }
    }

    // MARK: - Recognition

    private static func makeTranscriber(_ locale: Locale) -> SpeechTranscriber {
        SpeechTranscriber(locale: locale, transcriptionOptions: [], reportingOptions: [],
                          attributeOptions: [.audioTimeRange])
    }

    private static func transcribe(_ clip: URL, locale: Locale, offset: Double) async throws -> [TimedToken] {
        let transcriber = makeTranscriber(locale)
        let analyzer = SpeechAnalyzer(modules: [transcriber])
        let file = try AVAudioFile(forReading: clip)

        // Results arrive on their own stream while the file is analysed.
        let collecting = Task { try await collect(transcriber, offset: offset) }
        do {
            if let end = try await analyzer.analyzeSequence(from: file) {
                try await analyzer.finalizeAndFinish(through: end)
            } else {
                await analyzer.cancelAndFinishNow()
            }
        } catch {
            await analyzer.cancelAndFinishNow()
            collecting.cancel()
            throw error
        }
        return try await withTaskCancellationHandler {
            try await collecting.value
        } onCancel: {
            collecting.cancel()
        }
    }

    private static func collect(_ transcriber: SpeechTranscriber, offset: Double) async throws -> [TimedToken] {
        var words: [TimedToken] = []
        for try await result in transcriber.results where result.isFinal {
            for run in result.text.runs {
                let text = String(result.text[run.range].characters)
                if let time = run.audioTimeRange {
                    words.append(TimedToken(text, offset + time.start.seconds, offset + time.end.seconds))
                } else if let last = words.popLast() {
                    // Untimed text is punctuation; keep it on the word it follows.
                    words.append(TimedToken(last.text + text, last.start, last.end))
                }
            }
        }
        return words
    }

    private static func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
    }

    // MARK: - Speech model

    /// The model is a system download, like a translation language pack: the
    /// app sends nothing, it only asks iOS to fetch Apple's model once.
    private static func installModelIfNeeded(for locale: Locale) async throws {
        let transcriber = makeTranscriber(locale)
        switch await AssetInventory.status(forModules: [transcriber]) {
        case .installed:
            return
        case .unsupported:
            throw LoopTextSourceError.languageUnsupported
        default:
            await reserve(locale)
            if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
                captureLog.info("Downloading the speech model for \(locale.identifier(.bcp47), privacy: .public)")
                try await request.downloadAndInstall()
            }
        }
    }

    /// iOS keeps only a few speech languages reserved per app. Make room by
    /// releasing an old one, so moving between an English and a Japanese
    /// playlist never quietly blocks a download.
    private static func reserve(_ locale: Locale) async {
        let wanted = locale.identifier(.bcp47)
        let reserved = await AssetInventory.reservedLocales
        if !reserved.contains(where: { $0.identifier(.bcp47) == wanted }),
           reserved.count >= AssetInventory.maximumReservedLocales,
           let oldest = reserved.first {
            await AssetInventory.release(reservedLocale: oldest)
        }
        do {
            try await AssetInventory.reserve(locale: locale)
        } catch {
            captureLog.error("Couldn't reserve \(wanted, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Audio

    /// Only used when the player hasn't loaded the video yet.
    private static func loadAsset(videoID: String) async throws -> AVAsset {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [videoID], options: nil).firstObject else {
            throw LoopTextSourceError.videoUnavailable
        }
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true // an iCloud video is fetched by Photos, as for playback
        options.deliveryMode = .automatic

        let request = RequestBox()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                request.id = PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                    if let avAsset {
                        continuation.resume(returning: avAsset)
                    } else {
                        continuation.resume(throwing: LoopTextSourceError.videoUnavailable)
                    }
                }
            }
        } onCancel: {
            // Stop an iCloud download for a loop that has already changed.
            if let id = request.id { PHImageManager.default().cancelImageRequest(id) }
        }
    }

    /// Just the looped stretch as an audio file, so the recogniser never
    /// listens to more of the video than it has to.
    private static func exportAudio(of asset: AVAsset, from start: Double, to end: Double) async throws -> URL {
        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw LoopTextSourceError.exportFailed
        }
        let duration = try await asset.load(.duration).seconds
        let finish = duration.isFinite && duration > 0 ? min(end, duration) : end
        session.timeRange = CMTimeRange(
            start: CMTime(seconds: start, preferredTimescale: 600),
            end: CMTime(seconds: finish, preferredTimescale: 600)
        )
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        do {
            try await session.export(to: url, as: .m4a)
        } catch {
            try? FileManager.default.removeItem(at: url) // don't leave a partial file behind
            throw error
        }
        return url
    }
}

/// Holds a Photos request id so the cancellation handler can reach it.
private final class RequestBox: @unchecked Sendable {
    var id: PHImageRequestID?
}
