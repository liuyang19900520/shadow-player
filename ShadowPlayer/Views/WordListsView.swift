import SwiftUI

/// Every word list, grouped by the playlist its video belongs to.
///
/// The grouping is derived from the playlists and the stored lists rather than
/// copied into a structure of its own, so renaming a playlist, adding a video
/// or removing one is reflected here with no syncing to go wrong. A video
/// deleted from the photo library stays in its playlist, keeping its notes
/// where they were filed.
struct WordListsView: View {
    @ObservedObject var playlists: PlaylistStore
    @ObservedObject private var titles = VideoTitleStore.shared

    @State private var groups: [ListGroup] = []

    private struct Entry: Identifiable {
        let id: String   // video identifier
        let count: Int
    }

    private struct ListGroup: Identifiable {
        let id: String
        let title: String
        let entries: [Entry]
    }

    var body: some View {
        List {
            if groups.isEmpty {
                Text("No words yet. Add them while watching a video.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(groups) { group in
                Section(group.title) {
                    ForEach(sortedByName(group.entries)) { entry in
                        NavigationLink {
                            VideoWordListScreen(videoID: entry.id)
                        } label: {
                            row(entry)
                        }
                    }
                }
            }
        }
        .navigationTitle("Word Lists")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { rebuild() }
    }

    private func row(_ entry: Entry) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(titles.displayName(for: entry.id) ?? "Untitled")
                .font(.body)
                .lineLimit(2)

            HStack(spacing: 4) {
                Text("\(entry.count) " + (entry.count == 1 ? "word" : "words"))
                if titles.isMissing(entry.id) {
                    Text("·")
                    Text("Not on this iPhone")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .task(id: entry.id) { await titles.refresh(entry.id) }
    }

    /// Episodes read in the order their names imply — "02" before "10", which
    /// a plain string sort gets backwards. Sorted here rather than in `rebuild`
    /// so the order settles as names finish loading.
    private func sortedByName(_ entries: [Entry]) -> [Entry] {
        entries.sorted { a, b in
            let left = titles.displayName(for: a.id) ?? ""
            let right = titles.displayName(for: b.id) ?? ""
            return left.localizedStandardCompare(right) == .orderedAscending
        }
    }

    /// Rebuild the grouping from the current playlists and stored lists.
    private func rebuild() {
        let counts = Dictionary(
            uniqueKeysWithValues: WordListIndex.listsWithWords().map { ($0.videoID, $0.count) }
        )

        var built: [ListGroup] = []

        for playlist in playlists.playlists {
            let entries = playlist.videos
                .compactMap { video in counts[video.id].map { Entry(id: video.id, count: $0) } }
            if !entries.isEmpty {
                built.append(ListGroup(id: playlist.id.uuidString, title: playlist.name, entries: entries))
            }
        }

        groups = built
    }
}

/// One video's word list, opened without its player.
struct VideoWordListScreen: View {
    let videoID: String
    @StateObject private var store: WordListStore

    init(videoID: String) {
        self.videoID = videoID
        _store = StateObject(wrappedValue: WordListStore(videoID: videoID))
    }

    var body: some View {
        WordListEditor(store: store, scope: TranslationScope.forVideo(videoID))
            .navigationTitle(VideoTitleStore.shared.displayName(for: videoID) ?? "Words")
            .navigationBarTitleDisplayMode(.inline)
    }
}
