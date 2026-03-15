# Android System Optimizer - Complete Guide

## Overview

Hidden background service that monitors and optimizes your Android/Termux system 24/7.

**Features:**
- ✅ CPU monitoring and optimization
- ✅ Memory management
- ✅ Storage cleaning
- ✅ Temperature monitoring
- ✅ Battery-aware operation
- ✅ Auto-tuning thresholds
- ✅ Daily reports
- ✅ Hidden background operation

---

## Quick Start

### Install (First Time)

```bash
cd ~/my-dev-setup/scripts
./install-optimizer.sh
```

### Daily Usage

```bash
# Start optimizer (hidden background)
~/optimize.sh start

# Check status
~/optimize.sh status

# View real-time monitor
~/optimize.sh watch

# Generate report (last 24 hours)
~/optimize.sh report

# Generate weekly report
~/optimize.sh report 168

# Auto-tune thresholds
~/optimize.sh tune

# View recent logs
~/optimize.sh logs 50

# Clean cache and old logs
~/optimize.sh clean
```

---

## How It Works

### Background Operation

1. **Monitoring Loop** (every 60 seconds while charging, 5 minutes on battery):
   - CPU usage
   - Memory usage
   - Storage space
   - Temperature
   - Battery level
   - Network stats
   - Process count

2. **Automatic Actions**:
   - Clears caches when storage > 90%
   - Optimizes memory when RAM > 85%
   - Detects resource-heavy processes
   - Cleans old logs weekly
   - Generates daily reports at midnight

3. **Logging**:
   - All metrics saved to JSON
   - Alerts logged with timestamps
   - Reports generated daily

---

## File Locations

| File/Directory | Purpose |
|----------------|---------|
| `~/.system-optimizer/` | Main directory |
| `~/.system-optimizer/logs/system.log` | Activity logs |
| `~/.system-optimizer/logs/metrics.json` | Metrics data (JSON lines) |
| `~/.system-optimizer/logs/reports/` | Daily reports |
| `~/.system-optimizer/config.json` | Configuration |
| `~/optimize.sh` | Quick access command |

---

## Configuration

### Default Thresholds

```json
{
  "CPU_THRESHOLD": 80,
  "MEMORY_THRESHOLD": 85,
  "STORAGE_THRESHOLD": 90,
  "TEMP_THRESHOLD": 45,
  "MONITORING_INTERVAL_CHARGING": 60,
  "MONITORING_INTERVAL_BATTERY": 300,
  "LOG_RETENTION_DAYS": 7,
  "METRICS_RETENTION_DAYS": 30,
  "AUTO_TUNE_ENABLED": true
}
```

### Modify Thresholds

Edit `~/.system-optimizer/config.json`:

```json
{
  "CPU_THRESHOLD": 70,    // Alert when CPU > 70%
  "MEMORY_THRESHOLD": 80  // Alert when MEM > 80%
}
```

Then restart:
```bash
~/optimize.sh stop
~/optimize.sh start
```

---

## Log Analyzer

### Generate Report

```bash
# Last 24 hours
python3 ~/.system-optimizer/log_analyzer.py report

# Last week (168 hours)
python3 ~/.system-optimizer/log_analyzer.py report 168

# Last month (720 hours)
python3 ~/.system-optimizer/log_analyzer.py report 720
```

### Auto-Tune

Automatically adjusts thresholds based on historical data:

```bash
python3 ~/.system-optimizer/log_analyzer.py tune
```

This analyzes the last week of data and sets thresholds at 115% of the 95th percentile.

### Real-time Monitoring

```bash
python3 ~/.system-optimizer/log_analyzer.py watch
```

Shows live log analysis with alerts highlighted.

---

## Understanding Reports

### Sample Report Output

```
============================================================
  Android System Analyzer & Auto-Tuner
============================================================

Analysis Period: Last 24 hours
Samples Analyzed: 1440

┌──────────────────────────────────────────────────────────┐
│  RESOURCE STATISTICS                                      │
├──────────────────────────────────────────────────────────┤
│ CPU          Avg:   45.2%  Max:   92.1%  P95:   78.3%  │
│ MEMORY       Avg:   62.8%  Max:   88.5%  P95:   82.1%  │
│ TEMPERATURE  Avg:   38.5°C  Max:   44.0°C  P95:   42.0°C  │
│ STORAGE      Avg:   67.3%  Max:   67.8%  P95:   67.7%  │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│  ALERTS SUMMARY                                           │
├──────────────────────────────────────────────────────────┤
│   High Cpu                    15 occurrences                    │
│   High Memory                  8 occurrences                    │
│   Low Battery                  3 occurrences                    │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│  RECOMMENDATIONS                                          │
├──────────────────────────────────────────────────────────┤
│ 🟠 [HIGH    ] CPU                                         │
│   Issue: CPU frequently high (P95: 78.3%)                │
│   Action: Consider closing background apps               │
│                                                           │
│ 🟡 [MEDIUM  ] Memory                                      │
│   Issue: Memory moderately loaded (P95: 82.1%)           │
│   Action: Monitor for spikes during heavy usage          │
└──────────────────────────────────────────────────────────┘
```

