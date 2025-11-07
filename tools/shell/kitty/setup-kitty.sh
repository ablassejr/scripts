#!/bin/bash

#####################################
# Kitty Setup Script
# Installs and configures Kitty terminal emulator
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

# Install Kitty
install_kitty() {
    print_section "Installing Kitty"

    if command_exists kitty; then
        print_info "Kitty is already installed"
        kitty --version
        return
    fi

    detect_distro

    case $DISTRO in
        ubuntu|debian|fedora|arch|manjaro)
            # Universal installer
            curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

            # Create symbolic links
            sudo ln -sf "$HOME/.local/kitty.app/bin/kitty" /usr/local/bin/kitty
            sudo ln -sf "$HOME/.local/kitty.app/bin/kitten" /usr/local/bin/kitten

            # Desktop integration
            cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/
            cp ~/.local/kitty.app/share/applications/kitty-open.desktop ~/.local/share/applications/
            sed -i "s|Icon=kitty|Icon=$HOME/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" ~/.local/share/applications/kitty*.desktop
            ;;
        *)
            print_warning "Unknown distribution. Using universal installer..."
            curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
            ;;
    esac

    print_info "Kitty installed successfully"
}

# Configure Kitty
configure_kitty() {
    print_section "Configuring Kitty"

    mkdir -p ~/.config/kitty

    cat > ~/.config/kitty/kitty.conf << 'EOF'
# Kitty Configuration

# Fonts
font_family      FiraCode Nerd Font
bold_font        auto
italic_font      auto
bold_italic_font auto
font_size 11.0

# Cursor
cursor_shape block
cursor_blink_interval 0.5
cursor_stop_blinking_after 15.0

# Scrollback
scrollback_lines 10000
scrollback_pager less --chop-long-lines --RAW-CONTROL-CHARS +INPUT_LINE_NUMBER

# Mouse
mouse_hide_wait 3.0
url_color #0087bd
url_style curly

# Window layout
remember_window_size  yes
initial_window_width  640
initial_window_height 400
window_padding_width 10
window_margin_width 0
placement_strategy center

# Tab bar
tab_bar_edge bottom
tab_bar_margin_width 0.0
tab_bar_style powerline
tab_powerline_style slanted
tab_title_template "{index}: {title}"

# Color scheme (One Dark)
foreground #abb2bf
background #282c34
selection_foreground #282c34
selection_background #abb2bf

# Black
color0  #282c34
color8  #545862

# Red
color1  #e06c75
color9  #e06c75

# Green
color2  #98c379
color10 #98c379

# Yellow
color3  #e5c07b
color11 #e5c07b

# Blue
color4  #61afef
color12 #61afef

# Magenta
color5  #c678dd
color13 #c678dd

# Cyan
color6  #56b6c2
color14 #56b6c2

# White
color7  #abb2bf
color15 #c8ccd4

# Background opacity
background_opacity 0.95
dynamic_background_opacity yes

# Advanced
shell .
editor .
close_on_child_death no
allow_remote_control yes
update_check_interval 0

# OS specific tweaks
linux_display_server auto

# Keyboard shortcuts
map ctrl+shift+c copy_to_clipboard
map ctrl+shift+v paste_from_clipboard
map ctrl+shift+s paste_from_selection
map ctrl+shift+equal change_font_size all +2.0
map ctrl+shift+minus change_font_size all -2.0
map ctrl+shift+backspace change_font_size all 0
map ctrl+shift+t new_tab
map ctrl+shift+q close_tab
map ctrl+shift+right next_tab
map ctrl+shift+left previous_tab
map ctrl+shift+enter new_window
map ctrl+shift+w close_window
map ctrl+shift+n new_os_window
map ctrl+shift+f move_window_forward
map ctrl+shift+b move_window_backward

# Splits
map ctrl+shift+- launch --location=hsplit
map ctrl+shift+\ launch --location=vsplit
map ctrl+shift+[ layout_action decrease_num_full_size_windows
map ctrl+shift+] layout_action increase_num_full_size_windows

# Performance tuning
repaint_delay 10
input_delay 3
sync_to_monitor yes
EOF

    print_info "Kitty configured at ~/.config/kitty/kitty.conf"
}

# Install Kitty themes
install_themes() {
    print_section "Installing Kitty Themes"

    if [ ! -d "$HOME/.config/kitty/kitty-themes" ]; then
        git clone --depth 1 https://github.com/dexpota/kitty-themes.git ~/.config/kitty/kitty-themes
        print_info "Themes installed at ~/.config/kitty/kitty-themes"
        print_info "To use a theme, run: kitty +kitten themes"
    else
        print_info "Themes already installed"
    fi
}

# Set as default terminal
set_default_terminal() {
    print_section "Setting Kitty as Default Terminal"

    if command_exists update-alternatives; then
        sudo update-alternatives --set x-terminal-emulator "$(which kitty)" 2>/dev/null || print_warning "Could not set as default"
    fi

    # For GNOME
    if command_exists gsettings; then
        gsettings set org.gnome.desktop.default-applications.terminal exec 'kitty' 2>/dev/null || true
    fi
}

# Show usage tips
show_tips() {
    print_section "Kitty Usage Tips"

    cat << 'EOF'
Key Bindings:
  Ctrl+Shift+C                    Copy
  Ctrl+Shift+V                    Paste
  Ctrl+Shift++                    Increase font size
  Ctrl+Shift+-                    Decrease font size
  Ctrl+Shift+Backspace            Reset font size
  Ctrl+Shift+T                    New tab
  Ctrl+Shift+Q                    Close tab
  Ctrl+Shift+N                    New window
  Ctrl+Shift+Enter                New OS window
  Ctrl+Shift+-                    Split horizontally
  Ctrl+Shift+\                    Split vertically

Kittens (Plugins):
  kitty +kitten themes            Browse and select themes
  kitty +kitten diff              Side-by-side diff viewer
  kitty +kitten icat              Display images in terminal
  kitty +list-fonts               List available fonts

Configuration:
  Config file: ~/.config/kitty/kitty.conf
  Reload: Ctrl+Shift+F5 or edit config (auto-reloads)

Documentation: https://sw.kovidgoyal.net/kitty/
EOF
}

main() {
    print_info "Starting Kitty Setup"
    print_info "==================="

    install_kitty
    configure_kitty
    install_themes
    set_default_terminal
    show_tips

    print_info "\n==================="
    print_info "Kitty setup complete!"
    print_info "Launch with: kitty"
    print_info "Browse themes with: kitty +kitten themes"
}

main
