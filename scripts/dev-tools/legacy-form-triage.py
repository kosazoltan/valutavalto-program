#!/usr/bin/env python3
"""Legacy form-triage — a legacy-binary-analysis.json leképezetlen formjait osztályozza.

Dev/teszt-zaj kiszűrése útvonal-minták alapján, a maradék modulonként csoportosítva,
kompakt MD-összegzés a kézi (emberi/AI) besoroláshoz.

Használat: python scripts/dev-tools/legacy-form-triage.py
"""
import io
import json
import os
import re
import sys
from collections import defaultdict

# Sourcery review: nem minden környezetben van sys.stdout.buffer (pl. beágyazott futtató)
if hasattr(sys.stdout, "buffer"):
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(REPO, "docs", "legacy-analysis", "generated", "legacy-binary-analysis.json")
OUT = os.path.join(REPO, "docs", "legacy-analysis", "generated", "legacy-form-triage.md")

# Csak dev/teszt/próba kontextusban élő binárisok — nem termék-feature jelöltek.
DEV_RE = re.compile(
    r"(?i)(\\debug\\|\\pr.?oba|proba\.|\\teszt|_teszt|\\test\\|butitott|palyadij|tananyag"
    r"|\\old\\|fejleszt\\alap\\|fejleszt\\dijak\\|\\minta\\|project1\.exe|\\sandbox)"
)
# Generikus form-nevek, amelyek önmagukban nem feature-azonosítók.
GENERIC_RE = re.compile(r"(?i)^T?(FORM|FRM)\d*$|^TABLAZAT$|^TDM\d*$|^TDATAMODULE\d*$")


def main():
    # Copilot review: emberbarát skip/error a stack trace helyett (legacy-binary-analyzer minta)
    if not os.path.isfile(SRC):
        print(f"[triage] forrás-riport nem található: {os.path.relpath(SRC, REPO)}")
        print("[triage] futtasd előbb: python scripts/legacy-binary-analyzer.py --anti-root Anti")
        return 0
    try:
        with open(SRC, encoding="utf-8", errors="replace") as f:
            data = json.load(f)
        forms = data["forms"]
    except (json.JSONDecodeError, KeyError) as exc:
        print(f"[triage] sérült/hiányos forrás-riport ({exc}) — generáld újra az analyzerrel.")
        return 1
    unmapped = {k: v for k, v in forms.items() if v.get("implemented") is None}

    noise, candidates = [], {}
    for name, entry in sorted(unmapped.items()):
        bins = entry.get("binaries", [])
        prod_bins = [b for b in bins if not DEV_RE.search(b)]
        if not prod_bins or GENERIC_RE.match(name):
            noise.append(name)
            continue
        candidates[name] = prod_bins

    WRAPPER_RE = re.compile(r"(?i)^(_extracted.*|.*_unpacked|forrasok|szerver|fejleszt|valuta|dll)$")

    def module_of(path):
        # Codex P2: Linux/felhő-úton a riport "/"-szeparátorral készülhet — mindkettőt kezeljük
        segments = re.split(r"[\\/]+", path)[:-1]
        parts = [p for p in segments if not WRAPPER_RE.match(p)]
        return "/".join(parts[:2]).upper() if parts else "(gyökér)"

    by_module = defaultdict(list)
    for name, prod_bins in candidates.items():
        # a leggyakoribb értelmes modul-szegmens a nem-dev binárisok útvonalaiból
        counts = defaultdict(int)
        for b in prod_bins:
            counts[module_of(b)] += 1
        module = max(counts, key=counts.get)
        by_module[module].append(name)

    lines = [
        "# Legacy form-triage — leképezetlen formok osztályozása",
        "",
        f"> Forrás: legacy-binary-analysis.json ({data['binaries_scanned']} bináris, "
        f"{data['forms_total']} form) — generálta: scripts/dev-tools/legacy-form-triage.py",
        "",
        f"- Leképezetlen összesen: **{len(unmapped)}**",
        f"- Dev/teszt-zaj (csak debug/próba útvonalon él, vagy generikus név): **{len(noise)}**",
        f"- Érdemi triage-jelölt: **{len(candidates)}**",
        "",
        "## Érdemi jelöltek modulonként",
        "",
    ]
    for module in sorted(by_module, key=lambda m: -len(by_module[m])):
        names = sorted(by_module[module])
        lines.append(f"### {module} ({len(names)})")
        lines.append("")
        for n in names:
            sample = candidates[n][0]
            lines.append(f"- `{n}` — pl. `{sample}`")
        lines.append("")

    lines += ["## Dev/teszt-zaj (kihagyva)", "", ", ".join(f"`{n}`" for n in sorted(noise)), ""]

    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))

    print(f"[triage] leképezetlen: {len(unmapped)} | zaj: {len(noise)} | érdemi: {len(candidates)}")
    print(f"[triage] modulok: {len(by_module)} | riport: {os.path.relpath(OUT, REPO)}")
    for module in sorted(by_module, key=lambda m: -len(by_module[m]))[:15]:
        print(f"  {module}: {len(by_module[module])}")


if __name__ == "__main__":
    sys.exit(main() or 0)
