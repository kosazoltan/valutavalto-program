#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
frontend-route-api-audit.py -- route/page level frontend-backend hint audit.

This is intentionally a lightweight heuristic companion to
frontend-backend-contract-audit.py:
  - parse lazy page imports from frontend-react/src/App.tsx
  - parse <Route path="..."> declarations and their rendered lazy component
  - report routed page files that do not contain a direct API/service signal

Exit:
  0 = report generated. Findings are INFO, not failures.
"""
from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path


sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = Path(__file__).resolve().parent.parent.parent
APP = ROOT / "frontend-react" / "src" / "App.tsx"

LAZY_IMPORT = re.compile(
    r"const\s+(?P<name>[A-Za-z_$][\w$]*)\s*=\s*lazy\(\(\)\s*=>\s*import\('(?P<path>[^']+)'\)\)",
)
ROUTE_START = re.compile(r"<Route\b")
ROUTE_PATH = re.compile(r'path="(?P<path>[^"]+)"')
API_SIGNAL = re.compile(
    r"(?:from\s+['\"][^'\"]*services/api|"
    r"\bapi\s*\.|"
    r"\bfetch\s*\(|"
    r"\baxios\s*\.|"
    r"\b[A-Za-z0-9_]+Api\s*\.|"
    r"\b[A-Za-z0-9_]+Service\s*\.)",
)
LOCAL_IMPORT = re.compile(
    r"import\s+(?:type\s+)?(?:[\w${}\s,*]+?\s+from\s+)?['\"](?P<path>\.{1,2}/[^'\"]+)['\"]",
)

KNOWN_NAVIGATION_OR_SHELL = {
    "CashierMainMenu",
    "CentralWorkstationPage",
    "ClosingDenominationMenuPage",
    "NotFoundPage",
    "OtherTasksPage",
    "ReportsPage",
    "SettingsPage",
    "TreasuryLayout",
}

KNOWN_LOCAL_OR_EXTERNAL_ONLY = {
    "CustomerDisplayPage",  # Electron IPC/idle display, not a backend CRUD UI.
}


@dataclass(frozen=True)
class RoutedPage:
    route_path: str
    component: str
    source: Path | None
    has_api_signal: bool
    note: str


def rel(path: Path) -> str:
    return str(path.resolve().relative_to(ROOT)).replace("\\", "/")


def route_blocks(text: str) -> list[str]:
    blocks: list[str] = []
    for match in ROUTE_START.finditer(text):
        start = match.start()
        end = text.find("/>", start)
        if end < 0:
            continue
        blocks.append(text[start:end + 2])
    return blocks


def resolve_lazy_import(raw: str) -> Path | None:
    if not raw.startswith("./"):
        return None
    base = APP.parent / raw[2:]
    for suffix in (".tsx", ".ts", ".jsx", ".js"):
        candidate = base.with_suffix(suffix)
        if candidate.exists():
            return candidate
    index = base / "index.tsx"
    if index.exists():
        return index
    return None


def resolve_local_import(source: Path, raw: str) -> Path | None:
    base = (source.parent / raw).resolve()
    for suffix in (".tsx", ".ts", ".jsx", ".js"):
        candidate = base.with_suffix(suffix)
        if candidate.exists() and candidate.is_relative_to(ROOT):
            return candidate
    index = base / "index.tsx"
    if index.exists() and index.is_relative_to(ROOT):
        return index
    return None


def has_api_signal_recursive(source: Path, depth: int = 4, seen: set[Path] | None = None) -> bool:
    if seen is None:
        seen = set()
    source = source.resolve()
    if source in seen or depth < 0:
        return False
    seen.add(source)

    source_text = source.read_text(encoding="utf-8", errors="replace")
    if API_SIGNAL.search(source_text):
        return True

    for match in LOCAL_IMPORT.finditer(source_text):
        child = resolve_local_import(source, match.group("path"))
        if child is None:
            continue
        if "frontend-react/src/pages" not in str(child).replace("\\", "/"):
            continue
        if has_api_signal_recursive(child, depth - 1, seen):
            return True
    return False


def parse() -> list[RoutedPage]:
    text = APP.read_text(encoding="utf-8", errors="replace")
    lazy_sources = {
        match.group("name"): resolve_lazy_import(match.group("path"))
        for match in LAZY_IMPORT.finditer(text)
    }

    routed: list[RoutedPage] = []
    for block in route_blocks(text):
        path_match = ROUTE_PATH.search(block)
        if not path_match:
            continue
        route_path = path_match.group("path")
        components = [name for name in lazy_sources if re.search(rf"<{re.escape(name)}(?:\s|/|>)", block)]
        for component in components:
            source = lazy_sources[component]
            if source is None:
                routed.append(RoutedPage(route_path, component, None, False, "lazy source not resolved"))
                continue
            has_signal = has_api_signal_recursive(source)
            note = ""
            if component in KNOWN_NAVIGATION_OR_SHELL:
                note = "known navigation/shell route"
            elif component in KNOWN_LOCAL_OR_EXTERNAL_ONLY:
                note = "known local/electron/external route"
            routed.append(RoutedPage(route_path, component, source, has_signal, note))
    return routed


def main() -> int:
    routed = parse()
    missing = [
        item for item in routed
        if not item.has_api_signal
        and item.component not in KNOWN_NAVIGATION_OR_SHELL
        and item.component not in KNOWN_LOCAL_OR_EXTERNAL_ONLY
    ]
    shell = [item for item in routed if item.note]

    print("frontend-route-api-audit:")
    print(f"  routed lazy pages: {len(routed)}")
    print(f"  routes without direct API/service signal: {len(missing)}")
    print(f"  known shell/local exceptions: {len(shell)}")

    if missing:
        print("\nROUTES WITHOUT DIRECT API/SERVICE SIGNAL")
        for item in sorted(missing, key=lambda x: (x.route_path, x.component)):
            source = rel(item.source) if item.source else "<unresolved>"
            print(f"  {item.route_path:35s} {item.component:35s} {source}")

    if shell:
        print("\nKNOWN SHELL/LOCAL ROUTES")
        for item in sorted(shell, key=lambda x: (x.route_path, x.component)):
            source = rel(item.source) if item.source else "<unresolved>"
            print(f"  {item.route_path:35s} {item.component:35s} {source} [{item.note}]")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
