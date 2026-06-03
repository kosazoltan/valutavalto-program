from __future__ import annotations

import csv
import ctypes
import json
import os
import re
import subprocess
import sys
import tempfile
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


ROOT = Path(__file__).resolve().parents[2]
INVENTORY_DIR = ROOT / "EXCMD" / "_inventory"
COMPARE_DIR = ROOT / "EXCMD" / "_compare"
MODULE_DIR = ROOT / "EXCMD" / "media-module-extracts"

MANIFEST = INVENTORY_DIR / "media-manifest-2026-06-02.csv"

SELECTED_CSV = INVENTORY_DIR / "media-selected-non-duplicate-2026-06-02.csv"
OCR_JSONL = INVENTORY_DIR / "media-ocr-results-2026-06-02.jsonl"
ASR_JSON = INVENTORY_DIR / "media-asr-results-2026-06-02.json"
SUMMARY_JSON = INVENTORY_DIR / "media-content-summary-2026-06-02.json"
MODULE_INDEX_MD = COMPARE_DIR / "2026-06-02-media-module-content-extracts.md"
OCR_RETRY_REPORT_JSON = INVENTORY_DIR / "media-ocr-retry-report-2026-06-02.json"

TRANSCRIPTS_DIR = INVENTORY_DIR / "media-asr-transcripts-2026-06-02"
ASR_CLIP_SECONDS = 300

TESSERACT_EXE = Path("C:/Program Files/Tesseract-OCR/tesseract.exe")

IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".bmp", ".gif", ".webp"}
AUDIO_EXTS = {".m4a", ".mp3", ".wav", ".flac", ".ogg", ".aac"}


@dataclass
class MediaRow:
    rel_path: str
    root: str
    media_type: str
    extension: str
    size_bytes: int
    duration_seconds: float | None
    sha256: str

    @property
    def abs_path(self) -> Path:
        return ROOT / self.rel_path


def _priority(path: str) -> tuple[int, int, str]:
    checks = [
        ("forrasok/", 1),
        ("Felmérés/", 2),
        ("Anti/VALUTA/", 3),
        ("Anti/SZERVER/_extracted/", 4),
        ("Anti/SZERVER/_extracted_auto/", 5),
        ("Anti/", 6),
    ]
    for prefix, score in checks:
        if path.startswith(prefix):
            return (score, len(path), path)
    return (99, len(path), path)


