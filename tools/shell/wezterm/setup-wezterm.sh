#!/bin/bash

#####################################
# WezTerm Setup Script
# Installs and configures WezTerm terminal emulator
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

# Install WezTerm
install_wezterm() {
    print_section "Installing WezTerm"

    if command_exists wezterm; then
        print_info "WezTerm is already installed"
        wezterm --version
        return
    fi

    detect_distro

    case $DISTRO in
        ubuntu|debian)
            curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
            echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list
            sudo apt update
            sudo apt install -y wezterm
            ;;
        fedora)
            sudo dnf install -y https://github.com/wez/wezterm/releases/download/nightly/wezterm-nightly-fedora$(rpm -E %{fedora}).rpm
            ;;
        arch|manjaro)
            if command_exists yay; then
                yay -S --noconfirm wezterm
            else
                print_warning "yay not found. Please install WezTerm manually."
                return
            fi
            ;;
        *)
            print_warning "Unknown distribution. Downloading from GitHub..."
            cd /tmp
            wget https://github.com/wez/wezterm/releases/download/nightly/WezTerm-nightly-Ubuntu20.04.AppImage
            chmod +x WezTerm-nightly-Ubuntu20.04.AppImage
            sudo mv WezTerm-nightly-Ubuntu20.04.AppImage /usr/local/bin/wezterm
            cd -
            ;;
    esac

    print_info "WezTerm installed successfully"
}

# Configure WezTerm
configure_wezterm() {
    print_section "Configuring WezTerm"

    mkdir -p ~/.config/wezterm

    cat > ~/.config/wezterm/wezterm.lua << 'EOF'
-- WezTerm Configuration
local wezterm = require 'wezterm'
local config = {}

-- Use config builder for newer versions
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- Color scheme
config.color_scheme = 'OneDark (base16)'

-- Font configuration
config.font = wezterm.font('FiraCode Nerd Font', { weight = 'Regular' })
config.font_size = 11.0
config.line_height = 1.1

-- Window configuration
config.window_padding = {
  left = 10,
  right = 10,
  top = 10,
  bottom = 10,
}
config.window_background_opacity = 0.95
config.text_background_opacity = 1.0
config.window_decorations = "RESIZE"

-- Tab bar
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = true
config.tab_bar_at_bottom = false
config.tab_max_width = 32

-- Scrollback
config.scrollback_lines = 10000

-- Performance
config.animation_fps = 60
config.max_fps = 60

-- Cursor
config.default_cursor_style = 'BlinkingBlock'
config.cursor_blink_rate = 800
config.cursor_blink_ease_in = 'Constant'
config.cursor_blink_ease_out = 'Constant'

-- Bell
config.audible_bell = 'Disabled'
config.visual_bell = {
  fade_in_function = 'EaseIn',
  fade_in_duration_ms = 150,
  fade_out_function = 'EaseOut',
  fade_out_duration_ms = 150,
}

-- Key bindings
config.keys = {
  -- Splitting
  {
    key = '|',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  {
    key = '_',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  -- Pane navigation
  {
    key = 'LeftArrow',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ActivatePaneDirection 'Left',
  },
  {
    key = 'RightArrow',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ActivatePaneDirection 'Right',
  },
  {
    key = 'UpArrow',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ActivatePaneDirection 'Up',
  },
  {
    key = 'DownArrow',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ActivatePaneDirection 'Down',
  },
  -- Close pane
  {
    key = 'w',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.CloseCurrentPane { confirm = true },
  },
  -- Font size
  {
    key = '+',
    mods = 'CTRL',
    action = wezterm.action.IncreaseFontSize,
  },
  {
    key = '-',
    mods = 'CTRL',
    action = wezterm.action.DecreaseFontSize,
  },
  {
    key = '0',
    mods = 'CTRL',
    action = wezterm.action.ResetFontSize,
  },
  -- Copy/Paste
  {
    key = 'c',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.CopyTo 'Clipboard',
  },
  {
    key = 'v',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.PasteFrom 'Clipboard',
  },
}

-- Mouse bindings
config.mouse_bindings = {
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'CTRL',
    action = wezterm.action.OpenLinkAtMouseCursor,
  },
}

-- Hyperlink rules
config.hyperlink_rules = {
  -- URLs
  {
    regex = '\\b\\w+://[\\w.-]+\\S*\\b',
    format = '$0',
  },
  -- Email addresses
  {
    regex = '\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b',
    format = 'mailto:$0',
  },
  -- File paths
  {
    regex = '\\b[./~][\\w./-]+\\b',
    format = '$0',
  },
}

return config
EOF

    print_info "WezTerm configured at ~/.config/wezterm/wezterm.lua"
}

# Show usage tips
show_tips() {
    print_section "WezTerm Usage Tips"

    cat << 'EOF'
Key Bindings:
  Ctrl+Shift+C                    Copy
  Ctrl+Shift+V                    Paste
  Ctrl++                          Increase font size
  Ctrl+-                          Decrease font size
  Ctrl+0                          Reset font size
  Ctrl+Shift+|                    Split horizontally
  Ctrl+Shift+_                    Split vertically
  Ctrl+Shift+W                    Close pane
  Ctrl+Shift+Arrow                Navigate panes
  Ctrl+Shift+T                    New tab
  Ctrl+Shift+Tab                  Switch tabs

Configuration:
  Config file: ~/.config/wezterm/wezterm.lua
  Reload: Config auto-reloads on save

Features:
  - GPU-accelerated rendering
  - Ligature support
  - Multiplexing (built-in tmux-like)
  - Image protocol support
  - Hyperlink detection

Documentation: https://wezfurlong.org/wezterm/
EOF
}

main() {
    print_info "Starting WezTerm Setup"
    print_info "====================="

    install_wezterm
    configure_wezterm
    show_tips

    print_info "\n====================="
    print_info "WezTerm setup complete!"
    print_info "Launch with: wezterm"
}

main
