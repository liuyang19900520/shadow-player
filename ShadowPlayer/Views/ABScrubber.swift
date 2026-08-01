import SwiftUI

/// 自定义进度条：显示已播进度、可拖动，并在轨道上标出 A 起点 / B 终点及循环区间。
struct ABScrubber: View {
    let currentTime: Double
    let duration: Double
    let pointA: Double?
    let pointB: Double?
    /// 拖动结束后回调 seek。
    let onSeek: (Double) -> Void

    @State private var isDragging = false
    @State private var dragTime: Double = 0

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
                // 背景轨道
                Capsule()
                    .fill(Color.white.opacity(0.22))
                    .frame(height: trackHeight)

                // A-B 循环区间高亮
                if let aX, let bX {
                    Capsule()
                        .fill(Color.accentColor.opacity(0.55))
                        .frame(width: max(0, bX - aX), height: trackHeight)
                        .offset(x: aX)
                }

                // 已播放进度
                Capsule()
                    .fill(Color.white)
                    .frame(width: progress, height: trackHeight)

                // A 标记
                if let aX {
                    marker(color: .green, letter: "A")
                        .offset(x: aX - 1)
                }
                // B 标记
                if let bX {
                    marker(color: .orange, letter: "B")
                        .offset(x: bX - 1)
                }

                // 拖动圆点
                Circle()
                    .fill(Color.white)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(radius: 2)
                    .offset(x: progress - thumbSize / 2)
                    .scaleEffect(isDragging ? 1.3 : 1)
                    .animation(.easeOut(duration: 0.12), value: isDragging)
            }
            .frame(height: thumbSize)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        let r = min(max(0, value.location.x / width), 1)
                        dragTime = r * duration
                    }
                    .onEnded { _ in
                        onSeek(dragTime)
                        isDragging = false
                    }
            )
        }
        .frame(height: 28)
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
