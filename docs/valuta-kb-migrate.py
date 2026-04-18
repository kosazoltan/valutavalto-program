"""
Valutavalto knowledge base schema migrator.

Creates the audit-capable schema layers described in the knowledge-base
architecture plan and bootstraps existing rows from:
- felmeres_docs
- agent_knowledge_segments

Usage:
  python docs/valuta-kb-migrate.py
"""
from __future__ import annotations

import hashlib
import os
import sqlite3
import unicodedata
from datetime import datetime, timezone


DB_PATH = os.path.join(os.path.dirname(__file__), "valuta-knowledge.sqlite")

TOPICS = [
    ("cashdesk-shell", None, "Cashdesk Shell", "IBVALTO shell and cashier orchestration"),
    ("transactions-buy-sell-conversion", None, "Transactions", "Buy, sell, conversion transaction flows"),
    ("receipts-printing", None, "Receipts Printing", "Receipts, print templates, numbering, proofing"),
    ("customers-aml-kyc", None, "Customers AML KYC", "Customer handling, AML, KYC, identification"),
    ("sanctions-blacklist", "customers-aml-kyc", "Sanctions Blacklist", "Sanctions screening and blacklist rules"),
    ("rates-rate-publication", None, "Rates", "Rates, rate publication, exchange-rate workflows"),
    ("reservations-booking", None, "Reservations Booking", "Reservation and booking workflows"),
    ("closing-daily-monthly-yearly", None, "Closing", "Daily, monthly, yearly closing workflows"),
    ("denomination-cash-stock", None, "Denomination Cash Stock", "Denominations, stock, cash handling"),
    ("treasury-vault-transfer", None, "Treasury Vault Transfer", "Treasury, vault and handover flows"),
    ("server-import-receptor", None, "Server Import Receptor", "Server-side imports, receptor, data collection"),
    ("dat-file-formats", None, "DAT File Formats", "Legacy DAT and binary exchange formats"),
    ("firebird-schema-and-db-artifacts", None, "Firebird Schema DB Artifacts", "Firebird DBs, tables, schema reconstruction"),
    ("camera-core", None, "Camera Core", "Camera bounded context core"),
    ("camera-export-custody", "camera-core", "Camera Export Custody", "Camera export, custody, integrity"),
    ("western-union", None, "Western Union", "Western Union flows and integrations"),
    ("partner-integrations", None, "Partner Integrations", "External partner integrations"),
    ("survey-requirements", None, "Survey Requirements", "Survey, interviews, requirements corpus"),
    ("ui-screenshots-and-receipt-images", None, "UI Screenshots And Receipt Images", "Screenshots, scans, receipt images"),
    ("audio-video-transcripts", None, "Audio Video Transcripts", "ASR transcripts and media-derived text"),
]

