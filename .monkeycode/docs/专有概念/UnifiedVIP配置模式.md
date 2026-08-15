# UnifiedVIP 配置模式

## JSON

使用处理器定义修改后的对象字段，适合结构化响应。处理器可通过路径读写嵌套对象和数组。

## Regex

使用 `regexReplacements` 对响应文本执行预编译正则替换。正则实例由 `RegexPool` 复用。

## Forward

将请求体和配置指定的请求头转发到 `forwardUrl`，支持超时、有限重试、状态文本和响应头策略。

## Remote

从 `remoteUrl` 获取远程内容，支持超时、有限重试、缓存回退和响应头策略。

## Game

使用 `gameResources` 描述资源字段和目标值，运行时将匹配字段替换为配置值。

## Hybrid

组合 JSON 处理器和正则替换，适合同时需要结构化字段修改和文本清理的响应。

## HTML

使用 `htmlReplacements` 处理 HTML 文本，默认使用不区分大小写的正则标志。
