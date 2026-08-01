import Foundation

/// 最近播放列表：持久化到 UserDefaults，最近播放的排最前。
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

        // 过滤掉文件已不存在的记录（缓存可能被系统清理）。
        items = records.compactMap { record in
            let url = PickedVideo.url(for: record.id)
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            return PickedVideo(id: record.id, url: url, duration: record.duration)
        }
    }

    /// 新选的视频加入列表最前（去重）。
    func addMany(_ videos: [PickedVideo]) {
        guard !videos.isEmpty else { return }
        let existingIDs = Set(items.map(\.id))
        let unique = videos.filter { !existingIDs.contains($0.id) }
        items = unique + items
        save()
    }

    /// 播放某个视频后，把它移到最前。
    func bump(_ video: PickedVideo) {
        var list = items.filter { $0.id != video.id }
        list.insert(video, at: 0)
        items = list
        save()
    }

    func remove(atOffsets offsets: IndexSet) {
        let removed = offsets.map { items[$0] }
        items.remove(atOffsets: offsets)
        save()
        // 顺手删掉缓存文件。
        for video in removed {
            try? FileManager.default.removeItem(at: video.url)
        }
    }

    private func save() {
        let records = items.map { Record(id: $0.id, duration: $0.duration) }
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
