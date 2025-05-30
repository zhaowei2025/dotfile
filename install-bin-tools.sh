#!/bin/bash

# chezmoi run_once script to install binary tools (NO SUDO REQUIRED)
# This script installs all tools to ~/.local/bin without requiring root access

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Setup directories
BIN_DIR="$HOME/.local/bin"
TOOLS_DIR="$HOME/.local/share/tools"
mkdir -p "$BIN_DIR" "$TOOLS_DIR"

print_info "Installing binary tools to $BIN_DIR"

# Detect system architecture
detect_arch() {
    local arch=$(uname -m)
    case $arch in
        x86_64) echo "x86_64" ;;
        aarch64|arm64) echo "aarch64" ;;
        armv7l) echo "armv7" ;;
        *) 
            print_warning "Unknown architecture: $arch"
            echo "x86_64"  # fallback
            ;;
    esac
}

# Map architecture for specific tools
map_arch_for_tool() {
    local tool="$1"
    local arch="$2"
    
    case "$tool" in
        fzf)
            case "$arch" in
                x86_64) echo "amd64" ;;
                aarch64) echo "arm64" ;;
                *) echo "$arch" ;;
            esac
            ;;
        *)
            echo "$arch"
            ;;
    esac
}

ARCH=$(detect_arch)
print_info "Detected architecture: $ARCH"

# Check if we have sudo (but don't require it)
HAS_SUDO=false
if sudo -n true 2>/dev/null; then
    HAS_SUDO=true
    print_info "Sudo access detected (optional)"
else
    print_info "No sudo access - using user-space installation"
fi

# Function to install from package manager (if sudo available)
try_package_install() {
    local tool_name="$1"
    local package_name="${2:-$tool_name}"
    
    if [[ "$HAS_SUDO" != "true" ]]; then
        return 1
    fi
    
    if command -v "$tool_name" >/dev/null 2>&1; then
        return 0
    fi
    
    print_info "Trying package manager for $tool_name..."
    
    if command -v apt >/dev/null 2>&1; then
        case "$tool_name" in
            fd) package_name="fd-find" ;;
            rg) package_name="ripgrep" ;;
            bat) package_name="bat" ;;
        esac
        
        if sudo apt update -qq && sudo apt install -y "$package_name" >/dev/null 2>&1; then
            # Handle Ubuntu naming quirks
            if [[ "$tool_name" == "fd" && ! -f "$BIN_DIR/fd" ]]; then
                ln -sf "$(which fd-find)" "$BIN_DIR/fd" 2>/dev/null || true
            fi
            if [[ "$tool_name" == "bat" && ! -f "$BIN_DIR/bat" && -x "$(which batcat)" ]]; then
                ln -sf "$(which batcat)" "$BIN_DIR/bat" 2>/dev/null || true
            fi
            return 0
        fi
    fi
    
    return 1
}

# Function to install via Cargo
try_cargo_install() {
    local tool_name="$1"
    local crate_name="${2:-$tool_name}"
    
    if ! command -v cargo >/dev/null 2>&1; then
        return 1
    fi
    
    if command -v "$tool_name" >/dev/null 2>&1; then
        return 0
    fi
    
    print_info "Installing $tool_name via Cargo..."
    
    # Map tool names to crate names
    case "$tool_name" in
        fd) crate_name="fd-find" ;;
        rg) crate_name="ripgrep" ;;
        btm) crate_name="bottom" ;;
        dust) crate_name="du-dust" ;;
    esac
    
    if cargo install "$crate_name" >/dev/null 2>&1; then
        print_success "$tool_name installed via Cargo"
        return 0
    fi
    
    return 1
}