def load_manifest(path: Path) -> list[MediaRow]:
    rows: list[MediaRow] = []
    with path.open("r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        for r in reader:
            rel = (r.get("rel_path") or "").strip()
            if not rel:
                continue
            size_raw = (r.get("size_bytes") or "0").strip()
            dur_raw = (r.get("duration_seconds") or "").strip()
            ext = (r.get("extension") or "").strip().lower()
            rows.append(
                MediaRow(
                    rel_path=rel,
                    root=(r.get("root") or "").strip(),
                    media_type=(r.get("type") or "").strip(),
                    extension=ext,
                    size_bytes=int(size_raw) if size_raw.isdigit() else 0,
                    duration_seconds=float(dur_raw) if dur_raw else None,
                    sha256=(r.get("sha256") or "").strip(),
                )
            )
    return rows


def select_non_duplicates(rows: Iterable[MediaRow]) -> list[MediaRow]:
    by_hash: dict[str, list[MediaRow]] = defaultdict(list)
    selected: list[MediaRow] = []
    for row in rows:
        h = row.sha256
        if not h:
            selected.append(row)
            continue
        by_hash[h].append(row)

    for h, group in by_hash.items():
        if len(group) == 1:
            selected.append(group[0])
        else:
            selected.append(sorted(group, key=lambda x: _priority(x.rel_path))[0])

    return sorted(selected, key=lambda x: x.rel_path.casefold())


def detect_module(rel_path: str) -> str:
    p = rel_path
    if p.startswith("Felmérés/"):
        return "FELMERES"
    if p.startswith("forrasok/VALUTA/") or p.startswith("Anti/VALUTA/"):
        return "VALUTA"
    if p.startswith("forrasok/ERTEKTAR/") or "/ERTEKTAR/" in p:
        return "ERTEKTAR"
    if p.startswith("forrasok/SZERVER/") or p.startswith("Anti/SZERVER/"):
        return "SZERVER"
    return "OTHER"


def compact_text(s: str, max_len: int = 1200) -> str:
    s = s.replace("\r", "\n")
    s = re.sub(r"\n{3,}", "\n\n", s)
    s = re.sub(r"[ \t]{2,}", " ", s)
    s = s.strip()
    if len(s) <= max_len:
        return s
    return s[:max_len].rstrip() + "..."


def run_ocr(image_path: Path) -> tuple[str, str | None]:
    if not image_path.exists():
        return "", "file-not-found"

    suffix = image_path.suffix.lower()
    # Animated GIFs are not supported by Tesseract/Leptonica — skip them.
    if suffix == ".gif":
        return "", "animated-gif-not-supported"

    attempts = [(6, 45), (3, 90)]
    last_error: str | None = None
    best_out = ""

    # Tesseract on Windows cannot handle non-ASCII (accented) paths.
    # Copy the image to a short ASCII temp path for the duration of OCR.
    import tempfile, shutil
    with tempfile.TemporaryDirectory() as _td:
        safe_input = Path(_td) / ("img" + suffix)
        try:
            shutil.copy2(image_path, safe_input)
        except Exception as exc:
            return "", f"copy-failed: {exc}"

        for psm, timeout_sec in attempts:
            try:
                result = subprocess.run(
                    [
                        str(TESSERACT_EXE),
                        str(safe_input),
                        "stdout",
                        "-l",
                        "hun+eng",
                        "--psm",
                        str(psm),
                    ],
                    capture_output=True,
                    text=True,
                    encoding="utf-8",
                    errors="ignore",
                    timeout=timeout_sec,
                    check=False,
                )
                out = (result.stdout or "").strip()
                if out and len(out) > len(best_out):
                    best_out = out
                if result.returncode == 0:
                    return compact_text(out), None
                err = (result.stderr or "").strip()
                last_error = err or f"exit-{result.returncode}"
            except Exception as exc:  # noqa: BLE001
                last_error = str(exc)

    return compact_text(best_out), last_error or "ocr-failed"


def _configure_cuda_runtime() -> dict:
    dll_dirs: list[str] = []
    for base in [Path(p) for p in sys.path if p]:
        nvidia_root = base / "nvidia"
        if not nvidia_root.exists():
            continue
        for sub in nvidia_root.glob("*"):
            if not sub.is_dir():
                continue
            for candidate in [sub / "bin", sub / "lib", sub]:
                if candidate.exists() and candidate.is_dir():
                    s = str(candidate)
                    if s not in dll_dirs:
                        dll_dirs.append(s)

    if os.name == "nt":
        for d in dll_dirs:
            try:
                os.add_dll_directory(d)
            except Exception:
                pass
        if dll_dirs:
            os.environ["PATH"] = os.pathsep.join(dll_dirs + [os.environ.get("PATH", "")])

    return {"cuda_dll_dirs": dll_dirs}


def retry_ocr_errors(image_rows: list[MediaRow], ocr_records: list[dict]) -> tuple[list[dict], dict]:
    image_by_path = {r.rel_path: r for r in image_rows}
    retried = 0
    fixed = 0
    still_error = 0
    missing = 0

    for rec in ocr_records:
        if not rec.get("error"):
            continue
        rel = rec.get("rel_path")
        row = image_by_path.get(rel)
        if not row:
            continue

        retried += 1
        text_preview, err = run_ocr(row.abs_path)
        rec["text_preview"] = text_preview
        rec["error"] = err
        rec["ocr_retry"] = True
        if err:
            still_error += 1
            if err == "file-not-found":
                missing += 1
        else:
            fixed += 1

    report = {
        "retried": retried,
        "fixed": fixed,
        "still_error": still_error,
        "missing": missing,
    }
    return ocr_records, report


def write_selected_csv(selected: list[MediaRow]) -> None:
    with SELECTED_CSV.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["rel_path", "module", "type", "extension", "size_bytes", "duration_seconds", "sha256"])
        for r in selected:
            w.writerow(
                [
                    r.rel_path,
                    detect_module(r.rel_path),
                    r.media_type,
                    r.extension,
                    r.size_bytes,
                    "" if r.duration_seconds is None else f"{r.duration_seconds:.3f}",
                    r.sha256,
                ]
            )


