#!/usr/bin/env python3
"""
Update web/index.html with all benchmark results from data/results-*.json files
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
    data_dir = project_root / 'data'
    html_file = project_root / 'web' / 'index.html'

    # Load all available result files
    sizes = ["small", "medium", "large"]
    all_datasets = {}
    
    for size in sizes:
        results_file = data_dir / f'results-{size}.json'
        if results_file.exists():
            print(f"Reading {size} results from: {results_file}")
            with open(results_file, 'r') as f:
                results_data = json.load(f)
            
            # Augment metadata with helpful fields for the UI
            metadata = results_data.get("metadata", {})
            line_count = load_line_count(project_root, size)
            if line_count is not None:
                metadata["line_count"] = line_count
                results_data["metadata"] = metadata
            
            all_datasets[size] = results_data
            num_languages = len(results_data.get('languages', {}))
            print(f"  ✓ Loaded {num_languages} languages for {size} dataset")
        else:
            print(f"  ⚠ Skipping {size}: file not found")

    if not all_datasets:
        print("Error: No results files found")
        return 1

    # Read HTML
    print(f"\nReading HTML from: {html_file}")
    with open(html_file, 'r') as f:
        html_content = f.read()

    # Update BENCHMARK_DATASETS
    datasets_pattern = r'(window\.BENCHMARK_DATASETS\s*=\s*)(\{[\s\S]*?\})(\s*;)'
    datasets_match = re.search(datasets_pattern, html_content)
    
    if not datasets_match:
        print("Error: Could not find BENCHMARK_DATASETS pattern in HTML")
        return 1

    prefix, _, suffix = datasets_match.groups()
    
    # Create the replacement JSON
    replacement_json = json.dumps(all_datasets, indent=2)
    replacement = f"{prefix}{replacement_json}{suffix}"
    
    updated_html = (
        html_content[: datasets_match.start()]
        + replacement
        + html_content[datasets_match.end():]
    )

    # Write updated HTML
    print(f"Updating HTML file...")
    with open(html_file, 'w') as f:
        f.write(updated_html)

    print(f"\n✓ Successfully updated web page with {len(all_datasets)} dataset sizes")
    for size, data in all_datasets.items():
        num_langs = len(data.get('languages', {}))
        timestamp = data['metadata'].get('timestamp', 'unknown')
        print(f"  • {size}: {num_langs} languages ({timestamp})")
    print(f"  Location: {html_file}")

    return 0


if __name__ == '__main__':
    exit(main())
