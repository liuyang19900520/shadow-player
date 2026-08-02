import Foundation

/// Recent-playback list: persisted to UserDefaults (asset identifiers only),
/// most recently played first.
final class RecentStore: ObservableObject {
    @Published private(set) var items: [PickedVideo] = []

    private let key = "recentVideos"

    private struct Record: Codable {
        let id: String
        let duration: Double
    }

    init() {
        load()
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
        save()
    }

    func remove(atOffsets offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }

    private func save() {
        let records = items.map { Record(id: $0.id, duration: $0.duration) }
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
