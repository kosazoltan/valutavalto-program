"""
Anti legacy MÉLY modul-MD generátor — MINDEN .dpr-t tartalmazó modul-mappa.
A korábbi generátorok csak a top-level mappákat vették modulnak; a beágyazott
sub-modulokat (pl. fejleszt/helga/dllek/*, fejleszt/ugyfelcontrol/dll/*) a szülőbe
olvasztották. Ez a generátor MINDEN modul-mappát feldolgoz (a makedll .dpr neve =
a valódi DLL-modul-név), kizárva a duplikátum-fákat (_unpacked/_extracted_auto/forrasok).
Csak azokat generálja, amiknek MÉG NINCS MD-jük (a meglévő 5 modul-dir alapján).
Kimenet: EXCMD/legacy/modules-szerver-fejleszt/ (kiegészítés).
"""
import os, io, sys, re

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

CANON_ROOTS = [
    "Anti/VALUTA/DLL", "Anti/VALUTA/TRADE",
    "Anti/SZERVER/_extracted/ERTEKTAR/etdll",
    "Anti/SZERVER/_extracted/SZERVER/ujdll",
    "Anti/SZERVER/_extracted/SZERVER/fejleszt",
]
OUT = "EXCMD/legacy/modules-szerver-fejleszt"
EXISTING_DIRS = ["EXCMD/legacy/modules", "EXCMD/legacy/modules-ertektar",
                 "EXCMD/legacy/modules-szerver", "EXCMD/legacy/modules-szerver-fejleszt",
                 "EXCMD/legacy/modules-arfolyam"]
os.makedirs(OUT, exist_ok=True)

DUP = re.compile(r"_unpacked|_extracted_auto|forrasok_unpacked|[/\\]old[/\\]|[/\\]old_", re.I)


def read(p):
    for enc in ("cp1250", "latin-1"):
        try:
            return open(p, encoding=enc, errors="replace").read()
        except Exception:
            pass
    return ""


# meglévő MD-nevek (uppercase, T-prefix törölve az arfolyamnál)
existing = set()
for d in EXISTING_DIRS:
    if os.path.isdir(d):
        for f in os.listdir(d):
            if f.endswith(".md"):
                n = f[:-3].upper()
                existing.add(n)
                if n.startswith("T"):
                    existing.add(n[1:])


def module_dirs():
    """Minden modul-mappa: ahol van nem-project1 .dpr (makedll v. közvetlen), dup-fák nélkül.
       module-név = a .dpr basename (a valódi DLL-név)."""
    seen = {}
    for root in CANON_ROOTS:
        for r, dirs, files in os.walk(root):
            if DUP.search(r.replace("\\", "/")):
                continue
            for f in files:
                if not f.lower().endswith(".dpr"):
                    continue
                if f.lower().startswith("project1"):
                    continue
                name = os.path.splitext(f)[0].upper()
                # a modul-mappa = a .dpr mappája, vagy a szülő ha makedll/debug
                moddir = r
                base = os.path.basename(r).lower()
                if base in ("makedll", "debug"):
                    moddir = os.path.dirname(r)
                if name not in seen:
                    seen[name] = (moddir, os.path.join(r, f))
    return seen


def biggest_pas(moddir):
    best, sz = None, 0
    for r, d, files in os.walk(moddir):
        if DUP.search(r.replace("\\", "/")):
            continue
        for f in files:
            if f.lower().endswith(".pas") and not f.lower().startswith("project1"):
                p = os.path.join(r, f)
                s = os.path.getsize(p)
                if s > sz:
                    sz, best = s, p
    return best


def dfms(moddir):
    out = []
    for r, d, files in os.walk(moddir):
        if DUP.search(r.replace("\\", "/")):
            continue
        for f in files:
            if f.lower().endswith(".dfm"):
                out.append(os.path.join(r, f))
    return out


def exports_of(dpr):
    t = read(dpr)
    m = re.search(r"\bexports\b(.*?);", t, re.I | re.S)
    if not m:
        return []
    return [n for n in re.findall(r"([A-Za-z_]\w*)", m.group(1))
            if n.lower() not in ("index", "name", "resident")]


def procs_of(t):
    out, seen = [], set()
    for x in re.findall(r"\b(?:procedure|function)\s+([A-Za-z_][\w.]*)\s*[\(;]", t):
        if x not in seen:
            seen.add(x); out.append(x)
    return out


def sql_of(t):
    tables, ops = set(), []
    for m in re.finditer(r"'([^']*\b(?:SELECT|INSERT|UPDATE|DELETE|FROM|WHERE|INTO)\b[^']*)'", t, re.I):
        s = m.group(1).strip()
        if 4 <= len(s) <= 160:
            ops.append(s)
        for tm in re.finditer(r"\b(?:FROM|INTO|UPDATE|JOIN)\s+([A-Z_][A-Z0-9_]+)", s, re.I):
            tables.add(tm.group(1).upper())
    return sorted(tables), list(dict.fromkeys(ops))[:10]


def msgs_of(t):
    return list(dict.fromkeys(re.findall(
        r"(?:ShowMessage|MessageDlg|MessageBox)\s*\(\s*'([^']{3,})'", t)))[:15]


def dfm_caps(paths):
    caps = []
    for fp in paths:
        try:
            raw = open(fp, "rb").read()
        except Exception:
            continue
        if b"object" in raw[:200].lower():
            caps += re.findall(r"Caption\s*=\s*'([^']{2,40})'", read(fp))
    return list(dict.fromkeys(caps))[:25]


mods = module_dirs()
new = 0
for name, (moddir, dpr) in sorted(mods.items()):
    if name in existing:
        continue
    pas = biggest_pas(moddir)
    t = read(pas) if pas else ""
    exports = exports_of(dpr)
    pr = procs_of(t)
    tables, sqls = sql_of(t)
    msgs = msgs_of(t)
    caps = dfm_caps(dfms(moddir))
    rel_pas = os.path.relpath(pas, ".").replace("\\", "/") if pas else "(nincs .pas)"
    rel_dpr = os.path.relpath(dpr, ".").replace("\\", "/")

    L = [f"# Legacy modul (SZERVER-FEJLESZT mély): {name}", "",
         f"> Forrás (primer): `{rel_pas}` ({len(t)} karakter) · library: `{rel_dpr}`",
         "> Beágyazott sub-modul (a korábbi top-level generálás kihagyta). VALÓDI Delphi-forrás.", "",
         "## Exportált API", ", ".join(f"`{e}`" for e in exports) if exports else "_(nincs/üres)_", "",
         "## Eljárások / függvények", ", ".join(f"`{p}`" for p in pr[:30]) if pr else "_(nincs)_", "",
         "## DFM Caption-ök", " · ".join(caps) if caps else "_(nincs/bináris)_", "",
         "## Adatbázis-táblák", ", ".join(f"`{x}`" for x in tables) if tables else "_(nincs explicit SQL)_"]
    if sqls:
        L.append("")
        L += [f"- `{s}`" for s in sqls]
    L.append("")
    L.append("## Felhasználói üzenetek")
    L += [f"- {m}" for m in msgs] if msgs else ["_(nincs)_"]
    L.append("")
    L.append("## Megfeleltetés a jelenlegi programmal")
    L.append("_(a tényleges jelenlegi kód ellen verifikálandó.)_")
    L.append("")
    open(os.path.join(OUT, f"{name}.md"), "w", encoding="utf-8").write("\n".join(L))
    new += 1

print(f"[deep-md-gen] {new} ÚJ beágyazott modul-MD generálva ({OUT}/). Összes forrás-modul: {len(mods)}, már meglévő: {len(mods)-new}.")
