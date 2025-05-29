# 🔒 安全配置指南

本文档说明如何安全地管理和部署敏感信息（API密钥、token等）。

## 🛡️ 安全原则

1. **永不提交明文密钥** - 敏感信息绝不以明文形式提交到Git仓库
2. **使用环境变量** - 通过环境变量传递敏感信息
3. **模板化配置** - 使用chezmoi模板功能动态生成配置
4. **最小权限原则** - 确保文件权限正确设置

## 📋 敏感信息清单

### API 密钥
- `ALI_DEEPSEEK_API_KEY` - 阿里深度求索API密钥
- `DEEPSEEK_API_KEY` - DeepSeek API密钥
- `ZHIHE_API_KEY` - 智和API密钥

### 认证令牌
- `GITHUB_TOKEN` - GitHub Personal Access Token

## 🚀 新机器部署步骤

### 1. 克隆配置
```bash
# 使用公开仓库克隆（不包含敏感信息）
chezmoi init https://github.com/zhaowei2025/dotfile.git
```

### 2. 设置环境变量
```bash
# 设置API密钥
export ALI_DEEPSEEK_API_KEY="your_ali_deepseek_api_key"
export DEEPSEEK_API_KEY="your_deepseek_api_key"  
export ZHIHE_API_KEY="your_zhihe_api_key"

# 设置GitHub token
export GITHUB_TOKEN="your_github_token"
```

### 3. 应用配置
```bash
# 应用配置（环境变量会自动填入模板）
chezmoi apply
```

### 4. 验证配置
```bash
# 检查生成的环境变量文件
cat ~/.env.private

# 验证权限（应该是600）
ls -la ~/.env.private
```

## 🔄 持久化环境变量

### 方法1：添加到shell配置（推荐）
```bash
# 编辑你的shell配置文件
echo 'export GITHUB_TOKEN="your_token"' >> ~/.bashrc
echo 'export DEEPSEEK_API_KEY="your_key"' >> ~/.bashrc
# ... 其他变量

# 重新加载配置
source ~/.bashrc
```

### 方法2：使用系统环境文件
```bash
# 创建系统级环境文件
sudo tee /etc/environment << EOF
GITHUB_TOKEN="your_token"
DEEPSEEK_API_KEY="your_key"
EOF
```

### 方法3：使用专用配置文件
```bash
# 创建本地环境文件
cat > ~/.local.env << 'EOF'
export GITHUB_TOKEN="your_token"
export DEEPSEEK_API_KEY="your_key"
export ALI_DEEPSEEK_API_KEY="your_key"
export ZHIHE_API_KEY="your_key"
EOF

# 在shell配置中加载
echo 'source ~/.local.env' >> ~/.zshrc
```

## 🔐 安全最佳实践

### 文件权限
```bash
# 确保私有文件权限正确
chmod 600 ~/.env.private
chmod 600 ~/.local.env
```

### 备份安全
```bash
# 备份时排除敏感文件
tar --exclude='*.private' --exclude='.env*' -czf backup.tar.gz ~/dotfiles
```

### Git配置
```bash
# 确保git忽略敏感文件
echo '.env.private' >> ~/.gitignore
echo '.local.env' >> ~/.gitignore
```

## ⚠️ 安全注意事项

1. **定期轮换密钥** - 建议定期更新API密钥和token
2. **监控使用情况** - 关注API调用日志，及时发现异常
3. **限制权限范围** - 为token设置最小必要权限
4. **安全传输** - 通过加密渠道传输敏感信息

## 🆘 安全事件处理

### 如果密钥泄露
1. **立即撤销** - 在相应平台撤销泄露的密钥/token
2. **生成新密钥** - 生成新的API密钥或token
3. **更新配置** - 更新所有使用该密钥的环境
4. **检查日志** - 查看是否有异常使用记录

### 如果配置文件泄露
1. **检查内容** - 确认泄露的敏感信息范围
2. **撤销相关密钥** - 撤销所有可能泄露的密钥
3. **清理历史** - 使用git filter-branch清理git历史
4. **重新部署** - 使用新密钥重新部署环境

## 📚 相关资源

- [GitHub Personal Access Tokens](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token)
- [chezmoi Security](https://www.chezmoi.io/user-guide/password-managers/)
- [Git Secrets](https://github.com/awslabs/git-secrets) 