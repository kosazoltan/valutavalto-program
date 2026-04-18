"""
Extract searchable metadata and available text from Anti non-text artifacts.

Targets:
- PDF files: direct text extraction when possible, metadata fallback otherwise
- Image files: OCR when Tesseract is available, metadata fallback otherwise
- PE binaries: searchable strings + lightweight header clues
- Firebird DB artifacts: header + printable identifier strings

Usage:
  python docs/valuta-kb-extract-media-metadata.py
"""
from __future__ import annotations

import hashlib
import os
import re
import sqlite3
from datetime import datetime, timezone
from pathlib import Path
from xml.etree import ElementTree as ET

import fitz
from PIL import Image
import pytesseract


DB_PATH = Path(__file__).with_name("valuta-knowledge.sqlite")
ASCII_RE = re.compile(rb"[ -~]{4,}")
UTF16_RE = re.compile(rb"(?:[\x20-\x7e]\x00){4,}")
IDENTIFIER_RE = re.compile(r"^[A-Z0-9_$]{3,}$")
API_RE = re.compile(r"^(Create|Read|Write|Open|Close|Get|Set|Reg|Crypt|Load|Free|Query|Delete|Find|Move|Copy|Shell|Http|Internet)[A-Za-z0-9_@?$]+$")
IMPORT_KEYWORDS = ("SENDDATA", "RECEPTOR", "OLDDATA", "UJDATA", "SORSZAM", "BOOKING", "FOGLALO", "ARFDATA")
IMPORT_TEXT_EXTENSIONS = {".ini", ".cfg", ".txt", ".xml", ".json", ".yaml", ".yml", ".html", ".htm", ".md", ".pas", ".dpr", ".dpk", ".inc"}
DEFAULT_TESSERACT_CANDIDATES = [
    r"C:\Program Files\Tesseract-OCR\tesseract.exe",
    r"C:\Program Files (x86)\Tesseract-OCR\tesseract.exe",
]


def now_utc() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def open_db_connection(db_path: Path | str) -> sqlite3.Connection:
    conn = sqlite3.connect(db_path, timeout=30)
    conn.execute("PRAGMA busy_timeout = 30000")
    conn.execute("PRAGMA journal_mode = WAL")
    return conn


def resolve_tesseract_cmd() -> str | None:
    env_value = os.environ.get("TESSERACT_CMD")
    if env_value and Path(env_value).exists():
        return env_value
    for candidate in DEFAULT_TESSERACT_CANDIDATES:
        if Path(candidate).exists():
            return candidate
    local_candidate = Path(os.path.expandvars(r"%LOCALAPPDATA%\Programs\Tesseract-OCR\tesseract.exe"))
    if local_candidate.exists():
        return str(local_candidate)
    return None


def configure_tesseract_cmd() -> str | None:
    resolved = resolve_tesseract_cmd()
    if resolved:
        pytesseract.pytesseract.tesseract_cmd = resolved
    return resolved


def tesseract_available() -> bool:
    try:
        configure_tesseract_cmd()
        pytesseract.get_tesseract_version()
        return True
    except Exception:
        return False


def extract_ascii_strings(blob: bytes, limit: int = 80) -> list[str]:
    values: list[str] = []
    seen: set[str] = set()
    for match in ASCII_RE.findall(blob):
        value = match.decode("latin-1", errors="replace").strip()
        if value and value not in seen:
            seen.add(value)
            values.append(value)
        if len(values) >= limit:
            break
    for match in UTF16_RE.findall(blob):
        value = match.decode("utf-16le", errors="replace").strip()
        if value and value not in seen:
            seen.add(value)
            values.append(value)
        if len(values) >= limit:
            break
    return values


def unique_preserve(values: list[str]) -> list[str]:
    result: list[str] = []
    seen: set[str] = set()
    for value in values:
        cleaned = value.strip()
        if not cleaned or cleaned in seen:
            continue
        seen.add(cleaned)
        result.append(cleaned)
    return result


