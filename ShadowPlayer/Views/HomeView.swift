import SwiftUI

/// First screen, ordered by what a study session does next: today's check-in,
/// the video to pick up again, then Recent and Playlists. Adding videos and
/// playlists lives in the + menu, since it happens far less often than playing.
struct HomeView: View {
    @StateObject private var recent = RecentStore()
    @StateObject private var playlists = PlaylistStore()
    @ObservedObject private var practice = PracticeLogStore.shared

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
                    NavigationLink {
                        CheckInCalendarView(log: practice)
                    } label: {
                        TodayCard(log: practice)
                    }
                }

                if recent.items.isEmpty && playlists.playlists.isEmpty {
                    emptyState
                } else {
                    continueSection
                    recentSection
                    playlistsSection
                }
            }
            .navigationTitle("Kage Loop")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    NavigationLink {
                        WordListsView(playlists: playlists)
                    } label: {
                        Image(systemName: "text.book.closed")
                    }
                    .accessibilityLabel("Word Lists")

                    Menu {
                        Button {
                            selectVideos()
                        } label: {
                            Label("Add Videos", systemImage: "photo.on.rectangle")
                        }
                        Button {
                            newPlaylistName = ""
                            showNewPlaylist = true
                        } label: {
                            Label("New Playlist", systemImage: "music.note.list")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add")
                }
            }
            .navigationDestination(for: PickedVideo.self) { video in
                PlayerView(video: video, onStart: { recent.bump(video) })
            }
            .navigationDestination(for: Playlist.self) { playlist in
                PlaylistDetailView(playlistID: playlist.id, store: playlists, recent: recent)
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
            .photoAccessDeniedAlert(isPresented: $showDeniedAlert)
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

    /// First run: one clear way in, instead of empty sections.
    private var emptyState: some View {
        Section {
            VStack(spacing: 12) {
                Image(systemName: "film.stack")
                    .font(.system(size: 40))
                    .foregroundStyle(.tint)
                Text("Add your first video")
                    .font(.headline)
                Text("Pick videos from Photos, then loop a line A to B to practise it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Add Videos") { selectVideos() }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }

    /// The video last played, where it was left off: one tap to carry on.
    @ViewBuilder
    private var continueSection: some View {
        if let video = recent.lastPlayed {
            Section("Continue") {
                NavigationLink(value: video) {
                    ContinueRow(video: video)
                }
            }
        }
    }

    /// Recent videos other than the one already offered under Continue.
    private var recentVideos: [PickedVideo] {
        let skipped = recent.lastPlayed?.id
        return Array(recent.items.filter { $0.id != skipped }.prefix(recentLimit))
    }

    @ViewBuilder
    private var recentSection: some View {
        let videos = recentVideos
        if !videos.isEmpty {
            Section("Recent") {
                ForEach(videos) { video in
                    NavigationLink(value: video) {
                        VideoRow(
                            video: video,
                            playlistNames: playlists.playlistNames(containing: video.id)
                        )
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            recent.remove(video)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

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
            }
        }
    }

    @ViewBuilder
    private var playlistsSection: some View {
        if !playlists.playlists.isEmpty {
            playlistsList
        }
    }

    private var playlistsList: some View {
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
            if await VideoPicker.requestAccess() {
                showPicker = true
            } else {
                showDeniedAlert = true
            }
        }
    }
}
