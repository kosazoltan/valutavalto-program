#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
react-complexity-scan.py -- React komponens komplexitas elemzes.

Replaces: AI "is this component too complex?" felulvizsgalat.

Technika: .tsx fajl regex elemzes, hook-szamlalás, JSX melyseg.

Keres:
  - useState > 5 / komponens (tulzott allapotkezeles)
  - useEffect > 3 / komponens (mellekhatás-tul-zas)
  - Props szama > 7 (prop explosion)
  - useCallback / useMemo > 5 (premature optimization vagy val. bonyolult)
  - JSX melyseg > 6 szint
  - Komponens > 200 sor

Usage:
  python scripts/dev-tools/react-complexity-scan.py
  python scripts/dev-tools/react-complexity-scan.py --module penztar-client

Exit: 0 = clean, 1 = tul komplex komponensek
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
from pathlib import Path

ROOT    = Path(__file__).resolve().parent.parent.parent
IGNORED = {"node_modules", ".git", "dist", ".vite", "coverage"}

USE_STATE    = re.compile(r'\buseState\s*[(<]')
USE_EFFECT   = re.compile(r'\buseEffect\s*\(')
USE_CALLBACK = re.compile(r'\buseCallback\s*\(')
USE_MEMO     = re.compile(r'\buseMemo\s*\(')
PROPS_SIG    = re.compile(r'(?:function\s+\w+|const\s+\w+\s*=)\s*\(\s*\{([^}]+)\}')
COMP_DECL    = re.compile(r'^(?:export\s+)?(?:default\s+)?(?:function|const)\s+([A-Z]\w+)')
JSX_OPEN     = re.compile(r'<[A-Za-z]\w*(?:\s|>|/)')


def count_jsx_depth(lines: list[str]) -> int:
    depth = 0
    max_d = 0
    for line in lines:
        depth += line.count("<") - line.count("</") - line.count("/>")
        max_d = max(max_d, depth)
    return max_d


def scan_file(path: Path) -> list[str]:
    content = path.read_text(encoding="utf-8", errors="replace")
    if not JSX_OPEN.search(content):
        return []

    rel    = str(path.relative_to(ROOT))
    lines  = content.splitlines()
    issues = []

    # Find component start lines
    for i, line in enumerate(lines):
        m = COMP_DECL.match(line)
        if not m:
            continue
        comp_name = m.group(1)

        # Collect component body (until next top-level export or EOF)
        j = i + 1
        depth = 0
        comp_lines = [line]
        started = False
        while j < len(lines):
            comp_lines.append(lines[j])
            depth += lines[j].count("{") - lines[j].count("}")
            if lines[j].strip().startswith("{"):
                started = True
            if started and depth <= 0:
                break
            # Stop at next top-level export
            if j > i + 3 and COMP_DECL.match(lines[j]) and lines[j].startswith("export"):
                break
            j += 1

        body = "\n".join(comp_lines)

        states     = len(USE_STATE.findall(body))
        effects    = len(USE_EFFECT.findall(body))
        callbacks  = len(USE_CALLBACK.findall(body))
        memos      = len(USE_MEMO.findall(body))
        jsx_depth  = count_jsx_depth(comp_lines)
        comp_len   = len([l for l in comp_lines if l.strip()])

        # Props count
        props_m = PROPS_SIG.search(line + (lines[i + 1] if i + 1 < len(lines) else ""))
        props_count = 0
        if props_m:
            props_count = len([p.strip() for p in props_m.group(1).split(",") if p.strip()])

        lineno = i + 1
        if states > 5:
            issues.append(
                f"  [STATE-HEAVY]  {rel}:{lineno}  {comp_name}: "
                f"{states} useState (>5)")
        if effects > 3:
            issues.append(
                f"  [EFFECT-HEAVY] {rel}:{lineno}  {comp_name}: "
                f"{effects} useEffect (>3)")
        if props_count > 7:
            issues.append(
                f"  [PROP-HEAVY]   {rel}:{lineno}  {comp_name}: "
                f"{props_count} prop (>7)")
        if callbacks + memos > 5:
            issues.append(
                f"  [MEMO-HEAVY]   {rel}:{lineno}  {comp_name}: "
                f"{callbacks + memos} useCallback/useMemo (>5)")
        if jsx_depth > 6:
            issues.append(
                f"  [JSX-DEEP]     {rel}:{lineno}  {comp_name}: "
                f"JSX melyseg ~{jsx_depth} (>6)")
        if comp_len > 200:
            issues.append(
                f"  [LONG-COMP]    {rel}:{lineno}  {comp_name}: "
                f"{comp_len} sor (>200)")

    return issues


def main():
    args = sys.argv[1:]
    mod_filter = None
    i = 0
    while i < len(args):
        if args[i] == "--module" and i + 1 < len(args):
            mod_filter = args[i + 1]; i += 2
        else:
            i += 1

    modules = (["frontend-react", "penztar-client", "kozponti-client",
                "arfolyam-keszito-client"]
               if not mod_filter else [mod_filter])

    all_issues = []
    for mod in modules:
        src = ROOT / mod / "src"
        if not src.exists():
            continue
        for f in src.rglob("*.tsx"):
            if any(d in f.parts for d in IGNORED):
                continue
            if any(s in f.name for s in (".test.", ".spec.", ".stories.")):
                continue
            all_issues.extend(scan_file(f))

    print(f"react-complexity-scan: {len(all_issues)} komplexitas problema\n")

    if not all_issues:
        print("  OK -- React komponensek komplexitasa rendben")
        sys.exit(0)

    for cat in ("STATE-HEAVY", "EFFECT-HEAVY", "PROP-HEAVY",
                "MEMO-HEAVY", "JSX-DEEP", "LONG-COMP"):
        group = [x for x in all_issues if f"[{cat}]" in x]
        if group:
            print(f"  [{cat}] ({len(group)})")
            for iss in group[:8]:
                print(iss)
            if len(group) > 8:
                print(f"    ... ({len(group) - 8} tovabb)")
            print()

    sys.exit(1)


if __name__ == "__main__":
    main()
