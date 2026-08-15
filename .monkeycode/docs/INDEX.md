# UnifiedVIP 与 PaperTodo 项目文档

## 项目概览

当前仓库包含两个相互独立的代码面：

- `UnifiedVIP`：根目录 Node.js 构建工具，用于读取 `configs/` 和 `src/apps/` 中的应用配置，生成代理平台脚本、JSON 配置和 `rewrite.conf`。
- `PaperTodo`：`PaperTodo-iOS/` 下的 SwiftUI iOS 应用，提供纸片列表、待办、Markdown 笔记、日历、四象限和 Widget。

两个代码面共享同一 Git 仓库和 GitHub Actions，但构建产物、运行时和数据存储彼此独立。

## 文档导航

| 文档 | 内容 |
| --- | --- |
| [ARCHITECTURE.md](ARCHITECTURE.md) | 两个代码面的系统边界、模块关系和主要数据流 |
| [INTERFACES.md](INTERFACES.md) | Node.js 配置接口、构建产物、SwiftData 模型和 Widget 接口 |
| [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) | 环境要求、开发流程、验证命令和 CI 流程 |
| [模块/UnifiedVIP.md](模块/UnifiedVIP.md) | Node.js 构建器和运行时处理引擎 |
| [模块/PaperTodo-iOS.md](模块/PaperTodo-iOS.md) | SwiftUI 应用、SwiftData、图片资源和 Widget |
| [专有概念/首页模式.md](专有概念/首页模式.md) | 纸片、日历和四象限首页模式 |
| [专有概念/UnifiedVIP配置模式.md](专有概念/UnifiedVIP配置模式.md) | JSON、regex、forward、remote、game、hybrid 和 html 模式 |

## 代码入口

- Node.js 构建入口：`scripts/build.js`
- Node.js 配置校验入口：`scripts/validate.js`
- Node.js 新应用向导：`scripts/add-app.js`
- Node.js 运行时入口：由 `scripts/build.js` 组装到 `dist/Unified_VIP_Unlock_Manager_v22.js`
- iOS 应用入口：`PaperTodo-iOS/PaperTodo/PaperTodoApp.swift`
- iOS 首页入口：`PaperTodo-iOS/PaperTodo/ContentView.swift`
- Widget 入口：`PaperTodo-iOS/PaperTodoWidget/PaperTodoWidget.swift`

## 规格文档

- `.monkeycode/specs/calendar-quadrant-home/`：首页日历和四象限模式的需求、设计和历史任务清单。
- `.monkeycode/specs/global-optimization/`：全局主题、性能、交互、资源安全和错误处理的实施任务清单。

## 当前验证边界

- 根目录 Node.js 项目使用 `npm run validate` 和 `npm run build` 验证。
- iOS 项目由 GitHub Actions 在 macOS runner 上安装 XcodeGen、生成 Xcode 项目并执行无签名 Release 构建。
- 当前开发环境没有 `xcodebuild`，本地无法执行真实 iOS 编译。
