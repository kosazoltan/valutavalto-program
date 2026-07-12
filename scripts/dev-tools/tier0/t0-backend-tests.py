#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
t0-backend-tests.py -- Tier-0 fetcher: backend (Maven surefire+failsafe+jacoco)
teszt-digest.

Csak fajlolvasas, NINCS mvnw/npm hivas:
  - REPO/backend/target/surefire-reports/*.xml
  - REPO/backend/target/failsafe-reports/*.xml   (hianyzo dir = 0 IT fajl, nem hiba)
  - REPO/backend/target/site/jacoco/jacoco.xml   (a <report> gyoker UTOLSO 6
    <counter> gyerekeleme = INSTRUCTION/BRANCH/LINE/COMPLEXITY/METHOD/CLASS)

Szandekosan NEM hivja subprocess-szel a meglevo junit-report-parse.py-t (annak
kimenete ember-formatum) -- sajat ElementTree-parsolas, gepi digest <=3 KB.

Exit: 0 = nincs bukas, 1 = van bukott/error teszt, 2 = nincs egy XML se
(vagy az osszes korrupt).
"""
import argparse
import json
import os
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

# newline="\n": a digest szigoru <=3 KB budget-jet bajtban szamoljuk (print_digest_bytes) --
# Windows alatt forditas nelkul a sima "\n" irasa "\r\n"-re alakulna, ami soronkent +1 bajtot
# csempeszne be es alaasna a budget pontossagat.
sys.stdout.reconfigure(encoding="utf-8", errors="replace", newline="\n")

REPO = Path(os.environ.get("VALUTA_REPO", r"C:\Repo\valutavalto-program"))
BACKEND_TARGET = REPO / "backend" / "target"
MAX_DIGEST_BYTES = 3072
MAX_STACK_LINES = 15
SLOWEST_TOP_N = 10


def num(el, name, cast=int, default=0):
    try:
        return cast(el.get(name, default))
    except (TypeError, ValueError):
        return default


def print_digest_bytes(lines, max_bytes=MAX_DIGEST_BYTES):
    total = 0
    for i, line in enumerate(lines):
        size = len((line + "\n").encode("utf-8"))
        if total + size > max_bytes:
            print(f"... ({len(lines) - i} tovabbi sor levagva, a digest 3 KB budget-je miatt -- hasznald a --json kapcsolot)")
            return
        print(line)
        total += size


def collect_xml_files():
    files = []
    for sub in ("surefire-reports", "failsafe-reports"):
        d = BACKEND_TARGET / sub
        if d.is_dir():
            files.extend(sorted(d.glob("*.xml")))
    return files


def parse_reports(files):
    totals = {"tests": 0, "failures": 0, "errors": 0, "skipped": 0}
    slow_raw, first_failure, corrupt = [], None, []

    for f in files:
        try:
            root = ET.parse(f).getroot()
        except ET.ParseError as exc:
            corrupt.append(f"{f.name}: {exc}")
            continue

        for key in totals:
            totals[key] += num(root, key)
        suite_name = root.get("name", f.stem)

        for tc in root.findall("testcase"):
            classname = tc.get("classname") or suite_name
            test_name = tc.get("name") or "(osztaly-szintu)"
            slow_raw.append((num(tc, "time", float, 0.0), classname, test_name))

            if first_failure is None:
                bad, kind = tc.find("failure"), "failure"
                if bad is None:
                    bad, kind = tc.find("error"), "error"
                if bad is not None:
                    stack = (bad.text or "").strip().splitlines()
                    first_failure = {
                        "class": classname, "test": test_name, "kind": kind,
                        "message": (bad.get("message") or "")[:300],
                        "stack_excerpt": stack[:MAX_STACK_LINES], "file": f.name,
                    }

    slow_raw.sort(key=lambda x: x[0], reverse=True)
    slowest = [{"class": c, "test": n, "time": round(t, 3)} for t, c, n in slow_raw[:SLOWEST_TOP_N]]
    return totals, slowest, first_failure, corrupt


def parse_jacoco():
    path = BACKEND_TARGET / "site" / "jacoco" / "jacoco.xml"
    if not path.is_file():
        return None, f"nincs jacoco.xml: {path}"
    try:
        root = ET.parse(path).getroot()
    except ET.ParseError as exc:
        return None, f"jacoco.xml parse hiba: {exc}"

    counters = [c for c in root if c.tag == "counter"][-6:]
    by_type = {c.get("type"): (num(c, "missed"), num(c, "covered")) for c in counters}

    def pct(kind):
        missed, covered = by_type.get(kind, (0, 0))
        total = missed + covered
        return round(covered / total * 100, 1) if total else None

    line_m, line_c = by_type.get("LINE", (0, 0))
    branch_m, branch_c = by_type.get("BRANCH", (0, 0))
    return {
        "line_pct": pct("LINE"), "branch_pct": pct("BRANCH"),
        "line_missed": line_m, "line_covered": line_c,
        "branch_missed": branch_m, "branch_covered": branch_c,
    }, None


def build_digest(totals, coverage, jacoco_err, first_failure, slowest, corrupt, file_count):
    lines = [
        f"[t0-backend-tests] {file_count} XML feldolgozva (surefire+failsafe)",
        f"tests={totals['tests']} failures={totals['failures']} errors={totals['errors']} skipped={totals['skipped']}",
    ]
    if coverage:
        lt, bt = coverage["line_covered"] + coverage["line_missed"], coverage["branch_covered"] + coverage["branch_missed"]
        lines.append(f"jacoco LINE={coverage['line_pct']}% ({coverage['line_covered']}/{lt}) "
                      f"BRANCH={coverage['branch_pct']}% ({coverage['branch_covered']}/{bt})")
    else:
        lines.append(f"jacoco: nincs adat ({jacoco_err})")
    if corrupt:
        lines.append(f"korrupt XML: {len(corrupt)} db (pl. {corrupt[0][:200]})")

    lines.append("")
    if first_failure:
        lines.append(f"-- elso bukott teszt: {first_failure['class']}#{first_failure['test']} "
                      f"[{first_failure['kind']}] ({first_failure['file']})")
        lines.append(f"   {first_failure['message']}")
        lines.extend(f"   {l}" for l in first_failure["stack_excerpt"])
    else:
        lines.append("-- nincs bukott/error teszt")

    lines.append("")
    lines.append(f"-- {SLOWEST_TOP_N} leglassabb teszt:")
    lines.extend(f"   {item['time']:.3f}s  {item['class']}#{item['test']}" for item in slowest)
    return lines


def emit_tool_error(message, as_json):
    if as_json:
        print(json.dumps({"script": "t0-backend-tests", "exit_code": 2, "tool_error": message}, ensure_ascii=False, indent=2))
    else:
        print(f"[t0-backend-tests] TOOL-HIBA: {message}")


def main() -> int:
    ap = argparse.ArgumentParser(description="Backend teszt-digest (surefire+failsafe+jacoco) Tier-0 fetcher")
    ap.add_argument("--json", action="store_true", help="egyetlen JSON-objektum emberi digest helyett")
    args = ap.parse_args()

    files = collect_xml_files()
    if not files:
        emit_tool_error(f"nincs surefire/failsafe XML itt: {BACKEND_TARGET} (futtasd: cd backend && mvnw.cmd test)", args.json)
        return 2

    totals, slowest, first_failure, corrupt = parse_reports(files)
    if corrupt and len(corrupt) == len(files):
        emit_tool_error(f"mind a(z) {len(files)} XML korrupt volt, elso: {corrupt[0][:200]}", args.json)
        return 2

    coverage, jacoco_err = parse_jacoco()
    exit_code = 1 if (totals["failures"] + totals["errors"]) > 0 else 0

    if args.json:
        print(json.dumps({
            "script": "t0-backend-tests", "exit_code": exit_code,
            "totals": {**totals, "files": len(files), "corrupt_files": len(corrupt)},
            "coverage": coverage, "first_failure": first_failure, "slowest_tests": slowest,
        }, ensure_ascii=False, indent=2))
    else:
        print_digest_bytes(build_digest(totals, coverage, jacoco_err, first_failure, slowest, corrupt, len(files)))

    return exit_code


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:  # varatlan hiba -- soha ne szalljon el nyers tracebackkel
        print(f"[t0-backend-tests] varatlan hiba: {exc}", file=sys.stderr)
        sys.exit(2)
