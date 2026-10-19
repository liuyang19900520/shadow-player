import Foundation
import PracticeKit

/// Every close-reading segment ever recorded, persisted as one JSON file in
/// Application Support. Shared, so the player writes to the same log the home
/// screen and calendar read.
final class PracticeLogStore: ObservableObject {
    static let shared = PracticeLogStore()

    @Published private(set) var segments: [PracticeSegment] = []
    /// Each day's totals, rebuilt whenever a segment is added.
    @Published private(set) var summaries: [DayKey: DaySummary] = [:]

    /// The first day the check-in existed on this phone. Earlier days are
    /// left blank rather than marked missed.
    let trackingSince: DayKey

    private static let trackingSinceKey = "practiceTrackingSince"

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("practice-log.json")
    }()

    private init() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: Self.trackingSinceKey),
           let stored = try? JSONDecoder().decode(DayKey.self, from: data) {
            trackingSince = stored
        } else {
            trackingSince = DayKey(Date())
            defaults.set(try? JSONEncoder().encode(trackingSince), forKey: Self.trackingSinceKey)
        }

        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([PracticeSegment].self, from: data) {
            segments = decoded
        }
        summaries = PracticeRules.summaries(segments)
    }

    func add(_ segment: PracticeSegment) {
        segments.append(segment)
        summaries = PracticeRules.summaries(segments)
        if let data = try? JSONEncoder().encode(segments) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    func summary(for day: DayKey) -> DaySummary {
        summaries[day] ?? DaySummary()
    }

    func mark(for day: DayKey, today: DayKey = DayKey(Date())) -> DayMark {
        PracticeRules.mark(for: day, today: today, trackingSince: trackingSince, summary: summaries[day])
    }
}

extension PracticeLanguage {
    /// The check-in language for a playlist's audio language, or nil for the
    /// languages it doesn't track.
    init?(_ language: TranslationLanguage?) {
        switch language {
        case .english: self = .english
        case .japanese: self = .japanese
        default: return nil
        }
    }

    var label: String {
        switch self {
        case .english: return "English"
        case .japanese: return "日本語"
        }
    }
}
