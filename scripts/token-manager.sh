#!/bin/bash

# Token 管理器 - 一体化的token同步解决方案
# 支持多种同步方式：本地加密、云存储、密码管理器等

set -e

# 配置
TOKENS_FILE="$HOME/.env.tokens"
ENCRYPTED_FILE="$HOME/.tokens.enc"
BACKUP_DIR="$HOME/.tokens-backup"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${PURPLE}"
    echo "🔐 Token 管理器"
    echo "================="
    echo -e "${NC}"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# 菜单显示
show_menu() {
    echo -e "${BLUE}请选择操作：${NC}"
    echo "1. 🆕 初始设置（新机器）"
    echo "2. 📝 编辑tokens"
    echo "3. 💾 备份tokens"
    echo "4. 📦 恢复tokens"
    echo "5. 🔒 加密tokens"
    echo "6. 🔓 解密tokens"
    echo "7. 📋 显示token状态"
    echo "8. 🧹 清理临时文件"
    echo "9. ❓ 使用帮助"
    echo "0. 🚪 退出"
    echo
}

# 初始设置
initial_setup() {
    print_step "开始初始设置..."
    
    # 运行setup-tokens.sh脚本
    if [[ -f "$(dirname "$0")/setup-tokens.sh" ]]; then
        bash "$(dirname "$0")/setup-tokens.sh"
    else
        print_error "未找到 setup-tokens.sh 脚本"
        return 1
    fi
}

# 编辑tokens
edit_tokens() {
    if [[ ! -f "$TOKENS_FILE" ]]; then
        print_warning "Tokens文件不存在，创建新文件..."
        touch "$TOKENS_FILE"
        chmod 600 "$TOKENS_FILE"
    fi
    
    # 使用默认编辑器编辑
    ${EDITOR:-nano} "$TOKENS_FILE"
    
    # 确保权限正确
    chmod 600 "$TOKENS_FILE"
    print_success "Tokens文件已更新"
}

# 备份tokens
backup_tokens() {
    if [[ ! -f "$TOKENS_FILE" ]]; then
        print_error "Tokens文件不存在，无法备份"
        return 1
    fi
    
    # 创建备份目录
    mkdir -p "$BACKUP_DIR"
    
    # 生成备份文件名（带时间戳）
    local backup_name="tokens_$(date +%Y%m%d_%H%M%S).backup"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    # 复制文件
    cp "$TOKENS_FILE" "$backup_path"
    chmod 600 "$backup_path"
    
    print_success "Tokens已备份到: $backup_path"
    
    # 清理旧备份（保留最新10个）
    ls -t "$BACKUP_DIR"/tokens_*.backup | tail -n +11 | xargs -r rm
    print_info "已清理旧备份文件（保留最新10个）"
}