# Function to download and extract from archive
install_from_github() {
    local tool_name="$1"
    local version="$2"
    local url_template="$3"
    local extract_path="$4"
    local binary_name="${5:-$tool_name}"
    
    local target_path="$BIN_DIR/$tool_name"
    
    if [[ -f "$target_path" ]]; then
        print_info "$tool_name already exists, skipping..."
        return 0
    fi
    
    # Get the correct architecture for this tool
    local tool_arch=$(map_arch_for_tool "$tool_name" "$ARCH")
    
    # Replace variables in URL template and extract path
    local url="${url_template//\{version\}/$version}"
    url="${url//\{arch\}/$tool_arch}"
    
    # Replace variables in extract path
    local actual_extract_path="${extract_path//\{version\}/$version}"
    actual_extract_path="${actual_extract_path//\{arch\}/$tool_arch}"
    
    print_info "Installing $tool_name from GitHub..."
    print_info "URL: $url"
    print_info "Extract path: $actual_extract_path"
    
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    local install_success=false
    
    # Download and extract
    if [[ "$url" == *.tar.gz ]] || [[ "$url" == *.tgz ]]; then
        if ! curl -L --progress-bar --show-error "$url" | tar -xz; then
            print_error "Failed to download/extract $tool_name"
            cd - > /dev/null
            rm -rf "$temp_dir"
            return 1
        fi
    elif [[ "$url" == *.tar.xz ]]; then
        if ! curl -L --progress-bar --show-error "$url" | tar -xJ; then
            print_error "Failed to download/extract $tool_name"
            cd - > /dev/null
            rm -rf "$temp_dir"
            return 1
        fi
    elif [[ "$url" == *.zip ]]; then
        if ! curl -L --progress-bar --show-error "$url" -o archive.zip; then
            print_error "Failed to download $tool_name"
            cd - > /dev/null
            rm -rf "$temp_dir"
            return 1
        fi
        unzip -q archive.zip
        rm archive.zip
    elif [[ "$url" == *.AppImage ]]; then
        if ! curl -L --progress-bar --show-error "$url" -o "$binary_name.AppImage"; then
            print_error "Failed to download $tool_name"
            cd - > /dev/null
            rm -rf "$temp_dir"
            return 1
        fi
        chmod +x "$binary_name.AppImage"
        # Extract AppImage if possible
        if ./"$binary_name.AppImage" --appimage-extract >/dev/null 2>&1; then
            print_info "AppImage extracted successfully"
            # If squashfs-root exists, move it to tools directory and create symlink
            if [[ -d "squashfs-root" ]]; then
                local tool_dir="$TOOLS_DIR/$tool_name-$version"
                rm -rf "$tool_dir" 2>/dev/null || true
                mv squashfs-root "$tool_dir"
                ln -sf "$tool_dir/AppRun" "$target_path"
                print_success "Created symlink for $tool_name AppImage"
                install_success=true
            fi
        fi
        rm -f "$binary_name.AppImage"
    fi
    
    # If AppImage installation was successful, clean up and return
    if [[ "$install_success" == "true" ]]; then
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 0
    fi
    
    # Find and copy the binary
    if [[ -f "$actual_extract_path" ]]; then
        cp "$actual_extract_path" "$target_path"
        chmod +x "$target_path"
        print_success "$tool_name installed successfully"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 0
    else
        print_error "Binary not found at expected path: $actual_extract_path"
        # Try to find the binary
        local found_binary
        if found_binary=$(find . -type f -name "$binary_name" -executable -print -quit); then
            if [[ -n "$found_binary" ]]; then
                cp "$found_binary" "$target_path"
                chmod +x "$target_path"
                print_success "$tool_name installed successfully (found at: $found_binary)"
                cd - > /dev/null
                rm -rf "$temp_dir"
                return 0
            fi
        fi
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
}

# Function to handle existing squashfs-root directories
handle_squashfs_root() {
    local tool_name="$1"
    local version="$2"
    local squashfs_path="$3"
    
    if [[ ! -d "$squashfs_path" ]]; then
        print_error "squashfs-root directory not found at: $squashfs_path"
        return 1
    fi
    
    local tool_dir="$TOOLS_DIR/$tool_name-$version"
    local target_path="$BIN_DIR/$tool_name"
    
    print_info "Processing squashfs-root for $tool_name..."
    
    # Move squashfs-root to tools directory
    rm -rf "$tool_dir" 2>/dev/null || true
    mv "$squashfs_path" "$tool_dir"
    
    # Create symlink to AppRun or main executable
    if [[ -f "$tool_dir/AppRun" ]]; then
        ln -sf "$tool_dir/AppRun" "$target_path"
    elif [[ -f "$tool_dir/usr/bin/$tool_name" ]]; then
        ln -sf "$tool_dir/usr/bin/$tool_name" "$target_path"
    else
        # Try to find the executable
        local found_binary
        if found_binary=$(find "$tool_dir" -type f -name "$tool_name" -executable -print -quit); then
            if [[ -n "$found_binary" ]]; then
                ln -sf "$found_binary" "$target_path"
            else
                print_error "Could not find executable in squashfs-root"
                return 1
            fi
        fi
    fi
    
    print_success "Created symlink for $tool_name from squashfs-root"
    return 0
}

