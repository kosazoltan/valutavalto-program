#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
t0-e2e-relay.py -- Tier-0 fetcher: e2e-relay riportok digestje.

Cel-repo (csak OLVASVA, sosem irva): VALUTA_REPO env vagy alapertelmezetten
C:\\Repo\\valutavalto-program. Kizarolag ket ismert helyet olvas -- nincs
repo-szintu bejaras, a KOZOS KONTRAKTUS denylistje (.env*, .env.ssh-keys,
backend_deployment/) strukturalisan nem erintett (a results-dir *.json
glob-jara azert vedelmi haloval alkalmazzuk).

Bemenet:
  REPO/e2e-relay-final-report.json:
    RUN_STATUS, STARTUP_STATUS{backend,frontend_build,dev_server},
    BUTTON_COVERAGE{routes_tested,routes_loaded,routes_failed,total_clicked,
    total_btn_errors,...}, BUGS_FOUND[] (TOP-LEVEL tomb), FAILED_ROUTES[],
    PER_ROUTE[{route,clicked,disabled,errors}].
  REPO/e2e-relay-results/*.json (per-route reszletek):
    {route, loaded, clicked, errors, buttons[{label,state}]}.

FELMERESI KORREKCIO: a feladatleiras "errors[]"-t (tombot) feltetelezett a
results-fajlokban; a valos adatban (62/62 ellenorzott fajl, 2026-07-11) az
"errors" mezo MINDIG INT (hibaszamlalo), sosem tomb. A script mindket alakot
elfogadja (defensive: lista -> len(), szam -> int()), igy akkor is helyesen
mukodik, ha egy jovobeli futas visszaallna tomb-alakra.

Usage:
  python t0-e2e-relay.py [--json]

Env:
  VALUTA_REPO  cel-repo gyokere (default: C:\\Repo\\valutavalto-program)

Exit: 0 = nincs lelet, 1 = routes_failed>0 VAGY BUGS_FOUND nem ures VAGY
      barmely results-fajlban hiba van (errors>0), 2 = final-report
      hianyzik/serult JSON.
"""
import argparse
import json
import os
import sys
from pathlib import Path

REPO         = Path(os.environ.get("VALUTA_REPO", r"C:\Repo\valutavalto-program"))
FINAL_REPORT = REPO / "e2e-relay-final-report.json"
RESULTS_DIR  = REPO / "e2e-relay-results"
DENYLIST     = (".env", ".env.ssh-keys", "backend_deployment")  # KOZOS KONTRAKTUS


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
    # GLM F-003 fix (2026-07-12): a ".env" SUBSTRING-match tul szeles volt --
    # az utvonal BARMELY reszeben talalt ".env"-re tiltott (pl. "config.env.bak",
    # "src/env-helpers.ts" a szulo-utvonalon at). A kontraktus a .env* NEV-glob:
    # csak a ".env"-vel KEZDODO fajlNEV tiltott (a .env-helpers.json az marad is).
    if p.name.startswith(".env"):
        return True
    return "backend_deployment/" in str(p).replace("\\", "/")


def _error_count(raw) -> int:
    """A specifikacio tombot ('errors[]') feltetelez, a valosagban int -- mindket
    alakot elfogadjuk (l. modul-docstring FELMERESI KORREKCIO)."""
    if isinstance(raw, list):
        return len(raw)
    if isinstance(raw, (int, float)):
        return int(raw)
    return 0


def load_final_report():
    """(data:dict|None, tool_error:str|None)."""
    if not FINAL_REPORT.exists():
        return None, f"final-report hianyzik: {FINAL_REPORT}"
    try:
        # utf-8-sig: robusztus BOM-mal irt JSON-ra is (l. t0-security-scan.py azonos
        # megjegyzese -- itt ma nincs BOM, de a forras PowerShell/Node keverek).
        return json.loads(FINAL_REPORT.read_text(encoding="utf-8-sig", errors="replace")), None
    except json.JSONDecodeError as e:
        return None, f"final-report serult JSON: {e}"


def scan_results_dir():
    """([(route, error_count_or_-1_ha_olvasasi_hiba), ...], vizsgalt_fajlok_szama)."""
    error_routes = []
    total = 0
    if not RESULTS_DIR.exists():
        return error_routes, total
    for f in sorted(RESULTS_DIR.glob("*.json")):
        if _denied(f):
            continue
        total += 1
        try:
            rd = json.loads(f.read_text(encoding="utf-8-sig", errors="replace"))
        except (OSError, json.JSONDecodeError):
            error_routes.append((f.stem, -1))  # -1 = olvasasi/parse hiba jelzese
            continue
        cnt = _error_count(rd.get("errors"))
        if cnt > 0:
            error_routes.append((rd.get("route", f.stem), cnt))
    return error_routes, total


def main() -> int:
    ap = argparse.ArgumentParser(description="e2e-relay riportok digestje Tier-0 fetcher")
    ap.add_argument("--json", action="store_true", help="egyetlen JSON-objektum emberi digest helyett")
    args = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    data, tool_error = load_final_report()
    if data is None:
        return _tool_error(args.json, "t0-e2e-relay", tool_error)

    run_status = data.get("RUN_STATUS", "?")
    startup    = data.get("STARTUP_STATUS", {}) or {}
    btn        = data.get("BUTTON_COVERAGE", {}) or {}
    bugs       = data.get("BUGS_FOUND", []) or []
    failed_rt  = data.get("FAILED_ROUTES", []) or []
    routes_failed = btn.get("routes_failed", 0) or 0

    error_routes, scanned = scan_results_dir()
    finding = bool(routes_failed) or bool(bugs) or bool(error_routes)
    exit_code = 1 if finding else 0

    if args.json:
        print(json.dumps({
            "script": "t0-e2e-relay",
            "exit_code": exit_code,
            "run_status": run_status,
            "startup_status": startup,
            "button_coverage": btn,
            "bugs_found": bugs,
            "failed_routes": failed_rt,
            "results_scanned": scanned,
            "error_routes": [{"route": r, "errors": c} for r, c in error_routes],
        }, ensure_ascii=False, indent=2))
        return exit_code

    lines = [
        f"[run-status] {run_status}  backend={startup.get('backend', '?')}  "
        f"frontend_build={startup.get('frontend_build', '?')}  dev_server={startup.get('dev_server', '?')}",
        f"[button-coverage] routes_tested={btn.get('routes_tested', '?')} routes_loaded={btn.get('routes_loaded', '?')} "
        f"routes_failed={routes_failed} total_clicked={btn.get('total_clicked', '?')} "
        f"total_btn_errors={btn.get('total_btn_errors', '?')}",
        f"[bugs-found] {len(bugs)} db",
    ]
    for b in bugs[:3]:
        lines.append(f"    {b}")
    lines.append(f"[failed-routes] {failed_rt if failed_rt else '(nincs)'}")
    lines.append(f"[results-dir] {scanned} fajl vizsgalva, {len(error_routes)} hibas (max 10 listazva)")
    for route, cnt in error_routes[:10]:
        lines.append(f"    {route}: {'OLVASASI/PARSE HIBA' if cnt < 0 else f'{cnt} hiba'}")
    lines.append(f"[osszegzes] finding={finding}")
    print_digest(lines)
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
