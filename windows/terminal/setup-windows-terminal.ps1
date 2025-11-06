# Windows Terminal Setup Script
# Configures Windows Terminal with useful settings

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

# Check if Windows Terminal is installed
function Test-WindowsTerminal {
    return (Get-Command wt -ErrorAction SilentlyContinue) -ne $null
}

# Install Windows Terminal
function Install-WindowsTerminal {
    Write-Section "Installing Windows Terminal"

    if (Test-WindowsTerminal) {
        Write-Info "Windows Terminal is already installed"
        return
    }

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Info "Installing via winget..."
        winget install Microsoft.WindowsTerminal
    } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Info "Installing via chocolatey..."
        choco install microsoft-windows-terminal -y
    } else {
        Write-Warn "Please install Windows Terminal from Microsoft Store"
        Write-Host "https://aka.ms/terminal"
        exit 1
    }

    Write-Info "Windows Terminal installed"
}

# Configure Windows Terminal settings
function Configure-WindowsTerminal {
    Write-Section "Configuring Windows Terminal"

    $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

    if (!(Test-Path $settingsPath)) {
        Write-Warn "Windows Terminal settings file not found"
        Write-Warn "Please launch Windows Terminal at least once before running this script"
        return
    }

    # Backup existing settings
    $backupPath = "$settingsPath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $settingsPath $backupPath
    Write-Info "Backed up existing settings to $backupPath"

    # Create settings configuration
    $settings = @'
{
    "$help": "https://aka.ms/terminal-documentation",
    "$schema": "https://aka.ms/terminal-profiles-schema",
    "defaultProfile": "{61c54bbd-c2c6-5271-96e7-009a87ff44bf}",
    "copyOnSelect": true,
    "copyFormatting": "none",
    "theme": "dark",
    "themes": [],
    "actions": [
        {
            "command": {
                "action": "copy",
                "singleLine": false
            },
            "keys": "ctrl+c"
        },
        {
            "command": "paste",
            "keys": "ctrl+v"
        },
        {
            "command": "find",
            "keys": "ctrl+shift+f"
        },
        {
            "command": {
                "action": "splitPane",
                "split": "auto",
                "splitMode": "duplicate"
            },
            "keys": "alt+shift+d"
        },
        {
            "command": "closePane",
            "keys": "ctrl+shift+w"
        },
        {
            "command": {
                "action": "moveFocus",
                "direction": "down"
            },
            "keys": "alt+down"
        },
        {
            "command": {
                "action": "moveFocus",
                "direction": "left"
            },
            "keys": "alt+left"
        },
        {
            "command": {
                "action": "moveFocus",
                "direction": "right"
            },
            "keys": "alt+right"
        },
        {
            "command": {
                "action": "moveFocus",
                "direction": "up"
            },
            "keys": "alt+up"
        },
        {
            "command": "toggleFullscreen",
            "keys": "alt+enter"
        },
        {
            "command": {
                "action": "newTab"
            },
            "keys": "ctrl+shift+t"
        }
    ],
    "profiles": {
        "defaults": {
            "font": {
                "face": "FiraCode Nerd Font",
                "size": 11,
                "weight": "normal"
            },
            "colorScheme": "One Half Dark",
            "cursorShape": "bar",
            "opacity": 95,
            "useAcrylic": true,
            "padding": "8, 8, 8, 8",
            "scrollbarState": "visible",
            "snapOnInput": true,
            "historySize": 9001,
            "bellStyle": "none"
        },
        "list": [
            {
                "guid": "{61c54bbd-c2c6-5271-96e7-009a87ff44bf}",
                "name": "Windows PowerShell",
                "commandline": "powershell.exe",
                "hidden": false,
                "icon": "ms-appx:///ProfileIcons/{61c54bbd-c2c6-5271-96e7-009a87ff44bf}.png"
            },
            {
                "guid": "{574e775e-4f2a-5b96-ac1e-a2962a402336}",
                "name": "PowerShell",
                "commandline": "pwsh.exe",
                "hidden": false,
                "source": "Windows.Terminal.PowershellCore",
                "icon": "ms-appx:///ProfileIcons/{574e775e-4f2a-5b96-ac1e-a2962a402336}.png"
            },
            {
                "guid": "{0caa0dad-35be-5f56-a8ff-afceeeaa6101}",
                "name": "Command Prompt",
                "commandline": "cmd.exe",
                "hidden": false,
                "icon": "ms-appx:///ProfileIcons/{0caa0dad-35be-5f56-a8ff-afceeeaa6101}.png"
            }
        ]
    },
    "schemes": [
        {
            "name": "One Half Dark",
            "black": "#282c34",
            "red": "#e06c75",
            "green": "#98c379",
            "yellow": "#e5c07b",
            "blue": "#61afef",
            "purple": "#c678dd",
            "cyan": "#56b6c2",
            "white": "#dcdfe4",
            "brightBlack": "#282c34",
            "brightRed": "#e06c75",
            "brightGreen": "#98c379",
            "brightYellow": "#e5c07b",
            "brightBlue": "#61afef",
            "brightPurple": "#c678dd",
            "brightCyan": "#56b6c2",
            "brightWhite": "#dcdfe4",
            "background": "#282c34",
            "foreground": "#dcdfe4",
            "selectionBackground": "#474e5d",
            "cursorColor": "#dcdfe4"
        },
        {
            "name": "Dracula",
            "black": "#21222c",
            "red": "#ff5555",
            "green": "#50fa7b",
            "yellow": "#f1fa8c",
            "blue": "#bd93f9",
            "purple": "#ff79c6",
            "cyan": "#8be9fd",
            "white": "#f8f8f2",
            "brightBlack": "#6272a4",
            "brightRed": "#ff6e6e",
            "brightGreen": "#69ff94",
            "brightYellow": "#ffffa5",
            "brightBlue": "#d6acff",
            "brightPurple": "#ff92df",
            "brightCyan": "#a4ffff",
            "brightWhite": "#ffffff",
            "background": "#282a36",
            "foreground": "#f8f8f2",
            "selectionBackground": "#44475a",
            "cursorColor": "#f8f8f2"
        }
    ]
}
'@

    $settings | Out-File $settingsPath -Encoding UTF8
    Write-Info "Windows Terminal configured"
}

