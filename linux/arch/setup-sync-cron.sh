#!/bin/bash
#
# setup-sync-cron.sh - Setup automated cron job for syncing between desktop and laptop
#
# This script configures a cron job to automatically run the sync-machines.sh script
# at regular intervals. It intelligently determines the sync direction based on the
# current machine's hostname.
#
# Usage:
#   ./setup-sync-cron.sh [OPTIONS]
#
# Options:
#   --interval MINUTES    Sync interval in minutes (default: 30)
#   --direction DIRECTION Sync direction: to-laptop, to-desktop, or auto (default: auto)
#   --dry-run            Test the sync with dry-run mode
#   --remove             Remove the cron job
#   --list               List current sync cron jobs
#   -h, --help           Show this help message
#

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

# Script directory (where sync-machines.sh is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYNC_SCRIPT="${SCRIPT_DIR}/sync-machines.sh"

# Machine identifiers (must match the hostnames in sync-machines.sh)
DESKTOP_HOST="draogo-omarchy-desktop"
LAPTOP_HOST="draogo-omarchy-laptop"

# Default settings
DEFAULT_INTERVAL=30  # minutes
CRON_COMMENT="omarchy-sync-job"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================================================
# FUNCTIONS
# ============================================================================

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

print_usage() {
    cat << 'EOF'
Usage: ./setup-sync-cron.sh [OPTIONS]

This script sets up a cron job to automatically sync your home directory
between your desktop and laptop Arch Linux machines using rsync.

OPTIONS:
    --interval MINUTES    How often to sync (default: 30 minutes)
                         Examples: 15, 30, 60, 120

    --direction DIRECTION Which direction to sync:
                         - auto (default): Automatically determine based on hostname
                         - to-laptop: Always sync from this machine to laptop
                         - to-desktop: Always sync from this machine to desktop

    --dry-run            Configure cron to run syncs in dry-run mode (preview only)

    --remove             Remove the sync cron job

    --list               List all current sync-related cron jobs

    -h, --help           Show this help message

EXAMPLES:
    # Setup auto-sync every 30 minutes (default)
    ./setup-sync-cron.sh

    # Setup sync every hour
    ./setup-sync-cron.sh --interval 60

    # Setup to always sync to laptop, every 15 minutes
    ./setup-sync-cron.sh --interval 15 --direction to-laptop

    # Setup with dry-run mode (for testing)
    ./setup-sync-cron.sh --dry-run

    # Remove the cron job
    ./setup-sync-cron.sh --remove

    # List current sync jobs
    ./setup-sync-cron.sh --list

NOTES:
    - The script will automatically detect if you're on desktop or laptop
    - SSH keys must be set up between machines for passwordless authentication
    - The sync uses the exclude/include patterns defined in sync-machines.sh
    - Logs are stored in ~/.local/share/sync-logs/
    - To manually trigger a sync, run sync-machines.sh directly

MACHINE DETECTION:
    Desktop hostname: draogo-omarchy-desktop
    Laptop hostname:  draogo-omarchy-laptop

    If your hostname doesn't match, edit both this script and sync-machines.sh
    to update the DESKTOP_HOST and LAPTOP_HOST variables.

EOF
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_dependencies() {
    local missing_deps=()

    if ! command_exists rsync; then
        missing_deps+=("rsync")
    fi

    if ! command_exists ssh; then
        missing_deps+=("openssh")
    fi

    if ! command_exists crontab; then
        missing_deps+=("cronie")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        print_info "Install with: sudo pacman -S ${missing_deps[*]}"
        exit 1
    fi
}

check_sync_script() {
    if [ ! -f "${SYNC_SCRIPT}" ]; then
        print_error "Sync script not found at: ${SYNC_SCRIPT}"
        print_info "Please ensure sync-machines.sh is in the same directory as this script"
        exit 1
    fi

    if [ ! -x "${SYNC_SCRIPT}" ]; then
        print_warning "Sync script is not executable, making it executable..."
        chmod +x "${SYNC_SCRIPT}"
    fi
}

detect_machine() {
    local hostname
    hostname=$(hostname)

    print_info "Current hostname: ${hostname}"

    if [[ "${hostname}" == "${DESKTOP_HOST}" ]]; then
        echo "desktop"
    elif [[ "${hostname}" == "${LAPTOP_HOST}" ]]; then
        echo "laptop"
    else
        print_warning "Hostname '${hostname}' does not match expected desktop or laptop names"
        print_warning "Expected: ${DESKTOP_HOST} or ${LAPTOP_HOST}"
        echo "unknown"
    fi
}

determine_sync_direction() {
    local direction="$1"
    local machine_type
    machine_type=$(detect_machine)

    if [[ "${direction}" == "auto" ]]; then
        case "${machine_type}" in
            desktop)
                echo "to-laptop"
                ;;
            laptop)
                echo "to-desktop"
                ;;
            unknown)
                print_error "Cannot auto-detect sync direction with unknown hostname"
                print_info "Please specify --direction manually (to-laptop or to-desktop)"
                exit 1
                ;;
        esac
    else
        echo "${direction}"
    fi
}

