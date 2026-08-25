import SwiftUI

/// iOS-style "Add to Playlist" sheet: tap a playlist to toggle the video's
/// membership, or create a new playlist (the video is added to it).
struct AddToPlaylistView: View {
    let video: PickedVideo
    @ObservedObject var store: PlaylistStore
    @Environment(\.dismiss) private var dismiss

    @State private var showingNewPlaylist = false
    @State private var newName = ""

    var body: some View {
        NavigationStack {
            List {
                if !store.playlists.isEmpty {
                    Section {
                        ForEach(store.playlists) { playlist in
                            Button {
                                store.toggle(video, in: playlist.id)
                            } label: {
                                HStack {
                                    Image(systemName: "music.note.list")
                                        .foregroundStyle(.secondary)
                                    Text(playlist.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if store.contains(video, in: playlist.id) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.tint)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                        }
                    }
                }

                Section {
                    Button {
                        newName = ""
                        showingNewPlaylist = true
                    } label: {
                        Label("New Playlist", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Add to Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("New Playlist", isPresented: $showingNewPlaylist) {
                TextField("Name", text: $newName)
                Button("Create") {
                    let playlist = store.create(name: newName)
                    store.toggle(video, in: playlist.id) // add this video to the new playlist
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Name your new playlist.")
            }
        }
    }
}
