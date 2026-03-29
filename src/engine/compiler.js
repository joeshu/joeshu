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
