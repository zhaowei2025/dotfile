#!/bin/bash

# Simple Token Setup for Chezmoi Templates
# This script exports environment variables that chezmoi templates can use

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 Chezmoi Token Setup${NC}"
echo "This script will set up environment variables for chezmoi templates."
echo

# Function to read a token securely
read_token() {
    local var_name="$1"
    local description="$2"
    local current_value="${!var_name:-}"
    
    if [[ -n "$current_value" ]]; then
        echo -e "${GREEN}✓${NC} $var_name is already set"
        read -p "Update it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    echo -n "Enter $description: "
    read -s token
    echo
    
    if [[ -n "$token" ]]; then
        export "$var_name"="$token"
        echo -e "${GREEN}✓${NC} $var_name set"
    else
        echo -e "${YELLOW}⚠${NC} $var_name skipped"
    fi
}

# Set up tokens
echo -e "${YELLOW}Setting up API tokens:${NC}"
read_token "ALI_DEEPSEEK_API_KEY" "Ali DeepSeek API Key"
read_token "DEEPSEEK_API_KEY" "DeepSeek API Key"
read_token "ZHIHE_API_KEY" "Zhihe API Key"
read_token "GITHUB_TOKEN" "GitHub Personal Access Token"

echo

# Save to shell profile for persistence
SHELL_RC=""
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_RC="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_RC="$HOME/.bashrc"
fi

if [[ -n "$SHELL_RC" ]]; then
    echo -e "${BLUE}💾 Saving to shell profile...${NC}"
    
    # Create backup
    cp "$SHELL_RC" "$SHELL_RC.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Remove old token exports
    sed -i '/# Chezmoi Token Exports/,/# End Chezmoi Token Exports/d' "$SHELL_RC"
    
    # Add new token exports
    cat >> "$SHELL_RC" << 'EOF'

# Chezmoi Token Exports
EOF
    
    for var in ALI_DEEPSEEK_API_KEY DEEPSEEK_API_KEY ZHIHE_API_KEY GITHUB_TOKEN; do
        if [[ -n "${!var:-}" ]]; then
            echo "export $var=\"${!var}\"" >> "$SHELL_RC"
        fi
    done
    
    cat >> "$SHELL_RC" << 'EOF'
# End Chezmoi Token Exports
EOF
    
    echo -e "${GREEN}✓${NC} Tokens saved to $SHELL_RC"
fi

# Test chezmoi template rendering
echo
echo -e "${BLUE}🧪 Testing chezmoi template rendering...${NC}"
cd ~/.local/share/chezmoi
if chezmoi execute-template < private_dot_env.private.tmpl > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Templates render successfully"
else
    echo -e "${RED}✗${NC} Template rendering failed"
fi

echo
echo -e "${GREEN}🎉 Token setup complete!${NC}"
echo
echo "Next steps:"
echo "1. Reload your shell: source $SHELL_RC"
echo "2. Apply changes: chezmoi apply"
echo "3. Verify: chezmoi status" 