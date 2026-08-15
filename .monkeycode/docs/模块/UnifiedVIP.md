# UnifiedVIP 模块

## 职责

UnifiedVIP 是一个面向 QX、Surge、Loon、Stash 运行环境的配置驱动脚本生成器。它把应用配置转换为独立 JSON、rewrite 配置和一个包含匹配、缓存、加载、处理和响应输出逻辑的主脚本。

## 目录

- `src/apps/`：应用配置注册和前缀索引。
- `src/core/`：平台检测、日志、存储、HTTP 和通用工具。
- `src/engine/`：正则缓存、处理器工厂、处理器编译、清单加载、配置加载和 VIP 引擎。
- `scripts/`：构建、校验和新增应用脚本。
- `configs/`：应用 JSON 配置源。
- `dist/`：构建输出目录。

## 运行时流程

1. 读取请求或响应 URL。
2. 使用 `SimpleManifestLoader` 匹配应用 ID。
3. 使用 `SimpleConfigLoader` 读取版本化缓存或远程 JSON。
4. 使用 `VipEngine` 根据 mode 处理响应。
5. 将 body、headers、status 或原响应交给宿主平台的 `$done`。

## 缓存

- URL 匹配缓存只在 QX 环境持久化。
- 配置缓存使用 `Storage`，带版本号和 TTL。
- `RegexPool` 限制最多 100 个正则实例。
- 处理器编译缓存最多 200 个处理器。
- URL 持久化缓存默认限制 50 条，TTL 默认 1 小时。

## 重要限制

- 配置正则必须通过 `npm run validate` 检查。
- `VipEngine` 对响应体大小使用 `CONFIG.MAX_BODY_SIZE`，默认上限为 5 MiB。
- 组合处理器数量受 `CONFIG.MAX_PROCESSORS_PER_REQUEST` 限制，默认上限为 30。
- 网络请求使用显式超时和有限重试。
