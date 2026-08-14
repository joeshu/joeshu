# 全局优化实施计划

目标：从全局出发，统一界面视觉与设计令牌、提升 Markdown 与首页渲染性能、修复已审查出的功能 Bug 并补齐缺失交互。

- [ ] 1. 日历模式接入全局主题
  - [ ] 1.1 日历背景与卡片接入主题令牌
    - 将 `CalendarHomeView.swift` 整屏背景 `Color(hex: "E8EEF5")`、`CalendarBackdrop` 渐变与网格线改用 `theme.backgroundGradient`/`theme.canvas`/`theme.paperBorder`（行 87、135、147）
    - 将月卡 `Color.white.opacity`/`Color.white` 卡片底与时间线卡材质改为 `theme.surfaceGradient` + `theme.paperBorder`，统一深浅模式（行 275、366、437）
    - 圆角复用 `PaperRadius.shell`/`block`，消除 24/28/24 硬编码（行 274、366）
  - [ ] 1.2 日历文字与选中高亮接入主题
    - 正文近黑色 `Color(hex: "1C1C1E")` 改用 `theme.text`（行 249、258、288、338、345、430）
    - 选中日/周条/底部 tab 的 `Color(hex: "4A7BF7")` 改用 `theme.accent`（行 290、291、384、491、495）
    - 浅灰 `Color(hex: "C7C7CC")` 改为 `theme.weakText` 或提升对比度（行 266、305、382、412）
  - [ ] 1.3 统一日历底部导航与全局导航范式
    - 重构 `CalendarTabBar`：将日历底部三个 tab（日历/应用/个人中心）改为与全局一致的分段/工具栏切换，消除图标语义与实际跳转不符问题（CalendarHomeView.swift:467-508、HomeModeContent.swift:44-49）
    - 删除"应用→list、个人中心→quadrant"的错误映射，统一模式切换入口
  - [ ]* 1.4 深色模式一致性校验
    - 校验日历、列表、四象限三模式在 warm/ink/forest/rose 各主题深浅色下的背景、卡片、文字对比度一致

- [ ] 2. 全局颜色派生与无障碍适配
  - [ ] 2.1 事件分类与象限颜色并入主题派生
    - `EventCategory.tagBackground/tagText/ringColor` 由主题派生并提供深色变体，消除 18 个硬编码 `Color(hex:)`（Paper.swift:27-62）
    - `Quadrant.color` 从 palette 派生或提供 dark 版本，替换 `4A7BF7/5B9BD5/FFB04A/4CD964` 硬编码（Paper.swift:133-140）
    - `Color(hex:)` 结果缓存到静态字典，避免每次 getter 重复解析（Paper.swift:151-159）
  - [ ] 2.2 统一同语义颜色
    - `QuadrantHomeView` 未勾选复选框与操作菜单 `Color.secondary` 统一为 `theme.weakText`（行 96、132）
    - `AnimatedCheckCircle` 未选中描边与勾选图标接入主题（DesignSystem.swift:72-75）
    - 删除 dropZone `Color.red` 改用 `theme.danger`（TodoPaperView.swift:295）
    - 首页 segmented Picker 增加 `.tint(theme.active)` 与设置页一致（HomeModeContent.swift:17-23）
  - [ ] 2.3 统一触控目标尺寸
    - 日历"更多选项"/"+"按钮、周条日按钮触控区扩至 ≥44pt（CalendarHomeView.swift:256-260、335-341、382-393）
    - `QuadrantHomeView` 复选框与 ellipsis 菜单、`PaperFilterBar` 筛选胶囊补足最小触控尺寸（QuadrantHomeView.swift:95-99、ContentView.swift:316-317）
  - [ ] 2.4 动态字体适配
    - `MarkdownTextView` 标题固定 pt 改为可缩放样式（MarkdownTextView.swift:48）
    - `NotePaperView`/`MarkdownEditorTextView` 编辑器 17pt 固定字号改用 `UIFontMetrics.scaledFont`（MarkdownEditorTextView.swift:21）
    - `TodoPaperView` 新增待办输入框与日历事件行固定高度改为自适应（TodoPaperView.swift:105、MarkdownTextView.swift:294-304）
  - [ ] 2.5 无障碍标签修复
    - `TimelineEventRow` accessibilityLabel 改为"打开 X 进行编辑"，与点击动作一致并加 `.isButton`（CalendarHomeView.swift:443）
    - `SettingsView` PickerRow 合并为单个可交互元素（SettingsView.swift:104-121）
  - [ ]* 2.6 辅助功能与深色模式测试
    - 校验各模式 VoiceOver 标签可读、触控目标 ≥44pt、深色模式无白底

- [ ] 3. 检查点 - 界面优化完成，确保编译通过，如有疑问请询问用户