def classify_firebird_strings(strings: list[str]) -> dict[str, list[str]]:
    system_clues = [s for s in strings if s.startswith("RDB$")]
    generator_clues = [s for s in strings if s.startswith("GEN_")]
    trigger_clues = [s for s in strings if s.startswith("TRG_")]
    procedure_clues = [s for s in strings if s.startswith("SP_")]
    view_clues = [s for s in strings if s.startswith("VW_")]

    reserved = set(system_clues + generator_clues + trigger_clues + procedure_clues + view_clues)
    table_clues = [
        s for s in strings
        if s not in reserved and IDENTIFIER_RE.match(s) and not s.endswith(".DAT") and "$" not in s
    ]
    field_suffixes = ("_ID", "_KOD", "_CODE", "_DATUM", "_DATE", "_OSSZEG", "_AMOUNT", "_NEV", "_NAME")
    field_clues = [s for s in table_clues if "_" in s and s.endswith(field_suffixes)]

    return {
        "system_clues": unique_preserve(system_clues)[:20],
        "table_clues": unique_preserve(table_clues)[:25],
        "field_clues": unique_preserve(field_clues)[:25],
        "generator_clues": unique_preserve(generator_clues)[:20],
        "trigger_clues": unique_preserve(trigger_clues)[:20],
        "procedure_clues": unique_preserve(procedure_clues)[:20],
        "view_clues": unique_preserve(view_clues)[:20],
    }


def classify_binary_strings(strings: list[str]) -> dict[str, list[str]]:
    import_clues = [s for s in strings if s.lower().endswith(".dll")]
    symbol_clues = [s for s in strings if API_RE.match(s)]
    dat_clues = [s for s in strings if ".DAT" in s.upper()]
    import_chain_clues = [s for s in strings if any(keyword in s.upper() for keyword in IMPORT_KEYWORDS)]
    domain_clues = [
        s for s in strings
        if s not in import_clues
        and s not in symbol_clues
        and s not in dat_clues
        and IDENTIFIER_RE.match(s)
        and len(s) >= 4
    ]
    return {
        "import_clues": unique_preserve(import_clues)[:25],
        "symbol_clues": unique_preserve(symbol_clues)[:25],
        "domain_clues": unique_preserve(domain_clues + import_chain_clues)[:25],
        "dat_clues": unique_preserve(dat_clues)[:25],
        "import_chain_clues": unique_preserve(import_chain_clues)[:25],
    }


def detect_record_shape_lines(blob: bytes) -> list[str]:
    shapes: list[str] = []
    text = blob.decode("latin-1", errors="replace")
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        if ";" in line:
            shapes.append(f"semicolon_fields={len([part for part in line.split(';') if part != ''])}")
        elif "|" in line:
            shapes.append(f"pipe_fields={len([part for part in line.split('|') if part != ''])}")
        elif "," in line:
            shapes.append(f"comma_fields={len([part for part in line.split(',') if part != ''])}")
        if len(shapes) >= 10:
            break
    return unique_preserve(shapes)


def extract_import_config_clues_from_text(filename: str, text: str) -> tuple[str, str, str] | None:
    upper = text.upper()
    keyword_hits = [keyword for keyword in IMPORT_KEYWORDS if keyword in upper]
    dat_references = unique_preserve(re.findall(r"[A-Z0-9_/-]+\.DAT", upper))
    if not keyword_hits and not dat_references:
        return None

    matching_lines: list[str] = []
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        upper_line = line.upper()
        if any(keyword in upper_line for keyword in IMPORT_KEYWORDS) or ".DAT" in upper_line:
            matching_lines.append(line)
        if len(matching_lines) >= 8:
            break

    summary = [
        f"filename={filename}",
        "keyword_hits=" + ", ".join(unique_preserve(keyword_hits)),
        "dat_references=" + ", ".join(dat_references),
        "matching_lines=" + " || ".join(matching_lines),
    ]
    notes = f"keyword_count={len(unique_preserve(keyword_hits))};line_count={len(matching_lines)}"
    return "\n".join(summary), "import-config-clues", notes


