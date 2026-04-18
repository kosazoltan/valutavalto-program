import importlib.util
import math
import sqlite3
import tempfile
import unittest
import wave
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("valuta-kb-extract-asr.py")


def load_module():
    spec = importlib.util.spec_from_file_location("valuta_kb_extract_asr", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


class FakeSegment:
    def __init__(self, text: str):
        self.text = text


class ValutaKbExtractAsrTests(unittest.TestCase):
    def test_decode_audio_with_av_reads_wav_samples(self):
        module = load_module()

        with tempfile.TemporaryDirectory() as tmp_dir:
            wav_path = Path(tmp_dir) / "sample.wav"
            with wave.open(str(wav_path), "wb") as wav_file:
                wav_file.setnchannels(1)
                wav_file.setsampwidth(2)
                wav_file.setframerate(16000)
                frames = bytearray()
                for i in range(1600):
                    sample = int(12000 * math.sin(2 * math.pi * 440 * (i / 16000)))
                    frames += int(sample).to_bytes(2, byteorder="little", signed=True)
                wav_file.writeframes(bytes(frames))

            audio, sample_rate = module.decode_audio_with_av(wav_path)

        self.assertEqual(sample_rate, 16000)
        self.assertEqual(type(audio).__name__, "ndarray")
        self.assertGreater(len(audio), 1000)
        self.assertLess(len(audio), 5000)

    def test_import_whisper_with_patch_returns_module(self):
        module = load_module()

        whisper_module = module.import_whisper_with_patch()

        self.assertTrue(hasattr(whisper_module, "load_model"))

    def test_materialize_transcript_joins_nonempty_segments(self):
        module = load_module()

        transcript, count = module.materialize_transcript(
            [FakeSegment("elso sor"), FakeSegment(""), FakeSegment("masodik sor")]
        )

        self.assertEqual(transcript, "elso sor\nmasodik sor")
        self.assertEqual(count, 2)

    def test_iter_asr_candidates_only_returns_missing_transcripts(self):
        module = load_module()

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
                    sha256 TEXT,
                    size_bytes INTEGER
                );
                CREATE TABLE artifact_text_extracts (
                    extract_id TEXT PRIMARY KEY,
                    artifact_id TEXT NOT NULL,
                    extract_type TEXT NOT NULL
                );
                """
            )
            cur.executemany(
                "INSERT INTO source_artifacts(artifact_id, source_root, absolute_path, artifact_kind, format_family, sha256, size_bytes) VALUES (?, ?, ?, ?, ?, ?, ?)",
                [
                    ("a1", "Felmeres", "a1.mp3", "file", "audio", None, 100),
                    ("a2", "Felmeres", "a2.mp4", "file", "video", None, 200),
                    ("a3", "Felmeres", "a3.txt", "file", "text", None, 300),
                ],
            )
            cur.execute(
                "INSERT INTO artifact_text_extracts(extract_id, artifact_id, extract_type) VALUES (?, ?, ?)",
                ("e1", "a2", "asr-transcript"),
            )

            rows = module.iter_asr_candidates(cur)
            conn.close()

        self.assertEqual(rows, [("a1", "Felmeres", "a1.mp3", "audio", None, 100)])

    def test_group_asr_candidates_collapses_duplicates(self):
        module = load_module()

        grouped = module.group_asr_candidates(
            [
                ("a1", "Felmeres", "c:/audio/Hang 002_sd.m4a", "audio", None, 1234),
                ("a2", "Felmeres", "c:/dup/Hang 002_sd.m4a", "audio", None, 1234),
                ("a3", "Felmeres", "c:/audio/Hang 003_sd.m4a", "audio", "hash-3", 2222),
                ("a4", "Felmeres", "c:/dup/Hang 003_sd.m4a", "audio", "hash-3", 2222),
            ]
        )

        self.assertEqual(len(grouped), 2)
        self.assertEqual(grouped[0][0], "c:/audio/Hang 002_sd.m4a")
        self.assertEqual(grouped[0][1], ["a1", "a2"])
        self.assertEqual(grouped[1][0], "c:/audio/Hang 003_sd.m4a")
        self.assertEqual(grouped[1][1], ["a3", "a4"])

    def test_upsert_asr_extract_and_run(self):
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

            module.upsert_asr_extract(cur, "audio-1", "minta transcript", "hu", "model=tiny", "2026-04-09T12:00:00+00:00")
            module.record_asr_run(cur, "audio-1", "completed", "2026-04-09T12:00:00+00:00")
            conn.commit()

            extract = cur.execute(
                "SELECT artifact_id, extract_type, language, text_content, quality_notes FROM artifact_text_extracts"
            ).fetchone()
            run = cur.execute(
                "SELECT artifact_id, ingest_status, tooling FROM artifact_ingest_runs"
            ).fetchone()
            conn.close()

        self.assertEqual(extract, ("audio-1", "asr-transcript", "hu", "minta transcript", "model=tiny"))
        self.assertEqual(run, ("audio-1", "completed", "faster-whisper-asr"))


if __name__ == "__main__":
    unittest.main()
