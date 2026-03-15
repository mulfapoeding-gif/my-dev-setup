#!/bin/bash
# Complete Termux Backup Script
# Backup entire Termux environment for sync with PC

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
BACKUP_DIR="$HOME/termux-backup"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="termux-backup-$TIMESTAMP"
FULL_BACKUP="$BACKUP_DIR/$BACKUP_NAME"

# What to backup
BACKUP_ITEMS=(
    ".bashrc"
    ".bash_profile"
    ".profile"
    ".inputrc"
    ".gitconfig"
    ".gitignore_global"
    ".vimrc"
    ".nanorc"
    ".wget-hsts"
    ".curlrc"
    ".python_history"
    ".node_repl_history"
    ".npm"
    ".nvm"
    ".config"
    ".local"
    ".ssh"
    ".termux"
    ".qwen"
    ".aider"
    ".android"
    ".cache"
    "go"
    "my-dev-setup"
    "termux_cli_manager.py"
)

# Packages to backup
PACKAGES_LIST="$BACKUP_DIR/packages-$TIMESTAMP.txt"

# Create backup directory
mkdir -p "$BACKUP_DIR"

log_step "Starting Termux backup..."
echo ""

# Backup installed packages
log_info "Backing up package list..."
pkg list-installed > "$PACKAGES_LIST" 2>/dev/null || dpkg --get-selections > "$PACKAGES_LIST" 2>/dev/null || true
log_success "Package list saved: $PACKAGES_LIST"

# Backup configuration files
log_info "Backing up configuration files..."
mkdir -p "$FULL_BACKUP"

for item in "${BACKUP_ITEMS[@]}"; do
    if [ -e "$HOME/$item" ]; then
        log_info "Backing up $item..."
        cp -rp "$HOME/$item" "$FULL_BACKUP/" 2>/dev/null || log_warn "Failed to backup $item"
    fi
done

# Backup Termux specific files
if [ -d "$PREFIX/etc" ]; then
    log_info "Backing up Termux config..."
    mkdir -p "$FULL_BACKUP/prefix/etc"
    cp -rp "$PREFIX/etc" "$FULL_BACKUP/prefix/" 2>/dev/null || true
fi

# Create restore script
cat > "$FULL_BACKUP/restore.sh" << 'RESTORE_SCRIPT'
#!/bin/bash
# Restore Termux from backup

set -e

BACKUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo "  Termux Restore Script"
echo "========================================"
echo ""
echo "This will restore:"
echo "- Configuration files"
echo "- Directory structure"
echo "- Package list (manual install required)"
echo ""
read -p "Continue? (y/n): " confirm

if [ "$confirm" != "y" ]; then
    echo "Cancelled"
    exit 0
fi

# Restore config files
echo "Restoring configuration files..."
for item in .bashrc .profile .gitconfig .inputrc .vimrc; do
    if [ -f "$BACKUP_DIR/$item" ]; then
        echo "Restoring $item..."
        cp "$BACKUP_DIR/$item" "$HOME/"
    fi
done

# Restore directories
echo "Restoring directories..."
for dir in .npm .nvm .config .local .ssh .qwen .aider go; do
    if [ -d "$BACKUP_DIR/$dir" ]; then
        echo "Restoring $dir..."
        cp -rp "$BACKUP_DIR/$dir" "$HOME/"
    fi
done

# Show packages to install
echo ""
echo "Packages to install:"
if [ -f "$BACKUP_DIR/../packages-*.txt" ]; then
    cat "$BACKUP_DIR/../packages-*.txt"
    echo ""
    echo "To install: pkg install $(cat $BACKUP_DIR/../packages-*.txt | awk '{print $1}' | tr '\n' ' ')"
fi

echo ""
echo "Restore complete! Run: source ~/.bashrc"
RESTORE_SCRIPT

chmod +x "$FULL_BACKUP/restore.sh"

# Create compressed archive
log_info "Creating compressed archive..."
cd "$BACKUP_DIR"
tar -czf "$BACKUP_NAME.tar.gz" "$BACKUP_NAME" 2>/dev/null || log_warn "Compression failed"

# Calculate size
BACKUP_SIZE=$(du -sh "$FULL_BACKUP" 2>/dev/null | cut -f1)

log_success "Backup complete!"
echo ""
echo "========================================"
echo "  Backup Summary"
echo "========================================"
echo "Location: $FULL_BACKUP"
echo "Archive: $BACKUP_DIR/$BACKUP_NAME.tar.gz"
echo "Size: $BACKUP_SIZE"
echo "Packages: $PACKAGES_LIST"
echo ""
echo "To sync with PC:"
echo "  scp -r $FULL_BACKUP user@PC_IP:~/termux-backups/"
echo ""
echo "To restore:"
echo "  cd $FULL_BACKUP && ./restore.sh"
echo "========================================"
