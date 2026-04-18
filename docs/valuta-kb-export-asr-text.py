"""
Export local ASR transcripts to text files using ffmpeg's whisper filter.

This path avoids direct SQLite writes during transcription. It first produces
`.txt` transcript files under docs/knowledge/generated/asr-text/ and can be
ingested into the knowledge base afterwards.
"""
from __future__ import annotations

import hashlib
import os
import shutil
import subprocess
from pathlib import Path


WORKSPACE_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_MEDIA_ROOT = WORKSPACE_ROOT / "Felmérés"
DEFAULT_OUTPUT_ROOT = WORKSPACE_ROOT / "docs" / "knowledge" / "generated" / "asr-text"
DEFAULT_MODEL_PATH = WORKSPACE_ROOT / "tools" / "whisper-models" / "ggml-base.bin"
SUPPORTED_EXTENSIONS = {".m4a", ".mp3", ".wav", ".mp4", ".m4v", ".webm", ".ogg", ".flac", ".aac"}


def sha256_for_path(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def output_path_for_media(media_path: Path, output_root: Path) -> Path:
    safe_name = "".join(ch if ch.isalnum() else "_" for ch in media_path.stem).strip("_") or "audio"
    suffix = hashlib.sha1(str(media_path).encode("utf-8")).hexdigest()[:10]
    return output_root / f"{safe_name}-{suffix}.txt"


def iter_media_files(media_root: Path) -> list[Path]:
    files = [path for path in media_root.rglob("*") if path.is_file() and path.suffix.lower() in SUPPORTED_EXTENSIONS]
    files.sort(key=lambda path: (path.stat().st_size, str(path)))
    return files


def group_media_files(paths: list[Path]) -> list[tuple[Path, list[Path]]]:
    groups: dict[str, list[Path]] = {}
    ordered: list[str] = []
    for path in paths:
        key = sha256_for_path(path)
        if key not in groups:
            groups[key] = [path]
            ordered.append(key)
        else:
            groups[key].append(path)
    return [(groups[key][0], groups[key]) for key in ordered]


def run_ffmpeg_whisper(input_path: Path, output_path: Path, model_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    model_rel = os.path.relpath(model_path, WORKSPACE_ROOT).replace("\\", "/")
    output_rel = os.path.relpath(output_path, WORKSPACE_ROOT).replace("\\", "/")
    filter_args = (
        f"whisper=model={model_rel}:language=hu:queue=20:"
        f"use_gpu=false:destination={output_rel}:format=text"
    )
    command = [
        "ffmpeg",
        "-y",
        "-hide_banner",
        "-i",
        str(input_path),
        "-vn",
        "-af",
        filter_args,
        "-f",
        "null",
        "-",
    ]
    subprocess.run(command, cwd=WORKSPACE_ROOT, check=True)


def export_transcripts(
    media_root: Path = DEFAULT_MEDIA_ROOT,
    output_root: Path = DEFAULT_OUTPUT_ROOT,
    model_path: Path = DEFAULT_MODEL_PATH,
) -> list[Path]:
    if not media_root.exists():
        raise FileNotFoundError(f"Missing media root: {media_root}")
    if not model_path.exists():
        raise FileNotFoundError(f"Missing whisper model: {model_path}")

    created: list[Path] = []
    for primary_path, duplicates in group_media_files(iter_media_files(media_root)):
        primary_output = output_path_for_media(primary_path, output_root)
        run_ffmpeg_whisper(primary_path, primary_output, model_path)
        created.append(primary_output)
        primary_text = primary_output.read_text(encoding="utf-8", errors="replace")
        for duplicate in duplicates[1:]:
            duplicate_output = output_path_for_media(duplicate, output_root)
            duplicate_output.write_text(primary_text, encoding="utf-8")
            created.append(duplicate_output)
    return created


def main() -> None:
    created = export_transcripts()
    print("ASR text export complete.")
    print(f"  transcript_files={len(created)}")
    for path in created:
        print(f"  {path}")


if __name__ == "__main__":
    main()
