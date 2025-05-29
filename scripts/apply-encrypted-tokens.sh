#!/bin/bash

# 应用加密的 tokens 到环境的脚本

set -e

# 颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
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

# 解密并应用tokens
apply_tokens() {
    local encrypted_file="encrypted_private_dot_env.private.asc"
    local output_file="$HOME/.env.private"
    
    if [[ ! -f "$encrypted_file" ]]; then
        print_error "加密文件不存在: $encrypted_file"
        exit 1
    fi
    
    print_info "解密 tokens 文件..."
    
    # 提取base64编码的内容并解码
    grep -v "^#" "$encrypted_file" | grep -v "^$" | base64 -d > "$output_file"
    
    # 设置正确权限
    chmod 600 "$output_file"
    
    print_success "Tokens 已解密到: $output_file"
    
    # 添加到shell配置
    local shell_config
    if [[ "$SHELL" == *"zsh"* ]]; then
        shell_config="$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        shell_config="$HOME/.bashrc"
    else
        shell_config="$HOME/.profile"
    fi
    
    # 检查是否已经添加加载语句
    if ! grep -q "source.*\.env\.private" "$shell_config" 2>/dev/null; then
        print_info "添加环境变量加载到 $shell_config"
        echo "" >> "$shell_config"
        echo "# 加载私有环境变量" >> "$shell_config"
        echo "if [[ -f ~/.env.private ]]; then" >> "$shell_config"
        echo "    source ~/.env.private" >> "$shell_config"
        echo "fi" >> "$shell_config"
        print_success "已添加到 $shell_config"
    else
        print_info "环境变量加载已存在于 $shell_config"
    fi
    
    # 立即加载环境变量
    source "$output_file"
    
    print_success "环境变量已加载到当前session"
    
    # 显示加载的tokens
    echo
    print_info "已加载的 tokens:"
    for token_name in "GITHUB_TOKEN" "DEEPSEEK_API_KEY" "ALI_DEEPSEEK_API_KEY" "ZHIHE_API_KEY"; do
        local token_value=$(printenv "$token_name" 2>/dev/null || true)
        if [[ -n "$token_value" ]]; then
            echo "  ✅ $token_name: ${token_value:0:8}..."
        else
            echo "  ❌ $token_name: 未设置"
        fi
    done
    
    echo
    print_success "设置完成！"
    print_info "请重新打开终端或运行 'source ~/.env.private' 来在新session中加载环境变量"
}

# 查看当前状态
show_status() {
    local encrypted_file="encrypted_private_dot_env.private.asc"
    local env_file="$HOME/.env.private"
    
    print_info "文件状态:"
    
    if [[ -f "$encrypted_file" ]]; then
        local size=$(stat -c%s "$encrypted_file" 2>/dev/null || stat -f%z "$encrypted_file")
        echo "  ✅ 加密文件: $encrypted_file ($size bytes)"
    else
        echo "  ❌ 加密文件不存在"
    fi
    
    if [[ -f "$env_file" ]]; then
        local size=$(stat -c%s "$env_file" 2>/dev/null || stat -f%z "$env_file")
        local perms=$(stat -c%a "$env_file" 2>/dev/null || stat -f%A "$env_file")
        echo "  ✅ 环境文件: $env_file ($size bytes, 权限: $perms)"
        
        # 显示内容预览
        echo "     内容预览:"
        grep -E "^export " "$env_file" 2>/dev/null | sed 's/=.*/=***/' | sed 's/^/       /' || echo "       (无export语句)"
    else
        echo "  ❌ 环境文件不存在"
    fi
    
    echo
    print_info "当前环境变量:"
    for token_name in "GITHUB_TOKEN" "DEEPSEEK_API_KEY" "ALI_DEEPSEEK_API_KEY" "ZHIHE_API_KEY"; do
        local token_value=$(printenv "$token_name" 2>/dev/null || true)
        if [[ -n "$token_value" ]]; then
            echo "  ✅ $token_name: ${token_value:0:8}..."
        else
            echo "  ❌ $token_name: 未设置"
        fi
    done
}

# 主函数
main() {
    echo "🔐 应用加密的 Tokens"
    echo "===================="
    echo
    
    # 切换到chezmoi目录
    cd "$(chezmoi source-path)" || {
        print_error "无法切换到 chezmoi 源目录"
        exit 1
    }
    
    case "${1:-apply}" in
        "apply")
            apply_tokens
            ;;
        "status")
            show_status
            ;;
        *)
            echo "用法: $0 [apply|status]"
            echo "  apply  - 解密并应用tokens到环境 (默认)"
            echo "  status - 查看文件状态"
            exit 1
            ;;
    esac
}

main "$@" 