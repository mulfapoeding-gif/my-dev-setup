#!/data/data/com.termux/files/usr/bin/bash
# Termux-specific setup script

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
echo "   Termux Development Setup"
echo "======================================"
echo -e "${NC}"

# Enable wake lock for long installations
termux-wake-lock

# Step 1: Update and install base packages
log_step "Updating packages and installing dependencies"
pkg update -y
pkg upgrade -y
pkg install -y python nodejs git wget curl bash make clang llvm rust ripgrep proot tar

# Step 2: Setup NVM
log_step "Setting up NVM"
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts
nvm use --lts

# Step 3: Setup Go
log_step "Setting up Go"
pkg install -y golang
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"

# Step 4: Setup Ollama (if supported)
log_step "Setting up Ollama"
if command -v ollama &> /dev/null; then
    ollama pull qwen2.5-coder:1.5b 2>/dev/null || log_warn "Failed to pull Ollama model"
else
    log_warn "Ollama not available for Termux, skipping"
fi

# Step 5: Install AI coding tools
log_step "Installing AI coding tools"

# Fix node-gyp for Android
export CPLUSFLAGS="-Wl,--unresolved-symbols=ignore-in-object-files"
mkdir -p ~/.gyp
echo "{ 'variables': { 'android_ndk_path': '' } }" > ~/.gyp/include.gypi

# Install Qwen Code
log_info "Installing Qwen Code..."
npm install -g @qwen-code/qwen-code

# Install Gemini CLI
log_info "Installing Gemini CLI..."
npm install -g @google/gemini-cli

# Step 6: Apply patches for Termux compatibility
log_step "Applying Termux patches"
if [ -f "scripts/termux_cli_manager.py" ]; then
    python3 scripts/termux_cli_manager.py --fix-gemini --fix-qwen --auto || log_warn "Auto-patching failed"
fi

# Step 7: Copy configuration files
log_step "Copying configuration files"
cp -n configs/.bashrc "$HOME/.bashrc" 2>/dev/null || true
cp -n configs/.gitconfig "$HOME/.gitconfig" 2>/dev/null || true
cp -n configs/.profile "$HOME/.profile" 2>/dev/null || true

mkdir -p "$HOME/.qwen"
cp -n configs/.qwen/settings.json "$HOME/.qwen/settings.json" 2>/dev/null || true

cp -n configs/.aider.conf.yml "$HOME/.aider.conf.yml" 2>/dev/null || true
cp -n scripts/termux_cli_manager.py "$HOME/termux_cli_manager.py" 2>/dev/null || true

# Step 8: Setup environment
log_step "Setting up environment"
if [ -f ".env.template" ]; then
    cp .env.template .env
    log_info "Created .env from template"
    log_warn "Please edit .env and add your API keys"
fi

# Disable wake lock
termux-wake-unlock

echo ""
log_success "Termux setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit .env file and add your API keys"
echo "2. Run: source ~/.bashrc"
echo "3. Try: qwen or gemini"
echo ""
echo "For APK modding tools, run: ./setup-apktools.sh"
echo ""
