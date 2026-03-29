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
