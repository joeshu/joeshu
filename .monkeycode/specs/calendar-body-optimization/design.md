# Calendar Body Optimization

Feature Name: calendar-body-optimization
Updated: 2026-08-15

## Description

本轮优化聚焦日历主体。月历单元格使用稳定高度和分类色点表达事件密度，日时间线根据选中日期表达跨日事件边界，并通过上下文菜单提供完成状态操作。

## Components And Interfaces

- `MonthCard`: 使用最多四个分类色点和溢出数量替代多行事件标题，保持月历网格稳定高度。
- `DayTimelineCard`: 向时间线行传递选中日期和完成状态回调。
- `TimelineEventRow`: 显示单日时间、跨日上下文、事件分类和完成状态，提供编辑与完成上下文菜单。
- `CalendarHomeView.toggleEventCompletion`: 保存完成状态，保存失败时恢复原值并显示错误提示。

## Data Models

继续使用 `CalendarEvent` 的 `startTime`、`endTime`、`category` 和 `isCompleted` 字段，不增加持久化字段。

## Correctness Properties

- 月历单元格的事件色点数量最多为四个，溢出数量等于总事件数减去可见色点数量。
- 跨日事件的时间摘要与选中日期的开始日、结束日关系一致。
- 完成状态保存失败时，事件状态回滚到操作前的值。

## Test Strategy

- 通过 GitHub Actions `PaperTodo iOS Build` 验证 Swift 编译和 IPA 打包。
- 检查月历空事件、单事件、多事件和溢出事件的布局。
- 检查跨日事件在开始日、中间日和结束日的时间摘要。
- 检查事件上下文菜单的完成与回滚逻辑。
