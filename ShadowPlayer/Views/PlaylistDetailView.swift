import SwiftUI

/// A playlist's videos: tap to play, swipe to remove, Edit to reorder.
struct PlaylistDetailView: View {
    let playlistID: UUID
    @ObservedObject var store: PlaylistStore

    @State private var showMergedWords = false

    private var playlist: Playlist? {
        store.playlists.first { $0.id == playlistID }
    }

    private var videoIDs: [String] {
        playlist?.videos.map(\.id) ?? []
    }

    var body: some View {
        List {
            Section {
                Button {
                    showMergedWords = true
                } label: {
                    Label("Combined Word List", systemImage: "square.stack.3d.up.fill")
                }
            }

            Section("Videos") {
                if let playlist, !playlist.videos.isEmpty {
                    ForEach(playlist.videos) { video in
                        NavigationLink(value: video) {
                            VideoRow(video: video)
                        }
                    }
                    .onDelete { store.removeVideos(atOffsets: $0, from: playlistID) }
                    .onMove { store.moveVideos(fromOffsets: $0, toOffset: $1, in: playlistID) }
                } else {
                    Text("No videos yet. Add videos from the Recent list.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(playlist?.name ?? "Playlist")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let playlist, !playlist.videos.isEmpty {
                ToolbarItem(placement: .topBarTrailing) { EditButton() }
            }
        }
        .sheet(isPresented: $showMergedWords) {
            MergedWordListView(
                videoIDs: videoIDs,
                // Languages belong to the playlist, so every video in it shares one pair.
                scope: playlist.map(TranslationScope.playlist) ?? .shared
            )
        }
    }
}
