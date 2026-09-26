import SwiftUI

/// A playlist's videos: tap to play, swipe to remove or rename, Edit to reorder.
struct PlaylistDetailView: View {
    let playlistID: UUID
    @ObservedObject var store: PlaylistStore

    @Environment(\.editMode) private var editMode

    @State private var showMergedWords = false
    @State private var renamingPlaylist: Playlist?
    @State private var renamingVideo: PickedVideo?
    /// Shared by both rename prompts; only one can be open at a time.
    @State private var nameDraft = ""

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
                        .swipeActions(edge: .trailing) {
                            Button {
                                beginRename(video)
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            .tint(.gray)
                        }
                        .contextMenu {
                            Button {
                                beginRename(video)
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
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
        // One trailing control, not two: the menu holds everything that manages
        // the playlist, and becomes Done while reordering — the way Files and
        // Photos do it. A permanent Edit button beside the menu duplicated it.
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isEditing {
                    Button("Done") { setEditing(false) }
                } else {
                    Menu {
                        Button {
                            nameDraft = playlist?.name ?? ""
                            renamingPlaylist = playlist
                        } label: {
                            Label("Rename Playlist", systemImage: "pencil")
                        }

                        if let playlist, playlist.videos.count > 1 {
                            Button {
                                setEditing(true)
                            } label: {
                                Label("Reorder Videos", systemImage: "arrow.up.arrow.down")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .renameAlert(
            "Rename Playlist",
            subject: $renamingPlaylist,
            text: $nameDraft
        ) { playlist in
            store.rename(playlist.id, to: nameDraft)
        }
        .renameAlert(
            "Rename Video",
            footnote: "Leave it empty to go back to the video's own filename.",
            subject: $renamingVideo,
            text: $nameDraft
        ) { video in
            VideoTitleStore.shared.setTitle(nameDraft, for: video.id)
        }
        .sheet(isPresented: $showMergedWords) {
            MergedWordListView(
                videoIDs: videoIDs,
                // Languages belong to the playlist, so every video in it shares one pair.
                scope: playlist.map(TranslationScope.playlist) ?? .shared
            )
        }
    }

    private var isEditing: Bool { editMode?.wrappedValue.isEditing == true }

    private func setEditing(_ on: Bool) {
        withAnimation { editMode?.wrappedValue = on ? .active : .inactive }
    }

    /// Prefill with the name currently on screen, so the user edits what they
    /// see rather than starting from a blank field.
    private func beginRename(_ video: PickedVideo) {
        nameDraft = VideoTitleStore.shared.displayName(for: video.id) ?? ""
        renamingVideo = video
    }
}
