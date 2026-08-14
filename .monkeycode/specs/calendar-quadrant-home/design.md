# Calendar And Quadrant Home

Feature Name: calendar-quadrant-home
Updated: 2026-08-14

## Description

在现有 PaperTodo 首页增加三种模式：纸片列表、日历视图、四象限视图。日历视图使用月历网格承载时间安排，四象限视图承载优先级整理。两种视图复用现有 `Paper` 和 `TodoItem`，通过轻量派生数据展示，不引入外部服务或数据库迁移。

## Architecture

```mermaid
graph TD
    A[ContentView] --> B[HomeModePicker]
    A --> C[PaperListHome]
    A --> D[CalendarHomeView]
    A --> E[QuadrantHomeView]
    D --> F[CalendarViewModel]
    E --> G[QuadrantViewModel]
    F --> H[Paper and TodoItem]
    G --> H
```

`ContentView` 负责模式状态和导航，子视图负责单一展示场景。现有模型继续作为数据源；缺少日期或象限字段时使用确定性派生规则，保证旧数据立即可展示。

## Components And Interfaces

- `HomeMode`: 首页模式枚举，包含 `list`、`calendar`、`quadrant`。
- `HomeModePicker`: 首页顶部的分段模式切换控件。
- `CalendarHomeView`: 月份导航、日期网格、选中日期任务列表。
- `QuadrantHomeView`: 四象限网格和任务卡片。
- `CalendarTask`: 从 `Paper` 和 `TodoItem` 派生的日历任务。
- `QuadrantTask`: 从待办项目派生的象限任务。

## Data Models

现有 `Paper` 和 `TodoItem` 保持不变。任务日期使用 `TodoItem.createdAt` 作为首轮日历归属日期。四象限分类使用确定性规则：未完成任务按文本标签和任务状态推导默认象限；用户手动移动产生的分类暂存在视图状态中，后续可升级为模型字段。

## Correctness Properties

- 每个可见待办最多出现在一个日历日期和一个四象限区域。
- 月历网格始终包含完整的周行，日期顺序按系统日历排序。
- 四象限区域的标题、颜色和优先级语义保持固定映射。
- 视图切换不会修改 `Paper` 或 `TodoItem` 内容。

## Error Handling

- 无任务日期显示空状态和新增入口。
- 无待办四象限显示空状态。
- 任务打开失败时保留当前视图，并通过现有导航路径处理可用的 `Paper`。

## Test Strategy

- 单元测试日期网格跨月、月初星期偏移和空月份状态。
- 单元测试四象限默认分类和任务完成状态。
- UI 测试首页三种模式切换、月份切换、任务打开和象限显示。
- 在 iPhone 和 iPad 尺寸下验证网格不重叠、标题不截断和按钮可触达。
