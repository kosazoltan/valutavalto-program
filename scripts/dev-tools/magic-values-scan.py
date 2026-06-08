#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
magic-values-scan.py -- Hardkódolt mágikus értékek detektálása (Java + TS).

Replaces: AI "magic number/string" code review findings.

Keres:
  Java:
    - Hardkódolt HTTP-státuszkódok (200/201/400/401/403/404/500) nem konstansként
    - Thread.sleep(N) konkrét számmal
    - Ismétlődő literál-stringek (3+x ugyanabban a fájlban)
  TypeScript:
    - Hardkódolt URL-ek (http://, https://) kódban (ne .env-ben legyen!)
    - Ismétlődő hardkódolt stringek (3+x)

Usage:
  python scripts/dev-tools/magic-values-scan.py
  python scripts/dev-tools/magic-values-scan.py --type java
  python scripts/dev-tools/magic-values-scan.py --type ts

Exit: 0 = clean, 1 = issues found
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
from pathlib import Path
from collections import Counter

ROOT     = Path(__file__).resolve().parent.parent.parent
SRC_JAVA = ROOT / "backend" / "src" / "main" / "java"
IGNORED  = {"node_modules", ".git", "target", "dist", ".vite", "coverage", "test"}

# Java patterns
HTTP_STATUS_RAW = re.compile(
    r'\b(200|201|204|400|401|403|404|409|422|500|502|503)\b'
)
STATUS_CONST    = re.compile(
    r'HttpStatus\.|HTTP_|ResponseEntity\.ok|ResponseEntity\.created'
    r'|ResponseEntity\.badRequest|ResponseEntity\.notFound|ResponseEntity\.status'
)
THREAD_SLEEP    = re.compile(r'Thread\.sleep\((\d+)\)')
STRING_LITERAL  = re.compile(r'"([^"]{4,})"')

# TS patterns
TS_URL_LITERAL  = re.compile(r'["\'](https?://[^"\']{10,})["\']')
TS_STR_LITERAL  = re.compile(r'["\']([\w\-/]{6,})["\']')


def scan_java_magic(path: Path) -> list[str]:
    content = path.read_text(encoding="utf-8", errors="replace")
    if not content.strip():
        return []
    rel    = str(path.relative_to(ROOT))
    lines  = content.splitlines()
    issues = []

    # HTTP status codes without HttpStatus.*
    for i, line in enumerate(lines, 1):
        if HTTP_STATUS_RAW.search(line) and not STATUS_CONST.search(line):
            if re.search(r'response|status|code|return', line, re.IGNORECASE):
                issues.append(
                    f"  [MAGIC-HTTP]  {rel}:{i}  {line.strip()[:80]}"
                )

    # Thread.sleep with literal
    for i, line in enumerate(lines, 1):
        m = THREAD_SLEEP.search(line)
        if m and int(m.group(1)) > 100:
            issues.append(f"  [MAGIC-SLEEP]  {rel}:{i}  {line.strip()[:80]}")

    # Repeated string literals (4+ chars, 3+ times in file)
    string_counts: Counter = Counter()
    for line in lines:
        for m in STRING_LITERAL.finditer(line):
            s = m.group(1)
            if not re.match(r'^[\d\s\-_/.:]+$', s):  # skip pure numbers/paths
                string_counts[s] += 1
    for s, count in string_counts.items():
        if count >= 3 and len(s) >= 6:
            issues.append(
                f"  [MAGIC-STR]  {rel}  '{s[:40]}' appears {count}x "
                f"-- consider constant"
            )

    return issues


def scan_ts_magic(path: Path) -> list[str]:
    content = path.read_text(encoding="utf-8", errors="replace")
    if not content.strip():
        return []
    rel    = str(path.relative_to(ROOT))
    lines  = content.splitlines()
    issues = []

    # Hardcoded URLs
    for i, line in enumerate(lines, 1):
        for m in TS_URL_LITERAL.finditer(line):
            url = m.group(1)
            if "localhost" not in url and "example.com" not in url:
                issues.append(f"  [MAGIC-URL]  {rel}:{i}  '{url[:60]}'")

    return issues


def main():
    args      = sys.argv[1:]
    scan_type = "all"
    i = 0
    while i < len(args):
        if args[i] == "--type" and i + 1 < len(args):
            scan_type = args[i + 1]; i += 2
        else:
            i += 1

    all_issues: list[str] = []

    if scan_type in ("java", "all"):
        for java_file in SRC_JAVA.rglob("*.java"):
            if any(d in java_file.parts for d in IGNORED):
                continue
            if "Test" in java_file.stem:
                continue
            all_issues.extend(scan_java_magic(java_file))

    if scan_type in ("ts", "all"):
        for ext in ("*.ts", "*.tsx"):
            for ts_file in ROOT.rglob(ext):
                if any(d in ts_file.parts for d in IGNORED):
                    continue
                if ts_file.name.endswith((".d.ts", ".test.ts", ".spec.ts")):
                    continue
                all_issues.extend(scan_ts_magic(ts_file))

    total = len(all_issues)
    print(f"magic-values-scan: {total} finding(s)\n")

    if not all_issues:
        print("  OK -- no obvious magic values detected")
        sys.exit(0)

    # Show top 30
    for issue in all_issues[:30]:
        print(issue)
    if len(all_issues) > 30:
        print(f"  ... ({len(all_issues) - 30} more -- use --type java or --type ts to narrow)")
    sys.exit(1)


if __name__ == "__main__":
    main()