# 恢复tokens
restore_tokens() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        print_error "备份目录不存在: $BACKUP_DIR"
        return 1
    fi
    
    local backups=($(ls -t "$BACKUP_DIR"/tokens_*.backup 2>/dev/null))
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        print_error "未找到备份文件"
        return 1
    fi
    
    print_info "可用的备份文件："
    for i in "${!backups[@]}"; do
        local backup_file=$(basename "${backups[$i]}")
        local backup_time=$(echo "$backup_file" | sed 's/tokens_\(.*\)\.backup/\1/' | sed 's/_/ /')
        echo "  $((i+1)). $backup_time"
    done
    
    echo -n "请选择要恢复的备份 (1-${#backups[@]}): "
    read selection
    
    if [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -ge 1 ]] && [[ "$selection" -le ${#backups[@]} ]]; then
        local selected_backup="${backups[$((selection-1))]}"
        cp "$selected_backup" "$TOKENS_FILE"
        chmod 600 "$TOKENS_FILE"
        print_success "已恢复备份: $(basename "$selected_backup")"
    else
        print_error "无效的选择"
        return 1
    fi
}

# 加密tokens
encrypt_tokens() {
    if [[ ! -f "$TOKENS_FILE" ]]; then
        print_error "Tokens文件不存在，无法加密"
        return 1
    fi
    
    echo -n "请输入加密密码: "
    read -s password
    echo
    echo -n "确认密码: "
    read -s password2
    echo
    
    if [[ "$password" != "$password2" ]]; then
        print_error "密码不匹配"
        return 1
    fi
    
    # 使用openssl加密
    openssl enc -aes-256-cbc -salt -in "$TOKENS_FILE" -out "$ENCRYPTED_FILE" -pass pass:"$password"
    chmod 600 "$ENCRYPTED_FILE"
    
    print_success "Tokens已加密到: $ENCRYPTED_FILE"
    print_info "你可以将加密文件存储到云盘等地方进行同步"
}

# 解密tokens
decrypt_tokens() {
    if [[ ! -f "$ENCRYPTED_FILE" ]]; then
        print_error "加密文件不存在: $ENCRYPTED_FILE"
        return 1
    fi
    
    echo -n "请输入解密密码: "
    read -s password
    echo
    
    # 解密
    if openssl enc -aes-256-cbc -d -in "$ENCRYPTED_FILE" -out "$TOKENS_FILE" -pass pass:"$password" 2>/dev/null; then
        chmod 600 "$TOKENS_FILE"
        print_success "Tokens已解密到: $TOKENS_FILE"
    else
        print_error "解密失败，请检查密码"
        rm -f "$TOKENS_FILE"
        return 1
    fi
}

# 显示token状态
show_status() {
    print_info "Token 文件状态："
    
    if [[ -f "$TOKENS_FILE" ]]; then
        echo "  ✅ $TOKENS_FILE ($(stat -c%s "$TOKENS_FILE") bytes, 权限: $(stat -c%a "$TOKENS_FILE"))"
        
        # 显示token内容（隐藏敏感信息）
        echo "  📋 Token 内容："
        while IFS= read -r line; do
            if [[ "$line" =~ ^export ]]; then
                local var_name=$(echo "$line" | cut -d'=' -f1 | sed 's/export //')
                local var_value=$(echo "$line" | cut -d'=' -f2- | sed 's/"//g')
                if [[ -n "$var_value" ]]; then
                    echo "     ✅ $var_name: ${var_value:0:8}..."
                else
                    echo "     ❌ $var_name: 未设置"
                fi
            fi
        done < "$TOKENS_FILE"
    else
        echo "  ❌ $TOKENS_FILE 不存在"
    fi
    
    if [[ -f "$ENCRYPTED_FILE" ]]; then
        echo "  🔒 $ENCRYPTED_FILE ($(stat -c%s "$ENCRYPTED_FILE") bytes)"
    else
        echo "  ❌ 加密文件不存在"
    fi
    
    if [[ -d "$BACKUP_DIR" ]]; then
        local backup_count=$(ls "$BACKUP_DIR"/tokens_*.backup 2>/dev/null | wc -l)
        echo "  💾 备份文件: $backup_count 个"
    else
        echo "  ❌ 备份目录不存在"
    fi
}

# 清理临时文件
cleanup() {
    print_step "清理临时文件..."
    
    # 清理可能的临时文件
    rm -f "$HOME"/.tokens.tmp*
    rm -f /tmp/tokens.*
    
    print_success "临时文件已清理"
}

# 使用帮助
show_help() {
    echo -e "${CYAN}Token 管理器使用帮助${NC}"
    echo
    echo "这个工具帮助你管理开发环境中的API tokens和密钥。"
    echo
    echo -e "${YELLOW}主要功能：${NC}"
    echo "• 安全地存储和同步 API tokens"
    echo "• 支持加密备份"
    echo "• 跨机器同步配置"
    echo
    echo -e "${YELLOW}同步方案：${NC}"
    echo "1. 本地加密：使用 openssl 加密 tokens 文件"
    echo "2. 云存储：将加密文件上传到云盘（Dropbox, OneDrive 等）"
    echo "3. 版本控制：通过 git 同步配置模板（不包含敏感数据）"
    echo
    echo -e "${YELLOW}安全提示：${NC}"
    echo "• 永远不要将明文 tokens 提交到 git"
    echo "• 定期轮换 API 密钥"
    echo "• 使用强密码加密备份文件"
    echo "• 限制文件权限为 600"
}

# 主函数
main() {
    print_header
    
    while true; do
        show_menu
        echo -n "请输入选项 (0-9): "
        read choice
        echo
        
        case "$choice" in
            1) initial_setup ;;
            2) edit_tokens ;;
            3) backup_tokens ;;
            4) restore_tokens ;;
            5) encrypt_tokens ;;
            6) decrypt_tokens ;;
            7) show_status ;;
            8) cleanup ;;
            9) show_help ;;
            0) 
                echo -e "${GREEN}感谢使用 Token 管理器！${NC}"
                exit 0
                ;;
            *)
                print_error "无效的选项，请输入 0-9"
                ;;
        esac
        
        echo
        echo -e "${BLUE}按 Enter 继续...${NC}"
        read
        echo
    done
}

# 检查是否为交互式终端
if [[ ! -t 0 ]]; then
    print_error "此脚本需要在交互式终端中运行"
    exit 1
fi

main "$@" 