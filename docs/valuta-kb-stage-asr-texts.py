"""
Stage exported ASR text files into a separate SQLite database.

This avoids contention with the main knowledge base while the security gate or
other tooling is holding a lock on `valuta-knowledge.sqlite`.
"""
from __future__ import annotations

import sqlite3
from pathlib import Path


EXPORTER_MODULE_PATH = Path(__file__).with_name("valuta-kb-export-asr-text.py")
STAGE_DB_PATH = Path(__file__).with_name("valuta-asr-staging.sqlite")
DEFAULT_MEDIA_ROOT = Path(__file__).resolve().parent.parent / "Felmérés"
DEFAULT_OUTPUT_ROOT = Path(__file__).resolve().parent.parent / "docs" / "knowledge" / "generated" / "asr-text"
DEFAULT_MODEL_NAME = "ggml-base.bin"


def load_exporter():
    import importlib.util

    spec = importlib.util.spec_from_file_location("valuta_kb_export_asr_text", EXPORTER_MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def ensure_schema(conn: sqlite3.Connection) -> None:
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS exported_asr_texts (
            stage_id INTEGER PRIMARY KEY AUTOINCREMENT,
            source_path TEXT NOT NULL UNIQUE,
            transcript_path TEXT NOT NULL,
            transcript_text TEXT NOT NULL,
            model_name TEXT NOT NULL,
            status TEXT NOT NULL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
        """
    )


def upsert_stage_row(
    conn: sqlite3.Connection,
    source_path: str,
    transcript_path: str,
    transcript_text: str,
    model_name: str,
    status: str,
) -> None:
    conn.execute(
        """
        INSERT INTO exported_asr_texts(source_path, transcript_path, transcript_text, model_name, status)
        VALUES (?, ?, ?, ?, ?)
        ON CONFLICT(source_path) DO UPDATE SET
            transcript_path=excluded.transcript_path,
            transcript_text=excluded.transcript_text,
            model_name=excluded.model_name,
            status=excluded.status,
            updated_at=CURRENT_TIMESTAMP
        """,
        (source_path, transcript_path, transcript_text, model_name, status),
    )


def stage_exported_texts(
    media_root: Path = DEFAULT_MEDIA_ROOT,
    output_root: Path = DEFAULT_OUTPUT_ROOT,
    stage_db_path: Path = STAGE_DB_PATH,
) -> tuple[int, int]:
    exporter = load_exporter()
    expected = {path.resolve(): exporter.output_path_for_media(path, output_root) for path in exporter.iter_media_files(media_root)}

    conn = sqlite3.connect(stage_db_path)
    try:
        ensure_schema(conn)
        staged = 0
        missing = 0
        for media_path, transcript_path in expected.items():
            if not transcript_path.exists():
                missing += 1
                continue
            transcript_text = transcript_path.read_text(encoding="utf-8", errors="replace").strip()
            upsert_stage_row(
                conn,
                source_path=str(media_path),
                transcript_path=str(transcript_path),
                transcript_text=transcript_text,
                model_name=DEFAULT_MODEL_NAME,
                status="completed" if transcript_text else "empty",
            )
            staged += 1
        conn.commit()
        return staged, missing
    finally:
        conn.close()


def main() -> None:
    staged, missing = stage_exported_texts()
    print("ASR staging complete.")
    print(f"  staged={staged}")
    print(f"  missing={missing}")
    print(f"  stage_db={STAGE_DB_PATH}")


if __name__ == "__main__":
    main()
