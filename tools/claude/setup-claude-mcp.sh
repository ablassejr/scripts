#!/bin/bash

#####################################
# Claude Code MCP Setup Script
# Adds popular MCP servers and plugin marketplaces to Claude Code CLI
#####################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
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
    echo -e "\n${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} $1"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}\n"
}

print_marketplace() {
    echo -e "${BLUE}📦 $1${NC}"
    echo -e "   ${CYAN}→${NC} $2"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if Claude Code CLI is installed
check_claude_cli() {
    print_section "Checking Claude Code CLI Installation"

    if ! command_exists claude; then
        print_error "Claude Code CLI is not installed!"
        print_info "Please install Claude Code CLI first."
        print_info "Visit: https://code.claude.com for installation instructions"
        exit 1
    fi

    print_info "Claude Code CLI found: $(which claude)"

    # Check Claude version
    CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "unknown")
    print_info "Claude Code CLI version: $CLAUDE_VERSION"
}

# Check if Node.js and npm are installed
check_node() {
    print_section "Checking Node.js and npm"

    if ! command_exists node; then
        print_error "Node.js is not installed!"
        print_info "Many MCP servers require Node.js. Please install it first."
        print_info "Visit: https://nodejs.org"
        exit 1
    fi

    print_info "Node.js version: $(node --version)"

    if ! command_exists npm; then
        print_error "npm is not installed!"
        exit 1
    fi

    print_info "npm version: $(npm --version)"

    # Check for npx
    if ! command_exists npx; then
        print_warning "npx is not available. Installing latest npm..."
        npm install -g npm@latest
    fi
}

# Display MCP marketplaces information
display_marketplaces() {
    print_section "MCP Plugin Marketplaces & Directories"

    echo -e "${YELLOW}Available MCP Marketplaces for discovering more servers:${NC}\n"

    print_marketplace "Cline MCP Marketplace" "https://github.com/cline/mcp-marketplace"
    echo -e "   Official repository for submitting and discovering MCP servers"
    echo ""

    print_marketplace "MCPMarket.com" "https://mcpmarket.com/"
    echo -e "   Discover top MCP servers with ratings and reviews"
    echo ""

    print_marketplace "MCP.so" "https://mcp.so/"
    echo -e "   OpenSource MCP Marketplace with HTML plugin integration"
    echo ""

    print_marketplace "Higress MCP Marketplace" "https://mcp.higress.ai/"
    echo -e "   The shortest path connecting AI with the real world"
    echo ""

    print_marketplace "MCPcat.io" "https://mcpcat.io/"
    echo -e "   Comprehensive guides and MCP server catalog"
    echo ""

    print_marketplace "Smithery.ai" "https://smithery.ai/"
    echo -e "   MCP server registry and discovery platform"
    echo ""

    print_marketplace "glama.ai MCP Servers" "https://glama.ai/mcp/servers"
    echo -e "   Curated collection of MCP servers"
    echo ""
}

# Core Development MCP Servers
install_core_mcps() {
    print_section "Installing Core Development MCP Servers"

    # Sequential Thinking - Structured reasoning
    print_info "Installing Sequential Thinking MCP..."
    if claude mcp add sequential-thinking npx -- -y @modelcontextprotocol/server-sequential-thinking; then
        print_info "✓ Sequential Thinking MCP installed"
    else
        print_warning "Failed to install Sequential Thinking MCP"
    fi

    # Context7 - Documentation access
    print_info "Installing Context7 MCP..."
    if claude mcp add context7 npx -- -y @upstash/context7-mcp; then
        print_info "✓ Context7 MCP installed"
    else
        print_warning "Failed to install Context7 MCP"
    fi

    # Filesystem - Local file access
    print_info "Installing Filesystem MCP..."
    if claude mcp add filesystem npx -- -y @modelcontextprotocol/server-filesystem; then
        print_info "✓ Filesystem MCP installed"
    else
        print_warning "Failed to install Filesystem MCP"
    fi

    # Memory - Persistent memory across sessions
    print_info "Installing Memory MCP..."
    if claude mcp add memory npx -- -y @modelcontextprotocol/server-memory; then
        print_info "✓ Memory MCP installed"
    else
        print_warning "Failed to install Memory MCP"
    fi
}

