# Scripts

A centralized repository for setup scripts across various operating systems, development tools, and platforms.

## 📁 Repository Structure

This repository is organized to store setup scripts for different platforms, tools, and environments:

### 🐧 Linux

Setup files for various Linux distributions:

- `linux/ubuntu/` - Ubuntu-specific setups
- `linux/fedora/` - Fedora-specific setups
- `linux/arch/` - Arch Linux setups
- `linux/debian/` - Debian-specific setups
- `linux/general/` - General Linux setups (applicable across distributions)

### 🪟 Windows

Setup files for Windows environments:

- `windows/powershell/` - PowerShell profiles and scripts
- `windows/wsl/` - Windows Subsystem for Linux setups
- `windows/terminal/` - Windows Terminal settings
- `windows/registry/` - Registry tweaks and settings

### 🍎 macOS

Setup files for macOS:

- `macos/homebrew/` - Homebrew setups and package lists
- `macos/terminal/` - Terminal and shell setups
- `macos/system/` - System preferences and settings

### 💻 IDEs

Setup files for Integrated Development Environments:

- `ides/vscode/` - Visual Studio Code settings, extensions, and keybindings
- `ides/intellij/` - IntelliJ IDEA setups
- `ides/vim/` - Vim setups (.vimrc, plugins)
- `ides/neovim/` - Neovim setups
- `ides/emacs/` - Emacs setups
- `ides/sublime/` - Sublime Text settings
- `ides/atom/` - Atom editor setups

### ✏️ Text Editors

Setup files for lightweight text editors:

- `editors/nano/` - Nano editor setups
- `editors/micro/` - Micro editor settings

### 🛠️ Developer Tools

Setup files for common development tools:

- `tools/git/` - Git setups (.gitconfig, .gitignore templates)
- `tools/docker/` - Docker setups and compose files
- `tools/kubernetes/` - Kubernetes configs and manifests
- `tools/shell/` - Shell setups
  - `tools/shell/alacritty/` - Alacritty setups
  - `tools/shell/kitty/` - Kitty setups
  - `tools/shell/ghostty/` - Ghostty setups
  - `tools/shell/wezterm/` - Wezterm setups
- `tools/tmux/` - Tmux setups

### 🗄️ Databases

Setup files for database systems:

- `databases/mysql/` - MySQL setups
- `databases/postgresql/` - PostgreSQL setups
- `databases/mongodb/` - MongoDB setups
- `databases/redis/` - Redis setups

### ☁️ Cloud Platforms

Setup files for cloud services:

- `cloud/aws/` - AWS CLI and service setups
- `cloud/azure/` - Azure CLI setups
- `cloud/gcp/` - Google Cloud Platform setups

## 🚀 Usage

1. Browse to the directory that matches your platform or tool
2. Copy the setup files to the appropriate location on your system
3. Customize the setups to match your preferences
4. Keep this repository updated as you refine your setups

## 📝 Contributing to This Repository

This is a personal setup repository, but feel free to:

- Use any setups as reference for your own setups
- Submit issues if you find errors
- Suggest improvements through pull requests

## ⚠️ Important Notes

- Always backup your existing setup files before replacing them
- Review setups before applying them to ensure compatibility with your system
- Sensitive information (API keys, passwords, tokens) should NEVER be committed to this repository
- Use environment variables or separate credential managers for sensitive data

## 📋 Future Plans

- Add example setups for each category
- Create installation scripts for automated setup
- Document best practices for each platform
- Add dotfile management with symbolic links

## 📄 License

These setups are provided as-is for personal use.
