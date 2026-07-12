#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
t0-version-sync.py -- Tier-0 fetcher: 6-utas verzio-szinkron.

Cel-repo (csak OLVASVA, sosem irva): VALUTA_REPO env vagy alapertelmezetten
C:\\Repo\\valutavalto-program. Ez a script csak konkret, ismert fajlokat/
scripteket olvas illetve indit el a REPO-bol -- nincs repo-szintu bejaras,
igy a KOZOS KONTRAKTUS denylistje (.env*, backend_deployment/) nem erintett.

Ket forras:
  (a) `node scripts/check-four-area-alignment.mjs` cwd=REPO. Exit 0 = OK
      (stdout: "[four-area-alignment] OK" + "- jegyzet" sorok). Exit != 0 =
      HIBA (stderr: "[four-area-alignment] HIBA: ..." + "- hiba" sorok).
      Ez ellenorzi az 5 package.json (root + 4 kliens) verzio-egyezeset is.
  (b) OPCIONALIS melyebb check, CSAK T0_DEEP=1 eseten fut (alapertelmezetten
      ki van kapcsolva): `pwsh -NoLogo -NoProfile -File
      installer/scripts/check-version-bump.ps1 -RepoRoot <REPO>
      -BuildDir <REPO>/installer/build -CurrentVersion <root package.json
      verzio> -DryRun -NoAutoPatch`. Ez a 6. helyet (backend/pom.xml) is
      bevonja. A ps1 sajat exit-kodjai: 0 = KEPT_VERSION (nincs bump-igeny),
      1 = BUMP-IGENY (blokkolva, mert -NoAutoPatch), 2 = 6-utas drift/hiba
      (pl. npm hianyzik). Utolso gepi sora: "^(BUMPED_VERSION|KEPT_VERSION)=X.Y.Z$".

DOKUMENTALT DONTES az exit-kod osszevonasarol: a feladatleiras exit-kontraktusa
("alignment OK -> 0; HIBA -> 1; node/pwsh inditasi hiba -> 2") szo szerint az
(a) eredmenyere ad szabalyt, a "node/pwsh inditasi hiba" kifejezes viszont
mindket eszkozt (node ES pwsh) emliti -- ezert ha T0_DEEP=1 es a (b) lepes
FUT (nem csak inditasi hiba), az o eredmenye is beleszamit, UGYANAZZAL a
szamozassal, amit a ps1 maga is hasznal (1=blokkolt talalat, 2=strukturalis
drift/hiba) -- igy nem vezetunk be uj jelentest, csak konzisztensen
kiterjesztjuk. T0_DEEP=0/hianyzik eseten (alapertelmezett) a script kizarolag
(a) alapjan dont, szo szerint a kontraktus szerint.

Env-mock:
  T0_ALIGN_OUTPUT -- fajl az (a) nyers (stdout+stderr) kimenetevel, node-
                     futtatas helyett.
  T0_ALIGN_RC     -- az (a) szimulalt exit-kodja (a T0_ALIGN_OUTPUT-tal egyutt
                     hasznalando; alapertelmezes "0").
  (A (b) lepesre nincs kulon mock-seam a feladatleirasban -- T0_DEEP=1 csak
  elesben ertelmes; a sajat verifikaciok ezert nem fedik le T0_DEEP=1-et.)