def needs_media_reextract(
    format_family: str,
    extension: str,
    extract_types: set[str],
    tesseract_is_available: bool,
) -> bool:
    extension = (extension or "").lower()
    if not tesseract_is_available:
        return False
    if format_family == "image":
        return "ocr" not in extract_types
    if format_family == "pdf":
        return "pdf-text" not in extract_types and "pdf-ocr" not in extract_types and "ocr" not in extract_types
    return False


def extract_pdf_text_or_metadata(path: Path) -> tuple[str, str, str]:
    doc = fitz.open(path)
    try:
        page_texts = []
        for page in doc:
            text = page.get_text("text").strip()
            if text:
                page_texts.append(text)
        metadata = doc.metadata or {}
        notes = f"pages={doc.page_count};title={metadata.get('title') or ''}".strip(";")
        if page_texts:
            return "\n\n".join(page_texts), "pdf-text", notes
        if tesseract_available():
            ocr_text = try_pdf_ocr(path)
            if ocr_text:
                return ocr_text, "pdf-ocr", notes
        summary = [
            f"filename={path.name}",
            f"pages={doc.page_count}",
            f"title={metadata.get('title') or ''}",
            f"author={metadata.get('author') or ''}",
            "ocr-unavailable" if not tesseract_available() else "ocr-available",
        ]
        return "\n".join(summary), "pdf-metadata", notes
    finally:
        doc.close()


def extract_image_metadata(path: Path) -> tuple[str, str, str]:
    if path.suffix.lower() == ".svg":
        raw = path.read_text(encoding="utf-8", errors="replace")
        root = ET.fromstring(raw)
        width = root.attrib.get("width", "")
        height = root.attrib.get("height", "")
        title = ""
        ids: list[str] = []
        for elem in root.iter():
            tag = elem.tag.split("}")[-1]
            if tag == "title" and (elem.text or "").strip():
                title = (elem.text or "").strip()
            if "id" in elem.attrib and elem.attrib["id"]:
                ids.append(elem.attrib["id"])
        summary = [
            f"filename={path.name}",
            "format=SVG",
            f"width={width}",
            f"height={height}",
            f"title={title}",
            "ids=" + ", ".join(ids[:20]),
        ]
        return "\n".join(summary), "image-metadata", "svg-text;ocr-unavailable"
    with Image.open(path) as image:
        width, height = image.size
        fmt = image.format or path.suffix.lstrip(".").upper()
        mode = image.mode
        summary = [
            f"filename={path.name}",
            f"format={fmt}",
            f"mode={mode}",
            f"width={width}",
            f"height={height}",
        ]
        notes = "ocr-available" if tesseract_available() else "ocr-unavailable"
        return "\n".join(summary), "image-metadata", notes


def try_image_ocr(path: Path) -> tuple[str, str, str] | None:
    if not tesseract_available():
        return None
    if path.suffix.lower() == ".svg":
        return None
    with Image.open(path) as image:
        text = pytesseract.image_to_string(image, lang="hun+eng").strip()
    if not text:
        return None
    return text, "ocr", "ocr-text"


def try_pdf_ocr(path: Path) -> str | None:
    if not tesseract_available():
        return None
    doc = fitz.open(path)
    try:
        page_texts: list[str] = []
        for page in doc:
            pix = page.get_pixmap(matrix=fitz.Matrix(2, 2), alpha=False)
            image = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
            text = pytesseract.image_to_string(image, lang="hun+eng").strip()
            if text:
                page_texts.append(text)
        combined = "\n\n".join(page_texts).strip()
        return combined or None
    finally:
        doc.close()


def extract_binary_metadata(path: Path) -> tuple[str, str, str]:
    blob = path.read_bytes()
    header = blob[:1024]
    strings = extract_ascii_strings(blob[:2 * 1024 * 1024], limit=120)
    mz = header[:2] == b"MZ"
    pe = False
    if mz and len(header) >= 0x40:
        pe_offset = int.from_bytes(header[0x3C:0x40], "little", signed=False)
        if pe_offset + 4 <= len(blob):
            pe = blob[pe_offset:pe_offset + 4] == b"PE\x00\x00"
    clues = classify_binary_strings(strings)
    lines = [
        f"filename={path.name}",
        f"size_bytes={path.stat().st_size}",
        "import_clues=" + ", ".join(clues["import_clues"]),
        "symbol_clues=" + ", ".join(clues["symbol_clues"]),
        "domain_clues=" + ", ".join(clues["domain_clues"]),
        "dat_clues=" + ", ".join(clues["dat_clues"]),
        "import_chain_clues=" + ", ".join(clues["import_chain_clues"]),
    ]
    notes = f"mz={mz};pe={pe};import_count={len(clues['import_clues'])};symbol_count={len(clues['symbol_clues'])}"
    return "\n".join(lines), "binary-metadata", notes