# Web & Search MCP Servers
install_web_mcps() {
    print_section "Installing Web & Search MCP Servers"

    # Brave Search - Web search integration
    print_info "Installing Brave Search MCP..."
    echo -e "${YELLOW}Note: Requires BRAVE_API_KEY environment variable${NC}"
    if claude mcp add brave-search npx -- -y @modelcontextprotocol/server-brave-search; then
        print_info "✓ Brave Search MCP installed"
        print_warning "Remember to set BRAVE_API_KEY in your environment"
    else
        print_warning "Failed to install Brave Search MCP"
    fi

    # Puppeteer - Browser automation
    print_info "Installing Puppeteer MCP..."
    if claude mcp add puppeteer npx -- -y @modelcontextprotocol/server-puppeteer; then
        print_info "✓ Puppeteer MCP installed"
    else
        print_warning "Failed to install Puppeteer MCP"
    fi

    # Playwright - Modern web automation
    print_info "Installing Playwright MCP..."
    if claude mcp add playwright npx -- @playwright/mcp@latest; then
        print_info "✓ Playwright MCP installed"
    else
        print_warning "Failed to install Playwright MCP"
    fi
}

# Cloud & Infrastructure MCP Servers
install_cloud_mcps() {
    print_section "Installing Cloud & Infrastructure MCP Servers"

    # GitHub - Repository management
    print_info "Installing GitHub MCP (Remote)..."
    echo -e "${YELLOW}Note: Requires GitHub authentication${NC}"
    if claude mcp add --transport http github https://api.githubcopilot.com/mcp/; then
        print_info "✓ GitHub MCP installed"
    else
        print_warning "Failed to install GitHub MCP"
    fi

    # AWS Knowledge - AWS documentation
    print_info "Installing AWS Knowledge MCP..."
    if claude mcp add --transport http aws-knowledge https://knowledge-mcp.global.api.aws; then
        print_info "✓ AWS Knowledge MCP installed"
    else
        print_warning "Failed to install AWS Knowledge MCP"
    fi

    # Cloudflare Workers
    print_info "Installing Cloudflare Workers MCP..."
    if claude mcp add --transport sse cloudflare-workers https://bindings.mcp.cloudflare.com/sse; then
        print_info "✓ Cloudflare Workers MCP installed"
    else
        print_warning "Failed to install Cloudflare Workers MCP"
    fi

    # Cloudflare Docs
    print_info "Installing Cloudflare Docs MCP..."
    if claude mcp add --transport sse cloudflare-docs https://docs.mcp.cloudflare.com/sse; then
        print_info "✓ Cloudflare Docs MCP installed"
    else
        print_warning "Failed to install Cloudflare Docs MCP"
    fi
}

# Database MCP Servers
install_database_mcps() {
    print_section "Installing Database MCP Servers"

    # PostgreSQL - Database operations
    print_info "Installing PostgreSQL MCP..."
    if claude mcp add postgres npx -- -y @modelcontextprotocol/server-postgres; then
        print_info "✓ PostgreSQL MCP installed"
    else
        print_warning "Failed to install PostgreSQL MCP"
    fi

    # SQLite - Lightweight database
    print_info "Installing SQLite MCP..."
    if claude mcp add sqlite npx -- -y @modelcontextprotocol/server-sqlite; then
        print_info "✓ SQLite MCP installed"
    else
        print_warning "Failed to install SQLite MCP"
    fi
}

