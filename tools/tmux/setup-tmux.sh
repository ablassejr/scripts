#!/bin/bash

#####################################
# Tmux Setup Script
# Installs and configures Tmux
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

# Install Tmux
install_tmux() {
    print_section "Installing Tmux"

    if command_exists tmux; then
        print_info "Tmux is already installed"
        tmux -V
        return
    fi

    detect_distro

    case $DISTRO in
        ubuntu|debian)
            sudo apt install -y tmux
            ;;
        fedora)
            sudo dnf install -y tmux
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm tmux
            ;;
        *)
            print_warning "Unknown distribution. Please install tmux manually."
            return
            ;;
    esac

    print_info "Tmux installed successfully"
    tmux -V
}

# Configure Tmux
configure_tmux() {
    print_section "Configuring Tmux"

    cat > ~/.tmux.conf << 'EOF'
# Tmux Configuration

# Change prefix from Ctrl-b to Ctrl-a
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Enable mouse support
set -g mouse on

# Start windows and panes at 1, not 0
set -g base-index 1
setw -g pane-base-index 1

# Renumber windows when one is closed
set -g renumber-windows on

# Increase scrollback buffer size
set -g history-limit 10000

# Enable 256 colors
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",xterm-256color:Tc"

# Status bar
set -g status-position bottom
set -g status-justify left
set -g status-style 'bg=colour234 fg=colour137'
set -g status-left ''
set -g status-right '#[fg=colour233,bg=colour241,bold] %d/%m #[fg=colour233,bg=colour245,bold] %H:%M:%S '
set -g status-right-length 50
set -g status-left-length 20

setw -g window-status-current-style 'fg=colour1 bg=colour19 bold'
setw -g window-status-current-format ' #I#[fg=colour249]:#[fg=colour255]#W#[fg=colour249]#F '

setw -g window-status-style 'fg=colour9 bg=colour18'
setw -g window-status-format ' #I#[fg=colour237]:#[fg=colour250]#W#[fg=colour244]#F '

# Pane borders
set -g pane-border-style 'fg=colour238'
set -g pane-active-border-style 'fg=colour51'

# Message style
set -g message-style 'fg=colour232 bg=colour166 bold'

# Easy config reload
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# Split panes using | and -
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

# Switch panes using Alt-arrow without prefix
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Switch windows using Shift-arrow
bind -n S-Left previous-window
bind -n S-Right next-window

# Resize panes
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# Copy mode vi bindings
setw -g mode-keys vi
bind -T copy-mode-vi v send -X begin-selection
# Note: xclip must be installed for clipboard integration to work
bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "xclip -in -selection clipboard"

# No delay for escape key press
set -sg escape-time 0

# Enable activity alerts
setw -g monitor-activity on
set -g visual-activity off

# Synchronize panes
bind S setw synchronize-panes
EOF

    print_info "Tmux configuration created at ~/.tmux.conf"
}

# Install TPM (Tmux Plugin Manager)
install_tpm() {
    print_section "Installing TPM (Tmux Plugin Manager)"

    if [ -d "$HOME/.tmux/plugins/tpm" ]; then
        print_info "TPM already installed"
        return
    fi

    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

    # Add TPM configuration to tmux.conf
    cat >> ~/.tmux.conf << 'EOF'

# TPM (Tmux Plugin Manager)
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'tmux-plugins/tmux-yank'
set -g @plugin 'tmux-plugins/tmux-copycat'

# Enable automatic restore
set -g @continuum-restore 'on'

# Initialize TPM (keep this line at the very bottom)
run '~/.tmux/plugins/tpm/tpm'
EOF

    print_info "TPM installed. Press prefix + I inside tmux to install plugins"
}

# Create useful aliases
create_tmux_aliases() {
    print_section "Creating Tmux Aliases"

    cat >> ~/.bash_aliases << 'EOF'

# Tmux aliases
alias ta='tmux attach -t'
alias tad='tmux attach -d -t'
alias ts='tmux new-session -s'
alias tl='tmux list-sessions'
alias tksv='tmux kill-server'
alias tkss='tmux kill-session -t'

EOF

    print_info "Tmux aliases added to ~/.bash_aliases"
}

# Show usage tips
show_tmux_tips() {
    print_section "Tmux Usage Tips"

    cat << 'EOF'
Basic Commands:
  tmux                            Start a new session
  tmux new -s <name>              Start a new named session
  tmux ls                         List sessions
  tmux attach -t <name>           Attach to session
  tmux kill-session -t <name>     Kill session

Key Bindings (prefix = Ctrl-a):
  prefix + |                      Split vertically
  prefix + -                      Split horizontally
  prefix + c                      Create new window
  prefix + n                      Next window
  prefix + p                      Previous window
  prefix + d                      Detach from session
  prefix + [                      Enter copy mode
  prefix + ]                      Paste buffer
  prefix + r                      Reload config
  prefix + I                      Install plugins (TPM)

  Alt + Arrow keys                Switch panes
  Shift + Arrow keys              Switch windows

Plugins (TPM):
  prefix + I                      Install plugins
  prefix + U                      Update plugins
  prefix + alt + u                Uninstall plugins

Documentation: https://github.com/tmux/tmux/wiki
EOF
}

main() {
    print_info "Starting Tmux Setup"
    print_info "==================="

    install_tmux
    configure_tmux
    install_tpm
    create_tmux_aliases
    show_tmux_tips

    print_info "\n==================="
    print_info "Tmux setup complete!"
    print_info "Start tmux with: tmux"
    print_info "Press Ctrl-a + I inside tmux to install plugins"
}

main
