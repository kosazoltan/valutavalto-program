from __future__ import annotations

import csv
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXCMD = ROOT / "EXCMD"
OUT_DIR = EXCMD / "_ai-protokoll"

EXCLUDED_TOP = {"_ai-protokoll"}
EXCLUDED_FILES = {
    "_SABLON2-INSTRUKCIO.md",
}

FR_RE = re.compile(r"\[(FR-[^\]]+)\]", re.IGNORECASE)
TITLE_RE = re.compile(r'^title\s*:\s*"?(.*?)"?\s*$')
MODUL_RE = re.compile(r"^modul\s*:\s*(.*?)\s*$")
KAT_RE = re.compile(r"^kategoria\s*:\s*(.*?)\s*$")
APP_RE = re.compile(r"^alkalmazas\s*:\s*(.*?)\s*$")


def norm(s: str) -> str:
    return s.strip().strip('"').strip("'")


def classify(path: Path) -> str:
    rel = path.relative_to(EXCMD).as_posix()
    if rel.startswith("legacy/modules-szerver-fejleszt/"):
        return "legacy-szerver-fejlesztes"
    if rel.startswith("legacy/modules-szerver/"):
        return "legacy-szerver"
    if rel.startswith("legacy/modules-ertektar/"):
        return "legacy-ertektar"
    if rel.startswith("legacy/modules-arfolyam/"):
        return "legacy-arfolyam"
    if rel.startswith("legacy/modules/"):
        return "legacy-valuta"
    if rel.startswith("legacy/"):
        return "legacy-overview"
    return "business"


def parse_md(path: Path) -> dict:
    text = path.read_text(encoding="utf-8", errors="ignore")
    lines = text.splitlines()

    title = ""
    modul = ""
    kategoria = ""
    alkalmazas = ""

    in_frontmatter = len(lines) > 0 and lines[0].strip() == "---"
    if in_frontmatter:
        for ln in lines[1:120]:
            if ln.strip() == "---":
                break
            m = TITLE_RE.match(ln.strip())
            if m:
                title = norm(m.group(1))
                continue
            m = MODUL_RE.match(ln.strip())
            if m:
                modul = norm(m.group(1))
                continue
            m = KAT_RE.match(ln.strip())
            if m:
                kategoria = norm(m.group(1))
                continue
            m = APP_RE.match(ln.strip())
            if m:
                alkalmazas = norm(m.group(1))
                continue

    if not title:
        for ln in lines[:40]:
            if ln.startswith("# "):
                title = ln[2:].strip()
                break

    if not title:
        title = path.stem

    if not modul:
        modul = path.stem

    if not kategoria:
        kategoria = classify(path)

    if not alkalmazas:
        if relpath(path).startswith("legacy/"):
            alkalmazas = "backend"
        else:
            alkalmazas = "penztar-client"

    frs = sorted(set(FR_RE.findall(text)))

    risk = "Kozepes"
    tl = text.lower()
    if "aml" in tl or "pmt" in tl or "bank" in tl or "auth" in tl or "jogosults" in tl:
        risk = "Magas"
    elif "riport" in tl or "kijelz" in tl or "lista" in tl:
        risk = "Alacsony"

    return {
        "path": relpath(path),
        "title": title,
        "modul": modul,
        "kategoria": kategoria,
        "alkalmazas": alkalmazas,
        "fr_codes": frs,
        "risk": risk,
        "cluster": classify(path),
    }


