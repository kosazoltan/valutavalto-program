#!/usr/bin/env python3
"""
Legacy forrás-transzfer (pack/unpack) — Base64-híd a lokális Anti/ fa és a felhő-session közt.

MIÉRT: a Claude Code felhő-sessionbe egyetlen adatcsatorna vezet, a git. A nyers Anti/
legacy-fa gitignore-olt (proprietárius), a binárisok (EXE/DLL) pedig binárisként amúgy
sem utaznának jól szöveg-alapú diffekben. A Base64 adatKÓDOLÁS (nem titkosítás!) pont
erre való: bináris → biztonságosan szövegként továbbítható forma.

ADATVÉDELMI TÉNY: a becsomagolt tartalom a (privát) repóba kerül — a Base64 NEM
titkosítás, bárki visszafejti, aki a repót látja. Csak azt csomagold, amit a repo
láthatóságával vállalsz. Harmadik-fél base64 MCP-szolgáltatás használata TILOS lenne
erre (proprietárius forrás kiküldése külső szolgáltatónak); ez az eszköz mindent a
saját repón belül tart, stdlib-only.

Formátum (legacy-transfer/):
  manifest.json                — fájlonként: eredeti relatív út, típus, sha256, méret, chunkok
  blobs/<sha256>.b64[.NNN]     — binárisok base64-ben, 8 MB-os szöveg-chunkokban
  text/<relatív út>            — szöveges források (cp1250→UTF-8 konvertálva, guardrail-kompatibilis)

Használat:
  python scripts/legacy-transfer.py pack   --source Anti --out legacy-transfer [--include "*.exe" ...]
  python scripts/legacy-transfer.py unpack --in legacy-transfer --dest Anti_transfer
  python scripts/legacy-transfer.py self-test

A pack a forrást birtokló gépen fut (Windows: python kell, ahogy az analyze-legacy-local.ps1-hez is);
az unpack bárhol (felhő-session is) — utána: python scripts/legacy-binary-analyzer.py --anti-root Anti_transfer
"""
import argparse
import base64
import fnmatch
import hashlib
import io
import json
import os
import shutil
import sys
import tempfile
from datetime import datetime, timezone

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

CHUNK_BYTES = 8 * 1024 * 1024  # 8 MB bináris / chunk (b64-ben ~10.7 MB szöveg — GitHub-barát)
TEXT_EXTS = (".pas", ".dfm", ".dpr", ".inc", ".txt", ".sql")
BIN_EXTS = (".exe", ".dll")
DEFAULT_INCLUDE = ["*.pas", "*.dfm", "*.dpr", "*.inc", "*.exe", "*.dll"]


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def read_text_any(path):
    """Legacy Delphi forrás tipikusan cp1250; UTF-8-ként adjuk tovább (guardrail-kompatibilis)."""
    raw = open(path, "rb").read()
    for enc in ("utf-8", "cp1250", "latin-1"):
        try:
            return raw.decode(enc)
        except UnicodeDecodeError:
            continue
    return raw.decode("latin-1", "replace")


