#!/bin/bash

# 一键安装和配置开发环境脚本
# 使用方法: curl -fsSL https://raw.githubusercontent.com/zhaowei2025/dotfile/main/scripts/install.sh | bash

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

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查并安装基础工具
install_dependencies() {
    print_step "安装基础依赖..."
    
    if command -v apt > /dev/null; then
        sudo apt update
        sudo apt install -y git curl wget zsh
    elif command -v yum > /dev/null; then
        sudo yum install -y git curl wget zsh
    elif command -v pacman > /dev/null; then
        sudo pacman -S --noconfirm git curl wget zsh
    else
        print_error "不支持的包管理器"
        exit 1
    fi
    
    print_success "基础依赖安装完成"
}

# 安装 chezmoi
install_chezmoi() {
    print_step "安装 chezmoi..."
    
    if ! command -v chezmoi > /dev/null; then
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    print_success "chezmoi 安装完成"
}

# 初始化 dotfiles
init_dotfiles() {
    print_step "初始化 dotfiles..."
    
    # 如果已存在，备份
    if [ -d "$HOME/.local/share/chezmoi" ]; then
        print_warning "检测到现有配置，正在备份..."
        mv "$HOME/.local/share/chezmoi" "$HOME/.local/share/chezmoi.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # 使用 GitHub token 初始化
    if [ -n "$GITHUB_TOKEN" ]; then
        print_step "使用 GitHub token 初始化..."
        chezmoi init https://${GITHUB_TOKEN}@github.com/zhaowei2025/dotfile.git
    else
        print_step "使用 HTTPS 初始化..."
        chezmoi init https://github.com/zhaowei2025/dotfile.git
    fi
    
    print_success "dotfiles 初始化完成"
}

# 应用配置
apply_config() {
    print_step "应用配置..."
    
    chezmoi apply
    
    print_success "配置应用完成"
}

# 配置 Git
setup_git() {
    print_step "配置 Git..."
    
    # 设置 Git 凭据存储
    git config --global credential.helper store
    
    # 如果有 token，配置仓库使用 token
    if [ -n "$GITHUB_TOKEN" ]; then
        cd ~/.local/share/chezmoi
        git remote set-url origin https://${GITHUB_TOKEN}@github.com/zhaowei2025/dotfile.git
        cd -
    fi
    
    print_success "Git 配置完成"
}

# 切换到 zsh
setup_zsh() {
    print_step "设置 zsh 为默认 shell..."
    
    if [ "$SHELL" != "$(which zsh)" ]; then
        print_warning "将要切换默认 shell 到 zsh，需要输入密码"
        chsh -s $(which zsh)
        print_success "zsh 设置完成，请重新登录以生效"
    else
        print_success "zsh 已是默认 shell"
    fi
}

# 显示完成信息
show_completion() {
    echo
    echo -e "${GREEN}🎉 开发环境安装完成！${NC}"
    echo
    echo -e "${BLUE}📋 下一步：${NC}"
    echo "1. 重新登录或运行: exec zsh"
    echo "2. 使用快捷命令:"
    echo "   • dfpush '消息' - 推送配置到 GitHub"
    echo "   • dfpull - 从 GitHub 拉取配置"
    echo "   • dfstatus - 查看配置状态"
    echo "   • pon/poff - 开启/关闭代理"
    echo "   • gwork/gpersonal - 切换 Git 账户"
    echo
    echo -e "${YELLOW}💡 提示：${NC}"
    echo "• 编辑配置: chezmoi edit ~/.zshrc"
    echo "• 应用更改: chezmoi apply"
    echo "• 查看状态: chezmoi status"
}

# 主安装流程
main() {
    echo -e "${BLUE}"
    echo "🚀 开发环境一键安装脚本"
    echo "============================="
    echo -e "${NC}"
    
    install_dependencies
    install_chezmoi
    init_dotfiles
    apply_config
    setup_git
    setup_zsh
    show_completion
}

# 如果脚本被直接执行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 