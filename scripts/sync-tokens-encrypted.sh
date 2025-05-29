#!/bin/bash

# 加密Token同步脚本
# 可以将tokens加密存储到云存储，然后在新机器上解密

set -e

ENCRYPTED_FILE="$HOME/.tokens.enc"
CLOUD_URL=""  # 你可以设置一个云存储URL

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

# 加密tokens到文件
encrypt_tokens() {
    local password="$1"
    local tokens_file="$HOME/.env.tokens"
    
    if [[ ! -f "$tokens_file" ]]; then
        print_error "未找到 $tokens_file，请先运行 setup-tokens.sh"
        exit 1
    fi
    
    print_info "加密tokens到 $ENCRYPTED_FILE"
    
    # 使用openssl加密
    openssl enc -aes-256-cbc -salt -in "$tokens_file" -out "$ENCRYPTED_FILE" -pass pass:"$password"
    
    # 设置安全权限
    chmod 600 "$ENCRYPTED_FILE"
    
    print_success "Tokens已加密保存到 $ENCRYPTED_FILE"
}

# 解密tokens文件
decrypt_tokens() {
    local password="$1"
    local tokens_file="$HOME/.env.tokens"
    
    if [[ ! -f "$ENCRYPTED_FILE" ]]; then
        print_error "未找到加密文件 $ENCRYPTED_FILE"
        exit 1
    fi
    
    print_info "解密tokens到 $tokens_file"
    
    # 解密
    if openssl enc -aes-256-cbc -d -in "$ENCRYPTED_FILE" -out "$tokens_file" -pass pass:"$password"; then
        chmod 600 "$tokens_file"
        print_success "Tokens已解密到 $tokens_file"
    else
        print_error "解密失败，请检查密码"
        rm -f "$tokens_file"
        exit 1
    fi
}

# 上传到云存储（示例）
upload_encrypted() {
    if [[ -n "$CLOUD_URL" ]]; then
        print_info "上传加密文件到云存储..."
        # 这里可以使用 rclone, aws s3, gsutil 等工具
        # rclone copy "$ENCRYPTED_FILE" "$CLOUD_URL"
        print_warning "云存储功能需要配置 CLOUD_URL"
    else
        print_warning "未配置云存储，跳过上传"
    fi
}

# 从云存储下载
download_encrypted() {
    if [[ -n "$CLOUD_URL" ]]; then
        print_info "从云存储下载加密文件..."
        # rclone copy "$CLOUD_URL/.tokens.enc" "$HOME/"
        print_warning "云存储功能需要配置 CLOUD_URL"
    else
        print_warning "未配置云存储，跳过下载"
    fi
}

# 使用说明
usage() {
    echo "用法: $0 {encrypt|decrypt|upload|download} [password]"
    echo ""
    echo "命令:"
    echo "  encrypt   - 加密当前的tokens文件"
    echo "  decrypt   - 解密tokens文件"
    echo "  upload    - 上传加密文件到云存储"
    echo "  download  - 从云存储下载加密文件"
    echo ""
    echo "示例:"
    echo "  $0 encrypt mypassword123"
    echo "  $0 decrypt mypassword123"
}

# 主函数
main() {
    local command="$1"
    local password="$2"
    
    case "$command" in
        encrypt)
            if [[ -z "$password" ]]; then
                echo -n "请输入加密密码: "
                read -s password
                echo
            fi
            encrypt_tokens "$password"
            ;;
        decrypt)
            if [[ -z "$password" ]]; then
                echo -n "请输入解密密码: "
                read -s password
                echo
            fi
            decrypt_tokens "$password"
            ;;
        upload)
            upload_encrypted
            ;;
        download)
            download_encrypted
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

main "$@" 