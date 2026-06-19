#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
endpoint-audit.py — Lista az összes Spring REST végpontot + effektív auth-ellenőrzés.

Replaces: AI review "missing @PreAuthorize" findings + manual SecurityConfig audit.

Usage:
  python scripts/dev-tools/endpoint-audit.py
  python scripts/dev-tools/endpoint-audit.py --missing-only
  python scripts/dev-tools/endpoint-audit.py --csv

Exit: 0 = all secured, 1 = unsecured endpoints found, 2 = tool error
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
import csv
import io
from pathlib import Path
from dataclasses import dataclass, field

ROOT       = Path(__file__).resolve().parent.parent.parent
CTRL_DIR   = ROOT / "backend" / "src" / "main" / "java"
SECURITY_CONFIG = (
    CTRL_DIR / "hu" / "puzzleir" / "valuta" / "config" / "SecurityConfig.java"
)

HTTP_ANNOTATIONS = re.compile(
    r'@(GetMapping|PostMapping|PutMapping|DeleteMapping|PatchMapping|RequestMapping)'
    r'\s*(?:\([^)]*\))?'
)
PATH_VALUE = re.compile(r'@\w+Mapping\s*\(\s*(?:value\s*=\s*)?["\']([^"\']+)["\']')
SECURITY_ANNOTATIONS = re.compile(
    r'@(PreAuthorize|RolesAllowed|Secured|PermitAll|DenyAll|AnonymousAccess|Anonymous)'
)
CLASS_MAPPING = re.compile(r'@RequestMapping\s*\(\s*["\']([^"\']+)["\']')
CLASS_NAME    = re.compile(r'public\s+class\s+(\w+)')
PERMIT_ALL_BLOCK = re.compile(
    r'\.requestMatchers\s*\((.*?)\)\s*\.permitAll\s*\(\s*\)',
    re.S,
)
STRING_LITERAL = re.compile(r'"([^"]+)"')


@dataclass
class Endpoint:
    controller: str
    method_name: str
    http_method: str
    path: str
    security: str
    line: int
    file: str


def parse_controller(java_file: Path) -> list[Endpoint]:
    content = java_file.read_text(encoding="utf-8", errors="replace")
    lines   = content.splitlines()
    results: list[Endpoint] = []

    # Class-level base path
    base_path = ""
    for m in CLASS_MAPPING.finditer(content):
        base_path = m.group(1).rstrip("/")
        break

    ctrl_name = java_file.stem

    # Class-level security annotation (covers all methods)
    class_security: str = ""
    in_class_header = True
    for i, line in enumerate(lines):
        stripped = line.strip()
        if in_class_header:
            for m in SECURITY_ANNOTATIONS.finditer(stripped):
                class_security = m.group(1)
            # Class body starts — stop looking for class-level annotations
            if re.search(r'\bclass\s+\w+', stripped) and "{" in stripped:
                in_class_header = False
                break
            if re.search(r'\bclass\s+\w+', stripped):
                in_class_header = False  # next { will start body

    # Walk line by line; only collect method annotations INSIDE the class body
    i          = 0
    class_depth = 0   # 0 = before class body, 1+ = inside
    pending_security: list[str] = []
    pending_http: list[tuple[str, str]] = []

    while i < len(lines):
        raw  = lines[i]
        line = raw.strip()

        # Track when we enter the class body
        if class_depth == 0:
            if re.search(r'\bclass\s+\w+', line):
                # class declaration line — count opening brace
                class_depth += raw.count("{") - raw.count("}")
            i += 1
            continue

        class_depth += raw.count("{") - raw.count("}")

        # Method-level security annotations
        for m in SECURITY_ANNOTATIONS.finditer(line):
            pending_security.append(m.group(1))

        # HTTP mapping annotations (method-level only — class body depth >= 1)
        for m in HTTP_ANNOTATIONS.finditer(line):
            http_verb = m.group(1).replace("Mapping", "").upper()
            if http_verb == "REQUEST":
                http_verb = "ANY"
            path_m = PATH_VALUE.search(line)
            ep_suffix = path_m.group(1) if path_m else ""
            endpoint_path = (base_path.rstrip("/") + "/" + ep_suffix.lstrip("/")).replace("//", "/")
            if not ep_suffix and not endpoint_path:
                endpoint_path = base_path or "/"
            pending_http.append((http_verb, endpoint_path or base_path or "/"))

        # Method declaration — flush pending
        if pending_http and re.search(r'\bpublic\b.*\(', line) and not line.startswith("//"):
            method_match = re.search(r'\bpublic\b\s+\S+\s+(\w+)\s*\(', line)
            method_name  = method_match.group(1) if method_match else "?"
            if pending_security:
                sec_label = ", ".join(pending_security)
            elif class_security:
                sec_label = f"{class_security} (class)"
            else:
                sec_label = "NONE"
            for http_verb, ep_path in pending_http:
                results.append(Endpoint(
                    controller=ctrl_name,
                    method_name=method_name,
                    http_method=http_verb,
                    path=ep_path,
                    security=sec_label,
                    line=i + 1,
                    file=str(java_file.relative_to(ROOT)),
                ))
            pending_security = []
            pending_http     = []

        # Reset pending on blank lines
        if not line and not pending_http:
            pending_security = []

        i += 1

    return results