# Productivity & Collaboration MCP Servers
install_productivity_mcps() {
    print_section "Installing Productivity & Collaboration MCP Servers"

    # Notion - Knowledge base integration
    print_info "Installing Notion MCP..."
    echo -e "${YELLOW}Note: Requires NOTION_API_TOKEN environment variable${NC}"
    if claude mcp add notion npx -- -y @makenotion/notion-mcp-server; then
        print_info "✓ Notion MCP installed"
        print_warning "Remember to set NOTION_API_TOKEN in your environment"
    else
        print_warning "Failed to install Notion MCP"
    fi

    # Linear - Project management
    print_info "Installing Linear MCP..."
    if claude mcp add --transport sse linear https://mcp.linear.app/sse; then
        print_info "✓ Linear MCP installed"
    else
        print_warning "Failed to install Linear MCP"
    fi

    # Atlassian - Jira and Confluence
    print_info "Installing Atlassian MCP..."
    if claude mcp add --transport sse atlassian https://mcp.atlassian.com/v1/sse; then
        print_info "✓ Atlassian MCP installed"
    else
        print_warning "Failed to install Atlassian MCP"
    fi

    # Slack - Team communication
    print_info "Installing Slack MCP..."
    if claude mcp add slack npx -- -y @modelcontextprotocol/server-slack; then
        print_info "✓ Slack MCP installed"
    else
        print_warning "Failed to install Slack MCP"
    fi
}

# Monitoring & Observability MCP Servers
install_monitoring_mcps() {
    print_section "Installing Monitoring & Observability MCP Servers"

    # Sentry - Error tracking
    print_info "Installing Sentry MCP..."
    if claude mcp add --transport sse sentry https://mcp.sentry.dev/mcp; then
        print_info "✓ Sentry MCP installed"
    else
        print_warning "Failed to install Sentry MCP"
    fi

    # PostHog - Product analytics
    print_info "Installing PostHog MCP..."
    if claude mcp add --transport sse posthog https://mcp.posthog.com/sse; then
        print_info "✓ PostHog MCP installed"
    else
        print_warning "Failed to install PostHog MCP"
    fi
}

# Design & API MCP Servers
install_design_api_mcps() {
    print_section "Installing Design & API MCP Servers"

    # Figma - Design tool integration
    print_info "Installing Figma MCP..."
    echo -e "${YELLOW}Note: Requires Figma Dev/Full seat and local server${NC}"
    if claude mcp add --transport sse figma http://127.0.0.1:3845/sse; then
        print_info "✓ Figma MCP installed"
        print_warning "Note: Figma MCP requires local Figma desktop app running"
    else
        print_warning "Failed to install Figma MCP"
    fi
}

# Git & Version Control MCP Servers
install_git_mcps() {
    print_section "Installing Git & Version Control MCP Servers"

    # Git - Version control operations
    print_info "Installing Git MCP..."
    if claude mcp add git npx -- -y @modelcontextprotocol/server-git; then
        print_info "✓ Git MCP installed"
    else
        print_warning "Failed to install Git MCP"
    fi

    # GitLab
    print_info "Installing GitLab MCP..."
    if claude mcp add gitlab npx -- -y @modelcontextprotocol/server-gitlab; then
        print_info "✓ GitLab MCP installed"
    else
        print_warning "Failed to install GitLab MCP"
    fi
}

