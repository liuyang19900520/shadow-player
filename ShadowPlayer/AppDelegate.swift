import UIKit

/// Controls the app's supported interface orientations: locked to portrait by
/// default, allowing landscape only during fullscreen playback.
final class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock: UIInterfaceOrientationMask = .portrait

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        AppDelegate.orientationLock
    }
}

/// Switches and forces the screen to rotate to the given orientation.
enum Orientation {
    static func set(_ mask: UIInterfaceOrientationMask) {
        AppDelegate.orientationLock = mask

        guard
            let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else { return }

        scene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask)) { _ in }
    }
}