DOMAIN_TABLES = [
    "legacy_binary_inventory",
    "legacy_dll_parity_matrix",
    "firebird_db_artifacts",
    "szerver_dat_file_families",
    "aml_rule_parity_matrix",
    "firebird_table_entity_matrix",
    "camera_endpoint_gap_matrix",
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


def infer_source_root(path: str) -> str:
    lowered = normalize_text(path).lower()
    if "/anti/" in lowered:
        return "Anti"
    if "/felmérés/" in lowered or "/felmeres/" in lowered or "/felmérés/" in lowered:
        return "Felmeres"
    return "RepoDocs"


def infer_format_family(path: str, doc_type: str | None = None) -> str:
    lowered = normalize_text(path).lower()
    ext = os.path.splitext(lowered)[1]
    if lowered.endswith(".pas"):
        return "pascal"
    if ext in {".dpr", ".dpk", ".dfm", ".dproj"}:
        return "delphi-project"
    if ext == ".java":
        return "java"
    if ext in {".exe", ".dll"}:
        return "binary-pe"
    if ext in {".fdb", ".gdb", ".db", ".sqlite"}:
        return "firebird-db"
    if ext in {".html", ".htm"}:
        return "html"
    if ext == ".md":
        return "markdown"
    if ext == ".csv":
        return "csv"
    if ext in {".xls", ".xlsx", ".ods"}:
        return "spreadsheet"
    if ext == ".pdf":
        return "pdf"
    if ext in {".png", ".jpg", ".jpeg", ".gif", ".bmp", ".webp", ".tif", ".tiff", ".svg"}:
        return "image"
    if ext in {".mp3", ".wav", ".m4a", ".flac", ".ogg", ".aac", ".wma"}:
        return "audio"
    if ext in {".mp4", ".mov", ".avi", ".mkv", ".webm", ".wmv", ".mpeg", ".mpg"}:
        return "video"
    if ext in {".txt", ".log"}:
        return "text"
    if doc_type:
        return doc_type
    return "unknown"


def canonicalize_path(path: str) -> str:
    canonical = normalize_text(path)
    replacements = [
        "/_extracted_auto/",
        "/_extracted/",
        "/forrasok_unpacked/",
        "/old_unpacked/",
        "/camera_unpacked/",
        "/arfolyam_unpacked/",
        "/keszlex_unpacked/",
        "/orecptor_unpacked/",
    ]
    for token in replacements:
        canonical = canonical.replace(token, "/")
    while "//" in canonical:
        canonical = canonical.replace("//", "/")
    return canonical


def artifact_id_for(path: str) -> str:
    norm = normalize_text(path).encode("utf-8")
    return hashlib.sha1(norm).hexdigest()


def hash_for_content(content: str) -> str:
    return hashlib.sha256(content.encode("utf-8", errors="replace")).hexdigest()


def ensure_column(cur: sqlite3.Cursor, table: str, column: str, ddl: str) -> None:
    columns = {row[1] for row in cur.execute(f"PRAGMA table_info({table})")}
    if column not in columns:
        cur.execute(f"ALTER TABLE {table} ADD COLUMN {ddl}")


def table_exists(cur: sqlite3.Cursor, table: str) -> bool:
    row = cur.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?",
        (table,),
    ).fetchone()
    return row is not None


