#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
t0-flyway-gate.py -- Tier-0 fetcher: Flyway migracios preflight (KOTELEZO
migracios slice-hoz -- l. valutavalto-dev-loop SKILL.md).

Cel-repo (csak OLVASVA, sosem irva): VALUTA_REPO env vagy alapertelmezetten
C:\\Repo\\valutavalto-program. A repo #1 szamu incidensosztalya a Flyway
verzioutkozes / veszelyes SQL migracio (l. V296-style outage).

Negy resz-check:
  (a) `python scripts/dev-tools/flyway-validate.py` cwd=REPO -- nevkonvencio /
      duplikacio / verziout­kozes. Sajat kontraktusa: exit 0=OK, 1=hiba (SOHA
      nem ad 2-t sajat magatol).
  (b) `python scripts/dev-tools/flyway-content-audit.py --last 10
      --fail-severity HIGH` cwd=REPO -- veszelyes SQL mintak. FIGYELEM: a
      script sajat default-ja --fail-severity LOW lenne (minden CREATE INDEX
      buktatna) -- ezert explicit HIGH-jal hivjuk. A MEDIUM/LOW findingokat a
      nyers kimenet mindig tartalmazza (a tool sajat csoportositasa), csak a
      HIGH/CRITICAL szamit bukasnak -- a digest ezeket csak listazza, nem
      buktatja a mi scriptunket.
  (c) `python scripts/dev-tools/migration-next-version.py` cwd=REPO -- kovetkezo
      szabad V-szam. TISZTAN INFORMACIOS: sajat kontraktusa szerint "mindig
      exit 0" -- ezert (dokumentalt dontes) a returncode-jat SOHA nem szamitjuk
      bele a lelet-osszesitesbe, csak megjelenitjuk.
  (d) Out-of-band verzio-utkozes: REPO/database/migrations/*.sql (legacy, 8
      fajl, VEGYES elnevezes -- "00N_..." bare-numeric ES "VN__..." forma is
      elofordul) verzioszamainak metszete a REPO/backend/src/main/resources/
      db/migration/*.sql (elo fa, 328 fajl) verzioival. Csak fajlnev-listazas,
      tartalmat nem olvas. MINDIG elesben fut, FUGGETLENUL a
      T0_FLYWAY_CMD_LOG_DIR mock-tol (nem subprocess-alapu).

Az elo `flyway_schema_history` DB-tabla ellenorzeset KIHAGYJUK -- nincs
biztonsagos DB-eleres a fetcherbol (backend-kornyezet kellene hozza). A
digest ezt kulon sorban, expliciten jelzi.

DOKUMENTALT DONTES a parser-inditasi hiba (exit 2) felismeresere: a harom
alszkript (a/b/c) sajat kontraktusa szerint SOHA nem ad vissza 2-t -- ha
megis 2-t latunk (vagy a subprocess el sem indul), az csakis azt jelentheti,
hogy a python maga nem tudta megnyitni a celfajlt ("can't open file"), tehat
tool-hiba. Ez a jel kulon Path.exists() elo-ellenorzes nelkul is megbizhato,
es igy is illeszkedik a tobbi tier0 fetcher (pl. t0-rate-feeds.py) mintajahoz,
amely szinten nem pre-checkeli a celszkript letezeset.

Usage:
  python t0-flyway-gate.py [--json]

Env:
  VALUTA_REPO             cel-repo gyokere (default: C:\\Repo\\valutavalto-program)
  T0_FLYWAY_CMD_LOG_DIR   ha be van allitva: <dir>/validate.out(+.rc),
                          audit.out(+.rc), nextver.out fajlokbol olvas subprocess
                          inditas helyett -- CSAK a/b/c-re hat, (d) mindig elo.

Exit: 0 = nincs lelet, 1 = (a) vagy (b) hibat jelzett VAGY (d) atfedest talalt,
      2 = valamelyik alszkript nem inditható / az elo migracios mappa hianyzik.
"""
import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path

REPO       = Path(os.environ.get("VALUTA_REPO", r"C:\Repo\valutavalto-program"))
DEV_TOOLS  = REPO / "scripts" / "dev-tools"
LEGACY_DIR = REPO / "database" / "migrations"
LIVE_DIR   = REPO / "backend" / "src" / "main" / "resources" / "db" / "migration"
DENYLIST   = (".env", ".env.ssh-keys", "backend_deployment")  # KOZOS KONTRAKTUS

VER_LIVE   = re.compile(r'^V(\d+)(?:_\d+)?__', re.IGNORECASE)   # elo fa: Vx__ / Vx_y__
VER_LEGACY = re.compile(r'^V?(\d+)_', re.IGNORECASE)            # legacy: Vx__ VAGY bare 00N_


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


def _mock_part(name: str):
    """None, ha nincs mock beallitva; kulonben (rc, out, tool_error)."""
    mock_dir = os.environ.get("T0_FLYWAY_CMD_LOG_DIR")
    if not mock_dir:
        return None
    base = Path(mock_dir)
    out_f, rc_f = base / f"{name}.out", base / f"{name}.rc"
    try:
        out = out_f.read_text(encoding="utf-8-sig", errors="replace") if out_f.exists() else ""
        rc = int(rc_f.read_text(encoding="utf-8-sig", errors="replace").strip()) if rc_f.exists() else 0
    except (OSError, ValueError) as e:
        return (None, "", f"T0_FLYWAY_CMD_LOG_DIR/{name} nem olvashato: {e}")
    return (rc, out, None)


def run_part(name: str, script_name: str, extra_args=()):
    """(returncode:int|None, output:str, tool_error:str|None). rc==2 vagy inditasi
    hiba => tool-error (l. modul-docstring: a harom alszkript sajat magatol
    sosem ad 2-t)."""
    mocked = _mock_part(name)
    if mocked is not None:
        return mocked
    argv = [sys.executable, str(DEV_TOOLS / script_name), *extra_args]
    try:
        proc = subprocess.run(argv, cwd=str(REPO), capture_output=True, text=True,
                               encoding="utf-8", errors="replace", timeout=120)
    except (OSError, subprocess.SubprocessError) as e:
        return None, "", f"{script_name} inditasa sikertelen: {e}"
    rc = proc.returncode
    out = (proc.stdout or "") + (proc.stderr or "")
    if rc == 2:
        return None, out, f"{script_name} sajat kontraktusa szerint sosem ad 2-t -- valoszinuleg nem talalhato"
    return rc, out, None


def oob_overlap():
    """(findings:list[str], legacy_sql_files:int, live_sql_files:int, tool_error:str|None)."""
    if not LIVE_DIR.exists():
        return [], 0, 0, f"elo migracios mappa nem talalhato: {LIVE_DIR}"

    legacy: dict[int, list[str]] = {}
    if LEGACY_DIR.exists():
        for f in sorted(LEGACY_DIR.glob("*.sql")):
            if _denied(f):
                continue
            m = VER_LEGACY.match(f.name)
            if m:
                legacy.setdefault(int(m.group(1)), []).append(f.name)

    live: dict[int, list[str]] = {}
    for f in sorted(LIVE_DIR.glob("*.sql")):
        if _denied(f):
            continue
        m = VER_LIVE.match(f.name)
        if m:
            live.setdefault(int(m.group(1)), []).append(f.name)

    overlap = sorted(set(legacy) & set(live))
    findings = [f"V{v}: legacy={legacy[v]} vs elo={live[v]}" for v in overlap]
    legacy_total = sum(len(v) for v in legacy.values())
    return findings, legacy_total, len(live), None


def main() -> int:
    ap = argparse.ArgumentParser(description="Flyway migracios preflight Tier-0 fetcher")
    ap.add_argument("--json", action="store_true", help="egyetlen JSON-objektum emberi digest helyett")
    args = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    rc_a, out_a, err_a = run_part("validate", "flyway-validate.py")
    if rc_a is None:
        return _tool_error(args.json, "t0-flyway-gate", f"(a) flyway-validate -- {err_a}")
    rc_b, out_b, err_b = run_part("audit", "flyway-content-audit.py", ["--last", "10", "--fail-severity", "HIGH"])
    if rc_b is None:
        return _tool_error(args.json, "t0-flyway-gate", f"(b) flyway-content-audit -- {err_b}")
    rc_c, out_c, err_c = run_part("nextver", "migration-next-version.py")
    if rc_c is None:
        return _tool_error(args.json, "t0-flyway-gate", f"(c) migration-next-version -- {err_c}")
    oob_findings, legacy_n, live_n, oob_err = oob_overlap()
    if oob_err:
        return _tool_error(args.json, "t0-flyway-gate", f"(d) OOB-utkozes -- {oob_err}")

    lelet_a = [l.strip() for l in out_a.splitlines() if l.strip().startswith(("✗", "⚠"))]
    b_all = [l.strip() for l in out_b.splitlines() if l.strip()]
    b_summary, b_detail = (b_all[0], b_all[1:]) if b_all else ("", [])
    c_all = [l.strip() for l in out_c.splitlines() if l.strip()]
    c_summary, c_detail = (c_all[0], c_all[1:]) if c_all else ("", [])

    finding = (rc_a != 0) or (rc_b != 0) or bool(oob_findings)
    exit_code = 1 if finding else 0

    if args.json:
        print(json.dumps({
            "script": "t0-flyway-gate",
            "exit_code": exit_code,
            "a_validate": {"returncode": rc_a, "ok": rc_a == 0, "findings": lelet_a},
            "b_content_audit": {"returncode": rc_b, "ok": rc_b == 0, "summary": b_summary, "detail_lines": b_detail},
            "c_next_version": {"summary": c_summary, "detail_lines": c_detail},
            "d_oob_overlap": {"legacy_sql_files": legacy_n, "live_sql_files": live_n, "overlap": oob_findings},
            "db_schema_history_check": "kihagyva -- nincs biztonsagos DB-eleres a fetcherbol",
        }, ensure_ascii=False, indent=2))
        return exit_code

    lines = [f"[a-validate] rc={rc_a} ok={rc_a == 0} -- {len(lelet_a)} lelet-sor"]
    for l in lelet_a[:15]:
        lines.append(f"    {l}")
    lines.append(f"[b-content-audit] rc={rc_b} ok={rc_b == 0} (--last 10 --fail-severity HIGH) -- {b_summary}")
    for l in b_detail[:20]:
        lines.append(f"    {l}")
    lines.append(f"[c-next-version] (info, mindig zold) -- {c_summary}")
    for l in c_detail[:6]:
        lines.append(f"    {l}")
    lines.append(f"[d-oob-overlap] legacy={legacy_n} fajl elo={live_n} fajl -> {'LELET' if oob_findings else 'OK'}")
    for l in oob_findings[:15]:
        lines.append(f"    {l}")
    lines.append("[db-schema-history] kihagyva -- backend kornyezetbol fut, itt nincs biztonsagos DB-eleres")
    lines.append(f"[osszegzes] finding={finding}")
    print_digest(lines)
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
