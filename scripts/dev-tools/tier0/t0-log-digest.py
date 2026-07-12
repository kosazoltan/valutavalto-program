#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
t0-log-digest.py -- Tier-0 fetcher: helyi logok digestje.

Nem a cel-repot olvassa (a logok kulon konyvtarban vannak) -- de a VALUTA_REPO
konvenciot a KOZOS KONTRAKTUS miatt itt is definialjuk, hasznalat nelkul is.

Bemenet: log-konyvtarak listaja, alapertelmezetten "C:\\tmp\\logs;C:\\tmp"
(pontosvesszovel elvalasztva, a CI_DIGEST_LOCAL_LOG_DIRS mintajara), env
T0_LOG_DIRS-szel felulirhato. A repo collect-logs.mjs-e "/tmp/logs"-ba ir,
ami Windowson C:\\tmp\\logs-nak felel meg.

Minden felsorolt konyvtarban *.log fajlokat keresunk (nem rekurziv -- ezek
lapos log-konyvtarak). Komponens = fajl (a fajlnev a komponens-azonosito;
azonos nevu fajl kesobbi konyvtarban a teljes utvonallal disambigualodik).
Komponensenkent: ERROR/WARN sorok darabszama, az ELSO ERROR-sor + az azt
koveto legfeljebb 9 sor (heurisztikus "stack-jelolt" -- a script nem ismeri
a konkret log-formatumot, ezert a kovetkezo sorokat vesszuk a lehetseges
stack-trace resznek), utolso modositas ideje (ISO-8601).

Ures/hianyzo konyvtarak (egyik konyvtarban sincs egyetlen *.log sem):
"nincs osszegyujtott log -- futtasd: node scripts/collect-logs.mjs" es exit 0
(ez allapot, nem hiba).

Exit: van ERROR barmelyik komponensben -> 1; csak WARN/semmi -> 0.
(Ez a script tool-hibat -- exit 2 -- nem general: hianyzo konyvtar allapot,
nem hiba; olvasasi hiba egy-egy fajlnal a komponens sorat "olvasasi hiba"
jelzessel jeloli, de nem szakitja meg a tobbi komponens feldolgozasat.)
"""
import argparse
import json
import os
import re
import sys
from datetime import datetime
from pathlib import Path

REPO = Path(os.environ.get("VALUTA_REPO", r"C:\Repo\valutavalto-program"))  # KOZOS KONTRAKTUS, itt nem hasznalt
DEFAULT_LOG_DIRS = r"C:\tmp\logs;C:\tmp"
ERR_PATTERN = re.compile(r"ERROR")
WARN_PATTERN = re.compile(r"WARN")


def print_digest(lines, limit=120):
    if len(lines) <= limit:
        for line in lines:
            print(line)
        return
    for line in lines[: limit - 1]:
        print(line)
    print(f"... ({len(lines) - (limit - 1)} tovabbi sor levagva, hasznald a --json kapcsolot)")


def collect_log_files(dirs):
    """Visszaadja a (label, Path) parokat -- label a fajlnev, utkozesnel a teljes ut."""
    seen_names = set()
    result = []
    for d in dirs:
        dir_path = Path(d)
        if not dir_path.is_dir():
            continue
        for f in sorted(dir_path.glob("*.log")):
            label = f.name
            if label in seen_names:
                label = str(f)
            seen_names.add(f.name)
            result.append((label, f))
    return result


def digest_component(label: str, path: Path) -> dict:
    try:
        mtime = datetime.fromtimestamp(path.stat().st_mtime).isoformat()
    except OSError as e:
        return {"name": label, "path": str(path), "read_error": str(e)}
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            lines = f.readlines()
    except OSError as e:
        return {"name": label, "path": str(path), "mtime": mtime, "read_error": str(e)}

    error_count = sum(1 for line in lines if ERR_PATTERN.search(line))
    warn_count = sum(1 for line in lines if WARN_PATTERN.search(line))
    first_error_excerpt = []
    for i, line in enumerate(lines):
        if ERR_PATTERN.search(line):
            first_error_excerpt = [l.rstrip("\n") for l in lines[i : i + 10]]
            break

    return {
        "name": label, "path": str(path), "mtime": mtime,
        "error_count": error_count, "warn_count": warn_count,
        "first_error_excerpt": first_error_excerpt,
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Helyi logok digestje Tier-0 fetcher")
    ap.add_argument("--json", action="store_true", help="egyetlen JSON-objektum emberi digest helyett")
    args = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    dirs = [d for d in os.environ.get("T0_LOG_DIRS", DEFAULT_LOG_DIRS).split(";") if d]
    files = collect_log_files(dirs)

    if not files:
        message = "nincs osszegyujtott log -- futtasd: node scripts/collect-logs.mjs"
        if args.json:
            print(json.dumps({
                "script": "t0-log-digest", "exit_code": 0, "log_dirs": dirs,
                "empty": True, "message": message, "components": [],
            }, ensure_ascii=False, indent=2))
        else:
            print_digest([f"[t0-log-digest] {message}", f"  vizsgalt konyvtarak: {', '.join(dirs)}"])
        return 0

    components = [digest_component(label, path) for label, path in files]
    any_error = any(c.get("error_count", 0) > 0 for c in components)
    exit_code = 1 if any_error else 0

    if args.json:
        print(json.dumps({
            "script": "t0-log-digest", "exit_code": exit_code, "log_dirs": dirs,
            "empty": False, "components": components,
        }, ensure_ascii=False, indent=2))
        return exit_code

    lines = [f"[t0-log-digest] {len(components)} komponens ({', '.join(dirs)})"]
    for c in components:
        if "read_error" in c:
            lines.append(f"  [{c['name']}] OLVASASI HIBA: {c['read_error']}")
            continue
        lines.append(f"  [{c['name']}] ERROR={c['error_count']} WARN={c['warn_count']} mtime={c['mtime']}")
        for excerpt_line in c["first_error_excerpt"]:
            lines.append(f"      {excerpt_line}")
    lines.append(f"[osszegzes] hiba_van={any_error}")
    print_digest(lines)
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
