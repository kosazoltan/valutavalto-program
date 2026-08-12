#!/usr/bin/env python3
"""NSIS silent-mode (/S) MessageBox-blokkolas ellenorzo — BLOCKING kapu.

=== MIERT LETEZIK ===
A `installer/Penztar-Setup.nsi` hibaagai `IfSilent` / `MessageBox` / `Abort`
mintat hasznalnak. NSIS-ben a relativ ugras `+1` a KOVETKEZO utasitast jelenti,
azaz NEM UGRIK SEMMIT — igy az `IfSilent +1` mellett a MessageBox nema (`/S`)
modban IS megjelenik, es a telepito orokre blokkol rajta (nincs, aki OK-t nyomjon).

Ez v2.28.78-ig 7 helyen igy volt a scriptben (a v6.1 review szandeka helyes volt,
a megvalositas fordult meg). Egy penztargepen ez "fagyott telepitot" jelent, es a
tervezett suite-updater (`/S` csendes upgrade) pontosan ezen akadna el.

Empirikus bizonyitas (2026-08-12, makensis 3.x):
  IfSilent +1  -> a MessageBox MEGJELENT /S modban, a process timeoutolt (exit 124)
  IfSilent +2 0 -> atugrotta, lefutott (exit 0)

=== MIT ELLENORIZ ===
A LEFORDITOTT utasityaslistat (makensis /V4), nem a forras-szoveget: minden
`IfSilent` ugras celjat megvizsgalja, es bukik, ha barmelyik `?+1:` (nem ugras)
egy MessageBox ELE van tuzve. Ez azert erosebb a forras-grepnel, mert a makro-
expanzio utani tenyleges utasitas-sorrendet meri.

=== HASZNALAT ===
  python installer/tests/nsis-silent-mode-guard.py            # teljes kapu
  python installer/tests/nsis-silent-mode-guard.py --self-test # bukaskepesseg-proba

Exit 0 = PASS, 1 = szabalysertes, 2 = a kapu nem futtathato (makensis/stage hiany).
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
INSTALLER_DIR = REPO / 'installer'
SETUP_NSI = INSTALLER_DIR / 'Penztar-Setup.nsi'

MAKENSIS_CANDIDATES = [
    Path(r'C:\Program Files (x86)\NSIS\makensis.exe'),
    Path(r'C:\Program Files\NSIS\makensis.exe'),
]

# A dummy stage-fa: minden `File` direktiva feloldhato legyen.
STAGE_FILES = [
    'electron/icudtl.dat',
    'electron/resources.pak',
    'electron/v8_context_snapshot.bin',
    'electron/snapshot_blob.bin',
    'electron/chrome_100_percent.pak',
    'electron/chrome_200_percent.pak',
    'electron/ffmpeg.dll',
    'electron/Penztar.exe',
    'electron/locales/en-US.pak',
    'electron/locales/hu.pak',
    'electron/resources/app.asar',
    'pgsql/bin/postgres.exe',
    'jre/bin/java.exe',
    'backend/valuta-backend.jar',
    'tools/nssm.exe',
    'tools/vc_redist.x64.exe',
    'scripts/diagnose-penztar-network.ps1',
    'scripts/init.sql',
]


def find_makensis() -> Path | None:
    found = shutil.which('makensis')
    if found:
        return Path(found)
    for candidate in MAKENSIS_CANDIDATES:
        if candidate.exists():
            return candidate
    return None


def build_stage(root: Path) -> None:
    for rel in STAGE_FILES:
        target = root / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(b'dummy')


def compile_listing(makensis: Path, nsi: Path, stage: Path, out: Path) -> str:
    """Lefordítja a scriptet /V4-en, es visszaadja az utasityas-listat."""
    cmd = [
        str(makensis),
        '/V4',
        '/DVERSION=2.28.79',
        '/DBUILD_DATE=20260812',
        f'/DSTAGE_DIR={stage}',
        f'/DOUTPUT_DIR={out}',
        nsi.name,
    ]
    proc = subprocess.run(
        cmd,
        cwd=str(nsi.parent),
        capture_output=True,
        text=True,
        errors='replace',
    )
    if proc.returncode != 0:
        print('[nsis-silent-guard] makensis FORDITASI HIBA:')
        print((proc.stdout or '')[-3000:])
        print((proc.stderr or '')[-2000:])
        raise SystemExit(2)
    return proc.stdout or ''


def analyse(listing: str) -> tuple[int, list[str]]:
    """Visszaadja: (osszes IfSilent, hibas ugrasok leirasa)."""
    lines = listing.splitlines()
    total = 0
    failures: list[str] = []
    for i, line in enumerate(lines):
        if not line.startswith('IfSilent'):
            continue
        total += 1
        target = line.strip()
        following = lines[i + 1].strip() if i + 1 < len(lines) else ''
        # `?+1:` / `?+1:0` = a kovetkezo utasitasra "ugrik", azaz nem ugrik semmit.
        if re.match(r'^IfSilent \?\+1:', target):
            if following.startswith('MessageBox'):
                failures.append(
                    f'{target} -> {following[:70]} '
                    '(a MessageBox /S modban IS megjelenne, a nema telepito blokkolna)'
                )
            else:
                failures.append(f'{target} -> {following[:70]} (gyanus: +1 nem ugrik semmit)')
    return total, failures


def run_guard(nsi: Path) -> int:
    makensis = find_makensis()
    if makensis is None:
        print('[nsis-silent-guard] SKIP — makensis nem talalhato ezen a gepen.')
        print('  Telepitsd az NSIS-t, vagy futtasd a kaput Windows build-gepen.')
        return 2
    with tempfile.TemporaryDirectory(prefix='nsis-guard-stage-') as stage_dir, tempfile.TemporaryDirectory(
        prefix='nsis-guard-out-'
    ) as out_dir:
        stage = Path(stage_dir)
        build_stage(stage)
        listing = compile_listing(makensis, nsi, stage, Path(out_dir))
    total, failures = analyse(listing)
    print(f'[nsis-silent-guard] vizsgalt IfSilent utasitas: {total}')
    if failures:
        print(f'[nsis-silent-guard] {len(failures)} SZABALYSERTES:')
        for item in failures:
            print(f'  [FAIL] {item}')
        print()
        print('  Javitas: `IfSilent +2 0` — igy a MessageBox kimarad es a RA KOVETKEZO')
        print('  utasitas (tipikusan Abort) fut le. A `+1` NEM ugras.')
        return 1
    print('[nsis-silent-guard] OK — egyetlen MessageBox sem blokkolhatja a /S telepitest.')
    return 0


def self_test(nsi: Path) -> int:
    """Bizonyitja, hogy a kapu BUKASKEPES: `+2 0` -> `+1` mutacioval kell buknia."""
    original = nsi.read_bytes()
    text = original.decode('utf-8')
    mutated, count = re.subn(r'(?m)^([ \t]*)IfSilent \+2 0(?=\r?\n)', r'\1IfSilent +1', text, count=1)
    if not count:
        print('[nsis-silent-guard] SELF-TEST SKIP — nincs `IfSilent +2 0` minta a scriptben.')
        return 2
    print('[nsis-silent-guard] SELF-TEST: 1 db `IfSilent +2 0` -> `IfSilent +1` mutacio...')
    try:
        nsi.write_bytes(mutated.encode('utf-8'))
        rc = run_guard(nsi)
    finally:
        nsi.write_bytes(original)
    if rc == 1:
        print('[nsis-silent-guard] SELF-TEST PASS — a kapu bukasképes.')
        restored = run_guard(nsi)
        if restored != 0:
            print('[nsis-silent-guard] SELF-TEST HIBA — visszaallitas utan sem zold!')
            return 1
        return 0
    print(f'[nsis-silent-guard] SELF-TEST FAIL — a mutacio NEM buktatta a kaput (rc={rc}).')
    return 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--self-test', action='store_true', help='bukaskepesseg-proba mutacioval')
    parser.add_argument('--nsi', default=str(SETUP_NSI), help='a vizsgalt NSI fajl')
    args = parser.parse_args()
    nsi = Path(args.nsi)
    if not nsi.exists():
        print(f'[nsis-silent-guard] HIBA — nincs ilyen fajl: {nsi}')
        return 2
    return self_test(nsi) if args.self_test else run_guard(nsi)


if __name__ == '__main__':
    sys.exit(main())
