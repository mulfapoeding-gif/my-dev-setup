#!/bin/bash
# Setup script for Android APK reverse engineering tools

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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Detect OS
detect_os() {
    if [ -f "/data/data/com.termux/files/usr/bin/termux-info" ]; then
        OS="TERMUX"
    elif grep -q "kali" /etc/os-release 2>/dev/null; then
        OS="KALI"
    else
        OS="LINUX"
    fi
    log_info "Detected: $OS"
}

# Setup for Termux
setup_termux() {
    log_step "Setting up APK tools for Termux"
    
    # Enable wake lock
    termux-wake-lock
    
    # Install base dependencies
    pkg update -y
    pkg install -y wget bc busybox sed openjdk-17
    
    # Create directories
    ALPINEDIR="${PREFIX}/share/apkmod"
    BINDIR="${PREFIX}/bin"
    LIBDIR="${ALPINEDIR}/usr/lib"
    
    mkdir -p "$ALPINEDIR"
    mkdir -p "$LIBDIR"
    
    # Download APKTool
    APKTOOL_VERSION="2.6.1"
    log_info "Downloading APKTool v${APKTOOL_VERSION}..."
    wget -q "https://github.com/Hax4us/Apkmod/releases/download/v${APKTOOL_VERSION}/apktool-${APKTOOL_VERSION}.apk" \
        -O "$ALPINEDIR/opt/apktool.jar"
    
    # Download AAPT
    ARCH="aarch64"  # Default for most devices
    log_info "Downloading AAPT for $ARCH..."
    wget -q "https://github.com/Hax4us/Apkmod/releases/download/v${APKTOOL_VERSION}/aapt_${ARCH}.tar.gz" \
        -O aapt.tar.gz
    tar -xf aapt.tar.gz -C "$LIBDIR"
    rm aapt.tar.gz
    
    # Move AAPT binaries
    mkdir -p "$ALPINEDIR/usr/bin"
    mv "$LIBDIR/android/aapt" "$ALPINEDIR/usr/bin/" 2>/dev/null || true
    mv "$LIBDIR/android/aapt2" "$ALPINEDIR/usr/bin/" 2>/dev/null || true
    chmod +x "$ALPINEDIR/usr/bin/aapt" 2>/dev/null || true
    chmod +x "$ALPINEDIR/usr/bin/aapt2" 2>/dev/null || true
    
    # Download APKMod script
    log_info "Installing APKMod..."
    wget -q "https://github.com/hax4us/Apkmod/raw/master/apkmod.sh" \
        -O "$BINDIR/apkmod"
    chmod +x "$BINDIR/apkmod"
    
    # Setup APKMod config
    mkdir -p ~/.apkmod/framework
    mkdir -p ~/.apkmod/hooks
    
    # Download APKMod resources
    for file in apkmod.p12 signkill.jar hooks/hook2.smali hooks/hook.smali hooks/hook2.dex; do
        wget -q "https://github.com/hax4us/Apkmod/raw/master/$file" \
            -O "~/.apkmod/$file" 2>/dev/null || true
    done
    
    # Download JADX
    JADX_VERSION="1.3.2"
    log_info "Downloading JADX v${JADX_VERSION}..."
    wget -q "https://github.com/skylot/jadx/releases/download/v${JADX_VERSION}/jadx-${JADX_VERSION}.zip"
    mkdir -p "$ALPINEDIR/usr/lib/jadx"
    unzip -q "jadx-${JADX_VERSION}.zip" -d "$ALPINEDIR/usr/lib/jadx"
    rm "jadx-${JADX_VERSION}.zip"
    
    # Create JADX wrapper
    cat > "$BINDIR/jadx" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
ALPINEDIR="${PREFIX}/share/apkmod"
exec java -jar "$ALPINEDIR/usr/lib/jadx/lib/jadx-core.jar" "$@"
EOF
    chmod +x "$BINDIR/jadx"
    
    # Download scripts
    log_info "Installing helper scripts..."
    for script in signkill.sh apktool_termux.sh apktool_alpine.sh; do
        wget -q "https://github.com/Hax4us/Apkmod/raw/master/scripts/${script}" \
            -O "$script" 2>/dev/null || true
    done
    
    # Setup APKMod Alpine script
    if [ -f "apktool_termux.sh" ]; then
        mv apktool_termux.sh "$BINDIR/apktool"
        chmod +x "$BINDIR/apktool"
    fi
    
    # Disable wake lock
    termux-wake-unlock
    
    log_success "APK tools installed for Termux"
}

# Setup for Kali Linux
setup_kali() {
    log_step "Setting up APK tools for Kali Linux"
    
    # Install dependencies
    sudo apt update
    sudo apt install -y apktool default-jdk wget bc
    
    # Download JADX
    JADX_VERSION="1.3.2"
    log_info "Downloading JADX v${JADX_VERSION}..."
    wget -q "https://github.com/skylot/jadx/releases/download/v${JADX_VERSION}/jadx-${JADX_VERSION}.zip"
    sudo mkdir -p /opt/jadx
    sudo unzip -q "jadx-${JADX_VERSION}.zip" -d /opt/jadx
    rm "jadx-${JADX_VERSION}.zip"
    
    # Create JADX symlink
    sudo ln -sf /opt/jadx/bin/jadx /usr/local/bin/jadx
    sudo ln -sf /opt/jadx/bin/jadx-gui /usr/local/bin/jadx-gui
    
    # Download APKMod
    log_info "Installing APKMod..."
    wget -q "https://github.com/hax4us/Apkmod/raw/master/apkmod.sh" \
        -O /usr/local/bin/apkmod
    chmod +x /usr/local/bin/apkmod
    
    # Setup APKMod config
    mkdir -p ~/.apkmod/framework
    mkdir -p ~/.apkmod/hooks
    
    log_success "APK tools installed for Kali Linux"
}

# Main
main() {
    echo -e "${CYAN}"
    echo "======================================"
    echo "   APK Tools Setup"
    echo "======================================"
    echo -e "${NC}"
    
    detect_os
    
    case $OS in
        TERMUX)
            setup_termux
            ;;
        KALI|LINUX)
            setup_kali
            ;;
        *)
            log_error "Unsupported OS: $OS"
            exit 1
            ;;
    esac
    
    echo ""
    log_success "APK tools setup complete!"
    echo ""
    echo "Installed tools:"
    echo "  - APKTool (apktool)"
    echo "  - JADX (jadx, jadx-gui)"
    echo "  - AAPT (aapt, aapt2)"
    echo "  - APKMod (apkmod)"
    echo ""
    echo "Usage examples:"
    echo "  apktool d app.apk          # Decompile APK"
    echo "  apktool b folder -o out.apk # Recompile"
    echo "  jadx app.apk               # Decompile to Java"
    echo "  apkmod -i app.apk          # Inject payload"
    echo ""
}

main "$@"