# Install Nerd Fonts
function Install-NerdFonts {
    Write-Section "Installing Nerd Fonts"

    Write-Info "Downloading FiraCode Nerd Font..."

    $fontsPath = "$env:TEMP\nerdfonts"
    New-Item -ItemType Directory -Path $fontsPath -Force | Out-Null

    $fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraCode.zip"
    $fontZip = "$fontsPath\FiraCode.zip"

    try {
        Invoke-WebRequest -Uri $fontUrl -OutFile $fontZip
        Expand-Archive -Path $fontZip -DestinationPath $fontsPath -Force

        # Install fonts
        $FONTS = 0x14
        $objShell = New-Object -ComObject Shell.Application
        $objFolder = $objShell.Namespace($FONTS)

        $fontFiles = Get-ChildItem -Path $fontsPath -Filter "*.ttf"
        foreach ($fontFile in $fontFiles) {
            Write-Info "Installing $($fontFile.Name)..."
            $objFolder.CopyHere($fontFile.FullName)
        }

        Write-Info "Fonts installed successfully"
    } catch {
        Write-Warn "Failed to install fonts automatically"
        Write-Host "Please download manually from: https://www.nerdfonts.com/font-downloads"
    } finally {
        Remove-Item -Path $fontsPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Show usage tips
function Show-Tips {
    Write-Section "Windows Terminal Tips"

    Write-Host @'
Key Bindings:
  Ctrl+Shift+T        New tab
  Ctrl+Shift+W        Close pane/tab
  Ctrl+Shift+D        Duplicate tab
  Alt+Shift+D         Split pane
  Alt+Arrow           Navigate panes
  Alt+Enter           Fullscreen
  Ctrl+Shift+F        Find
  Ctrl++              Increase font size
  Ctrl+-              Decrease font size

Settings:
  Ctrl+,              Open settings
  Location:           %LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_*\LocalState\settings.json

Profiles:
  - PowerShell
  - Command Prompt
  - WSL distributions (auto-detected)

Customization:
  - Change color schemes in settings
  - Add custom profiles
  - Configure keyboard shortcuts
  - Set background images

Themes:
  Browse: https://windowsterminalthemes.dev/

Documentation:
  https://docs.microsoft.com/windows/terminal
'@
}

# Main execution
function Main {
    Write-Info "Starting Windows Terminal Setup"
    Write-Info "==============================="

    Install-WindowsTerminal
    Install-NerdFonts
    Configure-WindowsTerminal
    Show-Tips

    Write-Host ""
    Write-Info "==============================="
    Write-Info "Windows Terminal setup complete!"
    Write-Info "Launch Windows Terminal to see changes"
}

# Run main function
Main
