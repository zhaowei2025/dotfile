#!/bin/bash

# Chezmoi 原生加密 Token 管理器
# 使用 chezmoi 内置的 AGE 加密功能管理敏感信息

set -e

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
    echo "🔐 Chezmoi 原生加密 Token 管理器"
    echo "=================================="
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

# 检查AGE是否已配置
check_age_setup() {
    local config_file="$HOME/.config/chezmoi/chezmoi.toml"
    
    if [[ ! -f "$config_file" ]]; then
        return 1
    fi
    
    if grep -q "encryption" "$config_file" && grep -q "age" "$config_file"; then
        return 0
    else
        return 1
    fi
}

# 设置AGE加密
setup_age_encryption() {
    print_step "设置 AGE 加密..."
    
    # 创建配置目录
    mkdir -p "$HOME/.config/chezmoi"
    
    # 生成AGE密钥
    print_info "生成 AGE 密钥对..."
    
    # 检查是否已经有AGE密钥
    if [[ ! -f "$HOME/.config/chezmoi/key.txt" ]]; then
        # 使用chezmoi内置的age生成密钥
        if command -v age-keygen >/dev/null 2>&1; then
            age-keygen -o "$HOME/.config/chezmoi/key.txt"
        else
            # 如果没有age-keygen，使用chezmoi内置的
            print_info "使用 chezmoi 内置 AGE 功能..."
            # 创建一个临时密钥
            echo "# 临时AGE密钥 - 请替换为真实密钥" > "$HOME/.config/chezmoi/key.txt"
            echo "AGE-SECRET-KEY-1EXAMPLE123456789EXAMPLE123456789EXAMPLE123456789EXAMPLE" >> "$HOME/.config/chezmoi/key.txt"
        fi
        
        chmod 600 "$HOME/.config/chezmoi/key.txt"
        print_success "AGE 密钥已生成: ~/.config/chezmoi/key.txt"
    else
        print_info "AGE 密钥已存在"
    fi
    
    # 获取公钥
    local public_key
    if command -v age-keygen >/dev/null 2>&1; then
        public_key=$(grep "public key:" "$HOME/.config/chezmoi/key.txt" | cut -d: -f2 | tr -d ' ')
    else
        public_key="age1example123456789example123456789example123456789example"
        print_warning "请手动设置真实的 AGE 公钥"
    fi
    
    # 创建chezmoi配置
    cat > "$HOME/.config/chezmoi/chezmoi.toml" << EOF
# Chezmoi 配置文件

[encryption]
command = "age"

[encryption.age]
identity = "~/.config/chezmoi/key.txt"
recipient = "$public_key"
EOF
    
    print_success "Chezmoi AGE 加密配置已完成"
}

# 创建加密的token文件
create_encrypted_tokens() {
    print_step "创建加密的 tokens 文件..."
    
    # 临时文件收集tokens
    local temp_tokens="/tmp/tokens_temp.txt"
    
    echo "# 加密的Token配置文件" > "$temp_tokens"
    echo "# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$temp_tokens"
    echo "" >> "$temp_tokens"
    
    # 交互式收集tokens
    echo -e "${BLUE}请输入以下 tokens (输入时不显示):${NC}"
    
    for token_name in "GITHUB_TOKEN" "DEEPSEEK_API_KEY" "ALI_DEEPSEEK_API_KEY" "ZHIHE_API_KEY"; do
        echo -n "请输入 $token_name: "
        read -s token_value
        echo
        
        if [[ -n "$token_value" ]]; then
            echo "export $token_name=\"$token_value\"" >> "$temp_tokens"
        fi
    done
    
    # 使用chezmoi加密
    chezmoi encrypt "$temp_tokens" > "encrypted_private_dot_env.private.asc"
    
    # 清理临时文件
    rm -f "$temp_tokens"
    
    print_success "加密的 tokens 文件已创建: encrypted_private_dot_env.private.asc"
}

# 解密并查看token状态
view_token_status() {
    print_info "Token 状态："
    
    if [[ -f "encrypted_private_dot_env.private.asc" ]]; then
        echo "  ✅ 加密文件存在: encrypted_private_dot_env.private.asc"
        echo "  📋 Token 内容 (解密预览)："
        
        # 解密并显示（隐藏敏感信息）
        chezmoi decrypt "encrypted_private_dot_env.private.asc" | while IFS= read -r line; do
            if [[ "$line" =~ ^export ]]; then
                local var_name=$(echo "$line" | cut -d'=' -f1 | sed 's/export //')
                local var_value=$(echo "$line" | cut -d'=' -f2- | sed 's/"//g')
                if [[ -n "$var_value" ]]; then
                    echo "     ✅ $var_name: ${var_value:0:8}..."
                fi
            fi
        done
    else
        echo "  ❌ 加密文件不存在"
    fi
}

# 编辑加密的tokens
edit_encrypted_tokens() {
    if [[ ! -f "encrypted_private_dot_env.private.asc" ]]; then
        print_error "加密文件不存在，请先创建"
        return 1
    fi
    
    print_step "编辑加密的 tokens..."
    
    # 解密到临时文件
    local temp_file="/tmp/tokens_edit.txt"
    chezmoi decrypt "encrypted_private_dot_env.private.asc" > "$temp_file"
    
    # 编辑
    ${EDITOR:-nano} "$temp_file"
    
    # 重新加密
    chezmoi encrypt "$temp_file" > "encrypted_private_dot_env.private.asc"
    
    # 清理
    rm -f "$temp_file"
    
    print_success "Token 文件已更新"
}

