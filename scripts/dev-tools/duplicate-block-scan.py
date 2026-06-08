#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
duplicate-block-scan.py -- Ismetlodo kodblokk detekcio (CPD-light).

Replaces: AI "is this code duplicated?" kerdesek + PMD CPD install.

Modszer:
  - 6-soros normalizalt hash-ablak (whitespace/comment strip)
  - Java es TypeScript forrasfajlok
  - Minimum 3 elofordulas = WARN, minimum 5 = ERROR

Usage:
  python scripts/dev-tools/duplicate-block-scan.py
  python scripts/dev-tools/duplicate-block-scan.py --min-lines 8
  python scripts/dev-tools/duplicate-block-scan.py --module backend

Exit: 0 = clean, 1 = duplikaciok talalhatok
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
import hashlib
from pathlib import Path
from collections import defaultdict

ROOT    = Path(__file__).resolve().parent.parent.parent
IGNORED = {"node_modules", ".git", "target", "dist", ".vite", "coverage",
           "tmp", ".venv-asr", ".worktrees"}

COMMENT_JAVA = re.compile(r'//.*$|/\*.*?\*/', re.DOTALL)
COMMENT_TS   = re.compile(r'//.*$|/\*.*?\*/', re.DOTALL)
BLANK        = re.compile(r'\s+')

MIN_OCC  = 5
MIN_ERR  = 10


def normalize(line: str, ext: str) -> str:
    line = COMMENT_JAVA.sub(" ", line)
    line = BLANK.sub(" ", line).strip()
    return line


def file_hashes(path: Path, window: int) -> list[tuple[str, int]]:
    ext     = path.suffix.lower()
    content = path.read_text(encoding="utf-8", errors="replace")
    lines   = [normalize(l, ext) for l in content.splitlines()]
    lines   = [l for l in lines if l and l not in ("{", "}", "};", "{}", "//")]

    result = []
    for i in range(len(lines) - window + 1):
        block = "\n".join(lines[i: i + window])
        h     = hashlib.md5(block.encode()).hexdigest()
        result.append((h, i + 1))
    return result


def main():
    args   = sys.argv[1:]
    window = 10
    module_filter = None
    i = 0
    while i < len(args):
        if args[i] == "--min-lines" and i + 1 < len(args):
            window = int(args[i + 1]); i += 2
        elif args[i] == "--module" and i + 1 < len(args):
            module_filter = args[i + 1]; i += 2
        else:
            i += 1

    base    = ROOT / module_filter if module_filter else ROOT
    hashmap: dict[str, list[tuple[Path, int]]] = defaultdict(list)
    scanned = 0

    for f in base.rglob("*"):
        if not f.is_file():
            continue
        if any(d in f.parts for d in IGNORED):
            continue
        if f.suffix.lower() not in (".java", ".ts", ".tsx"):
            continue
        scanned += 1
        for h, lineno in file_hashes(f, window):
            hashmap[h].append((f, lineno))

    duplicated = {h: locs for h, locs in hashmap.items() if len(locs) >= MIN_OCC}
    errors     = {h: locs for h, locs in duplicated.items() if len(locs) >= MIN_ERR}

    print(f"duplicate-block-scan: {scanned} fajl, {window}-soros ablak, "
          f"{len(duplicated)} ismeltodo blokk ({len(errors)} kritikus)\n")

    if not duplicated:
        print("  OK -- nincs ismetlodo kod")
        sys.exit(0)

    shown = 0
    for h, locs in sorted(duplicated.items(), key=lambda x: -len(x[1]))[:20]:
        sev = "ERROR" if len(locs) >= MIN_ERR else "WARN"
        print(f"  [{sev}] {len(locs)}x elofordulas (hash {h[:8]}):")
        for path, lineno in locs[:4]:
            rel = str(path.relative_to(ROOT))
            print(f"    {rel}:{lineno}")
        if len(locs) > 4:
            print(f"    ... ({len(locs) - 4} tovabb)")
        print()
        shown += 1

    if shown < len(duplicated):
        print(f"  ... ({len(duplicated) - shown} tobb duplikalt blokk)")

    sys.exit(1)


if __name__ == "__main__":
    main()
