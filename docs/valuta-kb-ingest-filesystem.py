"""
Filesystem inventory + ingest-ledger loader for the knowledge base.

This script scans the ignored-but-present legacy trees and populates:
- source_artifacts
- artifact_ingest_runs
- artifact_dedup_groups
- artifact_dedup_members
- knowledge_coverage
- knowledge_gaps
- ingest_checkpoints

It does NOT attempt full OCR/ASR/content extraction. It establishes the
auditable inventory and baseline ingest ledger required before deeper ingestion.

Usage:
  python docs/valuta-kb-ingest-filesystem.py
"""
from __future__ import annotations

import hashlib
import os
import sqlite3
import unicodedata
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path


DB_PATH = Path(__file__).with_name("valuta-knowledge.sqlite")
ROOTS = [
    ("Anti", Path(r"D:/repo/valutavalto-program/Anti")),
    ("Felmeres", Path(r"D:/repo/valutavalto-program/Felmérés")),
]


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


def artifact_id_for(path: str) -> str:
    return hashlib.sha1(normalize_text(path).encode("utf-8")).hexdigest()


def normalize_relpath(rel_path: str) -> str:
    canonical = normalize_text(rel_path)
    tokens = [
        "/_extracted_auto/",
        "/_extracted/",
        "/forrasok_unpacked/",
        "/old_unpacked/",
        "/camera_unpacked/",
        "/arfolyam_unpacked/",
        "/keszlex_unpacked/",
        "/orecptor_unpacked/",
        "/camera-20260306t145042z-1-001_unpacked/",
    ]
    lowered = canonical.lower()
    for token in tokens:
        lowered = lowered.replace(token, "/")
    while "//" in lowered:
        lowered = lowered.replace("//", "/")
    return lowered


def infer_format_family(path: Path) -> str:
    suffix = path.suffix.lower()
    if path.is_dir():
        return "directory"
    if suffix == ".pas":
        return "pascal"
    if suffix in {".dpr", ".dpk", ".dfm", ".dproj", ".inc"}:
        return "delphi-project"
    if suffix in {".java", ".jar"}:
        return "java"
    if suffix in {".exe", ".dll"}:
        return "binary-pe"
    if suffix in {".fdb", ".gdb", ".db", ".sqlite"}:
        return "firebird-db"
    if suffix in {".zip", ".7z", ".rar", ".cab", ".arj", ".tar", ".gz"}:
        return "archive"
    if suffix in {".html", ".htm"}:
        return "html"
    if suffix == ".md":
        return "markdown"
    if suffix == ".csv":
        return "csv"
    if suffix in {".xls", ".xlsx", ".ods"}:
        return "spreadsheet"
    if suffix in {".doc", ".docx", ".docm", ".rtf", ".odt"}:
        return "word"
    if suffix == ".pdf":
        return "pdf"
    if suffix in {".png", ".jpg", ".jpeg", ".gif", ".bmp", ".webp", ".tif", ".tiff", ".svg", ".emf", ".wmf"}:
        return "image"
    if suffix in {".mp3", ".wav", ".m4a", ".flac", ".ogg", ".aac", ".wma"}:
        return "audio"
    if suffix in {".mp4", ".mov", ".avi", ".mkv", ".webm", ".wmv", ".mpeg", ".mpg", ".m4v", ".3gp"}:
        return "video"
    if suffix in {".txt", ".log", ".ini", ".cfg"}:
        return "text"
    if suffix in {".json", ".xml", ".yaml", ".yml"}:
        return "structured-text"
    return "other"


def infer_artifact_kind(path: Path) -> str:
    if path.is_dir():
        return "directory"
    family = infer_format_family(path)
    if family == "archive":
        return "archive"
    if "_extracted" in normalize_text(str(path)).lower() or "_unpacked" in normalize_text(str(path)).lower():
        return "extracted-file"
    return "file"


def visibility_for(path: Path, family: str) -> str:
    if path.is_dir():
        return "exists-but-index-hidden"
    if family in {"image", "audio", "video", "binary-pe", "firebird-db", "archive"}:
        return "binary-only"
    return "exists-but-index-hidden"


