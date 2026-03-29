const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

function generateHeaderMinified({ BUILD_CONFIG, APP_REGISTRY }) {
  const debugFlag = BUILD_CONFIG.DEBUG_MODE ? 'true' : 'false';

  return `/*
 * ==========================================
 * Unified VIP Unlock Manager v${BUILD_CONFIG.VERSION}
 * 构建时间: ${new Date().toISOString()}
 * APP数量: ${Object.keys(APP_REGISTRY).length}
 * ==========================================
 * 订阅规则: https://joeshu.github.io/joeshu/rewrite.conf
 */

'use strict';

if (typeof console === 'undefined') { globalThis.console = { log: () => {} }; }

const CONFIG = {
  REMOTE_BASE: 'https://joeshu.github.io/joeshu',
  CONFIG_CACHE_TTL: 86400000,
  MAX_BODY_SIZE: 5242880,
  MAX_PROCESSORS_PER_REQUEST: 30,
  TIMEOUT: 10,
  DEBUG: ${debugFlag},
  VERBOSE_PATTERN_LOG: ${debugFlag},
  URL_CACHE_KEY: 'url_match_v22_lazy',
  URL_CACHE_META_KEY: 'url_match_v22_lazy_meta',
  URL_CACHE_MIGRATED_KEY: 'url_match_v22_lazy_migrated',
  URL_CACHE_LEGACY_KEYS: ['url_match_v22', 'url_match_v21_lazy', 'url_match_cache_v22'],
  URL_CACHE_TTL_MS: 3600000,
  URL_CACHE_PERSIST_INTERVAL_MS: 15000,
  URL_CACHE_LIMIT: 50
};

const META = { name: 'joeshu', version: '${BUILD_CONFIG.VERSION}' };`;
}

function generateManifestOneLine({ APP_REGISTRY, CONFIGS_DIR, BUILD_CONFIG }) {
  const configs = {};
  for (const [id, baseCfg] of Object.entries(APP_REGISTRY)) {
    const configPath = path.join(CONFIGS_DIR, `${id}.json`);
    if (fs.existsSync(configPath)) {
      try {
        const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
        configs[id] = { name: config.name || id, urlPattern: config.urlPattern };
      } catch (e) {
        configs[id] = { name: id, urlPattern: baseCfg.urlPattern };
      }
    } else {
      configs[id] = { name: id, urlPattern: baseCfg.urlPattern };
    }
  }

  const manifestSourceHash = crypto
    .createHash('md5')
    .update(JSON.stringify(configs))
    .digest('hex')
    .slice(0, 8);

  return JSON.stringify({
    version: `${BUILD_CONFIG.VERSION}-${manifestSourceHash}`,
    updated: new Date().toISOString().split('T')[0],
    total: Object.keys(configs).length,
    configs
  });
}

function generatePrefixIndexCode(index) {
  const lines = ['const PREFIX_INDEX = {'];
  
  const emitGroup = (name, data, withComma = true) => {
    lines.push(` ${name}: {`);
    const entries = Object.entries(data || {});
    entries.forEach(([k, v], i) => {
      lines.push(`  '${k}': ${JSON.stringify(v)}${i < entries.length - 1 ? ',' : ''}`);
    });
    lines.push(withComma ? ' },' : ' }');
  };

  emitGroup('exact', index.exact || {});
  emitGroup('suffix', index.suffix || {});
  
  if (index.keyword && Object.keys(index.keyword).length > 0) {
    emitGroup('keyword', index.keyword, false);
  }

  lines.push('};');
  lines.push(`function findByPrefix(h){h=h.toLowerCase();if(PREFIX_INDEX.exact[h])return{ids:PREFIX_INDEX.exact[h],method:'exact',matched:h};for(const[s,ids]of Object.entries(PREFIX_INDEX.suffix))if(h.endsWith('.'+s)||h===s)return{ids,method:'suffix',matched:s};if(PREFIX_INDEX.keyword)for(const[k,ids]of Object.entries(PREFIX_INDEX.keyword))if(h.includes(k))return{ids,method:'keyword',matched:k};return null}`);
  return lines.join('\n');
}

