#!/bin/bash

# chezmoi run_onchange script to update binary tools when versions.toml changes
# This script runs when the versions.toml file is modified

# versions.toml hash: {{ include "dot_config/bin-tools/versions.toml" | sha256sum }}

set -euo pipefail

BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/bin-tools"
BACKUP_DIR="$HOME/.local/backup/bin-tools"

echo "🔄 Binary tools configuration has changed, updating..."
echo "📅 $(date '+%Y-%m-%d %H:%M:%S')"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Function to backup existing binary
backup_binary() {
    local name="$1"
    local target_path="$BIN_DIR/$name"
    
    if [[ -f "$target_path" ]] || [[ -L "$target_path" ]]; then
        local backup_path="$BACKUP_DIR/${name}.backup.$(date +%Y%m%d_%H%M%S)"
        echo "📦 Backing up existing $name to $backup_path"
        cp "$target_path" "$backup_path" 2>/dev/null || true
    fi
}

# Function to restore binary from backup if update fails
restore_binary() {
    local name="$1"
    local target_path="$BIN_DIR/$name"
    local backup_file=$(ls "$BACKUP_DIR/${name}.backup."* 2>/dev/null | tail -n1 || echo "")
    
    if [[ -n "$backup_file" && -f "$backup_file" ]]; then
        echo "🔄 Restoring $name from backup..."
        cp "$backup_file" "$target_path"
        chmod +x "$target_path"
    fi
}

# Function to clean old backups (keep only latest 5)
cleanup_backups() {
    local name="$1"
    
    # Remove old backups, keep only the latest 5
    ls -t "$BACKUP_DIR/${name}.backup."* 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true
}

# Detect tools that need updating by checking if they exist
echo "🔍 Checking which tools need updating..."

tools_to_update=()
for tool in fd rg nvim clangd lazygit; do
    if [[ ! -f "$BIN_DIR/$tool" ]] && [[ ! -L "$BIN_DIR/$tool" ]]; then
        echo "❌ $tool: missing, will install"
        tools_to_update+=("$tool")
    else
        echo "✅ $tool: present, will update if needed"
        backup_binary "$tool"
        tools_to_update+=("$tool")
    fi
done

if [[ ${#tools_to_update[@]} -eq 0 ]]; then
    echo "ℹ️  No tools need updating"
else
    echo "🔧 Tools to process: ${tools_to_update[*]}"
    
    # Force reinstall by removing the tools temporarily
    echo "⚡ Triggering reinstallation..."
    for tool in "${tools_to_update[@]}"; do
        rm -f "$BIN_DIR/$tool"
    done
fi

echo "✅ Binary tools update check completed!"
echo "💡 Tools will be reinstalled when chezmoi finishes applying changes"

# Clean old backups for all tools
for tool in fd rg nvim clangd lazygit; do
    cleanup_backups "$tool"
done

echo "🧹 Cleaned old backups" 