### Metrics JSON Format

Each line in `metrics.json` is a JSON object:

```json
{"timestamp":"2026-03-15T21:50:34+00:00","cpu":45.2,"memory":62.8,"storage":67.3,"temperature":38,"battery":85,"battery_status":"Charging","processes":125,"load":"2.45 1.89 1.56"}
```

---

## Advanced Usage

### Manual Optimization

```bash
# Run single optimization cycle
bash ~/.system-optimizer/optimizer.sh optimize

# Clear caches manually
bash ~/.system-optimizer/optimizer.sh clean

# Kill heavy processes (CPU > 90%, MEM > 90%)
bash ~/.system-optimizer/optimizer.sh kill_heavy 90 90
```

### Custom Scripts

Add custom optimization actions by editing `~/.system-optimizer/optimizer.sh`.

Example: Add package cleanup
```bash
optimize_package_cache() {
    log "Cleaning package cache..."
    pkg clean -y 2>/dev/null
    npm cache clean --force 2>/dev/null
    pip3 cache purge 2>/dev/null
}
```

### Integration with Other Tools

The optimizer logs to JSON, making it easy to integrate:

```python
# Read latest metrics
import json
from pathlib import Path

metrics_file = Path.home() / ".system-optimizer/logs/metrics.json"
with open(metrics_file) as f:
    latest = json.loads(f.readlines()[-1])
    print(f"CPU: {latest['cpu']}%")
    print(f"Memory: {latest['memory']}%")
```

---

## Troubleshooting

### Optimizer Not Starting

```bash
# Check if already running
~/optimize.sh status

# Kill any stuck processes
pkill -f "android-optimizer"
pkill -f "system-optimizer"

# Restart
~/optimize.sh stop
~/optimize.sh start
```

### High Resource Usage

If optimizer itself uses too much resources:

1. Increase monitoring interval in config:
```json
{
  "MONITORING_INTERVAL_CHARGING": 120,
  "MONITORING_INTERVAL_BATTERY": 600
}
```

2. Disable auto-tuning:
```json
{
  "AUTO_TUNE_ENABLED": false
}
```

### Logs Growing Too Large

```bash
# Clean old logs
~/optimize.sh clean

# Reduce retention in config
{
  "LOG_RETENTION_DAYS": 3,
  "METRICS_RETENTION_DAYS": 7
}
```

---

## Performance Impact

| Metric | Impact |
|--------|--------|
| **CPU** | < 1% average |
| **Memory** | ~5-10 MB |
| **Storage** | ~10 MB (logs) |
| **Battery** | Negligible (adaptive) |

---

## Best Practices

1. **Start on Boot**: Install termux-boot for auto-start
2. **Weekly Reports**: Run `optimize report 168` weekly
3. **Monthly Tune**: Run `optimize tune` monthly
4. **Monitor Temperature**: Keep below 45°C for best performance
5. **Clean Regularly**: Run `optimize clean` when storage > 80%

---

## Commands Reference

| Command | Description |
|---------|-------------|
| `optimize start` | Start hidden optimizer |
| `optimize stop` | Stop optimizer |
| `optimize status` | Show running status |
| `optimize watch` | Real-time monitor |
| `optimize report [h]` | Analysis report |
| `optimize tune` | Auto-tune thresholds |
| `optimize logs [n]` | Show last N lines |
| `optimize clean` | Clean cache/logs |

---

## API Reference

### Bash Functions

```bash
# Get current CPU usage
get_cpu_usage()

# Get current memory usage
get_memory_usage()

# Get storage usage
get_storage_usage()

# Get temperature
get_temperature()

# Get battery level
get_battery_level()
```

### Python Functions

```python
# Load metrics from last N hours
load_metrics(hours=24)

# Load last N log lines
load_logs(lines=1000)

# Analyze metrics
analyze_metrics(metrics)

# Generate recommendations
generate_recommendations(stats, log_analysis)
```

---

**Last Updated:** March 2026  
**Version:** 1.0.0
