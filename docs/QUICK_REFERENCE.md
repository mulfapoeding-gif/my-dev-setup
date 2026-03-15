# Quick Reference Card

## Setup Commands

### Windows PC (AI Server)
```powershell
# Run PowerShell as Administrator
cd my-dev-setup\windows
.\windows-pc-server.ps1 -Install

# Or use batch file
setup.bat
```

### Termux (Android)
```bash
cd ~/my-dev-setup
./setup-termux.sh
```

### Sync Setup
```bash
# On Termux
cd ~/my-dev-setup/sync
./termux-pc-sync.sh --setup
./termux-pc-sync.sh --configure-ollama
./termux-pc-sync.sh --tunnel
```

## Daily Use

### Use PC AI from Termux
```bash
# Start tunnel (connects to PC Ollama)
./sync/termux-pc-sync.sh --tunnel

# Now use Qwen/Gemini normally - uses PC models!
qwen
gemini
```

### Sync Files
```bash
# Pull from PC
./sync/termux-pc-sync.sh --pull

# Push to PC
./sync/termux-pc-sync.sh --push
```

### Backup Termux
```bash
./sync/backup-termux.sh
```

## AI Models

### On PC (PowerShell)
```powershell
ollama pull qwen2.5-coder:7b
ollama pull qwen2.5-coder:1.5b
ollama list
```

### On Termux (using PC)
```bash
# Via tunnel
export OLLAMA_HOST="localhost:11434"
ollama list

# Direct
export OLLAMA_HOST="192.168.1.100:11434"
ollama list
```

## SSH Setup (Windows)

```powershell
# Install OpenSSH (Admin PowerShell)
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# Firewall
New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" `
    -DisplayName "OpenSSH Server" -Enabled True `
    -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Can't connect to PC | Check IP, same network? |
| SSH refused | Windows SSH service running? |
| Ollama timeout | Firewall allows 11434? |
| Sync fails | Run `--setup` again |

## File Locations

```
~/my-dev-setup/
├── sync/           # Sync scripts
├── windows/        # Windows setup
├── configs/        # Dotfiles
└── docs/           # Documentation
```

## Ports Used

| Port | Service |
|------|---------|
| 11434 | Ollama API |
| 8080 | Sync server |
| 22 | SSH |

## Get PC IP (Windows)

```powershell
# PowerShell
Get-NetIPAddress -AddressFamily IPv4 | Where-Object IPAddress -like "192.168.*"
```

## Get PC IP (Termux)

Ask user to check Windows:
```
ipconfig | findstr IPv4
```
