#!/bin/bash
#
# setup-ssh-for-rsync.sh - Setup SSH authentication for rsync between machines
#
# This script automates the setup of SSH key-based authentication for secure
# rsync operations between Arch Linux machines. It handles:
#   - SSH package installation
#   - SSH key generation (Ed25519)
#   - Proper file permissions
#   - Public key deployment to remote machines
#   - SSH configuration optimization
#   - Connection testing
#
# Usage:
#   ./setup-ssh-for-rsync.sh [OPTIONS]
#
# Options:
#   --remote-host HOST      Remote hostname or IP address (required for setup)
#   --remote-user USER      Remote username (default: current user)
#   --key-name NAME         SSH key name (default: id_ed25519_rsync7)
#   --test-only            Only test existing SSH connection
#   --skip-copy-id         Skip copying public key to remote (manual setup)
#   -h, --help             Show this help message
#
# Examples:
#   ./setup-ssh-for-rsync.sh --remote-host 192.168.50.107
#   ./setup-ssh-for-rsync.sh --remote-host laptop.local --remote-user draogo
#   ./setup-ssh-for-rsync.sh --test-only --remote-host 192.168.50.48
#

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

# Default settings
DEFAULT_KEY_NAME="id_ed25519_rsync7"
SSH_DIR="${HOME}/.ssh"
SSH_CONFIG="${SSH_DIR}/config"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_section() {
    echo -e "\n${BLUE}${BOLD}==== $1 ====${NC}\n"
}

print_step() {
    echo -e "${CYAN}➜${NC} $1"
}

