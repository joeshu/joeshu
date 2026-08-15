# PaperTodo UI 商业化升级实施清单

执行顺序：P0 基础系统 -> P1 核心工作流 -> P2 重点页面 -> P3 质量验收。

## P0：视觉基础与导航骨架

- [x] 1. 建立 PaperTodo 商业化 Design System
  - 对应 Requirements 1.1-1.4、8.4；修改 `Support/DesignSystem.swift` 和 `Support/PaperTheme.swift`。
  - 增加 `PaperSpacing`、`PaperElevation`、`PaperTypography`、`PaperIconSize` 和语义化 Surface 组件。
  - 收敛颜色、边框、渐变、阴影、圆角和按钮状态，保留四种用户主题和 Light/Dark 支持。

- [x] 1.1 统一基础交互组件
  - 对应 Requirements 3.4、7.1；抽取主按钮、次按钮、图标按钮、筛选 chip、空状态和进度组件。
  - 为图标按钮补充 accessibility label、hint 和最小 44pt 触控区域。
  - 统一 pressed、disabled、selected、loading 和 destructive 状态。

- [ ] 1.2* 编写 Design System 状态测试
  - 对应 Design Correctness Properties 1、6、7；覆盖 Light/Dark、四种主题、Dynamic Type 和 Reduce Motion。
  - 验证组件在代表性尺寸下无文本、图标和按钮重叠。

- [x] 2. 重构一级工作视角导航
  - 对应 Requirements 3.1-3.3；修改 `Views/HomeModeContent.swift` 和 `ContentView.swift`。
  - iPhone 使用“今天、纸片、日历、四象限”四项带标签导航。
  - iPad 使用自适应持久导航区域与右侧内容区，保持现有 `HomeMode` 状态。
  - 将搜索、配色、设置和纸片快捷入口收敛到次级操作区域。

- [x] 2.1 统一首页安全区与滚动边界
  - 对应 Requirements 3.2、3.3、7.2；确保导航、底部胶囊栏、撤销 banner 和内容滚动互不遮挡。
  - 检查横屏、动态字体和底部手势区域下的可操作性。

- [ ] 2.2* 验证导航状态保持
  - 对应 Requirements 3.1；验证模式切换后纸片筛选、日历选中日期、日历视图和四象限状态保持。

- [ ] 3. 检查点：完成 P0 基础系统与导航骨架
  - 确保所有测试通过,如有疑问请询问用户。

## P1：今日工作台与核心执行流

- [x] 4. 重构 Today 页面信息层级
  - 对应 Requirements 2.1-2.5；修改 `Views/TodayHomeView.swift`。
  - 将日期上下文、完成进度、已安排时长和未安排任务整理为统一状态头部。
  - 将当前 `planningCard` 调整为轻量 Progress Summary，保留现有数据和操作。
  - 保留快速记录和今日回顾功能，减少同层级按钮数量。

- [x] 4.1 新增 Next Up 工作区
  - 对应 Requirements 2.2、2.3、2.4；从现有排期待办和事件派生下一项任务。
  - 展示任务标题、开始时间、预计时长、来源和完成入口。
  - 空状态提供进入排期或快速记录的可执行入口。

- [x] 4.2 升级统一时间轴
  - 对应 Requirements 2.3；调整今日事件与排期待办的视觉分组、图标和当前时间标记。
  - 任务和日历事件使用图标、辅助标签和布局语义共同区分。
  - 完成项降低视觉权重并保留历史可读性。

- [ ] 4.3* 验证 Today 数据与交互回归
  - 对应 Design Correctness Properties 3、4、5；覆盖空数据、任务完成、事件完成、未安排任务和快速记录。
  - 验证 Widget 刷新、保存失败和撤销行为保持原有结果。

- [ ] 5. 检查点：完成 Today 核心工作流
  - 确保所有测试通过,如有疑问请询问用户。

## P1：纸片索引与内容入口

- [x] 6. 重构纸片索引头部与筛选
  - 对应 Requirements 4.1、4.4；修改 `Views/HomeModeContent.swift` 及纸片列表相关视图。
  - 建立“纸片 / 你的工作内容”标题层级，整理搜索、新建和筛选入口。
  - 统一全部、待办、笔记、未完成筛选的 chip 状态、数量和触控区域。

- [x] 6.1 升级 PaperCard
  - 对应 Requirements 4.1-4.3；调整类型标识、完成进度、下一项任务、排期上下文和置顶状态。
  - 采用 flat、raised 两级表面，避免所有纸片使用相同阴影。
  - 处理长标题、无标题、无任务、已完成和折叠状态。

- [x] 6.2 完善纸片空状态
  - 对应 Requirements 4.4；提供新建待办、新建笔记和筛选无结果的清晰路径。
  - 保持创建入口与现有 `addPaper` 行为一致。

