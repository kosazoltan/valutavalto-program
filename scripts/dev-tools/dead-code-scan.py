#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
dead-code-scan.py — TypeScript/Java unused exportok és dead code detektálása.

Replaces: ts-prune API-hívások + AI "unused import/export" findings.

Módszer:
  TS: export-ok neve megkeresve, vissza-ellenőrzés rg-vel (ki importálja)
  Java: public metódusok/mezők amelyeket senki sem hív meg (heuristic)

Usage:
  python scripts/dev-tools/dead-code-scan.py
  python scripts/dev-tools/dead-code-scan.py --module frontend-react
  python scripts/dev-tools/dead-code-scan.py --type ts
  python scripts/dev-tools/dead-code-scan.py --type java

Exit: 0 = clean, 1 = dead code found
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
import subprocess
from pathlib import Path
from dataclasses import dataclass

ROOT         = Path(__file__).resolve().parent.parent.parent
IGNORED_DIRS = {"node_modules", ".git", "target", "dist", ".vite", "coverage",
                "tmp", "tmp-asar-extract", ".venv-asr", ".worktrees", "__pycache__"}

# TS export patterns
TS_NAMED_EXPORT = re.compile(
    r'^export\s+(?:const|function|class|interface|type|enum|abstract\s+class)\s+(\w+)',
    re.MULTILINE
)
TS_DEFAULT_EXPORT = re.compile(r'^export\s+default\s+(?:function\s+)?(\w+)', re.MULTILINE)
TS_RE_EXPORT      = re.compile(r'^export\s*\{[^}]+\}\s*from', re.MULTILINE)

# Java unused: public methods never referenced (simple heuristic)
JAVA_PUBLIC_METHOD = re.compile(
    r'^\s+public\s+(?!static\s+(?:void\s+)?main)(?:static\s+)?'
    r'[\w<>\[\],\s]+\s+(\w+)\s*\([^)]*\)\s*(?:throws[^{]*)?\{',
    re.MULTILINE
)
JAVA_SKIP_NAMES = {
    "toString", "equals", "hashCode", "compareTo", "clone", "finalize",
    "getClass", "notify", "notifyAll", "wait", "run", "call", "execute",
    "handle", "apply", "accept", "get", "set", "is", "has",
    "build", "create", "of", "from", "parse",
}


@dataclass
class DeadItem:
    kind: str     # "ts-export", "java-method"
    name: str
    file: str
    line: int
    usage_count: int


def rg_count(symbol: str, extensions: list[str], exclude_file: str) -> int:
    ignore_args = [arg for d in IGNORED_DIRS for arg in ("--glob", f"!**/{d}/**")]
    type_args   = [arg for ext in extensions for arg in ("--glob", f"*.{ext}")]
    cmd = ["rg", "--files-with-matches", "--color=never", "-e", rf'\b{re.escape(symbol)}\b',
           str(ROOT)] + type_args + ignore_args
    r = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    files = [l for l in r.stdout.strip().splitlines()
             if Path(l).resolve() != Path(exclude_file).resolve()]
    return len(files)


def scan_ts_exports(module_filter: str | None) -> list[DeadItem]:
    hits: list[DeadItem] = []
    base = ROOT / module_filter if module_filter else ROOT

    ts_files: list[Path] = []
    for ext in ("*.ts", "*.tsx"):
        for f in base.rglob(ext):
            if any(d in f.parts for d in IGNORED_DIRS):
                continue
            if f.name.endswith(".d.ts") or f.name.endswith(".test.ts") or f.name.endswith(".spec.ts"):
                continue
            ts_files.append(f)

    for ts_file in ts_files:
        content = ts_file.read_text(encoding="utf-8", errors="replace")
        if TS_RE_EXPORT.search(content):
            continue  # barrel file — skip

        for m in TS_NAMED_EXPORT.finditer(content):
            name = m.group(1)
            if name in ("default",):
                continue
            line = content[:m.start()].count("\n") + 1
            usage = rg_count(name, ["ts", "tsx"], str(ts_file))
            if usage == 0:
                hits.append(DeadItem("ts-export", name,
                                     str(ts_file.relative_to(ROOT)), line, 0))

    return hits


def scan_java_dead(module_filter: str | None) -> list[DeadItem]:
    hits: list[DeadItem] = []
    base = ROOT / module_filter if module_filter else ROOT / "backend"

    for java_file in base.rglob("*.java"):
        if any(d in java_file.parts for d in IGNORED_DIRS):
            continue
        fname = java_file.stem
        # Only check non-Controller, non-Entity, non-DTO public methods
        if any(x in fname for x in ("Controller", "Entity", "Dto", "DTO",
                                     "Test", "Config", "Application", "Mapper")):
            continue
        content = java_file.read_text(encoding="utf-8", errors="replace")
        for m in JAVA_PUBLIC_METHOD.finditer(content):
            name = m.group(1)
            if name in JAVA_SKIP_NAMES or len(name) <= 2:
                continue
            line = content[:m.start()].count("\n") + 1
            usage = rg_count(name, ["java"], str(java_file))
            if usage == 0:
                hits.append(DeadItem("java-method", name,
                                     str(java_file.relative_to(ROOT)), line, 0))

    return hits


def main():
    args          = sys.argv[1:]
    scan_type     = "all"
    module_filter = None

    i = 0
    while i < len(args):
        if args[i] == "--module" and i + 1 < len(args):
            module_filter = args[i + 1]; i += 2
        elif args[i] == "--type" and i + 1 < len(args):
            scan_type = args[i + 1]; i += 2
        else:
            i += 1

    all_hits: list[DeadItem] = []

    if scan_type in ("ts", "all"):
        print("Scanning TypeScript exports...", end=" ", flush=True)
        ts_hits = scan_ts_exports(module_filter)
        print(f"{len(ts_hits)} found")
        all_hits.extend(ts_hits)

    if scan_type in ("java", "all"):
        print("Scanning Java public methods...", end=" ", flush=True)
        java_hits = scan_java_dead(module_filter)
        print(f"{len(java_hits)} found")
        all_hits.extend(java_hits)

    print(f"\ndead-code-scan: {len(all_hits)} potential dead item(s)\n")

    if not all_hits:
        print("  OK — no obviously unused exports/methods detected")
        sys.exit(0)

    for kind in ("ts-export", "java-method"):
        group = [h for h in all_hits if h.kind == kind]
        if not group:
            continue
        label = "Unused TS exports" if kind == "ts-export" else "Unreferenced Java public methods (heuristic)"
        print(f"  [{label}] ({len(group)})")
        for h in sorted(group, key=lambda x: x.file)[:25]:
            print(f"    {h.file}:{h.line}  {h.name}")
        if len(group) > 25:
            print(f"    ... ({len(group) - 25} more)")
        print()

    print("NOTE: Results are heuristic — verify before deleting (re-exports, reflection, annotations).")
    sys.exit(1)


if __name__ == "__main__":
    main()
