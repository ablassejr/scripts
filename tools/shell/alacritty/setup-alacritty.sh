#!/bin/bash

#####################################
# Alacritty Setup Script
# Installs and configures Alacritty terminal emulator
#####################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_section() {
    echo -e "\n${BLUE}==== $1 ====${NC}\n"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        DISTRO="unknown"
    fi
}

# Install Alacritty
install_alacritty() {
    print_section "Installing Alacritty"

    if command_exists alacritty; then
        print_info "Alacritty is already installed"
        alacritty --version
        return
    fi

    detect_distro

    case $DISTRO in
        ubuntu|debian)
            # Install from PPA or build from source
            sudo add-apt-repository ppa:aslatter/ppa -y || {
                print_warning "PPA not available, installing from source..."
                install_from_source
                return
            }
            sudo apt update
            sudo apt install -y alacritty
            ;;
        fedora)
            sudo dnf install -y alacritty
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm alacritty
            ;;
        *)
            print_warning "Installing from source..."
            install_from_source
            ;;
    esac

    print_info "Alacritty installed successfully"
}

# Install from source (fallback)
install_from_source() {
    print_info "Building Alacritty from source..."

    # Install Rust if not present
    if ! command_exists cargo; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi

    # Install dependencies
    detect_distro
    case $DISTRO in
        ubuntu|debian)
            sudo apt install -y cmake pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3
            ;;
        fedora)
            sudo dnf install -y cmake freetype-devel fontconfig-devel libxcb-devel libxkbcommon-devel g++
            ;;
    esac

    # Clone and build
    cd /tmp
    git clone https://github.com/alacritty/alacritty.git
    cd alacritty
    cargo build --release

    # Install
    sudo cp target/release/alacritty /usr/local/bin/
    sudo cp extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg
    sudo desktop-file-install extra/linux/Alacritty.desktop
    sudo update-desktop-database

    cd -
    rm -rf /tmp/alacritty
}

# Configure Alacritty
configure_alacritty() {
    print_section "Configuring Alacritty"

    mkdir -p ~/.config/alacritty

    cat > ~/.config/alacritty/alacritty.toml << 'EOF'
# Alacritty Configuration

[window]
padding = { x = 10, y = 10 }
decorations = "full"
opacity = 0.95
dynamic_title = true

[scrolling]
history = 10000
multiplier = 3

[font]
size = 11.0

[font.normal]
family = "FiraCode Nerd Font"
style = "Regular"

[font.bold]
family = "FiraCode Nerd Font"
style = "Bold"

[font.italic]
family = "FiraCode Nerd Font"
style = "Italic"

[font.bold_italic]
family = "FiraCode Nerd Font"
style = "Bold Italic"

[colors]
draw_bold_text_with_bright_colors = true

[colors.primary]
background = "#1e1e1e"
foreground = "#d4d4d4"

[colors.normal]
black   = "#000000"
red     = "#cd3131"
green   = "#0dbc79"
yellow  = "#e5e510"
blue    = "#2472c8"
magenta = "#bc3fbc"
cyan    = "#11a8cd"
white   = "#e5e5e5"

[colors.bright]
black   = "#666666"
red     = "#f14c4c"
green   = "#23d18b"
yellow  = "#f5f543"
blue    = "#3b8eea"
magenta = "#d670d6"
cyan    = "#29b8db"
white   = "#ffffff"

[bell]
animation = "EaseOutExpo"
duration = 0

[selection]
save_to_clipboard = true

[cursor]
style = { shape = "Block", blinking = "On" }
blink_interval = 750

[terminal]
osc52 = "CopyPaste"

[mouse]
hide_when_typing = true

[[keyboard.bindings]]
key = "V"
mods = "Control|Shift"
action = "Paste"

[[keyboard.bindings]]
key = "C"
mods = "Control|Shift"
action = "Copy"

[[keyboard.bindings]]
key = "Plus"
mods = "Control"
action = "IncreaseFontSize"

[[keyboard.bindings]]
key = "Minus"
mods = "Control"
action = "DecreaseFontSize"

[[keyboard.bindings]]
key = "Key0"
mods = "Control"
action = "ResetFontSize"

[[keyboard.bindings]]
key = "N"
mods = "Control|Shift"
action = "CreateNewWindow"
EOF

    print_info "Alacritty configured at ~/.config/alacritty/alacritty.toml"
}

# Set as default terminal
set_default_terminal() {
    print_section "Setting Alacritty as Default Terminal"

    if command_exists update-alternatives; then
        sudo update-alternatives --set x-terminal-emulator $(which alacritty) || print_warning "Could not set as default"
    fi

    # For GNOME
    if command_exists gsettings; then
        gsettings set org.gnome.desktop.default-applications.terminal exec 'alacritty' || true
    fi
}

# Show usage tips
show_tips() {
    print_section "Alacritty Usage Tips"

    cat << 'EOF'
Key Bindings:
  Ctrl+Shift+C                    Copy
  Ctrl+Shift+V                    Paste
  Ctrl++                          Increase font size
  Ctrl+-                          Decrease font size
  Ctrl+0                          Reset font size
  Ctrl+Shift+N                    New window

Configuration:
  Config file: ~/.config/alacritty/alacritty.toml
  Reload: Edit config file (auto-reloads on save)

Themes:
  Browse themes: https://github.com/alacritty/alacritty-theme

Documentation: https://github.com/alacritty/alacritty
EOF
}

main() {
    print_info "Starting Alacritty Setup"
    print_info "======================="

    install_alacritty
    configure_alacritty
    set_default_terminal
    show_tips

    print_info "\n======================="
    print_info "Alacritty setup complete!"
    print_info "Launch with: alacritty"
}

main
