#!/usr/bin/env python3
"""
Legacy bináris (EXE/DLL) elemző — Delphi TPF0 form-kinyerés + implementáció-keresztellenőrzés.

DINAMIKUS WORKFLOW (autonóm, újrafuttatható):
  1. Beolvassa az `Anti/` fa alatti összes Delphi bináris végrehajtható fájlt (.exe/.dll)
     BINÁRIS szinten, és kinyeri a beágyazott DFM form-osztálynevek (TPF0 szignatúra) +
     length-prefixes Caption-stringek halmazát — külső függőség nélkül (stdlib only).
  2. Keresztellenőrzi a kinyert form/feature-neveket a jelenlegi kódbázis ellen
     (frontend-react, penztar-client, arfolyam-keszito-client, backend) egy konfigurálható
     leképező-táblán át → mely legacy-form van implementálva, melyik nyitott.
  3. JSON + Markdown riportot ír (docs/legacy-analysis/generated/), ami commitolható
     akkor is, ha a nyers Anti/ fa gitignore-olt.

Használat:
  python scripts/legacy-binary-analyzer.py            # teljes elemzés (Anti/ kell)
  python scripts/legacy-binary-analyzer.py --self-test  # önteszt szintetikus binárissal (Anti/ NEM kell)
  python scripts/legacy-binary-analyzer.py --anti-root <út> --out <út>

Anti/ hiányában (pl. CI vagy felhő-session, ahol a fa gitignore-olt) exit 0 + skip-üzenet,
hogy a pipeline ne bukjon — a tényleges elemzés a forrást birtokló gépen fut.
"""
import argparse
import io
import json
import os
import re
import sys
from datetime import datetime, timezone

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# A jelenlegi kódbázis azon gyökerei, ahol az implementáció keresendő.
CODE_ROOTS = [
    "frontend-react/src",
    "penztar-client",
    "arfolyam-keszito-client/src",
    "kozponti-client/src",
    "backend/src/main/java",
]
CODE_EXTS = (".ts", ".tsx", ".js", ".jsx", ".java", ".sql")

# Legacy Delphi form-osztálynév → a mai implementációt jelző kód-keresőminták (regex, OR).
# A minták a meglévő RE-doksik (EXCMD/legacy/02-ARFOLYAM-binaris-visszafejtes.md) megfeleltetéseiből.
# Új legacy-form felbukkanásakor ide kell felvenni a leképezést (a workflow ezt jelzi is).
FORM_IMPLEMENTATION_MAP = {
    "TALAPLAP": [r"MainRateSheetPage"],
    "TCSOPORTDISPLAY": [r"WorkgroupTileListView", r"workgroupSheetCompute"],
    "TLIMITALLITOFORM": [r"workgroupMaintenance", r"discountThreshold|kedvezm[eé]nyhat[aá]r"],
    "TINTERNETTMKFORM": [r"INTERNET"],
    "THOVAMASOLJAK": [r"crossGroupCopy", r"fillHelpers"],
    "TGETFUGGVENY": [r"FormulaSyntaxHelp", r"mainSheetFormula"],
    "TADATSZETKULDES": [r"MainRateSheetPage", r"publish"],
    "TADATBETOLTES": [r"exchangeRateMaster"],
    "TIRODANEVLISTA": [r"WorkgroupTileListView"],
    "TZOLDMENU": [r"menuGroups|RatesPage"],
    "TLOGINDIALOG": [r"LoginPage|useAuth"],
    "TPASSWORDDIALOG": [r"LoginPage|password"],
}


def read_text(path):
    for enc in ("cp1250", "latin-1", "utf-8"):
        try:
            with open(path, encoding=enc) as f:
                return f.read()
        except (UnicodeDecodeError, OSError):
            continue
    return ""


def extract_tpf0_forms(raw):
    """Beágyazott Delphi DFM form-osztálynevek a TPF0 szignatúrából (length-prefixed)."""
    forms = []
    for m in re.finditer(b"TPF0", raw):
        off = m.start() + 4
        if off < len(raw):
            length = raw[off]
            if 0 < length <= 60:
                name = raw[off + 1:off + 1 + length].decode("cp1250", "replace")
                # Csak valódi Delphi-osztálynév (T-előtag + alfanumerikus).
                if re.fullmatch(r"T[A-Za-z][A-Za-z0-9_]{1,58}", name):
                    forms.append(name)
    return list(dict.fromkeys(forms))


