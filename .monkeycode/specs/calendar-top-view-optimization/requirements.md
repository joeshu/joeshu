# Requirements Document

## Introduction

优化 PaperTodo 日历模式的顶部信息架构与月历浏览体验，使用户能够快速理解当前日期上下文、定位今天、切换月份和创建日程。

## Glossary

- **日历上下文工具栏**：日历内容顶部的标题、当前月份、今天入口、月份导航和新增入口集合。
- **选中日期**：用户当前查看日程列表对应的日期。
- **当前月份**：月历网格展示的月份。

## Requirements

### Requirement 1

**User Story:** AS a user, I want to see the current calendar context at the top, so that I can understand where I am before reviewing events.

#### Acceptance Criteria

1. WHEN the calendar mode is displayed, THE system SHALL show a calendar title, the current month, and the selected date context in the top content region.
2. WHEN the selected date is today, THE system SHALL identify the selected date as today.
3. WHEN the selected date is another date, THE system SHALL show the selected date using the device locale date format.

### Requirement 2

**User Story:** AS a user, I want direct date navigation controls, so that I can move through the calendar with one tap.

#### Acceptance Criteria

1. WHEN the user activates the previous-month control, THE system SHALL display the preceding month and select its first day.
2. WHEN the user activates the next-month control, THE system SHALL display the following month and select its first day.
3. WHEN the user activates the today control, THE system SHALL display the current month and select today.
4. WHEN the current month differs from the device month, THE system SHALL expose the today control with a visible state distinction.

### Requirement 3

**User Story:** AS a user, I want quick event creation from the calendar header, so that I can capture an event without searching through menus.

#### Acceptance Criteria

1. WHEN the user activates the add-event control, THE system SHALL open the event form using the selected date.
2. WHEN the selected date has events, THE system SHALL show the event count in the day context region.
3. WHEN the selected date has no events, THE system SHALL show the empty state and the same add-event action.

### Requirement 4

**User Story:** AS a user, I want the calendar layout to remain readable across device sizes, so that date navigation and event content remain accessible.

#### Acceptance Criteria

1. WHEN the available width is below 720 points, THE system SHALL present the context toolbar, month grid, and day timeline in a single vertical flow.
2. WHEN the available width is at least 720 points, THE system SHALL present the month grid and timeline as two coordinated columns.
3. WHEN dynamic type increases text size, THE system SHALL preserve a minimum 44 point interaction area for calendar controls.
