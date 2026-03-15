#!/bin/bash
# Main setup script for development environment
# Works on Termux (Android), Kali Linux, and other Linux distributions

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Detect OS
detect_os() {
    if [ -f "/data/data/com.termux/files/usr/bin/termux-info" ]; then
        OS="TERMUX"
        log_info "Detected Termux environment"
    elif grep -q "kali" /etc/os-release 2>/dev/null; then
        OS="KALI"
        log_info "Detected Kali Linux environment"
    elif [ -f "/etc/debian_version" ]; then
        OS="DEBIAN"
        log_info "Detected Debian-based Linux"
    elif [ -f "/etc/arch-release" ]; then
        OS="ARCH"
        log_info "Detected Arch Linux"
    elif [ -f "/etc/fedora-release" ]; then
        OS="FEDORA"
        log_info "Detected Fedora"
    else
        OS="LINUX"
        log_info "Detected generic Linux"
    fi
}

# Install dependencies based on OS
install_dependencies() {
    log_step "Installing dependencies for $OS"
    
    case $OS in
        TERMUX)
            pkg update -y
            pkg install -y python nodejs git wget curl bash make clang llvm rust ripgrep
            ;;
        KALI|DEBIAN)
            sudo apt update
            sudo apt install -y python3 python3-pip nodejs npm git wget curl build-essential ripgrep
            ;;
        ARCH)
            sudo pacman -Syu --noconfirm python python-pip nodejs npm git wget curl base-devel ripgrep
            ;;
        FEDORA)
            sudo dnf install -y python3 python3-pip nodejs npm git wget curl gcc gcc-c++ make ripgrep
            ;;
        *)
            log_warn "Unknown OS, attempting generic installation"
            command -v python3 >/dev/null || { log_error "Python3 not found"; return 1; }
            command -v node >/dev/null || { log_error "Node.js not found"; return 1; }
            command -v git >/dev/null || { log_error "Git not found"; return 1; }
            ;;
    esac
    
    log_success "Dependencies installed"
}

# Setup NVM (Node Version Manager)
setup_nvm() {
    log_step "Setting up NVM"
    
    if [ ! -d "$HOME/.nvm" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    fi
    
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Install latest LTS
    nvm install --lts
    nvm use --lts
    
    log_success "NVM setup complete"
}

# Setup Go
setup_go() {
    log_step "Setting up Go"
    
    if [ ! -d "$HOME/go" ]; then
        mkdir -p "$HOME/go"
    fi
    
    # Check if Go is installed
    if ! command -v go &> /dev/null; then
        log_info "Go not found, installing..."
        case $OS in
            TERMUX)
                pkg install -y golang
                ;;
            KALI|DEBIAN)
                sudo apt install -y golang-go
                ;;
            *)
                log_warn "Please install Go manually from https://golang.org/dl/"
                ;;
        esac
    fi
    
    export GOPATH="$HOME/go"
    export PATH="$PATH:$GOPATH/bin"
    
    log_success "Go setup complete"
}

# Setup Ollama
setup_ollama() {
    log_step "Setting up Ollama"
    
    if ! command -v ollama &> /dev/null; then
        log_info "Installing Ollama..."
        curl -fsSL https://ollama.com/install.sh | sh
    fi
    
    # Pull the default model
    ollama pull qwen2.5-coder:1.5b 2>/dev/null || log_warn "Failed to pull Ollama model"
    
    log_success "Ollama setup complete"
}

# Setup AI coding tools
setup_ai_tools() {
    log_step "Setting up AI coding tools"
    
    # Install Qwen Code
    log_info "Installing Qwen Code..."
    npm install -g @qwen-code/qwen-code
    
    # Install Gemini CLI
    log_info "Installing Gemini CLI..."
    npm install -g @google/gemini-cli
    
    # Install Aider
    log_info "Installing Aider..."
    pip3 install aider-chat 2>/dev/null || pip install aider-chat
    
    log_success "AI coding tools installed"
}

# Copy configuration files
copy_configs() {
    log_step "Copying configuration files"
    
    # Backup existing configs
    for config in .bashrc .gitconfig .profile; do
        if [ -f "$HOME/$config" ] && [ ! -f "$HOME/$config.backup" ]; then
            cp "$HOME/$config" "$HOME/$config.backup"
            log_info "Backed up $HOME/$config"
        fi
    done
    
    # Copy new configs (ask for confirmation)
    read -p "Copy configuration files to home directory? (y/n): " confirm
    if [ "$confirm" = "y" ]; then
        cp -n configs/.bashrc "$HOME/.bashrc" 2>/dev/null || true
        cp -n configs/.gitconfig "$HOME/.gitconfig" 2>/dev/null || true
        cp -n configs/.profile "$HOME/.profile" 2>/dev/null || true
        
        # Create .qwen directory
        mkdir -p "$HOME/.qwen"
        cp -n configs/.qwen/settings.json "$HOME/.qwen/settings.json" 2>/dev/null || true
        
        # Create .aider directory
        mkdir -p "$HOME/.aider"
        cp -n configs/.aider.conf.yml "$HOME/.aider.conf.yml" 2>/dev/null || true
        
        # Copy termux_cli_manager.py
        cp -n scripts/termux_cli_manager.py "$HOME/termux_cli_manager.py" 2>/dev/null || true
        
        log_success "Configuration files copied"
    else
        log_info "Skipping configuration copy"
    fi
}

# Setup environment variables
setup_env() {
    log_step "Setting up environment variables"
    
    if [ -f ".env.template" ]; then
        if [ ! -f ".env" ]; then
            cp .env.template .env
            log_info "Created .env from template"
            log_warn "Please edit .env and add your API keys"
        fi
    fi
    
    log_success "Environment setup complete"
}

# Apply patches for Termux
apply_termux_patches() {
    if [ "$OS" = "TERMUX" ]; then
        log_step "Applying Termux patches"
        
        # Run termux_cli_manager.py to patch Gemini and Qwen
        if [ -f "scripts/termux_cli_manager.py" ]; then
            python3 scripts/termux_cli_manager.py --fix-gemini --fix-qwen || log_warn "Patching failed"
        fi
        
        log_success "Termux patches applied"
    fi
}

# Main setup function
main() {
    echo -e "${CYAN}"
    echo "======================================"
    echo "   Development Environment Setup"
    echo "======================================"
    echo -e "${NC}"
    
    # Get script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    cd "$SCRIPT_DIR"
    
    detect_os
    
    echo ""
    log_info "Starting setup for $OS"
    echo ""
    
    install_dependencies
    setup_nvm
    setup_go
    setup_ollama
    setup_ai_tools
    copy_configs
    setup_env
    apply_termux_patches
    
    echo ""
    log_success "Setup complete!"
    echo ""
    echo "Next steps:"
    echo "1. Edit .env file and add your API keys"
    echo "2. Run: source ~/.bashrc"
    echo "3. Start Ollama: ollama serve"
    echo "4. Try: qwen or gemini"
    echo ""
}

# Run main function
main "$@"
