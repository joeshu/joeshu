// src/apps/_index.js
// APP注册表 - 支持 configs/*.json + 内联 urlPattern 双模式（带诊断功能）

const fs = require('fs');
const path = require('path');

const CONFIGS_DIR = path.join(__dirname, '../../configs');

// ==========================================
// 内联注册表 - 应急使用
// ==========================================
const INLINE_REGISTRY = {};

// ==========================================
// 扫描 configs 目录（带详细诊断）
// ==========================================
function scanConfigs() {
  const registry = {};
  const skipped = [];   // 记录被跳过的文件
  const errors = [];    // 记录错误
  const processed = []; // 记录成功处理的文件
  
  // 1. 首先加载内联注册表
  for (const [id, cfg] of Object.entries(INLINE_REGISTRY)) {
    registry[id] = { urlPattern: cfg.urlPattern };
  }

  // 2. 扫描 configs 目录
  if (!fs.existsSync(CONFIGS_DIR)) {
    console.error('❌ configs/ 目录不存在!');
    return { registry, skipped, errors, processed };
  }

  // 获取所有文件（包括非 json 文件，用于诊断）
  const allFiles = fs.readdirSync(CONFIGS_DIR).sort();
  const jsonFiles = allFiles.filter(f => f.endsWith('.json'));
  const nonJsonFiles = allFiles.filter(f => !f.endsWith('.json'));

  console.log(`\n📁 configs/ 目录内容:`);
  console.log(`   总文件数: ${allFiles.length}`);
  console.log(`   JSON文件: ${jsonFiles.length}`);
  if (nonJsonFiles.length > 0) {
    console.log(`   非JSON文件: ${nonJsonFiles.join(', ')} (将被忽略)`);
  }

  console.log(`\n🔍 开始扫描 ${jsonFiles.length} 个 JSON 文件...\n`);

  for (const file of jsonFiles) {
    const id = file.replace('.json', '');
    const filePath = path.join(CONFIGS_DIR, file);
    
    try {
      const content = fs.readFileSync(filePath, 'utf8');
      
      // 检查是否为空文件
      if (!content || content.trim() === '') {
        skipped.push({ file, id, reason: '文件为空' });
        console.log(`   ⚠️  ${file} - 跳过: 文件为空`);
        continue;
      }
      
      let config;
      try {
        config = JSON.parse(content);
      } catch (parseErr) {
        skipped.push({ file, id, reason: `JSON解析错误: ${parseErr.message}` });
        console.log(`   ❌ ${file} - 跳过: JSON解析失败`);
        continue;
      }
      
      // 检查是否有 urlPattern
      if (config.urlPattern && typeof config.urlPattern === 'string' && config.urlPattern.trim() !== '') {
        registry[id] = { urlPattern: config.urlPattern };
        processed.push({ file, id, urlPattern: config.urlPattern.substring(0, 40) + '...' });
        console.log(`   ✅ ${file.padEnd(20)} - 已注册`);
      } else if (registry[id]) {
        // JSON 中没有 urlPattern，但内联有
        processed.push({ file, id, urlPattern: '(来自内联)' });
        console.log(`   ℹ️  ${file.padEnd(20)} - 使用内联 urlPattern`);
      } else {
        // 既没有 urlPattern 也没有内联配置
        skipped.push({ 
          file, 
          id, 
          reason: '缺少 urlPattern 字段',
          hasFields: Object.keys(config).join(', ') || '(空对象)'
        });
        console.log(`   ⚠️  ${file.padEnd(20)} - 跳过: 缺少 urlPattern (字段: ${Object.keys(config).join(', ')})`);
      }
    } catch (e) {
      errors.push({ file, error: e.message });
      console.log(`   ❌ ${file.padEnd(20)} - 错误: ${e.message}`);
    }
  }

  // 输出详细统计
  console.log(`\n${'='.repeat(60)}`);
  console.log('📊 构建统计报告');
  console.log(`${'='.repeat(60)}`);
  console.log(`   总 JSON 文件: ${jsonFiles.length}`);
  console.log(`   ✅ 成功注册:  ${processed.length}`);
  console.log(`   ⚠️  被跳过:   ${skipped.length}`);
  console.log(`   ❌ 错误:      ${errors.length}`);
  console.log(`   📦 最终注册:  ${Object.keys(registry).length} 个 APP`);

  if (skipped.length > 0) {
    console.log(`\n⚠️  被跳过的文件详情 (${skipped.length} 个):`);
    skipped.forEach((s, i) => {
      console.log(`   ${i + 1}. ${s.file}`);
      console.log(`      原因: ${s.reason}`);
      if (s.hasFields) console.log(`      已有字段: ${s.hasFields}`);
    });
  }
  
  if (errors.length > 0) {
    console.log(`\n❌ 出错的文件 (${errors.length} 个):`);
    errors.forEach((e, i) => {
      console.log(`   ${i + 1}. ${e.file}: ${e.error}`);
    });
  }

  // 输出所有成功注册的 APP 列表
  console.log(`\n📋 已注册的 APP 列表 (${processed.length} 个):`);
  processed.forEach((p, i) => {
    console.log(`   ${String(i + 1).padStart(2)}. ${p.id.padEnd(15)} ${p.urlPattern.substring(0, 50)}`);
  });

  console.log(''); // 空行

  return { registry, skipped, errors, processed };
}

