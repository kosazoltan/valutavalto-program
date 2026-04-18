"""
Run OCR extraction for the Felmeres image/PDF corpus.

Reuses the tested OCR helpers from valuta-kb-extract-media-metadata.py
but scopes the candidate set to the Felmeres source root.
"""
from __future__ import annotations

import importlib.util
from pathlib import Path


DB_PATH = Path(__file__).with_name("valuta-knowledge.sqlite")
MEDIA_MODULE_PATH = Path(__file__).with_name("valuta-kb-extract-media-metadata.py")


def load_media_module():
    spec = importlib.util.spec_from_file_location("valuta_kb_extract_media_metadata", MEDIA_MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def iter_felmeres_candidates(cur, media_module):
    rows = cur.execute(
        """
        SELECT sa.artifact_id, sa.absolute_path, sa.format_family, sa.extension,
               GROUP_CONCAT(te.extract_type, ',')
        FROM source_artifacts sa
        LEFT JOIN artifact_text_extracts te ON te.artifact_id = sa.artifact_id
        WHERE sa.source_root='Felmeres'
          AND sa.artifact_kind != 'directory'
          AND sa.format_family IN ('image','pdf')
        GROUP BY sa.artifact_id, sa.absolute_path, sa.format_family, sa.extension
        ORDER BY sa.absolute_path
        """
    ).fetchall()
    ocr_ready = media_module.tesseract_available()
    result = []
    for artifact_id, absolute_path, format_family, extension, extract_types_csv in rows:
        extract_types = set((extract_types_csv or "").split(",")) if extract_types_csv else set()
        if not extract_types or media_module.needs_media_reextract(format_family, extension or "", extract_types, ocr_ready):
            result.append((artifact_id, absolute_path, format_family, extension))
    return result


def main():
    media_module = load_media_module()
    conn = media_module.open_db_connection(DB_PATH)
    cur = conn.cursor()
    timestamp = media_module.now_utc()

    extracted = 0
    completed = 0
    partial = 0
    failed = 0

    for artifact_id, absolute_path, format_family, extension in iter_felmeres_candidates(cur, media_module):
        path = Path(absolute_path)
        if not path.exists() or not path.is_file():
            media_module.record_ingest_run(cur, artifact_id, "failed", timestamp, "missing-file")
            failed += 1
            continue
        try:
            text, extract_type, notes, quality, status = media_module.process_candidate(path, format_family, extension or "")
            cleaned = text.strip()
            if not cleaned:
                media_module.record_ingest_run(cur, artifact_id, "partial", timestamp, "empty-metadata")
                partial += 1
                continue
            media_module.upsert_extract(cur, artifact_id, extract_type, cleaned, quality, notes, timestamp)
            if status == "completed":
                media_module.record_ingest_run(cur, artifact_id, "completed", timestamp)
                completed += 1
            else:
                reason = "ocr-needed" if "ocr-available" in notes else "metadata-only"
                media_module.record_ingest_run(cur, artifact_id, "partial", timestamp, reason)
                partial += 1
            extracted += 1
        except Exception as exc:
            media_module.record_ingest_run(cur, artifact_id, "failed", timestamp, type(exc).__name__)
            failed += 1

    coverage_rows = media_module.rebuild_coverage(cur)
    gap_rows = media_module.rebuild_gaps(cur)
    metrics = {
        "extracted": extracted,
        "completed": completed,
        "partial": partial,
        "failed": failed,
        "coverage_rows": coverage_rows,
        "gap_rows": gap_rows,
    }
    media_module.record_checkpoint(cur, metrics)

    conn.commit()
    conn.close()

    print("Felmeres OCR pass complete.")
    for key, value in metrics.items():
        print(f"  {key}={value}")


if __name__ == "__main__":
    main()
