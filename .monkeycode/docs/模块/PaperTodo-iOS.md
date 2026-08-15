# PaperTodo iOS 模块

## 职责

PaperTodo 是一个 SwiftUI 个人工作台。首页通过 `HomeMode` 在纸片、日历和四象限之间切换；纸片包含待办和 Markdown 笔记两种类型。

## 页面结构

- `ContentView`：首页容器、模式绑定、纸片查询、筛选、导航和删除撤销。
- `HomeModeContent`：模式分段控件和内容分发。
- `TodoPaperView`：待办编辑、拖放删除、排序、撤销重做、自动清除和 Widget 刷新。
- `NotePaperView`：标题、Markdown 编辑器、预览、图片导入、导出和主题设置。
- `CalendarHomeView`：月历网格、事件标签、周标尺和日时间线。
- `CalendarEventFormView`：日程创建、编辑、删除、日期时间和分类。
- `QuadrantHomeView`：四象限派生、任务移动、编辑、完成和所属纸片导航。
- `SettingsView`：外观、配色、待办字号、自动清除和 Markdown 渲染强度。

## 主题系统

`PaperColorScheme` 提供暖纸、墨、林、霞四种配色。`PaperPalette` 按配色和深浅模式提供正文、弱化文字、边框、强调色、危险色、画布色、时间色和渐变。`PaperRadius` 与 `PaperCardModifier` 为页面卡片提供统一的圆角、边框和阴影。

## 生命周期和错误处理

页面保存通过 `modelContext.save()` 执行，失败时显示 alert。异步 Markdown 高亮、图片导入和后台图片清理使用任务或队列；图片导入以正文引用快照和代际标识避免异步结果写入错误页面。

## Widget

Widget 从共享 SwiftData 容器读取所有待办，展示待办数、完成数和完成进度。主应用关键待办操作后主动调用 WidgetKit 刷新。
