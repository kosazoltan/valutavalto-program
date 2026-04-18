"""
Extract searchable text for Anti text-heavy artifacts.

This script fills the artifact_text_extracts layer from already inventoried
Anti artifacts that are directly readable or office-xml containers.

Usage:
  python docs/valuta-kb-extract-text.py
"""
from __future__ import annotations

import hashlib
import sqlite3
import unicodedata
import zipfile
from datetime import datetime, timezone
from pathlib import Path
from xml.etree import ElementTree as ET


DB_PATH = Path(__file__).with_name("valuta-knowledge.sqlite")
TEXT_EXTENSIONS = {
    ".pas",
    ".dpr",
    ".dpk",
    ".dfm",
    ".dproj",
    ".inc",
    ".java",
    ".txt",
    ".log",
    ".ini",
    ".cfg",
    ".json",
    ".xml",
    ".yaml",
    ".yml",
    ".html",
    ".htm",
    ".md",
    ".csv",
    ".rtf",
}
OFFICE_XML_EXTENSIONS = {
    ".docx",
    ".docm",
    ".odt",
    ".xlsx",
    ".ods",
}


def now_utc() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def normalize_text(value: str | None) -> str:
    if not value:
        return ""
    normalized = unicodedata.normalize("NFKD", value)
    normalized = normalized.replace("\\", "/").strip()
    while "//" in normalized:
        normalized = normalized.replace("//", "/")
    return normalized


def is_text_extractable(format_family: str, extension: str) -> bool:
    extension = (extension or "").lower()
    if extension in TEXT_EXTENSIONS or extension in OFFICE_XML_EXTENSIONS:
        return True
    return format_family in {
        "pascal",
        "delphi-project",
        "text",
        "structured-text",
        "html",
        "markdown",
        "csv",
    }


def extract_plain_text(path: Path) -> tuple[str, str]:
    encodings = ["utf-8", "utf-8-sig", "cp1250", "latin-1"]
    last_error = None
    for encoding in encodings:
        try:
            return path.read_text(encoding=encoding), f"plain-text:{encoding}"
        except UnicodeDecodeError as exc:
            last_error = exc
    if last_error:
        raise last_error
    return path.read_text(errors="replace"), "plain-text:replace"


def extract_xml_text(blob: bytes) -> str:
    root = ET.fromstring(blob)
    parts: list[str] = []
    for elem in root.iter():
        text = (elem.text or "").strip()
        if text:
            parts.append(text)
    return "\n".join(parts)


def extract_docx_text(path: Path) -> tuple[str, str]:
    with zipfile.ZipFile(path) as zf:
        text = extract_xml_text(zf.read("word/document.xml"))
    return text, "office-xml:word/document.xml"


def extract_odt_like_text(path: Path) -> tuple[str, str]:
    with zipfile.ZipFile(path) as zf:
        text = extract_xml_text(zf.read("content.xml"))
    return text, "office-xml:content.xml"


def extract_xlsx_text(path: Path) -> tuple[str, str]:
    texts: list[str] = []
    members: list[str] = []
    with zipfile.ZipFile(path) as zf:
        for name in zf.namelist():
            lowered = name.lower()
            if lowered == "xl/sharedstrings.xml" or lowered.startswith("xl/worksheets/sheet"):
                members.append(name)
                texts.append(extract_xml_text(zf.read(name)))
    return "\n".join(part for part in texts if part).strip(), "office-xml:" + ",".join(members[:5])


