"""
ZType — diktálás Windowsra: OpenAI Whisper API, kizárólag magyar (hu).
Hotkey: NumPad + — első: felvétel, második: leállítás + szöveg beillesztése (Ctrl+V).

API kulcs: első indításkor maszkolt ablak (chatbe ne írd); tárolás: Windows Credential Manager (keyring).
Opcionális: OPENAI_API_KEY környezeti változó (felülír mindent).
"""

from __future__ import annotations

import io
import logging
import os
import sys
import threading
import time
import wave
from pathlib import Path

import keyboard
import numpy as np
import pyperclip
import sounddevice as sd
from openai import OpenAI
from PIL import Image, ImageDraw
import pystray

from api_key_dialog import prompt_api_key
from secrets_store import load_api_key, save_api_key

# win_vk_hotkey hiánya (régi telepítés) ne omlassza le az appot
if os.name == "nt":
    try:
        from win_vk_hotkey import start_vk_add_hotkey
    except ImportError:

        def start_vk_add_hotkey(_callback, _hotkey_id: int = 1) -> bool:
            return False

else:

    def start_vk_add_hotkey(_callback, _hotkey_id: int = 1) -> bool:
        return False


APP_NAME = "ZType"
SAMPLE_RATE = int(os.environ.get("ZTYPE_SAMPLE_RATE", "16000"))
OPENAI_MODEL = os.environ.get("ZTYPE_WHISPER_MODEL", "whisper-1")
LANGUAGE = "hu"
# Alap: Win32 VK_ADD (NumPad +). Egyéni: pl. ZTYPE_HOTKEY=insert → keyboard könyvtár
HOTKEY = os.environ.get("ZTYPE_HOTKEY", "numpad +")

# Win32 RegisterHotKey NumPad +-hoz (1 = igen, 0 = csak keyboard csomag)
_USE_WIN32_NUMPAD = os.name == "nt" and os.environ.get("ZTYPE_HOTKEY_WIN32", "1") not in ("0", "false", "no")

LOG_DIR = Path(os.environ.get("LOCALAPPDATA", str(Path.home()))) / "ZType"
LOG_FILE = LOG_DIR / "ztype.log"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE, encoding="utf-8"),
        logging.StreamHandler(sys.stdout),
    ],
)
log = logging.getLogger("ztype")


