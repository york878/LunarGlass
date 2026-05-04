//
//  ContentView.swift
//  LunarGlass
//
//  Created by York on 2026/5/5.
//

import SwiftUI
import EventKit

struct ContentView: View {
    @AppStorage("accentStyle") private var accentStyle = AccentStyle.jade.rawValue
    @AppStorage("glassStrength") private var glassStrength = 0.42
    @AppStorage("showLunarNotes") private var showLunarNotes = true
    @AppStorage("showHolidayNotes") private var showHolidayNotes = true

    private let sharedDefaults = UserDefaults(suiteName: "group.com.york.LunarGlass")

    private var selectedAccent: AccentStyle {
        AccentStyle(rawValue: accentStyle) ?? .jade
    }

    var body: some View {
        NavigationSplitView {
            List {
                Section("外观") {
                    Picker("强调色", selection: $accentStyle) {
                        ForEach(AccentStyle.allCases) { style in
                            Label(style.title, systemImage: style.symbol)
                                .tag(style.rawValue)
                        }
                    }

                    LabeledContent("玻璃强度") {
                        Slider(value: $glassStrength, in: 0.18...0.72)
                            .frame(width: 150)
                    }
                }

                Section("日历") {
                    Toggle("农历", isOn: $showLunarNotes)
                    Toggle("节日", isOn: $showHolidayNotes)
                }
            }
            .navigationTitle("LunarGlass")
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    HStack(alignment: .top, spacing: 18) {
                        mediumPreview
                            .frame(width: 360, height: 170)

                        largePreview
                            .frame(width: 360, height: 360)
                    }
                }
                .padding(28)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .background(appBackdrop)
        }
        .task {
            let status = EKEventStore.authorizationStatus(for: .event)
            if status == .notDetermined {
                await withCheckedContinuation { continuation in
                    EKEventStore().requestAccess(to: .event) { _, _ in
                        continuation.resume()
                    }
                }
            }
        }
        .onChange(of: accentStyle) {
            sharedDefaults?.set(accentStyle, forKey: "accentStyle")
        }
        .task {
            sharedDefaults?.set(accentStyle, forKey: "accentStyle")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LunarGlass")
                .font(.system(size: 34, weight: .semibold, design: .rounded))

            Text("macOS 桌面月历")
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    private var mediumPreview: some View {
        VStack(alignment: .leading, spacing: 14) {
            previewHeader(title: "2026年5月", subtitle: subtitleText)

            HStack(spacing: 8) {
                ForEach(PreviewDay.week, id: \.day) { day in
                    previewDayCard(day)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(glassPreviewBackground(cornerRadius: 18))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var largePreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            previewHeader(title: "2026年5月", subtitle: subtitleText)
            weekdayHeader
            monthGrid
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(glassPreviewBackground(cornerRadius: 22))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func previewHeader(title: String, subtitle: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("5")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(selectedAccent.color)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Capsule().fill(selectedAccent.color.opacity(0.12)))
        }
    }

    private func previewDayCard(_ day: PreviewDay) -> some View {
        VStack(spacing: 5) {
            Text(day.weekday)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(day.isWeekend ? selectedAccent.color : .secondary)

            Text(day.day)
                .font(.system(size: day.isToday ? 21 : 18, weight: day.isToday ? .bold : .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(day.isToday ? .white : dayTextColor(day))
                .frame(width: 34, height: 34)
                .background(Circle().fill(day.isToday ? selectedAccent.color : .clear))

            Text(noteText(day))
                .font(.system(size: 9, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundStyle(day.isHoliday ? selectedAccent.color : .secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 78)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(day.isToday ? selectedAccent.color.opacity(0.12) : .white.opacity(0.08))
        )
    }

    private var weekdayHeader: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            GridRow {
                ForEach(["一", "二", "三", "四", "五", "六", "日"], id: \.self) { weekday in
                    Text(weekday)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(weekday == "六" || weekday == "日" ? selectedAccent.color : .secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var monthGrid: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 6) {
            ForEach(0..<6, id: \.self) { row in
                GridRow {
                    ForEach(0..<7, id: \.self) { column in
                        let day = PreviewDay.month[row * 7 + column]
                        compactDayCell(day)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func compactDayCell(_ day: PreviewDay) -> some View {
        VStack(spacing: 2) {
            Text(day.day)
                .font(.system(size: 15, weight: day.isToday ? .bold : .medium, design: .rounded))
                .monospacedDigit()
                .frame(width: 25, height: 25)
                .background(Circle().fill(day.isToday ? selectedAccent.color : .clear))
                .foregroundStyle(day.isToday ? .white : dayTextColor(day))

            Text(noteText(day))
                .font(.system(size: 8, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(day.isHoliday ? selectedAccent.color : .secondary)
        }
        .opacity(day.isCurrentMonth ? 1 : 0.35)
    }

    private var appBackdrop: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)

            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.14, blue: 0.22).opacity(0.16),
                    selectedAccent.color.opacity(0.10),
                    Color(red: 0.18, green: 0.22, blue: 0.20).opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Grid(horizontalSpacing: 22, verticalSpacing: 22) {
                ForEach(0..<18, id: \.self) { _ in
                    GridRow {
                        ForEach(0..<28, id: \.self) { _ in
                            Circle()
                                .fill(.secondary.opacity(0.12))
                                .frame(width: 2, height: 2)
                        }
                    }
                }
            }
        }
    }

    private func glassPreviewBackground(cornerRadius: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)

            LinearGradient(
                colors: [
                    Color.white.opacity(0.30),
                    selectedAccent.color.opacity(glassStrength * 0.42),
                    Color.black.opacity(0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    Color.white.opacity(0.42),
                    Color.white.opacity(0.06),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .center
            )

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.34), lineWidth: 1)
        }
    }

    private var subtitleText: String {
        guard showLunarNotes else {
            return "5月5日"
        }

        return "三月十九"
    }

    private func noteText(_ day: PreviewDay) -> String {
        if day.isHoliday, showHolidayNotes {
            return day.note
        }

        if showLunarNotes {
            return day.lunar
        }

        return ""
    }

    private func dayTextColor(_ day: PreviewDay) -> Color {
        if day.isWeekend || day.isHoliday {
            return selectedAccent.color
        }

        return .primary
    }
}

private enum AccentStyle: String, CaseIterable, Identifiable {
    case vermilion
    case jade
    case gold

    var id: String { rawValue }

    var title: String {
        switch self {
        case .vermilion: "朱砂"
        case .jade: "青玉"
        case .gold: "鎏金"
        }
    }

    var symbol: String {
        switch self {
        case .vermilion: "sun.max"
        case .jade: "leaf"
        case .gold: "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .vermilion:
            Color(red: 0.95, green: 0.32, blue: 0.28)
        case .jade:
            Color(red: 0.15, green: 0.68, blue: 0.54)
        case .gold:
            Color(red: 0.94, green: 0.65, blue: 0.22)
        }
    }
}

private struct PreviewDay {
    let day: String
    let weekday: String
    let lunar: String
    let note: String
    let isToday: Bool
    let isCurrentMonth: Bool
    let isWeekend: Bool
    let isHoliday: Bool

    static let week = [
        PreviewDay(day: "4", weekday: "一", lunar: "十八", note: "十八", isToday: false, isCurrentMonth: true, isWeekend: false, isHoliday: false),
        PreviewDay(day: "5", weekday: "二", lunar: "十九", note: "十九", isToday: true, isCurrentMonth: true, isWeekend: false, isHoliday: false),
        PreviewDay(day: "6", weekday: "三", lunar: "二十", note: "二十", isToday: false, isCurrentMonth: true, isWeekend: false, isHoliday: false),
        PreviewDay(day: "7", weekday: "四", lunar: "廿一", note: "廿一", isToday: false, isCurrentMonth: true, isWeekend: false, isHoliday: false),
        PreviewDay(day: "8", weekday: "五", lunar: "廿二", note: "廿二", isToday: false, isCurrentMonth: true, isWeekend: false, isHoliday: false),
        PreviewDay(day: "9", weekday: "六", lunar: "廿三", note: "廿三", isToday: false, isCurrentMonth: true, isWeekend: true, isHoliday: false),
        PreviewDay(day: "10", weekday: "日", lunar: "廿四", note: "廿四", isToday: false, isCurrentMonth: true, isWeekend: true, isHoliday: false)
    ]

    static let month: [PreviewDay] = [
        PreviewDay(day: "27", weekday: "一", lunar: "十一", note: "十一", isToday: false, isCurrentMonth: false, isWeekend: false, isHoliday: false),
        PreviewDay(day: "28", weekday: "二", lunar: "十二", note: "十二", isToday: false, isCurrentMonth: false, isWeekend: false, isHoliday: false),
        PreviewDay(day: "29", weekday: "三", lunar: "十三", note: "十三", isToday: false, isCurrentMonth: false, isWeekend: false, isHoliday: false),
        PreviewDay(day: "30", weekday: "四", lunar: "十四", note: "十四", isToday: false, isCurrentMonth: false, isWeekend: false, isHoliday: false),
        PreviewDay(day: "1", weekday: "五", lunar: "十五", note: "劳动", isToday: false, isCurrentMonth: true, isWeekend: false, isHoliday: true),
        PreviewDay(day: "2", weekday: "六", lunar: "十六", note: "十六", isToday: false, isCurrentMonth: true, isWeekend: true, isHoliday: false),
        PreviewDay(day: "3", weekday: "日", lunar: "十七", note: "十七", isToday: false, isCurrentMonth: true, isWeekend: true, isHoliday: false),
        PreviewDay(day: "4", weekday: "一", lunar: "十八", note: "青年", isToday: false, isCurrentMonth: true, isWeekend: false, isHoliday: true),
        PreviewDay(day: "5", weekday: "二", lunar: "十九", note: "十九", isToday: true, isCurrentMonth: true, isWeekend: false, isHoliday: false),
        PreviewDay(day: "6", weekday: "三", lunar: "二十", note: "二十", isToday: false, isCurrentMonth: true, isWeekend: false, isHoliday: false),
        PreviewDay(day: "7", weekday: "四", lunar: "廿一", note: "廿一", isToday: false, isCurrentMonth: true, isWeekend: false, isHoliday: false),
        PreviewDay(day: "8", weekday: "五", lunar: "廿二", note: "廿二", isToday: false, isCurrentMonth: true, isWeekend: false, isHoliday: false),
        PreviewDay(day: "9", weekday: "六", lunar: "廿三", note: "廿三", isToday: false, isCurrentMonth: true, isWeekend: true, isHoliday: false),
        PreviewDay(day: "10", weekday: "日", lunar: "廿四", note: "廿四", isToday: false, isCurrentMonth: true, isWeekend: true, isHoliday: false)
    ] + (11...31).map { day in
        PreviewDay(
            day: "\(day)",
            weekday: "",
            lunar: "\(day)",
            note: "\(day)",
            isToday: false,
            isCurrentMonth: true,
            isWeekend: [16, 17, 23, 24, 30, 31].contains(day),
            isHoliday: false
        )
    } + [
        PreviewDay(day: "1", weekday: "一", lunar: "十六", note: "儿童", isToday: false, isCurrentMonth: false, isWeekend: false, isHoliday: true),
        PreviewDay(day: "2", weekday: "二", lunar: "十七", note: "十七", isToday: false, isCurrentMonth: false, isWeekend: false, isHoliday: false),
        PreviewDay(day: "3", weekday: "三", lunar: "十八", note: "十八", isToday: false, isCurrentMonth: false, isWeekend: false, isHoliday: false),
        PreviewDay(day: "4", weekday: "四", lunar: "十九", note: "十九", isToday: false, isCurrentMonth: false, isWeekend: false, isHoliday: false),
        PreviewDay(day: "5", weekday: "五", lunar: "二十", note: "二十", isToday: false, isCurrentMonth: false, isWeekend: false, isHoliday: false),
        PreviewDay(day: "6", weekday: "六", lunar: "廿一", note: "廿一", isToday: false, isCurrentMonth: false, isWeekend: true, isHoliday: false),
        PreviewDay(day: "7", weekday: "日", lunar: "廿二", note: "廿二", isToday: false, isCurrentMonth: false, isWeekend: true, isHoliday: false)
    ]
}

#Preview {
    ContentView()
        .frame(width: 900, height: 560)
}
