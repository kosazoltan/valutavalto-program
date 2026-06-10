#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
complexity-scan.py --Komplex metódusok és fájlok detektálása (helyi, 0 API cost).

Replaces: AI review "method too long / too many params" findings.

Detektál:
  Java:       >50 soros metódus, >5 paraméteres metódus, >500 soros osztály
  TypeScript: >60 soros függvény/metódus, >500 soros fájl

Usage:
  python scripts/dev-tools/complexity-scan.py
  python scripts/dev-tools/complexity-scan.py --module backend
  python scripts/dev-tools/complexity-scan.py --threshold-method 40 --threshold-file 400

Exit: 0 = clean, 1 = issues found
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
from pathlib import Path
from dataclasses import dataclass

ROOT         = Path(__file__).resolve().parent.parent.parent
IGNORED_DIRS = {"node_modules", ".git", "target", "dist", ".vite", "coverage",
                "tmp", "tmp-asar-extract", ".venv-asr", ".worktrees"}

# Java method detection
JAVA_METHOD = re.compile(
    r'^\s+(?:public|private|protected|static|final|\s)+'
    r'[\w<>\[\],\s]+\s+(\w+)\s*\(([^)]*)\)\s*(?:throws\s+\w[\w,\s]*)?\s*\{'
)
JAVA_CLASS  = re.compile(r'^\s*(?:public|private|protected)?\s*(?:abstract\s+)?class\s+(\w+)')

# TS function/arrow detection
TS_FUNC     = re.compile(
    r'(?:function\s+(\w+)|(?:const|let|var)\s+(\w+)\s*=\s*(?:async\s*)?\(|'
    r'(?:async\s+)?(\w+)\s*\([^)]*\)\s*(?::\s*\S+\s*)?[{:])'
)


@dataclass
class Hit:
    kind: str       # "method", "function", "file"
    name: str
    file: str
    line: int
    size: int       # lines or param count
    detail: str


def count_params(params_str: str) -> int:
    s = params_str.strip()
    if not s:
        return 0
    # Rough count --split on commas, ignoring generics
    depth = 0
    count = 1
    for ch in s:
        if ch in "<({":
            depth += 1
        elif ch in ">)}":
            depth -= 1
        elif ch == "," and depth == 0:
            count += 1
    return count


def scan_java(path: Path, method_threshold: int, file_threshold: int,
              param_threshold: int) -> list[Hit]:
    hits: list[Hit] = []
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    rel   = str(path.relative_to(ROOT))

    if len(lines) > file_threshold:
        hits.append(Hit("file", path.name, rel, 1, len(lines),
                        f"{len(lines)} lines (threshold {file_threshold})"))

    method_start: int | None = None
    method_name:  str        = "?"
    param_count:  int        = 0
    brace_depth:  int        = 0
    in_method:    bool       = False

    for i, raw in enumerate(lines):
        line = raw.strip()

        if not in_method:
            m = JAVA_METHOD.match(raw)
            if m:
                name   = m.group(1)
                params = m.group(2) if m.group(2) else ""
                pc     = count_params(params)
                if pc > param_threshold:
                    hits.append(Hit("method", name, rel, i + 1, pc,
                                    f"{pc} parameters (threshold {param_threshold})"))
                method_start = i + 1
                method_name  = name
                param_count  = pc
                brace_depth  = raw.count("{") - raw.count("}")
                in_method    = brace_depth > 0
        else:
            brace_depth += raw.count("{") - raw.count("}")
            if brace_depth <= 0:
                method_len = i + 1 - (method_start or 0)
                if method_len > method_threshold:
                    hits.append(Hit("method", method_name, rel, method_start or 0,
                                    method_len,
                                    f"{method_len} lines (threshold {method_threshold})"))
                in_method   = False
                method_start = None

    return hits


def scan_ts(path: Path, func_threshold: int, file_threshold: int) -> list[Hit]:
    hits: list[Hit] = []
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    rel   = str(path.relative_to(ROOT))

    if len(lines) > file_threshold:
        hits.append(Hit("file", path.name, rel, 1, len(lines),
                        f"{len(lines)} lines (threshold {file_threshold})"))

    func_start:  int | None = None
    func_name:   str        = "?"
    brace_depth: int        = 0
    in_func:     bool       = False

    for i, raw in enumerate(lines):
        if not in_func:
            m = TS_FUNC.search(raw)
            if m and "{" in raw:
                func_name  = next((g for g in m.groups() if g), "anonymous")
                func_start = i + 1
                brace_depth = raw.count("{") - raw.count("}")
                in_func    = brace_depth > 0
        else:
            brace_depth += raw.count("{") - raw.count("}")
            if brace_depth <= 0:
                func_len = i + 1 - (func_start or 0)
                if func_len > func_threshold:
                    hits.append(Hit("function", func_name, rel, func_start or 0,
                                    func_len,
                                    f"{func_len} lines (threshold {func_threshold})"))
                in_func    = False
                func_start = None

    return hits


def main():
    args             = sys.argv[1:]
    module_filter    = None
    method_threshold = 50
    file_threshold   = 500
    param_threshold  = 5
    func_threshold   = 60

    i = 0
    while i < len(args):
        if args[i] == "--module" and i + 1 < len(args):
            module_filter = args[i + 1]; i += 2
        elif args[i] == "--threshold-method" and i + 1 < len(args):
            method_threshold = int(args[i + 1]); i += 2
        elif args[i] == "--threshold-file" and i + 1 < len(args):
            file_threshold = int(args[i + 1]); i += 2
        elif args[i] == "--threshold-params" and i + 1 < len(args):
            param_threshold = int(args[i + 1]); i += 2
        else:
            i += 1

    base = ROOT / module_filter if module_filter else ROOT
    all_hits: list[Hit] = []

    # Java scan
    for java_file in base.rglob("*.java"):
        if any(d in java_file.parts for d in IGNORED_DIRS):
            continue
        all_hits.extend(scan_java(java_file, method_threshold, file_threshold, param_threshold))

    # TypeScript scan
    for ts_file in base.rglob("*.tsx"):
        if any(d in ts_file.parts for d in IGNORED_DIRS):
            continue
        all_hits.extend(scan_ts(ts_file, func_threshold, file_threshold))
    for ts_file in base.rglob("*.ts"):
        if any(d in ts_file.parts for d in IGNORED_DIRS):
            continue
        if ts_file.suffix == ".ts" and not ts_file.name.endswith(".d.ts"):
            all_hits.extend(scan_ts(ts_file, func_threshold, file_threshold))

    total = len(all_hits)
    print(f"complexity-scan: {total} issue(s) found\n")

    if not all_hits:
        print("  OK --all methods and files within thresholds")
        sys.exit(0)

    # Group by kind
    for kind in ("file", "method", "function"):
        group = [h for h in all_hits if h.kind == kind]
        if not group:
            continue
        label = {"file": "Large files", "method": "Long/wide Java methods",
                 "function": "Long TS functions"}[kind]
        print(f"  [{label}] ({len(group)})")
        for h in sorted(group, key=lambda x: -x.size)[:20]:
            print(f"    {h.file}:{h.line}  {h.name}  --{h.detail}")
        if len(group) > 20:
            print(f"    ... ({len(group) - 20} more)")
        print()

    sys.exit(1)


if __name__ == "__main__":
    main()
