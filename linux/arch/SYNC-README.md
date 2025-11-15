# Arch Linux Machine Sync Setup

Automated bidirectional sync between your desktop and laptop Arch Linux installations using `rsync` and `cron`.

## Overview

This setup provides two scripts:

1. **sync-machines.sh** - Manual rsync script for syncing home directories
2. **setup-sync-cron.sh** - Automated cron job setup for scheduled syncing

## Features

- Bidirectional sync between desktop and laptop
- Intelligent exclusion of caches, build artifacts, and machine-specific files
- Preserves permissions, timestamps, and symbolic links
- Comprehensive logging
- Dry-run mode for testing
- SSH-based secure transfer with compression
- Automatic detection of current machine
- Configurable sync intervals

## Prerequisites

### 1. Install Required Packages

```bash
sudo pacman -S rsync openssh cronie
```

### 2. Configure SSH Hostnames

Edit `/etc/hosts` on both machines to add entries for each other:

```bash
# On Desktop
192.168.1.100   draogo-omarchy-laptop

# On Laptop
192.168.1.101   draogo-omarchy-desktop
```

Or use your router's DNS if hostnames are already configured.

### 3. Set Up SSH Passwordless Authentication

On both machines, generate SSH keys (if you don't have them):

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

Copy your public key to the remote machine:

```bash
# On Desktop (to access laptop)
ssh-copy-id draogo-omarchy-laptop

# On Laptop (to access desktop)
ssh-copy-id draogo-omarchy-desktop
```

Test the connection:

```bash
# From desktop
ssh draogo-omarchy-laptop

# From laptop
ssh draogo-omarchy-desktop
```

You should be able to connect without entering a password.

## Quick Start

### Manual Sync (One-time)

```bash
# Test what would be synced (dry-run)
./sync-machines.sh to-laptop --dry-run

# Actually sync to laptop
./sync-machines.sh to-laptop

# Sync to desktop
./sync-machines.sh to-desktop
```

### Automated Sync (Cron Job)

```bash
# Setup auto-sync every 30 minutes (default)
./setup-sync-cron.sh

# Setup sync every hour
./setup-sync-cron.sh --interval 60

# Setup sync every 15 minutes
./setup-sync-cron.sh --interval 15

# Test with dry-run mode first
./setup-sync-cron.sh --dry-run

# List current sync jobs
./setup-sync-cron.sh --list

# Remove sync job
./setup-sync-cron.sh --remove
```

## Configuration

### Customizing Hostnames

Edit both `sync-machines.sh` and `setup-sync-cron.sh` to update:

```bash
DESKTOP_HOST="your-desktop-hostname"
LAPTOP_HOST="your-laptop-hostname"
```

### Customizing Exclude Patterns

Edit the `EXCLUDES` array in `sync-machines.sh` to add or remove patterns.

Current exclusions include:

- **Security**: SSH keys, GPG keys, credentials, API tokens
- **Caches**: npm, cargo, gradle, pip, conda, browser caches
- **Build artifacts**: target/, dist/, node_modules/, venv/
- **System files**: Trash, logs, thumbnails, runtime files
- **Large files**: Docker volumes, VMs, game files, mail data
- **Machine-specific**: Browser profiles, IDE extensions, display settings

### What Gets Synced

Everything in your home directory **except** the excluded patterns:

- Documents, dotfiles, scripts
- Git repositories (but not node_modules or build artifacts)
- Configuration files (except machine-specific ones)
- SSH config (but not private keys)
- Development projects (source code only)
- Personal files, photos, etc.

## Usage Examples

### Scenario 1: Initial Setup on Both Machines

1. On desktop, test the sync:
   ```bash
   ./sync-machines.sh to-laptop --dry-run
   ```

2. If it looks good, do the actual sync:
   ```bash
   ./sync-machines.sh to-laptop
   ```

3. Set up automatic sync:
   ```bash
   ./setup-sync-cron.sh --interval 30
   ```

4. Repeat on laptop (or let it auto-sync after 30 minutes)

### Scenario 2: Testing Before Committing

```bash
# Preview what would change
./sync-machines.sh to-laptop --dry-run | less

# Review the output carefully
# If satisfied, run without --dry-run
./sync-machines.sh to-laptop
```

### Scenario 3: Different Intervals for Different Machines

```bash
# On desktop: sync every hour (less frequent)
./setup-sync-cron.sh --interval 60

# On laptop: sync every 15 minutes (more frequent)
./setup-sync-cron.sh --interval 15
```

### Scenario 4: Monitoring Sync Activity

```bash
# View live sync logs from cron
tail -f ~/.local/share/sync-logs/cron-sync.log

# View latest manual sync log
ls -lt ~/.local/share/sync-logs/ | head -n 2
tail ~/.local/share/sync-logs/sync-YYYYMMDD-HHMMSS.log
```

## Advanced Options

### Sync Direction Modes

The `--direction` flag in `setup-sync-cron.sh` supports:

- `auto` (default): Automatically determines direction based on hostname
  - Desktop syncs TO laptop
  - Laptop syncs TO desktop

- `to-laptop`: Always sync from current machine to laptop

- `to-desktop`: Always sync from current machine to desktop

### Custom Intervals

Supported intervals in minutes:

- 15, 30, 60 (1 hour), 120 (2 hours)
- 180 (3 hours), 240 (4 hours), 360 (6 hours)
- 720 (12 hours), 1440 (24 hours/daily)

Any custom interval will be converted to the appropriate cron format.

### Cron Management

```bash
# List all cron jobs
crontab -l

# Edit cron jobs manually
crontab -e

# Remove all cron jobs (be careful!)
crontab -r
```

## Logs

All sync operations are logged:

- **Manual syncs**: `~/.local/share/sync-logs/sync-YYYYMMDD-HHMMSS.log`
- **Cron syncs**: `~/.local/share/sync-logs/cron-sync.log`

View recent activity:

```bash
# Latest cron sync output
tail -n 100 ~/.local/share/sync-logs/cron-sync.log

# Find failed syncs
grep -i "error\|failed" ~/.local/share/sync-logs/*.log

# View sync statistics
grep "Number of files\|Total file size" ~/.local/share/sync-logs/*.log
```

## Troubleshooting

### Issue: "Cannot connect to remote host"

**Solution**:
1. Verify SSH connection: `ssh draogo-omarchy-laptop`
2. Check hostname resolution: `ping draogo-omarchy-laptop`
3. Ensure SSH keys are set up: `ssh-copy-id draogo-omarchy-laptop`

### Issue: "Permission denied"

**Solution**:
1. Check file permissions on both machines
2. Ensure you're using the same username on both systems
3. Verify SSH config allows your user

### Issue: "Sync is very slow"

**Solution**:
1. Check network bandwidth between machines
2. Review exclude patterns - you may be syncing large files
3. Use `--dry-run` to see what's being transferred
4. Consider adding more patterns to the EXCLUDES array

### Issue: "Cron job not running"

**Solution**:
1. Check if cronie is running: `systemctl status cronie`
2. View cron logs: `journalctl -u cronie`
3. Verify crontab: `crontab -l`
4. Check script permissions: `ls -l sync-machines.sh`

### Issue: "Files being deleted unexpectedly"

**Solution**:
The `--delete` flag removes files on the destination that don't exist on the source. This is intentional for true syncing. If you want to keep files:

1. Temporarily disable automatic sync
2. Manually sync with `--dry-run` to see what would be deleted
3. Add patterns to EXCLUDES for files you want to keep locally

### Issue: "Want to sync specific folders only"

**Solution**:
Modify `sync-machines.sh` to change SOURCE_DIR or add include patterns before exclude patterns in rsync options.

## Security Considerations

- **SSH Keys**: Private keys are excluded from sync for security
- **Credentials**: AWS, GCP, Docker credentials are excluded
- **Browser Data**: Cookies and session data are not synced
- **Mail**: Email data is excluded (sync separately if needed)

If you need to sync passwords or credentials, use a dedicated password manager with its own sync mechanism.

## Best Practices

1. **Test First**: Always use `--dry-run` before major syncs
2. **Monitor Logs**: Check sync logs periodically for errors
3. **Backup Important Data**: Keep backups independent of sync
4. **Review Excludes**: Customize EXCLUDES for your workflow
5. **Network Quality**: Use on reliable networks (avoid metered connections)
6. **Start Small**: Begin with longer intervals, adjust as needed

## Integration with Arch Setup

These sync scripts integrate with the main Arch setup script (`setup-arch.sh`):

```bash
# Run the full Arch setup (includes rsync installation)
./setup-arch.sh

# Then configure syncing
./setup-sync-cron.sh
```

## Uninstall

To completely remove the sync setup:

```bash
# Remove cron job
./setup-sync-cron.sh --remove

# Remove logs (optional)
rm -rf ~/.local/share/sync-logs/

# The scripts themselves can remain for future use
```

## Performance Tips

- **Network**: Use wired Ethernet for faster sync
- **Compression**: Already enabled (`-z` flag) for slow networks
- **Partial Transfers**: Enabled to resume interrupted transfers
- **Excludes**: Regularly review and update exclude patterns

## Comparison with Other Sync Tools

| Feature | rsync + cron | Syncthing | Nextcloud |
|---------|--------------|-----------|-----------|
| Setup complexity | Low | Medium | High |
| Resource usage | Low | Medium | High |
| Real-time sync | No | Yes | Yes |
| Selective sync | Yes | Yes | Yes |
| Server required | No | No | Yes |
| Version control | No | Yes | Yes |
| Cross-platform | Linux only | All | All |

**When to use rsync + cron**:
- You only need Linux-to-Linux sync
- You want minimal resource usage
- You don't need real-time sync
- You have direct SSH access between machines

## Additional Resources

- rsync manual: `man rsync`
- cron format: `man 5 crontab`
- SSH setup: `man ssh-keygen`, `man ssh-copy-id`
- Arch Wiki: https://wiki.archlinux.org/title/Rsync

## Support

For issues or questions:
1. Check logs in `~/.local/share/sync-logs/`
2. Run with `--dry-run` to diagnose
3. Review exclude patterns
4. Test SSH connection manually
5. Check cron service status

## License

These scripts are part of the omarchy dotfiles collection.