- [x] 4. 提升 Markdown 渲染与首页计算性能
  - [x] 4.1 编辑器增量高亮与防抖
    - `MarkdownEditorTextView.textViewDidChange` 增加 150-300ms 防抖，避免每次击键全量 `AttributedString(markdown:)` 解析（MarkdownEditorTextView.swift:56-69）
    - 防抖期间保留当前高亮，避免输入闪烁
  - [x] 4.2 解析下沉与缓存
    - `MarkdownTextView.inline(_:)` 的 `AttributedString(markdown:)` 解析下沉到 init 一次性完成，块级与内联均不再在 body 求值时重复解析（MarkdownTextView.swift:144-166）
  - [x] 4.3 首页 computed 链聚合
    - 合并 `sortedPapers → activePapers → visiblePapers → filterCounts` 为单次遍历构建索引，消除每次渲染的多重全量 filter/sort（ContentView.swift:16-63）
    - `PaperCard.summary/detailText` 笔记摘要只截取前 N 字符再正则/计词，避免每 60 秒全量扫描（ContentView.swift:492-505）
  - [x] 4.4 启动清理与图片加载异步化
    - `PaperTodoApp` 的 `cleanupOrphanedImages` 移到后台队列，避免启动阻塞主线程（PaperTodoApp.swift:30-38）
    - `NoteImageStore.referencedNames(in:)` 正则提升为 `static let` 一次性编译（NoteImageStore.swift:93-111）
    - `NoteImageStore.image(named:)` 同步主线程解码改为异步加载 + 占位图（NoteImageStore.swift:67-85）
  - [x] 4.5 undo/redo 快照优化
    - `TodoPaperView` undo 快照改为字段级回滚或复用对象 `id`，避免删除重建整个列表（TodoPaperView.swift:348-377）
  - [ ]* 4.6 渲染与计算性能基准测试
    - 大笔记连续输入、长列表滚动、多事件日历下测量主线程阻塞与帧率

- [ ] 5. 检查点 - 性能优化完成，确保编译通过，如有疑问请询问用户

- [ ] 6. 修复功能 Bug
  - [x] 6.1 修复筛选计数单位错误
    - `filterCounts.pending` 改为统计含未完成项的纸片数，与筛选结果一致（ContentView.swift:52-63）
  - [x] 6.2 修复 autoClearDone 与 undo 竞态
    - 延迟删除前校验 `item` 未被删除/所属纸片未变，使用任务取消避免访问已删除对象（TodoPaperView.swift:427-436）
  - [x] 6.3 修复 undo/redo 破坏对象身份
    - `restore` 复用快照 `id` 恢复对象，保证正在编辑的 item 与外部引用在 undo 后仍有效（TodoPaperView.swift:354-365）
  - [x] 6.4 修复图片删除清空缓存
    - `NoteImageStore.delete(named:)` 只移除对应 key，避免清空整个缓存（NoteImageStore.swift:87-91）
  - [x] 6.5 删除撤销一致性
    - 删除确认后延迟窗口内多次删除时保持各纸片独立撤销机会，避免前一纸片被立即永久删除（ContentView.swift:225-241）
  - [ ]* 6.6 单元测试
    - 为筛选计数、象限推导、undo/redo 对象身份编写单元测试

- [ ] 7. 功能增强与缺失补齐
  - [x] 7.1 笔记标题重命名
    - `NotePaperView` 增加标题编辑入口，与 `TodoPaperView` 对齐（NotePaperView.swift）
  - [x] 7.2 Widget 数据主动刷新
    - 关键变更（toggle/删除/添加）后调用 `WidgetCenter.shared.reloadAllTimelines()`，消除 30 分钟滞后（PaperTodoWidget.swift、TodoPaperView.swift、NotePaperView.swift）
  - [x] 7.3 导出异步化与失败提示
    - `NoteExportStore` 导出移到后台，失败时提示用户而非静默不弹 sheet（NoteExportStore.swift、NotePaperView.swift:112-117）
  - [x] 7.4 保存失败统一反馈
    - 三个编辑页 `try? modelContext.save()` 静默吞错统一为失败提示，与 `ContentView` 的保存失败 alert 一致（TodoPaperView.swift、NotePaperView.swift、CalendarHomeView.swift）
  - [x] 7.5 空状态统一
    - `TodoPaperView` 空列表增加"还没有待办"引导文案与输入框占位符（TodoPaperView.swift:47-121）
    - 全局空状态保留模式切换入口，日历模式无数据时提供首次引导（ContentView.swift:69-87）
  - [x] 7.6 日历表单与布局修复
    - `CalendarEventFormView` 结束时间无效时保存按钮禁用并说明，而非静默改值（CalendarEventFormView.swift:88-90）
    - 月历星期表头与网格按系统 `firstWeekday` 生成，消除周一/周日起始错位（CalendarHomeView.swift:18、375）
    - 月卡/时间线卡布局改为小屏纵向堆叠、iPad 固定容器宽度，消除重叠与裁剪（CalendarHomeView.swift:45-83、309）
  - [ ]* 7.7 集成测试
    - 校验三种模式切换、任务操作、导出失败提示与空状态引导
