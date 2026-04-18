import importlib.util
import sqlite3
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("valuta-kb-ingest-asr-text.py")


def load_module():
    spec = importlib.util.spec_from_file_location("valuta_kb_ingest_asr_text", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


class ValutaKbIngestAsrTextTests(unittest.TestCase):
    def test_build_expected_transcript_map_matches_export_naming(self):
        ingest_module = load_module()

        with tempfile.TemporaryDirectory() as tmp_dir:
            root = Path(tmp_dir)
            media_root = root / "Felmérés"
            media_root.mkdir()
            media_path = media_root / "Hang 003_sd.m4a"
            media_path.write_bytes(b"audio")
            output_root = root / "out"

            mapping = ingest_module.build_expected_transcript_map(media_root, output_root)

        self.assertEqual(len(mapping), 1)
        expected_output = next(iter(mapping.values()))
        self.assertEqual(expected_output.parent, output_root)
        self.assertEqual(expected_output.suffix, ".txt")

    def test_upsert_asr_text_extract_and_run_writes_rows(self):
        module = load_module()

        with tempfile.TemporaryDirectory() as tmp_dir:
            db_path = Path(tmp_dir) / "test.sqlite"
            conn = sqlite3.connect(db_path)
            cur = conn.cursor()
            cur.executescript(
                """
                CREATE TABLE artifact_text_extracts (
                    extract_id TEXT PRIMARY KEY,
                    artifact_id TEXT NOT NULL,
                    extract_type TEXT NOT NULL,
                    language TEXT,
                    text_content TEXT NOT NULL,
                    char_count INTEGER,
                    quality_score REAL,
                    quality_notes TEXT,
                    created_at TEXT
                );
                CREATE TABLE artifact_ingest_runs (
                    run_id TEXT PRIMARY KEY,
                    artifact_id TEXT NOT NULL,
                    ingest_stage TEXT NOT NULL,
                    ingest_status TEXT NOT NULL,
                    tooling TEXT,
                    output_artifact_id TEXT,
                    error_summary TEXT,
                    started_at TEXT,
                    finished_at TEXT
                );
                """
            )

            module.upsert_asr_text_extract(
                cur,
                "artifact-1",
                "szoveg",
                "hu",
                "source=txt",
                "2026-04-09T20:00:00+00:00",
            )
            module.record_asr_text_run(
                cur,
                "artifact-1",
                "completed",
                "2026-04-09T20:00:00+00:00",
                "ffmpeg-whisper-text",
            )
            conn.commit()

            extract = cur.execute(
                "SELECT artifact_id, extract_type, language, text_content FROM artifact_text_extracts"
            ).fetchone()
            run = cur.execute(
                "SELECT artifact_id, ingest_status, tooling FROM artifact_ingest_runs"
            ).fetchone()
            conn.close()

        self.assertEqual(extract, ("artifact-1", "asr-transcript", "hu", "szoveg"))
        self.assertEqual(run, ("artifact-1", "completed", "ffmpeg-whisper-text"))


if __name__ == "__main__":
    unittest.main()
