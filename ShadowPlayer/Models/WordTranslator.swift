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
    /// The language pair the current configuration was built for.
    @State private var activePair: String?

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
            activePair = nil
            return
        }

        let pair = "\(job.sourceIdentifier ?? "auto")>\(job.targetIdentifier)"

        // `translationTask` only re-runs when the configuration actually
        // changes, so assigning an equal one for the same language pair would
        // silently do nothing. Invalidating is how you ask for another run.
        if pair == activePair, configuration != nil {
            configuration?.invalidate()
            return
        }

        activePair = pair
        configuration = TranslationSession.Configuration(
            source: job.sourceIdentifier.map { Locale.Language(identifier: $0) },
            target: Locale.Language(identifier: job.targetIdentifier)
        )
    }

    private func run(_ session: TranslationSession) async {
        guard let job, !job.items.isEmpty else { return }

        // One word at a time, keeping whatever finished. `translationTask` is
        // cancelled whenever the view updates — and the player redraws several
        // times a second — so a single batch call regularly threw away every
        // result. Partial progress now survives, and the words still missing a
        // meaning are picked up by the next run.
        var results: [String: String] = [:]
        for item in job.items {
            do {
                results[item.id] = try await session.translate(item.text).targetText
            } catch {
                // Cancelled, or the language pair is unavailable / declined.
                break
            }
        }

        onFinish(results)
    }
}
