#!/bin/bash

# 新机器部署脚本 - 支持GPG加密解密
# 基于 https://www.chezmoi.io/user-guide/encryption/gpg/ 官方文档

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔐 Chezmoi GPG 部署脚本${NC}"
echo "基于官方文档: https://www.chezmoi.io/user-guide/encryption/gpg/"
echo

# 步骤1：初始化 chezmoi
echo -e "${YELLOW}步骤1：初始化 chezmoi 配置${NC}"
cd ~/.local/share/chezmoi

# 如果有 .chezmoi.toml.tmpl，它会提示输入密码
if [[ -f ".chezmoi.toml.tmpl" ]]; then
    echo "检测到加密配置模板，将提示输入GPG密码..."
    chezmoi init --apply
else
    echo "没有找到加密配置模板，跳过..."
fi

echo

# 步骤2：列出所有加密文件
echo -e "${YELLOW}步骤2：检查加密文件${NC}"
encrypted_files=$(find . -name "encrypted_*.asc" -type f)
if [[ -n "$encrypted_files" ]]; then
    echo "找到以下加密文件："
    echo "$encrypted_files" | while IFS= read -r file; do
        echo "  📁 $file"
    done
else
    echo "⚠️  没有找到加密文件"
    exit 1
fi

echo

# 步骤3：解密并部署文件
echo -e "${YELLOW}步骤3：解密并部署文件${NC}"
for encrypted_file in $encrypted_files; do
    echo -e "${BLUE}处理：${NC} $encrypted_file"
    
    # 获取原始文件名（去掉 encrypted_ 前缀和 .asc 后缀）
    original_name="${encrypted_file#./encrypted_}"
    original_name="${original_name%.asc}"
    target_path="$HOME/$original_name"
    
    echo "  解密到: $target_path"
    
    # 解密文件
    if chezmoi decrypt "$encrypted_file" > "$target_path"; then
        chmod 600 "$target_path"  # 设置安全权限
        echo -e "  ${GREEN}✓${NC} 解密成功"
    else
        echo -e "  ${RED}✗${NC} 解密失败"
        continue
    fi
done

echo

# 步骤4：验证
echo -e "${YELLOW}步骤4：验证部署${NC}"
if [[ -f "$HOME/.env.private" ]]; then
    echo "✓ ~/.env.private 已创建"
    echo "  文件大小: $(ls -lh ~/.env.private | awk '{print $5}')"
    echo "  权限: $(ls -l ~/.env.private | awk '{print $1}')"
else
    echo "⚠️  ~/.env.private 未找到"
fi

echo

# 步骤5：加载环境变量
echo -e "${YELLOW}步骤5：加载环境变量${NC}"
if [[ -f "$HOME/.env.private" ]]; then
    echo "添加到 shell 配置文件..."
    
    # 检测 shell 类型
    if [[ "$SHELL" == *"zsh"* ]]; then
        SHELL_RC="$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        SHELL_RC="$HOME/.bashrc"
    else
        SHELL_RC="$HOME/.profile"
    fi
    
    # 添加 source 命令
    if ! grep -q "source ~/.env.private" "$SHELL_RC" 2>/dev/null; then
        echo "" >> "$SHELL_RC"
        echo "# Load private environment variables (managed by chezmoi)" >> "$SHELL_RC"
        echo "if [[ -f ~/.env.private ]]; then" >> "$SHELL_RC"
        echo "    source ~/.env.private" >> "$SHELL_RC"
        echo "fi" >> "$SHELL_RC"
        echo "✓ 已添加到 $SHELL_RC"
    else
        echo "✓ $SHELL_RC 已包含环境变量加载配置"
    fi
    
    echo "运行以下命令重新加载："
    echo "  source $SHELL_RC"
fi

echo
echo -e "${GREEN}🎉 GPG 加密部署完成！${NC}"
echo
echo "下次在新机器上部署，只需运行："
echo "  ~/.local/share/chezmoi/scripts/deploy-with-encryption.sh" 