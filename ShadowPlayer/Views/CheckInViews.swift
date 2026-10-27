import SwiftUI
import UIKit
import PracticeKit

// MARK: - Style

enum CheckInStyle {
    /// Top half. Deep navy, lifted to a lighter blue in dark mode so it
    /// still reads against a black background.
    static let english = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0x85 / 255, green: 0xB7 / 255, blue: 0xEB / 255, alpha: 1)
            : UIColor(red: 0x0C / 255, green: 0x44 / 255, blue: 0x7C / 255, alpha: 1)
    })
    /// Bottom half. Near-black ink, near-white in dark mode.
    static let japanese = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0xE8 / 255, green: 0xE6 / 255, blue: 0xDF / 255, alpha: 1)
            : UIColor(red: 0x2C / 255, green: 0x2C / 255, blue: 0x2A / 255, alpha: 1)
    })
    static let pending = Color(.systemGray5)

    static func color(for language: PracticeLanguage) -> Color {
        language == .english ? english : japanese
    }
}

/// Whole minutes, rounded down, so "15" only shows once the goal is met.
func practiceMinutes(_ seconds: Double) -> Int { Int(seconds / 60) }

// MARK: - Circle

private struct HalfCircle: Shape {
    let top: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addArc(center: center, radius: min(rect.width, rect.height) / 2,
                    startAngle: .degrees(180), endAngle: .degrees(0), clockwise: !top)
        path.closeSubpath()
        return path
    }
}

/// One day's mark: top half English, bottom half Japanese, coloured when
/// that language was done; × for a missed day; dashed for days to come.
struct CheckInCircle: View {
    let mark: DayMark
    var size: CGFloat = 28

