import Foundation

/// A calendar day, independent of time zone once made. Used as the key for
/// everything the check-in records, so a day stays the same day even if the
/// phone later travels to another zone.
public struct DayKey: Hashable, Comparable, Codable, Identifiable, CustomStringConvertible, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// The day `date` falls on in `calendar`.
    public init(_ date: Date, calendar: Calendar = .current) {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: c.year ?? 0, month: c.month ?? 0, day: c.day ?? 0)
    }

    /// Midnight at the start of this day in `calendar`.
    public func startDate(in calendar: Calendar = .current) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .distantPast
    }

    /// The day `days` later (or earlier, when negative).
    public func adding(days: Int, calendar: Calendar = .current) -> DayKey {
        let date = calendar.date(byAdding: .day, value: days, to: startDate(in: calendar)) ?? startDate(in: calendar)
        return DayKey(date, calendar: calendar)
    }

    public var id: String { description }

    public static func < (lhs: DayKey, rhs: DayKey) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    public var description: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }
}
