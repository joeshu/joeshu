# 接口与数据契约

## SwiftData 模型

### `Paper`

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| `id` | `UUID` | 唯一标识 |
| `kindRaw` | `String` | `todo` 或 `note` |
| `title` | `String` | 纸片标题 |
| `body` | `String` | Markdown 正文或备用内容 |
| `isPinned` | `Bool` | 是否置顶 |
| `createdAt` | `Date` | 创建时间 |
| `updatedAt` | `Date` | 修改时间 |
| `isCollapsed` | `Bool` | 是否折叠 |
| `todoItems` | `[TodoItem]` | 级联待办关系 |

### `TodoItem`

包含 `id`、`text`、`isDone`、`sortIndex`、`createdAt`、可选的 `estimatedMinutes`、`scheduledStart`、`scheduledEnd`、`isAllDay`、`quadrantRaw` 和可选的 `paper` 关系。`quadrant` 计算属性将 `quadrantRaw` 映射为四象限枚举。`isAllDay` 为真时，排期区域使用日期区间展示并从小时网格分离。

### `CalendarEvent`

包含 `id`、`title`、`startTime`、`endTime`、`isAllDay`、`categoryRaw`、`isCompleted` 和可选 `note`。`category` 计算属性映射个人、工作、杂事、重要、休闲、日常、购物和出行八种分类。全天事件使用开始日期到结束日期次日的半开区间。

## 支持层接口

- `SharedContainer.storeURL()`：返回 App Group SwiftData store 地址。
- `SharedContainer.makeModelContainer()`：创建共享 SwiftData 容器。
- `SharedContainer.seedCalendarEvents(in:)`：当事件为空时插入示例事件。
- `CalendarDisplayMode`：日历页面的瞬时显示状态，包含月视图、周视图和日程视图，不写入 SwiftData。
- `NoteImageStore.save(data:referencedNames:)`：压缩并保存图片，返回生成的资源名。
- `NoteImageStore.referencedNames(in:)`：从 Markdown 中提取合法图片资源名。
- `NoteImageStore.deleteReferenced(in:preserving:)`：删除当前正文引用且未被保留集合引用的图片。
- `NoteImageStore.cleanupOrphans(referencedNames:)`：清理未被引用的合法 JPG 资源。
- `NoteExportStore.writeMarkdownPackage(title:body:)`：生成临时 Markdown 导出目录。

## 设置接口

`AppSettings` 使用 `UserDefaults` 持久化以下设置：

- `appearance`：跟随系统、浅色、深色。
- `colorScheme`：暖纸、墨、林、霞。
- `todoVisualSize`：小、中、大。
- `autoClearDone`：完成后自动清除。
- `renderStrength`：纯文本、轻渲染、完整渲染。
- `homeMode`：今日、纸片、日历、四象限，默认值为今日。

今日页面通过 `@Query` 读取 `CalendarEvent`，通过 `Paper` 关系聚合未完成 `TodoItem`。

## Widget 接口

`PaperTodoEntry` 暴露 `date`、`pendingCount` 和 `doneCount`。`Provider` 实现 `placeholder`、`getSnapshot` 和 `getTimeline`，时间线默认每 30 分钟刷新一次。

Widget 同时暴露 `todayPendingCount`、`scheduledMinutes` 和 `nextTask`，用于展示今日剩余任务、今日排期时长和下一项安排。
