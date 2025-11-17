#!/bin/bash

#####################################
# Arch Linux Setup Script
# Optimized for Arch Linux and Arch-based distributions
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
    sudo pacman -Syu --noconfirm
}

# Install base development tools
install_base_devel() {
    print_section "Installing Base Development Tools"
    sudo pacman -S --noconfirm base-devel
    sudo pacman -S --noconfirm linux-headers
}

# Install yay (AUR helper)
install_yay() {
    print_section "Installing Yay AUR Helper"

    if ! command_exists yay; then
        cd /tmp
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd -
        rm -rf /tmp/yay
    else
        print_info "yay is already installed"
    fi
}

# Install packages from Package List
install_from_package_list() {
    print_section "Installing Packages from Package List"

    local package_list_file="$(dirname "$0")/Package List.md"

    if [ ! -f "$package_list_file" ]; then
        print_warning "Package List.md not found at: $package_list_file"
        print_info "Skipping package list installation"
        return 0
    fi

    print_info "Reading packages from: $package_list_file"

    # Extract package names (remove version numbers after space)
    # Filter out empty lines
    local packages=()
    while IFS= read -r line; do
        # Extract package name (everything before the first space)
        local pkg_name=$(echo "$line" | awk '{print $1}')

        # Skip empty lines
        if [ -n "$pkg_name" ]; then
            packages+=("$pkg_name")
        fi
    done < "$package_list_file"

    if [ ${#packages[@]} -eq 0 ]; then
        print_warning "No packages found in Package List.md"
        return 0
    fi

    print_info "Found ${#packages[@]} packages to install"

    # Separate official repo packages from AUR packages
    local official_pkgs=()
    local aur_pkgs=()

    print_info "Checking which packages are in official repos..."

    for pkg in "${packages[@]}"; do
        if pacman -Si "$pkg" &>/dev/null; then
            official_pkgs+=("$pkg")
        else
            aur_pkgs+=("$pkg")
        fi
    done

    # Install official packages
    if [ ${#official_pkgs[@]} -gt 0 ]; then
        print_info "Installing ${#official_pkgs[@]} packages from official repositories..."
        sudo pacman -S --needed --noconfirm "${official_pkgs[@]}" || print_warning "Some official packages failed to install"
    fi

    # Install AUR packages
    if [ ${#aur_pkgs[@]} -gt 0 ]; then
        if command_exists yay; then
            print_info "Installing ${#aur_pkgs[@]} packages from AUR..."
            yay -S --needed --noconfirm "${aur_pkgs[@]}" || print_warning "Some AUR packages failed to install"
        else
            print_warning "yay not installed. Skipping ${#aur_pkgs[@]} AUR packages"
            print_info "AUR packages that will be skipped: ${aur_pkgs[*]}"
        fi
    fi

    print_info "Package installation from Package List complete"
}

# Install common utilities
install_utilities() {
    print_section "Installing Common Utilities"
    sudo pacman -S --noconfirm curl wget git vim nano
    sudo pacman -S --noconfirm unzip zip tar gzip bzip2 xz
    sudo pacman -S --noconfirm htop btop
    sudo pacman -S --noconfirm tree
    sudo pacman -S --noconfirm net-tools
    sudo pacman -S --noconfirm openssh
    sudo pacman -S --noconfirm rsync
    sudo pacman -S --noconfirm jq
    sudo pacman -S --noconfirm tmux
    sudo pacman -S --noconfirm man-db man-pages
}

# Install development languages
install_languages() {
    print_section "Installing Development Languages"

    # Python
    sudo pacman -S --noconfirm python python-pip python-virtualenv

    # Node.js
    sudo pacman -S --noconfirm nodejs npm

    # Rust
    if ! command_exists cargo; then
        sudo pacman -S --noconfirm rustup
        rustup default stable
    fi

    # Go
    sudo pacman -S --noconfirm go

    # Ruby
    sudo pacman -S --noconfirm ruby

    # Java
    sudo pacman -S --noconfirm jdk-openjdk
}

# Install Docker
install_docker() {
    print_section "Installing Docker"

    if ! command_exists docker; then
        sudo pacman -S --noconfirm docker docker-compose
        sudo systemctl enable --now docker
        sudo usermod -aG docker $USER
        print_info "Added $USER to docker group. Please log out and back in."
    fi
}

# Install additional tools
install_additional_tools() {
    print_section "Installing Additional Tools"
    sudo pacman -S --noconfirm bat fd ripgrep
    sudo pacman -S --noconfirm fzf
    sudo pacman -S --noconfirm eza  # Modern replacement for ls (replaces deprecated exa)
    sudo pacman -S --noconfirm zoxide
    sudo pacman -S --noconfirm tldr
}

# Install text editors
install_editors() {
    print_section "Installing Text Editors"
    sudo pacman -S --noconfirm neovim
    sudo pacman -S --noconfirm code  # VS Code
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
    sudo pacman -S --needed --noconfirm openssh rsync

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
        sudo pacman -S --noconfirm zsh zsh-completions
        print_info "ZSH installed. To set as default shell, run: chsh -s \$(which zsh)"
    fi
}

# Install fonts
install_fonts() {
    print_section "Installing Fonts"
    sudo pacman -S --noconfirm ttf-fira-code
    sudo pacman -S --noconfirm ttf-dejavu
    sudo pacman -S --noconfirm noto-fonts noto-fonts-emoji
    sudo pacman -S --noconfirm powerline-fonts

    # Install Nerd Fonts from AUR
    if command_exists yay; then
        yay -S --noconfirm ttf-firacode-nerd || true
    fi
}

# Install X11/Wayland tools
install_display_tools() {
    print_section "Installing Display Server Tools"

    # Check if running X11 or Wayland
    if [ ! -z "$DISPLAY" ]; then
        sudo pacman -S --noconfirm xorg-xrandr xorg-xrdb xorg-xinit
        sudo pacman -S --noconfirm xclip xsel
    fi

    if [ ! -z "$WAYLAND_DISPLAY" ]; then
        sudo pacman -S --noconfirm wl-clipboard
    fi
}

# Install multimedia codecs
install_multimedia() {
    print_section "Installing Multimedia Codecs"
    sudo pacman -S --noconfirm ffmpeg
    sudo pacman -S --noconfirm gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly
    sudo pacman -S --noconfirm libdvdcss
}

# Install GPU drivers helper
install_gpu_drivers() {
    print_section "Checking GPU Drivers"

    if lspci | grep -i nvidia > /dev/null; then
        print_info "NVIDIA GPU detected"
        print_warning "To install NVIDIA drivers, run: sudo pacman -S nvidia nvidia-utils"
    fi

    if lspci | grep -i amd > /dev/null; then
        print_info "AMD GPU detected"
        # Note: xf86-video-amdgpu is optional; modesetting driver usually works well
        # xf86-video-amdgpu may be needed for specific features or older hardware
        sudo pacman -S --noconfirm mesa xf86-video-amdgpu vulkan-radeon
    fi

    if lspci | grep -i intel > /dev/null; then
        print_info "Intel GPU detected"
        # Note: xf86-video-intel is not recommended for modern Intel GPUs (Haswell and newer)
        # The modesetting driver (included in xorg-server) is preferred
        sudo pacman -S --noconfirm mesa vulkan-intel
    fi
}

# Configure firewall
configure_firewall() {
    print_section "Configuring Firewall"
    sudo pacman -S --noconfirm ufw
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

    # Improve I/O scheduler for SSDs
    # Note: mq-deadline is good for SATA SSDs; for NVMe, "none" might perform better
    echo 'ACTION=="add|change", KERNEL=="sd[a-z]*|nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"' | sudo tee /etc/udev/rules.d/60-ioschedulers.rules

    # Enable periodic TRIM for SSDs
    sudo systemctl enable --now fstrim.timer
}

# Enable services
enable_services() {
    print_section "Enabling Services"
    sudo systemctl enable --now sshd
    sudo systemctl enable --now systemd-timesyncd
}

# Install snap support (optional)
install_snap() {
    print_section "Installing Snap Support (Optional)"
    print_warning "Snap is available but not recommended on Arch. Skipping..."
    # Uncomment if you really want snap:
    # if command_exists yay; then
    #     yay -S --noconfirm snapd
    #     sudo systemctl enable --now snapd.socket
    #     sudo ln -s /var/lib/snapd/snap /snap
    # fi
}

# Install flatpak
setup_flatpak() {
    print_section "Setting up Flatpak"
    sudo pacman -S --noconfirm flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

# Cleanup
cleanup() {
    print_section "Cleaning Up"
    sudo pacman -Sc --noconfirm
    if command_exists yay; then
        yay -Sc --noconfirm
    fi
}

main() {
    print_info "Starting Arch Linux Setup Script"
    print_info "================================="

    update_system
    install_base_devel
    install_yay
    install_from_package_list
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
    print_info "Arch Linux setup complete!"
    print_info "Please restart your system for all changes to take effect."
}

main
