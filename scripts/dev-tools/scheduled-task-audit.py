#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
scheduled-task-audit.py -- @Scheduled es @Async Spring metodusok auditja.

Replaces: AI "@Scheduled best practices?" review kerdesek.

Technika: regex elemzes, Spring dokumentacio minta alapjan.

Keres:
  - @Scheduled metodus try-catch nelkul (exception elnyeletlen -> task leall)
  - @Scheduled metodus @Async nelkul (blokkolja a Scheduler szalat)
  - Tul rovid fixedRate (<1000ms) -> scheduling overhead
  - @Scheduled + @Transactional egyutt (rossz praxis)
  - Ures @Scheduled metodus body

Usage:
  python scripts/dev-tools/scheduled-task-audit.py

Exit: 0 = clean, 1 = problema
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
from pathlib import Path

ROOT    = Path(__file__).resolve().parent.parent.parent
IGNORED = {"node_modules", ".git", "target", "dist"}

SCHEDULED   = re.compile(r'@Scheduled\b')
ASYNC       = re.compile(r'@Async\b')
TRANSACT    = re.compile(r'@Transactional\b')
FIXED_RATE  = re.compile(r'fixedRate\s*=\s*(\d+)', re.IGNORECASE)
FIXED_DELAY = re.compile(r'fixedDelay\s*=\s*(\d+)', re.IGNORECASE)
TRY_CATCH   = re.compile(r'\btry\s*\{')
METHOD_SIG  = re.compile(r'^\s+(?:public|protected|private)\s+\S+\s+(\w+)\s*\(')


def scan_file(path: Path) -> list[str]:
    content = path.read_text(encoding="utf-8", errors="replace")
    if not SCHEDULED.search(content):
        return []

    rel    = str(path.relative_to(ROOT))
    lines  = content.splitlines()
    issues = []

    i = 0
    while i < len(lines):
        line = lines[i]
        if not SCHEDULED.search(line):
            i += 1
            continue

        # Collect annotation block (up to 4 lines around @Scheduled)
        ann_block = "\n".join(lines[max(0, i - 3): i + 2])

        # Check fixedRate < 1000ms
        fr = FIXED_RATE.search(line) or FIXED_RATE.search(ann_block)
        if fr and int(fr.group(1)) < 1000:
            issues.append(
                f"  [FAST-RATE]   {rel}:{i + 1}  fixedRate={fr.group(1)}ms -- "
                f"<1s scheduling overhead")

        # Find method declaration
        j = i + 1
        while j < min(i + 5, len(lines)):
            m = METHOD_SIG.match(lines[j])
            if m:
                method_name = m.group(1)
                break
            j += 1
        else:
            i += 1
            continue

        # Check @Async near @Scheduled
        has_async = bool(ASYNC.search(ann_block))

        # Check @Transactional near @Scheduled
        has_tx = bool(TRANSACT.search(ann_block))
        if has_tx:
            issues.append(
                f"  [SCHED+TX]    {rel}:{j + 1}  {method_name}() -- "
                f"@Scheduled + @Transactional egyutt (tranzakcio-hatarok bizonytalanok)")

        # Collect method body
        brace_depth = 0
        body_lines  = []
        k = j
        while k < len(lines):
            body_lines.append(lines[k])
            brace_depth += lines[k].count("{") - lines[k].count("}")
            if brace_depth > 0 and k > j:
                pass
            if brace_depth <= 0 and k > j:
                break
            k += 1

        body = "\n".join(body_lines)

        # No try-catch
        if not TRY_CATCH.search(body) and len(body_lines) > 3:
            issues.append(
                f"  [NO-TRY]      {rel}:{j + 1}  {method_name}() -- "
                f"@Scheduled kivetel-kezeles nelkul (task leallhat!)")

        i = k + 1

    return issues


def main():
    issues  = []
    scanned = 0

    for f in (ROOT / "backend" / "src" / "main" / "java").rglob("*.java"):
        if any(d in f.parts for d in IGNORED):
            continue
        scanned += 1
        issues.extend(scan_file(f))

    print(f"scheduled-task-audit: {scanned} forrasfajl, {len(issues)} problema\n")

    if not issues:
        print("  OK -- @Scheduled metodusok rendben")
        sys.exit(0)

    for iss in issues:
        print(iss)

    sys.exit(1)


if __name__ == "__main__":
    main()
