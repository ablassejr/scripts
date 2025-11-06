#!/bin/bash

#####################################
# Micro Editor Setup Script
# Installs and configures Micro text editor
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

# Install Micro
install_micro() {
    print_section "Installing Micro Editor"

    if command_exists micro; then
        print_info "Micro is already installed"
        return
    fi

    local tmp_dir=$(mktemp -d)
    cd "$tmp_dir" || return 1
    curl https://getmic.ro | bash
    sudo mv micro /usr/local/bin/
    cd - > /dev/null
    rm -rf "$tmp_dir"

    print_info "Micro installed successfully"
}

# Configure Micro
configure_micro() {
    print_section "Configuring Micro"

    mkdir -p ~/.config/micro

    cat > ~/.config/micro/settings.json << 'EOF'
{
    "autoindent": true,
    "autosu": true,
    "backup": true,
    "backupdir": "",
    "basename": false,
    "colorscheme": "monokai",
    "cursorline": true,
    "diffgutter": true,
    "encoding": "utf-8",
    "eofnewline": true,
    "fastdirty": false,
    "fileformat": "unix",
    "filetype": "unknown",
    "ignorecase": true,
    "infobar": true,
    "keepautoindent": false,
    "keymenu": false,
    "matchbrace": true,
    "matchbraceleft": false,
    "mkparents": false,
    "mouse": true,
    "paste": false,
    "pluginchannels": [
        "https://raw.githubusercontent.com/micro-editor/plugin-channel/master/channel.json"
    ],
    "pluginrepos": [],
    "readonly": false,
    "rmtrailingws": true,
    "ruler": true,
    "relativeruler": false,
    "savecursor": false,
    "savehistory": true,
    "saveundo": false,
    "scrollbar": true,
    "scrollmargin": 3,
    "scrollspeed": 2,
    "smartpaste": true,
    "softwrap": false,
    "splitbottom": true,
    "splitright": true,
    "statusformatl": "$(filename) $(modified)($(line),$(col)) $(status.paste)| ft:$(opt:filetype) | $(opt:fileformat) | $(opt:encoding)",
    "statusformatr": "$(bind:ToggleKeyMenu): bindings, $(bind:ToggleHelp): help",
    "statusline": true,
    "syntax": true,
    "tabmovement": false,
    "tabsize": 4,
    "tabstospaces": true,
    "termtitle": false,
    "useprimary": true
}
EOF

    print_info "Micro configured at ~/.config/micro/settings.json"
}

# Install plugins
install_plugins() {
    print_section "Installing Micro Plugins"

    if ! command_exists micro; then
        print_warning "Micro not installed. Skipping plugins."
        return
    fi

    print_info "Installing useful plugins..."

    # File manager
    micro -plugin install filemanager

    # Jump to definition
    micro -plugin install jump

    # Syntax highlighting for more languages
    micro -plugin install linter

    # Git integration
    micro -plugin install diff

    # Code comment
    micro -plugin install comment

    print_info "Plugins installed successfully"
}

# Create useful bindings
configure_bindings() {
    print_section "Configuring Key Bindings"

    mkdir -p ~/.config/micro

    cat > ~/.config/micro/bindings.json << 'EOF'
{
    "Ctrl-s": "Save",
    "Ctrl-q": "Quit",
    "Ctrl-z": "Undo",
    "Ctrl-y": "Redo",
    "Ctrl-f": "Find",
    "Ctrl-h": "Replace",
    "Ctrl-d": "DuplicateLine",
    "Ctrl-k": "CutLine",
    "Alt-Up": "MoveLinesUp",
    "Alt-Down": "MoveLinesDown",
    "Ctrl-/": "comment.comment"
}
EOF

    print_info "Key bindings configured"
}

# Set as default editor
set_default_editor() {
    print_section "Setting Micro as Default Editor"

    if ! grep -q "EDITOR=micro" ~/.bashrc; then
        echo 'export EDITOR=micro' >> ~/.bashrc
        echo 'export VISUAL=micro' >> ~/.bashrc
        print_info "Micro set as default editor in ~/.bashrc"
    fi

    if [ -f ~/.zshrc ] && ! grep -q "EDITOR=micro" ~/.zshrc; then
        echo 'export EDITOR=micro' >> ~/.zshrc
        echo 'export VISUAL=micro' >> ~/.zshrc
        print_info "Micro set as default editor in ~/.zshrc"
    fi
}

# Show usage tips
show_tips() {
    print_section "Micro Editor Tips"

    cat << 'EOF'
Basic Usage:
  micro <filename>          Open or create a file
  micro -config-dir         Show config directory location
  micro -plugin list        List installed plugins

Key Bindings:
  Ctrl-q                    Quit
  Ctrl-s                    Save
  Ctrl-z                    Undo
  Ctrl-y                    Redo
  Ctrl-f                    Find
  Ctrl-h                    Replace
  Ctrl-g                    Go to line
  Alt-g                     Show help
  Ctrl-e                    Command prompt

Plugins:
  Ctrl-e plugin install <name>    Install a plugin
  Ctrl-e plugin remove <name>     Remove a plugin
  Ctrl-e plugin list              List plugins

For more information: https://micro-editor.github.io/
EOF
}

main() {
    print_info "Starting Micro Editor Setup"
    print_info "==========================="

    install_micro
    configure_micro
    install_plugins
    configure_bindings
    set_default_editor
    show_tips

    print_info "\n==========================="
    print_info "Micro editor setup complete!"
    print_info "Launch with: micro"
}

main
