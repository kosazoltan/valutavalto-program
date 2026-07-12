#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
t0-rate-feeds.py -- Tier-0 fetcher: arfolyam-feed statusz (UZEMKRITIKUS).

Cel-repo (csak OLVASVA, sosem irva): VALUTA_REPO env vagy alapertelmezetten
C:\\Repo\\valutavalto-program.

Harom forras:
  (a) `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/monitoring-preflight.ps1`
      cwd=REPO. A ps1 sajat exit-kodja 1, ha failed>0. A stdout utolso soraiban
      "passed=X, failed=Y, skipped=Z" + "summary: <ut>" jelenik meg; ebbol
      betoltjuk a summary.json-t (checks[] lista area/name/status/evidence/expected
      mezokkel), es a FAIL statuszu checkek nevet kigyujtjuk.
  (b) prod BankIntegrationStatus-szeru vegpont: api_url+"/bank-integration/status" GET.
      Ha 401/403/404 -> EZ NEM tool-hiba: "auth-vedett/nem elerheto -- kihagyva",
      es folytatjuk. FONTOS (dokumentalt dontes): a (b) eredmenye a feladatleiras
      exit-kod kontraktusaban NEM szerepel ("preflight failed>0 VAGY logban
      feed-hibaminta -> 1") -- ezert ez a check TISZTAN INFORMACIOS, sosem
      valtoztatja meg az exit-kodot, akkor sem, ha peldaul 500-at vagy
      kapcsolodasi hibat ad. Az eredmenye a digest/JSON kimenetben mindig lathato.
  (c) scheduler-log scan: alapertelmezett C:\\tmp\\logs\\backend.log (a
      collect-logs.mjs "/tmp/logs"-ba ir, ami Windowson a C:\\tmp\\logs-nak felel
      meg -- FUGGETLEN a REPO utvonaltol). "MNB"/"ECB"/"Raiffeisen" +
      "ERROR"/"WARN" egyutt szereplo sorok = feed-hibaminta. Heurisztika az
      "utolso sikeres fetch-minta"-hoz: az utolso olyan bank-nevet tartalmazo
      sor, amely NEM ERROR/WARN (a backend log.info hivasai a tenyleges sikeres/
      allapot-sorok, l. ExchangeRatePollingService.java) -- ez info-szintu
      minta, nem szigoruan garantalt "siker", ezert a kimenetben igy is jelolt.

Env-mock:
  T0_PREFLIGHT_SUMMARY -- kesz summary.json fajl utja (powershell-futtatas helyett).
  T0_HEALTH_MOCK_DIR   -- mint a t0-prod-health.py-ban: <dir>/<url_safe_name>.json
                          fajlokbol valaszol a (b) HTTP-hivasra valodi halozat helyett.
                          Fajlnev-kepzes es tartalom-sema azonos (l. ott).
  T0_BACKEND_LOG        -- a (c) logfajl utjanak felulirasa.

Exit: preflight failed>0 VAGY a logban feed-hibaminta -> 1; minden zold -> 0;
a summary SEHOGY sem elerheto (se mock, se live futtatas nem ad hasznalhato
summary.json-t) -> 2.
"""
import argparse
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path

REPO = Path(os.environ.get("VALUTA_REPO", r"C:\Repo\valutavalto-program"))
DEFAULT_BACKEND_LOG = r"C:\tmp\logs\backend.log"
BANK_NAMES = ("MNB", "ECB", "Raiffeisen")
ERR_PATTERN = re.compile(r"ERROR|WARN")


def print_digest(lines, limit=120):
    if len(lines) <= limit:
        for line in lines:
            print(line)
        return
    for line in lines[: limit - 1]:
        print(line)
    print(f"... ({len(lines) - (limit - 1)} tovabbi sor levagva, hasznald a --json kapcsolot)")


def url_safe_name(url: str) -> str:
    return re.sub(r"[^A-Za-z0-9]+", "_", url).strip("_")


def fetch(url: str, timeout: int = 10):
    """(status:int|None, body:str, error:str|None) -- l. t0-prod-health.py fetch()."""
    mock_dir = os.environ.get("T0_HEALTH_MOCK_DIR")
    if mock_dir:
        mock_path = Path(mock_dir) / f"{url_safe_name(url)}.json"
        if not mock_path.exists():
            return None, "", f"mock hianyzik: {mock_path}"
        try:
            with open(mock_path, "r", encoding="utf-8", errors="replace") as f:
                data = json.load(f)
        except (OSError, ValueError) as e:
            return None, "", f"mock parse hiba: {e}"
        if "error" in data:
            return None, "", str(data["error"])
        return int(data.get("status", 200)), str(data.get("body", "")), None
    try:
        req = urllib.request.Request(url, method="GET", headers={"User-Agent": "hermes-t0-rate-feeds/1"})
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.status, resp.read().decode("utf-8", errors="replace"), None
    except urllib.error.HTTPError as e:
        try:
            body = e.read().decode("utf-8", errors="replace")
        except (OSError, ValueError):
            body = ""
        return e.code, body, None
    except (urllib.error.URLError, OSError, TimeoutError) as e:
        return None, "", str(e)


def get_preflight_summary():
    """(summary:dict|None, source:str, tool_error:str|None)."""
    override = os.environ.get("T0_PREFLIGHT_SUMMARY")
    if override:
        try:
            with open(override, "r", encoding="utf-8", errors="replace") as f:
                return json.load(f), "override", None
        except (OSError, ValueError) as e:
            return None, "override", f"T0_PREFLIGHT_SUMMARY nem olvashato: {e}"

    ps1 = REPO / "scripts" / "monitoring-preflight.ps1"
    try:
        proc = subprocess.run(
            ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", str(ps1)],
            cwd=str(REPO), capture_output=True, text=True, timeout=600,
        )
    except (OSError, subprocess.SubprocessError) as e:
        return None, "live", f"monitoring-preflight.ps1 inditasa sikertelen: {e}"

    summary_path = None
    for line in proc.stdout.splitlines():
        m = re.search(r"summary:\s*(.+)$", line.strip())
        if m:
            summary_path = m.group(1).strip()
    if not summary_path:
        return None, "live", "summary.json ut nem talalhato a preflight stdout-jaban"
    try:
        with open(summary_path, "r", encoding="utf-8", errors="replace") as f:
            return json.load(f), "live", None
    except (OSError, ValueError) as e:
        return None, "live", f"summary.json nem olvashato ({summary_path}): {e}"


def check_bank_integration_status() -> dict:
    api_url = None
    try:
        with open(REPO / "config" / "production-urls.json", "r", encoding="utf-8", errors="replace") as f:
            api_url = json.load(f).get("api_url")
    except (OSError, ValueError):
        pass
    if not api_url:
        return {"url": None, "outcome": "skipped", "detail": "api_url nem allapithato meg (config hianyzik/parse-hiba)"}

    url = api_url.rstrip("/") + "/bank-integration/status"
    status, _body, error = fetch(url)
    if status in (401, 403, 404):
        return {"url": url, "status": status, "outcome": "skipped", "detail": "auth-vedett/nem elerheto -- kihagyva"}
    if status == 200:
        return {"url": url, "status": status, "outcome": "ok", "detail": "elerheto"}
    return {"url": url, "status": status, "outcome": "finding", "detail": error or f"varatlan statusz: {status}"}


def scan_backend_log():
    log_path = Path(os.environ.get("T0_BACKEND_LOG", DEFAULT_BACKEND_LOG))
    if not log_path.exists():
        return {"path": str(log_path), "found": False, "error_lines": [], "last_info_line": None}
    try:
        with open(log_path, "r", encoding="utf-8", errors="replace") as f:
            lines = f.readlines()
    except OSError as e:
        return {"path": str(log_path), "found": False, "error_lines": [], "last_info_line": None, "read_error": str(e)}

    error_lines, last_info = [], None
    for raw in lines:
        line = raw.rstrip("\n")
        if not any(bank in line for bank in BANK_NAMES):
            continue
        if ERR_PATTERN.search(line):
            error_lines.append(line)
        else:
            last_info = line
    return {"path": str(log_path), "found": True, "error_lines": error_lines[-10:], "last_info_line": last_info}


def main() -> int:
    ap = argparse.ArgumentParser(description="Arfolyam-feed statusz Tier-0 fetcher (uzemkritikus)")
    ap.add_argument("--json", action="store_true", help="egyetlen JSON-objektum emberi digest helyett")
    args = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    summary, source, tool_error = get_preflight_summary()
    if summary is None:
        print(f"[t0-rate-feeds] TOOL-HIBA: preflight summary sehogy sem elerheto ({source}): {tool_error}")
        return 2

    failed_count = int(summary.get("failed", 0))
    failed_checks = [c for c in summary.get("checks", []) if c.get("status") == "FAIL"]

    bank_check = check_bank_integration_status()
    log_result = scan_backend_log()
    feed_hiba = bool(log_result["error_lines"])

    finding = failed_count > 0 or feed_hiba
    exit_code = 1 if finding else 0

    if args.json:
        print(json.dumps({
            "script": "t0-rate-feeds",
            "exit_code": exit_code,
            "preflight": {
                "source": source, "passed": summary.get("passed"), "failed": failed_count,
                "skipped": summary.get("skipped"),
                "failed_checks": [{"area": c.get("area"), "name": c.get("name")} for c in failed_checks],
            },
            "bank_integration_status": bank_check,
            "backend_log": log_result,
            "finding": finding,
        }, ensure_ascii=False, indent=2))
        return exit_code

    lines = [f"[t0-rate-feeds] preflight ({source}): passed={summary.get('passed')} failed={failed_count} skipped={summary.get('skipped')}"]
    for c in failed_checks[:15]:
        lines.append(f"  FAIL [{c.get('area')}] {c.get('name')}")
    lines.append(f"[bank-integration-status] {bank_check['outcome']}: {bank_check['detail']} <{bank_check.get('url')}>")
    if log_result["found"]:
        lines.append(f"[backend-log] {log_result['path']}: hiba-sorok={len(log_result['error_lines'])}")
        for e in log_result["error_lines"][:10]:
            lines.append(f"  HIBA: {e}")
        if log_result["last_info_line"]:
            lines.append(f"  utolso info-szintu minta: {log_result['last_info_line']}")
    else:
        lines.append(f"[backend-log] {log_result['path']}: nem talalhato -- kihagyva")
    lines.append(f"[osszegzes] finding={finding}")
    print_digest(lines)
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
