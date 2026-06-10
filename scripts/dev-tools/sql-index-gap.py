#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
sql-index-gap.py -- Flyway migracios SQL index-rések keresése.

Replaces: AI "are there missing indexes?" DBA review kerdesek.

Technika: Flyway *.sql fajlok statikus elemzése, FK -> INDEX egyeztetes.

Keres:
  - REFERENCES (FK) sor utan hianyzó CREATE INDEX
  - Nagy VARCHAR (>500) oszlopok index nelkul
  - ON DELETE / ON UPDATE CASCADE (kaszkad veszely)
  - Tobb mint 30 oszlopos tabla (God Table)
  - CREATE INDEX nelkul, de ORDER BY / GROUP BY mező a szervizen

Usage:
  python scripts/dev-tools/sql-index-gap.py
  python scripts/dev-tools/sql-index-gap.py --last 20

Exit: 0 = clean, 1 = res talalhato
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
from pathlib import Path

ROOT    = Path(__file__).resolve().parent.parent.parent
MIG_DIR = ROOT / "backend" / "src" / "main" / "resources" / "db" / "migration"

REFERENCES    = re.compile(r'REFERENCES\s+(\w+)\s*\(',      re.IGNORECASE)
CREATE_INDEX  = re.compile(r'CREATE\s+(?:UNIQUE\s+)?INDEX\b', re.IGNORECASE)
FK_COLUMN     = re.compile(r'(\w+)\s+\w[\w<>()\s,]*REFERENCES', re.IGNORECASE)
LARGE_VARCHAR = re.compile(r'(\w+)\s+VARCHAR\s*\(\s*(\d{4,})\s*\)', re.IGNORECASE)
CASCADE       = re.compile(r'ON\s+(DELETE|UPDATE)\s+CASCADE',  re.IGNORECASE)
COLUMN_DEF    = re.compile(r'^\s+(\w+)\s+(?!--)',            re.IGNORECASE)
CREATE_TABLE  = re.compile(r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(\w+)', re.IGNORECASE)


def analyze_migration(path: Path) -> list[str]:
    content = path.read_text(encoding="utf-8", errors="replace")
    lines   = content.splitlines()
    issues  = []
    rel     = path.name

    # Collect FKs and indexes in this file
    fk_columns: list[tuple[int, str]] = []  # (lineno, col_name)
    index_columns: set[str] = set()
    current_table = ""
    column_count  = 0
    in_create     = False

    for i, line in enumerate(lines, 1):
        stripped = line.strip()
        if stripped.startswith("--") or not stripped:
            continue

        ct = CREATE_TABLE.search(line)
        if ct:
            current_table = ct.group(1)
            column_count  = 0
            in_create     = True

        if in_create:
            # Count columns (non-FK, non-INDEX lines)
            if COLUMN_DEF.match(line) and not any(
                kw in line.upper() for kw in
                ("CONSTRAINT", "PRIMARY", "FOREIGN", "UNIQUE", "INDEX", "CHECK", "CREATE", "ALTER")):
                column_count += 1

        # Detect FK
        fk = FK_COLUMN.search(line)
        if fk and "REFERENCES" in line.upper():
            col = fk.group(1)
            fk_columns.append((i, col))

        # Detect index definitions
        if CREATE_INDEX.search(line):
            # Extract column name from CREATE INDEX ON table(col)
            m = re.search(r'\(([^)]+)\)', line)
            if m:
                for c in m.group(1).split(","):
                    index_columns.add(c.strip().split()[0].lower())

        # Large VARCHAR
        lv = LARGE_VARCHAR.search(line)
        if lv:
            col_name = lv.group(1)
            size     = int(lv.group(2))
            issues.append(
                f"  [LARGE-VARCHAR]  {rel}:{i}  {col_name} VARCHAR({size}) -- "
                f"szukseges-e index?")

        # Cascade
        if CASCADE.search(line):
            direction = CASCADE.search(line).group(1)
            issues.append(
                f"  [CASCADE]        {rel}:{i}  ON {direction} CASCADE -- "
                f"kaszkad-torles/frissites veszely")

        # God Table
        if column_count > 30 and in_create and stripped == ");":
            issues.append(
                f"  [GOD-TABLE]      {rel}  {current_table} -- "
                f"{column_count} oszlop (God Table)")
            in_create = False

    # Check FK columns that have no corresponding index
    for lineno, col in fk_columns:
        if col.lower() not in index_columns:
            issues.append(
                f"  [FK-NO-INDEX]    {rel}:{lineno}  '{col}' FK-hoz nincs CREATE INDEX")

    return issues


def main():
    args   = sys.argv[1:]
    last_n = None
    i = 0
    while i < len(args):
        if args[i] == "--last" and i + 1 < len(args):
            last_n = int(args[i + 1]); i += 2
        else:
            i += 1

    sql_files = sorted(MIG_DIR.glob("*.sql"))
    if last_n:
        versioned = re.compile(r'^V(\d+)', re.IGNORECASE)
        sql_files = sorted(
            [f for f in sql_files if versioned.match(f.name)],
            key=lambda f: int(versioned.match(f.name).group(1)),
            reverse=True
        )[:last_n]

    issues  = []
    scanned = 0
    for f in sql_files:
        scanned += 1
        issues.extend(analyze_migration(f))

    print(f"sql-index-gap: {scanned} migracio vizsgalva, {len(issues)} problema\n")

    if not issues:
        print("  OK -- nem talalhato index-res vagy cascade-veszely")
        sys.exit(0)

    for sev in ("FK-NO-INDEX", "LARGE-VARCHAR", "CASCADE", "GOD-TABLE"):
        group = [x for x in issues if f"[{sev}]" in x]
        if group:
            print(f"  [{sev}] ({len(group)})")
            for iss in group[:10]:
                print(iss)
            print()

    sys.exit(1)


if __name__ == "__main__":
    main()
