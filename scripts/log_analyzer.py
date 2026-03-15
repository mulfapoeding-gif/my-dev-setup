#!/data/data/com.termux/files/usr/bin/python3
"""
Android System Log Analyzer & Auto-Tuner
Analyzes optimizer logs and generates tuning recommendations
"""

import json
import os
import sys
from datetime import datetime, timedelta
from pathlib import Path
from collections import defaultdict

# Configuration
OPTIMIZER_DIR = Path.home() / ".system-optimizer"
LOG_DIR = OPTIMIZER_DIR / "logs"
LOG_FILE = LOG_DIR / "system.log"
METRICS_FILE = LOG_DIR / "metrics.json"
REPORTS_DIR = LOG_DIR / "reports"
CONFIG_FILE = OPTIMIZER_DIR / "config.json"

# Ensure directories exist
LOG_DIR.mkdir(parents=True, exist_ok=True)
REPORTS_DIR.mkdir(parents=True, exist_ok=True)


def load_metrics(hours=24):
    """Load metrics from last N hours"""
    metrics = []
    cutoff = datetime.now() - timedelta(hours=hours)
    
    if not METRICS_FILE.exists():
        return metrics
    
    with open(METRICS_FILE, 'r') as f:
        for line in f:
            try:
                metric = json.loads(line.strip())
                timestamp = datetime.fromisoformat(metric['timestamp'])
                if timestamp >= cutoff:
                    metrics.append(metric)
            except (json.JSONDecodeError, KeyError):
                continue
    
    return metrics


def load_logs(lines=1000):
    """Load last N lines from log file"""
    if not LOG_FILE.exists():
        return []
    
    with open(LOG_FILE, 'r') as f:
        all_lines = f.readlines()
        return all_lines[-lines:]


def analyze_metrics(metrics):
    """Analyze metrics and return statistics"""
    if not metrics:
        return {}
    
    cpu_values = [m.get('cpu', 0) for m in metrics if m.get('cpu')]
    memory_values = [m.get('memory', 0) for m in metrics if m.get('memory')]
    temp_values = [m.get('temperature', 0) for m in metrics if m.get('temperature')]
    storage_values = [m.get('storage', 0) for m in metrics if m.get('storage')]
    
    def calc_stats(values):
        if not values:
            return {'avg': 0, 'min': 0, 'max': 0, 'p95': 0}
        values = sorted([float(v) for v in values if v])
        if not values:
            return {'avg': 0, 'min': 0, 'max': 0, 'p95': 0}
        
        p95_idx = int(len(values) * 0.95)
        return {
            'avg': sum(values) / len(values),
            'min': min(values),
            'max': max(values),
            'p95': values[p95_idx] if p95_idx < len(values) else values[-1]
        }
    
    return {
        'cpu': calc_stats(cpu_values),
        'memory': calc_stats(memory_values),
        'temperature': calc_stats(temp_values),
        'storage': calc_stats(storage_values),
        'samples': len(metrics),
        'period_hours': len(metrics) / 60  # Assuming 1 sample per minute avg
    }


def analyze_logs(logs):
    """Analyze log entries for patterns"""
    alerts = defaultdict(int)
    actions = defaultdict(int)
    warnings = []
    
    for line in logs:
        line = line.strip()
        if 'HIGH CPU' in line:
            alerts['high_cpu'] += 1
        elif 'HIGH MEMORY' in line:
            alerts['high_memory'] += 1
        elif 'HIGH STORAGE' in line:
            alerts['high_storage'] += 1
        elif 'HIGH TEMPERATURE' in line:
            alerts['high_temp'] += 1
        elif 'LOW BATTERY' in line:
            alerts['low_battery'] += 1
        elif 'Optimization Cycle Complete' in line:
            actions['optimization_cycles'] += 1
        elif 'Cleared' in line:
            actions['cleanups'] += 1
        elif 'WARNING' in line:
            warnings.append(line)
    
    return {
        'alerts': dict(alerts),
        'actions': dict(actions),
        'warning_count': len(warnings),
        'recent_warnings': warnings[-10:]
    }


