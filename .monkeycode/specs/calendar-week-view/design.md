# Calendar Week View

Feature Name: calendar-week-view
Updated: 2026-08-15

## Description

周视图作为月视图和日程视图之间的规划层，展示选中日期所在周的七个日期列。每列显示日期状态、事件数量、事件时间、标题、分类色和完成状态。

## Components And Interfaces

- `CalendarDisplayMode.week`: 新增周视图模式，复用现有工具栏菜单。
- `WeekCalendarCard`: 计算选中日期所在周，渲染七个日期列、周总量、完成进度和空闲日期快速新增。
- `CalendarHomeView`: 传递事件编辑和完成状态回调，保持现有 SwiftData 保存路径。

## Correctness Properties

- 周视图始终展示七个连续日期。
- 每个日期列只展示覆盖该日期的事件。
- 选中日期状态与顶部工具栏和其他视图共享。
- 空闲日期快速新增会先更新选中日期，再打开事件表单。

## Test Strategy

- 通过 GitHub Actions `PaperTodo iOS Build` 验证项目生成和 IPA 构建。
- 检查周首日、跨月周和跨日事件显示。
- 检查 iPhone 横向滚动列和 iPad 居中宽度布局。
