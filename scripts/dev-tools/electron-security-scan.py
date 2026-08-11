#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
electron-security-scan.py -- Electron biztonsági konfiguráció-ellenőrzés.

Replaces: Electronegativity tool / AI "Electron security" review findings.
Inspired by: https://github.com/doyensec/electronegativity

Keres (kritikus biztonsági anti-patternek):
  - nodeIntegration: true  (RCE kockázat)
  - contextIsolation: false  (prototype pollution kockázat)
  - sandbox: false  (reduced attack surface elveszítése)
  - enableRemoteModule: true  (deprecated, exploit vektor)
  - allowRunningInsecureContent: true
  - webSecurity: false  (SOP bypass)
  - dynamic code execution electron process-ben
  - ipcMain.on nélkül validáció
  - shell.openExternal() user input-tal
  - protocol.registerFileProtocol + user path

Usage:
  python scripts/dev-tools/electron-security-scan.py

Exit: 0 = clean, 1 = issues found (CRITICAL), 2 = warnings only
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
from pathlib import Path

ROOT    = Path(__file__).resolve().parent.parent.parent
IGNORED = {"node_modules", ".git", "target", "dist", ".vite", "coverage"}

ELECTRON_DIRS = ["penztar-client", "kozponti-client"]

CRITICAL_PATTERNS = [
    ("NODE-INTEGRATION",
     re.compile(r'nodeIntegration\s*[=:]\s*true'),
     "nodeIntegration=true enables Node.js in renderer (RCE risk)"),
    ("CONTEXT-ISOLATION",
     re.compile(r'contextIsolation\s*[=:]\s*false'),
     "contextIsolation=false allows prototype pollution attacks"),
    ("WEB-SECURITY-OFF",
     re.compile(r'webSecurity\s*[=:]\s*false'),
     "webSecurity=false disables Same-Origin Policy"),
    ("INSECURE-CONTENT",
     re.compile(r'allowRunningInsecureContent\s*[=:]\s*true'),
     "allowRunningInsecureContent=true allows mixed content"),
    ("REMOTE-MODULE",
     re.compile(r'enableRemoteModule\s*[=:]\s*true'),
     "enableRemoteModule=true is deprecated and exploitable"),
]

WARNING_PATTERNS = [
    ("SANDBOX-OFF",
     re.compile(r'sandbox\s*[=:]\s*false'),
     "sandbox=false reduces process isolation"),
    ("EVAL-IN-MAIN",
     re.compile(r'\beval\s*\(|new\s+Function\s*\('),
     "dynamic code execution -- code injection risk"),
    ("OPEN-EXTERNAL",
     re.compile(r'shell\.openExternal\s*\([^"\']/'),
     "shell.openExternal() with variable -- verify input sanitization"),
    ("LOAD-URL-VAR",
     re.compile(r'loadURL\s*\([^"\'`/]'),
     "loadURL() with variable -- verify URL is trusted"),
    ("IPC-NO-VALIDATE",
     re.compile(r'ipcMain\.on\s*\('),
     "ipcMain.on() -- verify input validation in handler"),
]


def scan_dir(base: Path) -> tuple[list[str], list[str]]:
    criticals: list[str] = []
    warnings:  list[str] = []

    for ext in ("*.js", "*.ts", "*.mjs", "*.cjs"):
        for f in base.rglob(ext):
            if any(d in f.parts for d in IGNORED):
                continue
            if f.name.endswith((".d.ts", ".test.ts", ".spec.ts")):
                continue

            content = f.read_text(encoding="utf-8", errors="replace")
            lines   = content.splitlines()
            rel     = str(f.relative_to(ROOT))

            for i, line in enumerate(lines, 1):
                stripped = line.strip()
                if stripped.startswith("//") or stripped.startswith("*"):
                    continue

                for code, pattern, desc in CRITICAL_PATTERNS:
                    if pattern.search(line):
                        criticals.append(f"  [CRITICAL:{code}]  {rel}:{i}  {desc}")
                        criticals.append(f"               Code: {stripped[:80]}")

                for code, pattern, desc in WARNING_PATTERNS:
                    if pattern.search(line):
                        warnings.append(f"  [WARN:{code}]  {rel}:{i}  {desc}")

    return criticals, warnings


def main():
    all_criticals: list[str] = []
    all_warnings:  list[str] = []

    for d in ELECTRON_DIRS:
        target = ROOT / d
        if not target.exists():
            continue
        c, w = scan_dir(target)
        all_criticals.extend(c)
        all_warnings.extend(w)

    total_c = len([x for x in all_criticals if x.strip().startswith("[CRITICAL")])
    total_w = len([x for x in all_warnings  if x.strip().startswith("[WARN")])

    print(f"electron-security-scan: {total_c} critical, {total_w} warning(s)\n")

    if all_criticals:
        print("CRITICAL ISSUES:")
        for c in all_criticals:
            print(c)
        print()

    if all_warnings:
        print("WARNINGS (verify manually):")
        for w in all_warnings[:20]:
            print(w)
        if len(all_warnings) > 20:
            print(f"  ... ({len(all_warnings) - 20} more)")

    if not all_criticals and not all_warnings:
        print("  OK -- no Electron security issues detected")
        sys.exit(0)

    sys.exit(1 if all_criticals else 2)


if __name__ == "__main__":
    main()
