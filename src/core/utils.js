// src/core/utils.js
// 工具函数集 - 极速版

const Utils = {
  safeJsonParse: (str, def = null) => {
    try { return JSON.parse(str); } catch (e) { return def; }
  },

  safeJsonStringify: (obj) => {
    try { return JSON.stringify(obj); } catch (e) { return '{}'; }
  },

  getPath: (obj, path) => {
    if (!path || !obj) return undefined;
    const parts = path.split('.');
    let cur = obj;
    for (const p of parts) {
      if (cur == null) return undefined;
      const m = p.match(/^([^\[]+)\[(\d+)\]$/);
      cur = m ? (cur[m[1]]?.[parseInt(m[2])]) : cur[p];
    }
    return cur;
  },

  setPath: (obj, path, value) => {
    if (!path || !obj) return obj;
    const parts = path.split('.');
    let cur = obj;
    for (let i = 0; i < parts.length - 1; i++) {
      const p = parts[i];
      const next = parts[i + 1];
      const m = p.match(/^([^\[]+)\[(\d+)\]$/);
      const isArr = /^\[.*\]$/.test(next);
      if (m) {
        const arr = cur[m[1]] || (cur[m[1]] = []);
        cur = arr[parseInt(m[2])] || (arr[parseInt(m[2])] = isArr ? [] : {});
      } else {
        cur = cur[p] || (cur[p] = isArr ? [] : {});
      }
    }
    const last = parts[parts.length - 1];
    const lm = last.match(/^([^\[]+)\[(\d+)\]$/);
    if (lm) {
      const arr = cur[lm[1]] || (cur[lm[1]] = []);
      arr[parseInt(lm[2])] = value;
    } else {
      cur[last] = value;
    }
    return obj;
  },

  simpleHash: (str) => {
    let h = 0;
    for (let i = 0; i < str.length; i++) {
      h = ((h << 5) - h) + str.charCodeAt(i);
      h = h & h;
    }
    return Math.abs(h).toString(16);
  },

  resolveTemplate: (str, obj) => {
    if (typeof str !== 'string' || !str.includes('{{')) return str;
    return str.replace(/\{\{([^}]+)\}\}/g, (m, p) => {
      const v = Utils.getPath(obj, p.trim());
      return v !== undefined ? v : m;
    });
  }
};

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { Utils };
}
