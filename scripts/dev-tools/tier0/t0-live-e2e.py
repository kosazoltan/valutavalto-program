#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
t0-live-e2e.py -- Tier-0 fetcher: playwright-live pass-matrix (excvaluta.com).

Cel-repo (csak OLVASVA, sosem irva -- es a sajat verifikaciohoz gh/HTTP hivas
SOSEM fut, l. lent): VALUTA_REPO env vagy alapertelmezetten
C:\\Repo\\valutavalto-program.

Elesben: a legutobbi .github/workflows/playwright-live.yml futast kerdezi le
(`gh run list --workflow=playwright-live.yml --limit 1 --json databaseId,
conclusion,createdAt`, cwd=REPO), majd ha van futas, letolti a riportot
(`gh run download <id> -n playwright-report-live-<id>`) egy ideiglenes
mappaba, es abban barmilyen JSON-fajlt felismer, amiben van "suites" kulcs
(Playwright JSON reporter sema: suites[].specs[].tests[].results[], a suite-ok
rekurzivan egymasba agyazva). A T01..T10 (T09 csak authenticated) es T20
(excvaluta-full-menu.spec.ts) tesztek cimebol a "T\\d\\d" prefix alapjan
azonositjuk a pass/fail allapotot (spec["ok"], vagy ha az hianyzik, az osszes
result status=="passed" -- l. _spec_passed()).

FELMERESI MEGJEGYZES (2026-07-11-i allapot, dokumentalt korlat): a
frontend-react/playwright.live.config.ts ES playwright.full-menu.config.ts
JELENLEG NEM tartalmaz json reportert (csak 'list' +/- 'html' -- l. a ket
config 'reporter' kulcsat), tehat a `gh run download` MA egy HTML-riportot ad
vissza JSON helyett, es a T20 futasa (csak 'list' reporter) semmit sem ir
lemezre. Ez azt jelenti, hogy elesben, amig a workflow nem kap json reportert,
ez a script a gh-agon is tipikusan a "nincs felismerheto JSON" agra fut ki
(exit 2) -- ez SZANDEKOSAN nem hamis-zold, hanem oszinte "nincs ertelmezheto
riport" jelzes. A parser emiatt barmilyen JSON-t elfogad "suites" kulccsal,
hogy a workflow kesobbi json-reporter-bovitese utan modositas nelkul mukodjon.
(A json reporter hozzaadasa a workflow-hoz kulon feladat -- ez a script csak
OLVASSA a cel-repot, nem modosithatja.)

Ha `gh` nincs/hibazik (pl. cron/sanitizalt env, nincs auth), fallback: a
legutobb letoltott riport keresese a T0_LIVE_REPORT_DIR alatt (default:
REPO/.agent/playwright-live).

Env-mock:
  T0_LIVE_REPORT_JSON  kesz playwright-riport JSON utja -- ha be van allitva,
                       SEM gh run list, SEM gh run download nem fut.
  T0_LIVE_REPORT_DIR   fallback-mappa gh-hiba eseten (default:
                       REPO/.agent/playwright-live).

Usage:
  python t0-live-e2e.py [--json]

Exit: 0 = minden megtalalt T-teszt PASS, 1 = barmelyik T-teszt FAIL,
      2 = nincs ertelmezheto riport (se mock, se gh, se fallback-mappa NEM ad
      "suites" kulcsu JSON-t), VAGY a talalt riportban egyetlen T01-T10/T20
      cimu teszt sincs.
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

REPO      = Path(os.environ.get("VALUTA_REPO", r"C:\Repo\valutavalto-program"))
WORKFLOW  = "playwright-live.yml"
DENYLIST  = (".env", ".env.ssh-keys", "backend_deployment")  # KOZOS KONTRAKTUS
TID_RE    = re.compile(r'^(T(?:0[1-9]|10|20))\b')
T_ORDER   = ["T01", "T02", "T03", "T04", "T05", "T06", "T07", "T08", "T09", "T10", "T20"]


def print_digest(lines, limit=120):
    if len(lines) <= limit:
        for line in lines:
            print(line)
        return
    for line in lines[: limit - 1]:
        print(line)
    print(f"... ({len(lines) - (limit - 1)} tovabbi sor levagva, hasznald a --json kapcsolot)")


def _tool_error(want_json: bool, script: str, msg: str) -> int:
    """Egysegesen kezeli a --json kontraktust a tool-hiba (exit 2) agon is:
    --json eseten IS egyetlen JSON-objektum, nem sima szoveg."""
    if want_json:
        print(json.dumps({"script": script, "exit_code": 2, "error": msg}, ensure_ascii=False))
    else:
        print(f"[{script}] TOOL-HIBA: {msg}")
    return 2


def _denied(p: Path) -> bool:
    # GLM F-003 fix (2026-07-12): a ".env" SUBSTRING-match tul szeles volt
    # (pl. ".env-helpers.json"-t is tiltana) -> nev-alapu .env* glob a kontraktus.
    if p.name.startswith(".env"):
        return True
    return "backend_deployment/" in str(p).replace("\\", "/")


