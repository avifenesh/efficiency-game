#!/usr/bin/env python3
"""
Python Concurrent Log Anomaly Counter
Uses multiprocessing for parallel processing of log chunks
"""

import sys
import json
from multiprocessing import Pool, cpu_count
from pathlib import Path

def _is_alnum_byte(b: int) -> bool:
    return (48 <= b <= 57) or (65 <= b <= 90) or (97 <= b <= 122)

def contains_word(line: str, word: str) -> bool:
    lb = line.encode('utf-8', errors='ignore')
    wb = word.encode('ascii')
    n = len(wb)
    m = len(lb)
    if n == 0 or m < n:
        return False
    start = 0
    while True:
        idx = lb.find(wb, start)
        if idx == -1:
            return False
        before = idx - 1
        after = idx + n
        start_ok = before < 0 or not _is_alnum_byte(lb[before])
        end_ok = after >= m or not _is_alnum_byte(lb[after])
        if start_ok and end_ok:
            return True
        start = idx + 1

def count_anomalies_in_chunk(lines):
    """Process a chunk of lines and count ERROR/WARN occurrences"""
    errors = 0
    warnings = 0
    for line in lines:
        if contains_word(line, "ERROR"):
            errors += 1
        elif contains_word(line, "WARN"):
            warnings += 1
    return errors, warnings

def process_log_file(filepath, chunk_size=10000):
    """Process log file using multiprocessing"""
    # Read file and split into chunks
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    # Create chunks for parallel processing
    chunks = []
    for i in range(0, len(lines), chunk_size):
        chunk = lines[i:i + chunk_size]
        chunks.append(chunk)
    
    # Process chunks in parallel
    num_processes = cpu_count()
    with Pool(processes=num_processes) as pool:
        results = pool.map(count_anomalies_in_chunk, chunks)
    
    # Aggregate results
    total_errors = sum(r[0] for r in results)
    total_warnings = sum(r[1] for r in results)
    
    return total_errors, total_warnings

def main():
    if len(sys.argv) != 2:
        print("Usage: python solution.py <logfile>", file=sys.stderr)
        sys.exit(1)
    
    logfile = sys.argv[1]
    
    if not Path(logfile).exists():
        print(f"Error: File not found: {logfile}", file=sys.stderr)
        sys.exit(1)
    
    errors, warnings = process_log_file(logfile)
    total = errors + warnings
    
    # Output JSON format as specified
    result = {
        "errors": errors,
        "warnings": warnings,
        "total": total
    }
    
    print(json.dumps(result))
    sys.exit(0)

if __name__ == '__main__':
    main()
