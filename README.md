# 🏠 Dotfiles - Personal Development Environment

[![chezmoi](https://img.shields.io/badge/managed%20by-chezmoi-blue.svg)](https://www.chezmoi.io/)
[![Shell](https://img.shields.io/badge/shell-zsh-green.svg)](https://www.zsh.org/)
[![Editor](https://img.shields.io/badge/editor-neovim-brightgreen.svg)](https://neovim.io/)

一个现代化的、基于 [chezmoi](https://www.chezmoi.io/) 管理的个人开发环境配置，支持跨平台同步和自动化部署。

## ✨ 主要功能

### 🔧 配置管理
- **Shell 环境**: 优化的 zsh 配置，包含智能提示和快捷命令
- **Git 配置**: 多用户快速切换（工作/个人账户）
- **编辑器**: Neovim 配置（基于 kickstart.nvim）
- **二进制工具**: 自动化管理开发工具（fd, ripgrep, clangd 等）

### 🌐 网络工具
- **代理管理**: 一键开启/关闭代理，支持 HTTP/HTTPS/Git 代理
- **连接测试**: 自动检测代理状态和连接质量
- **智能配置**: 自动排除本地和内网地址

### 🛠️ 开发工具
- **自动安装**: 一键安装常用开发工具
- **版本管理**: 统一的版本配置和更新机制
- **备份恢复**: 自动备份和快速恢复功能
- **跨平台**: 支持 x86_64 和 aarch64 架构

### 📦 工具集成
- **fd**: 现代化的 find 替代品
- **ripgrep**: 高性能文本搜索工具
- **neovim**: 现代化编辑器配置
- **clangd**: C/C++ 语言服务器

## 📁 项目结构

```
~/.local/share/chezmoi/
├── 📄 README.md                                    # 项目说明文档
├── 🔧 dot_gitconfig                               # Git 全局配置
├── 🐚 dot_zshrc                                   # Zsh Shell 配置
├── 🚀 run_once_install-bin-tools.sh.tmpl         # 二进制工具安装脚本
├── 🔄 run_onchange_update-bin-tools.sh.tmpl      # 工具更新脚本
│
├── 📁 dot_local/bin/
│   └── 🛠️ executable_manage-tools                # 工具管理脚本
│
└── 📁 private_dot_config/
    ├── 📁 bin-tools/
    │   ├── 📖 README.md                           # 工具管理文档
    │   └── ⚙️ versions.toml                       # 版本配置文件
    │
    └── 📁 nvim/                                   # Neovim 配置
        ├── 📄 init.lua                            # 主配置文件
        ├── 📁 lua/kickstart/                      # Kickstart 插件
        └── 📁 lua/custom/                         # 自定义配置
```

## 🚀 快速开始

### 系统要求

- **操作系统**: Linux (Ubuntu/Debian/CentOS/Arch 等)
- **架构**: x86_64 或 aarch64
- **依赖**: curl, unzip, git, zsh

### 🔧 新机器快速部署

1. **安装 chezmoi**
   ```bash
   # 使用官方脚本安装
   sh -c "$(curl -fsLS chezmoi.io/get)"
   
   # 或者使用包管理器
   # Ubuntu/Debian
   sudo apt install chezmoi
   
   # Arch Linux
   sudo pacman -S chezmoi
   ```

2. **初始化配置**
   ```bash
   # 从 GitHub 仓库初始化并应用配置
   chezmoi init --apply https://github.com/zhaowei2025/dotfile.git
   ```

3. **重启终端或重新加载配置**
   ```bash
   # 重新加载 zsh 配置
   source ~/.zshrc
   
   # 或者重启终端
   ```

4. **验证安装**
   ```bash
   # 检查工具状态
   manage-tools list
   
   # 检查代理功能
   pst  # proxy status
   ```

## 📖 使用指南

### 🌐 代理管理

```bash
# 开启代理
pon                    # 等同于 proxy_on

# 关闭代理  
poff                   # 等同于 proxy_off

# 查看代理状态
pst                    # 等同于 proxy_status

# 测试代理连接
ptest                  # 等同于 proxy_test

# Git 代理管理
gpon                   # 开启 Git 代理
gpoff                  # 关闭 Git 代理
gpst                   # 查看 Git 代理状态
```

### 🔄 Git 账户切换

```bash
# 切换到工作账户
git_work

# 切换到个人账户  
git_personal

# 查看当前 Git 配置
git config --global --list | grep user
```

### 🛠️ 二进制工具管理

```bash
# 查看所有工具状态
manage-tools list

# 安装特定工具
manage-tools install fd
manage-tools install nvim

# 更新所有工具
manage-tools update

# 更新特定工具
manage-tools update clangd

# 工具备份和恢复
manage-tools backup rg
manage-tools restore rg

# 清理旧备份
manage-tools clean

# 查看工具详细状态
manage-tools status nvim
```

### ⚙️ 配置更新

```bash
# 查看待应用的更改
chezmoi diff

# 应用配置更改
chezmoi apply

# 更新配置仓库
chezmoi update

# 编辑配置文件
chezmoi edit ~/.zshrc
```

## 🔧 自定义配置

### 修改工具版本

编辑 `~/.config/bin-tools/versions.toml`:

```toml
[fd]
version = "v10.2.0"

[ripgrep]  
version = "14.1.1"

[neovim]
version = "latest"

[clangd]
version = "19.1.2"
```

保存后 chezmoi 会自动检测并更新。

### 修改代理设置

编辑 `~/.local/share/chezmoi/dot_zshrc` 中的代理配置：

```bash
# 代理服务器配置
PROXY_HOST="your_proxy_host"
PROXY_PORT="your_proxy_port"
```

### 添加新的二进制工具

1. 在 `versions.toml` 中添加配置
2. 在 `run_once_install-bin-tools.sh.tmpl` 中添加安装逻辑
3. 在 `executable_manage-tools` 中添加管理支持

## 🎯 常用命令速查

| 功能 | 命令 | 说明 |
|------|------|------|
| 代理开启 | `pon` | 开启 HTTP/HTTPS 代理 |
| 代理关闭 | `poff` | 关闭所有代理设置 |
| 代理状态 | `pst` | 查看当前代理状态 |
| Git工作账户 | `git_work` | 切换到工作 Git 账户 |
| Git个人账户 | `git_personal` | 切换到个人 Git 账户 |
| 工具列表 | `manage-tools list` | 查看所有管理工具状态 |
| 工具更新 | `manage-tools update` | 更新所有二进制工具 |
| 配置同步 | `chezmoi apply` | 应用最新配置更改 |
| 查看差异 | `chezmoi diff` | 查看待应用的更改 |

## 🔒 安全特性

- **私有配置**: 敏感配置存储在 `private_` 前缀目录
- **备份机制**: 自动备份重要文件，支持快速恢复
- **版本控制**: 所有配置文件都在 git 版本控制下
- **权限管理**: 可执行文件自动设置正确权限

## 🚨 故障排除

### 工具未找到

```bash
# 确保 PATH 配置正确
echo $PATH | grep ".local/bin"

# 重新加载配置
source ~/.zshrc

# 检查工具安装状态
manage-tools list
```

### 下载失败

```bash
# 开启代理后重试
pon
manage-tools install tool_name

# 或检查网络连接
curl -I https://github.com
```

### 配置冲突

```bash
# 查看 chezmoi 状态
chezmoi doctor

# 强制应用配置
chezmoi apply --force

# 重置特定文件
chezmoi forget ~/.zshrc
chezmoi add ~/.zshrc
```

## 🤝 贡献指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

- [chezmoi](https://www.chezmoi.io/) - 优秀的 dotfiles 管理工具
- [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) - Neovim 配置起点
- 所有开源工具的开发者们

---

⭐ 如果这个项目对你有帮助，请考虑给个 Star！ 