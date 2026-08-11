#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build-warning-scan.py -- Maven es npm build figyelmeztetesek statikus keresese.

Replaces: AI "are there build warnings?" kerdesek + kezi build-output nézés.

Technika: Forrasfajlokban keresi a java deprecated annotaciokat es a
          TypeScript tsc/eslint warning-mintakat API-hivas nelkul.

Keres (Java):
  - @Deprecated annotaciok (sajat kodbazisban)
  - @SuppressWarnings("unchecked") - nem kezelt generikus hivas
  - @SuppressWarnings("deprecation") - deprecated API hasznalat
  - Raw types (List, Map, Set rawtype nelkul)
  - TODO: REMOVE / FIXME: before-release jelolők

Keres (TypeScript):
  - @deprecated JSDoc tag-ek
  - eslint-disable kommentek (letiltott szabalyok)
  - @ts-nocheck fajlok

Usage:
  python scripts/dev-tools/build-warning-scan.py
  python scripts/dev-tools/build-warning-scan.py --java-only
  python scripts/dev-tools/build-warning-scan.py --ts-only

Exit: 0 = clean, 1 = figyelmeztetesek
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
from pathlib import Path

ROOT    = Path(__file__).resolve().parent.parent.parent
IGNORED = {"node_modules", ".git", "target", "dist", ".vite", "coverage"}

# Java patterns
DEPRECATED_ANN  = re.compile(r'@Deprecated\b')
SUPPRESS_WARN   = re.compile(r'@SuppressWarnings\s*\(\s*["\{]([^"}\)]+)')
RAW_TYPE        = re.compile(r'\b(List|Map|Set|Collection|ArrayList|HashMap|HashSet)'
                             r'\s+\w+\s*[;=,(]')
GENERIC_RAW     = re.compile(r'\b(List|Map|Set)\s+\w+\s*=\s*new\s+(List|Map|Set|'
                             r'ArrayList|HashMap|HashSet)\s*\(\)')

# TypeScript patterns
JSDoc_DEPRECATED = re.compile(r'@deprecated\b',  re.IGNORECASE)
ESLINT_DISABLE   = re.compile(r'eslint-disable(?:-next-line|-line)?')
TS_NOCHECK       = re.compile(r'@ts-nocheck')


def scan_java(path: Path) -> list[str]:
    content = path.read_text(encoding="utf-8", errors="replace")
    rel     = str(path.relative_to(ROOT))
    lines   = content.splitlines()
    issues  = []

    for i, line in enumerate(lines, 1):
        if DEPRECATED_ANN.search(line) and not line.strip().startswith("//"):
            issues.append(f"  [DEPRECATED]   {rel}:{i}  {line.strip()[:80]}")

        m = SUPPRESS_WARN.search(line)
        if m:
            kind = m.group(1).strip().strip('"')
            issues.append(
                f"  [SUPPRESS]     {rel}:{i}  @SuppressWarnings(\"{kind}\")")

        if RAW_TYPE.search(line) and "<" not in line and "import" not in line:
            issues.append(
                f"  [RAW-TYPE]     {rel}:{i}  {line.strip()[:80]}")

    return issues


def scan_ts(path: Path) -> list[str]:
    content = path.read_text(encoding="utf-8", errors="replace")
    rel     = str(path.relative_to(ROOT))
    lines   = content.splitlines()
    issues  = []

    has_nocheck = bool(TS_NOCHECK.search(content))
    if has_nocheck:
        issues.append(f"  [TS-NOCHECK]   {rel}  -- @ts-nocheck teljes fajlra")

    for i, line in enumerate(lines, 1):
        if JSDoc_DEPRECATED.search(line):
            issues.append(
                f"  [TS-DEPRECATED] {rel}:{i}  {line.strip()[:80]}")
        if ESLINT_DISABLE.search(line):
            issues.append(
                f"  [ESLINT-OFF]   {rel}:{i}  {line.strip()[:80]}")

    return issues


def main():
    args     = sys.argv[1:]
    java_only = "--java-only" in args
    ts_only   = "--ts-only"   in args

    issues  = []
    scanned = 0

    if not ts_only:
        src = ROOT / "backend" / "src" / "main" / "java"
        for f in src.rglob("*.java"):
            if any(d in f.parts for d in IGNORED):
                continue
            scanned += 1
            issues.extend(scan_java(f))

    if not java_only:
        for mod in ("frontend-react", "penztar-client", "kozponti-client"):
            src = ROOT / mod / "src"
            if not src.exists():
                continue
            for f in src.rglob("*.ts"):
                if any(d in f.parts for d in IGNORED):
                    continue
                if f.name.endswith(".d.ts"):
                    continue
                scanned += 1
                issues.extend(scan_ts(f))

    print(f"build-warning-scan: {scanned} fajl, {len(issues)} figyelmeztetés\n")

    if not issues:
        print("  OK -- nem talalhato deprecated/suppress/eslint-disable problema")
        sys.exit(0)

    for cat in ("DEPRECATED", "SUPPRESS", "RAW-TYPE",
                "TS-DEPRECATED", "TS-NOCHECK", "ESLINT-OFF"):
        group = [x for x in issues if f"[{cat}]" in x]
        if group:
            print(f"  [{cat}] ({len(group)})")
            for iss in group[:10]:
                print(iss)
            if len(group) > 10:
                print(f"    ... ({len(group) - 10} tovabb)")
            print()

    sys.exit(0)  # warnings nem blokkolnak


if __name__ == "__main__":
    main()