def _iter_specs(node: dict):
    for s in node.get("specs", []) or []:
        yield s
    for sub in node.get("suites", []) or []:
        yield from _iter_specs(sub)


def _find_report(root: Path):
    """Elso JSON-fajl `root` alatt, aminek van 'suites' kulcsa (None, ha nincs)."""
    if not root.exists():
        return None
    for p in sorted(root.rglob("*.json")):
        if _denied(p):
            continue
        try:
            # utf-8-sig: BOM-tolerans (l. t0-security-scan.py megjegyzese) -- egy
            # letoltott/kezzel keszitett riport BOM-mal is erkezhet.
            data = json.loads(p.read_text(encoding="utf-8-sig", errors="replace"))
        except (OSError, json.JSONDecodeError):
            continue
        if isinstance(data, dict) and "suites" in data:
            return data
    return None


def load_report():
    """(report:dict|None, source:str|None, tool_error:str|None)."""
    mock = os.environ.get("T0_LIVE_REPORT_JSON")
    if mock:
        p = Path(mock)
        if not p.exists():
            return None, None, f"T0_LIVE_REPORT_JSON nem letezik: {p}"
        try:
            return json.loads(p.read_text(encoding="utf-8-sig", errors="replace")), f"mock:{p}", None
        except json.JSONDecodeError as e:
            return None, None, f"T0_LIVE_REPORT_JSON serult JSON: {e}"

    gh = shutil.which("gh")
    if gh:
        try:
            proc = subprocess.run(
                [gh, "run", "list", f"--workflow={WORKFLOW}", "--limit", "1",
                 "--json", "databaseId,conclusion,createdAt"],
                cwd=str(REPO), capture_output=True, text=True,
                encoding="utf-8", errors="replace", timeout=30,
            )
        except (OSError, subprocess.SubprocessError):
            proc = None
        runs = []
        if proc is not None and proc.returncode == 0 and proc.stdout.strip():
            try:
                runs = json.loads(proc.stdout)
            except json.JSONDecodeError:
                runs = []
        if runs:
            run_id = runs[0].get("databaseId")
            with tempfile.TemporaryDirectory(prefix="t0-live-e2e-") as td:
                dl = subprocess.run(
                    [gh, "run", "download", str(run_id),
                     "-n", f"playwright-report-live-{run_id}", "-D", td],
                    cwd=str(REPO), capture_output=True, text=True,
                    encoding="utf-8", errors="replace", timeout=180,
                )
                if dl.returncode == 0:
                    found = _find_report(Path(td))
                    if found is not None:
                        return found, f"gh:run{run_id}", None

    fallback_dir = Path(os.environ.get("T0_LIVE_REPORT_DIR", str(REPO / ".agent" / "playwright-live")))
    found = _find_report(fallback_dir)
    if found is not None:
        return found, f"fallback:{fallback_dir}", None

    return None, None, f"gh-auth kell VAGY tegyél riportot a fallback-mappába ({fallback_dir})"


def _spec_passed(spec: dict) -> bool:
    ok = spec.get("ok")
    if ok is not None:
        return bool(ok)
    statuses = [r.get("status") for t in spec.get("tests", []) or [] for r in t.get("results", []) or []]
    return bool(statuses) and all(s == "passed" for s in statuses)


def build_matrix(report: dict):
    matrix = {}
    for spec in _iter_specs(report):
        title = spec.get("title", "")
        m = TID_RE.match(title)
        if m:
            matrix[m.group(1)] = (title, _spec_passed(spec))
    return matrix


def main() -> int:
    ap = argparse.ArgumentParser(description="Playwright-live T01-T10/T20 pass-matrix Tier-0 fetcher")
    ap.add_argument("--json", action="store_true", help="egyetlen JSON-objektum emberi digest helyett")
    args = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    report, source, tool_error = load_report()
    if report is None:
        return _tool_error(args.json, "t0-live-e2e", tool_error)

    matrix = build_matrix(report)
    if not matrix:
        return _tool_error(args.json, "t0-live-e2e",
                            f"a riport ({source}) nem tartalmaz T01-T10/T20 jelolesu tesztet "
                            "-- rossz riport-formatum vagy ures futas?")

    missing = [t for t in T_ORDER if t not in matrix]
    failing = [t for t, (title, ok) in matrix.items() if not ok]
    exit_code = 1 if failing else 0

    if args.json:
        print(json.dumps({
            "script": "t0-live-e2e",
            "exit_code": exit_code,
            "source": source,
            "matrix": {tid: {"title": title, "passed": ok} for tid, (title, ok) in matrix.items()},
            "missing_tests": missing,
        }, ensure_ascii=False, indent=2))
        return exit_code

    lines = [f"[forras] {source}"]
    for tid in T_ORDER:
        if tid in matrix:
            title, ok = matrix[tid]
            lines.append(f"  {'PASS' if ok else 'FAIL'}  {tid}  {title}")
    if missing:
        lines.append(f"[hianyzo] nem talalhato a riportban: {', '.join(missing)}")
    lines.append(f"[osszegzes] finding={bool(failing)}")
    print_digest(lines)
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