def find_binaries(anti_root):
    bins = []
    for dirpath, _dirs, files in os.walk(anti_root):
        for fn in files:
            if fn.lower().endswith((".exe", ".dll")):
                bins.append(os.path.join(dirpath, fn))
    return sorted(bins)


def build_code_index():
    """Egyszeri index: minden kód-fájl tartalma kisbetűsítve, gyors regex-kereséshez."""
    blobs = []
    for root in CODE_ROOTS:
        abs_root = os.path.join(REPO_ROOT, root)
        if not os.path.isdir(abs_root):
            continue
        for dirpath, dirs, files in os.walk(abs_root):
            dirs[:] = [d for d in dirs if d not in ("node_modules", "target", "dist", "build")]
            for fn in files:
                if fn.endswith(CODE_EXTS):
                    blobs.append(read_text(os.path.join(dirpath, fn)))
    return "\n".join(blobs)


def check_implemented(form_name, code_index):
    patterns = FORM_IMPLEMENTATION_MAP.get(form_name.upper())
    if not patterns:
        return None  # nincs leképezés → ismeretlen, emberi besorolás kell
    for pat in patterns:
        if re.search(pat, code_index, re.IGNORECASE):
            return True
    return False


def analyze(anti_root, out_dir):
    binaries = find_binaries(anti_root)
    code_index = build_code_index()

    results = []
    all_forms = {}  # form -> {binaries: [...], implemented: bool|None}
    for bin_path in binaries:
        try:
            with open(bin_path, "rb") as f:
                raw = f.read()
        except OSError as e:
            results.append({"binary": bin_path, "error": str(e)})
            continue
        forms = extract_tpf0_forms(raw)
        rel = os.path.relpath(bin_path, anti_root)
        results.append({"binary": rel, "size_bytes": len(raw), "forms_found": len(forms)})
        for form in forms:
            entry = all_forms.setdefault(form, {"binaries": [], "implemented": check_implemented(form, code_index)})
            if rel not in entry["binaries"]:
                entry["binaries"].append(rel)

    implemented = {f: v for f, v in all_forms.items() if v["implemented"] is True}
    open_gaps = {f: v for f, v in all_forms.items() if v["implemented"] is False}
    unmapped = {f: v for f, v in all_forms.items() if v["implemented"] is None}

    report = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "anti_root": anti_root,
        "binaries_scanned": len(binaries),
        "forms_total": len(all_forms),
        "implemented_count": len(implemented),
        "open_gap_count": len(open_gaps),
        "unmapped_count": len(unmapped),
        "binaries": results,
        "forms": all_forms,
    }

    os.makedirs(out_dir, exist_ok=True)
    json_path = os.path.join(out_dir, "legacy-binary-analysis.json")
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False, indent=2)

    md_path = os.path.join(out_dir, "legacy-binary-analysis.md")
    with open(md_path, "w", encoding="utf-8") as f:
        f.write(_render_md(report, implemented, open_gaps, unmapped))

    print(f"[legacy-binary-analyzer] {len(binaries)} bináris, {len(all_forms)} egyedi form.")
    print(f"  implementált: {len(implemented)} | nyitott gap: {len(open_gaps)} | leképezetlen: {len(unmapped)}")
    print(f"  riport: {os.path.relpath(json_path, REPO_ROOT)} + .md")

    # A workflow akkor jelez hibát, ha VALÓDI nyitott gap van (implementált=False).
    # Leképezetlen form → figyelmeztetés (emberi besorolás kell), nem hiba.
    return 1 if open_gaps else 0


