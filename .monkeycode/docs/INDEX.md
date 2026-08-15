# PaperTodo 项目文档

## 项目概览

PaperTodo 是一个基于 SwiftUI 和 SwiftData 的 iOS 个人工作台，提供纸片列表、待办、Markdown 笔记、日历、四象限和 Widget 功能。

## 文档导航

| 文档 | 内容 |
| --- | --- |
| [ARCHITECTURE.md](ARCHITECTURE.md) | 应用架构、模块关系和数据流 |
| [INTERFACES.md](INTERFACES.md) | SwiftData 模型、支持层和 Widget 接口 |
| [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) | 环境要求、构建、验证和 CI 流程 |
| [模块/PaperTodo-iOS.md](模块/PaperTodo-iOS.md) | SwiftUI 应用、SwiftData、图片资源和 Widget |
| [专有概念/首页模式.md](专有概念/首页模式.md) | 纸片、日历和四象限首页模式 |

## 代码入口

- 应用入口：`PaperTodo-iOS/PaperTodo/PaperTodoApp.swift`
- 首页入口：`PaperTodo-iOS/PaperTodo/ContentView.swift`
- Widget 入口：`PaperTodo-iOS/PaperTodoWidget/PaperTodoWidget.swift`
- XcodeGen 配置：`PaperTodo-iOS/project.yml`

## 规格文档

- `.monkeycode/specs/calendar-quadrant-home/`：首页日历和四象限模式的需求、设计和历史任务清单。
- `.monkeycode/specs/global-optimization/`：全局主题、性能、交互、资源安全和错误处理的实施任务清单。
- `.monkeycode/specs/papertodo-commercial-ui-upgrade/`：PaperTodo 商业化 UI、界面和视觉升级的需求、设计与优先级实施清单。

## 当前验证边界

- iOS 项目由 GitHub Actions 在 macOS runner 上安装 XcodeGen、生成 Xcode 项目并执行无签名 Release 构建。
- 当前开发环境没有 `xcodebuild`，本地无法执行真实 iOS 编译。
