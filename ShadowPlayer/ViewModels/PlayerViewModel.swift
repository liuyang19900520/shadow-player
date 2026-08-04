import AVFoundation
import Photos
import Combine

/// Core player logic: video loading, playback control, infinite A-B loop, and press-and-hold scanning.
final class PlayerViewModel: ObservableObject {
    let player = AVPlayer()

    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isReady = false

    /// A-B loop start / end (seconds). Setting only A does not loop; looping needs both A and B.
    @Published var pointA: Double?
    @Published var pointB: Double?

    /// Tap seek step for forward / backward (seconds).
    let seekStep: Double = 3

    /// Playback speed (0.8x–1.2x).
    @Published var playbackRate: Float = 1.0
    /// Available speed options.
    let rateOptions: [Float] = [0.8, 0.9, 1.0, 1.1, 1.2]

    func setRate(_ rate: Float) {
        playbackRate = rate
        if isPlaying { player.rate = rate }
    }

    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var scanTimer: Timer?
    private var wasPlayingBeforeScan = false

    /// Resume playback: tracks the current video identifier and the last saved progress.
    private var videoID = ""
    private var lastSavedProgress: Double = 0
    private let progressKeyPrefix = "progress_"
    private var progressKey: String { progressKeyPrefix + videoID }

    var isLooping: Bool { pointA != nil && pointB != nil }

    // MARK: - Loading

    func load(video: PickedVideo) {
        videoID = video.id
        duration = video.duration
        configureAudioSession()

        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [video.id], options: nil).firstObject else {
            return
        }
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .automatic

        let resume = resumePosition()

        PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { [weak self] item, _ in
            guard let self, let item else { return }
            DispatchQueue.main.async {
                item.audioTimePitchAlgorithm = .timeDomain // keep voice pitch natural when changing speed
                self.player.replaceCurrentItem(with: item)
                self.addObservers(for: item)
                // Resume from where it last stopped (start over if near the end).
                if resume > 1, self.duration <= 0 || resume < self.duration - 2 {
                    self.preciseSeek(to: resume)
                    self.lastSavedProgress = resume
                }
                self.player.rate = self.playbackRate
                self.isPlaying = true
                self.isReady = true
            }
        }
    }

    // MARK: - Resume playback

    private func resumePosition() -> Double {
        UserDefaults.standard.double(forKey: progressKey)
    }

    /// Saves the current progress; clears the record once playback reaches the end.
    private func saveProgress() {
        guard !videoID.isEmpty, currentTime.isFinite else { return }
        if duration > 0, currentTime >= duration - 2 {
            UserDefaults.standard.removeObject(forKey: progressKey)
        } else if currentTime > 1 {
            UserDefaults.standard.set(currentTime, forKey: progressKey)
        }
    }

    /// Use .playback so audio plays even when the hardware silent switch is on.
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

            // Duration fallback: if it wasn't available at pick time, fill it from the player.
            if self.duration <= 0, let d = self.player.currentItem?.duration.seconds, d.isFinite, d > 0 {
                self.duration = d
            }

            // A-B loop: jump back to A once playback reaches B.
            if let a = self.pointA, let b = self.pointB, t >= b - 0.03 {
                self.preciseSeek(to: a)
            }

            // Save progress every 5 seconds.
            if abs(t - self.lastSavedProgress) >= 5 {
                self.lastSavedProgress = t
                self.saveProgress()
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.isPlaying = false
            self.saveProgress() // clear progress on completion so it starts over next time
        }
    }

    // MARK: - Playback control

    func playPause() {
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            if duration > 0, currentTime >= duration - 0.1 {
                preciseSeek(to: 0)
            }
            player.rate = playbackRate
            isPlaying = true
        }
    }

    /// Tap: precisely jump by delta seconds.
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

    // MARK: - Press-and-hold continuous scan

    /// Hold begins: jump ~0.5s every 0.1s, i.e. roughly 5x scanning.
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
            // Use tolerant seek while scanning for smoother motion.
            self.player.seek(
                to: CMTime(seconds: target, preferredTimescale: 600),
                toleranceBefore: CMTime(seconds: 0.25, preferredTimescale: 600),
                toleranceAfter: CMTime(seconds: 0.25, preferredTimescale: 600)
            )
        }
    }

    /// Release: stop scanning and restore the previous playback state.
    func stopScan() {
        scanTimer?.invalidate()
        scanTimer = nil
        if wasPlayingBeforeScan {
            player.rate = playbackRate
            isPlaying = true
        }
    }

    // MARK: - A / B / C

    /// Set the A start point. Clears B if it already exists and B <= A.
    func setPointA() {
        pointA = currentTime
        if let b = pointB, b <= currentTime { pointB = nil }
    }

    /// Set the B end point. Requires A first, and B must be after A.
    func setPointB() {
        guard let a = pointA, currentTime > a else { return }
        pointB = currentTime
    }

    /// Cancel the loop and resume normal playback from the current position.
    func cancelAB() {
        pointA = nil
        pointB = nil
    }

    // MARK: - Cleanup

    func cleanup() {
        saveProgress() // save progress when leaving the player
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
