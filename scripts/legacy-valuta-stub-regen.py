"""Célzott regenerálás: a Anti/VALUTA/DLL 0-bájtos stub-modulok VALÓDI forrása az
_extracted/VALUTA/DLL-ben van. + IBVALTO fő kliens. Felülírja a meglévő üres MD-ket."""
import os, io, sys, re
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")


def read(p):
    for enc in ("cp1250", "latin-1"):
        try:
            return open(p, encoding=enc, errors="replace").read()
        except Exception:
            pass
    return ""


def biggest_pas(d):
    best, sz = None, 0
    for r, _, fs in os.walk(d):
        if re.search(r"_unpacked|/old/", r, re.I):
            continue
        for f in fs:
            if f.lower().endswith(".pas") and not f.lower().startswith("project1"):
                p = os.path.join(r, f)
                s = os.path.getsize(p)
                if s > sz:
                    sz, best = s, p
    return best


def find_dpr(d):
    for r, _, fs in os.walk(d):
        for f in fs:
            if f.lower().endswith(".dpr") and not f.lower().startswith("project1"):
                return os.path.join(r, f)
    return None


def gen(name, moddir, out, note):
    pas = biggest_pas(moddir)
    t = read(pas) if pas else ""
    dp = find_dpr(moddir)
    exports = []
    if dp:
        m = re.search(r"\bexports\b(.*?);", read(dp), re.I | re.S)
        if m:
            exports = [n for n in re.findall(r"([A-Za-z_]\w*)", m.group(1))
                       if n.lower() not in ("index", "name", "resident")]
    procs, seen = [], set()
    for x in re.findall(r"\b(?:procedure|function)\s+([A-Za-z_][\w.]*)\s*[\(;]", t):
        if x not in seen:
            seen.add(x); procs.append(x)
    tables, ops = set(), []
    for m in re.finditer(r"'([^']*\b(?:SELECT|INSERT|UPDATE|DELETE|FROM|WHERE|INTO)\b[^']*)'", t, re.I):
        s = m.group(1).strip()
        if 4 <= len(s) <= 160:
            ops.append(s)
        for tm in re.finditer(r"\b(?:FROM|INTO|UPDATE|JOIN)\s+([A-Z_][A-Z0-9_]+)", s, re.I):
            tables.add(tm.group(1).upper())
    msgs = list(dict.fromkeys(re.findall(r"(?:ShowMessage|MessageDlg|MessageBox)\s*\(\s*'([^']{3,})'", t)))[:15]
    rp = os.path.relpath(pas, ".").replace(os.sep, "/") if pas else "(nincs)"
    L = [f"# Legacy modul (VALUTA): {name}", "",
         f"> Forrás (primer): `{rp}` ({len(t)} karakter)", f"> {note}", "",
         "## Exportált API", ", ".join(f"`{e}`" for e in exports) if exports else "_(nincs)_", "",
         "## Eljárások / függvények", ", ".join(f"`{p}`" for p in procs[:40]) if procs else "_(nincs)_", "",
         "## Érintett adatbázis-táblák", ", ".join(f"`{x}`" for x in sorted(tables)) if tables else "_(nincs explicit SQL)_"]
    if ops:
        L.append("")
        L += [f"- `{s}`" for s in list(dict.fromkeys(ops))[:10]]
    L.append("")
    L.append("## Felhasználói üzenetek")
    L += [f"- {m}" for m in msgs] if msgs else ["_(nincs)_"]
    L.append("")
    L.append("## Megfeleltetés a jelenlegi programmal")
    L.append("_(a tényleges jelenlegi kód ellen verifikálandó.)_")
    L.append("")
    open(os.path.join(out, f"{name}.md"), "w", encoding="utf-8").write("\n".join(L))
    return len(t), len(procs), len(exports)


base = "Anti/SZERVER/_extracted/VALUTA/DLL"
note = "KORREKCIÓ: a Anti/VALUTA/DLL-ben 0-bájtos stub volt; a VALÓDI forrás az _extracted/VALUTA/DLL-ben."
for m in ["ADATLAP", "AFATABLA", "ARFDISP", "ARFREG", "ARFTMK"]:
    r = gen(m, os.path.join(base, m), "EXCMD/legacy/modules", note)
    print(f"{m}: {r[0]} char, {r[1]} proc, {r[2]} export")

r = gen("IBVALTO", "Anti/VALUTA/IBVALTO", "EXCMD/legacy/modules",
        "VALUTA — FŐ PÉNZTÁR-KLIENS (IBVALTO.DPR, a 109 DLL-t betöltő alkalmazás-héj).")
print(f"IBVALTO: {r[0]} char, {r[1]} proc")
