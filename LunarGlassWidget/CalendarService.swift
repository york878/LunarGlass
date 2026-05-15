import EventKit
import Foundation

struct CalendarService {
    private let store = EKEventStore()

    func fetchEvents(from start: Date, to end: Date) -> [Date: Int] {
        guard authorizationStatus == .fullAccess else {
            return [:]
        }

        let calendars = store.calendars(for: .event)
            .filter { isRelevantCalendar($0) }

        guard !calendars.isEmpty else {
            return [:]
        }

        let predicate = store.predicateForEvents(
            withStart: start,
            end: end,
            calendars: calendars.isEmpty ? nil : calendars
        )

        let events = store.events(matching: predicate)

        return events.reduce(into: [:]) { result, event in
            let day = Calendar.current.startOfDay(for: event.startDate)
            result[day, default: 0] += 1
        }
    }

    func fetchHolidays(from start: Date, to end: Date) -> [Date: String] {
        guard authorizationStatus == .fullAccess else {
            return [:]
        }

        let holidaysCalendar = chineseHolidayCalendar
        guard let calendar = holidaysCalendar else {
            return [:]
        }

        let predicate = store.predicateForEvents(
            withStart: start,
            end: end,
            calendars: [calendar]
        )

        let events = store.events(matching: predicate)

        return events.reduce(into: [:]) { result, event in
            let day = Calendar.current.startOfDay(for: event.startDate)
            let title = event.title.trimmingCharacters(in: .whitespaces)
            if isMakeupWorkday(title) { return }
            let existing = result[day] ?? ""
            result[day] = existing.isEmpty ? shortHolidayName(title) : existing
        }
    }

    func fetchWorkdays(from start: Date, to end: Date) -> Set<Date> {
        guard authorizationStatus == .fullAccess else {
            return []
        }

        let holidaysCalendar = chineseHolidayCalendar
        guard let calendar = holidaysCalendar else {
            return []
        }

        let predicate = store.predicateForEvents(
            withStart: start,
            end: end,
            calendars: [calendar]
        )

        let events = store.events(matching: predicate)
        var workdays = Set<Date>()

        for event in events {
            let title = event.title.trimmingCharacters(in: .whitespaces)
            if isMakeupWorkday(title) {
                workdays.insert(Calendar.current.startOfDay(for: event.startDate))
            }
        }

        return workdays
    }

    private var chineseHolidayCalendar: EKCalendar? {
        store.calendars(for: .event)
            .first { cal in
                let src = cal.source.title
                let t = cal.title
                return src.contains("节假日") || t.contains("节假日") || t.contains("中国") || t.contains("China")
            }
    }

    private func isMakeupWorkday(_ title: String) -> Bool {
        let lower = title.lowercased()
        return lower.contains("班") || lower.contains("补") || lower.contains("work")
    }

    var authorizationStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    func requestAccess() async -> Bool {
        do {
            return try await store.requestFullAccessToEvents()
        } catch {
            return false
        }
    }

    private func isRelevantCalendar(_ calendar: EKCalendar) -> Bool {
        let allowed = [
            EKSourceType.calDAV,
            EKSourceType.local,
            EKSourceType.exchange,
            EKSourceType.subscribed,
            EKSourceType.mobileMe
        ]

        let title = calendar.title.lowercased()
        let skipKeywords = ["提醒", "reminders", "birthdays", "生日", "siri", "found"]

        if skipKeywords.contains(where: { title.contains($0) }) {
            return false
        }

        return allowed.contains(calendar.source.sourceType)
    }

    private func shortHolidayName(_ title: String) -> String {
        let overrides: [String: String] = [
            "New Year's Day": "元旦",
            "Chinese New Year": "春节",
            "Lunar New Year": "除夕",
            "Spring Festival": "春节",
            "Qingming Festival": "清明",
            "Tomb-Sweeping Day": "清明",
            "清明": "清明",
            "Labour Day": "劳动",
            "Dragon Boat Festival": "端午",
            "Mid-Autumn Festival": "中秋",
            "National Day": "国庆"
        ]

        for (key, value) in overrides {
            if title.contains(key) {
                return value
            }
        }

        return String(title.prefix(2))
    }
}