def create_schema(cur: sqlite3.Cursor) -> None:
    cur.executescript(
        """
        CREATE TABLE IF NOT EXISTS kb_schema_meta (
            key TEXT PRIMARY KEY,
            value TEXT,
            updated_at TEXT
        );

        CREATE TABLE IF NOT EXISTS source_artifacts (
            artifact_id TEXT PRIMARY KEY,
            source_root TEXT NOT NULL,
            absolute_path TEXT NOT NULL,
            canonical_path TEXT,
            parent_path TEXT,
            artifact_kind TEXT NOT NULL,
            format_family TEXT NOT NULL,
            extension TEXT,
            size_bytes INTEGER,
            sha256 TEXT,
            mtime_utc TEXT,
            discovery_method TEXT NOT NULL,
            visibility_status TEXT NOT NULL,
            ingest_priority TEXT,
            notes TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        );
        CREATE INDEX IF NOT EXISTS idx_source_artifacts_root ON source_artifacts(source_root);
        CREATE INDEX IF NOT EXISTS idx_source_artifacts_canonical ON source_artifacts(canonical_path);
        CREATE INDEX IF NOT EXISTS idx_source_artifacts_format ON source_artifacts(format_family);

        CREATE TABLE IF NOT EXISTS artifact_dedup_groups (
            dedup_group_id TEXT PRIMARY KEY,
            dedup_key TEXT NOT NULL UNIQUE,
            canonical_artifact_id TEXT,
            duplicate_count INTEGER DEFAULT 0,
            dedup_reason TEXT,
            confidence TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (canonical_artifact_id) REFERENCES source_artifacts(artifact_id)
        );

        CREATE TABLE IF NOT EXISTS artifact_dedup_members (
            dedup_group_id TEXT NOT NULL,
            artifact_id TEXT NOT NULL,
            member_role TEXT NOT NULL,
            PRIMARY KEY (dedup_group_id, artifact_id),
            FOREIGN KEY (dedup_group_id) REFERENCES artifact_dedup_groups(dedup_group_id),
            FOREIGN KEY (artifact_id) REFERENCES source_artifacts(artifact_id)
        );
        CREATE INDEX IF NOT EXISTS idx_dedup_members_artifact ON artifact_dedup_members(artifact_id);

        CREATE TABLE IF NOT EXISTS artifact_ingest_runs (
            run_id TEXT PRIMARY KEY,
            artifact_id TEXT NOT NULL,
            ingest_stage TEXT NOT NULL,
            ingest_status TEXT NOT NULL,
            tooling TEXT,
            output_artifact_id TEXT,
            error_summary TEXT,
            started_at TEXT,
            finished_at TEXT,
            FOREIGN KEY (artifact_id) REFERENCES source_artifacts(artifact_id),
            FOREIGN KEY (output_artifact_id) REFERENCES source_artifacts(artifact_id)
        );
        CREATE INDEX IF NOT EXISTS idx_ingest_runs_artifact ON artifact_ingest_runs(artifact_id);
        CREATE INDEX IF NOT EXISTS idx_ingest_runs_status ON artifact_ingest_runs(ingest_status);

        CREATE TABLE IF NOT EXISTS artifact_text_extracts (
            extract_id TEXT PRIMARY KEY,
            artifact_id TEXT NOT NULL,
            extract_type TEXT NOT NULL,
            language TEXT,
            text_content TEXT NOT NULL,
            char_count INTEGER,
            quality_score REAL,
            quality_notes TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (artifact_id) REFERENCES source_artifacts(artifact_id)
        );
        CREATE INDEX IF NOT EXISTS idx_text_extracts_artifact ON artifact_text_extracts(artifact_id);
        CREATE INDEX IF NOT EXISTS idx_text_extracts_type ON artifact_text_extracts(extract_type);

        CREATE TABLE IF NOT EXISTS topics (
            topic_id TEXT PRIMARY KEY,
            parent_topic_id TEXT,
            title TEXT NOT NULL,
            description TEXT,
            FOREIGN KEY (parent_topic_id) REFERENCES topics(topic_id)
        );

        CREATE TABLE IF NOT EXISTS artifact_topics (
            artifact_id TEXT NOT NULL,
            topic_id TEXT NOT NULL,
            relevance_score REAL DEFAULT 1.0,
            PRIMARY KEY (artifact_id, topic_id),
            FOREIGN KEY (artifact_id) REFERENCES source_artifacts(artifact_id),
            FOREIGN KEY (topic_id) REFERENCES topics(topic_id)
        );

        CREATE TABLE IF NOT EXISTS segment_topics (
            segment_id INTEGER NOT NULL,
            topic_id TEXT NOT NULL,
            relevance_score REAL DEFAULT 1.0,
            PRIMARY KEY (segment_id, topic_id),
            FOREIGN KEY (segment_id) REFERENCES agent_knowledge_segments(id),
            FOREIGN KEY (topic_id) REFERENCES topics(topic_id)
        );

        CREATE TABLE IF NOT EXISTS knowledge_coverage (
            coverage_id TEXT PRIMARY KEY,
            source_root TEXT NOT NULL,
            topic_id TEXT NOT NULL,
            artifact_count_seen INTEGER DEFAULT 0,
            artifact_count_ingested INTEGER DEFAULT 0,
            artifact_count_indexed INTEGER DEFAULT 0,
            artifact_count_blocked INTEGER DEFAULT 0,
            coverage_percent REAL DEFAULT 0,
            last_computed_at TEXT
        );
        CREATE INDEX IF NOT EXISTS idx_knowledge_coverage_root_topic ON knowledge_coverage(source_root, topic_id);

        CREATE TABLE IF NOT EXISTS knowledge_gaps (
            gap_id TEXT PRIMARY KEY,
            topic_id TEXT,
            gap_type TEXT NOT NULL,
            artifact_id TEXT,
            severity TEXT,
            description TEXT NOT NULL,
            resolution_status TEXT NOT NULL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (artifact_id) REFERENCES source_artifacts(artifact_id),
            FOREIGN KEY (topic_id) REFERENCES topics(topic_id)
        );
        CREATE INDEX IF NOT EXISTS idx_knowledge_gaps_topic ON knowledge_gaps(topic_id);
        CREATE INDEX IF NOT EXISTS idx_knowledge_gaps_status ON knowledge_gaps(resolution_status);

        CREATE TABLE IF NOT EXISTS ingest_checkpoints (
            checkpoint_id TEXT PRIMARY KEY,
            checkpoint_name TEXT NOT NULL,
            source_root TEXT,
            metrics_json TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        );
        """
    )

    ensure_column(cur, "agent_knowledge_segments", "artifact_id", "artifact_id TEXT")
    ensure_column(cur, "agent_knowledge_segments", "extract_id", "extract_id TEXT")
    ensure_column(cur, "agent_knowledge_segments", "evidence_level", "evidence_level TEXT")
    ensure_column(cur, "agent_knowledge_segments", "topic_id", "topic_id TEXT")
    ensure_column(cur, "agent_knowledge_segments", "confidence", "confidence TEXT")
    ensure_column(cur, "agent_knowledge_segments", "segment_hash", "segment_hash TEXT")

    ensure_column(cur, "felmeres_docs", "artifact_id", "artifact_id TEXT")

    for table in DOMAIN_TABLES:
        if table_exists(cur, table):
            ensure_column(cur, table, "source_artifact_ids", "source_artifact_ids TEXT")
            ensure_column(cur, table, "evidence_level", "evidence_level TEXT")
            ensure_column(cur, table, "confidence", "confidence TEXT")
            ensure_column(cur, table, "last_verified_at", "last_verified_at TEXT")


