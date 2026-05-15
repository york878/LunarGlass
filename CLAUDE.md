# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

LunarGlass is a macOS desktop calendar widget app with a glass-morphism visual style. It displays Gregorian dates alongside Chinese lunar calendar dates, solar holidays, and lunar holidays. Built with SwiftUI + WidgetKit, targeting macOS.

## Build & run

Open `LunarGlass.xcodeproj` in Xcode (built with Xcode 26.4). Select the `LunarGlass` scheme and run (⌘R). The main app shows a settings panel with live widget previews; the actual widget appears in the macOS notification center / desktop.

No CLI build tools, linting, or test targets are configured.

## Architecture

Two targets:

- **LunarGlass** (main app) — `LunarGlass/`
  - `LunarGlassApp.swift` — `@main` entry, wraps `ContentView` in a `WindowGroup`
  - `ContentView.swift` — Settings UI (accent color, glass strength, lunar/holiday toggles) with live widget previews. Also defines `AccentStyle` (vermilion/jade/gold) and hardcoded `PreviewDay` data for the preview.

- **LunarGlassWidget** (WidgetKit extension) — `LunarGlassWidget/`
  - `LunarGlassWidgetBundle.swift` — `@main` entry for the widget extension
  - `LunarGlassWidget.swift` — `TimelineProvider` (refreshes at midnight), `LunarGlassWidgetEntryView` (medium + large widget families), `WidgetBackground` (glass-morphism dark gradient). Hardcoded vermilion accent colors.
  - `MonthModel.swift` — Core calendar logic. Wraps `Calendar.gregorian` (firstWeekday=2 for Monday-start) and `Calendar.chinese` for lunar dates. Produces `MonthSnapshot` (42-day grid) and `DaySnapshot` from a given date. Contains hardcoded solar and lunar holiday dictionaries. Handles lunar new year's eve detection.

Key data flow: `MonthModel` takes a `Date` → computes a 42-day grid starting from the Monday before the 1st of the month → each `DaySnapshot` is populated with gregorian day, lunar day name, weekday, and holiday note → the widget views render the grid with glass-morphism styling.

## Notes

- The widget accent color (vermilion) is hardcoded in `LunarGlassWidget.swift` — it does not read the `AccentStyle` preference from the main app. The two are out of sync by design (or pending a sync mechanism like App Groups).
- `MonthModel.swift` is currently untracked (new file, not yet committed).
- The main app's `ContentView` has a `NavigationSplitView` for settings, but the widget has no knowledge of user preferences — settings only affect the in-app preview.
