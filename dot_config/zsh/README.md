# ZSH 增强配置

这个配置为您的 zsh 环境添加了现代化的功能和工具，提供更好的终端体验。

## 🚀 主要功能

### Oh My Zsh 集成
- **主题**: Agnoster (可切换到 Powerlevel10k)
- **智能补全**: 自动建议历史命令
- **语法高亮**: 实时命令语法检查
- **Git 集成**: 显示 Git 状态和快捷命令

### 现代化工具别名
如果安装了对应工具，会自动使用更好的替代品：

| 传统工具 | 现代替代 | 功能增强 |
|---------|---------|---------|
| `ls`    | `exa/eza` | 图标显示、Git 状态 |
| `cat`   | `bat`   | 语法高亮、行号 |
| `find`  | `fd`    | 更快、更友好 |
| `grep`  | `rg`    | 更快的搜索 |
| `top`   | `btm`   | 更美观的系统监控 |
| `du`    | `dust`  | 更直观的磁盘使用 |

### 增强功能函数

#### 文件和目录操作
- `mkcd <dir>` - 创建并进入目录
- `backup <file>` - 创建带时间戳的备份
- `extract <file>` - 智能解压缩各种格式

#### 模糊查找 (需要 fzf)
- `fvim` - 模糊查找并编辑文件
- `fcd` - 模糊查找并进入目录

#### 系统工具
- `serve [port]` - 快速启动 HTTP 服务器
- `sysinfo` - 显示系统信息

### 键绑定增强
- `Ctrl+R` - 增强的历史搜索
- `Ctrl+T` - 模糊文件查找 (fzf)
- `Ctrl+X Ctrl+E` - 编辑当前命令行
- `Ctrl+Left/Right` - 词汇导航

### 历史记录优化
- 智能去重
- 多终端共享
- 增加历史容量 (10000 条)
- 忽略以空格开头的命令

## 📦 安装

### 自动安装
运行以下脚本自动安装所有组件：

```bash
# 安装 Oh My Zsh 和插件
./run_once_install-zsh-enhancements.sh.tmpl

# 安装现代化 CLI 工具
./run_once_install-modern-cli-tools.sh.tmpl
```

### 手动安装 Oh My Zsh
如果自动安装失败，可以手动安装：

```bash
# 安装 Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 安装插件
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
```

### 现代化工具安装

#### Ubuntu/Debian
```bash
# 基础工具
sudo apt update
sudo apt install fd-find ripgrep bat exa

# 创建符号链接 (Ubuntu 特有)
mkdir -p ~/.local/bin
ln -sf $(which fdfind) ~/.local/bin/fd
ln -sf $(which batcat) ~/.local/bin/bat
```

#### macOS (Homebrew)
```bash
brew install fd ripgrep bat exa bottom dust
```

#### 通过 Cargo 安装
```bash
cargo install fd-find ripgrep bat exa bottom dust
```

## 🎯 使用指南

### 基础命令
```bash
# 目录导航
ll              # 详细列表 (带 Git 状态)
la              # 显示隐藏文件
lt              # 树形显示
..              # 上级目录
...             # 上两级目录

# 文件操作
bat file.txt    # 语法高亮查看文件
fd pattern      # 查找文件
rg pattern      # 搜索内容
```

### 高级功能
```bash
# 模糊查找 (需要 fzf)
fvim           # 查找并编辑文件
fcd            # 查找并进入目录
Ctrl+T         # 模糊文件选择

# 系统监控
btm            # 现代化系统监控
dust           # 磁盘使用分析

# 快速操作
mkcd project   # 创建并进入目录
serve 8080     # 启动 HTTP 服务器
sysinfo        # 系统信息
backup ~/.zshrc # 备份文件
```

### Git 工作流
```bash
# 用户切换
gwork          # 切换到工作账户
gpersonal      # 切换到个人账户
gwho           # 查看当前用户

# LazyGit (如果安装)
lg             # 启动 LazyGit
```

## ⚙️ 自定义配置

### 更改主题
编辑 `.zshrc` 文件中的主题设置：

```bash
# 可选主题
ZSH_THEME="agnoster"           # 默认
ZSH_THEME="powerlevel10k/powerlevel10k"  # 需要安装 P10k
ZSH_THEME="robbyrussell"       # 简洁
ZSH_THEME="af-magic"           # 彩色
```

### 添加插件
在 `.zshrc` 的 plugins 数组中添加：

```bash
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    # 添加更多插件...
)
```

### FZF 配置
可以自定义 FZF 的行为：

```bash
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
```

## 🔧 故障排除

### Oh My Zsh 未加载
检查安装状态：
```bash
ls -la ~/.oh-my-zsh
```

如果不存在，重新运行安装脚本。

### 插件不工作
检查插件目录：
```bash
ls -la ~/.oh-my-zsh/custom/plugins/
```

### 现代工具未生效
检查工具是否安装：
```bash
which fd rg bat exa
```

确保 `~/.local/bin` 在 PATH 中。

### 权限问题
如果遇到权限问题：
```bash
sudo chown -R $USER:$USER ~/.oh-my-zsh
```

## 📚 相关资源

- [Oh My Zsh 官网](https://ohmyz.sh/)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [FZF GitHub](https://github.com/junegunn/fzf)
- [Modern Unix Tools](https://github.com/ibraheemdev/modern-unix)

## 🎨 字体建议

为了获得最佳体验，建议安装 Nerd Fonts：

1. 下载 [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts)
2. 推荐字体：FiraCode Nerd Font, JetBrains Mono Nerd Font
3. 在终端中设置字体

## 📝 更新日志

- **v1.0**: 初始版本，集成 Oh My Zsh 和基础插件
- **v1.1**: 添加现代化工具支持
- **v1.2**: 增强键绑定和历史记录功能
- **v1.3**: 添加模糊查找和系统工具 