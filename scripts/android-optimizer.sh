#!/data/data/com.termux/files/usr/bin/bash
#
# Android System Optimizer - Hidden Background Service
# Monitors and optimizes system resources 24/7
#

# Configuration
OPTIMIZER_DIR="$HOME/.system-optimizer"
LOG_DIR="$OPTIMIZER_DIR/logs"
CONFIG_FILE="$OPTIMIZER_DIR/config.json"
PID_FILE="$OPTIMIZER_DIR/optimizer.pid"
LOG_FILE="$LOG_DIR/system.log"
METRICS_FILE="$LOG_DIR/metrics.json"
LOCK_FILE="$OPTIMIZER_DIR/optimizer.lock"

# Thresholds (auto-tuned based on logs)
CPU_THRESHOLD=80
MEMORY_THRESHOLD=85
STORAGE_THRESHOLD=90
TEMP_THRESHOLD=45

# Colors (disabled in background mode)
RED=''
GREEN=''
YELLOW=''
NC=''

# Create directories
mkdir -p "$LOG_DIR"

# Logging function
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

# Get CPU usage
get_cpu_usage() {
    if command -v top &> /dev/null; then
        top -n 1 2>/dev/null | grep -E "^[0-9.]+%.*user" | awk '{print $1}' | tr -d '%' || echo "0"
    else
        echo "0"
    fi
}

# Get memory usage
get_memory_usage() {
    if command -v free &> /dev/null; then
        free 2>/dev/null | awk '/Mem:/ {printf "%.1f", $3/$2 * 100}' || echo "0"
    else
        echo "0"
    fi
}

# Get storage usage
get_storage_usage() {
    df /data 2>/dev/null | awk 'NR==2 {gsub(/%/,""); print $5}' || echo "0"
}

# Get temperature (if available)
get_temperature() {
    local temp=0
    
    # Try various temperature sensors
    for sensor in /sys/class/thermal/thermal_zone*/temp /sys/devices/virtual/thermal/thermal_zone*/temp; do
        if [ -f "$sensor" ]; then
            temp=$(cat "$sensor" 2>/dev/null)
            if [ -n "$temp" ] && [ "$temp" -gt 0 ]; then
                # Convert to Celsius (some sensors report millidegrees)
                if [ "$temp" -gt 1000 ]; then
                    temp=$((temp / 1000))
                fi
                echo "$temp"
                return
            fi
        fi
    done
    
    echo "0"
}

# Get battery level
get_battery_level() {
    if [ -f /sys/class/power_supply/battery/capacity ]; then
        cat /sys/class/power_supply/battery/capacity 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Get battery status (charging/discharging)
get_battery_status() {
    if [ -f /sys/class/power_supply/battery/status ]; then
        cat /sys/class/power_supply/battery/status 2>/dev/null || echo "Unknown"
    else
        echo "Unknown"
    fi
}

# Get network stats
get_network_stats() {
    local rx_bytes=0
    local tx_bytes=0
    
    if [ -f /proc/net/dev ]; then
        rx_bytes=$(cat /proc/net/dev | awk '/wlan0|eth0/ {rx+=$2} END {print rx}')
        tx_bytes=$(cat /proc/net/dev | awk '/wlan0|eth0/ {tx+=$10} END {print tx}')
    fi
    
    echo "$rx_bytes:$tx_bytes"
}

# Get process count
get_process_count() {
    ps 2>/dev/null | wc -l || echo "0"
}

# Get load average
get_load_average() {
    if [ -f /proc/loadavg ]; then
        cat /proc/loadavg 2>/dev/null | awk '{print $1, $2, $3}'
    else
        echo "0 0 0"
    fi
}

# Kill resource-heavy processes
kill_heavy_processes() {
    local cpu_limit="${1:-90}"
    local memory_limit="${2:-90}"
    
    log "Checking for resource-heavy processes (CPU>${cpu_limit}%, MEM>${memory_limit}%)"
    
    # Get top processes by CPU
    ps -o pid,%cpu,%mem,comm 2>/dev/null | sort -k2 -rn | head -10 | while read pid cpu mem comm; do
        # Skip header and system processes
        if [ "$pid" = "PID" ] || [ -z "$pid" ]; then
            continue
        fi
        
        # Skip important system processes
        case "$comm" in
            init|zygote|system_server|android.*|com.android.*)
                log "Skipping system process: $comm (PID: $pid)"
                continue
                ;;
        esac
        
        # Check if process exceeds limits
        cpu_int=${cpu%.*}
        mem_int=${mem%.*}
        
        if [ "${cpu_int:-0}" -gt "$cpu_limit" ] || [ "${mem_int:-0}" -gt "$memory_limit" ]; then
            log "WARNING: Process $comm (PID: $pid) using CPU:${cpu}% MEM:${mem}%"
            
            # Don't kill, just log for now (safe mode)
            # kill -15 "$pid" 2>/dev/null && log "Killed process $pid"
        fi
    done
}

