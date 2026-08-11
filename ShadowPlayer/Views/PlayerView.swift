import SwiftUI

/// Playback screen: video + scrubber (with A/B markers) + transport controls + A/B/C loop buttons.
struct PlayerView: View {
    let video: PickedVideo
    /// Called when playback starts (used to update the recent list).
    var onStart: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = PlayerViewModel()
    @StateObject private var pip = PictureInPictureManager()
    @State private var isFullscreen = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            PlayerLayerView(player: vm.player, pip: pip)
                .ignoresSafeArea()

            // Top-left: back plus the low-frequency controls, kept out of the
            // thumb's main path so the bottom bar stays dedicated to playback.
            // Same cluster in both orientations, so fullscreen can go back too.
            VStack {
                HStack(spacing: 12) {
                    backButton
                    speedMenu
                    if pip.isSupported { pipButton }
                    fullscreenButton
                    Spacer()
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            // Controls stay visible (landscape uses a right-side column to avoid covering subtitles)
            if isFullscreen {
                landscapeControls
            } else {
                controls
            }
        }
        // The custom back button above replaces the system one in both orientations.
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .statusBarHidden(isFullscreen)
        .onAppear {
            vm.load(video: video)
            onStart()
        }
        .onDisappear {
            vm.cleanup()
            Orientation.set(.portrait) // restore portrait when leaving the player
        }
    }

    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .padding(10)
                .background(Color.black.opacity(0.45), in: Circle())
        }
    }

    private var speedMenu: some View {
        Menu {
            ForEach(vm.rateOptions, id: \.self) { rate in
                Button {
                    vm.setRate(rate)
                } label: {
                    if vm.playbackRate == rate {
                        Label(rateText(rate), systemImage: "checkmark")
                    } else {
                        Text(rateText(rate))
                    }
                }
            }
        } label: {
            Text(rateText(vm.playbackRate))
                .font(.system(size: 14, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(vm.playbackRate == 1.0 ? .white : Color.accentColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color.black.opacity(0.45), in: Capsule())
        }
    }

    private func rateText(_ rate: Float) -> String {
        String(format: "%.1f×", rate)
    }

    private var pipButton: some View {
        Button {
            pip.toggle()
        } label: {
            Image(systemName: pip.isActive
                  ? "pip.exit"
                  : "pip.enter")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .padding(10)
                .background(Color.black.opacity(0.45), in: Circle())
        }
        .disabled(!pip.isPossible)
        .opacity(pip.isPossible ? 1 : 0.4)
    }

    private var fullscreenButton: some View {
        Button {
            toggleFullscreen()
        } label: {
            Image(systemName: isFullscreen
                  ? "arrow.down.right.and.arrow.up.left"
                  : "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .padding(10)
                .background(Color.black.opacity(0.45), in: Circle())
        }
    }

    private func toggleFullscreen() {
        isFullscreen.toggle()
        Orientation.set(isFullscreen ? .landscape : .portrait)
    }

    // MARK: - Controls layer

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

    // MARK: - Landscape layout: scrubber pinned to bottom, controls on the right, video/subtitles in the middle

    private var landscapeControls: some View {
        ZStack {
            // Right-side vertical control panel (vertically centered)
            HStack {
                Spacer()
                VStack(spacing: 12) {
                    if vm.isLooping {
                        Label("A-B Loop", systemImage: "repeat")
                            .font(.caption2)
                            .foregroundStyle(.tint)
                    }

                    HStack(spacing: 12) {
                        SeekButton(
                            systemImage: "backward.fill",
                            compact: true,
                            onTap: { vm.seekBy(-vm.seekStep) },
                            onHold: { holding in holding ? vm.startScan(forward: false) : vm.stopScan() }
                        )
                        Button {
                            vm.playPause()
                        } label: {
                            Image(systemName: vm.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 30))
                                .frame(width: 44, height: 44)
                        }
                        SeekButton(
                            systemImage: "forward.fill",
                            compact: true,
                            onTap: { vm.seekBy(vm.seekStep) },
                            onHold: { holding in holding ? vm.startScan(forward: true) : vm.stopScan() }
                        )
                    }
                    .foregroundStyle(.white)

                    abColumn
                }
                .frame(width: 180)
                .padding(.vertical, 14)
                .padding(.horizontal, 12)
                .background(Color.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .padding(.trailing, 16)

            // Slim scrubber at the bottom
            VStack {
                Spacer()
                VStack(spacing: 4) {
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
                        Text(formatTime(vm.duration))
                    }
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
        }
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
                    Label("A-B Loop", systemImage: "repeat")
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

    /// Portrait: three buttons in a row.
    private var abRow: some View {
        HStack(spacing: 10) { abButtons }
    }

    /// Landscape: three buttons in a column (right-side panel).
    private var abColumn: some View {
        VStack(spacing: 10) { abButtons }
    }

    @ViewBuilder
    private var abButtons: some View {
        ABButton(
            title: "Set A",
            systemImage: "a.circle.fill",
            tint: .green,
            isActive: vm.pointA != nil
        ) {
            vm.setPointA()
        }

        ABButton(
            title: "Set B",
            systemImage: "b.circle.fill",
            tint: .orange,
            isActive: vm.pointB != nil,
            isDisabled: vm.pointA == nil
        ) {
            vm.setPointB()
        }

        ABButton(
            title: "Cancel",
            systemImage: "xmark.circle.fill",
            tint: .red,
            isActive: false,
            isDisabled: vm.pointA == nil && vm.pointB == nil
        ) {
            vm.cancelAB()
        }
    }
}

/// Seek button: tap jumps 3 seconds, press-and-hold scans continuously, release stops.
private struct SeekButton: View {
    let systemImage: String
    var compact: Bool = false
    let onTap: () -> Void
    /// Hold state change: true = start scanning, false = stop.
    let onHold: (Bool) -> Void

    @State private var isPressing = false
    @State private var didHold = false
    @State private var holdWork: DispatchWorkItem?

    private let holdDelay = 0.35

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: systemImage)
                .font(.system(size: compact ? 22 : 28))
            if !compact {
                Text("3s")
                    .font(.system(size: 10, weight: .semibold))
                    .opacity(0.7)
            }
        }
        .foregroundStyle(.white)
        .scaleEffect(isPressing ? 1.15 : 1)
        .animation(.easeOut(duration: 0.12), value: isPressing)
        .contentShape(Rectangle())
        .frame(width: compact ? 44 : 60, height: compact ? 44 : 56)
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

/// A / B / C button style.
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
