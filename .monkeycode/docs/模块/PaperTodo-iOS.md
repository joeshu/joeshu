# PaperTodo iOS 模块

## 职责

PaperTodo 是一个 SwiftUI 个人工作台。首页通过 `HomeMode` 在纸片、日历和四象限之间切换；纸片包含待办和 Markdown 笔记两种类型。

## 页面结构

- `ContentView`：首页容器、模式绑定、纸片查询、筛选、导航和删除撤销。
- `HomeModeContent`：今日、纸片、日历和四象限模式分段控件及内容分发。
- `TodayHomeView`：当天待办、日历事件、完成进度和快速记录入口。
- `QuickCaptureSheet`：将输入快速保存为收件箱任务或新笔记纸片。
- `TaskScheduleSheet`：为待办设置开始时间和预计时长，并显示在今日时间线。
- `CalendarContextToolbar`：展示日历上下文、今天定位、月份导航和快速新增日程。
- `CalendarContextToolbar`：按上下文、导航、视图、筛选和新增层级组织日历操作，新增菜单包含普通日程与自然语言创建。
- `CalendarDisplayMode`：在月视图与日程视图之间切换，保持选中日期状态。
- `WeekCalendarCard`：展示选中日期所在周的连续事件列和日期状态。
- `WeekCalendarCard`：显示周总量、完成进度，并从空闲日期快速新建日程。
- `TimelineEventRow`：展示单日与跨日时间摘要，支持编辑和上下文菜单切换完成状态。
- `DayTimelineCard`：以当天状态条、当前时间标记和来源标签组织日历事件与排期待办的执行时间线。
- `TimelineStatusStrip`：更新今天的当前时间，并展示选中日期的日程完成进度。
- `PaperCard`：在纸片索引中展示类型、进度、下一项任务和今日排期信息。
- `PaperFilterBar`：展示全部、待办、笔记和未完成筛选及数量；过滤空状态提供新建入口。
- `PaperSearchSheet`：搜索纸片标题、笔记正文和待办内容。
- `DailyReviewSheet`：展示今日任务完成率、剩余任务和排期时长。
- `NotePaperView`：识别 Markdown 未完成复选项，并支持去重导入收件箱。
- `PaperTodoWidget`：展示全部待办、今日待办、今日排期时长和下一项任务。
- `TodoPaperView`：待办编辑、拖放删除、排序、撤销重做、自动清除和 Widget 刷新。
- `TodoPaperView`：使用共享标题、完成进度、任务行和新增输入层级，保留待办编辑、拖放删除、排序、撤销重做、自动清除和 Widget 刷新。
- `NotePaperView`：标题、Markdown 编辑器、预览、图片导入、导出和主题设置。
- `NotePaperView`：以编辑/预览状态标题和统一纸面表面组织 Markdown 编辑、图片导入、导出和任务导入。
- `CalendarHomeView`：月历网格、事件标签、周标尺和日时间线。
- `CalendarEventFormView`：日程创建、编辑、删除、日期时间和分类。
- `QuadrantHomeView`：四象限派生、任务移动、编辑、完成和所属纸片导航。
- `QuadrantHomeView`：使用象限语义色、任务计数和来源纸片摘要组织优先级工作区，保留任务移动、编辑、完成和保存失败处理。
- `SettingsView`：外观、配色、待办字号、自动清除和 Markdown 渲染强度。
- `SettingsView`：按外观、首页、待办和笔记分组管理设置，默认首页视角复用 `HomeMode` 持久化。
- 一级导航、日历日期/事件、Today 时间线和任务行均提供 VoiceOver 标签、值和操作提示；共享按钮样式与页面事务会响应 Reduce Motion。

## 主题系统

`PaperColorScheme` 提供暖纸、墨、林、霞四种配色。`PaperPalette` 按配色和深浅模式提供正文、弱化文字、边框、强调色、危险色、画布色、时间色和渐变。`PaperRadius` 与 `PaperCardModifier` 为页面卡片提供统一的圆角、边框和阴影。

## UI Design System

商业化 UI 升级使用 Editorial Paper OS 方向。共享设计 token 位于 `Support/DesignSystem.swift`，包含间距、圆角、图标尺寸、排层、字体和表面组件；`WorkPerspectiveNavigation` 为 iPhone 提供底部工作视角导航，为 iPad 提供侧边工作视角导航。业务视图继续复用现有 SwiftData、Widget 和 Sheet 流程。

## 生命周期和错误处理

页面保存通过 `modelContext.save()` 执行，失败时显示 alert。异步 Markdown 高亮、图片导入和后台图片清理使用任务或队列；图片导入以正文引用快照和代际标识避免异步结果写入错误页面。

## Widget

Widget 从共享 SwiftData 容器读取所有待办，展示待办数、完成数和完成进度。主应用关键待办操作后主动调用 WidgetKit 刷新。
