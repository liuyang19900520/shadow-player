import SwiftUI

/// 第三页：播放页。视频 + 进度条(带 A/B 标记) + 传输控制 + A/B/C 循环按钮。
struct PlayerView: View {
    let video: PickedVideo
    /// 开始播放时回调（用于更新"最近播放"）。
    var onStart: () -> Void = {}

    @StateObject private var vm = PlayerViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            PlayerLayerView(player: vm.player)
                .ignoresSafeArea()

            // 控制条一直显示
            controls
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            vm.load(video: video)
            onStart()
        }
        .onDisappear {
            vm.cleanup()
        }
    }

    // MARK: - 控制层

    private var controls: some View {
        VStack(spacing: 0) {
            Spacer()
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)

            VStack(spacing: 18) {
                progressSection
                transportRow
                abRow
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .padding(.top, 8)
            .background(Color.black.opacity(0.7))
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var progressSection: some View {
        VStack(spacing: 6) {
            ABScrubber(
                currentTime: vm.currentTime,
                duration: vm.duration,
                pointA: vm.pointA,
                pointB: vm.pointB,
                onSeek: { vm.seek(to: $0) }
            )
            HStack {
                Text(formatTime(vm.currentTime))
                Spacer()
                if vm.isLooping {
                    Label("A-B 循环中", systemImage: "repeat")
                        .foregroundStyle(.tint)
                }
                Spacer()
                Text(formatTime(vm.duration))
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.white.opacity(0.85))
        }
    }

    private var transportRow: some View {
        HStack(spacing: 48) {
            SeekButton(
                systemImage: "backward.fill",
                onTap: { vm.seekBy(-vm.seekStep) },
                onHold: { holding in
                    if holding { vm.startScan(forward: false) }
                    else { vm.stopScan() }
                }
            )

            Button {
                vm.playPause()
            } label: {
                Image(systemName: vm.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 40))
                    .frame(width: 54, height: 54)
            }

            SeekButton(
                systemImage: "forward.fill",
                onTap: { vm.seekBy(vm.seekStep) },
                onHold: { holding in
                    if holding { vm.startScan(forward: true) }
                    else { vm.stopScan() }
                }
            )
        }
        .foregroundStyle(.white)
    }

    private var abRow: some View {
        HStack(spacing: 10) {
            ABButton(
                title: "A 起点",
                systemImage: "a.circle.fill",
                tint: .green,
                isActive: vm.pointA != nil
            ) {
                vm.setPointA()
            }

            ABButton(
                title: "B 终点",
                systemImage: "b.circle.fill",
                tint: .orange,
                isActive: vm.pointB != nil,
                isDisabled: vm.pointA == nil
            ) {
                vm.setPointB()
            }

            ABButton(
                title: "取消",
                systemImage: "xmark.circle.fill",
                tint: .red,
                isActive: false,
                isDisabled: vm.pointA == nil && vm.pointB == nil
            ) {
                vm.cancelAB()
            }
        }
    }
}

/// 快进/快退按钮：短按跳 3 秒，长按连续扫描，松手停止。
private struct SeekButton: View {
    let systemImage: String
    let onTap: () -> Void
    /// 长按状态变化：true = 开始扫描，false = 停止。
    let onHold: (Bool) -> Void

    @State private var isPressing = false
    @State private var didHold = false
    @State private var holdWork: DispatchWorkItem?

    private let holdDelay = 0.35

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: systemImage)
                .font(.system(size: 28))
            Text("3秒")
                .font(.system(size: 10, weight: .semibold))
                .opacity(0.7)
        }
        .foregroundStyle(.white)
        .scaleEffect(isPressing ? 1.15 : 1)
        .animation(.easeOut(duration: 0.12), value: isPressing)
        .contentShape(Rectangle())
        .frame(width: 60, height: 56)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isPressing else { return }
                    isPressing = true
                    didHold = false
                    let work = DispatchWorkItem {
                        didHold = true
                        onHold(true)
                    }
                    holdWork = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + holdDelay, execute: work)
                }
                .onEnded { _ in
                    isPressing = false
                    holdWork?.cancel()
                    if didHold {
                        onHold(false)
                    } else {
                        onTap()
                    }
                }
        )
    }
}

/// A / B / C 按钮样式。
private struct ABButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    let isActive: Bool
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 22))
                Text(title)
                    .font(.caption2.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isActive ? tint.opacity(0.9) : Color.white.opacity(0.12))
            )
            .foregroundStyle(isActive ? Color.white : tint)
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.4 : 1)
    }
}
