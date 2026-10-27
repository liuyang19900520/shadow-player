import Foundation
import PracticeKit

/// Counts completed loops of the current A-B range and, on the loop that
/// makes it close reading, records the range in the practice log. Counted on
/// its own rather than through `LoopCaptureModel`, which only counts when
/// speech recognition is available.
@MainActor
final class PracticeTracker: ObservableObject {
    private let videoID: String
    private let log: PracticeLogStore

    private var range: ClosedRange<Double>?
    private var loops = 0

    init(videoID: String, log: PracticeLogStore = .shared) {
        self.videoID = videoID
        self.log = log
    }

    /// A or B moved, or the loop was cancelled: a new range starts from zero.
    func loopChanged(a: Double?, b: Double?) {
        loops = 0
        if let a, let b, b > a {
            range = a...b
        } else {
            range = nil
        }
    }

    func loopCompleted(now: Date = Date()) {
        guard let range else { return }
        loops += 1
        // Exactly once per range: further loops of the same stretch add nothing.
        guard loops == LoopCaptureModel.loopsBeforeOffer else { return }

        // The language is read now, not when the player opened, so choosing
        // it mid-session still counts this loop. Videos outside any playlist
        // don't count, even if the shared default has a language set.
        guard
            TranslationScope.isInPlaylist(videoID),
            let language = PracticeLanguage(TranslationScope.forVideo(videoID).audioLanguage),
            let day = PracticeRules.countingDay(for: now)
        else { return }

        log.add(PracticeSegment(
            day: day,
            videoID: videoID,
            language: language,
            start: range.lowerBound,
            end: range.upperBound
        ))
    }
}