def _render_md(report, implemented, open_gaps, unmapped):
    lines = [
        "# Legacy bináris (EXE/DLL) elemzés — automatikus riport",
        "",
        f"> Generálva: {report['generated_at']} — `scripts/legacy-binary-analyzer.py`",
        f"> Beolvasott bináris: **{report['binaries_scanned']}** · egyedi form: **{report['forms_total']}**",
        "",
        f"- ✅ Implementált: **{report['implemented_count']}**",
        f"- ⚠️ Nyitott gap: **{report['open_gap_count']}**",
        f"- ❓ Leképezetlen (emberi besorolás kell): **{report['unmapped_count']}**",
        "",
    ]
    if open_gaps:
        lines += ["## ⚠️ Nyitott gap-ek (implementálandó)", "", "| Form | Bináris(ok) |", "|---|---|"]
        for form, v in sorted(open_gaps.items()):
            lines.append(f"| `{form}` | {', '.join(v['binaries'])} |")
        lines.append("")
    if unmapped:
        lines += [
            "## ❓ Leképezetlen form-ok",
            "",
            "Új legacy-form, amelyhez nincs implementáció-leképezés a "
            "`FORM_IMPLEMENTATION_MAP`-ben. Vedd fel a leképezést, vagy minősítsd "
            "(scope-on kívül / infra-csere) egy `EXCMD/_compare/` verdiktben.",
            "",
            "| Form | Bináris(ok) |", "|---|---|",
        ]
        for form, v in sorted(unmapped.items()):
            lines.append(f"| `{form}` | {', '.join(v['binaries'])} |")
        lines.append("")
    lines += ["## ✅ Implementált form-ok", "", "| Form | Bizonyíték-minta | Bináris(ok) |", "|---|---|---|"]
    for form, v in sorted(implemented.items()):
        pats = " / ".join(FORM_IMPLEMENTATION_MAP.get(form.upper(), []))
        lines.append(f"| `{form}` | `{pats}` | {', '.join(v['binaries'])} |")
    lines.append("")
    return "\n".join(lines)


def self_test(out_dir):
    """Önteszt: szintetikus TPF0-bináris + ismert kód-minta → a kinyerés és a
    keresztellenőrzés determinisztikusan ellenőrizhető Anti/ fa nélkül."""
    print("[self-test] szintetikus TPF0-bináris kinyerés…")
    # 'TPF0' + length-prefix 'TALAPLAP' (8) + 'TISMERETLENXFORM' (16)
    blob = b"MZ\x90\x00garbage" + b"TPF0" + bytes([8]) + b"TALAPLAP"
    blob += b"\x00\x00TPF0" + bytes([16]) + b"TISMERETLENXFORM" + b"junk"
    forms = extract_tpf0_forms(blob)
    assert "TALAPLAP" in forms, f"TALAPLAP nem jött ki: {forms}"
    assert "TISMERETLENXFORM" in forms, f"TISMERETLENXFORM nem jött ki: {forms}"
    # nem-Delphi minta nem szivároghat be:
    assert extract_tpf0_forms(b"TPF0" + bytes([3]) + b"abc") == [], "nem-T-prefix átment"
    print(f"  ✓ form-kinyerés: {forms}")

    code_index = build_code_index()
    # TALAPLAP → MainRateSheetPage (a repóban létezik) → implementált
    assert check_implemented("TALAPLAP", code_index) is True, "TALAPLAP nem implementáltként jött"
    # leképezetlen form → None
    assert check_implemented("TISMERETLENXFORM", code_index) is None, "leképezetlen nem None"
    print("  ✓ keresztellenőrzés: TALAPLAP→implementált, ismeretlen→leképezetlen")

    os.makedirs(out_dir, exist_ok=True)
    probe = os.path.join(out_dir, ".self-test-ok")
    with open(probe, "w") as f:
        f.write(datetime.now(timezone.utc).isoformat())
    print("[self-test] PASS")
    return 0


def main():
    ap = argparse.ArgumentParser(description="Legacy bináris (EXE/DLL) elemző + implementáció-keresztellenőrzés.")
    ap.add_argument("--anti-root", default=os.path.join(REPO_ROOT, "Anti"))
    ap.add_argument("--out", default=os.path.join(REPO_ROOT, "docs", "legacy-analysis", "generated"))
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()

    if args.self_test:
        sys.exit(self_test(args.out))

    if not os.path.isdir(args.anti_root):
        print(f"[legacy-binary-analyzer] Az Anti/ fa nem található ({args.anti_root}).")
        print("  A nyers legacy-forrás gitignore-olt; az elemzés a forrást birtokló gépen fut.")
        print("  CI/felhő: ez várt — kihagyva (exit 0). Lokálisan futtasd a fa gyökeréből.")
        sys.exit(0)

    sys.exit(analyze(args.anti_root, args.out))


if __name__ == "__main__":
    main()
