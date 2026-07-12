#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
t0-security-scan.py -- Tier-0 fetcher: security-riport (gate-status + audit) digest.

Cel-repo (csak OLVASVA, sosem irva): VALUTA_REPO env vagy alapertelmezetten
C:\\Repo\\valutavalto-program. Kizarolag a REPO/security-reports/latest/ alatti
ismert fajlokat olvassa -- nincs repo-szintu bejaras, a KOZOS KONTRAKTUS
denylistje (.env*, .env.ssh-keys, backend_deployment/) strukturalisan nem
erintett.

FELMERESI KORREKCIO: a feladatleiras trivy SARIF-ot es gitleaks-et feltetelezett
security-forraskent. A cel-repoban EGYIK SEM letezik -- a sajat ripgrep-alapu
security-kapu (l. security-reports/latest/gate-status.json "checks" tombje:
hardcoded_secrets_scan, weak_crypto_scan, electron_dangerous_apis_scan,
sqli_pattern_scan, react_xss_patterns_scan, node_dangerous_runtime_scan,
python_dangerous_api_scan, mandatory_db_preflight, nvd_api_key_check) adja az
eredmenyt. A .trivyignore fajl LETEZIK (CVE-suppressionok az OWASP
dependency-check-hez), de ez NEM jelenti trivy hasznalatat -- csak kontextuskent
irjuk ki a CVE-sorok szamat.

Bemenet (REPO/security-reports/latest/ alatt, mind csak olvasva):
  gate-status.json -- {timestamp, status, stacks{...}, checks:[{check,status,
    command,output,note}]}.
  frontend_npm_audit_prod.txt, electron_npm_audit_prod.txt,
  backend_dependency_check.txt, python_pip_audit.txt -- mindegyik azonos
  fejlecu: "Command: ...\\nStatus: PASSED|FAILED\\nNote: ...\\n--- STDOUT ---...".
  A "Status:" sor + egy opcionalis "found N vulnerabilities" minta adja az
  osszegzo sort minden fajlra egysegesen (igy nem kell 4 kulon parsert irni a
  maven/npm/pip-audit eltero formatumaira).

Usage:
  python t0-security-scan.py [--json]

Env:
  VALUTA_REPO  cel-repo gyokere (default: C:\\Repo\\valutavalto-program)

Exit: 0 = status PASSED, nincs buko check, a riport <=7 napos, 1 = status!=PASSED
      VAGY van buko check VAGY a riport elavult (>7 nap -- ONMAGABAN IS lelet),
      2 = gate-status.json hianyzik/serult.