convert_interval_to_cron() {
    local minutes="$1"

    # Validate interval
    if ! [[ "${minutes}" =~ ^[0-9]+$ ]] || [ "${minutes}" -lt 1 ]; then
        print_error "Invalid interval: ${minutes}"
        print_info "Interval must be a positive number of minutes"
        exit 1
    fi

    # Convert to cron format
    if [ "${minutes}" -lt 60 ]; then
        # Every N minutes
        echo "*/${minutes} * * * *"
    elif [ "${minutes}" -eq 60 ]; then
        # Every hour
        echo "0 * * * *"
    elif [ "${minutes}" -eq 120 ]; then
        # Every 2 hours
        echo "0 */2 * * *"
    elif [ "${minutes}" -eq 180 ]; then
        # Every 3 hours
        echo "0 */3 * * *"
    elif [ "${minutes}" -eq 240 ]; then
        # Every 4 hours
        echo "0 */4 * * *"
    elif [ "${minutes}" -eq 360 ]; then
        # Every 6 hours
        echo "0 */6 * * *"
    elif [ "${minutes}" -eq 720 ]; then
        # Every 12 hours
        echo "0 */12 * * *"
    elif [ "${minutes}" -eq 1440 ]; then
        # Once a day at midnight
        echo "0 0 * * *"
    else
        # For other intervals, use simple division
        local hours=$((minutes / 60))
        if [ $((minutes % 60)) -eq 0 ] && [ "${hours}" -lt 24 ]; then
            echo "0 */${hours} * * *"
        else
            # Fall back to every N minutes for non-standard intervals
            echo "*/${minutes} * * * *"
        fi
    fi
}

enable_cron_service() {
    print_info "Ensuring cron service is enabled and running..."

    if systemctl is-enabled cronie.service &>/dev/null; then
        print_info "Cron service already enabled"
    else
        print_info "Enabling cron service..."
        sudo systemctl enable cronie.service
    fi

    if systemctl is-active cronie.service &>/dev/null; then
        print_info "Cron service is running"
    else
        print_info "Starting cron service..."
        sudo systemctl start cronie.service
    fi
}

remove_cron_job() {
    print_section "Removing Sync Cron Job"

    # Get current crontab
    local current_crontab
    current_crontab=$(crontab -l 2>/dev/null || echo "")

    if echo "${current_crontab}" | grep -q "${CRON_COMMENT}"; then
        # Remove lines containing our comment
        local new_crontab
        new_crontab=$(echo "${current_crontab}" | grep -v "${CRON_COMMENT}")

        # Update crontab
        echo "${new_crontab}" | crontab -

        print_info "Sync cron job removed successfully"
    else
        print_warning "No sync cron job found to remove"
    fi
}

list_cron_jobs() {
    print_section "Current Sync Cron Jobs"

    local current_crontab
    current_crontab=$(crontab -l 2>/dev/null || echo "")

    if echo "${current_crontab}" | grep -q "${CRON_COMMENT}"; then
        echo "${current_crontab}" | grep -A1 "${CRON_COMMENT}" | grep -v "^--$"
    else
        print_info "No sync cron jobs found"
    fi
}

add_cron_job() {
    local interval="$1"
    local direction="$2"
    local dry_run_flag="$3"

    print_section "Setting Up Sync Cron Job"

    # Determine actual sync direction
    local actual_direction
    actual_direction=$(determine_sync_direction "${direction}")
    print_info "Sync direction: ${actual_direction}"

    # Convert interval to cron format
    local cron_schedule
    cron_schedule=$(convert_interval_to_cron "${interval}")
    print_info "Cron schedule: ${cron_schedule} (every ${interval} minutes)"

    # Build the cron command
    local cron_command="${SYNC_SCRIPT} ${actual_direction}"
    if [[ "${dry_run_flag}" == "true" ]]; then
        cron_command="${cron_command} --dry-run"
        print_warning "Cron job will run in DRY-RUN mode (no actual changes)"
    fi

    # Redirect output to log file with timestamp
    local log_redirect=">> \${HOME}/.local/share/sync-logs/cron-sync.log 2>&1"

    # Remove existing sync cron job if present
    remove_cron_job

    # Get current crontab
    local current_crontab
    current_crontab=$(crontab -l 2>/dev/null || echo "")

    # Create new crontab entry
    local new_entry="# ${CRON_COMMENT} - Auto-sync every ${interval} minutes"
    new_entry="${new_entry}\n${cron_schedule} ${cron_command} ${log_redirect}"

    # Combine and install new crontab
    local new_crontab
    if [ -n "${current_crontab}" ]; then
        new_crontab="${current_crontab}\n${new_entry}"
    else
        new_crontab="${new_entry}"
    fi

    echo -e "${new_crontab}" | crontab -

    print_info "Cron job added successfully!"
    echo ""
    print_info "Configuration:"
    echo "  - Interval: Every ${interval} minutes"
    echo "  - Direction: ${actual_direction}"
    echo "  - Dry-run: ${dry_run_flag}"
    echo "  - Command: ${cron_command}"
    echo ""
    print_info "Logs will be written to: ~/.local/share/sync-logs/"
    print_info "To view logs: tail -f ~/.local/share/sync-logs/cron-sync.log"
    echo ""
    print_info "To test manually, run: ${SYNC_SCRIPT} ${actual_direction} --dry-run"
}

