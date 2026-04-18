import importlib.util
import os
import sqlite3
import tempfile
import unittest
from unittest import mock
from pathlib import Path

import fitz
from PIL import Image


MODULE_PATH = Path(__file__).with_name("valuta-kb-extract-media-metadata.py")


def load_module():
    spec = importlib.util.spec_from_file_location("valuta_kb_extract_media_metadata", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


class ValutaKbExtractMediaMetadataTests(unittest.TestCase):
    def test_resolve_tesseract_cmd_prefers_env_override(self):
        module = load_module()

        with tempfile.TemporaryDirectory() as tmp_dir:
            fake_exe = Path(tmp_dir) / "tesseract.exe"
            fake_exe.write_text("stub", encoding="utf-8")
            old_value = os.environ.get("TESSERACT_CMD")
            os.environ["TESSERACT_CMD"] = str(fake_exe)
            try:
                resolved = module.resolve_tesseract_cmd()
            finally:
                if old_value is None:
                    os.environ.pop("TESSERACT_CMD", None)
                else:
                    os.environ["TESSERACT_CMD"] = old_value

        self.assertEqual(resolved, str(fake_exe))

    def test_needs_media_reextract_when_only_metadata_exists_and_ocr_available(self):
        module = load_module()

        self.assertTrue(
            module.needs_media_reextract("image", ".png", {"image-metadata"}, tesseract_is_available=True)
        )
        self.assertTrue(
            module.needs_media_reextract("pdf", ".pdf", {"pdf-metadata"}, tesseract_is_available=True)
        )
        self.assertFalse(
            module.needs_media_reextract("image", ".png", {"ocr"}, tesseract_is_available=True)
        )
        self.assertFalse(
            module.needs_media_reextract("pdf", ".pdf", {"pdf-text"}, tesseract_is_available=True)
        )

    def test_extract_pdf_text_reads_visible_text(self):
        module = load_module()

        with tempfile.TemporaryDirectory() as tmp_dir:
            sample = Path(tmp_dir) / "minta.pdf"
            doc = fitz.open()
            page = doc.new_page()
            page.insert_text((72, 72), "PDF minta szoveg")
            doc.save(sample)
            doc.close()

            text, extract_type, notes = module.extract_pdf_text_or_metadata(sample)

        self.assertIn("PDF minta szoveg", text)
        self.assertEqual(extract_type, "pdf-text")
        self.assertIn("pages=1", notes)

    def test_extract_pdf_text_or_metadata_uses_ocr_when_no_embedded_text(self):
        module = load_module()

        with tempfile.TemporaryDirectory() as tmp_dir:
            sample = Path(tmp_dir) / "scan.pdf"
            doc = fitz.open()
            page = doc.new_page()
            page.draw_rect((50, 50, 250, 150), color=(0, 0, 0), fill=(1, 1, 1))
            doc.save(sample)
            doc.close()

            with mock.patch.object(module, "tesseract_available", return_value=True):
                with mock.patch.object(module, "try_pdf_ocr", return_value="OCR MINTA PDF"):
                    text, extract_type, notes = module.extract_pdf_text_or_metadata(sample)

        self.assertIn("OCR MINTA PDF", text)
        self.assertEqual(extract_type, "pdf-ocr")
        self.assertIn("pages=1", notes)

    def test_extract_image_metadata_reports_size_and_mode(self):
        module = load_module()

        with tempfile.TemporaryDirectory() as tmp_dir:
            sample = Path(tmp_dir) / "kep.png"
            Image.new("RGB", (40, 20), color="white").save(sample)

            text, extract_type, notes = module.extract_image_metadata(sample)

        self.assertIn("width=40", text)
        self.assertIn("height=20", text)
        self.assertEqual(extract_type, "image-metadata")
        self.assertIn("ocr-", notes)

    def test_extract_svg_metadata_reads_markup_clues(self):
        module = load_module()

        with tempfile.TemporaryDirectory() as tmp_dir:
            sample = Path(tmp_dir) / "ikon.svg"
            sample.write_text(
                '<svg width="16" height="16"><title>Camera Icon</title><path id="cam" d="M0 0" /></svg>',
                encoding="utf-8",
            )

            text, extract_type, notes = module.extract_image_metadata(sample)

        self.assertIn("width=16", text)
        self.assertIn("Camera Icon", text)
        self.assertEqual(extract_type, "image-metadata")
        self.assertIn("svg-text", notes)

    def test_try_image_ocr_skips_svg(self):
        module = load_module()

        with tempfile.TemporaryDirectory() as tmp_dir:
            sample = Path(tmp_dir) / "ikon.svg"
            sample.write_text('<svg width="16" height="16"><title>Icon</title></svg>', encoding="utf-8")

            result = module.try_image_ocr(sample)

        self.assertIsNone(result)

    def test_extract_binary_metadata_finds_strings_and_pe_markers(self):
        module = load_module()

        with tempfile.TemporaryDirectory() as tmp_dir:
            sample = Path(tmp_dir) / "modul.dll"
            sample.write_bytes(b"MZ\x00\x00kernel32.dll\x00CreateFileA\x00ValutaModule\x00")

            text, extract_type, notes = module.extract_binary_metadata(sample)

        self.assertIn("kernel32.dll", text)
        self.assertIn("CreateFileA", text)
        self.assertEqual(extract_type, "binary-metadata")
        self.assertIn("mz=True", notes)

    def test_extract_binary_metadata_classifies_imports_symbols_and_dat_clues(self):
        module = load_module()

        with tempfile.TemporaryDirectory() as tmp_dir:
            sample = Path(tmp_dir) / "import.dll"
            sample.write_bytes(
                b"MZ\x00\x00kernel32.dll\x00advapi32.dll\x00CreateFileA\x00RegOpenKeyExA\x00"
                b"AMLCHECK\x00SENDDATA\x00OLDDATA.DAT\x00FOGLALO.DAT\x00"
            )

            text, extract_type, notes = module.extract_binary_metadata(sample)

        self.assertEqual(extract_type, "binary-metadata")
        self.assertIn("import_clues=kernel32.dll, advapi32.dll", text)
        self.assertIn("symbol_clues=CreateFileA, RegOpenKeyExA", text)
        self.assertIn("domain_clues=AMLCHECK, SENDDATA", text)
        self.assertIn("dat_clues=OLDDATA.DAT, FOGLALO.DAT", text)

    def test_extract_firebird_metadata_reports_header_and_strings(self):
        module = load_module()

        with tempfile.TemporaryDirectory() as tmp_dir:
            sample = Path(tmp_dir) / "adatbazis.fdb"
            sample.write_bytes(b"\x00\x01FIREBIRD\x00UGYFEL\x00TRANSAKCIOTABLA\x00")

            text, extract_type, notes = module.extract_firebird_metadata(sample)

        self.assertIn("UGYFEL", text)
        self.assertIn("TRANSAKCIOTABLA", text)
        self.assertEqual(extract_type, "firebird-metadata")
        self.assertIn("header_hex=", notes)

    def test_extract_firebird_metadata_surfaces_schema_clues(self):
        module = load_module()

        with tempfile.TemporaryDirectory() as tmp_dir:
            sample = Path(tmp_dir) / "schema.fdb"
            sample.write_bytes(
                b"\x00\x01RDB$RELATIONS\x00RDB$FIELDS\x00UGYFEL\x00TRANSACTIONS\x00"
                b"GEN_BIZONYLAT\x00TRG_BI_UJDATA\x00SP_IMPORT_UGYFEL\x00VW_AML_STATUS\x00"
            )

            text, extract_type, notes = module.extract_firebird_metadata(sample)

        self.assertEqual(extract_type, "firebird-metadata")
        self.assertIn("system_clues=RDB$RELATIONS, RDB$FIELDS", text)
        self.assertIn("table_clues=UGYFEL, TRANSACTIONS", text)
        self.assertIn("generator_clues=GEN_BIZONYLAT", text)
        self.assertIn("trigger_clues=TRG_BI_UJDATA", text)
        self.assertIn("procedure_clues=SP_IMPORT_UGYFEL", text)
        self.assertIn("view_clues=VW_AML_STATUS", text)

    def test_extract_dat_metadata_surfaces_records_and_import_clues(self):
        module = load_module()

        with tempfile.TemporaryDirectory() as tmp_dir:
            sample = Path(tmp_dir) / "OLDDATA.DAT"
            sample.write_bytes(
                b"OLDDATA.DAT\x00SENDDATA\x00RECEPTOR\x00SORSZAM\x00UGYFEL\x00"
                b"12345;EUR;HUF\r\n23456;USD;HUF\r\n"
            )

            text, extract_type, notes = module.extract_dat_metadata(sample)

        self.assertEqual(extract_type, "dat-metadata")
        self.assertIn("dat_markers=OLDDATA.DAT", text)
        self.assertIn("import_clues=SENDDATA, RECEPTOR, SORSZAM", text)
        self.assertIn("record_shape_clues=", text)
        self.assertIn("header_hex=", notes)

    def test_extract_import_config_clues_from_text_summarizes_matching_lines(self):
        module = load_module()

        text, extract_type, notes = module.extract_import_config_clues_from_text(
            "senddata.ini",
            "\n".join(
                [
                    "server=127.0.0.1",
                    "senddata=true",
                    "target=RECEPTOR",
                    "source=OLDDATA.DAT",
                    "counter=SORSZAM",
                ]
            ),
        )

        self.assertEqual(extract_type, "import-config-clues")
        self.assertIn("keyword_hits=SENDDATA, RECEPTOR, OLDDATA, SORSZAM", text)
        self.assertIn("dat_references=OLDDATA.DAT", text)
        self.assertIn("matching_lines=", text)
        self.assertIn("keyword_count=4", notes)

    def test_upsert_extract_and_partial_run(self):
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

            module.upsert_extract(
                cur=cur,
                artifact_id="artifact-ocr",
                extract_type="image-metadata",
                text_content="filename=a.png",
                quality_score=0.3,
                quality_notes="ocr-unavailable",
                timestamp="2026-04-09T12:00:00+00:00",
            )
            module.record_ingest_run(
                cur=cur,
                artifact_id="artifact-ocr",
                ingest_status="partial",
                timestamp="2026-04-09T12:00:00+00:00",
                error_summary="ocr-unavailable",
            )
            conn.commit()

            extract = cur.execute(
                "SELECT artifact_id, extract_type, text_content, quality_notes FROM artifact_text_extracts"
            ).fetchone()
            run = cur.execute(
                "SELECT artifact_id, ingest_status, tooling, error_summary FROM artifact_ingest_runs"
            ).fetchone()
            conn.close()

        self.assertEqual(extract, ("artifact-ocr", "image-metadata", "filename=a.png", "ocr-unavailable"))
        self.assertEqual(run, ("artifact-ocr", "partial", "anti-media-metadata-pass", "ocr-unavailable"))

    def test_rebuild_gaps_creates_deeper_gap_types(self):
        module = load_module()

        with tempfile.TemporaryDirectory() as tmp_dir:
            db_path = Path(tmp_dir) / "test.sqlite"
            conn = sqlite3.connect(db_path)
            try:
                cur = conn.cursor()
                cur.executescript(
                    """
                    CREATE TABLE source_artifacts (
                        artifact_id TEXT PRIMARY KEY,
                        source_root TEXT NOT NULL,
                        absolute_path TEXT NOT NULL,
                        artifact_kind TEXT NOT NULL,
                        format_family TEXT NOT NULL,
                        extension TEXT,
                        visibility_status TEXT NOT NULL
                    );
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
                    CREATE TABLE knowledge_gaps (
                        gap_id TEXT PRIMARY KEY,
                        topic_id TEXT,
                        gap_type TEXT NOT NULL,
                        artifact_id TEXT,
                        severity TEXT,
                        description TEXT NOT NULL,
                        resolution_status TEXT NOT NULL,
                        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
                    );
                    """
                )
                cur.executemany(
                    "INSERT INTO source_artifacts(artifact_id, source_root, absolute_path, artifact_kind, format_family, extension, visibility_status) VALUES (?, ?, ?, ?, ?, ?, ?)",
                    [
                        ("bin1", "Anti", "a.exe", "file", "binary-pe", ".exe", "binary-only"),
                        ("fdb1", "Anti", "a.fdb", "file", "firebird-db", ".fdb", "binary-only"),
                        ("img1", "Anti", "a.png", "file", "image", ".png", "binary-only"),
                        ("aud1", "Anti", "a.mp3", "file", "audio", ".mp3", "binary-only"),
                        ("arc1", "Anti", "a.zip", "archive", "archive", ".zip", "binary-only"),
                    ],
                )
                cur.executemany(
                    "INSERT INTO artifact_text_extracts(extract_id, artifact_id, extract_type, language, text_content, char_count, quality_score, quality_notes) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                    [
                        ("e1", "bin1", "binary-metadata", "mixed", "x", 1, 0.4, ""),
                        ("e2", "fdb1", "firebird-metadata", "mixed", "x", 1, 0.4, ""),
                        ("e3", "img1", "image-metadata", "mixed", "x", 1, 0.2, "ocr-unavailable"),
                    ],
                )

                created = module.rebuild_gaps(cur, tesseract_is_available=False)
                rows = cur.execute(
                    "SELECT artifact_id, gap_type FROM knowledge_gaps ORDER BY artifact_id, gap_type"
                ).fetchall()
            finally:
                conn.close()

        self.assertGreaterEqual(created, 5)
        self.assertIn(("bin1", "metadata-only-binary"), rows)
        self.assertIn(("fdb1", "schema-clue-only"), rows)
        self.assertIn(("img1", "ocr-tooling-missing"), rows)
        self.assertIn(("aud1", "asr-needed"), rows)
        self.assertIn(("arc1", "not-ingested"), rows)

    def test_open_db_connection_sets_busy_timeout(self):
        module = load_module()

        with tempfile.TemporaryDirectory() as tmp_dir:
            db_path = Path(tmp_dir) / "busy.sqlite"
            conn = module.open_db_connection(db_path)
            try:
                busy_timeout = conn.execute("PRAGMA busy_timeout").fetchone()[0]
            finally:
                conn.close()

        self.assertGreaterEqual(busy_timeout, 30000)


if __name__ == "__main__":
    unittest.main()
