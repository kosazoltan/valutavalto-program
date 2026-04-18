"""
ASR transcript extractor for audio/video artifacts in the knowledge base.

Uses faster-whisper when available and falls back to patched openai-whisper.
Stores transcripts in artifact_text_extracts with extract_type='asr-transcript'.
"""
from __future__ import annotations

import hashlib
import importlib.util
import os
import sys
import types
from pathlib import Path

import av
import numpy as np


DB_PATH = Path(__file__).with_name("valuta-knowledge.sqlite")
MEDIA_MODULE_PATH = Path(__file__).with_name("valuta-kb-extract-media-metadata.py")
DEFAULT_MODEL_SIZE = os.environ.get("FASTER_WHISPER_MODEL", "tiny")
DEFAULT_COMPUTE_TYPE = os.environ.get("FASTER_WHISPER_COMPUTE_TYPE", "int8")
DEFAULT_ASR_BACKEND = os.environ.get("ASR_BACKEND", "auto").strip().lower()


def load_media_module():
    spec = importlib.util.spec_from_file_location("valuta_kb_extract_media_metadata", MEDIA_MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def iter_asr_candidates(cur):
    return cur.execute(
        """
        SELECT sa.artifact_id, sa.source_root, sa.absolute_path, sa.format_family, sa.sha256, sa.size_bytes
        FROM source_artifacts sa
        WHERE sa.artifact_kind != 'directory'
          AND sa.format_family IN ('audio','video')
          AND NOT EXISTS (
                SELECT 1 FROM artifact_text_extracts te
                WHERE te.artifact_id = sa.artifact_id
                  AND te.extract_type = 'asr-transcript'
          )
        ORDER BY sa.source_root, sa.absolute_path
        """
    ).fetchall()


def group_asr_candidates(rows):
    groups = {}
    ordered = []
    for artifact_id, source_root, absolute_path, format_family, sha256, size_bytes in rows:
        path = Path(absolute_path)
        fingerprint = sha256 or f"{path.name.lower()}::{size_bytes}"
        if fingerprint not in groups:
            groups[fingerprint] = [absolute_path, [artifact_id]]
            ordered.append(fingerprint)
        else:
            groups[fingerprint][1].append(artifact_id)
    return [(groups[key][0], groups[key][1]) for key in ordered]


def import_whisper_with_patch():
    try:
        import coverage  # type: ignore
    except ModuleNotFoundError:
        coverage = types.SimpleNamespace()
        sys.modules["coverage"] = coverage

    coverage.types = types.SimpleNamespace(
        Tracer=object,
        TTraceData=object,
        TShouldTraceFn=object,
        TFileDisposition=object,
        TShouldStartContextFn=object,
        TWarnFn=object,
        TTraceFn=object,
    )
    import whisper

    return whisper


def decode_audio_with_av(path: Path) -> tuple[np.ndarray, int]:
    container = av.open(str(path))
    try:
        stream = next(s for s in container.streams if s.type == "audio")
        resampler = av.audio.resampler.AudioResampler(format="s16", layout="mono", rate=16000)
        chunks = []
        for frame in container.decode(stream):
            frame = resampler.resample(frame)
            if isinstance(frame, list):
                frames = frame
            else:
                frames = [frame]
            for item in frames:
                chunk = item.to_ndarray()
                chunks.append(chunk.reshape(-1))
        if not chunks:
            return np.zeros(0, dtype=np.float32), 16000
        pcm = np.concatenate(chunks).astype(np.float32)
        audio = pcm / 32768.0
        return audio, 16000
    finally:
        container.close()


def load_asr_backend(
    model_size: str = DEFAULT_MODEL_SIZE,
    compute_type: str = DEFAULT_COMPUTE_TYPE,
    preferred_backend: str = DEFAULT_ASR_BACKEND,
):
    if preferred_backend == "whisper":
        whisper = import_whisper_with_patch()
        model = whisper.load_model(model_size)
        return "whisper", model

    if preferred_backend in ("auto", "faster-whisper"):
        try:
            from faster_whisper import WhisperModel

            model = WhisperModel(model_size, compute_type=compute_type)
            return "faster-whisper", model
        except Exception:
            if preferred_backend == "faster-whisper":
                raise

    whisper = import_whisper_with_patch()
    model = whisper.load_model(model_size)
    return "whisper", model


def materialize_transcript(segments) -> tuple[str, int]:
    parts = []
    count = 0
    for segment in segments:
        text = (segment.text or "").strip()
        if not text:
            continue
        parts.append(text)
        count += 1
    return "\n".join(parts).strip(), count


def transcribe_media(path: Path, backend_name: str, model) -> tuple[str, str, str]:
    if backend_name == "faster-whisper":
        segments, info = model.transcribe(str(path), beam_size=1, vad_filter=True)
        transcript, segment_count = materialize_transcript(segments)
        language = getattr(info, "language", None) or "unknown"
        duration = getattr(info, "duration", None)
        notes = f"backend={backend_name};model={DEFAULT_MODEL_SIZE};segments={segment_count};duration={duration}"
        return transcript, language, notes

    audio, sample_rate = decode_audio_with_av(path)
    result = model.transcribe(audio, language="hu", fp16=False, verbose=False)
    transcript = (result.get("text") or "").strip()
    language = result.get("language") or "unknown"
    segments = result.get("segments") or []
    notes = f"backend={backend_name};model={DEFAULT_MODEL_SIZE};segments={len(segments)};sample_rate={sample_rate}"
    return transcript, language, notes


def upsert_asr_extract(cur, artifact_id: str, transcript: str, language: str, quality_notes: str, timestamp: str):
    extract_id = hashlib.sha1(f"{artifact_id}:asr-transcript".encode("utf-8")).hexdigest()
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
            "asr-transcript",
            language,
            transcript,
            len(transcript),
            0.7,
            quality_notes,
            timestamp,
        ),
    )


