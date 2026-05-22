"""
Batch docx/odt → sima szöveg kinyerés stdlib-bel (zipfile + XML tag-strip),
külső függőség nélkül. A Felmérés/Valuta primer docx/odt forrásait írja
EXCMD/_inventory/docx-text/ alá, hogy a spec-generáláshoz olvashatók legyenek.
"""
import csv, os, sys, io, zipfile, re, html

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
BASE = "Felmérés/Valuta"
OUT = "EXCMD/_inventory/docx-text"
os.makedirs(OUT, exist_ok=True)


def extract_text(path):
    with zipfile.ZipFile(path) as z:
        names = z.namelist()
        target = "word/document.xml" if "word/document.xml" in names else (
            "content.xml" if "content.xml" in names else None)
        if not target:
            return ""
        xml = z.read(target).decode("utf-8", errors="replace")
    xml = re.sub(r"</w:p>", "\n", xml)
    xml = re.sub(r"</text:p>", "\n", xml)
    xml = re.sub(r"<w:tab[^>]*/>", "\t", xml)
    text = re.sub(r"<[^>]+>", "", xml)
    text = html.unescape(text)
    text = re.sub(r"\n[ \t]*\n[ \t]*\n+", "\n\n", text)
    return text.strip()


rows = [r for r in csv.DictReader(open("EXCMD/_inventory/primary-worklist.csv", encoding="utf-8"))
        if r["ext"] in ("docx", "docm", "odt")]
print(f"[docx-batch] {len(rows)} fájl")
ok = 0
for i, r in enumerate(rows, 1):
    src = os.path.join(BASE, r["relpath"])
    safe = r["relpath"].replace("/", "__").replace("\\", "__")
    dst = os.path.join(OUT, safe + ".txt")
    if not os.path.exists(src):
        print(f"[{i}] HIÁNYZIK: {src}")
        continue
    try:
        txt = extract_text(src)
        with open(dst, "w", encoding="utf-8") as fh:
            fh.write(f"# Forrás: {r['relpath']}\n# karakter: {len(txt)}\n\n{txt}\n")
        ok += 1
    except Exception as e:
        print(f"[{i}] HIBA {r['relpath']}: {e}")
print(f"[docx-batch] KÉSZ: {ok}/{len(rows)} -> {OUT}")
