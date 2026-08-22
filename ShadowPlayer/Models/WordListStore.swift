import Foundation

/// Per-video word list, persisted to UserDefaults keyed by the video identifier.
final class WordListStore: ObservableObject {
    @Published var entries: [WordEntry] { didSet { save() } }

    private let key: String

    init(videoID: String) {
        key = "words_" + videoID
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([WordEntry].self, from: data),
           !decoded.isEmpty {
            entries = decoded
        } else {
            // Start with one blank row so the user can type right away.
            entries = [WordEntry()]
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
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
