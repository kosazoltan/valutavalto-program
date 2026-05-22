"""
Helyi interjú-átirat (faster-whisper, CUDA). A Felmérés/Valuta alatti .m4a
hangfelvételeket írja át magyar szöveggé, EXCMD/_inventory/transcripts/ alá.
NEM tölt le külső MCP-t — csak a már telepített ffmpeg + faster-whisper.
"""
import csv, os, sys, io, time

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
BASE = "Felmérés/Valuta"
OUT = "EXCMD/_inventory/transcripts"
os.makedirs(OUT, exist_ok=True)

rows = [r for r in csv.DictReader(open("EXCMD/_inventory/primary-worklist.csv", encoding="utf-8"))
        if r["ext"] == "m4a"]
print(f"[transcribe] {len(rows)} m4a fájl")

from faster_whisper import WhisperModel
# RTX 5090 → CUDA float16; ha nem megy, CPU int8 fallback
try:
    model = WhisperModel("large-v3", device="cuda", compute_type="float16")
    print("[transcribe] modell: large-v3 / cuda / float16")
except Exception as e:
    print(f"[transcribe] CUDA nem ment ({e}); CPU/int8 fallback")
    model = WhisperModel("large-v3", device="cpu", compute_type="int8")

for i, r in enumerate(rows, 1):
    src = os.path.join(BASE, r["relpath"])
    safe = r["relpath"].replace("/", "__").replace("\\", "__")
    dst = os.path.join(OUT, safe + ".txt")
    if os.path.exists(dst) and os.path.getsize(dst) > 0:
        print(f"[{i}/{len(rows)}] SKIP (kész): {safe}")
        continue
    if not os.path.exists(src):
        print(f"[{i}/{len(rows)}] HIÁNYZIK: {src}")
        continue
    t0 = time.time()
    print(f"[{i}/{len(rows)}] átírás: {r['relpath']} ...")
    segments, info = model.transcribe(src, language="hu", vad_filter=True)
    with open(dst, "w", encoding="utf-8") as fh:
        fh.write(f"# Átirat: {r['relpath']}\n# nyelv: {info.language} ({info.language_probability:.2f}), hossz: {info.duration:.0f}s\n\n")
        for seg in segments:
            fh.write(f"[{seg.start:7.1f}] {seg.text.strip()}\n")
    print(f"[{i}/{len(rows)}] KÉSZ ({time.time()-t0:.0f}s) -> {dst}")

print("[transcribe] MIND KÉSZ")
