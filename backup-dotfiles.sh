#!/bin/bash

# =================================================================
# Dotfiles 备份脚本
# 用途：在执行 chezmoi init --apply 之前备份现有配置
# 使用：chmod +x backup-dotfiles.sh && ./backup-dotfiles.sh
# =================================================================

# 配置
BACKUP_ROOT="$HOME/dotfiles-backup"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 需要备份的文件和目录列表
BACKUP_TARGETS=(
    # 顶级 dotfiles
    "$HOME/.zshrc"
    "$HOME/.gitconfig"
    "$HOME/.env"
    
    # .config 目录下的配置
    "$HOME/.config/nvim"
    "$HOME/.config/bin-tools"
    
    # .local 目录下的内容
    "$HOME/.local/bin"
    "$HOME/.local/share/applications"
    
    # 其他可能的配置文件
    "$HOME/.bashrc"
    "$HOME/.bash_profile"
    "$HOME/.profile"
    "$HOME/.vimrc"
    "$HOME/.tmux.conf"
    "$HOME/.screenrc"
    
    # Git 相关
    "$HOME/.gitignore_global"
    "$HOME/.gitmessage"
    
    # SSH 配置（谨慎备份）
    "$HOME/.ssh/config"
    
    # Shell 历史文件
    "$HOME/.zsh_history"
    "$HOME/.bash_history"
)

# 检查是否有需要备份的文件
check_backup_needed() {
    local found_files=0
    
    print_info "检查需要备份的文件..."
    
    for target in "${BACKUP_TARGETS[@]}"; do
        if [[ -e "$target" ]]; then
            ((found_files++))
            if [[ -d "$target" ]]; then
                print_info "发现目录: $target"
            else
                print_info "发现文件: $target"
            fi
        fi
    done
    
    if [[ $found_files -eq 0 ]]; then
        print_success "没有发现需要备份的文件"
        return 1
    fi
    
    print_warning "发现 $found_files 个需要备份的项目"
    return 0
}

# 创建备份目录
create_backup_dir() {
    print_info "创建备份目录: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR" || {
        print_error "无法创建备份目录: $BACKUP_DIR"
        exit 1
    }
    
    # 创建备份信息文件
    cat > "$BACKUP_DIR/backup-info.txt" << EOF
备份信息
========
备份时间: $(date)
备份用户: $(whoami)
备份主机: $(hostname)
系统信息: $(uname -a)
当前目录: $(pwd)

说明：
此备份是在执行 chezmoi init --apply 之前创建的
备份包含所有可能被 chezmoi 替换的配置文件

恢复方法：
1. 查看 restore-commands.sh 文件中的恢复命令
2. 根据需要选择性恢复特定文件
EOF
}

# 备份文件
backup_files() {
    local backed_up=0
    local skipped=0
    local failed=0
    
    print_info "开始备份文件..."
    
    # 创建恢复脚本
    local restore_script="$BACKUP_DIR/restore-commands.sh"
    cat > "$restore_script" << 'EOF'
#!/bin/bash
# 自动生成的恢复脚本
# 使用方法：选择需要的命令执行

echo "可用的恢复命令："
echo "=================="
EOF
    
    for target in "${BACKUP_TARGETS[@]}"; do
        if [[ -e "$target" ]]; then
            local relative_path="${target#$HOME/}"
            local backup_path="$BACKUP_DIR/$relative_path"
            local backup_parent=$(dirname "$backup_path")
            
            # 创建父目录
            mkdir -p "$backup_parent"
            
            # 备份文件或目录
            if [[ -d "$target" ]]; then
                print_info "备份目录: $target"
                if cp -r "$target" "$backup_parent/" 2>/dev/null; then
                    echo "cp -r \"$backup_path\" \"$target\"" >> "$restore_script"
                    ((backed_up++))
                else
                    print_error "备份失败: $target"
                    ((failed++))
                fi
            elif [[ -f "$target" ]]; then
                print_info "备份文件: $target"
                if cp "$target" "$backup_path" 2>/dev/null; then
                    echo "cp \"$backup_path\" \"$target\"" >> "$restore_script"
                    ((backed_up++))
                else
                    print_error "备份失败: $target"
                    ((failed++))
                fi
            elif [[ -L "$target" ]]; then
                print_info "备份符号链接: $target"
                if cp -P "$target" "$backup_path" 2>/dev/null; then
                    echo "cp -P \"$backup_path\" \"$target\"" >> "$restore_script"
                    ((backed_up++))
                else
                    print_error "备份失败: $target"
                    ((failed++))
                fi
            fi
        else
            ((skipped++))
        fi
    done
    
    chmod +x "$restore_script"
    
    print_success "备份完成: $backed_up 个项目"
    if [[ $skipped -gt 0 ]]; then
        print_info "跳过不存在的文件: $skipped 个"
    fi
    if [[ $failed -gt 0 ]]; then
        print_warning "备份失败: $failed 个项目"
    fi
}

