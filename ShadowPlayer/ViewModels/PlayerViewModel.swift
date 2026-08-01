import AVFoundation
import Combine

/// 播放器核心逻辑：加载视频、播放控制、A-B 无限循环、长按连续快进/快退。
final class PlayerViewModel: ObservableObject {
    let player = AVPlayer()

    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isReady = false

    /// A-B 循环的起点 / 终点（秒）。只设 A 不循环；A、B 都有才循环。
    @Published var pointA: Double?
    @Published var pointB: Double?

    /// 短按快进 / 快退步长（秒）。
    let seekStep: Double = 3

    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var scanTimer: Timer?
    private var wasPlayingBeforeScan = false

    var isLooping: Bool { pointA != nil && pointB != nil }

    // MARK: - 加载

    func load(video: PickedVideo) {
        duration = video.duration
        configureAudioSession()

        let item = AVPlayerItem(url: video.url)
        player.replaceCurrentItem(with: item)
        addObservers(for: item)
        player.play()
        isPlaying = true
        isReady = true
    }

    /// 设为 .playback：即使手机侧边静音拨片打开也能出声。
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .moviePlayback)
        try? session.setActive(true)
    }

    private func addObservers(for item: AVPlayerItem) {
        let interval = CMTime(seconds: 0.2, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            let t = time.seconds
            if t.isFinite { self.currentTime = t }

            // 时长兜底：若选取时没拿到时长，从 player 补上。
            if self.duration <= 0, let d = self.player.currentItem?.duration.seconds, d.isFinite, d > 0 {
                self.duration = d
            }

            // A-B 循环：播到 B 就跳回 A。
            if let a = self.pointA, let b = self.pointB, t >= b - 0.03 {
                self.preciseSeek(to: a)
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.isPlaying = false
        }
    }

    // MARK: - 播放控制

    func playPause() {
        if isPlaying {
            player.pause()
        } else {
            if duration > 0, currentTime >= duration - 0.1 {
                preciseSeek(to: 0)
            }
            player.play()
        }
        isPlaying.toggle()
    }

    /// 短按：精确跳 delta 秒。
    func seekBy(_ delta: Double) {
        seek(to: currentTime + delta)
    }

    func seek(to time: Double) {
        preciseSeek(to: clamp(time))
    }

    private func preciseSeek(to time: Double) {
        let target = CMTime(seconds: time, preferredTimescale: 600)
        currentTime = time
        player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    private func clamp(_ time: Double) -> Double {
        max(0, min(time, duration > 0 ? duration : time))
    }

    // MARK: - 长按连续快进/快退

    /// 长按开始：每 0.1s 跳约 0.5s，即约 5 倍速扫描。
    func startScan(forward: Bool) {
        wasPlayingBeforeScan = isPlaying
        player.pause()
        isPlaying = false
        scanTimer?.invalidate()
        scanTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            let delta: Double = forward ? 0.5 : -0.5
            let target = self.clamp(self.currentTime + delta)
            self.currentTime = target
            // 扫描用容差 seek，更流畅。
            self.player.seek(
                to: CMTime(seconds: target, preferredTimescale: 600),
                toleranceBefore: CMTime(seconds: 0.25, preferredTimescale: 600),
                toleranceAfter: CMTime(seconds: 0.25, preferredTimescale: 600)
            )
        }
    }

    /// 松手：停止扫描，恢复之前的播放状态。
    func stopScan() {
        scanTimer?.invalidate()
        scanTimer = nil
        if wasPlayingBeforeScan {
            player.play()
            isPlaying = true
        }
    }

    // MARK: - A / B / C

    /// 设 A 起点。若已有 B 且 B <= A，则清除 B。
    func setPointA() {
        pointA = currentTime
        if let b = pointB, b <= currentTime { pointB = nil }
    }

    /// 设 B 终点。必须先有 A，且 B 要在 A 之后。
    func setPointB() {
        guard let a = pointA, currentTime > a else { return }
        pointB = currentTime
    }

    /// 取消循环，从当前位置继续正常播放。
    func cancelAB() {
        pointA = nil
        pointB = nil
    }

    // MARK: - 清理

    func cleanup() {
        scanTimer?.invalidate()
        scanTimer = nil
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        player.pause()
        player.replaceCurrentItem(with: nil)
    }
}
