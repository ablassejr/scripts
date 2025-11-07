# DevDocs Setup for Arch Linux

Automated installation script for [DevDocs](https://devdocs.io) - an open-source API documentation browser that combines multiple API documentations in a clean and organized interface.

## What is DevDocs?

DevDocs is a free and open-source API documentation browser with:
- 400+ documentation sets (JavaScript, Python, Ruby, PHP, Go, Rust, and more)
- Fast, offline-capable searching
- Keyboard shortcuts
- Mobile-friendly interface
- Customizable documentation sets

## Installation

Run the setup script:

```bash
./setup-devdocs-arch.sh
```

The script will present you with multiple installation options:

### 1. Desktop Application (AUR)
- Standalone desktop application
- Native system integration
- Offline documentation access
- Best for: Users who want a dedicated app

### 2. Docker Container
- Isolated environment
- Easy to manage and update
- Web interface on `http://localhost:9292`
- Auto-starts with systemd service
- Best for: Users who prefer containerized applications

### 3. Self-Hosted (From Source)
- Full control over installation
- Uses Ruby and Node.js
- Web interface on `http://localhost:9292`
- Includes systemd service for auto-start
- Best for: Developers who want full control

### 4. Web Version
- No installation required
- Access at https://devdocs.io
- Works offline with service worker
- Best for: Quick access without local installation

## Features

The script automatically:
- Detects and installs missing dependencies
- Configures systemd services (for Docker and self-hosted options)
- Creates convenient start scripts
- Sets up desktop entries
- Provides comprehensive usage instructions

## Requirements

### Desktop App
- AUR helper (yay) - automatically installed if missing

### Docker Version
- Docker - automatically installed if missing

### Self-Hosted Version
- Ruby 3.x
- Node.js
- libcurl
- Git
- All automatically installed by the script

## Usage

After installation:

### Desktop App
Launch from your application menu or run `devdocs-desktop`

### Docker Version
```bash
# Access at http://localhost:9292
# Manage container
docker stop devdocs
docker start devdocs
docker restart devdocs

# Or use systemd
systemctl status devdocs-docker.service
```

### Self-Hosted Version
```bash
# Start manually
devdocs-start

# Or use systemd
systemctl --user enable --now devdocs.service
systemctl --user status devdocs.service

# Download documentation
cd ~/.local/share/devdocs
thor docs:list              # List available docs
thor docs:download python   # Download specific doc
thor docs:download --all    # Download all docs
```

## Documentation Sets

DevDocs includes documentation for:
- Languages: JavaScript, Python, Ruby, PHP, Go, Rust, C++, Java, etc.
- Frameworks: React, Vue, Django, Rails, Laravel, etc.
- Tools: Git, Docker, Kubernetes, Nginx, etc.
- Databases: PostgreSQL, MySQL, MongoDB, Redis, etc.
- And 400+ more...

## Keyboard Shortcuts

Once DevDocs is running:
- Press `?` to see all keyboard shortcuts
- `/` to focus search
- `↑` `↓` to navigate results
- `Enter` to select
- `Esc` to close

## Troubleshooting

### Desktop App Won't Launch
```bash
# Reinstall with:
yay -S devdocs-desktop --rebuild
```

### Docker Container Issues
```bash
# Check logs
docker logs devdocs

# Restart container
docker restart devdocs

# Remove and recreate
docker rm -f devdocs
docker pull ghcr.io/freecodecamp/devdocs:latest
docker run --name devdocs -d -p 9292:9292 --restart unless-stopped ghcr.io/freecodecamp/devdocs:latest
```

### Self-Hosted Issues
```bash
# Check service status
systemctl --user status devdocs.service

# View logs
journalctl --user -u devdocs.service -f

# Update installation
cd ~/.local/share/devdocs
git pull
bundle install
systemctl --user restart devdocs.service
```

## Resources

- Official Website: https://devdocs.io
- GitHub Repository: https://github.com/freeCodeCamp/devdocs
- Contributing Guide: https://github.com/freeCodeCamp/devdocs/blob/main/CONTRIBUTING.md

## License

DevDocs is licensed under the Mozilla Public License 2.0.
