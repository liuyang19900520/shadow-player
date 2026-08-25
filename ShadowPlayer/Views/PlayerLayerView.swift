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

    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    /// Kept so we can detach the player on background and reattach on foreground.
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

    /// Screen lock / swipe-to-home: detach the layer's player so AVPlayer keeps
    /// playing audio only. A player tied to a hidden video layer gets paused by
    /// the system, which is why audio stopped when the phone was locked.
    @objc private func didEnterBackground() {
        playerLayer.player = nil
    }

    /// Back to foreground: reattach so the picture returns.
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
