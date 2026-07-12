#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
t0-frontend-tests.py -- Tier-0 fetcher: vitest teszt-digest (frontend-react +
penztar-client).

A ket kliens vitest-configjaban NINCS JSON-riporter beallitva, ezert a script
maga hivja meg CLI-flagekkel (cwd=REPO, a kliens iranyitasat a --prefix vegzi):
  npm --prefix <kliens> run test -- --reporter=json --outputFile=<tmp.json> --run

Megjegyzes: frontend-react "test" scriptje "vitest run", penztar-client-e
"vitest --config vitest.config.ts --run" -- a -- utani flagek EHHEZ fuzodnek
hozza (nem cserelik le), ezert a --outputFile mindig abszolut utvonal.

Env-mock (nincs npm-hivas, kozvetlenul fajlbol olvas):
  T0_VITEST_JSON_FR -- frontend-react vitest JSON kimenetenek utja
  T0_VITEST_JSON_PC -- penztar-client vitest JSON kimenetenek utja

Exit: 0 = nincs bukas, 1 = van bukott teszt, 2 = npm-hiba / hianyzo-hibas JSON.
"""
import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

REPO = Path(os.environ.get("VALUTA_REPO", r"C:\Repo\valutavalto-program"))
CLIENTS = {"frontend-react": "T0_VITEST_JSON_FR", "penztar-client": "T0_VITEST_JSON_PC"}
MAX_FAILURES_SHOWN = 15


def print_digest(lines, limit=120):
    if len(lines) <= limit:
        for line in lines:
            print(line)
        return
    for line in lines[: limit - 1]:
        print(line)
    print(f"... ({len(lines) - (limit - 1)} tovabbi sor levagva, hasznald a --json kapcsolot)")


def resolve_npm() -> str:
    """PATHEXT-tudatos feloldas -- Windows alatt npm .cmd shim-kent bujik el,
    a subprocess pedig shell=False mellett nem keresi vegig a PATHEXT-et."""
    return shutil.which("npm") or "npm"


def client_result(source, tool_error, total=None, failed=None, failures=None):
    return {"source": source, "tool_error": tool_error, "total": total, "failed": failed, "failures": failures or []}


def run_vitest_json(client: str):
    """npm-mel lefuttatja a vitestet JSON riporterrel. (kimeneti_fajl|None, tool_error|None, tmp_path)."""
    fd, tmp_path = tempfile.mkstemp(prefix=f"t0-vitest-{client}-", suffix=".json")
    os.close(fd)
    try:
        proc = subprocess.run(
            [resolve_npm(), "--prefix", str(REPO / client), "run", "test", "--",
             "--reporter=json", f"--outputFile={tmp_path}", "--run"],
            cwd=str(REPO), capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=900,
        )
    except (OSError, subprocess.SubprocessError) as e:
        return None, f"npm inditasa sikertelen ({client}): {e}", tmp_path

    out_file = Path(tmp_path)
    if not out_file.is_file() or out_file.stat().st_size == 0:
        tail = (proc.stderr or proc.stdout or "").strip()[-500:]
        return None, f"npm exit={proc.returncode}, nincs vitest JSON kimenet ({client}): {tail}", tmp_path
    return out_file, None, tmp_path


def parse_vitest_json(path: Path):
    data = json.loads(path.read_text(encoding="utf-8", errors="replace"))
    failures = []
    for suite in data.get("testResults", []):
        for assertion in suite.get("assertionResults", []):
            if assertion.get("status") == "failed":
                msgs = assertion.get("failureMessages") or []
                first_msg = (msgs[0].splitlines()[0] if msgs and msgs[0] else "")[:300]
                failures.append({
                    "file": suite.get("name", "(ismeretlen fajl)"),
                    "test": assertion.get("fullName") or assertion.get("title") or "(ismeretlen teszt)",
                    "message": first_msg,
                })
    return data.get("numTotalTests", 0), data.get("numFailedTests", 0), failures


def collect_client(client: str, env_var: str):
    mock_path = os.environ.get(env_var)
    source_label = "env-mock" if mock_path else "npm"
    tmp_to_clean = None
    try:
        if mock_path:
            source = Path(mock_path)
            if not source.is_file():
                return client_result(source_label, f"hianyzo mock fajl: {mock_path}")
        else:
            source, err, tmp_to_clean = run_vitest_json(client)
            if source is None:
                return client_result(source_label, err)

        try:
            total, failed, failures = parse_vitest_json(source)
        except (json.JSONDecodeError, OSError, KeyError, TypeError) as exc:
            return client_result(source_label, f"vitest JSON parse hiba: {exc}")

        return client_result(source_label, None, total, failed, failures[:MAX_FAILURES_SHOWN])
    finally:
        if tmp_to_clean:
            Path(tmp_to_clean).unlink(missing_ok=True)


def main() -> int:
    ap = argparse.ArgumentParser(description="Vitest teszt-digest (frontend-react + penztar-client) Tier-0 fetcher")
    ap.add_argument("--json", action="store_true", help="egyetlen JSON-objektum emberi digest helyett")
    args = ap.parse_args()

    results = {client: collect_client(client, env_var) for client, env_var in CLIENTS.items()}
    tool_error = any(r["tool_error"] for r in results.values())
    any_failed = any((r["failed"] or 0) > 0 for r in results.values() if not r["tool_error"])
    exit_code = 2 if tool_error else (1 if any_failed else 0)

    if args.json:
        print(json.dumps({"script": "t0-frontend-tests", "exit_code": exit_code, "clients": results},
                          ensure_ascii=False, indent=2))
        return exit_code

    lines = [f"[t0-frontend-tests] exit_code={exit_code}"]
    for client, r in results.items():
        if r["tool_error"]:
            lines.append(f"  {client}: TOOL-HIBA -- {r['tool_error']}")
            continue
        lines.append(f"  {client} ({r['source']}): total={r['total']} failed={r['failed']}")
        lines.extend(f"    [{f['file']}] {f['test']}: {f['message']}" for f in r["failures"])
    print_digest(lines)
    return exit_code


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:  # varatlan hiba -- soha ne szalljon el nyers tracebackkel
        print(f"[t0-frontend-tests] varatlan hiba: {exc}", file=sys.stderr)
        sys.exit(2)