def record_asr_run(
    cur,
    artifact_id: str,
    ingest_status: str,
    timestamp: str,
    error_summary: str | None = None,
    tooling: str = "faster-whisper-asr",
):
    status_key = ingest_status if not error_summary else f"{ingest_status}:{error_summary}"
    run_id = hashlib.sha1(f"{artifact_id}:asr:{tooling}:{status_key}".encode("utf-8")).hexdigest()
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
            "transcribed",
            ingest_status,
            tooling,
            None,
            error_summary,
            timestamp,
            timestamp,
        ),
    )


def persist_asr_result(
    media_module,
    artifact_ids: list[str],
    ingest_status: str,
    timestamp: str,
    backend_name: str,
    transcript: str | None = None,
    language: str | None = None,
    notes: str | None = None,
    error_summary: str | None = None,
):
    conn = media_module.open_db_connection(DB_PATH)
    try:
        cur = conn.cursor()
        for artifact_id in artifact_ids:
            if transcript:
                upsert_asr_extract(cur, artifact_id, transcript, language or "unknown", notes or "", timestamp)
            record_asr_run(
                cur,
                artifact_id,
                ingest_status,
                timestamp,
                error_summary=error_summary,
                tooling=f"{backend_name}-asr",
            )
        conn.commit()
    finally:
        conn.close()


def record_checkpoint(cur, media_module, metrics: dict[str, int]):
    checkpoint_id = hashlib.sha1(f"asr:{media_module.now_utc()}".encode("utf-8")).hexdigest()
    metrics_json = "{" + ", ".join(f'"{k}": {v}' for k, v in metrics.items()) + "}"
    cur.execute(
        """
        INSERT INTO ingest_checkpoints(checkpoint_id, checkpoint_name, source_root, metrics_json, created_at)
        VALUES (?, ?, ?, ?, ?)
        """,
        (checkpoint_id, "asr-transcript-pass", None, metrics_json, media_module.now_utc()),
    )


def main():
    media_module = load_media_module()
    timestamp = media_module.now_utc()
    read_conn = media_module.open_db_connection(DB_PATH)
    try:
        candidate_rows = iter_asr_candidates(read_conn.cursor())
        candidate_rows.sort(key=lambda row: ((row[5] or 0), row[2]))
        worklist = group_asr_candidates(candidate_rows)
    finally:
        read_conn.close()

    backend_name, model = load_asr_backend()
    extracted = 0
    failed = 0

    for absolute_path, artifact_ids in worklist:
        path = Path(absolute_path)
        if not path.exists() or not path.is_file():
            persist_asr_result(
                media_module,
                artifact_ids,
                "failed",
                timestamp,
                backend_name,
                error_summary="missing-file",
            )
            failed += len(artifact_ids)
            continue
        try:
            transcript, language, notes = transcribe_media(path, backend_name, model)
            if not transcript:
                persist_asr_result(
                    media_module,
                    artifact_ids,
                    "partial",
                    timestamp,
                    backend_name,
                    error_summary="empty-transcript",
                )
                continue
            persist_asr_result(
                media_module,
                artifact_ids,
                "completed",
                timestamp,
                backend_name,
                transcript=transcript,
                language=language,
                notes=notes,
            )
            extracted += len(artifact_ids)
        except Exception as exc:
            persist_asr_result(
                media_module,
                artifact_ids,
                "failed",
                timestamp,
                backend_name,
                error_summary=type(exc).__name__,
            )
            failed += len(artifact_ids)

    finalize_conn = media_module.open_db_connection(DB_PATH)
    try:
        finalize_cur = finalize_conn.cursor()
        coverage_rows = media_module.rebuild_coverage(finalize_cur)
        gap_rows = media_module.rebuild_gaps(finalize_cur)
        metrics = {
            "extracted": extracted,
            "failed": failed,
            "coverage_rows": coverage_rows,
            "gap_rows": gap_rows,
        }
        record_checkpoint(finalize_cur, media_module, metrics)
        finalize_conn.commit()
    finally:
        finalize_conn.close()

    print("ASR pass complete.")
    for key, value in metrics.items():
        print(f"  {key}={value}")


if __name__ == "__main__":
    main()
