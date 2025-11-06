#!/bin/bash

#####################################
# General Linux Setup Script
# Works across different distributions
# Uses distribution-agnostic installation methods
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

# Install Homebrew (works on Linux)
install_homebrew() {
    print_section "Installing Homebrew"

    if ! command_exists brew; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add to PATH
        if ! grep -q "/home/linuxbrew/.linuxbrew/bin/brew shellenv" ~/.bashrc 2>/dev/null; then
            echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
        fi
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    else
        print_info "Homebrew already installed"
    fi
}

# Install mise (replacement for asdf)
install_mise() {
    print_section "Installing mise"

    if ! command_exists mise; then
        curl https://mise.run | sh
        if ! grep -q "mise activate bash" ~/.bashrc 2>/dev/null; then
            echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
        fi
    else
        print_info "mise already installed"
    fi
}

# Install common CLI tools via mise
install_mise_tools() {
    print_section "Installing Tools via mise"

    if command_exists mise; then
        ~/.local/bin/mise use --global node@lts
        ~/.local/bin/mise use --global python@latest
        ~/.local/bin/mise use --global ruby@latest
        ~/.local/bin/mise use --global rust@latest
    fi
}

# Install fzf
install_fzf() {
    print_section "Installing fzf"

    if [ ! -d "$HOME/.fzf" ]; then
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --all
    else
        print_info "fzf already installed"
    fi
}

# Install zoxide
install_zoxide() {
    print_section "Installing zoxide"

    if ! command_exists zoxide; then
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
        if ! grep -q "zoxide init bash" ~/.bashrc 2>/dev/null; then
            echo 'eval "$(zoxide init bash)"' >> ~/.bashrc
        fi
    else
        print_info "zoxide already installed"
    fi
}

# Install starship prompt
install_starship() {
    print_section "Installing Starship Prompt"

    if ! command_exists starship; then
        curl -sS https://starship.rs/install.sh | sh -s -- -y
        if ! grep -q "starship init bash" ~/.bashrc 2>/dev/null; then
            echo 'eval "$(starship init bash)"' >> ~/.bashrc
        fi
    else
        print_info "Starship already installed"
    fi
}

# Install ble.sh
install_blesh() {
    print_section "Installing ble.sh"

    if [ ! -f "$HOME/.local/share/blesh/ble.sh" ]; then
        git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git /tmp/ble.sh
        make -C /tmp/ble.sh install PREFIX=~/.local
        if ! grep -q "blesh/ble.sh" ~/.bashrc 2>/dev/null; then
            echo 'source ~/.local/share/blesh/ble.sh' >> ~/.bashrc
        fi
        rm -rf /tmp/ble.sh
    else
        print_info "ble.sh already installed"
    fi
}

# Install chezmoi
install_chezmoi() {
    print_section "Installing chezmoi"

    if ! command_exists chezmoi; then
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
    else
        print_info "chezmoi already installed"
    fi
}

# Install yadm
install_yadm() {
    print_section "Installing yadm"

    if ! command_exists yadm; then
        curl -fLo ~/.local/bin/yadm https://github.com/TheLocehiliosan/yadm/raw/master/yadm
        chmod +x ~/.local/bin/yadm
    else
        print_info "yadm already installed"
    fi
}

# Install bat (better cat)
install_bat() {
    print_section "Installing bat"

    if ! command_exists bat && ! command_exists batcat; then
        # Install via GitHub releases
        local tmp_dir=$(mktemp -d)
        cd "$tmp_dir" || return 1
        BAT_VERSION="0.24.0"
        wget https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat-v${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz
        tar xzf bat-v${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz
        sudo cp bat-v${BAT_VERSION}-x86_64-unknown-linux-musl/bat /usr/local/bin/
        cd - > /dev/null
        rm -rf "$tmp_dir"
    else
        print_info "bat already installed"
    fi
}

# Install ripgrep
install_ripgrep() {
    print_section "Installing ripgrep"

    if ! command_exists rg; then
        local tmp_dir=$(mktemp -d)
        cd "$tmp_dir" || return 1
        RG_VERSION="14.0.3"
        wget https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz
        tar xzf ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz
        sudo cp ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl/rg /usr/local/bin/
        cd - > /dev/null
        rm -rf "$tmp_dir"
    else
        print_info "ripgrep already installed"
    fi
}

# Install fd
install_fd() {
    print_section "Installing fd"

    if ! command_exists fd; then
        local tmp_dir=$(mktemp -d)
        cd "$tmp_dir" || return 1
        FD_VERSION="9.0.0"
        wget https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz
        tar xzf fd-v${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz
        sudo cp fd-v${FD_VERSION}-x86_64-unknown-linux-musl/fd /usr/local/bin/
        cd - > /dev/null
        rm -rf "$tmp_dir"
    else
        print_info "fd already installed"
    fi
}

# Install cht.sh
install_chtsh() {
    print_section "Installing cht.sh"

    if [ ! -f "$HOME/.local/bin/cht.sh" ]; then
        mkdir -p ~/.local/bin
        curl -s https://cht.sh/:cht.sh > ~/.local/bin/cht.sh
        chmod +x ~/.local/bin/cht.sh

        # Add to PATH if not there
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && ! grep -q '.local/bin.*PATH' ~/.bashrc 2>/dev/null; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        fi
    else
        print_info "cht.sh already installed"
    fi
}

# Install tldr
install_tldr() {
    print_section "Installing tldr"

    if ! command_exists tldr; then
        npm install -g tldr || print_warning "npm not available. Install Node.js first."
    else
        print_info "tldr already installed"
    fi
}

# Setup Git configuration
setup_git() {
    print_section "Setting up Git Configuration"

    # Set basic config if not already set
    if [ -z "$(git config --global user.name)" ]; then
        echo "Enter your Git username:"
        read git_name
        git config --global user.name "$git_name"
    fi

    if [ -z "$(git config --global user.email)" ]; then
        echo "Enter your Git email:"
        read git_email
        git config --global user.email "$git_email"
    fi

    # Useful git configurations
    git config --global init.defaultBranch main
    git config --global push.autoSetupRemote true
    git config --global pull.rebase false
    git config --global core.editor vim
}

# Create useful aliases
create_aliases() {
    print_section "Creating Useful Aliases"

    cat >> ~/.bash_aliases << 'EOF'
# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Common commands
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gco='git checkout'

# Safety
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Modern alternatives
command -v bat >/dev/null && alias cat='bat'
command -v batcat >/dev/null && alias cat='batcat'
command -v rg >/dev/null && alias grep='rg'
command -v fd >/dev/null && alias find='fd'

EOF

    if ! grep -q ".bash_aliases" ~/.bashrc; then
        echo '[ -f ~/.bash_aliases ] && . ~/.bash_aliases' >> ~/.bashrc
    fi
}

main() {
    print_info "Starting General Linux Setup Script"
    print_info "==================================="

    install_mise
    install_mise_tools
    install_fzf
    install_zoxide
    install_starship
    install_chezmoi
    install_yadm
    install_bat
    install_ripgrep
    install_fd
    install_chtsh
    install_tldr
    setup_git
    create_aliases

    print_info "\n==================================="
    print_info "General setup complete!"
    print_info "Please restart your terminal or run 'source ~/.bashrc' to apply changes."
}

main
