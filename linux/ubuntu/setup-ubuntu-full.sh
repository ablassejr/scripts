#!/bin/bash

#####################################
# Ubuntu Linux Setup Script
# Optimized for Ubuntu and Ubuntu-based distributions
# Includes: Package installation, SSH setup for rsync, Neovim nightly install
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
    sudo apt-get update
    sudo apt-get upgrade -y
    sudo apt-get dist-upgrade -y
}

# Install base development tools
install_base_devel() {
    print_section "Installing Base Development Tools"
    sudo apt-get install -y build-essential
    sudo apt-get install -y linux-headers-$(uname -r)
    sudo apt-get install -y pkg-config
    sudo apt-get install -y cmake
    sudo apt-get install -y software-properties-common
}

# Install common utilities
install_utilities() {
    print_section "Installing Common Utilities"
    sudo apt-get install -y curl wget git vim nano
    sudo apt-get install -y unzip zip tar gzip bzip2 xz-utils
    sudo apt-get install -y htop btop
    sudo apt-get install -y tree
    sudo apt-get install -y net-tools
    sudo apt-get install -y openssh-client
    sudo apt-get install -y rsync
    sudo apt-get install -y jq
    sudo apt-get install -y tmux
    sudo apt-get install -y man-db manpages manpages-dev
}

# Install development languages
install_languages() {
    print_section "Installing Development Languages"

    # Python
    sudo apt-get install -y python3 python3-pip python3-venv

    # Node.js (using NodeSource repository for latest version)
    if ! command_exists node; then
        print_info "Installing Node.js from NodeSource..."
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi

    # Rust
    if ! command_exists cargo; then
        print_info "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi

    # Go
    sudo apt-get install -y golang

    # Ruby
    sudo apt-get install -y ruby ruby-dev

    # Java
    sudo apt-get install -y default-jdk
}

# Install Docker
install_docker() {
    print_section "Installing Docker"

    if ! command_exists docker; then
        print_info "Installing Docker from official repository..."

        # Install prerequisites
        sudo apt-get install -y ca-certificates gnupg lsb-release

        # Add Docker's official GPG key
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg

        # Set up the repository
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        # Install Docker
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        sudo systemctl enable --now docker
        sudo usermod -aG docker $USER
        print_info "Added $USER to docker group. Please log out and back in."
    fi
}

