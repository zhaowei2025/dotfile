# 🔄 Dotfiles 备份指南

## 📖 概述

`backup-dotfiles.sh` 是一个智能备份脚本，用于在执行 `chezmoi init --apply` 之前安全备份现有的配置文件，避免重要配置丢失。

## 🚀 快速使用

### 1. 下载并执行备份脚本
```bash
# 下载脚本（如果还没有）
curl -O https://raw.githubusercontent.com/zhaowei2025/dotfile/main/backup-dotfiles.sh

# 添加执行权限
chmod +x backup-dotfiles.sh

# 执行备份
./backup-dotfiles.sh
```

### 2. 备份完成后部署 dotfiles
```bash
chezmoi init --apply https://github.com/zhaowei2025/dotfile.git
```

## 📋 备份内容

脚本会自动检测并备份以下文件/目录：

### 🔧 核心配置文件
- `~/.zshrc` - Zsh 配置
- `~/.gitconfig` - Git 全局配置  
- `~/.env` - 环境变量

### 📁 配置目录
- `~/.config/nvim/` - Neovim 配置
- `~/.config/bin-tools/` - 工具配置

### 🛠️ 二进制工具
- `~/.local/bin/` - 本地可执行文件
- `~/.local/share/applications/` - 应用程序快捷方式

### 📜 其他常见配置
- `~/.bashrc`, `~/.bash_profile`, `~/.profile`
- `~/.vimrc`, `~/.tmux.conf`, `~/.screenrc`
- `~/.gitignore_global`, `~/.gitmessage`
- `~/.ssh/config`
- `~/.zsh_history`, `~/.bash_history`

## 📂 备份结构

备份会保存在 `~/dotfiles-backup/YYYYMMDD-HHMMSS/` 目录中：

```
~/dotfiles-backup/20241129-143022/
├── backup-info.txt           # 备份信息
├── manifest.txt              # 详细清单
├── restore-commands.sh       # 恢复脚本
├── .zshrc                    # 备份的配置文件
├── .gitconfig
├── .config/
│   └── nvim/
└── .local/
    └── bin/
```

## 🔄 恢复方法

### 方式 1：使用自动生成的恢复脚本
```bash
# 查看恢复命令
cat ~/dotfiles-backup/20241129-143022/restore-commands.sh

# 选择性执行恢复命令
cp "~/dotfiles-backup/20241129-143022/.zshrc" "~/.zshrc"
```

### 方式 2：手动恢复
```bash
# 恢复特定文件
cp ~/dotfiles-backup/20241129-143022/.zshrc ~/.zshrc

# 恢复整个目录
cp -r ~/dotfiles-backup/20241129-143022/.config/nvim ~/.config/
```

## 🎯 使用场景

### 场景 1：新机器初始化
```bash
# 1. 先备份（可能存在默认配置）
./backup-dotfiles.sh

# 2. 部署 dotfiles
chezmoi init --apply https://github.com/zhaowei2025/dotfile.git
```

### 场景 2：更新现有配置
```bash
# 1. 备份当前配置
./backup-dotfiles.sh

# 2. 更新 dotfiles
chezmoi update

# 3. 如需回退，使用备份恢复
```

### 场景 3：测试新配置
```bash
# 1. 备份
./backup-dotfiles.sh

# 2. 部署新配置
chezmoi init --apply https://github.com/zhaowei2025/dotfile.git

# 3. 如果不满意，恢复原配置
~/dotfiles-backup/20241129-143022/restore-commands.sh
```

## ⚠️ 注意事项

### 备份不包含的内容
- **敏感文件**：`~/.ssh/id_*` 私钥文件
- **缓存文件**：临时和缓存数据
- **大型文件**：数据库、日志文件

### 安全建议
- 备份中可能包含敏感信息，注意保护
- 定期清理旧备份：`rm -rf ~/dotfiles-backup/old-backups`
- SSH 配置仅备份 `config` 文件，不备份私钥

## 🔧 自定义配置

### 修改备份目标
编辑脚本中的 `BACKUP_TARGETS` 数组：

```bash
BACKUP_TARGETS=(
    "$HOME/.zshrc"
    "$HOME/.my-custom-config"
    # 添加更多文件...
)
```

### 修改备份位置
```bash
BACKUP_ROOT="$HOME/my-custom-backup-dir"
```

## 🆘 故障排除

### 权限问题
```bash
chmod +x backup-dotfiles.sh
```

### 空间不足
```bash
# 检查可用空间
df -h ~

# 清理旧备份
find ~/dotfiles-backup -type d -mtime +30 -exec rm -rf {} \;
```

### 备份失败
- 检查文件权限
- 确保目标目录存在
- 查看详细错误信息

## 💡 最佳实践

1. **备份前检查**：运行脚本先查看会备份什么
2. **记录时间戳**：备份目录包含时间戳，便于管理
3. **定期清理**：避免备份占用过多空间
4. **测试恢复**：偶尔测试恢复流程确保备份有效

---

**🔗 相关链接**
- [Dotfiles 仓库](https://github.com/zhaowei2025/dotfile)
- [Chezmoi 官方文档](https://www.chezmoi.io/) 