"""
import argparse
import json
import os
import re
import sys
from datetime import date
from pathlib import Path

REPO        = Path(os.environ.get("VALUTA_REPO", r"C:\Repo\valutavalto-program"))
SEC_DIR     = REPO / "security-reports" / "latest"
GATE_FILE   = SEC_DIR / "gate-status.json"
TRIVYIGNORE = REPO / ".trivyignore"
AUDIT_FILES = (
    "frontend_npm_audit_prod.txt",
    "electron_npm_audit_prod.txt",
    "backend_dependency_check.txt",
    "python_pip_audit.txt",
)
STALE_DAYS  = 7
VULN_RE     = re.compile(r'found\s+\d+\s+vulnerabilit\w*', re.IGNORECASE)
STATUS_RE   = re.compile(r'^Status:\s*(.+)$', re.MULTILINE)
DENYLIST    = (".env", ".env.ssh-keys", "backend_deployment")  # KOZOS KONTRAKTUS, itt nem erintett (fix fajlnevek)


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


def _stale_days(ts_raw: str):
    """Csak a datum-resz (nap-granularitas) -- robusztus barmilyen tortmasodperc-
    pontossaggal/idozona-formaval szemben (l. gate-status.json '+02:00' + 7 jegyu
    tortmasodperc, amit a datetime.fromisoformat nem mindig fogad el egysegesen)."""
    m = re.match(r'^(\d{4})-(\d{2})-(\d{2})', ts_raw or "")
    if not m:
        return None
    try:
        d = date(int(m.group(1)), int(m.group(2)), int(m.group(3)))
    except ValueError:
        return None
    return (date.today() - d).days


def _audit_summary(name: str) -> str:
    p = SEC_DIR / name
    if not p.exists():
        return f"{name}: HIANYZIK"
    try:
        txt = p.read_text(encoding="utf-8-sig", errors="replace")  # l. GATE_FILE BOM-megjegyzes fent
    except OSError as e:
        return f"{name}: OLVASASI HIBA ({e})"
    status_m = STATUS_RE.search(txt)
    vuln_m = VULN_RE.search(txt)
    summary = status_m.group(1).strip() if status_m else "?"
    if vuln_m:
        summary += f" | {vuln_m.group(0)}"
    return f"{name}: {summary}"


def main() -> int:
    ap = argparse.ArgumentParser(description="Security gate-status + audit digest Tier-0 fetcher")
    ap.add_argument("--json", action="store_true", help="egyetlen JSON-objektum emberi digest helyett")
    args = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    if not GATE_FILE.exists():
        return _tool_error(args.json, "t0-security-scan", f"gate-status.json hianyzik: {GATE_FILE}")
    try:
        # utf-8-sig: a gate-status.json-t PowerShell irja (ConvertTo-Json | Set-Content),
        # ami UTF-8 BOM-mal ir -- sima "utf-8" dekoder a BOM-ot megtartana es a
        # json.loads elsot elrontana ("Unexpected UTF-8 BOM"), l. verifikacio.
        data = json.loads(GATE_FILE.read_text(encoding="utf-8-sig", errors="replace"))
    except json.JSONDecodeError as e:
        return _tool_error(args.json, "t0-security-scan", f"gate-status.json serult: {e}")

    status   = data.get("status", "?")
    ts_raw   = data.get("timestamp", "")
    checks   = data.get("checks", []) or []
    failing  = [c for c in checks if c.get("status") != "PASSED"]
    age_days = _stale_days(ts_raw)
    stale    = age_days is None or age_days > STALE_DAYS

    audit_summaries = [_audit_summary(n) for n in AUDIT_FILES]

    trivy_note = None
    if TRIVYIGNORE.exists():
        try:
            cve_lines = [l for l in TRIVYIGNORE.read_text(encoding="utf-8-sig", errors="replace").splitlines()
                         if re.match(r'^CVE-\d{4}-\d+$', l.strip())]
            trivy_note = f".trivyignore jelen van, {len(cve_lines)} CVE-suppresszio sor (trivy-riport NINCS a repoban)"
        except OSError:
            trivy_note = ".trivyignore letezik, de nem olvashato"

    finding = (status != "PASSED") or bool(failing) or stale
    exit_code = 1 if finding else 0

    if args.json:
        print(json.dumps({
            "script": "t0-security-scan",
            "exit_code": exit_code,
            "status": status,
            "timestamp": ts_raw,
            "age_days": age_days,
            "stale": stale,
            "checks_total": len(checks),
            "failing_checks": failing,
            "audit_summaries": audit_summaries,
            "trivyignore_note": trivy_note,
        }, ensure_ascii=False, indent=2))
        return exit_code

    lines = [
        f"[gate-status] {status}  timestamp={ts_raw}  kor={age_days if age_days is not None else '?'} nap"
        f"{'  <== ELAVULT (>7 nap)' if stale else ''}",
        f"[checks] {len(checks)} db, buko: {len(failing)} db",
    ]
    for c in failing[:15]:
        lines.append(f"    HIBA [{c.get('check')}] {c.get('status')} ({c.get('note', '')})")
    lines.append("[audit-osszegzok]")
    for s in audit_summaries:
        lines.append(f"    {s}")
    if trivy_note:
        lines.append(f"[megjegyzes] {trivy_note}")
    if stale:
        lines.append("  ⚠  elavult riport — futtasd ujra a security-kaput")
    lines.append(f"[osszegzes] finding={finding}")
    print_digest(lines)
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
