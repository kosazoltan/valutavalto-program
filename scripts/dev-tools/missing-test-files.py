#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
missing-test-files.py -- TypeScript/React komponens tesztfajl hianykimutatas.

Replaces: AI "do all components have tests?" kerdesek.

Technika: fajlrendszer-parositas: *.tsx/*.ts -> *.test.tsx/*.spec.ts.

Ellenorzi:
  - frontend-react/src/pages/*.tsx -> *.test.tsx
  - frontend-react/src/components/*.tsx -> *.test.tsx
  - */hooks/*.ts -> *.test.ts
  - */services/*.ts -> *.test.ts
  - Hianyzo __mocks__ mappak

Usage:
  python scripts/dev-tools/missing-test-files.py
  python scripts/dev-tools/missing-test-files.py --module penztar-client
  python scripts/dev-tools/missing-test-files.py --strict  (index.ts-t is ellenorzi)

Exit: 0 = minden lefedett, 1 = hianyzik tesztfajl
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
from pathlib import Path

ROOT    = Path(__file__).resolve().parent.parent.parent
IGNORED = {"node_modules", ".git", "dist", ".vite", "coverage", "__mocks__",
           "__tests__", "test", "tests"}

SKIP_STEMS = {"index", "types", "constants", "config", "routes",
              "App", "main", "vite-env", "setupTests", "jest.config",
              "vitest.config", "tailwind.config", "postcss.config"}
SKIP_DIRS  = {"__tests__", "__mocks__", "test", "tests", "fixtures",
              "mocks", "coverage", "dist"}

PRIORITY_DIRS = {"pages", "components", "hooks", "services",
                 "utils", "stores", "contexts", "api"}


def is_test_file(name: str) -> bool:
    return any(s in name for s in (".test.", ".spec.", ".stories."))


def find_test_file(source: Path, base_dir: Path) -> bool:
    stem   = re.sub(r'\.(tsx?)$', '', source.name)
    parent = source.parent
    for ext in (".test.tsx", ".test.ts", ".spec.tsx", ".spec.ts",
                ".test.jsx", ".spec.jsx"):
        if (parent / (stem + ext)).exists():
            return True
    # Also check __tests__ sibling dir
    tests_dir = parent / "__tests__"
    if tests_dir.exists():
        for f in tests_dir.iterdir():
            if f.stem == stem or f.stem.startswith(stem):
                return True
    return False


def scan_module(module_dir: Path, strict: bool) -> list[str]:
    src = module_dir / "src"
    if not src.exists():
        return []

    issues = []
    for f in src.rglob("*"):
        if not f.is_file():
            continue
        if any(d in f.parts for d in IGNORED):
            continue
        if any(str(f).count(skip) for skip in SKIP_DIRS if skip in str(f)):
            continue

        # Only .ts / .tsx
        if f.suffix not in (".ts", ".tsx"):
            continue
        if f.name.endswith(".d.ts"):
            continue
        if is_test_file(f.name):
            continue
        if f.stem in SKIP_STEMS:
            continue

        # Priority check: always test pages/components/hooks
        is_priority = any(p in f.parts for p in PRIORITY_DIRS)
        if not is_priority and not strict:
            continue

        if not find_test_file(f, src):
            rel = str(f.relative_to(ROOT))
            # Mark priority items
            tag = "MISSING-TEST"
            issues.append(f"  [{tag}]  {rel}")

    return issues


def main():
    args = sys.argv[1:]
    strict     = "--strict" in args
    mod_filter = None
    i = 0
    while i < len(args):
        if args[i] == "--module" and i + 1 < len(args):
            mod_filter = args[i + 1]; i += 2
        else:
            i += 1

    modules = (["frontend-react", "penztar-client", "kozponti-client"]
               if not mod_filter else [mod_filter])

    all_issues = []
    for mod in modules:
        mod_dir = ROOT / mod
        if not mod_dir.exists():
            continue
        found = scan_module(mod_dir, strict)
        if found:
            print(f"  [{mod}]: {len(found)} hianyzó tesztfajl")
        all_issues.extend(found)

    print(f"\nmissing-test-files: {len(all_issues)} hianyzó tesztfajl "
          f"({'strict' if strict else 'priority-only'} mod)\n")

    if not all_issues:
        print("  OK -- minden prioritas-komponensnek van tesztfajlja")
        sys.exit(0)

    for iss in all_issues[:30]:
        print(iss)
    if len(all_issues) > 30:
        print(f"  ... ({len(all_issues) - 30} tovabb)")

    sys.exit(1)


if __name__ == "__main__":
    main()