def load_security_config() -> tuple[list[str], bool]:
    if not SECURITY_CONFIG.exists():
        return [], False
    content = SECURITY_CONFIG.read_text(encoding="utf-8", errors="replace")
    permit_all_patterns: list[str] = []
    for block in PERMIT_ALL_BLOCK.findall(content):
        permit_all_patterns.extend(STRING_LITERAL.findall(block))
    compact = re.sub(r"\s+", "", content)
    default_authenticated = ".anyRequest().authenticated()" in compact
    return permit_all_patterns, default_authenticated


def matches_security_pattern(pattern: str, path: str) -> bool:
    normalized_pattern = pattern.rstrip("/") or "/"
    normalized_path = path.rstrip("/") or "/"
    if normalized_pattern.endswith("/**"):
        prefix = normalized_pattern[:-3].rstrip("/")
        return normalized_path == prefix or normalized_path.startswith(prefix + "/")
    return normalized_path == normalized_pattern


def apply_http_security(endpoints: list[Endpoint]) -> None:
    permit_all_patterns, default_authenticated = load_security_config()
    for endpoint in endpoints:
        if endpoint.security != "NONE":
            continue
        if any(matches_security_pattern(pattern, endpoint.path) for pattern in permit_all_patterns):
            endpoint.security = "PermitAll (SecurityConfig)"
        elif default_authenticated:
            endpoint.security = "Authenticated (SecurityConfig default)"


def main():
    args       = sys.argv[1:]
    missing_only = "--missing-only" in args
    as_csv       = "--csv" in args

    controllers = sorted(CTRL_DIR.rglob("*Controller.java"))
    if not controllers:
        print("No *Controller.java files found.", file=sys.stderr)
        sys.exit(2)

    all_endpoints: list[Endpoint] = []
    for c in controllers:
        all_endpoints.extend(parse_controller(c))
    apply_http_security(all_endpoints)

    if not all_endpoints:
        print("No mapped endpoints found.")
        sys.exit(0)

    unsecured = [e for e in all_endpoints if e.security == "NONE"]

    if as_csv:
        out = io.StringIO()
        writer = csv.writer(out)
        writer.writerow(["controller", "method", "http", "path", "security", "line", "file"])
        for e in all_endpoints:
            writer.writerow([e.controller, e.method_name, e.http_method, e.path,
                             e.security, e.line, e.file])
        print(out.getvalue())
        sys.exit(0)

    if missing_only:
        if not unsecured:
            print("endpoint-audit: all endpoints have effective security.")
            sys.exit(0)
        print(f"endpoint-audit: {len(unsecured)} UNSECURED endpoint(s):\n")
        for e in unsecured:
            print(f"  [{e.http_method:6}] {e.path:<50}  {e.controller}.{e.method_name}  (line {e.line})")
        sys.exit(1)

    # Full report
    total    = len(all_endpoints)
    secured  = total - len(unsecured)
    pct      = secured * 100 // total if total else 0
    print(f"endpoint-audit: {total} endpoint(s), {secured} secured ({pct}%), {len(unsecured)} UNSECURED\n")

    by_ctrl: dict[str, list[Endpoint]] = {}
    for e in all_endpoints:
        by_ctrl.setdefault(e.controller, []).append(e)

    for ctrl in sorted(by_ctrl):
        eps = by_ctrl[ctrl]
        print(f"  [{ctrl}]")
        for e in eps:
            flag = "⚠ " if e.security == "NONE" else "  "
            print(f"  {flag} {e.http_method:6} {e.path:<45} {e.security}")
        print()

    if unsecured:
        print(f"RESULT: {len(unsecured)} unsecured endpoint(s) — run with --missing-only for compact list")
        sys.exit(1)
    print("RESULT: all endpoints secured")
    sys.exit(0)


if __name__ == "__main__":
    main()
