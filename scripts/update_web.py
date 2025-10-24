#!/usr/bin/env python3
"""
Update web/index.html with latest benchmark results from data/results.json
"""

import json
import re
from pathlib import Path

def main():
    # Paths
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    results_file = project_root / 'data' / 'results.json'
    html_file = project_root / 'web' / 'index.html'

    # Check if results file exists
    if not results_file.exists():
        print(f"Error: Results file not found: {results_file}")
        return 1

    # Read results
    print(f"Reading results from: {results_file}")
    with open(results_file, 'r') as f:
        results_data = json.load(f)

    # Read HTML
    print(f"Reading HTML from: {html_file}")
    with open(html_file, 'r') as f:
        html_content = f.read()

    # Format the results as JavaScript object (pretty printed)
    results_js = json.dumps(results_data, indent=2)

    # Pattern to match the embedded BENCHMARK_DATA
    pattern = r'(window\.BENCHMARK_DATA = )({[\s\S]*?});'

    # Replace with new data
    replacement = f'window.BENCHMARK_DATA = {results_js};'
    updated_html = re.sub(pattern, replacement, html_content)

    # Check if replacement happened
    if updated_html == html_content:
        print("Warning: Could not find BENCHMARK_DATA pattern in HTML")
        return 1

    # Write updated HTML
    print(f"Updating HTML file...")
    with open(html_file, 'w') as f:
        f.write(updated_html)

    # Count languages
    num_languages = len(results_data.get('languages', {}))
    print(f"✓ Successfully updated web page with {num_languages} languages")
    print(f"  Timestamp: {results_data['metadata']['timestamp']}")
    print(f"  Location: {html_file}")

    return 0

if __name__ == '__main__':
    exit(main())
