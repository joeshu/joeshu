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