test_ssh_connection() {
    print_section "Testing SSH Connection"

    local direction="$1"
    local target_host

    case "${direction}" in
        to-laptop)
            target_host="${LAPTOP_HOST}"
            ;;
        to-desktop)
            target_host="${DESKTOP_HOST}"
            ;;
        *)
            print_warning "Cannot test SSH connection for direction: ${direction}"
            return 0
            ;;
    esac

    print_info "Testing connection to ${USER}@${target_host}..."

    if ssh -o ConnectTimeout=5 -o BatchMode=yes "${USER}@${target_host}" exit 2>/dev/null; then
        print_info "SSH connection successful!"
        return 0
    else
        print_error "Cannot connect to ${USER}@${target_host}"
        echo ""
        print_warning "SSH passwordless authentication is required for cron sync"
        echo ""
        echo "To set up SSH keys:"
        echo "  1. Generate SSH key (if you don't have one):"
        echo "     ssh-keygen -t ed25519 -C \"your_email@example.com\""
        echo ""
        echo "  2. Copy key to remote machine:"
        echo "     ssh-copy-id ${USER}@${target_host}"
        echo ""
        echo "  3. Test connection:"
        echo "     ssh ${USER}@${target_host}"
        echo ""
        print_info "You can still set up the cron job, but it won't work until SSH is configured"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

create_log_directory() {
    local log_dir="${HOME}/.local/share/sync-logs"
    if [ ! -d "${log_dir}" ]; then
        print_info "Creating log directory: ${log_dir}"
        mkdir -p "${log_dir}"
    fi
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    # Parse arguments
    local interval="${DEFAULT_INTERVAL}"
    local direction="auto"
    local dry_run="false"
    local action="add"

    while [[ $# -gt 0 ]]; do
        case $1 in
            --interval)
                interval="$2"
                shift 2
                ;;
            --direction)
                direction="$2"
                if [[ ! "${direction}" =~ ^(auto|to-laptop|to-desktop)$ ]]; then
                    print_error "Invalid direction: ${direction}"
                    print_info "Valid options: auto, to-laptop, to-desktop"
                    exit 1
                fi
                shift 2
                ;;
            --dry-run)
                dry_run="true"
                shift
                ;;
            --remove)
                action="remove"
                shift
                ;;
            --list)
                action="list"
                shift
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo ""
                print_usage
                exit 1
                ;;
        esac
    done

    # Execute requested action
    case "${action}" in
        list)
            list_cron_jobs
            exit 0
            ;;
        remove)
            remove_cron_job
            exit 0
            ;;
        add)
            print_info "Setting up omarchy sync cron job"

            # Check dependencies
            check_dependencies

            # Check sync script exists
            check_sync_script

            # Enable cron service
            enable_cron_service

            # Create log directory
            create_log_directory

            # Determine actual direction for SSH test
            local actual_direction
            actual_direction=$(determine_sync_direction "${direction}")

            # Test SSH connection (only if not in dry-run)
            if [[ "${dry_run}" == "false" ]]; then
                test_ssh_connection "${actual_direction}"
            fi

            # Add the cron job
            add_cron_job "${interval}" "${direction}" "${dry_run}"

            # Show helpful info
            echo ""
            print_section "Next Steps"
            echo "1. The cron job is now active and will run every ${interval} minutes"
            echo "2. Monitor logs: tail -f ~/.local/share/sync-logs/cron-sync.log"
            echo "3. Test manually: ${SYNC_SCRIPT} ${actual_direction} --dry-run"
            echo "4. List cron jobs: crontab -l"
            echo "5. Remove cron job: $0 --remove"
            echo ""
            print_info "Setup complete!"
            ;;
    esac
}

main "$@"