# Interactive installation menu
interactive_install() {
    print_section "Claude Code MCP Interactive Installation"

    echo -e "${YELLOW}Select which MCP server categories to install:${NC}\n"

    PS3=$'\n'"${CYAN}Please enter your choice (or 'done' when finished): ${NC}"

    options=(
        "Core Development (Sequential Thinking, Context7, Filesystem, Memory)"
        "Web & Search (Brave Search, Puppeteer, Playwright)"
        "Cloud & Infrastructure (GitHub, AWS, Cloudflare)"
        "Database (PostgreSQL, SQLite)"
        "Productivity (Notion, Linear, Atlassian, Slack)"
        "Monitoring (Sentry, PostHog)"
        "Design & API (Figma)"
        "Git & Version Control (Git, GitLab)"
        "Install ALL MCP servers"
        "Show MCP Marketplaces Info Only"
        "Exit"
    )

    while true; do
        select opt in "${options[@]}"; do
            case $REPLY in
                1)
                    install_core_mcps
                    break
                    ;;
                2)
                    install_web_mcps
                    break
                    ;;
                3)
                    install_cloud_mcps
                    break
                    ;;
                4)
                    install_database_mcps
                    break
                    ;;
                5)
                    install_productivity_mcps
                    break
                    ;;
                6)
                    install_monitoring_mcps
                    break
                    ;;
                7)
                    install_design_api_mcps
                    break
                    ;;
                8)
                    install_git_mcps
                    break
                    ;;
                9)
                    install_core_mcps
                    install_web_mcps
                    install_cloud_mcps
                    install_database_mcps
                    install_productivity_mcps
                    install_monitoring_mcps
                    install_design_api_mcps
                    install_git_mcps
                    return
                    ;;
                10)
                    display_marketplaces
                    return
                    ;;
                11)
                    print_info "Exiting installation."
                    exit 0
                    ;;
                *)
                    print_error "Invalid option. Please try again."
                    break
                    ;;
            esac
        done

        echo -e "\n${YELLOW}Install another category? (y/n)${NC}"
        read -r continue_install
        if [[ ! $continue_install =~ ^[Yy]$ ]]; then
            break
        fi
    done
}

# Non-interactive installation (all MCPs)
install_all_mcps() {
    print_info "Installing all MCP servers..."

    install_core_mcps
    install_web_mcps
    install_cloud_mcps
    install_database_mcps
    install_productivity_mcps
    install_monitoring_mcps
    install_design_api_mcps
    install_git_mcps
}

# List installed MCPs
list_installed_mcps() {
    print_section "Installed MCP Servers"

    if command_exists claude; then
        claude mcp list || print_warning "Unable to list MCP servers. Use 'claude mcp list' manually."
    fi
}

# Display usage information
show_usage() {
    echo -e "${CYAN}Usage:${NC} $0 [OPTIONS]"
    echo ""
    echo -e "${CYAN}Options:${NC}"
    echo -e "  -a, --all          Install all MCP servers (non-interactive)"
    echo -e "  -i, --interactive  Interactive installation menu (default)"
    echo -e "  -m, --marketplaces Show MCP marketplaces information only"
    echo -e "  -l, --list         List installed MCP servers"
    echo -e "  -h, --help         Display this help message"
    echo ""
    echo -e "${CYAN}Examples:${NC}"
    echo -e "  $0                 # Interactive installation"
    echo -e "  $0 --all           # Install all MCP servers"
    echo -e "  $0 --marketplaces  # Show marketplaces only"
    echo -e "  $0 --list          # List installed servers"
}

# Main function
main() {
    echo -e "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║         Claude Code MCP & Plugin Marketplace Setup Script        ║
║                                                                   ║
║             Adds various MCP servers and marketplaces            ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"

    # Parse command line arguments
    case "${1:-}" in
        -a|--all)
            check_claude_cli
            check_node
            install_all_mcps
            display_marketplaces
            list_installed_mcps
            ;;
        -i|--interactive)
            check_claude_cli
            check_node
            interactive_install
            display_marketplaces
            list_installed_mcps
            ;;
        -m|--marketplaces)
            display_marketplaces
            ;;
        -l|--list)
            check_claude_cli
            list_installed_mcps
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        "")
            # Default: interactive mode
            check_claude_cli
            check_node
            interactive_install
            display_marketplaces
            list_installed_mcps
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac

    print_section "Installation Complete!"
    echo -e "${GREEN}✓ MCP setup finished successfully!${NC}\n"
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "  1. Configure API keys/tokens for MCPs that require them"
    echo -e "  2. Restart Claude Code CLI to activate new MCP servers"
    echo -e "  3. Use 'claude mcp list' to view all installed servers"
    echo -e "  4. Explore MCP marketplaces for additional servers\n"

    echo -e "${CYAN}Useful Commands:${NC}"
    echo -e "  claude mcp list              # List installed MCP servers"
    echo -e "  claude mcp remove <name>     # Remove an MCP server"
    echo -e "  claude mcp add <name> ...    # Add a new MCP server"
    echo ""
}

# Run main function
main "$@"
