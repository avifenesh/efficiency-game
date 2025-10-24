#!/usr/bin/env python3
"""
Synthetic Log Generator for Language Efficiency Benchmark
Generates realistic Apache/Nginx style logs with controlled ERROR/WARN/INFO distribution
"""

import random
import datetime
import sys
from pathlib import Path

# Configuration
SEED = 42  # For reproducibility
LOG_LEVELS = {
    'INFO': 0.70,   # 70%
    'WARN': 0.20,   # 20%
    'ERROR': 0.10   # 10%
}

COMPONENTS = [
    'Auth', 'Database', 'Cache', 'Service', 'API', 'Queue',
    'Worker', 'Gateway', 'Proxy', 'Storage', 'Session', 'Security'
]

INFO_MESSAGES = [
    'Request processed successfully',
    'Connection established',
    'Data retrieved from cache',
    'Transaction completed',
    'User session started',
    'Configuration loaded',
    'Service initialized',
    'Health check passed',
    'Backup completed successfully',
    'Metrics published',
]

WARN_MESSAGES = [
    'Memory threshold exceeded',
    'Response time degraded',
    'Connection pool nearly exhausted',
    'Cache miss rate elevated',
    'Retry attempt initiated',
    'Deprecated API endpoint accessed',
    'Rate limit approaching',
    'Disk space running low',
    'Slow query detected',
    'Certificate expiring soon',
]

ERROR_MESSAGES = [
    'Connection timeout',
    'Database query failed',
    'Authentication failed',
    'Resource not found',
    'Permission denied',
    'Invalid request format',
    'Service unavailable',
    'Out of memory',
    'Deadlock detected',
    'Failed to write to disk',
]

def get_weighted_level():
    """Return a log level based on configured weights"""
    rand = random.random()
    cumulative = 0
    for level, weight in LOG_LEVELS.items():
        cumulative += weight
        if rand <= cumulative:
            return level
    return 'INFO'

def get_message_for_level(level):
    """Get appropriate message for log level"""
    if level == 'ERROR':
        return random.choice(ERROR_MESSAGES)
    elif level == 'WARN':
        return random.choice(WARN_MESSAGES)
    else:
        return random.choice(INFO_MESSAGES)

def generate_log_line(base_time, offset_seconds):
    """Generate a single log line"""
    timestamp = base_time + datetime.timedelta(seconds=offset_seconds)
    level = get_weighted_level()
    component = random.choice(COMPONENTS)
    message = get_message_for_level(level)
    
    return f"{timestamp.strftime('%Y-%m-%d %H:%M:%S')} {level} [{component}] {message}"

def generate_logs(output_path, num_lines):
    """Generate log file with specified number of lines"""
    random.seed(SEED)
    base_time = datetime.datetime(2024, 10, 24, 10, 0, 0)
    
    print(f"Generating {num_lines:,} log lines to {output_path}...")
    
    with open(output_path, 'w') as f:
        for i in range(num_lines):
            line = generate_log_line(base_time, i)
            f.write(line + '\n')
            
            if (i + 1) % 100000 == 0:
                print(f"  Progress: {i+1:,} lines written...")
    
    # Get file size
    size_bytes = Path(output_path).stat().st_size
    size_mb = size_bytes / (1024 * 1024)
    
    print(f"✓ Complete: {num_lines:,} lines ({size_mb:.2f} MB)")
    
    # Calculate actual distribution
    random.seed(SEED)
    error_count = 0
    warn_count = 0
    info_count = 0
    
    for _ in range(num_lines):
        level = get_weighted_level()
        if level == 'ERROR':
            error_count += 1
        elif level == 'WARN':
            warn_count += 1
        else:
            info_count += 1
    
    print(f"  Distribution: {info_count:,} INFO ({info_count/num_lines*100:.1f}%), "
          f"{warn_count:,} WARN ({warn_count/num_lines*100:.1f}%), "
          f"{error_count:,} ERROR ({error_count/num_lines*100:.1f}%)")

def main():
    """Main entry point"""
    # Create data directory if it doesn't exist
    data_dir = Path(__file__).parent.parent / 'data' / 'synthetic'
    data_dir.mkdir(parents=True, exist_ok=True)
    
    # Generate three sizes
    sizes = {
        'small': 10_000,      # ~1 MB
        'medium': 100_000,    # ~10 MB
        'large': 1_000_000    # ~100 MB
    }
    
    print("=" * 60)
    print("SYNTHETIC LOG GENERATOR")
    print("=" * 60)
    print()
    
    for name, num_lines in sizes.items():
        output_path = data_dir / f"{name}.log"
        generate_logs(output_path, num_lines)
        print()
    
    print("=" * 60)
    print("All log files generated successfully!")
    print(f"Location: {data_dir}")
    print("=" * 60)

if __name__ == '__main__':
    main()
