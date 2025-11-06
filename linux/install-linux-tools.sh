#!/bin/bash

#####################################
# Linux Tools Installation Script
# Installs tools listed in linux/README.md
#####################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        DISTRO_VERSION=$VERSION_ID
    elif command_exists lsb_release; then
        DISTRO=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
        DISTRO_VERSION=$(lsb_release -sr)
    else
        print_error "Cannot detect Linux distribution"
        exit 1
    fi
    print_info "Detected distribution: $DISTRO $DISTRO_VERSION"
}

# Update package manager
update_package_manager() {
    print_info "Updating package manager..."
    case $DISTRO in
        ubuntu|debian)
            sudo apt update
            ;;
        fedora)
            sudo dnf check-update || true
            ;;
        arch|manjaro)
            sudo pacman -Sy
            ;;
        *)
            print_warning "Unknown distribution. Skipping package manager update."
            ;;
    esac
}

# Install snap/snapd
install_snap() {
    print_info "Installing snap/snapd..."
    if command_exists snap; then
        print_info "snapd is already installed"
        return
    fi

    case $DISTRO in
        ubuntu|debian)
            sudo apt install -y snapd
            sudo systemctl enable --now snapd.socket
            ;;
        fedora)
            sudo dnf install -y snapd
            sudo systemctl enable --now snapd.socket
            sudo ln -s /var/lib/snapd/snap /snap
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm snapd
            sudo systemctl enable --now snapd.socket
            ;;
        *)
            print_warning "Cannot install snapd on $DISTRO. Please install manually."
            ;;
    esac
}

# Install flatpak
install_flatpak() {
    print_info "Installing flatpak..."
    if command_exists flatpak; then
        print_info "flatpak is already installed"
        return
    fi

    case $DISTRO in
        ubuntu|debian)
            sudo apt install -y flatpak
            ;;
        fedora)
            sudo dnf install -y flatpak
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm flatpak
            ;;
        *)
            print_warning "Cannot install flatpak on $DISTRO. Please install manually."
            ;;
    esac
}

# Install bashmarks
install_bashmarks() {
    print_info "Installing bashmarks..."
    if [ -d "$HOME/.local/bin/bashmarks" ]; then
        print_info "bashmarks is already installed"
        return
    fi

    git clone https://github.com/huyng/bashmarks.git /tmp/bashmarks
    cd /tmp/bashmarks
    make install
    cd -
    print_info "Please add 'source ~/.local/bin/bashmarks.sh' to your .bashrc"
}

# Install zed
install_zed() {
    print_info "Installing zed..."
    if command_exists zed; then
        print_info "zed is already installed"
        return
    fi

    curl -f https://zed.dev/install.sh | sh
}

# Install neovim
install_neovim() {
    print_info "Installing neovim..."
    if command_exists nvim; then
        print_info "neovim is already installed"
        return
    fi

    case $DISTRO in
        ubuntu|debian)
            sudo apt install -y neovim
            ;;
        fedora)
            sudo dnf install -y neovim
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm neovim
            ;;
        *)
            print_warning "Cannot install neovim on $DISTRO. Please install manually."
            ;;
    esac
}

# Install micro
install_micro() {
    print_info "Installing micro..."
    if command_exists micro; then
        print_info "micro is already installed"
        return
    fi

    curl https://getmic.ro | bash
    sudo mv micro /usr/local/bin/
}

# Install docker
install_docker() {
    print_info "Installing docker..."
    if command_exists docker; then
        print_info "docker is already installed"
        return
    fi

    case $DISTRO in
        ubuntu|debian)
            # Add Docker's official GPG key
            sudo apt-get update
            sudo apt-get install -y ca-certificates curl
            sudo install -m 0755 -d /etc/apt/keyrings
            sudo curl -fsSL https://download.docker.com/linux/$DISTRO/gpg -o /etc/apt/keyrings/docker.asc
            sudo chmod a+r /etc/apt/keyrings/docker.asc

            # Add the repository to Apt sources
            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$DISTRO \
              $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
              sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        fedora)
            sudo dnf -y install dnf-plugins-core
            sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        *)
            print_warning "Cannot install docker on $DISTRO. Please install manually."
            return
            ;;
    esac

    # Add user to docker group
    sudo usermod -aG docker $USER
    sudo systemctl enable --now docker
    print_info "You may need to log out and back in for docker group changes to take effect"
}

# Install firefox
install_firefox() {
    print_info "Installing firefox..."
    if command_exists firefox; then
        print_info "firefox is already installed"
        return
    fi

    case $DISTRO in
        ubuntu|debian)
            sudo apt install -y firefox
            ;;
        fedora)
            sudo dnf install -y firefox
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm firefox
            ;;
        *)
            print_warning "Cannot install firefox on $DISTRO. Please install manually."
            ;;
    esac
}

# Install composer
install_composer() {
    print_info "Installing composer..."
    if command_exists composer; then
        print_info "composer is already installed"
        return
    fi

    EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

    if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
        print_error "Invalid installer checksum"
        rm composer-setup.php
        return 1
    fi

    php composer-setup.php --quiet
    rm composer-setup.php
    sudo mv composer.phar /usr/local/bin/composer
}

