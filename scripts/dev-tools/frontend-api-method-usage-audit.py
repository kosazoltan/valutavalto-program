#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
frontend-api-method-usage-audit.py -- direct production usage hints for API wrapper methods.

This is intentionally narrower than a TypeScript compiler. It scans exported
`*Api` object literals under frontend-react/src/services/api and reports
methods that do not have a direct `wrapper.method` reference in production
frontend UI/app code outside services/api.

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
API_EXPORT = re.compile(r"\bexport\s+const\s+(?P<name>[A-Za-z_$][\w$]*Api)\s*=\s*\{")
TOP_LEVEL_KEY = re.compile(r"^\s*(?P<name>[A-Za-z_$][\w$]*)\s*:")

KNOWN_INFRASTRUCTURE_OR_LEGACY = {
    # Generic/low-level or compatibility wrappers where every method does not
    # need a direct production UI reference.
    "rateApi",
}


@dataclass(frozen=True)
class ApiMethod:
    wrapper: str
    method: str
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


def find_matching_brace(text: str, open_index: int) -> int | None:
    depth = 0
    in_string: str | None = None
    escape = False
    in_line_comment = False
    in_block_comment = False

    for index in range(open_index, len(text)):
        char = text[index]
        next_char = text[index + 1] if index + 1 < len(text) else ""

        if in_line_comment:
            if char == "\n":
                in_line_comment = False
            continue
        if in_block_comment:
            if char == "*" and next_char == "/":
                in_block_comment = False
            continue
        if in_string:
            if escape:
                escape = False
            elif char == "\\":
                escape = True
            elif char == in_string:
                in_string = None
            continue

        if char == "/" and next_char == "/":
            in_line_comment = True
            continue
        if char == "/" and next_char == "*":
            in_block_comment = True
            continue
        if char in {"'", '"', "`"}:
            in_string = char
            continue
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return index
    return None


def strip_strings_and_comments(line: str) -> str:
    result: list[str] = []
    in_string: str | None = None
    escape = False
    index = 0
    while index < len(line):
        char = line[index]
        next_char = line[index + 1] if index + 1 < len(line) else ""
        if in_string:
            if escape:
                escape = False
            elif char == "\\":
                escape = True
            elif char == in_string:
                in_string = None
            result.append(" ")
            index += 1
            continue
        if char == "/" and next_char == "/":
            break
        if char in {"'", '"', "`"}:
            in_string = char
            result.append(" ")
            index += 1
            continue
        result.append(char)
        index += 1
    return "".join(result)


def iter_top_level_method_keys(body: str, base_line: int) -> Iterable[tuple[str, int]]:
    curly = 0
    square = 0
    paren = 0
    for offset, line in enumerate(body.splitlines()):
        if curly == 0 and square == 0 and paren == 0:
            match = TOP_LEVEL_KEY.match(line)
            if match:
                name = match.group("name")
                if name not in {"if", "for", "while", "return"}:
                    yield name, base_line + offset
        sanitized = strip_strings_and_comments(line)
        curly += sanitized.count("{") - sanitized.count("}")
        square += sanitized.count("[") - sanitized.count("]")
        paren += sanitized.count("(") - sanitized.count(")")
        curly = max(curly, 0)
        square = max(square, 0)
        paren = max(paren, 0)


def collect_api_methods() -> list[tuple[str, str, Path, int]]:
    methods: list[tuple[str, str, Path, int]] = []
    for path in iter_sources(API_DIR):
        if path.name == "index.ts":
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        for export in API_EXPORT.finditer(text):
            wrapper = export.group("name")
            open_index = text.find("{", export.start())
            close_index = find_matching_brace(text, open_index)
            if close_index is None:
                continue
            body = text[open_index + 1:close_index]
            base_line = line_number(text, open_index + 1)
            for method, method_line in iter_top_level_method_keys(body, base_line):
                methods.append((wrapper, method, path, method_line))
    return sorted(methods, key=lambda item: (item[0], item[1], rel(item[2]), item[3]))


def collect_ui_reference_files(wrapper: str, method: str) -> tuple[str, ...]:
    pattern = re.compile(rf"\b{re.escape(wrapper)}\s*\.\s*{re.escape(method)}\b")
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


def audit() -> list[ApiMethod]:
    return [
        ApiMethod(wrapper, method, source, line, collect_ui_reference_files(wrapper, method))
        for wrapper, method, source, line in collect_api_methods()
    ]


def main() -> int:
    methods = audit()
    unused = [
        method for method in methods
        if not method.ui_references and method.wrapper not in KNOWN_INFRASTRUCTURE_OR_LEGACY
    ]
    infrastructure = [
        method for method in methods
        if not method.ui_references and method.wrapper in KNOWN_INFRASTRUCTURE_OR_LEGACY
    ]

    print("frontend-api-method-usage-audit:")
    print(f"  exported Api wrapper methods: {len(methods)}")
    print(f"  methods referenced by production UI/app code: {len([m for m in methods if m.ui_references])}")
    print(f"  methods without direct production UI/app reference: {len(unused)}")
    print(f"  known infrastructure/legacy method exceptions: {len(infrastructure)}")

    if unused:
        print("\nAPI WRAPPER METHODS WITHOUT DIRECT PRODUCTION UI/APP REFERENCE")
        for method in unused:
            print(f"  {method.wrapper}.{method.method:32s} {rel(method.source)}:{method.line}")

    if infrastructure:
        print("\nKNOWN INFRASTRUCTURE/LEGACY METHOD EXCEPTIONS")
        for method in infrastructure:
            print(f"  {method.wrapper}.{method.method:32s} {rel(method.source)}:{method.line}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
