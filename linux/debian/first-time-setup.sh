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
        if ! sudo apt install -y "$pkg" 2>/dev/null; then
            print_warning "Failed to install: $pkg"
            failed+=("$pkg")
        else
            print_info "Successfully installed: $pkg"
        fi
    done

    if [ ${#failed[@]} -gt 0 ]; then
        print_warning "Failed packages: ${failed[*]}"
    fi
}

print_info "Updating package lists..."
sudo apt-get update || print_warning "Failed to update package lists"

print_info "Upgrading existing packages..."
sudo apt upgrade -y || print_warning "Failed to upgrade packages"

print_info "Installing essential packages..."
safe_apt_install make git curl gh wget dirmngr gpg gawk luarocks snap snapd composer flatpak unzip gcc lldb

print_info "Creating keyrings directory..."
sudo install -dm 755 /etc/apt/keyrings || print_error "Failed to create keyrings directory"

print_info "Adding mise GPG key..."
if wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg 1> /dev/null; then
    print_info "Mise GPG key added successfully"
else
    print_error "Failed to add mise GPG key"
    exit 1
fi

print_info "Adding mise repository..."
echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=amd64] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list

touch ~/.bash_profile
echo 'eval "$(/usr/bin/mise activate bash)"' > ~/.bash_profile

print_info "Updating package lists for mise..."
sudo apt update || print_warning "Failed to update after adding mise repo"

print_info "Installing mise..."
if sudo apt install -y mise; then
    print_info "Mise installed successfully"
else
    print_error "Failed to install mise"
fi

print_info "Installing mise tools..."
for tool in node python rust lua java; do
    if mise install "$tool"; then
        print_info "Successfully installed: $tool"
    else
        print_warning "Failed to install mise tool: $tool"
    fi
done

print_info "Installing chezmoi..."
if sh -c "$(curl -fsLS get.chezmoi.io)"; then
    print_info "Chezmoi installed successfully"
else
    print_warning "Failed to install chezmoi"
fi

print_info "Setup complete!"
