#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
mapper-audit.py -- MapStruct es kezzel irt mapper teljessegellenorzese.

Replaces: AI "are all fields mapped?" kerdesek.

Keres:
  - @Mapper annotalt interfeszek / abstract osztályok
  - @Mapping(target=...) deklaraciok
  - Ignoralt mezok (@Mapping(target="...", ignore=true))
  - Tobb ignoralt mezo = potencialis adatvesztes
  - Bemeneti parameter nelkuli mapping metodusok

Usage:
  python scripts/dev-tools/mapper-audit.py
  python scripts/dev-tools/mapper-audit.py --module backend

Exit: 0 = clean, 1 = potencialis problemak
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
from pathlib import Path

ROOT    = Path(__file__).resolve().parent.parent.parent

MAPPER_ANN    = re.compile(r'@Mapper\b')
METHOD_SIG    = re.compile(r'^\s+\w[\w<>, ]+\s+(\w+)\s*\(([^)]*)\)\s*[{;]')
MAPPING_ANN   = re.compile(r'@Mapping\s*\(')
IGNORE_ANN    = re.compile(r'@Mapping\s*\([^)]*ignore\s*=\s*true', re.I)
TARGET_FIELD  = re.compile(r'target\s*=\s*"([^"]+)"')
CLASS_DECL    = re.compile(r'\b(?:interface|class)\s+(\w+)')

SKIP_METHODS  = {"toString", "hashCode", "equals", "clone",
                 "getClass", "notify", "wait"}
IGNORED = {"node_modules", ".git", "target", "dist"}


def scan_file(path: Path) -> list[str]:
    content = path.read_text(encoding="utf-8", errors="replace")
    if not MAPPER_ANN.search(content):
        return []

    rel    = str(path.relative_to(ROOT))
    issues = []

    # Class/interface name
    cls = CLASS_DECL.search(content)
    cls_name = cls.group(1) if cls else path.stem

    lines        = content.splitlines()
    pending_maps = []
    pending_ignores = []

    for i, line in enumerate(lines):
        if MAPPING_ANN.search(line):
            t = TARGET_FIELD.search(line)
            if t:
                pending_maps.append(t.group(1))
            if IGNORE_ANN.search(line):
                t2 = TARGET_FIELD.search(line)
                if t2:
                    pending_ignores.append(t2.group(1))
        m = METHOD_SIG.match(line)
        if m:
            method = m.group(1)
            params = m.group(2).strip()
            if method in SKIP_METHODS:
                pending_maps = []; pending_ignores = []
                continue
            # Method with no source parameter (converter, factory — OK if explicit)
            if not params and pending_maps:
                issues.append(f"  [NO-SOURCE]  {rel}  {cls_name}.{method}() -- nincs bemeneti parameter")
            # Many ignored fields
            if len(pending_ignores) >= 3:
                issues.append(f"  [MANY-IGNORE]  {rel}  {cls_name}.{method}() -- "
                              f"{len(pending_ignores)} ignore: {', '.join(pending_ignores[:5])}")
            pending_maps = []; pending_ignores = []

    return issues


def main():
    args = sys.argv[1:]
    module_filter = None
    i = 0
    while i < len(args):
        if args[i] == "--module" and i + 1 < len(args):
            module_filter = args[i + 1]; i += 2
        else:
            i += 1

    base   = ROOT / module_filter if module_filter else ROOT
    issues = []

    for f in base.rglob("*.java"):
        if any(d in f.parts for d in IGNORED):
            continue
        issues.extend(scan_file(f))

    print(f"mapper-audit: {len(issues)} potencialis mapper problema\n")

    if not issues:
        print("  OK -- mapper-ek rendben")
        sys.exit(0)

    for iss in issues:
        print(iss)

    sys.exit(1)


if __name__ == "__main__":
    main()
