#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
openapi-spec-audit.py -- OpenAPI/Swagger YAML spec statikus ellenorzese.

Replaces: AI "is the API spec complete?" kerdesek + Spectral/openapi-validator.

Technika: PyYAML / json parse + strukturalis ellenorzes (kiszolgalo nelkul).

Keres:
  - Hianyzo 401/403 valasz vedett endpointokon
  - Hianyzo 500 valasz (minden endpointnak kellene)
  - Leiras nelkuli operaciok (description/summary hianyzik)
  - Sikeres valasz (2xx) nelkuli endpoint
  - application/json nelkuli request body
  - Path parameter, ami nincs deklaralva az operacioban

Spec helye: backend/src/main/resources/openapi*.yaml
             (vagy projekt gyoker openapi.yaml)

Usage:
  python scripts/dev-tools/openapi-spec-audit.py
  python scripts/dev-tools/openapi-spec-audit.py --spec path/to/openapi.yaml

Exit: 0 = clean, 1 = spec hianyossagok
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent

try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False

SPEC_CANDIDATES = [
    "backend/src/main/resources/openapi.yaml",
    "backend/src/main/resources/openapi.json",
    "openapi.yaml",
    "openapi.json",
    "swagger.yaml",
    "swagger.json",
]

PATH_PARAM = re.compile(r'\{(\w+)\}')
VERBS = ("get", "post", "put", "delete", "patch", "options", "head")


def find_spec() -> Path | None:
    for candidate in SPEC_CANDIDATES:
        p = ROOT / candidate
        if p.exists():
            return p
    return None


def load_spec(path: Path) -> dict | None:
    content = path.read_text(encoding="utf-8", errors="replace")
    if path.suffix in (".yaml", ".yml"):
        if not HAS_YAML:
            print("  [WARN] PyYAML nincs telepitve -- pip install pyyaml")
            return None
        return yaml.safe_load(content)
    return json.loads(content)


def audit_spec(spec: dict) -> list[str]:
    issues = []
    paths  = spec.get("paths") or spec.get("openapi", {})
    if not paths:
        issues.append("  [NO-PATHS]  Nincsenek paths deklaralva a specben")
        return issues

    for path, path_item in paths.items():
        path_params = set(PATH_PARAM.findall(path))

        for verb in VERBS:
            op = path_item.get(verb)
            if not op:
                continue

            label = f"{verb.upper()} {path}"

            # Missing summary / description
            if not op.get("summary") and not op.get("description"):
                issues.append(
                    f"  [NO-DESC]     {label}  -- nincs summary/description")

            # Check responses
            responses = op.get("responses") or {}
            status_codes = set(str(s) for s in responses)

            # No 2xx success response
            has_success = any(s.startswith("2") or s == "default" for s in status_codes)
            if not has_success:
                issues.append(
                    f"  [NO-SUCCESS]  {label}  -- nincs 2xx sikeres valasz")

            # Check if secured (has security at op or global level)
            secured = bool(op.get("security") or spec.get("security"))
            if secured:
                if "401" not in status_codes and "403" not in status_codes:
                    issues.append(
                        f"  [NO-AUTH-RSP] {label}  -- vedett endpoint, de nincs 401/403")

            # No 500 response (should be documented)
            if "500" not in status_codes and "5XX" not in status_codes:
                issues.append(
                    f"  [NO-500]      {label}  -- 500 szerver-hiba nincs dokumentalva")

            # Request body without application/json
            rb = op.get("requestBody")
            if rb:
                content_types = list((rb.get("content") or {}).keys())
                if content_types and "application/json" not in content_types:
                    issues.append(
                        f"  [NO-JSON]     {label}  -- requestBody content: {content_types}")

            # Path params declared in path but not in parameters
            op_params = {p.get("name") for p in (op.get("parameters") or [])
                         if p.get("in") == "path"}
            missing_params = path_params - op_params
            if missing_params:
                issues.append(
                    f"  [PARAM-GAP]   {label}  -- path param nincs deklaralva: "
                    f"{', '.join(missing_params)}")

    return issues


def main():
    args = sys.argv[1:]
    spec_path = None
    i = 0
    while i < len(args):
        if args[i] == "--spec" and i + 1 < len(args):
            spec_path = Path(args[i + 1]); i += 2
        else:
            i += 1

    if spec_path is None:
        spec_path = find_spec()

    if spec_path is None:
        print("openapi-spec-audit: Nem talalhato OpenAPI spec fajl.")
        print("  Hely: backend/src/main/resources/openapi.yaml")
        print("  Vagy: python openapi-spec-audit.py --spec path/to/spec.yaml")
        sys.exit(0)

    print(f"openapi-spec-audit: {spec_path.relative_to(ROOT)}")
    spec = load_spec(spec_path)
    if spec is None:
        sys.exit(1)

    issues = audit_spec(spec)
    print(f"  {len(issues)} problema\n")

    if not issues:
        print("  OK -- spec hianytalannak tunik")
        sys.exit(0)

    for cat in ("NO-DESC", "NO-SUCCESS", "NO-AUTH-RSP", "NO-500",
                "NO-JSON", "PARAM-GAP", "NO-PATHS"):
        group = [x for x in issues if f"[{cat}]" in x]
        if group:
            print(f"  [{cat}] ({len(group)})")
            for iss in group[:8]:
                print(iss)
            if len(group) > 8:
                print(f"    ... ({len(group) - 8} tovabb)")
            print()

    sys.exit(1)


if __name__ == "__main__":
    main()
