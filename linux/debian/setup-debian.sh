#!/bin/bash

#####################################
# Debian-Specific Setup Script
# Optimized for Debian stable
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
    sudo apt dist-upgrade -y
}

# Enable contrib and non-free repositories
enable_extra_repos() {
    print_section "Enabling Contrib and Non-Free Repositories"
    sudo apt-add-repository contrib non-free -y || true
    sudo apt update
}

# Install build essentials
install_build_essentials() {
    print_section "Installing Build Essentials"
    sudo apt install -y build-essential
    sudo apt install -y linux-headers-$(uname -r)
    sudo apt install -y dkms
}

# Install common utilities
install_utilities() {
    print_section "Installing Common Utilities"
    sudo apt install -y curl wget git vim nano
    sudo apt install -y unzip zip tar gzip bzip2
    sudo apt install -y htop
    sudo apt install -y tree
    sudo apt install -y net-tools
    sudo apt install -y openssh-client openssh-server
    sudo apt install -y rsync
    sudo apt install -y jq
    sudo apt install -y tmux screen
    sudo apt install -y apt-transport-https
    sudo apt install -y ca-certificates
    sudo apt install -y gnupg
    sudo apt install -y lsb-release
}

# Install development tools
install_dev_tools() {
    print_section "Installing Development Tools"

    # Python
    sudo apt install -y python3 python3-pip python3-venv python3-dev

    # Node.js (using NodeSource)
    if ! command_exists node; then
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt install -y nodejs
    fi

    # Docker
    if ! command_exists docker; then
        sudo apt install -y docker.io
        sudo systemctl enable --now docker
        sudo usermod -aG docker $USER
        print_info "Added $USER to docker group. Please log out and back in."
    fi
}

# Install additional programming languages
install_languages() {
    print_section "Installing Additional Languages"

    # GCC and G++
    sudo apt install -y gcc g++

    # Rust
    if ! command_exists cargo; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi

    # Go
    sudo apt install -y golang || print_warning "Go not available in stable repos. Install manually if needed."

    # Ruby
    sudo apt install -y ruby-full

    # Java
    sudo apt install -y default-jdk
}

# Install text editors
install_editors() {
    print_section "Installing Text Editors"
    sudo apt install -y neovim || sudo apt install -y vim-gtk3
}

# Install snap support
install_snap() {
    print_section "Installing Snap Support"

    if ! command_exists snap; then
        sudo apt install -y snapd
        sudo systemctl enable --now snapd.socket
        sudo systemctl enable --now snapd.apparmor
    fi
}

# Setup flatpak
setup_flatpak() {
    print_section "Setting up Flatpak"

    if ! command_exists flatpak; then
        sudo apt install -y flatpak
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    fi
}

# Install ZSH
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
    sudo apt install -y fonts-noto fonts-noto-color-emoji

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

# Install multimedia
install_multimedia() {
    print_section "Installing Multimedia Codecs"
    sudo apt install -y ffmpeg
    sudo apt install -y gstreamer1.0-plugins-base gstreamer1.0-plugins-good
    sudo apt install -y gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly
    sudo apt install -y gstreamer1.0-libav
    sudo apt install -y libdvd-pkg
    sudo dpkg-reconfigure -f noninteractive libdvd-pkg || true
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

# Install additional tools
install_additional_tools() {
    print_section "Installing Additional Tools"
    sudo apt install -y neofetch
    sudo apt install -y ripgrep fd-find || print_warning "Some tools not available"
    sudo apt install -y fzf
}

# System optimizations
apply_system_tweaks() {
    print_section "Applying System Tweaks"

    # Increase inotify watches
    echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p

    # Reduce swappiness
    echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
}

# Enable necessary services
enable_services() {
    print_section "Enabling Services"
    sudo systemctl enable --now ssh
}

# Cleanup
cleanup() {
    print_section "Cleaning Up"
    sudo apt autoremove -y
    sudo apt autoclean -y
}

main() {
    print_info "Starting Debian Setup Script"
    print_info "============================"

    update_system
    enable_extra_repos
    install_build_essentials
    install_utilities
    install_dev_tools
    install_languages
    install_editors
    install_snap
    setup_flatpak
    install_zsh
    install_fonts
    install_multimedia
    configure_firewall
    install_additional_tools
    apply_system_tweaks
    enable_services
    cleanup

    print_info "\n============================"
    print_info "Debian setup complete!"
    print_info "Please restart your system for all changes to take effect."
}

main
