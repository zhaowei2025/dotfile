#!/bin/bash
set -e

# 检查 glibc 版本
GLIBC_VER=$(ldd --version | head -n1 | grep -oE '[0-9]+\.[0-9]+')
REQUIRED_GLIBC=2.12

# 1. 安装 nvim (AppImage)，仅当 glibc >= 2.12
if [ "$(printf '%s\n' "$REQUIRED_GLIBC" "$GLIBC_VER" | sort -V | head -n1)" = "$REQUIRED_GLIBC" ]; then
  mkdir -p "$HOME/.local/bin"
  if [ ! -f "$HOME/.local/bin/nvim" ]; then
    echo "正在下载 Neovim v0.11.1..."
    curl -LO https://github.com/neovim/neovim/releases/download/v0.11.1/nvim-linux-x86_64.appimage
    chmod +x nvim-linux-x86_64.appimage
    # 提取 AppImage 内容以避免 FUSE 问题
    ./nvim-linux-x86_64.appimage --appimage-extract
    # 创建软链接到提取的二进制文件
    ln -s "$HOME/.local/bin/squashfs-root/usr/bin/nvim" "$HOME/.local/bin/nvim"
    # 清理 AppImage 文件
    rm nvim-linux-x86_64.appimage
    echo "Neovim 安装完成"
  else
    echo "Neovim 已存在，跳过下载"
  fi
else
  echo "[警告] 你的 glibc 版本为 $GLIBC_VER，低于 Neovim 官方 release 要求的 $REQUIRED_GLIBC，已跳过 nvim 安装。"
fi

# 2. 安装 fd (GitHub Releases)
if [ ! -f "$HOME/.local/bin/fd" ]; then
  echo "正在下载 fd v10.2.0..."
  FD_VERSION="v10.2.0"
  FD_TAR="fd-${FD_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
  curl -LO https://github.com/sharkdp/fd/releases/download/${FD_VERSION}/${FD_TAR}
  tar -xzf ${FD_TAR}
  mv fd-${FD_VERSION}-x86_64-unknown-linux-gnu/fd "$HOME/.local/bin/"
  rm -rf fd-${FD_VERSION}-x86_64-unknown-linux-gnu ${FD_TAR}
  echo "fd 安装完成"
else
  echo "fd 已存在，跳过下载"
fi

# 3. 安装 ripgrep (GitHub Releases)
if [ ! -f "$HOME/.local/bin/rg" ]; then
  echo "正在下载 ripgrep 14.1.1..."
  RG_VERSION="14.1.1"
  RG_TAR="ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz"
  curl -LO https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/${RG_TAR}
  tar -xzf ${RG_TAR}
  mv ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl/rg "$HOME/.local/bin/"
  rm -rf ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl ${RG_TAR}
  echo "ripgrep 安装完成"
else
  echo "ripgrep 已存在，跳过下载"
fi

# 4. 安装 clangd/clang-format (GitHub Releases)
if [ ! -d "$HOME/.local/clangd/clangd_19.1.2" ]; then
  echo "正在下载 clangd 19.1.2..."
  mkdir -p "$HOME/.local/clangd"
  curl -LO https://github.com/clangd/clangd/releases/download/19.1.2/clangd-linux-19.1.2.zip
  unzip -o clangd-linux-19.1.2.zip -d "$HOME/.local/clangd"
  rm clangd-linux-19.1.2.zip
  echo "clangd 安装完成"
else
  echo "clangd 已存在，跳过下载"
fi

# 5. 添加 PATH 提示
if ! grep -q 'clangd_19.1.2/bin' ~/.zshrc; then
  echo 'export PATH="$HOME/.local/clangd/clangd_19.1.2/bin:$PATH"' >> ~/.zshrc
fi
if ! grep -q '.local/bin' ~/.zshrc; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
fi

# 6. 完成提示
echo "请重新打开终端或 source ~/.zshrc 以生效 PATH" 