# Clear caches
clear_caches() {
    log "Clearing system caches..."
    
    # Clear package cache
    if [ -d "$HOME/.cache" ]; then
        local cache_size=$(du -sm "$HOME/.cache" 2>/dev/null | cut -f1)
        if [ "${cache_size:-0}" -gt 100 ]; then
            rm -rf "$HOME/.cache/"* 2>/dev/null
            log "Cleared cache directory (${cache_size}MB freed)"
        fi
    fi
    
    # Clear npm cache
    if command -v npm &> /dev/null; then
        npm cache clean --force 2>/dev/null && log "Cleared npm cache"
    fi
    
    # Clear pip cache
    if command -v pip3 &> /dev/null; then
        pip3 cache purge 2>/dev/null && log "Cleared pip cache"
    fi
}

# Optimize memory
optimize_memory() {
    log "Optimizing memory..."
    
    # Drop caches (requires root)
    if [ -w /proc/sys/vm/drop_caches ]; then
        echo 1 > /proc/sys/vm/drop_caches 2>/dev/null && log "Dropped page cache"
    fi
    
    # Adjust swappiness (if available)
    if [ -w /proc/sys/vm/swappiness ]; then
        echo 10 > /proc/sys/vm/swappiness 2>/dev/null
    fi
}

# Clean old logs
clean_old_logs() {
    local max_age_days=7
    
    log "Cleaning logs older than $max_age_days days..."
    find "$LOG_DIR" -name "*.log" -type f -mtime +$max_age_days -delete 2>/dev/null
    find "$LOG_DIR" -name "*.json" -type f -mtime +30 -delete 2>/dev/null
}

# Save metrics to JSON
save_metrics() {
    local cpu="$1"
    local memory="$2"
    local storage="$3"
    local temp="$4"
    local battery="$5"
    local battery_status="$6"
    local processes="$7"
    local load="$8"
    
    local timestamp=$(date -Iseconds)
    
    # Append to metrics file
    cat >> "$METRICS_FILE" << EOF
{"timestamp":"$timestamp","cpu":$cpu,"memory":$memory,"storage":$storage,"temperature":$temp,"battery":$battery,"battery_status":"$battery_status","processes":$processes,"load":"$load"}
EOF
}

