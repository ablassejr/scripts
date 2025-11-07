#!/bin/bash

#####################################
# macOS Homebrew Setup Script
# Installs Homebrew and common packages
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

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_section() {
    echo -e "\n${BLUE}==== $1 ====${NC}\n"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if running on macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script is for macOS only!"
        exit 1
    fi
}

# Install Homebrew
install_homebrew() {
    print_section "Installing Homebrew"

    if command_exists brew; then
        print_info "Homebrew is already installed"
        brew --version
        return
    fi

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH
    if [[ $(uname -m) == "arm64" ]]; then
        # Apple Silicon
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        # Intel
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    print_info "Homebrew installed successfully"
}

# Update Homebrew
update_homebrew() {
    print_section "Updating Homebrew"
    brew update
    brew upgrade
}

# Install essential formulae
install_essentials() {
    print_section "Installing Essential Formulae"

    brew install git
    brew install wget
    brew install curl
    brew install tree
    brew install htop
    brew install jq
    brew install vim
    brew install neovim
    brew install tmux
    brew install zsh
    brew install fzf
    brew install ripgrep
    brew install fd
    brew install bat
    brew install exa
    brew install zoxide
    brew install starship
}

# Install development tools
install_dev_tools() {
    print_section "Installing Development Tools"

    # Version managers
    brew install mise

    # Programming languages
    brew install node
    brew install python3
    brew install go
    brew install rust

    # Database clients
    brew install postgresql
    brew install redis
    brew install mysql-client

    # Docker
    brew install --cask docker
}

# Install GUI applications
install_gui_apps() {
    print_section "Installing GUI Applications"

    print_info "Select applications to install:"

    read -p "Install VSCode? (y/n): " vscode
    [[ "$vscode" == "y" ]] && brew install --cask visual-studio-code

    read -p "Install iTerm2? (y/n): " iterm
    [[ "$iterm" == "y" ]] && brew install --cask iterm2

    read -p "Install Alacritty? (y/n): " alacritty
    [[ "$alacritty" == "y" ]] && brew install --cask alacritty

    read -p "Install Firefox? (y/n): " firefox
    [[ "$firefox" == "y" ]] && brew install --cask firefox

    read -p "Install Chrome? (y/n): " chrome
    [[ "$chrome" == "y" ]] && brew install --cask google-chrome

    read -p "Install Spotify? (y/n): " spotify
    [[ "$spotify" == "y" ]] && brew install --cask spotify

    read -p "Install Slack? (y/n): " slack
    [[ "$slack" == "y" ]] && brew install --cask slack

    read -p "Install Rectangle (window manager)? (y/n): " rectangle
    [[ "$rectangle" == "y" ]] && brew install --cask rectangle
}

# Install fonts
install_fonts() {
    print_section "Installing Fonts"

    brew tap homebrew/cask-fonts
    brew install --cask font-fira-code
    brew install --cask font-fira-code-nerd-font
    brew install --cask font-jetbrains-mono
    brew install --cask font-jetbrains-mono-nerd-font
    brew install --cask font-hack-nerd-font
}

# Configure Git
configure_git() {
    print_section "Configuring Git"

    if [ -z "$(git config --global user.name)" ]; then
        read -p "Enter your Git username: " git_name
        git config --global user.name "$git_name"
    fi

    if [ -z "$(git config --global user.email)" ]; then
        read -p "Enter your Git email: " git_email
        git config --global user.email "$git_email"
    fi

    git config --global init.defaultBranch main
    git config --global push.autoSetupRemote true
    git config --global pull.rebase false
}

# Install Oh My Zsh
install_oh_my_zsh() {
    print_section "Installing Oh My Zsh"

    if [ -d "$HOME/.oh-my-zsh" ]; then
        print_info "Oh My Zsh already installed"
        return
    fi

    read -p "Install Oh My Zsh? (y/n): " install_omz
    if [[ "$install_omz" == "y" ]]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

        # Install plugins
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

        print_info "Oh My Zsh installed with plugins"
    fi
}

# Create useful aliases
create_aliases() {
    print_section "Creating Aliases"

    cat >> ~/.zshrc << 'EOF'

# Homebrew aliases
alias brewup='brew update && brew upgrade && brew cleanup'
alias brewdoc='brew doctor'

# Modern CLI tools
alias ls='exa'
alias ll='exa -la'
alias cat='bat'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

EOF

    print_info "Aliases added to ~/.zshrc"
}

# Cleanup
cleanup() {
    print_section "Cleaning Up"
    brew cleanup
    brew doctor || true
}

main() {
    print_info "Starting macOS Homebrew Setup"
    print_info "============================="

    check_macos
    install_homebrew
    update_homebrew
    install_essentials
    install_dev_tools
    install_gui_apps
    install_fonts
    configure_git
    install_oh_my_zsh
    create_aliases
    cleanup

    print_info "\n============================="
    print_info "Homebrew setup complete!"
    print_info "Restart your terminal to apply changes"
}

main
