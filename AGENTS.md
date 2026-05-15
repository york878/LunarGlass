# AGENTS.md — LunarGlass

## 构建与运行

**唯一构建方式**：
```
xcodebuild -project LunarGlass.xcodeproj -scheme LunarGlass -configuration Debug -destination 'platform=macOS' build
```
无 package.json，无 Makefile，无 swift build。必须使用 Xcode 或 xcodebuild。

**运行**：
- 主应用：Xcode 中选择 `LunarGlass` scheme → ⌘R
- Widget 扩展：Xcode 中选择 `LunarGlassWidgetExtension` scheme → ⌘R

## 项目结构

两个独立编译目标：
- `LunarGlass/`：主 macOS 应用
  - `LunarGlassApp.swift`：@main 入口，请求 EventKit 日历授权
  - `ContentView.swift`：设置面板 + 实时 widget 预览
- `LunarGlassWidget/`：WidgetKit 扩展目标
  - `LunarGlassWidgetBundle.swift`：@main 入口
  - `LunarGlassWidget.swift`：TimelineProvider + 中型/大型视图
  - `MonthModel.swift`：纯 Swift 日历核心（零 UI 依赖）
  - `CalendarService.swift`：EventKit 包装器（事件、节假日、调休日）

## 关键架构点

1. **数据流**：
   `MonthModel`（纯逻辑） → `MonthSnapshot`（42 天网格）/ `DaySnapshot`（每日：公历日、农历名、节日备注、事件计数）  
   → `LunarGlassWidgetEntryView` 渲染  
   → WidgetKit → macOS 通知中心/桌面

2. **目标通信**：  
   唯一桥梁：`UserDefaults(suiteName: "group.com.york.LunarGlass")`  
   主应用通过 `@AppStorage` 保存设置并同步到共享 UserDefaults  
   Widget 从同一 UserDefaults 读取 `accentStyle`

3. **MonthModel 是纯 Swift 大脑**：  
   - 无任何 SwiftUI/UI 依赖  
   - 使用 `Calendar.gregorian`（周一起始，`firstWeekday=2`）和 `Calendar.chinese` 进行农历转换  
   - 硬编码节日：
     * 太阳历：1-1（元旦）、5-1（劳动）、10-1（国庆）
     * 农历：春节/元宵/龙头/端午/七夕/中元/中秋/重阳/腊八/小年
     * 清明：通过公式计算（`qingmingDay(year:)`）

4. **Widget 刷新策略**：  
   `TimelineProvider.getTimeline` 返回 `.after(nextMidnight)`  
   每日午夜获取一次事件/节假日/调休日数据

## 注意事项

- **EventKit 授权**：  
  两个目标均需完整日历访问权限。  
  主应用在启动时请求授权（`LunarGlassApp.swift`）。  
  Widget 未授权时静默返回空数据（`CalendarService` 检查 `authorizationStatus`）。

- **App Group 配置**（已修复）：  
  Widget 通过 `UserDefaults(suiteName: "group.com.york.LunarGlass")` 读取主应用的 `accentStyle` 设置。  
  两个 `.entitlements` 均已配置 `com.apple.security.application-groups` → `["group.com.york.LunarGlass"]`。  
  `DEVELOPMENT_TEAM = V4UCV3RRG7`，项目使用开发证书签名，颜色同步应正常工作。

## 开发者命令

| 操作 | 命令 |
|------|------|
| 构建 | `xcodebuild -project LunarGlass.xcodeproj -scheme LunarGlass -configuration Debug -destination 'platform=macOS' build` |
| 清理构建 | 在构建命令末尾追加 `clean` |
| 安装 Widget | `pluginkit -e use -i com.york.LunarGlass.LunarGlassWidget` |
| 重置 Widget | `pluginkit -r /Applications/LunarGlass.app/Contents/PlugIns/LunarGlassWidgetExtension.appex` |

## 项目特殊约定

- **无标准配置**：  
  无 README.md，无 .gitignore（仅 Xcode 默认忽略），无测试目标，无 linting，无 CI
- **Swift 命名**：  
  PascalCase 用于类型，camelCase 用于变量/函数，无分号，单引号括起字符串，2 空格缩进
- **共享 App Group ID**：  
  `group.com.york.LunarGlass` — 两个目标的 `UserDefaults(suiteName:)` 中使用
- **Widget 支持的家族**：  
  `.systemMedium`（周条视图）和 `.systemLarge`（月历网格视图）

## 现有说明文件

- `CLAUDE.md`：较旧的项目概览（被本文件取代）
- `.claude/settings.local.json`：OpenCode 本地权限配置（Xcode、pluginkit、git）