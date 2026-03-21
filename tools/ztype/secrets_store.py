"""
OpenAI API kulcs tárolás: először Windows Credential Manager (keyring), opcionális fájl.
A kulcsot NE küldd chatbe — első indításkor a program maszkolt mezőben kéri.
"""

from __future__ import annotations

import logging
import os
from pathlib import Path

log = logging.getLogger("ztype")

SERVICE_NAME = "ZType"
ACCOUNT_NAME = "openai_api_key"


def _data_dir() -> Path:
    return Path(os.environ.get("LOCALAPPDATA", str(Path.home()))) / "ZType"


def _legacy_file() -> Path:
    """Régi fallback (SimpleWhisperDictate / korai próbák) — ha létezik, beolvassuk."""
    return _data_dir() / "api_key.txt"


def load_api_key() -> str | None:
    """1) OPENAI_API_KEY környezet  2) keyring  3) legacy api_key.txt"""
    env = os.environ.get("OPENAI_API_KEY", "").strip()
    if env:
        return env

    try:
        import keyring

        k = keyring.get_password(SERVICE_NAME, ACCOUNT_NAME)
        if k and k.strip():
            return k.strip()
    except Exception as e:
        log.warning("Keyring olvasás sikertelen: %s", e)

    p = _legacy_file()
    if p.is_file():
        try:
            t = p.read_text(encoding="utf-8").strip()
            if t:
                log.info("API kulcs a legacy fájlból (fontos: töröld a fájlt, ha már keyringbe mentetted).")
                return t
        except OSError:
            pass

    return None


def save_api_key(key: str) -> None:
    key = key.strip()
    if not key:
        raise ValueError("Üres kulcs")

    try:
        import keyring

        keyring.set_password(SERVICE_NAME, ACCOUNT_NAME, key)
        log.info("API kulcs elmentve (Windows Credential Manager / keyring).")
    except Exception as e:
        log.warning("Keyring mentés sikertelen (%s), fájlba írunk (kevésbé ajánlott).", e)
        d = _data_dir()
        d.mkdir(parents=True, exist_ok=True)
        legacy = _legacy_file()
        legacy.write_text(key, encoding="utf-8")
        try:
            os.chmod(legacy, 0o600)
        except Exception:
            pass


def clear_stored_key() -> None:
    try:
        import keyring

        keyring.delete_password(SERVICE_NAME, ACCOUNT_NAME)
    except Exception:
        pass
    p = _legacy_file()
    if p.is_file():
        try:
            p.unlink()
        except OSError:
            pass
