import SwiftUI

/// A playlist's videos: add from Photos, tap to play, swipe to remove or
/// rename, Edit to reorder.
struct PlaylistDetailView: View {
    let playlistID: UUID
    @ObservedObject var store: PlaylistStore
    /// Videos added here also land in Recent, as they do from Home.
    @ObservedObject var recent: RecentStore

    @Environment(\.editMode) private var editMode

    @State private var renamingPlaylist: Playlist?
    @State private var renamingVideo: PickedVideo?
    /// Shared by both rename prompts; only one can be open at a time.
    @State private var nameDraft = ""
    @State private var showPicker = false
    @State private var showDeniedAlert = false

    private var playlist: Playlist? {
        store.playlists.first { $0.id == playlistID }
    }

    var body: some View {
        List {
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
                    Text("No videos yet. Tap + to add some from Photos.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(playlist?.name ?? "Playlist")
        .navigationBarTitleDisplayMode(.inline)
        // + adds videos, as on Home; the menu holds everything else that
        // manages the playlist. Both give way to Done while reordering — the
        // way Files and Photos do it.
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if isEditing {
                    Button("Done") { setEditing(false) }
                } else {
                    Button {
                        selectVideos()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Videos")

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
        .sheet(isPresented: $showPicker) {
            VideoPicker(onPicked: { picked in
                guard !picked.isEmpty else { return }
                recent.addMany(picked)
                store.setMembership(picked, in: playlistID, add: true)
            })
            .ignoresSafeArea()
        }
        .photoAccessDeniedAlert(isPresented: $showDeniedAlert)
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
    }

    private var isEditing: Bool { editMode?.wrappedValue.isEditing == true }

    private func setEditing(_ on: Bool) {
        withAnimation { editMode?.wrappedValue = on ? .active : .inactive }
    }

    private func selectVideos() {
        Task {
            if await VideoPicker.requestAccess() {
                showPicker = true
            } else {
                showDeniedAlert = true
            }
        }
    }

    /// Prefill with the name currently on screen, so the user edits what they
    /// see rather than starting from a blank field.
    private func beginRename(_ video: PickedVideo) {
        nameDraft = VideoTitleStore.shared.displayName(for: video.id) ?? ""
        renamingVideo = video
    }
}
