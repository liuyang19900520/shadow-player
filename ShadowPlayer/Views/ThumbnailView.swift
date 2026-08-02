import SwiftUI
import Photos

/// Loads a thumbnail from a photo-library asset identifier.
struct ThumbnailView: View {
    let assetID: String
    var maxSize: CGSize = CGSize(width: 400, height: 400)

    @State private var image: UIImage?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .overlay(Image(systemName: "film").foregroundStyle(.white.opacity(0.3)))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .task(id: assetID) { await load() }
    }

    private func load() async {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil).firstObject else {
            return
        }
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast

        image = await withCheckedContinuation { continuation in
            var resumed = false
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: maxSize,
                contentMode: .aspectFill,
                options: options
            ) { img, _ in
                guard !resumed else { return }
                resumed = true
                continuation.resume(returning: img)
            }
        }
    }
}

/// Seconds -> "m:ss" / "h:mm:ss"
func formatTime(_ seconds: Double) -> String {
    guard seconds.isFinite, seconds >= 0 else { return "0:00" }
    let total = Int(seconds.rounded())
    let h = total / 3600
    let m = (total % 3600) / 60
    let s = total % 60
    if h > 0 {
        return String(format: "%d:%02d:%02d", h, m, s)
    }
    return String(format: "%d:%02d", m, s)
}
