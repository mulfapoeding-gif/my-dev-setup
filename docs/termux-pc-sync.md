# Termux-PC Sync Documentation

Complete guide for syncing Termux (Android) with your Windows 10 PC.

## Overview

This setup allows you to:
1. **Run AI models on your PC** (more powerful, better battery life on phone)
2. **Sync configurations** between devices
3. **Access PC resources** from Termux
4. **Seamless development** across devices

## Architecture

```
┌─────────────────┐         ┌─────────────────┐
│   Android       │         │   Windows 10 PC │
│   Termux        │◄───────►│   Ollama Server │
│                 │  SSH/   │                 │
│ - Qwen Code     │  HTTP   │ - AI Models     │
│ - Gemini CLI    │         │ - File Server   │
│ - Dev Tools     │         │ - SSH Server    │
└─────────────────┘         └─────────────────┘
```

## Quick Start

### Step 1: Setup Windows PC

**Option A: Using PowerShell Script**
```powershell
# Run PowerShell as Administrator
cd my-dev-setup\windows
.\windows-pc-server.ps1 -Install
```

**Option B: Using Batch File**
```cmd
# Run as Administrator
cd my-dev-setup\windows
setup.bat
```

**Option C: Manual Setup**

1. Install Ollama from https://ollama.com/
2. Set environment variable:
   ```powershell
   setx OLLAMA_HOST "0.0.0.0:11434"
   ```
3. Configure firewall:
   ```powershell
   netsh advfirewall firewall add rule name="Ollama API" dir=in action=allow protocol=TCP localport=11434
   ```
4. Pull models:
   ```powershell
   ollama pull qwen2.5-coder:1.5b
   ollama pull qwen2.5-coder:7b
   ```

### Step 2: Enable SSH on Windows

Run in PowerShell (as Administrator):
```powershell
# Install OpenSSH Server
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Start SSH service
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# Configure firewall
New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -DisplayName "OpenSSH Server (TCP)" `
    -Enabled True -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow
```

### Step 3: Setup Termux

```bash
# Install sync script
cd ~/my-dev-setup
chmod +x sync/termux-pc-sync.sh

# Run setup wizard
./sync/termux-pc-sync.sh --setup
```

### Step 4: Configure Qwen to Use PC

```bash
# Configure Ollama endpoint
./sync/termux-pc-sync.sh --configure-ollama

# Create SSH tunnel (optional, for persistent connection)
./sync/termux-pc-sync.sh --tunnel
```

## Usage

### Sync Files

```bash
# Pull files from PC
./sync/termux-pc-sync.sh --pull

# Push files to PC
./sync/termux-pc-sync.sh --push
```

### Use PC Ollama from Termux

**Option 1: Direct Connection**
```bash
# Set Ollama host to PC
export OLLAMA_HOST="192.168.1.100:11434"

# Use as normal
ollama list
ollama run qwen2.5-coder:1.5b
```

**Option 2: SSH Tunnel (Recommended)**
```bash
# Create tunnel
./sync/termux-pc-sync.sh --tunnel

# Use localhost (tunneled to PC)
export OLLAMA_HOST="localhost:11434"
ollama run qwen2.5-coder:1.5b
```

**Option 3: Qwen Code Configuration**

Your `~/.qwen/settings.json` will include:
```json
{
  "modelProviders": {
    "openai": [
      {
        "id": "pc-ollama",
        "name": "PC Ollama (Windows)",
        "baseUrl": "http://192.168.1.100:11434/v1"
      }
    ]
  }
}
```

### Interactive Menu

```bash
./sync/termux-pc-sync.sh
```

Menu options:
1. Setup Wizard - Initial configuration
2. Test Connection - Verify PC connectivity
3. Sync Files (Pull) - Download from PC
4. Sync Files (Push) - Upload to PC
5. Configure PC Ollama - Setup AI endpoint
6. Create SSH Tunnel - Persistent connection
7. Sync Ollama Models - Download models from PC
8. Show Configuration - View current settings

## Files Synced

The following files are automatically synced:
- `.bashrc` - Shell configuration
- `.profile` - Login profile
- `.gitconfig` - Git settings
- `.qwen/settings.json` - Qwen Code config
- `.aider.conf.yml` - Aider settings
- `.goterm.json` - Go-Term config
- `termux_cli_manager.py` - CLI manager script

## Advanced Configuration

### Custom Sync Directory

Edit `~/.termux-pc-sync/config.json`:
```json
{
  "pc_host": "192.168.1.100",
  "pc_port": "8080",
  "ollama_port": "11434",
  "ssh_port": "22",
  "sync_method": "ssh"
}
```

### Auto-start Tunnel

Add to `~/.bashrc`:
```bash
# Auto-start SSH tunnel to PC
if [ -f ~/.termux-pc-sync/config.json ]; then
    PC_HOST=$(jq -r '.pc_host' ~/.termux-pc-sync/config.json)
    ssh -N -f -L 11434:$PC_HOST:11434 -o ServerAliveInterval=60 $PC_HOST 2>/dev/null
fi
```

### Sync Additional Files

Edit `sync/termux-pc-sync.sh` and add to the `files` array:
```bash
local files=(
    ".bashrc"
    ".profile"
    # Add your files here
    ".my_custom_config"
)
```

## Troubleshooting

### Cannot Connect to PC

1. **Check IP address**: Ensure PC and Termux are on same network
2. **Check firewall**: Windows Firewall may block connections
3. **Test ping**: `ping 192.168.1.100` from Termux

### SSH Connection Failed

1. **Verify SSH service**: On Windows, run `Get-Service sshd`
2. **Check authorized_keys**: Ensure public key is copied correctly
3. **Test manually**: `ssh -v user@PC_IP`

### Ollama Connection Timeout

1. **Check OLLAMA_HOST**: `echo $OLLAMA_HOST`
2. **Restart Ollama**: On PC, restart Ollama service
3. **Check firewall**: Ensure port 11434 is allowed

### Sync Not Working

1. **Check config**: `cat ~/.termux-pc-sync/config.json`
2. **Re-run setup**: `./sync/termux-pc-sync.sh --setup`
3. **Check permissions**: `chmod +x sync/termux-pc-sync.sh`

## Security Notes

1. **Use SSH keys** instead of passwords
2. **Keep devices on same network** or use VPN
3. **Don't expose Ollama to internet** without authentication
4. **Regular backups** of important files

## Performance Tips

1. **Use SSH tunnel** for stable connection
2. **Pull models once** to Termux for offline use
3. **Sync only necessary files** to reduce transfer time
4. **Use 5GHz WiFi** for faster transfers

## Commands Reference

### Windows PC (PowerShell)
```powershell
# Start Ollama
ollama serve

# List models
ollama list

# Check service
Get-Service sshd

# View logs
Get-EventLog -LogName System -Source sshd | Select-Object -First 20
```

### Termux (Bash)
```bash
# Sync setup
./sync/termux-pc-sync.sh --setup

# Pull files
./sync/termux-pc-sync.sh --pull

# Create tunnel
./sync/termux-pc-sync.sh --tunnel

# Configure Ollama
./sync/termux-pc-sync.sh --configure-ollama

# Test connection
./sync/termux-pc-sync.sh --test
```

## Support

For issues:
1. Check logs: `cat ~/.termux-pc-sync/sync.log`
2. Test connection: `./sync/termux-pc-sync.sh --test`
3. Verify config: `cat ~/.termux-pc-sync/config.json`
