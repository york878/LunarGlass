//
//  LunarGlassWidget.swift
//  LunarGlassWidget
//
//  Created by York on 2026/5/5.
//

import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
    private let calendarService = CalendarService()

    func placeholder(in context: Context) -> CalendarEntry {
        CalendarEntry(date: Date(), events: [:], holidays: [:], workdays: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> Void) {
        let now = Date()
        let events = calendarService.fetchEvents(from: startOfMonth(now), to: endOfMonth(now))
        let holidays = calendarService.fetchHolidays(from: startOfMonth(now), to: endOfMonth(now))
        let workdays = calendarService.fetchWorkdays(from: startOfMonth(now), to: endOfMonth(now))
        completion(CalendarEntry(date: now, events: events, holidays: holidays, workdays: workdays))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarEntry>) -> Void) {
        let now = Date()
        let monthStart = startOfMonth(now)
        let monthEnd = endOfMonth(now)

        let events = calendarService.fetchEvents(from: monthStart, to: monthEnd)
        let holidays = calendarService.fetchHolidays(from: monthStart, to: monthEnd)
        let workdays = calendarService.fetchWorkdays(from: monthStart, to: monthEnd)

        let nextMidnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
        )

        completion(Timeline(
            entries: [CalendarEntry(date: now, events: events, holidays: holidays, workdays: workdays)],
            policy: .after(nextMidnight)
        ))
    }

    private func startOfMonth(_ date: Date) -> Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: date)
        return cal.date(from: comps) ?? date
    }

    private func endOfMonth(_ date: Date) -> Date {
        let cal = Calendar.current
        guard let start = cal.date(from: cal.dateComponents([.year, .month], from: date)),
              let end = cal.date(byAdding: DateComponents(month: 1, day: -1), to: start) else {
            return date
        }
        return cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: end) ?? end)
    }
}

struct CalendarEntry: TimelineEntry {
    let date: Date
    let events: [Date: Int]
    let holidays: [Date: String]
    let workdays: Set<Date>
}

struct LunarGlassWidgetEntryView: View {
    let entry: CalendarEntry

    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme

    private let model = MonthModel()

    var body: some View {
        Group {
            if family == .systemMedium {
                mediumBody
            } else {
                largeBody
            }
        }
    }

    private var mediumBody: some View {
        let month = model.month(for: entry.date, events: entry.events, holidays: entry.holidays, workdays: entry.workdays)
        let week = model.week(for: entry.date, events: entry.events, holidays: entry.holidays, workdays: entry.workdays)

        return VStack(alignment: .leading, spacing: 12) {
            header(for: month)
            mediumWeekStrip(week)
        }
        .padding(14)
    }

    private var largeBody: some View {
        let month = model.month(for: entry.date, events: entry.events, holidays: entry.holidays, workdays: entry.workdays)

        return VStack(alignment: .leading, spacing: 8) {
            header(for: month)
            weekdayHeader
            calendarGrid(month.days)
        }
        .padding(14)
    }

