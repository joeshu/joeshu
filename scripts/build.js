#!/usr/bin/env node

// scripts/build.js
// 构建脚本 - 极速版

const fs = require('fs');
const path = require('path');
const pkg = require('../package.json');
const BuildGenerators = require('./build/generators');

// ==========================================
// 构建配置
// ==========================================
const BUILD_CONFIG = {
  ENABLE_DIAGNOSE: false,
  DEBUG_MODE: false,  // 生产环境关闭DEBUG
  VERSION_TAG: '',
  get VERSION() {
    return this.VERSION_TAG ? `${pkg.version}-${this.VERSION_TAG}` : pkg.version;
  }
};

const SRC_DIR = path.join(__dirname, '../src');
const DIST_DIR = path.join(__dirname, '../dist');
const CONFIGS_DIR = path.join(__dirname, '../configs');
const RULES_DIR = path.join(__dirname, '../rules');

// ==========================================
// 步骤 0: 准备目录
// ==========================================
console.log('📂 准备目录...');

if (fs.existsSync(DIST_DIR)) {
  fs.rmSync(DIST_DIR, { recursive: true, force: true });
}
fs.mkdirSync(DIST_DIR, { recursive: true });
fs.mkdirSync(path.join(DIST_DIR, 'configs'), { recursive: true });

if (!fs.existsSync(RULES_DIR)) {
  fs.mkdirSync(RULES_DIR, { recursive: true });
}

// ==========================================
// 加载 APP 注册表
// ==========================================
const { APP_REGISTRY, getAllConfigs } = require('../src/apps/_index');
const { generatePrefixIndex } = require('../src/apps/_prefix-index');

// ==========================================
// 辅助函数
// ==========================================
function loadModule(filename) {
  const content = fs.readFileSync(path.join(SRC_DIR, filename), 'utf8');
  return content.replace(/\/\/ CommonJS导出[\s\S]*$/, '').trim();
}

// ==========================================
// 主构建流程
// ==========================================
function build() {
  console.log(`\n🔨 构建 UnifiedVIP v${BUILD_CONFIG.VERSION}`);
  console.log(`   DEBUG模式: ${BUILD_CONFIG.DEBUG_MODE ? '✅ 启用' : '❌ 禁用'}\n`);

  // 步骤 1: 读取配置
  console.log('📦 读取配置...');
  let allConfigs;
  try {
    allConfigs = getAllConfigs();
    console.log(`   ✅ ${Object.keys(allConfigs).length} 个配置`);
  } catch (e) {
    console.error(`   ❌ 失败: ${e.message}`);
    process.exit(1);
  }

  // 步骤 2: 生成 configs
  console.log('📦 生成 configs...');
  let count = 0;
  for (const [appId, config] of Object.entries(allConfigs)) {
    const jsonContent = JSON.stringify(config);
    fs.writeFileSync(path.join(CONFIGS_DIR, `${appId}.json`), jsonContent);
    fs.writeFileSync(path.join(DIST_DIR, 'configs', `${appId}.json`), jsonContent);
    count++;
  }
  console.log(`   ✅ ${count} 个配置文件`);

  // 步骤 3: 加载核心模块
  console.log('📦 加载核心模块...');
  const modules = {
    platform: loadModule('core/platform.js'),
    logger: loadModule('core/logger.js'),
    storage: loadModule('core/storage.js'),
    http: loadModule('core/http.js'),
    utils: loadModule('core/utils.js'),
    regexPool: loadModule('engine/regex-pool.js'),
    processorFactory: loadModule('engine/processor-factory.js'),
    compiler: loadModule('engine/compiler.js'),
    manifestLoader: loadModule('engine/manifest-loader.js'),
    configLoader: loadModule('engine/config-loader.js'),
    vipEngine: loadModule('engine/vip-engine.js')
  };
  console.log('   ✅ 11 个核心模块');

  // 步骤 4: 组装主脚本
  console.log('📦 组装主脚本...');

  const manifestStr = BuildGenerators.generateManifestOneLine({ APP_REGISTRY, CONFIGS_DIR, BUILD_CONFIG });
  const prefixCode = BuildGenerators.generatePrefixIndexCode(generatePrefixIndex());

  const fullScript = `${BuildGenerators.generateHeaderMinified({ BUILD_CONFIG, APP_REGISTRY })}

// ==========================================
// 1. 内置Manifest
// ==========================================
const BUILTIN_MANIFEST = ${manifestStr};

// ==========================================
// 2. 前缀索引
// ==========================================
${prefixCode}

// ==========================================
// 3. 平台检测
// ==========================================
${modules.platform}

// ==========================================
// 4. 日志系统
// ==========================================
${modules.logger}

// ==========================================
// 5. M3存储系统
// ==========================================
${modules.storage}

// ==========================================
// 6. HTTP客户端
// ==========================================
${modules.http}

// ==========================================
// 7. 工具函数
// ==========================================
${modules.utils}

// ==========================================
// 8. 正则缓存池
// ==========================================
${modules.regexPool}

// ==========================================
// 9. 处理器工厂
// ==========================================
${modules.processorFactory}

// ==========================================
// 10. 处理器编译器
// ==========================================
${modules.compiler}

// ==========================================
// 11. Manifest加载器
// ==========================================
${modules.manifestLoader}

// ==========================================
// 12. 配置加载器
// ==========================================
${modules.configLoader}

// ==========================================
// 13. VIP引擎
// ==========================================
${modules.vipEngine}

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
`;

  // 步骤 5: 写入构建产物
  console.log('📦 写入构建产物...');

  const outputPath = path.join(DIST_DIR, 'Unified_VIP_Unlock_Manager_v22.js');
  fs.writeFileSync(outputPath, fullScript);
  const scriptSize = (fs.statSync(outputPath).size / 1024).toFixed(2);
  console.log(`   ✅ Unified_VIP_Unlock_Manager_v22.js (${scriptSize} KB)`);

  const rewritePath = path.join(DIST_DIR, 'rewrite.conf');
  fs.writeFileSync(rewritePath, BuildGenerators.generateRewriteConf({
    BUILD_CONFIG,
    APP_REGISTRY,
    getAllConfigs,
    RULES_DIR
  }));
  const rewriteSize = (fs.statSync(rewritePath).size / 1024).toFixed(2);
  console.log(`   ✅ rewrite.conf (${rewriteSize} KB)`);

  console.log('\n📋 构建完成:');
  const distFiles = fs.readdirSync(DIST_DIR);
  distFiles.forEach(file => {
    const stat = fs.statSync(path.join(DIST_DIR, file));
    const size = stat.isDirectory() ? '-' : `${(stat.size / 1024).toFixed(2)} KB`;
    console.log(`   ${stat.isDirectory() ? '📁' : '📄'} ${file.padEnd(40)} ${size}`);
  });

  const configCount = fs.readdirSync(path.join(DIST_DIR, 'configs')).filter(f => f.endsWith('.json')).length;
  console.log(`   📦 configs/*.json (${configCount} 个)`);

  console.log('\n🚀 发布:');
  console.log('   git add . && git commit -m "build: update v22" && git push');
  console.log('\n📎 订阅: https://joeshu.github.io/joeshu/rewrite.conf');
}

// 运行构建
build();