# 创建备份清单
create_manifest() {
    local manifest="$BACKUP_DIR/manifest.txt"
    
    print_info "创建备份清单..."
    
    echo "备份清单 - $(date)" > "$manifest"
    echo "=========================" >> "$manifest"
    echo "" >> "$manifest"
    
    find "$BACKUP_DIR" -type f -not -name "manifest.txt" -not -name "backup-info.txt" -not -name "restore-commands.sh" 2>/dev/null | while read -r file; do
        local relative_file="${file#$BACKUP_DIR/}"
        local original_file="$HOME/$relative_file"
        local file_size=$(stat -c%s "$file" 2>/dev/null || echo "unknown")
        
        echo "文件: $relative_file" >> "$manifest"
        echo "  原始位置: $original_file" >> "$manifest"
        echo "  大小: $file_size bytes" >> "$manifest"
        echo "  备份路径: $file" >> "$manifest"
        echo "" >> "$manifest"
    done
    
    find "$BACKUP_DIR" -type d -not -path "$BACKUP_DIR" 2>/dev/null | while read -r dir; do
        local relative_dir="${dir#$BACKUP_DIR/}"
        local original_dir="$HOME/$relative_dir"
        
        echo "目录: $relative_dir" >> "$manifest"
        echo "  原始位置: $original_dir" >> "$manifest"
        echo "  备份路径: $dir" >> "$manifest"
        echo "" >> "$manifest"
    done
}

# 显示备份统计
show_backup_stats() {
    local total_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
    local file_count=$(find "$BACKUP_DIR" -type f 2>/dev/null | wc -l)
    local dir_count=$(find "$BACKUP_DIR" -type d 2>/dev/null | wc -l)
    
    echo ""
    echo "================================================"
    print_success "备份完成！"
    echo "================================================"
    echo "📁 备份位置: $BACKUP_DIR"
    echo "📊 总大小: $total_size"
    echo "📄 文件数量: $file_count"
    echo "📂 目录数量: $dir_count"
    echo ""
    echo "📋 重要文件:"
    echo "  • backup-info.txt     - 备份信息"
    echo "  • manifest.txt        - 备份清单"
    echo "  • restore-commands.sh - 恢复脚本"
    echo ""
    print_info "现在可以安全地运行："
    echo "  chezmoi init --apply https://github.com/zhaowei2025/dotfile.git"
    echo ""
    print_warning "如需恢复，请查看: $BACKUP_DIR/restore-commands.sh"
}

# 主函数
main() {
    echo "================================================"
    echo "🔄 Dotfiles 备份脚本"
    echo "================================================"
    
    # 检查是否需要备份
    if ! check_backup_needed; then
        exit 0
    fi
    
    # 检查是否强制模式
    local force_mode=false
    if [[ "$1" == "--force" || "$1" == "-f" ]]; then
        force_mode=true
        print_info "强制模式：跳过确认"
    fi
    
    # 询问用户确认
    if [[ "$force_mode" == "false" ]]; then
        echo ""
        read -p "是否继续创建备份？(y/N): " -r REPLY
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "备份已取消"
            exit 0
        fi
    fi
    
    # 执行备份
    create_backup_dir
    backup_files
    create_manifest
    show_backup_stats
    
    print_success "备份脚本执行完成！"
}

# 如果直接执行脚本（不是被 source）
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 