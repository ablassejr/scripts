#!/bin/bash

#####################################
# macOS Terminal Setup Script
# Configures Terminal.app and iTerm2
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

# Check if running on macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo "This script is for macOS only!"
        exit 1
    fi
}

# Configure zsh (default on macOS)
configure_zsh() {
    print_section "Configuring Zsh"

    # Create .zshrc if it doesn't exist
    touch ~/.zshrc

    # Add useful configurations
    cat >> ~/.zshrc << 'EOF'

# Enable colors
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

# History settings
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# Auto-completion
autoload -Uz compinit
compinit

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Prompt
PS1='%F{green}%n@%m%f:%F{blue}%~%f$ '

EOF

    print_info "Zsh configured"
}

# Configure Terminal.app
configure_terminal_app() {
    print_section "Configuring Terminal.app"

    # Set default shell to zsh
    chsh -s /bin/zsh

    # Terminal preferences
    defaults write com.apple.terminal "Default Window Settings" -string "Pro"
    defaults write com.apple.terminal "Startup Window Settings" -string "Pro"

    # Enable Option as Meta key
    defaults write com.apple.terminal SecureKeyboardEntry -bool true

    print_info "Terminal.app configured"
}

# Install and configure iTerm2
configure_iterm2() {
    print_section "Configuring iTerm2"

    if [ ! -d "/Applications/iTerm.app" ]; then
        print_warning "iTerm2 not installed. Install with: brew install --cask iterm2"
        return
    fi

    # iTerm2 preferences
    defaults write com.googlecode.iterm2 PromptOnQuit -bool false
    defaults write com.googlecode.iterm2 HideTab -bool false
    defaults write com.googlecode.iterm2 ShowFullScreenTabBar -bool true

    print_info "iTerm2 configured"
    print_info "To use custom themes, visit: https://iterm2colorschemes.com/"
}

# Install Oh My Zsh
install_oh_my_zsh() {
    print_section "Installing Oh My Zsh"

    if [ -d "$HOME/.oh-my-zsh" ]; then
        print_info "Oh My Zsh already installed"
        return
    fi

    read -p "Install Oh My Zsh? (y/n): " install_omz
    if [[ "$install_omz" != "y" ]]; then
        return
    fi

    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    # Install popular plugins
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions

    # Update .zshrc to use plugins
    sed -i '' 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions macos brew)/g' ~/.zshrc

    print_info "Oh My Zsh installed with plugins"
}

# Install Powerlevel10k theme
install_powerlevel10k() {
    print_section "Installing Powerlevel10k Theme"

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        print_warning "Oh My Zsh not installed. Skipping Powerlevel10k."
        return
    fi

    read -p "Install Powerlevel10k theme? (y/n): " install_p10k
    if [[ "$install_p10k" != "y" ]]; then
        return
    fi

    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

    # Set theme in .zshrc
    sed -i '' 's/ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/g' ~/.zshrc

    print_info "Powerlevel10k installed. Run 'p10k configure' to set up."
}

# Install Starship prompt
install_starship() {
    print_section "Installing Starship Prompt"

    read -p "Install Starship prompt? (y/n): " install_star
    if [[ "$install_star" != "y" ]]; then
        return
    fi

    if command_exists brew; then
        brew install starship
    else
        curl -sS https://starship.rs/install.sh | sh
    fi

    echo 'eval "$(starship init zsh)"' >> ~/.zshrc

    # Create default config
    mkdir -p ~/.config
    starship preset nerd-font-symbols -o ~/.config/starship.toml

    print_info "Starship prompt installed"
}

# Create useful aliases
create_aliases() {
    print_section "Creating Aliases"

    cat >> ~/.zshrc << 'EOF'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Shortcuts
alias h='history'
alias c='clear'
alias q='exit'

# List files
alias la='ls -la'
alias ll='ls -lh'
alias lsa='ls -lah'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gco='git checkout'
alias gb='git branch'

# macOS specific
alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'
alias cleanup='find . -type f -name "*.DS_Store" -ls -delete'

# Network
alias myip='curl ifconfig.me'
alias localip='ipconfig getifaddr en0'

# System
alias update='sudo softwareupdate -i -a'
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'

EOF

    print_info "Aliases added to ~/.zshrc"
}

# Install useful CLI tools
install_cli_tools() {
    print_section "Installing CLI Tools"

    if ! command_exists brew; then
        print_warning "Homebrew not installed. Skipping CLI tools."
        return
    fi

    print_info "Installing useful CLI tools..."

    brew install fzf
    brew install bat
    brew install exa
    brew install ripgrep
    brew install fd
    brew install zoxide
    brew install tldr
    brew install tree
    brew install htop

    # Install fzf key bindings
    $(brew --prefix)/opt/fzf/install --all

    print_info "CLI tools installed"
}

# Show usage tips
show_tips() {
    print_section "Terminal Setup Tips"

    cat << 'EOF'
Zsh Configuration:
  Config file: ~/.zshrc
  Reload: source ~/.zshrc

Oh My Zsh:
  Themes: ~/.oh-my-zsh/themes/
  Plugins: ~/.oh-my-zsh/plugins/
  Update: omz update

iTerm2:
  Preferences: Cmd+,
  Split horizontal: Cmd+D
  Split vertical: Cmd+Shift+D
  Switch panes: Cmd+[ or Cmd+]
  New tab: Cmd+T
  Fullscreen: Cmd+Enter

Useful Tools:
  fzf - Fuzzy finder (Ctrl+R for history, Ctrl+T for files)
  bat - Better cat with syntax highlighting
  exa - Modern ls replacement
  zoxide - Smart cd command
  tldr - Simplified man pages

Color Schemes:
  iTerm2 themes: https://iterm2colorschemes.com/
  Terminal themes: https://github.com/lysyi3m/macos-terminal-themes
EOF
}

main() {
    print_info "Starting macOS Terminal Setup"
    print_info "============================="

    check_macos
    configure_zsh
    configure_terminal_app
    configure_iterm2
    install_oh_my_zsh
    install_powerlevel10k
    install_starship
    create_aliases
    install_cli_tools
    show_tips

    print_info "\n============================="
    print_info "Terminal setup complete!"
    print_info "Restart your terminal to apply changes"
}

main
