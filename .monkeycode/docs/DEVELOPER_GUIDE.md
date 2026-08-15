# 开发者指南

## 环境

### UnifiedVIP

- Node.js 18 或兼容版本。
- 依赖通过 `npm install` 安装，核心开发依赖为 `ajv`。
- 根目录配置源在 `configs/`，核心运行时代码在 `src/`。

### PaperTodo iOS

- iOS Deployment Target：17.0。
- Swift：5.9。
- XcodeGen 用于从 `PaperTodo-iOS/project.yml` 生成 Xcode 项目。
- 本地开发环境没有 `xcodebuild` 时，使用 GitHub Actions 验证 iOS 编译。

## 常用命令

```bash
# 安装 Node.js 依赖
npm install

# 校验应用注册表和配置
npm run validate

# 生成 dist 产物
npm run build

# 构建并检查 dist
npm run dev
```

iOS 项目在 macOS 环境中使用：

```bash
# 进入 iOS 项目
cd PaperTodo-iOS

# 生成 Xcode 项目
xcodegen generate

# 执行无签名 Release 构建
xcodebuild -project PaperTodo.xcodeproj -scheme PaperTodo -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY='' build
```

## 新增 UnifiedVIP 应用

运行 `npm run add-app`，按向导输入应用 ID、显示名称、域名、API 路径、处理模式、优先级和描述。向导会更新 `src/apps/_index.js`。完成后依次执行：

1. `npm run validate`
2. `npm run build`
3. 检查 `dist/configs/` 和主脚本。

## iOS 数据约定

- 所有 SwiftData 模型通过 `SharedContainer` 创建，应用和 Widget 使用同一个 App Group。
- 修改待办状态、排序或删除后更新 `Paper.updatedAt`，并刷新 Widget 时间线。
- Markdown 图片引用使用 `NoteImageStore` 提供的 UUID `.jpg` 资源名。
- 保存操作应处理 `modelContext.save()` 错误并保留用户输入。
- 页面异步任务需要在页面离开或对象变化时取消或验证代际标识。

## CI 流程

### `Build and Deploy`

`.github/workflows/build.yml` 在 `main` 或 `master` 推送时执行 Node.js 依赖安装、`npm run build`、产物验证，并部署到 GitHub Pages 和 `gh-pages` 分支。

### `PaperTodo iOS Build`

`.github/workflows/papertodo-ios.yml` 仅在 `PaperTodo-iOS/**` 变化时触发。流程在 macOS 15 上安装 XcodeGen、生成 Xcode 项目、构建无签名 Release App、打包 IPA 并上传 artifact。

## 变更验证

提交前执行 `git diff --check`。涉及根目录脚本时执行 `npm run validate` 和 `npm run build`。涉及 iOS 源代码时推送后使用 `gh run list --workflow "PaperTodo iOS Build"` 检查构建结果，同时检查 `Build and Deploy`。

## 文档与安全边界

- 项目文档统一放在 `.monkeycode/docs/`。
- 文档只描述已存在的代码、配置和工作流。
- 不在代码、文档或示例中写入 API key、密码、令牌和内部凭证。
- 生成产物目录 `dist/` 由构建脚本重建，手工修改不会成为稳定源代码。
