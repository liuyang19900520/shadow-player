import Foundation

/// One row of the combined playlist word list, tagged with its source video.
struct MergedWord: Identifiable, Hashable {
    let id: UUID
    let videoID: String
    var text: String
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
                all.append(MergedWord(id: entry.id, videoID: vid, text: entry.text))
            }
        }
        items = all
    }

    func setText(_ text: String, for id: UUID) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        items[i].text = text
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
    func addEmpty() {
        guard let first = order.first else { return }
        items.append(MergedWord(id: UUID(), videoID: first, text: ""))
    }

    /// Rewrite one video's stored list from the current merged items.
    private func persist(videoID: String) {
        let entries = items
            .filter { $0.videoID == videoID }
            .map { WordEntry(id: $0.id, text: $0.text) }
        WordListStore.save(entries, videoID: videoID)
    }
}