def run_asr(audio_rows: list[MediaRow]) -> list[dict]:
    try:
        from faster_whisper import WhisperModel
    except Exception as exc:  # noqa: BLE001
        return [{"error": f"import-failed: {exc}"}]

    TRANSCRIPTS_DIR.mkdir(parents=True, exist_ok=True)
    runtime_bootstrap = _configure_cuda_runtime()

    def _has_cuda_runtime() -> bool:
        try:
            ctypes.WinDLL("cublas64_12.dll")
            ctypes.WinDLL("cudnn64_9.dll")
            return True
        except Exception:
            return False

    # Prefer GPU for speed; fall back to CPU when CUDA is unavailable.
    if _has_cuda_runtime():
        try:
            model = WhisperModel("tiny", device="cuda", compute_type="float16")
            asr_runtime = {"device": "cuda", "compute_type": "float16", **runtime_bootstrap}
        except Exception:
            model = WhisperModel("tiny", device="cpu", compute_type="int8")
            asr_runtime = {
                "device": "cpu",
                "compute_type": "int8",
                "fallback": "cuda-init-failed",
                **runtime_bootstrap,
            }
    else:
        model = WhisperModel("tiny", device="cpu", compute_type="int8")
        asr_runtime = {
            "device": "cpu",
            "compute_type": "int8",
            "fallback": "cuda-runtime-missing",
            **runtime_bootstrap,
        }
    results: list[dict] = []

    for row in audio_rows:
        item = {
            "rel_path": row.rel_path,
            "module": detect_module(row.rel_path),
            "duration_seconds": row.duration_seconds,
            "sha256": row.sha256,
        }
        p = row.abs_path
        if not p.exists():
            item["error"] = "file-not-found"
            results.append(item)
            continue
        try:
            # Transcribe only the first N seconds to keep turnaround practical on CPU.
            with tempfile.TemporaryDirectory() as td:
                clip_path = Path(td) / "clip.wav"
                ffmpeg = subprocess.run(
                    [
                        "ffmpeg",
                        "-y",
                        "-v",
                        "error",
                        "-i",
                        str(p),
                        "-t",
                        str(ASR_CLIP_SECONDS),
                        "-ac",
                        "1",
                        "-ar",
                        "16000",
                        str(clip_path),
                    ],
                    capture_output=True,
                    text=True,
                    check=False,
                )
                if ffmpeg.returncode != 0 or not clip_path.exists():
                    item["error"] = (ffmpeg.stderr or "ffmpeg-clip-failed").strip()[:800]
                    results.append(item)
                    continue

                try:
                    segments, info = model.transcribe(str(clip_path), beam_size=1, vad_filter=True)
                except Exception as transcribe_exc:  # noqa: BLE001
                    # Some Windows setups can initialize CUDA but fail later due missing DLLs.
                    # Retry once on CPU so the pass can still complete end-to-end.
                    msg = str(transcribe_exc).lower()
                    cuda_dll_error = any(x in msg for x in ["cublas", "cudnn", "cuda", "dll"])
                    if asr_runtime.get("device") == "cuda" and cuda_dll_error:
                        model = WhisperModel("tiny", device="cpu", compute_type="int8")
                        asr_runtime = {
                            "device": "cpu",
                            "compute_type": "int8",
                            "fallback": "cuda-runtime-missing",
                            **runtime_bootstrap,
                        }
                        segments, info = model.transcribe(str(clip_path), beam_size=1, vad_filter=True)
                    else:
                        raise
            text_parts = []
            ts_parts = []
            for seg in segments:
                seg_text = (seg.text or "").strip()
                if not seg_text:
                    continue
                text_parts.append(seg_text)
                ts_parts.append(f"[{seg.start:.2f}-{seg.end:.2f}] {seg_text}")
            full_text = " ".join(text_parts).strip()
            transcript_file = TRANSCRIPTS_DIR / (re.sub(r"[^A-Za-z0-9._-]", "_", row.rel_path) + ".txt")
            transcript_file.write_text("\n".join(ts_parts), encoding="utf-8")
            item.update(
                {
                    "language": getattr(info, "language", None),
                    "language_probability": getattr(info, "language_probability", None),
                    "segments": len(ts_parts),
                    "transcribed_seconds": ASR_CLIP_SECONDS,
                    "note": "first-5-minutes-extract",
                    "asr_runtime": asr_runtime,
                    "text_preview": compact_text(full_text, 800),
                    "transcript_file": str(transcript_file.relative_to(ROOT)).replace("\\", "/"),
                }
            )
        except Exception as exc:  # noqa: BLE001
            item["error"] = str(exc)
        results.append(item)
    return results


