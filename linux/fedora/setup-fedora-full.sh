#!/bin/bash

#####################################
# Fedora Linux Setup Script
# Optimized for Fedora and Fedora-based distributions
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
    sudo dnf upgrade -y --refresh
}

# Install base development tools
install_base_devel() {
    print_section "Installing Base Development Tools"
    sudo dnf groupinstall -y "Development Tools"
    sudo dnf install -y kernel-devel kernel-headers
    sudo dnf install -y cmake
}

# Enable RPM Fusion repositories
enable_rpmfusion() {
    print_section "Enabling RPM Fusion Repositories"

    if ! dnf repolist | grep -q rpmfusion; then
        print_info "Installing RPM Fusion repositories..."
        sudo dnf install -y \
            https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
            https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    else
        print_info "RPM Fusion repositories already enabled"
    fi
}

# Install common utilities
install_utilities() {
    print_section "Installing Common Utilities"
    sudo dnf install -y curl wget git vim nano
    sudo dnf install -y unzip zip tar gzip bzip2 xz
    sudo dnf install -y htop btop
    sudo dnf install -y tree
    sudo dnf install -y net-tools
    sudo dnf install -y openssh-clients
    sudo dnf install -y rsync
    sudo dnf install -y jq
    sudo dnf install -y tmux
    sudo dnf install -y man-db man-pages
}

# Install development languages
install_languages() {
    print_section "Installing Development Languages"

    # Python
    sudo dnf install -y python3 python3-pip python3-virtualenv

    # Node.js
    sudo dnf install -y nodejs npm

    # Rust
    if ! command_exists cargo; then
        print_info "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi

    # Go
    sudo dnf install -y golang

    # Ruby
    sudo dnf install -y ruby ruby-devel

    # Java
    sudo dnf install -y java-latest-openjdk java-latest-openjdk-devel
}

# Install Docker
install_docker() {
    print_section "Installing Docker"

    if ! command_exists docker; then
        print_info "Installing Docker from official repository..."

        # Remove old versions
        sudo dnf remove -y docker \
                          docker-client \
                          docker-client-latest \
                          docker-common \
                          docker-latest \
                          docker-latest-logrotate \
                          docker-logrotate \
                          docker-selinux \
                          docker-engine-selinux \
                          docker-engine 2>/dev/null || true

        # Install Docker repository
        sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

        # Install Docker
        sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        sudo systemctl enable --now docker
        sudo usermod -aG docker $USER
        print_info "Added $USER to docker group. Please log out and back in."
    fi
}

# Install additional tools
install_additional_tools() {
    print_section "Installing Additional Tools"
    sudo dnf install -y bat
    sudo dnf install -y fd-find
    sudo dnf install -y ripgrep
    sudo dnf install -y fzf

    # eza (modern ls replacement)
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

    sudo dnf install -y tldr
}

# Install text editors
install_editors() {
    print_section "Installing Text Editors"
    sudo dnf install -y neovim

    # VS Code
    if ! command_exists code; then
        print_info "Installing VS Code..."
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
        sudo dnf check-update
        sudo dnf install -y code
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
    sudo dnf install -y openssh-clients rsync

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
        sudo dnf install -y zsh zsh-autosuggestions zsh-syntax-highlighting
        print_info "ZSH installed. To set as default shell, run: chsh -s \$(which zsh)"
    fi
}

# Install fonts
install_fonts() {
    print_section "Installing Fonts"
    sudo dnf install -y fira-code-fonts
    sudo dnf install -y dejavu-fonts-all
    sudo dnf install -y google-noto-emoji-fonts
    sudo dnf install -y powerline-fonts
    sudo dnf install -y 'google-noto*-fonts'
}

# Install X11/Wayland tools
install_display_tools() {
    print_section "Installing Display Server Tools"

    # Check if running X11 or Wayland
    if [ ! -z "$DISPLAY" ]; then
        sudo dnf install -y xorg-x11-server-utils
        sudo dnf install -y xclip xsel
    fi

    if [ ! -z "$WAYLAND_DISPLAY" ]; then
        sudo dnf install -y wl-clipboard
    fi
}

# Install multimedia codecs
install_multimedia() {
    print_section "Installing Multimedia Codecs"

    # Ensure RPM Fusion is enabled
    enable_rpmfusion

    # Install multimedia packages
    sudo dnf groupupdate -y multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
    sudo dnf groupupdate -y sound-and-video

    sudo dnf install -y ffmpeg
    sudo dnf install -y gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel
    sudo dnf install -y lame\* --exclude=lame-devel
    sudo dnf group upgrade -y --with-optional Multimedia
}

# Install GPU drivers helper
install_gpu_drivers() {
    print_section "Checking GPU Drivers"

    if lspci | grep -i nvidia > /dev/null; then
        print_info "NVIDIA GPU detected"
        print_warning "To install NVIDIA drivers from RPM Fusion, run:"
        print_warning "  sudo dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda"
    fi

    if lspci | grep -i amd > /dev/null; then
        print_info "AMD GPU detected"
        sudo dnf install -y mesa-vulkan-drivers mesa-vdpau-drivers
    fi

    if lspci | grep -i intel > /dev/null; then
        print_info "Intel GPU detected"
        sudo dnf install -y mesa-vulkan-drivers intel-media-driver
    fi
}

# Configure firewall
configure_firewall() {
    print_section "Configuring Firewall"

    # Fedora uses firewalld by default
    sudo systemctl enable --now firewalld

    # Allow SSH
    sudo firewall-cmd --permanent --add-service=ssh
    sudo firewall-cmd --reload

    print_info "Firewall configured with firewalld"
    print_info "To use ufw instead, run: sudo dnf install ufw && sudo systemctl disable firewalld && sudo systemctl enable ufw"
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
    sudo systemctl enable --now sshd
    sudo systemctl enable --now chronyd  # Fedora uses chronyd instead of systemd-timesyncd
}

# Install flatpak (default on Fedora Workstation)
setup_flatpak() {
    print_section "Setting up Flatpak"

    if ! command_exists flatpak; then
        sudo dnf install -y flatpak
    fi

    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
    print_info "Flatpak is configured"
}

# Cleanup
cleanup() {
    print_section "Cleaning Up"
    sudo dnf autoremove -y
    sudo dnf clean all
}

main() {
    print_info "Starting Fedora Linux Setup Script"
    print_info "================================="

    update_system
    enable_rpmfusion
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
    setup_flatpak
    cleanup

    print_info "\n================================="
    print_info "Fedora Linux setup complete!"
    print_info "Please restart your system for all changes to take effect."
}

main
