import SwiftUI

/// A thumbnail + duration row used in the Recent list and playlist detail.
struct VideoRow: View {
    let video: PickedVideo

    var body: some View {
        HStack(spacing: 12) {
            ThumbnailView(assetID: video.id)
                .frame(width: 72, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(formatTime(video.duration))
                .font(.body.monospacedDigit())
            Spacer()
            Image(systemName: "play.circle.fill")
                .font(.title2)
                .foregroundStyle(.tint)
        }
        .padding(.vertical, 4)
    }
}
