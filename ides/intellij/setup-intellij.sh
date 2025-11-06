#!/bin/bash

#####################################
# IntelliJ IDEA Setup Script
# Installs IntelliJ IDEA and configures it
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

print_section() {
    echo -e "\n${BLUE}==== $1 ====${NC}\n"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        DISTRO="unknown"
    fi
}

# Install IntelliJ IDEA
install_intellij() {
    print_section "Installing IntelliJ IDEA"

    detect_distro

    echo "Select IntelliJ IDEA edition:"
    echo "1) Community (Free)"
    echo "2) Ultimate (Paid)"
    read -p "Enter choice [1-2]: " edition_choice

    case $edition_choice in
        1)
            EDITION="community"
            ;;
        2)
            EDITION="ultimate"
            print_warning "Ultimate edition requires a license"
            ;;
        *)
            print_warning "Invalid choice. Installing Community edition."
            EDITION="community"
            ;;
    esac

    case $DISTRO in
        ubuntu|debian)
            # Install via snap
            if [ "$EDITION" = "community" ]; then
                sudo snap install intellij-idea-community --classic
            else
                sudo snap install intellij-idea-ultimate --classic
            fi
            ;;
        fedora)
            # Install via snap
            if [ "$EDITION" = "community" ]; then
                sudo snap install intellij-idea-community --classic
            else
                sudo snap install intellij-idea-ultimate --classic
            fi
            ;;
        arch|manjaro)
            # Install via AUR
            if command_exists yay; then
                if [ "$EDITION" = "community" ]; then
                    yay -S --noconfirm intellij-idea-community-edition
                else
                    yay -S --noconfirm intellij-idea-ultimate-edition
                fi
            else
                print_warning "yay not found. Please install manually."
            fi
            ;;
        *)
            # Manual installation
            print_info "Downloading IntelliJ IDEA..."
            cd /tmp
            if [ "$EDITION" = "community" ]; then
                wget -O ideaIC.tar.gz "https://download.jetbrains.com/idea/ideaIC-latest.tar.gz"
                tar xzf ideaIC.tar.gz
                sudo mv idea-IC-* /opt/intellij-idea-community
                sudo ln -sf /opt/intellij-idea-community/bin/idea.sh /usr/local/bin/idea
            else
                wget -O ideaIU.tar.gz "https://download.jetbrains.com/idea/ideaIU-latest.tar.gz"
                tar xzf ideaIU.tar.gz
                sudo mv idea-IU-* /opt/intellij-idea-ultimate
                sudo ln -sf /opt/intellij-idea-ultimate/bin/idea.sh /usr/local/bin/idea
            fi
            rm -f idea*.tar.gz
            cd -
            ;;
    esac

    print_info "IntelliJ IDEA $EDITION installed"
}

# Install JetBrains Toolbox (recommended)
install_jetbrains_toolbox() {
    print_section "Installing JetBrains Toolbox"

    print_info "JetBrains Toolbox allows easy management of all JetBrains IDEs"
    read -p "Do you want to install JetBrains Toolbox? (y/n): " install_toolbox

    if [[ "$install_toolbox" != "y" ]]; then
        print_info "Skipping Toolbox installation"
        return
    fi

    cd /tmp
    wget -O jetbrains-toolbox.tar.gz "https://data.services.jetbrains.com/products/download?platform=linux&code=TBA"
    tar xzf jetbrains-toolbox.tar.gz
    TOOLBOX_DIR=$(find . -maxdepth 1 -type d -name 'jetbrains-toolbox-*' | head -1)
    cd "$TOOLBOX_DIR"
    ./jetbrains-toolbox
    cd /tmp
    rm -rf jetbrains-toolbox*

    print_info "JetBrains Toolbox installed and launched"
}

# Configure IntelliJ settings
configure_intellij() {
    print_section "Configuring IntelliJ IDEA"

    print_info "Recommended plugins:"
    echo "  - IdeaVim (Vim emulation)"
    echo "  - Rainbow Brackets"
    echo "  - GitToolBox"
    echo "  - Material Theme UI"
    echo "  - Key Promoter X"
    echo "  - String Manipulation"
    echo "  - .ignore"
    echo "  - Docker"
    echo "  - Markdown"

    print_info "\nRecommended settings:"
    echo "  - Enable 'Auto-import'"
    echo "  - Set tab size to 2 or 4 spaces"
    echo "  - Enable 'Format on save'"
    echo "  - Configure keyboard shortcuts"
    echo "  - Enable 'Show line numbers'"
    echo "  - Enable 'Show method separators'"

    print_warning "Configure these manually in IntelliJ IDEA settings"
}

# Create desktop entry if not exists
create_desktop_entry() {
    print_section "Creating Desktop Entry"

    if [ -f "$HOME/.local/share/applications/jetbrains-idea.desktop" ]; then
        print_info "Desktop entry already exists"
        return
    fi

    # Only create if manual installation was used
    if [ -d "/opt/intellij-idea-community" ] || [ -d "/opt/intellij-idea-ultimate" ]; then
        IDEA_PATH="/opt/intellij-idea-community"
        [ -d "/opt/intellij-idea-ultimate" ] && IDEA_PATH="/opt/intellij-idea-ultimate"

        mkdir -p ~/.local/share/applications

        cat > ~/.local/share/applications/jetbrains-idea.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=IntelliJ IDEA
Icon=$IDEA_PATH/bin/idea.svg
Exec=$IDEA_PATH/bin/idea.sh %f
Comment=Capable and Ergonomic IDE for JVM
Categories=Development;IDE;
Terminal=false
StartupWMClass=jetbrains-idea
EOF

        chmod +x ~/.local/share/applications/jetbrains-idea.desktop
        print_info "Desktop entry created"
    fi
}

# Install recommended JDK versions
install_jdks() {
    print_section "Installing JDK"

    print_info "IntelliJ IDEA can download and manage JDKs automatically"
    print_info "Or install manually:"

    detect_distro

    read -p "Do you want to install OpenJDK 17? (y/n): " install_jdk

    if [[ "$install_jdk" != "y" ]]; then
        return
    fi

    case $DISTRO in
        ubuntu|debian)
            sudo apt install -y openjdk-17-jdk openjdk-17-source
            ;;
        fedora)
            sudo dnf install -y java-17-openjdk java-17-openjdk-devel
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm jdk17-openjdk
            ;;
        *)
            print_warning "Please install JDK manually"
            ;;
    esac

    print_info "Installed JDK version:"
    java -version
}

main() {
    print_info "Starting IntelliJ IDEA Setup"
    print_info "==========================="

    install_intellij
    install_jetbrains_toolbox
    install_jdks
    create_desktop_entry
    configure_intellij

    print_info "\n==========================="
    print_info "IntelliJ IDEA setup complete!"
}

main
