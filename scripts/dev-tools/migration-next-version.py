#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
migration-next-version.py — Következő Flyway verziószám meghatározása.

Replaces: kézi max+1 számolás + V296-style ütközés megelőzés.

Usage:
  python scripts/dev-tools/migration-next-version.py
  python scripts/dev-tools/migration-next-version.py --sub   (pl. V299 → V299_1)
  python scripts/dev-tools/migration-next-version.py --check V305  (ütközés-ellenőrzés)

Exit: 0 = OK, 1 = conflict detected
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
from pathlib import Path

ROOT       = Path(__file__).resolve().parent.parent.parent
MIG_DIR    = ROOT / "backend" / "src" / "main" / "resources" / "db" / "migration"
VERSIONED  = re.compile(r'^V(\d+)(?:_(\d+))?__', re.IGNORECASE)


def load_versions() -> dict[int, list[tuple[int | None, str]]]:
    """Returns {major: [(minor_or_None, filename), ...]}"""
    versions: dict[int, list[tuple[int | None, str]]] = {}
    for f in MIG_DIR.glob("*.sql"):
        m = VERSIONED.match(f.name)
        if not m:
            continue
        major = int(m.group(1))
        minor = int(m.group(2)) if m.group(2) else None
        versions.setdefault(major, []).append((minor, f.name))
    return versions


def main():
    args      = sys.argv[1:]
    want_sub  = "--sub" in args
    check_ver = None

    i = 0
    while i < len(args):
        if args[i] == "--check" and i + 1 < len(args):
            check_ver = args[i + 1]; i += 2
        else:
            i += 1

    versions = load_versions()
    if not versions:
        print("No Flyway migrations found in", MIG_DIR)
        sys.exit(1)

    max_major = max(versions.keys())

    # ── Check mode ──────────────────────────────────────────────────────────
    if check_ver:
        m = re.match(r'^V?(\d+)(?:_(\d+))?$', check_ver, re.IGNORECASE)
        if not m:
            print(f"Invalid version: {check_ver}")
            sys.exit(1)
        major = int(m.group(1))
        minor = int(m.group(2)) if m.group(2) else None
        if major in versions:
            existing = versions[major]
            if minor is None:
                top_levels = [x for x in existing if x[0] is None]
                if top_levels:
                    print(f"CONFLICT: V{major} already exists: {top_levels[0][1]}")
                    sys.exit(1)
                else:
                    all_minors = [x[0] for x in existing if x[0] is not None]
                    print(f"CONFLICT: V{major} has sub-versions: {sorted(all_minors)}")
                    sys.exit(1)
            else:
                sub_clash = [x for x in existing if x[0] == minor]
                if sub_clash:
                    print(f"CONFLICT: V{major}_{minor} already exists: {sub_clash[0][1]}")
                    sys.exit(1)
        print(f"OK: V{'%d_%d' % (major, minor) if minor else major} is free")
        sys.exit(0)

    # ── Next version suggestion ──────────────────────────────────────────────
    next_major = max_major + 1

    if want_sub:
        # Sub-version of max_major (e.g. for hotfixes alongside main development)
        existing_subs = [x[0] for x in versions.get(max_major, []) if x[0] is not None]
        next_sub = max(existing_subs, default=0) + 1
        suggestion = f"V{max_major}_{next_sub}"
        print(f"Next sub-version:  {suggestion}__<description>.sql")
    else:
        suggestion = f"V{next_major}"
        print(f"Next version:      {suggestion}__<description>.sql")

    print(f"Current max:       V{max_major}  ({len(versions[max_major])} file(s))")
    print(f"Total migrations:  {sum(len(v) for v in versions.values())}")
    print()

    # Warn if there are gaps in the last 10 versions
    all_majors = sorted(versions.keys())
    recent = all_majors[-10:]
    gaps   = [recent[i+1] - recent[i] for i in range(len(recent)-1) if recent[i+1] - recent[i] > 1]
    if gaps:
        print(f"Note: version gaps in recent history: {gaps} — intentional?")

    sys.exit(0)


if __name__ == "__main__":
    main()
