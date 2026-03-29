/*
 * ==========================================
 * Unified VIP Unlock Manager v22.0.0
 * 构建时间: 2026-03-29T07:26:00.046Z
 * APP数量: 21
 * ==========================================
 * 订阅规则: https://joeshu.github.io/UnifiedVIP/rewrite.conf
 */

'use strict';

if (typeof console === 'undefined') { globalThis.console = { log: () => {} }; }

const CONFIG = {
  REMOTE_BASE: 'https://joeshu.github.io/UnifiedVIP',
  CONFIG_CACHE_TTL: 86400000,
  MAX_BODY_SIZE: 5242880,
  MAX_PROCESSORS_PER_REQUEST: 30,
  TIMEOUT: 10,
  DEBUG: false,
  VERBOSE_PATTERN_LOG: false,
  URL_CACHE_KEY: 'url_match_v22_lazy',
  URL_CACHE_META_KEY: 'url_match_v22_lazy_meta',
  URL_CACHE_MIGRATED_KEY: 'url_match_v22_lazy_migrated',
  URL_CACHE_LEGACY_KEYS: ['url_match_v22', 'url_match_v21_lazy', 'url_match_cache_v22'],
  URL_CACHE_TTL_MS: 3600000,
  URL_CACHE_PERSIST_INTERVAL_MS: 15000,
  URL_CACHE_LIMIT: 50
};

const META = { name: 'UnifiedVIP', version: '22.0.0' };

// ==========================================
// 1. 内置Manifest
// ==========================================
const BUILTIN_MANIFEST = {"version":"22.0.0-d02ed82f","updated":"2026-03-29","total":21,"configs":{"bqwz":{"name":"标枪王者","urlPattern":"^https?:\\/\\/javelin\\.mandrillvr\\.com\\/api\\/data\\/get_game_data"},"bxkt":{"name":"伴学课堂","urlPattern":"^https?:\\/\\/api\\.banxueketang\\.com\\/api\\/classpal\\/app\\/v1"},"cyljy":{"name":"成语来解压","urlPattern":"^https?:\\/\\/yr-game-api\\.feigo\\.fun\\/api\\/user\\/get-game-user-value"},"foday":{"name":"复游会","urlPattern":"^https?:\\/\\/apis\\.folidaymall\\.com\\/online\\/capi\\/component\\/getPageComponents"},"gps":{"name":"GPS工具箱","urlPattern":"^https:\\/\\/service\\.gpstool\\.com\\/app\\/index\\/getUserInfo"},"iappdaily":{"name":"iAppDaily","urlPattern":"^https:\\/\\/api\\.iappdaily\\.com\\/my\\/balance"},"kada":{"name":"KaDa 阅读 VIP Unlock","urlPattern":"^https://service\\.hhdd\\.com/book2"},"keep":{"name":"Keep","urlPattern":"^https?:\\/\\/(?:api|kit)\\.gotokeep\\.com\\/(?:nuocha|gerudo|athena|nuocha\\/plans|suit\\/v5\\/smart|kprime\\/v4\\/suit\\/sales)\\/"},"kyxq":{"name":"口语星球","urlPattern":"^https?:\\/\\/mapi\\.kouyuxingqiu\\.com\\/api\\/v2"},"mhlz":{"name":"魔幻粒子","urlPattern":"^https?:\\/\\/ss\\.landintheair\\.com\\/storage\\/"},"mingcalc":{"name":"明计算","urlPattern":"^https?://jsq\\.mingcalc\\.cn/XMGetMeCount\\.ashx"},"qiujingapp":{"name":"球竞APP","urlPattern":"^https?:\\/\\/gateway-api\\.yizhilive\\.com\\/api\\/(?:v2\\/index\\/carouses\\/(?:3|6|8|11)|v3\\/index\\/all)"},"qmjyzc":{"name":"全民解压找茬","urlPattern":"^https?://res5\\.haotgame\\.com/cu03/static/OpenDoors/Res/data/levels/\\d+\\.json"},"sylangyue":{"name":"思朗月影视","urlPattern":"^https?:\\/\\/theater-api\\.sylangyue\\.xyz\\/api\\/user\\/info"},"tophub":{"name":"TopHub","urlPattern":"^https:\\/\\/(?:api[23]\\.tophub\\.(?:xyz|today|app)|tophub(?:2)?\\.(?:tophubdata\\.com|idaily\\.today|remai\\.today|iappdaiy\\.com|ipadown\\.com))\\/account\\/sync"},"tv":{"name":"影视去广告","urlPattern":"^https?:\\/\\/(?:yzy0916|yz1018|yz250907|yz0320|cfvip)\\..+\\.com\\/(?:v2|v1)\\/api\\/(?:basic\\/init|home\\/firstScreen|adInfo\\/getPageAd|home\\/body)"},"v2ex":{"name":"V2EX去广告","urlPattern":"^https?:\\/\\/.*v2ex\\.com\\/(?!(?:.*(?:api|login|cdn-cgi|verify|auth|captch|\\.(js|css|jpg|jpeg|png|webp|gif|zip|woff|woff2|m3u8|mp4|mov|m4v|avi|mkv|flv|rmvb|wmv|rm|asf|asx|mp3|json|ico|otf|ttf)))).+$"},"vvebo":{"name":"Vvebo Subscription Forward","urlPattern":"^https:\\/\\/fluxapi\\.vvebo\\.vip\\/v1\\/purchase\\/iap\\/subscription"},"wohome":{"name":"联通智家","urlPattern":"^https:\\/\\/iotpservice\\.smartont\\.net\\/wohome\\/dispatcher"},"xjsm":{"name":"星际使命","urlPattern":"^https?:\\/\\/star\\.jvplay\\.cn\\/v2\\/storage"},"zhenti":{"name":"真题伴侣","urlPattern":"^https?://newtest\\.zoooy111\\.com/mobilev4\\.php/User/index"}}};

