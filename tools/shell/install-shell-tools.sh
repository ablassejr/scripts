#!/bin/bash

#####################################
# Shell Tools Installation Script
# Installs tools listed in tools/shell/README.md
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

# Install curl
install_curl() {
    print_info "Installing curl..."
    if command_exists curl; then
        print_info "curl is already installed"
        return
    fi

    case $DISTRO in
        ubuntu|debian)
            sudo apt install -y curl
            ;;
        fedora)
            sudo dnf install -y curl
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm curl
            ;;
        *)
            print_warning "Cannot install curl on $DISTRO. Please install manually."
            ;;
    esac
}

# Install wget
install_wget() {
    print_info "Installing wget..."
    if command_exists wget; then
        print_info "wget is already installed"
        return
    fi

    case $DISTRO in
        ubuntu|debian)
            sudo apt install -y wget
            ;;
        fedora)
            sudo dnf install -y wget
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm wget
            ;;
        *)
            print_warning "Cannot install wget on $DISTRO. Please install manually."
            ;;
    esac
}

# Install git
install_git() {
    print_info "Installing git..."
    if command_exists git; then
        print_info "git is already installed"
        return
    fi

    case $DISTRO in
        ubuntu|debian)
            sudo apt install -y git
            ;;
        fedora)
            sudo dnf install -y git
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm git
            ;;
        *)
            print_warning "Cannot install git on $DISTRO. Please install manually."
            ;;
    esac
}

# Install mise
install_mise() {
    print_info "Installing mise..."
    if command_exists mise; then
        print_info "mise is already installed"
        return
    fi

    curl https://mise.run | sh
    if ! grep -q "mise activate bash" ~/.bashrc 2>/dev/null; then
        echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
    fi

    print_info "Installing mise tools: nodejs, python, cargo, ruby, neovim@0.12.0, rust..."
    ~/.local/bin/mise use --global node@lts
    ~/.local/bin/mise use --global python@latest
    ~/.local/bin/mise use --global ruby@latest
    ~/.local/bin/mise use --global rust@latest
    ~/.local/bin/mise use --global neovim@0.12.0
}

# Install unzip
install_unzip() {
    print_info "Installing unzip..."
    if command_exists unzip; then
        print_info "unzip is already installed"
        return
    fi

    case $DISTRO in
        ubuntu|debian)
            sudo apt install -y unzip
            ;;
        fedora)
            sudo dnf install -y unzip
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm unzip
            ;;
        *)
            print_warning "Cannot install unzip on $DISTRO. Please install manually."
            ;;
    esac
}

# Install fzf
install_fzf() {
    print_info "Installing fzf..."
    if command_exists fzf; then
        print_info "fzf is already installed"
        return
    fi

    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all
}

# Install guix
install_guix() {
    print_info "Installing guix..."
    if command_exists guix; then
        print_info "guix is already installed"
        return
    fi

    cd /tmp
    wget https://git.savannah.gnu.org/cgit/guix.git/plain/etc/guix-install.sh
    chmod +x guix-install.sh
    sudo ./guix-install.sh
    cd -
}

# Install zoxide
install_zoxide() {
    print_info "Installing zoxide..."
    if command_exists zoxide; then
        print_info "zoxide is already installed"
        return
    fi

    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    if ! grep -q "zoxide init bash" ~/.bashrc 2>/dev/null; then
        echo 'eval "$(zoxide init bash)"' >> ~/.bashrc
    fi
}

# Install blesh
install_blesh() {
    print_info "Installing blesh (ble.sh)..."
    if [ -f ~/.local/share/blesh/ble.sh ]; then
        print_info "blesh is already installed"
        return
    fi

    git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git /tmp/ble.sh
    make -C /tmp/ble.sh install PREFIX=~/.local
    if ! grep -q "source ~/.local/share/blesh/ble.sh" ~/.bashrc 2>/dev/null; then
        echo 'source ~/.local/share/blesh/ble.sh' >> ~/.bashrc
    fi
    rm -rf /tmp/ble.sh 2>/dev/null || true
}