function generateRewriteConf({ BUILD_CONFIG, APP_REGISTRY, getAllConfigs, RULES_DIR }) {
  const autoHostSet = new Set();
  for (const cfg of Object.values(APP_REGISTRY)) {
    if (!cfg?.urlPattern || typeof cfg.urlPattern !== 'string') continue;
    const hostMatches = cfg.urlPattern.match(/[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g) || [];
    for (const host of hostMatches) {
      const h = host.toLowerCase();
      if (h.includes('\\/') || /^\d+\.\d+\.\d+\.\d+$/.test(h) || h.includes('.*')) continue;
      if (h.startsWith('www.')) {
        autoHostSet.add(h);
        autoHostSet.add(h.slice(4));
      } else {
        autoHostSet.add(h);
      }
    }
  }

  const manualHosts = [
    '59.82.99.78', '*.ipalfish.com', 'service.hhdd.com', 'apis.lifeweek.com.cn', 'fluxapi.vvebo.vip',
    'res5.haotgame.com', 'jsq.mingcalc.cn', 'theater-api.sylangyue.xyz', 'api.iappdaily.com',
    'api2.tophub.today', 'api2.tophub.app', 'api3.tophub.xyz', 'api3.tophub.today', 'api3.tophub.app',
    'tophub.tophubdata.com', 'tophub2.tophubdata.com', 'tophub.idaily.today', 'tophub2.idaily.today',
    'tophub.remai.today', 'tophub.iappdaiy.com', 'tophub.ipadown.com', 'service.gpstool.com',
    'mapi.kouyuxingqiu.com', 'ss.landintheair.com', '*.v2ex.com', 'apis.folidaymall.com',
    'gateway-api.yizhilive.com', 'pagead*.googlesyndication.com', 'api.gotokeep.com', 'kit.gotokeep.com',
    '*.gotokeep.*', '120.53.74.*', '162.14.5.*', '42.187.199.*', '101.42.124.*', 'javelin.mandrillvr.com',
    'api.banxueketang.com', 'yzy0916.*.com', 'yz1018.*.com', 'yz250907.*.com', 'yz0320.*.com',
    'cfvip.*.com', 'yr-game-api.feigo.fun', 'star.jvplay.cn', 'iotpservice.smartont.net'
  ];

  const hostnames = Array.from(new Set([...manualHosts, ...Array.from(autoHostSet)])).sort();
  
  let conf = `# Unified VIP Unlock Manager v${BUILD_CONFIG.VERSION}
# 构建时间: ${new Date().toISOString()}
# APP数量: ${Object.keys(APP_REGISTRY).length}

[rewrite_local]

`;

  let allConfigs = {};
  try { allConfigs = getAllConfigs(); } catch (e) {
    for (const [id, cfg] of Object.entries(APP_REGISTRY)) allConfigs[id] = { name: id, ...cfg };
  }

  for (const [id, cfg] of Object.entries(APP_REGISTRY)) {
    const name = allConfigs[id]?.name || id;
    conf += `# ${name}\n${cfg.urlPattern} url script-response-body https://joeshu.github.io/joeshu/Unified_VIP_Unlock_Manager_v22.js\n\n`;
  }

  const customRejectPath = path.join(RULES_DIR, 'custom-reject.txt');
  if (fs.existsSync(customRejectPath)) {
    const customRules = fs.readFileSync(customRejectPath, 'utf8')
      .split('\n')
      .map(s => s.trim())
      .filter(s => s && !s.startsWith('#'))
      .map(s => s.includes(' url ') ? s : `${s} url reject-dict`);
    if (customRules.length > 0) conf += `# custom reject\n${customRules.join('\n')}\n\n`;
  }

  conf += `[mitm]\nhostname = ${hostnames.join(', ')}\n`;
  return conf;
}

module.exports = {
  generateHeaderMinified,
  generateManifestOneLine,
  generatePrefixIndexCode,
  generateRewriteConf
};
