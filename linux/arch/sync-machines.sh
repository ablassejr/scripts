#!/bin/bash
#
# sync-machines.sh - Bidirectional rsync script for syncing home directory
# between desktop and laptop Arch Linux installations
#
# Usage:
#   ./sync-machines.sh [to-laptop|to-desktop] [--dry-run]
#

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

# Remote machine settings (customize these)
DESKTOP_HOST="draogo-omarchy-desktop"  # SSH hostname or IP for desktop
LAPTOP_HOST="draogo-omarchy-laptop"    # SSH hostname or IP for laptop
REMOTE_USER="${USER}"   # Username on remote machine (defaults to current user)

# Source directory (always use home directory)
SOURCE_DIR="${HOME}/"

# Log settings
LOG_DIR="${HOME}/.local/share/sync-logs"
LOG_FILE="${LOG_DIR}/sync-$(date +%Y%m%d-%H%M%S).log"

# ============================================================================
# RSYNC OPTIONS
# ============================================================================

# Archive mode: preserves permissions, timestamps, symbolic links, etc.
# -v: verbose
# -h: human-readable numbers
# --progress: show progress during transfer
# --stats: give file-transfer stats
# --delete: delete files on receiver that don't exist on sender
# --delete-excluded: also delete excluded files from dest dirs
# -z: compress during transfer
# --partial: keep partially transferred files
# --partial-dir: put partial files in this directory
RSYNC_OPTS=(
    -avh
    --progress
    --stats
    --delete
    --delete-excluded
    -z
    --partial
    --partial-dir=.rsync-partial
)

# ============================================================================
# EXCLUDE PATTERNS
# ============================================================================

# Common directories and files to exclude from sync
EXCLUDES=(
    # Cache directories
    '.cache/'
    '.npm/'
    '.yarn/'
    '.pnpm-store/'
    '.cargo/registry/'
    '.cargo/git/'
    '.rustup/toolchains/'
    '.gradle/caches/'
    '.m2/repository/'
    'node_modules/'
    '__pycache__/'
    '.pytest_cache/'

    # Temporary files
    '.tmp/'
    'tmp/'
    '*.tmp'
    '*.temp'
    '.Trash*/'

    # Build artifacts
    'target/'
    'build/'
    'dist/'
    '.next/'
    'out/'

    # IDE and editor files
    '.vscode/extensions/'
    '.local/share/JetBrains/'

    # Browser data (too large and not needed)
    '.mozilla/firefox/*/cache2/'
    '.mozilla/firefox/*/startupCache/'
    '.config/google-chrome/*/Cache/'
    '.config/chromium/*/Cache/'
    '.config/BraveSoftware/*/Cache/'

    # System and runtime files
    '.local/share/Trash/'
    '.gvfs/'
    '.dbus/'
    '.thumbnails/'

    # Package manager caches
    '.local/share/paru/'
    '.local/share/yay/'

    # Docker and VM images (usually too large)
    '.docker/volumes/'
    '.local/share/containers/'
    'VirtualBox VMs/'

    # Steam and game files (optional - uncomment if needed)
    # '.local/share/Steam/'
    # '.steam/'

    # Lost+found
    'lost+found/'

    # Rsync temp files
    '.rsync-partial/'
)

# ============================================================================
# FUNCTIONS
# ============================================================================

print_usage() {
    cat << EOF
Usage: $0 [DIRECTION] [OPTIONS]

DIRECTION:
    to-laptop       Sync from desktop to laptop
    to-desktop      Sync from laptop to desktop

OPTIONS:
    --dry-run       Show what would be transferred without making changes
    -h, --help      Show this help message

EXAMPLES:
    $0 to-laptop --dry-run    # Preview sync to laptop
    $0 to-desktop             # Sync to desktop
    $0 to-laptop              # Sync to laptop

CONFIGURATION:
    Edit the script to set DESKTOP_HOST and LAPTOP_HOST variables.
    Current settings:
        Desktop: ${DESKTOP_HOST}
        Laptop:  ${LAPTOP_HOST}
        User:    ${REMOTE_USER}

EOF
}

