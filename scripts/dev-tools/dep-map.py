#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
dep-map.py -- Show import/dependency tree for a file (2 levels) + who imports it.

Usage:
  python scripts/dev-tools/dep-map.py <file_path>
  python scripts/dev-tools/dep-map.py <file_path> --depth 3

Supports: .ts  .tsx  .js  .java
Exit: 0 = OK, 1 = file not found / tool error
"""
import sys
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent

IGNORED = {"node_modules", ".git", "target", "dist", ".vite", "coverage",
           "tmp", "tmp-asar-extract", ".venv-asr"}

# Regex patterns per extension
TS_IMPORT  = re.compile(r"""(?:^|\n)\s*(?:import|export)\b.*?from\s+['"](.+?)['"]""", re.MULTILINE)
JAVA_IMPORT = re.compile(r"""^import\s+([\w.]+(?:\.\*)?)\s*;""", re.MULTILINE)

MAX_LINES = 48  # leave room for header/footer


def read_file(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return ""


def get_imports(path: Path) -> list[str]:
    ext = path.suffix.lower()
    content = read_file(path)
    results: list[str] = []

    if ext in (".ts", ".tsx", ".js"):
        for m in TS_IMPORT.finditer(content):
            spec = m.group(1)
            if spec.startswith("."):
                resolved = resolve_relative(path, spec)
                if resolved:
                    try:
                        results.append(str(resolved.relative_to(ROOT)))
                    except ValueError:
                        results.append(str(resolved))
            else:
                results.append(spec)   # external package or alias

    elif ext == ".java":
        for m in JAVA_IMPORT.finditer(content):
            results.append(m.group(1))

    return results


def resolve_relative(source: Path, spec: str) -> Path | None:
    candidate = (source.parent / spec).resolve()
    if candidate.exists():
        return candidate
    for ext in (".ts", ".tsx", ".js", "/index.ts", "/index.tsx", "/index.js"):
        p = Path(str(candidate) + ext) if not ext.startswith("/") else candidate / ext.lstrip("/")
        if p.exists():
            return p
    return None


def reverse_deps(target: Path, extensions: tuple = (".ts", ".tsx", ".java")) -> list[str]:
    """Files that import/reference target (by stem name) via rg."""
    stem = target.stem
    ignore_args = [f"!**/{d}/**" for d in IGNORED]
    glob_args = []
    for ig in ignore_args:
        glob_args += ["--glob", ig]
    for ext in extensions:
        glob_args += ["--glob", f"*{ext}"]

    cmd = ["rg", "--files-with-matches", "--color=never", "-e", stem,
           str(ROOT)] + glob_args
    result = subprocess.run(cmd, capture_output=True, text=True,
                            encoding="utf-8", errors="replace")
    hits: list[str] = []
    for line in result.stdout.strip().splitlines():
        p = Path(line)
        if p.resolve() == target.resolve():
            continue
        try:
            hits.append(str(p.relative_to(ROOT)))
        except ValueError:
            hits.append(line)
    return sorted(hits)


def print_deps(path: Path, depth: int, prefix: str = "", seen: set | None = None,
               line_count: list | None = None):
    if seen is None:
        seen = set()
    if line_count is None:
        line_count = [0]

    imports = get_imports(path)
    for imp in imports:
        if line_count[0] >= MAX_LINES:
            print(f"{prefix}  ... (truncated -- use --depth 1 to reduce)")
            return
        # Only recurse into relative (local) imports
        imp_path = (ROOT / imp) if not imp.startswith(".") else None
        is_local = imp_path and imp_path.exists()
        print(f"{prefix}  -> {imp}")
        line_count[0] += 1
        if is_local and depth > 1 and imp not in seen:
            seen.add(imp)
            print_deps(imp_path, depth - 1, prefix + "  ", seen, line_count)


def main():
    args = sys.argv[1:]
    if not args or args[0] in ("-h", "--help"):
        print(__doc__)
        sys.exit(0)

    file_arg = args[0]
    depth = 2
    i = 1
    while i < len(args):
        if args[i] == "--depth" and i + 1 < len(args):
            depth = max(1, int(args[i + 1]))
            i += 2
        else:
            i += 1

    # Resolve file path (allow relative to root or cwd)
    target = Path(file_arg).resolve()
    if not target.exists():
        target = (ROOT / file_arg).resolve()
    if not target.exists():
        print(f"File not found: {file_arg}", file=sys.stderr)
        sys.exit(1)

    try:
        rel = target.relative_to(ROOT)
    except ValueError:
        rel = target

    print(f"dep-map: {rel}\n")

    # Outgoing deps
    print("DEPENDS ON (imports):")
    line_count = [0]
    seen: set[str] = set()
    imports = get_imports(target)
    if not imports:
        print("  (none found)")
    else:
        for imp in imports:
            if line_count[0] >= MAX_LINES:
                print(f"  ... truncated — pass --depth 1 to reduce")
                break
            imp_path = (ROOT / imp).resolve() if not imp.startswith(".") else None
            is_local = imp_path and imp_path.exists() if imp_path else False
            print(f"  -> {imp}")
            line_count[0] += 1
            if is_local and depth > 1 and imp not in seen:
                seen.add(imp)
                print_deps(imp_path, depth - 1, "  ", seen, line_count)

    print()

    # Reverse deps
    print("IMPORTED BY (reverse deps):")
    rev = reverse_deps(target)
    if not rev:
        print("  (none found)")
    else:
        for r in rev[:20]:
            print(f"  <- {r}")
        if len(rev) > 20:
            print(f"  ... ({len(rev) - 20} more)")

    total_deps = len(imports)
    total_rev  = len(rev)
    print(f"\n{total_deps} outgoing dep(s), {total_rev} reverse dep(s)")


if __name__ == "__main__":
    main()
