// src/engine/vip-engine.js
// VIP引擎 - 极速版 (修复版)

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
    // FIX: QX 平台 $request 可能是字符串（整个 URL）
    if (this.isQX && typeof $request === 'string') {
      url = $request;
    }
    return url.toString();
  }

  getBody() {
    // FIX: 确保返回字符串
    const body = this.response?.body;
    return typeof body === 'string' ? body : (body ? String(body) : '');
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
    // FIX: 确保 body 是字符串
    const normalizedBody = typeof body === 'string' ? body : (body ? String(body) : '');
    
    if (!config || !config.mode) {
      return { body: normalizedBody };
    }

    // forward/remote 模式优先处理
    if (config.mode === 'forward') {
      return await this._processForward(config);
    }
    if (config.mode === 'remote') {
      return await this._processRemote(config);
    }

    if (!normalizedBody) return { body: '' };

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
    // FIX: 优先使用预编译的 _htmlReplacements
    const replacements = config._htmlReplacements || config.htmlReplacements || [];
    
    // FIX: 添加调试日志
    Logger.debug('VipEngine', `HTML processing: ${replacements.length} rules`);

    for (const rule of replacements) {
      try {
        const regex = rule.pattern instanceof RegExp ? rule.pattern : RegexPool.get(rule.pattern, rule.flags || 'gi');
        modified = modified.replace(regex, rule.replacement);
      } catch (e) {
        Logger.error('VipEngine', `HTML replace error: ${e.message}`);
      }
    }

    return { body: modified };
  }
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { Environment, VipEngine };
}