def ingest_priority(source_root: str, family: str, path: Path) -> str:
    lowered = normalize_text(str(path)).lower()
    if source_root == "Anti" and family in {"pascal", "delphi-project", "binary-pe", "firebird-db", "archive"}:
        return "P0"
    if source_root == "Felmeres" and family in {"word", "html", "markdown", "csv", "pdf", "image", "audio"}:
        return "P0"
    if "aml" in lowered or "bigctrl" in lowered or "terror" in lowered:
        return "P0"
    if family in {"text", "spreadsheet", "structured-text"}:
        return "P1"
    return "P2"


def calc_sha256_if_reasonable(path: Path, size_bytes: int | None, family: str) -> str | None:
    if path.is_dir():
        return None
    if size_bytes is None:
        return None
    if size_bytes > 64 * 1024 * 1024:
        return None
    if family in {"audio", "video"} and size_bytes > 16 * 1024 * 1024:
        return None
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def ensure_schema_columns(cur: sqlite3.Cursor) -> None:
    existing = {row[0] for row in cur.execute("SELECT name FROM sqlite_master WHERE type='table'")}
    required = {"source_artifacts", "artifact_ingest_runs", "artifact_dedup_groups", "artifact_dedup_members", "knowledge_coverage", "knowledge_gaps", "topics"}
    missing = required - existing
    if missing:
        raise RuntimeError(f"Missing required schema tables: {sorted(missing)}. Run docs/valuta-kb-migrate.py first.")


def upsert_artifact(cur: sqlite3.Cursor, source_root: str, root: Path, path: Path, timestamp: str) -> str:
    artifact_id = artifact_id_for(str(path))
    rel_path = path.relative_to(root)
    canonical_path = f"{source_root}/{normalize_relpath(str(rel_path))}"
    parent_path = normalize_text(str(path.parent))
    family = infer_format_family(path)
    kind = infer_artifact_kind(path)
    stat = path.stat()
    size_bytes = None if path.is_dir() else stat.st_size
    sha256 = calc_sha256_if_reasonable(path, size_bytes, family)
    visibility_status = visibility_for(path, family)
    priority = ingest_priority(source_root, family, path)
    notes = None
    lowered = normalize_text(str(path)).lower()
    if "_extracted_auto/" in lowered or "_unpacked/" in lowered:
        notes = "Derived from extracted or unpacked legacy tree"

    cur.execute(
        """
        INSERT INTO source_artifacts(
            artifact_id, source_root, absolute_path, canonical_path, parent_path,
            artifact_kind, format_family, extension, size_bytes, sha256,
            mtime_utc, discovery_method, visibility_status, ingest_priority,
            notes, created_at, updated_at
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(artifact_id) DO UPDATE SET
            canonical_path=excluded.canonical_path,
            parent_path=excluded.parent_path,
            artifact_kind=excluded.artifact_kind,
            format_family=excluded.format_family,
            extension=excluded.extension,
            size_bytes=excluded.size_bytes,
            sha256=COALESCE(excluded.sha256, source_artifacts.sha256),
            mtime_utc=excluded.mtime_utc,
            visibility_status=excluded.visibility_status,
            ingest_priority=excluded.ingest_priority,
            notes=COALESCE(excluded.notes, source_artifacts.notes),
            updated_at=excluded.updated_at
        """,
        (
            artifact_id,
            source_root,
            str(path),
            canonical_path,
            parent_path,
            kind,
            family,
            path.suffix.lower(),
            size_bytes,
            sha256,
            datetime.fromtimestamp(stat.st_mtime, tz=timezone.utc).replace(microsecond=0).isoformat(),
            "direct-read",
            visibility_status,
            priority,
            notes,
            timestamp,
            timestamp,
        ),
    )

    stage = "discovered" if path.is_dir() else "hashed" if sha256 else "classified"
    status = "completed"
    if family == "image":
        status = "ocr-required"
        stage = "ocr"
    elif family in {"audio", "video"}:
        status = "asr-required"
        stage = "asr"
    elif family == "archive":
        status = "archive-expand-required"
        stage = "parsed"
    elif family in {"binary-pe", "firebird-db"}:
        status = "blocked"
        stage = "read"

    run_id = hashlib.sha1(f"{artifact_id}:{stage}:{status}".encode("utf-8")).hexdigest()
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
            stage,
            status,
            "filesystem-ingest",
            None,
            None,
            timestamp,
            timestamp,
        ),
    )
    return artifact_id


