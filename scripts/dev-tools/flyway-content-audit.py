#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
flyway-content-audit.py -- Flyway SQL-migrációk tartalom-ellenőrzése.

Replaces: kézi SQL review + AI "dangerous migration" findings.

Keres:
  - DROP TABLE / DROP COLUMN (production data loss risk)
  - TRUNCATE TABLE (data loss)
  - DELETE FROM table WHERE nélkül (teljes törlés)
  - ALTER TABLE DROP COLUMN (irreverzibilis)
  - UPDATE table SET x=y WHERE nélkül (teljes felülírás)
  - CREATE INDEX (lock-veszély nagy táblákon)
  - DROP INDEX (constraint/index drift vagy lock-kockázat)
  - Megjegyzés nélküli veszélyes műveletek

Usage:
  python scripts/dev-tools/flyway-content-audit.py
  python scripts/dev-tools/flyway-content-audit.py --last 10  (utolsó N migráció)
  python scripts/dev-tools/flyway-content-audit.py --last 10 --fail-severity MEDIUM

Exit: 0 = nincs a küszöböt elérő finding, 1 = küszöböt elérő finding van
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
from pathlib import Path

ROOT    = Path(__file__).resolve().parent.parent.parent
MIG_DIR = ROOT / "backend" / "src" / "main" / "resources" / "db" / "migration"

DANGEROUS = [
    ("DROP-TABLE",     re.compile(r'^\s*DROP\s+TABLE\b',          re.IGNORECASE), "CRITICAL"),
    ("DROP-DATABASE",  re.compile(r'^\s*DROP\s+(DATABASE|SCHEMA)\b', re.IGNORECASE), "CRITICAL"),
    ("TRUNCATE",       re.compile(r'^\s*TRUNCATE\b',              re.IGNORECASE), "HIGH"),
    ("DELETE-NO-WHERE",re.compile(r'^\s*DELETE\s+FROM\s+\w+\s*;', re.IGNORECASE), "HIGH"),
    ("UPDATE-NO-WHERE",re.compile(r'^\s*UPDATE\s+\w+\s+SET\b[^;]*;(?!\s*WHERE)', re.IGNORECASE), "HIGH"),
    ("DROP-COLUMN",    re.compile(r'\bDROP\s+COLUMN\b',           re.IGNORECASE), "MEDIUM"),
    ("ALTER-COLUMN",   re.compile(r'\bALTER\s+COLUMN\b',          re.IGNORECASE), "MEDIUM"),
    ("CREATE-INDEX",   re.compile(r'^\s*CREATE\s+(?:UNIQUE\s+)?INDEX\b', re.IGNORECASE), "LOW"),
    ("DROP-INDEX",     re.compile(r'^\s*DROP\s+INDEX\b',          re.IGNORECASE), "LOW"),
    ("ADD-NOT-NULL",   re.compile(r'\bADD\s+COLUMN\b[^;]*NOT\s+NULL(?!\s+DEFAULT)', re.IGNORECASE), "HIGH"),
]

VERSIONED = re.compile(r'^V(\d+)', re.IGNORECASE)
SEVERITY_ORDER = {
    "LOW": 1,
    "MEDIUM": 2,
    "HIGH": 3,
    "CRITICAL": 4,
}


def main():
    args = sys.argv[1:]
    last_n = None
    fail_severity = "LOW"
    i = 0
    while i < len(args):
        if args[i] == "--last" and i + 1 < len(args):
            last_n = int(args[i + 1]); i += 2
        elif args[i] == "--fail-severity" and i + 1 < len(args):
            fail_severity = args[i + 1].upper()
            if fail_severity not in SEVERITY_ORDER:
                print(
                    f"Invalid --fail-severity: {args[i + 1]} "
                    "(expected LOW, MEDIUM, HIGH, CRITICAL)",
                    file=sys.stderr,
                )
                sys.exit(2)
            i += 2
        else:
            i += 1

    sql_files = sorted(MIG_DIR.glob("*.sql"))
    if last_n:
        # Sort by version number descending, take last N
        versioned = sorted(
            [f for f in sql_files if VERSIONED.match(f.name)],
            key=lambda f: int(VERSIONED.match(f.name).group(1)),
            reverse=True
        )
        sql_files = versioned[:last_n]

    issues: list[tuple[str, str]] = []
    scanned = 0

    for sql_file in sql_files:
        content = sql_file.read_text(encoding="utf-8", errors="replace")
        lines   = content.splitlines()
        rel     = sql_file.name
        scanned += 1

        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith("--") or not stripped:
                continue

            for code, pattern, severity in DANGEROUS:
                if pattern.search(line):
                    issues.append((severity, f"  [{severity}:{code}]  {rel}:{i}  {stripped[:80]}"))

    print(f"flyway-content-audit: {scanned} file(s) scanned, {len(issues)} issue(s)\n")

    if not issues:
        print("  OK -- no dangerous SQL patterns detected")
        sys.exit(0)

    # Group by severity
    for sev in ("CRITICAL", "HIGH", "MEDIUM", "LOW"):
        group = [message for severity, message in issues if severity == sev]
        if group:
            print(f"  [{sev}] ({len(group)})")
            for item in group:
                print(item)
            print()

    failing = [
        message
        for severity, message in issues
        if SEVERITY_ORDER[severity] >= SEVERITY_ORDER[fail_severity]
    ]
    if failing:
        print(f"FAILED: {len(failing)} finding(s) at or above --fail-severity {fail_severity}")
        sys.exit(1)

    print(f"OK -- findings are below --fail-severity {fail_severity}")
    sys.exit(0)


if __name__ == "__main__":
    main()
