// src/engine/config-loader.js
// 配置加载器 - 极速版 (修复版)

class SimpleConfigLoader {
  constructor(requestId) {
    this._requestId = requestId;
    this._versionTag = (typeof BUILTIN_MANIFEST !== 'undefined' && BUILTIN_MANIFEST?.version)
      ? String(BUILTIN_MANIFEST.version)
      : 'v1';
  }

  _versionedId(configId) {
    return `${configId}@${this._versionTag}`;
  }

  async load(configId, remoteVersion) {
    const versionedId = this._versionedId(configId);
    const cached = Storage.readConfig(versionedId);

    if (cached) {
      try {
        const { v, t, d } = JSON.parse(cached);
        const ttl = typeof CONFIG !== 'undefined' ? CONFIG.CONFIG_CACHE_TTL : 86400000;
        if (v === remoteVersion && (Date.now() - t) < ttl) {
          Logger.info('ConfigLoader', `${configId} cache hit`);
          // FIX: 对缓存配置也进行 _prepareConfig 处理
          return this._prepareConfig(d);
        }
      } catch (e) {}
    }

    const baseUrl = typeof CONFIG !== 'undefined' ? CONFIG.REMOTE_BASE : 'https://joeshu.github.io/UnifiedVIP';
    const url = `${baseUrl}/configs/${configId}.json?t=${Date.now()}`;
    Logger.info('ConfigLoader', `${configId} fetching...`);

    try {
      const res = await HTTP.get(url);
      if (res.statusCode !== 200 || !res.body) {
        throw new Error(`HTTP ${res.statusCode}`);
      }

      const fresh = Utils.safeJsonParse(res.body);
      
      Storage.writeConfig(versionedId, {
        v: remoteVersion,
        t: Date.now(),
        d: fresh
      });

      return this._prepareConfig(fresh);
    } catch (e) {
      Logger.error('ConfigLoader', `${configId} failed: ${e.message}`);
      
      if (cached) {
        Logger.warn('ConfigLoader', `${configId} using stale cache`);
        const { d } = JSON.parse(cached);
        // FIX: 对缓存配置也进行 _prepareConfig 处理
        return this._prepareConfig(d);
      }
      throw e;
    }
  }

  _prepareConfig(raw) {
    // FIX: 深拷贝避免修改原始对象
    const config = JSON.parse(JSON.stringify(raw));

    if (config.mode === 'forward' || config.mode === 'remote') {
      return config;
    }

    // 预编译正则替换规则
    if (raw.regexReplacements && Array.isArray(raw.regexReplacements)) {
      config._regexReplacements = raw.regexReplacements.map(r => ({
        pattern: RegexPool.get(r.pattern, r.flags || 'g'),
        replacement: r.replacement
      }));
    }

    // 预编译游戏资源规则
    if (raw.gameResources && Array.isArray(raw.gameResources)) {
      config._gameResources = raw.gameResources.map(r => ({
        field: r.field,
        value: r.value,
        pattern: RegexPool.get(`"${r.field}":\\d+`, 'g')
      }));
    }

    // 预编译 HTML 替换规则
    if (raw.htmlReplacements && Array.isArray(raw.htmlReplacements)) {
      config._htmlReplacements = raw.htmlReplacements.map(r => ({
        pattern: RegexPool.get(r.pattern, r.flags || 'gi'),
        replacement: r.replacement
      }));
    }

    return config;
  }
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { SimpleConfigLoader };
}