def extract_firebird_metadata(path: Path) -> tuple[str, str, str]:
    blob = path.read_bytes()
    header = blob[:32]
    strings = extract_ascii_strings(blob[:4 * 1024 * 1024], limit=150)
    clues = classify_firebird_strings(strings)
    lines = [
        f"filename={path.name}",
        f"size_bytes={path.stat().st_size}",
        "system_clues=" + ", ".join(clues["system_clues"]),
        "table_clues=" + ", ".join(clues["table_clues"]),
        "field_clues=" + ", ".join(clues["field_clues"]),
        "generator_clues=" + ", ".join(clues["generator_clues"]),
        "trigger_clues=" + ", ".join(clues["trigger_clues"]),
        "procedure_clues=" + ", ".join(clues["procedure_clues"]),
        "view_clues=" + ", ".join(clues["view_clues"]),
    ]
    notes = "header_hex=" + header.hex() + f";schema_clue_count={sum(len(v) for v in clues.values())}"
    return "\n".join(lines), "firebird-metadata", notes


def extract_dat_metadata(path: Path) -> tuple[str, str, str]:
    blob = path.read_bytes()
    strings = extract_ascii_strings(blob[:2 * 1024 * 1024], limit=120)
    upper_strings = [s.upper() for s in strings]
    dat_markers = [s for s in strings if s.upper().endswith(".DAT")]
    import_clues = [
        s for s in strings
        if any(keyword in s.upper() for keyword in IMPORT_KEYWORDS) and not s.upper().endswith(".DAT")
    ]
    identifier_clues = [s for s in strings if IDENTIFIER_RE.match(s) and s not in import_clues and s not in dat_markers][:20]
    record_shape_clues = detect_record_shape_lines(blob)
    lines = [
        f"filename={path.name}",
        f"size_bytes={path.stat().st_size}",
        "dat_markers=" + ", ".join(unique_preserve(dat_markers or [path.name.upper()])),
        "import_clues=" + ", ".join(unique_preserve(import_clues)),
        "identifier_clues=" + ", ".join(unique_preserve(identifier_clues)),
        "record_shape_clues=" + ", ".join(record_shape_clues),
    ]
    notes = "header_hex=" + blob[:32].hex() + f";string_count={len(upper_strings)}"
    return "\n".join(lines), "dat-metadata", notes


