// src/engine/manifest-loader.js
// Manifest加载器 - 极速版 (修复版)

class SimpleManifestLoader {
  constructor(requestId) {
    this._requestId = requestId;
    this._versionTag = (typeof BUILTIN_MANIFEST !== 'undefined' && BUILTIN_MANIFEST?.version)
      ? String(BUILTIN_MANIFEST.version)
      : 'v1';
    
    this._urlCache = Platform.isQX ? {} : null;
    this._memoizedMatches = new Map();
    this._regexCache = new Map();
    this._prefixIndex = typeof PREFIX_INDEX !== 'undefined' ? PREFIX_INDEX : {};
    this._lazyConfigs = typeof BUILTIN_MANIFEST !== 'undefined' ? BUILTIN_MANIFEST.configs : {};
    this._hostTokenIndex = null;
    
    const cfg = typeof CONFIG !== 'undefined' ? CONFIG : {};
    this._urlCacheKey = cfg.URL_CACHE_KEY || 'url_match_v22_lazy';
    this._urlMetaKey = `${this._urlCacheKey}_meta`;
    this._urlCacheMigratedKey = `${this._urlCacheKey}_migrated`;
    this._cacheTtlMs = Math.max(60000, Number(cfg.URL_CACHE_TTL_MS) || 3600000);
    this._persistIntervalMs = Math.max(5000, Number(cfg.URL_CACHE_PERSIST_INTERVAL_MS) || 15000);
    this._persistLimit = Math.max(20, Math.min(200, Math.floor(Number(cfg.URL_CACHE_LIMIT) || 50)));
    this._persistMeta = { lastPersistAt: 0 };
    
    const legacyKeys = ['url_match_v22', 'url_match_v21_lazy', 'url_match_cache_v22'];
    this._legacyUrlCacheKeys = [this._urlCacheKey, ...legacyKeys].filter((k, i, a) => k && a.indexOf(k) === i);
    
    if (this._urlCache && typeof $prefs !== 'undefined') {
      const migrated = this._isLegacyMigrated();
      const { raw, keyUsed } = this._readFirstAvailable(migrated ? [this._urlCacheKey] : this._legacyUrlCacheKeys);
      
      if (raw) this._restoreUrlCache(raw);
      if (!migrated) {
        if (raw && keyUsed && keyUsed !== this._urlCacheKey) this._saveUrlCache(true);
        this._cleanupLegacyKeys();
        this._markLegacyMigrated();
      }
    }
  }

  _isLegacyMigrated() {
    if (typeof $prefs === 'undefined') return true;
    try { return $prefs.valueForKey(this._urlCacheMigratedKey) === '1'; } catch (e) { return false; }
  }

  _markLegacyMigrated() {
    if (typeof $prefs === 'undefined') return;
    try { $prefs.setValueForKey(this._urlCacheMigratedKey, '1'); } catch (e) {}
  }

  _cleanupLegacyKeys() {
    if (typeof $prefs === 'undefined') return;
    const keys = this._legacyUrlCacheKeys.filter(k => k !== this._urlCacheKey);
    for (const k of keys) {
      try { $prefs.removeValueForKey(k); } catch (e) {}
    }
  }

  _readFirstAvailable(keys) {
    if (typeof $prefs === 'undefined') return { raw: null, keyUsed: null };
    for (const k of keys) {
      try {
        const raw = $prefs.valueForKey(k);
        if (raw) return { raw, keyUsed: k };
      } catch (e) {}
    }
    return { raw: null, keyUsed: null };
  }

  _restoreUrlCache(raw) {
    try {
      const parsed = JSON.parse(raw);
      if (!parsed || typeof parsed !== 'object') return;
      const now = Date.now();
      for (const [k, v] of Object.entries(parsed)) {
        if (v?.id && v?.ts && (now - v.ts) < this._cacheTtlMs) {
          this._urlCache[k] = { id: v.id, ts: v.ts };
        }
      }
    } catch (e) {}
  }

