"""
Ingest previously exported ASR text files into the knowledge base.

This script assumes transcripts were first generated as `.txt` files by
`valuta-kb-export-asr-text.py`, then maps them back to media artifacts and
stores them in `artifact_text_extracts`.
"""
from __future__ import annotations

import hashlib
import importlib.util
from pathlib import Path


DB_PATH = Path(__file__).with_name("valuta-knowledge.sqlite")
EXPORTER_MODULE_PATH = Path(__file__).with_name("valuta-kb-export-asr-text.py")
MEDIA_MODULE_PATH = Path(__file__).with_name("valuta-kb-extract-media-metadata.py")
DEFAULT_MEDIA_ROOT = Path(__file__).resolve().parent.parent / "Felmérés"
DEFAULT_OUTPUT_ROOT = Path(__file__).resolve().parent.parent / "docs" / "knowledge" / "generated" / "asr-text"


def load_module(path: Path, name: str):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def build_expected_transcript_map(media_root: Path, output_root: Path) -> dict[Path, Path]:
    exporter = load_module(EXPORTER_MODULE_PATH, "valuta_kb_export_asr_text")
    mapping: dict[Path, Path] = {}
    for media_path in exporter.iter_media_files(media_root):
        mapping[media_path.resolve()] = exporter.output_path_for_media(media_path, output_root)
    return mapping


def upsert_asr_text_extract(cur, artifact_id: str, transcript: str, language: str, quality_notes: str, timestamp: str):
    extract_id = hashlib.sha1(f"{artifact_id}:asr-transcript".encode("utf-8")).hexdigest()
    cur.execute(
        """
        INSERT OR REPLACE INTO artifact_text_extracts(
            extract_id, artifact_id, extract_type, language, text_content,
            char_count, quality_score, quality_notes, created_at
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            extract_id,
            artifact_id,
            "asr-transcript",
            language,
            transcript,
            len(transcript),
            0.6,
            quality_notes,
            timestamp,
        ),
    )


def record_asr_text_run(
    cur,
    artifact_id: str,
    ingest_status: str,
    timestamp: str,
    tooling: str,
    error_summary: str | None = None,
):
    status_key = ingest_status if not error_summary else f"{ingest_status}:{error_summary}"
    run_id = hashlib.sha1(f"{artifact_id}:asr-text:{tooling}:{status_key}".encode("utf-8")).hexdigest()
    cur.execute(
        """
        INSERT OR REPLACE INTO artifact_ingest_runs(
            run_id, artifact_id, ingest_stage, ingest_status, tooling,
            output_artifact_id, error_summary, started_at, finished_at
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            run_id,
            artifact_id,
            "transcribed",
            ingest_status,
            tooling,
            None,
            error_summary,
            timestamp,
            timestamp,
        ),
    )


def main() -> None:
    media_module = load_module(MEDIA_MODULE_PATH, "valuta_kb_extract_media_metadata")
    conn = media_module.open_db_connection(DB_PATH)
    try:
        cur = conn.cursor()
        timestamp = media_module.now_utc()
        expected_map = build_expected_transcript_map(DEFAULT_MEDIA_ROOT, DEFAULT_OUTPUT_ROOT)

        rows = cur.execute(
            """
            SELECT artifact_id, absolute_path
            FROM source_artifacts
            WHERE artifact_kind != 'directory'
              AND format_family IN ('audio','video')
            ORDER BY absolute_path
            """
        ).fetchall()

        ingested = 0
        skipped = 0
        for artifact_id, absolute_path in rows:
            media_path = Path(absolute_path).resolve()
            transcript_path = expected_map.get(media_path)
            if not transcript_path or not transcript_path.exists():
                skipped += 1
                continue
            transcript = transcript_path.read_text(encoding="utf-8", errors="replace").strip()
            if not transcript:
                record_asr_text_run(cur, artifact_id, "partial", timestamp, "ffmpeg-whisper-text", "empty-transcript")
                continue
            notes = f"source_file={transcript_path.name};imported_from=ffmpeg-whisper-text"
            upsert_asr_text_extract(cur, artifact_id, transcript, "hu", notes, timestamp)
            record_asr_text_run(cur, artifact_id, "completed", timestamp, "ffmpeg-whisper-text")
            ingested += 1

        coverage_rows = media_module.rebuild_coverage(cur)
        gap_rows = media_module.rebuild_gaps(cur)
        conn.commit()
    finally:
        conn.close()

    print("ASR text ingest complete.")
    print(f"  ingested={ingested}")
    print(f"  skipped={skipped}")
    print(f"  coverage_rows={coverage_rows}")
    print(f"  gap_rows={gap_rows}")


if __name__ == "__main__":
    main()
