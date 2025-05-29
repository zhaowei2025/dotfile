# 🔐 Token 管理方案对比

本文档对比了不同的 token 管理方案，帮助你选择最适合的方式。

## 📋 方案概览

| 方案 | 安全性 | 便利性 | 技术复杂度 | 适用场景 |
|------|--------|--------|------------|----------|
| **环境变量** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐ | 个人开发、简单环境 |
| **自定义加密** | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | 多机器同步 |
| **Chezmoi原生AGE** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ | 专业用户、团队协作 |

## 🔄 方案详细对比

### 1. 环境变量方案（基础）

#### 工具脚本
- `setup-tokens.sh` - 交互式设置
- `token-manager.sh` - 综合管理

#### 优点
- ✅ 简单易懂，学习成本低
- ✅ 设置快速，即时生效
- ✅ 兼容性好，支持所有shell
- ✅ 无需额外依赖

#### 缺点
- ❌ 无法版本控制敏感信息
- ❌ 跨机器同步需要手动操作
- ❌ 无法在Git仓库中备份配置

#### 适用场景
```bash
# 适合：
- 个人开发环境
- 单机使用
- 快速原型开发
- 临时环境配置
```

#### 使用方式
```bash
# 快速设置
~/.local/share/chezmoi/scripts/setup-tokens.sh

# 管理tokens
~/.local/share/chezmoi/scripts/token-manager.sh
```

---

### 2. 自定义加密方案（中级）

#### 工具脚本
- `sync-tokens-encrypted.sh` - OpenSSL加密同步

#### 优点
- ✅ 支持加密存储
- ✅ 可以通过云盘同步
- ✅ 使用标准的OpenSSL工具
- ✅ 密码保护，相对安全

#### 缺点
- ❌ 需要管理密码
- ❌ 不能与Git仓库集成
- ❌ 手动同步流程
- ❌ 密码遗忘会丢失所有数据

#### 适用场景
```bash
# 适合：
- 多台机器开发
- 需要备份的环境
- 对安全有一定要求
- 不想学习复杂工具
```

#### 使用方式
```bash
# 加密tokens
~/.local/share/chezmoi/scripts/sync-tokens-encrypted.sh encrypt

# 同步到新机器后解密
~/.local/share/chezmoi/scripts/sync-tokens-encrypted.sh decrypt
```

---

### 3. Chezmoi原生AGE加密（高级）⭐推荐

#### 工具脚本
- `chezmoi-token-manager.sh` - AGE加密管理

#### 优点
- ✅ 军用级AGE加密算法
- ✅ 与chezmoi完美集成
- ✅ 可以安全提交到Git仓库
- ✅ 支持版本控制和分支
- ✅ 密钥对管理，更安全
- ✅ 跨平台标准化解决方案

#### 缺点
- ❌ 学习成本相对较高
- ❌ 需要管理AGE密钥对
- ❌ 密钥丢失无法恢复

#### 适用场景
```bash
# 适合：
- 专业开发环境
- 团队协作项目
- 需要版本控制的配置
- 高安全要求的场景
- 长期维护的项目
```

#### 使用方式
```bash
# 运行原生加密管理器
~/.local/share/chezmoi/scripts/chezmoi-token-manager.sh

# 工作流程：
# 1. 设置AGE加密
# 2. 创建加密tokens
# 3. 提交到Git（安全！）
# 4. 新机器：克隆仓库→导入密钥→应用配置
```

## 🚀 推荐使用流程

### 新手入门
```bash
# 第一次使用，快速上手
~/.local/share/chezmoi/scripts/setup-tokens.sh
```

### 进阶用户
```bash
# 多机器环境，需要同步
~/.local/share/chezmoi/scripts/token-manager.sh  # 选择加密功能
```

### 专业用户
```bash
# 完整的DevOps工作流
~/.local/share/chezmoi/scripts/chezmoi-token-manager.sh
```

## 🔄 迁移指南

### 从环境变量迁移到AGE加密

