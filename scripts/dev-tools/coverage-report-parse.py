#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
coverage-report-parse.py -- Vitest/Jest JSON lefedettségi riport elemzese.

Replaces: AI "what is uncovered?" kerdesek + HTML coverage report bongeszese.

Technika: coverage/coverage-summary.json JSON parse (standard V8 / Istanbul format).

Keres:
  - 0%-os lefedettség (teljesen teszteletlen fajl)
  - <50% sorlefedettseg (kritikus)
  - <80% sorlefedettseg (figyelmeztetés)
  - Osszesito: globalis %

Megjegyzes: Vitest beallitas:
  coverage.reporter = ['json-summary', 'text']
  (vitest.config.ts-ben kell beallitani a JSON riport generalasahoz)

Usage:
  python scripts/dev-tools/coverage-report-parse.py
  python scripts/dev-tools/coverage-report-parse.py --threshold 80
  python scripts/dev-tools/coverage-report-parse.py --module penztar-client

Exit: 0 = zold, 1 = alatta van a kuszobertek
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent

COVERAGE_PATHS = [
    "frontend-react/coverage/coverage-summary.json",
    "penztar-client/coverage/coverage-summary.json",
    "kozponti-client/coverage/coverage-summary.json",
]


def load_coverage(path: Path) -> dict | None:
    if not path.exists():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return None


def analyze(data: dict, module: str, threshold: int) -> list[str]:
    issues = []
    total  = data.get("total", {})
    global_lines = total.get("lines", {}).get("pct", 100)

    print(f"\n  [{module}]  Globalis lefedettség: "
          f"sorok={global_lines:.1f}%  "
          f"ag={total.get('branches', {}).get('pct', 0):.1f}%  "
          f"fuggveny={total.get('functions', {}).get('pct', 0):.1f}%")

    for file_path, metrics in data.items():
        if file_path == "total":
            continue
        pct = metrics.get("lines", {}).get("pct", 100)
        if pct == 0:
            issues.append(f"  [ZERO-COV]   {file_path}  -- 0% sorlefedettseg")
        elif pct < 50:
            issues.append(f"  [LOW-COV]    {file_path}  -- {pct:.0f}% (<50%)")
        elif pct < threshold:
            issues.append(f"  [WARN-COV]   {file_path}  -- {pct:.0f}% (<{threshold}%)")

    return issues, global_lines


def main():
    args      = sys.argv[1:]
    threshold = 80
    mod_filter = None
    i = 0
    while i < len(args):
        if args[i] == "--threshold" and i + 1 < len(args):
            threshold = int(args[i + 1]); i += 2
        elif args[i] == "--module" and i + 1 < len(args):
            mod_filter = args[i + 1]; i += 2
        else:
            i += 1

    all_issues  = []
    found_any   = False

    for cov_path_str in COVERAGE_PATHS:
        module = cov_path_str.split("/")[0]
        if mod_filter and mod_filter not in module:
            continue
        data = load_coverage(ROOT / cov_path_str)
        if data is None:
            continue
        found_any = True
        issues, _ = analyze(data, module, threshold)
        all_issues.extend(issues)

    if not found_any:
        print("\ncoverage-report-parse: Nincs coverage-summary.json.")
        print("  Generald a riportot: cd <module> && npx vitest run --coverage")
        print("  Vitest beallitas: coverage.reporter = ['json-summary', 'text']")
        sys.exit(0)

    print(f"\ncoverage-report-parse: {len(all_issues)} lefedettségi problema "
          f"(kuszob: {threshold}%)\n")

    if not all_issues:
        print("  OK -- minden fajl a kuszob felett van")
        sys.exit(0)

    for cat in ("ZERO-COV", "LOW-COV", "WARN-COV"):
        group = [x for x in all_issues if f"[{cat}]" in x]
        if group:
            print(f"  [{cat}] ({len(group)})")
            for iss in group[:12]:
                print(iss)
            if len(group) > 12:
                print(f"    ... ({len(group) - 12} tovabb)")
            print()

    sys.exit(1 if any("[ZERO-COV]" in x or "[LOW-COV]" in x for x in all_issues) else 0)


if __name__ == "__main__":
    main()
