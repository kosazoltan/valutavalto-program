"""Export the recovered valuta-knowledge.sqlite survey corpus to indexable markdown.

Background: `docs/valuta-knowledge.sqlite` (414 survey documents + FTS5) was
tracked in three commits during 2026-04, then gitignored on 2026-04-17
(commit 6d688ec8) and deleted from the tree by 0e4560a2. The binary was
therefore invisible to the memory bundle, which only indexes text sources.

This recovers the substantive rows into vault/references/felmeres-kb/ as
markdown so the normal qMD/YAML/Cognee/vector pipeline can index them.

Rules:
  - Only rows with real extracted text are exported. Image placeholder rows
    ("[Kep: ...]") carry no queryable knowledge, so they are collapsed into a
    single inventory file instead of 178 empty stubs.
  - Absolute Windows paths in the DB are rewritten to repo-relative form.
  - Deterministic output (stable filenames, sorted) so repeated runs do not
    churn the memory bundle's source hashes.
"""

import os
import re
import sqlite3
import unicodedata
from collections import Counter

DB = ".hermes/tmp/kb-recover/valuta-knowledge.sqlite"
OUT = "vault/references/felmeres-kb"
MIN_CONTENT = 400  # chars of real text required for a standalone document


def slug(text: str, maxlen: int = 60) -> str:
    norm = unicodedata.normalize("NFD", text)
    norm = "".join(c for c in norm if unicodedata.category(c) != "Mn")
    norm = re.sub(r"[^A-Za-z0-9]+", "-", norm).strip("-").lower()
    return (norm[:maxlen].rstrip("-")) or "doc"


def rel_path(p: str) -> str:
    if not p:
        return ""
    p = p.replace("\\", "/")
    marker = "valutavalto-program/"
    return p.split(marker, 1)[1] if marker in p else p


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    conn = sqlite3.connect(DB)
    conn.row_factory = sqlite3.Row

    rows = list(conn.execute(
        "select id, path, filename, type, size_kb, content, summary, category "
        "from felmeres_docs order by id"
    ))

    exported, skipped = 0, []
    used = set()
    cat_count = Counter()

    for r in rows:
        content = (r["content"] or "").strip()
        # Placeholder rows for images/media have no extracted text.
        if len(content) < MIN_CONTENT or content.startswith("[Kep:"):
            skipped.append(r)
            continue

        cat = r["category"] or "altalanos"
        cat_count[cat] += 1
        base = f"{r['id']:03d}-{slug(r['filename'] or 'doc')}"
        name = base
        n = 2
        while name in used:
            name, n = f"{base}-{n}", n + 1
        used.add(name)

        src = rel_path(r["path"])
        body = [
            "---",
            f"title: {(r['filename'] or 'ismeretlen').replace(':', ' -')}",
            "type: long-term-legacy",
            "source: felmeres-knowledge-base (recovered from git history)",
            f"category: {cat}",
            f"original_path: {src}",
            f"doc_type: {r['type'] or 'unknown'}",
            "---",
            "",
            f"# {r['filename'] or 'Ismeretlen dokumentum'}",
            "",
            f"**Kategoria:** {cat}  |  **Tipus:** {r['type']}  "
            f"|  **Meret:** {r['size_kb']} KB",
            f"**Eredeti utvonal:** `{src}`",
            "",
        ]
        if r["summary"]:
            body += ["## Osszefoglalo", "", str(r["summary"]).strip(), ""]
        body += ["## Tartalom", "", content, ""]

        with open(os.path.join(OUT, f"{name}.md"), "w", encoding="utf-8") as fh:
            fh.write("\n".join(body))
        exported += 1

    # One inventory file for everything without extractable text, so the
    # knowledge that these artifacts EXIST stays queryable.
    inv = [
        "---",
        "title: Felmeres KB - media es rovid dokumentumok leltara",
        "type: long-term-legacy",
        "source: felmeres-knowledge-base (recovered from git history)",
        "---",
        "",
        "# Felmeresi tudasbazis - leltar (kivonatolt szoveg nelkuli elemek)",
        "",
        "Ezek a felmeresi anyagok kepernyokepek, hangfelvetelek es rovid",
        "dokumentumok. Szoveges tartalmuk nem volt kinyerheto, de a letezesuk",
        "es helyuk tudas: ha egy fejlesztesi kerdes ezek valamelyikere vonatkozik,",
        "az eredeti fajlt kell megnyitni a megadott utvonalon.",
        "",
        "| # | Fajl | Kategoria | Tipus | Eredeti utvonal |",
        "|---|------|-----------|-------|-----------------|",
    ]
    for r in skipped:
        inv.append(
            f"| {r['id']} | {(r['filename'] or '').replace('|', '/')} "
            f"| {r['category'] or ''} | {r['type'] or ''} "
            f"| `{rel_path(r['path'])}` |"
        )
    with open(os.path.join(OUT, "000-leltar-media-es-rovid-dokumentumok.md"),
              "w", encoding="utf-8") as fh:
        fh.write("\n".join(inv) + "\n")

    print(f"rows in DB        : {len(rows)}")
    print(f"exported as docs  : {exported}")
    print(f"inventory entries : {len(skipped)}")
    print(f"output dir        : {OUT}")
    print("categories        :", dict(cat_count.most_common()))


if __name__ == "__main__":
    main()
