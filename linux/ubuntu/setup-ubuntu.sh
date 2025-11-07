#!/bin/bash

#####################################
# Ubuntu-Specific Setup Script
# Optimized for Ubuntu and Ubuntu-based distributions
#####################################

# Disable exit on error to allow continuing on package failures
set +e

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

# Safe package installation function
safe_apt_install() {
    local packages=("$@")
    local failed=()

    for pkg in "${packages[@]}"; do
        if sudo apt install -y "$pkg" 2>/dev/null; then
            print_info "✓ Installed: $pkg"
        else
            print_warning "✗ Failed to install: $pkg"
            failed+=("$pkg")
        fi
    done

    if [ ${#failed[@]} -gt 0 ]; then
        print_warning "Failed packages: ${failed[*]}"
        return 1
    fi
    return 0
}

# Update system
update_system() {
    print_section "Updating System"
    sudo apt update || print_warning "Failed to update package lists"
    sudo apt upgrade -y || print_warning "Failed to upgrade packages"
    sudo apt autoremove -y || print_warning "Failed to autoremove packages"
}

# Install essential build tools
install_build_essentials() {
    print_section "Installing Build Essentials"
    safe_apt_install build-essential software-properties-common apt-transport-https ca-certificates gnupg lsb-release
}

# Install common utilities
install_utilities() {
    print_section "Installing Common Utilities"
    safe_apt_install curl wget git vim nano unzip zip tar gzip htop btop tree net-tools openssh-client openssh-server rsync jq tmux
}

# Install development tools
install_dev_tools() {
    print_section "Installing Development Tools"

    # Python
    safe_apt_install python3 python3-pip python3-venv

    # Node.js LTS
    if ! command_exists node; then
        if curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -; then
            safe_apt_install nodejs
        else
            print_warning "Failed to add Node.js repository"
        fi
    fi

    # Docker
    if ! command_exists docker; then
        if sudo apt install -y docker.io; then
            sudo systemctl enable --now docker || print_warning "Failed to enable docker"
            sudo usermod -aG docker "$USER" || print_warning "Failed to add user to docker group"
            print_info "Added $USER to docker group. Please log out and back in for changes to take effect."
        else
            print_warning "Failed to install docker.io"
        fi
    fi
}

# Install snap packages
install_snap_packages() {
    print_section "Installing Snap Packages"

    if ! command_exists snap; then
        if sudo apt install -y snapd; then
            sudo systemctl enable --now snapd.socket || print_warning "Failed to enable snapd"
        else
            print_warning "Failed to install snapd"
            return
        fi
    fi

    # Common snap packages
    sudo snap install --classic code || print_warning "Failed to install VS Code via snap"
    sudo snap install --classic nvim || print_warning "Failed to install Neovim via snap"
}

# Install flatpak
setup_flatpak() {
    print_section "Setting up Flatpak"

    if ! command_exists flatpak; then
        safe_apt_install flatpak
        sudo apt install -y gnome-software-plugin-flatpak
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        print_warning "Please restart your system for Flatpak changes to take effect."
    fi
}

# Configure firewall
configure_firewall() {
    print_section "Configuring Firewall"
    if safe_apt_install ufw; then
        sudo ufw default deny incoming || print_warning "Failed to set ufw default deny"
        sudo ufw default allow outgoing || print_warning "Failed to set ufw default allow"
        sudo ufw allow ssh || print_warning "Failed to allow ssh"
        sudo ufw --force enable || print_warning "Failed to enable ufw"
    fi
}

# Install ZSH and Oh My Zsh
install_zsh() {
    print_section "Installing ZSH"

    if ! command_exists zsh; then
        if safe_apt_install zsh; then
            print_info "ZSH installed. To set as default shell, run: chsh -s \$(which zsh)"
        fi
    fi
}

# Install fonts
install_fonts() {
    print_section "Installing Fonts"
    safe_apt_install fonts-firacode fonts-powerline

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
