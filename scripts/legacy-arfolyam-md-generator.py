"""
Anti ARFOLYAM (árfolyamkészítő) VALÓDI Delphi-forrás → mély modul-MD generátor.
Forrás: Anti/SZERVER/_extracted/SZERVER/fejleszt/arfolyam/verzio22/arfolyam_unpacked/
        (Unit1..Unit16.pas + .dfm; arfolyam.dpr a fő projekt).
KORREKCIÓ: a korábbi doksi tévesen állította, hogy az ARFOLYAM-nak nincs forrása
(csak bináris-RE). A teljes Object Pascal forrás megvan — itt unit/form szinten
dolgozzuk fel. Kimenet: EXCMD/legacy/modules-arfolyam/<FORMCLASS>.md.
Külső függőség nélkül (stdlib).
"""
import os, io, sys, re

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
SRC = "Anti/SZERVER/_extracted/SZERVER/fejleszt/arfolyam/verzio22/arfolyam_unpacked"
OUT = "EXCMD/legacy/modules-arfolyam"
os.makedirs(OUT, exist_ok=True)


def read(p):
    for enc in ("cp1250", "latin-1"):
        try:
            return open(p, encoding=enc, errors="replace").read()
        except Exception:
            pass
    return ""


def form_class(t):
    m = re.search(r"\b(T[A-Za-z0-9_]+)\s*=\s*class\(TForm\)", t)
    return m.group(1) if m else None


def components(t):
    # csak az interface deklarációs blokkból: "Név: TKomponens;"
    comps = re.findall(r"^\s+([A-Za-z_]\w*)\s*:\s*(T[A-Za-z]\w*)\s*;", t, re.M)
    out = []
    for name, typ in comps:
        if typ in ("TForm",):
            continue
        out.append(f"{name}:{typ}")
    return out[:60]


def procs(t):
    p = re.findall(r"\bprocedure\s+T[A-Za-z0-9_]+\.([A-Za-z_]\w*)", t)
    f = re.findall(r"\bfunction\s+T[A-Za-z0-9_]+\.([A-Za-z_]\w*)", t)
    seen, out = set(), []
    for x in p + f:
        if x not in seen:
            seen.add(x); out.append(x)
    return out


def exports_dpr(dpr_text):
    m = re.search(r"\bexports\b(.*?);", dpr_text, re.I | re.S)
    if not m:
        return []
    return [n for n in re.findall(r"([A-Za-z_]\w*)", m.group(1))
            if n.lower() not in ("index", "name", "resident")]


def sql_of(t):
    tables, ops = set(), []
    for m in re.finditer(r"'([^']*\b(?:SELECT|INSERT|UPDATE|DELETE|FROM|WHERE|INTO)\b[^']*)'", t, re.I):
        s = m.group(1).strip()
        if 4 <= len(s) <= 160:
            ops.append(s)
        for tm in re.finditer(r"\b(?:FROM|INTO|UPDATE|JOIN)\s+([A-Z_][A-Z0-9_]+)", s, re.I):
            tables.add(tm.group(1).upper())
    return sorted(tables), list(dict.fromkeys(ops))[:10]


def messages_of(t):
    msgs = re.findall(r"(?:ShowMessage|MessageDlg|MessageBox)\s*\(\s*'([^']{3,})'", t)
    return list(dict.fromkeys(msgs))[:15]


def dfm_captions(dfm_path):
    if not os.path.exists(dfm_path):
        return []
    t = read(dfm_path)
    return list(dict.fromkeys(re.findall(r"Caption\s*=\s*'([^']{2,40})'", t)))[:30]


# unit → rövid funkció-leírás (a form-osztályból ismert)
DESC = {
    "TForm1": "fő ablak / belépés",
    "TALAPLAP": "0-s alaplap (A–I oszlopok árfolyam-rács)",
    "TINTERNETTMKFORM": "INTERNET-cím (URL) karbantartó — gomb {sorszám, felirat, URL}",
    "TGetFuggveny": "képlet/függvény segéd (cella-másolás)",
    "TNyomtatoForm": "nyomtatás",
    "TARFDATAIRAS": "arfdata.dat írás (árfolyam-fájl perzisztálás)",
    "TAdatSzetkuldes": "árfolyamok szétküldése az irodáknak",
    "TCSOPORTDISPLAY": "54-csempe csoport-rács (J–S oszlopok)",
    "TMUNKAFORM": "munka-form",
    "THELPFORM": "súgó",
    "TINTERNETBONGESZO": "internet-böngésző (a karbantartott URL-ek megnyitása)",
    "TAdatBetoltes": "adat-betöltés (arfdata.dat olvasás)",
    "TZOLDMENU": "zöld menü (fő navigáció)",
    "THOVAMASOLJAK": "hova-másoljak (cella-másolás cél)",
    "TLIMITALLITOFORM": "limit-állító (kedvezmény alsó/közép/felső)",
    "TIRODANEVLISTA": "iroda-név lista (árfolyam-csoport→iroda hozzárendelés)",
}


