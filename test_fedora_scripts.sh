#!/bin/bash

#####################################
# Fedora Scripts Testing & Debugging
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

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_section() {
    echo -e "\n${BLUE}==== $1 ====${NC}\n"
}

# Test script availability and permissions
test_script() {
    local script_path="$1"
    local script_name=$(basename "$script_path")

    echo ""
    print_section "Testing: $script_name"

    # Check if file exists
    if [ ! -f "$script_path" ]; then
        print_error "Script not found: $script_path"
        return 1
    fi
    print_info "✓ File exists"

    # Check if readable
    if [ ! -r "$script_path" ]; then
        print_error "Script not readable: $script_path"
        return 1
    fi
    print_info "✓ File is readable"

    # Check shebang
    first_line=$(head -n1 "$script_path")
    if [[ ! "$first_line" =~ ^#!/ ]]; then
        print_warning "Missing or invalid shebang: $first_line"
    else
        print_info "✓ Valid shebang: $first_line"
    fi

    # Check for syntax errors
    if bash -n "$script_path" 2>/dev/null; then
        print_info "✓ No syntax errors detected"
    else
        print_error "Syntax errors found!"
        bash -n "$script_path"
        return 1
    fi

    # Check for Fedora compatibility
    if grep -q "fedora" "$script_path" || grep -q "dnf" "$script_path" || [ "$script_name" == "setup-general.sh" ] || [ "$script_name" == "install-linux-tools.sh" ] || [ "$script_name" == "install-shell-tools.sh" ]; then
        print_info "✓ Fedora-compatible script"
    else
        print_warning "Script may not be Fedora-specific"
    fi

    # Check for dangerous commands
    dangerous_patterns=(
        "rm -rf /\$"
        "rm -rf /[^t]"
        "dd if=/dev/zero of=/dev/"
        "mkfs\."
        ":(){ :|:& };:"
    )

    for pattern in "${dangerous_patterns[@]}"; do
        if grep -q "$pattern" "$script_path"; then
            print_error "DANGEROUS COMMAND DETECTED: $pattern"
            return 1
        fi
    done
    print_info "✓ No dangerous commands detected"

    # Extract and display main functions
    print_info "Main functions/sections in script:"
    grep -E "^[a-zA-Z_][a-zA-Z0-9_]*\(\)" "$script_path" | sed 's/().*//' | while read func; do
        echo "  - $func"
    done

    # Check for required commands
    print_info "External commands used:"
    grep -oE '(sudo|dnf|yum|apt|pacman|brew|curl|wget|git|docker|podman|snap|flatpak)\b' "$script_path" | sort -u | while read cmd; do
        echo -n "  - $cmd"
        if command -v "$cmd" &>/dev/null; then
            echo " (✓ available)"
        else
            echo " (✗ not installed)"
        fi
    done

    return 0
}

# Main testing routine
main() {
    print_section "Fedora Scripts Testing Suite"
    echo "Testing scripts for Fedora compatibility and debugging..."
    echo "Current system: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo ""

    # List of scripts to test
    scripts=(
        "linux/fedora/setup-fedora.sh"
        "linux/fedora/install_ghostty_fedora.sh"
        "linux/general/setup-general.sh"
        "linux/install-linux-tools.sh"
        "tools/shell/install-shell-tools.sh"
        "tools/docker/setup-docker.sh"
        "tools/git/git-setup.sh"
        "tools/tmux/setup-tmux.sh"
    )

    failed_scripts=()
    passed_scripts=()

    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            if test_script "$script"; then
                passed_scripts+=("$script")
            else
                failed_scripts+=("$script")
            fi
        else
            print_warning "Script not found: $script"
        fi
    done

    # Summary
    echo ""
    print_section "Test Summary"

    if [ ${#passed_scripts[@]} -gt 0 ]; then
        print_info "Scripts that passed all tests (${#passed_scripts[@]}):"
        for script in "${passed_scripts[@]}"; do
            echo "  ✓ $script"
        done
    fi

    if [ ${#failed_scripts[@]} -gt 0 ]; then
        print_error "Scripts with issues (${#failed_scripts[@]}):"
        for script in "${failed_scripts[@]}"; do
            echo "  ✗ $script"
        done
    fi

    echo ""
    print_section "Recommended Execution Order for Fedora"
    echo "1. linux/fedora/setup-fedora.sh        - Main Fedora system setup"
    echo "2. linux/general/setup-general.sh      - Cross-platform tools (Homebrew, mise)"
    echo "3. linux/install-linux-tools.sh        - Additional Linux tools"
    echo "4. tools/shell/install-shell-tools.sh  - Shell utilities"
    echo "5. tools/docker/setup-docker.sh        - Docker installation (if needed)"
    echo "6. tools/git/git-setup.sh              - Git configuration"
    echo "7. tools/tmux/setup-tmux.sh           - Tmux setup"
    echo "8. linux/fedora/install_ghostty_fedora.sh - Ghostty terminal (optional)"

    echo ""
    print_info "To run a script individually:"
    echo "  bash <script_path>"
    echo ""
    print_info "To run with debugging:"
    echo "  bash -x <script_path>"
}

# Run main function
main