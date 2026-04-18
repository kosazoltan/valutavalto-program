import importlib.util
import sqlite3
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("valuta-kb-stage-asr-texts.py")


def load_module():
    spec = importlib.util.spec_from_file_location("valuta_kb_stage_asr_texts", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


class ValutaKbStageAsrTextsTests(unittest.TestCase):
    def test_ensure_schema_creates_stage_table(self):
        module = load_module()

        with tempfile.TemporaryDirectory() as tmp_dir:
            db_path = Path(tmp_dir) / "stage.sqlite"
            conn = sqlite3.connect(db_path)
            module.ensure_schema(conn)
            tables = conn.execute(
                "SELECT name FROM sqlite_master WHERE type='table' AND name='exported_asr_texts'"
            ).fetchall()
            conn.close()

        self.assertEqual(tables, [("exported_asr_texts",)])

    def test_upsert_stage_row_writes_transcript(self):
        module = load_module()

        with tempfile.TemporaryDirectory() as tmp_dir:
            db_path = Path(tmp_dir) / "stage.sqlite"
            conn = sqlite3.connect(db_path)
            module.ensure_schema(conn)
            module.upsert_stage_row(
                conn,
                source_path="D:/repo/valutavalto-program/Felmérés/audio.m4a",
                transcript_path="D:/repo/valutavalto-program/docs/knowledge/generated/asr-text/audio.txt",
                transcript_text="minta szoveg",
                model_name="ggml-base.bin",
                status="completed",
            )
            row = conn.execute(
                "SELECT source_path, transcript_path, transcript_text, model_name, status FROM exported_asr_texts"
            ).fetchone()
            conn.close()

        self.assertEqual(
            row,
            (
                "D:/repo/valutavalto-program/Felmérés/audio.m4a",
                "D:/repo/valutavalto-program/docs/knowledge/generated/asr-text/audio.txt",
                "minta szoveg",
                "ggml-base.bin",
                "completed",
            ),
        )


if __name__ == "__main__":
    unittest.main()
