import SwiftUI

/// A thumbnail + name row used in the Recent list and playlist detail. The name
/// leads and the duration sits under it, so a list of episodes is readable at a
/// glance; with no name known the duration keeps the leading role.
struct VideoRow: View {
    let video: PickedVideo
    /// Playlists this video belongs to. Shown in Recent so it is clear where a
    /// video came from; left empty inside a playlist, where it would be noise.
    var playlistNames: [String] = []

    @ObservedObject private var titles = VideoTitleStore.shared

    private var name: String? { titles.displayName(for: video.id) }

    /// "Japanese N3", or "Japanese N3 +2" when it is in several.
    private var playlistLabel: String? {
        guard let first = playlistNames.first else { return nil }
        return playlistNames.count > 1 ? "\(first) +\(playlistNames.count - 1)" : first
    }

    var body: some View {
        HStack(spacing: 12) {
            ThumbnailView(assetID: video.id)
                .frame(width: 72, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(name ?? formatTime(video.duration))
                    .font(name == nil ? .body.monospacedDigit() : .body)
                    .lineLimit(2)

                if name != nil || playlistLabel != nil {
                    metadata
                }
            }

            Spacer()

            Image(systemName: "play.circle.fill")
                .font(.title2)
                .foregroundStyle(.tint)
        }
        .padding(.vertical, 4)
        .task(id: video.id) { await titles.loadFilename(for: video.id) }
    }

    /// Duration and playlist on one dot-separated line, the way iOS lists show
    /// secondary details. The duration is dropped when it is already the title.
    @ViewBuilder
    private var metadata: some View {
        HStack(spacing: 4) {
            if name != nil {
                Text(formatTime(video.duration))
                    .monospacedDigit()
            }
            if let playlistLabel {
                if name != nil { Text("·") }
                Image(systemName: "music.note.list")
                Text(playlistLabel)
                    .lineLimit(1)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}
