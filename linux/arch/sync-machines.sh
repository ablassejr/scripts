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
DESKTOP_HOST="192.168.50.107"  # SSH hostname or IP for desktop
LAPTOP_HOST="192.168.50.48"    # SSH hostname or IP for laptop
REMOTE_USER="draogo"   # Username on remote machine (defaults to current user)

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
    # ============================================================================
    # SECURITY & CREDENTIALS (DO NOT SYNC)
    # ============================================================================
    '.ssh/id_*'                     # SSH private keys (keep machine-specific)
    '.ssh/known_hosts'              # Machine-specific SSH hosts
    '.gnupg/private-keys-v1.d/'     # GPG private keys
    '.gnupg/random_seed'            # GPG random seed
    '.password-store/'              # Password manager data (sync separately if needed)
    '.aws/credentials'              # AWS credentials
    '.config/gcloud/credentials/'   # Google Cloud credentials
    '.kube/config'                  # Kubernetes config (may contain certs)
    '.docker/config.json'           # Docker credentials

    # ============================================================================
    # CACHE DIRECTORIES (Rebuild on each machine)
    # ============================================================================
    '.cache/'
    '.npm/'
    '.yarn/'
    '.pnpm-store/'
    '.node-gyp/'
    '.cargo/registry/'
    '.cargo/git/'
    '.rustup/toolchains/'
    '.rustup/downloads/'
    '.rustup/tmp/'
    '.gradle/caches/'
    '.gradle/wrapper/'
    '.m2/repository/'
    '.ivy2/cache/'
    '.sbt/boot/'
    'node_modules/'
    '__pycache__/'
    '.pytest_cache/'
    '.mypy_cache/'
    '.ruff_cache/'
    '*.pyc'
    '.pip/'
    '.conda/pkgs/'
    '.gem/cache/'
    'go/pkg/mod/'
    '.ccache/'

    # ============================================================================
    # TEMPORARY FILES
    # ============================================================================
    '.tmp/'
    'tmp/'
    '*.tmp'
    '*.temp'
    '*.swp'
    '*.swo'
    '*~'
    '.Trash*/'
    '.nohup.out'

    # ============================================================================
    # BUILD ARTIFACTS (Rebuild on each machine)
    # ============================================================================
    'target/'
    'build/'
    'dist/'
    '.next/'
    'out/'
    '.turbo/'
    '.nuxt/'
    '.output/'
    '.vercel/'
    'venv/'
    'env/'
    '.venv/'
    '.env/'
    '__pypackages__/'

    # ============================================================================
    # IDE AND EDITOR FILES (Machine-specific)
    # ============================================================================
    '.vscode/extensions/'
    '.vscode-server/'
    '.vscode-insiders/'
    '.local/share/JetBrains/'
    '.config/JetBrains/*/eval/'
    '.local/share/nvim/swap/'
    '.local/share/nvim/shada/'
    '.vim/swap/'
    '.vim/backup/'
    '.vim/undo/'

    # ============================================================================
    # BROWSER DATA (Too large and machine-specific)
    # ============================================================================
    '.mozilla/firefox/*/cache2/'
    '.mozilla/firefox/*/startupCache/'
    '.mozilla/firefox/*/storage/default/*/cache/'
    '.mozilla/firefox/*/thumbnails/'
    '.config/google-chrome/*/Cache/'
    '.config/google-chrome/*/Code Cache/'
    '.config/google-chrome/*/GPUCache/'
    '.config/google-chrome/*/Service Worker/'
    '.config/chromium/*/Cache/'
    '.config/chromium/*/Code Cache/'
    '.config/BraveSoftware/*/Cache/'
    '.config/BraveSoftware/*/Code Cache/'
    '.config/vivaldi/*/Cache/'
    '.config/opera/*/Cache/'

    # ============================================================================
    # SYSTEM AND RUNTIME FILES
    # ============================================================================
    '.local/share/Trash/'
    '.gvfs/'
    '.dbus/'
    '.thumbnails/'
    '.xsession-errors*'
    '.ICEauthority'
    '.Xauthority'
    '.nvidia-settings-rc'
    '.pulse-cookie'
    '.esd_auth'
    '.local/share/recently-used.xbel'

    # ============================================================================
    # PACKAGE MANAGER CACHES
    # ============================================================================
    '.local/share/paru/'
    '.local/share/yay/'
    '.cache/pacman/'
    '.cache/yay/'
    '.cache/paru/'

    # ============================================================================
    # CONTAINERS, VMs, AND VIRTUALIZATION (Too large)
    # ============================================================================
    '.docker/volumes/'
    '.docker/containers/'
    '.docker/image/'
    '.docker/overlay2/'
    '.local/share/containers/'
    '.local/share/podman/'
    'VirtualBox VMs/'
    '.vagrant.d/boxes/'
    'vmware/'
    '.minikube/cache/'

    # ============================================================================
    # FLATPAK AND SNAP (Machine-specific installs)
    # ============================================================================
    '.local/share/flatpak/'
    '.var/app/*/cache/'

    # ============================================================================
    # DATABASES (Should not be synced while running)
    # ============================================================================
    '.local/share/akonadi/'
    '.local/share/baloo/'
    '.mozilla/firefox/*/places.sqlite-wal'
    '.mozilla/firefox/*/places.sqlite-shm'
    '*.db-wal'
    '*.db-shm'

    # ============================================================================
    # GAMING (Optional - very large)
    # ============================================================================
    '.local/share/Steam/steamapps/common/'  # Game files
    '.local/share/Steam/steamapps/downloading/'
    '.steam/steam/steamapps/common/'
    '.steam/steam/steamapps/downloading/'
    'Games/Steam/'
    '.local/share/lutris/runners/'

    # ============================================================================
    # MAIL (Sync separately if needed)
    # ============================================================================
    '.thunderbird/*/ImapMail/'
    '.local/share/evolution/mail/'
    'Mail/'
    'Maildir/'

    # ============================================================================
    # LOGS (Machine-specific)
    # ============================================================================
    '*.log'
    '.xsession-errors'
    '.local/share/xorg/'

    # ============================================================================
    # MISC
    # ============================================================================
    'lost+found/'
    '.rsync-partial/'
    '.nfs*'

    # Wine prefixes (can be large)
    '.wine/drive_c/windows/'

    # Electron app caches
    '.config/*/Cache/'
    '.config/*/GPUCache/'
    '.config/*/Code Cache/'
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

    if ! ssh -o ConnectTimeout=5 -o BatchMode=yes -i ~/.ssh/id_ed25519_rsync7 "${REMOTE_USER}@${host}" exit 2>/dev/null; then
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
