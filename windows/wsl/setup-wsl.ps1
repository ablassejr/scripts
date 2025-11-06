# WSL (Windows Subsystem for Linux) Setup Script
# Installs and configures WSL 2

$ErrorActionPreference = "Stop"

function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput Green "[INFO] $Message"
}

function Write-Warn {
    param([string]$Message)
    Write-ColorOutput Yellow "[WARNING] $Message"
}

function Write-Section {
    param([string]$Message)
    Write-Host ""
    Write-ColorOutput Cyan "==== $Message ===="
    Write-Host ""
}

# Check if running as Administrator
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check if WSL is installed
function Test-WSLInstalled {
    try {
        $wslVersion = wsl --version 2>$null
        return $true
    } catch {
        return $false
    }
}

# Enable WSL feature
function Enable-WSLFeature {
    Write-Section "Enabling WSL Feature"

    if (!(Test-Admin)) {
        Write-Warn "This script must be run as Administrator"
        exit 1
    }

    # Enable Virtual Machine Platform
    Write-Info "Enabling Virtual Machine Platform..."
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

    # Enable WSL
    Write-Info "Enabling Windows Subsystem for Linux..."
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

    Write-Info "WSL features enabled"
    Write-Warn "Please restart your computer and run this script again"
}

# Install WSL
function Install-WSL {
    Write-Section "Installing WSL"

    if (Test-WSLInstalled) {
        Write-Info "WSL is already installed"
        wsl --version
        return
    }

    Write-Info "Installing WSL..."
    wsl --install

    Write-Info "WSL installed successfully"
}

# Set WSL 2 as default
function Set-WSL2Default {
    Write-Section "Setting WSL 2 as Default"

    wsl --set-default-version 2

    Write-Info "WSL 2 set as default version"
}

# List available distributions
function Get-WSLDistributions {
    Write-Section "Available Linux Distributions"

    wsl --list --online

    Write-Host ""
}

# Install Ubuntu (default)
function Install-UbuntuDistro {
    Write-Section "Installing Ubuntu Distribution"

    $existingDistros = wsl --list --quiet

    if ($existingDistros -match "Ubuntu") {
        Write-Info "Ubuntu is already installed"
        return
    }

    Write-Info "Installing Ubuntu..."
    wsl --install -d Ubuntu

    Write-Info "Ubuntu installed. Please complete the initial setup in the Ubuntu window."
}

# Install additional distributions
function Install-AdditionalDistros {
    Write-Section "Install Additional Distributions"

    Write-Host "Available distributions:"
    wsl --list --online

    Write-Host ""
    $install = Read-Host "Would you like to install additional distributions? (y/n)"

    if ($install -eq 'y') {
        $distro = Read-Host "Enter distribution name (e.g., Debian, kali-linux, openSUSE-42)"
        Write-Info "Installing $distro..."
        wsl --install -d $distro
    }
}

# Update WSL kernel
function Update-WSLKernel {
    Write-Section "Updating WSL Kernel"

    wsl --update

    Write-Info "WSL kernel updated"
}

# Configure WSL settings
function Configure-WSL {
    Write-Section "Configuring WSL"

    $wslConfigPath = "$env:USERPROFILE\.wslconfig"

    $wslConfig = @"
[wsl2]
# Limits VM memory
memory=4GB

# Sets amount of swap storage
swap=2GB

# Sets the VM to use
processors=2

# Turns off nested virtualization
nestedVirtualization=true

# Kernel command line
# kernelCommandLine=

[experimental]
# Enable DNS tunneling
dnsTunneling=true

# Enable network mirroring
networkingMode=mirrored

# Enable GPU support
autoMemoryReclaim=gradual
"@

    if (Test-Path $wslConfigPath) {
        $backup = "$wslConfigPath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item $wslConfigPath $backup
        Write-Info "Backed up existing .wslconfig to $backup"
    }

    $wslConfig | Out-File $wslConfigPath -Encoding UTF8
    Write-Info "WSL configured at $wslConfigPath"
}

# Install Windows Terminal integration
function Install-WindowsTerminal {
    Write-Section "Installing Windows Terminal"

    if (Get-Command wt -ErrorAction SilentlyContinue) {
        Write-Info "Windows Terminal is already installed"
        return
    }

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Info "Installing Windows Terminal..."
        winget install Microsoft.WindowsTerminal
    } else {
        Write-Warn "Please install Windows Terminal from Microsoft Store"
    }
}

# Install Docker Desktop with WSL 2 backend
function Install-DockerDesktop {
    Write-Section "Installing Docker Desktop"

    $dockerInstalled = Get-Command docker -ErrorAction SilentlyContinue

    if ($dockerInstalled) {
        Write-Info "Docker is already installed"
        return
    }

    $install = Read-Host "Would you like to install Docker Desktop with WSL 2 backend? (y/n)"

    if ($install -eq 'y') {
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Info "Installing Docker Desktop..."
            winget install Docker.DockerDesktop
        } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco install docker-desktop -y
        } else {
            Write-Warn "Please download Docker Desktop manually from https://www.docker.com/products/docker-desktop"
        }

        Write-Info "After installation, enable WSL 2 backend in Docker Desktop settings"
    }
}

# Show usage tips
function Show-Tips {
    Write-Section "WSL Usage Tips"

    Write-Host @'
Basic Commands:
  wsl                         Launch default distribution
  wsl -d <distro>             Launch specific distribution
  wsl --list                  List installed distributions
  wsl --list --online         List available distributions
  wsl --set-default <distro>  Set default distribution
  wsl --shutdown              Shutdown all distributions
  wsl --terminate <distro>    Terminate specific distribution
  wsl --update                Update WSL kernel

File Access:
  From Windows:               \\wsl$\<distro>\home\<user>
  From WSL:                   /mnt/c/Users/<user>

Configuration:
  WSL config:                 %USERPROFILE%\.wslconfig
  Distro config:              /etc/wsl.conf (inside distro)

Integration:
  - Windows Terminal automatically detects WSL distributions
  - VS Code: Install "Remote - WSL" extension
  - Docker Desktop can use WSL 2 backend

Useful Commands:
  wsl hostname -I             Get WSL IP address
  wsl export <distro> <file>  Export distribution
  wsl import <distro> <dir> <file>  Import distribution

Documentation:
  https://docs.microsoft.com/windows/wsl
'@
}

# Main execution
function Main {
    Write-Info "Starting WSL Setup"
    Write-Info "=================="

    if (!(Test-Admin)) {
        Write-Warn "This script should be run as Administrator for full functionality"
        $continue = Read-Host "Continue anyway? (y/n)"
        if ($continue -ne 'y') {
            Write-Info "Setup cancelled"
            exit
        }
    }

    # Check Windows version
    $osVersion = [System.Environment]::OSVersion.Version
    if ($osVersion.Major -lt 10 -or ($osVersion.Major -eq 10 -and $osVersion.Build -lt 19041)) {
        Write-Warn "WSL 2 requires Windows 10 version 2004 (Build 19041) or higher"
        Write-Warn "Please update Windows before continuing"
        exit 1
    }

    if (!(Test-WSLInstalled)) {
        Enable-WSLFeature
        Install-WSL
    } else {
        Write-Info "WSL is already installed"
    }

    Set-WSL2Default
    Update-WSLKernel
    Get-WSLDistributions
    Install-UbuntuDistro
    Install-AdditionalDistros
    Configure-WSL
    Install-WindowsTerminal
    Install-DockerDesktop
    Show-Tips

    Write-Host ""
    Write-Info "=================="
    Write-Info "WSL setup complete!"
    Write-Info "Launch with: wsl"
}

# Run main function
Main
