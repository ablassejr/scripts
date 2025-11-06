#!/bin/bash

# Ghostty Installation Script for Fedora
# This script installs Ghostty terminal emulator on Fedora systems

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running on Fedora
if ! grep -q "Fedora" /etc/os-release 2>/dev/null; then
    print_error "This script is designed for Fedora. Detected: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    exit 1
fi

print_status "Starting Ghostty installation for Fedora..."

# Update system
print_status "Updating system packages..."
sudo dnf update -y

# Install build dependencies
print_status "Installing required dependencies..."
sudo dnf install -y \
    git \
    gcc \
    gcc-c++ \
    make \
    cmake \
    pkg-config \
    fontconfig-devel \
    freetype-devel \
    libX11-devel \
    libXcursor-devel \
    libXrandr-devel \
    libXinerama-devel \
    libXi-devel \
    libGL-devel \
    mesa-libEGL-devel \
    wayland-devel \
    wayland-protocols-devel \
    libxkbcommon-devel \
    gtk4-devel \
    adwaita-icon-theme \
    wget \
    curl

# Install Rust if not already installed
if ! command -v rustc &> /dev/null; then
    print_status "Rust not found. Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
else
    print_status "Rust is already installed (version: $(rustc --version))"
fi

# Ensure Rust is in PATH
if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
fi

# Install Zig compiler (required for building Ghostty)
print_status "Checking for Zig compiler..."
if ! command -v zig &> /dev/null; then
    print_status "Installing Zig compiler..."
    ZIG_VERSION="0.11.0"  # Adjust version as needed
    ARCH=$(uname -m)
    
    if [ "$ARCH" = "x86_64" ]; then
        ZIG_ARCH="x86_64"
    elif [ "$ARCH" = "aarch64" ]; then
        ZIG_ARCH="aarch64"
    else
        print_error "Unsupported architecture: $ARCH"
        exit 1
    fi
    
    ZIG_URL="https://ziglang.org/download/${ZIG_VERSION}/zig-linux-${ZIG_ARCH}-${ZIG_VERSION}.tar.xz"
    
    cd /tmp
    wget -q --show-progress "$ZIG_URL" -O zig.tar.xz
    tar -xf zig.tar.xz
    sudo mv zig-linux-${ZIG_ARCH}-${ZIG_VERSION} /opt/zig
    sudo ln -sf /opt/zig/zig /usr/local/bin/zig
    rm zig.tar.xz
    
    print_status "Zig installed successfully"
else
    print_status "Zig is already installed (version: $(zig version))"
fi

# Create installation directory
INSTALL_DIR="$HOME/.local/share/ghostty"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Clone or update Ghostty repository
if [ -d "ghostty" ]; then
    print_status "Updating existing Ghostty repository..."
    cd ghostty
    git pull
else
    print_status "Cloning Ghostty repository..."
    git clone https://github.com/ghostty-org/ghostty.git
    cd ghostty
fi

# Build Ghostty
print_status "Building Ghostty... (this may take several minutes)"
zig build -Doptimize=ReleaseFast

# Install Ghostty
print_status "Installing Ghostty..."

# Copy binary to local bin
mkdir -p "$HOME/.local/bin"
cp zig-out/bin/ghostty "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin/ghostty"

# Create desktop entry
print_status "Creating desktop entry..."
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/ghostty.desktop" << EOF
[Desktop Entry]
Name=Ghostty
Comment=A fast, feature-rich, and cross-platform terminal emulator
Exec=$HOME/.local/bin/ghostty
Icon=utilities-terminal
Type=Application
Categories=System;TerminalEmulator;
Terminal=false
StartupNotify=true
EOF

# Create default configuration directory
print_status "Setting up configuration directory..."
mkdir -p "$HOME/.config/ghostty"

# Create a sample configuration file if it doesn't exist
if [ ! -f "$HOME/.config/ghostty/config" ]; then
    cat > "$HOME/.config/ghostty/config" << EOF
# Ghostty Configuration File
# Uncomment and modify settings as needed

# Font settings
# font-family = "JetBrains Mono"
# font-size = 12

# Theme
# theme = dark

# Window settings
# window-padding-x = 10
# window-padding-y = 10

# Background opacity (0.0 to 1.0)
# background-opacity = 0.95

# Shell
# shell = /bin/bash

# Copy on select
# copy-on-select = true

# Cursor style (block, underline, bar)
# cursor-style = block

# Enable bold text
# bold-is-bright = true

# Window decorations
# window-decoration = true
EOF
    print_status "Created sample configuration at ~/.config/ghostty/config"
fi

# Add ~/.local/bin to PATH if not already there
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    print_status "Adding ~/.local/bin to PATH..."
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    export PATH="$HOME/.local/bin:$PATH"
fi

# Update desktop database
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi

print_status "================================"
print_status "Ghostty installation completed!"
print_status "================================"
echo ""
print_status "Installation details:"
echo "  • Binary location: $HOME/.local/bin/ghostty"
echo "  • Configuration: $HOME/.config/ghostty/config"
echo "  • Desktop entry: $HOME/.local/share/applications/ghostty.desktop"
echo ""
print_status "To start Ghostty:"
echo "  • From terminal: ghostty"
echo "  • From application menu: Look for 'Ghostty'"
echo ""
print_warning "Note: You may need to log out and back in or run 'source ~/.bashrc' for PATH changes to take effect."

# Test if ghostty is accessible
if command -v ghostty &> /dev/null; then
    print_status "Ghostty is ready to use! Version: $(ghostty --version 2>/dev/null || echo 'version info not available')"
else
    print_warning "Please run 'source ~/.bashrc' or restart your terminal to use ghostty command"
fi
