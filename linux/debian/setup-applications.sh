#!/bin/bash

# Disable exit on error for package installations
set +e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Install essential applications
print_info "Installing essential applications..."
safe_apt_install firefox-esr onedrive gnome-terminal libgtk-4-dev libadwaita-1-dev

# Install snap packages
print_info "Installing snap packages..."
if sudo snap install --edge nvim --classic; then
    print_info "Neovim installed via snap"
else
    print_warning "Failed to install neovim via snap"
fi

if sudo snap install zig --classic --beta; then
    print_info "Zig installed via snap"
else
    print_warning "Failed to install zig via snap"
fi

# Install zed
print_info "Installing Zed editor..."
if curl -f https://zed.dev/install.sh | sh; then
    print_info "Zed installed successfully"
else
    print_warning "Failed to install Zed"
fi

# Build and install ghostty
print_info "Building and installing Ghostty..."
if [ -d ghostty ]; then
    print_warning "ghostty directory already exists, skipping clone"
else
    if git clone https://github.com/ghostty-org/ghostty.git; then
        cd ghostty || exit
        if zig build -Doptimize=ReleaseFast; then
            if sudo zig build -Doptimize=ReleaseFast --prefix /usr/local install; then
                print_info "Ghostty installed successfully"
            else
                print_warning "Failed to install Ghostty"
            fi
        else
            print_warning "Failed to build Ghostty"
        fi
        cd ..
    else
        print_warning "Failed to clone Ghostty repository"
    fi
fi

# Download and install the Dropbox package
print_info "Installing Dropbox..."
cd ~ || exit
if wget -O dropbox.deb "https://www.dropbox.com/download?dl=packages/ubuntu/dropbox_2020.03.04_amd64.deb"; then
    if sudo apt install -y ./dropbox.deb; then
        print_info "Dropbox installed successfully"
        rm -f dropbox.deb
    else
        print_warning "Failed to install Dropbox"
    fi
else
    print_warning "Failed to download Dropbox"
fi

# Add Docker's official GPG key:
print_info "Setting up Docker repository..."
sudo apt-get update || print_warning "Failed to update"
safe_apt_install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings || print_warning "Failed to create keyrings directory"

if sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc; then
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    print_info "Docker GPG key added"
else
    print_warning "Failed to add Docker GPG key"
fi

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Download and install Docker Desktop
print_info "Installing Docker Desktop..."
if curl -L -o docker-desktop-amd64.deb "https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-linux-amd64"; then
    sudo apt-get update || print_warning "Failed to update after adding Docker repo"
    if sudo apt-get install -y ./docker-desktop-amd64.deb; then
        print_info "Docker Desktop installed successfully"
        rm -f docker-desktop-amd64.deb
    else
        print_warning "Failed to install Docker Desktop"
    fi
else
    print_warning "Failed to download Docker Desktop"
fi

# Download and install Neovim nightly
print_info "Installing Neovim nightly..."
if curl -L -o nvim-linux-x86_64.tar.gz https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz; then
    mkdir -p ~/neovim
    if tar xzvf nvim-linux-x86_64.tar.gz -C ~/neovim --strip-components=1; then
        echo 'alias nvim="$HOME/neovim/bin/nvim"' >> ~/.bash_profile
        print_info "Neovim nightly installed successfully"
        rm -f nvim-linux-x86_64.tar.gz
    else
        print_warning "Failed to extract Neovim"
    fi
else
    print_warning "Failed to download Neovim"
fi

# Install vscode
print_info "Installing VS Code..."
echo "code code/add-microsoft-repo boolean true" | sudo debconf-set-selections
sudo apt update || print_warning "Failed to update"
if sudo apt install -y code; then
    print_info "VS Code installed successfully"
else
    print_warning "Failed to install VS Code"
fi

print_info "Application setup complete!"
