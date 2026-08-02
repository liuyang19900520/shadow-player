import SwiftUI
import AVFoundation
import UIKit

/// Displays video via AVPlayerLayer (no built-in controls, so the UI can be fully custom).
struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerContainerUIView {
        PlayerContainerUIView(player: player)
    }

    func updateUIView(_ uiView: PlayerContainerUIView, context: Context) {}
}

final class PlayerContainerUIView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }

    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    /// Strong reference kept so we can detach the layer's player on background
    /// (letting audio keep playing) and reattach it on foreground.
    private let boundPlayer: AVPlayer

    init(player: AVPlayer) {
        boundPlayer = player
        super.init(frame: .zero)
        backgroundColor = .black
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspect

        let center = NotificationCenter.default
        center.addObserver(
            self,
            selector: #selector(didEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(willEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    /// Swipe up to home: detach the video layer from the player so AVPlayer keeps
    /// playing audio-only in the background (A-B loop included).
    @objc private func didEnterBackground() {
        playerLayer.player = nil
    }

    /// Back to foreground: reattach the player to restore the picture.
    @objc private func willEnterForeground() {
        playerLayer.player = boundPlayer
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
