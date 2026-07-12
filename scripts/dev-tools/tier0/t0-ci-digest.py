#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
t0-ci-digest.py -- Tier-0 fetcher: CI-hiba digest.

Elsodleges ut: `node scripts/ci-error-digest.mjs --report-only` a cel-repo
gyokerebol (cwd=REPO -- a collector sajat .agent/ci kimeneti utja cwd-fuggo),
majd a legfrissebb REPO/.agent/ci/ci-error-digest-*.md beolvasasa es
tomoritese. A collector --fail-on-findings nelkul mindig exit 0-val ter
vissza, tehat itt "node-hivas hiba" tenylegesen inditasi/futasi hibat jelent,
nem azt, hogy lelet van a digestben.

Fallback (env T0_SKIP_GH=1 VAGY a node-hivas hibaja eseten): a node-ot nem
hivja (ujra), csak a mar letezo legfrissebb digest-md-t olvassa be.

Exit: 0 = nincs blokkolo lelet ("## Summary" -> "No blocking..."), 1 = van
lelet, 2 = tool-hiba (se friss futtatas, se fallback-fajl nem elerheto).
"""
import argparse
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

REPO = Path(os.environ.get("VALUTA_REPO", r"C:\Repo\valutavalto-program"))
DIGEST_DIR = REPO / ".agent" / "ci"
MAX_SECTION_LINES = 100


def print_digest(lines, limit=120):
    if len(lines) <= limit:
        for line in lines:
            print(line)
        return
    for line in lines[: limit - 1]:
        print(line)
    print(f"... ({len(lines) - (limit - 1)} tovabbi sor levagva, hasznald a --json kapcsolot)")


def latest_digest_file():
    if not DIGEST_DIR.is_dir():
        return None
    files = sorted(DIGEST_DIR.glob("ci-error-digest-*.md"), key=lambda p: p.stat().st_mtime, reverse=True)
    return files[0] if files else None


def try_run_node():
    """Egyszer lefuttatja a node collectort. (path, tool_error) -- path=None eseten tool_error!=None."""
    script_path = REPO / "scripts" / "ci-error-digest.mjs"
    if not script_path.is_file():
        return None, f"hianyzik a collector: {script_path}"
    try:
        proc = subprocess.run(
            ["node", str(script_path), "--report-only"], cwd=str(REPO),
            capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=300,
        )
    except (OSError, subprocess.SubprocessError) as e:
        return None, f"node inditasa sikertelen: {e}"
    if proc.returncode != 0:
        return None, f"node exit={proc.returncode}: {proc.stderr.strip()[:300]}"
    for line in proc.stdout.splitlines():
        if "[ci-error-digest] wrote " in line:
            candidate = Path(line.split("wrote ", 1)[1].strip())
            if candidate.is_file():
                return candidate, None
    found = latest_digest_file()
    return (found, None) if found else (None, "a node lefutott (exit=0), de nem talalhato digest-fajl")


def extract_summary_body(text: str):
    """A '## Summary' szakasz nem-ures sorai, vagy None ha nincs ilyen szakasz."""
    lines = text.splitlines()
    start = next((i for i, l in enumerate(lines) if l.strip() == "## Summary"), None)
    if start is None:
        return None
    end = next((i for i in range(start + 1, len(lines)) if lines[i].startswith("## ")), len(lines))
    return [l for l in lines[start + 1:end] if l.strip()]


def build_section_digest(text: str, max_lines=MAX_SECTION_LINES):
    """Szakaszonkent (## fejlecek) az elso hibablokkok; a Summary mindig teljes -- max_lines sorban."""
    lines = text.splitlines()
    idxs = [i for i, l in enumerate(lines) if l.startswith("## ")] + [len(lines)]
    sections = [lines[idxs[k]:idxs[k + 1]] for k in range(len(idxs) - 1)]

    summary = next((s for s in sections if s[0].strip() == "## Summary"), ["## Summary", "(nincs Summary szakasz)"])[:20]
    others = [s for s in sections if s[0].strip() != "## Summary"]

    out, budget, skipped = [], max_lines - len(summary) - 2, 0
    for sec in others:
        if budget <= 0:
            skipped += 1
            continue
        take = sec[:max(0, min(10, budget))]
        out.extend(take)
        if len(sec) > len(take):
            out.append(f"  [... {len(sec) - len(take)} sor kihagyva ebbol a szakaszbol ...]")
        budget -= len(take)
    if skipped:
        out.append(f"[... {skipped} tovabbi szakasz kihagyva, lasd a teljes fajlt ...]")

    # A per-szakasz "kihagyva" jelzosorok a budget-en felul kerulnek be, ezert vegso
    # vagas kell -- a Summary-t ez soha nem erintheti, azt mindig teljes egeszeben tartjuk meg.
    result = out + [""] + summary
    if len(result) > max_lines:
        result = out[: max(0, max_lines - len(summary) - 1)] + [""] + summary
    return result


def emit_tool_error(message, as_json):
    if as_json:
        print(json.dumps({"script": "t0-ci-digest", "exit_code": 2, "tool_error": message}, ensure_ascii=False, indent=2))
    else:
        print(f"[t0-ci-digest] TOOL-HIBA: {message}")


def main() -> int:
    ap = argparse.ArgumentParser(description="CI-hiba digest Tier-0 fetcher")
    ap.add_argument("--json", action="store_true", help="egyetlen JSON-objektum emberi digest helyett")
    args = ap.parse_args()
    skip_gh = os.environ.get("T0_SKIP_GH") == "1"

    node_err, path, mode = None, None, "fallback"
    if not skip_gh:
        path, node_err = try_run_node()
        if path is not None:
            mode = "node"
    if path is None:
        path = latest_digest_file()
        mode = "fallback"

    if path is None:
        reason = "T0_SKIP_GH=1 (node kihagyva)" if skip_gh else (node_err or "node hiba")
        emit_tool_error(f"{reason}; nincs digest-fajl itt: {DIGEST_DIR}", args.json)
        return 2

    text = path.read_text(encoding="utf-8", errors="replace")
    summary_body = extract_summary_body(text)
    if summary_body is None:
        emit_tool_error(f"nincs '## Summary' szakasz (korrupt/regi fajl?): {path}", args.json)
        return 2

    findings = [l[2:].strip() for l in summary_body if l.startswith("- ")]
    blocking = not any("no blocking" in l.lower() for l in summary_body)
    exit_code = 1 if blocking else 0

    if args.json:
        print(json.dumps({
            "script": "t0-ci-digest", "exit_code": exit_code, "source_file": str(path),
            "mode": mode, "blocking": blocking, "findings": findings,
        }, ensure_ascii=False, indent=2))
    else:
        header = [f"[t0-ci-digest] mode={mode} forras={path}",
                  f"exit_code={exit_code} ({'lelet van' if blocking else 'zold, nincs blokkolo lelet'})", ""]
        print_digest(header + build_section_digest(text))

    return exit_code


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:  # varatlan hiba -- soha ne szalljon el nyers tracebackkel
        print(f"[t0-ci-digest] varatlan hiba: {exc}", file=sys.stderr)
        sys.exit(2)
