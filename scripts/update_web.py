#!/usr/bin/env python3
"""
Update web/index.html with latest benchmark results from data/results.json
"""

import json
import re
from pathlib import Path


def load_line_count(project_root: Path, log_size: str) -> int | None:
    """Return the number of lines for the dataset size, if available."""
    if not log_size:
        return None

    log_path = project_root / "data" / "synthetic" / f"{log_size.lower()}.log"
    if not log_path.exists():
        return None

    try:
        with log_path.open("r", encoding="utf-8", errors="ignore") as handle:
            return sum(1 for _ in handle)
    except OSError:
        return None

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

    # Augment metadata with helpful fields for the UI
    metadata = results_data.get("metadata", {})
    log_size = metadata.get("log_size", "").lower()
    line_count = load_line_count(project_root, log_size)
    if line_count is not None:
        metadata["line_count"] = line_count
        results_data["metadata"] = metadata

    # Read HTML
    print(f"Reading HTML from: {html_file}")
    with open(html_file, 'r') as f:
        html_content = f.read()

    # Format the results as JavaScript object (pretty printed)
    results_js = json.dumps(results_data, indent=2)

    updated_html = html_content
    replaced = False

    # Pattern to match the embedded BENCHMARK_DATA
    single_pattern = r'(window\.BENCHMARK_DATA\s*=\s*)(\{[\s\S]*?\})(\s*;)'
    single_match = re.search(single_pattern, html_content)
    if single_match:
        prefix, _, suffix = single_match.groups()
        replacement = f"{prefix}{results_js}{suffix}"
        updated_html = (
            html_content[: single_match.start()]
            + replacement
            + html_content[single_match.end():]
        )
        replaced = True
    else:
        # Attempt to update BENCHMARK_DATASETS
        datasets_pattern = r'(window\.BENCHMARK_DATASETS\s*=\s*)(\{[\s\S]*?\})(\s*;)'
        datasets_match = re.search(datasets_pattern, html_content)
        if datasets_match:
            prefix, datasets_json, suffix = datasets_match.groups()
            try:
                datasets_data = json.loads(datasets_json)
            except json.JSONDecodeError as exc:
                print(f"Error: Could not parse embedded datasets JSON: {exc}")
                return 1

            if not log_size:
                log_size = next(iter(datasets_data.keys()), "medium")

            datasets_data[log_size] = results_data
            replacement_json = json.dumps(datasets_data, indent=2)
            replacement = f"{prefix}{replacement_json}{suffix}"
            updated_html = (
                html_content[: datasets_match.start()]
                + replacement
                + html_content[datasets_match.end():]
            )
            replaced = True

    if not replaced:
        print("Warning: Could not find BENCHMARK_DATA or BENCHMARK_DATASETS pattern in HTML")
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
