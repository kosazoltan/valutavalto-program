#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ts-antipattern-scan.py -- TypeScript típusbiztonság anti-pattern detektálás.

Replaces: AI "@typescript-eslint/no-explicit-any" + type safety review findings.

Keres:
  - : any  explicit any típusok
  - as any  típus-cast any-re
  - !  non-null assertion operator (overuse)
  - @ts-ignore / @ts-nocheck
  - Object típus (bármilyen alak nélkül)
  - Funkció visszatérési típus hiánya (exported functions)

Usage:
  python scripts/dev-tools/ts-antipattern-scan.py
  python scripts/dev-tools/ts-antipattern-scan.py --module frontend-react

Exit: 0 = clean, 1 = issues found
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
from pathlib import Path

ROOT     = Path(__file__).resolve().parent.parent.parent
IGNORED  = {"node_modules", ".git", "target", "dist", ".vite", "coverage",
            "tmp", ".venv-asr", ".worktrees"}

PATTERNS = [
    ("ANY-TYPE",       re.compile(r':\s*any\b'),             "explicit 'any' type"),
    ("ANY-CAST",       re.compile(r'\bas\s+any\b'),          "'as any' cast"),
    ("TS-IGNORE",      re.compile(r'@ts-ignore|@ts-nocheck'), "@ts-ignore / @ts-nocheck"),
    ("NON-NULL-BANG",  re.compile(r'\w!\.\w|\w![\[;,)\s]'),  "non-null assertion (!)"),
    ("OBJECT-TYPE",    re.compile(r':\s*Object\b'),          ": Object type (use specific interface)"),
]

EXPORT_FN_NO_RET = re.compile(
    r'^export\s+(?:async\s+)?function\s+\w+\s*\([^)]*\)\s*\{'
)
HAS_RETURN_TYPE = re.compile(
    r'^export\s+(?:async\s+)?function\s+\w+\s*\([^)]*\)\s*:\s*\w'
)


def scan_file(path: Path) -> list[str]:
    content = path.read_text(encoding="utf-8", errors="replace")
    lines   = content.splitlines()
    rel     = str(path.relative_to(ROOT))
    issues  = []

    for i, line in enumerate(lines, 1):
        stripped = line.strip()
        if stripped.startswith("//") or stripped.startswith("*"):
            continue

        for code, pattern, desc in PATTERNS:
            if pattern.search(line):
                issues.append(f"  [{code}]  {rel}:{i}  {desc}  -- {stripped[:70]}")
                break  # one issue per line max

        # Exported function without return type
        if EXPORT_FN_NO_RET.match(stripped) and not HAS_RETURN_TYPE.match(stripped):
            issues.append(
                f"  [NO-RETURN-TYPE]  {rel}:{i}  exported function missing return type -- "
                f"{stripped[:60]}"
            )

    return issues


def main():
    args          = sys.argv[1:]
    module_filter = None
    i = 0
    while i < len(args):
        if args[i] == "--module" and i + 1 < len(args):
            module_filter = args[i + 1]; i += 2
        else:
            i += 1

    base       = ROOT / module_filter if module_filter else ROOT
    all_issues: list[str] = []

    for ext in ("*.ts", "*.tsx"):
        for ts_file in base.rglob(ext):
            if any(d in ts_file.parts for d in IGNORED):
                continue
            if ts_file.name.endswith((".d.ts", ".test.ts", ".spec.ts", ".test.tsx", ".spec.tsx")):
                continue
            all_issues.extend(scan_file(ts_file))

    # Count by type
    type_counts: dict[str, int] = {}
    for issue in all_issues:
        m = re.match(r'\s*\[(\w[\w-]*)\]', issue)
        if m:
            type_counts[m.group(1)] = type_counts.get(m.group(1), 0) + 1

    total = len(all_issues)
    print(f"ts-antipattern-scan: {total} issue(s) found\n")

    if not all_issues:
        print("  OK -- no TypeScript anti-patterns detected")
        sys.exit(0)

    # Summary
    for t, c in sorted(type_counts.items(), key=lambda x: -x[1]):
        print(f"  {t:<20} {c:>4}")
    print()

    # Details (top 30)
    for issue in all_issues[:30]:
        print(issue)
    if len(all_issues) > 30:
        print(f"  ... ({len(all_issues) - 30} more)")

    sys.exit(1)


if __name__ == "__main__":
    main()
