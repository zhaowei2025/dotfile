# Binary Tools Management with chezmoi

这个系统使用 chezmoi 来管理 `~/.local/bin` 下的二进制工具，包括 fd、ripgrep、neovim 和 clangd。

## 特性

- 🚀 自动下载和安装二进制工具
- 📦 版本管理和配置
- 🔄 自动更新机制
- 💾 备份和恢复功能
- 🧹 清理旧版本
- 🎯 跨平台支持 (x86_64, aarch64)

## 文件结构

```
~/.local/share/chezmoi/
├── install-bin-tools.sh          # 初始安装脚本
├── update-bin-tools.sh       # 配置变更时的更新脚本
├── dot_local/bin/executable_manage-tools       # 管理工具脚本
└── dot_config/bin-tools/
    ├── versions.toml                            # 版本配置文件
    └── README.md                                # 说明文档
```

## 管理的工具

| 工具 | 描述 | 官方仓库 |
|------|------|----------|
| fd | 现代化的 find 替代品 | [sharkdp/fd](https://github.com/sharkdp/fd) |
| rg (ripgrep) | 快速的文本搜索工具 | [BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep) |
| nvim (neovim) | 现代化的 vim 编辑器 | [neovim/neovim](https://github.com/neovim/neovim) |
| clangd | C/C++ 语言服务器 | [clangd/clangd](https://github.com/clangd/clangd) |
| lazygit | 终端下的 Git UI | [jesseduffield/lazygit](https://github.com/jesseduffield/lazygit) |

## 使用方法

### 初始设置

1. 将文件添加到 chezmoi：
   ```bash
   chezmoi add ~/.config/bin-tools/
   chezmoi apply
   ```

2. 工具会自动安装到 `~/.local/bin/`

### 管理命令

使用 `manage-tools` 脚本来管理工具：

```bash
# 查看所有工具状态
manage-tools list

# 安装特定工具
manage-tools install fd

# 更新所有工具
manage-tools update

# 更新特定工具
manage-tools update nvim

# 查看工具状态
manage-tools status clangd

# 备份工具
manage-tools backup rg

# 从备份恢复
manage-tools restore rg

# 清理旧备份
manage-tools clean

# 移除工具
manage-tools remove fd
```

### 版本管理

编辑 `~/.config/bin-tools/versions.toml` 来更新工具版本：

```toml
[fd]
version = "v10.2.0"

[ripgrep]
version = "14.1.1"

[neovim]
version = "latest"

[clangd]
version = "19.1.2"

[lazygit]
version = "v0.51.1"
```

保存后，chezmoi 会自动检测变更并更新工具。

### 手动操作

```bash
# 强制重新安装所有工具
chezmoi apply --force

# 查看 chezmoi 状态
chezmoi status

# 查看将要执行的脚本
chezmoi diff
```

## 工作原理

1. **初始安装**: `install-bin-tools.sh` 在首次运行时安装所有工具
2. **配置监控**: `update-bin-tools.sh` 监控 `versions.toml` 的变化
3. **版本管理**: 通过修改配置文件来控制工具版本
4. **自动下载**: 脚本自动从 GitHub releases 下载对应架构的二进制文件
5. **备份机制**: 更新前自动备份现有版本

## 添加新工具

要添加新的二进制工具：

1. 在 `versions.toml` 中添加配置
2. 在安装脚本中添加下载逻辑
3. 在管理脚本中添加工具名称

## 故障排除

### 工具未找到
确保 `~/.local/bin` 在你的 PATH 中：
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### 下载失败
检查网络连接和 GitHub 访问：
```bash
curl -I https://github.com
```

### 权限问题
确保脚本有执行权限：
```bash
chmod +x ~/.local/bin/manage-tools
```

### 清理和重置
完全重置所有工具：
```bash
rm -rf ~/.local/bin/{fd,rg,nvim,clangd,lazygit}
chezmoi apply
```

## 自定义

你可以通过以下方式自定义：

- 修改 `versions.toml` 来更改版本
- 编辑安装脚本来添加新工具
- 调整下载源和镜像
- 修改安装路径和配置

## 注意事项

- 大型二进制文件不会存储在 git 仓库中
- 首次安装可能需要较长时间下载
- 确保有足够的磁盘空间
- 某些工具可能需要额外的依赖 