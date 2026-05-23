"""
Anti/VALUTA legacy modul → mély utasítás-MD generátor.
Minden DLL-modulból kiolvassa (bináris mélységig): exportált API (.dpr exports),
tényleges eljárások/SQL/üzenetek (.pas), DFM-form (.dfm szöveg vagy bináris TPF0).
Kimenet: EXCMD/legacy/modules/<MODUL>.md (a forrásfájl nevei alapján).
Külső függőség nélkül (stdlib).
"""
import os, io, sys, re, csv

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
ROOT = "Anti/VALUTA"
DLL = os.path.join(ROOT, "DLL")
OUT = "EXCMD/legacy/modules"
os.makedirs(OUT, exist_ok=True)


def read(p):
    for enc in ("cp1250", "latin-1"):
        try:
            return open(p, encoding=enc, errors="replace").read()
        except Exception:
            pass
    return ""


def find_files(moddir):
    """fő .dpr (library), fő .pas (legnagyobb non-DEBUG), .dfm-ek."""
    dpr = pas = None
    pas_sz = 0
    dfms = []
    for r, dirs, files in os.walk(moddir):
        up = r.upper()
        for f in files:
            fp = os.path.join(r, f)
            low = f.lower()
            if low.endswith(".dpr") and "project1" not in low and not dpr:
                dpr = fp
            elif low.endswith(".pas") and "DEBUG" not in up and "EXEPROBA" not in up:
                sz = os.path.getsize(fp)
                if sz > pas_sz:
                    pas_sz, pas = sz, fp
            elif low.endswith(".dfm") and "DEBUG" not in up and "EXEPROBA" not in up:
                dfms.append(fp)
    return dpr, pas, dfms


def exports_of(dpr):
    if not dpr:
        return []
    t = read(dpr)
    m = re.search(r"\bexports\b(.*?);", t, re.I | re.S)
    if not m:
        return []
    names = re.findall(r"([A-Za-z_]\w*)", m.group(1))
    return [n for n in names if n.lower() not in ("index", "name", "resident")]


def procs_of(pas_text):
    p = re.findall(r"\b(?:procedure|function)\s+([A-Za-z_][\w.]*)\s*[\(;]", pas_text)
    out = []
    for x in p:
        if x not in out:
            out.append(x)
    return out


def sql_of(pas_text):
    tables = set()
    ops = []
    for m in re.finditer(r"'([^']*\b(?:SELECT|INSERT|UPDATE|DELETE|FROM|WHERE|INTO)\b[^']*)'", pas_text, re.I):
        s = m.group(1).strip()
        if 4 <= len(s) <= 160:
            ops.append(s)
        for tm in re.finditer(r"\b(?:FROM|INTO|UPDATE|JOIN)\s+([A-Z_][A-Z0-9_]+)", s, re.I):
            tables.add(tm.group(1).upper())
    return sorted(tables), list(dict.fromkeys(ops))[:12]


def messages_of(pas_text):
    msgs = re.findall(r"(?:ShowMessage|MessageDlg|MessageBox|Application\.MessageBox)\s*\(\s*'([^']{4,})'", pas_text)
    return list(dict.fromkeys(msgs))[:15]


def dfm_info(dfms):
    """form-osztály + caption-ök; szöveges és bináris .dfm is."""
    forms = []
    caps = []
    for fp in dfms:
        raw = open(fp, "rb").read()
        if raw[:4] == b"\xff\xff\xff\xff" or b"object" not in raw[:200].lower():
            # bináris DFM (TPF0) — class-név + length-prefix stringek
            for m in re.finditer(b"TPF0", raw):
                off = m.start() + 4
                if off < len(raw):
                    L = raw[off]
                    if 0 < L <= 50:
                        forms.append(raw[off + 1:off + 1 + L].decode("cp1250", "replace"))
        else:
            t = read(fp)
            forms += re.findall(r"object\s+\w+:\s+(\w+)", t)[:1]
            caps += re.findall(r"Caption\s*=\s*'([^']{2,40})'", t)
    return list(dict.fromkeys(forms))[:10], list(dict.fromkeys(caps))[:25]


def gen(mod):
    moddir = os.path.join(DLL, mod)
    dpr, pas, dfms = find_files(moddir)
    exports = exports_of(dpr)
    pt = read(pas) if pas else ""
    procs = procs_of(pt)
    tables, sqls = sql_of(pt)
    msgs = messages_of(pt)
    forms, caps = dfm_info(dfms)
    rel_pas = os.path.relpath(pas, ROOT).replace("\\", "/") if pas else "(nincs .pas)"
    rel_dpr = os.path.relpath(dpr, ROOT).replace("\\", "/") if dpr else "(nincs .dpr)"

    L = []
    L.append(f"# Legacy modul: {mod}")
    L.append("")
    L.append(f"> Forrás (primer): `Anti/VALUTA/{rel_pas}` ({len(pt)} karakter) · library: `{rel_dpr}`")
    L.append("> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.")
    L.append("")
    L.append("## Exportált API (DLL-szerződés)")
    L.append(", ".join(f"`{e}`" for e in exports) if exports else "_(nincs/üres exports clause)_")
    L.append("")
    L.append("## DFM form(ok) / képernyő")
    L.append(", ".join(f"`{f}`" for f in forms) if forms else "_(nincs DFM / üres)_")
    if caps:
        L.append("")
        L.append("**Feliratok/gombok (Caption):** " + " · ".join(caps))
    L.append("")
    L.append("## Eljárások / függvények (.pas)")
    if procs:
        L.append(", ".join(f"`{p}`" for p in procs[:30]))
    else:
        L.append("_(nincs / üres .pas)_")
    L.append("")
    L.append("## Érintett adatbázis-táblák")
    L.append(", ".join(f"`{t}`" for t in tables) if tables else "_(nincs explicit SQL-tábla)_")
    if sqls:
        L.append("")
        L.append("**SQL-műveletek (minta):**")
        for s in sqls:
            L.append(f"- `{s}`")
    L.append("")
    L.append("## Felhasználói üzenetek (üzleti szabály-jelek)")
    if msgs:
        for m in msgs:
            L.append(f"- {m}")
    else:
        L.append("_(nincs kinyerhető üzenet)_")
    L.append("")
    L.append("## Megfeleltetés a jelenlegi programmal")
    L.append("_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; "
             "gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_")
    L.append("")
    open(os.path.join(OUT, f"{mod}.md"), "w", encoding="utf-8").write("\n".join(L))
    return mod, len(exports), len(procs), len(tables), len(msgs), len(forms)


rows = list(csv.DictReader(open("EXCMD/legacy/valuta-modul-lista.csv", encoding="utf-8")))
done = 0
empty = 0
for r in rows:
    mod = r["modul"]
    moddir = os.path.join(DLL, mod)
    if not os.path.isdir(moddir):
        continue
    res = gen(mod)
    if res[2] == 0 and res[1] == 0:
        empty += 1
    done += 1
print(f"[legacy-md-gen] {done} modul-MD generálva (EXCMD/legacy/modules/), ebből {empty} üres-stub.")
