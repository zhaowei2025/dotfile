#!/bin/bash

# 转换现有私有文件为 AGE 加密格式的脚本

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

# 检查AGE配置
check_age_config() {
    if [[ ! -f "$HOME/.config/chezmoi/chezmoi.toml" ]] || [[ ! -f "$HOME/.config/chezmoi/key.txt" ]]; then
        print_error "AGE 配置不存在，请先运行 chezmoi-token-manager.sh 选择选项1设置AGE加密"
        exit 1
    fi
}

# 从环境变量文件创建加密文件
convert_env_file() {
    local env_file="$1"
    local output_file="encrypted_private_dot_env.private.asc"
    
    if [[ ! -f "$env_file" ]]; then
        print_error "文件不存在: $env_file"
        return 1
    fi
    
    print_info "将 $env_file 转换为加密格式..."
    
    # 创建临时文件，添加注释
    local temp_file="/tmp/tokens_convert.txt"
    
    cat > "$temp_file" << EOF
# 加密的私有环境变量文件
# 转换时间: $(date '+%Y-%m-%d %H:%M:%S')
# 原文件: $env_file

EOF
    
    # 复制实际内容，过滤掉注释和空行
    grep -E "^export " "$env_file" >> "$temp_file" 2>/dev/null || true
    
    # 使用chezmoi加密
    if chezmoi encrypt "$temp_file" > "$output_file" 2>/dev/null; then
        rm -f "$temp_file"
        print_success "已创建加密文件: $output_file"
        
        # 显示文件大小
        local size=$(stat -c%s "$output_file" 2>/dev/null || stat -f%z "$output_file" 2>/dev/null)
        print_info "文件大小: $size bytes"
        
        return 0
    else
        rm -f "$temp_file"
        print_error "加密失败"
        return 1
    fi
}

# 从当前环境变量创建加密文件
convert_from_env() {
    local output_file="encrypted_private_dot_env.private.asc"
    local temp_file="/tmp/tokens_from_env.txt"
    
    print_info "从当前环境变量创建加密文件..."
    
    cat > "$temp_file" << EOF
# 加密的私有环境变量文件
# 创建时间: $(date '+%Y-%m-%d %H:%M:%S')
# 来源: 当前环境变量

EOF
    
    # 收集相关的环境变量
    local found_tokens=false
    
    for token_name in "GITHUB_TOKEN" "DEEPSEEK_API_KEY" "ALI_DEEPSEEK_API_KEY" "ZHIHE_API_KEY"; do
        local token_value=$(printenv "$token_name" 2>/dev/null || true)
        if [[ -n "$token_value" ]]; then
            echo "export $token_name=\"$token_value\"" >> "$temp_file"
            print_info "已添加 $token_name"
            found_tokens=true
        fi
    done
    
    if [[ "$found_tokens" = false ]]; then
        print_warning "未找到任何相关的环境变量"
        rm -f "$temp_file"
        return 1
    fi
    
    # 加密
    if chezmoi encrypt "$temp_file" > "$output_file" 2>/dev/null; then
        rm -f "$temp_file"
        print_success "已创建加密文件: $output_file"
        return 0
    else
        rm -f "$temp_file"
        print_error "加密失败"
        return 1
    fi
}

# 手动输入创建加密文件
create_manual() {
    local output_file="encrypted_private_dot_env.private.asc"
    local temp_file="/tmp/tokens_manual.txt"
    
    print_info "手动输入创建加密文件..."
    
    cat > "$temp_file" << EOF
# 加密的私有环境变量文件
# 创建时间: $(date '+%Y-%m-%d %H:%M:%S')
# 来源: 手动输入

EOF
    
    echo "请输入你的 tokens (输入完成后按 Ctrl+D):"
    echo "格式示例: export GITHUB_TOKEN=\"your_token_here\""
    echo "---"
    
    # 读取用户输入
    while IFS= read -r line; do
        if [[ "$line" =~ ^export ]]; then
            echo "$line" >> "$temp_file"
        fi
    done
    
    # 加密
    if chezmoi encrypt "$temp_file" > "$output_file" 2>/dev/null; then
        rm -f "$temp_file"
        print_success "已创建加密文件: $output_file"
        return 0
    else
        rm -f "$temp_file"
        print_error "加密失败"
        return 1
    fi
}

