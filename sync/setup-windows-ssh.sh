#!/bin/bash
# Install OpenSSH Server on Windows (via PowerShell)
# Run this script from Termux after connecting to Windows

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo -e "${CYAN}"
echo "========================================"
echo "  Windows OpenSSH Server Setup Guide"
echo "========================================"
echo -e "${NC}"

echo "To enable SSH on Windows 10/11, run these commands in PowerShell (as Admin):"
echo ""
echo -e "${YELLOW}# Install OpenSSH Server${NC}"
echo 'Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0'
echo ""
echo -e "${YELLOW}# Start SSH service${NC}"
echo 'Start-Service sshd'
echo 'Set-Service -Name sshd -StartupType Automatic'
echo ""
echo -e "${YELLOW}# Configure firewall${NC}"
echo 'if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue)) {'
echo '    New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -DisplayName "OpenSSH Server (TCP)"'
echo '    -Enabled True -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow'
echo '}'
echo ""
echo -e "${YELLOW}# Verify SSH is running${NC}"
echo 'Get-Service sshd'
echo ""
echo "========================================"
echo ""
echo "After enabling SSH, copy your Termux public key to Windows:"
echo ""
echo -e "${CYAN}# From Termux, run:${NC}"
echo "ssh-keygen -t ed25519  # If you don't have a key"
echo "ssh-copy-id user@WINDOWS_IP"
echo ""
echo "Or manually:"
echo "1. Copy content of ~/.ssh/id_ed25519.pub"
echo "2. On Windows, create/edit: C:\\Users\\YourName\\.ssh\\authorized_keys"
echo "3. Paste the public key"
echo ""
echo "Then test connection:"
echo "ssh user@WINDOWS_IP"
echo ""