// ==========================================
// 2. 前缀索引
// ==========================================
const PREFIX_INDEX = {
 exact: {
  'javelin.mandrillvr.com': ["bqwz"],
  'api.banxueketang.com': ["bxkt"],
  'yr-game-api.feigo.fun': ["cyljy"],
  'apis.folidaymall.com': ["foday"],
  'service.gpstool.com': ["gps"],
  'api.iappdaily.com': ["iappdaily"],
  'service.hhdd.com': ["kada"],
  'mapi.kouyuxingqiu.com': ["kyxq"],
  'ss.landintheair.com': ["mhlz"],
  'jsq.mingcalc.cn': ["mingcalc"],
  'gateway-api.yizhilive.com': ["qiujingapp"],
  'res5.haotgame.com': ["qmjyzc"],
  'theater-api.sylangyue.xyz': ["sylangyue"],
  'fluxapi.vvebo.vip': ["vvebo"],
  'iotpservice.smartont.net': ["wohome"],
  'star.jvplay.cn': ["xjsm"],
  'newtest.zoooy111.com': ["zhenti"]
 },
 suffix: {
  'mandrillvr.com': ["bqwz"],
  'banxueketang.com': ["bxkt"],
  'feigo.fun': ["cyljy"],
  'folidaymall.com': ["foday"],
  'gpstool.com': ["gps"],
  'iappdaily.com': ["iappdaily"],
  'hhdd.com': ["kada"],
  'gotokeep.com': ["keep"],
  'kouyuxingqiu.com': ["kyxq"],
  'landintheair.com': ["mhlz"],
  'mingcalc.cn': ["mingcalc"],
  'xmgetmecount.ashx': ["mingcalc"],
  'yizhilive.com': ["qiujingapp"],
  'haotgame.com': ["qmjyzc"],
  'sylangyue.xyz': ["sylangyue"],
  'tophubdata.com': ["tophub"],
  'idaily.today': ["tophub"],
  'remai.today': ["tophub"],
  'iappdaiy.com': ["tophub"],
  'ipadown.com': ["tophub"],
  'v2ex.com': ["v2ex"],
  'vvebo.vip': ["vvebo"],
  'smartont.net': ["wohome"],
  'jvplay.cn': ["xjsm"],
  'zoooy111.com': ["zhenti"]
 },
 keyword: {
  'yz': ["tv"],
  'yzy': ["tv"],
  'yz1018': ["tv"],
  'yz250907': ["tv"],
  'yz0320': ["tv"],
  'cfvip': ["tv"],
  'cf': ["tv"],
  'keep': ["keep"],
  'gotokeep': ["keep"],
  'nuocha': ["keep"],
  'gerudo': ["keep"],
  'athena': ["keep"],
  'tophub': ["tophub"],
  'tophubdata': ["tophub"],
  'idaily': ["tophub"],
  'remai': ["tophub"],
  'v2ex': ["v2ex"],
  'vvebo': ["vvebo"],
  'fluxapi': ["vvebo"],
  'slzd': ["slzd"],
  'lifeweek': ["slzd"],
  'kyxq': ["kyxq"],
  'kouyuxingqiu': ["kyxq"],
  'mhlz': ["mhlz"],
  'xjsm': ["xjsm"],
  'jvplay': ["xjsm"],
  'bqwz': ["bqwz"],
  'mandrillvr': ["bqwz"],
  'javelin': ["bqwz"],
  'qmj': ["qmjyzc"],
  'qmjyzc': ["qmjyzc"],
  'haotgame': ["qmjyzc"],
  'bxkt': ["bxkt"],
  'banxueketang': ["bxkt"],
  'cyljy': ["cyljy"],
  'feigo': ["cyljy"],
  'wohome': ["wohome"],
  'smartont': ["wohome"],
  'iotpservice': ["wohome"],
  'kada': ["kada"],
  'hhdd': ["kada"],
  'ipalfish': ["ipalfish"],
  'picturebook': ["ipalfish"],
  'gps': ["gps"],
  'gpstool': ["gps"],
  'iapp': ["iappdaily"],
  'iappdaily': ["iappdaily"],
  'sylangyue': ["sylangyue"],
  'theater-api': ["sylangyue"],
  'mingcalc': ["mingcalc"],
  'jsq': ["mingcalc"],
  'qiujing': ["qiujingapp"],
  'qiujingapp': ["qiujingapp"],
  'yizhilive': ["qiujingapp"],
  'foday': ["foday"],
  'folidaymall': ["foday"],
  'zhenti': ["zhenti"]
 }
};
function findByPrefix(h){h=h.toLowerCase();if(PREFIX_INDEX.exact[h])return{ids:PREFIX_INDEX.exact[h],method:'exact',matched:h};for(const[s,ids]of Object.entries(PREFIX_INDEX.suffix))if(h.endsWith('.'+s)||h===s)return{ids,method:'suffix',matched:s};if(PREFIX_INDEX.keyword)for(const[k,ids]of Object.entries(PREFIX_INDEX.keyword))if(h.includes(k))return{ids,method:'keyword',matched:k};return null}

