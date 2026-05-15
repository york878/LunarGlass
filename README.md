# LunarGlass

macOS 桌面月历 Widget — 透明玻璃风格，支持公历、农历、中国节气和 EventKit 日历事件。

## 功能

- **桌面 Widget**: 支持中尺寸（周条）和大尺寸（月历网格）两种形态
- **农历显示**: 每日标注农历日期（初一、初二……廿九、三十）
- **中国节日**: 硬编码春节、元宵、端午、中秋等传统节日，以及清明（公式计算）
- **日历事件**: 通过 EventKit 读取系统日历，在日期下方显示事件数量
- **调休日**: 自动识别中国节假日日历中的调休工作日并标记「班」
- **强调色**: 青玉（默认）、朱砂、鎏金 三种主题色，Widget 与主应用实时同步
- **毛玻璃效果**: 可调节的玻璃强度参数

## 项目结构

```
LunarGlass.xcodeproj
├── LunarGlass/                    # macOS 主应用
│   ├── LunarGlassApp.swift        # @main 入口，请求日历权限
│   ├── ContentView.swift          # 设置面板 + Widget 实时预览
│   └── LunarGlass.entitlements
└── LunarGlassWidget/              # WidgetKit 扩展
    ├── LunarGlassWidgetBundle.swift  # WidgetBundle 入口
    ├── LunarGlassWidget.swift        # TimelineProvider + 视图渲染
    ├── MonthModel.swift              # 纯 Swift 日历逻辑（农历、节日、日网格）
    ├── CalendarService.swift         # EventKit 封装（事件、节假日、调休日）
    └── Info.plist
```

### 数据流

```
MonthModel（纯逻辑）
  → MonthSnapshot（42 天网格）/ DaySnapshot（每日信息）
  → LunarGlassWidgetEntryView 渲染
  → WidgetKit → 通知中心 / 桌面
```

主应用与 Widget 通过 `UserDefaults(suiteName: "group.com.york.LunarGlass")` 共享设置（强调色等）。

## 构建

```bash
xcodebuild -project LunarGlass.xcodeproj -scheme LunarGlass -configuration Debug -destination 'platform=macOS' build
```

开发调试在 Xcode 中直接 ⌘R。

## 使用

1. 首次启动授权日历访问
2. 右键桌面 → 编辑 Widget → 添加 LunarGlass
3. 可选择中尺寸（周视图）或大尺寸（月视图）
4. 打开主应用调整强调色、玻璃强度、农历/节日显示

## 自定义

| 强调色 | 值 |
|--------|-----|
| 青玉（默认） | `#277B50` |
| 朱砂 | `#FF5C52` |
| 鎏金 | `#F0A638` |

强调色通过 App Group 的 UserDefaults 同步到 Widget。

## 技术细节

- 周一为每周起始（`firstWeekday = 2`）
- 农历使用 `Calendar.Identifier.chinese`
- 清明日期通过公式 `4.81 + 0.2422 × (year − 2000) − floor((year − 2000) / 4)` 计算
- Widget 每日午夜刷新一次（`.after(nextMidnight)`）
