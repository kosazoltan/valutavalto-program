#!/usr/bin/env python3
"""
blast-radius.py — Find all usages of a symbol across the project.

Usage:
  python scripts/dev-tools/blast-radius.py <symbol>
  python scripts/dev-tools/blast-radius.py <symbol> --ext java,ts,tsx
  python scripts/dev-tools/blast-radius.py <symbol> --module backend

Exit: 0 = found or not-found cleanly, 1 = tool error
"""
import sys
import os
import subprocess
from pathlib import Path
from collections import defaultdict

ROOT = Path(__file__).resolve().parent.parent.parent

IGNORED_DIRS = {"node_modules", ".git", "target", "dist", ".vite", "coverage",
                "tmp", "tmp-asar-extract", ".venv-asr", ".worktrees"}

DEFAULT_EXTS = ["java", "ts", "tsx"]


def rg_search(symbol: str, extensions: list[str], module_filter: str | None) -> list[str]:
    search_path = ROOT / module_filter if module_filter else ROOT
    type_args = []
    for ext in extensions:
        type_args += ["--glob", f"*.{ext}"]

    ignore_args = []
    for d in IGNORED_DIRS:
        ignore_args += ["--glob", f"!**/{d}/**"]

    cmd = [
        "rg",
        "--no-heading",
        "--line-number",
        "--color=never",
        "-e", symbol,
        str(search_path),
    ] + type_args + ignore_args

    result = subprocess.run(cmd, capture_output=True, text=True,
                            encoding="utf-8", errors="replace")
    if result.returncode not in (0, 1):
        # rg exit 2 = error
        print(f"rg error: {result.stderr.strip()[:200]}", file=sys.stderr)
        sys.exit(1)
    return result.stdout.strip().splitlines() if result.stdout.strip() else []


def group_by_module(lines: list[str]) -> dict[str, list[str]]:
    by_module: dict[str, list[str]] = defaultdict(list)
    # rg output on Windows: C:\path\to\file.ts:42:content
    # The path may contain ":" for the drive letter, so we split at most
    # at the first colon that is followed by a digit (the line number).
    import re as _re
    WIN_SPLIT = _re.compile(r'^(.+?):(\d+):(.*)$')
    for line in lines:
        m = WIN_SPLIT.match(line)
        if not m:
            by_module["?"].append(line)
            continue
        abs_path, lineno, content = m.group(1), m.group(2), m.group(3)
        try:
            rel = Path(abs_path).relative_to(ROOT)
            module = rel.parts[0] if len(rel.parts) > 1 else "."
            short = f"{rel}:{lineno}: {content.strip()}"
            by_module[module].append(short)
        except ValueError:
            by_module["?"].append(line)
    return dict(by_module)


def main():
    args = sys.argv[1:]
    if not args or args[0] in ("-h", "--help"):
        print(__doc__)
        sys.exit(0)

    symbol = args[0]
    extensions = DEFAULT_EXTS
    module_filter = None

    i = 1
    while i < len(args):
        if args[i] == "--ext" and i + 1 < len(args):
            extensions = [e.lstrip(".") for e in args[i + 1].split(",")]
            i += 2
        elif args[i] == "--module" and i + 1 < len(args):
            module_filter = args[i + 1]
            i += 2
        else:
            i += 1

    lines = rg_search(symbol, extensions, module_filter)

    if not lines:
        print(f"blast-radius '{symbol}': 0 usages found.")
        sys.exit(0)

    by_module = group_by_module(lines)
    total = len(lines)
    scope = f" in {module_filter}/" if module_filter else ""
    print(f"blast-radius '{symbol}'{scope}: {total} usage(s) across {len(by_module)} module(s)\n")

    shown = 0
    for module in sorted(by_module):
        module_lines = by_module[module]
        print(f"  [{module}] ({len(module_lines)} hit(s))")
        limit = min(10, 48 - shown)
        for ml in module_lines[:limit]:
            print(f"    {ml}")
            shown += 1
        if len(module_lines) > limit:
            print(f"    ... ({len(module_lines) - limit} more in this module)")
        if shown >= 48:
            remaining = total - shown
            if remaining > 0:
                print(f"\n  ... {remaining} more hit(s) — use --module to narrow scope")
            break


if __name__ == "__main__":
    main()
