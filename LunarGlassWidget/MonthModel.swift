//
//  MonthModel.swift
//  LunarGlassWidget
//
//  Created by York on 2026/5/5.
//

import Foundation

struct MonthModel {
    static let weekdays = ["一", "二", "三", "四", "五", "六", "日"]

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = .current
        calendar.firstWeekday = 2
        return calendar
    }

    private var lunarCalendar: Calendar {
        var calendar = Calendar(identifier: .chinese)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = .current
        return calendar
    }

    func month(for date: Date, events: [Date: Int] = [:], holidays: [Date: String] = [:], workdays: Set<Date> = []) -> MonthSnapshot {
        let calendar = calendar
        let startOfToday = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.year, .month], from: date)
        let firstDay = calendar.date(from: components) ?? startOfToday
        let weekdayOffset = (calendar.component(.weekday, from: firstDay) + 5) % 7
        let gridStart = calendar.date(byAdding: .day, value: -weekdayOffset, to: firstDay) ?? firstDay
        let currentMonth = calendar.component(.month, from: date)

        let days = (0..<42).map { index in
            let day = calendar.date(byAdding: .day, value: index, to: gridStart) ?? gridStart
            return snapshot(for: day, currentMonth: currentMonth, today: startOfToday, events: events, holidays: holidays, workdays: workdays)
        }

        let today = snapshot(for: startOfToday, currentMonth: currentMonth, today: startOfToday, events: events, holidays: holidays, workdays: workdays)
        let title = "\(calendar.component(.year, from: date))年\(calendar.component(.month, from: date))月"

        return MonthSnapshot(
            title: title,
            subtitle: today.detail,
            days: days,
            today: today
        )
    }

    func week(for date: Date, events: [Date: Int] = [:], holidays: [Date: String] = [:], workdays: Set<Date> = []) -> [DaySnapshot] {
        let calendar = calendar
        let startOfToday = calendar.startOfDay(for: date)
        let weekdayOffset = (calendar.component(.weekday, from: startOfToday) + 5) % 7
        let weekStart = calendar.date(byAdding: .day, value: -weekdayOffset, to: startOfToday) ?? startOfToday
        let currentMonth = calendar.component(.month, from: date)

        return (0..<7).map { index in
            let day = calendar.date(byAdding: .day, value: index, to: weekStart) ?? weekStart
            return snapshot(for: day, currentMonth: currentMonth, today: startOfToday, events: events, holidays: holidays, workdays: workdays)
        }
    }

    private func snapshot(for date: Date, currentMonth: Int, today: Date, events: [Date: Int], holidays: [Date: String], workdays: Set<Date>) -> DaySnapshot {
        let calendar = calendar
        let lunarCalendar = lunarCalendar
        let lunar = lunarCalendar.dateComponents([.month, .day, .isLeapMonth], from: date)
        let solarMonth = calendar.component(.month, from: date)
        let solarDay = calendar.component(.day, from: date)
        let weekday = calendar.component(.weekday, from: date)
        let lunarMonth = lunar.month ?? 1
        let lunarDay = lunar.day ?? 1
        let isLeapMonth = lunar.isLeapMonth ?? false
        let dayStart = calendar.startOfDay(for: date)

        let systemHoliday = holidays[dayStart]
        let solarHoliday = Self.solarHolidays["\(solarMonth)-\(solarDay)"]
        let qingming = isQingming(date)
        let lunarHoliday = lunarHoliday(
            for: date,
            month: lunarMonth,
            day: lunarDay,
            isLeapMonth: isLeapMonth,
            lunarCalendar: lunarCalendar
        )

        let note: String
        if let q = qingming {
            note = q
        } else if let s = systemHoliday {
            note = s
        } else if let s = solarHoliday {
            note = s
        } else if let l = lunarHoliday {
            note = l
        } else {
            note = lunarDayName(lunarDay)
        }

        return DaySnapshot(
            date: date,
            dayText: "\(solarDay)",
            note: note,
            lunarMonthText: lunarMonthName(lunarMonth, isLeapMonth: isLeapMonth),
            weekdayText: weekdayName(for: weekday),
            isToday: calendar.isDate(date, inSameDayAs: today),
            isCurrentMonth: solarMonth == currentMonth,
            isWeekend: weekday == 1 || weekday == 7,
            isHoliday: qingming != nil || systemHoliday != nil || solarHoliday != nil || lunarHoliday != nil,
            isWorkday: workdays.contains(dayStart),
            eventCount: events[dayStart] ?? 0
        )
    }

    private func lunarHoliday(
        for date: Date,
        month: Int,
        day: Int,
        isLeapMonth: Bool,
        lunarCalendar: Calendar
    ) -> String? {
        guard !isLeapMonth else {
            return nil
        }

        if isLunarNewYearEve(date, lunarCalendar: lunarCalendar) {
            return "除夕"
        }

        return Self.lunarHolidays["\(month)-\(day)"]
    }

    private func isLunarNewYearEve(_ date: Date, lunarCalendar: Calendar) -> Bool {
        guard let tomorrow = lunarCalendar.date(byAdding: .day, value: 1, to: date) else {
            return false
        }

        let tomorrowLunar = lunarCalendar.dateComponents([.month, .day, .isLeapMonth], from: tomorrow)
        return tomorrowLunar.month == 1
            && tomorrowLunar.day == 1
            && tomorrowLunar.isLeapMonth != true
    }

    private func weekdayName(for weekday: Int) -> String {
        let names = ["日", "一", "二", "三", "四", "五", "六"]
        return names.indices.contains(weekday - 1) ? names[weekday - 1] : ""
    }

    private func lunarDayName(_ day: Int) -> String {
        let names = [
            "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
            "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
            "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
        ]

        return names.indices.contains(day - 1) ? names[day - 1] : ""
    }

    private func lunarMonthName(_ month: Int, isLeapMonth: Bool) -> String {
        let names = ["正月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "冬月", "腊月"]
        let name = names.indices.contains(month - 1) ? names[month - 1] : ""
        return isLeapMonth ? "闰\(name)" : name
    }

    private static let solarHolidays = [
        "1-1": "元旦",
        "5-1": "劳动",
        "10-1": "国庆"
    ]

    private static let lunarHolidays = [
        "1-1": "春节",
        "1-15": "元宵",
        "2-2": "龙头",
        "5-5": "端午",
        "7-7": "七夕",
        "7-15": "中元",
        "8-15": "中秋",
        "9-9": "重阳",
        "12-8": "腊八",
        "12-23": "小年"
    ]

    private func isQingming(_ date: Date) -> String? {
        let gregorian = Calendar(identifier: .gregorian)
        let components = gregorian.dateComponents([.year, .month, .day], from: date)
        guard components.month == 4, let day = components.day, (4...6).contains(day) else {
            return nil
        }
        guard let year = components.year else { return nil }

        let qDay = qingmingDay(year: year)
        return day == qDay ? "清明" : nil
    }

    private func qingmingDay(year: Int) -> Int {
        let offset = Double(year - 2000)
        let d = 4.81 + 0.2422 * offset - Double(Int(offset / 4))
        return Int(d)
    }
}

struct MonthSnapshot {
    let title: String
    let subtitle: String
    let days: [DaySnapshot]
    let today: DaySnapshot
}

struct DaySnapshot {
    let date: Date
    let dayText: String
    let note: String
    let lunarMonthText: String
    let weekdayText: String
    let isToday: Bool
    let isCurrentMonth: Bool
    let isWeekend: Bool
    let isHoliday: Bool
    let isWorkday: Bool
    let eventCount: Int

    var detail: String {
        "\(lunarMonthText)\(note)"
    }
}
