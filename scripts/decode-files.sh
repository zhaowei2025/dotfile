#!/bin/bash

# 文件解码助手脚本
# 支持多种加密格式的解码

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔓 文件解码助手${NC}"
echo

# 使用说明
usage() {
    echo "使用方法："
    echo "  $0 <加密文件路径> [输出文件路径]"
    echo
    echo "支持的格式："
    echo "  - .age (AGE 加密)"
    echo "  - .asc/.gpg (GPG 加密)"
    echo "  - chezmoi 管理的加密文件"
    echo
    echo "示例："
    echo "  $0 encrypted_file.age"
    echo "  $0 encrypted_file.asc decrypted.txt"
    echo "  $0 ~/.local/share/chezmoi/encrypted_private_dot_env.private"
    exit 1
}

# 检查参数
if [[ $# -lt 1 ]]; then
    usage
fi

INPUT_FILE="$1"
OUTPUT_FILE="${2:-}"

# 检查输入文件是否存在
if [[ ! -f "$INPUT_FILE" ]]; then
    echo -e "${RED}错误：文件 '$INPUT_FILE' 不存在${NC}"
    exit 1
fi

# 获取文件扩展名
EXT="${INPUT_FILE##*.}"
echo -e "${YELLOW}检测到文件类型：${NC} .$EXT"

# 解码函数
decode_file() {
    local input="$1"
    local output="$2"
    local method="$3"
    
    echo -e "${BLUE}使用方法：${NC} $method"
    
    case "$method" in
        "chezmoi")
            if [[ -n "$output" ]]; then
                chezmoi decrypt "$input" > "$output"
            else
                chezmoi decrypt "$input"
            fi
            ;;
        "age")
            local identity_file="$HOME/.config/chezmoi/key.txt"
            if [[ -f "$identity_file" ]]; then
                if [[ -n "$output" ]]; then
                    chezmoi age decrypt --identity "$identity_file" "$input" > "$output"
                else
                    chezmoi age decrypt --identity "$identity_file" "$input"
                fi
            else
                echo -e "${RED}错误：找不到 AGE 密钥文件 $identity_file${NC}"
                return 1
            fi
            ;;
        "gpg")
            if [[ -n "$output" ]]; then
                gpg --quiet --decrypt "$input" > "$output"
            else
                gpg --quiet --decrypt "$input"
            fi
            ;;
        *)
            echo -e "${RED}错误：不支持的解码方法${NC}"
            return 1
            ;;
    esac
}

# 根据文件类型选择解码方法
case "$EXT" in
    "age")
        decode_file "$INPUT_FILE" "$OUTPUT_FILE" "age"
        ;;
    "asc"|"gpg")
        decode_file "$INPUT_FILE" "$OUTPUT_FILE" "gpg"
        ;;
    *)
        # 尝试使用 chezmoi 解码
        echo -e "${YELLOW}尝试使用 chezmoi 解码...${NC}"
        decode_file "$INPUT_FILE" "$OUTPUT_FILE" "chezmoi"
        ;;
esac

# 成功消息
if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✓ 解码成功！${NC}"
    if [[ -n "$OUTPUT_FILE" ]]; then
        echo -e "${GREEN}输出文件：${NC} $OUTPUT_FILE"
        echo -e "${BLUE}文件大小：${NC} $(ls -lh "$OUTPUT_FILE" | awk '{print $5}')"
    fi
else
    echo -e "${RED}✗ 解码失败${NC}"
    exit 1
fi 