Exit: alignment OK -> 0; HIBA -> 1; node/pwsh inditasi hiba -> 2 (l. fent a
T0_DEEP=1 kiterjesztest).
"""
import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(os.environ.get("VALUTA_REPO", r"C:\Repo\valutavalto-program"))
BUMP_LINE_RE = re.compile(r"^(BUMPED_VERSION|KEPT_VERSION)=(\d+\.\d+\.\d+)\s*$")


def print_digest(lines, limit=120):
    if len(lines) <= limit:
        for line in lines:
            print(line)
        return
    for line in lines[: limit - 1]:
        print(line)
    print(f"... ({len(lines) - (limit - 1)} tovabbi sor levagva, hasznald a --json kapcsolot)")


def get_root_version():
    try:
        with open(REPO / "package.json", "r", encoding="utf-8", errors="replace") as f:
            v = json.load(f).get("version")
        return v if isinstance(v, str) else None
    except (OSError, ValueError):
        return None


def run_alignment_check():
    """(returncode:int|None, output_text:str, tool_error:str|None)."""
    override_path = os.environ.get("T0_ALIGN_OUTPUT")
    if override_path:
        try:
            with open(override_path, "r", encoding="utf-8", errors="replace") as f:
                text = f.read()
        except OSError as e:
            return None, "", f"T0_ALIGN_OUTPUT nem olvashato: {e}"
        rc_raw = os.environ.get("T0_ALIGN_RC", "0")
        try:
            rc = int(rc_raw)
        except ValueError:
            return None, "", f"T0_ALIGN_RC nem szam: {rc_raw!r}"
        return rc, text, None

    script_path = REPO / "scripts" / "check-four-area-alignment.mjs"
    try:
        proc = subprocess.run(
            ["node", str(script_path)], cwd=str(REPO), capture_output=True, text=True, timeout=300,
        )
    except (OSError, subprocess.SubprocessError) as e:
        return None, "", f"node inditasa sikertelen: {e}"
    return proc.returncode, proc.stdout + proc.stderr, None


def run_deep_check(root_version: str):
    """(returncode:int|None, line:str|None, version:str|None, tool_error:str|None)."""
    script_path = REPO / "installer" / "scripts" / "check-version-bump.ps1"
    build_dir = REPO / "installer" / "build"
    try:
        proc = subprocess.run(
            [
                "pwsh", "-NoLogo", "-NoProfile", "-File", str(script_path),
                "-RepoRoot", str(REPO), "-BuildDir", str(build_dir),
                "-CurrentVersion", root_version, "-DryRun", "-NoAutoPatch",
            ],
            cwd=str(REPO), capture_output=True, text=True, timeout=300,
        )
    except (OSError, subprocess.SubprocessError) as e:
        return None, None, None, f"pwsh inditasa sikertelen: {e}"

    last_line, last_version = None, None
    for line in proc.stdout.splitlines():
        m = BUMP_LINE_RE.match(line.strip())
        if m:
            last_line, last_version = line.strip(), m.group(2)
    return proc.returncode, last_line, last_version, None


def main() -> int:
    ap = argparse.ArgumentParser(description="6-utas verzio-szinkron Tier-0 fetcher")
    ap.add_argument("--json", action="store_true", help="egyetlen JSON-objektum emberi digest helyett")
    args = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    root_version = get_root_version()
    rc, output_text, tool_error = run_alignment_check()
    if rc is None:
        print(f"[t0-version-sync] TOOL-HIBA: node inditasa/olvasasa sikertelen: {tool_error}")
        return 2

    summary_line = next((l for l in output_text.splitlines() if l.strip().startswith("[four-area-alignment]")), "")
    detail_lines = [l.strip() for l in output_text.splitlines() if l.strip().startswith("- ")]
    alignment_ok = rc == 0

    deep = None
    exit_code = 0 if alignment_ok else 1

    if os.environ.get("T0_DEEP") == "1":
        if not root_version:
            print("[t0-version-sync] TOOL-HIBA: T0_DEEP=1, de a root package.json verzioja nem allapithato meg")
            return 2
        deep_rc, deep_line, deep_version, deep_tool_error = run_deep_check(root_version)
        if deep_rc is None:
            print(f"[t0-version-sync] TOOL-HIBA: pwsh inditasa sikertelen: {deep_tool_error}")
            return 2
        deep = {"returncode": deep_rc, "line": deep_line, "version": deep_version}
        # Dokumentalt kiterjesztes (l. fejlec): a ps1 sajat szamozasat ujrahasznositjuk.
        if deep_rc == 2:
            exit_code = 2
        elif deep_rc == 1 and exit_code == 0:
            exit_code = 1

    if args.json:
        print(json.dumps({
            "script": "t0-version-sync",
            "exit_code": exit_code,
            "root_version": root_version,
            "alignment": {
                "source": "override" if os.environ.get("T0_ALIGN_OUTPUT") else "live",
                "returncode": rc, "ok": alignment_ok,
                "summary_line": summary_line, "details": detail_lines,
            },
            "deep_check": deep,
        }, ensure_ascii=False, indent=2))
        return exit_code

    lines = [
        f"[t0-version-sync] root verzio: {root_version}",
        f"[alignment] returncode={rc} ok={alignment_ok} -- {summary_line or '(nincs osszegzo sor)'}",
    ]
    for d in detail_lines[:20]:
        lines.append(f"    {d}")
    if deep is not None:
        lines.append(f"[deep-check] returncode={deep['returncode']} -- {deep['line'] or '(nincs BUMPED/KEPT sor)'}")
    lines.append(f"[osszegzes] exit_code={exit_code}")
    print_digest(lines)
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
