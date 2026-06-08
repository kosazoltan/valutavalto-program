#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
test-coverage-gap.py -- Teszt-lefedettség res-elemzés forraskod alapjan.

Replaces: AI "what is not tested?" kerdesek + JaCoCo HTML bogaraszas.

Technika: forraskod vs teszt-fajlok nevegyeztetese (nincs build szukseges).

Ellenorzi:
  - Minden *Service.java -> van-e *ServiceTest.java / *ServiceIT.java?
  - Minden *Controller.java -> van-e *ControllerTest.java?
  - Minden *Repository.java -> van-e tesztelt metodus?
  - Vitest: minden *.tsx -> van-e *.test.tsx / *.spec.tsx?

Usage:
  python scripts/dev-tools/test-coverage-gap.py
  python scripts/dev-tools/test-coverage-gap.py --java-only
  python scripts/dev-tools/test-coverage-gap.py --ts-only

Exit: 0 = minden lefedett, 1 = res talalhato
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
from pathlib import Path

ROOT    = Path(__file__).resolve().parent.parent.parent
IGNORED = {"node_modules", ".git", "target", "dist", ".vite", "coverage"}

JAVA_SRC  = ROOT / "backend" / "src" / "main" / "java"
JAVA_TEST = ROOT / "backend" / "src" / "test" / "java"


def collect_java_tests() -> set[str]:
    tests = set()
    if not JAVA_TEST.exists():
        return tests
    for f in JAVA_TEST.rglob("*.java"):
        tests.add(f.stem)
    return tests


def check_java_coverage(java_only: bool) -> list[str]:
    issues = []
    if not JAVA_SRC.exists():
        return issues
    test_names = collect_java_tests()

    categories = {
        "Service":    ["Service"],
        "Controller": ["Controller", "RestController"],
        "Repository": ["Repository", "Repo"],
    }

    for f in JAVA_SRC.rglob("*.java"):
        stem = f.stem
        for cat, suffixes in categories.items():
            for suf in suffixes:
                if stem.endswith(suf):
                    # Look for *Test or *IT
                    base   = stem[: -len(suf)]
                    tested = (
                        f"{stem}Test" in test_names or
                        f"{stem}IT"   in test_names or
                        f"{base}{suf}Test" in test_names or
                        f"{base}{suf}IT"   in test_names
                    )
                    if not tested:
                        rel = str(f.relative_to(ROOT))
                        issues.append(f"  [JAVA-{cat.upper()}]  {rel}")
                    break

    return issues


def collect_ts_tests(base: Path) -> set[str]:
    tests = set()
    for f in base.rglob("*"):
        if any(d in f.parts for d in IGNORED):
            continue
        name = f.name
        for suffix in (".test.ts", ".test.tsx", ".spec.ts", ".spec.tsx"):
            if name.endswith(suffix):
                bare = re.sub(r'\.(test|spec)\.(ts|tsx)$', '', name)
                tests.add(bare)
    return tests


def check_ts_coverage() -> list[str]:
    issues = []
    for module in ("frontend-react", "penztar-client", "kozponti-client",
                   "arfolyam-keszito-client"):
        mod_dir = ROOT / module / "src"
        if not mod_dir.exists():
            continue
        ts_tests = collect_ts_tests(mod_dir)

        for f in mod_dir.rglob("*"):
            if any(d in f.parts for d in IGNORED):
                continue
            if not (f.name.endswith(".tsx") or
                    (f.name.endswith(".ts") and not f.name.endswith(".d.ts"))):
                continue
            if any(s in f.name for s in (".test.", ".spec.", ".stories.", ".mock.")):
                continue
            # Only check component / hook / service files (not index/type/config)
            if f.stem in ("index", "types", "constants", "config",
                          "routes", "App", "main", "vite-env"):
                continue
            bare = re.sub(r'\.(tsx?)$', '', f.name)
            if bare not in ts_tests:
                rel = str(f.relative_to(ROOT))
                issues.append(f"  [TS-{module.upper()[:8]}]  {rel}")

    return issues


def main():
    args     = sys.argv[1:]
    java_only = "--java-only" in args
    ts_only   = "--ts-only"   in args

    all_issues = []
    if not ts_only:
        all_issues.extend(check_java_coverage(java_only))
    if not java_only:
        all_issues.extend(check_ts_coverage())

    java_count = len([x for x in all_issues if "[JAVA-" in x])
    ts_count   = len([x for x in all_issues if "[TS-"   in x])

    print(f"test-coverage-gap: {len(all_issues)} lefedetlen osztaly/komponens  "
          f"(Java: {java_count}, TS: {ts_count})\n")

    if not all_issues:
        print("  OK -- minden Service/Controller/Repository es TS-komponens lefedett")
        sys.exit(0)

    for cat in ("JAVA-SERVICE", "JAVA-CONTROLLER", "JAVA-REPOSITORY"):
        group = [x for x in all_issues if f"[{cat}]" in x]
        if group:
            print(f"  [{cat}] ({len(group)})")
            for iss in group[:10]:
                print(iss)
            if len(group) > 10:
                print(f"    ... ({len(group) - 10} tovabb)")
            print()

    ts_groups: dict[str, list[str]] = {}
    for iss in all_issues:
        m = re.search(r'\[TS-(\w+)\]', iss)
        if m:
            ts_groups.setdefault(m.group(1), []).append(iss)
    for key, group in sorted(ts_groups.items()):
        print(f"  [TS-{key}] ({len(group)})")
        for iss in group[:8]:
            print(iss)
        if len(group) > 8:
            print(f"    ... ({len(group) - 8} tovabb)")
        print()

    sys.exit(1)


if __name__ == "__main__":
    main()
