# 接口与数据契约

## Node.js 配置接口

### 基础配置

每个 `configs/*.json` 配置至少包含：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `name` | string | 显示名称 |
| `mode` | string | 处理模式 |
| `urlPattern` | string | URL 正则匹配表达式 |
| `config` | object | 处理模式具体参数 |

`scripts/validate.js` 允许的模式为 `json`、`regex`、`forward`、`remote`、`game`、`hybrid`、`html`。

### 模式参数

| 模式 | 主要参数 | 运行行为 |
| --- | --- | --- |
| `json` | `config.processor` | 使用处理器修改解析后的 JSON |
| `regex` | `config.regexReplacements` | 对响应文本执行正则替换 |
| `forward` | `config.forwardUrl` | 将请求转发到目标地址 |
| `remote` | `config.remoteUrl` | 获取并返回远程内容 |
| `game` | `config.gameResources` | 修改匹配的数值资源字段 |
| `hybrid` | `processor` 或 `regexReplacements` | 组合 JSON 处理和文本替换 |
| `html` | `config.htmlReplacements` | 对 HTML 内容执行替换 |

### 处理器接口

`src/engine/processor-factory.js` 提供 `setFields`、`mapArray`、`filterArray`、`clearArray`、`deleteFields`、`sliceArray`、`shiftArray`、`processByKeyPrefix`、`notify`、`compose`、`when` 和 `sceneDispatcher` 等处理器。

处理器统一接收 `(obj, env)`，返回修改后的对象。路径使用点号和数组下标表达式，例如 `data.items[0].enabled`。模板字符串使用 `{{path.to.value}}` 读取当前对象值。

### 构建产物

`npm run build` 生成：

- `dist/Unified_VIP_Unlock_Manager_v22.js`：组装后的主运行时脚本。
- `dist/rewrite.conf`：根据应用注册表生成的 rewrite 配置。
- `dist/configs/*.json`：面向运行时远程加载的独立应用配置。

## PaperTodo SwiftData 模型

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

包含 `id`、`text`、`isDone`、`sortIndex`、`createdAt`、`quadrantRaw` 和可选的 `paper` 关系。`quadrant` 计算属性将 `quadrantRaw` 映射为四象限枚举。

### `CalendarEvent`

包含 `id`、`title`、`startTime`、`endTime`、`categoryRaw`、`isCompleted` 和可选 `note`。`category` 计算属性映射八种事件分类。

### 支持层接口

- `SharedContainer.makeModelContainer()`：创建共享 SwiftData 容器。
- `SharedContainer.seedCalendarEvents(in:)`：当事件为空时插入示例事件。
- `NoteImageStore.save(data:referencedNames:)`：压缩并保存图片，返回生成的资源名。
- `NoteImageStore.referencedNames(in:)`：从 Markdown 中提取合法图片资源名。
- `NoteImageStore.deleteReferenced(in:preserving:)`：删除当前正文引用且未被保留集合引用的图片。
- `NoteImageStore.cleanupOrphans(referencedNames:)`：清理未被引用的合法 JPG 资源。
- `NoteExportStore.writeMarkdownPackage(title:body:)`：生成临时 Markdown 导出目录。

## Widget 接口

`PaperTodoEntry` 暴露 `date`、`pendingCount` 和 `doneCount`。`Provider` 实现 `placeholder`、`getSnapshot` 和 `getTimeline`，时间线默认每 30 分钟刷新一次。