1. **备份现有tokens**
   ```bash
   cp ~/.env.tokens ~/.env.tokens.backup
   ```

2. **设置AGE加密**
   ```bash
   ~/.local/share/chezmoi/scripts/chezmoi-token-manager.sh
   # 选择选项1: 设置AGE加密
   ```

3. **导入现有tokens**
   ```bash
   # 选择选项2: 创建加密tokens
   # 手动输入现有的token值
   ```

4. **提交到Git仓库**
   ```bash
   cd ~/.local/share/chezmoi
   git add encrypted_private_dot_env.private.asc
   git commit -m "feat: 添加AGE加密的tokens"
   git push
   ```

### 新机器快速部署（AGE加密）

1. **克隆配置**
   ```bash
   chezmoi init https://github.com/zhaowei2025/dotfile.git
   ```

2. **复制AGE密钥**
   ```bash
   # 从安全地方复制密钥文件
   cp /path/to/backup/key.txt ~/.config/chezmoi/key.txt
   chmod 600 ~/.config/chezmoi/key.txt
   ```

3. **应用配置**
   ```bash
   ~/.local/share/chezmoi/scripts/chezmoi-token-manager.sh
   # 选择选项4: 应用tokens到环境
   ```

## 🔒 安全最佳实践

### AGE密钥管理
```bash
# 1. 备份AGE私钥到安全地方
cp ~/.config/chezmoi/key.txt /secure/backup/location/

# 2. 设置正确权限
chmod 600 ~/.config/chezmoi/key.txt

# 3. 定期轮换密钥（高级）
age-keygen -o ~/.config/chezmoi/key_new.txt
# 更新配置，重新加密所有文件
```

### Token轮换
```bash
# 定期更新API tokens
~/.local/share/chezmoi/scripts/chezmoi-token-manager.sh
# 选择选项3: 编辑加密tokens
```

### 权限控制
```bash
# 确保文件权限正确
find ~/.config/chezmoi -type f -exec chmod 600 {} \;
find ~/.env* -type f -exec chmod 600 {} \; 2>/dev/null || true
```

## 🆘 故障排除

### AGE解密失败
```bash
# 检查密钥文件
ls -la ~/.config/chezmoi/key.txt

# 检查chezmoi配置
cat ~/.config/chezmoi/chezmoi.toml

# 重新设置AGE
~/.local/share/chezmoi/scripts/chezmoi-token-manager.sh  # 选项1
```

### 环境变量不生效
```bash
# 检查文件是否存在
ls -la ~/.env.private

# 检查是否在shell配置中加载
grep -n "env.private" ~/.zshrc

# 手动加载测试
source ~/.env.private && echo $GITHUB_TOKEN | cut -c1-8
```

### Git推送失败
```bash
# 检查token是否有效
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user

# 重新设置token
~/.local/share/chezmoi/scripts/setup-tokens.sh
```

## 📊 性能对比

| 操作 | 环境变量 | 自定义加密 | AGE加密 |
|------|----------|------------|---------|
| 首次设置 | 30秒 | 1分钟 | 2分钟 |
| 日常使用 | 即时 | 即时 | 即时 |
| 跨机器同步 | 5分钟 | 2分钟 | 1分钟 |
| 安全性评分 | 6/10 | 8/10 | 10/10 |

## 🎯 选择建议

| 如果你是... | 推荐方案 | 理由 |
|-------------|----------|------|
| **新手开发者** | 环境变量 | 简单快速，容易理解 |
| **有经验开发者** | AGE加密 | 平衡了安全性和便利性 |
| **DevOps工程师** | AGE加密 | 符合专业标准，支持团队协作 |
| **安全敏感项目** | AGE加密 | 军用级加密，可审计 |
| **临时项目** | 环境变量 | 快速搭建，无需复杂配置 |

---

**💡 建议：** 对于长期项目，强烈推荐使用 Chezmoi 原生 AGE 加密方案，它是最安全且最标准化的解决方案。 