def assign_topics_for_artifact(cur: sqlite3.Cursor, artifact_id: str, path: Path, family: str) -> None:
    lowered = normalize_text(str(path)).lower()
    topics = set()
    if any(x in lowered for x in ["bigctrl", "aml", "ugyfel", "terror"]):
        topics.add("customers-aml-kyc")
    if any(x in lowered for x in ["terror", "blacklist", "sanction"]):
        topics.add("sanctions-blacklist")
    if any(x in lowered for x in ["camera", "inspecter", "player"]):
        topics.add("camera-core")
    if any(x in lowered for x in ["custody", "verify-chain", "export"]):
        topics.add("camera-export-custody")
    if any(x in lowered for x in ["arfolyam", "mnb", "getarf", "rate"]):
        topics.add("rates-rate-publication")
    if any(x in lowered for x in ["fdb", "gdb", "firebird", "database"]):
        topics.add("firebird-schema-and-db-artifacts")
    if any(x in lowered for x in ["booking", "foglalo", "reservation"]):
        topics.add("reservations-booking")
    if any(x in lowered for x in ["bizonylat", "nyugta", "receipt", "p91"]):
        topics.add("receipts-printing")
    if any(x in lowered for x in ["zar", "napzar", "havizar", "closing", "forgalmi"]):
        topics.add("closing-daily-monthly-yearly")
    if any(x in lowered for x in ["cimlet", "keszlet", "stock"]):
        topics.add("denomination-cash-stock")
    if any(x in lowered for x in ["ertektar", "atad", "vault", "treasury"]):
        topics.add("treasury-vault-transfer")
    if any(x in lowered for x in ["recptor", "receptor", "senddata", "import", "server"]):
        topics.add("server-import-receptor")
    if family == "csv" or family == "word" or "felm" in lowered or "interju" in lowered:
        topics.add("survey-requirements")
    if family == "image":
        topics.add("ui-screenshots-and-receipt-images")
    if family in {"audio", "video"}:
        topics.add("audio-video-transcripts")
    if any(x in lowered for x in ["wunion", "western", "mtcn"]):
        topics.add("western-union")
    if any(x in lowered for x in ["dat", "olddata", "ujdata", "sorszam"]):
        topics.add("dat-file-formats")
    if any(x in lowered for x in ["metro", "tesco", "otp", "moneygram", "partner", "nav"]):
        topics.add("partner-integrations")

    for topic_id in topics:
        cur.execute(
            "INSERT OR IGNORE INTO artifact_topics(artifact_id, topic_id, relevance_score) VALUES (?, ?, ?)",
            (artifact_id, topic_id, 1.0),
        )


