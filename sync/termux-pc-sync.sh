#!/bin/bash
# Termux-PC Sync Script
# Sync files and configurations between Termux and PC

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

# Configuration
SYNC_DIR="$HOME/.termux-pc-sync"
CONFIG_FILE="$SYNC_DIR/config.json"
PC_HOST=""
PC_PORT="8080"
OLLAMA_PORT="11434"
SSH_PORT="22"
SYNC_METHOD="ssh"  # ssh, http, rsync

# Load configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        PC_HOST=$(jq -r '.pc_host' "$CONFIG_FILE" 2>/dev/null)
        PC_PORT=$(jq -r '.pc_port' "$CONFIG_FILE" 2>/dev/null)
        OLLAMA_PORT=$(jq -r '.ollama_port' "$CONFIG_FILE" 2>/dev/null)
        SSH_PORT=$(jq -r '.ssh_port' "$CONFIG_FILE" 2>/dev/null)
        SYNC_METHOD=$(jq -r '.sync_method' "$CONFIG_FILE" 2>/dev/null)
    fi
}

# Save configuration
save_config() {
    mkdir -p "$SYNC_DIR"
    cat > "$CONFIG_FILE" << EOF
{
  "pc_host": "$PC_HOST",
  "pc_port": "$PC_PORT",
  "ollama_port": "$OLLAMA_PORT",
  "ssh_port": "$SSH_PORT",
  "sync_method": "$SYNC_METHOD",
  "last_sync": "$(date -Iseconds)"
}
EOF
    log_success "Configuration saved"
}

# Interactive setup
setup_wizard() {
    log_step "Termux-PC Sync Setup Wizard"
    echo ""
    
    echo "Enter your Windows PC IP address:"
    echo "(The PC and Termux must be on the same network)"
    read -p "PC IP Address: " PC_HOST
    
    echo ""
    echo "Select sync method:"
    echo "1) SSH (recommended, requires SSH server on PC)"
    echo "2) HTTP (simple file transfer)"
    echo "3) Rsync (fast, efficient)"
    read -p "Choose [1-3]: " choice
    
    case $choice in
        1) SYNC_METHOD="ssh" ;;
        2) SYNC_METHOD="http" ;;
        3) SYNC_METHOD="rsync" ;;
        *) SYNC_METHOD="ssh" ;;
    esac
    
    echo ""
    read -p "Sync Ollama models? (y/n): " sync_ollama
    if [ "$sync_ollama" = "y" ]; then
        OLLAMA_SYNC="true"
    else
        OLLAMA_SYNC="false"
    fi
    
    save_config
    
    log_success "Setup complete!"
}

# Test connection to PC
test_connection() {
    log_step "Testing connection to PC ($PC_HOST)..."
    
    case $SYNC_METHOD in
        ssh)
            if command -v nc &> /dev/null; then
                if nc -z -w 5 "$PC_HOST" "$SSH_PORT" 2>/dev/null; then
                    log_success "SSH port $SSH_PORT is open"
                    return 0
                else
                    log_error "Cannot connect to SSH port $SSH_PORT"
                    return 1
                fi
            else
                if ssh -o ConnectTimeout=5 -o BatchMode=yes "$PC_HOST" "echo test" 2>/dev/null; then
                    log_success "SSH connection successful"
                    return 0
                else
                    log_error "SSH connection failed"
                    return 1
                fi
            fi
            ;;
        http)
            if curl -s --connect-timeout 5 "http://$PC_HOST:$PC_PORT/" > /dev/null 2>&1; then
                log_success "HTTP sync server is running"
                return 0
            else
                log_error "Cannot connect to HTTP sync server"
                return 1
            fi
            ;;
        rsync)
            if rsync -e "ssh -p $SSH_PORT" --daemon --address "$PC_HOST" 2>/dev/null; then
                log_success "Rsync daemon is running"
                return 0
            else
                if ssh -o ConnectTimeout=5 -o BatchMode=yes "$PC_HOST" "which rsync" 2>/dev/null; then
                    log_success "Rsync is available on PC"
                    return 0
                else
                    log_error "Rsync not available"
                    return 1
                fi
            fi
            ;;
    esac
}