# Function to install AppImage
install_appimage() {
    local tool_name="$1"
    local url="$2"
    local version="${3:-latest}"
    
    local target_path="$BIN_DIR/$tool_name"
    
    if [[ -f "$target_path" ]]; then
        print_info "$tool_name already exists, skipping..."
        return 0
    fi
    
    print_info "Installing $tool_name AppImage..."
    
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Download AppImage
    if ! curl -L --progress-bar --show-error "$url" -o "${tool_name}.appimage"; then
        print_error "Failed to download $tool_name"
        return 1
    fi
    
    chmod +x "${tool_name}.appimage"
    
    # Extract AppImage to avoid FUSE issues
    print_info "Extracting AppImage..."
    if ./"${tool_name}.appimage" --appimage-extract >/dev/null 2>&1; then
        # Create extraction directory
        local extract_dir="$TOOLS_DIR/${tool_name}_extracted"
        rm -rf "$extract_dir"
        mv squashfs-root "$extract_dir"
        
        # Create wrapper script
        cat > "$target_path" << EOF
#!/bin/bash
exec "$extract_dir/usr/bin/$tool_name" "\$@"
EOF
        chmod +x "$target_path"
        print_success "Installed $tool_name (AppImage extracted)"
    else
        # Fallback: just copy the AppImage
        cp "${tool_name}.appimage" "$target_path"
        print_success "Installed $tool_name (AppImage)"
    fi
    
    cd - > /dev/null
    rm -rf "$temp_dir"
}

