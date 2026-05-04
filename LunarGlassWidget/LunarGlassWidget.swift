//
//  LunarGlassWidget.swift
//  LunarGlassWidget
//
//  Created by York on 2026/5/5.
//

import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> CalendarEntry {
        CalendarEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> Void) {
        completion(CalendarEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarEntry>) -> Void) {
        let now = Date()
        let nextMidnight = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now)
        completion(Timeline(entries: [CalendarEntry(date: now)], policy: .after(nextMidnight)))
    }
}

struct CalendarEntry: TimelineEntry {
    let date: Date
}

struct LunarGlassWidgetEntryView: View {
    let entry: CalendarEntry

    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme

    private let model = MonthModel()

    var body: some View {
        if family == .systemMedium {
            mediumBody
        } else {
            largeBody
        }
    }

    private var mediumBody: some View {
        let month = model.month(for: entry.date)
        let week = model.week(for: entry.date)

        return VStack(alignment: .leading, spacing: 12) {
            header(for: month)
            mediumWeekStrip(week)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var largeBody: some View {
        let month = model.month(for: entry.date)

        return VStack(alignment: .leading, spacing: 8) {
            header(for: month)
            weekdayHeader
            calendarGrid(month.days)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func header(for month: MonthSnapshot) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(month.title)
                    .font(.system(size: family == .systemLarge ? 20 : 18, weight: .semibold))
                Text(month.subtitle)
                    .font(.system(size: family == .systemLarge ? 10 : 9, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(month.today.dayText)
                .font(.system(size: family == .systemLarge ? 22 : 20, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(todayAccent)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Capsule().fill(todayAccent.opacity(colorScheme == .dark ? 0.14 : 0.1)))
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
                .foregroundStyle(day.isWeekend ? weekendColor : .secondary)

            Text(day.dayText)
                .font(.system(size: day.isToday ? 21 : 18, weight: day.isToday ? .bold : .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(day.isToday ? .white : dayTextColor(day))
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(day.isToday ? todayAccent : .clear)
                )

            Text(day.note)
                .font(.system(size: 9, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundStyle(day.isHoliday ? weekendColor : .secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 76)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(day.isToday ? todayAccent.opacity(colorScheme == .dark ? 0.12 : 0.08) : .white.opacity(colorScheme == .dark ? 0.035 : 0.08))
        )
    }

    private var weekdayHeader: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            GridRow {
                ForEach(MonthModel.weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(weekday == "六" || weekday == "日" ? weekendColor : .secondary)
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

            Text(day.note)
                .font(.system(size: family == .systemLarge ? 9 : 7, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundStyle(day.isCurrentMonth ? noteColor(day) : .secondary.opacity(0.32))
                .frame(maxWidth: .infinity)
        }
        .opacity(day.isCurrentMonth ? 1 : 0.36)
    }

    private var weekendColor: Color {
        Color(red: 0.9, green: 0.36, blue: 0.28)
    }

    private var todayAccent: Color {
        Color(red: 0.95, green: 0.32, blue: 0.28)
    }

    private func dayTextColor(_ day: DaySnapshot) -> Color {
        if day.isToday {
            return .white
        }

        if day.isWeekend {
            return weekendColor
        }

        return .primary
    }

    private func noteColor(_ day: DaySnapshot) -> Color {
        day.isHoliday ? weekendColor : .secondary
    }

    @ViewBuilder
    private func todayBackground(for day: DaySnapshot) -> some View {
        if day.isToday {
            Circle().fill(todayAccent)
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
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.09, blue: 0.16),
                    Color(red: 0.13, green: 0.16, blue: 0.28),
                    Color(red: 0.09, green: 0.10, blue: 0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.42)
        }
    }
}

private struct MonthModel {
    static let weekdays = ["一", "二", "三", "四", "五", "六", "日"]

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.firstWeekday = 2
        return calendar
    }

    private let lunarCalendar = Calendar(identifier: .chinese)

    func month(for date: Date) -> MonthSnapshot {
        let calendar = calendar
        let startOfToday = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.year, .month], from: date)
        let firstDay = calendar.date(from: components) ?? startOfToday
        let weekdayOffset = (calendar.component(.weekday, from: firstDay) + 5) % 7
        let gridStart = calendar.date(byAdding: .day, value: -weekdayOffset, to: firstDay) ?? firstDay
        let currentMonth = calendar.component(.month, from: date)

        let days = (0..<42).map { index in
            let day = calendar.date(byAdding: .day, value: index, to: gridStart) ?? gridStart
            return snapshot(for: day, currentMonth: currentMonth, today: startOfToday)
        }

        let today = snapshot(for: startOfToday, currentMonth: currentMonth, today: startOfToday)
        let title = "\(calendar.component(.year, from: date))年\(calendar.component(.month, from: date))月"

        return MonthSnapshot(
            title: title,
            subtitle: "\(today.lunarMonthText)\(today.note)",
            days: days,
            today: today
        )
    }

    func week(for date: Date) -> [DaySnapshot] {
        let calendar = calendar
        let startOfToday = calendar.startOfDay(for: date)
        let weekdayOffset = (calendar.component(.weekday, from: startOfToday) + 5) % 7
        let weekStart = calendar.date(byAdding: .day, value: -weekdayOffset, to: startOfToday) ?? startOfToday
        let currentMonth = calendar.component(.month, from: date)

        return (0..<7).map { index in
            let day = calendar.date(byAdding: .day, value: index, to: weekStart) ?? weekStart
            return snapshot(for: day, currentMonth: currentMonth, today: startOfToday)
        }
    }

    private func snapshot(for date: Date, currentMonth: Int, today: Date) -> DaySnapshot {
        let calendar = calendar
        let lunar = lunarCalendar.dateComponents([.month, .day, .isLeapMonth], from: date)
        let solarMonth = calendar.component(.month, from: date)
        let solarDay = calendar.component(.day, from: date)
        let weekday = calendar.component(.weekday, from: date)
        let lunarMonth = lunar.month ?? 1
        let lunarDay = lunar.day ?? 1
        let isLeapMonth = lunar.isLeapMonth ?? false
        let solarHoliday = Self.solarHolidays["\(solarMonth)-\(solarDay)"]
        let lunarHoliday = isLeapMonth ? nil : Self.lunarHolidays["\(lunarMonth)-\(lunarDay)"]
        let note = solarHoliday ?? lunarHoliday ?? lunarDayName(lunarDay)

        return DaySnapshot(
            date: date,
            dayText: "\(solarDay)",
            note: note,
            lunarMonthText: lunarMonthName(lunarMonth),
            isToday: calendar.isDate(date, inSameDayAs: today),
            isCurrentMonth: solarMonth == currentMonth,
            isWeekend: weekday == 1 || weekday == 7,
            isHoliday: solarHoliday != nil || lunarHoliday != nil
        )
    }

    private func lunarDayName(_ day: Int) -> String {
        let names = [
            "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
            "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
            "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
        ]

        return names.indices.contains(day - 1) ? names[day - 1] : ""
    }

    private func lunarMonthName(_ month: Int) -> String {
        let names = ["正月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "冬月", "腊月"]
        return names.indices.contains(month - 1) ? names[month - 1] : ""
    }

    private static let solarHolidays = [
        "1-1": "元旦",
        "2-14": "情人",
        "5-1": "劳动",
        "10-1": "国庆",
        "12-25": "圣诞"
    ]

    private static let lunarHolidays = [
        "1-1": "春节",
        "1-15": "元宵",
        "5-5": "端午",
        "7-7": "七夕",
        "8-15": "中秋",
        "9-9": "重阳",
        "12-8": "腊八"
    ]
}

private struct MonthSnapshot {
    let title: String
    let subtitle: String
    let days: [DaySnapshot]
    let today: DaySnapshot
}

private struct DaySnapshot {
    let date: Date
    let dayText: String
    let note: String
    let lunarMonthText: String
    let isToday: Bool
    let isCurrentMonth: Bool
    let isWeekend: Bool
    let isHoliday: Bool

    var detail: String {
        "\(lunarMonthText)\(note)"
    }

    var weekdayText: String {
        let weekday = Calendar.current.component(.weekday, from: date)
        let names = ["日", "一", "二", "三", "四", "五", "六"]
        return names[weekday - 1]
    }
}

#Preview(as: .systemMedium) {
    LunarGlassWidget()
} timeline: {
    CalendarEntry(date: Date())
}

#Preview(as: .systemLarge) {
    LunarGlassWidget()
} timeline: {
    CalendarEntry(date: Date())
}
