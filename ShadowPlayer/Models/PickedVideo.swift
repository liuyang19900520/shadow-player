import Foundation

/// A user-selected video, represented by its photo-library asset identifier
/// (streamed for playback, no file copy).
struct PickedVideo: Identifiable, Hashable {
    /// PHAsset.localIdentifier
    let id: String
    let duration: Double

    static func == (lhs: PickedVideo, rhs: PickedVideo) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
