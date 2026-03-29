// src/core/storage.js
// M3单键存储系统 - 极速版

const Storage = (() => {
  const KEY = 'vip_v22_data';
  const MAX_SIZE = 480000; // QX限制约500KB，留20KB余量
  const qxRead = (k) => $prefs.valueForKey(k);
  const qxWrite = (k, v) => $prefs.setValueForKey(v, k);
  
  return {
    readConfig: (configId) => {
      const raw = qxRead(KEY);
      if (!raw) return null;
      try {
        const all = JSON.parse(raw);
        const item = all[configId];
        const ttl = typeof CONFIG !== 'undefined' ? CONFIG.CONFIG_CACHE_TTL : 86400000;
        if (item && (Date.now() - item.t) < ttl) {
          return JSON.stringify(item);
        }
      } catch (e) {}
      return null;
    },

    writeConfig: (configId, value) => {
      let all = {};
      const raw = qxRead(KEY);
      if (raw) {
        try { all = JSON.parse(raw); } catch (e) {}
      }
      
      let parsed;
      try {
        parsed = typeof value === 'string' ? JSON.parse(value) : value;
      } catch (e) {
        parsed = value;
      }

      all[configId] = {
        v: parsed.v || '1.0',
        t: Date.now(),
        d: parsed.d || parsed
      };

      let str = JSON.stringify(all);
      
      // 超限保护：保留最近5个
      if (str.length > MAX_SIZE) {
        const sorted = Object.entries(all)
          .sort((a, b) => (b[1].t || 0) - (a[1].t || 0))
          .slice(0, 5);
        all = Object.fromEntries(sorted);
        str = JSON.stringify(all);
      }

      qxWrite(KEY, str);
    },

    read: (key) => qxRead(key),
    write: (key, value) => qxWrite(key, value),
    remove: (key) => $prefs.removeValueForKey(key)
  };
})();

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { Storage };
}
