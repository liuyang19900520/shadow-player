import XCTest
@testable import PracticeKit

private let today = DayKey(year: 2026, month: 10, day: 19)

private func segment(_ start: Double, _ end: Double, video: String = "v1",
                     _ language: PracticeLanguage = .english, day: DayKey = today) -> PracticeSegment {
    PracticeSegment(day: day, videoID: video, language: language, start: start, end: end)
}

final class PracticeRulesTests: XCTestCase {
    private var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return c
    }()

    private func date(hour: Int, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 19, hour: hour, minute: minute))!
    }

    // MARK: - Covered time

    func testOverlappingLoopsCountOnce() {
        // 3:30–3:45, 3:45–4:10, then 3:40–3:50 again: 3:30–4:10 = 40s.
        let segments = [segment(210, 225), segment(225, 250), segment(220, 230)]
        XCTAssertEqual(PracticeRules.coveredSeconds(segments), 40, accuracy: 0.001)
    }

    func testGapsAreNotFilled() {
        let segments = [segment(210, 225), segment(230, 245)]
        XCTAssertEqual(PracticeRules.coveredSeconds(segments), 30, accuracy: 0.001)
    }

    func testDifferentVideosDoNotOverlap() {
        let segments = [segment(0, 60, video: "a"), segment(0, 60, video: "b")]
        XCTAssertEqual(PracticeRules.coveredSeconds(segments), 120, accuracy: 0.001)
    }

    func testContainedLoopAddsNothing() {
        let segments = [segment(100, 200), segment(120, 150)]
        XCTAssertEqual(PracticeRules.coveredSeconds(segments), 100, accuracy: 0.001)
    }

    func testEmptyOrBackwardsSegmentsCountZero() {
        XCTAssertEqual(PracticeRules.coveredSeconds([]), 0)
        XCTAssertEqual(PracticeRules.coveredSeconds([segment(50, 40)]), 0)
    }

    // MARK: - Days

    func testEachDayStandsAlone() {
        let yesterday = today.adding(days: -1, calendar: calendar)
        let summaries = PracticeRules.summaries([
            segment(0, 600, day: yesterday),
            segment(0, 600, day: today),
            segment(0, 300, video: "j", .japanese, day: today),
        ])
        XCTAssertEqual(summaries[yesterday], DaySummary(english: 600))
        XCTAssertEqual(summaries[today], DaySummary(english: 600, japanese: 300))
    }

    func testFifteenMinutesCompletesALanguage() {
        XCTAssertTrue(DaySummary(english: 900).isComplete(.english))
        XCTAssertFalse(DaySummary(english: 899).isComplete(.english))
        XCTAssertFalse(DaySummary(english: 900).isComplete(.japanese))
    }

    func testCountingHours() {
        XCTAssertNil(PracticeRules.countingDay(for: date(hour: 4, minute: 59), calendar: calendar))
        XCTAssertEqual(PracticeRules.countingDay(for: date(hour: 5), calendar: calendar), today)
        XCTAssertEqual(PracticeRules.countingDay(for: date(hour: 22, minute: 59), calendar: calendar), today)
        XCTAssertNil(PracticeRules.countingDay(for: date(hour: 23), calendar: calendar))
    }

    func testDayKeyArithmeticCrossesMonths() {
        let oct1 = DayKey(year: 2026, month: 10, day: 1)
        XCTAssertEqual(oct1.adding(days: -1, calendar: calendar), DayKey(year: 2026, month: 9, day: 30))
        XCTAssertLessThan(DayKey(year: 2026, month: 9, day: 30), oct1)
        XCTAssertEqual(oct1.description, "2026-10-01")
    }

    // MARK: - Marks

    func testMarks() {
        let since = DayKey(year: 2026, month: 10, day: 5)
        let past = DayKey(year: 2026, month: 10, day: 10)
        func mark(_ day: DayKey, _ summary: DaySummary?) -> DayMark {
            PracticeRules.mark(for: day, today: today, trackingSince: since, summary: summary)
        }

        XCTAssertEqual(mark(DayKey(year: 2026, month: 10, day: 4), nil), .blank)
        XCTAssertEqual(mark(DayKey(year: 2026, month: 10, day: 20), nil), .upcoming)
        XCTAssertEqual(mark(past, nil), .missed)
        XCTAssertEqual(mark(past, DaySummary(english: 300, japanese: 300)), .missed)
        XCTAssertEqual(mark(past, DaySummary(english: 900)), .progress(english: true, japanese: false))
        XCTAssertEqual(mark(past, DaySummary(english: 900, japanese: 900)), .progress(english: true, japanese: true))
        // Today is never missed while it is still going.
        XCTAssertEqual(mark(today, nil), .progress(english: false, japanese: false))
    }
}
