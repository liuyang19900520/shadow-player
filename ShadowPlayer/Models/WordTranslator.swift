import SwiftUI
#if canImport(Translation)
import Translation
#endif

/// One word queued for translation, tracked by its word-list entry id.
struct TranslationItem: Equatable, Hashable {
    let id: String
    let text: String
}

/// A batch of words to translate. The fresh `id` makes an otherwise identical
/// batch compare unequal, so re-running is just a matter of building a new job.
struct TranslationJob: Equatable {
    let id = UUID()
    var items: [TranslationItem]
    /// nil lets the translator detect the language.
    var sourceIdentifier: String?
    var targetIdentifier: String
}

/// Whether this device can translate on-device. Apple's Translation framework
/// arrived in iOS 18, so the feature is hidden entirely below that.
var isTranslationAvailable: Bool {
    if #available(iOS 18.0, *) { return true }
    return false
}

extension View {
    /// Runs `job` through Apple's on-device translator and hands back a map of
    /// entry id -> translated text. Does nothing below iOS 18.
    func translationBackfill(
        job: TranslationJob?,
        onFinish: @escaping ([String: String]) -> Void
    ) -> some View {
        background {
            if #available(iOS 18.0, *) {
                TranslationRunner(job: job, onFinish: onFinish)
            }
        }
    }
}

/// Invisible view that owns the translation session. `translationTask` needs to
/// live in the view hierarchy, and the session is only valid inside its closure,
/// so the work happens here and the results are handed back through `onFinish`.
@available(iOS 18.0, *)
private struct TranslationRunner: View {
    let job: TranslationJob?
    let onFinish: ([String: String]) -> Void

    @State private var configuration: TranslationSession.Configuration?

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .translationTask(configuration) { session in
                await run(session)
            }
            .onAppear { sync(job) }
            .onChange(of: job) { _, new in sync(new) }
    }

    /// Point the session at the right language pair; this is what kicks off
    /// `translationTask`. The system prompts to download the languages if needed.
    private func sync(_ job: TranslationJob?) {
        guard let job, !job.items.isEmpty else {
            configuration = nil
            return
        }
        configuration = TranslationSession.Configuration(
            source: job.sourceIdentifier.map { Locale.Language(identifier: $0) },
            target: Locale.Language(identifier: job.targetIdentifier)
        )
    }

    private func run(_ session: TranslationSession) async {
        guard let job, !job.items.isEmpty else { return }

        let requests = job.items.map {
            TranslationSession.Request(sourceText: $0.text, clientIdentifier: $0.id)
        }

        var results: [String: String] = [:]
        do {
            for response in try await session.translations(from: requests) {
                guard let id = response.clientIdentifier else { continue }
                results[id] = response.targetText
            }
        } catch {
            // Languages unavailable, download declined, or the session was torn
            // down. Leave the rows untranslated rather than surfacing an error —
            // the user can flip the switch again to retry.
            results = [:]
        }

        onFinish(results)
    }
}
