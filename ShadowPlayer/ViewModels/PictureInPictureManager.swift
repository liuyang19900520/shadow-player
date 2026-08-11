import AVKit
import AVFoundation
import Combine

/// Manages Picture-in-Picture (the floating desktop window) for an `AVPlayerLayer`.
///
/// Auto-start is enabled, so swiping up to the home screen while playing hands the
/// video off to a floating window instead of stopping playback. A manual toggle is
/// also exposed for the on-screen button.
///
/// Requires the "audio" background mode, declared in `ShadowPlayer-Info.plist`.
final class PictureInPictureManager: NSObject, ObservableObject, AVPictureInPictureControllerDelegate {
    /// True once the system reports PiP can actually start (playback ready, foreground, etc.).
    @Published private(set) var isPossible = false
    /// True while the floating window is on screen.
    @Published private(set) var isActive = false
    /// Whether the running device supports PiP at all (false on some simulators / older iPads).
    let isSupported = AVPictureInPictureController.isPictureInPictureSupported()

    private weak var playerLayer: AVPlayerLayer?
    private var controller: AVPictureInPictureController?
    private var possibleObservation: NSKeyValueObservation?
    private var readyObservation: NSKeyValueObservation?

    /// Bind to a player layer. The controller is deliberately *not* created here:
    /// building it before the layer has decoded its first frame leaves
    /// `isPictureInPicturePossible` stuck at false. Instead we watch
    /// `isReadyForDisplay` and construct it once the layer is actually rendering.
    func attach(to layer: AVPlayerLayer) {
        guard isSupported else { return }

        if playerLayer !== layer {
            playerLayer = layer
            readyObservation = layer.observe(\.isReadyForDisplay, options: [.initial, .new]) { [weak self] _, _ in
                DispatchQueue.main.async { self?.setupControllerIfReady() }
            }
        }
        // Re-check on each SwiftUI update as a safety net. Deferred, because this
        // runs during a view update and must not mutate published state inline.
        DispatchQueue.main.async { [weak self] in self?.setupControllerIfReady() }
    }

    private func setupControllerIfReady() {
        guard controller == nil, let layer = playerLayer, layer.isReadyForDisplay else { return }

        // PiP requires a .playback-family audio session; make sure it's set & active.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .moviePlayback)
        try? session.setActive(true)

        // iOS 15+ recommended initializer: a ContentSource wrapping the layer.
        let source = AVPictureInPictureController.ContentSource(playerLayer: layer)
        let pip = AVPictureInPictureController(contentSource: source)
        pip.canStartPictureInPictureAutomaticallyFromInline = true
        pip.delegate = self
        controller = pip

        possibleObservation = pip.observe(\.isPictureInPicturePossible, options: [.initial, .new]) { [weak self] pip, _ in
            DispatchQueue.main.async { self?.isPossible = pip.isPictureInPicturePossible }
        }
    }

    /// Manually start / stop the floating window.
    func toggle() {
        guard let controller else { return }
        if controller.isPictureInPictureActive {
            controller.stopPictureInPicture()
        } else if controller.isPictureInPicturePossible {
            controller.startPictureInPicture()
        }
    }

    // MARK: - AVPictureInPictureControllerDelegate

    func pictureInPictureControllerDidStartPictureInPicture(_ controller: AVPictureInPictureController) {
        isActive = true
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ controller: AVPictureInPictureController) {
        isActive = false
    }

    func pictureInPictureController(
        _ controller: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        isActive = false
    }

    /// Tapping "return to app" on the floating window: the player screen is still
    /// mounted, so just report the UI as restored.
    func pictureInPictureController(
        _ controller: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(true)
    }
}