def seed_topics(cur: sqlite3.Cursor) -> None:
    cur.executemany(
        """
        INSERT INTO topics(topic_id, parent_topic_id, title, description)
        VALUES (?, ?, ?, ?)
        ON CONFLICT(topic_id) DO UPDATE SET
            parent_topic_id=excluded.parent_topic_id,
            title=excluded.title,
            description=excluded.description
        """,
        TOPICS,
    )


def bootstrap_felmeres_docs(cur: sqlite3.Cursor) -> int:
    rows = cur.execute(
        "SELECT id, path, filename, type, size_kb, content, category FROM felmeres_docs"
    ).fetchall()
    migrated = 0
    timestamp = now_utc()

    for doc_id, path, filename, doc_type, size_kb, content, category in rows:
        if not path:
            path = filename or f"felmeres_doc_{doc_id}"
        artifact_id = artifact_id_for(path)
        canonical_path = canonicalize_path(path)
        source_root = infer_source_root(path)
        format_family = infer_format_family(path, doc_type)
        sha256 = hash_for_content(content or "")
        parent_path = normalize_text(os.path.dirname(path))
        ext = os.path.splitext(path)[1].lower()

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
                source_root=excluded.source_root,
                absolute_path=excluded.absolute_path,
                canonical_path=excluded.canonical_path,
                parent_path=excluded.parent_path,
                format_family=excluded.format_family,
                extension=excluded.extension,
                size_bytes=excluded.size_bytes,
                sha256=excluded.sha256,
                updated_at=excluded.updated_at
            """,
            (
                artifact_id,
                source_root,
                path,
                canonical_path,
                parent_path,
                "file",
                format_family,
                ext,
                int((size_kb or 0) * 1024),
                sha256,
                None,
                "direct-read",
                "directly-readable",
                "P1",
                f"Bootstrap from felmeres_docs category={category}",
                timestamp,
                timestamp,
            ),
        )

        extract_id = hashlib.sha1(f"{artifact_id}:fulltext".encode("utf-8")).hexdigest()
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
                "fulltext",
                "hu",
                content or "",
                len(content or ""),
                1.0,
                "Bootstrapped from felmeres_docs",
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
                "bootstrap-felmeres-docs",
                None,
                None,
                timestamp,
                timestamp,
            ),
        )

        cur.execute(
            "UPDATE felmeres_docs SET artifact_id=? WHERE id=?",
            (artifact_id, doc_id),
        )
        migrated += 1

    return migrated


def bootstrap_segments(cur: sqlite3.Cursor) -> int:
    rows = cur.execute(
        "SELECT id, title, reference_path, content FROM agent_knowledge_segments"
    ).fetchall()
    updated = 0
    timestamp = now_utc()

    for seg_id, title, reference_path, content in rows:
        reference_path = reference_path or title or f"segment_{seg_id}"
        artifact_id = artifact_id_for(reference_path)
        canonical_path = canonicalize_path(reference_path)
        source_root = infer_source_root(reference_path)
        format_family = infer_format_family(reference_path)

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
                updated_at=excluded.updated_at
            """,
            (
                artifact_id,
                source_root,
                reference_path,
                canonical_path,
                normalize_text(os.path.dirname(reference_path)),
                "file",
                format_family,
                os.path.splitext(reference_path)[1].lower(),
                None,
                None,
                None,
                "manual-path",
                "exists-but-index-hidden" if source_root in {"Anti", "Felmeres"} else "directly-readable",
                "P1",
                "Bootstrap from agent_knowledge_segments",
                timestamp,
                timestamp,
            ),
        )

        extract_id = hashlib.sha1(f"{artifact_id}:segment-source".encode("utf-8")).hexdigest()
        cur.execute(
            """
            INSERT OR IGNORE INTO artifact_text_extracts(
                extract_id, artifact_id, extract_type, language, text_content,
                char_count, quality_score, quality_notes, created_at
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                extract_id,
                artifact_id,
                "manual-summary",
                "hu",
                content or "",
                len(content or ""),
                0.7,
                "Segment source bootstrap",
                timestamp,
            ),
        )

        seg_hash = hash_for_content((title or "") + "\n" + (content or ""))
        cur.execute(
            """
            UPDATE agent_knowledge_segments
            SET artifact_id=?,
                extract_id=?,
                evidence_level=COALESCE(evidence_level, 'direct'),
                confidence=COALESCE(confidence, 'medium'),
                segment_hash=?
            WHERE id=?
            """,
            (artifact_id, extract_id, seg_hash, seg_id),
        )
        updated += 1

    return updated


def build_dedup_groups(cur: sqlite3.Cursor) -> int:
    rows = cur.execute(
        "SELECT artifact_id, canonical_path, sha256 FROM source_artifacts"
    ).fetchall()
    groups: dict[str, list[str]] = {}
    for artifact_id, canonical_path, sha256 in rows:
        dedup_key = f"sha256:{sha256}" if sha256 else f"canonical:{canonical_path}"
        groups.setdefault(dedup_key, []).append(artifact_id)

    timestamp = now_utc()
    count = 0
    for dedup_key, artifact_ids in groups.items():
        dedup_group_id = hashlib.sha1(dedup_key.encode("utf-8")).hexdigest()
        canonical_artifact_id = sorted(artifact_ids)[0]
        reason = "same-hash" if dedup_key.startswith("sha256:") else "same-content-different-path"
        confidence = "high" if dedup_key.startswith("sha256:") else "medium"

        cur.execute(
            """
            INSERT OR REPLACE INTO artifact_dedup_groups(
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
        for member_id in artifact_ids:
            cur.execute(
                """
                INSERT OR REPLACE INTO artifact_dedup_members(
                    dedup_group_id, artifact_id, member_role
                )
                VALUES (?, ?, ?)
                """,
                (
                    dedup_group_id,
                    member_id,
                    "canonical" if member_id == canonical_artifact_id else "duplicate",
                ),
            )
        count += 1
    return count


def populate_topic_links(cur: sqlite3.Cursor) -> int:
    rows = cur.execute(
        "SELECT id, topic, area, title, keywords, artifact_id FROM agent_knowledge_segments"
    ).fetchall()
    linked = 0
    known_topics = {row[0] for row in cur.execute("SELECT topic_id FROM topics")}

    for seg_id, topic, area, title, keywords, artifact_id in rows:
        topic_candidates = []
        lowered = " ".join(filter(None, [topic, area, title, keywords])).lower()
        mapping = {
            "aml": "customers-aml-kyc",
            "bigctrl": "customers-aml-kyc",
            "sanction": "sanctions-blacklist",
            "terror": "sanctions-blacklist",
            "camera": "camera-core",
            "custody": "camera-export-custody",
            "rate": "rates-rate-publication",
            "arfolyam": "rates-rate-publication",
            "firebird": "firebird-schema-and-db-artifacts",
            "fdb": "firebird-schema-and-db-artifacts",
            "dat": "dat-file-formats",
            "receipt": "receipts-printing",
            "bizonylat": "receipts-printing",
            "closing": "closing-daily-monthly-yearly",
            "zar": "closing-daily-monthly-yearly",
            "reservation": "reservations-booking",
            "booking": "reservations-booking",
            "survey": "survey-requirements",
            "felmeres": "survey-requirements",
            "screenshot": "ui-screenshots-and-receipt-images",
            "kep": "ui-screenshots-and-receipt-images",
            "western": "western-union",
            "wu": "western-union",
        }
        for needle, topic_id in mapping.items():
            if needle in lowered and topic_id in known_topics:
                topic_candidates.append(topic_id)

        if not topic_candidates and topic in known_topics:
            topic_candidates.append(topic)

        if topic_candidates:
            first_topic = sorted(set(topic_candidates))[0]
            cur.execute(
                "UPDATE agent_knowledge_segments SET topic_id=COALESCE(topic_id, ?), confidence=COALESCE(confidence, 'medium') WHERE id=?",
                (first_topic, seg_id),
            )
            for topic_id in sorted(set(topic_candidates)):
                cur.execute(
                    "INSERT OR IGNORE INTO segment_topics(segment_id, topic_id, relevance_score) VALUES (?, ?, ?)",
                    (seg_id, topic_id, 1.0),
                )
                if artifact_id:
                    cur.execute(
                        "INSERT OR IGNORE INTO artifact_topics(artifact_id, topic_id, relevance_score) VALUES (?, ?, ?)",
                        (artifact_id, topic_id, 1.0),
                    )
            linked += 1
    return linked


def compute_baseline_coverage(cur: sqlite3.Cursor) -> int:
    cur.execute("DELETE FROM knowledge_coverage")
    source_roots = [row[0] for row in cur.execute("SELECT DISTINCT source_root FROM source_artifacts")]
    topic_ids = [row[0] for row in cur.execute("SELECT topic_id FROM topics")]
    timestamp = now_utc()
    inserted = 0

    for source_root in source_roots:
        for topic_id in topic_ids:
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
            ingested = cur.execute(
                """
                SELECT COUNT(DISTINCT sa.artifact_id)
                FROM source_artifacts sa
                JOIN artifact_topics at ON at.artifact_id = sa.artifact_id
                JOIN artifact_ingest_runs ir ON ir.artifact_id = sa.artifact_id
                WHERE sa.source_root=? AND at.topic_id=? AND ir.ingest_status='completed'
                """,
                (source_root, topic_id),
            ).fetchone()[0]
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
            blocked = cur.execute(
                """
                SELECT COUNT(DISTINCT sa.artifact_id)
                FROM source_artifacts sa
                JOIN artifact_topics at ON at.artifact_id = sa.artifact_id
                WHERE sa.source_root=? AND at.topic_id=? AND sa.visibility_status IN ('binary-only', 'missing', 'unverified')
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
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
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


def create_gap_baseline(cur: sqlite3.Cursor) -> int:
    cur.execute("DELETE FROM knowledge_gaps WHERE resolution_status='open' AND description LIKE 'Auto baseline:%'")
    rows = cur.execute(
        """
        SELECT artifact_id, source_root, visibility_status, format_family
        FROM source_artifacts
        """
    ).fetchall()
    created = 0
    timestamp = now_utc()
    for artifact_id, source_root, visibility_status, format_family in rows:
        gap_type = None
        severity = "P2"
        if visibility_status in {"binary-only", "unverified"}:
            gap_type = "not-searchable"
        if format_family == "image":
            gap_type = "ocr-needed"
            severity = "P1"
        elif format_family in {"audio", "video"}:
            gap_type = "asr-needed"
            severity = "P1"
        if gap_type:
            gap_id = hashlib.sha1(f"{artifact_id}:{gap_type}".encode("utf-8")).hexdigest()
            cur.execute(
                """
                INSERT OR REPLACE INTO knowledge_gaps(
                    gap_id, topic_id, gap_type, artifact_id, severity,
                    description, resolution_status, created_at, updated_at
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    gap_id,
                    None,
                    gap_type,
                    artifact_id,
                    severity,
                    f"Auto baseline: {source_root} artifact requires {gap_type}",
                    "open",
                    timestamp,
                    timestamp,
                ),
            )
            created += 1
    return created


def record_checkpoint(cur: sqlite3.Cursor) -> None:
    metrics = {
        "source_artifacts": cur.execute("SELECT COUNT(*) FROM source_artifacts").fetchone()[0],
        "artifact_dedup_groups": cur.execute("SELECT COUNT(*) FROM artifact_dedup_groups").fetchone()[0],
        "artifact_ingest_runs": cur.execute("SELECT COUNT(*) FROM artifact_ingest_runs").fetchone()[0],
        "artifact_text_extracts": cur.execute("SELECT COUNT(*) FROM artifact_text_extracts").fetchone()[0],
        "topics": cur.execute("SELECT COUNT(*) FROM topics").fetchone()[0],
        "artifact_topics": cur.execute("SELECT COUNT(*) FROM artifact_topics").fetchone()[0],
        "segment_topics": cur.execute("SELECT COUNT(*) FROM segment_topics").fetchone()[0],
        "knowledge_coverage": cur.execute("SELECT COUNT(*) FROM knowledge_coverage").fetchone()[0],
        "knowledge_gaps": cur.execute("SELECT COUNT(*) FROM knowledge_gaps").fetchone()[0],
    }
    metrics_json = "{" + ", ".join(f'"{k}": {v}' for k, v in metrics.items()) + "}"
    checkpoint_id = hashlib.sha1(f"baseline:{now_utc()}".encode("utf-8")).hexdigest()
    cur.execute(
        """
        INSERT INTO ingest_checkpoints(checkpoint_id, checkpoint_name, source_root, metrics_json, created_at)
        VALUES (?, ?, ?, ?, ?)
        """,
        (checkpoint_id, "kb-schema-baseline", None, metrics_json, now_utc()),
    )
    cur.execute(
        """
        INSERT OR REPLACE INTO kb_schema_meta(key, value, updated_at)
        VALUES (?, ?, ?)
        """,
        ("schema_version", "2026-04-09-kb-architecture-v1", now_utc()),
    )


def main() -> None:
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    create_schema(cur)
    seed_topics(cur)
    migrated_docs = bootstrap_felmeres_docs(cur)
    migrated_segments = bootstrap_segments(cur)
    dedup_groups = build_dedup_groups(cur)
    linked_topics = populate_topic_links(cur)
    coverage_rows = compute_baseline_coverage(cur)
    gap_rows = create_gap_baseline(cur)
    record_checkpoint(cur)

    conn.commit()
    conn.close()

    print("Knowledge base schema migration complete.")
    print(f"  migrated_docs={migrated_docs}")
    print(f"  migrated_segments={migrated_segments}")
    print(f"  dedup_groups={dedup_groups}")
    print(f"  linked_topics={linked_topics}")
    print(f"  coverage_rows={coverage_rows}")
    print(f"  gap_rows={gap_rows}")


if __name__ == "__main__":
    main()
