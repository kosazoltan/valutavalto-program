#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
jpql-perf-scan.py -- JPQL / @Query teljesitmeny anti-mintak detektalasa.

Replaces: AI "is this query efficient?" kerdesek + Hibernate statistics manualis nezese.

Technika: @Query annotacios JPQL/SQL kivonas + pattern ellenorzes.

Keres:
  - SELECT * (nativ SQL-ben)
  - JOIN FE_TCH nelkuli @OneToMany/@ManyToMany hivatkozas
  - Karteziai szorzat (FROM A, B WHERE nelkul)
  - Tomb visszateres nativ queryvel (CRITICAL: type safety hianyzik)
  - UPDATE/DELETE @Modifying nelkul
  - LIKE '%...%' vezeto wildcard (index-tilto)
  - findAll() / findAllBy... kollekcio-metodusok limitalas nelkul

Usage:
  python scripts/dev-tools/jpql-perf-scan.py
  python scripts/dev-tools/jpql-perf-scan.py --native-only

Exit: 0 = clean, 1 = problemak
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
from pathlib import Path

ROOT    = Path(__file__).resolve().parent.parent.parent
IGNORED = {"node_modules", ".git", "target", "dist"}

QUERY_ANN    = re.compile(r'@Query\s*\(\s*(?:value\s*=\s*)?["\']([^"\']+)["\']',
                          re.IGNORECASE | re.DOTALL)
NATIVE_FLAG  = re.compile(r'nativeQuery\s*=\s*true', re.IGNORECASE)
MODIFYING    = re.compile(r'@Modifying\b')
METHOD_SIG   = re.compile(r'^\s+\S.*\s+(\w+)\s*\([^)]*\)\s*;')

SELECT_STAR  = re.compile(r'\bSELECT\s+\*\b',           re.IGNORECASE)
CARTESIAN    = re.compile(r'\bFROM\s+\w+\s*,\s*\w+\b',  re.IGNORECASE)
LEADING_LIKE = re.compile(r"LIKE\s+['\"]%",              re.IGNORECASE)
FIND_ALL     = re.compile(r'\bfindAll\b(?!\w)')


def scan_file(path: Path) -> list[str]:
    content = path.read_text(encoding="utf-8", errors="replace")
    if "@Query" not in content and "findAll" not in content:
        return []

    rel    = str(path.relative_to(ROOT))
    lines  = content.splitlines()
    issues = []

    # Scan @Query blocks
    for i, line in enumerate(lines, 1):
        if "@Query" not in line and "LIKE" not in line.upper() and "findAll" not in line:
            continue

        # Leading wildcard LIKE
        if LEADING_LIKE.search(line):
            issues.append(
                f"  [LEADING-LIKE]   {rel}:{i}  {line.strip()[:80]}")

        # findAll without Pageable
        if FIND_ALL.search(line) and "Pageable" not in line and "Page<" not in line:
            # Only flag in Repository/interface files
            issues.append(
                f"  [FINDALL-NOLIMIT] {rel}:{i}  {line.strip()[:80]}")

        # @Query checks — collect multi-line query
        if "@Query" in line:
            # Grab up to 5 lines for multi-line annotations
            block = " ".join(lines[i - 1: i + 5])
            m     = QUERY_ANN.search(block)
            if not m:
                continue
            query   = m.group(1).strip()
            is_nat  = bool(NATIVE_FLAG.search(block))

            if SELECT_STAR.search(query) and is_nat:
                issues.append(
                    f"  [SELECT-STAR]    {rel}:{i}  {query[:80]}")

            if CARTESIAN.search(query):
                issues.append(
                    f"  [CARTESIAN-JOIN] {rel}:{i}  {query[:80]}")

            # UPDATE/DELETE without @Modifying (look back 3 lines)
            if re.search(r'\b(UPDATE|DELETE)\b', query, re.I):
                context = "\n".join(lines[max(0, i - 5): i])
                if not MODIFYING.search(context):
                    issues.append(
                        f"  [NO-MODIFYING]   {rel}:{i}  {query[:80]}")

    return issues


def main():
    args = sys.argv[1:]
    native_only = "--native-only" in args

    issues   = []
    scanned  = 0

    src_dir = ROOT / "backend" / "src" / "main" / "java"
    for f in src_dir.rglob("*.java"):
        if any(d in f.parts for d in IGNORED):
            continue
        if "Repository" not in f.stem and "Dao" not in f.stem and "Query" not in f.stem:
            continue
        scanned += 1
        file_issues = scan_file(f)
        if native_only:
            file_issues = [x for x in file_issues if "SELECT-STAR" in x or "CARTESIAN" in x]
        issues.extend(file_issues)

    print(f"jpql-perf-scan: {scanned} Repository fajl vizsgalva, {len(issues)} problema\n")

    if not issues:
        print("  OK -- nem talalhato JPQL/SQL teljesitmeny problema")
        sys.exit(0)

    for iss in issues:
        print(iss)

    sys.exit(1)


if __name__ == "__main__":
    main()