# Install additional tools
install_additional_tools() {
    print_section "Installing Additional Tools"
    sudo apt-get install -y bat
    sudo apt-get install -y fd-find
    sudo apt-get install -y ripgrep
    sudo apt-get install -y fzf

    # eza (modern ls replacement) - install from GitHub releases
    if ! command_exists eza; then
        print_info "Installing eza from GitHub releases..."
        EZA_VERSION=$(curl -s https://api.github.com/repos/eza-community/eza/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
        if [ -n "$EZA_VERSION" ]; then
            wget -q "https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_x86_64-unknown-linux-gnu.tar.gz" -O /tmp/eza.tar.gz
            sudo tar -xzf /tmp/eza.tar.gz -C /usr/local/bin/
            rm /tmp/eza.tar.gz
        fi
    fi

    # zoxide
    if ! command_exists zoxide; then
        print_info "Installing zoxide..."
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    fi

    sudo apt-get install -y tldr
}

# Install text editors
install_editors() {
    print_section "Installing Text Editors"
    sudo apt-get install -y neovim

    # VS Code
    if ! command_exists code; then
        print_info "Installing VS Code..."
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
        sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
        sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
        rm -f /tmp/packages.microsoft.gpg

        sudo apt-get update
        sudo apt-get install -y code
    fi
}

# Install Neovim Nightly (optional)
install_neovim_nightly() {
    print_section "Installing Neovim Nightly"

    echo ""
    read -p "Do you want to install Neovim nightly build? (y/N) " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Skipping Neovim nightly installation"
        return 0
    fi

    print_info "Downloading Neovim nightly..."
    cd /tmp

    # Download latest nightly
    if curl -LO https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz; then
        print_info "Removing old Neovim nightly installation (if exists)..."
        sudo rm -rf /opt/nvim-linux-x86_64

        print_info "Extracting Neovim nightly to /opt..."
        sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz

        print_info "Creating symlink to /usr/local/bin/nvim..."
        sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim

        # Cleanup
        rm -f nvim-linux-x86_64.tar.gz

        print_info "Neovim nightly installed successfully!"
        print_info "Version: $(/usr/local/bin/nvim --version | head -n 1)"
        print_info "You may need to add /usr/local/bin to your PATH if not already present"
    else
        print_error "Failed to download Neovim nightly"
        return 1
    fi

    cd -
}

# Setup SSH for rsync
setup_ssh_for_rsync() {
    print_section "Setting Up SSH for rsync"

    echo ""
    read -p "Do you want to setup SSH authentication for rsync? (y/N) " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Skipping SSH setup"
        return 0
    fi

    # Ensure openssh and rsync are installed
    print_info "Ensuring SSH and rsync are installed..."
    sudo apt-get install -y openssh-client rsync

    local SSH_DIR="${HOME}/.ssh"
    local KEY_NAME="id_ed25519_rsync7"
    local KEY_PATH="${SSH_DIR}/${KEY_NAME}"

    # Create SSH directory if needed
    if [ ! -d "${SSH_DIR}" ]; then
        print_info "Creating SSH directory..."
        mkdir -p "${SSH_DIR}"
        chmod 700 "${SSH_DIR}"
    fi

    # Check if key already exists
    if [ -f "${KEY_PATH}" ]; then
        print_warning "SSH key already exists: ${KEY_PATH}"
        echo ""
        read -p "Do you want to use the existing key? (Y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            print_info "Generating new SSH key..."
            ssh-keygen -t ed25519 \
                -C "rsync-key-$(hostname)-$(date +%Y%m%d)" \
                -f "${KEY_PATH}"
            chmod 600 "${KEY_PATH}"
            chmod 644 "${KEY_PATH}.pub"
        fi
    else
        print_info "Generating Ed25519 SSH key for rsync..."
        echo ""
        print_warning "PASSPHRASE OPTIONS:"
        echo "  - With passphrase: More secure, but requires entry (can use ssh-agent)"
        echo "  - Without passphrase: Less secure, but enables full automation"
        echo ""

        ssh-keygen -t ed25519 \
            -C "rsync-key-$(hostname)-$(date +%Y%m%d)" \
            -f "${KEY_PATH}"

        chmod 600 "${KEY_PATH}"
        chmod 644 "${KEY_PATH}.pub"
    fi

    print_info "SSH key ready at: ${KEY_PATH}"
    echo ""
    print_info "Your public key:"
    echo "────────────────────────────────────────────────────────────"
    cat "${KEY_PATH}.pub"
    echo "────────────────────────────────────────────────────────────"
    echo ""

    echo ""
    read -p "Do you want to copy the public key to a remote machine now? (y/N) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        read -p "Enter remote host (IP or hostname): " REMOTE_HOST
        read -p "Enter remote username [${USER}]: " REMOTE_USER
        REMOTE_USER=${REMOTE_USER:-${USER}}

        print_info "Copying public key to ${REMOTE_USER}@${REMOTE_HOST}..."
        print_info "You will be prompted for the password on the remote machine"
        echo ""

        if ssh-copy-id -i "${KEY_PATH}.pub" "${REMOTE_USER}@${REMOTE_HOST}"; then
            print_info "Public key copied successfully!"

            # Test connection
            print_info "Testing SSH connection..."
            if ssh -i "${KEY_PATH}" -o BatchMode=yes "${REMOTE_USER}@${REMOTE_HOST}" 'echo "Connection successful!"'; then
                print_info "✓ SSH connection working!"
            else
                print_warning "SSH test failed. You may need to troubleshoot."
            fi
        else
            print_warning "Failed to copy public key. You may need to do this manually."
        fi
    fi

    print_info "SSH setup complete!"
    echo ""
    print_info "To use this key with rsync:"
    echo "  rsync -avz -e 'ssh -i ${KEY_PATH}' /source/ user@host:/dest/"
}

# Install ZSH
install_zsh() {
    print_section "Installing ZSH"

    if ! command_exists zsh; then
        sudo apt-get install -y zsh zsh-autosuggestions zsh-syntax-highlighting
        print_info "ZSH installed. To set as default shell, run: chsh -s \$(which zsh)"
    fi
}

# Install fonts
install_fonts() {
    print_section "Installing Fonts"
    sudo apt-get install -y fonts-firacode
    sudo apt-get install -y fonts-dejavu
    sudo apt-get install -y fonts-noto fonts-noto-color-emoji
    sudo apt-get install -y fonts-powerline
}

# Install X11/Wayland tools
install_display_tools() {
    print_section "Installing Display Server Tools"

    # Check if running X11 or Wayland
    if [ ! -z "$DISPLAY" ]; then
        sudo apt-get install -y x11-xserver-utils
        sudo apt-get install -y xclip xsel
    fi

    if [ ! -z "$WAYLAND_DISPLAY" ]; then
        sudo apt-get install -y wl-clipboard
    fi
}

# Install multimedia codecs
install_multimedia() {
    print_section "Installing Multimedia Codecs"

    # Enable Ubuntu restricted extras
    sudo apt-get install -y ubuntu-restricted-extras || print_warning "ubuntu-restricted-extras not available"

    sudo apt-get install -y ffmpeg
    sudo apt-get install -y gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly
    sudo apt-get install -y libdvd-pkg

    # Configure libdvdcss
    sudo dpkg-reconfigure -plow libdvd-pkg || true
}

# Install GPU drivers helper
install_gpu_drivers() {
    print_section "Checking GPU Drivers"

    if lspci | grep -i nvidia > /dev/null; then
        print_info "NVIDIA GPU detected"
        print_warning "To install NVIDIA drivers, run: sudo ubuntu-drivers autoinstall"
    fi

    if lspci | grep -i amd > /dev/null; then
        print_info "AMD GPU detected"
        sudo apt-get install -y mesa-vulkan-drivers xserver-xorg-video-amdgpu
    fi

    if lspci | grep -i intel > /dev/null; then
        print_info "Intel GPU detected"
        sudo apt-get install -y mesa-vulkan-drivers intel-media-va-driver
    fi
}

# Configure firewall
configure_firewall() {
    print_section "Configuring Firewall"
    sudo apt-get install -y ufw
    sudo systemctl enable --now ufw
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw --force enable
}

# System optimizations
apply_system_tweaks() {
    print_section "Applying System Tweaks"

    # Increase inotify watches
    echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    sudo sysctl --system

    # Enable periodic TRIM for SSDs
    sudo systemctl enable --now fstrim.timer
}

# Enable services
enable_services() {
    print_section "Enabling Services"
    sudo systemctl enable --now ssh
    sudo systemctl enable --now systemd-timesyncd
}

# Install Snap support (default on Ubuntu)
setup_snap() {
    print_section "Setting up Snap"
    if ! command_exists snap; then
        sudo apt-get install -y snapd
    fi
    print_info "Snap is already installed on Ubuntu by default"
}

# Install flatpak
setup_flatpak() {
    print_section "Setting up Flatpak"
    sudo apt-get install -y flatpak
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
}

# Cleanup
cleanup() {
    print_section "Cleaning Up"
    sudo apt-get autoremove -y
    sudo apt-get autoclean
}

main() {
    print_info "Starting Ubuntu Linux Setup Script"
    print_info "================================="

    update_system
    install_base_devel
    install_utilities
    install_languages
    install_docker
    install_additional_tools
    install_editors
    install_neovim_nightly
    setup_ssh_for_rsync
    install_zsh
    install_fonts
    install_display_tools
    install_multimedia
    install_gpu_drivers
    configure_firewall
    apply_system_tweaks
    enable_services
    setup_snap
    setup_flatpak
    cleanup

    print_info "\n================================="
    print_info "Ubuntu Linux setup complete!"
    print_info "Please restart your system for all changes to take effect."
}

main
