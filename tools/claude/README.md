# Claude Code Tools

Setup scripts and utilities for Claude Code CLI configuration and enhancement.

## 📋 Contents

- `setup-claude-mcp.sh` - MCP server installation and marketplace configuration script

## 🚀 Claude Code MCP Setup Script

A comprehensive script for installing popular Model Context Protocol (MCP) servers and discovering MCP plugin marketplaces for Claude Code CLI.

### Features

- **Interactive Installation Menu**: Choose which MCP server categories to install
- **Batch Installation**: Install all MCP servers at once with `--all` flag
- **Marketplace Discovery**: Display popular MCP marketplaces and directories
- **Organized Categories**:
  - Core Development (Sequential Thinking, Context7, Filesystem, Memory)
  - Web & Search (Brave Search, Puppeteer, Playwright)
  - Cloud & Infrastructure (GitHub, AWS, Cloudflare)
  - Database (PostgreSQL, SQLite)
  - Productivity (Notion, Linear, Atlassian, Slack)
  - Monitoring (Sentry, PostHog)
  - Design & API (Figma)
  - Git & Version Control (Git, GitLab)

### Usage

```bash
# Interactive installation (default)
./setup-claude-mcp.sh

# Install all MCP servers
./setup-claude-mcp.sh --all

# Show MCP marketplaces only
./setup-claude-mcp.sh --marketplaces

# List installed MCP servers
./setup-claude-mcp.sh --list

# Show help
./setup-claude-mcp.sh --help
```

### Prerequisites

- Claude Code CLI installed (`claude` command available)
- Node.js and npm (for most MCP servers)
- Internet connection for downloading MCP packages

### MCP Servers Included

#### Core Development
- **Sequential Thinking**: Structured, reflective thinking process
- **Context7**: Real-time documentation from source repositories
- **Filesystem**: Local file system access and manipulation
- **Memory**: Persistent memory across Claude sessions

#### Web & Search
- **Brave Search**: Web search integration (requires API key)
- **Puppeteer**: Browser automation for testing and scraping
- **Playwright**: Modern web automation using accessibility trees

#### Cloud & Infrastructure
- **GitHub**: Repository management, PRs, CI/CD workflows
- **AWS Knowledge**: AWS documentation access
- **Cloudflare Workers**: Cloudflare Workers integration
- **Cloudflare Docs**: Cloudflare documentation access

#### Database
- **PostgreSQL**: Database operations and queries
- **SQLite**: Lightweight database operations

#### Productivity & Collaboration
- **Notion**: Knowledge base integration (requires API token)
- **Linear**: Project management and issue tracking
- **Atlassian**: Jira and Confluence access
- **Slack**: Team communication integration

#### Monitoring & Observability
- **Sentry**: Error tracking and performance monitoring
- **PostHog**: Product analytics and feature flags

#### Design & API
- **Figma**: Design tool integration (requires local desktop app)

#### Git & Version Control
- **Git**: Version control operations
- **GitLab**: GitLab repository management

### MCP Marketplaces & Directories

The script provides information about these popular MCP marketplaces:

1. **Cline MCP Marketplace** - https://github.com/cline/mcp-marketplace
   - Official repository for submitting and discovering MCP servers

2. **MCPMarket.com** - https://mcpmarket.com/
   - Discover top MCP servers with ratings and reviews

3. **MCP.so** - https://mcp.so/
   - OpenSource MCP Marketplace with HTML plugin integration

4. **Higress MCP Marketplace** - https://mcp.higress.ai/
   - The shortest path connecting AI with the real world

5. **MCPcat.io** - https://mcpcat.io/
   - Comprehensive guides and MCP server catalog

6. **Smithery.ai** - https://smithery.ai/
   - MCP server registry and discovery platform

7. **glama.ai MCP Servers** - https://glama.ai/mcp/servers
   - Curated collection of MCP servers

### Environment Variables Required

Some MCP servers require environment variables to be configured:

- **Brave Search**: `BRAVE_API_KEY`
- **Notion**: `NOTION_API_TOKEN`
- **AWS**: `AWS_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- **Google Cloud**: `GOOGLE_APPLICATION_CREDENTIALS`

### Post-Installation Steps

1. Configure required API keys and tokens for MCPs that need them
2. Restart Claude Code CLI to activate new MCP servers
3. Use `claude mcp list` to verify installed servers
4. Explore MCP marketplaces for additional specialized servers

### Managing MCP Servers

```bash
# List all installed MCP servers
claude mcp list

# Remove an MCP server
claude mcp remove <server-name>

# Add a new MCP server manually
claude mcp add <server-name> <command> -- <args>
```

### Examples

```bash
# Interactive installation with menu
./setup-claude-mcp.sh --interactive

# Quick install everything
./setup-claude-mcp.sh --all

# Just want to see available marketplaces
./setup-claude-mcp.sh --marketplaces

# Check what's already installed
./setup-claude-mcp.sh --list
```

### Troubleshooting

**Claude CLI not found**
- Ensure Claude Code CLI is installed
- Visit https://code.claude.com for installation instructions

**Node.js not found**
- Install Node.js from https://nodejs.org
- Most MCP servers require Node.js and npm

**Installation failures**
- Check internet connection
- Verify you have the latest npm version: `npm install -g npm@latest`
- Some MCPs may require specific environment variables or credentials

**MCP server not working**
- Restart Claude Code CLI after installation
- Check if required environment variables are set
- Use `claude mcp list` to verify the server is installed

### Learn More

- [Claude Code Documentation](https://code.claude.com/docs)
- [MCP Specification](https://modelcontextprotocol.io/)
- [Claude Code MCP Guide](https://code.claude.com/docs/en/mcp)

## 📝 Contributing

Feel free to submit issues or pull requests to add more MCP servers or improve the installation script.

## ⚠️ Important Notes

- Some MCP servers require paid API keys or subscriptions
- Review each MCP server's documentation for specific requirements
- Keep API keys and tokens secure - never commit them to version control
- Use environment variables or secure credential managers for sensitive data

## 📄 License

These scripts are provided as-is for personal use.
