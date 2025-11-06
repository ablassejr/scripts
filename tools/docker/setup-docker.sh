#!/bin/bash

#####################################
# Docker Setup Script
# Installs Docker and Docker Compose
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

# Install Docker
install_docker() {
    print_section "Installing Docker"

    if command_exists docker; then
        print_info "Docker is already installed"
        docker --version
        return
    fi

    detect_distro

    case $DISTRO in
        ubuntu|debian)
            # Add Docker's official GPG key
            sudo apt-get update
            sudo apt-get install -y ca-certificates curl
            sudo install -m 0755 -d /etc/apt/keyrings
            sudo curl -fsSL https://download.docker.com/linux/$DISTRO/gpg -o /etc/apt/keyrings/docker.asc
            sudo chmod a+r /etc/apt/keyrings/docker.asc

            # Add the repository
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

        arch|manjaro)
            sudo pacman -S --noconfirm docker docker-compose
            ;;

        *)
            print_warning "Unknown distribution. Please install Docker manually."
            print_info "Visit: https://docs.docker.com/engine/install/"
            return
            ;;
    esac

    print_info "Docker installed successfully"
}

# Configure Docker
configure_docker() {
    print_section "Configuring Docker"

    # Enable and start Docker service
    sudo systemctl enable docker
    sudo systemctl start docker

    # Add current user to docker group
    sudo usermod -aG docker $USER

    print_info "Docker service enabled and started"
    print_warning "Please log out and back in for group membership to take effect"
}

# Install Docker Compose standalone (if needed)
install_docker_compose_standalone() {
    print_section "Checking Docker Compose"

    if docker compose version &>/dev/null; then
        print_info "Docker Compose (plugin) is installed"
        docker compose version
        return
    fi

    if command_exists docker-compose; then
        print_info "Docker Compose (standalone) is installed"
        docker-compose --version
        return
    fi

    print_info "Installing Docker Compose standalone..."

    DOCKER_COMPOSE_VERSION="v2.24.5"
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    print_info "Docker Compose installed"
    docker-compose --version
}

# Configure Docker daemon
configure_docker_daemon() {
    print_section "Configuring Docker Daemon"

    sudo mkdir -p /etc/docker

    cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "dns": ["8.8.8.8", "8.8.4.4"],
  "storage-driver": "overlay2"
}
EOF

    sudo systemctl restart docker
    print_info "Docker daemon configured"
}

# Install useful Docker tools
install_docker_tools() {
    print_section "Installing Docker Tools"

    # Lazy Docker (Terminal UI for Docker)
    if ! command_exists lazydocker; then
        print_info "Installing lazydocker..."
        curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
    fi

    # ctop (Top-like interface for containers)
    if ! command_exists ctop; then
        print_info "Installing ctop..."
        sudo wget https://github.com/bcicen/ctop/releases/download/v0.7.7/ctop-0.7.7-linux-amd64 -O /usr/local/bin/ctop
        sudo chmod +x /usr/local/bin/ctop
    fi
}

# Create useful aliases
create_docker_aliases() {
    print_section "Creating Docker Aliases"

    cat >> ~/.bash_aliases << 'EOF'

# Docker aliases
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dlog='docker logs -f'
alias dstop='docker stop $(docker ps -q)'
alias drm='docker rm $(docker ps -aq)'
alias drmi='docker rmi $(docker images -q)'
alias dprune='docker system prune -af'
alias dc='docker compose'
alias dcup='docker compose up -d'
alias dcdown='docker compose down'
alias dclogs='docker compose logs -f'

EOF

    print_info "Docker aliases added to ~/.bash_aliases"
}

# Run hello-world test
test_docker() {
    print_section "Testing Docker Installation"

    print_info "Running hello-world container..."

    if sudo docker run hello-world; then
        print_info "Docker is working correctly!"
    else
        print_error "Docker test failed"
        return 1
    fi
}

# Show usage tips
show_docker_tips() {
    print_section "Docker Usage Tips"

    cat << 'EOF'
Basic Commands:
  docker run <image>              Run a container
  docker ps                       List running containers
  docker ps -a                    List all containers
  docker images                   List images
  docker pull <image>             Pull an image
  docker stop <container>         Stop a container
  docker rm <container>           Remove a container
  docker rmi <image>              Remove an image

Docker Compose:
  docker compose up               Start services
  docker compose up -d            Start in detached mode
  docker compose down             Stop services
  docker compose logs             View logs
  docker compose ps               List services

Useful Tools:
  lazydocker                      Terminal UI for Docker
  ctop                            Top-like interface for containers

Documentation: https://docs.docker.com/
EOF
}

main() {
    print_info "Starting Docker Setup"
    print_info "===================="

    install_docker
    configure_docker
    install_docker_compose_standalone
    configure_docker_daemon
    install_docker_tools
    create_docker_aliases
    test_docker
    show_docker_tips

    print_info "\n===================="
    print_info "Docker setup complete!"
    print_warning "Please log out and back in to use Docker without sudo"
}

main
