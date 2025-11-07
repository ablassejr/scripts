#!/bin/bash

#####################################
# DevDocs Setup Script for Arch Linux
# Installs and configures DevDocs - API Documentation Browser
# Repository: https://github.com/freeCodeCamp/devdocs
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

# Show installation options
show_installation_options() {
    print_section "DevDocs Installation Options"

    cat << 'EOF'
DevDocs can be installed in multiple ways on Arch Linux:

1. Desktop Application (AUR)
   - Easy to use, standalone desktop app
   - Offline documentation access
   - Native system integration

2. Docker Container
   - Isolated environment
   - Easy to manage and update
   - Web-based interface on localhost:9292

3. Self-Hosted (Source)
   - Full control over installation
   - Requires Ruby, Node.js
   - Web-based interface

4. Web Version
   - No installation required
   - Access at https://devdocs.io
   - Works offline with service worker

EOF

    echo -n "Select installation method (1-4): "
    read -r INSTALL_METHOD
}

# Install yay if not present
ensure_yay() {
    if ! command_exists yay; then
        print_info "Installing yay AUR helper..."
        sudo pacman -S --needed --noconfirm base-devel git
        cd /tmp
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd -
        rm -rf /tmp/yay
    fi
}

# Install DevDocs Desktop from AUR
install_desktop_app() {
    print_section "Installing DevDocs Desktop Application"

    ensure_yay

    # Try devdocs-desktop-bin first (binary package, faster)
    print_info "Installing devdocs-desktop from AUR..."

    if yay -S --noconfirm devdocs-desktop-bin; then
        print_info "DevDocs Desktop installed successfully!"
    elif yay -S --noconfirm devdocs-desktop; then
        print_info "DevDocs Desktop installed successfully!"
    else
        print_error "Failed to install DevDocs Desktop from AUR"
        print_info "You can try manually: yay -S devdocs-desktop"
        return 1
    fi

    print_info "You can launch DevDocs from your application menu"
}

# Install Docker if not present
ensure_docker() {
    if ! command_exists docker; then
        print_info "Installing Docker..."
        sudo pacman -S --noconfirm docker docker-compose
        sudo systemctl enable --now docker
        sudo usermod -aG docker $USER
        print_warning "Added $USER to docker group. You may need to log out and back in."

        # Try to use docker with sudo for this session
        print_info "Using sudo for Docker commands in this session..."
    fi
}

# Install DevDocs using Docker
install_docker_version() {
    print_section "Installing DevDocs via Docker"

    ensure_docker

    print_info "Pulling DevDocs Docker image..."
    sudo docker pull ghcr.io/freecodecamp/devdocs:latest

    print_info "Starting DevDocs container..."
    sudo docker run --name devdocs -d \
        -p 9292:9292 \
        --restart unless-stopped \
        ghcr.io/freecodecamp/devdocs:latest

    print_info "DevDocs is now running!"
    print_info "Access it at: http://localhost:9292"

    # Create systemd service for auto-start
    create_docker_service
}

# Create systemd service for Docker container
create_docker_service() {
    print_info "Creating systemd service for DevDocs..."

    sudo mkdir -p /etc/systemd/system

    cat << 'EOF' | sudo tee /etc/systemd/system/devdocs-docker.service > /dev/null
[Unit]
Description=DevDocs Docker Container
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStartPre=-/usr/bin/docker stop devdocs
ExecStartPre=-/usr/bin/docker rm devdocs
ExecStart=/usr/bin/docker run --name devdocs -d -p 9292:9292 --restart unless-stopped ghcr.io/freecodecamp/devdocs:latest
ExecStop=/usr/bin/docker stop devdocs
ExecStopPost=/usr/bin/docker rm devdocs

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable devdocs-docker.service

    print_info "DevDocs service created and enabled"
}

# Install dependencies for self-hosted version
install_selfhosted_dependencies() {
    print_section "Installing Dependencies for Self-Hosted DevDocs"

    print_info "Installing Ruby, Node.js, and other dependencies..."

    # Install Ruby (required version 3.4.1 or compatible)
    sudo pacman -S --noconfirm ruby

    # Install Node.js (for JavaScript runtime)
    sudo pacman -S --noconfirm nodejs npm

    # Install libcurl
    sudo pacman -S --noconfirm curl

    # Install git
    sudo pacman -S --noconfirm git

    # Install bundler for Ruby
    sudo gem install bundler

    print_info "Dependencies installed successfully"
}

# Install DevDocs from source
install_selfhosted() {
    print_section "Installing DevDocs from Source"

    install_selfhosted_dependencies

    DEVDOCS_DIR="$HOME/.local/share/devdocs"

    print_info "Cloning DevDocs repository..."
    if [ -d "$DEVDOCS_DIR" ]; then
        print_warning "DevDocs directory already exists at $DEVDOCS_DIR"
        echo -n "Remove and reinstall? (y/n): "
        read -r REINSTALL
        if [[ "$REINSTALL" =~ ^[Yy]$ ]]; then
            rm -rf "$DEVDOCS_DIR"
        else
            print_info "Skipping clone..."
        fi
    fi

    if [ ! -d "$DEVDOCS_DIR" ]; then
        mkdir -p "$(dirname "$DEVDOCS_DIR")"
        git clone https://github.com/freeCodeCamp/devdocs.git "$DEVDOCS_DIR"
    fi

    cd "$DEVDOCS_DIR"

    print_info "Installing Ruby dependencies..."
    bundle install

    print_info "Setting up DevDocs..."
    thor docs:download --all || print_warning "Optional: You can download specific docs later with: thor docs:download <doc>"

    print_info "Creating start script..."
    create_start_script "$DEVDOCS_DIR"

    print_info "Creating systemd service..."
    create_selfhosted_service "$DEVDOCS_DIR"

    print_info "DevDocs installed at: $DEVDOCS_DIR"
    print_info "Start DevDocs with: devdocs-start"
    print_info "Or enable service: systemctl --user enable --now devdocs.service"
}

