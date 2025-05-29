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
├── 📋 BACKUP-GUIDE.md                              # 备份使用指南
├── 🚀 DEPLOYMENT-WORKFLOW.md                       # 部署工作流程
├── 💾 backup-dotfiles.sh                           # 配置备份脚本
├── 🔧 dot_gitconfig                               # Git 全局配置
├── 🐚 dot_zshrc                                   # Zsh Shell 配置
├── 🚀 run_once_install-bin-tools.sh.tmpl         # 二进制工具安装脚本
├── 🔄 run_onchange_update-bin-tools.sh.tmpl      # 工具更新脚本
│
├── 📁 dot_local/bin/
│   └── 🛠️ executable_manage-tools                # 工具管理脚本
│
└── 📁 dot_config/
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

### 🔒 备份现有配置（推荐）

如果你的机器上已有配置文件，建议先备份：

```bash
# 下载备份脚本
curl -O https://raw.githubusercontent.com/zhaowei2025/dotfile/main/backup-dotfiles.sh
chmod +x backup-dotfiles.sh

# 执行备份
./backup-dotfiles.sh

# 备份将保存在 ~/dotfiles-backup/时间戳/ 目录中
```

**备份内容包括**:
- Shell 配置 (`.zshrc`, `.bashrc`, etc.)
- Git 配置 (`.gitconfig`)
- 编辑器配置 (`.config/nvim/`)
- 开发工具 (`.local/bin/`)
- SSH 配置 (`.ssh/config`)

详细信息请查看 [📋 备份指南](BACKUP-GUIDE.md)

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

### 📚 部署指南

- 📋 [BACKUP-GUIDE.md](BACKUP-GUIDE.md) - 详细的备份使用指南
- 🚀 [DEPLOYMENT-WORKFLOW.md](DEPLOYMENT-WORKFLOW.md) - 完整的部署工作流程

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

# 我的开发环境配置 (dotfiles)

这是我的跨平台开发环境配置，使用 [chezmoi](https://www.chezmoi.io/) 管理，支持快速部署到新机器。

## 🚀 一键部署到新机器

### 方法1：使用安装脚本（推荐）
```bash
# 设置 GitHub token 环境变量
export GITHUB_TOKEN="your_github_token"

# 运行一键安装脚本
curl -fsSL https://raw.githubusercontent.com/zhaowei2025/dotfile/main/scripts/install.sh | bash
```

### 方法2：手动安装
```bash
# 1. 安装 chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin

# 2. 初始化配置
chezmoi init https://github.com/zhaowei2025/dotfile.git

# 3. 应用配置
chezmoi apply

# 4. 切换到 zsh
chsh -s $(which zsh)
```

## 🔧 包含的工具和配置

### 核心工具
- **Neovim** - 现代化的文本编辑器
- **fd** - 快速文件查找工具
- **ripgrep (rg)** - 快速文本搜索
- **clangd** - C/C++ 语言服务器
- **clang-format** - 代码格式化工具

### Shell 配置
- **zsh** - 强化的 shell 环境
- 彩色提示符
- 智能补全和历史记录
- 丰富的别名和快捷命令

### 代理管理
- `pon` / `poff` - 开启/关闭代理
- `pst` - 查看代理状态
- `ptest` - 测试代理连接
- `gpon` / `gpoff` - Git 代理管理

### Git 用户管理
- `gwork` - 切换到工作账户
- `gpersonal` - 切换到个人账户
- `gwho` - 查看当前用户
- `glwork` / `glpersonal` - 仓库级用户切换

## 📦 Dotfiles 管理命令

### 基本同步
```bash
dfpush "提交消息"    # 推送配置到 GitHub
dfpull              # 从 GitHub 拉取最新配置
dfstatus            # 查看配置状态
dfinit              # 在新机器上初始化配置
```

### 高级操作
```bash
dfedit ~/.zshrc     # 编辑配置并自动推送
dfquick "快速保存"  # 快速提交所有更改
```

### Chezmoi 原生命令
```bash
chezmoi edit <file>     # 编辑配置文件
chezmoi apply           # 应用配置更改
chezmoi status          # 查看配置状态
chezmoi diff            # 查看配置差异
chezmoi cd              # 进入 chezmoi 源目录
```

## 🔐 GitHub Token 配置

为了实现自动认证和推送，需要配置 GitHub Personal Access Token：

### 1. 创建 Token
1. 访问 [GitHub Settings > Personal access tokens](https://github.com/settings/tokens)
2. 点击 "Generate new token (classic)"
3. 设置权限：勾选 `repo` 和 `workflow`
4. 复制生成的 token

### 2. 配置 Token
```bash
# 方法1：环境变量（推荐）
export GITHUB_TOKEN="your_github_token"

# 方法2：写入私有配置文件
echo 'export GITHUB_TOKEN="your_github_token"' >> ~/.env.private
```

### 3. Token 安全性
- Token 存储在 `~/.env.private` 文件中，不会被 git 追踪
- 使用 HTTPS 而非 SSH，避免密钥管理复杂性
- Token 支持精细权限控制

## 📁 目录结构

```
~/.local/share/chezmoi/          # chezmoi 源目录
├── dot_zshrc                    # zsh 配置
├── dot_gitconfig                # Git 配置
├── private_dot_env.private      # 私有环境变量（不被 git 追踪）
├── dot_config/
│   ├── nvim/                    # Neovim 配置
│   └── bin-tools/               # 二进制工具版本管理
├── scripts/
│   └── install.sh               # 一键安装脚本
└── README.md                    # 本文件
```

## 🛠 自定义配置

### 修改代理设置
编辑 `~/.zshrc` 中的代理配置：
```bash
PROXY_HOST="your-proxy-host"
PROXY_PORT="your-proxy-port"
```

### 修改 Git 用户信息
编辑 `~/.zshrc` 中的用户配置：
```bash
GIT_USER_WORK_NAME="your-work-name"
GIT_USER_WORK_EMAIL="your-work-email"
GIT_USER_PERSONAL_NAME="your-personal-name"
GIT_USER_PERSONAL_EMAIL="your-personal-email"
```

### 添加私有配置
在 `~/.env.private` 中添加不想公开的配置：
```bash
export API_KEY="your-secret-key"
export DATABASE_URL="your-database-url"
```

## 🔄 工作流程

### 日常使用
1. **修改配置**：`dfedit ~/.zshrc`
2. **快速保存**：`dfquick`
3. **同步配置**：`dfpush "描述更改"`

### 新机器部署
1. **一键安装**：使用安装脚本
2. **手动微调**：根据具体环境调整
3. **验证功能**：测试各种工具和命令

### 版本管理
- 所有配置都通过 Git 管理
- 支持分支和回滚
- 自动备份现有配置

## 🆘 故障排除

### 常见问题
1. **推送失败**：检查 GITHUB_TOKEN 是否正确设置
2. **配置未生效**：运行 `chezmoi apply` 重新应用
3. **权限问题**：确保 token 有正确的仓库权限

### 重置配置
```bash
# 备份并重新初始化
mv ~/.local/share/chezmoi ~/.local/share/chezmoi.backup
dfinit
```

### 查看日志
```bash
# 查看 chezmoi 详细输出
chezmoi apply -v

# 查看 git 状态
chezmoi cd && git log --oneline -n 10
```

## 📄 许可证

此配置基于 MIT 许可证开源，欢迎自由使用和修改。 