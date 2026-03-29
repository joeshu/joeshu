// src/core/http.js
// HTTP 客户端 - 极速版 (修复版)

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
