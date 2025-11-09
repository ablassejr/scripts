# SSH Fundamentals: A Comprehensive Educational Guide

## Table of Contents
1. [Introduction to SSH](#introduction-to-ssh)
2. [How SSH Works](#how-ssh-works)
3. [SSH Key Types and Cryptography](#ssh-key-types-and-cryptography)
4. [Authentication Methods](#authentication-methods)
5. [SSH Architecture and Components](#ssh-architecture-and-components)
6. [Configuration Files](#configuration-files)
7. [Host Key Verification](#host-key-verification)
8. [Common Use Cases](#common-use-cases)
9. [Security Best Practices](#security-best-practices)
10. [Advanced Features](#advanced-features)

---

## Introduction to SSH

**SSH (Secure Shell)** is a cryptographic network protocol that provides secure encrypted communications between two untrusted hosts over an insecure network. It was designed as a secure replacement for legacy protocols like Telnet, rlogin, and rsh, which transmitted data (including passwords) in plain text.

### Why SSH Matters

- **Encryption**: All data transmitted over SSH is encrypted, protecting sensitive information from eavesdropping
- **Authentication**: Multiple robust authentication mechanisms verify both client and server identities
- **Integrity**: Cryptographic hashing ensures data hasn't been tampered with during transmission
- **Versatility**: Beyond remote shell access, SSH enables secure file transfers, port forwarding, and tunneling

### Primary Uses

1. **Remote System Administration**: Securely manage servers and devices
2. **Secure File Transfer**: SFTP and SCP protocols built on SSH
3. **Port Forwarding**: Tunnel network traffic securely through SSH
4. **Git and Version Control**: Secure repository access
5. **Automated Backup**: Tools like rsync leverage SSH for encrypted transfers

---

## How SSH Works

SSH operates using a **client-server architecture** where an SSH client initiates a connection to an SSH server (daemon). The connection establishment follows a multi-phase process:

### Connection Establishment Process

#### Phase 1: TCP Connection
The client establishes a TCP connection to the server (default port 22).

#### Phase 2: Protocol Version Exchange
```
Client → Server: SSH-2.0-OpenSSH_9.0
Server → Client: SSH-2.0-OpenSSH_9.0
```
Both parties agree on the SSH protocol version (SSH-2 is standard).

#### Phase 3: Algorithm Negotiation
The client and server negotiate which cryptographic algorithms to use:
- **Key exchange algorithms**: How to establish the session key
- **Host key algorithms**: Server authentication method
- **Encryption algorithms**: Symmetric encryption for the session
- **MAC algorithms**: Message authentication codes for integrity
- **Compression algorithms**: Optional data compression

#### Phase 4: Key Exchange (Diffie-Hellman)
The client and server perform a key exchange to establish a shared secret session key without transmitting it over the network. This provides **perfect forward secrecy** - even if the host key is compromised later, past sessions remain secure.

#### Phase 5: Server Authentication
The server proves its identity using its host key. The client verifies this key against its `known_hosts` file.

#### Phase 6: User Authentication
The user authenticates to the server using one of several methods (password, public key, etc.).

#### Phase 7: Encrypted Session
Once authenticated, all communication is encrypted using the negotiated session key and algorithms.

### Encryption Layers

SSH employs **hybrid cryptography**:

1. **Asymmetric Cryptography** (Public/Private Keys)
   - Used for server authentication (host keys)
   - Used for user authentication (client keys)
   - Used in key exchange algorithms

2. **Symmetric Cryptography** (Session Keys)
   - Used for encrypting the actual session data
   - Much faster than asymmetric encryption
   - New session key generated for each connection

3. **Cryptographic Hashing** (MAC - Message Authentication Code)
   - Ensures data integrity
   - Prevents tampering and replay attacks
   - Common algorithms: HMAC-SHA2-256, HMAC-SHA2-512

---

## SSH Key Types and Cryptography

SSH supports several public key algorithms, each with different security characteristics and performance profiles.

### Modern Key Types (Recommended)

#### Ed25519 (Edwards-curve Digital Signature Algorithm)
```bash
ssh-keygen -t ed25519 -C "user@example.com"
```

**Characteristics:**
- **Key Size**: 256 bits (fixed)
- **Security**: Extremely strong, equivalent to ~3000-bit RSA
- **Performance**: Very fast signature generation and verification
- **File Size**: Smallest key files (~68 bytes public key)
- **Recommendation**: ⭐ **Best choice for new keys**

**Advantages:**
- Resistant to timing attacks
- No parameter choices to get wrong
- Excellent security-to-performance ratio
- Modern cryptography based on elliptic curves

#### ECDSA (Elliptic Curve Digital Signature Algorithm)
```bash
ssh-keygen -t ecdsa -b 521
```

**Characteristics:**
- **Key Sizes**: 256, 384, or 521 bits
- **Security**: Strong when implemented correctly
- **Performance**: Fast, though slightly slower than Ed25519
- **Compatibility**: Widely supported

**Caution:**
- Requires high-quality random number generation
- Implementation flaws can compromise security
- Some concerns about NIST curve parameter choices

### Legacy Key Types

#### RSA (Rivest-Shamir-Adleman)
```bash
ssh-keygen -t rsa -b 4096
```

**Characteristics:**
- **Key Sizes**: 2048, 3072, or 4096 bits (minimum 2048 recommended)
- **Security**: Well-studied, still secure at sufficient key lengths
- **Performance**: Slower than elliptic curve algorithms
- **File Size**: Large key files
- **Compatibility**: Universal support

**Use When:**
- Legacy system compatibility is required
- Ed25519 is not supported

#### DSA (Digital Signature Algorithm)
**Status**: ⚠️ **DEPRECATED** - Do not use

**Why Deprecated:**
- Limited to 1024-bit keys (no longer considered secure)
- Removed from OpenSSH 7.0+ by default
- Vulnerable if random number generation is weak

### Key Strength Comparison

| Algorithm | Key Size | Approximate Security Level | Speed | Recommendation |
|-----------|----------|---------------------------|-------|----------------|
| Ed25519   | 256-bit  | ~128-bit security         | ⚡⚡⚡ | ✅ Highly Recommended |
| ECDSA-521 | 521-bit  | ~260-bit security         | ⚡⚡  | ✅ Good |
| RSA-4096  | 4096-bit | ~128-bit security         | ⚡    | ✅ Good (compatibility) |
| RSA-2048  | 2048-bit | ~112-bit security         | ⚡    | ⚠️ Minimum acceptable |
| DSA       | 1024-bit | Broken                    | ⚡    | ❌ Never use |

---

## Authentication Methods

SSH supports multiple authentication mechanisms, which can be used individually or in combination.

### 1. Public Key Authentication (Most Secure)

**How It Works:**
1. User generates a key pair (private key + public key)
2. Public key is placed in `~/.ssh/authorized_keys` on the server
3. Private key remains on the client (should be passphrase-protected)
4. During authentication:
   - Server sends a challenge encrypted with the public key
   - Client decrypts with private key and proves possession
   - No password transmitted over the network

**Security Benefits:**
- Passwords never transmitted
- Private key never leaves the client
- Can be passphrase-protected for two-factor security
- Enables passwordless automation when needed

**Example Setup:**
```bash
# Generate key pair
ssh-keygen -t ed25519 -C "admin@workstation"

# Copy public key to server
ssh-copy-id user@server.example.com

# Or manually
cat ~/.ssh/id_ed25519.pub | ssh user@server 'cat >> ~/.ssh/authorized_keys'
```

### 2. Password Authentication (Simple but Less Secure)

**How It Works:**
1. User provides username and password
2. Server verifies against system user database
3. Password is transmitted encrypted over SSH connection

**Considerations:**
- Susceptible to brute-force attacks
- Password must be transmitted (though encrypted)
- No way to authenticate without user interaction
- Often disabled on production servers

**Server Configuration:**
```bash
# In /etc/ssh/sshd_config
PasswordAuthentication yes  # Enable
PasswordAuthentication no   # Disable (recommended for production)
```

### 3. Host-Based Authentication

**How It Works:**
- Trusts connections from specific hosts
- Server verifies client's host key
- No user password or key required
- User must be in `.shosts` or `/etc/hosts.equiv`

**Example ~/.shosts file:**
```bash
# Allow connections from specific host
server.example.com

# Allow specific user from specific host
backup.example.com backup_user

# Allow entire domain
*.internal.example.com
```

**Server Configuration:**
```bash
# In /etc/ssh/sshd_config
HostbasedAuthentication yes
IgnoreRhosts no
```

**Use Cases:**
- Internal network automation
- Cluster computing environments
- Legacy system integration

**Security Note:** Less secure than public key authentication; use only in controlled environments.

### 4. Keyboard-Interactive Authentication

**How It Works:**
- Server sends prompts to the client
- User responds to each prompt
- Supports multi-factor authentication
- Can integrate with PAM, OTP, etc.

**Use Cases:**
- Two-factor authentication
- Custom authentication challenges
- Integration with external auth systems

### 5. GSSAPI Authentication (Kerberos)

**How It Works:**
- Uses Kerberos tickets for authentication
- Single sign-on in enterprise environments
- No password transmission needed after initial Kerberos login

**Use Cases:**
- Enterprise environments with Active Directory
- Large-scale centralized authentication

### Authentication Cascading

SSH attempts authentication methods in order until one succeeds:

```bash
# Client tries methods in this order (configurable):
1. Public key authentication
2. Keyboard-interactive
3. Password authentication
```

**Server can require multiple methods:**
```bash
# In /etc/ssh/sshd_config
AuthenticationMethods publickey,password
```
This requires BOTH public key AND password (two-factor).

---

## SSH Architecture and Components

### Client Components

#### 1. SSH Client (`ssh`)
The primary command-line tool for connecting to remote servers.

```bash
# Basic connection
ssh user@hostname

# Specify port
ssh -p 2222 user@hostname

# Execute command without interactive shell
ssh user@hostname 'ls -la /var/log'

# Enable compression
ssh -C user@hostname

# Verbose output (debugging)
ssh -v user@hostname
ssh -vv user@hostname  # More verbose
ssh -vvv user@hostname # Maximum verbosity
```

#### 2. SSH Key Generator (`ssh-keygen`)
Creates, manages, and converts SSH keys.

```bash
# Generate new key
ssh-keygen -t ed25519 -C "comment"

# Show fingerprint of key
ssh-keygen -l -f ~/.ssh/id_ed25519.pub

# Change passphrase
ssh-keygen -p -f ~/.ssh/id_ed25519

# Remove host from known_hosts
ssh-keygen -R hostname

# Hash known_hosts file for privacy
ssh-keygen -H
```

#### 3. SSH Copy ID (`ssh-copy-id`)
Installs public keys on remote servers.

```bash
# Copy default key
ssh-copy-id user@server

# Copy specific key
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@server
```

#### 4. SSH Agent (`ssh-agent`)
Manages private keys in memory, providing secure key storage without repeated passphrase entry.

```bash
# Start agent
eval $(ssh-agent)

# Add key to agent
ssh-add ~/.ssh/id_ed25519

# List loaded keys
ssh-add -l

# Remove all keys
ssh-add -D
```

#### 5. Secure Copy (`scp`)
Copies files over SSH.

```bash
# Copy to remote
scp file.txt user@server:/path/to/destination/

# Copy from remote
scp user@server:/path/to/file.txt ./

# Copy directory recursively
scp -r directory/ user@server:/path/
```

#### 6. SSH File Transfer Protocol (`sftp`)
Interactive file transfer client.

```bash
# Connect
sftp user@server

# Commands within SFTP session
put file.txt          # Upload
get remote_file.txt   # Download
ls                    # List remote directory
lls                   # List local directory
cd /path              # Change remote directory
lcd /path             # Change local directory
```

### Server Components

#### 1. SSH Daemon (`sshd`)
The server process that listens for incoming SSH connections.

```bash
# Start in foreground (debugging)
sshd -D

# Start in debug mode
sshd -d

# Test configuration
sshd -t

# Show effective configuration
sshd -T

# Test with specific connection parameters
sshd -T -C user=admin,host=192.168.1.100,addr=192.168.1.100
```

#### 2. Host Keys
Server identity keys stored in `/etc/ssh/`:

```bash
# Generate all host key types
ssh-keygen -A

# Generate specific type
ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""

# Set proper permissions
chmod 600 /etc/ssh/ssh_host_*_key
chmod 644 /etc/ssh/ssh_host_*_key.pub
```

---

## Configuration Files

SSH behavior is controlled through configuration files on both client and server sides.

### Client Configuration

#### User-Specific: `~/.ssh/config`

```ssh-config
# Default settings for all hosts
Host *
    # Maintain connection
    ServerAliveInterval 60
    ServerAliveCountMax 3

    # Security settings
    HashKnownHosts yes

    # Key preferences
    IdentityFile ~/.ssh/id_ed25519
    IdentityFile ~/.ssh/id_rsa

# Specific host configuration
Host myserver
    HostName 192.168.1.100
    User admin
    Port 2222
    IdentityFile ~/.ssh/myserver_key

# Production servers
Host prod-*
    User deployer
    ForwardAgent no
    StrictHostKeyChecking yes

# Development environment
Host dev.example.com
    User developer
    ForwardAgent yes
    LocalForward 8080 localhost:80
    LocalForward 5432 localhost:5432

# Jump host (bastion)
Host internal-server
    HostName 10.0.1.50
    ProxyJump bastion.example.com

# Short alias
Host db
    HostName database.internal.example.com
    User postgres
    IdentityFile ~/.ssh/db_key
```

#### System-Wide: `/etc/ssh/ssh_config`
Global defaults for all users (overridden by user config).

### Server Configuration: `/etc/ssh/sshd_config`

```ssh-config
# Network settings
Port 22
#Port 2222  # Non-standard port for security through obscurity
AddressFamily any
ListenAddress 0.0.0.0
ListenAddress ::

# Host keys
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key

# Security: Authentication
PermitRootLogin no                    # Disable root login
PasswordAuthentication no             # Disable password auth
PubkeyAuthentication yes              # Enable key-based auth
AuthorizedKeysFile .ssh/authorized_keys
PermitEmptyPasswords no               # Never allow empty passwords

# Security: Features
X11Forwarding no                      # Disable unless needed
AllowTcpForwarding no                 # Disable unless needed
AllowAgentForwarding no               # Disable unless needed
PermitTunnel no                       # Disable VPN tunneling unless needed

# Performance
UseDNS no                             # Faster connections
Compression delayed                    # Compress after authentication

# Login settings
LoginGraceTime 1m                     # Time limit for authentication
MaxAuthTries 3                        # Max authentication attempts
MaxSessions 10                        # Max concurrent sessions per connection

# Access control
AllowUsers admin deployer             # Only these users can login
#AllowGroups ssh-users                # Or limit by group
#DenyUsers baduser                    # Explicitly deny users

# Logging
SyslogFacility AUTH
LogLevel VERBOSE                      # Log authentication attempts

# Banner and messages
Banner /etc/ssh/banner.txt            # Pre-authentication banner
PrintMotd yes                         # Show message of the day

# Subsystems
Subsystem sftp /usr/lib/ssh/sftp-server

# Match blocks for conditional configuration
Match User backup
    ForceCommand /usr/local/bin/backup-script
    AllowTcpForwarding no

Match Address 192.168.1.0/24
    PasswordAuthentication yes

Match Group admins
    AllowTcpForwarding yes
    PermitTunnel yes
```

### Important Permission Requirements

```bash
# User SSH directory and files
~/.ssh/                         # 700 (drwx------)
~/.ssh/config                   # 600 (-rw-------)
~/.ssh/id_*                     # 600 (-rw-------)  # Private keys
~/.ssh/id_*.pub                 # 644 (-rw-r--r--)  # Public keys
~/.ssh/authorized_keys          # 600 (-rw-------)
~/.ssh/known_hosts              # 644 (-rw-r--r--)

# Server configuration
/etc/ssh/sshd_config            # 644 (-rw-r--r--)
/etc/ssh/ssh_host_*_key         # 600 (-rw-------)  # Private host keys
/etc/ssh/ssh_host_*_key.pub     # 644 (-rw-r--r--)  # Public host keys

# Privilege separation
/var/empty/                     # 755 (drwxr-xr-x)  # Must be owned by root
```

---

## Host Key Verification

Host key verification is SSH's mechanism for preventing **man-in-the-middle attacks** by ensuring you're connecting to the correct server.

### How It Works

1. **First Connection**: Server presents its host key fingerprint
2. **User Verification**: User confirms the fingerprint is correct
3. **Storage**: Client stores the host key in `~/.ssh/known_hosts`
4. **Subsequent Connections**: Client verifies server presents the same key

### The Known Hosts File

#### Format: `~/.ssh/known_hosts`

```text
# Standard entry (hostname, IP, key type, key)
server.example.com,192.168.1.10 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI...

# Multiple hostnames for same key
web01.example.com,web01,192.168.1.20 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5...

# Hashed hostname (privacy protection)
|1|JfKTdBh7rNbXkVAQCRp4OQoPfmI=|USECr3SWf1JUPsms5AqfD5QfxkM= ssh-rsa AAAAB3NzaC...

# Non-standard port
[server.example.com]:2222 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI...

# Wildcard pattern
*.example.com,192.168.1.* ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAA...

# Revoked key (security incident)
@revoked compromised.example.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAA...

# Certificate authority for domain
@cert-authority *.internal.example.com ssh-rsa AAAAB5W...
```

### Fingerprint Verification

Before first connection, verify the server's fingerprint through a trusted channel:

```bash
# On the server, get fingerprints
ssh-keygen -l -f /etc/ssh/ssh_host_ed25519_key.pub
# Output: 256 SHA256:7HqxPZ8pZ... root@server (ED25519)

# Client sees on first connection:
# The authenticity of host 'server.example.com (192.168.1.10)' can't be established.
# ED25519 key fingerprint is SHA256:7HqxPZ8pZ...
# Are you sure you want to continue connecting (yes/no)?
```

### Managing Known Hosts

```bash
# Remove a host entry
ssh-keygen -R server.example.com

# Remove specific port
ssh-keygen -R '[server.example.com]:2222'

# Hash the known_hosts file (privacy)
ssh-keygen -H

# Generate hashed entry
ssh-keyscan -H server.example.com >> ~/.ssh/known_hosts

# Scan and add multiple hosts
ssh-keyscan server1.com server2.com server3.com >> ~/.ssh/known_hosts
```

### Security Levels

```bash
# Strict checking (production - recommended)
StrictHostKeyChecking yes

# Accept new hosts, reject changed keys (default)
StrictHostKeyChecking ask

# Accept all keys (DANGEROUS - testing only)
StrictHostKeyChecking no
UserKnownHostsFile=/dev/null
```

---

## Common Use Cases

### 1. Remote Command Execution

```bash
# Single command
ssh user@server 'uptime'

# Multiple commands
ssh user@server 'cd /var/log && tail -n 20 syslog'

# Pipe local input to remote command
cat local_file.txt | ssh user@server 'cat > remote_file.txt'

# Pipe remote output to local command
ssh user@server 'cat /var/log/app.log' | grep ERROR

# Background process on remote server
ssh user@server 'nohup ./long_running_script.sh &'
```

### 2. File Transfer

```bash
# SCP - Copy files
scp local_file.txt user@server:/path/to/destination/
scp user@server:/path/to/file.txt ./local_directory/
scp -r directory/ user@server:/remote/path/

# SFTP - Interactive session
sftp user@server
> put local_file.txt
> get remote_file.txt
> quit

# rsync over SSH (most efficient)
rsync -avz -e ssh /local/path/ user@server:/remote/path/
```

### 3. Port Forwarding (Tunneling)

#### Local Port Forwarding
Access remote service through local port:

```bash
# Forward local port 8080 to remote service
ssh -L 8080:localhost:80 user@server

# Access remote database through tunnel
ssh -L 5432:database.internal:5432 user@bastion
# Now connect to localhost:5432 to reach database.internal:5432
```

#### Remote Port Forwarding
Expose local service to remote server:

```bash
# Let remote server access your local service
ssh -R 8080:localhost:3000 user@server
# Remote server can now access localhost:8080 to reach your local port 3000
```

#### Dynamic Port Forwarding (SOCKS Proxy)
Create a SOCKS proxy for browsing:

```bash
# Create SOCKS proxy on local port 9090
ssh -D 9090 user@server

# Configure browser to use SOCKS5 proxy: localhost:9090
# All browser traffic now goes through the SSH tunnel
```

### 4. Jump Hosts (Bastion/Proxy)

```bash
# Old method: ProxyCommand
ssh -o ProxyCommand="ssh -W %h:%p user@bastion" user@internal-server

# Modern method: ProxyJump (OpenSSH 7.3+)
ssh -J user@bastion user@internal-server

# Multiple jumps
ssh -J user@bastion1,user@bastion2 user@final-destination

# In ~/.ssh/config
Host internal-server
    HostName 10.0.1.50
    User admin
    ProxyJump bastion.example.com
```

### 5. X11 Forwarding (GUI Applications)

```bash
# Enable X11 forwarding
ssh -X user@server

# Trusted X11 forwarding (less secure, more compatible)
ssh -Y user@server

# Run GUI application
xclock  # Application appears on your local display
```

### 6. Session Multiplexing (Connection Sharing)

```bash
# In ~/.ssh/config
Host *
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h:%p
    ControlPersist 10m

# First connection creates master
ssh user@server

# Subsequent connections reuse the master (much faster)
ssh user@server  # Instant connection
scp file.txt user@server:/tmp/  # Uses existing connection
```

---

## Security Best Practices

### 1. Key Management

✅ **DO:**
- Use Ed25519 keys for new deployments
- Protect private keys with strong passphrases
- Use different keys for different purposes/servers
- Rotate keys periodically (annual review)
- Use SSH agent to avoid storing unencrypted keys
- Remove old/unused keys from authorized_keys

❌ **DON'T:**
- Share private keys between users or systems
- Store private keys unencrypted on shared systems
- Use the same key everywhere
- Commit private keys to version control

### 2. Server Hardening

```bash
# /etc/ssh/sshd_config - Secure Configuration

# Disable dangerous features
PermitRootLogin no
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no

# Limit access
AllowUsers admin deployer
AllowGroups ssh-users
DenyUsers guest

# Rate limiting (use fail2ban or similar)
MaxAuthTries 3
LoginGraceTime 30s

# Disable unused features
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
PermitTunnel no

# Use strong cryptography only
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
HostKeyAlgorithms ssh-ed25519,rsa-sha2-512,rsa-sha2-256

# Log everything
LogLevel VERBOSE
```

### 3. Authorized Keys Restrictions

Limit what a key can do in `~/.ssh/authorized_keys`:

```bash
# Read-only access to specific directory
restrict,command="cd /backup && ls" ssh-ed25519 AAAAC3...

# Forced command - only run backup script
restrict,command="/usr/local/bin/backup.sh" ssh-rsa AAAAB3...

# Restrict source IP addresses
from="192.168.1.0/24,10.0.0.5" ssh-ed25519 AAAAC3...

# Limit port forwarding destinations
permitopen="192.0.2.1:80",permitopen="192.0.2.2:25" ssh-rsa AAAAB3...

# Time-limited key
expiry-time="20261231235959" ssh-ed25519 AAAAC3...

# No port forwarding
restrict,no-port-forwarding ssh-ed25519 AAAAC3...

# No PTY allocation (non-interactive only)
restrict,no-pty ssh-ed25519 AAAAC3...
```

### 4. Network Security

```bash
# Change default port (security through obscurity)
Port 2222

# Bind to specific interface
ListenAddress 192.168.1.10

# Use firewall rules
# iptables example:
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
```

### 5. Monitoring and Logging

```bash
# Enable verbose logging
LogLevel VERBOSE

# Monitor authentication attempts
tail -f /var/log/auth.log | grep sshd

# Install fail2ban to block brute-force attacks
apt install fail2ban

# Configure fail2ban for SSH
# /etc/fail2ban/jail.local
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
```

### 6. Regular Auditing

```bash
# Check who's currently connected
who
w
last

# Review authorized_keys files
find /home -name authorized_keys -exec ls -l {} \;

# Check for weak configurations
sshd -T | grep -i password
sshd -T | grep -i permit

# Review SSH logs
grep 'Accepted\|Failed' /var/log/auth.log | tail -50
```

---

## Advanced Features

### 1. SSH Certificates

Instead of managing individual keys, use certificate authorities:

```bash
# Create CA key
ssh-keygen -t ed25519 -f ca_key

# Sign user key with CA
ssh-keygen -s ca_key -I user_id -n username -V +52w user_key.pub

# Sign host key with CA
ssh-keygen -s ca_key -I host.example.com -h -n host.example.com -V +520w /etc/ssh/ssh_host_ed25519_key.pub

# Trust CA on server (authorized_keys)
cert-authority,principals="admin,backup" ssh-ed25519 AAAAC3... # CA public key

# Trust CA on client (known_hosts)
@cert-authority *.example.com ssh-ed25519 AAAAC3... # CA public key
```

### 2. SSHFS - Mount Remote Filesystem

```bash
# Mount remote directory
sshfs user@server:/remote/path /local/mountpoint

# With options
sshfs user@server:/remote/path /local/mountpoint -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3

# Unmount
fusermount -u /local/mountpoint
```

### 3. SSH Escape Sequences

When in an SSH session, type `~?` to see escape sequences:

```
~.  - Terminate connection
~^Z - Suspend SSH
~#  - List forwarded connections
~&  - Background SSH (on logout)
~?  - Display escape sequence help
~~  - Send literal ~
```

### 4. Environment Variables

```bash
# ~/.ssh/environment (requires PermitUserEnvironment=yes on server)
PATH=/usr/local/bin:/usr/bin:/bin
EDITOR=vim
LANG=en_US.UTF-8

# Per-key in authorized_keys
environment="ROLE=backup",environment="PATH=/usr/local/backup/bin" ssh-rsa AAAAB3...
```

### 5. Match Blocks for Conditional Configuration

Server-side conditional configuration:

```bash
# /etc/ssh/sshd_config

# Defaults for everyone
PasswordAuthentication no
X11Forwarding no

# Special rules for admin group
Match Group admin
    AllowTcpForwarding yes
    PermitTunnel yes

# Special rules for specific subnet
Match Address 192.168.1.0/24
    PasswordAuthentication yes

# Restrict specific user
Match User backup
    ForceCommand /usr/local/bin/backup-script
    PermitTTY no
    AllowTcpForwarding no
```

---

## Troubleshooting Tips

### Debug Connection Issues

```bash
# Client-side verbose output
ssh -vvv user@server

# Server-side debug mode
sudo sshd -d -p 2222  # Run on alternate port for testing

# Check server is listening
netstat -tlnp | grep :22
ss -tlnp | grep :22

# Test configuration syntax
sshd -t

# Show effective configuration
sshd -T
```

### Common Issues

1. **Permission Denied (publickey)**
   - Check key file permissions (600 for private key)
   - Verify public key is in authorized_keys
   - Check authorized_keys file permissions (600)
   - Verify ~/.ssh directory permissions (700)

2. **Connection Timeout**
   - Check firewall rules
   - Verify SSH daemon is running
   - Confirm correct hostname/IP and port

3. **Host Key Verification Failed**
   - Server key changed (reinstall/security incident?)
   - Remove old key: `ssh-keygen -R hostname`
   - Verify fingerprint through trusted channel

4. **Too Many Authentication Failures**
   - SSH tries all keys in agent
   - Limit keys: `ssh -o IdentitiesOnly=yes -i specific_key user@server`

---

## Conclusion

SSH is a fundamental tool in modern computing, providing secure remote access and encrypted communication. Understanding its architecture, authentication mechanisms, and security features enables you to:

- **Secure your systems** with strong authentication and encryption
- **Automate workflows** safely using key-based authentication
- **Tunnel traffic** securely through untrusted networks
- **Transfer files** with confidence in their integrity and confidentiality

The investment in learning SSH thoroughly pays dividends in system administration, DevOps practices, and security posture.

### Further Reading

- OpenSSH Manual Pages: `man ssh`, `man sshd`, `man ssh_config`, `man sshd_config`
- RFC 4253: The Secure Shell (SSH) Transport Layer Protocol
- NIST Guidelines on SSH: NIST IR 7966
- OpenSSH Official Documentation: https://www.openssh.com/manual.html

---

*Document created for educational purposes. Security recommendations current as of 2025.*
