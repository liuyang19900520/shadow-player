import SwiftUI
import AVFoundation
import UIKit

/// Displays video via AVPlayerLayer (no built-in controls, so the UI can be fully custom).
struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer
    /// Manages the Picture-in-Picture (floating desktop window) for this layer.
    let pip: PictureInPictureManager

    func makeUIView(context: Context) -> PlayerContainerUIView {
        let view = PlayerContainerUIView(player: player)
        pip.attach(to: view.playerLayer)
        return view
    }

    func updateUIView(_ uiView: PlayerContainerUIView, context: Context) {
        pip.attach(to: uiView.playerLayer)
    }
}

final class PlayerContainerUIView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }

    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    init(player: AVPlayer) {
        super.init(frame: .zero)
        backgroundColor = .black
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspect
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