# Install ssh
install_ssh() {
    print_info "Installing ssh..."
    if command_exists ssh; then
        print_info "ssh is already installed"
        return
    fi

    case $DISTRO in
        ubuntu|debian)
            sudo apt install -y openssh-client openssh-server
            ;;
        fedora)
            sudo dnf install -y openssh-clients openssh-server
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm openssh
            ;;
        *)
            print_warning "Cannot install ssh on $DISTRO. Please install manually."
            ;;
    esac
}

# Install tldr
install_tldr() {
    print_info "Installing tldr..."
    if command_exists tldr; then
        print_info "tldr is already installed"
        return
    fi

    case $DISTRO in
        ubuntu|debian)
            sudo apt install -y tldr
            ;;
        fedora)
            sudo dnf install -y tldr
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm tldr
            ;;
        *)
            # Install via npm if available
            if command_exists npm; then
                npm install -g tldr
            else
                print_warning "Cannot install tldr. Please install Node.js first or install manually."
            fi
            ;;
    esac
}

# Install cht.sh
install_chtsh() {
    print_info "Installing cht.sh..."
    if [ -f ~/.local/bin/cht.sh ]; then
        print_info "cht.sh is already installed"
        return
    fi

    mkdir -p ~/.local/bin
    curl -s https://cht.sh/:cht.sh > ~/.local/bin/cht.sh
    chmod +x ~/.local/bin/cht.sh

    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    fi
}

# Install oh-my-bash
install_oh_my_bash() {
    print_info "Installing oh-my-bash..."
    if [ -d ~/.oh-my-bash ]; then
        print_info "oh-my-bash is already installed"
        return
    fi

    bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
}

# Install GitHub Copilot CLI
install_copilot() {
    print_info "Installing GitHub Copilot CLI..."
    if command_exists github-copilot-cli; then
        print_info "GitHub Copilot CLI is already installed"
        return
    fi

    if command_exists npm; then
        npm install -g @githubnext/github-copilot-cli
    else
        print_warning "npm is not installed. Please install Node.js first."
        return
    fi
}

# Install Claude CLI
install_claude() {
    print_info "Installing Claude CLI..."

    if command_exists npm; then
        npm install -g @anthropic-ai/claude-code
    else
        print_warning "npm is not installed. Please install Node.js first or use mise."
        return
    fi
}

# Install Gemini CLI
install_gemini() {
    print_info "Installing Gemini CLI..."
    print_warning "Gemini CLI installation depends on your preferred method."
    print_warning "Please refer to Google AI documentation for installation instructions."
}

# Install chezmoi
install_chezmoi() {
    print_info "Installing chezmoi..."
    if command_exists chezmoi; then
        print_info "chezmoi is already installed"
        return
    fi

    sh -c "$(curl -fsLS get.chezmoi.io)"
}

# Install yadm
install_yadm() {
    print_info "Installing yadm..."
    if command_exists yadm; then
        print_info "yadm is already installed"
        return
    fi

    case $DISTRO in
        ubuntu|debian)
            sudo apt install -y yadm
            ;;
        fedora)
            sudo dnf install -y yadm
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm yadm
            ;;
        *)
            # Install manually
            curl -fLo ~/.local/bin/yadm https://github.com/TheLocehiliosan/yadm/raw/master/yadm
            chmod +x ~/.local/bin/yadm
            ;;
    esac
}

# Main installation function
main() {
    print_info "Starting Shell Tools Installation Script"
    print_info "========================================"

    detect_distro
    update_package_manager

    # Install all tools
    install_curl
    install_wget
    install_git
    install_unzip
    install_fzf
    install_zoxide
    install_ssh
    install_tldr
    install_chtsh
    install_mise  # This should be installed after curl
    install_guix
    install_blesh
    install_oh_my_bash
    install_copilot
    install_claude
    install_gemini
    install_chezmoi
    install_yadm

    print_info "========================================"
    print_info "Installation complete!"
    print_info "Please restart your terminal or run 'source ~/.bashrc' to apply changes."
    print_info "For mise tools, run: eval \"\$(~/.local/bin/mise activate bash)\""
}

# Run main function
main
