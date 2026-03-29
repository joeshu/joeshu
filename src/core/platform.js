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
