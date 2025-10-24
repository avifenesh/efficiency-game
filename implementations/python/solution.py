#!/usr/bin/env python3
"""
Python Concurrent Log Anomaly Counter - Optimized Version

Optimizations applied:
1. Binary mode I/O (eliminates UTF-8 encode/decode overhead)
2. Pre-converted byte constants (eliminates repeated encoding)
3. Optimized chunk size (20K lines for better load distribution)
4. Early exit on byte presence check
"""

import sys
import json
from multiprocessing import Pool, cpu_count
from pathlib import Path

# Pre-converted to bytes to avoid repeated encoding
ERROR_BYTES = b"ERROR"
WARN_BYTES = b"WARN"

def _is_alnum_byte(b: int) -> bool:
    """Check if byte is alphanumeric"""
    return (48 <= b <= 57) or (65 <= b <= 90) or (97 <= b <= 122)

def contains_word_bytes(line_bytes: bytes, word_bytes: bytes) -> bool:
    """Check if word exists with word boundaries in byte string"""
    n = len(word_bytes)
    m = len(line_bytes)
    if n == 0 or m < n:
        return False

    start = 0
    while True:
        idx = line_bytes.find(word_bytes, start)
        if idx == -1:
            return False

        before = idx - 1
        after = idx + n
        start_ok = before < 0 or not _is_alnum_byte(line_bytes[before])
        end_ok = after >= m or not _is_alnum_byte(line_bytes[after])

        if start_ok and end_ok:
            return True
        start = idx + 1

def count_anomalies_in_chunk(lines):
    """Process a chunk of byte lines and count ERROR/WARN occurrences"""
    errors = 0
    warnings = 0

    for line in lines:
        # Early exit optimization: check if byte exists before expensive boundary check
        if b'E' in line and contains_word_bytes(line, ERROR_BYTES):
            errors += 1
        elif b'W' in line and contains_word_bytes(line, WARN_BYTES):
            warnings += 1

    return errors, warnings

def process_log_file(filepath, chunk_size=20000):
    """Process log file using multiprocessing"""
    # Read file in binary mode (no UTF-8 decoding overhead)
    with open(filepath, 'rb') as f:
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
