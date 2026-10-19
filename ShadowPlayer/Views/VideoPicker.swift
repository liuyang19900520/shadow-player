import SwiftUI
import PhotosUI
import Photos

/// System video picker: returns the asset identifiers of the selected videos
/// (streamed for playback, no file copy, returns instantly).
struct VideoPicker: UIViewControllerRepresentable {
    let onPicked: ([PickedVideo]) -> Void

    /// Asks for photo-library access; true when the picker may be shown.
    static func requestAccess() async -> Bool {
        // PHAccessLevel only offers .addOnly / .readWrite — there is no
        // read-only level, so .readWrite is required just to read the library.
        // The app never adds to or modifies the user's photos.
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        return status == .authorized || status == .limited
    }

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

extension View {
    /// Shown when photo-library access was refused, pointing to Settings.
    func photoAccessDeniedAlert(isPresented: Binding<Bool>) -> some View {
        alert("Can’t Access Photos", isPresented: isPresented) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please allow Kage Loop to access your photos in Settings to select and play videos.")
        }
    }
}
