import Foundation

/// User-created playlists, persisted to UserDefaults.
final class PlaylistStore: ObservableObject {
    @Published private(set) var playlists: [Playlist] = []

    private let key = "playlists"

    init() {
        load()
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Playlist].self, from: data) {
            playlists = decoded
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(playlists) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    @discardableResult
    func create(name: String) -> Playlist {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let playlist = Playlist(name: trimmed.isEmpty ? "New Playlist" : trimmed)
        playlists.append(playlist)
        save()
        return playlist
    }

    func rename(_ id: UUID, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let i = index(of: id) else { return }
        playlists[i].name = trimmed
        save()
    }

    func delete(atOffsets offsets: IndexSet) {
        playlists.remove(atOffsets: offsets)
        save()
    }

    // MARK: - Membership

    func contains(_ video: PickedVideo, in id: UUID) -> Bool {
        guard let i = index(of: id) else { return false }
        return playlists[i].videos.contains { $0.id == video.id }
    }

    /// Add the video if absent, remove it if present.
    func toggle(_ video: PickedVideo, in id: UUID) {
        guard let i = index(of: id) else { return }
        if let vi = playlists[i].videos.firstIndex(where: { $0.id == video.id }) {
            playlists[i].videos.remove(at: vi)
        } else {
            playlists[i].videos.insert(video, at: 0) // newest first
        }
        save()
    }

    func removeVideos(atOffsets offsets: IndexSet, from id: UUID) {
        guard let i = index(of: id) else { return }
        playlists[i].videos.remove(atOffsets: offsets)
        save()
    }

    func moveVideos(fromOffsets: IndexSet, toOffset: Int, in id: UUID) {
        guard let i = index(of: id) else { return }
        playlists[i].videos.move(fromOffsets: fromOffsets, toOffset: toOffset)
        save()
    }

    private func index(of id: UUID) -> Int? {
        playlists.firstIndex { $0.id == id }
    }
}