arfdpr = read(os.path.join(SRC, "Arfolyam.dpr"))
exports = exports_dpr(arfdpr)

units = sorted([f for f in os.listdir(SRC) if re.match(r"(?i)unit\d+\.pas$", f)],
               key=lambda x: int(re.search(r"\d+", x).group()))
done = 0
for u in units:
    t = read(os.path.join(SRC, u))
    cls = form_class(t)
    if not cls:
        continue
    comps = components(t)
    pr = procs(t)
    tables, sqls = sql_of(t)
    msgs = messages_of(t)
    dfm = os.path.join(SRC, u[:-4] + ".dfm")
    caps = dfm_captions(dfm)
    desc = DESC.get(cls, "")

    L = [f"# Legacy modul (ARFOLYAM / árfolyamkészítő): {cls}"]
    if desc:
        L.append(f"\n> **Funkció:** {desc}")
    L.append(f"> Forrás (primer, VALÓDI Object Pascal): `{SRC}/{u}` ({len(t)} karakter)")
    L.append("> Alrendszer: **ARFOLYAM** (rate-maker). KORREKCIÓ: a forrás megvan, NEM csak bináris-RE.")
    L.append("")
    L.append("## Komponensek (form-mezők)")
    L.append(", ".join(f"`{c}`" for c in comps) if comps else "_(nincs)_")
    L.append("")
    L.append("## Eljárások / függvények")
    L.append(", ".join(f"`{p}`" for p in pr[:40]) if pr else "_(nincs)_")
    L.append("")
    L.append("## Feliratok/gombok (DFM Caption)")
    L.append(" · ".join(caps) if caps else "_(nincs/bináris DFM)_")
    L.append("")
    L.append("## Érintett adatbázis/fájl")
    L.append(", ".join(f"`{x}`" for x in tables) if tables else "_(arfdata.dat fájl-alapú, nincs SQL-tábla)_")
    if sqls:
        L.append("")
        for s in sqls:
            L.append(f"- `{s}`")
    L.append("")
    L.append("## Felhasználói üzenetek")
    L += [f"- {m}" for m in msgs] if msgs else ["_(nincs)_"]
    L.append("")
    L.append("## Megfeleltetés a jelenlegi programmal")
    L.append("_(a jelenlegi rate-maker: arfolyam-keszito-client + frontend-react "
             "MainRateSheetPage/RateCreationPage + rfmRules ellen verifikálandó.)_")
    L.append("")
    open(os.path.join(OUT, f"{cls}.md"), "w", encoding="utf-8").write("\n".join(L))
    done += 1

# index
idx = ["# ARFOLYAM (árfolyamkészítő) — VALÓDI forrás modul-MD-k", "",
       f"> Forrás: `{SRC}` (verzio22, a legújabb). 16 Delphi form-unit + `Arfolyam.dpr`.",
       "> **KORREKCIÓ (2026-05-23):** a korábbi doksi tévesen állította, hogy az ARFOLYAM-nak",
       "> nincs forrása (csak bináris-RE). A teljes Object Pascal forrás MEGVAN ezen az úton.", ""]
if exports:
    idx.append("**Exportált API (Arfolyam.dpr):** " + ", ".join(f"`{e}`" for e in exports))
    idx.append("")
idx.append("| Form | Funkció |")
idx.append("|---|---|")
for u in units:
    cls = form_class(read(os.path.join(SRC, u)))
    if cls:
        idx.append(f"| `{cls}` | {DESC.get(cls,'')} |")
open(os.path.join(OUT, "00-INDEX.md"), "w", encoding="utf-8").write("\n".join(idx))

print(f"[arfolyam-md-gen] {done} ARFOLYAM form-MD generálva ({OUT}/) + 00-INDEX.md. Exports: {len(exports)}")
