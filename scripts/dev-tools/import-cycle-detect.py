#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
import-cycle-detect.py -- Körkörös import-függőség detektálás (TypeScript).

Replaces: madge CLI / AI "circular dependency" findings (0 npm install needed).

Módszer:
  1. Relatív importok felépítik a gráfot
  2. DFS topológiai rendezés -- ciklus detektálás
  3. Csak a ciklust alkotó fájlok kerülnek kiírásra

Usage:
  python scripts/dev-tools/import-cycle-detect.py
  python scripts/dev-tools/import-cycle-detect.py --module frontend-react
  python scripts/dev-tools/import-cycle-detect.py --max-cycles 10

Exit: 0 = clean, 1 = cycles found
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
from pathlib import Path
from collections import defaultdict

ROOT    = Path(__file__).resolve().parent.parent.parent
IGNORED = {"node_modules", ".git", "target", "dist", ".vite", "coverage",
           "tmp", ".venv-asr", ".worktrees"}

IMPORT_RE = re.compile(
    r"""(?:^|\n)\s*(?:import|export)\b.*?from\s+['"](\.\.?/[^'"]+)['"]""",
    re.MULTILINE
)


def resolve_import(source: Path, spec: str) -> Path | None:
    candidate = (source.parent / spec).resolve()
    if candidate.exists() and candidate.is_file():
        return candidate
    for ext in (".ts", ".tsx", ".js", "/index.ts", "/index.tsx", "/index.js"):
        p = Path(str(candidate) + ext) if not ext.startswith("/") \
            else candidate / ext.lstrip("/")
        if p.exists():
            return p
    return None


def build_graph(base: Path) -> dict[str, list[str]]:
    graph: dict[str, list[str]] = defaultdict(list)
    for ext in ("*.ts", "*.tsx"):
        for f in base.rglob(ext):
            if any(d in f.parts for d in IGNORED):
                continue
            if f.name.endswith((".d.ts", ".test.ts", ".spec.ts", ".test.tsx", ".spec.tsx")):
                continue
            content = f.read_text(encoding="utf-8", errors="replace")
            key     = str(f.resolve())
            for m in IMPORT_RE.finditer(content):
                resolved = resolve_import(f, m.group(1))
                if resolved:
                    graph[key].append(str(resolved))
    return dict(graph)


def find_cycles(graph: dict[str, list[str]]) -> list[list[str]]:
    visited:    set[str] = set()
    rec_stack:  set[str] = set()
    cycles:     list[list[str]] = []

    def dfs(node: str, path: list[str]) -> None:
        visited.add(node)
        rec_stack.add(node)
        path.append(node)

        for neighbour in graph.get(node, []):
            if neighbour not in visited:
                dfs(neighbour, path)
            elif neighbour in rec_stack:
                # Found cycle
                cycle_start = path.index(neighbour)
                cycle       = path[cycle_start:]
                cycles.append(cycle[:])

        path.pop()
        rec_stack.discard(node)

    for node in list(graph.keys()):
        if node not in visited:
            dfs(node, [])

    # Dedup cycles
    seen_cycles: set[frozenset] = set()
    unique: list[list[str]] = []
    for c in cycles:
        key = frozenset(c)
        if key not in seen_cycles:
            seen_cycles.add(key)
            unique.append(c)

    return unique


def main():
    args          = sys.argv[1:]
    module_filter = None
    max_cycles    = 20
    i = 0
    while i < len(args):
        if args[i] == "--module" and i + 1 < len(args):
            module_filter = args[i + 1]; i += 2
        elif args[i] == "--max-cycles" and i + 1 < len(args):
            max_cycles = int(args[i + 1]); i += 2
        else:
            i += 1

    base   = ROOT / module_filter if module_filter else ROOT
    print(f"import-cycle-detect: building import graph from {base.name}...", end=" ", flush=True)
    graph  = build_graph(base)
    print(f"{len(graph)} files")

    cycles = find_cycles(graph)
    total  = len(cycles)
    print(f"import-cycle-detect: {total} cycle(s) found\n")

    if not cycles:
        print("  OK -- no circular imports detected")
        sys.exit(0)

    for idx, cycle in enumerate(cycles[:max_cycles], 1):
        print(f"  Cycle {idx} ({len(cycle)} nodes):")
        for node in cycle:
            try:
                rel = str(Path(node).relative_to(ROOT))
            except ValueError:
                rel = node
            print(f"    {rel}")
        print()

    if total > max_cycles:
        print(f"  ... ({total - max_cycles} more cycles -- use --max-cycles N)")

    sys.exit(1)


if __name__ == "__main__":
    main()