# Create convenient start script
create_start_script() {
    local devdocs_dir="$1"

    cat << EOF > "$HOME/.local/bin/devdocs-start"
#!/bin/bash
cd "$devdocs_dir"
bundle exec rackup -o 0.0.0.0 -p 9292
EOF

    chmod +x "$HOME/.local/bin/devdocs-start"

    # Ensure ~/.local/bin is in PATH
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        print_info "Added ~/.local/bin to PATH in ~/.bashrc"
    fi
}

# Create systemd user service for self-hosted version
create_selfhosted_service() {
    local devdocs_dir="$1"

    mkdir -p "$HOME/.config/systemd/user"

    cat << EOF > "$HOME/.config/systemd/user/devdocs.service"
[Unit]
Description=DevDocs Documentation Browser
After=network.target

[Service]
Type=simple
WorkingDirectory=$devdocs_dir
ExecStart=/usr/bin/bundle exec rackup -o 0.0.0.0 -p 9292
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF

    systemctl --user daemon-reload

    print_info "Systemd service created"
    print_info "Enable with: systemctl --user enable --now devdocs.service"
}

# Show usage information
show_usage_info() {
    print_section "DevDocs Usage Information"

    case $INSTALL_METHOD in
        1)
            cat << 'EOF'
Desktop Application:
  - Launch from your application menu
  - Or run: devdocs-desktop (if in PATH)
  - Documentation is downloaded on-demand
  - Works offline after initial download

EOF
            ;;
        2)
            cat << 'EOF'
Docker Version:
  - Access at: http://localhost:9292
  - Container management:
    - Stop: docker stop devdocs
    - Start: docker start devdocs
    - Restart: docker restart devdocs
    - Remove: docker rm -f devdocs
  - View logs: docker logs devdocs
  - Update: docker pull ghcr.io/freecodecamp/devdocs:latest && docker restart devdocs

Systemd Service:
  - Status: systemctl status devdocs-docker.service
  - Stop: sudo systemctl stop devdocs-docker.service
  - Disable auto-start: sudo systemctl disable devdocs-docker.service

EOF
            ;;
        3)
            cat << 'EOF'
Self-Hosted Version:
  - Access at: http://localhost:9292
  - Start manually: devdocs-start
  - Or use systemd:
    - Enable: systemctl --user enable --now devdocs.service
    - Status: systemctl --user status devdocs.service
    - Stop: systemctl --user stop devdocs.service
    - Logs: journalctl --user -u devdocs.service -f

  - Download documentation:
    - List available: thor docs:list
    - Download specific: thor docs:download <doc>
    - Download all: thor docs:download --all

  - Update:
    - cd ~/.local/share/devdocs
    - git pull
    - bundle install
    - Restart service

EOF
            ;;
        4)
            cat << 'EOF'
Web Version:
  - Access at: https://devdocs.io
  - Works offline with service worker after first visit
  - No installation or maintenance required
  - Always up-to-date
  - Sync settings across devices with browser sync

EOF
            ;;
    esac

    cat << 'EOF'
General DevDocs Tips:
  - Press '?' to see keyboard shortcuts
  - Use fuzzy search to find documentation quickly
  - Enable/disable documentation sets in settings
  - DevDocs supports 400+ API documentation sets
  - Popular docs: JavaScript, Python, Ruby, PHP, Go, Rust, etc.

Resources:
  - GitHub: https://github.com/freeCodeCamp/devdocs
  - Website: https://devdocs.io
  - Contributing: https://github.com/freeCodeCamp/devdocs/blob/main/CONTRIBUTING.md

EOF
}

# Create desktop entry for self-hosted version
create_desktop_entry() {
    if [ "$INSTALL_METHOD" != "3" ]; then
        return
    fi

    print_info "Creating desktop entry..."

    mkdir -p "$HOME/.local/share/applications"

    cat << EOF > "$HOME/.local/share/applications/devdocs.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=DevDocs
Comment=API Documentation Browser
Exec=xdg-open http://localhost:9292
Icon=web-browser
Terminal=false
Categories=Development;Documentation;
Keywords=documentation;api;docs;developer;
EOF

    print_info "Desktop entry created at ~/.local/share/applications/devdocs.desktop"
}

# Main installation flow
main() {
    print_info "DevDocs Setup Script for Arch Linux"
    print_info "===================================="

    # Show options and get user choice
    show_installation_options

    case $INSTALL_METHOD in
        1)
            install_desktop_app
            ;;
        2)
            install_docker_version
            ;;
        3)
            install_selfhosted
            create_desktop_entry
            ;;
        4)
            print_info "Opening DevDocs web version..."
            xdg-open https://devdocs.io 2>/dev/null || print_info "Visit https://devdocs.io in your browser"
            print_info "No installation required!"
            ;;
        *)
            print_error "Invalid selection. Please run the script again."
            exit 1
            ;;
    esac

    show_usage_info

    print_info "\n===================================="
    print_info "DevDocs setup complete!"

    if [ "$INSTALL_METHOD" = "2" ] || [ "$INSTALL_METHOD" = "3" ]; then
        print_info "Access DevDocs at: http://localhost:9292"
    fi
}

main
