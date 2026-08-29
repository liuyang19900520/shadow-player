import SwiftUI

/// iOS-style "Add to Playlist" sheet. Tap a playlist to add the picked
/// video(s) to it (tap again to remove); or create a new playlist. Videos
/// left unassigned simply stay in Recent — that is the default bucket.
struct AddToPlaylistView: View {
    let videos: [PickedVideo]
    @ObservedObject var store: PlaylistStore
    @Environment(\.dismiss) private var dismiss

    @State private var showingNewPlaylist = false
    @State private var newName = ""

    private var countLabel: String {
        videos.count == 1 ? "1 video" : "\(videos.count) videos"
    }

    var body: some View {
        NavigationStack {
            List {
                if !store.playlists.isEmpty {
                    Section {
                        ForEach(store.playlists) { playlist in
                            Button {
                                let allIn = store.containsAll(videos, in: playlist.id)
                                store.setMembership(videos, in: playlist.id, add: !allIn)
                            } label: {
                                HStack {
                                    Image(systemName: "music.note.list")
                                        .foregroundStyle(.secondary)
                                    Text(playlist.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if store.containsAll(videos, in: playlist.id) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.tint)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                        }
                    } footer: {
                        Text("Not added to a playlist? It stays in Recent.")
                    }
                }

                Section {
                    Button {
                        newName = ""
                        showingNewPlaylist = true
                    } label: {
                        Label("New Playlist", systemImage: "plus")
                    }
                } footer: {
                    if store.playlists.isEmpty {
                        Text("Create a playlist to group these videos, or tap Done to keep them in Recent.")
                    }
                }
            }
            .navigationTitle("Add to Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 1) {
                        Text("Add to Playlist").font(.headline)
                        Text(countLabel).font(.caption).foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("New Playlist", isPresented: $showingNewPlaylist) {
                TextField("Name", text: $newName)
                Button("Create") {
                    let playlist = store.create(name: newName)
                    store.setMembership(videos, in: playlist.id, add: true)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Name your new playlist.")
            }
        }
    }
}
