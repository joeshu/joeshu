#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

const question = (q) => new Promise(resolve => rl.question(q, resolve));

async function main() {
  console.log('🚀 UnifiedVIP APP 新增向导\n');
  
  const appId = await question('APP ID (小写英文，如newapp): ');
  const name = await question('显示名称 (如"新应用"): ');
  const domain = await question('主域名 (如api.newapp.com): ');
  const apiPath = await question('API路径 (如/vip/info，可选): ') || '/.*';
  
  console.log('\n📋 处理模式:');
  console.log('  1. json    - JSON字段修改（最常用）');
  console.log('  2. regex   - 正则替换文本');
  console.log('  3. forward - 转发到其他服务器');
  console.log('  4. remote  - 替换为远程JSON');
  console.log('  5. game    - 游戏资源修改');
  console.log('  6. hybrid  - JSON+正则混合');
  console.log('  7. html    - HTML页面修改');
  
  const modeNum = await question('模式编号 (1-7, 默认1): ') || '1';
  const modes = ['json', 'regex', 'forward', 'remote', 'game', 'hybrid', 'html'];
  const mode = modes[parseInt(modeNum) - 1] || 'json';
  
  const priority = await question('优先级 (数字越小越优先, 默认10): ') || '10';
  const description = await question('描述 (可选): ') || `${name}VIP解锁`;

  // 生成配置
  const config = generateConfig(mode, name, domain, apiPath, parseInt(priority), description);
  
  // 更新注册表
  await updateRegistry(appId, config);
  
  console.log(`\n✅ APP "${name}" 创建成功！`);
  console.log(`\n📁 已更新: src/apps/_index.js`);
  console.log(`\n📝 下一步：`);
  console.log('   npm run build    # 构建并生成配置文件');
  console.log('   npm run deploy   # 发布到GitHub Pages');
  
  rl.close();
}

function generateConfig(mode, name, domain, apiPath, priority, description) {
  const base = {
    name,
    urlPattern: `^https?:\\\\/\\\\/${domain.replace(/\./g, '\\\\.')}${apiPath.replace(/\//g, '\\\\/')}`,
    mode,
    priority,
    description,
    config: {}
  };

  switch (mode) {
    case 'json':
      base.config.processor = {
        processor: "setFields",
        params: {
          fields: {
            "data.isVip": true,
            "data.vipExpireTime": "2099-12-31"
          }
        }
      };
      break;
      
    case 'regex':
      base.config.regexReplacements = [
        { pattern: '\\"isVip\\":false', replacement: '\\"isVip\\":true', flags: 'g' },
        { pattern: '\\"vipExpire\\":\\"[^\\"]*\\"', replacement: '\\"vipExpire\\":\\"2099-12-31\\"', flags: 'g' }
      ];
      break;
      
    case 'forward':
      base.config.forwardUrl = `https://your-worker.dev/forward${apiPath}`;
      base.config.method = 'POST';
      base.config.timeout = 10000;
      base.config.forwardHeaders = { "Content-Type": "application/json; charset=utf-8" };
      base.config.statusTexts = { "200": "OK", "500": "Internal Server Error" };
      break;
      
    case 'remote':
      base.config.remoteUrl = `https://your-cdn.com/mock/${name.toLowerCase()}.json`;
      base.config.validateJson = true;
      break;
      
    case 'game':
      base.config.gameResources = [
        { field: "coin", value: 9999999 },
        { field: "gem", value: 9999999 }
      ];
      break;
      
    case 'hybrid':
      base.config.processor = {
        processor: "setFields",
        params: { fields: { "data.isVip": true } }
      };
      base.config.regexReplacements = [
        { pattern: '"ads":\\[.*?\\]', replacement: '"ads":[]', flags: 'g' }
      ];
      break;
      
    case 'html':
      base.config.htmlReplacements = [
        { pattern: "<div[^>]*class=\\"[^\\"]*ad[^\\"]*\\"[^>]*>[\\s\\S]*?<\\/div>", replacement: "", flags: "gi" }
      ];
      break;
  }
  
  return base;
}

async function updateRegistry(appId, config) {
  const registryPath = path.join(__dirname, '../src/apps/_index.js');
  let content = fs.readFileSync(registryPath, 'utf8');
  
  // 找到最后一个APP的结束位置
  const lastAppMatch = content.match(/(\s+\/\/ =+ \d+\. \S+ =+\s+\w+: \{[\s\S]+?\n  \},)/g);
  if (!lastAppMatch) {
    console.error('❌ 无法找到插入位置');
    return;
  }
  
  const lastApp = lastAppMatch[lastAppMatch.length - 1];
  const lastIndex = content.lastIndexOf(lastApp) + lastApp.length;
  
  // 格式化新配置
  const configStr = formatConfigEntry(appId, config);
  
  // 插入新配置
  content = content.slice(0, lastIndex) + '\n' + configStr + content.slice(lastIndex);
  
  fs.writeFileSync(registryPath, content);
}

function formatConfigEntry(appId, config) {
  const nextNum = (Object.keys(require('../src/apps/_index').APP_REGISTRY).length + 1);
  
  let configObjStr = JSON.stringify(config.config, null, 2).replace(/^/gm, '    ');
  
  return `
  // ==================== ${nextNum}. ${config.name} ====================
  ${appId}: {
    name: "${config.name}",
    urlPattern: "${config.urlPattern}",
    mode: "${config.mode}",
    priority: ${config.priority},
    description: "${config.description}",
    config: ${configObjStr}
  },`;
}

main().catch(console.error);