# 主函数
main() {
    echo "🔐 转换私有文件为 AGE 加密格式"
    echo "================================"
    echo
    
    # 检查AGE配置
    check_age_config
    
    # 切换到chezmoi目录
    cd "$(chezmoi source-path)" || {
        print_error "无法切换到 chezmoi 源目录"
        exit 1
    }
    
    print_info "当前目录: $(pwd)"
    echo
    
    echo "请选择转换方式:"
    echo "1. 从现有环境变量文件转换 (如 ~/.env.tokens)"
    echo "2. 从当前环境变量自动收集"
    echo "3. 手动输入tokens"
    echo "4. 查看现有文件状态"
    echo "0. 退出"
    echo
    
    echo -n "请选择 (0-4): "
    read choice
    echo
    
    case "$choice" in
        1)
            echo "常见的环境变量文件:"
            echo "- ~/.env.tokens"
            echo "- ~/.env.private" 
            echo
            echo -n "请输入文件路径: "
            read file_path
            
            # 支持 ~ 展开
            file_path="${file_path/#\~/$HOME}"
            
            convert_env_file "$file_path"
            ;;
        2)
            convert_from_env
            ;;
        3)
            create_manual
            ;;
        4)
            print_info "检查现有文件状态..."
            
            echo "环境变量文件:"
            for file in ~/.env.tokens ~/.env.private; do
                if [[ -f "$file" ]]; then
                    echo "  ✅ $file ($(stat -c%s "$file" 2>/dev/null || stat -f%z "$file") bytes)"
                    echo "     内容预览:"
                    grep -E "^export " "$file" 2>/dev/null | sed 's/=.*/=***/' | sed 's/^/       /' || echo "       (无export语句)"
                else
                    echo "  ❌ $file (不存在)"
                fi
            done
            
            echo
            echo "加密文件:"
            if [[ -f "encrypted_private_dot_env.private.asc" ]]; then
                echo "  ✅ encrypted_private_dot_env.private.asc ($(stat -c%s "encrypted_private_dot_env.private.asc" 2>/dev/null || stat -f%z "encrypted_private_dot_env.private.asc") bytes)"
                echo "     解密预览:"
                chezmoi decrypt "encrypted_private_dot_env.private.asc" 2>/dev/null | grep -E "^export " | sed 's/=.*/=***/' | sed 's/^/       /' || echo "       (解密失败或无export语句)"
            else
                echo "  ❌ encrypted_private_dot_env.private.asc (不存在)"
            fi
            
            echo
            echo "当前环境变量:"
            for token_name in "GITHUB_TOKEN" "DEEPSEEK_API_KEY" "ALI_DEEPSEEK_API_KEY" "ZHIHE_API_KEY"; do
                local token_value=$(printenv "$token_name" 2>/dev/null || true)
                if [[ -n "$token_value" ]]; then
                    echo "  ✅ $token_name: ${token_value:0:8}***"
                else
                    echo "  ❌ $token_name: 未设置"
                fi
            done
            ;;
        0)
            echo "退出"
            exit 0
            ;;
        *)
            print_error "无效选择"
            exit 1
            ;;
    esac
    
    echo
    if [[ -f "encrypted_private_dot_env.private.asc" ]]; then
        print_success "转换完成！"
        echo
        echo "下一步:"
        echo "1. 验证加密文件: chezmoi decrypt encrypted_private_dot_env.private.asc"
        echo "2. 提交到Git: git add encrypted_private_dot_env.private.asc && git commit -m 'feat: 添加加密的tokens'"
        echo "3. 删除旧的明文文件(可选): rm ~/.env.tokens ~/.env.private"
        echo "4. 删除环境变量模板(可选): rm private_dot_env.private.tmpl"
    fi
}

main "$@" 