print_usage() {
    cat << 'EOF'
Usage: ./setup-ssh-for-rsync.sh [OPTIONS]

This script sets up SSH key-based authentication for rsync operations
between Arch Linux machines. It automates the entire process from
package installation to connection testing.

OPTIONS:
    --remote-host HOST     Remote machine hostname or IP address
                          Examples: 192.168.50.107, laptop.local, server.example.com
                          (Required unless --test-only is used)

    --remote-user USER     Username on the remote machine
                          Default: Current user ($USER)

    --key-name NAME        Name for the SSH key pair
                          Default: id_ed25519_rsync7
                          Full path: ~/.ssh/id_ed25519_rsync7

    --test-only           Only test the existing SSH connection
                          Does not create keys or modify configuration

    --skip-copy-id        Skip automatic key copying to remote machine
                          Use this if you want to manually copy the key

    -h, --help            Show this help message

EXAMPLES:
    # Basic setup to sync with desktop
    ./setup-ssh-for-rsync.sh --remote-host 192.168.50.107

    # Setup with custom username
    ./setup-ssh-for-rsync.sh --remote-host laptop.local --remote-user draogo

    # Setup with custom key name
    ./setup-ssh-for-rsync.sh --remote-host 192.168.50.48 --key-name id_ed25519_backup

    # Test existing connection
    ./setup-ssh-for-rsync.sh --test-only --remote-host 192.168.50.107

    # Setup but manually copy key
    ./setup-ssh-for-rsync.sh --remote-host server.example.com --skip-copy-id

WHAT THIS SCRIPT DOES:
    1. Checks and installs openssh and rsync packages
    2. Generates Ed25519 SSH key pair (secure and efficient)
    3. Sets correct permissions on SSH directory and files
    4. Copies public key to remote machine (passwordless auth)
    5. Configures SSH client for optimized rsync performance
    6. Tests the SSH connection
    7. Provides next steps for using with sync-machines.sh

SECURITY NOTES:
    - Ed25519 keys are more secure than RSA
    - Private keys are protected with 600 permissions
    - You'll be prompted whether to use a passphrase
    - For automated syncs, consider no passphrase or use ssh-agent

PREREQUISITES:
    - Network connectivity to remote machine
    - Account on remote machine with password (for initial setup)
    - SSH server running on remote machine
    - Sudo access (for package installation if needed)

AFTER SETUP:
    - Update sync-machines.sh with the correct key name if different
    - Run sync-machines.sh to test rsync functionality
    - Setup automated syncing with setup-sync-cron.sh

EOF
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ============================================================================
# DEPENDENCY CHECKS
# ============================================================================

check_dependencies() {
    print_section "Checking Dependencies"

    local missing_deps=()
    local need_install=false

    # Check for openssh
    if ! command_exists ssh; then
        print_warning "SSH client not found"
        missing_deps+=("openssh")
        need_install=true
    else
        local ssh_version
        ssh_version=$(ssh -V 2>&1 | head -n1)
        print_info "SSH client installed: ${ssh_version}"
    fi

    # Check for rsync
    if ! command_exists rsync; then
        print_warning "rsync not found"
        missing_deps+=("rsync")
        need_install=true
    else
        local rsync_version
        rsync_version=$(rsync --version | head -n1)
        print_info "rsync installed: ${rsync_version}"
    fi

    # Check for ssh-copy-id
    if ! command_exists ssh-copy-id; then
        print_warning "ssh-copy-id not found (usually part of openssh)"
    fi

    # Install missing dependencies
    if [ "$need_install" = true ]; then
        print_warning "Missing dependencies: ${missing_deps[*]}"
        echo ""
        read -p "Install missing packages with pacman? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_step "Installing packages..."
            sudo pacman -S --needed "${missing_deps[@]}"
            print_success "Dependencies installed"
        else
            print_error "Cannot continue without required packages"
            echo ""
            echo "Install manually with: sudo pacman -S ${missing_deps[*]}"
            exit 1
        fi
    else
        print_success "All dependencies satisfied"
    fi
}

# ============================================================================
# SSH SETUP FUNCTIONS
# ============================================================================

setup_ssh_directory() {
    print_section "Setting Up SSH Directory"

    if [ ! -d "${SSH_DIR}" ]; then
        print_step "Creating SSH directory: ${SSH_DIR}"
        mkdir -p "${SSH_DIR}"
        chmod 700 "${SSH_DIR}"
        print_success "SSH directory created"
    else
        print_info "SSH directory already exists"
    fi

    # Ensure correct permissions
    local current_perms
    current_perms=$(stat -c %a "${SSH_DIR}")
    if [ "${current_perms}" != "700" ]; then
        print_step "Fixing SSH directory permissions"
        chmod 700 "${SSH_DIR}"
        print_success "Permissions set to 700"
    else
        print_info "SSH directory permissions are correct (700)"
    fi
}

generate_ssh_key() {
    local key_name="$1"
    local key_path="${SSH_DIR}/${key_name}"

    print_section "Generating SSH Key Pair"

    # Check if key already exists
    if [ -f "${key_path}" ]; then
        print_warning "SSH key already exists: ${key_path}"
        echo ""
        read -p "Do you want to overwrite it? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Using existing key"
            return 0
        fi
    fi

    print_step "Generating Ed25519 key pair..."
    echo ""
    print_info "Key location: ${key_path}"
    print_info "Key type: Ed25519 (secure and efficient)"
    echo ""
    print_warning "PASSPHRASE OPTIONS:"
    echo "  - With passphrase: More secure, but requires entry (can use ssh-agent)"
    echo "  - Without passphrase: Less secure, but enables full automation"
    echo "  - For automated rsync: Consider no passphrase or use ssh-agent"
    echo ""

    # Generate the key
    ssh-keygen -t ed25519 \
        -C "rsync-key-$(hostname)-$(date +%Y%m%d)" \
        -f "${key_path}"

    if [ $? -eq 0 ]; then
        print_success "SSH key pair generated successfully"

        # Set correct permissions
        chmod 600 "${key_path}"
        chmod 644 "${key_path}.pub"

        print_info "Private key: ${key_path} (permissions: 600)"
        print_info "Public key: ${key_path}.pub (permissions: 644)"

        echo ""
        print_info "Your public key:"
        echo "────────────────────────────────────────────────────────────"
        cat "${key_path}.pub"
        echo "────────────────────────────────────────────────────────────"
    else
        print_error "Failed to generate SSH key"
        exit 1
    fi
}

copy_key_to_remote() {
    local key_name="$1"
    local remote_user="$2"
    local remote_host="$3"
    local key_path="${SSH_DIR}/${key_name}"

    print_section "Copying Public Key to Remote Machine"

    if [ ! -f "${key_path}.pub" ]; then
        print_error "Public key not found: ${key_path}.pub"
        print_info "Please generate the key first"
        exit 1
    fi

    print_step "Copying public key to ${remote_user}@${remote_host}..."
    echo ""
    print_info "You will be prompted for the password on the remote machine"
    print_info "This is the LAST time you'll need to enter it!"
    echo ""

    if ssh-copy-id -i "${key_path}.pub" "${remote_user}@${remote_host}"; then
        print_success "Public key copied successfully"
    else
        print_error "Failed to copy public key"
        echo ""
        print_warning "Manual setup instructions:"
        echo ""
        echo "1. Display your public key:"
        echo "   cat ${key_path}.pub"
        echo ""
        echo "2. SSH to the remote machine:"
        echo "   ssh ${remote_user}@${remote_host}"
        echo ""
        echo "3. On the remote machine, run:"
        echo "   mkdir -p ~/.ssh"
        echo "   chmod 700 ~/.ssh"
        echo "   nano ~/.ssh/authorized_keys"
        echo "   # Paste the public key, save and exit"
        echo "   chmod 600 ~/.ssh/authorized_keys"
        echo ""
        return 1
    fi
}

configure_ssh_client() {
    local key_name="$1"
    local remote_user="$2"
    local remote_host="$3"
    local key_path="${SSH_DIR}/${key_name}"

    print_section "Configuring SSH Client"

    # Create or update SSH config
    local config_entry="
# rsync SSH configuration for ${remote_host}
# Generated by setup-ssh-for-rsync.sh on $(date)
Host ${remote_host}
    User ${remote_user}
    IdentityFile ${key_path}
    IdentitiesOnly yes
    Compression yes
    ServerAliveInterval 60
    ServerAliveCountMax 3
    TCPKeepAlive yes
"

    # Check if entry already exists
    if [ -f "${SSH_CONFIG}" ]; then
        if grep -q "Host ${remote_host}" "${SSH_CONFIG}"; then
            print_warning "SSH config entry for ${remote_host} already exists"
            echo ""
            read -p "Do you want to update it? (y/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                # Backup existing config
                cp "${SSH_CONFIG}" "${SSH_CONFIG}.backup.$(date +%Y%m%d%H%M%S)"
                print_info "Backed up existing config"

                # Remove old entry (simple approach - remove from "Host" to next "Host" or EOF)
                # This is a basic implementation; for production consider more robust parsing
                print_warning "Please manually update ${SSH_CONFIG}"
                print_info "Add this configuration:"
                echo "${config_entry}"
            fi
            return 0
        fi
    fi

    print_step "Adding SSH config entry for ${remote_host}..."
    echo "${config_entry}" >> "${SSH_CONFIG}"
    chmod 600 "${SSH_CONFIG}"
    print_success "SSH config updated"

    echo ""
    print_info "You can now use shorter commands like:"
    echo "  ssh ${remote_host}"
    echo "  rsync -avz /local/path/ ${remote_host}:/remote/path/"
}

test_ssh_connection() {
    local remote_user="$1"
    local remote_host="$2"
    local key_name="$3"
    local key_path="${SSH_DIR}/${key_name}"

    print_section "Testing SSH Connection"

    print_step "Attempting to connect to ${remote_user}@${remote_host}..."
    echo ""

    # Test with key file
    if ssh -i "${key_path}" \
           -o ConnectTimeout=10 \
           -o BatchMode=yes \
           -o StrictHostKeyChecking=accept-new \
           "${remote_user}@${remote_host}" \
           'echo "SSH connection successful! Hostname: $(hostname)"'; then
        echo ""
        print_success "SSH connection established successfully!"
        print_success "Passwordless authentication is working!"
        return 0
    else
        echo ""
        print_error "SSH connection failed"
        echo ""
        print_warning "Troubleshooting steps:"
        echo ""
        echo "1. Check if SSH server is running on remote machine:"
        echo "   ssh ${remote_user}@${remote_host} 'systemctl status sshd'"
        echo ""
        echo "2. Verify network connectivity:"
        echo "   ping -c 4 ${remote_host}"
        echo ""
        echo "3. Try connecting with verbose output:"
        echo "   ssh -vvv -i ${key_path} ${remote_user}@${remote_host}"
        echo ""
        echo "4. Check remote machine's auth log:"
        echo "   ssh ${remote_user}@${remote_host} 'sudo tail -n 50 /var/log/auth.log'"
        echo ""
        echo "5. Verify permissions on remote machine:"
        echo "   ssh ${remote_user}@${remote_host} 'ls -la ~/.ssh/'"
        echo ""
        return 1
    fi
}

verify_rsync_functionality() {
    local remote_user="$1"
    local remote_host="$2"
    local key_name="$3"
    local key_path="${SSH_DIR}/${key_name}"

    print_section "Verifying rsync Functionality"

    print_step "Testing rsync over SSH..."
    echo ""

    # Create a temporary test file
    local test_dir="/tmp/rsync-test-$$"
    local test_file="${test_dir}/test-file.txt"

    mkdir -p "${test_dir}"
    echo "Test rsync transfer - $(date)" > "${test_file}"

    print_info "Created test file: ${test_file}"

    # Test rsync dry-run
    print_step "Running rsync dry-run..."
    if rsync -avz --dry-run \
             -e "ssh -i ${key_path}" \
             "${test_file}" \
             "${remote_user}@${remote_host}:/tmp/"; then
        print_success "rsync dry-run successful"

        echo ""
        read -p "Perform actual test transfer? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if rsync -avz \
                     -e "ssh -i ${key_path}" \
                     "${test_file}" \
                     "${remote_user}@${remote_host}:/tmp/"; then
                print_success "rsync test transfer successful!"

                # Cleanup remote test file
                ssh -i "${key_path}" "${remote_user}@${remote_host}" \
                    "rm -f /tmp/test-file.txt" 2>/dev/null || true
            else
                print_error "rsync test transfer failed"
            fi
        fi
    else
        print_error "rsync dry-run failed"
    fi

    # Cleanup local test files
    rm -rf "${test_dir}"
}

# ============================================================================
# MAIN SETUP WORKFLOW
# ============================================================================

perform_full_setup() {
    local key_name="$1"
    local remote_user="$2"
    local remote_host="$3"
    local skip_copy_id="$4"

    print_section "SSH Setup for rsync"
    echo "Remote: ${remote_user}@${remote_host}"
    echo "Key: ${SSH_DIR}/${key_name}"
    echo ""

    # Step 1: Check dependencies
    check_dependencies

    # Step 2: Setup SSH directory
    setup_ssh_directory

    # Step 3: Generate SSH key
    generate_ssh_key "${key_name}"

    # Step 4: Copy key to remote (unless skipped)
    if [ "${skip_copy_id}" = "false" ]; then
        if ! copy_key_to_remote "${key_name}" "${remote_user}" "${remote_host}"; then
            print_warning "Public key copy failed - you may need to set it up manually"
            return 1
        fi
    else
        print_warning "Skipping automatic key copy (--skip-copy-id specified)"
        echo ""
        print_info "To copy the key manually, run:"
        echo "  ssh-copy-id -i ${SSH_DIR}/${key_name}.pub ${remote_user}@${remote_host}"
        echo ""
        echo "Or display the public key to copy manually:"
        echo "  cat ${SSH_DIR}/${key_name}.pub"
    fi

    # Step 5: Configure SSH client
    configure_ssh_client "${key_name}" "${remote_user}" "${remote_host}"

    # Step 6: Test connection
    if test_ssh_connection "${remote_user}" "${remote_host}" "${key_name}"; then
        # Step 7: Verify rsync
        verify_rsync_functionality "${remote_user}" "${remote_host}" "${key_name}"
    fi
}

display_next_steps() {
    local key_name="$1"
    local remote_user="$2"
    local remote_host="$3"

    print_section "Setup Complete!"

    echo "Your SSH setup is ready for rsync operations."
    echo ""
    print_info "Next Steps:"
    echo ""
    echo "1. Update sync-machines.sh script:"
    echo "   - Edit line 308 to use: -i ~/.ssh/${key_name}"
    echo "   - Or update DESKTOP_HOST/LAPTOP_HOST variables as needed"
    echo ""
    echo "2. Test manual sync (dry-run first!):"
    echo "   cd $(dirname "$0")"
    echo "   ./sync-machines.sh to-laptop --dry-run"
    echo "   # or"
    echo "   ./sync-machines.sh to-desktop --dry-run"
    echo ""
    echo "3. If dry-run looks good, perform actual sync:"
    echo "   ./sync-machines.sh to-laptop"
    echo ""
    echo "4. Setup automated syncing with cron:"
    echo "   ./setup-sync-cron.sh --interval 30"
    echo ""
    echo "5. Monitor sync logs:"
    echo "   tail -f ~/.local/share/sync-logs/cron-sync.log"
    echo ""
    print_info "Useful Commands:"
    echo ""
    echo "  # Test SSH connection"
    echo "  ssh ${remote_host}"
    echo ""
    echo "  # Manual rsync"
    echo "  rsync -avz -e 'ssh -i ~/.ssh/${key_name}' /source/ ${remote_user}@${remote_host}:/dest/"
    echo ""
    echo "  # View SSH config"
    echo "  cat ~/.ssh/config"
    echo ""
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    # Default values
    local key_name="${DEFAULT_KEY_NAME}"
    local remote_user="${USER}"
    local remote_host=""
    local test_only="false"
    local skip_copy_id="false"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --remote-host)
                remote_host="$2"
                shift 2
                ;;
            --remote-user)
                remote_user="$2"
                shift 2
                ;;
            --key-name)
                key_name="$2"
                shift 2
                ;;
            --test-only)
                test_only="true"
                shift
                ;;
            --skip-copy-id)
                skip_copy_id="true"
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

    # Validate required arguments
    if [ -z "${remote_host}" ]; then
        print_error "Remote host is required"
        echo ""
        echo "Usage: $0 --remote-host <HOST> [OPTIONS]"
        echo "Run with --help for more information"
        exit 1
    fi

    # Print header
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "  SSH Setup for rsync - Arch Linux"
    echo "════════════════════════════════════════════════════════════════"
    echo ""

    # Execute requested operation
    if [ "${test_only}" = "true" ]; then
        print_section "Testing Existing SSH Setup"
        check_dependencies
        test_ssh_connection "${remote_user}" "${remote_host}" "${key_name}"
    else
        perform_full_setup "${key_name}" "${remote_user}" "${remote_host}" "${skip_copy_id}"
        display_next_steps "${key_name}" "${remote_user}" "${remote_host}"
    fi

    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo ""
}

main "$@"
