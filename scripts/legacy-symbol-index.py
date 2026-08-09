"""Build a symbol index over the legacy Delphi corpus.

Why: legacy-transfer/text holds ~2780 .pas / .dfm / .dpr files (~45 MB of
Pascal). Full-text indexing them would blow up the memory bundle, but the
question a developer actually asks -- "where did the old program do X?" -- is
answerable from symbols alone: module name, exported DLL API, form class,
procedures, SQL tables touched, and UI captions.

Output: .agent/memory/legacy/symbol-index.json (+ a compact markdown digest
that the normal memory pipeline indexes, so `memory:query --area legacy`
surfaces the modules too).

Deduplication: the corpus ships DEBUG/ and MAKEDLL/ copies of nearly every
unit. Symbols are aggregated per MODULE (the business-meaningful directory,
e.g. VALUTA/DLL/CIMLET), and each representative file is recorded once, with
MAKEDLL preferred over DEBUG as the canonical source.

Deterministic: sorted output, no timestamps inside the per-module records, so
re-running does not churn the bundle's source hashes.
"""

import json
import os
import re
import sys
from collections import defaultdict

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
CORPUS = os.path.join(ROOT, "legacy-transfer", "text")
OUT_DIR = os.path.join(ROOT, ".agent", "memory", "legacy")
OUT_JSON = os.path.join(OUT_DIR, "symbol-index.json")
OUT_DIGEST = os.path.join(OUT_DIR, "legacy-module-map.md")

# --- patterns ---------------------------------------------------------------
RE_UNIT = re.compile(r"^\s*unit\s+([A-Za-z_][\w]*)\s*;", re.I | re.M)
RE_LIBRARY = re.compile(r"^\s*library\s+([A-Za-z_][\w]*)\s*;", re.I | re.M)
RE_EXPORTS = re.compile(r"^\s*exports\s+(.+?);", re.I | re.M | re.S)
RE_CLASS = re.compile(r"^\s*(T[\w]+)\s*=\s*class\s*\(\s*(T[\w]+)\s*\)", re.I | re.M)
RE_PROC = re.compile(r"^\s*(?:procedure|function)\s+([A-Za-z_][\w]*)", re.I | re.M)
# SQL touched by the module -- table names are the bridge to the modern schema.
RE_SQL = re.compile(
    r"\b(?:from|into|update|join)\s+([A-Z][A-Z0-9_]{2,})\b", re.I)
RE_CAPTION = re.compile(r"Caption\s*=\s*'([^']{2,60})'", re.I)
RE_USES_IB = re.compile(r"\bIB(?:Query|Table|Database|CustomDataSet)\b", re.I)

SQL_NOISE = {
    "SELECT", "WHERE", "ORDER", "GROUP", "VALUES", "TABLE", "INNER", "LEFT",
    "OUTER", "RIGHT", "SET", "AND", "NOT", "NULL", "THE", "STRING", "INTEGER",
}


def read(path: str) -> str:
    with open(path, "rb") as fh:
        raw = fh.read()
    # Delphi 7 sources are Windows-1250 / Latin-2 in this corpus.
    for enc in ("utf-8", "cp1250", "latin-1"):
        try:
            return raw.decode(enc)
        except UnicodeDecodeError:
            continue
    return raw.decode("latin-1", "replace")


def module_of(rel: str) -> str:
    """Business module identity, normalised across extraction paths.

    The corpus contains the same module several times: VALUTA/DLL/CIMLET,
    SZERVER/_extracted/ERTEKTAR/etdll/cimlet, SZERVER/_extracted_auto/... etc.
    Those are the same business unit, so the module key is the last meaningful
    directory segment, upper-cased; the owning system is tracked separately.
    """
    parts = [p for p in rel.split("/")[:-1] if p]
    drop = {"debug", "makedll", "release", "__history", "backup", "bin",
            "exeproba", "proba", "temp", "tmp", "old", "obj"}
    keep = [p for p in parts if p.lower() not in drop]
    if not keep:
        return parts[0].upper() if parts else "ROOT"
    return keep[-1].upper()


# Container directories that describe the owning system rather than a module.
SYSTEM_HINTS = ("ERTEKTAR", "VALUTA", "SZERVER", "TRADE", "IBVALTO", "ARFOLYAM")


def system_of(rel: str) -> str:
    upper = [p.upper() for p in rel.split("/")]
    for hint in SYSTEM_HINTS:
        if hint in upper:
            return hint
    return upper[0] if upper else "?"


def rank(rel: str) -> int:
    """Canonical-source preference: MAKEDLL > plain > DEBUG."""
    low = rel.lower()
    if "/makedll/" in low:
        return 0
    if "/debug/" in low:
        return 2
    return 1