# Sync files via SSH
sync_ssh() {
    local direction="${1:-pull}"  # pull (PC->Termux) or push (Termux->PC)
    
    log_step "Syncing via SSH ($direction)..."
    
    # Create SSH key if not exists
    if [ ! -f "$HOME/.ssh/id_rsa" ]; then
        log_info "Generating SSH key..."
        ssh-keygen -t ed25519 -f "$HOME/.ssh/id_rsa" -N "" -q
    fi
    
    # Show public key for setup
    if [ ! -f "$HOME/.ssh/key_sent" ]; then
        log_warn "Copy this public key to PC ~/.ssh/authorized_keys:"
        cat "$HOME/.ssh/id_rsa.pub"
        echo ""
        read -p "Press Enter after copying..."
        touch "$HOME/.ssh/key_sent"
    fi
    
    # Define files to sync
    local files=(
        ".bashrc"
        ".profile"
        ".gitconfig"
        ".qwen/settings.json"
        ".aider.conf.yml"
        ".goterm.json"
        "termux_cli_manager.py"
    )
    
    case $direction in
        pull)
            for file in "${files[@]}"; do
                log_info "Pulling $file..."
                scp -P "$SSH_PORT" "$PC_HOST:~/termux-sync/$file" "$HOME/$file" 2>/dev/null || log_warn "Failed to pull $file"
            done
            ;;
        push)
            for file in "${files[@]}"; do
                if [ -f "$HOME/$file" ]; then
                    log_info "Pushing $file..."
                    scp -P "$SSH_PORT" "$HOME/$file" "$PC_HOST:~/termux-sync/$file" 2>/dev/null || log_warn "Failed to push $file"
                fi
            done
            ;;
    esac
    
    log_success "Sync complete"
}

# Sync files via HTTP
sync_http() {
    local direction="${1:-pull}"
    
    log_step "Syncing via HTTP ($direction)..."
    
    local files=(
        ".bashrc"
        ".profile"
        ".gitconfig"
        ".qwen/settings.json"
        ".aider.conf.yml"
        ".goterm.json"
    )
    
    case $direction in
        pull)
            for file in "${files[@]}"; do
                log_info "Pulling $file..."
                curl -s "http://$PC_HOST:$PC_PORT/$file" -o "$HOME/$file" 2>/dev/null || log_warn "Failed to pull $file"
            done
            ;;
        push)
            for file in "${files[@]}"; do
                if [ -f "$HOME/$file" ]; then
                    log_info "Pushing $file..."
                    curl -s -X POST -T "$HOME/$file" "http://$PC_HOST:$PC_PORT/$file" 2>/dev/null || log_warn "Failed to push $file"
                fi
            done
            ;;
    esac
    
    log_success "Sync complete"
}

# Configure Ollama to use PC
configure_ollama_pc() {
    log_step "Configuring Ollama to use PC..."
    
    local qwen_settings="$HOME/.qwen/settings.json"
    
    if [ ! -f "$qwen_settings" ]; then
        log_error "Qwen settings not found"
        return 1
    fi
    
    # Backup
    cp "$qwen_settings" "$qwen_settings.bak"
    
    # Add PC Ollama endpoint using jq
    if command -v jq &> /dev/null; then
        jq --arg host "$PC_HOST" --arg port "$OLLAMA_PORT" '
        .modelProviders.openai += [{
            "id": "pc-ollama",
            "name": "PC Ollama (Windows)",
            "baseUrl": ("http://" + $host + ":" + $port + "/v1"),
            "envKey": "BAILIAN_CODING_PLAN_API_KEY",
            "generationConfig": {
                "contextWindowSize": 32768
            }
        }]
        ' "$qwen_settings" > "$qwen_settings.tmp" && mv "$qwen_settings.tmp" "$qwen_settings"
        
        log_success "PC Ollama endpoint added to Qwen settings"
    else
        log_warn "jq not installed, manual configuration needed"
        echo "Add this to $qwen_settings:"
        cat << EOF
{
  "id": "pc-ollama",
  "name": "PC Ollama (Windows)",
  "baseUrl": "http://$PC_HOST:$OLLAMA_PORT/v1"
}
EOF
    fi
    
    # Update .bashrc with PC Ollama alias
    if ! grep -q "pc-ollama" "$HOME/.bashrc" 2>/dev/null; then
        cat >> "$HOME/.bashrc" << 'EOF'

# PC Ollama shortcuts
alias ollama-pc='OLLAMA_HOST=$PC_HOST:11434 ollama'
EOF
        log_info "Added PC Ollama shortcuts to .bashrc"
    fi
}

