import AVFoundation
import UIKit
import PhraseKit

/// Watches an A-B loop and, once it has repeated a few times, offers to add
/// what was said to the video's word list.
///
/// Recognition starts as soon as the loop is set, so by the time the offer
/// appears the line is usually ready and a shake adds it at once.
@MainActor
final class LoopCaptureModel: ObservableObject {
    enum Prompt: Equatable {
        case none
        /// A line is ready: shake or tap Add.
        case ready(preview: String)
        /// The playlist's audio language hasn't been chosen yet.
        case needsLanguage
        case added(count: Int)
    }

    @Published private(set) var prompt: Prompt = .none

    /// Completed loops before the offer appears.
    static let loopsBeforeOffer = 3

    private let videoID: String
    private let scope: TranslationScope
    private let source: LoopTextSource?
    private let extractor = PhraseExtractor()

    private var range: ClosedRange<Double>?
    /// The player's copy of the video, so it isn't fetched again.
    private var asset: AVAsset?
    private var loops = 0
    /// Lines heard in the current loop; nil while still listening.
    private var lines: [String]?
    /// The language the loop is being, or was, heard in. Compared against
    /// settings rather than the finished result: settings change every few
    /// seconds (playback progress is saved there), and comparing with a result
    /// still pending would restart recognition before it could ever finish.
    private var listeningLanguage: TranslationLanguage?
    /// The offer is made once per loop, not on every repeat.
    private var offered = false
    private var captured = false
    private var transcription: Task<Void, Never>?
    private var dismissal: Task<Void, Never>?

    init(videoID: String, scope: TranslationScope, source: LoopTextSource? = LoopCaptureAvailability.makeSource()) {
        self.videoID = videoID
        self.scope = scope
        self.source = source
    }

    /// A or B moved, or the loop was cancelled: start over.
    func loopChanged(a: Double?, b: Double?, asset: AVAsset?) {
        transcription?.cancel()
        self.asset = asset
        loops = 0
        lines = nil
        listeningLanguage = nil
        offered = false
        captured = false
        show(.none)

        guard source != nil, let a, let b, b > a else {
            range = nil
            return
        }
        range = a...b
        listen()
    }

    func loopCompleted() {
        guard range != nil, !captured else { return }
        loops += 1
        offerIfReady()
    }

    /// Called whenever settings change. Only a new audio language matters:
    /// the loop is heard again in that language.
    func languageMayHaveChanged() {
        guard range != nil, !captured, scope.audioLanguage != listeningLanguage else { return }
        transcription?.cancel()
        lines = nil
        offered = false
        // Whatever the banner offered belonged to the old language.
        show(.none)
        listen()
    }

    /// Shaking works for as long as the loop is unchanged, even after the
    /// banner has faded.
    var canCapture: Bool {
        !captured && loops >= Self.loopsBeforeOffer && !(lines ?? []).isEmpty
    }

    func capture(into store: WordListStore) {
        guard canCapture, let lines else { return }
        store.append(lines: lines)
        captured = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        show(.added(count: lines.count), for: 2)
    }

    /// Leaving the player: stop listening.
    func stop() {
        transcription?.cancel()
        dismissal?.cancel()
    }

    // MARK: - Private

    private func listen() {
        // Recorded even when unset, so an unset language isn't mistaken for a
        // change on every settings write.
        listeningLanguage = scope.audioLanguage
        guard let source, let range, let language = listeningLanguage else { return }
        let videoID = self.videoID
        let asset = self.asset
        transcription = Task { [weak self] in
            do {
                let words = try await source.words(videoID: videoID, asset: asset, range: range, language: language)
                guard !Task.isCancelled, let self else { return }
                let found = self.extractor.phrases(from: words, in: range, languageCode: language.rawValue)
                captureLog.info("Heard \(words.count) words, kept \(found.count) line(s)")
                self.lines = found
                self.offerIfReady()
            } catch {
                guard !Task.isCancelled else { return }
                captureLog.error("Couldn't hear the loop: \(String(describing: error), privacy: .public)")
            }
        }
    }

    private func offerIfReady() {
        guard !offered, !captured, loops >= Self.loopsBeforeOffer else { return }
        if scope.audioLanguage == nil {
            offered = true
            show(.needsLanguage, for: 8)
            return
        }
        // Still listening, or nothing was said: stay quiet.
        guard let lines, !lines.isEmpty else { return }
        offered = true
        show(.ready(preview: lines.joined(separator: "  ")), for: 8)
    }

    private func show(_ next: Prompt, for seconds: Double? = nil) {
        dismissal?.cancel()
        prompt = next
        guard let seconds else { return }
        dismissal = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.prompt = .none
        }
    }
}