def rebuild_dedup(cur: sqlite3.Cursor) -> int:
    cur.execute("DELETE FROM artifact_dedup_members")
    cur.execute("DELETE FROM artifact_dedup_groups")
    rows = cur.execute(
        "SELECT artifact_id, canonical_path, sha256 FROM source_artifacts"
    ).fetchall()
    groups = defaultdict(list)
    for artifact_id, canonical_path, sha256 in rows:
        dedup_key = f"sha256:{sha256}" if sha256 else f"canonical:{canonical_path}"
        groups[dedup_key].append(artifact_id)

    timestamp = now_utc()
    for dedup_key, artifact_ids in groups.items():
        dedup_group_id = hashlib.sha1(dedup_key.encode("utf-8")).hexdigest()
        canonical_artifact_id = sorted(artifact_ids)[0]
        reason = "same-hash" if dedup_key.startswith("sha256:") else "same-content-different-path"
        confidence = "high" if dedup_key.startswith("sha256:") else "medium"
        cur.execute(
            """
            INSERT INTO artifact_dedup_groups(
                dedup_group_id, dedup_key, canonical_artifact_id,
                duplicate_count, dedup_reason, confidence, created_at, updated_at
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                dedup_group_id,
                dedup_key,
                canonical_artifact_id,
                len(artifact_ids) - 1,
                reason,
                confidence,
                timestamp,
                timestamp,
            ),
        )
        for artifact_id in artifact_ids:
            cur.execute(
                "INSERT INTO artifact_dedup_members(dedup_group_id, artifact_id, member_role) VALUES (?, ?, ?)",
                (dedup_group_id, artifact_id, "canonical" if artifact_id == canonical_artifact_id else "duplicate"),
            )
    return len(groups)


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
                LEFT JOIN artifact_text_extracts te ON te.artifact_id = sa.artifact_id
                WHERE sa.source_root=? AND at.topic_id=? AND te.extract_id IS NOT NULL
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


def rebuild_gap_baseline(cur: sqlite3.Cursor) -> int:
    cur.execute("DELETE FROM knowledge_gaps WHERE description LIKE 'Filesystem baseline:%'")
    rows = cur.execute(
        "SELECT artifact_id, source_root, format_family, visibility_status FROM source_artifacts"
    ).fetchall()
    timestamp = now_utc()
    created = 0
    for artifact_id, source_root, family, visibility in rows:
        gap_type = None
        severity = "P2"
        if family == "image":
            gap_type = "ocr-needed"
            severity = "P1"
        elif family in {"audio", "video"}:
            gap_type = "asr-needed"
            severity = "P1"
        elif family == "archive":
            gap_type = "not-ingested"
            severity = "P1"
        elif visibility == "binary-only":
            gap_type = "not-searchable"
        if gap_type:
            gap_id = hashlib.sha1(f"fs:{artifact_id}:{gap_type}".encode("utf-8")).hexdigest()
            cur.execute(
                """
                INSERT OR REPLACE INTO knowledge_gaps(
                    gap_id, topic_id, gap_type, artifact_id, severity,
                    description, resolution_status, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    gap_id,
                    None,
                    gap_type,
                    artifact_id,
                    severity,
                    f"Filesystem baseline: {source_root} artifact requires {gap_type}",
                    "open",
                    timestamp,
                    timestamp,
                ),
            )
            created += 1
    return created


def record_checkpoint(cur: sqlite3.Cursor, metrics: dict[str, int]) -> None:
    checkpoint_id = hashlib.sha1(f"filesystem:{now_utc()}".encode("utf-8")).hexdigest()
    metrics_json = "{" + ", ".join(f'"{k}": {v}' for k, v in metrics.items()) + "}"
    cur.execute(
        """
        INSERT INTO ingest_checkpoints(checkpoint_id, checkpoint_name, source_root, metrics_json, created_at)
        VALUES (?, ?, ?, ?, ?)
        """,
        (checkpoint_id, "filesystem-ingest-baseline", None, metrics_json, now_utc()),
    )


def main() -> None:
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    ensure_schema_columns(cur)

    inserted = 0
    by_root = Counter()
    timestamp = now_utc()

    for source_root, root in ROOTS:
        if not root.exists():
            print(f"SKIP missing root: {root}")
            continue
        for path in [root, *root.rglob("*")]:
            try:
                artifact_id = upsert_artifact(cur, source_root, root, path, timestamp)
                assign_topics_for_artifact(cur, artifact_id, path, infer_format_family(path))
                inserted += 1
                by_root[source_root] += 1
            except Exception as exc:
                print(f"WARN failed to ingest {path}: {exc}")

    dedup_groups = rebuild_dedup(cur)
    coverage_rows = rebuild_coverage(cur)
    gap_rows = rebuild_gap_baseline(cur)

    metrics = {
        "inserted_paths": inserted,
        "anti_paths": by_root["Anti"],
        "felmeres_paths": by_root["Felmeres"],
        "dedup_groups": dedup_groups,
        "coverage_rows": coverage_rows,
        "gap_rows": gap_rows,
    }
    record_checkpoint(cur, metrics)

    conn.commit()
    conn.close()

    print("Filesystem ingest complete.")
    for key, value in metrics.items():
        print(f"  {key}={value}")


if __name__ == "__main__":
    main()