def generate_recommendations(stats, log_analysis):
    """Generate tuning recommendations based on analysis"""
    recommendations = []
    
    # CPU recommendations
    cpu_p95 = stats.get('cpu', {}).get('p95', 0)
    if cpu_p95 > 80:
        recommendations.append({
            'priority': 'HIGH',
            'category': 'CPU',
            'issue': f'CPU frequently high (P95: {cpu_p95:.1f}%)',
            'action': 'Consider closing background apps or reducing workload'
        })
    elif cpu_p95 > 60:
        recommendations.append({
            'priority': 'MEDIUM',
            'category': 'CPU',
            'issue': f'CPU moderately loaded (P95: {cpu_p95:.1f}%)',
            'action': 'Monitor for spikes during heavy usage'
        })
    
    # Memory recommendations
    mem_p95 = stats.get('memory', {}).get('p95', 0)
    if mem_p95 > 85:
        recommendations.append({
            'priority': 'HIGH',
            'category': 'Memory',
            'issue': f'Memory frequently high (P95: {mem_p95:.1f}%)',
            'action': 'Reduce concurrent processes, clear caches more frequently'
        })
    elif mem_p95 > 70:
        recommendations.append({
            'priority': 'MEDIUM',
            'category': 'Memory',
            'issue': f'Memory moderately loaded (P95: {mem_p95:.1f}%)',
            'action': 'Consider reducing npm/node processes'
        })
    
    # Temperature recommendations
    temp_max = stats.get('temperature', {}).get('max', 0)
    if temp_max > 50:
        recommendations.append({
            'priority': 'CRITICAL',
            'category': 'Temperature',
            'issue': f'High temperature detected (Max: {temp_max}°C)',
            'action': 'Reduce workload, improve ventilation, check for thermal throttling'
        })
    elif temp_max > 40:
        recommendations.append({
            'priority': 'LOW',
            'category': 'Temperature',
            'issue': f'Temperature elevated (Max: {temp_max}°C)',
            'action': 'Normal operating temperature, continue monitoring'
        })
    
    # Storage recommendations
    storage_avg = stats.get('storage', {}).get('avg', 0)
    if storage_avg > 85:
        recommendations.append({
            'priority': 'HIGH',
            'category': 'Storage',
            'issue': f'Storage nearly full ({storage_avg:.1f}%)',
            'action': 'Clean old logs, remove unused packages, clear downloads'
        })
    
    # Alert frequency recommendations
    alerts = log_analysis.get('alerts', {})
    if alerts.get('high_cpu', 0) > 10:
        recommendations.append({
            'priority': 'MEDIUM',
            'category': 'Tuning',
            'issue': f'Frequent CPU alerts ({alerts["high_cpu"]} times)',
            'action': 'Consider increasing CPU threshold or reducing background tasks'
        })
    
    if alerts.get('high_memory', 0) > 10:
        recommendations.append({
            'priority': 'MEDIUM',
            'category': 'Tuning',
            'issue': f'Frequent memory alerts ({alerts["high_memory"]} times)',
            'action': 'Enable aggressive memory optimization, reduce concurrent processes'
        })
    
    return recommendations


def generate_report(hours=24):
    """Generate comprehensive analysis report"""
    print("=" * 60)
    print("  Android System Analyzer & Auto-Tuner")
    print("=" * 60)
    print()
    
    # Load data
    metrics = load_metrics(hours)
    logs = load_logs()
    
    # Analyze
    stats = analyze_metrics(metrics)
    log_analysis = analyze_logs(logs)
    recommendations = generate_recommendations(stats, log_analysis)
    
    # Print statistics
    print(f"Analysis Period: Last {hours} hours")
    print(f"Samples Analyzed: {stats.get('samples', 0)}")
    print()
    
    print("┌" + "─" * 58 + "┐")
    print("│  RESOURCE STATISTICS".ljust(59) + "│")
    print("├" + "─" * 58 + "┤")
    
    for resource in ['cpu', 'memory', 'temperature', 'storage']:
        if resource in stats:
            r = stats[resource]
            unit = '%' if resource != 'temperature' else '°C'
            print(f"│ {resource.upper():12} Avg: {r['avg']:6.1f}{unit}  Max: {r['max']:6.1f}{unit}  P95: {r['p95']:6.1f}{unit}  │")
    
    print("└" + "─" * 58 + "┘")
    print()
    
    # Print alerts summary
    alerts = log_analysis.get('alerts', {})
    if alerts:
        print("┌" + "─" * 58 + "┐")
        print("│  ALERTS SUMMARY".ljust(59) + "│")
        print("├" + "─" * 58 + "┤")
        for alert_type, count in sorted(alerts.items(), key=lambda x: x[1], reverse=True):
            alert_name = alert_type.replace('_', ' ').title()
            print(f"│   {alert_name:25} {count:5} occurrences                    │")
        print("└" + "─" * 58 + "┘")
        print()
    
    # Print recommendations
    if recommendations:
        print("┌" + "─" * 58 + "┐")
        print("│  RECOMMENDATIONS".ljust(59) + "│")
        print("├" + "─" * 58 + "┤")
        
        for i, rec in enumerate(recommendations, 1):
            priority_colors = {
                'CRITICAL': '🔴',
                'HIGH': '🟠',
                'MEDIUM': '🟡',
                'LOW': '🟢'
            }
            icon = priority_colors.get(rec['priority'], '⚪')
            
            print(f"│ {icon} [{rec['priority']:8}] {rec['category']}".ljust(59) + "│")
            print(f"│   Issue: {rec['issue'][:45]}".ljust(59) + "│")
            print(f"│   Action: {rec['action'][:45]}".ljust(59) + "│")
            if i < len(recommendations):
                print("│" + " " * 58 + "│")
        
        print("└" + "─" * 58 + "┘")
        print()
    
    # Auto-tune suggestions
    print("┌" + "─" * 58 + "┐")
    print("│  AUTO-TUNE SUGGESTIONS".ljust(59) + "│")
    print("├" + "─" * 58 + "┤")
    
    # Calculate optimal thresholds
    if stats.get('cpu', {}).get('p95', 0) > 0:
        new_cpu_threshold = int(stats['cpu']['p95'] * 1.15)
        print(f"│   CPU Threshold: Current 80% → Suggested {new_cpu_threshold}%".ljust(59) + "│")
    
    if stats.get('memory', {}).get('p95', 0) > 0:
        new_mem_threshold = int(stats['memory']['p95'] * 1.15)
        print(f"│   Memory Threshold: Current 85% → Suggested {new_mem_threshold}%".ljust(59) + "│")
    
    print("│".ljust(59) + "│")
    print("│   Run: ./android-optimizer.sh tune  to apply".ljust(59) + "│")
    print("└" + "─" * 58 + "┘")
    
    # Save report
    report_data = {
        'generated_at': datetime.now().isoformat(),
        'period_hours': hours,
        'statistics': stats,
        'alerts': alerts,
        'recommendations': recommendations
    }
    
    report_file = REPORTS_DIR / f"report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    with open(report_file, 'w') as f:
        json.dump(report_data, f, indent=2)
    
    print()
    print(f"Report saved to: {report_file}")
    
    return report_data