# Main optimization loop
optimize() {
    log "=== Optimization Cycle Started ==="
    
    # Gather metrics
    local cpu=$(get_cpu_usage)
    local memory=$(get_memory_usage)
    local storage=$(get_storage_usage)
    local temp=$(get_temperature)
    local battery=$(get_battery_level)
    local battery_status=$(get_battery_status)
    local processes=$(get_process_count)
    local load=$(get_load_average)
    
    log "CPU: ${cpu}% | MEM: ${memory}% | Storage: ${storage}% | Temp: ${temp}°C | Battery: ${battery}% ($battery_status)"
    log "Processes: $processes | Load: $load"
    
    # Save metrics
    save_metrics "$cpu" "$memory" "$storage" "$temp" "$battery" "$battery_status" "$processes" "$load"
    
    # Check thresholds and act
    local actions_taken=0
    
    # High CPU
    if [ "${cpu%.*}" -gt "$CPU_THRESHOLD" ] 2>/dev/null; then
        log "HIGH CPU DETECTED: ${cpu}%"
        kill_heavy_processes 80 80
        actions_taken=$((actions_taken + 1))
    fi
    
    # High Memory
    if [ "${memory%.*}" -gt "$MEMORY_THRESHOLD" ] 2>/dev/null; then
        log "HIGH MEMORY DETECTED: ${memory}%"
        optimize_memory
        actions_taken=$((actions_taken + 1))
    fi
    
    # High Storage
    if [ "${storage:-0}" -gt "$STORAGE_THRESHOLD" ] 2>/dev/null; then
        log "HIGH STORAGE DETECTED: ${storage}%"
        clear_caches
        actions_taken=$((actions_taken + 1))
    fi
    
    # High Temperature
    if [ "${temp:-0}" -gt "$TEMP_THRESHOLD" ] 2>/dev/null; then
        log "HIGH TEMPERATURE DETECTED: ${temp}°C"
        # Reduce background activity
        log "Temperature warning - consider reducing workload"
        actions_taken=$((actions_taken + 1))
    fi
    
    # Battery optimization (when not charging)
    if [ "$battery_status" = "Discharging" ] && [ "${battery:-0}" -lt 20 ]; then
        log "LOW BATTERY: ${battery}% - Entering power save mode"
        # Could reduce monitoring frequency here
    fi
    
    # Clean old logs weekly
    if [ "$(date +%H)" = "03" ] && [ "$(date +%M)" = "00" ]; then
        clean_old_logs
    fi
    
    log "=== Optimization Cycle Complete (Actions: $actions_taken) ==="
}

# Generate daily report
generate_daily_report() {
    local yesterday=$(date -d "yesterday" +%Y-%m-%d)
    local report_file="$LOG_DIR/daily_report_$(date +%Y%m%d).md"
    
    log "Generating daily report..."
    
    cat > "$report_file" << EOF
# Daily System Report - $(date +%Y-%m-%d)

## Summary
- **Optimizer Uptime**: $(uptime 2>/dev/null || echo "N/A")
- **Log Entries**: $(wc -l < "$LOG_FILE" 2>/dev/null || echo "0")
- **Metric Records**: $(wc -l < "$METRICS_FILE" 2>/dev/null || echo "0")

## Performance Metrics
EOF
    
    # Calculate averages from metrics
    if [ -f "$METRICS_FILE" ] && [ -s "$METRICS_FILE" ]; then
        local avg_cpu=$(tail -100 "$METRICS_FILE" | jq -s 'map(.cpu) | add / length' 2>/dev/null || echo "N/A")
        local avg_mem=$(tail -100 "$METRICS_FILE" | jq -s 'map(.memory) | add / length' 2>/dev/null || echo "N/A")
        local max_temp=$(tail -100 "$METRICS_FILE" | jq -s 'map(.temperature) | max' 2>/dev/null || echo "N/A")
        
        cat >> "$report_file" << EOF
- Average CPU (last 100 samples): ${avg_cpu}%
- Average Memory (last 100 samples): ${avg_mem}%
- Max Temperature (last 100 samples): ${max_temp}°C
EOF
    fi
    
    log "Daily report saved to: $report_file"
}

# Auto-tune thresholds based on historical data
auto_tune_thresholds() {
    if [ ! -f "$METRICS_FILE" ] || [ ! -s "$METRICS_FILE" ]; then
        return
    fi
    
    log "Auto-tuning thresholds based on historical data..."
    
    # Get 95th percentile values
    local p95_cpu=$(jq -s 'map(.cpu) | sort | .[length * 0.95 | floor]' "$METRICS_FILE" 2>/dev/null)
    local p95_mem=$(jq -s 'map(.memory) | sort | .[length * 0.95 | floor]' "$METRICS_FILE" 2>/dev/null)
    
    # Adjust thresholds (set 10% above 95th percentile)
    if [ -n "$p95_cpu" ] && [ "$p95_cpu" != "null" ]; then
        CPU_THRESHOLD=$(echo "$p95_cpu * 1.1" | bc 2>/dev/null | cut -d. -f1 || echo "80")
        log "Auto-tuned CPU threshold: $CPU_THRESHOLD%"
    fi
    
    if [ -n "$p95_mem" ] && [ "$p95_mem" != "null" ]; then
        MEMORY_THRESHOLD=$(echo "$p95_mem * 1.1" | bc 2>/dev/null | cut -d. -f1 || echo "85")
        log "Auto-tuned Memory threshold: $MEMORY_THRESHOLD%"
    fi
}

