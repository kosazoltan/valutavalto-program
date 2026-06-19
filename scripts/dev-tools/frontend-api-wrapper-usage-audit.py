#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
frontend-api-wrapper-usage-audit.py -- usage hints for exported frontend API wrappers.

This does not prove endpoint behavior. It answers a narrower question:
which exported `*Api` wrappers under frontend-react/src/services/api are not
referenced by production UI/app code outside services/api.

Exit:
  0 = report generated. Findings are INFO, not failures.
"""
from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = Path(__file__).resolve().parent.parent.parent
FRONTEND = ROOT / "frontend-react" / "src"
API_DIR = FRONTEND / "services" / "api"

SOURCE_SUFFIXES = {".ts", ".tsx", ".js", ".jsx"}
SKIP_DIR_NAMES = {"node_modules", "dist", "dist-electron", "build", "coverage", ".vite"}
SKIP_FILE_MARKERS = {".test.", ".spec.", ".stories."}
SKIP_FILE_NAMES = {"setup.ts", "setup.tsx", "setupTests.ts", "setupTests.tsx"}
API_EXPORT = re.compile(r"\bexport\s+const\s+(?P<name>[A-Za-z_$][\w$]*Api)\b")

KNOWN_INFRASTRUCTURE_OR_LEGACY = {
    # Generic/low-level or legacy aliases where direct UI usage is not required.
    "rateApi",
}


@dataclass(frozen=True)
class ApiWrapper:
    name: str
    source: Path
    line: int
    ui_references: tuple[str, ...]


def rel(path: Path) -> str:
    return str(path.resolve().relative_to(ROOT)).replace("\\", "/")


def is_skipped_file(path: Path) -> bool:
    return path.name in SKIP_FILE_NAMES or any(marker in path.name for marker in SKIP_FILE_MARKERS)


def iter_sources(root: Path) -> Iterable[Path]:
    for path in root.rglob("*"):
        if path.is_dir():
            continue
        if any(part in SKIP_DIR_NAMES for part in path.parts):
            continue
        if is_skipped_file(path):
            continue
        if path.suffix.lower() in SOURCE_SUFFIXES:
            yield path


def line_number(text: str, index: int) -> int:
    return text.count("\n", 0, index) + 1


def collect_api_exports() -> list[tuple[str, Path, int]]:
    exports: list[tuple[str, Path, int]] = []
    for path in iter_sources(API_DIR):
        if path.name == "index.ts":
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        for match in API_EXPORT.finditer(text):
            exports.append((match.group("name"), path, line_number(text, match.start())))
    return sorted(exports, key=lambda item: (item[0], rel(item[1]), item[2]))


def collect_ui_reference_files(api_name: str) -> tuple[str, ...]:
    pattern = re.compile(rf"\b{re.escape(api_name)}\b")
    refs: list[str] = []
    for path in iter_sources(FRONTEND):
        try:
            path.relative_to(API_DIR)
            continue
        except ValueError:
            pass
        text = path.read_text(encoding="utf-8", errors="replace")
        if pattern.search(text):
            refs.append(rel(path))
    return tuple(sorted(set(refs)))


def audit() -> list[ApiWrapper]:
    wrappers: list[ApiWrapper] = []
    for name, source, line in collect_api_exports():
        wrappers.append(ApiWrapper(name, source, line, collect_ui_reference_files(name)))
    return wrappers


def main() -> int:
    wrappers = audit()
    unused = [
        wrapper for wrapper in wrappers
        if not wrapper.ui_references and wrapper.name not in KNOWN_INFRASTRUCTURE_OR_LEGACY
    ]
    infrastructure = [
        wrapper for wrapper in wrappers
        if not wrapper.ui_references and wrapper.name in KNOWN_INFRASTRUCTURE_OR_LEGACY
    ]

    print("frontend-api-wrapper-usage-audit:")
    print(f"  exported Api wrappers: {len(wrappers)}")
    print(f"  wrappers referenced by production UI/app code: {len([w for w in wrappers if w.ui_references])}")
    print(f"  wrappers without production UI/app reference: {len(unused)}")
    print(f"  known infrastructure/legacy exceptions: {len(infrastructure)}")

    if unused:
        print("\nAPI WRAPPERS WITHOUT PRODUCTION UI/APP REFERENCE")
        for wrapper in unused:
            print(f"  {wrapper.name:36s} {rel(wrapper.source)}:{wrapper.line}")

    if infrastructure:
        print("\nKNOWN INFRASTRUCTURE/LEGACY WRAPPERS")
        for wrapper in infrastructure:
            print(f"  {wrapper.name:36s} {rel(wrapper.source)}:{wrapper.line}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
