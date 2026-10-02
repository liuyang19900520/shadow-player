import SwiftUI
import UIKit

extension Notification.Name {
    static let deviceDidShake = Notification.Name("deviceDidShake")
}

extension UIWindow {
    /// SwiftUI has no shake gesture; UIKit reports shakes to the window, so
    /// relay them. The event still travels on up the responder chain.
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
        }
    }
}

/// The offer to add a looped line, shown above the A-B buttons. There is
/// always a button as well as the shake, since a shake isn't possible for
/// everyone and isn't always convenient mid-practice.
struct LoopCaptureBanner: View {
    let prompt: LoopCaptureModel.Prompt
    let onAdd: () -> Void
    let onChooseLanguage: () -> Void

    var body: some View {
        switch prompt {
        case .none:
            EmptyView()
        case .ready(let preview):
            bar(icon: "iphone.gen3.radiowaves.left.and.right", tint: .accentColor,
                title: "Shake to add this line", detail: preview) {
                Button("Add", action: onAdd)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        case .needsLanguage:
            bar(icon: "character.bubble", tint: .accentColor,
                title: "Choose the audio language",
                detail: "Needed to add looped lines to your words") {
                Button("Choose", action: onChooseLanguage)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        case .added(let count):
            bar(icon: "checkmark.circle.fill", tint: .green,
                title: count == 1 ? "Added to your words" : "Added \(count) lines to your words",
                detail: nil) { EmptyView() }
        }
    }

    private func bar<Trailing: View>(
        icon: String,
        tint: Color,
        title: String,
        detail: String?,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            trailing()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .environment(\.colorScheme, .dark) // the player is always dark
        .accessibilityElement(children: .contain)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
