#!/bin/bash

# GPG 密钥管理脚本
# 支持对称加密和非对称加密两种方式

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔐 GPG 密钥管理${NC}"
echo

# 功能选择
echo "请选择操作："
echo "1. 查看当前密钥状态"
echo "2. 生成新的 GPG 密钥对（公钥/私钥）"
echo "3. 导出公钥（用于分享）"
echo "4. 导出私钥（用于备份）"
echo "5. 导入密钥"
echo "6. 切换到非对称加密配置"
echo "7. 测试非对称加密"
read -p "请输入选择 (1-7): " choice

case $choice in
    1)
        echo -e "${YELLOW}=== 当前密钥状态 ===${NC}"
        echo
        echo -e "${BLUE}私钥列表：${NC}"
        if gpg --list-secret-keys --keyid-format LONG; then
            echo
        else
            echo "没有找到私钥"
        fi
        
        echo -e "${BLUE}公钥列表：${NC}"
        if gpg --list-keys --keyid-format LONG; then
            echo
        else
            echo "没有找到公钥"
        fi
        
        echo -e "${BLUE}当前 chezmoi 配置：${NC}"
        if [[ -f ~/.config/chezmoi/chezmoi.toml ]]; then
            cat ~/.config/chezmoi/chezmoi.toml
        else
            echo "没有找到 chezmoi 配置文件"
        fi
        ;;
        
    2)
        echo -e "${YELLOW}=== 生成 GPG 密钥对 ===${NC}"
        echo "将会创建一个新的 GPG 密钥对（公钥/私钥）"
        echo
        
        # 创建批处理配置文件
        cat > /tmp/gpg-gen-key.conf << EOF
%echo Generating GPG key
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: $(whoami)
Name-Email: $(whoami)@$(hostname)
Expire-Date: 2y
Passphrase: 
%commit
%echo done
EOF

        echo "生成密钥中，请稍候..."
        if gpg --batch --generate-key /tmp/gpg-gen-key.conf; then
            rm -f /tmp/gpg-gen-key.conf
            echo -e "${GREEN}✓ 密钥对生成成功${NC}"
            
            # 显示生成的密钥
            echo
            echo "生成的密钥："
            gpg --list-secret-keys --keyid-format LONG
        else
            rm -f /tmp/gpg-gen-key.conf
            echo -e "${RED}✗ 密钥生成失败${NC}"
        fi
        ;;
        
    3)
        echo -e "${YELLOW}=== 导出公钥 ===${NC}"
        
        # 列出可用的密钥
        keys=$(gpg --list-keys --keyid-format LONG | grep "^pub" | awk '{print $2}' | cut -d'/' -f2)
        if [[ -z "$keys" ]]; then
            echo "没有找到可导出的公钥"
            exit 1
        fi
        
        echo "可用的密钥："
        gpg --list-keys --keyid-format LONG
        echo
        
        read -p "请输入要导出的密钥ID: " key_id
        output_file="public-key-${key_id}.asc"
        
        if gpg --armor --export "$key_id" > "$output_file"; then
            echo -e "${GREEN}✓ 公钥已导出到 $output_file${NC}"
            echo "文件大小: $(ls -lh "$output_file" | awk '{print $5}')"
        else
            echo -e "${RED}✗ 公钥导出失败${NC}"
        fi
        ;;
        
    4)
        echo -e "${YELLOW}=== 导出私钥 ===${NC}"
        echo -e "${RED}警告：私钥非常敏感，请安全保管！${NC}"
        
        keys=$(gpg --list-secret-keys --keyid-format LONG | grep "^sec" | awk '{print $2}' | cut -d'/' -f2)
        if [[ -z "$keys" ]]; then
            echo "没有找到可导出的私钥"
            exit 1
        fi
        
        echo "可用的私钥："
        gpg --list-secret-keys --keyid-format LONG
        echo
        
        read -p "请输入要导出的密钥ID: " key_id
        output_file="private-key-${key_id}.asc"
        
        if gpg --armor --export-secret-keys "$key_id" > "$output_file"; then
            chmod 600 "$output_file"  # 设置严格权限
            echo -e "${GREEN}✓ 私钥已导出到 $output_file${NC}"
            echo "文件大小: $(ls -lh "$output_file" | awk '{print $5}')"
            echo -e "${RED}⚠️  请妥善保管此文件，建议加密存储！${NC}"
        else
            echo -e "${RED}✗ 私钥导出失败${NC}"
        fi
        ;;
        
    5)
        echo -e "${YELLOW}=== 导入密钥 ===${NC}"
        echo "请输入要导入的密钥文件路径："
        read -p "文件路径: " key_file
        
        if [[ ! -f "$key_file" ]]; then
            echo -e "${RED}文件不存在: $key_file${NC}"
            exit 1
        fi
        
        if gpg --import "$key_file"; then
            echo -e "${GREEN}✓ 密钥导入成功${NC}"
        else
            echo -e "${RED}✗ 密钥导入失败${NC}"
        fi
        ;;
        
    6)
        echo -e "${YELLOW}=== 切换到非对称加密 ===${NC}"
        
        # 检查是否有可用的密钥
        keys=$(gpg --list-secret-keys --keyid-format LONG | grep "^sec" | awk '{print $2}' | cut -d'/' -f2)
        if [[ -z "$keys" ]]; then
            echo "没有找到私钥，请先生成密钥对"
            exit 1
        fi
        
        echo "可用的密钥："
        gpg --list-keys --keyid-format LONG
        echo
        
        read -p "请输入要使用的密钥ID: " key_id
        
        # 创建新的 chezmoi 配置
        mkdir -p ~/.config/chezmoi
        cat > ~/.config/chezmoi/chezmoi.toml << EOF
# Chezmoi 配置文件 - 非对称加密

encryption = "gpg"

[gpg]
    recipient = "$key_id"
EOF

        echo -e "${GREEN}✓ 已切换到非对称加密模式${NC}"
        echo "配置文件: ~/.config/chezmoi/chezmoi.toml"
        echo
        cat ~/.config/chezmoi/chezmoi.toml
        ;;
        
    7)
        echo -e "${YELLOW}=== 测试非对称加密 ===${NC}"
        
        # 检查配置
        if [[ ! -f ~/.config/chezmoi/chezmoi.toml ]] || ! grep -q "recipient" ~/.config/chezmoi/chezmoi.toml; then
            echo "请先切换到非对称加密配置"
            exit 1
        fi
        
        # 创建测试文件
        test_file="/tmp/test-asymmetric.txt"
        echo "这是非对称加密测试内容 - $(date)" > "$test_file"
        
        cd ~/.local/share/chezmoi
        echo "加密测试文件..."
        if chezmoi add --encrypt "$test_file"; then
            echo -e "${GREEN}✓ 加密成功${NC}"
            
            # 找到加密文件
            encrypted_file=$(find . -name "encrypted_test-asymmetric.txt.asc" -type f)
            if [[ -n "$encrypted_file" ]]; then
                echo "解密测试..."
                if chezmoi decrypt "$encrypted_file"; then
                    echo -e "${GREEN}✓ 解密成功${NC}"
                else
                    echo -e "${RED}✗ 解密失败${NC}"
                fi
            fi
        else
            echo -e "${RED}✗ 加密失败${NC}"
        fi
        
        # 清理
        rm -f "$test_file"
        ;;
        
    *)
        echo -e "${RED}无效选择${NC}"
        exit 1
        ;;
esac 