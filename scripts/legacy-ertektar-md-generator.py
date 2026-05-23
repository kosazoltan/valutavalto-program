"""
Anti ERTEKTAR (értéktár) alrendszer → mély utasítás-MD generátor.
Forrás: Anti/SZERVER/_extracted/ERTEKTAR/etdll/<modul>/[debug/] (project1.dpr + unit*.pas + *.dfm).
Kimenet: EXCMD/legacy/modules-ertektar/<MODUL>.md (a forrásfájl-mappák nevei alapján).
Külső függőség nélkül (stdlib). A VALUTA-generátor logikáját követi, de a debug-mappát
NEM zárja ki (az értéktár-forrás ott van), és a modul-listát a könyvtárfából veszi.
"""
import os, io, sys, re

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
# argv: [ROOT] [OUT] [SUBSYS]
ROOT = sys.argv[1] if len(sys.argv) > 1 else "Anti/SZERVER/_extracted/ERTEKTAR/etdll"
OUT = sys.argv[2] if len(sys.argv) > 2 else "EXCMD/legacy/modules-ertektar"
SUBSYS = sys.argv[3] if len(sys.argv) > 3 else "ERTEKTAR"
os.makedirs(OUT, exist_ok=True)


def read(p):
    for enc in ("cp1250", "latin-1"):
        try:
            return open(p, encoding=enc, errors="replace").read()
        except Exception:
            pass
    return ""


def find_files(moddir):
    """fő .dpr (named vagy project1), legnagyobb .pas (non-DCU), .dfm-ek — debug is."""
    dpr = pas = None
    pas_sz = 0
    dfms = []
    named_dpr = None
    for r, dirs, files in os.walk(moddir):
        for f in files:
            fp = os.path.join(r, f)
            low = f.lower()
            if low.endswith(".dpr"):
                if "project1" not in low and not named_dpr:
                    named_dpr = fp
                elif not dpr:
                    dpr = fp
            elif low.endswith(".pas"):
                sz = os.path.getsize(fp)
                if sz > pas_sz:
                    pas_sz, pas = sz, fp
            elif low.endswith(".dfm"):
                dfms.append(fp)
    return (named_dpr or dpr), pas, dfms


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
    forms = []
    caps = []
    for fp in dfms:
        try:
            raw = open(fp, "rb").read()
        except Exception:
            continue
        if raw[:4] == b"\xff\xff\xff\xff" or b"object" not in raw[:200].lower():
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


UNIQUE = {"GETELLEN", "HRKATVEVO", "HRKCIMLET", "IRARFOLY", "NIFVAL",
          "PENZTARAK", "PICTLOAD", "RATECTRL", "RATEPERM"}


def gen(mod, moddir):
    dpr, pas, dfms = find_files(moddir)
    exports = exports_of(dpr)
    pt = read(pas) if pas else ""
    procs = procs_of(pt)
    tables, sqls = sql_of(pt)
    msgs = messages_of(pt)
    forms, caps = dfm_info(dfms)
    rel_pas = os.path.relpath(pas, ".").replace("\\", "/") if pas else "(nincs .pas)"
    rel_dpr = os.path.relpath(dpr, ".").replace("\\", "/") if dpr else "(nincs .dpr)"
    uniq = " **[ÉRTÉKTÁR-EGYEDI — nincs VALUTA megfelelő]**" if (SUBSYS == "ERTEKTAR" and mod.upper() in UNIQUE) else ""

    L = []
    L.append(f"# Legacy modul ({SUBSYS}): {mod.upper()}{uniq}")
    L.append("")
    L.append(f"> Forrás (primer): `{rel_pas}` ({len(pt)} karakter) · library: `{rel_dpr}`")
    L.append(f"> Alrendszer: **{SUBSYS}** — a tényleges Delphi-forrásból.")
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
    L.append(", ".join(f"`{p}`" for p in procs[:30]) if procs else "_(nincs / üres .pas)_")
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
    L.append("_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; "
             "gap-jelölt, ha a fenti logika/üzenet hiányzik.)_")
    L.append("")
    open(os.path.join(OUT, f"{mod.upper()}.md"), "w", encoding="utf-8").write("\n".join(L))
    return len(exports), len(procs), len(tables), len(msgs), len(forms)


dirs = sorted([d for d in os.listdir(ROOT) if os.path.isdir(os.path.join(ROOT, d))])
done = empty = 0
for mod in dirs:
    e, p, t, m, f = gen(mod, os.path.join(ROOT, mod))
    if e == 0 and p == 0:
        empty += 1
    done += 1
print(f"[ertektar-md-gen] {done} értéktár modul-MD generálva ({OUT}/), ebből {empty} üres-stub.")