# 应用配置到目标环境
apply_tokens() {
    print_step "应用 tokens 到环境..."
    
    if [[ ! -f "encrypted_private_dot_env.private.asc" ]]; then
        print_error "加密文件不存在"
        return 1
    fi
    
    # 解密并写入到目标文件
    chezmoi decrypt "encrypted_private_dot_env.private.asc" > "$HOME/.env.private"
    chmod 600 "$HOME/.env.private"
    
    # 确保在shell配置中加载
    local shell_config
    if [[ "$SHELL" == *"zsh"* ]]; then
        shell_config="$HOME/.zshrc"
    else
        shell_config="$HOME/.bashrc"
    fi
    
    if ! grep -q "source.*\.env\.private" "$shell_config" 2>/dev/null; then
        echo "" >> "$shell_config"
        echo "# 加载私有环境变量" >> "$shell_config"
        echo "if [[ -f ~/.env.private ]]; then" >> "$shell_config"
        echo "    source ~/.env.private" >> "$shell_config"
        echo "fi" >> "$shell_config"
    fi
    
    print_success "Tokens 已应用到环境"
    print_info "请重新加载 shell: source $shell_config"
}

# 导出加密文件（用于同步）
export_encrypted() {
    local export_file="$1"
    
    if [[ -z "$export_file" ]]; then
        export_file="$HOME/tokens_encrypted_backup.asc"
    fi
    
    if [[ -f "encrypted_private_dot_env.private.asc" ]]; then
        cp "encrypted_private_dot_env.private.asc" "$export_file"
        print_success "加密文件已导出到: $export_file"
        print_info "你可以将此文件安全地存储到云盘或其他机器"
    else
        print_error "加密文件不存在"
    fi
}

# 导入加密文件
import_encrypted() {
    local import_file="$1"
    
    if [[ -z "$import_file" ]]; then
        echo -n "请输入要导入的加密文件路径: "
        read import_file
    fi
    
    if [[ -f "$import_file" ]]; then
        cp "$import_file" "encrypted_private_dot_env.private.asc"
        print_success "加密文件已导入"
    else
        print_error "文件不存在: $import_file"
    fi
}

# 菜单显示
show_menu() {
    echo -e "${BLUE}请选择操作：${NC}"
    echo "1. 🔧 设置 AGE 加密"
    echo "2. 🆕 创建加密 tokens"
    echo "3. 📝 编辑加密 tokens"
    echo "4. 🚀 应用 tokens 到环境"
    echo "5. 📋 查看 token 状态"
    echo "6. 📤 导出加密文件"
    echo "7. 📥 导入加密文件"
    echo "8. ❓ 使用帮助"
    echo "0. 🚪 退出"
    echo
}

# 使用帮助
show_help() {
    echo -e "${CYAN}Chezmoi 原生加密 Token 管理器使用帮助${NC}"
    echo
    echo -e "${YELLOW}主要优势：${NC}"
    echo "• 使用 chezmoi 内置 AGE 加密，更安全可靠"
    echo "• 加密文件可以安全地提交到 Git 仓库"
    echo "• 原生集成到 chezmoi 工作流中"
    echo "• 支持跨平台和跨机器同步"
    echo
    echo -e "${YELLOW}工作流程：${NC}"
    echo "1. 首次使用：设置 AGE 加密 → 创建加密 tokens"
    echo "2. 新机器：导入加密文件 → 应用到环境"
    echo "3. 日常使用：直接使用环境变量进行 Git 操作"
    echo
    echo -e "${YELLOW}文件说明：${NC}"
    echo "• ~/.config/chezmoi/key.txt - AGE 私钥（需保密）"
    echo "• ~/.config/chezmoi/chezmoi.toml - chezmoi 配置"
    echo "• encrypted_private_dot_env.private.asc - 加密的 tokens（可提交到 Git）"
    echo "• ~/.env.private - 解密后的环境变量文件（运行时生成）"
}

# 主函数
main() {
    print_header
    
    # 切换到chezmoi目录
    cd "$(chezmoi source-path)" || {
        print_error "无法切换到 chezmoi 源目录"
        exit 1
    }
    
    while true; do
        show_menu
        echo -n "请输入选项 (0-8): "
        read choice
        echo
        
        case "$choice" in
            1) setup_age_encryption ;;
            2) 
                if ! check_age_setup; then
                    print_warning "请先设置 AGE 加密 (选项 1)"
                else
                    create_encrypted_tokens
                fi
                ;;
            3)
                if ! check_age_setup; then
                    print_warning "请先设置 AGE 加密 (选项 1)"
                else
                    edit_encrypted_tokens
                fi
                ;;
            4) apply_tokens ;;
            5) 
                if check_age_setup; then
                    view_token_status
                else
                    print_warning "AGE 加密未设置"
                fi
                ;;
            6)
                echo -n "导出文件路径 (回车使用默认): "
                read export_path
                export_encrypted "$export_path"
                ;;
            7)
                echo -n "导入文件路径: "
                read import_path
                import_encrypted "$import_path"
                ;;
            8) show_help ;;
            0)
                echo -e "${GREEN}感谢使用 Chezmoi 原生加密 Token 管理器！${NC}"
                exit 0
                ;;
            *)
                print_error "无效的选项，请输入 0-8"
                ;;
        esac
        
        echo
        echo -e "${BLUE}按 Enter 继续...${NC}"
        read
        echo
    done
}

# 检查依赖
if ! command -v chezmoi >/dev/null 2>&1; then
    print_error "未找到 chezmoi，请先安装"
    exit 1
fi

# 检查是否为交互式终端
if [[ ! -t 0 ]]; then
    print_error "此脚本需要在交互式终端中运行"
    exit 1
fi

main "$@" 