# Create tunnel to PC (for remote access)
create_tunnel() {
    log_step "Creating SSH tunnel to PC..."
    
    # Kill existing tunnel
    pkill -f "ssh.*$PC_HOST.*$OLLAMA_PORT" 2>/dev/null || true
    
    # Create new tunnel
    ssh -N -f -L "$OLLAMA_PORT:$PC_HOST:$OLLAMA_PORT" \
        -o ServerAliveInterval=60 \
        -o ServerAliveCountMax=3 \
        "$PC_HOST" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_success "Tunnel created: localhost:$OLLAMA_PORT -> PC:$OLLAMA_PORT"
        echo "Use Ollama at: http://localhost:$OLLAMA_PORT"
    else
        log_error "Failed to create tunnel"
    fi
}

# Sync Ollama models list
sync_models() {
    log_step "Syncing Ollama models from PC..."
    
    # Get models from PC
    local models=$(curl -s "http://$PC_HOST:$OLLAMA_PORT/api/tags" 2>/dev/null | jq -r '.models[].name' 2>/dev/null)
    
    if [ -n "$models" ]; then
        log_info "Available models on PC:"
        echo "$models"
        echo ""
        
        read -p "Pull all models? (y/n): " pull_all
        if [ "$pull_all" = "y" ]; then
            for model in $models; do
                log_info "Pulling $model..."
                ollama pull "$model"
            done
        else
            read -p "Enter model name to pull: " model_name
            ollama pull "$model_name"
        fi
    else
        log_warn "Could not fetch models from PC"
    fi
}

# Main menu
show_menu() {
    echo ""
    echo -e "${CYAN}======================================${NC}"
    echo -e "${CYAN}  Termux-PC Sync Menu${NC}"
    echo -e "${CYAN}======================================${NC}"
    echo "1) Setup Wizard"
    echo "2) Test Connection"
    echo "3) Sync Files (Pull from PC)"
    echo "4) Sync Files (Push to PC)"
    echo "5) Configure PC Ollama"
    echo "6) Create SSH Tunnel"
    echo "7) Sync Ollama Models"
    echo "8) Show Configuration"
    echo "9) Exit"
    echo ""
}

# Main
main() {
    load_config
    
    # Install dependencies
    if ! command -v jq &> /dev/null; then
        log_info "Installing jq..."
        pkg install jq -y 2>/dev/null || apt install jq -y 2>/dev/null || true
    fi
    
    if [ "$1" = "--setup" ]; then
        setup_wizard
        exit 0
    elif [ "$1" = "--pull" ]; then
        test_connection && sync_ssh pull
        exit 0
    elif [ "$1" = "--push" ]; then
        test_connection && sync_ssh push
        exit 0
    elif [ "$1" = "--tunnel" ]; then
        create_tunnel
        exit 0
    elif [ "$1" = "--configure-ollama" ]; then
        configure_ollama_pc
        exit 0
    fi
    
    # Interactive mode
    while true; do
        show_menu
        read -p "Choose [1-9]: " choice
        
        case $choice in
            1) setup_wizard ;;
            2) test_connection ;;
            3) test_connection && sync_ssh pull ;;
            4) test_connection && sync_ssh push ;;
            5) configure_ollama_pc ;;
            6) create_tunnel ;;
            7) sync_models ;;
            8)
                if [ -f "$CONFIG_FILE" ]; then
                    cat "$CONFIG_FILE"
                else
                    log_warn "No configuration found"
                fi
                ;;
            9) exit 0 ;;
            *) log_error "Invalid choice" ;;
        esac
    done
}

main "$@"
