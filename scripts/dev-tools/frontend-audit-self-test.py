#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Self-tests for the frontend/backend audit helper scripts.

Uses only Python stdlib so it can run on a clean Windows dev machine without
installing pytest or other dependencies.
"""
from __future__ import annotations

import importlib.util
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent.parent


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise AssertionError(f"Cannot load module: {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def test_contract_audit_skips_frontend_tests(contract_module) -> None:
    with tempfile.TemporaryDirectory() as tmp:
        tmp_root = Path(tmp)
        src = tmp_root / "frontend-react" / "src"
        write(src / "services" / "real.ts", "api.get('/real')\n")
        write(src / "services" / "real.test.ts", "api.get('/test-only')\n")
        write(src / "e2e" / "flow.spec.ts", "api.post('/spec-only')\n")

        original_roots = contract_module.FRONTEND_ROOTS
        try:
            contract_module.FRONTEND_ROOTS = [src]
            files = {path.name for path in contract_module.iter_source_files()}
        finally:
            contract_module.FRONTEND_ROOTS = original_roots

    assert "real.ts" in files
    assert "real.test.ts" not in files
    assert "flow.spec.ts" not in files


def test_contract_audit_classifies_nav_discrepancy(contract_module) -> None:
    endpoint = contract_module.Endpoint(
        "POST",
        "/nav/closings/validate-amount",
        "backend/src/main/java/hu/puzzleir/valuta/controller/NavClosingController.java",
        141,
        "NavClosingController",
    )
    classification = contract_module.classify_backend_reference(endpoint)
    assert classification.category == "ui-candidate/financial-contract-required"


def test_contract_audit_distinguishes_wrapper_only_from_ui_used(contract_module) -> None:
    with tempfile.TemporaryDirectory() as tmp:
        tmp_root = Path(tmp)
        api_dir = tmp_root / "frontend-react" / "src" / "services" / "api"
        page_dir = tmp_root / "frontend-react" / "src" / "pages"
        write(api_dir / "foo.ts", """
export const fooApi = {
  used: async () => api.get('/used-backend'),
  unused: async () => api.get('/unused-backend'),
}
""")
        write(page_dir / "FooPage.tsx", """
import { fooApi } from '../services/api/foo'
export default function FooPage() {
  void fooApi.used()
  return null
}
""")

        original_root = contract_module.ROOT
        original_roots = contract_module.FRONTEND_ROOTS
        original_api_dir = contract_module.FRONTEND_API_DIR
        try:
            contract_module.ROOT = tmp_root
            contract_module.FRONTEND_ROOTS = [tmp_root / "frontend-react" / "src"]
            contract_module.FRONTEND_API_DIR = api_dir
            calls, unresolved = contract_module.parse_frontend_calls()
            spans = contract_module.collect_api_method_spans()
            ui_calls = contract_module.production_ui_referenced_calls(calls, spans)
        finally:
            contract_module.ROOT = original_root
            contract_module.FRONTEND_ROOTS = original_roots
            contract_module.FRONTEND_API_DIR = original_api_dir

    assert unresolved == []
    assert {call.path for call in calls} == {"/used-backend", "/unused-backend"}
    assert {call.path for call in ui_calls} == {"/used-backend"}


def test_route_audit_follows_child_page_import(route_module) -> None:
    with tempfile.TemporaryDirectory() as tmp:
        tmp_root = Path(tmp)
        app = tmp_root / "frontend-react" / "src" / "App.tsx"
        parent = tmp_root / "frontend-react" / "src" / "pages" / "ParentPage.tsx"
        child = tmp_root / "frontend-react" / "src" / "pages" / "ChildPanel.tsx"
        write(app, """
import { lazy } from 'react'
const ParentPage = lazy(() => import('./pages/ParentPage'))
export default function App() {
  return <Route path="/parent" element={<ParentPage />} />
}
""")
        write(parent, """
import ChildPanel from './ChildPanel'
export default function ParentPage() {
  return <ChildPanel />
}
""")
        write(child, """
import { api } from '../services/api'
export default function ChildPanel() {
  void api.get('/child')
  return null
}
""")

        original_root = route_module.ROOT
        original_app = route_module.APP
        try:
            route_module.ROOT = tmp_root
            route_module.APP = app
            routed = route_module.parse()
        finally:
            route_module.ROOT = original_root
            route_module.APP = original_app

    assert len(routed) == 1
    assert routed[0].route_path == "/parent"
    assert routed[0].component == "ParentPage"
    assert routed[0].has_api_signal is True


def test_wrapper_audit_finds_unused_production_api_wrapper(wrapper_module) -> None:
    with tempfile.TemporaryDirectory() as tmp:
        tmp_root = Path(tmp)
        api_dir = tmp_root / "frontend-react" / "src" / "services" / "api"
        page_dir = tmp_root / "frontend-react" / "src" / "pages"
        write(api_dir / "foo.ts", """
