import importlib.util
import sqlite3
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("valuta-kb-extract-felmeres-ocr.py")
MEDIA_MODULE_PATH = Path(__file__).with_name("valuta-kb-extract-media-metadata.py")


def load_module(path: Path, name: str):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


class ValutaKbExtractFelmeresOcrTests(unittest.TestCase):
    def test_iter_felmeres_candidates_only_returns_felmeres_media_needing_ocr(self):
        module = load_module(MODULE_PATH, "valuta_kb_extract_felmeres_ocr")
        media_module = load_module(MEDIA_MODULE_PATH, "valuta_kb_extract_media_metadata")

        with tempfile.TemporaryDirectory() as tmp_dir:
            db_path = Path(tmp_dir) / "test.sqlite"
            conn = sqlite3.connect(db_path)
            cur = conn.cursor()
            cur.executescript(
                """
                CREATE TABLE source_artifacts (
                    artifact_id TEXT PRIMARY KEY,
                    source_root TEXT NOT NULL,
                    absolute_path TEXT NOT NULL,
                    artifact_kind TEXT NOT NULL,
                    format_family TEXT NOT NULL,
                    extension TEXT
                );
                CREATE TABLE artifact_text_extracts (
                    extract_id TEXT PRIMARY KEY,
                    artifact_id TEXT NOT NULL,
                    extract_type TEXT NOT NULL
                );
                """
            )
            cur.executemany(
                "INSERT INTO source_artifacts(artifact_id, source_root, absolute_path, artifact_kind, format_family, extension) VALUES (?, ?, ?, ?, ?, ?)",
                [
                    ("f-img", "Felmeres", "fel.png", "file", "image", ".png"),
                    ("f-pdf", "Felmeres", "fel.pdf", "file", "pdf", ".pdf"),
                    ("a-img", "Anti", "anti.png", "file", "image", ".png"),
                ],
            )
            cur.executemany(
                "INSERT INTO artifact_text_extracts(extract_id, artifact_id, extract_type) VALUES (?, ?, ?)",
                [
                    ("e1", "f-pdf", "pdf-text"),
                    ("e2", "a-img", "image-metadata"),
                ],
            )

            original = media_module.tesseract_available
            media_module.tesseract_available = lambda: True
            try:
                rows = module.iter_felmeres_candidates(cur, media_module)
            finally:
                media_module.tesseract_available = original
                conn.close()

        self.assertEqual(rows, [("f-img", "fel.png", "image", ".png")])


if __name__ == "__main__":
    unittest.main()