def extract_text_from_path(path: Path, format_family: str) -> tuple[str, str, str]:
    extension = path.suffix.lower()
    if extension in TEXT_EXTENSIONS or format_family in {
        "pascal",
        "delphi-project",
        "text",
        "structured-text",
        "html",
        "markdown",
        "csv",
    }:
        text, note = extract_plain_text(path)
        return text, "fulltext", note
    if extension in {".docx", ".docm"}:
        try:
            text, note = extract_docx_text(path)
            return text, "office-xml", note
        except (zipfile.BadZipFile, KeyError, ET.ParseError):
            text, note = extract_plain_text(path)
            return text, "fulltext", f"{note};fallback-from:{extension}"
    if extension in {".odt", ".ods"}:
        try:
            text, note = extract_odt_like_text(path)
            return text, "office-xml", note
        except (zipfile.BadZipFile, KeyError, ET.ParseError):
            text, note = extract_plain_text(path)
            return text, "fulltext", f"{note};fallback-from:{extension}"
    if extension == ".xlsx":
        try:
            text, note = extract_xlsx_text(path)
            return text, "office-xml", note
        except (zipfile.BadZipFile, KeyError, ET.ParseError):
            text, note = extract_plain_text(path)
            return text, "fulltext", f"{note};fallback-from:{extension}"
    raise ValueError(f"Unsupported text extraction target: {path}")


def upsert_text_extract(
    cur: sqlite3.Cursor,
    artifact_id: str,
    extract_type: str,
    text_content: str,
    quality_score: float,
    quality_notes: str,
    timestamp: str,
) -> None:
    extract_id = hashlib.sha1(f"{artifact_id}:{extract_type}".encode("utf-8")).hexdigest()
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
            extract_type,
            "mixed",
            text_content,
            len(text_content),
            quality_score,
            quality_notes,
            timestamp,
        ),
    )

    run_id = hashlib.sha1(f"{artifact_id}:indexed".encode("utf-8")).hexdigest()
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
            "indexed",
            "completed",
            "anti-text-extract",
            None,
            None,
            timestamp,
            timestamp,
        ),
    )


def record_ingest_run(
    cur: sqlite3.Cursor,
    artifact_id: str,
    ingest_status: str,
    timestamp: str,
    error_summary: str | None = None,
) -> None:
    status_key = ingest_status if not error_summary else f"{ingest_status}:{error_summary}"
    run_id = hashlib.sha1(f"{artifact_id}:{status_key}".encode("utf-8")).hexdigest()
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
            "indexed",
            ingest_status,
            "anti-text-extract",
            None,
            error_summary,
            timestamp,
            timestamp,
        ),
    )


