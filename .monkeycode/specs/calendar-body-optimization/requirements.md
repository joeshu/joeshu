# Requirements Document

## Introduction

优化 PaperTodo 日历模式的月历信息密度和日时间线交互，使跨日事件、事件分类、完成状态和日程数量在小屏设备上保持清晰。

## Requirements

### Requirement 1

**User Story:** AS a user, I want the month grid to remain compact, so that I can scan a complete month without oversized event labels.

#### Acceptance Criteria

1. WHEN a month grid cell contains events, THE system SHALL show category color markers and the overflow count.
2. WHEN a month grid cell contains no events, THE system SHALL preserve the same stable cell height as neighboring cells.
3. WHEN the user selects a date, THE system SHALL preserve the selected-date highlight and event count accessibility label.

### Requirement 2

**User Story:** AS a user, I want cross-day events to explain their current-day context, so that I can understand an event without opening it.

#### Acceptance Criteria

1. WHEN an event starts and ends on the selected date, THE system SHALL show its start and end times.
2. WHEN an event covers the selected date between its start and end dates, THE system SHALL show an all-day continuation label.
3. WHEN an event starts before the selected date or ends after the selected date, THE system SHALL show the relevant continuation boundary.

### Requirement 3

**User Story:** AS a user, I want to complete an event from the timeline, so that calendar maintenance takes one direct action.

#### Acceptance Criteria

1. WHEN the user opens an event context menu, THE system SHALL provide an action matching the event completion state.
2. WHEN the completion action succeeds, THE system SHALL persist the new completion state and update the event appearance.
3. IF saving the completion state fails, THE system SHALL restore the previous state and show an error message.