def relpath(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def collect_modules() -> list[Path]:
    out: list[Path] = []
    for p in EXCMD.rglob("*.md"):
        rel = p.relative_to(EXCMD).as_posix()
        top = rel.split("/")[0]
        if top in EXCLUDED_TOP:
            continue
        if p.name in EXCLUDED_FILES:
            continue
        out.append(p)
    return sorted(out)


def write_registry(rows: list[dict]) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    csv_path = OUT_DIR / "all-modules-registry.csv"
    with csv_path.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow([
            "path",
            "title",
            "modul",
            "kategoria",
            "alkalmazas",
            "cluster",
            "risk",
            "fr_count",
            "fr_codes",
        ])
        for r in rows:
            w.writerow([
                r["path"],
                r["title"],
                r["modul"],
                r["kategoria"],
                r["alkalmazas"],
                r["cluster"],
                r["risk"],
                len(r["fr_codes"]),
                ";".join(r["fr_codes"]),
            ])


def write_jsonl(rows: list[dict]) -> None:
    path = OUT_DIR / "ai-workitems.jsonl"
    with path.open("w", encoding="utf-8") as f:
        for r in rows:
            obj = {
                "module_path": r["path"],
                "mic": {
                    "modul": r["modul"],
                    "title": r["title"],
                    "kategoria": r["kategoria"],
                    "alkalmazas": r["alkalmazas"],
                    "fr_codes": r["fr_codes"],
                    "risk": r["risk"],
                },
                "ticket_template": {
                    "title": f"[{r['modul']}] {r['title']} fejlesztes",
                    "scope_in": ["EXCMD-ben leirt FR-ek implementalasa"],
                    "scope_out": ["Nem kapcsolodo modulok refaktoralasa"],
                    "acceptance": [
                        "FR-ek teljesulnek",
                        "Jogosultsag es tenant izolacio rendben",
                        "Tesztek zolden futnak",
                    ],
                },
                "spec_template": {
                    "architecture": "Minimalis diff, meglevo retegek hasznalata",
                    "data_model": "Csak szukseges valtozas",
                    "api_ui_contract": "FR pontokkal visszavezetve",
                },
                "test_template": {
                    "required": [
                        "happy path",
                        "jogosultsagi tiltott eset",
                        "validacios hiba",
                        "regresszios eset",
                    ]
                },
                "code_prompt": "Implementald a ticketet minimalis diffel, tenant izolacio, audit es secure coding mellett.",
            }
            f.write(json.dumps(obj, ensure_ascii=False) + "\n")


def write_batch_md(rows: list[dict]) -> None:
    path = OUT_DIR / "ai-ticket-spec-test-kod-batch.md"
    with path.open("w", encoding="utf-8") as f:
        f.write("# EXCMD teljes AI munkacsomag\n\n")
        f.write("Ez a fajl az osszes modulra tartalmaz egy roviden futtathato munkacsomag-vazat.\n\n")
        f.write(f"Osszes modul: {len(rows)}\n\n")
        for idx, r in enumerate(rows, start=1):
            f.write(f"## {idx}. {r['title']}\n")
            f.write(f"- Modul: {r['modul']}\n")
            f.write(f"- Fajl: {r['path']}\n")
            f.write(f"- Kategoria: {r['kategoria']}\n")
            f.write(f"- Alkalmazas: {r['alkalmazas']}\n")
            f.write(f"- Kockazat: {r['risk']}\n")
            fr = ", ".join(r["fr_codes"]) if r["fr_codes"] else "nincs explicit FR"
            f.write(f"- FR-ek: {fr}\n")
            f.write("\n")
            f.write("Ticket:\n")
            f.write(f"- Cim: [{r['modul']}] {r['title']} fejlesztes\n")
            f.write("- AC: FR megfeleles, tesztek zold, tenant izolacio\n")
            f.write("\n")
            f.write("Spec:\n")
            f.write("- Architekturadontes: minimalis diff\n")
            f.write("- Adatmodell/API/UI: csak szukseges valtozas\n")
            f.write("\n")
            f.write("Teszt:\n")
            f.write("- happy path + jogosultsag + validacio + regresszio\n")
            f.write("\n")
            f.write("Kod:\n")
            f.write("- Implementalas a meglevo kodstilus szerint\n")
            f.write("\n")


def write_summary(rows: list[dict]) -> None:
    by_cluster: dict[str, int] = {}
    by_risk: dict[str, int] = {}
    with_fr = 0
    for r in rows:
        by_cluster[r["cluster"]] = by_cluster.get(r["cluster"], 0) + 1
        by_risk[r["risk"]] = by_risk.get(r["risk"], 0) + 1
        if r["fr_codes"]:
            with_fr += 1

    p = OUT_DIR / "README.md"
    with p.open("w", encoding="utf-8") as f:
        f.write("# EXCMD AI protokoll pack\n\n")
        f.write("Automatikusan generalt munkacsomag az osszes EXCMD modulhoz.\n\n")
        f.write(f"- Modulok szama: {len(rows)}\n")
        f.write(f"- Explicit FR kodot tartalmaz: {with_fr}\n")
        f.write(f"- Explicit FR nelkuli modul: {len(rows) - with_fr}\n\n")

        f.write("## Cluster bontas\n")
        for k in sorted(by_cluster):
            f.write(f"- {k}: {by_cluster[k]}\n")

        f.write("\n## Kockazati bontas\n")
        for k in sorted(by_risk):
            f.write(f"- {k}: {by_risk[k]}\n")

        f.write("\n## Kimeneti fajlok\n")
        f.write("- all-modules-registry.csv\n")
        f.write("- ai-workitems.jsonl\n")
        f.write("- ai-ticket-spec-test-kod-batch.md\n")


def main() -> None:
    modules = collect_modules()
    rows = [parse_md(p) for p in modules]

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    write_registry(rows)
    write_jsonl(rows)
    write_batch_md(rows)
    write_summary(rows)

    print(f"Generated AI pack for {len(rows)} EXCMD modules -> {OUT_DIR}")


if __name__ == "__main__":
    main()