def pack(source, out, include):
    if not os.path.isdir(source):
        print(f"[pack] forrás nem található: {source}")
        return 2
    if os.path.isdir(out):
        shutil.rmtree(out)
    os.makedirs(os.path.join(out, "blobs"))
    os.makedirs(os.path.join(out, "text"))

    entries = []
    for dirpath, _dirs, files in os.walk(source):
        for fn in sorted(files):
            rel = os.path.relpath(os.path.join(dirpath, fn), source).replace(os.sep, "/")
            if not any(fnmatch.fnmatch(fn.lower(), pat.lower()) for pat in include):
                continue
            src_path = os.path.join(dirpath, fn)
            digest = sha256_file(src_path)
            size = os.path.getsize(src_path)
            ext = os.path.splitext(fn)[1].lower()

            if ext in TEXT_EXTS:
                dest = os.path.join(out, "text", rel)
                os.makedirs(os.path.dirname(dest), exist_ok=True)
                with open(dest, "w", encoding="utf-8", newline="\n") as f:
                    f.write(read_text_any(src_path))
                entries.append({"path": rel, "kind": "text", "sha256_original": digest, "size": size})
            else:
                chunks = []
                with open(src_path, "rb") as f:
                    idx = 0
                    while True:
                        block = f.read(CHUNK_BYTES)
                        if not block:
                            break
                        name = f"{digest}.b64" if size <= CHUNK_BYTES else f"{digest}.b64.{idx:03d}"
                        with open(os.path.join(out, "blobs", name), "w", encoding="ascii", newline="\n") as bf:
                            b64 = base64.b64encode(block).decode("ascii")
                            bf.write("\n".join(b64[i:i + 120] for i in range(0, len(b64), 120)))
                            bf.write("\n")
                        chunks.append(name)
                        idx += 1
                entries.append({"path": rel, "kind": "base64", "sha256": digest, "size": size, "chunks": chunks})
            print(f"  + {rel} ({size} B, {entries[-1]['kind']})")

    manifest = {
        "format": "legacy-transfer/1",
        "created_at": datetime.now(timezone.utc).isoformat(),
        "source_root": os.path.basename(os.path.abspath(source)),
        "files": entries,
    }
    with open(os.path.join(out, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(f"[pack] {len(entries)} fájl → {out}/ (manifest + blobs + text)")
    print("[pack] Commitold és pushold a mappát; a felhő-oldalon: legacy-transfer.py unpack")
    return 0


def unpack(indir, dest):
    mf_path = os.path.join(indir, "manifest.json")
    if not os.path.isfile(mf_path):
        print(f"[unpack] manifest nem található: {mf_path}")
        return 2
    manifest = json.load(open(mf_path, encoding="utf-8"))
    if manifest.get("format") != "legacy-transfer/1":
        print(f"[unpack] ismeretlen formátum: {manifest.get('format')}")
        return 2

    os.makedirs(dest, exist_ok=True)
    errors = 0
    for entry in manifest["files"]:
        target = os.path.join(dest, entry["path"].replace("/", os.sep))
        os.makedirs(os.path.dirname(target), exist_ok=True)
        if entry["kind"] == "text":
            shutil.copyfile(os.path.join(indir, "text", entry["path"]), target)
        else:
            raw = b""
            for chunk in entry["chunks"]:
                b64 = open(os.path.join(indir, "blobs", chunk), encoding="ascii").read()
                raw += base64.b64decode("".join(b64.split()))
            with open(target, "wb") as f:
                f.write(raw)
            actual = hashlib.sha256(raw).hexdigest()
            if actual != entry["sha256"]:
                print(f"  ✗ SHA-256 ELTÉRÉS: {entry['path']} (várt {entry['sha256'][:12]}…, kapott {actual[:12]}…)")
                errors += 1
                continue
        print(f"  ✓ {entry['path']}")
    if errors:
        print(f"[unpack] {errors} integritás-hiba — NE használd az érintett fájlokat.")
        return 1
    print(f"[unpack] kész → {dest}/  (elemzés: python scripts/legacy-binary-analyzer.py --anti-root {dest})")
    return 0


def self_test():
    """Round-trip: szintetikus bináris (TPF0-val) + cp1250 szöveg → pack → unpack → bájt-azonosság."""
    print("[self-test] pack→unpack round-trip…")
    with tempfile.TemporaryDirectory() as tmp:
        src = os.path.join(tmp, "Anti")
        os.makedirs(os.path.join(src, "VALUTA"))
        bin_payload = b"MZ\x90\x00" + os.urandom(64) + b"TPF0" + bytes([8]) + b"TALAPLAP" + os.urandom(32)
        with open(os.path.join(src, "VALUTA", "proba.exe"), "wb") as f:
            f.write(bin_payload)
        pas_payload = "unit Proba;\n// árvíztűrő tükörfúrógép\nend.\n".encode("cp1250")
        with open(os.path.join(src, "VALUTA", "Proba.pas"), "wb") as f:
            f.write(pas_payload)

        out = os.path.join(tmp, "legacy-transfer")
        dest = os.path.join(tmp, "Anti_transfer")
        assert pack(src, out, DEFAULT_INCLUDE) == 0
        # a blob tisztán ASCII szöveg-e? (szöveg-csatorna kompatibilitás — a Base64 lényege)
        blobs = os.listdir(os.path.join(out, "blobs"))
        assert len(blobs) == 1, blobs
        blob_text = open(os.path.join(out, "blobs", blobs[0]), encoding="ascii").read()
        assert all(c.isalnum() or c in "+/=\n" for c in blob_text), "nem tiszta base64 szöveg"
        assert unpack(out, dest) == 0
        restored = open(os.path.join(dest, "VALUTA", "proba.exe"), "rb").read()
        assert restored == bin_payload, "bináris round-trip eltérés!"
        text = open(os.path.join(dest, "VALUTA", "Proba.pas"), encoding="utf-8").read()
        assert "árvíztűrő tükörfúrógép" in text, "cp1250→UTF-8 konverzió elveszett"
        # integritás-őr: rontott blob → hibát jelez
        blob_path = os.path.join(out, "blobs", blobs[0])
        corrupted = open(blob_path).read().replace("A", "B", 1)
        open(blob_path, "w").write(corrupted)
        assert unpack(out, os.path.join(tmp, "dest2")) == 1, "rontott blob átment!"
    print("[self-test] PASS — bináris bájt-azonos, szöveg UTF-8-ban, sha256-őr működik")
    return 0


def main():
    ap = argparse.ArgumentParser(description="Legacy forrás Base64 pack/unpack (git-transzporthoz).")
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("pack")
    p.add_argument("--source", default="Anti")
    p.add_argument("--out", default="legacy-transfer")
    p.add_argument("--include", action="append", help="glob (ismételhető); default: pas/dfm/dpr/inc/exe/dll")
    u = sub.add_parser("unpack")
    u.add_argument("--in", dest="indir", default="legacy-transfer")
    u.add_argument("--dest", default="Anti_transfer")
    sub.add_parser("self-test")
    args = ap.parse_args()

    if args.cmd == "self-test":
        sys.exit(self_test())
    if args.cmd == "pack":
        sys.exit(pack(args.source, args.out, args.include or DEFAULT_INCLUDE))
    sys.exit(unpack(args.indir, args.dest))


if __name__ == "__main__":
    main()
