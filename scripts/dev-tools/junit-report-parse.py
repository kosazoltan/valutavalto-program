#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
junit-report-parse.py -- Maven Surefire/Failsafe XML teszt-jelentes feldolgozas.

Replaces: AI "how did tests run?" / kezi Maven output bogaraszas.

Technika: xml.etree.ElementTree, JUnit XML standard (testsuites/testsuite/testcase).

Keres:
  - backend/target/surefire-reports/*.xml
  - backend/target/failsafe-reports/*.xml
  - Osszes modul target/-jeben

Kiszamol:
  - Teljes: run / failed / error / skipped / idobelyeg
  - Leglass teszt top-10
  - Legtobbszor bukott osztaly
  - Hiba uzenet kivonata

Usage:
  python scripts/dev-tools/junit-report-parse.py
  python scripts/dev-tools/junit-report-parse.py --slow 3   (>3s flagel)
  python scripts/dev-tools/junit-report-parse.py --failed-only

Exit: 0 = zold, 1 = bukott tesztek vannak
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent

REPORT_DIRS = [
    "backend/target/surefire-reports",
    "backend/target/failsafe-reports",
]


def parse_report_dir(d: Path) -> list[dict]:
    results = []
    if not d.exists():
        return results
    for xml_file in d.glob("*.xml"):
        try:
            tree = ET.parse(xml_file)
            root = tree.getroot()
        except ET.ParseError:
            continue

        suites = [root] if root.tag == "testsuite" else root.findall(".//testsuite")
        for suite in suites:
            suite_name = suite.get("name", "?")
            for tc in suite.findall("testcase"):
                failure = tc.find("failure")
                error   = tc.find("error")
                skipped = tc.find("skipped")
                status  = "PASS"
                message = ""
                if failure is not None:
                    status  = "FAIL"
                    message = (failure.get("message") or "")[:120]
                elif error is not None:
                    status  = "ERROR"
                    message = (error.get("message") or "")[:120]
                elif skipped is not None:
                    status  = "SKIP"
                results.append({
                    "suite":   suite_name,
                    "name":    tc.get("name", "?"),
                    "time":    float(tc.get("time") or 0),
                    "status":  status,
                    "message": message,
                })
    return results


def main():
    args        = sys.argv[1:]
    slow_thresh = 5.0
    failed_only = "--failed-only" in args
    i = 0
    while i < len(args):
        if args[i] == "--slow" and i + 1 < len(args):
            slow_thresh = float(args[i + 1]); i += 2
        else:
            i += 1

    all_tests = []
    for rd in REPORT_DIRS:
        all_tests.extend(parse_report_dir(ROOT / rd))

    if not all_tests:
        print("junit-report-parse: Nem talalhato surefire/failsafe riport.")
        print("  Futtasd: cd backend && .\\mvnw.cmd test")
        sys.exit(0)

    total   = len(all_tests)
    failed  = [t for t in all_tests if t["status"] == "FAIL"]
    errors  = [t for t in all_tests if t["status"] == "ERROR"]
    skipped = [t for t in all_tests if t["status"] == "SKIP"]
    passed  = total - len(failed) - len(errors) - len(skipped)

    print(f"junit-report-parse: {total} teszt  "
          f"(OK: {passed}  FAIL: {len(failed)}  ERROR: {len(errors)}  SKIP: {len(skipped)})\n")

    # Failures
    broken = failed + errors
    if broken:
        print(f"  [BUKOK] ({len(broken)})")
        for t in broken[:15]:
            msg = f"  -- {t['message']}" if t["message"] else ""
            print(f"    {t['suite']}.{t['name']}{msg}")
        if len(broken) > 15:
            print(f"    ... ({len(broken) - 15} tovabb)")
        print()

    if failed_only:
        sys.exit(1 if broken else 0)

    # Slow tests
    slow = sorted([t for t in all_tests if t["time"] >= slow_thresh],
                  key=lambda x: -x["time"])
    if slow:
        print(f"  [LASSU >{slow_thresh}s] ({len(slow)})")
        for t in slow[:10]:
            print(f"    {t['time']:.1f}s  {t['suite']}.{t['name']}")
        print()

    # Top suites by failure
    suite_fails: dict[str, int] = {}
    for t in broken:
        suite_fails[t["suite"]] = suite_fails.get(t["suite"], 0) + 1
    if suite_fails:
        print("  [Legtobb hiba]")
        for suite, cnt in sorted(suite_fails.items(), key=lambda x: -x[1])[:5]:
            print(f"    {cnt}x  {suite}")
        print()

    total_time = sum(t["time"] for t in all_tests)
    print(f"  Osszes futtasi ido: {total_time:.1f}s")

    sys.exit(1 if broken else 0)


if __name__ == "__main__":
    main()
