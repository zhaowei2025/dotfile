#!/bin/bash

# GitHub Token 管理脚本
# 安全地管理 GitHub Personal Access Token

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ENCRYPTED_FILE="encrypted_private_dot_github-token.env.asc"

echo -e "${BLUE}🐙 GitHub Token 管理${NC}"
echo

# 功能选择
echo "请选择操作："
echo "1. 查看当前 token 状态"
echo "2. 加载 token 到当前会话"
echo "3. 更新 GitHub token"
echo "4. 测试 token 有效性"
echo "5. 在新机器上设置 token"
echo "6. 撤销当前 token（安全建议）"
read -p "请输入选择 (1-6): " choice

case $choice in
    1)
        echo -e "${YELLOW}=== Token 状态 ===${NC}"
        cd ~/.local/share/chezmoi
        
        if [[ -f "$ENCRYPTED_FILE" ]]; then
            echo -e "${GREEN}✓${NC} 找到加密的 token 文件"
            echo "文件: $ENCRYPTED_FILE"
            echo "大小: $(ls -lh "$ENCRYPTED_FILE" | awk '{print $5}')"
            
            echo
            echo "解密预览 (隐藏敏感部分):"
            decrypted=$(chezmoi decrypt "$ENCRYPTED_FILE")
            echo "$decrypted" | sed 's/ghp_[a-zA-Z0-9]*/ghp_****HIDDEN****/g'
        else
            echo -e "${RED}✗${NC} 未找到加密的 token 文件"
        fi
        
        echo
        echo -e "${BLUE}当前环境变量：${NC}"
        if [[ -n "${GITHUB_TOKEN:-}" ]]; then
            echo "GITHUB_TOKEN: ghp_****$(echo "$GITHUB_TOKEN" | tail -c 8)"
        else
            echo "GITHUB_TOKEN: 未设置"
        fi
        ;;
        
    2)
        echo -e "${YELLOW}=== 加载 Token ===${NC}"
        cd ~/.local/share/chezmoi
        
        if [[ ! -f "$ENCRYPTED_FILE" ]]; then
            echo -e "${RED}✗${NC} 未找到加密的 token 文件"
            exit 1
        fi
        
        echo "正在解密并加载 token..."
        decrypted_content=$(chezmoi decrypt "$ENCRYPTED_FILE")
        
        # 写入临时文件并source
        temp_file=$(mktemp)
        echo "$decrypted_content" > "$temp_file"
        
        echo "请运行以下命令加载 token 到当前会话："
        echo -e "${GREEN}source $temp_file${NC}"
        echo
        echo "或者运行："
        echo -e "${GREEN}eval \"\$(chezmoi decrypt $ENCRYPTED_FILE)\"${NC}"
        ;;
        
    3)
        echo -e "${YELLOW}=== 更新 GitHub Token ===${NC}"
        echo -e "${RED}警告：这将覆盖现有的加密 token${NC}"
        read -p "确认继续？(y/N): " confirm
        
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "操作已取消"
            exit 0
        fi
        
        echo "请输入新的 GitHub token:"
        read -s new_token
        echo
        
        if [[ ! "$new_token" =~ ^ghp_[a-zA-Z0-9]{36}$ ]]; then
            echo -e "${RED}✗${NC} Token 格式不正确"
            echo "GitHub Personal Access Token 应该以 'ghp_' 开头，后跟36个字符"
            exit 1
        fi
        
        # 创建新的 token 文件
        temp_token_file=$(mktemp)
        cat > "$temp_token_file" << EOF
# GitHub Personal Access Token
export GITHUB_TOKEN="$new_token"
EOF
        
        cd ~/.local/share/chezmoi
        
        # 删除旧的加密文件
        if [[ -f "$ENCRYPTED_FILE" ]]; then
            rm "$ENCRYPTED_FILE"
        fi
        
        # 加密新文件
        if chezmoi add --encrypt "$temp_token_file"; then
            rm "$temp_token_file"
            echo -e "${GREEN}✓${NC} Token 已更新并加密"
        else
            rm "$temp_token_file"
            echo -e "${RED}✗${NC} Token 加密失败"
            exit 1
        fi
        ;;
        
    4)
        echo -e "${YELLOW}=== 测试 Token ===${NC}"
        
        # 从加密文件或环境变量获取 token
        if [[ -n "${GITHUB_TOKEN:-}" ]]; then
            test_token="$GITHUB_TOKEN"
            echo "使用环境变量中的 token"
        elif [[ -f ~/.local/share/chezmoi/"$ENCRYPTED_FILE" ]]; then
            cd ~/.local/share/chezmoi
            decrypted=$(chezmoi decrypt "$ENCRYPTED_FILE")
            test_token=$(echo "$decrypted" | grep "GITHUB_TOKEN=" | cut -d'"' -f2)
            echo "使用加密文件中的 token"
        else
            echo -e "${RED}✗${NC} 未找到 token"
            exit 1
        fi
        
        echo "测试 GitHub API 连接..."
        if curl -s -H "Authorization: token $test_token" https://api.github.com/user > /dev/null; then
            echo -e "${GREEN}✓${NC} Token 有效"
            
            # 显示用户信息
            user_info=$(curl -s -H "Authorization: token $test_token" https://api.github.com/user)
            username=$(echo "$user_info" | grep -o '"login":"[^"]*"' | cut -d'"' -f4)
            echo "GitHub 用户: $username"
        else
            echo -e "${RED}✗${NC} Token 无效或网络连接失败"
        fi
        ;;
        
    5)
        echo -e "${YELLOW}=== 新机器设置 ===${NC}"
        echo "在新机器上设置 GitHub token 的步骤："
        echo
        echo "1. 确保已导入 GPG 私钥:"
        echo "   gpg --import private-key-513B803E2ACE042F.asc"
        echo
        echo "2. 配置 chezmoi GPG:"
        echo "   ~/.config/chezmoi/chezmoi.toml 应包含:"
        echo "   encryption = \"gpg\""
        echo "   [gpg]"
        echo "       recipient = \"513B803E2ACE042F\""
        echo
        echo "3. 解密并加载 token:"
        echo "   eval \"\$(chezmoi decrypt $ENCRYPTED_FILE)\""
        echo
        echo "4. 验证 token:"
        echo "   echo \$GITHUB_TOKEN"
        ;;
        
    6)
        echo -e "${YELLOW}=== 撤销 Token ===${NC}"
        echo -e "${RED}这将指导您撤销当前的 GitHub token${NC}"
        echo
        echo "请按以下步骤操作:"
        echo "1. 访问 GitHub: https://github.com/settings/tokens"
        echo "2. 找到并删除当前使用的 token"
        echo "3. 生成新的 token"
        echo "4. 运行此脚本的选项 3 来更新 token"
        echo
        echo -e "${YELLOW}为什么要撤销？${NC}"
        echo "- Token 可能已经暴露"
        echo "- 定期轮换是安全最佳实践"
        echo "- 确保只有您控制的 token 处于活跃状态"
        ;;
        
    *)
        echo -e "${RED}无效选择${NC}"
        exit 1
        ;;
esac 