# Status check
status() {
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        echo "Optimizer is RUNNING (PID: $(cat "$PID_FILE"))"
        echo ""
        echo "Recent logs:"
        tail -10 "$LOG_FILE"
    else
        echo "Optimizer is STOPPED"
    fi
}

# Stop optimizer
stop() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
            rm -f "$PID_FILE"
            log "Optimizer stopped"
            echo "Optimizer stopped"
        else
            rm -f "$PID_FILE"
            echo "Optimizer was not running"
        fi
    else
        echo "Optimizer is not running"
    fi
}

# Start optimizer in background
start() {
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        echo "Optimizer is already running (PID: $(cat "$PID_FILE"))"
        return 1
    fi
    
    # Acquire lock
    exec 200>"$LOCK_FILE"
    if ! flock -n 200; then
        echo "Another instance is already running"
        return 1
    fi
    
    echo "Starting system optimizer..."
    
    # Auto-tune thresholds
    auto_tune_thresholds
    
    # Start background loop
    (
        while true; do
            # Run optimization
            optimize
            
            # Generate daily report at midnight
            if [ "$(date +%H:%M)" = "00:05" ]; then
                generate_daily_report
            fi
            
            # Sleep interval (adaptive based on battery)
            local battery_status=$(get_battery_status)
            if [ "$battery_status" = "Discharging" ]; then
                sleep 300  # 5 minutes on battery
            else
                sleep 60   # 1 minute while charging
            fi
        done
    ) &
    
    local pid=$!
    echo $pid > "$PID_FILE"
    log "Optimizer started (PID: $pid)"
    echo "Optimizer started (PID: $pid)"
    echo "Logs: $LOG_FILE"
    echo "Metrics: $METRICS_FILE"
}

# Show real-time metrics
watch() {
    echo "Real-time system metrics (Ctrl+C to stop)"
    echo "=========================================="
    
    while true; do
        clear
        echo "=== Android System Monitor ==="
        echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        echo "CPU Usage:     $(get_cpu_usage)%"
        echo "Memory Usage:  $(get_memory_usage)%"
        echo "Storage Usage: $(get_storage_usage)%"
        echo "Temperature:   $(get_temperature)°C"
        echo "Battery:       $(get_battery_level)% ($(get_battery_status))"
        echo ""
        echo "Processes:     $(get_process_count)"
        echo "Load Average:  $(get_load_average)"
        echo ""
        
        local net_stats=$(get_network_stats)
        local rx=$(echo "$net_stats" | cut -d: -f1)
        local tx=$(echo "$net_stats" | cut -d: -f2)
        echo "Network RX:    $((rx / 1024 / 1024)) MB"
        echo "Network TX:    $((tx / 1024 / 1024)) MB"
        echo ""
        echo "Optimizer PID: $(cat "$PID_FILE" 2>/dev/null || echo "Not running")"
        echo ""
        echo "Recent alerts:"
        tail -5 "$LOG_FILE" 2>/dev/null | grep -E "WARNING|HIGH" || echo "No recent alerts"
        
        sleep 2
    done
}

# Show usage
usage() {
    cat << EOF
Android System Optimizer - Hidden Background Service

Usage: $0 {start|stop|status|watch|report|clean}

Commands:
    start   - Start optimizer in background (hidden)
    stop    - Stop the optimizer
    status  - Show optimizer status
    watch   - Show real-time metrics (foreground)
    report  - Generate daily report
    clean   - Clean old logs and caches
    tune    - Auto-tune thresholds

Examples:
    $0 start          # Start hidden optimizer
    $0 status         # Check if running
    $0 watch          # Real-time monitoring
    $0 report         # Generate today's report

Logs location: $LOG_FILE
Metrics location: $METRICS_FILE
EOF
}

# Main
case "${1:-start}" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    status)
        status
        ;;
    watch)
        watch
        ;;
    report)
        generate_daily_report
        ;;
    clean)
        clean_old_logs
        clear_caches
        ;;
    tune)
        auto_tune_thresholds
        ;;
    *)
        usage
        ;;
esac