  _buildHostTokenIndex() {
    const index = {};
    const ignored = new Set(['www', 'api', 'com', 'net', 'org', 'cn', 'co', 'io', 'app', 'vip', 'xyz']);
    
    for (const [id, cfg] of Object.entries(this._lazyConfigs || {})) {
      const pattern = cfg?.urlPattern;
      if (!pattern) continue;
      const hosts = pattern.match(/[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g) || [];
      for (const host of hosts) {
        const tokens = host.toLowerCase().split('.').filter(Boolean);
        for (const tk of tokens) {
          if (tk.length < 3 || ignored.has(tk)) continue;
          if (!index[tk]) index[tk] = new Set();
          index[tk].add(id);
        }
      }
    }
    
    const compact = {};
    for (const [tk, set] of Object.entries(index)) {
      compact[tk] = Array.from(set);
    }
    return compact;
  }

  _findByHostToken(hostname) {
    if (!this._hostTokenIndex) {
      this._hostTokenIndex = this._buildHostTokenIndex();
    }
    const ignored = new Set(['www', 'api', 'com', 'net', 'org', 'cn', 'co', 'io', 'app', 'vip', 'xyz']);
    const candidates = new Set();
    const tokens = String(hostname || '').toLowerCase().split('.').filter(Boolean);
    
    for (const tk of tokens) {
      if (tk.length < 3 || ignored.has(tk)) continue;
      const ids = this._hostTokenIndex[tk];
      if (Array.isArray(ids)) ids.forEach(id => candidates.add(id));
    }
    return Array.from(candidates);
  }

  _buildUrlCacheKey(url) {
    const method = (typeof $request !== 'undefined' && $request?.method)
      ? String($request.method).toUpperCase()
      : 'GET';
    try {
      const u = new URL(url);
      return `${method}|${u.hostname.toLowerCase()}|${u.pathname}`;
    } catch (e) {
      return `${method}|${String(url || '').split('?')[0]}`;
    }
  }

  _findByPrefix(hostname) {
    if (typeof findByPrefix === 'function') return findByPrefix(hostname);
    const h = hostname.toLowerCase();
    if (this._prefixIndex.exact?.[h]) {
      return { ids: this._prefixIndex.exact[h], method: 'exact', matched: h };
    }
    if (this._prefixIndex.suffix) {
      for (const [suffix, ids] of Object.entries(this._prefixIndex.suffix)) {
        if (h.endsWith('.' + suffix) || h === suffix) {
          return { ids, method: 'suffix', matched: suffix };
        }
      }
    }
    if (this._prefixIndex.keyword) {
      for (const [kw, ids] of Object.entries(this._prefixIndex.keyword)) {
        if (h.includes(kw)) {
          return { ids, method: 'keyword', matched: kw };
        }
      }
    }
    return null;
  }

  _saveUrlCache(force = false) {
    if (!this._urlCache || typeof $prefs === 'undefined') return;
    const now = Date.now();
    if (!force && (now - this._persistMeta.lastPersistAt) < this._persistIntervalMs) return;
    
    const entries = Object.entries(this._urlCache)
      .filter(([, v]) => v?.ts && (now - v.ts) < this._cacheTtlMs)
      .sort((a, b) => b[1].ts - a[1].ts)
      .slice(0, this._persistLimit);
    
    try {
      $prefs.setValueForKey(this._urlCacheKey, JSON.stringify(Object.fromEntries(entries)));
      this._persistMeta.lastPersistAt = now;
      $prefs.setValueForKey(this._urlMetaKey, JSON.stringify(this._persistMeta));
    } catch (e) {}
  }

  _touchUrlCache(cacheKey, id) {
    if (!this._urlCache) return;
    const prev = this._urlCache[cacheKey];
    const changed = !prev || prev.id !== id;
    this._urlCache[cacheKey] = { id, ts: Date.now() };
    this._saveUrlCache(changed);
  }

  async load() {
    Logger.debug('ManifestLoader', `Lazy load v${BUILTIN_MANIFEST?.version || '22.0.0'}`);
    return this._createLazyProxy();
  }

  _createLazyProxy() {
    const self = this;
    return {
      findMatch: (url) => {
        const cacheKey = self._buildUrlCacheKey(url);
        
        if (self._urlCache) {
          const cached = self._urlCache[cacheKey];
          if (cached && (Date.now() - cached.ts) < self._cacheTtlMs) {
            Logger.debug('ManifestLoader', `Cache hit: ${cached.id}`);
            self._touchUrlCache(cacheKey, cached.id);
            return cached.id;
          }
        }

        let candidates = [];
        try {
          const hostname = new URL(url).hostname;
          const matchInfo = self._findByPrefix(hostname);
          
          if (matchInfo) {
            candidates = matchInfo.ids;
            Logger.debug('ManifestLoader', `Prefix ${matchInfo.method}: ${matchInfo.matched}`);
          } else {
            const tokenCandidates = self._findByHostToken(hostname);
            if (tokenCandidates.length > 0) {
              candidates = tokenCandidates;
              Logger.debug('ManifestLoader', `Token narrow: ${hostname} -> ${tokenCandidates.length}`);
            }
          }
        } catch (e) {
          Logger.debug('ManifestLoader', 'URL parse failed');
        }

        if (candidates.length === 0) {
          candidates = Object.keys(self._lazyConfigs);
          Logger.debug('ManifestLoader', `Fallback: scanning ${candidates.length} patterns`);
        }

        for (const id of candidates) {
          let regex = self._regexCache.get(id);
          
          if (!regex && self._lazyConfigs[id]) {
            const patternStr = self._lazyConfigs[id].urlPattern;
            if (!patternStr) continue;
            try {
              regex = new RegExp(patternStr);
              self._regexCache.set(id, regex);
            } catch (e) {
              Logger.error('ManifestLoader', `Invalid pattern: ${id}`);
              continue;
            }
          }
          
          if (regex && regex.test(url)) {
            Logger.debug('ManifestLoader', `Matched: ${id}`);
            if (self._urlCache) self._touchUrlCache(cacheKey, id);
            return id;
          }
        }

        Logger.warn('ManifestLoader', `No match for ${url.substring(0, 40)}...`);
        return null;
      },

      getConfigVersion: (configId) => self._lazyConfigs[configId] ? '1.0' : null
    };
  }
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { SimpleManifestLoader };
}
