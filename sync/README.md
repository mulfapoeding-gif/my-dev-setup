# Complete Termux Setup Backup & Sync

This guide covers backing up your entire Termux environment and syncing with PC.

## Quick Backup

```bash
# Run backup script
cd ~/my-dev-setup/sync
chmod +x backup-termux.sh
./backup-termux.sh
```

This creates:
- Full backup of config files
- Package list for reinstallation
- Restore script
- Compressed archive

## Complete Sync Workflow

### 1. Initial Setup on PC

```powershell
# Windows PowerShell (Admin)
cd my-dev-setup\windows
.\windows-pc-server.ps1 -Install
```

### 2. Enable SSH on Windows

```powershell
# Install OpenSSH
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Start service
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# Firewall rule
New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -DisplayName "OpenSSH Server" `
    -Enabled True -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow
```

### 3. Backup Termux

```bash
# On Termux
cd ~/my-dev-setup/sync
./backup-termux.sh
```

### 4. Sync to PC

```bash
# Copy backup to PC
scp -r ~/termux-backup user@PC_IP:~/termux-backups/

# Or use sync script
./termux-pc-sync.sh --setup
./termux-pc-sync.sh --push
```

### 5. Configure Remote Ollama

```bash
# On Termux, set PC as Ollama host
export OLLAMA_HOST="192.168.1.100:11434"

# Or create tunnel
./termux-pc-sync.sh --tunnel

# Test
ollama list
```

## Directory Structure

```
~/my-dev-setup/
├── sync/
│   ├── termux-pc-sync.sh      # Main sync script
│   ├── backup-termux.sh       # Backup script
│   └── setup-windows-ssh.sh   # Windows SSH guide
├── windows/
│   ├── windows-pc-server.ps1  # PC server setup
│   └── setup.bat              # Quick setup (CMD)
└── docs/
    └── termux-pc-sync.md      # Full documentation
```

## Automated Sync

Add to crontab (Termux):
```bash
crontab -e
```

Add line for daily sync:
```
0 2 * * * /data/data/com.termux/files/home/my-dev-setup/sync/termux-pc-sync.sh --pull
```

## Restore from Backup

### On Same Device
```bash
cd ~/termux-backup/termux-backup-YYYYMMDD_HHMMSS
./restore.sh
```

### On Different Device
```bash
# Copy backup to new device
scp user@PC_IP:~/termux-backups/termux-backup-*.tar.gz ~/

# Extract and restore
tar -xzf termux-backup-*.tar.gz
cd termux-backup-*
./restore.sh
```

## Package Reinstallation

```bash
# From backup
pkg install $(cat ~/termux-backup/packages-*.txt | awk '{print $1}' | tr '\n' ' ')
```

## Troubleshooting

### Permission Denied
```bash
# Grant storage access
termux-setup-storage
```

### SSH Connection Refused
```bash
# Check Windows SSH service
# On Windows PowerShell:
Get-Service sshd
Start-Service sshd
```

### Ollama Not Accessible
```bash
# Check firewall on Windows
# On Windows PowerShell:
Get-NetFirewallRule | Where-Object DisplayName -like "*Ollama*"
```

### Sync Script Not Found
```bash
# Make executable
chmod +x ~/my-dev-setup/sync/*.sh
```