// ==========================================
// 3. 平台检测
// ==========================================
// src/core/platform.js
// 平台检测 - 极速版

const Platform = {
  isQX: typeof $task !== 'undefined',
  isLoon: typeof $loon !== 'undefined',
  isSurge: typeof $httpClient !== 'undefined' && typeof $loon === 'undefined',
  isStash: typeof $stash !== 'undefined',
  getName() {
    return this.isQX ? 'QX' : this.isLoon ? 'Loon' : this.isSurge ? 'Surge' : this.isStash ? 'Stash' : 'Unknown';
  }
};

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { Platform };
}

// ==========================================
// 4. 日志系统
// ==========================================
// src/core/logger.js
// 日志系统 - 极速版（减少运行时判断）

const Logger = (() => {
  const isDebug = typeof CONFIG !== 'undefined' && CONFIG.DEBUG === true;
  const metaName = typeof META !== 'undefined' ? META.name : 'UnifiedVIP';
  const now = () => {
    const d = new Date();
    return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}:${String(d.getSeconds()).padStart(2, '0')}`;
  };
  const print = (level, tag, msg) => {
    console.log(`[${metaName}][${now()}][${level}][${tag}] ${msg}`);
  };
  return {
    info: isDebug ? (tag, msg) => print('INFO', tag, msg) : () => {},
    error: (tag, msg) => print('ERROR', tag, msg),
    debug: isDebug ? (tag, msg) => print('DEBUG', tag, msg) : () => {},
    warn: isDebug ? (tag, msg) => print('WARN', tag, msg) : () => {}
  };
})();

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { Logger };
}

// ==========================================
// 5. M3存储系统
// ==========================================
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

// ==========================================
// 6. HTTP客户端
// ==========================================
// src/core/http.js
// HTTP 客户端 - 极速版

const HTTP = (() => {
  const toQxSec = (ms) => Math.max(1, Math.ceil(ms / 1000));
  
  const normalizeTimeout = (v, fb = 10000) => {
    const n = Number(v);
    return (!Number.isFinite(n) || n <= 0) ? fb : n;
  };

  const createCallback = (resolve, reject, timer) => (err, res, body) => {
    clearTimeout(timer);
    if (err) {
      reject(new Error(String(err)));
    } else {
      resolve({
        body: body || '',
        statusCode: typeof res === 'object' ? (res.statusCode || res.status || 200) : 200,
        headers: typeof res === 'object' ? (res.headers || {}) : {}
      });
    }
  };

  return {
    get: (url, timeout = 10000) => new Promise((resolve, reject) => {
      const t = normalizeTimeout(timeout, 10000);
      const timer = setTimeout(() => reject(new Error('Timeout')), t);
      const cb = createCallback(resolve, reject, timer);

      try {
        if (Platform.isQX) {
          $task.fetch({ url, method: 'GET', timeout: toQxSec(t) })
            .then(res => cb(null, { statusCode: res.statusCode, headers: res.headers }, res.body), err => cb(err, null, null));
        } else if (typeof $httpClient !== 'undefined') {
          $httpClient.get({ url, timeout: t / 1000 }, cb);
        } else {
          clearTimeout(timer);
          reject(new Error('No HTTP client'));
        }
      } catch (e) {
        clearTimeout(timer);
        reject(e);
      }
    }),

    post: (options, timeout = 10000) => new Promise((resolve, reject) => {
      const t = normalizeTimeout(options?.timeout, normalizeTimeout(timeout, 10000));
      const timer = setTimeout(() => reject(new Error('Timeout')), t);
      const cb = createCallback(resolve, reject, timer);

      try {
        if (Platform.isQX) {
          $task.fetch({
            url: options.url,
            method: 'POST',
            headers: options.headers || {},
            body: options.body || '',
            timeout: toQxSec(t)
          }).then(res => cb(null, { statusCode: res.statusCode, headers: res.headers }, res.body), err => cb(err, null, null));
        } else if (typeof $httpClient !== 'undefined') {
          $httpClient.post({
            url: options.url,
            headers: options.headers || {},
            body: options.body || '',
            timeout: t / 1000
          }, cb);
        } else {
          clearTimeout(timer);
          reject(new Error('No HTTP client'));
        }
      } catch (e) {
        clearTimeout(timer);
        reject(e);
      }
    })
  };
})();

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { HTTP };
}

// ==========================================
// 7. 工具函数
// ==========================================
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

// ==========================================
// 8. 正则缓存池
// ==========================================
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

// ==========================================
// 9. 处理器工厂
// ==========================================
// src/engine/processor-factory.js
// 处理器工厂 - 极速版

function createProcessorFactory(requestId) {
  return {
    setFields: (params) => (obj, env) => {
      const fields = params.fields || {};
      for (const p in fields) {
        let v = fields[p];
        if (typeof v === 'string' && v.includes('{{')) {
          v = Utils.resolveTemplate(v, obj);
        }
        Utils.setPath(obj, p, v);
      }
      return obj;
    },

    mapArray: (params) => (obj, env) => {
      const arr = Utils.getPath(obj, params.path);
      if (!Array.isArray(arr)) return obj;
      const fields = params.fields || {};
      for (const item of arr) {
        if (!item) continue;
        for (const p in fields) {
          let v = fields[p];
          if (typeof v === 'string' && v.includes('{{')) {
            v = Utils.resolveTemplate(v, item);
          }
          Utils.setPath(item, p, v);
        }
      }
      return obj;
    },

    filterArray: (params) => (obj, env) => {
      const arr = Utils.getPath(obj, params.path);
      if (!Array.isArray(arr)) return obj;
      const exclude = new Set(params.excludeKeys || []);
      Utils.setPath(obj, params.path, arr.filter(i => !exclude.has(i?.[params.keyField])));
      return obj;
    },

    clearArray: (params) => (obj, env) => {
      const arr = Utils.getPath(obj, params.path);
      if (Array.isArray(arr)) arr.length = 0;
      return obj;
    },

    deleteFields: (params) => (obj, env) => {
      for (const path of params.paths || []) {
        if (!path) continue;
        const parts = path.split('.');
        const parentPath = parts.slice(0, -1).join('.');
        const last = parts[parts.length - 1];
        const parent = parentPath ? Utils.getPath(obj, parentPath) : obj;
        if (!parent || typeof parent !== 'object') continue;
        
        const lm = last.match(/^([^\[]+)\[(\d+)\]$/);
        if (lm) {
          const arr = parent[lm[1]];
          const idx = parseInt(lm[2]);
          if (Array.isArray(arr) && idx >= 0 && idx < arr.length) {
            arr.splice(idx, 1);
          }
        } else if (Array.isArray(parent)) {
          for (const item of parent) {
            if (item && typeof item === 'object') delete item[last];
          }
        } else {
          delete parent[last];
        }
      }
      return obj;
    },

    sliceArray: (params) => (obj, env) => {
      const arr = Utils.getPath(obj, params.path);
      if (Array.isArray(arr) && arr.length > params.keepCount) {
        Utils.setPath(obj, params.path, arr.slice(0, params.keepCount));
      }
      return obj;
    },

    shiftArray: (params) => (obj, env) => {
      const arr = Utils.getPath(obj, params.path);
      if (Array.isArray(arr) && arr.length > 0) arr.shift();
      return obj;
    },

    processByKeyPrefix: (params) => (obj, env) => {
      const target = Utils.getPath(obj, params.objPath);
      if (!target || typeof target !== 'object') return obj;
      const rules = Object.entries(params.prefixRules || {});
      for (const key in target) {
        const v = target[key];
        if (!v || typeof v !== 'object') continue;
        for (const [prefix, handler] of rules) {
          if ((prefix !== '*' && key.startsWith(prefix)) || prefix === '*') {
            Object.assign(v, handler);
            break;
          }
        }
      }
      return obj;
    },

    notify: (params) => (obj, env) => {
      const title = params.title || 'UnifiedVIP';
      let subtitle = params.subtitle || '';
      let message = params.message || '';

      if (params.subtitleField) {
        subtitle = Utils.getPath(obj, params.subtitleField) || subtitle;
      }

      if (params.template) {
        message = params.template.replace(/\{\{(\w+)\}\}/g, (m, k) => Utils.getPath(obj, k) || m);
      } else if (params.messageField) {
        const fd = Utils.getPath(obj, params.messageField);
        message = fd ? (typeof fd === 'object' ? JSON.stringify(fd) : String(fd)) : '';
      }

      if (params.prefix) message = params.prefix + message;
      if (message.length > (params.maxLength || 500)) {
        message = message.substring(0, params.maxLength || 500) + '...';
      }

      if (Platform.isQX && typeof $notify !== 'undefined') {
        $notify(title, subtitle, message, params.options || {});
      } else if (typeof $notification !== 'undefined') {
        if (Platform.isLoon && params.options?.['open-url']) {
          $notification.post(title, subtitle, message, params.options['open-url']);
        } else {
          $notification.post(title, subtitle, message, params.options || {});
        }
      }

      if (params.markField) {
        Utils.setPath(obj, params.markField, true);
      }

      return obj;
    },

    compose: (params, compile) => {
      const steps = params.steps || [];
      const maxSteps = typeof CONFIG !== 'undefined' ? CONFIG.MAX_PROCESSORS_PER_REQUEST : 30;
      if (steps.length > maxSteps) {
        throw new Error(`Too many processors: ${steps.length}`);
      }
      const processors = steps.map(s => compile(s));
      return (obj, env) => {
        let r = obj;
        for (const p of processors) {
          if (!r) break;
          r = p(r, env);
        }
        return r;
      };
    },

    when: (params, compile) => {
      const condFn = (obj, env) => {
        const url = env?.getUrl?.() || '';
        switch (params.condition) {
          case 'empty':
            const d = Utils.getPath(obj, params.check || 'data');
            return !d || Object.keys(d).length === 0;
          case 'pathMatch':
            return params.path && url.includes(params.path);
          case 'queryMatch':
            const m = url.match(RegexPool.get(`[?&]${params.param}=([^&]+)`));
            return m && decodeURIComponent(m[1]) === params.value;
          case 'includes':
            const cd = Utils.getPath(obj, params.check || 'data');
            return Array.isArray(cd) ? cd.includes(params.value) : String(cd).includes(params.value);
          case 'isObject':
            return typeof obj.data === 'object' && !Array.isArray(obj.data);
          case 'isArray':
            return Array.isArray(obj.data);
          default:
            return false;
        }
      };

      const thenP = params.then ? compile(params.then) : null;
      const elseP = params.else ? compile(params.else) : null;

      return (obj, env) => {
        const met = condFn(obj, env);
        if (met && thenP) return thenP(obj, env);
        if (!met && elseP) return elseP(obj, env);
        return obj;
      };
    },

    sceneDispatcher: (params, compile) => {
      const scenes = (params.scenes || []).map(s => ({
        matchFn: (obj, env) => {
          const url = env?.getUrl?.() || '';
          switch (s.when) {
            case 'pathMatch': return s.path && url.includes(s.path);
            case 'queryMatch':
              const m = url.match(RegexPool.get(`[?&]${s.param}=([^&]+)`));
              return m && decodeURIComponent(m[1]) === s.value;
            case 'includes':
              const d = Utils.getPath(obj, s.check || 'data');
              return Array.isArray(d) ? d.includes(s.value) : String(d).includes(s.value);
            case 'empty':
              const ed = Utils.getPath(obj, s.check || 'data');
              return !ed || Object.keys(ed).length === 0;
            case 'isObject': return typeof obj.data === 'object' && !Array.isArray(obj.data);
            case 'isArray': return Array.isArray(obj.data);
            default: return false;
          }
        },
        then: compile(s.then)
      }));

      return (obj, env) => {
        for (const s of scenes) {
          if (s.matchFn(obj, env)) return s.then(obj, env);
        }
        return obj;
      };
    }
  };
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { createProcessorFactory };
}

// ==========================================
// 10. 处理器编译器
// ==========================================
// src/engine/compiler.js
// 处理器编译器 - 极速版

function createCompiler(factory) {
  const cache = new Map();
  const MAX_CACHE = 200;
  
  return function compileProcessor(def) {
    if (!def || !def.processor) return null;
    
    const key = Utils.simpleHash(Utils.safeJsonStringify(def));
    const cached = cache.get(key);
    if (cached) return cached;
    
    const pf = factory[def.processor];
    if (!pf) return null;
    
    const processor = pf(def.params, compileProcessor);
    if (processor) {
      if (cache.size >= MAX_CACHE) {
        const first = cache.keys().next().value;
        cache.delete(first);
      }
      cache.set(key, processor);
    }
    return processor;
  };
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { createCompiler };
}

// ==========================================
// 11. Manifest加载器
// ==========================================
// src/engine/manifest-loader.js
// Manifest加载器 - 极速版

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

// ==========================================
// 12. 配置加载器
// ==========================================
// src/engine/config-loader.js
// 配置加载器 - 极速版

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
          return d;
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
        return d;
      }
      throw e;
    }
  }

  _prepareConfig(raw) {
    const config = { ...raw };

    if (config.mode === 'forward' || config.mode === 'remote') {
      return config;
    }

    if (raw.regexReplacements) {
      config._regexReplacements = raw.regexReplacements.map(r => ({
        pattern: RegexPool.get(r.pattern, r.flags || 'g'),
        replacement: r.replacement
      }));
    }

    if (raw.gameResources) {
      config._gameResources = raw.gameResources.map(r => ({
        field: r.field,
        value: r.value,
        pattern: RegexPool.get(`"${r.field}":\\d+`, 'g')
      }));
    }

    if (raw.htmlReplacements) {
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

// ==========================================
// 13. VIP引擎
// ==========================================
// src/engine/vip-engine.js
// VIP引擎 - 极速版

class Environment {
  constructor(name) {
    this.name = name;
    this.isQX = typeof Platform !== 'undefined' ? Platform.isQX : false;
    this.isSurge = typeof Platform !== 'undefined' ? Platform.isSurge : false;
    this.isLoon = typeof Platform !== 'undefined' ? Platform.isLoon : false;
    this.isStash = typeof Platform !== 'undefined' ? Platform.isStash : false;

    this.response = (typeof $response !== 'undefined') ? $response : {};
    this.request = (typeof $request !== 'undefined') ? $request : {};

    if (!this.request.url && this.response?.request) {
      this.request = this.response.request;
    }
  }

  getUrl() {
    let url = this.response?.url || this.request?.url || '';
    if (this.isQX && typeof $request === 'string') {
      url = $request;
    }
    return url.toString();
  }

  getBody() {
    return this.response?.body || '';
  }

  getRequestHeaders() {
    return this.request?.headers || {};
  }

  getRequestBody() {
    return this.request?.body || '';
  }

  done(result) {
    if (typeof $done === 'function') {
      $done(result);
    } else {
      console.log('[DONE]', result);
    }
  }
}

class VipEngine {
  constructor(env, requestId) {
    this.env = env;
    this._requestId = requestId;
  }

  async process(body, config) {
    if (!config || !config.mode) {
      return { body: typeof body === 'string' ? body : Utils.safeJsonStringify(body || {}) };
    }

    // forward/remote 模式优先处理
    if (config.mode === 'forward') {
      return await this._processForward(config);
    }
    if (config.mode === 'remote') {
      return await this._processRemote(config);
    }

    const normalizedBody = typeof body === 'string' ? body : Utils.safeJsonStringify(body || {});
    if (!normalizedBody) return { body: '{}' };

    const maxSize = typeof CONFIG !== 'undefined' ? CONFIG.MAX_BODY_SIZE : 5242880;
    if (normalizedBody.length > maxSize) {
      return { body: normalizedBody };
    }

    switch (config.mode) {
      case 'json':
        return this._processJson(normalizedBody, config);
      case 'regex':
        return this._processRegex(normalizedBody, config);
      case 'game':
        return this._processGame(normalizedBody, config);
      case 'hybrid':
        return this._processHybrid(normalizedBody, config);
      case 'html':
        return this._processHtml(normalizedBody, config);
      default:
        return { body: normalizedBody };
    }
  }

  _delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  _shouldRetryError(error) {
    const msg = String(error?.message || '').toLowerCase();
    return msg.includes('timeout') || msg.includes('network') || msg.includes('timed out');
  }

  async _requestWithRetry(requestFn, retryConfig = {}) {
    const retries = Math.max(0, Number(retryConfig.retries || 0));
    const delayMs = Math.max(0, Number(retryConfig.delayMs || 300));

    let lastError = null;
    for (let attempt = 0; attempt <= retries; attempt++) {
      try {
        return await requestFn();
      } catch (e) {
        lastError = e;
        if (attempt >= retries || !this._shouldRetryError(e)) {
          throw e;
        }
        Logger.warn('VipEngine', `Retry ${attempt + 1}/${retries} after error: ${e.message}`);
        await this._delay(delayMs);
      }
    }

    throw lastError || new Error('Unknown request error');
  }

  async _processForward(config) {
    const statusTexts = config.statusTexts || {
      '200': 'OK', '201': 'Created', '204': 'No Content',
      '400': 'Bad Request', '401': 'Unauthorized', '403': 'Forbidden',
      '404': 'Not Found', '500': 'Internal Server Error',
      '502': 'Bad Gateway', '503': 'Service Unavailable'
    };

    const requestHeaders = this.env.getRequestHeaders();
    const requestHeadersLower = {};
    for (const [k, v] of Object.entries(requestHeaders || {})) {
      requestHeadersLower[String(k).toLowerCase()] = v;
    }

    const forwardHeaders = {};
    if (config.forwardHeaders && typeof config.forwardHeaders === 'object') {
      for (const [key, value] of Object.entries(config.forwardHeaders)) {
        if (typeof value === 'string' && value.startsWith('{{') && value.endsWith('}}')) {
          const headerName = value.slice(2, -2).trim().toLowerCase();
          forwardHeaders[key] = requestHeadersLower[headerName] || requestHeaders[headerName] || '';
        } else {
          forwardHeaders[key] = value;
        }
      }
    }

    const options = {
      url: config.forwardUrl,
      method: config.method || 'POST',
      headers: forwardHeaders,
      body: this.env.getRequestBody(),
      timeout: config.timeout || 10000
    };

    const retryConfig = {
      retries: typeof config.retryTimes === 'number' ? config.retryTimes : 1,
      delayMs: typeof config.retryDelayMs === 'number' ? config.retryDelayMs : 300
    };

    Logger.info('Forward', `Forwarding to ${options.url}`);

    try {
      const response = await this._requestWithRetry(() => HTTP.post(options), retryConfig);
      const statusCode = response.statusCode || 200;
      const statusText = statusTexts[String(statusCode)] || 'Unknown';

      const responseHeaders = {};
      if (config.responseHeaders && typeof config.responseHeaders === 'object') {
        Object.assign(responseHeaders, config.responseHeaders);
      }

      return {
        status: `HTTP/1.1 ${statusCode} ${statusText}`,
        statusCode,
        headers: responseHeaders,
        body: response.body
      };
    } catch (e) {
      Logger.error('Forward', `Failed: ${e.message}`);
      const errorCode = 500;
      const errorText = statusTexts[String(errorCode)] || 'Internal Server Error';
      
      return {
        status: `HTTP/1.1 ${errorCode} ${errorText}`,
        statusCode: errorCode,
        headers: config.responseHeaders ? { ...config.responseHeaders } : {},
        body: Utils.safeJsonStringify({
          error: 'Request failed',
          message: e.message,
          timestamp: new Date().toISOString()
        })
      };
    }
  }

  _pickHeaderCaseInsensitive(headers, key) {
    if (!headers || !key) return undefined;
    if (headers[key] !== undefined) return headers[key];
    const target = String(key).toLowerCase();
    for (const [k, v] of Object.entries(headers)) {
      if (String(k).toLowerCase() === target) return v;
    }
    return undefined;
  }

  _applyRemoteHeaderPolicy(config, sourceHeaders = {}, responseHeaders = {}) {
    const policy = config?.headerPolicy || {};
    const whitelist = Array.isArray(policy.whitelist)
      ? policy.whitelist
      : (Array.isArray(config.preserveHeaders) ? config.preserveHeaders : []);

    for (const key of whitelist) {
      const value = this._pickHeaderCaseInsensitive(sourceHeaders, key);
      if (value !== undefined) responseHeaders[key] = value;
    }

    if (policy.passContentType !== false) {
      const remoteContentType = this._pickHeaderCaseInsensitive(sourceHeaders, 'content-type');
      if (remoteContentType && !this._pickHeaderCaseInsensitive(responseHeaders, 'content-type')) {
        responseHeaders['Content-Type'] = remoteContentType;
      }
    }

    if (policy.passCacheHeaders === true) {
      ['cache-control', 'etag', 'last-modified', 'expires'].forEach(k => {
        const value = this._pickHeaderCaseInsensitive(sourceHeaders, k);
        if (value !== undefined && this._pickHeaderCaseInsensitive(responseHeaders, k) === undefined) {
          responseHeaders[k] = value;
        }
      });
    }

    if (config.forceHeaders && typeof config.forceHeaders === 'object') {
      Object.assign(responseHeaders, config.forceHeaders);
    }

    if (!this._pickHeaderCaseInsensitive(responseHeaders, 'content-type')) {
      responseHeaders['Content-Type'] = 'application/json; charset=utf-8';
    }

    return responseHeaders;
  }

  async _processRemote(config) {
    if (!config.remoteUrl) {
      Logger.error('Remote', 'Missing remoteUrl');
      return {};
    }

    try {
      const retryConfig = {
        retries: typeof config.retryTimes === 'number' ? config.retryTimes : 1,
        delayMs: typeof config.retryDelayMs === 'number' ? config.retryDelayMs : 300
      };

      const response = await this._requestWithRetry(
        () => HTTP.get(config.remoteUrl, config.timeout || 10000),
        retryConfig
      );

      if (response.statusCode !== 200 || !response.body) {
        return {};
      }

      if (config.validateJson !== false) {
        try {
          JSON.parse(response.body);
        } catch (e) {
          return {};
        }
      }

      const responseHeaders = this._applyRemoteHeaderPolicy(config, response.headers || {}, {});

      Logger.info('Remote', `Success: ${response.body.length} bytes`);
      return { headers: responseHeaders, body: response.body };

    } catch (e) {
      Logger.error('Remote', `Error: ${e.message}`);
      return {};
    }
  }

  _processJson(body, config) {
    let obj = Utils.safeJsonParse(body);
    if (!obj) return { body };

    const factory = createProcessorFactory(this._requestId);
    const compile = createCompiler(factory);
    const processor = config.processor ? compile(config.processor) : null;

    if (typeof processor === 'function') {
      try {
        obj = processor(obj, this.env);
        Logger.info('VipEngine', `${config.name || 'VIP'} unlocked`);
      } catch (e) {
        Logger.error('VipEngine', `Processor error: ${e.message}`);
      }
    }

    return { body: Utils.safeJsonStringify(obj) };
  }

  _processRegex(body, config) {
    let modified = body;
    const replacements = config._regexReplacements || config.regexReplacements || [];

    for (const rule of replacements) {
      try {
        const regex = rule.pattern instanceof RegExp ? rule.pattern : RegexPool.get(rule.pattern, rule.flags || 'g');
        modified = modified.replace(regex, rule.replacement);
      } catch (e) {}
    }

    return { body: modified };
  }

  _processGame(body, config) {
    let modified = body;
    const resources = config._gameResources || config.gameResources || [];

    for (const res of resources) {
      try {
        const regex = res.pattern instanceof RegExp ? res.pattern : RegexPool.get(`"${res.field}":\\d+`, 'g');
        modified = modified.replace(regex, `"${res.field}":${res.value}`);
      } catch (e) {}
    }

    return { body: modified };
  }

  _processHybrid(body, config) {
    let result = this._processJson(body, config);
    if (config._regexReplacements || config.regexReplacements) {
      result = this._processRegex(result.body, config);
    }
    return result;
  }

  _processHtml(body, config) {
    let modified = body;
    const replacements = config._htmlReplacements || config.htmlReplacements || [];

    for (const rule of replacements) {
      try {
        const regex = rule.pattern instanceof RegExp ? rule.pattern : RegexPool.get(rule.pattern, rule.flags || 'gi');
        modified = modified.replace(regex, rule.replacement);
      } catch (e) {}
    }

    return { body: modified };
  }
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { Environment, VipEngine };
}

// ==========================================
// 14. 主入口
// ==========================================
async function main(){
  const rid = Math.random().toString(36).slice(2, 8).toUpperCase();
  try {
    let u = '';
    if (typeof $request !== 'undefined') u = typeof $request === 'string' ? $request : $request.url || '';
    else if (typeof $response !== 'undefined' && $response) u = $response.url || '';
    if (!u) return $done(typeof $response !== 'undefined' && $response ? { body: $response.body } : {});

    Logger.debug('Main', rid + '|' + u.split('?')[0].slice(0, 60));

    const g = typeof globalThis !== 'undefined' ? globalThis : {};
    const ml = g.__UVIP_ML || (g.__UVIP_ML = new SimpleManifestLoader('GLOBAL'));
    const mf = g.__UVIP_MF || (g.__UVIP_MF = await ml.load());
    const cid = mf.findMatch(u);

    if (!cid) {
      Logger.debug('Main', 'No match');
      return $done(typeof $response !== 'undefined' && $response ? { body: $response.body } : {});
    }

    const cl = g.__UVIP_CL || (g.__UVIP_CL = new SimpleConfigLoader('GLOBAL'));
    const cfg = await cl.load(cid, mf.getConfigVersion(cid));
    const env = new Environment(META.name);
    const eng = new VipEngine(env, rid);
    const res = await eng.process(typeof $response !== 'undefined' && $response ? $response.body : '', cfg);

    Logger.debug('Main', rid + ' done [' + cfg.mode + ']');
    $done(res);
  } catch (e) {
    Logger.error('Main', rid + ' fail:' + e.message);
    $done(typeof $response !== 'undefined' && $response ? { body: $response.body } : {});
  }
}
main();
