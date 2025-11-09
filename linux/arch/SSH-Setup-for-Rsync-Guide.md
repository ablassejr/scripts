# Complete Guide: Setting Up SSH for rsync

## Table of Contents
1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Understanding rsync Over SSH](#understanding-rsync-over-ssh)
4. [Step-by-Step Setup Guide](#step-by-step-setup-guide)
5. [Advanced Configuration](#advanced-configuration)
6. [Security Hardening](#security-hardening)
7. [Testing and Verification](#testing-and-verification)
8. [Troubleshooting](#troubleshooting)
9. [Real-World Examples](#real-world-examples)
10. [Best Practices](#best-practices)

---

## Introduction

**rsync** is a powerful file synchronization and transfer utility that can operate over SSH for secure, encrypted transfers. This guide provides detailed, step-by-step instructions for setting up SSH authentication specifically optimized for rsync usage.

### Why Use rsync Over SSH?

- **Encryption**: All data transferred is encrypted
- **Differential Transfers**: Only changed portions of files are transmitted
- **Bandwidth Efficiency**: Built-in compression and delta transfer algorithm
- **Integrity**: Checksums verify file integrity
- **Automation**: Perfect for scheduled backups and synchronization
- **Preservation**: Maintains permissions, ownership, timestamps, and attributes

### What You'll Learn

This guide covers:
- SSH key generation and deployment for rsync
- Passwordless authentication setup
- Security restrictions and best practices
- Advanced rsync configurations
- Troubleshooting common issues
- Real-world deployment scenarios

---

## Prerequisites

### System Requirements

#### On Both Source and Destination Systems:
- **SSH Server**: OpenSSH 7.0+ recommended
- **rsync**: Version 3.0+ recommended (check with `rsync --version`)
- **Shell Access**: Terminal/command-line access
- **User Account**: With appropriate permissions

#### Installation Commands

**Debian/Ubuntu:**
```bash
sudo apt update
sudo apt install openssh-server openssh-client rsync
```

**RHEL/CentOS/Fedora:**
```bash
sudo dnf install openssh-server openssh-clients rsync
# Or on older systems:
sudo yum install openssh-server openssh-clients rsync
```

**Arch Linux:**
```bash
sudo pacman -S openssh rsync
```

**macOS:**
```bash
# SSH is pre-installed
# Install rsync with Homebrew:
brew install rsync
```

### Verify Installations

```bash
# Check SSH client
ssh -V
# Output: OpenSSH_9.0p1, OpenSSL 3.0.7

# Check SSH server
sshd -v
# Or check if running:
systemctl status sshd  # Linux
sudo launchctl list | grep ssh  # macOS

# Check rsync
rsync --version
# Output: rsync  version 3.2.7  protocol version 31
```

### Network Requirements

- **Connectivity**: Source must be able to reach destination
- **Firewall**: SSH port (default 22) must be open
- **DNS/Hosts**: Hostname resolution or IP addresses available

```bash
# Test connectivity
ping -c 4 destination-host

# Test SSH port
telnet destination-host 22
# Or with nc:
nc -zv destination-host 22
```

---

## Understanding rsync Over SSH

### How rsync Uses SSH

When you run rsync with a remote host, it can use SSH as its transport mechanism:

```bash
rsync -avz /local/path/ user@remote:/remote/path/
```

**What happens internally:**

1. rsync initiates an SSH connection to the remote host
2. SSH authenticates the user (password or key-based)
3. SSH establishes an encrypted tunnel
4. rsync spawns a server process on the remote end
5. Both rsync processes communicate through the SSH tunnel
6. Files are synchronized using rsync's delta-transfer algorithm
7. All data is encrypted by SSH

### rsync Syntax with SSH

```bash
# Basic syntax
rsync [OPTIONS] SOURCE DESTINATION

# Local to remote
rsync [OPTIONS] /local/path/ user@host:/remote/path/

# Remote to local
rsync [OPTIONS] user@host:/remote/path/ /local/path/

# Remote to remote (through local host)
rsync [OPTIONS] user1@host1:/path/ user2@host2:/path/
```

### Common rsync Options

```bash
-a, --archive          # Archive mode (preserves permissions, times, etc.)
-v, --verbose          # Verbose output
-z, --compress         # Compress during transfer
-h, --human-readable   # Human-readable sizes
-P                     # Show progress and keep partial files
--delete               # Delete files in dest not in source
--dry-run, -n          # Test run without making changes
-e 'ssh -p 2222'       # Specify SSH command/port
```

---

## Step-by-Step Setup Guide

### Step 1: Verify SSH Server is Running

On the **destination/remote server**:

```bash
# Check if SSH daemon is running
systemctl status sshd

# If not running, start it
sudo systemctl start sshd

# Enable to start on boot
sudo systemctl enable sshd

# For macOS
sudo systemsetup -setremotelogin on
```

### Step 2: Test Basic SSH Connection

From the **source/local machine**, verify you can connect:

```bash
# Test SSH connection with password
ssh username@destination-host

# If successful, you'll get a shell prompt
# Type 'exit' to close the connection
```

**Common issues at this stage:**
- **Connection refused**: SSH server not running or firewall blocking
- **Permission denied**: Wrong username or password
- **Timeout**: Network connectivity or DNS issues

### Step 3: Generate SSH Key Pair

On the **source/local machine** (the machine that will initiate rsync):

```bash
# Generate Ed25519 key (recommended - most secure and efficient)
ssh-keygen -t ed25519 -C "rsync-backup-$(hostname)" -f ~/.ssh/id_ed25519_rsync

# Or generate RSA key (for compatibility with older systems)
ssh-keygen -t rsa -b 4096 -C "rsync-backup-$(hostname)" -f ~/.ssh/id_rsa_rsync
```

**Interactive prompts:**

```
Generating public/private ed25519 key pair.
Enter file in which to save the key (/home/user/.ssh/id_ed25519_rsync): [Press Enter]
Enter passphrase (empty for no passphrase): [Enter passphrase or leave empty]
Enter same passphrase again: [Repeat passphrase]
```

**Passphrase considerations:**

- **With passphrase**: More secure, but requires interaction (or ssh-agent)
- **Without passphrase**: Less secure, but enables full automation
- **Best practice for automation**: Use passphrase-protected keys with ssh-agent, or use restricted authorized_keys

**Files created:**
- `~/.ssh/id_ed25519_rsync` - Private key (NEVER share this)
- `~/.ssh/id_ed25519_rsync.pub` - Public key (safe to share)

### Step 4: Set Correct Permissions

```bash
# Ensure .ssh directory has correct permissions
chmod 700 ~/.ssh

# Ensure private key is readable only by you
chmod 600 ~/.ssh/id_ed25519_rsync

# Public key can be more permissive
chmod 644 ~/.ssh/id_ed25519_rsync.pub
```

**Why permissions matter:**
SSH will refuse to use keys with incorrect permissions as a security measure. Private keys must not be readable by other users.

### Step 5: Copy Public Key to Remote Server

**Method 1: Using ssh-copy-id (Easiest)**

```bash
# Copy the specific key to remote server
ssh-copy-id -i ~/.ssh/id_ed25519_rsync.pub username@destination-host

# You'll be prompted for the remote user's password one last time
# Enter the password, and the key will be installed
```

**Method 2: Manual Copy (If ssh-copy-id is unavailable)**

```bash
# Display your public key
cat ~/.ssh/id_ed25519_rsync.pub

# SSH to the remote server
ssh username@destination-host

# On remote server, ensure .ssh directory exists
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Append your public key to authorized_keys
nano ~/.ssh/authorized_keys
# Paste the public key as a single line, then save

# Set correct permissions
chmod 600 ~/.ssh/authorized_keys

# Exit remote shell
exit
```

**Method 3: One-liner (Advanced)**

```bash
cat ~/.ssh/id_ed25519_rsync.pub | ssh username@destination-host 'mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys'
```

### Step 6: Test SSH Key Authentication

```bash
# Test connection using the specific key
ssh -i ~/.ssh/id_ed25519_rsync username@destination-host

# If successful, you should connect WITHOUT entering a password
# You may be prompted for the key passphrase if you set one

# Verify and exit
whoami
hostname
exit
```

**Troubleshooting if password is still requested:**
- Check file permissions (Step 4)
- Verify public key was added correctly to `~/.ssh/authorized_keys`
- Check server logs: `sudo tail -f /var/log/auth.log`
- Try verbose mode: `ssh -vvv -i ~/.ssh/id_ed25519_rsync username@destination-host`

### Step 7: Configure SSH Client (Optional but Recommended)

Create/edit `~/.ssh/config` on the **source machine**:

```bash
nano ~/.ssh/config
```

Add configuration for your destination:

```ssh-config
# rsync Backup Server Configuration
Host backup-server
    HostName destination-host.example.com
    User username
    Port 22
    IdentityFile ~/.ssh/id_ed25519_rsync
    IdentitiesOnly yes
    Compression yes
    ServerAliveInterval 60
    ServerAliveCountMax 3

# Short alias for convenience
Host backup
    HostName 192.168.1.100
    User backup-user
    IdentityFile ~/.ssh/id_ed25519_rsync
```

Set correct permissions:

```bash
chmod 600 ~/.ssh/config
```

**Benefits:**
- Shorter commands: `ssh backup-server` instead of full connection string
- Consistent settings across all SSH connections to this host
- Easy to manage multiple destinations

### Step 8: Test rsync Over SSH

```bash
# Test dry-run (doesn't actually transfer files)
rsync -avzn -e "ssh -i ~/.ssh/id_ed25519_rsync" /source/test/ username@destination-host:/destination/test/

# If using SSH config from Step 7:
rsync -avzn /source/test/ backup-server:/destination/test/

# Actual transfer (remove -n flag)
rsync -avz -e "ssh -i ~/.ssh/id_ed25519_rsync" /source/test/ username@destination-host:/destination/test/
```

**Expected output:**
```
sending incremental file list
./
file1.txt
file2.txt
directory1/
directory1/file3.txt

sent 1,234 bytes  received 89 bytes  2,646.00 bytes/sec
total size is 10,000  speedup is 7.56
```

### Step 9: Create Backup Script (Optional)

Create a reusable backup script:

```bash
#!/bin/bash
# File: ~/bin/backup-to-remote.sh

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration
SOURCE_DIR="/home/user/important-data/"
DEST_HOST="backup-server"
DEST_DIR="/backups/user-data/"
SSH_KEY="$HOME/.ssh/id_ed25519_rsync"
LOG_FILE="$HOME/logs/rsync-backup.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Log start
echo "[$DATE] Backup started" >> "$LOG_FILE"

# Perform rsync
rsync -avz --delete \
    --exclude='.cache/' \
    --exclude='*.tmp' \
    -e "ssh -i $SSH_KEY" \
    "$SOURCE_DIR" \
    "${DEST_HOST}:${DEST_DIR}" \
    2>&1 | tee -a "$LOG_FILE"

# Log completion
echo "[$DATE] Backup completed" >> "$LOG_FILE"
echo "---" >> "$LOG_FILE"
```

Make it executable:

```bash
chmod +x ~/bin/backup-to-remote.sh

# Test run
~/bin/backup-to-remote.sh
```

### Step 10: Automate with Cron (Optional)

Schedule automatic backups:

```bash
# Edit crontab
crontab -e

# Add entries (adjust paths and schedule as needed)

# Daily backup at 2 AM
0 2 * * * /home/user/bin/backup-to-remote.sh

# Hourly backup during business hours (9 AM - 6 PM, Mon-Fri)
0 9-18 * * 1-5 /home/user/bin/backup-to-remote.sh

# Weekly backup every Sunday at 3 AM
0 3 * * 0 /home/user/bin/backup-to-remote.sh
```

**Important for cron jobs:**
- Use absolute paths
- Ensure SSH key has no passphrase OR use ssh-agent
- Redirect output to log file
- Test manually first

---

## Advanced Configuration

### Restricted SSH Keys for rsync

Limit what the SSH key can do by adding restrictions to `~/.ssh/authorized_keys` on the **remote server**:

#### Basic Restriction (Command Only)

```bash
# In ~/.ssh/authorized_keys on REMOTE server
restrict,command="rsync --server --daemon ." ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... rsync-backup
```

This forces the key to only run rsync in server mode.

#### Restrict with Directory Limitation (using rrsync)

**rrsync** is a restricted rsync wrapper included with rsync. It confines rsync to a specific directory.

**Step 1: Install/Locate rrsync**

```bash
# Find rrsync
find /usr -name rrsync 2>/dev/null

# Common locations:
# /usr/bin/rrsync
# /usr/share/rsync/rrsync
# /usr/local/bin/rrsync

# If not found, download from rsync source
wget https://raw.githubusercontent.com/WayneD/rsync/master/support/rrsync
chmod +x rrsync
sudo mv rrsync /usr/local/bin/
```

**Step 2: Configure authorized_keys with rrsync**

```bash
# In ~/.ssh/authorized_keys on REMOTE server

# Read-write access to specific directory
command="/usr/local/bin/rrsync /backup/client-data" ssh-ed25519 AAAAC3... rsync-key

# Read-only access
command="/usr/local/bin/rrsync -ro /backup/client-data" ssh-ed25519 AAAAC3... rsync-ro-key

# Write-only access (for backups)
command="/usr/local/bin/rrsync -wo /backup/client-data" ssh-ed25519 AAAAC3... rsync-backup-key

# Read-only with additional restrictions
command="/usr/local/bin/rrsync -ro -no-del /backup/client-data" ssh-ed25519 AAAAC3... rsync-safe-key
```

**rrsync Options:**
```bash
-ro              # Read-only
-wo              # Write-only
-no-del          # Disable delete operations
-no-overwrite    # Prevent overwriting existing files
-munge           # Enable symlink munging for security
```

#### Additional Restrictions

Combine multiple restrictions:

```bash
# Restrict by source IP, command, and disable dangerous features
restrict,from="192.168.1.100",command="/usr/local/bin/rrsync /backup/data",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ssh-ed25519 AAAAC3... backup-key

# Time-limited key for temporary access
restrict,expiry-time="20251231235959",command="/usr/local/bin/rrsync /backup/temp" ssh-ed25519 AAAAC3... temp-backup

# Multiple allowed source IPs
from="192.168.1.100,192.168.1.101,10.0.0.50" ssh-ed25519 AAAAC3... multi-source-key
```

### rsync Daemon Over SSH

For more complex scenarios, you can run rsync in daemon mode over SSH:

**Step 1: Create rsyncd.conf**

On the **remote server**, create `/etc/rsyncd.conf` or `~/.rsyncd.conf`:

```conf
# ~/.rsyncd.conf

# Global settings
uid = nobody
gid = nobody
use chroot = no
max connections = 4
log file = /home/username/rsync.log

# Module definition
[backup]
    path = /backup/data
    comment = Backup storage
    read only = no
    list = yes
    auth users = backup-user
    secrets file = /home/username/.rsyncd.secrets

[readonly-archive]
    path = /archive
    comment = Read-only archive
    read only = yes
    list = yes
```

**Step 2: Create secrets file**

```bash
# Create password file
echo "backup-user:SecurePassword123" > ~/.rsyncd.secrets
chmod 600 ~/.rsyncd.secrets
```

**Step 3: Configure authorized_keys**

```bash
# In ~/.ssh/authorized_keys
restrict,command="rsync --server --daemon --config=$HOME/.rsyncd.conf ." ssh-ed25519 AAAAC3... daemon-key
```

**Step 4: Use from client**

```bash
# Syntax: rsync://[user@]host[:port]/module/path
rsync -avz --password-file=~/.rsync-password /local/data/ username@server::backup/

# With SSH transport
rsync -avz -e ssh /local/data/ username@server::'backup'
```

### Using Different SSH Ports

If your SSH server runs on a non-standard port:

**Method 1: Command-line**

```bash
rsync -avz -e "ssh -p 2222 -i ~/.ssh/id_ed25519_rsync" /local/ user@host:/remote/
```

**Method 2: SSH Config**

```ssh-config
# In ~/.ssh/config
Host backup-server
    HostName server.example.com
    User backup-user
    Port 2222
    IdentityFile ~/.ssh/id_ed25519_rsync
```

Then use:

```bash
rsync -avz /local/ backup-server:/remote/
```

### Using SSH Jump Hosts (Bastion)

When the destination is behind a bastion/jump host:

**SSH Config Method:**

```ssh-config
# In ~/.ssh/config

# Bastion host
Host bastion
    HostName bastion.example.com
    User jump-user
    IdentityFile ~/.ssh/id_bastion

# Internal server through bastion
Host internal-backup
    HostName 10.0.1.50
    User backup-user
    IdentityFile ~/.ssh/id_ed25519_rsync
    ProxyJump bastion
```

Then rsync through the jump host:

```bash
rsync -avz /local/data/ internal-backup:/backup/
```

**Command-line Method:**

```bash
rsync -avz -e "ssh -J jump-user@bastion.example.com" /local/ backup-user@10.0.1.50:/remote/
```

---

## Security Hardening

### 1. Server-Side SSH Configuration

On the **remote server**, edit `/etc/ssh/sshd_config`:

```bash
# Security-focused sshd_config for rsync server

# Disable password authentication (keys only)
PasswordAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no
PermitEmptyPasswords no

# Disable root login
PermitRootLogin no

# Limit to specific users
AllowUsers backup-user rsync-user

# Disable unnecessary features
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
PermitTunnel no
GatewayPorts no

# Rate limiting
MaxAuthTries 3
MaxSessions 5
LoginGraceTime 30s

# Use strong cryptography
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com

# Logging
LogLevel VERBOSE
SyslogFacility AUTH

# Performance (if bandwidth is sufficient)
Compression delayed
```

Restart SSH daemon:

```bash
# Test configuration first
sudo sshd -t

# Restart SSH
sudo systemctl restart sshd
```

### 2. Firewall Configuration

Limit SSH access to specific IPs:

**Using ufw (Ubuntu/Debian):**

```bash
# Allow SSH only from specific IP
sudo ufw allow from 192.168.1.100 to any port 22

# Allow from subnet
sudo ufw allow from 192.168.1.0/24 to any port 22

# Enable firewall
sudo ufw enable
```

**Using firewalld (RHEL/CentOS):**

```bash
# Add rich rule for specific source
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.1.100" port port="22" protocol="tcp" accept'

# Reload
sudo firewall-cmd --reload
```

**Using iptables:**

```bash
# Allow from specific IP
sudo iptables -A INPUT -p tcp -s 192.168.1.100 --dport 22 -j ACCEPT

# Drop all other SSH attempts
sudo iptables -A INPUT -p tcp --dport 22 -j DROP

# Save rules
sudo iptables-save > /etc/iptables/rules.v4
```

### 3. Rate Limiting with fail2ban

Install and configure fail2ban to block brute-force attempts:

```bash
# Install
sudo apt install fail2ban  # Debian/Ubuntu
sudo dnf install fail2ban  # RHEL/Fedora

# Create local configuration
sudo nano /etc/fail2ban/jail.local
```

Add:

```ini
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
destemail = admin@example.com
sendername = Fail2Ban
action = %(action_mwl)s

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 86400
```

Start fail2ban:

```bash
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Check status
sudo fail2ban-client status sshd
```

### 4. Client-Side Security

On the **source machine**:

```bash
# Protect private keys with passphrase
ssh-keygen -p -f ~/.ssh/id_ed25519_rsync

# Use ssh-agent to avoid repeated passphrase entry
eval $(ssh-agent)
ssh-add ~/.ssh/id_ed25519_rsync

# Set strict permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*
chmod 644 ~/.ssh/*.pub
chmod 644 ~/.ssh/known_hosts
chmod 600 ~/.ssh/config

# Use different keys for different purposes
# Avoid reusing the same key everywhere
```

### 5. Monitoring and Auditing

**Log rsync operations:**

```bash
# rsync with logging
rsync -avz --log-file=/var/log/rsync-backup.log /source/ user@host:/dest/

# Server-side logging in rsyncd.conf
log file = /var/log/rsyncd.log
log format = %t %o %h [%a] %m (%u) %f %l
transfer logging = yes
```

**Monitor SSH access:**

```bash
# Watch authentication attempts
sudo tail -f /var/log/auth.log | grep sshd

# Review successful connections
sudo grep "Accepted" /var/log/auth.log | tail -20

# Review failed attempts
sudo grep "Failed" /var/log/auth.log | tail -20

# Check currently connected users
who
w
last | head -20
```

---

## Testing and Verification

### Pre-Flight Checks

Before putting your rsync setup into production:

#### 1. Test SSH Connection

```bash
# Verbose SSH test
ssh -vvv -i ~/.ssh/id_ed25519_rsync username@destination-host

# Look for:
# - "debug1: Authentication succeeded (publickey)"
# - No password prompts
# - Successful shell access
```

#### 2. Test rsync Dry Run

```bash
# Dry run shows what would be transferred without actually doing it
rsync -avzn --delete /source/ user@host:/destination/

# Review output carefully
# Check for unexpected deletions (if using --delete)
# Verify paths are correct
```

#### 3. Test Small Transfer

```bash
# Create test directory
mkdir -p /tmp/rsync-test-source
echo "Test file content" > /tmp/rsync-test-source/test.txt

# Transfer
rsync -avz /tmp/rsync-test-source/ user@host:/tmp/rsync-test-dest/

# Verify on remote
ssh user@host 'cat /tmp/rsync-test-dest/test.txt'

# Should output: Test file content
```

#### 4. Test Bandwidth Limiting

```bash
# Limit to 1 MB/s (1000 KB/s)
rsync -avz --bwlimit=1000 /source/ user@host:/destination/
```

#### 5. Test Exclusions

```bash
# Test exclude patterns
rsync -avzn \
    --exclude='*.log' \
    --exclude='.cache/' \
    --exclude='tmp/' \
    /source/ user@host:/destination/

# Verify excluded files don't appear in dry-run output
```

### Verification Checklist

- [ ] SSH connection works without password
- [ ] rsync transfers files successfully
- [ ] File permissions are preserved
- [ ] Timestamps are preserved
- [ ] Symbolic links handled correctly
- [ ] Exclusion patterns work as expected
- [ ] Deletion (if using --delete) works safely
- [ ] Bandwidth limiting works (if configured)
- [ ] Logging captures transfers
- [ ] Cron job executes successfully (if automated)
- [ ] SSH key restrictions work (if configured)
- [ ] Firewall allows connection from source

---

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: Permission Denied (publickey)

**Symptoms:**
```
Permission denied (publickey,password).
rsync: connection unexpectedly closed (0 bytes received so far) [sender]
```

**Diagnosis:**

```bash
# Test with verbose SSH
ssh -vvv -i ~/.ssh/id_ed25519_rsync username@destination-host

# Check server logs
# On remote server:
sudo tail -f /var/log/auth.log
```

**Common Causes & Solutions:**

1. **Wrong permissions on files**
   ```bash
   # On LOCAL machine:
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/id_ed25519_rsync

   # On REMOTE server:
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/authorized_keys
   ```

2. **Public key not in authorized_keys**
   ```bash
   # Copy public key again
   ssh-copy-id -i ~/.ssh/id_ed25519_rsync.pub username@destination-host
   ```

3. **Wrong user or hostname**
   ```bash
   # Verify username
   ssh username@destination-host whoami
   ```

4. **SELinux blocking (RHEL/CentOS)**
   ```bash
   # Check SELinux status
   getenforce

   # Restore correct SELinux context
   restorecon -R ~/.ssh
   ```

#### Issue 2: Host Key Verification Failed

**Symptoms:**
```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
```

**Cause:** Server's host key changed (reinstall, hardware change, or MITM attack)

**Solution:**

```bash
# Remove old host key
ssh-keygen -R destination-host

# Or remove specific line from known_hosts
nano ~/.ssh/known_hosts
# Delete the line mentioned in the error

# Reconnect and verify NEW fingerprint through trusted channel
ssh username@destination-host
```

#### Issue 3: rsync: connection unexpectedly closed

**Symptoms:**
```
rsync: connection unexpectedly closed (0 bytes received so far) [sender]
rsync error: error in rsync protocol data stream (code 12)
```

**Common Causes & Solutions:**

1. **rsync not installed on remote**
   ```bash
   ssh user@host 'which rsync'
   # If not found:
   ssh user@host 'sudo apt install rsync'  # Or appropriate package manager
   ```

2. **Different rsync versions (incompatible protocol)**
   ```bash
   # Check versions
   rsync --version
   ssh user@host 'rsync --version'

   # Solution: Upgrade older version
   ```

3. **Forced command in authorized_keys blocking rsync**
   ```bash
   # Check authorized_keys on remote
   ssh user@host 'cat ~/.ssh/authorized_keys'

   # Ensure command allows rsync, e.g.:
   # restrict,command="rsync --server --daemon ." ssh-ed25519 ...
   ```

#### Issue 4: Slow Transfer Speeds

**Diagnosis:**

```bash
# Test with bandwidth monitoring
rsync -avz --progress --stats /source/ user@host:/destination/
```

**Solutions:**

1. **Disable compression on fast networks**
   ```bash
   # Compression adds CPU overhead
   rsync -av /source/ user@host:/destination/  # No -z flag
   ```

2. **Enable compression on slow networks**
   ```bash
   rsync -avz --compress-level=9 /source/ user@host:/destination/
   ```

3. **Use faster SSH cipher**
   ```bash
   rsync -av -e "ssh -c aes128-gcm@openssh.com" /source/ user@host:/destination/
   ```

4. **Increase SSH buffer sizes**
   ```bash
   rsync -av -e "ssh -o 'TCPRcvBuf=262144' -o 'TCPSndBuf=262144'" /source/ user@host:/destination/
   ```

#### Issue 5: Disk Space Issues

**Symptoms:**
```
rsync: write failed on "/destination/file": No space left on device (28)
```

**Diagnosis:**

```bash
# Check remote disk space
ssh user@host 'df -h /destination'

# Check inodes
ssh user@host 'df -i /destination'
```

**Solutions:**

```bash
# Free up space on remote
ssh user@host 'du -sh /destination/* | sort -h | tail -10'

# Use --delete-before to remove old files first
rsync -avz --delete-before /source/ user@host:/destination/

# Or specify temp directory with more space
rsync -avz --temp-dir=/large-partition/tmp /source/ user@host:/destination/
```

#### Issue 6: Symbolic Link Issues

**Symptoms:**
Symlinks not transferred or broken on destination

**Solutions:**

```bash
# Preserve symlinks (default with -a)
rsync -avz /source/ user@host:/destination/

# Copy symlink targets instead of symlinks
rsync -avzL /source/ user@host:/destination/

# Transform absolute symlinks to relative
rsync -avz --copy-unsafe-links /source/ user@host:/destination/

# Munge symlinks for security (when using rrsync)
# In authorized_keys:
command="/usr/local/bin/rrsync -munge /backup" ssh-ed25519 ...
```

---

## Real-World Examples

### Example 1: Daily Backup to Remote Server

**Scenario:** Backup home directory to remote server daily, excluding cache and temporary files.

```bash
#!/bin/bash
# daily-backup.sh

set -euo pipefail

SOURCE="/home/user/"
DEST="backup-server:/backups/home/"
LOG="/var/log/rsync-home-backup.log"
EXCLUDE_FILE="/home/user/.rsync-exclude"

# Create exclude file
cat > "$EXCLUDE_FILE" <<EOF
.cache/
.tmp/
.local/share/Trash/
*.tmp
*.log
Downloads/
.mozilla/firefox/*/Cache/
.config/google-chrome/*/Cache/
EOF

# Run backup
rsync -avz --delete \
    --exclude-from="$EXCLUDE_FILE" \
    --log-file="$LOG" \
    --backup --backup-dir="/backups/home-incremental/$(date +%Y%m%d)" \
    "$SOURCE" "$DEST"

# Optional: Cleanup old incremental backups (keep 30 days)
ssh backup-server "find /backups/home-incremental/ -type d -mtime +30 -exec rm -rf {} +"
```

**Cron entry:**
```cron
0 2 * * * /home/user/bin/daily-backup.sh
```

### Example 2: Two-Way Sync Between Machines

**Scenario:** Keep two machines synchronized (use with caution - can cause data loss if not careful)

```bash
#!/bin/bash
# bidirectional-sync.sh

set -euo pipefail

SYNC_DIR="/home/user/Documents/shared/"
REMOTE="workstation:/home/user/Documents/shared/"

# Sync local to remote
rsync -avzu --delete "$SYNC_DIR" "$REMOTE"

# Sync remote to local
rsync -avzu --delete "$REMOTE" "$SYNC_DIR"
```

**Warning:** Bidirectional sync can cause data loss if files are deleted. Consider using version control or unison instead.

### Example 3: Incremental Backup with Hardlinks

**Scenario:** Space-efficient incremental backups using hardlinks

```bash
#!/bin/bash
# incremental-backup.sh

set -euo pipefail

SOURCE="/data/important/"
BACKUP_ROOT="/backups/"
REMOTE="backup-server"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
LATEST="$BACKUP_ROOT/latest"
NEW_BACKUP="$BACKUP_ROOT/$DATE"

# Create new backup with hardlinks to previous backup
ssh "$REMOTE" "mkdir -p $NEW_BACKUP"

rsync -avz --delete \
    --link-dest="$LATEST" \
    "$SOURCE" \
    "$REMOTE:$NEW_BACKUP/"

# Update 'latest' symlink
ssh "$REMOTE" "rm -f $LATEST && ln -s $NEW_BACKUP $LATEST"

# Cleanup: keep only last 30 backups
ssh "$REMOTE" "cd $BACKUP_ROOT && ls -1t | tail -n +31 | xargs -r rm -rf"
```

**Result:** Each backup is a full snapshot, but unchanged files use hardlinks, saving space.

### Example 4: Backup Multiple Servers to Central Repository

**Scenario:** Central backup server pulls from multiple clients

```bash
#!/bin/bash
# central-backup.sh - Run on backup server

set -euo pipefail

BACKUP_ROOT="/backups"
LOG_DIR="/var/log/backups"
DATE=$(date +%Y%m%d)

# List of servers to back up
SERVERS=(
    "web1.example.com:/var/www/"
    "web2.example.com:/var/www/"
    "db1.example.com:/var/lib/mysql/"
    "files.example.com:/home/"
)

mkdir -p "$LOG_DIR"

for server_path in "${SERVERS[@]}"; do
    # Extract server name and source path
    server="${server_path%%:*}"
    source="${server_path#*:}"

    # Create backup directory
    backup_dir="$BACKUP_ROOT/$server/$DATE"
    mkdir -p "$backup_dir"

    # Perform backup
    echo "Backing up $server:$source..."
    rsync -avz --delete \
        --timeout=3600 \
        --log-file="$LOG_DIR/${server}_${DATE}.log" \
        "root@$server:$source" \
        "$backup_dir/" \
        || echo "ERROR: Failed to backup $server" | tee -a "$LOG_DIR/errors.log"
done

# Cleanup old backups (keep 7 days)
find "$BACKUP_ROOT" -type d -name "[0-9]*" -mtime +7 -exec rm -rf {} +

echo "Backup completed at $(date)"
```

### Example 5: Secure Backup with Encryption

**Scenario:** Encrypt files before transfer for extra security

```bash
#!/bin/bash
# encrypted-backup.sh

set -euo pipefail

SOURCE="/sensitive/data/"
DEST="backup-server:/encrypted-backups/"
ENCRYPT_KEY="backup@example.com"  # GPG key ID

# Create temporary directory for encrypted files
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Encrypt files
find "$SOURCE" -type f -print0 | while IFS= read -r -d '' file; do
    rel_path="${file#$SOURCE}"
    mkdir -p "$TEMP_DIR/$(dirname "$rel_path")"
    gpg --encrypt --recipient "$ENCRYPT_KEY" \
        --output "$TEMP_DIR/$rel_path.gpg" "$file"
done

# Transfer encrypted files
rsync -avz --delete "$TEMP_DIR/" "$DEST"

echo "Encrypted backup completed"
```

---

## Best Practices

### 1. Planning and Strategy

✅ **DO:**
- Test backups before automation
- Perform dry runs first (`--dry-run`)
- Document your backup strategy
- Verify backups periodically
- Keep multiple backup generations
- Monitor backup success/failure
- Have a restoration procedure documented and tested

❌ **DON'T:**
- Use `--delete` without testing first
- Run bidirectional syncs without understanding the risks
- Ignore backup logs
- Assume backups work without testing restoration
- Use the same SSH key for everything

### 2. Performance Optimization

```bash
# For large files, use checksums only for changed files
rsync -avz --no-whole-file /source/ user@host:/dest/

# Skip based on checksum instead of size+time (slower but accurate)
rsync -avzc /source/ user@host:/dest/

# Increase batch size for many small files
rsync -avz --batch-size=1000 /source/ user@host:/dest/

# Use partial transfers for resumability
rsync -avzP /source/ user@host:/dest/
```

### 3. Safety Measures

```bash
# Always test with dry-run first
rsync -avzn --delete /source/ user@host:/dest/

# Use --backup to keep deleted files
rsync -avz --delete --backup --backup-dir=/backup/deleted /source/ user@host:/dest/

# Set maximum delete threshold
rsync -avz --delete --max-delete=100 /source/ user@host:/dest/

# Exclude important files
rsync -avz --exclude='*.db' --exclude='/config/' /source/ user@host:/dest/
```

### 4. Monitoring and Maintenance

```bash
# Email on completion
rsync -avz /source/ user@host:/dest/ && \
    echo "Backup completed successfully" | mail -s "Backup Status" admin@example.com

# Log with timestamps
rsync -avz --log-file="/var/log/rsync-$(date +%Y%m%d).log" /source/ user@host:/dest/

# Check exit status
rsync -avz /source/ user@host:/dest/
if [ $? -eq 0 ]; then
    echo "Success"
else
    echo "Failed with code $?" | mail -s "Backup FAILED" admin@example.com
fi
```

### 5. Key Management

```bash
# Use separate keys for different purposes
~/.ssh/id_ed25519_backup_server1
~/.ssh/id_ed25519_backup_server2
~/.ssh/id_ed25519_admin

# Rotate keys annually
# Document when keys were created
# Remove old authorized_keys entries when keys are rotated

# Use ssh-agent for passphrase-protected keys
eval $(ssh-agent)
ssh-add ~/.ssh/id_ed25519_rsync
# Keys remain unlocked for session duration
```

---

## Conclusion

You now have a comprehensive understanding of how to set up and use SSH for rsync operations securely and efficiently. Key takeaways:

### Essential Steps Recap

1. **Generate SSH keys** on the source machine
2. **Copy public key** to destination's `authorized_keys`
3. **Test connection** before automation
4. **Configure restrictions** for security
5. **Automate carefully** with proper logging
6. **Monitor and verify** backups regularly

### Security Checklist

- ✅ Password authentication disabled
- ✅ Key-based authentication only
- ✅ SSH keys with restricted permissions
- ✅ `authorized_keys` with command restrictions
- ✅ Firewall limiting SSH access
- ✅ fail2ban protecting against brute force
- ✅ Regular audit of SSH access logs

### Maintenance Schedule

- **Daily**: Check backup logs
- **Weekly**: Test backup restoration
- **Monthly**: Review disk space and cleanup
- **Quarterly**: Review authorized_keys entries
- **Annually**: Rotate SSH keys

rsync over SSH is a powerful combination for secure, efficient file synchronization and backups. With proper setup and security measures, it provides a robust foundation for data protection.

---

## Additional Resources

### Man Pages
```bash
man rsync
man ssh
man sshd_config
man ssh-keygen
man authorized_keys
```

### Useful rsync Options Reference

```bash
-a, --archive          # Preserve almost everything
-v, --verbose          # Increase verbosity
-z, --compress         # Compress during transfer
-P                     # --partial --progress
-h, --human-readable   # Output numbers in human-readable format
-n, --dry-run          # Perform trial run with no changes
-u, --update           # Skip files newer on receiver
-c, --checksum         # Skip based on checksum, not mod-time & size
-e, --rsh=COMMAND      # Specify remote shell
--delete               # Delete extraneous files from dest
--delete-before        # Receiver deletes before transfer
--delete-after         # Receiver deletes after transfer
--exclude=PATTERN      # Exclude files matching PATTERN
--exclude-from=FILE    # Read exclude patterns from FILE
--include=PATTERN      # Don't exclude files matching PATTERN
--backup               # Make backups
--backup-dir=DIR       # Make backups into hierarchy in DIR
--log-file=FILE        # Log to FILE
--bwlimit=RATE         # Limit socket I/O bandwidth (KB/s)
--timeout=SECONDS      # Set I/O timeout in seconds
--stats                # Give file-transfer stats
```

---

*Guide created for educational purposes. Always test in non-production environments first. Security recommendations current as of 2025.*