def main() -> int:
    if not os.path.isdir(CORPUS):
        print(f"corpus not found: {CORPUS}", file=sys.stderr)
        return 1

    modules = defaultdict(lambda: {
        "files": [], "units": set(), "libraries": set(), "exports": set(),
        "classes": set(), "procedures": set(), "sql_tables": set(),
        "captions": set(), "uses_firebird": False, "loc": 0, "systems": set(),
    })

    scanned = 0
    for dirpath, _dirs, files in os.walk(CORPUS):
        for fn in files:
            ext = os.path.splitext(fn)[1].lower()
            if ext not in (".pas", ".dpr", ".dfm"):
                continue
            full = os.path.join(dirpath, fn)
            rel = os.path.relpath(full, ROOT).replace("\\", "/")
            relc = os.path.relpath(full, CORPUS).replace("\\", "/")
            text = read(full)
            scanned += 1
            m = modules[module_of(relc)]
            m["files"].append(rel)
            m["systems"].add(system_of(relc))
            m["loc"] += text.count("\n")

            if ext in (".pas", ".dpr"):
                m["units"].update(RE_UNIT.findall(text))
                m["libraries"].update(RE_LIBRARY.findall(text))
                for blob in RE_EXPORTS.findall(text):
                    for name in re.split(r"[,\s]+", blob.strip()):
                        name = name.strip().strip(";")
                        if name and re.match(r"^[A-Za-z_]\w*$", name):
                            m["exports"].add(name)
                for cls, _parent in RE_CLASS.findall(text):
                    m["classes"].add(cls)
                m["procedures"].update(
                    p for p in RE_PROC.findall(text) if len(p) > 2)
                for tbl in RE_SQL.findall(text):
                    up = tbl.upper()
                    if up not in SQL_NOISE and not up.isdigit():
                        m["sql_tables"].add(up)
                if RE_USES_IB.search(text):
                    m["uses_firebird"] = True
            else:  # .dfm -- UI labels are how users describe a feature
                m["captions"].update(
                    c.strip() for c in RE_CAPTION.findall(text) if c.strip())

    # --- serialise ----------------------------------------------------------
    out = {}
    for name, m in sorted(modules.items()):
        files = sorted(set(m["files"]), key=lambda r: (rank(r), r))
        out[name] = {
            "module": name,
            "systems": sorted(m["systems"]),
            "canonical_file": files[0] if files else None,
            "file_count": len(files),
            "loc": m["loc"],
            "units": sorted(m["units"]),
            "libraries": sorted(m["libraries"]),
            "exports": sorted(m["exports"]),
            "classes": sorted(m["classes"]),
            "procedures": sorted(m["procedures"])[:120],
            "procedure_count": len(m["procedures"]),
            "sql_tables": sorted(m["sql_tables"]),
            "captions": sorted(m["captions"])[:40],
            "uses_firebird": m["uses_firebird"],
            "files": files[:8],
        }

    os.makedirs(OUT_DIR, exist_ok=True)
    with open(OUT_JSON, "w", encoding="utf-8") as fh:
        json.dump({"schema": 1, "module_count": len(out), "modules": out},
                  fh, ensure_ascii=False, indent=1, sort_keys=True)

    # Markdown digest: one line per module so the text pipeline can index it.
    lines = [
        "---",
        "title: Legacy Delphi modul-terkep (szimbolum-index)",
        "type: long-term-legacy",
        "source: legacy-transfer/text (generated by scripts/legacy-symbol-index.py)",
        "---",
        "",
        "# Legacy Delphi modul-terkep",
        "",
        "Az eredeti valutavalto program moduljai, exportalt DLL-API-juk, form-",
        "osztalyaik es az altaluk erintett adatbazis-tablak. Reszletekert:",
        "`npm run memory:symbol -- <kifejezes>`.",
        "",
        f"Modulok: {len(out)}",
        "",
    ]
    for name, mod in sorted(out.items()):
        bits = [f"## {name}", ""]
        if mod["exports"]:
            bits.append(f"- **Exportalt API:** {', '.join(mod['exports'])}")
        if mod["classes"]:
            bits.append(f"- **Osztalyok:** {', '.join(mod['classes'][:8])}")
        if mod["sql_tables"]:
            bits.append(f"- **DB-tablak:** {', '.join(mod['sql_tables'][:20])}")
        if mod["captions"]:
            bits.append(f"- **Kepernyo-feliratok:** {', '.join(mod['captions'][:12])}")
        bits.append(
            f"- **Forras:** `{mod['canonical_file']}` "
            f"({mod['file_count']} fajl, {mod['loc']} sor, "
            f"{mod['procedure_count']} eljaras)")
        bits.append("")
        lines += bits

    with open(OUT_DIGEST, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines))

    tables = sorted({t for m in out.values() for t in m["sql_tables"]})
    exports = sorted({e for m in out.values() for e in m["exports"]})
    print(f"scanned files : {scanned}")
    print(f"modules       : {len(out)}")
    print(f"exported APIs : {len(exports)}")
    print(f"SQL tables    : {len(tables)}")
    print(f"json          : {os.path.relpath(OUT_JSON, ROOT)} "
          f"({os.path.getsize(OUT_JSON)/1024:.0f} KB)")
    print(f"digest        : {os.path.relpath(OUT_DIGEST, ROOT)} "
          f"({os.path.getsize(OUT_DIGEST)/1024:.0f} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
