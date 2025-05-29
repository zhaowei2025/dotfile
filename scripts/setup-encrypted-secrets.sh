#!/bin/bash

# 完整的 GPG 加密设置和部署脚本
# 基于 https://www.chezmoi.io/user-guide/encryption/gpg/

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔐 Chezmoi GPG 加密管理${NC}"
echo

# 功能选择
echo "请选择操作："
echo "1. 初始设置（加密现有敏感文件）"
echo "2. 新机器部署（解密并应用文件）"
echo "3. 查看加密文件列表"
echo "4. 解密单个文件查看内容"
read -p "请输入选择 (1-4): " choice

case $choice in
    1)
        echo -e "${YELLOW}=== 初始设置模式 ===${NC}"
        cd ~/.local/share/chezmoi
        
        # 检查敏感文件
        echo "检查需要加密的文件..."
        sensitive_files=(
            "$HOME/.env.private"
            "$HOME/.gitconfig"
            "$HOME/.ssh/config"
        )
        
        for file in "${sensitive_files[@]}"; do
            if [[ -f "$file" ]]; then
                echo -e "${BLUE}加密文件：${NC} $file"
                if chezmoi add --encrypt "$file"; then
                    echo -e "${GREEN}✓ 加密成功${NC}"
                else
                    echo -e "${RED}✗ 加密失败${NC}"
                fi
            else
                echo -e "${YELLOW}⚠ 文件不存在：${NC} $file"
            fi
        done
        
        echo
        echo "已加密的文件列表："
        find . -name "encrypted_*.asc" -type f | while read -r file; do
            echo "  📁 $file"
        done
        ;;
        
    2)
        echo -e "${YELLOW}=== 新机器部署模式 ===${NC}"
        cd ~/.local/share/chezmoi
        
        # 列出加密文件
        encrypted_files=$(find . -name "encrypted_*.asc" -type f)
        if [[ -z "$encrypted_files" ]]; then
            echo -e "${RED}没有找到加密文件${NC}"
            exit 1
        fi
        
        echo "找到以下加密文件："
        echo "$encrypted_files"
        echo
        
        # 解密文件到home目录
        for encrypted_file in $encrypted_files; do
            # 去掉路径前缀、encrypted_前缀和.asc后缀
            base_name=$(basename "$encrypted_file")
            original_name="${base_name#encrypted_}"
            original_name="${original_name%.asc}"
            target_path="$HOME/$original_name"
            
            echo -e "${BLUE}解密：${NC} $encrypted_file -> $target_path"
            
            if chezmoi decrypt "$encrypted_file" > "$target_path"; then
                chmod 600 "$target_path"
                echo -e "${GREEN}✓ 解密成功${NC}"
            else
                echo -e "${RED}✗ 解密失败${NC}"
            fi
        done
        
        # 应用 chezmoi 配置
        echo
        echo -e "${BLUE}应用 chezmoi 配置...${NC}"
        chezmoi apply
        
        echo -e "${GREEN}🎉 部署完成！${NC}"
        ;;
        
    3)
        echo -e "${YELLOW}=== 加密文件列表 ===${NC}"
        cd ~/.local/share/chezmoi
        find . -name "encrypted_*.asc" -type f | while read -r file; do
            size=$(ls -lh "$file" | awk '{print $5}')
            echo "📁 $file (大小: $size)"
        done
        ;;
        
    4)
        echo -e "${YELLOW}=== 解密文件查看 ===${NC}"
        cd ~/.local/share/chezmoi
        
        # 列出可用文件
        files=($(find . -name "encrypted_*.asc" -type f))
        if [[ ${#files[@]} -eq 0 ]]; then
            echo "没有找到加密文件"
            exit 1
        fi
        
        echo "可用的加密文件："
        for i in "${!files[@]}"; do
            echo "$((i+1)). ${files[i]}"
        done
        
        read -p "请选择要解密查看的文件编号: " file_num
        selected_file="${files[$((file_num-1))]}"
        
        echo -e "${BLUE}解密内容：${NC}"
        echo "----------------------------------------"
        chezmoi decrypt "$selected_file"
        echo "----------------------------------------"
        ;;
        
    *)
        echo -e "${RED}无效选择${NC}"
        exit 1
        ;;
esac 