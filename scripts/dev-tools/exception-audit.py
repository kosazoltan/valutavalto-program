#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
exception-audit.py -- Elnyelt/rosszul kezelt kivételek detektálása (Java).

Replaces: AI "exception swallowing" / "error handling" review findings.

Keres:
  - Üres catch blokk (catch { })
  - Csak komment a catch-ben
  - System.out.println / e.printStackTrace (ne logger!)
  - catch(Exception e) / catch(Throwable t) szupertípus
  - throw new RuntimeException(e) nélkül eredeti üzenet megőrzése
  - Log nélküli elnyelés

Usage:
  python scripts/dev-tools/exception-audit.py
  python scripts/dev-tools/exception-audit.py --module backend

Exit: 0 = clean, 1 = issues found
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
from pathlib import Path

ROOT     = Path(__file__).resolve().parent.parent.parent
SRC_JAVA = ROOT / "backend" / "src" / "main" / "java"
IGNORED  = {"node_modules", ".git", "target", "dist"}


CATCH_OPEN   = re.compile(r'\bcatch\s*\(\s*([\w.]+(?:\s*\|\s*[\w.]+)*)\s+(\w+)\s*\)')
EMPTY_BODY   = re.compile(r'\bcatch\s*\([^)]+\)\s*\{(\s*//[^\n]*)?\s*\}')
SYSOUT       = re.compile(r'System\.out\.print|e\.printStackTrace\(\)')
BROAD_CATCH  = re.compile(r'\bcatch\s*\(\s*(Exception|Throwable|RuntimeException)\s+')
THROW_WRAP   = re.compile(r'throw\s+new\s+\w+Exception\s*\(\s*["\']')  # no original cause


def main():
    args = sys.argv[1:]
    module_filter = None
    i = 0
    while i < len(args):
        if args[i] == "--module" and i + 1 < len(args):
            module_filter = args[i + 1]; i += 2
        else:
            i += 1

    base   = ROOT / module_filter if module_filter else SRC_JAVA
    issues: list[str] = []

    for java_file in base.rglob("*.java"):
        if any(d in java_file.parts for d in IGNORED):
            continue
        if "Test" in java_file.stem:
            continue
        content = java_file.read_text(encoding="utf-8", errors="replace")
        rel     = str(java_file.relative_to(ROOT))
        lines   = content.splitlines()

        for i, line in enumerate(lines, 1):
            stripped = line.strip()

            # Empty catch block (single line)
            if EMPTY_BODY.search(stripped):
                issues.append(f"  [EMPTY-CATCH]   {rel}:{i}  {stripped[:80]}")

            # System.out.println / e.printStackTrace
            if SYSOUT.search(stripped):
                issues.append(f"  [SYSOUT-CATCH]  {rel}:{i}  {stripped[:80]}")

            # Broad catch (Exception/Throwable)
            if BROAD_CATCH.search(stripped):
                issues.append(f"  [BROAD-CATCH]   {rel}:{i}  {stripped[:80]}")

            # throw new Exception("msg") without original cause
            if THROW_WRAP.search(stripped) and re.search(r'throw\s+new', stripped):
                # Check if `e` or cause is passed
                if not re.search(r'throw\s+new\s+\w+\([^)]*\b[a-z]\w*\b[^)]*\)', stripped):
                    issues.append(f"  [LOST-CAUSE]    {rel}:{i}  {stripped[:80]}")

    # Multi-line empty catch detection
    catch_depth_map: dict[str, int] = {}
    for java_file in base.rglob("*.java"):
        if any(d in java_file.parts for d in IGNORED):
            continue
        if "Test" in java_file.stem:
            continue
        content = java_file.read_text(encoding="utf-8", errors="replace")
        rel     = str(java_file.relative_to(ROOT))
        lines   = content.splitlines()
        in_catch = False
        catch_start = 0
        catch_body: list[str] = []
        depth = 0

        for i, raw in enumerate(lines, 1):
            line = raw.strip()
            if CATCH_OPEN.search(line) and "{" in raw:
                in_catch    = True
                catch_start = i
                catch_body  = []
                depth       = raw.count("{") - raw.count("}")
            elif in_catch:
                depth      += raw.count("{") - raw.count("}")
                catch_body.append(line)
                if depth <= 0:
                    # Evaluate body
                    body_meaningful = [
                        l for l in catch_body
                        if l and not l.startswith("//") and l != "}"
                        and not re.match(r'^/\*', l)
                    ]
                    if not body_meaningful:
                        key = f"{rel}:{catch_start}:empty"
                        if key not in catch_depth_map:
                            catch_depth_map[key] = 1
                            issues.append(
                                f"  [EMPTY-CATCH-ML] {rel}:{catch_start}  "
                                f"multi-line empty catch block"
                            )
                    in_catch = False

    # Dedup
    seen: set[str] = set()
    deduped = []
    for issue in issues:
        key = issue[:80]
        if key not in seen:
            seen.add(key)
            deduped.append(issue)

    total = len(deduped)
    print(f"exception-audit: {total} issue(s) found\n")

    if not deduped:
        print("  OK -- no exception handling issues found")
        sys.exit(0)

    for issue in sorted(deduped):
        print(issue)
    sys.exit(1)


if __name__ == "__main__":
    main()
