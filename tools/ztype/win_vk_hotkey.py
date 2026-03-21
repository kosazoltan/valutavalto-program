"""
Windows: globális hotkey VK_ADD (0x6B) = fizikai billentyűzet NumPad +.
RegisterHotKey — a billentyű nem jut el a szerkesztőnek (nem íródik be '+').

A 'keyboard' csomag 'numpad +' stringje gyakran nem egyezik a tényleges eseménnyel
(Num Lock mellett), ezért ez a modul megbízhatóbb.
"""

from __future__ import annotations

import ctypes
import logging
import os
import random
import sys
import threading
from ctypes import wintypes

log = logging.getLogger("ztype")

user32 = ctypes.WinDLL("user32", use_last_error=True)
kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)

WM_HOTKEY = 0x0312
VK_ADD = 0x6B  # Numeric keypad +
MOD_NOREPEAT = 0x4000
HWND_MESSAGE = -3

LRESULT = ctypes.c_longlong if sys.maxsize > 2**32 else ctypes.c_long
WNDPROC = ctypes.WINFUNCTYPE(LRESULT, wintypes.HWND, wintypes.UINT, wintypes.WPARAM, wintypes.LPARAM)


class MSG(ctypes.Structure):
    _fields_ = [
        ("hwnd", wintypes.HWND),
        ("message", wintypes.UINT),
        ("wParam", wintypes.WPARAM),
        ("lParam", wintypes.LPARAM),
        ("time", wintypes.DWORD),
        ("pt", wintypes.POINT),
    ]


class WNDCLASSW(ctypes.Structure):
    _fields_ = [
        ("style", wintypes.UINT),
        ("lpfnWndProc", WNDPROC),
        ("cbClsExtra", ctypes.c_int),
        ("cbWndExtra", ctypes.c_int),
        ("hInstance", wintypes.HINSTANCE),
        ("hIcon", wintypes.HANDLE),
        ("hCursor", wintypes.HANDLE),
        ("hbrBackground", wintypes.HANDLE),
        ("lpszMenuName", wintypes.LPCWSTR),
        ("lpszClassName", wintypes.LPCWSTR),
    ]


_cb_holder: dict[str, object] = {"fn": None}


@WNDPROC
def _wnd_proc(hwnd, msg, wparam, lparam):
    if msg == WM_HOTKEY:
        fn = _cb_holder.get("fn")
        if callable(fn):
            try:
                fn()
            except Exception:
                log.exception("NumPad+ hotkey callback")
        return 0
    return user32.DefWindowProcW(hwnd, msg, wparam, lparam)


def start_vk_add_hotkey(callback, hotkey_id: int = 1) -> bool:
    """
    Háttérszál: üzenetablak + RegisterHotKey(VK_ADD).
    True, ha a NumPad + regisztrálva van.
    """
    if os.name != "nt":
        return False

    _cb_holder["fn"] = callback

    hinst = kernel32.GetModuleHandleW(None)
    # Egyedi osztálynév, hogy ne ütközzön korábbi (nem takarított) regisztrációval
    class_name = f"ZTypeHK_{os.getpid()}_{random.randint(0, 999_999)}"

    wc = WNDCLASSW()
    wc.lpfnWndProc = _wnd_proc
    wc.hInstance = hinst
    wc.lpszClassName = class_name

    if not user32.RegisterClassW(ctypes.byref(wc)):
        err = ctypes.get_last_error()
        if err != 1410:
            log.error("RegisterClassW: %s", err)
            return False

    hwnd = user32.CreateWindowExW(
        0,
        class_name,
        "ZType",
        0,
        0,
        0,
        0,
        0,
        wintypes.HWND(HWND_MESSAGE),
        None,
        hinst,
        None,
    )
    if not hwnd:
        log.error("CreateWindowExW: %s", ctypes.get_last_error())
        return False

    if not user32.RegisterHotKey(hwnd, hotkey_id, MOD_NOREPEAT, VK_ADD):
        err = ctypes.get_last_error()
        log.error(
            "RegisterHotKey (VK_ADD / NumPad+) sikertelen, hiba=%s. "
            "Lehet, más program már lefoglalta a NumPad +-ot.",
            err,
        )
        user32.DestroyWindow(hwnd)
        return False

    log.info("Hotkey: NumPad + (Win32 RegisterHotKey, VK_ADD) — a + nem kerül a szövegmezőbe.")

    def message_loop() -> None:
        msg = MSG()
        try:
            while user32.GetMessageW(ctypes.byref(msg), None, 0, 0) > 0:
                user32.TranslateMessage(ctypes.byref(msg))
                user32.DispatchMessageW(ctypes.byref(msg))
        finally:
            user32.UnregisterHotKey(hwnd, hotkey_id)
            user32.DestroyWindow(hwnd)
            user32.UnregisterClassW(class_name, hinst)

    threading.Thread(target=message_loop, daemon=True, name="ZTypeWinHotkey").start()
    return True
