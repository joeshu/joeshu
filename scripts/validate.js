#!/usr/bin/env node

const Ajv = require('ajv');
const { APP_REGISTRY, getAllConfigs } = require('../src/apps/_index');

const VALID_MODES = new Set(['json', 'regex', 'forward', 'remote', 'game', 'hybrid', 'html']);
const ajv = new Ajv({ allErrors: true, allowUnionTypes: true });

function isValidRegex(pattern) {
  try {
    new RegExp(pattern);
    return true;
  } catch (e) {
    return false;
  }
}

const baseSchema = {
  type: 'object',
  required: ['name', 'mode', 'urlPattern'],
  properties: {
    name: { type: 'string', minLength: 1 },
    mode: { type: 'string', enum: [...VALID_MODES] },
    urlPattern: { type: 'string', minLength: 1 },
    processor: {},
    regexReplacements: { type: 'array' },
    forwardUrl: { type: 'string', minLength: 1 },
    remoteUrl: { type: 'string', minLength: 1 },
    gameResources: { type: 'array' },
    htmlReplacements: { type: 'array' }
  },
  additionalProperties: true
};

const modeRules = {
  json: cfg => !!cfg.processor,
  regex: cfg => Array.isArray(cfg.regexReplacements) && cfg.regexReplacements.length > 0,
  forward: cfg => !!cfg.forwardUrl,
  remote: cfg => !!cfg.remoteUrl,
  game: cfg => Array.isArray(cfg.gameResources) && cfg.gameResources.length > 0,
  html: cfg => Array.isArray(cfg.htmlReplacements) && cfg.htmlReplacements.length > 0,
  hybrid: cfg => !!cfg.processor || (Array.isArray(cfg.regexReplacements) && cfg.regexReplacements.length > 0)
};

function validateRegistry(errors) {
  for (const [id, cfg] of Object.entries(APP_REGISTRY)) {
    if (!cfg || typeof cfg !== 'object') {
      errors.push(`${id}: APP_REGISTRY 项不是对象`);
      continue;
    }

    if (!cfg.urlPattern || typeof cfg.urlPattern !== 'string') {
      errors.push(`${id}: 缺少 urlPattern`);
      continue;
    }

    if (!isValidRegex(cfg.urlPattern)) {
      errors.push(`${id}: urlPattern 正则错误`);
    }
  }
}

function validateConfigByMode(id, cfg, errors) {
  if (!cfg.mode) {
    errors.push(`${id}: 缺少 mode`);
    return;
  }

  if (!VALID_MODES.has(cfg.mode)) {
    errors.push(`${id}: 无效 mode "${cfg.mode}"`);
    return;
  }

  if (!modeRules[cfg.mode](cfg)) {
    const hints = {
      json: 'json模式缺少 processor',
      regex: 'regex模式缺少 regexReplacements',
      forward: 'forward模式缺少 forwardUrl',
      remote: 'remote模式缺少 remoteUrl',
      game: 'game模式缺少 gameResources',
      html: 'html模式缺少 htmlReplacements',
      hybrid: 'hybrid模式至少需要 processor 或 regexReplacements'
    };
    errors.push(`${id}: ${hints[cfg.mode] || 'mode字段不完整'}`);
  }
}

function validateConfigs(errors) {
  const allConfigs = getAllConfigs();
  const validateSchema = ajv.compile(baseSchema);

  for (const [id, cfg] of Object.entries(allConfigs)) {
    if (!cfg || typeof cfg !== 'object') {
      errors.push(`${id}: 配置不是对象`);
      continue;
    }

    if (!validateSchema(cfg)) {
      const schemaErrors = (validateSchema.errors || [])
        .slice(0, 5)
        .map(e => `${e.instancePath || '/'} ${e.message}`)
        .join('; ');
      errors.push(`${id}: Schema校验失败 -> ${schemaErrors}`);
    }

    if (!cfg.urlPattern || typeof cfg.urlPattern !== 'string') {
      errors.push(`${id}: 缺少 urlPattern`);
      continue;
    }

    if (!isValidRegex(cfg.urlPattern)) {
      errors.push(`${id}: urlPattern 正则错误`);
      continue;
    }

    validateConfigByMode(id, cfg, errors);
  }

  return allConfigs;
}

function validate() {
  console.log('🔍 验证配置...\n');

  const errors = [];

  // 1) 检查 APP_REGISTRY（只校验其职责字段：urlPattern）
  validateRegistry(errors);

  // 2) 检查完整配置（由 getAllConfigs 生成）
  const allConfigs = validateConfigs(errors);

  // 3) 检查重复 ID
  const ids = Object.keys(APP_REGISTRY);
  const uniqueIds = [...new Set(ids)];
  if (ids.length !== uniqueIds.length) {
    errors.push('APP_REGISTRY 中有重复的ID');
  }

  // 输出结果
  if (errors.length === 0) {
    console.log('✅ 验证通过！');
    console.log(`   APP数量: ${ids.length}`);
    console.log('   模式分布:');

    const modeCount = {};
    Object.values(allConfigs).forEach(c => {
      modeCount[c.mode] = (modeCount[c.mode] || 0) + 1;
    });

    Object.entries(modeCount).forEach(([m, c]) => {
      console.log(`     ${m}: ${c}`);
    });

    return 0;
  }

  console.log(`❌ 发现 ${errors.length} 个错误:\n`);
  errors.forEach(e => console.log(`   - ${e}`));
  return 1;
}

process.exit(validate());