def write_module_outputs(
    selected: list[MediaRow],
    ocr_records: list[dict],
    asr_records: list[dict],
) -> None:
    MODULE_DIR.mkdir(parents=True, exist_ok=True)

    ocr_by_path = {r["rel_path"]: r for r in ocr_records}
    asr_by_path = {r["rel_path"]: r for r in asr_records}
    mod_rows: dict[str, list[MediaRow]] = defaultdict(list)

    for row in selected:
        mod_rows[detect_module(row.rel_path)].append(row)

    idx_lines = [
        "# Modulonkénti OCR/ASR kivonat (2026-06-02)",
        "",
        "Automatikusan generált tartalmi kivonatok a nem-duplikált médiahalmazról.",
        "",
        "## Modul fájlok",
        "",
    ]

    for mod in sorted(mod_rows):
        out_file = MODULE_DIR / f"2026-06-02-{mod.lower()}-media-kivonat.md"
        rows = mod_rows[mod]
        images = [r for r in rows if r.extension in IMAGE_EXTS]
        audios = [r for r in rows if r.extension in AUDIO_EXTS]

        lines = [
            f"# {mod} - Média tartalmi kivonat (2026-06-02)",
            "",
            f"- Nem-duplikált elemek: {len(rows)}",
            f"- Képek: {len(images)}",
            f"- Hangok: {len(audios)}",
            "",
            "## OCR kivonatok (képek)",
            "",
        ]

        image_added = 0
        for r in images:
            rec = ocr_by_path.get(r.rel_path)
            if not rec:
                continue
            txt = (rec.get("text_preview") or "").strip()
            if not txt:
                continue
            lines.append(f"### {r.rel_path}")
            lines.append("")
            lines.append(txt)
            lines.append("")
            image_added += 1
            if image_added >= 40:
                break

        lines.append("## ASR kivonatok (hang)")
        lines.append("")
        for r in audios:
            rec = asr_by_path.get(r.rel_path)
            if not rec:
                continue
            lines.append(f"### {r.rel_path}")
            lines.append("")
            if rec.get("error"):
                lines.append(f"- Hiba: {rec['error']}")
            else:
                lines.append(f"- Nyelv: {rec.get('language')}")
                lines.append(f"- Szakaszok: {rec.get('segments')}")
                lines.append(f"- Kivonat: {rec.get('text_preview') or '(ures)'}")
                lines.append(f"- Transcript: {rec.get('transcript_file')}")
            lines.append("")

        out_file.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
        rel = str(out_file.relative_to(ROOT)).replace("\\", "/")
        idx_lines.append(f"- `{rel}`")

    MODULE_INDEX_MD.write_text("\n".join(idx_lines).rstrip() + "\n", encoding="utf-8")


