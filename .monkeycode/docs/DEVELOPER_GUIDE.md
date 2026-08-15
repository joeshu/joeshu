# 开发者指南

## 环境要求

- iOS Deployment Target：17.0。
- Swift：5.9。
- XcodeGen 用于从 `PaperTodo-iOS/project.yml` 生成 Xcode 项目。
- 当前开发环境没有 `xcodebuild` 时，使用 GitHub Actions 验证 iOS 编译。

## 本地构建

在 macOS 环境中执行：

```bash
# 进入 iOS 项目
cd PaperTodo-iOS

# 生成 Xcode 项目
xcodegen generate

# 执行无签名 Release 构建
xcodebuild -project PaperTodo.xcodeproj -scheme PaperTodo -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY='' build
```

## iOS 数据约定

- 所有 SwiftData 模型通过 `SharedContainer` 创建，应用和 Widget 使用同一个 App Group。
- 修改待办状态、排序或删除后更新 `Paper.updatedAt`，并刷新 Widget 时间线。
- Markdown 图片引用使用 `NoteImageStore` 提供的 UUID `.jpg` 资源名。
- 保存操作应处理 `modelContext.save()` 错误并保留用户输入。
- 页面异步任务需要在页面离开或对象变化时取消或验证代际标识。
- 日历事件通过 `CalendarEventFormView` 校验开始和结束日期时间，跨日事件按覆盖日期显示。

## CI 流程

### `PaperTodo iOS Build`

`.github/workflows/papertodo-ios.yml` 在 `PaperTodo-iOS/**` 变化时触发。流程在 macOS 15 上安装 XcodeGen、生成 Xcode 项目、构建无签名 Release App、打包 IPA 并上传 artifact。

## 变更验证

提交前执行：

```bash
# 检查差异格式
git diff --check

# 查看工作树状态
git status --short
```

涉及 iOS 源代码时推送后使用：

```bash
# 查看 iOS 构建工作流
gh run list --workflow "PaperTodo iOS Build"
```

## 文档与安全边界

- 项目文档统一放在 `.monkeycode/docs/`。
- 文档只描述 PaperTodo iOS 代码、配置和工作流。
- 不在代码、文档或示例中写入 API key、密码、令牌和内部凭证。
- 图片资源通过 `NoteImageStore` 的合法文件名校验访问。