    var body: some View {
        Group {
            switch mark {
            case .blank:
                Color.clear
            case .upcoming:
                Circle()
                    .strokeBorder(Color(.systemGray3), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
            case .missed:
                Image(systemName: "xmark")
                    .font(.system(size: size * 0.45, weight: .semibold))
                    .foregroundStyle(.tertiary)
            case let .progress(english, japanese):
                ZStack {
                    HalfCircle(top: true).fill(english ? CheckInStyle.english : CheckInStyle.pending)
                    HalfCircle(top: false).fill(japanese ? CheckInStyle.japanese : CheckInStyle.pending)
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        switch mark {
        case .blank, .upcoming: return ""
        case .missed: return "Missed"
        case let .progress(english, japanese):
            switch (english, japanese) {
            case (true, true): return "English and Japanese done"
            case (true, false): return "English done"
            case (false, true): return "Japanese done"
            case (false, false): return "Not done yet"
            }
        }
    }
}

// MARK: - Home card

/// Today's progress and this week's marks. Sits at the top of Home and
/// leads to the calendar.
struct TodayCard: View {
    @ObservedObject var log: PracticeLogStore

    private var calendar: Calendar { .current }

    var body: some View {
        let today = DayKey(Date())
        let summary = log.summary(for: today)

        VStack(spacing: 14) {
            HStack(spacing: 14) {
                CheckInCircle(mark: log.mark(for: today, today: today), size: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Today")
                        .font(.headline)
                    ForEach(PracticeLanguage.allCases, id: \.self) { language in
                        progressLine(language, summary)
                    }
                }
                Spacer()
            }

            HStack(spacing: 0) {
                ForEach(weekDays(containing: today), id: \.self) { day in
                    VStack(spacing: 4) {
                        Text(weekdaySymbol(day))
                            .font(.caption2)
                            .foregroundStyle(day == today ? Color.accentColor : .secondary)
                        CheckInCircle(mark: log.mark(for: day, today: today), size: 18)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func progressLine(_ language: PracticeLanguage, _ summary: DaySummary) -> some View {
        HStack(spacing: 4) {
            Text(language.label)
            Text("\(min(practiceMinutes(summary.seconds(for: language)), 999)) / 5 min")
                .monospacedDigit()
            if summary.isComplete(language) {
                Image(systemName: "checkmark")
                    .foregroundStyle(CheckInStyle.color(for: language))
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private func weekDays(containing day: DayKey) -> [DayKey] {
        let date = day.startDate(in: calendar)
        guard let start = calendar.dateInterval(of: .weekOfYear, for: date)?.start else { return [day] }
        let first = DayKey(start, calendar: calendar)
        return (0..<7).map { first.adding(days: $0, calendar: calendar) }
    }

    private func weekdaySymbol(_ day: DayKey) -> String {
        let weekday = calendar.component(.weekday, from: day.startDate(in: calendar))
        return calendar.veryShortWeekdaySymbols[weekday - 1]
    }
}

// MARK: - Calendar

/// A month of check-in marks. Tap a day to see its minutes and new words.
struct CheckInCalendarView: View {
    @ObservedObject var log: PracticeLogStore

    @State private var month: DayKey = {
        let today = DayKey(Date())
        return DayKey(year: today.year, month: today.month, day: 1)
    }()
    @State private var selectedDay: DayKey?

    private var calendar: Calendar { .current }
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        let today = DayKey(Date())

        List {
            Section {
                VStack(spacing: 16) {
                    monthHeader(today: today)
                    grid(today: today)
                }
                .padding(.vertical, 8)
            }

            Section {
                HStack {
                    Text("Days done this month")
                    Spacer()
                    Text("\(daysDone(today: today))")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            } footer: {
                legend
            }
        }
        .navigationTitle("Check-in")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedDay) { day in
            CheckInDayView(day: day, log: log)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private func monthHeader(today: DayKey) -> some View {
        let isCurrentMonth = month.year == today.year && month.month == today.month
        return HStack {
            Text(monthTitle)
                .font(.title3.weight(.semibold))
            Spacer()
            Button { shiftMonth(-1) } label: {
                Image(systemName: "chevron.left").frame(width: 36, height: 36)
            }
            .accessibilityLabel("Previous month")
            Button { shiftMonth(1) } label: {
                Image(systemName: "chevron.right").frame(width: 36, height: 36)
            }
            .disabled(isCurrentMonth)
            .accessibilityLabel("Next month")
        }
        .buttonStyle(.borderless)
    }

    private func grid(today: DayKey) -> some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Array(weekdayHeaders.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(0..<leadingBlanks, id: \.self) { _ in
                Color.clear.frame(height: 1)
            }
            ForEach(daysInMonth, id: \.self) { day in
                dayCell(day, today: today)
            }
        }
    }

    private func dayCell(_ day: DayKey, today: DayKey) -> some View {
        let mark = log.mark(for: day, today: today)
        let isToday = day == today
        let tappable = mark != .upcoming && mark != .blank

        return Button {
            selectedDay = day
        } label: {
            VStack(spacing: 4) {
                CheckInCircle(mark: mark, size: 28)
                    .overlay {
                        if isToday {
                            Circle()
                                .strokeBorder(Color.accentColor, lineWidth: 1.5)
                                .padding(-4)
                        }
                    }
                    .frame(width: 36, height: 36)
                Text(cellCaption(day, isToday: isToday))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(isToday ? Color.accentColor : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!tappable)
    }

    /// The date, except today, which shows its minutes so far (English·Japanese).
    private func cellCaption(_ day: DayKey, isToday: Bool) -> String {
        guard isToday else { return "\(day.day)" }
        let summary = log.summary(for: day)
        return "\(practiceMinutes(summary.english))·\(practiceMinutes(summary.japanese))m"
    }

    private var legend: some View {
        HStack(spacing: 16) {
            legendItem(CheckInStyle.english, top: true, "English")
            legendItem(CheckInStyle.japanese, top: false, "日本語")
            Label("Missed", systemImage: "xmark")
        }
        .font(.caption)
        .padding(.top, 4)
    }

    private func legendItem(_ color: Color, top: Bool, _ title: String) -> some View {
        HStack(spacing: 4) {
            ZStack {
                HalfCircle(top: top).fill(color)
                HalfCircle(top: !top).fill(CheckInStyle.pending)
            }
            .frame(width: 12, height: 12)
            Text(title)
        }
    }

    // MARK: Month maths

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("yMMMM")
        return formatter.string(from: month.startDate(in: calendar))
    }

    private var daysInMonth: [DayKey] {
        let count = calendar.range(of: .day, in: .month, for: month.startDate(in: calendar))?.count ?? 30
        return (0..<count).map { month.adding(days: $0, calendar: calendar) }
    }

    /// Empty cells before the 1st, so it lands under its weekday.
    private var leadingBlanks: Int {
        let weekday = calendar.component(.weekday, from: month.startDate(in: calendar))
        return (weekday - calendar.firstWeekday + 7) % 7
    }

    private var weekdayHeaders: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    private func daysDone(today: DayKey) -> Int {
        daysInMonth.filter { day in
            if case let .progress(english, japanese) = log.mark(for: day, today: today) {
                return english || japanese
            }
            return false
        }.count
    }

    private func shiftMonth(_ delta: Int) {
        let date = calendar.date(byAdding: .month, value: delta, to: month.startDate(in: calendar)) ?? month.startDate(in: calendar)
        month = DayKey(date, calendar: calendar)
    }
}

// MARK: - Day detail

/// One day's numbers, shown as a half-height sheet over the calendar.
struct CheckInDayView: View {
    let day: DayKey
    @ObservedObject var log: PracticeLogStore

    @State private var words: (total: Int, byLanguage: [PracticeLanguage: Int]) = (0, [:])

    var body: some View {
        let summary = log.summary(for: day)
        let isToday = day == DayKey(Date())

        NavigationStack {
            List {
                Section {
                    ForEach(PracticeLanguage.allCases, id: \.self) { language in
                        languageRow(language, summary)
                    }
                    HStack {
                        Label("New words", systemImage: "text.badge.plus")
                        Spacer()
                        Text("\(words.total)")
                            .monospacedDigit()
                            .fontWeight(.semibold)
                    }
                } footer: {
                    Text("A stretch counts once its A-B loop plays \(LoopCaptureModel.loopsBeforeOffer) times between 5:00 and 23:00. Each language needs 5 minutes of video a day.")
                }
            }
            .navigationTitle(title(isToday: isToday))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CheckInCircle(mark: log.mark(for: day), size: 24)
                }
            }
        }
        .task(id: day) { words = WordListIndex.wordsAdded(on: day) }
    }

    private func languageRow(_ language: PracticeLanguage, _ summary: DaySummary) -> some View {
        let done = summary.isComplete(language)
        return HStack {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(done ? CheckInStyle.color(for: language) : Color(.systemGray3))
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(language.label)
                Text("\(words.byLanguage[language] ?? 0) new words")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(practiceMinutes(summary.seconds(for: language))) min")
                .monospacedDigit()
                .fontWeight(.semibold)
        }
    }

    private func title(isToday: Bool) -> String {
        if isToday { return "Today" }
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMMdEEEE")
        return formatter.string(from: day.startDate())
    }
}
