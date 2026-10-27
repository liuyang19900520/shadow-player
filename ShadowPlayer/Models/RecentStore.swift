import Foundation

/// Recent-playback list: persisted to UserDefaults (asset identifiers only),
/// most recently played first.
final class RecentStore: ObservableObject {
    @Published private(set) var items: [PickedVideo] = []
    /// The video last opened in the player, for Home's Continue row. Kept
    /// apart from the list order, which newly picked videos also change.
    @Published private(set) var lastPlayedID: String?

    private let key = "recentVideos"
    private let lastPlayedKey = "lastPlayedVideo"

    private struct Record: Codable {
        let id: String
        let duration: Double
    }

    init() {
        load()
        lastPlayedID = UserDefaults.standard.string(forKey: lastPlayedKey)
    }

    /// The last played video, if it is still in the list.
    var lastPlayed: PickedVideo? {
        items.first { $0.id == lastPlayedID }
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let records = try? JSONDecoder().decode([Record].self, from: data)
        else {
            items = []
            return
        }
        items = records.map { PickedVideo(id: $0.id, duration: $0.duration) }
    }

    /// Adds newly picked videos to the front of the list (deduplicated).
    func addMany(_ videos: [PickedVideo]) {
        guard !videos.isEmpty else { return }
        let existingIDs = Set(items.map(\.id))
        let unique = videos.filter { !existingIDs.contains($0.id) }
        items = unique + items
        save()
    }

    /// Moves a video to the front after it starts playing.
    func bump(_ video: PickedVideo) {
        var list = items.filter { $0.id != video.id }
        list.insert(video, at: 0)
        items = list
        lastPlayedID = video.id
        UserDefaults.standard.set(video.id, forKey: lastPlayedKey)
        save()
    }

    func remove(_ video: PickedVideo) {
        items.removeAll { $0.id == video.id }
        save()
    }

    private func save() {
        let records = items.map { Record(id: $0.id, duration: $0.duration) }
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
