#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
god-class-scan.py -- God Class / God Service anti-minta detektalasa.

Replaces: AI "is this class too big?" refactoring tanacs + SonarQube.

Technika: forras-metrika: metodusszam, mezo-szam, import-szam, sorszam.

Hatarertek (konfiguralhatoak):
  - >20 nyilvanos metodus
  - >15 privat mezo
  - >25 import (magas csuatoltsag)
  - >800 sor (fizikailag tul nagy osztaly)
  - >10 @Autowired / @Inject (dependency hell)

Usage:
  python scripts/dev-tools/god-class-scan.py
  python scripts/dev-tools/god-class-scan.py --methods 15 --fields 10

Exit: 0 = clean, 1 = God Class talalhato
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
from pathlib import Path

ROOT    = Path(__file__).resolve().parent.parent.parent
IGNORED = {"node_modules", ".git", "target", "dist"}

METHOD_PUB  = re.compile(r'^\s+public\s+(?!class|interface|static\s+class)\S+\s+\w+\s*\(')
FIELD_PRIV  = re.compile(r'^\s+private\s+(?!class|interface|static\s+class)\S+\s+\w+\s*[;=]')
IMPORT_LINE = re.compile(r'^\s*import\s+')
INJECT_LINE = re.compile(r'@(Autowired|Inject|Value)\b')
CLASS_DECL  = re.compile(r'\bclass\s+(\w+)')


THRESHOLDS = {
    "methods":  20,
    "fields":   15,
    "imports":  25,
    "lines":    800,
    "injects":  10,
}


def scan_file(path: Path, thresholds: dict) -> list[str]:
    content = path.read_text(encoding="utf-8", errors="replace")
    lines   = content.splitlines()
    rel     = str(path.relative_to(ROOT))
    issues  = []

    cls = CLASS_DECL.search(content)
    cls_name = cls.group(1) if cls else path.stem

    methods = sum(1 for l in lines if METHOD_PUB.match(l))
    fields  = sum(1 for l in lines if FIELD_PRIV.match(l))
    imports = sum(1 for l in lines if IMPORT_LINE.match(l))
    injects = sum(1 for l in lines if INJECT_LINE.search(l))
    total   = len(lines)

    if methods > thresholds["methods"]:
        issues.append(
            f"  [METHODS]  {rel}  {cls_name}: {methods} publikus metodus "
            f"(>{thresholds['methods']})")
    if fields > thresholds["fields"]:
        issues.append(
            f"  [FIELDS]   {rel}  {cls_name}: {fields} privat mezo "
            f"(>{thresholds['fields']})")
    if imports > thresholds["imports"]:
        issues.append(
            f"  [IMPORTS]  {rel}  {cls_name}: {imports} import "
            f"(>{thresholds['imports']}, magas csuatoltsag)")
    if total > thresholds["lines"]:
        issues.append(
            f"  [LINES]    {rel}  {cls_name}: {total} sor "
            f"(>{thresholds['lines']})")
    if injects > thresholds["injects"]:
        issues.append(
            f"  [INJECTS]  {rel}  {cls_name}: {injects} injekcios mezo "
            f"(>{thresholds['injects']}, dependency hell)")

    return issues


def main():
    args = sys.argv[1:]
    thresholds = dict(THRESHOLDS)
    i = 0
    while i < len(args):
        for key in thresholds:
            if args[i] == f"--{key}" and i + 1 < len(args):
                thresholds[key] = int(args[i + 1]); i += 2; break
        else:
            i += 1

    issues  = []
    scanned = 0

    src = ROOT / "backend" / "src" / "main" / "java"
    for f in src.rglob("*.java"):
        if any(d in f.parts for d in IGNORED):
            continue
        scanned += 1
        issues.extend(scan_file(f, thresholds))

    print(f"god-class-scan: {scanned} Java osztaly vizsgalva, {len(issues)} God Class jel\n")

    if not issues:
        print("  OK -- nincs God Class anti-minta")
        sys.exit(0)

    for cat in ("METHODS", "FIELDS", "IMPORTS", "LINES", "INJECTS"):
        group = [x for x in issues if f"  [{cat}]" in x]
        if group:
            print(f"  [{cat}] ({len(group)})")
            for iss in group[:10]:
                print(iss)
            if len(group) > 10:
                print(f"    ... ({len(group) - 10} tovabb)")
            print()

    sys.exit(1)


if __name__ == "__main__":
    main()
