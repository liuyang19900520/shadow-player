import Foundation

/// Per-video word list, persisted to UserDefaults keyed by the video identifier.
final class WordListStore: ObservableObject {
    @Published var entries: [WordEntry] { didSet { save() } }

    private let videoID: String

    init(videoID: String) {
        self.videoID = videoID
        let loaded = WordListStore.load(videoID: videoID)
        // Start with one blank row so the user can type right away.
        entries = loaded.isEmpty ? [WordEntry()] : loaded
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

    /// Append a blank row for the user to fill in.
    func addEmpty() {
        entries.append(WordEntry())
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
