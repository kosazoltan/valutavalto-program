#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
transaction-audit.py -- Service metódusok @Transactional-hiány detektálása.

Replaces: AI "@Transactional missing" review findings.

Keres:
  - Service osztályokban adatmódosító metódusok @Transactional nélkül
  - save/delete/persist/merge/flush/remove hívások tranzakció nélkül
  - @Transactional(readOnly=true) amin mégis írás történik

Usage:
  python scripts/dev-tools/transaction-audit.py
  python scripts/dev-tools/transaction-audit.py --module backend

Exit: 0 = clean, 1 = issues found
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
from pathlib import Path

ROOT     = Path(__file__).resolve().parent.parent.parent
SRC_JAVA = ROOT / "backend" / "src" / "main" / "java"
IGNORED  = {"node_modules", ".git", "target", "dist", "test"}

# Patterns
WRITE_CALL = re.compile(
    r'(?P<receiver>[A-Za-z_][\w.]*)\.(?P<op>save|saveAll|saveAndFlush|delete|'
    r'deleteAll|deleteById|persist|merge|remove|flush|executeUpdate|bulkUpdate|'
    r'createNativeQuery)\s*\('
)
TRANSACTIONAL = re.compile(r'@Transactional\b')
READONLY_TX   = re.compile(r'@Transactional\s*\(\s*readOnly\s*=\s*true')
METHOD_DECL   = re.compile(
    r'^\s+(?:public|protected)\s+(?:(?:static|final|synchronized)\s+)*'
    r'[\w<>\[\],\s]+\s+(\w+)\s*\([^)]*\)\s*(?:throws[^{]*)?\{'
)
SERVICE_CLASS = re.compile(r'@(Service|Component)\b')


def is_persistence_write(line: str) -> bool:
    """Return true for likely DB writes, not Map.merge(), stream.flush(), PDF save(), etc."""
    for match in WRITE_CALL.finditer(line):
        receiver = match.group("receiver").split(".")[-1].lower()
        op = match.group("op")
        if op == "createNativeQuery":
            return "executeUpdate" in line
        if op in {"executeUpdate", "bulkUpdate"}:
            return True
        if (
            receiver == "repository"
            or receiver == "repo"
            or receiver.endswith("repo")
            or receiver.endswith("repository")
            or receiver in {"entitymanager", "em", "jdbctemplate", "namedparameterjdbctemplate"}
        ):
            return True
    return False


def parse_service_methods(java_file: Path) -> list[dict]:
    content = java_file.read_text(encoding="utf-8", errors="replace")
    if not SERVICE_CLASS.search(content):
        return []

    lines   = content.splitlines()
    results = []
    i       = 0
    class_tx = bool(TRANSACTIONAL.search(content.split("class ")[0] if "class " in content else ""))

    while i < len(lines):
        line = lines[i].strip()

        # Collect annotations before method
        ann_block: list[str] = []
        j = i
        while j < len(lines) and (lines[j].strip().startswith("@") or not lines[j].strip()):
            if lines[j].strip().startswith("@"):
                ann_block.append(lines[j].strip())
            j += 1

        m = METHOD_DECL.match(lines[j]) if j < len(lines) else None
        if m:
            method_name = m.group(1)
            has_tx      = any(TRANSACTIONAL.search(a) for a in ann_block) or class_tx
            is_readonly = any(READONLY_TX.search(a) for a in ann_block)

            # Scan method body for persistence write ops. Count braces on the
            # declaration line too, otherwise one-line methods absorb following methods.
            brace_depth = lines[j].count("{") - lines[j].count("}")
            body_lines  = [(j + 1, lines[j])]
            k = j + 1
            while k < len(lines) and brace_depth > 0:
                body_lines.append((k + 1, lines[k]))
                brace_depth += lines[k].count("{") - lines[k].count("}")
                k += 1

            write_hits = [(ln, bl.strip()) for ln, bl in body_lines if is_persistence_write(bl)]

            if write_hits:
                results.append({
                    "method": method_name,
                    "line":   j + 1,
                    "has_tx": has_tx,
                    "readonly": is_readonly,
                    "writes":  write_hits[:3],
                    "file":   str(java_file.relative_to(ROOT)),
                })
            i = k
            continue
        i = j + 1 if j > i else i + 1

    return results


def main():
    args          = sys.argv[1:]
    module_filter = None
    i = 0
    while i < len(args):
        if args[i] == "--module" and i + 1 < len(args):
            module_filter = args[i + 1]; i += 2
        else:
            i += 1

    base = ROOT / module_filter if module_filter else SRC_JAVA
    issues: list[str] = []

    for java_file in base.rglob("*Service*.java"):
        if any(d in java_file.parts for d in IGNORED):
            continue
        methods = parse_service_methods(java_file)
        for md in methods:
            if not md["has_tx"]:
                issues.append(
                    f"  [NO-TX]     {md['file']}:{md['line']}  {md['method']}() -- "
                    f"has write ops but no @Transactional"
                )
                for ln, bl in md["writes"][:2]:
                    issues.append(f"               line {ln}: {bl[:70]}")
            elif md["readonly"] and md["writes"]:
                issues.append(
                    f"  [RO-TX-WRITE] {md['file']}:{md['line']}  {md['method']}() -- "
                    f"@Transactional(readOnly=true) but has write ops"
                )

    total = len([x for x in issues if x.startswith("  [")])
    print(f"transaction-audit: {total} issue(s) found\n")

    if not issues:
        print("  OK -- no missing @Transactional detected")
        sys.exit(0)

    for issue in issues:
        print(issue)
    sys.exit(1)


if __name__ == "__main__":
    main()
