"""Query the legacy Delphi symbol index.

Answers "where did the old program do X?" without loading 45 MB of Pascal:
matches a term against module names, exported DLL APIs, form classes,
procedures, SQL table names and UI captions, then prints the module with its
canonical source file so the developer can open exactly the right unit.

Usage:
  python scripts/legacy-symbol-query.py cimlet
  python scripts/legacy-symbol-query.py --table CIMLETEK
  python scripts/legacy-symbol-query.py --export cimletezorutin
  python scripts/legacy-symbol-query.py napzaras --limit 5 --json
"""

import argparse
import json
import os
import sys
import unicodedata

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
INDEX = os.path.join(ROOT, ".agent", "memory", "legacy", "symbol-index.json")


def fold(text: str) -> str:
    norm = unicodedata.normalize("NFD", str(text).lower())
    return "".join(c for c in norm if unicodedata.category(c) != "Mn")


# The legacy code uses its own transliteration of Hungarian business terms
# (STORNO not "sztorno", ARFVALT not "arfolyamvaltas"). Without these aliases a
# perfectly correct Hungarian query returns nothing even though the module
# exists -- verified: "sztorno" missed the STORNO module entirely.
ALIASES = {
    "sztorno": ["storno"],
    "storno": ["sztorno"],
    "arfolyam": ["arf", "arfvalt", "arfolyam"],
    "arfolyamvaltas": ["arfvalt"],
    "cimletezes": ["cimlet"],
    "napzaras": ["zaras", "napizaras", "estizar", "regizaro"],
    "zaras": ["zaro", "zar"],
    "ertektar": ["ertektar", "et"],
    "penztar": ["ptar", "penztar"],
    "bizonylat": ["bizo", "blok", "bloknyom", "nyugta"],
    "nyomtatas": ["nyom", "print"],
    "ugyfel": ["ugyf", "ugyfel"],
    "atadas": ["atad", "atadvet", "atadolap"],
    "gongyoles": ["gong", "gongback"],
    "eladas": ["eladas"],
    "vetel": ["vetel", "vasarlas"],
    "jelszo": ["super", "supervisor", "password"],
    "foglalo": ["foglalo", "foglrend"],
}


def expand(term: str) -> list[str]:
    base = fold(term)
    out = [base] + [fold(a) for a in ALIASES.get(base, [])]
    seen, uniq = set(), []
    for t in out:
        if t not in seen:
            seen.add(t)
            uniq.append(t)
    return uniq


def score(mod: dict, term: str) -> tuple[int, list[str]]:
    """Weighted match. Exported API and module name are the strongest signals:
    they identify the unit a developer actually has to open."""
    pts, why = 0, []
    if term in fold(mod["module"]):
        pts += 10
        why.append(f"modul={mod['module']}")
    for e in mod["exports"]:
        if term in fold(e):
            pts += 8
            why.append(f"export={e}")
    for c in mod["classes"]:
        if term in fold(c):
            pts += 6
            why.append(f"osztaly={c}")
    for t in mod["sql_tables"]:
        if term in fold(t):
            pts += 5
            why.append(f"tabla={t}")
    for p in mod["procedures"]:
        if term in fold(p):
            pts += 3
            why.append(f"eljaras={p}")
            if len([w for w in why if w.startswith("eljaras=")]) >= 4:
                break
    for c in mod["captions"]:
        if term in fold(c):
            pts += 2
            why.append(f"felirat={c!r}")
            if len([w for w in why if w.startswith("felirat=")]) >= 3:
                break
    return pts, why


def main() -> int:
    ap = argparse.ArgumentParser(description="Query the legacy Delphi symbol index")
    ap.add_argument("terms", nargs="*", help="free-text terms")
    ap.add_argument("--table", help="exact SQL table name")
    ap.add_argument("--export", help="exported DLL API name")
    ap.add_argument("--system", help="filter by system (VALUTA/ERTEKTAR/SZERVER)")
    ap.add_argument("--limit", type=int, default=8)
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--list-tables", action="store_true")
    ap.add_argument("--list-exports", action="store_true")
    args = ap.parse_args()

    if not os.path.exists(INDEX):
        print("symbol index missing; run: npm run memory:legacy-index", file=sys.stderr)
        return 1
    data = json.load(open(INDEX, encoding="utf-8"))
    mods = list(data["modules"].values())

    if args.list_tables:
        for t in sorted({t for m in mods for t in m["sql_tables"]}):
            owners = [m["module"] for m in mods if t in m["sql_tables"]]
            print(f"{t:24} {', '.join(sorted(owners)[:6])}")
        return 0
    if args.list_exports:
        for e in sorted({e for m in mods for e in m["exports"]}):
            owners = [m["module"] for m in mods if e in m["exports"]]
            print(f"{e:28} {', '.join(sorted(owners)[:4])}")
        return 0

    if args.system:
        want = args.system.upper()
        mods = [m for m in mods if want in m.get("systems", [])]

    ranked = []
    if args.table:
        want = args.table.upper()
        ranked = [(20, [f"tabla={want}"], m) for m in mods if want in m["sql_tables"]]
    elif args.export:
        want = fold(args.export)
        ranked = [(20, [f"export={e}"], m)
                  for m in mods for e in m["exports"] if want == fold(e)]
    else:
        if not args.terms:
            ap.error("give search terms, or --table / --export / --list-*")
        for m in mods:
            total, why = 0, []
            for raw in args.terms:
                # Alias variants of the same term must not multiply the score;
                # take the best-scoring variant only.
                best, best_why = 0, []
                for term in expand(raw):
                    pts, w = score(m, term)
                    if pts > best:
                        best, best_why = pts, w
                total += best
                why += best_why
            if total:
                ranked.append((total, why, m))

    ranked.sort(key=lambda r: (-r[0], r[2]["module"]))
    ranked = ranked[: args.limit]

    if args.json:
        print(json.dumps([
            {"score": s, "why": w, **{k: v for k, v in m.items() if k != "procedures"}}
            for s, w, m in ranked], ensure_ascii=False, indent=1))
        return 0

    if not ranked:
        print("Nincs talalat a legacy szimbolum-indexben.")
        print("Probald: --list-tables | --list-exports, vagy masik kulcsszot.")
        return 0

    print(f"# legacy szimbolum-talalatok ({len(ranked)})\n")
    for s, why, m in ranked:
        print(f"## {m['module']}  [{', '.join(m.get('systems', []))}]  (score {s})")
        print(f"- forras: `{m['canonical_file']}`")
        print(f"- meret : {m['file_count']} fajl, {m['loc']} sor, "
              f"{m['procedure_count']} eljaras")
        if m["exports"]:
            print(f"- API   : {', '.join(m['exports'])}")
        if m["classes"]:
            print(f"- form  : {', '.join(m['classes'][:6])}")
        if m["sql_tables"]:
            print(f"- tablak: {', '.join(m['sql_tables'][:14])}")
        if why:
            seen, uniq = set(), []
            for w in why:
                if w not in seen:
                    seen.add(w)
                    uniq.append(w)
            print(f"- talalat: {'; '.join(uniq[:8])}")
        print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
