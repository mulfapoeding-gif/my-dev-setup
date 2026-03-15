#!/data/data/com.termux/files/usr/bin/bash
# Install Android System Optimizer
# Sets up hidden background service

set -e

echo "========================================"
echo "  Android System Optimizer Installation"
echo "========================================"
echo ""

OPTIMIZER_DIR="$HOME/.system-optimizer"
SCRIPTS_DIR="$HOME/my-dev-setup/scripts"

# Create directories
echo "[1/5] Creating directories..."
mkdir -p "$OPTIMIZER_DIR/logs"
mkdir -p "$OPTIMIZER_DIR/logs/reports"

# Copy scripts
echo "[2/5] Installing scripts..."
cp "$SCRIPTS_DIR/android-optimizer.sh" "$OPTIMIZER_DIR/optimizer.sh" 2>/dev/null || true
cp "$SCRIPTS_DIR/log_analyzer.py" "$OPTIMIZER_DIR/log_analyzer.py" 2>/dev/null || true
chmod +x "$OPTIMIZER_DIR/optimizer.sh" 2>/dev/null || true
chmod +x "$OPTIMIZER_DIR/log_analyzer.py" 2>/dev/null || true

# Create wrapper script in home
echo "[3/5] Creating wrapper script..."
cat > "$HOME/optimize.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Android System Optimizer - Quick Access

OPTIMIZER_DIR="$HOME/.system-optimizer"

case "$1" in
    start)
        "$OPTIMIZER_DIR/optimizer.sh" start
        ;;
    stop)
        "$OPTIMIZER_DIR/optimizer.sh" stop
        ;;
    status)
        "$OPTIMIZER_DIR/optimizer.sh" status
        ;;
    watch)
        "$OPTIMIZER_DIR/optimizer.sh" watch
        ;;
    report)
        python3 "$OPTIMIZER_DIR/log_analyzer.py" report ${2:-24}
        ;;
    tune)
        python3 "$OPTIMIZER_DIR/log_analyzer.py" tune
        ;;
    logs)
        tail -${2:-50} "$OPTIMIZER_DIR/logs/system.log"
        ;;
    clean)
        "$OPTIMIZER_DIR/optimizer.sh" clean
        echo "Cache and old logs cleaned"
        ;;
    *)
        cat << HELP
Android System Optimizer - Hidden Background Service

Usage: optimize {command} [options]

Commands:
    start       - Start hidden optimizer (background)
    stop        - Stop optimizer
    status      - Show running status
    watch       - Real-time system monitor
    report [h]  - Analysis report (default: 24h)
    tune        - Auto-tune thresholds
    logs [n]    - Show last N log lines
    clean       - Clean cache and old logs

Examples:
    optimize start          # Start hidden optimizer
    optimize status         # Check if running
    optimize report 168     # Weekly report
    optimize tune           # Auto-tune based on logs
    optimize watch          # Real-time monitoring

Logs: ~/.system-optimizer/logs/system.log
HELP
        ;;
esac
EOF

chmod +x "$HOME/optimize.sh"

# Add to termux boot (if termux-boot is installed)
echo "[4/5] Setting up auto-start..."
if [ -d "$HOME/.termux/boot" ]; then
    cat > "$HOME/.termux/boot/optimize.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
sleep 5
/optimize.sh start
EOF
    chmod +x "$HOME/.termux/boot/optimize.sh"
    echo "  ✓ Auto-start configured"
else
    echo "  ℹ termux-boot not installed (optional)"
    echo "  Install: pkg install termux-boot"
fi

# Create default config
echo "[5/5] Creating default configuration..."
cat > "$OPTIMIZER_DIR/config.json" << 'EOF'
{
  "CPU_THRESHOLD": 80,
  "MEMORY_THRESHOLD": 85,
  "STORAGE_THRESHOLD": 90,
  "TEMP_THRESHOLD": 45,
  "MONITORING_INTERVAL_CHARGING": 60,
  "MONITORING_INTERVAL_BATTERY": 300,
  "LOG_RETENTION_DAYS": 7,
  "METRICS_RETENTION_DAYS": 30,
  "AUTO_TUNE_ENABLED": true,
  "auto_tuned_at": null
}
EOF

echo ""
echo "========================================"
echo "  Installation Complete!"
echo "========================================"
echo ""
echo "Quick Start:"
echo "  optimize start      # Start hidden optimizer"
echo "  optimize status     # Check status"
echo "  optimize report     # View analysis"
echo "  optimize watch      # Real-time monitor"
echo ""
echo "The optimizer runs hidden in background"
echo "Logs: ~/.system-optimizer/logs/system.log"
echo ""
echo "Starting optimizer now..."
"$OPTIMIZER_DIR/optimizer.sh" start