def upsert_extract(
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
            "anti-media-metadata-pass",
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


def rebuild_gaps(cur: sqlite3.Cursor, tesseract_is_available: bool | None = None) -> int:
    if tesseract_is_available is None:
        tesseract_is_available = tesseract_available()

    cur.execute("DELETE FROM knowledge_gaps WHERE description LIKE 'Filesystem baseline:%'")
    cur.execute("DELETE FROM knowledge_gaps WHERE description LIKE 'Auto baseline:%'")
    cur.execute("DELETE FROM knowledge_gaps WHERE description LIKE 'Deep ingest:%'")

    rows = cur.execute(
        """
        SELECT sa.artifact_id, sa.source_root, sa.absolute_path, sa.format_family, sa.extension,
               GROUP_CONCAT(te.extract_type, ',')
        FROM source_artifacts sa
        LEFT JOIN artifact_text_extracts te ON te.artifact_id = sa.artifact_id
        GROUP BY sa.artifact_id, sa.source_root, sa.absolute_path, sa.format_family, sa.extension
        """
    ).fetchall()

    timestamp = now_utc()
    created = 0
    for artifact_id, source_root, absolute_path, format_family, extension, extract_types_csv in rows:
        extract_types = set((extract_types_csv or "").split(",")) if extract_types_csv else set()
        gap_type = None
        severity = "P2"

        if format_family == "archive":
            gap_type = "not-ingested"
            severity = "P1"
        elif format_family in {"audio", "video"}:
            gap_type = "asr-needed"
            severity = "P1"
        elif format_family == "image" and "ocr" not in extract_types:
            gap_type = "ocr-needed" if tesseract_is_available else "ocr-tooling-missing"
            severity = "P1"
        elif format_family == "pdf" and "pdf-text" not in extract_types:
            gap_type = "ocr-needed" if tesseract_is_available else "ocr-tooling-missing"
            severity = "P1"
        elif format_family == "binary-pe" and "binary-metadata" in extract_types:
            gap_type = "metadata-only-binary"
        elif format_family == "firebird-db" and "firebird-metadata" in extract_types:
            gap_type = "schema-clue-only"
        elif (extension or "").lower() == ".dat" and "dat-metadata" in extract_types:
            gap_type = "format-clue-only"

        if not gap_type:
            continue

        gap_id = hashlib.sha1(f"deep-gap:{artifact_id}:{gap_type}".encode("utf-8")).hexdigest()
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
                f"Deep ingest: {source_root} artifact still at {gap_type} stage ({absolute_path})",
                "open",
                timestamp,
                timestamp,
            ),
        )
        created += 1
    return created


def record_checkpoint(cur: sqlite3.Cursor, metrics: dict[str, int]) -> None:
    checkpoint_id = hashlib.sha1(f"anti-media-metadata:{now_utc()}".encode("utf-8")).hexdigest()
    metrics_json = "{" + ", ".join(f'"{k}": {v}' for k, v in metrics.items()) + "}"
    cur.execute(
        """
        INSERT INTO ingest_checkpoints(checkpoint_id, checkpoint_name, source_root, metrics_json, created_at)
        VALUES (?, ?, ?, ?, ?)
        """,
        (checkpoint_id, "anti-media-metadata-pass", "Anti", metrics_json, now_utc()),
    )


def iter_import_config_candidates(cur: sqlite3.Cursor) -> list[tuple[str, str, str, str]]:
    return cur.execute(
        """
        SELECT sa.artifact_id, sa.absolute_path, sa.extension, te.text_content
        FROM source_artifacts sa
        JOIN artifact_text_extracts te
          ON te.artifact_id = sa.artifact_id
         AND te.extract_type IN ('fulltext','office-xml')
        WHERE sa.source_root='Anti'
          AND sa.artifact_kind != 'directory'
          AND sa.extension IN ('.ini','.cfg','.txt','.xml','.json','.yaml','.yml','.html','.htm','.md','.pas','.dpr','.dpk','.inc')
          AND NOT EXISTS (
                SELECT 1 FROM artifact_text_extracts extra
                WHERE extra.artifact_id = sa.artifact_id
                  AND extra.extract_type = 'import-config-clues'
          )
        ORDER BY sa.absolute_path
        """
    ).fetchall()


def iter_candidates(cur: sqlite3.Cursor) -> list[tuple[str, str, str, str]]:
    rows = cur.execute(
        """
        SELECT sa.artifact_id, sa.absolute_path, sa.format_family, sa.extension,
               GROUP_CONCAT(te.extract_type, ',')
        FROM source_artifacts sa
        LEFT JOIN artifact_text_extracts te ON te.artifact_id = sa.artifact_id
        WHERE sa.source_root='Anti'
          AND sa.artifact_kind != 'directory'
        GROUP BY sa.artifact_id, sa.absolute_path, sa.format_family, sa.extension
        ORDER BY sa.absolute_path
        """
    ).fetchall()
    ocr_ready = tesseract_available()
    result: list[tuple[str, str, str, str]] = []
    for artifact_id, absolute_path, format_family, extension, extract_types_csv in rows:
        extract_types = set((extract_types_csv or "").split(",")) if extract_types_csv else set()
        if format_family in {"binary-pe", "firebird-db"}:
            result.append((artifact_id, absolute_path, format_family, extension))
            continue
        if (extension or "").lower() == ".dat":
            result.append((artifact_id, absolute_path, format_family, extension))
            continue
        if format_family in {"image", "pdf"}:
            if not extract_types or needs_media_reextract(format_family, extension or "", extract_types, ocr_ready):
                result.append((artifact_id, absolute_path, format_family, extension))
    return result


