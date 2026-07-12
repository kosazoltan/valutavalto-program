#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
t0-lint-typecheck.py -- Tier-0 fetcher: 4 kliens typecheck + frontend-react
lint digest.

Elesben: `npm --prefix <kliens> run typecheck` mind a 4 kliensre. A "typecheck"
scriptnevet NEM hardcodeoljuk vakon: minden futtatas elott beolvassuk a kliens
package.json-jat es csak akkor hivjuk, ha tenyleg van "typecheck" kulcs a
scripts-ben (ma mind a 4-nel van, de ne feltetelezzuk statikusan).
Lint: `npm --prefix frontend-react run lint` KOZVETLENUL -- a root "lint"
script sajat self-check-gateket huzna be, azt innen tilos hivni.

FIGYELEM: kozponti-client es arfolyam-keszito-client typecheckje a
frontend-react/node_modules/typescript binarisra mutat. Ha az nincs telepitve,
a hiba nem "error TSxxxx" alaku tsc-diagnosztika, hanem npm/node inditasi hiba
-- ezt exit=2-vel es "npm install kell a frontend-react-ben" utalassal jelezzuk.

Env-mock (nincs npm-hivas): T0_TYPECHECK_LOG_DIR -- <dir>/<kliens>.log (a 4
kliensre) es <dir>/lint.log fajlokbol olvas npm-futtatas helyett.

Exit: 0 = nincs hiba, 1 = van tsc/eslint hiba, 2 = npm-inditasi hiba.
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

REPO = Path(os.environ.get("VALUTA_REPO", r"C:\Repo\valutavalto-program"))
CLIENTS = ["frontend-react", "penztar-client", "kozponti-client", "arfolyam-keszito-client"]
LINT_PACKAGE = "frontend-react"
MAX_SAMPLE_LINES = 15
TSC_ERROR_RE = re.compile(r"error TS\d+")
ESLINT_SUMMARY_RE = re.compile(r"\((\d+)\s+errors?,\s*(\d+)\s+warnings?\)")


def print_digest(lines, limit=120):
    if len(lines) <= limit:
        for line in lines:
            print(line)
        return
    for line in lines[: limit - 1]:
        print(line)
    print(f"... ({len(lines) - (limit - 1)} tovabbi sor levagva, hasznald a --json kapcsolot)")


def resolve_npm() -> str:
    """PATHEXT-tudatos feloldas -- Windows alatt npm .cmd shim-kent bujik el."""
    return shutil.which("npm") or "npm"


def read_mock(log_dir: str, stem: str):
    path = Path(log_dir) / f"{stem}.log"
    if not path.is_file():
        return None, f"hianyzo mock log: {path}"
    return path.read_text(encoding="utf-8", errors="replace"), None


def run_npm_script(client_dir: Path, script: str):
    try:
        proc = subprocess.run(
            [resolve_npm(), "--prefix", str(client_dir), "run", script],
            cwd=str(REPO), capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=600,
        )
    except (OSError, subprocess.SubprocessError) as exc:
        return None, None, f"npm inditasa sikertelen: {exc}"
    return proc.stdout or "", proc.returncode, proc.stderr or ""


def typecheck_client(client: str, log_dir: str):
    if log_dir:
        output, err = read_mock(log_dir, client)
        if err:
            return {"error_count": None, "sample_lines": [], "tool_error": err}
        returncode = None
    else:
        pkg_path = REPO / client / "package.json"
        try:
            pkg = json.loads(pkg_path.read_text(encoding="utf-8", errors="replace"))
        except (OSError, json.JSONDecodeError) as exc:
            return {"error_count": None, "sample_lines": [], "tool_error": f"package.json olvasasi hiba: {exc}"}
        if "typecheck" not in (pkg.get("scripts") or {}):
            return {"error_count": None, "sample_lines": [], "tool_error": f"nincs 'typecheck' script: {pkg_path}"}

        stdout, returncode, stderr = run_npm_script(REPO / client, "typecheck")
        if stdout is None:
            return {"error_count": None, "sample_lines": [], "tool_error": stderr}
        output = stdout + stderr

    errors = TSC_ERROR_RE.findall(output)
    error_lines = [l for l in output.splitlines() if "error TS" in l]
    if not errors and returncode not in (0, None):
        low = output.lower()
        hint = " (npm install kell a frontend-react-ben?)" if "typescript" in low and "cannot find" in low else ""
        return {"error_count": None, "sample_lines": output.strip().splitlines()[-MAX_SAMPLE_LINES:],
                "tool_error": f"npm exit={returncode}, nincs tsc-hibasor a kimenetben{hint}"}

    return {"error_count": len(errors), "sample_lines": error_lines[:MAX_SAMPLE_LINES], "tool_error": None}


