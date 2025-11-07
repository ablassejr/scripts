#!/bin/bash
set -e

sudo apt install -y  firefox-esr onedrive gnome-terminal libgtk-4-dev libadwaita-1-dev
sudo snap install --edge nvim --classic
sudo snap install zig --classic --beta

# zed
curl -f https://zed.dev/install.sh | sh

# ghostty
git clone https://github.com/ghostty-org/ghostty.git
cd ghostty
zig build -Doptimize=ReleaseFast
sudo zig build -Doptimize=ReleaseFast --prefix /usr/local install
cd ..

# Download and install the Dropbox package
cd ~ && wget -O dropbox.deb "https://www.dropbox.com/download?dl=packages/ubuntu/dropbox_2020.03.04_amd64.deb"
sudo apt install -y ./dropbox.deb

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Download and install Docker Desktop
curl -L -o docker-desktop-amd64.deb "https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-linux-amd64"
sudo apt-get update
sudo apt-get install -y ./docker-desktop-amd64.deb

# Download and install Neovim nightly
curl -L -o nvim-linux-x86_64.tar.gz https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz
mkdir -p ~/neovim
tar xzvf nvim-linux-x86_64.tar.gz -C ~/neovim --strip-components=1
echo 'alias nvim="$HOME/neovim/bin/nvim"' >> ~/.bash_profile

# vscode
echo "code code/add-microsoft-repo boolean true" | sudo debconf-set-selections
sudo apt update
sudo apt install -y code
