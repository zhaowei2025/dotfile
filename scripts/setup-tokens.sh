#!/bin/bash

# Token 设置脚本 - 在新机器上运行一次即可
# 此脚本会交互式地收集并设置所有必要的环境变量

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 安全输入函数（隐藏输入）
secure_read() {
    local prompt="$1"
    local var_name="$2"
    local current_value="$3"
    
    echo -n "$prompt"
    if [[ -n "$current_value" ]]; then
        echo -n " [当前: ${current_value:0:8}...] "
    fi
    echo -n ": "
    
    read -s input
    echo  # 换行
    
    if [[ -n "$input" ]]; then
        declare -g "$var_name"="$input"
    elif [[ -n "$current_value" ]]; then
        declare -g "$var_name"="$current_value"
    fi
}

# 收集所有token
collect_tokens() {
    echo -e "${BLUE}"
    echo "🔐 Token 设置向导"
    echo "=================="
    echo -e "${NC}"
    echo "请输入以下API密钥和token（输入时不会显示字符）"
    echo "如果不想更改现有值，直接按回车即可"
    echo

    # GitHub Token
    secure_read "GitHub Personal Access Token" "GITHUB_TOKEN" "${GITHUB_TOKEN}"
    
    # DeepSeek API Keys
    secure_read "DeepSeek API Key" "DEEPSEEK_API_KEY" "${DEEPSEEK_API_KEY}"
    secure_read "ALI DeepSeek API Key" "ALI_DEEPSEEK_API_KEY" "${ALI_DEEPSEEK_API_KEY}"
    secure_read "ZhiHe API Key" "ZHIHE_API_KEY" "${ZHIHE_API_KEY}"
    
    echo
}

# 写入到配置文件
write_to_config() {
    local config_file="$HOME/.env.tokens"
    
    print_step "写入配置到 $config_file"
    
    cat > "$config_file" << EOF
# 自动生成的Token配置文件
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')

# GitHub Personal Access Token
export GITHUB_TOKEN="$GITHUB_TOKEN"

# DeepSeek API Keys
export DEEPSEEK_API_KEY="$DEEPSEEK_API_KEY"
export ALI_DEEPSEEK_API_KEY="$ALI_DEEPSEEK_API_KEY"
export ZHIHE_API_KEY="$ZHIHE_API_KEY"
EOF

    # 设置安全权限
    chmod 600 "$config_file"
    
    print_success "配置已写入 $config_file (权限: 600)"
}

# 添加到shell配置
add_to_shell() {
    local shell_config
    
    # 检测使用的shell
    if [[ "$SHELL" == *"zsh"* ]]; then
        shell_config="$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        shell_config="$HOME/.bashrc"
    else
        shell_config="$HOME/.profile"
    fi
    
    print_step "添加配置加载到 $shell_config"
    
    # 检查是否已经添加
    if ! grep -q "source.*\.env\.tokens" "$shell_config" 2>/dev/null; then
        echo "" >> "$shell_config"
        echo "# Token 配置加载" >> "$shell_config"
        echo "if [[ -f ~/.env.tokens ]]; then" >> "$shell_config"
        echo "    source ~/.env.tokens" >> "$shell_config"
        echo "fi" >> "$shell_config"
        
        print_success "已添加到 $shell_config"
    else
        print_warning "配置加载已存在于 $shell_config"
    fi
}

# 应用chezmoi配置
apply_chezmoi() {
    print_step "应用 chezmoi 配置..."
    
    # 加载环境变量
    source ~/.env.tokens
    
    # 应用配置
    chezmoi apply
    
    print_success "chezmoi 配置已应用"
}

# 验证配置
verify_setup() {
    print_step "验证配置..."
    
    # 重新加载环境变量
    source ~/.env.tokens
    
    echo "Token 状态："
    [[ -n "$GITHUB_TOKEN" ]] && echo "  ✅ GITHUB_TOKEN: ${GITHUB_TOKEN:0:8}..." || echo "  ❌ GITHUB_TOKEN: 未设置"
    [[ -n "$DEEPSEEK_API_KEY" ]] && echo "  ✅ DEEPSEEK_API_KEY: ${DEEPSEEK_API_KEY:0:8}..." || echo "  ❌ DEEPSEEK_API_KEY: 未设置"
    [[ -n "$ALI_DEEPSEEK_API_KEY" ]] && echo "  ✅ ALI_DEEPSEEK_API_KEY: ${ALI_DEEPSEEK_API_KEY:0:8}..." || echo "  ❌ ALI_DEEPSEEK_API_KEY: 未设置"
    [[ -n "$ZHIHE_API_KEY" ]] && echo "  ✅ ZHIHE_API_KEY: ${ZHIHE_API_KEY:0:8}..." || echo "  ❌ ZHIHE_API_KEY: 未设置"
    
    echo
    print_success "设置完成！请重新打开终端或运行 'source ~/.env.tokens' 来加载环境变量"
}

# 主函数
main() {
    # 加载现有的环境变量（如果存在）
    [[ -f ~/.env.tokens ]] && source ~/.env.tokens
    
    collect_tokens
    write_to_config
    add_to_shell
    apply_chezmoi
    verify_setup
    
    echo
    echo -e "${GREEN}🎉 Token 设置完成！${NC}"
    echo
    echo "下一步："
    echo "1. 重新打开终端或运行: source ~/.env.tokens"
    echo "2. 测试推送: dfpush 'test from new machine'"
    echo "3. 在其他机器上，只需运行此脚本即可同步所有token"
}

# 检查是否为交互式终端
if [[ ! -t 0 ]]; then
    echo "错误：此脚本需要在交互式终端中运行"
    exit 1
fi

main "$@" 