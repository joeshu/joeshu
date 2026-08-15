# Requirements Document

## Introduction

将 PaperTodo 日历模式优化为可用于日常工作的商业化日程工作台，统一日期导航、月视图、日程列表、快速新增、状态反馈和多尺寸布局。

## Glossary

- **月视图**：展示完整月份网格和事件密度标记的日历视图。
- **日程视图**：展示选中日期事件列表、周日期条和当天执行状态的视图。
- **日历工具栏**：展示日历标题、日期上下文、月份导航、视图切换和新增入口的顶部区域。

## Requirements

### Requirement 1

**User Story:** AS a user, I want a stable calendar toolbar, so that I can navigate and create events from the same place.

#### Acceptance Criteria

1. WHEN calendar mode is displayed, THE system SHALL show the current month, selected date, today action, previous-month action, next-month action, view selector, and add-event action.
2. WHEN the user changes the view selector, THE system SHALL preserve the selected date and display the chosen calendar view.
3. WHEN the user activates the add-event action, THE system SHALL open the event form using the selected date.

### Requirement 2

**User Story:** AS a user, I want month and agenda views, so that I can switch between planning and execution tasks.

#### Acceptance Criteria

1. WHEN the user selects month view, THE system SHALL show the complete calendar month and the selected date timeline.
2. WHEN the user selects agenda view, THE system SHALL show the selected date timeline as the primary content area.
3. WHEN the user selects a date outside the current month, THE system SHALL move the month view to that date's month and preserve the selected date.

### Requirement 3

**User Story:** AS a user, I want the calendar to remain readable on iPhone and iPad, so that controls and events retain clear hierarchy.

#### Acceptance Criteria

1. WHEN the available width is below 720 points, THE system SHALL present calendar content in a single vertical flow.
2. WHEN the available width is at least 720 points, THE system SHALL present month and agenda content in a non-overlapping two-column layout.
3. WHEN dynamic type increases text size, THE system SHALL preserve accessible control areas and allow event text to wrap within its container.

### Requirement 4

**User Story:** AS a user, I want event editing to validate the complete date and time, so that cross-day events can be created reliably.

#### Acceptance Criteria

1. WHEN the end date-time is later than the start date-time, THE system SHALL enable event saving.
2. WHEN the end date-time is equal to or earlier than the start date-time, THE system SHALL show a validation message and disable event saving.
3. WHEN a cross-day event is edited, THE system SHALL preserve both date values and time values in the form.