def float32_to_wav_bytes(mono_float: np.ndarray, sample_rate: int) -> bytes:
    mono_float = np.clip(mono_float, -1.0, 1.0)
    pcm = (mono_float * 32767.0).astype(np.int16)
    buf = io.BytesIO()
    with wave.open(buf, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        wf.writeframes(pcm.tobytes())
    return buf.getvalue()


class Recorder:
    def __init__(self) -> None:
        self._frames: list[np.ndarray] = []
        self._stream: sd.InputStream | None = None
        self._lock = threading.Lock()

    def _callback(self, indata, _frames, _time, status) -> None:
        if status:
            log.warning("sounddevice status: %s", status)
        with self._lock:
            self._frames.append(indata.copy())

    def start(self) -> None:
        with self._lock:
            self._frames.clear()
        self._stream = sd.InputStream(
            samplerate=SAMPLE_RATE,
            channels=1,
            dtype="float32",
            callback=self._callback,
        )
        self._stream.start()

    def stop(self) -> np.ndarray:
        if self._stream:
            self._stream.stop()
            self._stream.close()
            self._stream = None
        with self._lock:
            if not self._frames:
                return np.array([], dtype=np.float32)
            return np.concatenate(self._frames, axis=0).flatten()


class ZTypeApp:
    def __init__(self, api_key: str) -> None:
        self._lock = threading.Lock()
        self._state = "idle"
        self._recorder = Recorder()
        self._client = OpenAI(api_key=api_key.strip())
        self._tray_icon: pystray.Icon | None = None

    def _set_state(self, s: str) -> None:
        with self._lock:
            self._state = s
        log.info("állapot: %s", s)
        self._update_tray_tooltip()

    def _update_tray_tooltip(self) -> None:
        if not self._tray_icon:
            return
        tips = {
            "idle": f"{APP_NAME}: NumPad + felvétel / leállítás + beillesztés",
            "recording": f"{APP_NAME}: FELVÉTEL… NumPad + leállítás",
            "transcribing": f"{APP_NAME}: Átírás…",
        }
        with self._lock:
            t = tips.get(self._state, APP_NAME)

        def _run() -> None:
            try:
                self._tray_icon.title = t  # type: ignore[union-attr]
            except Exception:
                pass

        threading.Thread(target=_run, daemon=True).start()

    def toggle(self) -> None:
        with self._lock:
            if self._state == "transcribing":
                log.info("Átírás alatt — kihagyva.")
                return
            if self._state == "idle":
                self._state = "recording"
                st = "start"
            else:
                self._state = "transcribing"
                st = "stop"

        if st == "start":
            log.info("Felvétel indul (magyar, %s Hz).", SAMPLE_RATE)
            self._update_tray_tooltip()
            try:
                self._recorder.start()
            except Exception:
                log.exception("Mikrofon hiba")
                self._set_state("idle")
            return

        log.info("Felvétel leállítása…")
        self._update_tray_tooltip()
        audio = self._recorder.stop()
        if audio.size < SAMPLE_RATE * 0.3:
            log.warning("Túl rövid felvétel, nincs küldés.")
            self._set_state("idle")
            return

        def job() -> None:
            try:
                wav_bytes = float32_to_wav_bytes(audio, SAMPLE_RATE)
                t0 = time.perf_counter()
                bio = io.BytesIO(wav_bytes)
                bio.name = "ztype.wav"
                tr = self._client.audio.transcriptions.create(
                    model=OPENAI_MODEL,
                    file=bio,
                    language=LANGUAGE,
                )
                text = (tr.text or "").strip()
                elapsed = time.perf_counter() - t0
                log.info("Whisper kész (%.1f s): %s", elapsed, text[:200] if text else "(üres)")
                if text:
                    pyperclip.copy(text)
                    time.sleep(0.05)
                    keyboard.send("ctrl+v")
            except Exception:
                log.exception("Átírás hiba")
            finally:
                self._set_state("idle")

        threading.Thread(target=job, daemon=True).start()

    def _change_api_key(self, icon: pystray.Icon | None = None, _item=None) -> None:
        def _dlg() -> None:
            k = prompt_api_key(f"{APP_NAME} – új OpenAI API kulcs")
            if k:
                try:
                    save_api_key(k)
                    with self._lock:
                        self._client = OpenAI(api_key=k.strip())
                    log.info("API kulcs frissítve — a következő diktálástól érvényes.")
                except Exception:
                    log.exception("Kulcs mentés hiba")

        threading.Thread(target=_dlg, daemon=True).start()

    def _quit(self, icon: pystray.Icon | None = None, _item=None) -> None:
        log.info("Kilépés.")
        if icon:
            icon.stop()
        os._exit(0)

    def _build_tray_image(self) -> Image.Image:
        img = Image.new("RGBA", (64, 64), (20, 24, 32, 255))
        d = ImageDraw.Draw(img)
        d.rounded_rectangle((8, 8, 56, 56), radius=10, outline=(0, 180, 220, 255), width=3)
        d.text((20, 18), "Z", fill=(0, 220, 255, 255))
        return img

    def run(self) -> None:
        LOG_DIR.mkdir(parents=True, exist_ok=True)
        log.info("%s indul. Hotkey: %s | nyelv: %s", APP_NAME, HOTKEY, LANGUAGE)

        def _register_hotkey() -> None:
            numpad_aliases = {"numpad +", "numpad+", "vk_add", "numadd", "default", ""}
            want_numpad = HOTKEY.strip().lower() in numpad_aliases
            if _USE_WIN32_NUMPAD and want_numpad:
                if start_vk_add_hotkey(self.toggle):
                    return
                log.warning("Win32 NumPad+ nem elérhető — visszaesés a keyboard csomagra.")
            keyboard.add_hotkey(HOTKEY, self.toggle, suppress=True, trigger_on_release=False)
            log.info("Hotkey (keyboard csomag): %r", HOTKEY)

        menu = pystray.Menu(
            pystray.MenuItem("OpenAI kulcs megváltoztatása…", self._change_api_key),
            pystray.Menu.SEPARATOR,
            pystray.MenuItem("Kilépés", self._quit),
        )
        self._tray_icon = pystray.Icon(
            "ztype",
            self._build_tray_image(),
            APP_NAME,
            menu,
        )

        _register_hotkey()
        self._tray_icon.run()


def ensure_api_key() -> str:
    k = load_api_key()
    if k:
        return k
    k = prompt_api_key(f"{APP_NAME} – OpenAI API kulcs (első beállítás)")
    if not k:
        log.error("Nincs API kulcs — kilépés.")
        raise SystemExit(1)
    save_api_key(k)
    return k


def _set_windows_app_id() -> None:
    """Tálcán / feladatváltón jobb felismerhetőség (nem mindig változtatja a Task Manager nevet)."""
    if os.name != "nt":
        return
    try:
        import ctypes

        ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID("ZType.Dictation.1.0")
    except Exception:
        pass


def _fatal_startup(exc: BaseException) -> None:
    """pythonw.exe alatt nincs konzol — MessageBox + fájl, különben „láthatatlanul” kilép."""
    import traceback

    tb = traceback.format_exc()
    try:
        LOG_DIR.mkdir(parents=True, exist_ok=True)
        crash = LOG_DIR / "ztype-crash.log"
        crash.write_text(tb, encoding="utf-8")
    except OSError:
        crash = LOG_DIR / "ztype-crash.log"

    msg = (
        f"A ZType nem fut tovább, vagy azonnal leállt.\n\n"
        f"Hiba: {exc!s}\n\n"
        f"Részletes napló:\n{crash}\n\n"
        f"Feladatkezelőben a folyamat neve általában:\n"
        f"„Python” vagy „pythonw.exe” (nem „ZType”).\n"
        f"Indítsd a „ZType (hibakeresés)” parancsikont,\n"
        f"vagy futtasd: ZType-debug.cmd — ott látszik a hiba."
    )
    if os.name == "nt":
        try:
            import ctypes

            ctypes.windll.user32.MessageBoxW(None, msg[:2000], "ZType — indulási hiba", 0x10)
        except Exception:
            print(msg, file=sys.stderr)
    else:
        print(msg, file=sys.stderr)
    raise SystemExit(1) from exc


def main() -> None:
    try:
        LOG_DIR.mkdir(parents=True, exist_ok=True)
        _set_windows_app_id()
        key = ensure_api_key()
        ZTypeApp(key).run()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as e:
        _fatal_startup(e)
