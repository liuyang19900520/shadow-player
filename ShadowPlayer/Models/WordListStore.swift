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

    // MARK: - Translation

    /// Rows that have a word but no meaning yet.
    var untranslated: [TranslationItem] {
        entries
            .filter(\.needsTranslation)
            .map { TranslationItem(id: $0.id.uuidString, text: $0.trimmedText) }
    }

    /// Fill in meanings from a finished translation batch. Rows the user has
    /// since typed a meaning into are left alone.
    func applyTranslations(_ results: [String: String]) {
        guard !results.isEmpty else { return }
        for i in entries.indices where entries[i].needsTranslation {
            guard let meaning = results[entries[i].id.uuidString],
                  !meaning.isEmpty else { continue }
            entries[i].translation = meaning
        }
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
