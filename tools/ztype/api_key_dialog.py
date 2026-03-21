"""
Maszkolt OpenAI API kulcs bekérő ablak (Tkinter — a kulcs nem jelenik meg, chatbe nem kell írni).
"""

from __future__ import annotations

import tkinter as tk
from tkinter import messagebox, ttk


def prompt_api_key(title: str = "ZType – OpenAI API kulcs") -> str | None:
    """
    Modális ablak. Visszaadja a kulcsot, vagy None ha Mégse / X.
    A mező show='*' — nem látszik a kulcs.
    """
    result: dict[str, str | None] = {"key": None}

    root = tk.Tk()
    root.title(title)
    root.resizable(False, False)
    root.attributes("-topmost", True)

    frm = ttk.Frame(root, padding=16)
    frm.grid(row=0, column=0, sticky="nsew")

    ttk.Label(
        frm,
        text=(
            "Add meg az OpenAI API kulcsodat.\n"
            "A mező maszkolt — ne másold chatbe.\n"
            "A kulcs a Windows Credential Managerben tárolódik (keyring)."
        ),
        justify="left",
    ).grid(row=0, column=0, columnspan=2, sticky="w", pady=(0, 8))

    ttk.Label(frm, text="API kulcs:").grid(row=1, column=0, sticky="w")
    entry = ttk.Entry(frm, width=52, show="*")
    entry.grid(row=1, column=1, sticky="ew", padx=(8, 0))
    entry.focus()

    btn_row = ttk.Frame(frm)
    btn_row.grid(row=2, column=0, columnspan=2, pady=(12, 0))

    def on_ok() -> None:
        k = entry.get().strip()
        if len(k) < 20:
            messagebox.showerror("ZType", "A kulcs túl rövid vagy üres.", parent=root)
            return
        result["key"] = k
        root.destroy()

    def on_cancel() -> None:
        result["key"] = None
        root.destroy()

    ttk.Button(btn_row, text="Mentés és folytatás", command=on_ok).pack(side="left", padx=4)
    ttk.Button(btn_row, text="Mégse", command=on_cancel).pack(side="left", padx=4)

    root.bind("<Return>", lambda e: on_ok())
    root.bind("<Escape>", lambda e: on_cancel())

    root.mainloop()
    return result["key"]  # type: ignore[return-value]
