#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
flyway-validate.py — Flyway migrációs fájlok helyi validálása.

Replaces: V296-style outage prevention + AI "duplicate migration" findings.

Ellenőrzi:
  - Verzióütközés (ugyanaz a V-prefix kétszer)
  - Elnevezési konvenció (V<num>__<desc>.sql vagy R__<desc>.sql)
  - Duplikált fájlnév
  - Nagy verzióugrás (>10, figyelmeztetés)
  - Üres leírás

Usage:
  python scripts/dev-tools/flyway-validate.py
  python scripts/dev-tools/flyway-validate.py --dir backend/src/main/resources/db/migration

Exit: 0 = OK, 1 = errors found
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
from pathlib import Path
from collections import defaultdict

ROOT         = Path(__file__).resolve().parent.parent.parent
DEFAULT_DIR  = ROOT / "backend" / "src" / "main" / "resources" / "db" / "migration"

VERSIONED    = re.compile(r'^V(\d+(?:_\d+)?)__(.+)\.sql$', re.IGNORECASE)
REPEATABLE   = re.compile(r'^R__(.+)\.sql$',                re.IGNORECASE)
UNDO         = re.compile(r'^U(\d+(?:_\d+)?)__(.+)\.sql$', re.IGNORECASE)


def parse_version(ver_str: str) -> tuple[int, ...]:
    return tuple(int(x) for x in ver_str.split("_"))


def main():
    args    = sys.argv[1:]
    mig_dir = DEFAULT_DIR

    i = 0
    while i < len(args):
        if args[i] == "--dir" and i + 1 < len(args):
            mig_dir = (ROOT / args[i + 1]).resolve()
            i += 2
        else:
            i += 1

    if not mig_dir.exists():
        print(f"Migration dir not found: {mig_dir}", file=sys.stderr)
        sys.exit(1)

    sql_files = sorted(mig_dir.glob("*.sql"))
    if not sql_files:
        print(f"No .sql files in {mig_dir}")
        sys.exit(0)

    errors:   list[str] = []
    warnings: list[str] = []

    by_version: dict[tuple, list[str]] = defaultdict(list)
    versioned_sorted: list[tuple[tuple, str]] = []
    seen_names: dict[str, str] = {}

    for f in sql_files:
        name = f.name

        # Duplicate filenames
        if name.lower() in seen_names:
            errors.append(f"Duplicate filename: {name} vs {seen_names[name.lower()]}")
        seen_names[name.lower()] = name

        vm = VERSIONED.match(name)
        rm = REPEATABLE.match(name)
        um = UNDO.match(name)

        if vm:
            ver   = parse_version(vm.group(1))
            desc  = vm.group(2)
            by_version[ver].append(name)
            versioned_sorted.append((ver, name))
            if not desc.strip():
                errors.append(f"Empty description: {name}")
        elif rm:
            pass  # repeatable scripts are always OK structurally
        elif um:
            pass  # undo scripts accepted
        else:
            errors.append(f"Invalid naming convention: {name}  (expected V<num>__<desc>.sql or R__<desc>.sql)")

    # Duplicate versions
    for ver, files in by_version.items():
        if len(files) > 1:
            ver_str = "_".join(str(v) for v in ver)
            errors.append(f"DUPLICATE VERSION V{ver_str}: {', '.join(files)}")

    # Version gaps / large jumps
    sorted_vers = sorted(by_version.keys())
    for idx in range(1, len(sorted_vers)):
        prev = sorted_vers[idx - 1]
        curr = sorted_vers[idx]
        if len(prev) == 1 and len(curr) == 1:
            gap = curr[0] - prev[0]
            if gap > 10:
                warnings.append(
                    f"Large version gap: V{prev[0]} -> V{curr[0]} (gap={gap}) -- intentional?"
                )

    # Summary
    total = len(sql_files)
    versioned_count = len(versioned_sorted)
    repeatable_count = sum(1 for f in sql_files if REPEATABLE.match(f.name))

    print(f"flyway-validate: {total} files  ({versioned_count} versioned, {repeatable_count} repeatable)\n")

    if warnings:
        for w in warnings:
            print(f"  ⚠  {w}")
        print()

    if errors:
        for e in errors:
            print(f"  ✗  {e}")
        print(f"\nFAILED: {len(errors)} error(s)")
        sys.exit(1)

    print(f"  Version range: V{sorted_vers[0][0] if sorted_vers else '?'} -> V{sorted_vers[-1][0] if sorted_vers else '?'}")
    print("  OK — no naming conflicts or duplicate versions")
    sys.exit(0)


if __name__ == "__main__":
    main()
