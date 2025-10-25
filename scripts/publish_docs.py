#!/usr/bin/env python3
"""Synchronise the static dashboard into docs/ for GitHub Pages."""

import shutil
from pathlib import Path


def main() -> int:
    project_root = Path(__file__).resolve().parent.parent
    web_dir = project_root / "web"
    docs_dir = project_root / "docs"

    if not web_dir.exists():
        print(f"Error: web directory not found: {web_dir}")
        return 1

    if docs_dir.exists():
        print(f"Removing existing docs directory: {docs_dir}")
        shutil.rmtree(docs_dir)

    print(f"Copying {web_dir} → {docs_dir}")
    shutil.copytree(web_dir, docs_dir)

    print("✓ GitHub Pages bundle updated")
    print("  Tip: run 'python3 -m http.server' inside docs/ to preview the hosted site.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
