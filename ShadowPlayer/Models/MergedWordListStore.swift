import Foundation

/// One row of the combined playlist word list, tagged with its source video.
struct MergedWord: Identifiable, Hashable {
    let id: UUID
    let videoID: String
    var text: String
    var translation: String?

    var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var needsTranslation: Bool {
        !trimmedText.isEmpty
            && (translation ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

/// Aggregates the word lists of every video in a playlist into one editable list.
/// Edits/deletes are written back to each source video's stored word list, so the
/// per-video lists stay the single source of truth.
final class MergedWordListStore: ObservableObject {
    @Published var items: [MergedWord] = []

    private let order: [String]

    init(videoIDs: [String]) {
        order = videoIDs
        var all: [MergedWord] = []
        for vid in videoIDs {
            for entry in WordListStore.load(videoID: vid) where !entry.text.isEmpty {
                all.append(
                    MergedWord(
                        id: entry.id,
                        videoID: vid,
                        text: entry.text,
                        translation: entry.translation
                    )
                )
            }
        }
        items = all
    }

    func setText(_ text: String, for id: UUID) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        items[i].text = text
        persist(videoID: items[i].videoID)
    }

    func setTranslation(_ translation: String, for id: UUID) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        items[i].translation = translation.isEmpty ? nil : translation
        persist(videoID: items[i].videoID)
    }

    func delete(atOffsets offsets: IndexSet) {
        let affected = Set(offsets.map { items[$0].videoID })
        items.remove(atOffsets: offsets)
        affected.forEach(persist)
    }

    func delete(_ id: UUID) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        let videoID = items[i].videoID
        items.remove(at: i)
        persist(videoID: videoID)
    }

    /// New words are added under the playlist's first video.
    @discardableResult
    func addEmpty() -> UUID? {
        guard let first = order.first else { return nil }
        let word = MergedWord(id: UUID(), videoID: first, text: "")
        items.append(word)
        return word.id
    }

    // MARK: - Translation

    /// Rows that have a word but no meaning yet.
    var untranslated: [TranslationItem] {
        items
            .filter(\.needsTranslation)
            .map { TranslationItem(id: $0.id.uuidString, text: $0.trimmedText) }
    }

    /// Fill in meanings from a finished batch, leaving any the user wrote alone.
    func applyTranslations(_ results: [String: String]) {
        guard !results.isEmpty else { return }
        var touched: Set<String> = []
        for i in items.indices where items[i].needsTranslation {
            guard let meaning = results[items[i].id.uuidString],
                  !meaning.isEmpty else { continue }
            items[i].translation = meaning
            touched.insert(items[i].videoID)
        }
        touched.forEach(persist)
    }

    /// Rewrite one video's stored list from the current merged items.
    private func persist(videoID: String) {
        let entries = items
            .filter { $0.videoID == videoID }
            .map { WordEntry(id: $0.id, text: $0.text, translation: $0.translation) }
        WordListStore.save(entries, videoID: videoID)
    }
}
