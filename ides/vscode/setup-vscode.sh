#!/bin/bash

#####################################
# VSCode Setup Script
# Installs VSCode and recommended extensions
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

# Install VSCode
install_vscode() {
    print_section "Installing VSCode"

    if command_exists code; then
        print_info "VSCode already installed"
        return
    fi

    detect_distro

    case $DISTRO in
        ubuntu|debian)
            wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
            sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
            sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
            rm -f packages.microsoft.gpg
            sudo apt update
            sudo apt install -y code
            ;;
        fedora)
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
            sudo dnf check-update
            sudo dnf install -y code
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm code
            ;;
        *)
            print_warning "Unknown distribution. Please install VSCode manually from: https://code.visualstudio.com/"
            return
            ;;
    esac
}

# Install essential extensions
install_extensions() {
    print_section "Installing VSCode Extensions"

    if ! command_exists code; then
        print_warning "VSCode not found. Skipping extension installation."
        return
    fi

    # General
    code --install-extension esbenp.prettier-vscode
    code --install-extension dbaeumer.vscode-eslint
    code --install-extension eamodio.gitlens
    code --install-extension ms-vscode.vscode-typescript-next
    code --install-extension formulahendry.auto-rename-tag
    code --install-extension christian-kohler.path-intellisense
    code --install-extension usernamehw.errorlens
    code --install-extension gruntfuggly.todo-tree

    # Python
    code --install-extension ms-python.python
    code --install-extension ms-python.vscode-pylance

    # JavaScript/TypeScript
    code --install-extension dsznajder.es7-react-js-snippets

    # Markdown
    code --install-extension yzhang.markdown-all-in-one

    # Docker
    code --install-extension ms-azuretools.vscode-docker

    # Remote Development
    code --install-extension ms-vscode-remote.remote-ssh
    code --install-extension ms-vscode-remote.remote-containers

    # Git
    code --install-extension mhutchie.git-graph

    # Theme & Icons
    code --install-extension pkief.material-icon-theme
    code --install-extension GitHub.github-vscode-theme

    # AI Assistants
    code --install-extension GitHub.copilot || print_warning "GitHub Copilot requires subscription"

    print_info "Extensions installed successfully"
}

# Configure VSCode settings
configure_vscode() {
    print_section "Configuring VSCode Settings"

    VSCODE_SETTINGS_DIR="$HOME/.config/Code/User"
    mkdir -p "$VSCODE_SETTINGS_DIR"

    cat > "$VSCODE_SETTINGS_DIR/settings.json" << 'EOF'
{
    "editor.fontSize": 14,
    "editor.fontFamily": "'FiraCode Nerd Font', 'Fira Code', 'Courier New', monospace",
    "editor.fontLigatures": true,
    "editor.tabSize": 2,
    "editor.insertSpaces": true,
    "editor.formatOnSave": true,
    "editor.formatOnPaste": true,
    "editor.minimap.enabled": true,
    "editor.lineNumbers": "on",
    "editor.rulers": [80, 120],
    "editor.renderWhitespace": "boundary",
    "editor.bracketPairColorization.enabled": true,
    "editor.guides.bracketPairs": true,
    "editor.cursorBlinking": "smooth",
    "editor.cursorSmoothCaretAnimation": "on",
    "editor.smoothScrolling": true,

    "workbench.colorTheme": "GitHub Dark",
    "workbench.iconTheme": "material-icon-theme",
    "workbench.startupEditor": "welcomePage",

    "terminal.integrated.fontSize": 13,
    "terminal.integrated.fontFamily": "'FiraCode Nerd Font Mono'",
    "terminal.integrated.defaultProfile.linux": "bash",

    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 1000,
    "files.trimTrailingWhitespace": true,
    "files.insertFinalNewline": true,

    "git.autofetch": true,
    "git.confirmSync": false,
    "git.enableSmartCommit": true,

    "explorer.confirmDelete": false,
    "explorer.confirmDragAndDrop": false,

    "prettier.singleQuote": true,
    "prettier.semi": true,
    "prettier.tabWidth": 2,

    "eslint.format.enable": true,

    "python.linting.enabled": true,
    "python.linting.pylintEnabled": true,
    "python.formatting.provider": "black",

    "[javascript]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "[typescript]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "[json]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "[html]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "[css]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "[python]": {
        "editor.defaultFormatter": "ms-python.python"
    }
}
EOF

    print_info "Settings configured at $VSCODE_SETTINGS_DIR/settings.json"
}

# Create keybindings
configure_keybindings() {
    print_section "Configuring Keybindings"

    VSCODE_SETTINGS_DIR="$HOME/.config/Code/User"

    cat > "$VSCODE_SETTINGS_DIR/keybindings.json" << 'EOF'
[
    {
        "key": "ctrl+shift+d",
        "command": "editor.action.duplicateSelection"
    },
    {
        "key": "ctrl+shift+k",
        "command": "editor.action.deleteLines"
    },
    {
        "key": "ctrl+/",
        "command": "editor.action.commentLine"
    }
]
EOF

    print_info "Keybindings configured"
}

main() {
    print_info "Starting VSCode Setup"
    print_info "===================="

    install_vscode
    install_extensions
    configure_vscode
    configure_keybindings

    print_info "\n===================="
    print_info "VSCode setup complete!"
    print_info "Launch with: code"
}

main
