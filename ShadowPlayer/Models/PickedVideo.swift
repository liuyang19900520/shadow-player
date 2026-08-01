import Foundation

/// 用户手动选择的视频（已拷贝到本地缓存，直接用文件 URL 播放）。
struct PickedVideo: Identifiable, Hashable {
    let id: String
    let url: URL
    let duration: Double

    static func == (lhs: PickedVideo, rhs: PickedVideo) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension PickedVideo {
    /// 选中视频的本地缓存目录。
    static func cacheDirectory() -> URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("PickedVideos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// 由文件名（即 id）还原文件 URL。缓存目录随 App 容器路径变化，故只存文件名。
    static func url(for id: String) -> URL {
        cacheDirectory().appendingPathComponent(id)
    }
}
