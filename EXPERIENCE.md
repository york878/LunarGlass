# 开发经验总结

## WidgetKit 相关

### 1. 无法动态改变 Widget 尺寸

WidgetKit 不支持编程式动态改变 widget 的物理尺寸（`.systemMedium` ↔ `.systemLarge`）。用户必须通过 widget 画廊手动添加/移除不同尺寸。

**替代方案**：在单一尺寸内切换内容密度（紧凑模式 vs 展开模式），通过 `UserDefaults` 存储显示偏好，`AppIntent` 触发切换。

### 2. 修改设置后必须手动刷新 Widget

`TimelineProvider` 的刷新策略设为 `.after(nextMidnight)` 时，Widget 仅在午夜自动刷新。如果主应用修改了共享 UserDefaults（如强调色），**必须**调用：

```swift
WidgetCenter.shared.reloadAllTimelines()
```

否则 Widget 不会反映新设置，直到下一次 Timeline 刷新。

### 3. 主应用与 Widget 颜色值必须一致

主应用的 `AccentStyle.color` 和 Widget 的 `todayAccent` 是两套独立代码。修改一处时务必同步另一处，否则预览和实际 Widget 颜色不一致。

**建议**：将颜色定义提取为共享常量或枚举，放在两个 target 都能访问的模块中。

### 4. Widget 扩展的授权状态检查

iOS 17+/macOS 14+ 中 `EKAuthorizationStatus.authorized` 已废弃，应使用 `.fullAccess`。Widget 未授权时应静默返回空数据。

## 性能优化

### 5. Calendar 对象应缓存

`Calendar` 是值类型但创建成本不低。在循环中反复创建（如生成 42 天网格时）会造成不必要的开销。

```swift
// 错误：每次调用都创建新实例
private var calendar: Calendar { ... }

// 正确：初始化时创建一次
private let calendar: Calendar = { ... }()
```

## 项目维护

### 6. 必须配置 .gitignore

Xcode 项目必须包含 `.gitignore`，排除：
- `xcuserdata/` — 用户本地 scheme 和偏好
- `*.xcuserstate` — 用户状态
- `DerivedData/` — 构建缓存
- `.DS_Store` — macOS 系统文件

**教训**：本项目初始无 `.gitignore`，导致 `xcuserdata/xcschememanagement.plist` 被提交到所有历史提交中。修复需要使用 `git filter-branch` 重写历史，操作繁琐。

### 7. 代码审查常见检查点

| 类别 | 检查项 |
|------|--------|
| 数据同步 | 主应用修改共享数据后是否通知 Widget 刷新 |
| 颜色一致性 | 主应用和 Widget 的颜色值是否一致 |
| 性能 | 循环内是否重复创建对象 |
| 废弃 API | 是否使用了已废弃的系统 API |
| 内存 | `EKEventStore` 是否被正确持有 |
| 时区 | `Calendar` 的 `timeZone` 是否统一使用 `.current` |

## 构建与部署

### 8. 本地开发无需手动卸载

Xcode 的 ⌘R 会自动替换已安装的应用。无需手动从 `/Applications/` 删除再安装。

### 9. Widget 注册命令

```bash
# 注册 Widget
pluginkit -e use -i com.york.LunarGlass.LunarGlassWidget

# 重置 Widget
pluginkit -r /Applications/LunarGlass.app/Contents/PlugIns/LunarGlassWidgetExtension.appex
```