def lint_frontend(log_dir: str):
    if log_dir:
        output, err = read_mock(log_dir, "lint")
        if err:
            return {"error_count": None, "warning_count": None, "sample_lines": [], "tool_error": err}
        returncode = None
    else:
        stdout, returncode, stderr = run_npm_script(REPO / LINT_PACKAGE, "lint")
        if stdout is None:
            return {"error_count": None, "warning_count": None, "sample_lines": [], "tool_error": stderr}
        output = stdout + stderr

    m = ESLINT_SUMMARY_RE.search(output)
    if m:
        error_count, warning_count, tool_error = int(m.group(1)), int(m.group(2)), None
    elif returncode in (0, None):
        # ESLint stylish formatter nema kimenetet ad, ha nincs talalat -- ez a zold eset.
        error_count, warning_count, tool_error = 0, 0, None
    else:
        error_count = warning_count = None
        tool_error = f"npm exit={returncode}, nincs eslint osszegzo sor a kimenetben"

    lines = [l for l in output.splitlines() if l.strip()]
    return {"error_count": error_count, "warning_count": warning_count,
            "sample_lines": lines[:MAX_SAMPLE_LINES], "tool_error": tool_error}


def main() -> int:
    ap = argparse.ArgumentParser(description="4 kliens typecheck + frontend-react lint Tier-0 fetcher")
    ap.add_argument("--json", action="store_true", help="egyetlen JSON-objektum emberi digest helyett")
    args = ap.parse_args()
    log_dir = os.environ.get("T0_TYPECHECK_LOG_DIR")

    typecheck_results = {c: typecheck_client(c, log_dir) for c in CLIENTS}
    lint_result = lint_frontend(log_dir)

    tool_error = any(r["tool_error"] for r in typecheck_results.values()) or bool(lint_result["tool_error"])
    any_errors = any((r["error_count"] or 0) > 0 for r in typecheck_results.values() if not r["tool_error"])
    if not lint_result["tool_error"] and (lint_result["error_count"] or 0) > 0:
        any_errors = True
    exit_code = 2 if tool_error else (1 if any_errors else 0)

    if args.json:
        print(json.dumps({
            "script": "t0-lint-typecheck", "exit_code": exit_code,
            "typecheck": typecheck_results, "lint": {"package": LINT_PACKAGE, **lint_result},
        }, ensure_ascii=False, indent=2))
        return exit_code

    lines = [f"[t0-lint-typecheck] exit_code={exit_code}"]
    for c, r in typecheck_results.items():
        if r["tool_error"]:
            lines.append(f"  typecheck {c}: TOOL-HIBA -- {r['tool_error']}")
        else:
            lines.append(f"  typecheck {c}: {r['error_count']} hiba")
        lines.extend(f"    {l}" for l in r["sample_lines"])
    if lint_result["tool_error"]:
        lines.append(f"  lint {LINT_PACKAGE}: TOOL-HIBA -- {lint_result['tool_error']}")
    else:
        lines.append(f"  lint {LINT_PACKAGE}: {lint_result['error_count']} hiba, {lint_result['warning_count']} warning")
    lines.extend(f"    {l}" for l in lint_result["sample_lines"])
    print_digest(lines)
    return exit_code


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:  # varatlan hiba -- soha ne szalljon el nyers tracebackkel
        print(f"[t0-lint-typecheck] varatlan hiba: {exc}", file=sys.stderr)
        sys.exit(2)