def process_candidate(path: Path, format_family: str, extension: str) -> tuple[str, str, str, float, str]:
    if extension.lower() == ".dat":
        text, extract_type, notes = extract_dat_metadata(path)
        return text, extract_type, notes, 0.5, "completed"
    if format_family == "pdf":
        text, extract_type, notes = extract_pdf_text_or_metadata(path)
        status = "completed" if extract_type == "pdf-text" else "partial"
        quality = 0.8 if extract_type == "pdf-text" else 0.35
        return text, extract_type, notes, quality, status
    if format_family == "image":
        ocr_result = try_image_ocr(path)
        if ocr_result:
            text, extract_type, notes = ocr_result
            return text, extract_type, notes, 0.75, "completed"
        text, extract_type, notes = extract_image_metadata(path)
        return text, extract_type, notes, 0.25, "partial"
    if format_family == "binary-pe":
        text, extract_type, notes = extract_binary_metadata(path)
        return text, extract_type, notes, 0.45, "completed"
    if format_family == "firebird-db":
        text, extract_type, notes = extract_firebird_metadata(path)
        return text, extract_type, notes, 0.4, "completed"
    raise ValueError(f"Unsupported family {format_family}")


def main() -> None:
    conn = open_db_connection(DB_PATH)
    cur = conn.cursor()
    timestamp = now_utc()

    extracted = 0
    completed = 0
    partial = 0
    failed = 0
    config_clues = 0

    for artifact_id, absolute_path, format_family, extension in iter_candidates(cur):
        path = Path(absolute_path)
        if not path.exists() or not path.is_file():
            record_ingest_run(cur, artifact_id, "failed", timestamp, "missing-file")
            failed += 1
            continue
        try:
            text, extract_type, notes, quality, status = process_candidate(path, format_family, extension or "")
            cleaned = text.strip()
            if not cleaned:
                record_ingest_run(cur, artifact_id, "partial", timestamp, "empty-metadata")
                partial += 1
                continue
            upsert_extract(cur, artifact_id, extract_type, cleaned, quality, notes, timestamp)
            if status == "completed":
                record_ingest_run(cur, artifact_id, "completed", timestamp)
                completed += 1
            else:
                reason = "ocr-unavailable" if "ocr-unavailable" in notes else "metadata-only"
                record_ingest_run(cur, artifact_id, "partial", timestamp, reason)
                partial += 1
            extracted += 1
        except Exception as exc:
            record_ingest_run(cur, artifact_id, "failed", timestamp, type(exc).__name__)
            failed += 1

    for artifact_id, absolute_path, extension, text_content in iter_import_config_candidates(cur):
        if (extension or "").lower() not in IMPORT_TEXT_EXTENSIONS:
            continue
        result = extract_import_config_clues_from_text(Path(absolute_path).name, text_content or "")
        if not result:
            continue
        summary, extract_type, notes = result
        upsert_extract(cur, artifact_id, extract_type, summary, 0.7, notes, timestamp)
        record_ingest_run(cur, artifact_id, "completed", timestamp, "import-config-clues")
        config_clues += 1

    coverage_rows = rebuild_coverage(cur)
    gap_rows = rebuild_gaps(cur)
    metrics = {
        "extracted": extracted,
        "completed": completed,
        "partial": partial,
        "failed": failed,
        "config_clues": config_clues,
        "coverage_rows": coverage_rows,
        "gap_rows": gap_rows,
    }
    record_checkpoint(cur, metrics)

    conn.commit()
    conn.close()

    print("Anti media metadata pass complete.")
    for key, value in metrics.items():
        print(f"  {key}={value}")


if __name__ == "__main__":
    main()
