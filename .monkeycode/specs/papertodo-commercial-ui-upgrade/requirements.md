# Requirements Document

## Introduction

PaperTodo 商业化 UI 升级将现有 SwiftUI 个人工作台提升为具有明确品牌识别、稳定信息层级和高端商用质感的 iOS 生产力产品。升级覆盖视觉基础、首页工作流、纸片索引、日历执行视图、四象限、详情页、设置页和无障碍体验；现有 SwiftData 数据模型、Widget、任务排期、Markdown 笔记与删除撤销能力继续保持。

## Glossary

- **Editorial Paper OS**：PaperTodo 的目标视觉方向，将纸张隐喻与现代 iOS 工作台结合。
- **今日工作台**：默认首页视角，聚合完成进度、下一项任务、时间轴和未安排任务。
- **纸片索引**：展示待办纸片和笔记纸片的内容入口。
- **工作视角导航**：今天、纸片、日历和四象限四个一级工作入口。
- **语义色彩**：按用途定义的品牌色、文字色、表面色、状态色和边界色。
- **Raised Surface**：用于重要内容和关键操作的高层级表面。

## Requirements

### Requirement 1: 视觉基础系统

**User Story:** AS a PaperTodo user, I want a consistent visual language, so that every screen feels like one premium product.

#### Acceptance Criteria

1. WHEN any PaperTodo screen renders, THE system SHALL use semantic palette, spacing, radius, typography, icon size and elevation tokens.
2. WHEN the user changes light or dark appearance, THE system SHALL preserve semantic hierarchy and readable contrast for primary text, secondary text and controls.
3. WHEN a component uses a raised surface, THE system SHALL apply the shared elevation scale and preserve the surface distinction from the canvas.
4. WHEN the user selects a paper theme, THE system SHALL change the paper atmosphere while preserving brand action semantics and event category semantics.

### Requirement 2: 今日工作台

**User Story:** AS a user planning the day, I want the first screen to explain my current workload, so that I can start the next meaningful task immediately.

#### Acceptance Criteria

1. WHEN the app opens, THE system SHALL present today as the primary work perspective.
2. WHEN today contains unfinished tasks, THE system SHALL show the date context, remaining task count, completion progress and the next scheduled task.
3. WHEN today contains scheduled events or tasks, THE system SHALL show them in one timeline with distinct task and calendar semantics.
4. WHEN today contains unscheduled tasks, THE system SHALL show the count and provide a visible path to schedule or start one task.
5. WHEN the user activates the primary quick capture action, THE system SHALL open the existing capture flow without losing the current date context.

### Requirement 3: 工作视角导航

**User Story:** AS a user switching between planning contexts, I want predictable navigation, so that I can move between execution and review without losing state.

#### Acceptance Criteria

1. WHEN the user switches between today, papers, calendar and quadrant perspectives, THE system SHALL preserve each perspective's relevant selection and filter state.
2. WHEN the app runs on iPhone, THE system SHALL provide reachable labeled top-level navigation within the safe area.
3. WHEN the app runs on iPad width, THE system SHALL provide an adaptive navigation layout with a persistent work area and non-overlapping content.
4. WHEN a top-level action is icon-only, THE system SHALL provide an accessibility label and a minimum 44pt interaction area.

### Requirement 4: 纸片索引

**User Story:** AS a user managing multiple work materials, I want paper cards to reveal type, progress and next action, so that I can scan my workspace efficiently.

#### Acceptance Criteria

1. WHEN the paper index renders, THE system SHALL distinguish todo papers and note papers through icon, label and layout semantics.
2. WHEN a todo paper contains unfinished work, THE system SHALL show completion progress and the next relevant task when available.
3. WHEN a paper is pinned or collapsed, THE system SHALL show the state through a stable visual indicator and preserve the existing action behavior.
4. WHEN the paper index is empty or filtered to zero results, THE system SHALL provide a clear explanation and an actionable creation path.

### Requirement 5: 日历商业化视觉

**User Story:** AS a user planning capacity, I want the calendar to distinguish planning, execution and conflict states, so that I can adjust my schedule with confidence.

#### Acceptance Criteria

1. WHEN calendar mode renders, THE system SHALL group month context, selected date, view selection, navigation, filters and creation actions into a stable toolbar hierarchy.
2. WHEN the user views month, week or agenda content, THE system SHALL preserve selected date and use consistent event, todo, completed and conflict semantics.
3. WHEN a date contains multiple items, THE system SHALL preserve stable cell height and express overflow with a count indicator.
4. WHEN a selected date contains overlapping or over-capacity plans, THE system SHALL show an explicit status message and a recoverable path to inspect the conflict.

### Requirement 6: 四象限与详情页

**User Story:** AS a user prioritizing work, I want the quadrant and paper detail screens to share the same visual system, so that prioritization and execution feel connected.

#### Acceptance Criteria

1. WHEN the quadrant screen renders, THE system SHALL show four clearly named regions with distinct low-saturation semantic colors and task counts.
2. WHEN a quadrant contains tasks, THE system SHALL provide visible completion, edit, move and source-paper actions with accessible labels.
3. WHEN a todo paper renders, THE system SHALL show title, completion summary, task list and task creation entry in a stable hierarchy.
4. WHEN a note paper renders, THE system SHALL separate title, editing, preview and document actions while preserving Markdown and image workflows.

### Requirement 7: 交互质量与无障碍

**User Story:** AS a user with different accessibility and motion preferences, I want every key action to remain understandable and operable, so that visual polish does not reduce usability.

#### Acceptance Criteria

1. WHEN a user taps a primary or secondary control, THE system SHALL provide a clear pressed state within the platform interaction rhythm.
2. WHEN Dynamic Type increases, THE system SHALL allow titles, task text, event text and controls to wrap without overlap or loss of action access.
3. WHEN VoiceOver reads an interactive screen, THE system SHALL expose meaningful labels, values, selected states and action hints in visual order.
4. WHEN Reduce Motion is enabled, THE system SHALL reduce non-essential transitions while preserving state feedback.
5. WHEN a save, delete, undo or completion operation fails, THE system SHALL show a clear cause and a recoverable next action while preserving user input where applicable.

### Requirement 8: 商用验收基线

**User Story:** AS a product owner, I want a repeatable visual quality baseline, so that future UI changes retain the commercial standard.

#### Acceptance Criteria

1. WHEN the UI upgrade is reviewed, THE system SHALL cover iPhone portrait, iPhone landscape, iPad portrait and iPad landscape representative layouts.
2. WHEN the UI upgrade is reviewed, THE system SHALL cover light mode, dark mode, all paper themes, empty states, long text and populated states.
3. WHEN the UI upgrade is reviewed, THE system SHALL verify touch target, contrast, Dynamic Type, VoiceOver and Reduce Motion behavior for key workflows.
4. WHEN a visual component is added after this upgrade, THE system SHALL use the shared design system tokens and component patterns.
