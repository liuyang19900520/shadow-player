import SwiftUI
import PhotosUI
import Photos

/// System video picker: returns the asset identifiers of the selected videos
/// (streamed for playback, no file copy, returns instantly).
struct VideoPicker: UIViewControllerRepresentable {
    let onPicked: ([PickedVideo]) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .videos
        config.selectionLimit = 0 // unlimited, multi-select
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPicked: onPicked) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPicked: ([PickedVideo]) -> Void

        init(onPicked: @escaping ([PickedVideo]) -> Void) {
            self.onPicked = onPicked
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            let ids = results.compactMap { $0.assetIdentifier }
            guard !ids.isEmpty else {
                onPicked([])
                return
            }

            // Fetch PHAssets to read durations; return in the user's selection order.
            let fetched = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
            var byID: [String: PHAsset] = [:]
            fetched.enumerateObjects { asset, _, _ in byID[asset.localIdentifier] = asset }

            let items = ids.compactMap { id -> PickedVideo? in
                guard let asset = byID[id] else { return nil }
                return PickedVideo(id: id, duration: asset.duration)
            }
            onPicked(items)
        }
    }
}
