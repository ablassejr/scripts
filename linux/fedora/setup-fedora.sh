#!/bin/bash

#####################################
# Fedora-Specific Setup Script
# Optimized for Fedora Workstation
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

# Safe package installation function for DNF
safe_dnf_install() {
  local packages=("$@")
  local failed=()

  for pkg in "${packages[@]}"; do
    if sudo dnf install -y "$pkg" 2>/dev/null; then
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
  sudo dnf upgrade --refresh -y || print_warning "Failed to upgrade packages"
}

# Enable RPM Fusion repositories
enable_rpm_fusion() {
  print_section "Enabling RPM Fusion Repositories"
  sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" \
    || print_warning "Failed to install RPM Fusion repositories"
}

# Install development tools
install_dev_tools() {
  print_section "Installing Development Tools"
  sudo dnf group install development-tools sound-and-video system-tools -y || print_warning "Failed to install some groups"
  safe_dnf_install gcc gcc-c++ make cmake kernel-devel kernel-headers
}

# Install common utilities
install_utilities() {
  print_section "Installing Common Utilities"
  safe_dnf_install curl wget git vim nano unzip zip tar gzip bzip2 htop btop tree net-tools openssh-clients openssh-server rsync jq yq tmux util-linux-user
}

# Install multimedia codecs
install_multimedia() {
  print_section "Installing Multimedia Codecs"
  sudo dnf install -y gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel || print_warning "Failed to install some gstreamer plugins"
  sudo dnf install -y lame\* --exclude=lame-devel || print_warning "Failed to install lame"
  sudo dnf group upgrade -y sound-and-video system-tools || print_warning "Failed to upgrade groups"
}

# Install development languages
install_languages() {
  print_section "Installing Development Languages"

  # Python
  safe_dnf_install python3 python3-pip python3-devel

  # Node.js
  if ! command_exists node; then
    safe_dnf_install nodejs npm
  fi

  # Rust
  if ! command_exists cargo; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || print_warning "Failed to install Rust"
    [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
  fi

  # Go
  safe_dnf_install golang
}

# Install Docker
install_docker() {
  print_section "Installing Docker"

  if ! command_exists docker; then
    if safe_dnf_install dnf-plugins-core; then
      sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo || print_warning "Failed to add Docker repo"
      sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin --allowerasing --skip-broken || print_warning "Failed to install Docker packages"
      sudo systemctl enable --now docker || print_warning "Failed to enable docker service"
      sudo usermod -aG docker "$USER" || print_warning "Failed to add user to docker group"
      print_info "Added $USER to docker group. Please log out and back in."
    fi
  fi
}

# Install Podman (Fedora's preferred container runtime)
install_podman() {
  print_section "Installing Podman"
  sudo dnf install -y podman podman-compose podman-docker --skip-broken
}

# Install virtualization tools
install_virtualization() {
  print_section "Installing Virtualization Tools"
  sudo dnf install -y @virtualization
  sudo systemctl enable --now libvirtd
  sudo usermod -aG libvirt $USER
}

# Install snap support
install_snap() {
  print_section "Installing Snap Support"

  if ! command_exists snap; then
    sudo dnf install -y snapd
    sudo ln -s /var/lib/snapd/snap /snap
    sudo systemctl enable --now snapd.socket
  fi
}

# Install flatpak (usually pre-installed)
setup_flatpak() {
  print_section "Setting up Flatpak"
  sudo dnf install -y flatpak
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

# Install GNOME tweaks and extensions
install_gnome_tools() {
  print_section "Installing GNOME Tools"
  sudo dnf install -y gnome-tweaks
  sudo dnf install -y gnome-extensions-app
  sudo dnf install -y dconf-editor
}

# Install ZSH
install_zsh() {
  print_section "Installing ZSH"

  if ! command_exists zsh; then
    sudo dnf install -y zsh
    print_info "ZSH installed. To set as default shell, run: chsh -s \$(which zsh)"
  fi
}

# Install fonts
install_fonts() {
  print_section "Installing Fonts"
  sudo dnf install -y fira-code-fonts
  sudo dnf install -y powerline-fonts
  sudo dnf install -y google-noto-fonts-common
  sudo dnf install -y google-noto-emoji-fonts

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

# Configure firewall
configure_firewall() {
  print_section "Configuring Firewall"
  sudo systemctl enable --now firewalld
  sudo firewall-cmd --permanent --add-service=ssh
  sudo firewall-cmd --reload
}

# System optimizations
apply_system_tweaks() {
  print_section "Applying System Tweaks"

  # Increase inotify watches
  echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf
  sudo sysctl -p

  # Improve I/O scheduler for SSDs
  echo 'ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"' | sudo tee /etc/udev/rules.d/60-ioschedulers.rules

  # Enable better power management
  sudo dnf install -y tlp tlp-rdw
  sudo systemctl enable --now tlp
}

# Install additional tools
install_additional_tools() {
  print_section "Installing Additional Tools"
  sudo dnf install -y bat fd-find ripgrep --skip-unavailable
  sudo dnf install -y fzf
}

# Cleanup
cleanup() {
  print_section "Cleaning Up"
  sudo dnf autoremove -y
  sudo dnf clean all
}

main() {
  print_info "Starting Fedora Setup Script"
  print_info "============================="

  update_system
  enable_rpm_fusion
  install_dev_tools
  install_utilities
  install_multimedia
  install_languages
  install_docker
  install_podman
  install_virtualization
  install_snap
  setup_flatpak
  install_gnome_tools
  install_zsh
  install_fonts
  configure_firewall
  apply_system_tweaks
  install_additional_tools
  cleanup

  print_info "\n============================="
  print_info "Fedora setup complete!"
  print_info "Please restart your system for all changes to take effect."
}

main