    private func header(for month: MonthSnapshot) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(month.title)
                    .font(.system(size: family == .systemLarge ? 20 : 18, weight: .semibold))
                    .foregroundStyle(headerColor)
                Text(month.subtitle)
                    .font(.system(size: family == .systemLarge ? 10 : 9, weight: .medium))
                    .foregroundStyle(secondaryTextColor)
            }

            Spacer()
        }
    }

    private func mediumWeekStrip(_ days: [DaySnapshot]) -> some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 0) {
            GridRow {
                ForEach(days, id: \.date) { day in
                    mediumDayCard(day)
                }
            }
        }
    }

    private func mediumDayCard(_ day: DaySnapshot) -> some View {
        VStack(spacing: 5) {
            Text(day.weekdayText)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(day.isWeekend ? weekendColor : secondaryTextColor)

            Text(day.dayText)
                .font(.system(size: day.isToday ? 21 : 18, weight: day.isToday ? .bold : .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(day.isToday ? Color.white : dayTextColor(day))
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(day.isToday ? todayAccent : .clear)
                )

            if day.eventCount > 0 {
                eventDots(count: day.eventCount)
            }

            if day.isWorkday {
                Text("班")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(todayAccent)
            } else {
                Text(day.note)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .foregroundStyle(day.isHoliday ? weekendColor : secondaryTextColor)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 76)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(day.isToday ? todayAccent.opacity(0.10) : Color.clear)
        )
    }

    private var weekdayHeader: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            GridRow {
                ForEach(MonthModel.weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(weekday == "六" || weekday == "日" ? weekendColor : secondaryTextColor)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func calendarGrid(_ days: [DaySnapshot]) -> some View {
        Grid(horizontalSpacing: 0, verticalSpacing: family == .systemLarge ? 5 : 4) {
            ForEach(0..<6, id: \.self) { row in
                GridRow {
                    ForEach(0..<7, id: \.self) { column in
                        let day = days[row * 7 + column]
                        dayCell(day)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func dayCell(_ day: DaySnapshot) -> some View {
        VStack(spacing: family == .systemLarge ? 2 : 1) {
            Text(day.dayText)
                .font(.system(size: family == .systemLarge ? 16 : 13, weight: day.isToday ? .bold : .medium, design: .rounded))
                .monospacedDigit()
                .frame(width: family == .systemLarge ? 25 : 22, height: family == .systemLarge ? 25 : 22)
                .background(todayBackground(for: day))
                .foregroundStyle(dayTextColor(day))

            if day.eventCount > 0 {
                eventDots(count: day.eventCount)
            }

            if day.isWorkday {
                Text("班")
                    .font(.system(size: family == .systemLarge ? 9 : 7, weight: .bold))
                    .foregroundStyle(todayAccent)
                    .frame(maxWidth: .infinity)
            } else {
                Text(day.note)
                    .font(.system(size: family == .systemLarge ? 9 : 7, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .foregroundStyle(day.isCurrentMonth ? noteColor(day) : mutedTextColor)
                    .frame(maxWidth: .infinity)
            }
        }
        .opacity(day.isCurrentMonth ? 1 : 0.42)
    }

    private var weekendColor: Color {
        todayAccent
    }

    private var todayAccent: Color {
        let defaults = UserDefaults(suiteName: "group.com.york.LunarGlass")
        let style = defaults?.string(forKey: "accentStyle") ?? ""
        switch style {
        case "vermilion":
            return Color(red: 1.0, green: 0.36, blue: 0.32)
        case "gold":
            return Color(red: 0.94, green: 0.65, blue: 0.22)
        default:
            return Color(red: 0.15, green: 0.68, blue: 0.54)
        }
    }

    private var headerColor: Color {
        .primary
    }

    private var bodyTextColor: Color {
        .primary
    }

    private var secondaryTextColor: Color {
        .secondary
    }

    private var mutedTextColor: Color {
        .secondary.opacity(0.4)
    }

    private func dayTextColor(_ day: DaySnapshot) -> Color {
        if day.isToday {
            return .white
        }

        return bodyTextColor
    }

    private func noteColor(_ day: DaySnapshot) -> Color {
        day.isHoliday ? todayAccent : secondaryTextColor
    }

    @ViewBuilder
    private func todayBackground(for day: DaySnapshot) -> some View {
        if day.isToday {
            Circle().fill(todayAccent)
        }
    }

    private func eventDots(count: Int) -> some View {
        HStack(spacing: 3) {
            ForEach(0..<min(count, 3), id: \.self) { _ in
                Circle()
                    .fill(todayAccent)
                    .frame(width: 4, height: 4)
            }
        }
    }
}

struct LunarGlassWidget: Widget {
    let kind = "LunarGlassWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(macOS 14.0, *) {
                LunarGlassWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        WidgetBackground()
                    }
            } else {
                LunarGlassWidgetEntryView(entry: entry)
                    .padding()
                    .background(WidgetBackground())
            }
        }
        .configurationDisplayName("LunarGlass")
        .description("透明玻璃风桌面月历，显示公历、农历和节日。")
        .supportedFamilies([.systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

private struct WidgetBackground: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.thinMaterial)

            LinearGradient(
                colors: [
                    Color(red: 0.56, green: 0.54, blue: 0.72).opacity(0.10),
                    Color(red: 0.48, green: 0.50, blue: 0.68).opacity(0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

#Preview(as: .systemMedium) {
    LunarGlassWidget()
} timeline: {
    CalendarEntry(date: Date(), events: [:], holidays: [:], workdays: [])
}

#Preview(as: .systemLarge) {
    LunarGlassWidget()
} timeline: {
    CalendarEntry(date: Date(), events: [:], holidays: [:], workdays: [])
}
