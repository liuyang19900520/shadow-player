import SwiftUI
import Photos

/// First screen: pick a video, recent playback (last 3), and playlists.
struct HomeView: View {
    @StateObject private var recent = RecentStore()
    @StateObject private var playlists = PlaylistStore()

    @State private var showPicker = false
    @State private var showDeniedAlert = false
    @State private var addToPlaylistVideo: PickedVideo?
    @State private var showNewPlaylist = false
    @State private var newPlaylistName = ""

    private let recentLimit = 3

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
                VideoPicker(onPicked: { recent.addMany($0) })
                    .ignoresSafeArea()
            }
            .sheet(item: $addToPlaylistVideo) { video in
                AddToPlaylistView(video: video, store: playlists)
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
                        VideoRow(video: video)
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            addToPlaylistVideo = video
                        } label: {
                            Label("Add to Playlist", systemImage: "text.badge.plus")
                        }
                        .tint(.accentColor)
                    }
                    .contextMenu {
                        Button {
                            addToPlaylistVideo = video
                        } label: {
                            Label("Add to Playlist", systemImage: "text.badge.plus")
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

    /// Requests photo-library permission, then opens the picker.
    private func selectVideos() {
        Task {
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            if status == .authorized || status == .limited {
                showPicker = true
            } else {
                showDeniedAlert = true
            }
        }
    }
}