- [ ] 6.3* 验证纸片索引状态
  - 对应 Requirements 4.2-4.4；验证排序、筛选、置顶、折叠、预览、删除和撤销不受视觉改造影响。

## P2：日历与四象限商业化视觉

- [x] 7. 重构日历上下文工具栏
  - 对应 Requirements 5.1、5.2；修改 `Views/CalendarHomeView.swift` 中的工具栏组件。
  - 将月份、选中日期、视图切换、今天、筛选、前后月份和新增动作按优先级分层。
  - 保持月、周、日程视图切换和选中日期状态。

- [x] 7.1 升级月视图和周视图视觉密度
  - 对应 Requirements 5.2、5.3；保持日期单元格稳定高度、事件分类点、溢出数量和选中状态。
  - 为排期、完成、跨日和冲突状态建立统一表达。
  - 在 iPad 双列布局中保持月视图和日程内容边界稳定。

- [x] 7.2 升级日程执行视图
  - 对应 Requirements 5.2、5.4；突出当前时间、日程完成进度、冲突提示和排期任务。
  - 保留已有事件编辑、任务排期、自然语言新增和筛选行为。

- [ ] 7.3* 验证日历视觉回归
  - 对应 Design Correctness Properties 5；覆盖跨日事件、冲突、超 8 小时计划、筛选、完成状态和 iPhone/iPad 布局。

- [x] 8. 重构四象限区域视觉
  - 对应 Requirements 6.1、6.2；修改 `Views/QuadrantHomeView.swift`。
  - 四个区域采用低饱和语义色、明确标题、说明、数量和新增入口。
  - 任务行统一完成、编辑、移动、来源纸片和长文本行为。

- [ ] 8.1* 验证四象限交互回归
  - 对应 Requirements 6.2；覆盖新增、编辑、移动、完成、保存失败、长标题和空象限。

- [x] 9. 检查点：完成 P2 重点工作视图
  - 确保所有测试通过,如有疑问请询问用户。

## P2：详情页与设置页

- [x] 10. 升级待办纸片详情页
  - 对应 Requirements 6.3；修改 `Views/TodoPaperView.swift`。
  - 重做标题、完成摘要、任务列表、任务新增和拖放删除区域的视觉层级。
  - 保留排序、撤销重做、自动清除、排期、保存错误和 Widget 刷新逻辑。

- [x] 10.1 升级笔记纸片详情页
  - 对应 Requirements 6.4；修改 `Views/NotePaperView.swift` 及编辑器相关视图。
  - 建立标题、编辑/预览、保存状态、图片、导出和任务导入的清晰操作层级。
  - 保留 Markdown 高亮、图片安全边界和异步导入生命周期。

- [ ] 10.2* 验证详情页输入与保存回归
  - 对应 Requirements 6.3、6.4、7.5；覆盖长文本、动态字体、保存失败、页面离开和异步图片导入。

- [x] 11. 重构设置页信息架构
  - 对应 Requirements 1.4、8.4；修改 `Views/SettingsView.swift`。
  - 增加首页设置分组，整理外观、首页、待办、笔记、通知、数据与关于入口。
  - 保留现有设置持久化字段和主题预览。

## P3：质量基线与交付验收

- [x] 12. 完成全局无障碍与动态字体审查
  - 对应 Requirements 7.1-7.5；审查所有一级导航、日期单元格、事件行、任务行、象限操作和 Sheet 控件。
  - 补充 accessibilityLabel、accessibilityValue、accessibilityHint、selected trait 和 decoration semantics。
  - 验证最大 Dynamic Type 下文本换行、控件触达和滚动边界。

- [x] 12.1 完成动效与 Reduce Motion 适配
  - 对应 Requirements 7.1、7.4；统一 150-300ms 微交互节奏，保证动画可中断。
  - 为任务完成、导航切换、日期选中、删除撤销和 Sheet 入口提供因果明确的反馈。

- [ ] 12.2* 执行跨设备视觉回归
  - 对应 Requirements 8.1-8.3；覆盖 iPhone portrait、iPhone landscape、iPad portrait、iPad landscape、Light/Dark、四种主题和空/满数据。

- [ ] 13. 完成代码质量与构建验证
  - 对应 Requirement 8；执行 `git diff --check`，清理调试输出和重复样式。
  - 通过 GitHub Actions `PaperTodo iOS Build` 验证 XcodeGen、无签名构建和 Release 构建。
  - 检查新增组件只使用语义 token，避免回退到页面级 raw color、shadow 和任意间距。
  - 当前已完成 `git diff --check`、调试输出检查、重复文档清理和新增 UI 结构审查；本地缺少 `swift` 与 `xcodebuild`，CI 构建验证待在 macOS runner 上执行。

- [ ] 13.1 检查点：完成 PaperTodo UI 商业化升级
  - 确保所有测试通过,如有疑问请询问用户。
