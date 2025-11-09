#!/bin/bash

# Docker Desktop Installation Script for Arch Linux
# This script downloads and installs Docker Desktop on Arch Linux

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then
        print_error "Please do not run this script as root. It will request sudo when needed."
        exit 1
    fi
}

# Function to check if Docker Desktop is already installed
check_existing_installation() {
    if command -v docker-desktop &> /dev/null; then
        print_warning "Docker Desktop appears to be already installed."
        read -p "Do you want to reinstall? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Installation cancelled."
            exit 0
        fi
    fi
}

# Main installation function
main() {
    print_info "Starting Docker Desktop installation for Arch Linux"
    echo

    # Check if running as root
    check_root

    # Check for existing installation
    check_existing_installation

    # Define download URLs
    DOCKER_DESKTOP_URL="https://desktop.docker.com/linux/main/amd64/docker-desktop-x86_64.pkg.tar.zst"
    CHECKSUM_URL="https://desktop.docker.com/linux/main/amd64/checksums.txt"
    DOWNLOAD_DIR="/tmp/docker-desktop-install"
    PACKAGE_NAME="docker-desktop-x86_64.pkg.tar.zst"

    # Create temporary directory
    print_info "Creating temporary download directory..."
    mkdir -p "$DOWNLOAD_DIR"
    cd "$DOWNLOAD_DIR"

    # Download Docker Desktop package
    print_info "Downloading Docker Desktop package..."
    if ! wget -q --show-progress "$DOCKER_DESKTOP_URL" -O "$PACKAGE_NAME"; then
        print_error "Failed to download Docker Desktop package."
        exit 1
    fi
    print_success "Docker Desktop package downloaded successfully"

    # Download checksums
    print_info "Downloading checksums file..."
    if ! wget -q "$CHECKSUM_URL" -O checksums.txt; then
        print_warning "Failed to download checksums file. Skipping verification."
    else
        print_info "Verifying package integrity..."
        # Extract the checksum for our package
        EXPECTED_CHECKSUM=$(grep "$PACKAGE_NAME" checksums.txt | awk '{print $1}')
        if [ -n "$EXPECTED_CHECKSUM" ]; then
            ACTUAL_CHECKSUM=$(sha256sum "$PACKAGE_NAME" | awk '{print $1}')
            if [ "$EXPECTED_CHECKSUM" = "$ACTUAL_CHECKSUM" ]; then
                print_success "Package integrity verified successfully"
            else
                print_error "Checksum verification failed!"
                print_error "Expected: $EXPECTED_CHECKSUM"
                print_error "Actual:   $ACTUAL_CHECKSUM"
                exit 1
            fi
        else
            print_warning "Could not find checksum for package. Skipping verification."
        fi
    fi

    # Install Docker Desktop
    print_info "Installing Docker Desktop..."
    print_info "This will require sudo privileges..."
    if sudo pacman -U --noconfirm "$PACKAGE_NAME"; then
        print_success "Docker Desktop installed successfully!"
    else
        print_error "Failed to install Docker Desktop."
        exit 1
    fi

    # Cleanup
    print_info "Cleaning up temporary files..."
    cd ~
    rm -rf "$DOWNLOAD_DIR"
    print_success "Cleanup completed"

    echo
    print_success "Docker Desktop installation completed!"
    echo
    print_info "Next steps:"
    echo "  1. Start Docker Desktop from your application menu or run: systemctl --user start docker-desktop"
    echo "  2. Docker Desktop will be available at /opt/docker-desktop"
    echo "  3. You may need to log out and log back in for all changes to take effect"
    echo
    print_info "For more information, visit: https://docs.docker.com/desktop/install/linux/"
}

# Run main function
main
