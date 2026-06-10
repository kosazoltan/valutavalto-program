#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
n-plus-one-scan.py -- N+1 query anti-pattern detektálás (Java/Spring/JPA).

Replaces: AI "N+1 query" performance review findings.

Keres:
  - @OneToMany / @ManyToMany annotáció @BatchSize vagy @EntityGraph nélkül
  - Repository hívás cikluson belül (for/while + repository.find*())
  - JPQL SELECT nélkül JOIN FETCH a kollekciókra

Usage:
  python scripts/dev-tools/n-plus-one-scan.py

Exit: 0 = clean, 1 = issues found
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
from pathlib import Path

ROOT     = Path(__file__).resolve().parent.parent.parent
SRC_JAVA = ROOT / "backend" / "src" / "main" / "java"
IGNORED  = {"node_modules", ".git", "target", "dist", "test"}

RELATION_ANN   = re.compile(r'@(OneToMany|ManyToMany|OneToOne)\b')
BATCH_OR_GRAPH = re.compile(r'@(BatchSize|EntityGraph|Fetch)\b')
FOR_LOOP       = re.compile(r'\b(for|while)\s*\(')
REPO_CALL      = re.compile(r'\.(findById|findAll|findBy\w+|getById|getOne)\s*\(')
JPQL_COLLECTION = re.compile(
    r'@Query\s*\(\s*["\']SELECT\s+\w+\s+FROM\s+\w+\s+\w+[^"\']*["\']',
    re.IGNORECASE
)
JOIN_FETCH     = re.compile(r'\bJOIN\s+FETCH\b', re.IGNORECASE)


def check_entity_relations(java_file: Path) -> list[str]:
    """Find @OneToMany without @BatchSize or @EntityGraph."""
    content = java_file.read_text(encoding="utf-8", errors="replace")
    lines   = content.splitlines()
    issues  = []
    rel     = str(java_file.relative_to(ROOT))

    i = 0
    while i < len(lines):
        line = lines[i].strip()
        m = RELATION_ANN.search(line)
        if m:
            # Look ahead 5 lines for @BatchSize or @EntityGraph
            window = "\n".join(lines[max(0, i-2):i+5])
            if not BATCH_OR_GRAPH.search(window):
                issues.append(
                    f"  [N+1-RELATION]  {rel}:{i+1}  {line[:70]}"
                    f"  -- no @BatchSize or @EntityGraph nearby"
                )
        i += 1
    return issues


def check_loop_queries(java_file: Path) -> list[str]:
    """Find repository.find* calls inside for/while loops."""
    content = java_file.read_text(encoding="utf-8", errors="replace")
    if "Repository" not in content and "repository" not in content:
        return []
    lines   = content.splitlines()
    issues  = []
    rel     = str(java_file.relative_to(ROOT))

    in_loop     = False
    loop_depth  = 0
    loop_start  = 0
    brace_depth = 0

    for i, raw in enumerate(lines, 1):
        line = raw.strip()
        if FOR_LOOP.search(line) and not in_loop:
            in_loop    = True
            loop_start = i
            loop_depth = brace_depth + raw.count("{") - raw.count("}")
        elif in_loop:
            if REPO_CALL.search(line):
                issues.append(
                    f"  [N+1-LOOP]  {rel}:{i}  "
                    f"repository call inside loop (started line {loop_start}): "
                    f"{line[:60]}"
                )
        brace_depth += raw.count("{") - raw.count("}")
        if in_loop and brace_depth <= loop_depth - 1:
            in_loop = False

    return issues


def check_jpql_missing_fetch(java_file: Path) -> list[str]:
    """Find @Query JPQL missing JOIN FETCH for collection fields."""
    content = java_file.read_text(encoding="utf-8", errors="replace")
    if "@Query" not in content:
        return []
    lines  = content.splitlines()
    issues = []
    rel    = str(java_file.relative_to(ROOT))

    for i, line in enumerate(lines, 1):
        if "@Query" in line:
            snippet = "\n".join(lines[i-1:i+4])
            if JPQL_COLLECTION.search(snippet) and not JOIN_FETCH.search(snippet):
                # Heuristic: if query has WHERE clause fetching entity with known relations
                issues.append(
                    f"  [N+1-JPQL]  {rel}:{i}  JPQL SELECT without JOIN FETCH -- "
                    f"verify if lazy collections exist: {line.strip()[:60]}"
                )

    return issues


def main():
    all_issues: list[str] = []

    for java_file in SRC_JAVA.rglob("*.java"):
        if any(d in java_file.parts for d in IGNORED):
            continue
        stem = java_file.stem
        if "Test" in stem:
            continue
        if "Entity" in stem or "entity" in java_file.parent.name:
            all_issues.extend(check_entity_relations(java_file))
        if "Service" in stem:
            all_issues.extend(check_loop_queries(java_file))
        if "Repository" in stem:
            all_issues.extend(check_jpql_missing_fetch(java_file))

    total = len(all_issues)
    print(f"n-plus-one-scan: {total} potential N+1 issue(s)\n")

    if not all_issues:
        print("  OK -- no obvious N+1 patterns detected")
        sys.exit(0)

    for issue in all_issues[:30]:
        print(issue)
    if len(all_issues) > 30:
        print(f"  ... ({len(all_issues) - 30} more)")
    print("\nNOTE: Heuristic -- verify with slow query log or Hibernate statistics.")
    sys.exit(1)


if __name__ == "__main__":
    main()
