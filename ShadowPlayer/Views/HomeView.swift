import SwiftUI
import Photos

/// First screen: pick a video, recent playback (last 3), and playlists.
struct HomeView: View {
    @StateObject private var recent = RecentStore()
    @StateObject private var playlists = PlaylistStore()

    @State private var showPicker = false
    @State private var showDeniedAlert = false
    @State private var assignBatch: PickedBatch?
    @State private var showNewPlaylist = false
    @State private var newPlaylistName = ""
    @State private var renamingVideo: PickedVideo?
    @State private var renamingPlaylist: Playlist?
    /// Shared by both rename prompts; only one can be open at a time.
    @State private var nameDraft = ""

    private let recentLimit = 4

    /// Identifiable wrapper so a batch of just-picked videos can drive a sheet.
    private struct PickedBatch: Identifiable {
        let id = UUID()
        let videos: [PickedVideo]
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        selectVideos()
                    } label: {
                        Label("Select Video", systemImage: "plus.circle.fill")
                            .font(.body.weight(.medium))
                    }
                }

                recentSection
                playlistsSection
            }
            .navigationTitle("ShadowPlayer")
            .navigationDestination(for: PickedVideo.self) { video in
                PlayerView(video: video, onStart: { recent.bump(video) })
            }
            .navigationDestination(for: Playlist.self) { playlist in
                PlaylistDetailView(playlistID: playlist.id, store: playlists)
            }
            .sheet(isPresented: $showPicker) {
                VideoPicker(onPicked: { picked in
                    guard !picked.isEmpty else { return }
                    recent.addMany(picked)
                    // Let the picker finish dismissing before presenting the
                    // assign sheet, otherwise the second sheet won't appear.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        assignBatch = PickedBatch(videos: picked)
                    }
                })
                .ignoresSafeArea()
            }
            .sheet(item: $assignBatch) { batch in
                AddToPlaylistView(videos: batch.videos, store: playlists)
            }
            .alert("Can’t Access Photos", isPresented: $showDeniedAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please allow ShadowPlayer to access your photos in Settings to select and play videos.")
            }
            .alert("New Playlist", isPresented: $showNewPlaylist) {
                TextField("Name", text: $newPlaylistName)
                Button("Create") { playlists.create(name: newPlaylistName) }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Name your new playlist.")
            }
            .renameAlert(
                "Rename Video",
                footnote: "Leave it empty to go back to the video's own filename.",
                subject: $renamingVideo,
                text: $nameDraft
            ) { video in
                VideoTitleStore.shared.setTitle(nameDraft, for: video.id)
            }
            .renameAlert(
                "Rename Playlist",
                subject: $renamingPlaylist,
                text: $nameDraft
            ) { playlist in
                playlists.rename(playlist.id, to: nameDraft)
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var recentSection: some View {
        if recent.items.isEmpty {
            Section {
                Text("No videos yet. Tap “Select Video” above to start.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } else {
            Section("Recent") {
                ForEach(Array(recent.items.prefix(recentLimit))) { video in
                    NavigationLink(value: video) {
                        VideoRow(
                            video: video,
                            playlistNames: playlists.playlistNames(containing: video.id)
                        )
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            assignBatch = PickedBatch(videos: [video])
                        } label: {
                            Label("Add to Playlist", systemImage: "text.badge.plus")
                        }
                        .tint(.accentColor)

                        Button {
                            beginRename(video)
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                        .tint(.gray)
                    }
                    .contextMenu {
                        Button {
                            assignBatch = PickedBatch(videos: [video])
                        } label: {
                            Label("Add to Playlist", systemImage: "text.badge.plus")
                        }
                        Button {
                            beginRename(video)
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                    }
                }
                .onDelete { recent.remove(atOffsets: $0) }
            }
        }
    }

    private var playlistsSection: some View {
        Section("Playlists") {
            ForEach(playlists.playlists) { playlist in
                NavigationLink(value: playlist) {
                    HStack(spacing: 12) {
                        Image(systemName: "music.note.list")
                            .font(.title3)
                            .foregroundStyle(.tint)
                            .frame(width: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(playlist.name)
                                .font(.body.weight(.medium))
                            Text("\(playlist.videos.count) videos")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .swipeActions(edge: .trailing) {
                    Button {
                        beginRename(playlist)
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    .tint(.gray)
                }
                .contextMenu {
                    Button {
                        beginRename(playlist)
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                }
            }
            .onDelete { playlists.delete(atOffsets: $0) }

            Button {
                newPlaylistName = ""
                showNewPlaylist = true
            } label: {
                Label("New Playlist", systemImage: "plus")
            }
        }
    }

    // MARK: - Actions

    /// Prefill with the name currently on screen, so the user edits what they
    /// see rather than starting from a blank field.
    private func beginRename(_ video: PickedVideo) {
        nameDraft = VideoTitleStore.shared.displayName(for: video.id) ?? ""
        renamingVideo = video
    }

    private func beginRename(_ playlist: Playlist) {
        nameDraft = playlist.name
        renamingPlaylist = playlist
    }

    /// Requests photo-library permission, then opens the picker.
    private func selectVideos() {
        Task {
            // PHAccessLevel only offers .addOnly / .readWrite — there is no
            // read-only level, so .readWrite is required just to read the library.
            // The app never adds to or modifies the user's photos.
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            if status == .authorized || status == .limited {
                showPicker = true
            } else {
                showDeniedAlert = true
            }
        }
    }
}