def rebuild_coverage(cur: sqlite3.Cursor) -> int:
    cur.execute("DELETE FROM knowledge_coverage")
    timestamp = now_utc()
    roots = [row[0] for row in cur.execute("SELECT DISTINCT source_root FROM source_artifacts")]
    topics = [row[0] for row in cur.execute("SELECT topic_id FROM topics")]
    inserted = 0
    for source_root in roots:
        for topic_id in topics:
            seen = cur.execute(
                """
                SELECT COUNT(DISTINCT sa.artifact_id)
                FROM source_artifacts sa
                JOIN artifact_topics at ON at.artifact_id = sa.artifact_id
                WHERE sa.source_root=? AND at.topic_id=?
                """,
                (source_root, topic_id),
            ).fetchone()[0]
            if not seen:
                continue
            indexed = cur.execute(
                """
                SELECT COUNT(DISTINCT sa.artifact_id)
                FROM source_artifacts sa
                JOIN artifact_topics at ON at.artifact_id = sa.artifact_id
                JOIN artifact_text_extracts te ON te.artifact_id = sa.artifact_id
                WHERE sa.source_root=? AND at.topic_id=?
                """,
                (source_root, topic_id),
            ).fetchone()[0]
            ingested = cur.execute(
                """
                SELECT COUNT(DISTINCT sa.artifact_id)
                FROM source_artifacts sa
                JOIN artifact_topics at ON at.artifact_id = sa.artifact_id
                JOIN artifact_ingest_runs ir ON ir.artifact_id = sa.artifact_id
                WHERE sa.source_root=? AND at.topic_id=? AND ir.ingest_status IN
                    ('completed','partial','ocr-required','asr-required','archive-expand-required','blocked')
                """,
                (source_root, topic_id),
            ).fetchone()[0]
            blocked = cur.execute(
                """
                SELECT COUNT(DISTINCT sa.artifact_id)
                FROM source_artifacts sa
                JOIN artifact_topics at ON at.artifact_id = sa.artifact_id
                WHERE sa.source_root=? AND at.topic_id=? AND sa.visibility_status IN ('binary-only','missing','unverified')
                """,
                (source_root, topic_id),
            ).fetchone()[0]
            coverage_percent = round((indexed / seen) * 100, 2) if seen else 0.0
            coverage_id = hashlib.sha1(f"{source_root}:{topic_id}".encode("utf-8")).hexdigest()
            cur.execute(
                """
                INSERT INTO knowledge_coverage(
                    coverage_id, source_root, topic_id, artifact_count_seen,
                    artifact_count_ingested, artifact_count_indexed,
                    artifact_count_blocked, coverage_percent, last_computed_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    coverage_id,
                    source_root,
                    topic_id,
                    seen,
                    ingested,
                    indexed,
                    blocked,
                    coverage_percent,
                    timestamp,
                ),
            )
            inserted += 1
    return inserted


def record_checkpoint(cur: sqlite3.Cursor, metrics: dict[str, int]) -> None:
    checkpoint_id = hashlib.sha1(f"anti-text-extract:{now_utc()}".encode("utf-8")).hexdigest()
    metrics_json = "{" + ", ".join(f'"{k}": {v}' for k, v in metrics.items()) + "}"
    cur.execute(
        """
        INSERT INTO ingest_checkpoints(checkpoint_id, checkpoint_name, source_root, metrics_json, created_at)
        VALUES (?, ?, ?, ?, ?)
        """,
        (checkpoint_id, "anti-text-extract", "Anti", metrics_json, now_utc()),
    )


def iter_candidates(cur: sqlite3.Cursor) -> list[tuple[str, str, str, str]]:
    return cur.execute(
        """
        SELECT sa.artifact_id, sa.absolute_path, sa.format_family, sa.extension
        FROM source_artifacts sa
        LEFT JOIN artifact_text_extracts te ON te.artifact_id = sa.artifact_id
        WHERE sa.source_root='Anti'
          AND sa.artifact_kind != 'directory'
          AND te.extract_id IS NULL
        ORDER BY sa.absolute_path
        """
    ).fetchall()


def main() -> None:
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    timestamp = now_utc()

    extracted = 0
    skipped = 0
    failed = 0
    empty = 0

    for artifact_id, absolute_path, format_family, extension in iter_candidates(cur):
        if not is_text_extractable(format_family, extension or ""):
            skipped += 1
            continue

        path = Path(absolute_path)
        if not path.exists() or not path.is_file():
            failed += 1
            continue

        try:
            text, extract_type, quality_notes = extract_text_from_path(path, format_family)
            cleaned = text.strip()
            if not cleaned:
                record_ingest_run(cur, artifact_id, "partial", timestamp, "empty-text")
                empty += 1
                continue
            quality_score = 0.95 if "plain-text:utf-8" in quality_notes else 0.9
            if extract_type == "office-xml":
                quality_score = 0.85
            upsert_text_extract(
                cur=cur,
                artifact_id=artifact_id,
                extract_type=extract_type,
                text_content=cleaned,
                quality_score=quality_score,
                quality_notes=quality_notes,
                timestamp=timestamp,
            )
            extracted += 1
        except Exception as exc:
            record_ingest_run(cur, artifact_id, "failed", timestamp, type(exc).__name__)
            failed += 1

    coverage_rows = rebuild_coverage(cur)
    metrics = {
        "extracted": extracted,
        "skipped": skipped,
        "failed": failed,
        "empty": empty,
        "coverage_rows": coverage_rows,
    }
    record_checkpoint(cur, metrics)

    conn.commit()
    conn.close()

    print("Anti text extraction complete.")
    for key, value in metrics.items():
        print(f"  {key}={value}")


if __name__ == "__main__":
    main()
