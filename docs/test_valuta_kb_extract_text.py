import importlib.util
import sqlite3
import tempfile
import unittest
import zipfile
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("valuta-kb-extract-text.py")


def load_module():
    spec = importlib.util.spec_from_file_location("valuta_kb_extract_text", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


class ValutaKbExtractTextTests(unittest.TestCase):
    def test_supported_text_families_include_pascal_and_docx(self):
        module = load_module()

        self.assertTrue(module.is_text_extractable("pascal", ".pas"))
        self.assertTrue(module.is_text_extractable("word", ".docx"))
        self.assertFalse(module.is_text_extractable("binary-pe", ".exe"))

    def test_extract_text_from_plaintext_file_with_cp1250_fallback(self):
        module = load_module()

        with tempfile.TemporaryDirectory() as tmp_dir:
            sample = Path(tmp_dir) / "minta.txt"
            sample.write_bytes("Árfolyamőrzés".encode("cp1250"))

            text, extract_type, quality_notes = module.extract_text_from_path(sample, "text")

        self.assertIn("Árfolyamőrzés", text)
        self.assertEqual(extract_type, "fulltext")
        self.assertIn("cp1250", quality_notes)

    def test_extract_docx_text_reads_document_xml(self):
        module = load_module()

        with tempfile.TemporaryDirectory() as tmp_dir:
            sample = Path(tmp_dir) / "minta.docx"
            with zipfile.ZipFile(sample, "w") as zf:
                zf.writestr(
                    "[Content_Types].xml",
                    """<?xml version="1.0" encoding="UTF-8"?>
                    <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"></Types>""",
                )
                zf.writestr(
                    "word/document.xml",
                    """<?xml version="1.0" encoding="UTF-8"?>
                    <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
                      <w:body>
                        <w:p><w:r><w:t>Első sor</w:t></w:r></w:p>
                        <w:p><w:r><w:t>Második sor</w:t></w:r></w:p>
                      </w:body>
                    </w:document>""",
                )

            text, extract_type, quality_notes = module.extract_text_from_path(sample, "word")

        self.assertIn("Első sor", text)
        self.assertIn("Második sor", text)
        self.assertEqual(extract_type, "office-xml")
        self.assertIn("document.xml", quality_notes)

    def test_invalid_odt_falls_back_to_plain_text(self):
        module = load_module()

        with tempfile.TemporaryDirectory() as tmp_dir:
            sample = Path(tmp_dir) / "legacy.odt"
            sample.write_text("Nem zip, de olvasható szöveg", encoding="utf-8")

            text, extract_type, quality_notes = module.extract_text_from_path(sample, "word")

        self.assertIn("olvasható szöveg", text)
        self.assertEqual(extract_type, "fulltext")
        self.assertIn("fallback", quality_notes)

    def test_upsert_text_extract_writes_extract_and_indexed_run(self):
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
                    created_at TEXT DEFAULT CURRENT_TIMESTAMP
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

            module.upsert_text_extract(
                cur=cur,
                artifact_id="artifact-1",
                extract_type="fulltext",
                text_content="mintaszoveg",
                quality_score=0.9,
                quality_notes="unit-test",
                timestamp="2026-04-09T12:00:00+00:00",
            )
            conn.commit()

            extract = cur.execute(
                "SELECT artifact_id, extract_type, text_content, char_count, quality_score, quality_notes FROM artifact_text_extracts"
            ).fetchone()
            run = cur.execute(
                "SELECT artifact_id, ingest_stage, ingest_status, tooling FROM artifact_ingest_runs"
            ).fetchone()
            conn.close()

        self.assertEqual(
            extract,
            ("artifact-1", "fulltext", "mintaszoveg", len("mintaszoveg"), 0.9, "unit-test"),
        )
        self.assertEqual(run, ("artifact-1", "indexed", "completed", "anti-text-extract"))


if __name__ == "__main__":
    unittest.main()
