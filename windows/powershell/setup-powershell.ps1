# PowerShell Profile Setup Script
# Configures PowerShell with useful modules and settings

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

# Install PowerShell modules
function Install-PowerShellModules {
    Write-Section "Installing PowerShell Modules"

    # Set PSGallery as trusted
    if ((Get-PSRepository -Name PSGallery).InstallationPolicy -ne 'Trusted') {
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    }

    # Essential modules
    $modules = @(
        'PSReadLine',
        'posh-git',
        'Terminal-Icons',
        'PSFzf',
        'z'
    )

    foreach ($module in $modules) {
        if (!(Get-Module -ListAvailable -Name $module)) {
            Write-Info "Installing $module..."
            Install-Module -Name $module -Scope CurrentUser -Force
        } else {
            Write-Info "$module is already installed"
        }
    }

    Write-Info "PowerShell modules installed"
}

# Install Chocolatey
function Install-Chocolatey {
    Write-Section "Installing Chocolatey Package Manager"

    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Info "Chocolatey is already installed"
        return
    }

    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

    Write-Info "Chocolatey installed successfully"
}

# Install common tools via Chocolatey
function Install-CommonTools {
    Write-Section "Installing Common Tools"

    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Warn "Chocolatey not installed. Skipping tool installation."
        return
    }

    $tools = @(
        'git',
        'vscode',
        'nodejs',
        'python',
        'fzf',
        'ripgrep',
        'fd',
        'bat',
        'neovim'
    )

    foreach ($tool in $tools) {
        Write-Info "Installing $tool..."
        choco install $tool -y
    }

    Write-Info "Common tools installed"
}

# Install Windows Terminal
function Install-WindowsTerminal {
    Write-Section "Installing Windows Terminal"

    if (Get-Command wt -ErrorAction SilentlyContinue) {
        Write-Info "Windows Terminal is already installed"
        return
    }

    # Install via winget if available
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install Microsoft.WindowsTerminal
    } else {
        Write-Warn "Please install Windows Terminal from Microsoft Store"
    }
}

# Install Oh My Posh
function Install-OhMyPosh {
    Write-Section "Installing Oh My Posh"

    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        Write-Info "Oh My Posh is already installed"
        return
    }

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install JanDeDobbeleer.OhMyPosh -s winget
    } else {
        choco install oh-my-posh -y
    }

    Write-Info "Oh My Posh installed"
}

# Configure PowerShell Profile
function Configure-PowerShellProfile {
    Write-Section "Configuring PowerShell Profile"

    $profileContent = @'
# PowerShell Profile Configuration

# PSReadLine Configuration
Import-Module PSReadLine
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# Import useful modules
Import-Module posh-git
Import-Module Terminal-Icons

# PSFzf configuration
if (Get-Module -ListAvailable -Name PSFzf) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}

# z directory jumper
if (Get-Module -ListAvailable -Name z) {
    Import-Module z
}

# Oh My Posh prompt
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh | Invoke-Expression
}

# Aliases
Set-Alias -Name vim -Value nvim -ErrorAction SilentlyContinue
Set-Alias -Name g -Value git
Set-Alias -Name ll -Value Get-ChildItem

# Functions
function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }

function Get-GitStatus { git status }
Set-Alias -Name gs -Value Get-GitStatus

function Git-Add { git add $args }
Set-Alias -Name ga -Value Git-Add

function Git-Commit { git commit -m $args }
Set-Alias -Name gc -Value Git-Commit

function Git-Push { git push }
Set-Alias -Name gp -Value Git-Push

function Git-Pull { git pull }
Set-Alias -Name gl -Value Git-Pull

function which($command) {
    Get-Command -Name $command -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}

function touch($file) {
    "" | Out-File $file -Encoding ASCII
}

function mkcd($dir) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Set-Location $dir
}

# Enhanced ls
function ll {
    Get-ChildItem -Force $args
}

function la {
    Get-ChildItem -Force -Hidden $args
}

# Clear screen
function c { Clear-Host }

Write-Host "PowerShell Profile Loaded" -ForegroundColor Green
'@

    # Create profile directory if it doesn't exist
    $profileDir = Split-Path -Parent $PROFILE
    if (!(Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }

    # Backup existing profile
    if (Test-Path $PROFILE) {
        $backupPath = "$PROFILE.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item $PROFILE $backupPath
        Write-Info "Backed up existing profile to $backupPath"
    }

    # Write new profile
    $profileContent | Out-File $PROFILE -Encoding UTF8
    Write-Info "PowerShell profile configured at $PROFILE"
}

# Install fonts
function Install-Fonts {
    Write-Section "Installing Nerd Fonts"

    Write-Info "Please install Nerd Fonts manually from:"
    Write-Host "https://www.nerdfonts.com/font-downloads"
    Write-Host "Recommended: FiraCode Nerd Font, JetBrains Mono Nerd Font"
}

# Show usage tips
function Show-Tips {
    Write-Section "PowerShell Setup Tips"

    Write-Host @'
PowerShell Profile:
  Location: $PROFILE
  Reload: . $PROFILE

Key Bindings:
  Ctrl+R          Search command history (PSFzf)
  Ctrl+T          Search files (PSFzf)
  Tab             Menu complete
  UpArrow         History search backward

Aliases:
  gs              git status
  ga              git add
  gc              git commit
  gp              git push
  gl              git pull
  ..              cd ..
  ll              ls -Force

Functions:
  which <cmd>     Find command location
  touch <file>    Create empty file
  mkcd <dir>      Create and cd into directory

Oh My Posh:
  Themes: oh-my-posh config export ~/.poshthemes
  List themes: Get-PoshThemes
  Change theme: oh-my-posh init pwsh --config <theme>

Documentation:
  https://docs.microsoft.com/powershell
  https://ohmyposh.dev/
'@
}

# Main execution
function Main {
    Write-Info "Starting PowerShell Setup"
    Write-Info "========================"

    if (!(Test-Admin)) {
        Write-Warn "Not running as Administrator. Some features may not install."
        $continue = Read-Host "Continue anyway? (y/n)"
        if ($continue -ne 'y') {
            Write-Info "Setup cancelled"
            exit
        }
    }

    Install-Chocolatey
    Install-CommonTools
    Install-WindowsTerminal
    Install-PowerShellModules
    Install-OhMyPosh
    Configure-PowerShellProfile
    Install-Fonts
    Show-Tips

    Write-Host ""
    Write-Info "========================"
    Write-Info "PowerShell setup complete!"
    Write-Info "Restart PowerShell to apply changes"
}

# Run main function
Main
