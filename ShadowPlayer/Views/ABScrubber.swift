import SwiftUI

/// Custom scrubber: shows playback progress, is draggable, and marks the A start
/// point / B end point and the loop range on the track.
struct ABScrubber: View {
    let currentTime: Double
    let duration: Double
    let pointA: Double?
    let pointB: Double?
    /// Callback to seek when dragging ends.
    let onSeek: (Double) -> Void
    /// The time being scrubbed to while dragging, and nil once it ends. The
    /// thumb is hidden mid-drag, so this is what gives the user a precise
    /// read-out of where they are about to land.
    var onScrubbing: ((Double?) -> Void)? = nil

    @State private var isDragging = false
    @State private var dragTime: Double = 0
    /// Set when the touch landed on the thumb: the thumb is then dragged by how
    /// far the finger moves, rather than jumping to wherever the finger landed.
    @State private var grabbedThumb = false
    @State private var grabStartTime: Double = 0

    /// How far from the thumb's centre still counts as grabbing it.
    private let grabRadius: CGFloat = 22

    private let trackHeight: CGFloat = 5
    private let thumbSize: CGFloat = 15

    private var displayTime: Double { isDragging ? dragTime : currentTime }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let progress = ratio(displayTime) * width
            let aX = pointA.map { ratio($0) * width }
            let bX = pointB.map { ratio($0) * width }

            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.white.opacity(0.22))
                    .frame(height: trackHeight)

                // A-B loop range highlight
                if let aX, let bX {
                    Capsule()
                        .fill(Color.accentColor.opacity(0.55))
                        .frame(width: max(0, bX - aX), height: trackHeight)
                        .offset(x: aX)
                }

                // Played progress
                Capsule()
                    .fill(Color.white)
                    .frame(width: progress, height: trackHeight)

                // A marker
                if let aX {
                    marker(color: .green, letter: "A")
                        .offset(x: aX - 1)
                }
                // B marker
                if let bX {
                    marker(color: .orange, letter: "B")
                        .offset(x: bX - 1)
                }

                // Draggable thumb. Hidden while dragging: a 15pt dot can never
                // sit exactly under a fingertip, and the gap between the two is
                // far more distracting than having no dot at all. The filled
                // track and the live time read-out show where you are instead.
                if !isDragging {
                    Circle()
                        .fill(Color.white)
                        .frame(width: thumbSize, height: thumbSize)
                        .shadow(radius: 2)
                        .offset(x: progress - thumbSize / 2)
                }
            }
            .frame(height: thumbSize)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDragging {
                            // Decide once, on touch-down, how this drag behaves.
                            let thumbX = ratio(currentTime) * width
                            grabbedThumb = abs(value.startLocation.x - thumbX) <= grabRadius
                            grabStartTime = currentTime
                            isDragging = true
                        }

                        if grabbedThumb {
                            // Follow the finger's movement, so the thumb never
                            // jumps away from where it was picked up.
                            let moved = Double((value.location.x - value.startLocation.x) / width)
                            dragTime = clampTime(grabStartTime + moved * duration)
                        } else {
                            // Touching the bare track scrubs to that point.
                            dragTime = clampTime(Double(value.location.x / width) * duration)
                        }
                        onScrubbing?(dragTime)
                    }
                    .onEnded { _ in
                        onSeek(dragTime)
                        isDragging = false
                        grabbedThumb = false
                        onScrubbing?(nil)
                    }
            )
        }
        .frame(height: 28)
    }

    private func clampTime(_ time: Double) -> Double {
        guard duration > 0 else { return 0 }
        return min(max(0, time), duration)
    }

    private func ratio(_ time: Double) -> CGFloat {
        guard duration > 0 else { return 0 }
        return CGFloat(min(max(0, time / duration), 1))
    }

    private func marker(color: Color, letter: String) -> some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 1)
                .fill(color)
                .frame(width: 2, height: trackHeight + 6)
            Text(letter)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(color)
                .offset(y: -12)
        }
    }
}