// 动态生成 APP_REGISTRY
const scanResult = scanConfigs();
const APP_REGISTRY = scanResult.registry;

// ==========================================
// 获取所有配置
// ==========================================
function getAllConfigs() {
  const configs = {};

  for (const [id, baseCfg] of Object.entries(APP_REGISTRY)) {
    const configPath = path.join(CONFIGS_DIR, `${id}.json`);
    
    if (fs.existsSync(configPath)) {
      try {
        const fullConfig = JSON.parse(fs.readFileSync(configPath, 'utf8'));
        configs[id] = {
          urlPattern: baseCfg.urlPattern,
          ...fullConfig
        };
      } catch (e) {
        console.warn(`⚠️ 读取 configs/${id}.json 失败，使用最小配置`);
        configs[id] = {
          urlPattern: baseCfg.urlPattern,
          name: id,
          mode: 'json',
          priority: 10,
          description: `${id} VIP解锁`
        };
      }
    } else {
      configs[id] = {
        urlPattern: baseCfg.urlPattern,
        name: id,
        mode: 'json',
        priority: 10,
        description: `${id} VIP解锁（应急配置）`
      };
    }
  }

  return configs;
}

// ==========================================
// 生成 Manifest
// ==========================================
function generateManifest() {
  const configs = {};
  
  for (const [id, cfg] of Object.entries(APP_REGISTRY)) {
    configs[id] = {
      urlPattern: cfg.urlPattern,
      configFile: `${id}.json`
    };
  }

  return {
    version: "22.0.0",
    updated: new Date().toISOString().split('T')[0],
    total: Object.keys(APP_REGISTRY).length,
    configs: configs
  };
}

// ==========================================
// 生成 rewrite.conf 注释
// ==========================================
function generateRewriteComments() {
  const allConfigs = getAllConfigs();

  return Object.entries(APP_REGISTRY).map(([id, cfg]) => {
    const fullCfg = allConfigs[id] || {};
    const name = fullCfg.name || id;
    return ` * # ${name}\\n * ${cfg.urlPattern} url script-response-body https://joeshu.github.io/joeshu/Unified_VIP_Unlock_Manager_v22.js`;
  }).join('\\n');
}

// ==========================================
// 生成前缀索引
// ==========================================
function generatePrefixIndex() {
  const index = {
    exact: {},
    suffix: {},
    keyword: {}
  };

  const allConfigs = getAllConfigs();

  for (const [id, cfg] of Object.entries(allConfigs)) {
    const pattern = cfg.urlPattern;
    if (!pattern) continue;

    const domainMatches = pattern.match(/[a-z0-9][a-z0-9-]*\.[a-z0-9][a-z0-9.-]*\.[a-z]{2,}/gi);
    if (!domainMatches) continue;

    for (const domain of domainMatches) {
      const parts = domain.toLowerCase().split('.');

      if (parts.length >= 3) {
        if (!index.exact[domain]) index.exact[domain] = [];
        if (!index.exact[domain].includes(id)) index.exact[domain].push(id);

        const suffix = parts.slice(-2).join('.');
        if (!index.suffix[suffix]) index.suffix[suffix] = [];
        if (!index.suffix[suffix].includes(id)) index.suffix[suffix].push(id);
      } else {
        if (!index.suffix[domain]) index.suffix[domain] = [];
        if (!index.suffix[domain].includes(id)) index.suffix[domain].push(id);
      }

      const keywords = parts.filter(p => 
        p.length >= 4 &&
        !['api', 'www', 'm', 'mobile', 'app', 'v1', 'v2', 'v3', 'service', 'com', 'cn', 'net', 'org'].includes(p)
      );

      for (const kw of keywords) {
        if (!index.keyword[kw] && kw.length >= 4) {
          index.keyword[kw] = [id];
        } else if (index.keyword[kw] && !index.keyword[kw].includes(id)) {
          index.keyword[kw].push(id);
        }
      }
    }
  }

  return index;
}

// ==========================================
// 应急添加函数
// ==========================================
function addEmergencyApp(id, urlPattern, defaultConfig = {}) {
  if (!id || !urlPattern) {
    console.error('❌ addEmergencyApp: 需要提供 id 和 urlPattern');
    return false;
  }

  INLINE_REGISTRY[id] = { urlPattern };
  
  if (Object.keys(defaultConfig).length > 0) {
    const configPath = path.join(CONFIGS_DIR, `${id}.json`);
    const fullConfig = {
      name: id,
      description: `${id} VIP解锁（应急添加）`,
      mode: 'json',
      priority: 10,
      urlPattern: urlPattern,
      ...defaultConfig
    };
    
    try {
      fs.writeFileSync(configPath, JSON.stringify(fullConfig, null, 2));
      console.log(`✅ 已创建应急配置文件: configs/${id}.json`);
    } catch (e) {
      console.error(`❌ 创建配置文件失败: ${e.message}`);
    }
  }

  console.log(`✅ 已添加应急 APP: ${id}`);
  return true;
}

// CommonJS导出
module.exports = {
  APP_REGISTRY,
  INLINE_REGISTRY,
  getAllConfigs,
  generateManifest,
  generateRewriteComments,
  generatePrefixIndex,
  scanConfigs: () => scanResult, // 返回带诊断信息的结果
  addEmergencyApp
};
