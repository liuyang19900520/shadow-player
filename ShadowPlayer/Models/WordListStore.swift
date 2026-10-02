import Foundation

/// Per-video word list, persisted to UserDefaults keyed by the video identifier.
final class WordListStore: ObservableObject {
    @Published var entries: [WordEntry] { didSet { save() } }

    private let videoID: String

    init(videoID: String) {
        self.videoID = videoID
        // No blank seed row: an empty list shows just "Add word", which focuses
        // the new row as soon as it is tapped.
        entries = WordListStore.load(videoID: videoID)
    }

    // MARK: - Persistence (also used by the merged playlist word list)

    static func key(for videoID: String) -> String { "words_" + videoID }

    /// The persisted rows for a video (empty if none saved yet — no blank seed).
    static func load(videoID: String) -> [WordEntry] {
        guard
            let data = UserDefaults.standard.data(forKey: key(for: videoID)),
            let decoded = try? JSONDecoder().decode([WordEntry].self, from: data)
        else { return [] }
        return decoded
    }

    static func save(_ entries: [WordEntry], videoID: String) {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key(for: videoID))
        }
    }

    /// Append a blank row for the user to fill in, and report its id so the
    /// caller can put the keyboard straight into it.
    @discardableResult
    func addEmpty() -> UUID {
        let entry = WordEntry()
        entries.append(entry)
        return entry.id
    }

    /// Add finished lines to the end — used when a looped line is captured.
    /// A blank row left open for typing stays last, where the user expects it.
    func append(lines: [String]) {
        let added = lines.map { WordEntry(text: $0) }
        guard !added.isEmpty else { return }
        if let blank = entries.lastIndex(where: { $0.trimmedText.isEmpty }), blank == entries.count - 1 {
            entries.insert(contentsOf: added, at: blank)
        } else {
            entries.append(contentsOf: added)
        }
    }

    // MARK: - Translation

    /// Rows with no meaning yet, or one written for what the word used to be.
    var untranslated: [TranslationItem] {
        entries
            .filter(\.needsTranslation)
            .map { TranslationItem(id: $0.id.uuidString, text: $0.trimmedText) }
    }

    /// Fill in meanings from a finished translation batch. Each result is
    /// matched to the text that was sent, so a row edited while the batch was
    /// running keeps waiting for its new word instead of taking the old
    /// word's meaning. Rows given a meaning by hand meanwhile are left alone.
    func applyTranslations(_ results: [String: String], for items: [TranslationItem]) {
        guard !results.isEmpty else { return }
        let sent = Dictionary(items.map { ($0.id, $0.text) }, uniquingKeysWith: { first, _ in first })

        var updated = entries
        var changed = false
        for i in updated.indices {
            let key = updated[i].id.uuidString
            guard let meaning = results[key], let source = sent[key] else { continue }
            changed = updated[i].applyTranslation(meaning, of: source) || changed
        }
        if changed { entries = updated } // one save, not one per row
    }

    func remove(atOffsets offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
    }

    /// Delete a single row by identity.
    func remove(_ entry: WordEntry) {
        entries.removeAll { $0.id == entry.id }
    }

    private func save() {
        WordListStore.save(entries, videoID: videoID)
    }
}
