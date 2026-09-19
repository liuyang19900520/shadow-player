import Foundation

/// User-created playlists, persisted to UserDefaults.
final class PlaylistStore: ObservableObject {
    @Published private(set) var playlists: [Playlist] = []

    private static let key = "playlists"
    private var key: String { Self.key }

    init() {
        playlists = PlaylistStore.loadAll()
    }

    /// The stored playlists, without having to build a store — used to find
    /// which playlist a video belongs to.
    static func loadAll() -> [Playlist] {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode([Playlist].self, from: data)
        else { return [] }
        return decoded
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

    /// Adds or removes a batch of videos in one playlist. Adding skips videos
    /// already present; removing skips videos that aren't there.
    func setMembership(_ videos: [PickedVideo], in id: UUID, add: Bool) {
        guard let i = index(of: id) else { return }
        for video in videos {
            let existing = playlists[i].videos.firstIndex { $0.id == video.id }
            if add, existing == nil {
                playlists[i].videos.insert(video, at: 0) // newest first
            } else if !add, let e = existing {
                playlists[i].videos.remove(at: e)
            }
        }
        save()
    }

    /// True only when every given video is already in the playlist.
    func containsAll(_ videos: [PickedVideo], in id: UUID) -> Bool {
        guard !videos.isEmpty, let i = index(of: id) else { return false }
        let ids = Set(playlists[i].videos.map(\.id))
        return videos.allSatisfy { ids.contains($0.id) }
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