def _write_summary(selected: list[MediaRow], image_rows: list[MediaRow], ocr_records: list[dict], asr_records: list[dict]) -> dict:
    summary = {
        "selected_non_duplicate_total": len(selected),
        "selected_images": len(image_rows),
        "selected_audios": len([r for r in selected if r.extension in AUDIO_EXTS]),
        "ocr_processed": len(ocr_records),
        "ocr_with_text": sum(1 for r in ocr_records if (r.get("text_preview") or "").strip()),
        "ocr_errors": sum(1 for r in ocr_records if r.get("error")),
        "asr_processed": len([r for r in asr_records if isinstance(r, dict) and r.get("rel_path")]),
        "asr_errors": sum(1 for r in asr_records if isinstance(r, dict) and r.get("error")),
        "artifacts": {
            "selected_csv": str(SELECTED_CSV.relative_to(ROOT)).replace("\\", "/"),
            "ocr_jsonl": str(OCR_JSONL.relative_to(ROOT)).replace("\\", "/"),
            "asr_json": str(ASR_JSON.relative_to(ROOT)).replace("\\", "/"),
            "module_index": str(MODULE_INDEX_MD.relative_to(ROOT)).replace("\\", "/"),
            "module_dir": str(MODULE_DIR.relative_to(ROOT)).replace("\\", "/"),
            "ocr_retry_report": str(OCR_RETRY_REPORT_JSON.relative_to(ROOT)).replace("\\", "/"),
        },
    }
    SUMMARY_JSON.write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    return summary


def main() -> None:
    if not TESSERACT_EXE.exists():
        raise SystemExit(f"Tesseract not found at: {TESSERACT_EXE}")
    if not MANIFEST.exists():
        raise SystemExit(f"Manifest not found: {MANIFEST}")

    retry_ocr_errors_only = "--retry-ocr-errors-only" in sys.argv

    all_rows = load_manifest(MANIFEST)
    selected = select_non_duplicates(all_rows)
    write_selected_csv(selected)

    image_rows = [r for r in selected if r.extension in IMAGE_EXTS]
    audio_rows = [r for r in selected if r.extension in AUDIO_EXTS]

    ocr_records: list[dict] = []
    if retry_ocr_errors_only and OCR_JSONL.exists():
        with OCR_JSONL.open("r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                ocr_records.append(json.loads(line))
        ocr_records, retry_report = retry_ocr_errors(image_rows, ocr_records)
        OCR_RETRY_REPORT_JSON.write_text(json.dumps(retry_report, ensure_ascii=False, indent=2), encoding="utf-8")
    else:
        for idx, row in enumerate(image_rows, start=1):
            text_preview, err = run_ocr(row.abs_path)
            item = {
                "index": idx,
                "rel_path": row.rel_path,
                "module": detect_module(row.rel_path),
                "sha256": row.sha256,
                "text_preview": text_preview,
                "error": err,
            }
            ocr_records.append(item)
        OCR_RETRY_REPORT_JSON.write_text(
            json.dumps({"retried": 0, "fixed": 0, "still_error": 0, "missing": 0}, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )

    with OCR_JSONL.open("w", encoding="utf-8") as out:
        for rec in ocr_records:
            out.write(json.dumps(rec, ensure_ascii=False) + "\n")

    asr_records = run_asr(audio_rows)
    ASR_JSON.write_text(json.dumps(asr_records, ensure_ascii=False, indent=2), encoding="utf-8")

    write_module_outputs(selected, ocr_records, asr_records)

    summary = _write_summary(selected, image_rows, ocr_records, asr_records)
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
