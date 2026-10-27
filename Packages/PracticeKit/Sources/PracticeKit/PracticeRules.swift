import Foundation

/// The two languages the check-in tracks. Raw values match the app's audio
/// language tags, so mapping from a playlist's setting is a lookup.
public enum PracticeLanguage: String, Codable, CaseIterable, Sendable {
    case english = "en"
    case japanese = "ja"
}

/// One stretch of video that was looped enough times to count as close
/// reading. Recorded once, when the loop reaches the required count.
public struct PracticeSegment: Codable, Equatable, Sendable {
    public let day: DayKey
    public let videoID: String
    public let language: PracticeLanguage
    /// Video time, in seconds.
    public let start: Double
    public let end: Double

    public init(day: DayKey, videoID: String, language: PracticeLanguage, start: Double, end: Double) {
        self.day = day
        self.videoID = videoID
        self.language = language
        self.start = start
        self.end = end
    }
}

/// How much of each language a day covered, in seconds of video.
public struct DaySummary: Equatable, Sendable {
    public var english: Double = 0
    public var japanese: Double = 0

    public init(english: Double = 0, japanese: Double = 0) {
        self.english = english
        self.japanese = japanese
    }

    public func seconds(for language: PracticeLanguage) -> Double {
        switch language {
        case .english: return english
        case .japanese: return japanese
        }
    }

    public func isComplete(_ language: PracticeLanguage) -> Bool {
        seconds(for: language) >= PracticeRules.goalSeconds
    }
}

/// How the calendar shows one day.
public enum DayMark: Equatable, Sendable {
    /// Before the check-in existed: nothing to show.
    case blank
    /// Still to come.
    case upcoming
    /// Today, or a past day where at least one language was done. Each half
    /// of the circle is coloured when its language is complete.
    case progress(english: Bool, japanese: Bool)
    /// A past day where neither language was done.
    case missed
}

public enum PracticeRules {
    /// Seconds of video each language needs per day.
    public static let goalSeconds: Double = 5 * 60

    /// Loops finished between these hours count; the rest of the night doesn't.
    public static let countingHours = 5..<23

    /// The day a loop finished at `date` counts toward, or nil outside the
    /// counting hours.
    public static func countingDay(for date: Date, calendar: Calendar = .current) -> DayKey? {
        let hour = calendar.component(.hour, from: date)
        guard countingHours.contains(hour) else { return nil }
        return DayKey(date, calendar: calendar)
    }

    /// Total length of the given segments, counting overlapping stretches of
    /// the same video once. Gaps between segments are not filled.
    public static func coveredSeconds(_ segments: [PracticeSegment]) -> Double {
        Dictionary(grouping: segments, by: \.videoID).values.reduce(0) { total, videoSegments in
            total + unionLength(videoSegments.map { ($0.start, $0.end) })
        }
    }

    /// Each day's totals. Every day stands alone, so a stretch looped again on
    /// a later day counts again.
    public static func summaries(_ segments: [PracticeSegment]) -> [DayKey: DaySummary] {
        Dictionary(grouping: segments, by: \.day).mapValues { daySegments in
            let byLanguage = Dictionary(grouping: daySegments, by: \.language)
            return DaySummary(
                english: coveredSeconds(byLanguage[.english] ?? []),
                japanese: coveredSeconds(byLanguage[.japanese] ?? [])
            )
        }
    }

    public static func mark(for day: DayKey, today: DayKey, trackingSince: DayKey, summary: DaySummary?) -> DayMark {
        if day > today { return .upcoming }
        if day < trackingSince { return .blank }
        let english = summary?.isComplete(.english) ?? false
        let japanese = summary?.isComplete(.japanese) ?? false
        if day < today, !english, !japanese { return .missed }
        return .progress(english: english, japanese: japanese)
    }

    private static func unionLength(_ intervals: [(Double, Double)]) -> Double {
        let sorted = intervals.filter { $0.1 > $0.0 }.sorted { $0.0 < $1.0 }
        var total = 0.0
        var current: (Double, Double)?
        for interval in sorted {
            if let c = current, interval.0 <= c.1 {
                current = (c.0, max(c.1, interval.1))
            } else {
                if let c = current { total += c.1 - c.0 }
                current = interval
            }
        }
        if let c = current { total += c.1 - c.0 }
        return total
    }
}