# Install ghostty
install_ghostty() {
    print_info "Installing ghostty..."
    if command_exists ghostty; then
        print_info "ghostty is already installed"
        return
    fi

    print_warning "Ghostty requires manual installation. Please visit: https://ghostty.org"
    print_warning "Or use the specific distribution script in linux/fedora/install_ghostty_fedora.sh"
}

# Install pcloud
install_pcloud() {
    print_info "Installing pcloud..."
    print_warning "pCloud requires manual download from: https://www.pcloud.com/download-free-online-cloud-file-storage.html"
}

# Install dropbox
install_dropbox() {
    print_info "Installing dropbox..."
    if command_exists dropbox; then
        print_info "dropbox is already installed"
        return
    fi

    case $DISTRO in
        ubuntu|debian)
            cd /tmp
            wget -O dropbox.deb "https://www.dropbox.com/download?dl=packages/ubuntu/dropbox_2020.03.04_amd64.deb"
            sudo apt install -y ./dropbox.deb
            rm dropbox.deb
            cd -
            ;;
        fedora)
            cd /tmp
            wget -O dropbox.rpm "https://www.dropbox.com/download?dl=packages/fedora/nautilus-dropbox-2020.03.04-1.fedora.x86_64.rpm"
            sudo dnf install -y ./dropbox.rpm
            rm dropbox.rpm
            cd -
            ;;
        *)
            print_warning "Cannot install dropbox on $DISTRO. Please install manually."
            ;;
    esac
}

# Install github desktop
install_github_desktop() {
    print_info "Installing github desktop..."

    case $DISTRO in
        ubuntu|debian)
            wget -qO - https://apt.packages.shiftkey.dev/gpg.key | gpg --dearmor | sudo tee /usr/share/keyrings/shiftkey-packages.gpg > /dev/null
            sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/shiftkey-packages.gpg] https://apt.packages.shiftkey.dev/ubuntu/ any main" > /etc/apt/sources.list.d/shiftkey-packages.list'
            sudo apt update
            sudo apt install -y github-desktop
            ;;
        *)
            print_warning "GitHub Desktop is primarily available for Ubuntu/Debian. Please install manually from: https://github.com/shiftkey/desktop"
            ;;
    esac
}

# Install gitkraken
install_gitkraken() {
    print_info "Installing gitkraken..."

    case $DISTRO in
        ubuntu|debian)
            wget https://release.gitkraken.com/linux/gitkraken-amd64.deb
            sudo apt install -y ./gitkraken-amd64.deb
            rm gitkraken-amd64.deb
            ;;
        *)
            print_warning "Please download GitKraken manually from: https://www.gitkraken.com/download"
            ;;
    esac
}

# Install nvidia drivers
install_nvidia_drivers() {
    print_info "Checking for NVIDIA GPU..."

    if ! lspci | grep -i nvidia > /dev/null; then
        print_warning "No NVIDIA GPU detected. Skipping NVIDIA driver installation."
        return
    fi

    print_info "NVIDIA GPU detected. Installing drivers..."

    case $DISTRO in
        ubuntu|debian)
            sudo apt install -y nvidia-driver-545
            ;;
        fedora)
            sudo dnf install -y akmod-nvidia
            ;;
        *)
            print_warning "Please install NVIDIA drivers manually for $DISTRO"
            ;;
    esac
}

# Install rsync
install_rsync() {
    print_info "Installing rsync..."
    if command_exists rsync; then
        print_info "rsync is already installed"
        return
    fi

    case $DISTRO in
        ubuntu|debian)
            sudo apt install -y rsync
            ;;
        fedora)
            sudo dnf install -y rsync
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm rsync
            ;;
        *)
            print_warning "Cannot install rsync on $DISTRO. Please install manually."
            ;;
    esac
}

# Install razer drivers
install_razer_drivers() {
    print_info "Installing razer drivers (OpenRazer)..."

    case $DISTRO in
        ubuntu|debian)
            sudo add-apt-repository ppa:openrazer/stable -y
            sudo apt update
            sudo apt install -y openrazer-meta
            ;;
        fedora)
            sudo dnf config-manager --add-repo https://download.opensuse.org/repositories/hardware:razer/Fedora_$(rpm -E %fedora)/hardware:razer.repo
            sudo dnf install -y openrazer-meta
            ;;
        *)
            print_warning "Please install OpenRazer manually from: https://openrazer.github.io"
            ;;
    esac
}

# Main installation function
main() {
    print_info "Starting Linux Tools Installation Script"
    print_info "========================================"

    detect_distro
    update_package_manager

    # Install all tools
    install_snap
    install_flatpak
    install_bashmarks
    install_zed
    install_neovim
    install_micro
    install_docker
    install_firefox
    install_composer
    install_ghostty
    install_pcloud
    install_dropbox
    install_github_desktop
    install_gitkraken
    install_nvidia_drivers
    install_rsync
    install_razer_drivers

    print_info "========================================"
    print_info "Installation complete!"
    print_info "Some applications may require a system restart or logout to work properly."
}

# Run main function
main