# Function to install a tool with multiple fallback methods
install_tool() {
    local tool_name="$1"
    shift
    
    print_info "Installing $tool_name..."
    
    # Check if already installed globally
    if command -v "$tool_name" >/dev/null 2>&1 && [[ ! -f "$BIN_DIR/$tool_name" ]]; then
        print_info "$tool_name already available globally"
        return 0
    fi
    
    # Method 1: Try package manager
    if try_package_install "$@"; then
        return 0
    fi
    
    # Method 2: Try Cargo
    if try_cargo_install "$@"; then
        return 0
    fi
    
    # Method 3: Install from GitHub (passed as additional arguments)
    if [[ $# -ge 4 ]]; then
        if install_from_github "$@"; then
            return 0
        fi
    fi
    
    print_warning "Failed to install $tool_name"
    return 1
}

# Install tools based on configuration
print_info "Starting installation of all tools..."

# Modern CLI tools
install_tool "fd" "fd-find" "v10.2.0" \
    "https://github.com/sharkdp/fd/releases/download/{version}/fd-{version}-{arch}-unknown-linux-musl.tar.gz" \
    "fd-{version}-{arch}-unknown-linux-musl/fd"

install_tool "rg" "ripgrep" "14.1.1" \
    "https://github.com/BurntSushi/ripgrep/releases/download/{version}/ripgrep-{version}-{arch}-unknown-linux-musl.tar.gz" \
    "ripgrep-{version}-{arch}-unknown-linux-musl/rg"

install_tool "bat" "bat" "v0.25.0" \
    "https://github.com/sharkdp/bat/releases/download/{version}/bat-{version}-{arch}-unknown-linux-musl.tar.gz" \
    "bat-{version}-{arch}-unknown-linux-musl/bat"

install_tool "eza" "eza" "v0.21.3" \
    "https://github.com/eza-community/eza/releases/download/{version}/eza_{arch}-unknown-linux-musl.tar.gz" \
    "eza"

install_tool "btm" "bottom" "0.10.2" \
    "https://github.com/ClementTsang/bottom/releases/download/{version}/bottom_{arch}-unknown-linux-gnu.tar.gz" \
    "btm"

install_tool "dust" "dust" "v1.1.1" \
    "https://github.com/bootandy/dust/releases/download/{version}/dust-{version}-{arch}-unknown-linux-gnu.tar.gz" \
    "dust-{version}-{arch}-unknown-linux-gnu/dust"

install_tool "fzf" "fzf" "v0.62.0" \
    "https://github.com/junegunn/fzf/releases/download/{version}/fzf-0.62.0-linux_{arch}.tar.gz" \
    "fzf"

# Development tools
print_info "Installing development tools..."

# Neovim
if [[ ! -f "$BIN_DIR/nvim" ]]; then
    install_appimage "nvim" "https://github.com/neovim/neovim/releases/latest/download/nvim.appimage"
else
    print_info "nvim already exists, skipping..."
fi

# clangd
if [[ ! -f "$BIN_DIR/clangd" ]]; then
    print_info "Installing clangd..."
    CLANGD_VERSION="19.1.2"
    CLANGD_URL="https://github.com/clangd/clangd/releases/download/${CLANGD_VERSION}/clangd-linux-${CLANGD_VERSION}.zip"
    CLANGD_DIR="$HOME/.local/clangd/clangd_${CLANGD_VERSION}"
    
    mkdir -p "$CLANGD_DIR"
    temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    if curl -L --progress-bar --show-error "$CLANGD_URL" -o clangd.zip; then
        unzip -q clangd.zip
        if command -v rsync >/dev/null 2>&1; then
            rsync -a "clangd_${CLANGD_VERSION}/" "$CLANGD_DIR/"
        else
            cp -rf "clangd_${CLANGD_VERSION}"/* "$CLANGD_DIR/"
        fi
        ln -sf "$CLANGD_DIR/bin/clangd" "$BIN_DIR/clangd"
        print_success "Installed clangd"
    else
        print_error "Failed to download clangd"
    fi
    
    cd - > /dev/null
    rm -rf "$temp_dir"
else
    print_info "clangd already exists, skipping..."
fi

# lazygit
install_tool "lazygit" "lazygit" "v0.51.1" \
    "https://github.com/jesseduffield/lazygit/releases/download/{version}/lazygit_0.51.1_Linux_x86_64.tar.gz" \
    "lazygit"

# Ensure PATH is properly set
print_info "Configuring PATH..."
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    export PATH="$BIN_DIR:$PATH"
    print_info "Added $BIN_DIR to PATH for current session"
fi

# Install Oh My Zsh and plugins if not present
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    print_info "Installing Oh My Zsh..."
    
    # Save current ZSH value and unset it for installation
    old_zsh="$ZSH"
    unset ZSH
    
    # Create a temporary directory for installation
    temp_install_dir=$(mktemp -d)
    cd "$temp_install_dir"
    
    # Download and run the installer in the temp directory
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh > install.sh
    elif command -v wget >/dev/null 2>&1; then
        wget -q https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O install.sh
    fi
    
    # Make the installer executable
    chmod +x install.sh
    
    # Run the installer with custom options
    ZSH="$HOME/.oh-my-zsh" KEEP_ZSHRC=yes RUNZSH=no CHSH=no sh install.sh
    
    # Clean up
    cd - > /dev/null
    rm -rf "$temp_install_dir"
    
    # Restore ZSH value if it was set
    if [[ -n "$old_zsh" ]]; then
        export ZSH="$old_zsh"
    fi
    
    # Install plugins
    ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
    
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    fi
    
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    fi
    
    if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
    fi
    
    print_success "Oh My Zsh and plugins installed"
fi

# Install FZF key bindings
if command -v fzf >/dev/null 2>&1; then
    if [[ ! -d "$HOME/.fzf" ]]; then
        print_info "Setting up FZF key bindings..."
        git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
        "$HOME/.fzf/install" --all --no-bash --no-fish
    fi
fi

print_success "All tools installation completed!"

# Report installation status
echo ""
echo "🎉 Installation Summary:"
echo ""

tools_to_check=(
    "fd:Better find"
    "rg:Better grep"
    "bat:Better cat"
    "eza:Better ls"
    "btm:Better top"
    "dust:Better du"
    "fzf:Fuzzy finder"
    "nvim:Neovim editor"
    "clangd:C/C++ LSP"
    "lazygit:Git TUI"
)

for tool_info in "${tools_to_check[@]}"; do
    IFS=':' read -r tool desc <<< "$tool_info"
    if command -v "$tool" >/dev/null 2>&1; then
        version=$(command "$tool" --version 2>/dev/null | head -1 | cut -d' ' -f2 || echo "installed")
        echo "✅ $desc ($tool) - $version"
    else
        echo "❌ $desc ($tool) - not found"
    fi
done

echo ""
echo "💡 Installation methods used:"
if [[ "$HAS_SUDO" == "true" ]]; then
    echo "• Package manager (with sudo)"
fi
if command -v cargo >/dev/null 2>&1; then
    echo "• Cargo (Rust package manager)"
fi
echo "• GitHub releases (user-space binaries)"
echo ""

echo "🚀 Next steps:"
echo "• Restart your terminal or run 'source ~/.zshrc'"
echo "• All tools are available in ~/.local/bin"
echo "• Enhanced zsh features are ready to use"
echo ""

if [[ "$HAS_SUDO" != "true" ]]; then
    echo "💡 No sudo required! All tools installed to user directories"
    echo ""
fi

print_success "Setup complete! 🎉" 