log_message() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${message}" | tee -a "${LOG_FILE}"
}

setup_logging() {
    mkdir -p "${LOG_DIR}"
    log_message "==== Sync Session Started ===="
    log_message "Source: ${SOURCE_DIR}"
    log_message "Direction: ${DIRECTION}"
    log_message "Dry run: ${DRY_RUN}"
}

verify_remote_host() {
    local host="$1"
    log_message "Verifying connection to ${REMOTE_USER}@${host}..."

    if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "${REMOTE_USER}@${host}" exit 2>/dev/null; then
        echo "ERROR: Cannot connect to ${REMOTE_USER}@${host}"
        echo "Please ensure:"
        echo "  1. SSH is configured and running on the remote machine"
        echo "  2. SSH keys are set up for passwordless authentication"
        echo "  3. The hostname/IP is correct in the script configuration"
        echo ""
        echo "To set up SSH keys, run:"
        echo "  ssh-copy-id ${REMOTE_USER}@${host}"
        exit 1
    fi

    log_message "Connection successful!"
}

build_exclude_args() {
    local exclude_args=()
    for pattern in "${EXCLUDES[@]}"; do
        exclude_args+=(--exclude="${pattern}")
    done
    echo "${exclude_args[@]}"
}

perform_sync() {
    local source="$1"
    local dest="$2"

    log_message "Starting rsync..."
    log_message "From: ${source}"
    log_message "To:   ${dest}"

    # Build exclude arguments
    local exclude_args
    exclude_args=$(build_exclude_args)

    # Add dry-run flag if requested
    local rsync_command=("rsync" "${RSYNC_OPTS[@]}")
    if [[ "${DRY_RUN}" == "true" ]]; then
        rsync_command+=(--dry-run)
        log_message "DRY RUN MODE - No changes will be made"
    fi

    # Execute rsync
    if "${rsync_command[@]}" ${exclude_args} "${source}" "${dest}" 2>&1 | tee -a "${LOG_FILE}"; then
        log_message "Sync completed successfully!"
        return 0
    else
        log_message "ERROR: Sync failed with exit code $?"
        return 1
    fi
}

# ============================================================================
# MAIN
# ============================================================================

# Parse arguments
DIRECTION=""
DRY_RUN="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        to-laptop|to-desktop)
            DIRECTION="$1"
            shift
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo "ERROR: Unknown argument: $1"
            echo ""
            print_usage
            exit 1
            ;;
    esac
done

# Validate direction
if [[ -z "${DIRECTION}" ]]; then
    echo "ERROR: Direction not specified"
    echo ""
    print_usage
    exit 1
fi

# Setup logging
setup_logging

# Determine current machine and remote host
CURRENT_HOSTNAME=$(hostname)
log_message "Current machine: ${CURRENT_HOSTNAME}"

case "${DIRECTION}" in
    to-laptop)
        REMOTE_HOST="${LAPTOP_HOST}"
        DEST="${REMOTE_USER}@${LAPTOP_HOST}:${SOURCE_DIR}"
        verify_remote_host "${LAPTOP_HOST}"
        perform_sync "${SOURCE_DIR}" "${DEST}"
        ;;
    to-desktop)
        REMOTE_HOST="${DESKTOP_HOST}"
        DEST="${REMOTE_USER}@${DESKTOP_HOST}:${SOURCE_DIR}"
        verify_remote_host "${DESKTOP_HOST}"
        perform_sync "${SOURCE_DIR}" "${DEST}"
        ;;
esac

log_message "==== Sync Session Ended ===="
log_message "Log saved to: ${LOG_FILE}"

if [[ "${DRY_RUN}" == "true" ]]; then
    echo ""
    echo "This was a DRY RUN. To perform the actual sync, run without --dry-run"
fi
