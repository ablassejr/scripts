#!/bin/bash

#####################################
# Ubuntu-Specific Setup Script
# Optimized for Ubuntu and Ubuntu-based distributions
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

# Update system
update_system() {
    print_section "Updating System"
    sudo apt update
    sudo apt upgrade -y
    sudo apt autoremove -y
}

# Install essential build tools
install_build_essentials() {
    print_section "Installing Build Essentials"
    sudo apt install -y build-essential
    sudo apt install -y software-properties-common
    sudo apt install -y apt-transport-https
    sudo apt install -y ca-certificates
    sudo apt install -y gnupg
    sudo apt install -y lsb-release
}

# Install common utilities
install_utilities() {
    print_section "Installing Common Utilities"
    sudo apt install -y curl wget git vim nano
    sudo apt install -y unzip zip tar gzip
    sudo apt install -y htop btop
    sudo apt install -y tree
    sudo apt install -y net-tools
    sudo apt install -y openssh-client openssh-server
    sudo apt install -y rsync
    sudo apt install -y jq
    sudo apt install -y tmux
}

# Install development tools
install_dev_tools() {
    print_section "Installing Development Tools"

    # Python
    sudo apt install -y python3 python3-pip python3-venv

    # Node.js LTS
    if ! command_exists node; then
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt install -y nodejs
    fi

    # Docker
    if ! command_exists docker; then
        sudo apt install -y docker.io
        sudo systemctl enable --now docker
        sudo usermod -aG docker $USER
        print_info "Added $USER to docker group. Please log out and back in for changes to take effect."
    fi
}

# Install snap packages
install_snap_packages() {
    print_section "Installing Snap Packages"

    if ! command_exists snap; then
        sudo apt install -y snapd
        sudo systemctl enable --now snapd.socket
    fi

    # Common snap packages
    sudo snap install --classic code  # VS Code
    sudo snap install --classic nvim  # Neovim
}

# Install flatpak
setup_flatpak() {
    print_section "Setting up Flatpak"

    if ! command_exists flatpak; then
        sudo apt install -y flatpak
        sudo apt install -y gnome-software-plugin-flatpak
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        print_warning "Please restart your system for Flatpak changes to take effect."
    fi
}

# Configure firewall
configure_firewall() {
    print_section "Configuring Firewall"
    sudo apt install -y ufw
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw --force enable
}

# Install ZSH and Oh My Zsh
install_zsh() {
    print_section "Installing ZSH"

    if ! command_exists zsh; then
        sudo apt install -y zsh
        print_info "ZSH installed. To set as default shell, run: chsh -s \$(which zsh)"
    fi
}

# Install fonts
install_fonts() {
    print_section "Installing Fonts"
    sudo apt install -y fonts-firacode
    sudo apt install -y fonts-powerline

    # Install Nerd Fonts
    if [ ! -d "$HOME/.local/share/fonts/NerdFonts" ]; then
        mkdir -p ~/.local/share/fonts/NerdFonts
        cd ~/.local/share/fonts/NerdFonts
        wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraCode.zip
        unzip FiraCode.zip
        rm FiraCode.zip
        fc-cache -fv
        cd -
    fi
}

# System tweaks
apply_system_tweaks() {
    print_section "Applying System Tweaks"

    # Increase inotify watches for development
    echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p

    # Reduce swappiness
    echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
}

# Cleanup
cleanup() {
    print_section "Cleaning Up"
    sudo apt autoremove -y
    sudo apt autoclean -y
}

main() {
    print_info "Starting Ubuntu Setup Script"
    print_info "=============================="

    update_system
    install_build_essentials
    install_utilities
    install_dev_tools
    install_snap_packages
    setup_flatpak
    configure_firewall
    install_zsh
    install_fonts
    apply_system_tweaks
    cleanup

    print_info "\n=============================="
    print_info "Ubuntu setup complete!"
    print_info "Please restart your system for all changes to take effect."
}

main