export const usedApi = { list: async () => [] }
export const unusedApi = { list: async () => [] }
""")
        write(page_dir / "FooPage.tsx", """
import { usedApi } from '../services/api/foo'
export default function FooPage() {
  void usedApi.list()
  return null
}
""")
        write(page_dir / "FooPage.test.tsx", """
import { unusedApi } from '../services/api/foo'
void unusedApi.list()
""")

        original_root = wrapper_module.ROOT
        original_frontend = wrapper_module.FRONTEND
        original_api_dir = wrapper_module.API_DIR
        try:
            wrapper_module.ROOT = tmp_root
            wrapper_module.FRONTEND = tmp_root / "frontend-react" / "src"
            wrapper_module.API_DIR = api_dir
            wrappers = {wrapper.name: wrapper for wrapper in wrapper_module.audit()}
        finally:
            wrapper_module.ROOT = original_root
            wrapper_module.FRONTEND = original_frontend
            wrapper_module.API_DIR = original_api_dir

    assert "usedApi" in wrappers
    assert "unusedApi" in wrappers
    assert wrappers["usedApi"].ui_references == ("frontend-react/src/pages/FooPage.tsx",)
    assert wrappers["unusedApi"].ui_references == ()


def test_method_audit_ignores_test_only_method_references(method_module) -> None:
    with tempfile.TemporaryDirectory() as tmp:
        tmp_root = Path(tmp)
        api_dir = tmp_root / "frontend-react" / "src" / "services" / "api"
        page_dir = tmp_root / "frontend-react" / "src" / "pages"
        write(api_dir / "foo.ts", """
export const usedApi = {
  list: async () => [],
  create: async () => ({}),
}
""")
        write(page_dir / "FooPage.tsx", """
import { usedApi } from '../services/api/foo'
export default function FooPage() {
  void usedApi.list()
  return null
}
""")
        write(page_dir / "FooPage.test.tsx", """
import { usedApi } from '../services/api/foo'
void usedApi.create()
""")

        original_root = method_module.ROOT
        original_frontend = method_module.FRONTEND
        original_api_dir = method_module.API_DIR
        try:
            method_module.ROOT = tmp_root
            method_module.FRONTEND = tmp_root / "frontend-react" / "src"
            method_module.API_DIR = api_dir
            methods = {(method.wrapper, method.method): method for method in method_module.audit()}
        finally:
            method_module.ROOT = original_root
            method_module.FRONTEND = original_frontend
            method_module.API_DIR = original_api_dir

    assert ("usedApi", "list") in methods
    assert ("usedApi", "create") in methods
    assert methods[("usedApi", "list")].ui_references == ("frontend-react/src/pages/FooPage.tsx",)
    assert methods[("usedApi", "create")].ui_references == ()


def main() -> int:
    contract_module = load_module(
        "frontend_backend_contract_audit",
        ROOT / "scripts" / "dev-tools" / "frontend-backend-contract-audit.py",
    )
    route_module = load_module(
        "frontend_route_api_audit",
        ROOT / "scripts" / "dev-tools" / "frontend-route-api-audit.py",
    )
    wrapper_module = load_module(
        "frontend_api_wrapper_usage_audit",
        ROOT / "scripts" / "dev-tools" / "frontend-api-wrapper-usage-audit.py",
    )
    method_module = load_module(
        "frontend_api_method_usage_audit",
        ROOT / "scripts" / "dev-tools" / "frontend-api-method-usage-audit.py",
    )

    tests = [
        ("contract skips frontend test/spec files", lambda: test_contract_audit_skips_frontend_tests(contract_module)),
        ("contract classifies NAV discrepancy", lambda: test_contract_audit_classifies_nav_discrepancy(contract_module)),
        ("contract distinguishes wrapper-only from UI-used calls", lambda: test_contract_audit_distinguishes_wrapper_only_from_ui_used(contract_module)),
        ("route audit follows child page imports", lambda: test_route_audit_follows_child_page_import(route_module)),
        ("wrapper audit ignores test-only references", lambda: test_wrapper_audit_finds_unused_production_api_wrapper(wrapper_module)),
        ("method audit ignores test-only references", lambda: test_method_audit_ignores_test_only_method_references(method_module)),
    ]

    for name, test in tests:
        test()
        print(f"PASS {name}")

    print(f"frontend-audit-self-test: {len(tests)} passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
