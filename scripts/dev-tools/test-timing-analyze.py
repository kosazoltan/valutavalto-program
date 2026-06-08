#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
test-timing-analyze.py -- JUnit XML teszt-idok elemzese, lassak azonositasa.

Replaces: AI "which tests are slow?" kerdesek + Maven output bongeszese.

Technika: xml.etree.ElementTree, time attribuum kinyerese testcase csompontokon.

Kiszamol:
  - Leglassabb 15 teszt (time kinyerese)
  - Osztaly szintu összesito
  - Tesztek idoeloszlas kategoriankent (<1s / 1-5s / >5s)
  - Teljes tesztcsomag ideje

Usage:
  python scripts/dev-tools/test-timing-analyze.py
  python scripts/dev-tools/test-timing-analyze.py --slow 3   (>3s kuszob)
  python scripts/dev-tools/test-timing-analyze.py --top 20

Exit: 0 = OK
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent

REPORT_DIRS = [
    "backend/target/surefire-reports",
    "backend/target/failsafe-reports",
]


def collect_timings() -> list[dict]:
    results = []
    for rd in REPORT_DIRS:
        d = ROOT / rd
        if not d.exists():
            continue
        for xml_file in d.glob("*.xml"):
            try:
                tree = ET.parse(xml_file)
                root = tree.getroot()
            except ET.ParseError:
                continue
            suites = [root] if root.tag == "testsuite" else root.findall(".//testsuite")
            for suite in suites:
                sname = suite.get("name", "?")
                for tc in suite.findall("testcase"):
                    t = float(tc.get("time") or 0)
                    results.append({
                        "suite":  sname,
                        "name":   tc.get("name", "?"),
                        "time":   t,
                    })
    return results


def main():
    args      = sys.argv[1:]
    slow_thr  = 5.0
    top_n     = 15
    i = 0
    while i < len(args):
        if args[i] == "--slow" and i + 1 < len(args):
            slow_thr = float(args[i + 1]); i += 2
        elif args[i] == "--top" and i + 1 < len(args):
            top_n = int(args[i + 1]); i += 2
        else:
            i += 1

    timings = collect_timings()
    if not timings:
        print("test-timing-analyze: Nincs surefire riport. "
              "Futtasd: cd backend && .\\mvnw.cmd test")
        sys.exit(0)

    total_time = sum(t["time"] for t in timings)
    fast   = [t for t in timings if t["time"] < 1]
    medium = [t for t in timings if 1 <= t["time"] < slow_thr]
    slow   = [t for t in timings if t["time"] >= slow_thr]

    print(f"test-timing-analyze: {len(timings)} teszt  "
          f"({total_time:.1f}s osszes)\n")
    print(f"  <1s:     {len(fast):4d} db")
    print(f"  1-{slow_thr:.0f}s:  {len(medium):4d} db")
    print(f"  >{slow_thr:.0f}s:    {len(slow):4d} db  (lassak)")
    print()

    # Top N slowest
    top = sorted(timings, key=lambda x: -x["time"])[:top_n]
    print(f"  [TOP {top_n} LEGLASS]")
    for t in top:
        print(f"    {t['time']:6.2f}s  {t['suite']}.{t['name'][:60]}")
    print()

    # Class summaries
    suite_times: dict[str, float] = {}
    for t in timings:
        suite_times[t["suite"]] = suite_times.get(t["suite"], 0) + t["time"]
    top_suites = sorted(suite_times.items(), key=lambda x: -x[1])[:8]
    print("  [LEGLASSABB OSZTALYOK]")
    for s, ts in top_suites:
        print(f"    {ts:6.1f}s  {s}")

    sys.exit(0)


if __name__ == "__main__":
    main()
