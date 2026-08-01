import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation

/// 系统视频选择器（免相册权限）：只拿用户勾选的视频文件，拷贝到本地缓存后播放。
struct VideoPicker: UIViewControllerRepresentable {
    /// 开始导入（拷贝文件）时回调，用于显示 loading。
    var onBegin: () -> Void = {}
    /// 导入完成回调。
    let onPicked: ([PickedVideo]) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration() // 不传 photoLibrary → 免权限，只访问所选文件
        config.filter = .videos
        config.selectionLimit = 0 // 不限，可多选
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onBegin: onBegin, onPicked: onPicked) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onBegin: () -> Void
        let onPicked: ([PickedVideo]) -> Void

        init(onBegin: @escaping () -> Void, onPicked: @escaping ([PickedVideo]) -> Void) {
            self.onBegin = onBegin
            self.onPicked = onPicked
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            let providers = results
                .map(\.itemProvider)
                .filter { $0.hasItemConformingToTypeIdentifier(UTType.movie.identifier) }

            guard !providers.isEmpty else {
                onPicked([])
                return
            }

            onBegin()
            Task {
                var items: [PickedVideo] = []
                for provider in providers {
                    if let item = await Self.loadVideo(from: provider) {
                        items.append(item)
                    }
                }
                let result = items
                await MainActor.run { self.onPicked(result) }
            }
        }

        /// 把所选视频拷贝到缓存目录，并读取时长。
        private static func loadVideo(from provider: NSItemProvider) async -> PickedVideo? {
            await withCheckedContinuation { continuation in
                provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, _ in
                    guard let url else {
                        continuation.resume(returning: nil)
                        return
                    }

                    // 临时文件只在本闭包内有效，必须先同步拷贝出来。
                    let ext = url.pathExtension.isEmpty ? "mov" : url.pathExtension
                    let destName = UUID().uuidString + "." + ext
                    let dest = PickedVideo.cacheDirectory().appendingPathComponent(destName)
                    do {
                        try FileManager.default.copyItem(at: url, to: dest)
                    } catch {
                        continuation.resume(returning: nil)
                        return
                    }

                    // 拷贝完成后再异步读时长。
                    let asset = AVURLAsset(url: dest)
                    Task {
                        let seconds = (try? await asset.load(.duration).seconds) ?? 0
                        let duration = seconds.isFinite ? seconds : 0
                        continuation.resume(
                            returning: PickedVideo(id: destName, url: dest, duration: duration)
                        )
                    }
                }
            }
        }

    }
}