def apply_tune():
    """Apply auto-tuned thresholds"""
    metrics = load_metrics(168)  # Last week
    
    if len(metrics) < 100:
        print("Not enough data for auto-tuning (need 100+ samples)")
        return
    
    stats = analyze_metrics(metrics)
    
    # Calculate new thresholds
    new_cpu = int(stats.get('cpu', {}).get('p95', 80) * 1.15)
    new_mem = int(stats.get('memory', {}).get('p95', 85) * 1.15)
    new_temp = int(stats.get('temperature', {}).get('p95', 45) + 5)
    
    # Clamp to reasonable values
    new_cpu = max(50, min(95, new_cpu))
    new_mem = max(50, min(95, new_mem))
    new_temp = max(35, min(60, new_temp))
    
    # Save config
    config = {
        'CPU_THRESHOLD': new_cpu,
        'MEMORY_THRESHOLD': new_mem,
        'TEMP_THRESHOLD': new_temp,
        'auto_tuned_at': datetime.now().isoformat(),
        'samples_used': len(metrics)
    }
    
    with open(CONFIG_FILE, 'w') as f:
        json.dump(config, f, indent=2)
    
    print("Auto-tune applied!")
    print(f"  CPU Threshold: {new_cpu}%")
    print(f"  Memory Threshold: {new_mem}%")
    print(f"  Temperature Threshold: {new_temp}°C")
    print()
    print("Restart optimizer to apply: ./android-optimizer.sh stop && ./android-optimizer.sh start")


def show_realtime():
    """Show real-time analysis"""
    print("Real-time Log Analysis (Ctrl+C to stop)")
    print("=" * 60)
    
    try:
        last_pos = 0
        while True:
            if LOG_FILE.exists():
                with open(LOG_FILE, 'r') as f:
                    f.seek(last_pos)
                    new_lines = f.readlines()
                    last_pos = f.tell()
                    
                    for line in new_lines:
                        line = line.strip()
                        if 'HIGH' in line or 'WARNING' in line:
                            print(f"⚠️  {line}")
                        elif 'Optimization Cycle' in line:
                            print(f"✓  {line}")
            
            # Load recent metrics
            metrics = load_metrics(1)
            if metrics:
                latest = metrics[-1]
                print(f"\r📊 CPU: {latest.get('cpu', 0):5.1f}% | MEM: {latest.get('memory', 0):5.1f}% | TEMP: {latest.get('temperature', 0):2d}°C", end='', flush=True)
            
            import time
            time.sleep(5)
    except KeyboardInterrupt:
        print("\n\nStopped")


def usage():
    print("""
Android System Log Analyzer & Auto-Tuner

Usage: python3 log_analyzer.py {command} [options]

Commands:
    report [hours]  - Generate analysis report (default: 24 hours)
    tune            - Auto-apply optimal thresholds
    watch           - Real-time log monitoring
    config          - Show current configuration
    reset           - Reset thresholds to defaults

Examples:
    python3 log_analyzer.py report      # Last 24 hours
    python3 log_analyzer.py report 168  # Last week
    python3 log_analyzer.py tune        # Auto-apply tuning
    python3 log_analyzer.py watch       # Real-time monitoring
""")


if __name__ == '__main__':
    command = sys.argv[1] if len(sys.argv) > 1 else 'report'
    
    if command == 'report':
        hours = int(sys.argv[2]) if len(sys.argv) > 2 else 24
        generate_report(hours)
    elif command == 'tune':
        apply_tune()
    elif command == 'watch':
        show_realtime()
    elif command == 'config':
        if CONFIG_FILE.exists():
            with open(CONFIG_FILE, 'r') as f:
                print(json.dumps(json.load(f), indent=2))
        else:
            print("No custom config (using defaults)")
    elif command == 'reset':
        if CONFIG_FILE.exists():
            CONFIG_FILE.unlink()
            print("Configuration reset to defaults")
        else:
            print("Already at defaults")
    else:
        usage()
