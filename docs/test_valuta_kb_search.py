import contextlib
import importlib.util
import io
import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("valuta-kb-search.py")


def load_module():
    original_stdout = sys.stdout
    try:
        spec = importlib.util.spec_from_file_location("valuta_kb_search", MODULE_PATH)
        module = importlib.util.module_from_spec(spec)
        assert spec.loader is not None
        spec.loader.exec_module(module)
    finally:
        sys.stdout = original_stdout
    return module


class ValutaKbSearchTests(unittest.TestCase):
    def setUp(self):
        self.module = load_module()
        self.tmp_dir = tempfile.TemporaryDirectory()
        self.db_path = Path(self.tmp_dir.name) / "kb.sqlite"
        self.module.DB_PATH = str(self.db_path)

    def tearDown(self):
        self.tmp_dir.cleanup()

    def connect(self):
        return contextlib.closing(sqlite3.connect(self.db_path))

    def capture_output(self, func, *args):
        buffer = io.StringIO()
        with contextlib.redirect_stdout(buffer):
            func(*args)
        return buffer.getvalue()

    def test_schema_lists_existing_tables_and_columns(self):
        with self.connect() as conn:
            conn.executescript(
                """
                CREATE TABLE source_artifacts (
                    artifact_id TEXT PRIMARY KEY,
                    source_root TEXT NOT NULL,
                    format_family TEXT NOT NULL,
                    visibility_status TEXT NOT NULL
                );
                CREATE TABLE knowledge_gaps (
                    gap_id TEXT PRIMARY KEY,
                    severity TEXT NOT NULL,
                    gap_type TEXT NOT NULL,
                    resolution_status TEXT NOT NULL,
                    description TEXT NOT NULL,
                    created_at TEXT NOT NULL
                );
                """
            )

        output = self.capture_output(self.module.schema)

        self.assertIn("Tabla schema osszesito:", output)
        self.assertIn("source_artifacts: artifact_id, source_root, format_family, visibility_status", output)
        self.assertIn("knowledge_gaps: gap_id, severity, gap_type, resolution_status, description, created_at", output)

    def test_sources_summarizes_artifact_counts_by_root_family_and_visibility(self):
        with self.connect() as conn:
            conn.executescript(
                """
                CREATE TABLE source_artifacts (
                    artifact_id TEXT PRIMARY KEY,
                    source_root TEXT NOT NULL,
                    format_family TEXT NOT NULL,
                    visibility_status TEXT NOT NULL
                );
                """
            )
            conn.executemany(
                "INSERT INTO source_artifacts(artifact_id, source_root, format_family, visibility_status) VALUES (?, ?, ?, ?)",
                [
                    ("a1", "RepoDocs", "text", "indexed"),
                    ("a2", "RepoDocs", "text", "indexed"),
                    ("a3", "Anti", "audio", "pending"),
                ],
            )
            conn.commit()

        output = self.capture_output(self.module.sources, 10)

        self.assertIn("Forras artifact statisztika:", output)
        self.assertIn("RepoDocs | text | indexed: 2", output)
        self.assertIn("Anti | audio | pending: 1", output)

    def test_gaps_lists_gap_rows_with_severity_and_status(self):
        with self.connect() as conn:
            conn.executescript(
                """
                CREATE TABLE knowledge_gaps (
                    gap_id TEXT PRIMARY KEY,
                    topic_id TEXT,
                    gap_type TEXT NOT NULL,
                    artifact_id TEXT,
                    severity TEXT NOT NULL,
                    description TEXT NOT NULL,
                    resolution_status TEXT NOT NULL,
                    created_at TEXT NOT NULL,
                    updated_at TEXT
                );
                """
            )
            conn.execute(
                """
                INSERT INTO knowledge_gaps(
                    gap_id, topic_id, gap_type, artifact_id, severity, description,
                    resolution_status, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    "gap-1",
                    "camera-core",
                    "missing-evidence",
                    "artifact-1",
                    "high",
                    "Nincs eleg bizonyitek a kamera export verify lancrol.",
                    "open",
                    "2026-04-11T12:00:00+00:00",
                    "2026-04-11T12:00:00+00:00",
                ),
            )
            conn.commit()

        output = self.capture_output(self.module.gaps, 10)

        self.assertIn("Nyitott / rogzitett gap-ek:", output)
        self.assertIn("[high] missing-evidence / open - Nincs eleg bizonyitek", output)

    def test_coverage_lists_lowest_coverage_topics_first(self):
        with self.connect() as conn:
            conn.executescript(
                """
                CREATE TABLE knowledge_coverage (
                    coverage_id TEXT PRIMARY KEY,
                    source_root TEXT NOT NULL,
                    topic_id TEXT NOT NULL,
                    artifact_count_seen INTEGER NOT NULL,
                    artifact_count_ingested INTEGER,
                    artifact_count_indexed INTEGER NOT NULL,
                    artifact_count_blocked INTEGER,
                    coverage_percent REAL NOT NULL,
                    last_computed_at TEXT
                );
                """
            )
            conn.executemany(
                """
                INSERT INTO knowledge_coverage(
                    coverage_id, source_root, topic_id, artifact_count_seen,
                    artifact_count_ingested, artifact_count_indexed,
                    artifact_count_blocked, coverage_percent, last_computed_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                [
                    ("c1", "Anti", "camera-core", 100, 70, 40, 5, 40.0, "2026-04-11T12:00:00+00:00"),
                    ("c2", "Felmeres", "survey-requirements", 50, 49, 49, 0, 98.0, "2026-04-11T12:00:00+00:00"),
                ],
            )
            conn.commit()

        output = self.capture_output(self.module.coverage, 10)
        lines = [line for line in output.splitlines() if line.startswith("  ")]

        self.assertIn("Coverage osszesito:", output)
        self.assertGreaterEqual(len(lines), 2)
        self.assertEqual(lines[0].strip(), "Anti | camera-core: seen=100, indexed=40, coverage=40.0%")
        self.assertEqual(lines[1].strip(), "Felmeres | survey-requirements: seen=50, indexed=49, coverage=98.0%")


if __name__ == "__main__":
    unittest.main()
