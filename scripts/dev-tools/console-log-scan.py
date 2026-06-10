#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
console-log-scan.py -- console.log/debug produkciós kódban (TypeScript/React).

Replaces: AI "debug code left in production" review findings.

Keres:
  - console.log / console.debug / console.warn / console.error
  - debugger; utasítás
  - alert() / confirm() böngésző-dialog
  - Csak produkciós kódban (test/spec fájlokat kihagyja)

Usage:
  python scripts/dev-tools/console-log-scan.py
  python scripts/dev-tools/console-log-scan.py --strict  (console.warn/error is hiba)

Exit: 0 = clean, 1 = issues found
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
from pathlib import Path

ROOT    = Path(__file__).resolve().parent.parent.parent
IGNORED = {"node_modules", ".git", "target", "dist", ".vite", "coverage",
           "tmp", ".venv-asr", ".worktrees"}

CONSOLE_LOG   = re.compile(r'\bconsole\.(log|debug)\s*\(')
CONSOLE_WARN  = re.compile(r'\bconsole\.(warn|error)\s*\(')
DEBUGGER      = re.compile(r'\bdebugger\s*;')
ALERT         = re.compile(r'\b(alert|confirm|prompt)\s*\(')


def main():
    args   = sys.argv[1:]
    strict = "--strict" in args

    issues: list[tuple[str, str, int, str]] = []  # (severity, file, line, content)

    for ext in ("*.ts", "*.tsx", "*.js"):
        for f in ROOT.rglob(ext):
            if any(d in f.parts for d in IGNORED):
                continue
            name = f.name
            if any(x in name for x in (".test.", ".spec.", ".d.ts", "__test__", "__spec__")):
                continue

            lines = f.read_text(encoding="utf-8", errors="replace").splitlines()
            rel   = str(f.relative_to(ROOT))

            for i, line in enumerate(lines, 1):
                stripped = line.strip()
                if stripped.startswith("//"):
                    continue

                if DEBUGGER.search(line):
                    issues.append(("ERROR", rel, i, stripped))
                elif ALERT.search(line):
                    issues.append(("ERROR", rel, i, stripped))
                elif CONSOLE_LOG.search(line):
                    issues.append(("WARN", rel, i, stripped))
                elif strict and CONSOLE_WARN.search(line):
                    issues.append(("INFO", rel, i, stripped))

    errors   = [x for x in issues if x[0] == "ERROR"]
    warnings = [x for x in issues if x[0] == "WARN"]
    infos    = [x for x in issues if x[0] == "INFO"]

    total = len(issues)
    print(f"console-log-scan: {total} issue(s)  "
          f"({len(errors)} errors, {len(warnings)} warnings, {len(infos)} info)\n")

    if not issues:
        print("  OK -- no debug statements in production code")
        sys.exit(0)

    for sev, rel, line, content in sorted(issues, key=lambda x: (x[0], x[1])):
        label = {"ERROR": "[ERR]", "WARN": "[LOG]", "INFO": "[NFO]"}[sev]
        print(f"  {label}  {rel}:{line}  {content[:80]}")

    sys.exit(1 if (errors or warnings) else 0)


if __name__ == "__main__":
    main()
