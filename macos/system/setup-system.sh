#!/bin/bash

#####################################
# macOS System Preferences Setup Script
# Configures macOS system settings
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

# Check if running on macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo "This script is for macOS only!"
        exit 1
    fi
}

# General UI/UX tweaks
configure_general_ui() {
    print_section "Configuring General UI/UX"

    # Close any System Preferences panes
    osascript -e 'tell application "System Preferences" to quit'

    # Disable the sound effects on boot
    sudo nvram SystemAudioVolume=" "

    # Expand save panel by default
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

    # Expand print panel by default
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

    # Save to disk (not to iCloud) by default
    defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

    # Disable automatic termination of inactive apps
    defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true

    # Reveal IP address, hostname, OS version, etc. when clicking the clock in the login window
    sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

    print_info "General UI/UX configured"
}

# Trackpad, mouse, keyboard, Bluetooth accessories
configure_input_devices() {
    print_section "Configuring Input Devices"

    # Trackpad: enable tap to click
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

    # Trackpad: map bottom right corner to right-click
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
    defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
    defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true

    # Increase sound quality for Bluetooth headphones/headsets
    defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

    # Enable full keyboard access for all controls
    defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

    # Set a blazingly fast keyboard repeat rate
    defaults write NSGlobalDomain KeyRepeat -int 2
    defaults write NSGlobalDomain InitialKeyRepeat -int 15

    # Disable auto-correct
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

    print_info "Input devices configured"
}

# Screen settings
configure_screen() {
    print_section "Configuring Screen Settings"

    # Require password immediately after sleep or screen saver begins
    defaults write com.apple.screensaver askForPassword -int 1
    defaults write com.apple.screensaver askForPasswordDelay -int 0

    # Save screenshots to the desktop
    defaults write com.apple.screencapture location -string "${HOME}/Desktop"

    # Save screenshots in PNG format
    defaults write com.apple.screencapture type -string "png"

    # Disable shadow in screenshots
    defaults write com.apple.screencapture disable-shadow -bool true

    # Enable subpixel font rendering on non-Apple LCDs
    defaults write NSGlobalDomain AppleFontSmoothing -int 2

    # Enable HiDPI display modes
    sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true

    print_info "Screen settings configured"
}

# Finder settings
configure_finder() {
    print_section "Configuring Finder"

    # Show icons for hard drives, servers, and removable media on the desktop
    defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
    defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
    defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
    defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

    # Finder: show hidden files by default
    defaults write com.apple.finder AppleShowAllFiles -bool true

    # Finder: show all filename extensions
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true

    # Finder: show status bar
    defaults write com.apple.finder ShowStatusBar -bool true

    # Finder: show path bar
    defaults write com.apple.finder ShowPathbar -bool true

    # Display full POSIX path as Finder window title
    defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

    # Keep folders on top when sorting by name
    defaults write com.apple.finder _FXSortFoldersFirst -bool true

    # When performing a search, search the current folder by default
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

    # Disable the warning when changing a file extension
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

    # Avoid creating .DS_Store files on network or USB volumes
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

    # Use list view in all Finder windows by default
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

    # Show the ~/Library folder
    chflags nohidden ~/Library

    # Show the /Volumes folder
    sudo chflags nohidden /Volumes

    print_info "Finder configured"
}

# Dock settings
configure_dock() {
    print_section "Configuring Dock"

    # Set the icon size of Dock items
    defaults write com.apple.dock tilesize -int 48

    # Change minimize/maximize window effect
    defaults write com.apple.dock mineffect -string "scale"

    # Minimize windows into their application's icon
    defaults write com.apple.dock minimize-to-application -bool true

    # Show indicator lights for open applications in the Dock
    defaults write com.apple.dock show-process-indicators -bool true

    # Don't automatically rearrange Spaces based on most recent use
    defaults write com.apple.dock mru-spaces -bool false

    # Remove the auto-hiding Dock delay
    defaults write com.apple.dock autohide-delay -float 0

    # Automatically hide and show the Dock
    defaults write com.apple.dock autohide -bool true

    # Make Dock icons of hidden applications translucent
    defaults write com.apple.dock showhidden -bool true

    # Don't show recent applications in Dock
    defaults write com.apple.dock show-recents -bool false

    print_info "Dock configured"
}

# Safari & WebKit
configure_safari() {
    print_section "Configuring Safari"

    # Privacy: don't send search queries to Apple
    defaults write com.apple.Safari UniversalSearchEnabled -bool false
    defaults write com.apple.Safari SuppressSearchSuggestions -bool true

    # Show the full URL in the address bar
    defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true

    # Set Safari's home page to about:blank
    defaults write com.apple.Safari HomePage -string "about:blank"

    # Prevent Safari from opening 'safe' files automatically after downloading
    defaults write com.apple.Safari AutoOpenSafeDownloads -bool false

    # Enable Safari's debug menu
    defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

    # Enable the Develop menu and the Web Inspector in Safari
    defaults write com.apple.Safari IncludeDevelopMenu -bool true
    defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
    defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

    # Enable continuous spellchecking
    defaults write com.apple.Safari WebContinuousSpellCheckingEnabled -bool true

    print_info "Safari configured"
}

# Activity Monitor
configure_activity_monitor() {
    print_section "Configuring Activity Monitor"

    # Show the main window when launching Activity Monitor
    defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

    # Visualize CPU usage in the Activity Monitor Dock icon
    defaults write com.apple.ActivityMonitor IconType -int 5

    # Show all processes in Activity Monitor
    defaults write com.apple.ActivityMonitor ShowCategory -int 0

    # Sort Activity Monitor results by CPU usage
    defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
    defaults write com.apple.ActivityMonitor SortDirection -int 0

    print_info "Activity Monitor configured"
}

# Time Machine
configure_time_machine() {
    print_section "Configuring Time Machine"

    # Prevent Time Machine from prompting to use new hard drives as backup volume
    defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

    print_info "Time Machine configured"
}

# Restart affected applications
restart_applications() {
    print_section "Restarting Applications"

    for app in "Activity Monitor" \
        "cfprefsd" \
        "Dock" \
        "Finder" \
        "Safari" \
        "SystemUIServer"; do
        killall "${app}" &> /dev/null || true
    done

    print_info "Applications restarted"
}

main() {
    print_info "Starting macOS System Setup"
    print_info "==========================="

    check_macos

    print_warning "This will modify your system preferences."
    read -p "Continue? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then
        print_info "Setup cancelled"
        exit 0
    fi

    configure_general_ui
    configure_input_devices
    configure_screen
    configure_finder
    configure_dock
    configure_safari
    configure_activity_monitor
    configure_time_machine
    restart_applications

    print_info "\n==========================="
    print_info "System setup complete!"
    print_info "Some changes may require a logout/restart to take effect"
}

main
