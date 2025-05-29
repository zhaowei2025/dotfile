# 🚀 Dotfiles 部署工作流程

## 📖 完整部署指南

这是一个安全部署 dotfiles 到新机器或现有环境的完整工作流程。

## 🎯 部署场景

### 场景 A：全新机器部署
```bash
# 1. 克隆仓库获取备份脚本
git clone https://github.com/zhaowei2025/dotfile.git
cd dotfile

# 2. 执行备份（保险起见）
./backup-dotfiles.sh

# 3. 部署 dotfiles
chezmoi init --apply https://github.com/zhaowei2025/dotfile.git

# 4. 重新加载配置
source ~/.zshrc
```

### 场景 B：现有环境更新
```bash
# 1. 下载备份脚本
curl -O https://raw.githubusercontent.com/zhaowei2025/dotfile/main/backup-dotfiles.sh
chmod +x backup-dotfiles.sh

# 2. 备份现有配置
./backup-dotfiles.sh

# 3. 部署新配置
chezmoi init --apply https://github.com/zhaowei2025/dotfile.git

# 4. 验证和调整
source ~/.zshrc
```

## 📋 详细步骤说明

### 步骤 1：环境准备
```bash
# 检查系统信息
uname -a
echo $SHELL

# 确保基础工具存在
which git curl zsh

# 检查磁盘空间
df -h ~
```

### 步骤 2：备份现有配置
```bash
# 执行备份脚本
./backup-dotfiles.sh

# 示例输出：
# ================================================
# 🔄 Dotfiles 备份脚本
# ================================================
# ℹ️  检查需要备份的文件...
# ℹ️  发现文件: /home/user/.zshrc
# ℹ️  发现文件: /home/user/.gitconfig
# ...
# ⚠️  发现 10 个需要备份的项目
# 
# 是否继续创建备份？(y/N): y
```

### 步骤 3：部署 Dotfiles
```bash
# 执行一键部署
chezmoi init --apply https://github.com/zhaowei2025/dotfile.git

# 部署过程会：
# 1. 克隆仓库到 ~/.local/share/chezmoi
# 2. 处理模板文件
# 3. 复制文件到目标位置
# 4. 执行 run_once 和 run_onchange 脚本
```

### 步骤 4：验证部署结果
```bash
# 重新加载 shell 配置
source ~/.zshrc

# 验证工具是否正常
fd --version
rg --version
nvim --version
clangd --version

# 测试 alias 和函数
ll
dfstatus
ptest

# 检查环境变量
echo $COLORTERM
echo $EDITOR
```

## 🔍 部署过程详解

### 文件映射关系
| Chezmoi 源文件 | 目标位置 | 权限 |
|---------------|----------|------|
| `dot_zshrc` | `~/.zshrc` | 644 |
| `dot_gitconfig` | `~/.gitconfig` | 644 |
| `private_dot_env.private` | `~/.env` | 600 |
| `dot_config/nvim/` | `~/.config/nvim/` | 755/644 |
| `dot_config/bin-tools/` | `~/.config/bin-tools/` | 755/644 |
| `dot_local/bin/` | `~/.local/bin/` | 755/755 |

### 脚本执行顺序
1. **install-bin-tools.sh**
   - 检测系统架构和 glibc 版本
   - 下载并安装二进制工具 (fd, rg, nvim, clangd)
   - 创建符号链接和设置权限

2. **update-bin-tools.sh**
   - 当 `versions.toml` 变化时触发
   - 更新现有工具到新版本
   - 备份旧版本并清理

## ⚠️ 可能遇到的问题

### 问题 1：权限错误
```bash
# 症状
permission denied: /home/user/.local/bin/fd

# 解决
chmod +x ~/.local/bin/*
```

### 问题 2：工具下载失败
```bash
# 症状
curl: (28) Connection timed out

# 解决方案
# 1. 检查网络连接
ping github.com

# 2. 使用代理
export https_proxy=http://proxy.example.com:8080
chezmoi apply

# 3. 手动下载
cd ~/.local/bin
wget https://github.com/sharkdp/fd/releases/download/v10.2.0/fd-v10.2.0-x86_64-unknown-linux-gnu.tar.gz
```

### 问题 3：nvim 配置冲突
```bash
# 症状
nvim 启动报错或插件无法加载

# 解决
# 1. 检查配置语法
nvim --headless -c 'checkhealth' -c 'quit'

# 2. 重新安装插件
nvim +PackerSync +qall

# 3. 恢复备份配置
cp -r ~/dotfiles-backup/20241129-143022/.config/nvim ~/.config/
```

### 问题 4：shell 配置问题
```bash
# 症状
zsh 提示符异常或 alias 不生效

# 解决
# 1. 重新加载配置
source ~/.zshrc

# 2. 检查配置文件
cat ~/.zshrc | grep -E "(error|Error)"

# 3. 恢复备份
cp ~/dotfiles-backup/20241129-143022/.zshrc ~/.zshrc
```

## 🧪 测试和验证

### 功能测试清单
```bash
# 1. Shell 功能
✅ zsh 启动正常
✅ 提示符显示正确
✅ alias 生效 (ll, la, l, etc.)
✅ 代理管理 (pon, poff, pst, ptest)
✅ Git 账户切换 (gwitch, gpitch)
✅ Dotfiles 管理 (dfpush, dfpull, dfstatus)

# 2. 工具功能
✅ fd 搜索文件
✅ rg 搜索文本
✅ nvim 编辑器启动和插件
✅ clangd LSP 服务器

# 3. 环境变量
✅ COLORTERM=truecolor
✅ EDITOR=nvim
✅ API keys 正确设置
```

### 性能测试
```bash
# 测试 shell 启动时间
time zsh -c "exit"

# 测试工具响应时间
time fd . --max-depth 1
time rg "function" ~/.zshrc
```

## 🔄 回滚流程

如果部署出现问题，可以快速回滚：

```bash
# 1. 查看可用备份
ls ~/dotfiles-backup/

# 2. 使用最新备份恢复
BACKUP_DIR=$(ls -t ~/dotfiles-backup/ | head -1)
echo "恢复备份: $BACKUP_DIR"

# 3. 恢复关键配置
cp ~/dotfiles-backup/$BACKUP_DIR/.zshrc ~/.zshrc
cp ~/dotfiles-backup/$BACKUP_DIR/.gitconfig ~/.gitconfig
cp -r ~/dotfiles-backup/$BACKUP_DIR/.config/nvim ~/.config/

# 4. 重新加载
source ~/.zshrc
```

## 📚 后续维护

### 定期维护任务
```bash
# 1. 更新 dotfiles
chezmoi update

# 2. 更新工具版本
# 编辑 ~/.config/bin-tools/versions.toml
# 然后运行 chezmoi apply

# 3. 清理旧备份
find ~/dotfiles-backup -type d -mtime +90 -exec rm -rf {} \;

# 4. 同步到仓库
dfpush  # 推送本地修改到 GitHub
```

### 添加新配置
```bash
# 1. 添加到 chezmoi 管理
chezmoi add ~/.new-config

# 2. 编辑模板
chezmoi edit ~/.new-config

# 3. 应用更改
chezmoi apply

# 4. 提交到仓库
cd ~/.local/share/chezmoi
git add . && git commit -m "Add new config" && git push
```

---

**🎉 恭喜！你的开发环境已经成功部署！**

现在你拥有了一个完全同步、可复现的开发环境，可以在任何机器上快速部署。 