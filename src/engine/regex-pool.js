// src/engine/regex-pool.js
// 正则缓存池 - 极速版

const RegexPool = (() => {
  const cache = new Map();
  const MAX_SIZE = 100; // 增加缓存容量
  
  return {
    get: (pattern, flags = '') => {
      const key = `${pattern}|||${flags}`;
      const cached = cache.get(key);
      if (cached) return cached;
      
      try {
        const regex = new RegExp(pattern, flags);
        if (cache.size >= MAX_SIZE) {
          const first = cache.keys().next().value;
          cache.delete(first);
        }
        cache.set(key, regex);
        return regex;
      } catch (e) {
        return /(?!)/;
      }
    },
    clear: () => cache.clear(),
    size: () => cache.size
  };
})();

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { RegexPool };
}
