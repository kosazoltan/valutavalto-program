#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
frontend-backend-contract-audit.py -- static REST wiring audit.

Facts checked:
  - backend @RestController HTTP mappings
  - high-confidence frontend REST calls with literal URL paths

Exit:
  0 = no unmatched frontend REST call
  1 = at least one frontend call has no matching backend method/path

Notes:
  - Backend endpoints not referenced from literal frontend calls are reported as
    INFO, because several endpoints are webhooks, downloads, admin-only tools,
    diagnostics, or intentionally backend-only workflows.
  - Dynamic calls where the path is a variable are listed separately as
    unresolved; those require manual review.
"""
from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = Path(__file__).resolve().parent.parent.parent
BACKEND = ROOT / "backend" / "src" / "main" / "java"

FRONTEND_ROOTS = [
    ROOT / "frontend-react" / "src",
    ROOT / "penztar-client" / "electron",
    ROOT / "penztar-client" / "src",
    ROOT / "penztar-client" / "main.js",
    ROOT / "kozponti-client" / "src",
    ROOT / "kozponti-client" / "electron",
]
FRONTEND_API_DIR = ROOT / "frontend-react" / "src" / "services" / "api"

SOURCE_SUFFIXES = {".ts", ".tsx", ".js", ".jsx"}
SKIP_DIR_NAMES = {"node_modules", "dist", "dist-electron", "build", "coverage", ".vite"}
SKIP_FILE_MARKERS = {
    ".test.",
    ".spec.",
    ".stories.",
}
SKIP_FILE_NAMES = {
    "setupTests.ts",
    "setupTests.tsx",
    "setup.ts",
    "setup.tsx",
}

REST_CTRL = re.compile(r"@RestController\b")
CLASS_NAME = re.compile(r"\bclass\s+(\w+)")
METHOD_SIG = re.compile(
    r"^\s*(?:public|protected)\s+(?:[\w.<>\[\], ?]+)\s+(\w+)\s*\(",
)
MAPPING_START = re.compile(r"@(RequestMapping|GetMapping|PostMapping|PutMapping|DeleteMapping|PatchMapping)\b")
REQUEST_METHOD = re.compile(r"RequestMethod\.([A-Z]+)")
STRING_LITERAL = re.compile(r'"([^"]*)"')
QUOTED_PATH_LITERAL = re.compile(r"""['"`](/[^'"`?]+)(?:\?[^'"`]*)?['"`]""")

API_CALL = re.compile(
    r"\b(?:api|axios|client|http)\s*\.\s*"
    r"(?P<method>get|post|put|delete|patch)\s*"
    r"(?:<[^()\n]*>)?\s*\(\s*"
    r"(?P<quote>['\"`])(?P<path>[^'\"`]+)(?P=quote)",
    re.IGNORECASE,
)
RATE_MAKER_REQUEST = re.compile(
    r"\brequest\s*(?:<[^;\n()]*>)?\s*\(\s*"
    r"[^,\n]+,\s*['\"](?P<method>GET|POST|PUT|DELETE|PATCH)['\"]\s*,\s*"
    r"(?P<quote>['\"`])(?P<path>[^'\"`]+)(?P=quote)",
)
SYNC_ENGINE_CALL = re.compile(
    r"\bhttp(?P<method>Get|Post|Put|Delete|Patch)\s*(?:<[^;\n()]*>)?\s*\(\s*"
    r"`\$\{[^}]+\}(?P<path>/[^`?]+)(?:\?[^`]*)?`",
)
FETCH_START = re.compile(r"\bfetch\s*\(")
FETCH_METHOD = re.compile(r"\bmethod\s*:\s*['\"`](GET|POST|PUT|DELETE|PATCH)['\"`]", re.IGNORECASE)
JSX_SRC_API_URL = re.compile(r"\bsrc\s*=\s*\{\s*`(?P<path>/api(?:/v1)?/[^`?]+)(?:\?[^`]*)?`")
DOM_SRC_API_URL = re.compile(r"\.src\s*=\s*`(?P<path>/api(?:/v1)?/[^`?]+)(?:\?[^`]*)?`")
API_EXPORT = re.compile(r"\bexport\s+const\s+(?P<name>[A-Za-z_$][\w$]*Api)\s*=\s*\{")
TOP_LEVEL_KEY = re.compile(r"^\s*(?P<name>[A-Za-z_$][\w$]*)\s*:")

# Framework/proxy endpoints that are configured outside @RestController.
SYNTHETIC_BACKEND_ENDPOINTS = {
    ("GET", "/actuator/health"),
    ("GET", "/actuator/info"),
    ("GET", "/actuator/prometheus"),
}


@dataclass(frozen=True)
class Endpoint:
    method: str
    path: str
    source: str
    line: int
    owner: str


@dataclass(frozen=True)
class FrontendCall:
    method: str
    path: str
    source: str
    line: int
    kind: str


@dataclass(frozen=True)
class UnresolvedCall:
    source: str
    line: int
    expression: str
    reason: str


@dataclass(frozen=True)
class BackendReferenceClass:
    category: str
    evidence: str


@dataclass(frozen=True)
class ApiMethodSpan:
    wrapper: str
    method: str
    source: str
    start_line: int
    end_line: int
    ui_references: tuple[str, ...]


def rel(path: Path) -> str:
    return str(path.resolve().relative_to(ROOT)).replace("\\", "/")


def iter_source_files() -> Iterable[Path]:
    for root in FRONTEND_ROOTS:
        if not root.exists():
            continue
        if root.is_file():
            yield root
            continue
        for path in root.rglob("*"):
            if path.is_dir():
                continue
            if any(part in SKIP_DIR_NAMES for part in path.parts):
                continue
            if path.name in SKIP_FILE_NAMES or any(marker in path.name for marker in SKIP_FILE_MARKERS):
                continue
            if path.suffix.lower() in SOURCE_SUFFIXES:
                yield path


def collect_global_path_constants(paths: Iterable[Path]) -> dict[str, list[str]]:
    constants: dict[str, list[str]] = {}
    for path in paths:
        text = path.read_text(encoding="utf-8", errors="replace")
        for match in re.finditer(
            r"\b(?:export\s+)?const\s+([A-Z][A-Z0-9_]*)\s*=\s*['\"`]([^'\"`]+)['\"`]",
            text,
        ):
            normalized = normalize_path(match.group(2))
            if normalized:
                constants.setdefault(match.group(1), []).append(normalized)
    return constants


def normalize_path(raw_path: str) -> str | None:
    path = raw_path.strip()
    if not path:
        return "/"
    if path.startswith(("http://", "https://", "file://", "app://")):
        return None
    if "${" in path and "}" not in path:
        path = path.split("${", 1)[0]
    path = re.sub(r"\$\{[^}]+\}", "{param}", path)
    path = path.split("?", 1)[0].split("#", 1)[0]
    if not path.startswith("/"):
        return None
    path = re.sub(r"/+", "/", path)
    for prefix in ("/api/v1", "/api"):
        if path == prefix:
            path = "/"
        elif path.startswith(prefix + "/"):
            path = path[len(prefix):]
            break
    if len(path) > 1 and path.endswith("/"):
        path = path.rstrip("/")
    return path


def normalize_url_like_path(raw_path: str) -> str | None:
    path = raw_path.strip()
    if not path:
        return None
    path = re.sub(r"\$\{[^}]+\}", "{base}", path)
    for prefix in ("/api/v1", "/api"):
        if path == prefix:
            return "/"
        index = path.find(prefix + "/")
        if index >= 0:
            return normalize_path(path[index:])
    return normalize_path(path)


def path_segments(path: str) -> tuple[str, ...]:
    normalized = normalize_path(path)
    if normalized is None:
        return tuple()
    return tuple(part for part in normalized.strip("/").split("/") if part)


def is_variable_segment(part: str) -> bool:
    return (
        part.startswith("{")
        and part.endswith("}")
        or part.startswith(":")
        or "{param}" in part
    )


def is_probable_identifier_literal(part: str) -> bool:
    return bool(re.fullmatch(r"\d+|[0-9a-fA-F-]{8,}", part))


def path_segments_match(frontend_part: str, backend_part: str) -> bool:
    if frontend_part == backend_part:
        return True
    frontend_variable = is_variable_segment(frontend_part)
    backend_variable = is_variable_segment(backend_part)
    if frontend_variable and backend_variable:
        return True
    if backend_variable and is_probable_identifier_literal(frontend_part):
        return True
    if frontend_variable and is_probable_identifier_literal(backend_part):
        return True
    return False


def paths_match(frontend: str, backend: str) -> bool:
    fp = path_segments(frontend)
    bp = path_segments(backend)
    if len(fp) != len(bp):
        return False
    return all(path_segments_match(frontend_part, backend_part) for frontend_part, backend_part in zip(fp, bp))


def backend_reference_paths_match(
    frontend: str,
    backend: str,
    method: str,
    backend_endpoints: list[Endpoint],
) -> bool:
    fp = path_segments(frontend)
    bp = path_segments(backend)
    if len(fp) != len(bp) or not paths_match(frontend, backend):
        return False

    for index, (frontend_part, backend_part) in enumerate(zip(fp, bp)):
        if frontend_part == backend_part:
            continue
        frontend_variable = is_variable_segment(frontend_part)
        backend_variable = is_variable_segment(backend_part)
        if backend_variable and not frontend_variable and not is_probable_identifier_literal(frontend_part):
            if any(
                other.method == method
                and other.path != backend
                and tuple(path_segments(other.path)) == fp
                for other in backend_endpoints
            ):
                return False
        if frontend_variable and not backend_variable:
            if any(
                other.method == method
                and other.path != backend
                and paths_match(frontend, other.path)
                and len(path_segments(other.path)) > index
                and is_variable_segment(path_segments(other.path)[index])
                for other in backend_endpoints
            ):
                return False
    return True


def collect_annotation(lines: list[str], start: int) -> tuple[str, int]:
    text = lines[start].strip()
    open_count = text.count("(") - text.count(")")
    end = start
    while open_count > 0 and end + 1 < len(lines):
        end += 1
        text += " " + lines[end].strip()
        open_count += lines[end].count("(") - lines[end].count(")")
    return text, end


def mapping_paths(annotation: str) -> list[str]:
    literals = [s for s in STRING_LITERAL.findall(annotation) if s == "" or s.startswith("/")]
    if not literals:
        return [""]
    return literals


def mapping_methods(kind: str, annotation: str) -> list[str]:
    if kind == "RequestMapping":
        methods = REQUEST_METHOD.findall(annotation)
        return methods or ["ANY"]
    return [kind.replace("Mapping", "").upper()]


def join_paths(base: str, sub: str) -> str:
    joined = f"{base.rstrip('/')}/{sub.lstrip('/')}"
    joined = "/" + joined.strip("/")
    normalized = normalize_path(joined)
    return normalized or joined


def parse_backend_controller(path: Path) -> list[Endpoint]:
    text = path.read_text(encoding="utf-8", errors="replace")
    if not REST_CTRL.search(text):
        return []

    lines = text.splitlines()
    class_match = CLASS_NAME.search(text)
    owner = class_match.group(1) if class_match else path.stem

    class_line = 0
    for i, line in enumerate(lines):
        if re.search(r"\bclass\s+\w+", line):
            class_line = i
            break

    base_paths = [""]
    i = max(0, class_line - 20)
    while i < class_line:
        if "@RequestMapping" in lines[i]:
            annotation, end = collect_annotation(lines, i)
            base_paths = mapping_paths(annotation)
            i = end + 1
            continue
        i += 1

    endpoints: list[Endpoint] = []
    i = 0
    while i < len(lines):
        start_match = MAPPING_START.search(lines[i])
        if not start_match:
            i += 1
            continue

        annotation, end = collect_annotation(lines, i)
        kind = start_match.group(1)
        paths = mapping_paths(annotation)
        methods = mapping_methods(kind, annotation)

        sig_index = end + 1
        while sig_index < min(len(lines), end + 25):
            if METHOD_SIG.match(lines[sig_index]):
                for base in base_paths:
                    for sub in paths:
                        full_path = join_paths(base, sub)
                        for method in methods:
                            if method != "ANY":
                                endpoints.append(
                                    Endpoint(method, full_path, rel(path), i + 1, owner),
                                )
                break
            if MAPPING_START.search(lines[sig_index]) or re.search(r"\bclass\s+\w+", lines[sig_index]):
                break
            sig_index += 1
        i = max(end + 1, sig_index)

    return endpoints


def parse_backend_endpoints() -> list[Endpoint]:
    endpoints: list[Endpoint] = []
    for path in BACKEND.rglob("*.java"):
        endpoints.extend(parse_backend_controller(path))
    for method, path in SYNTHETIC_BACKEND_ENDPOINTS:
        endpoints.append(Endpoint(method, path, "spring-actuator", 0, "Actuator"))
    unique: dict[tuple[str, str, str], Endpoint] = {}
    for ep in endpoints:
        unique[(ep.method, ep.path, ep.owner)] = ep
    return sorted(unique.values(), key=lambda ep: (ep.path, ep.method, ep.source, ep.line))


def line_number(text: str, index: int) -> int:
    return text.count("\n", 0, index) + 1


def strip_strings_and_line_comments(line: str) -> str:
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


def find_matching_brace(text: str, open_index: int) -> int | None:
    depth = 0
    quote: str | None = None
    escaped = False
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
        if quote:
            if escaped:
                escaped = False
                continue
            if char == "\\":
                escaped = True
                continue
            if char == quote:
                quote = None
            continue
        if char == "/" and next_char == "/":
            in_line_comment = True
            continue
        if char == "/" and next_char == "*":
            in_block_comment = True
            continue
        if char in {"'", '"', "`"}:
            quote = char
            continue
        if char == "{":
            depth += 1
            continue
        if char == "}":
            depth -= 1
            if depth == 0:
                return index
    return None


def local_variable_paths(text: str, variable_name: str, position: int) -> list[str]:
    before = text[:position]
    assignments = list(re.finditer(
        rf"\b(?:const|let)\s+{re.escape(variable_name)}\s*=\s*(?P<expr>[\s\S]*?)(?:\n\s*(?:const|let|if|try|await|return)|;)",
        before,
    ))
    if not assignments:
        return []
    expr = assignments[-1].group("expr")
    result: list[str] = []
    for raw in QUOTED_PATH_LITERAL.findall(expr):
        normalized = normalize_path(raw)
        if normalized:
            result.append(normalized)
    return sorted(set(result))


def normalize_template_path(raw: str) -> str | None:
    templated = re.sub(r"\$\{[^}]+\}", "{id}", raw)
    return normalize_path(templated)


def local_template_variable_paths(text: str, variable_name: str, position: int) -> list[str]:
    before = text[:position]
    assignments = list(re.finditer(
        rf"\b(?:const|let)\s+{re.escape(variable_name)}\s*=\s*`(?P<path>/[^`?]+)(?:\?[^`]*)?`",
        before,
    ))
    result: list[str] = []
    for assignment in assignments:
        normalized = normalize_template_path(assignment.group("path"))
        if normalized:
            result.append(normalized)
    return sorted(set(result))


def local_fetch_variable_paths(text: str, variable_name: str, position: int) -> list[str]:
    before = text[:position]
    assignments = list(re.finditer(
        rf"\b(?:const|let)\s+{re.escape(variable_name)}\s*=\s*(?P<quote>['\"`])(?P<path>[^'\"`]+)(?P=quote)",
        before,
    ))
    result: list[str] = []
    for assignment in assignments:
        normalized = normalize_url_like_path(assignment.group("path"))
        if normalized:
            result.append(normalized)
    return sorted(set(result))


def find_matching_paren(text: str, open_index: int) -> int | None:
    depth = 0
    quote: str | None = None
    escaped = False
    for index in range(open_index, len(text)):
        char = text[index]
        if quote:
            if escaped:
                escaped = False
                continue
            if char == "\\":
                escaped = True
                continue
            if char == quote:
                quote = None
            continue
        if char in {"'", '"', "`"}:
            quote = char
            continue
        if char == "(":
            depth += 1
            continue
        if char == ")":
            depth -= 1
            if depth == 0:
                return index
    return None


def split_first_argument(args: str) -> tuple[str, str]:
    quote: str | None = None
    escaped = False
    depth = 0
    for index, char in enumerate(args):
        if quote:
            if escaped:
                escaped = False
                continue
            if char == "\\":
                escaped = True
                continue
            if char == quote:
                quote = None
            continue
        if char in {"'", '"', "`"}:
            quote = char
            continue
        if char in "([{":
            depth += 1
            continue
        if char in ")]}":
            depth = max(0, depth - 1)
            continue
        if char == "," and depth == 0:
            return args[:index].strip(), args[index + 1:].strip()
    return args.strip(), ""


def frontend_fetch_calls(text: str) -> list[tuple[str, str, int]]:
    result: list[tuple[str, str, int]] = []
    for match in FETCH_START.finditer(text):
        open_index = text.find("(", match.start())
        close_index = find_matching_paren(text, open_index)
        if close_index is None:
            continue
        first_arg, options = split_first_argument(text[open_index + 1:close_index])
        method_match = FETCH_METHOD.search(options)
        method = method_match.group(1).upper() if method_match else "GET"

        resolved_paths: list[str] = []
        literal_match = re.fullmatch(r"(?P<quote>['\"`])(?P<path>[^'\"`]+)(?P=quote)", first_arg, re.DOTALL)
        if literal_match:
            normalized = normalize_url_like_path(literal_match.group("path"))
            if normalized:
                resolved_paths.append(normalized)
        elif re.fullmatch(r"[A-Za-z_$][\w$]*", first_arg):
            resolved_paths.extend(local_fetch_variable_paths(text, first_arg, match.start()))

        for resolved_path in sorted(set(resolved_paths)):
            result.append((method, resolved_path, match.start()))
    return result


def frontend_api_url_gets(text: str) -> list[tuple[str, str, int]]:
    result: list[tuple[str, str, int]] = []
    for regex in (JSX_SRC_API_URL, DOM_SRC_API_URL):
        for match in regex.finditer(text):
            normalized = normalize_template_path(match.group("path"))
            if normalized:
                result.append(("GET", normalized, match.start()))
    return result


def frontend_http_json_with_retry_calls(text: str) -> list[tuple[str, str, int]]:
    result: list[tuple[str, str, int]] = []
    for match in re.finditer(r"\bhttpJsonWithRetry\b", text):
        open_index = text.find("(", match.start())
        if open_index < 0:
            continue
        close_index = find_matching_paren(text, open_index)
        if close_index is None:
            continue
        first_arg, options = split_first_argument(text[open_index + 1:close_index])
        template_match = re.fullmatch(r"`\$\{[^}]+\}(?P<path>/[^`?]+)(?:\?[^`]*)?`", first_arg.strip(), re.DOTALL)
        if not template_match:
            continue
        normalized = normalize_template_path(template_match.group("path"))
        if not normalized:
            continue
        method_match = FETCH_METHOD.search(options)
        method = method_match.group(1).upper() if method_match else "GET"
        result.append((method, normalized, match.start()))
    return result


def enclosing_function_parameter_call_fragments(text: str, parameter_name: str, position: int) -> list[str]:
    before = text[:position]
    function_matches = list(re.finditer(
        r"\b(?:const|let)\s+(?P<name>[A-Za-z_$][\w$]*)\s*=\s*"
        r"(?:async\s*)?\((?P<params>[^)]*)\)\s*=>",
        before,
    ))
    if not function_matches:
        return []

    function_match = function_matches[-1]
    params = [
        param.strip().split(":", 1)[0].strip()
        for param in function_match.group("params").split(",")
    ]
    if not params or params[0] != parameter_name:
        return []

    function_name = function_match.group("name")
    result: list[str] = []
    call_pattern = re.compile(
        rf"\b{re.escape(function_name)}\s*\(\s*"
        r"(?P<quote>['\"`])(?P<path>[^'\"`]+)(?P=quote)",
    )
    for call in call_pattern.finditer(text):
        if function_match.start() <= call.start() <= position:
            continue
        fragment = re.sub(r"\$\{[^}]+\}", "{id}", call.group("path")).strip("/")
        if fragment:
            result.append(fragment)
    return sorted(set(result))


def template_base_api_calls(text: str) -> list[tuple[str, str, int]]:
    result: list[tuple[str, str, int]] = []
    call_pattern = re.compile(
        r"\bapi\s*\.\s*(?P<method>get|post|put|delete|patch)\s*(?:<[^()\n]*>)?\s*\(\s*"
        r"`\$\{(?P<variable>[A-Za-z_$][\w$]*)\}(?P<suffix>/[^`?]+)(?:\?[^`]*)?`",
        re.IGNORECASE,
    )
    for match in call_pattern.finditer(text):
        bases = local_template_variable_paths(text, match.group("variable"), match.start())
        suffix = match.group("suffix")
        for base in bases:
            parameter_only = re.fullmatch(r"/\$\{(?P<parameter>[A-Za-z_$][\w$]*)\}", suffix)
            if parameter_only:
                fragments = enclosing_function_parameter_call_fragments(
                    text,
                    parameter_only.group("parameter"),
                    match.start(),
                )
                for fragment in fragments:
                    result.append((match.group("method").upper(), join_paths(base, fragment), match.start()))
                continue
            if "${" in suffix:
                continue
            result.append((match.group("method").upper(), join_paths(base, suffix), match.start()))
    return result


def function_parameter_literal_paths(text: str, variable_name: str, position: int) -> list[str]:
    before = text[:position]
    function_matches = list(re.finditer(
        r"\b(?:async\s+)?function\s+(?P<name>[A-Za-z_$][\w$]*)\s*"
        r"(?:<[^()\n]*>)?\s*\((?P<params>[^)]*)\)",
        before,
    ))
    if not function_matches:
        return []

    function_match = function_matches[-1]
    params = [
        param.strip().split(":", 1)[0].strip()
        for param in function_match.group("params").split(",")
    ]
    if not params or params[0] != variable_name:
        return []

    function_name = function_match.group("name")
    result: list[str] = []
    call_pattern = re.compile(
        rf"\b{re.escape(function_name)}\s*(?:<[^()\n]*>)?\s*\(\s*"
        r"(?P<quote>['\"`])(?P<path>[^'\"`]+)(?P=quote)",
    )
    for call in call_pattern.finditer(text):
        if function_match.start() <= call.start() <= position:
            continue
        normalized = normalize_path(call.group("path"))
        if normalized:
            result.append(normalized)
    return sorted(set(result))


def extract_frontend_calls(
    path: Path,
    global_path_constants: dict[str, list[str]],
) -> tuple[list[FrontendCall], list[UnresolvedCall]]:
    text = path.read_text(encoding="utf-8", errors="replace")
    calls: list[FrontendCall] = []
    unresolved: list[UnresolvedCall] = []

    for regex, kind in (
        (API_CALL, "api-call"),
        (RATE_MAKER_REQUEST, "rate-maker-request"),
        (SYNC_ENGINE_CALL, "sync-engine"),
    ):
        for match in regex.finditer(text):
            raw_path = match.group("path")
            normalized = normalize_path(raw_path)
            if normalized is None:
                continue
            method = match.group("method").upper()
            if method in {"GET", "POST", "PUT", "DELETE", "PATCH"}:
                calls.append(FrontendCall(method, normalized, rel(path), line_number(text, match.start()), kind))

    for method, resolved_path, position in template_base_api_calls(text):
        calls.append(FrontendCall(method, resolved_path, rel(path), line_number(text, position), "resolved-template-base"))

    for method, resolved_path, position in frontend_fetch_calls(text):
        calls.append(FrontendCall(method, resolved_path, rel(path), line_number(text, position), "fetch-call"))

    for method, resolved_path, position in frontend_api_url_gets(text):
        calls.append(FrontendCall(method, resolved_path, rel(path), line_number(text, position), "api-url-src"))

    for method, resolved_path, position in frontend_http_json_with_retry_calls(text):
        calls.append(FrontendCall(method, resolved_path, rel(path), line_number(text, position), "http-json-with-retry"))

    # High-confidence variable-path api calls. Resolve only simple local/global constants.
    variable_call = re.compile(
        r"\bapi\s*\.\s*(get|post|put|delete|patch)\s*(?:<[^()\n]*>)?\s*\(\s*([A-Za-z_$][\w$]*)",
    )
    for match in variable_call.finditer(text):
        method = match.group(1).upper()
        variable_name = match.group(2)
        resolved = local_variable_paths(text, variable_name, match.start())
        if not resolved:
            resolved = global_path_constants.get(variable_name, [])
        if not resolved:
            resolved = function_parameter_literal_paths(text, variable_name, match.start())
        if resolved:
            for resolved_path in resolved:
                calls.append(FrontendCall(method, resolved_path, rel(path), line_number(text, match.start()), "resolved-variable"))
            continue
        unresolved.append(
            UnresolvedCall(
                rel(path),
                line_number(text, match.start()),
                match.group(0).strip(),
                "variable path",
            ),
        )

    unique: dict[tuple[str, str, str, int, str], FrontendCall] = {}
    for call in calls:
        unique[(call.method, call.path, call.source, call.line, call.kind)] = call
    return list(unique.values()), unresolved


def parse_frontend_calls() -> tuple[list[FrontendCall], list[UnresolvedCall]]:
    calls: list[FrontendCall] = []
    unresolved: list[UnresolvedCall] = []
    source_files = list(iter_source_files())
    global_path_constants = collect_global_path_constants(source_files)
    for path in source_files:
        file_calls, file_unresolved = extract_frontend_calls(path, global_path_constants)
        calls.extend(file_calls)
        unresolved.extend(file_unresolved)
    return sorted(calls, key=lambda c: (c.source, c.line, c.method, c.path)), unresolved


def is_api_service_source(source: str) -> bool:
    return source.startswith("frontend-react/src/services/api/")


def collect_production_ui_source_texts() -> tuple[tuple[str, str], ...]:
    sources: list[tuple[str, str]] = []
    for path in iter_source_files():
        path_rel = rel(path)
        if is_api_service_source(path_rel):
            continue
        sources.append((path_rel, path.read_text(encoding="utf-8", errors="replace")))
    return tuple(sources)


def collect_ui_reference_files(
    wrapper: str,
    method: str,
    production_sources: tuple[tuple[str, str], ...] | None = None,
) -> tuple[str, ...]:
    pattern = re.compile(rf"\b{re.escape(wrapper)}\s*\.\s*{re.escape(method)}\b")
    refs: list[str] = []
    if production_sources is None:
        production_sources = collect_production_ui_source_texts()
    for path_rel, text in production_sources:
        if pattern.search(text):
            refs.append(path_rel)
    return tuple(sorted(set(refs)))


def iter_api_method_lines(body: str, base_line: int) -> Iterable[tuple[str, int]]:
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
        sanitized = strip_strings_and_line_comments(line)
        curly += sanitized.count("{") - sanitized.count("}")
        square += sanitized.count("[") - sanitized.count("]")
        paren += sanitized.count("(") - sanitized.count(")")
        curly = max(curly, 0)
        square = max(square, 0)
        paren = max(paren, 0)


def collect_api_method_spans() -> list[ApiMethodSpan]:
    spans: list[ApiMethodSpan] = []
    if not FRONTEND_API_DIR.exists():
        return spans
    production_sources = collect_production_ui_source_texts()
    for path in iter_source_files():
        try:
            path.relative_to(FRONTEND_API_DIR)
        except ValueError:
            continue
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
            method_lines = list(iter_api_method_lines(body, base_line))
            object_end_line = line_number(text, close_index)
            for index, (method, start_line) in enumerate(method_lines):
                next_start = method_lines[index + 1][1] if index + 1 < len(method_lines) else object_end_line + 1
                spans.append(
                    ApiMethodSpan(
                        wrapper=wrapper,
                        method=method,
                        source=rel(path),
                        start_line=start_line,
                        end_line=next_start - 1,
                        ui_references=collect_ui_reference_files(wrapper, method, production_sources),
                    ),
                )
    return spans


def production_ui_referenced_calls(
    frontend_calls: list[FrontendCall],
    api_method_spans: list[ApiMethodSpan],
) -> list[FrontendCall]:
    spans_by_source: dict[str, list[ApiMethodSpan]] = {}
    for span in api_method_spans:
        if span.ui_references:
            spans_by_source.setdefault(span.source, []).append(span)

    result: dict[tuple[str, str, str, int, str], FrontendCall] = {}
    for call in frontend_calls:
        if not is_api_service_source(call.source):
            result[(call.method, call.path, call.source, call.line, call.kind)] = call
            continue
        for span in spans_by_source.get(call.source, []):
            if span.start_line <= call.line <= span.end_line:
                result[(call.method, call.path, call.source, call.line, f"ui-used-wrapper:{span.wrapper}.{span.method}")] = FrontendCall(
                    call.method,
                    call.path,
                    call.source,
                    call.line,
                    f"ui-used-wrapper:{span.wrapper}.{span.method}",
                )
                break
    return sorted(result.values(), key=lambda c: (c.source, c.line, c.method, c.path, c.kind))


def find_unmatched(
    frontend_calls: list[FrontendCall],
    backend_endpoints: list[Endpoint],
) -> list[tuple[FrontendCall, list[Endpoint]]]:
    unmatched: list[tuple[FrontendCall, list[Endpoint]]] = []
    for call in frontend_calls:
        same_method = [ep for ep in backend_endpoints if ep.method == call.method]
        if any(paths_match(call.path, ep.path) for ep in same_method):
            continue
        same_path_other_method = [ep for ep in backend_endpoints if paths_match(call.path, ep.path)]
        unmatched.append((call, same_path_other_method))
    return unmatched


def unreferenced_backend(
    backend_endpoints: list[Endpoint],
    frontend_calls: list[FrontendCall],
) -> list[Endpoint]:
    result: list[Endpoint] = []
    for ep in backend_endpoints:
        if ep.source == "spring-actuator":
            continue
        if not any(
            call.method == ep.method
            and backend_reference_paths_match(call.path, ep.path, ep.method, backend_endpoints)
            for call in frontend_calls
        ):
            result.append(ep)
    return result


def classify_backend_reference(ep: Endpoint) -> BackendReferenceClass:
    path = ep.path
    owner = ep.owner.lower()
    first = path.strip("/").split("/", 1)[0] if path.strip("/") else ""

    if ep.method == "POST" and path == "/notifications/{id}/mark-read":
        return BackendReferenceClass(
            "backend-only/legacy-alias",
            "Legacy alias for the canonical PUT /notifications/{id}/read endpoint, which is used by the frontend.",
        )
    if ep.method == "POST" and path == "/workers/{id}/change-password":
        return BackendReferenceClass(
            "backend-only/legacy-compat",
            "WorkerController legacy self/admin password route; routed UI uses canonical /users/me/password for own password and /users/{id}/change-password for admin user password changes.",
        )
    if ep.method in {"GET", "PUT"} and path == "/admin/branches/{id}":
        return BackendReferenceClass(
            "backend-only/alternate-admin-api",
            "Admin branch detail/update endpoint; the routed branch editor uses GET /admin/branches/{id} for stats and canonical PUT /branches/{id} for edits.",
        )
    if ep.method == "POST" and path == "/branches":
        return BackendReferenceClass(
            "backend-only/alternate-admin-api",
            "Full CreateBranchDto admin/főértéktári create contract; the routed new-branch page uses /branches/simple-cashier for the current user-facing office/cashier creation flow.",
        )
    if ep.method == "GET" and path in {"/audit", "/audit/worker/{id}", "/audit/action/{action}"}:
        return BackendReferenceClass(
            "backend-only/legacy-compat",
            "AuditLogController marks this as backward-compatible; the routed AuditLogPage uses /audit/search, /audit/branch, /audit/trail and /audit/export.",
        )
    if ep.method == "GET" and path == "/branch-groups/active":
        return BackendReferenceClass(
            "backend-only/alternate-read-api",
            "Branch group active-list helper; the routed BranchGroupPage uses /branch-groups and /branch-groups/roots for the management view.",
        )
    if ep.method == "POST" and path == "/authorized-representatives":
        return BackendReferenceClass(
            "backend-only/legacy-compat",
            "AuthorizedRepresentativeController marks this as a legacy route; the routed create page uses /authorized-representatives/customer/{customerId}/register.",
        )
    if ep.method == "POST" and path == "/authorized-representatives/record-transaction":
        return BackendReferenceClass(
            "backend-only/legacy-compat",
            "Representative transaction-log helper; no direct routed UI action is required for the current representative management flow.",
        )
    if ep.method == "POST" and path == "/monitoring/heartbeat":
        return BackendReferenceClass(
            "integration-or-device",
            "Branch heartbeat ingest endpoint; monitored by frontend dashboard via /monitoring/dashboard, /online, and /offline.",
        )
    if ep.method == "POST" and path == "/sync/events":
        return BackendReferenceClass(
            "integration-or-callback",
            "Inbound sync event receiver with mandatory Idempotency-Key; driven by sync/outbox clients, not by a human UI control.",
        )
    if ep.method == "POST" and path in {
        "/daily-closing/execute",
        "/daily-sessions/open",
        "/daily-sessions/close",
        "/daily-sessions/close-with-validation",
        "/daily-sessions/{sessionId}/close",
    }:
        if path == "/daily-sessions/open":
            return BackendReferenceClass(
                "backend-only/legacy-compat",
                "Legacy SecurityContext-based day-open path; the routed DayOpenPage uses /sessions/open, /sessions/validate-open/{branchId}, and /sessions/opening-balance/{sessionId} for the richer user-facing opening flow.",
            )
        if path == "/daily-sessions/close":
            return BackendReferenceClass(
                "backend-only/legacy-compat",
                "Direct legacy day-close path; the user-facing closing UI is the closing-wizard flow with validation/report/finalize steps.",
            )
        return BackendReferenceClass(
            "backend-only/legacy-compat",
            "Legacy/POS-compatible closing path; the user-facing closing UI is the closing-wizard flow.",
        )
    if ep.method == "POST" and path == "/closing-wizard/{wizardId}/complete":
        return BackendReferenceClass(
            "backend-only/alternate-workflow-api",
            "Wizard status-only completion path; the routed ClosingWizardPage uses /closing-wizard/{wizardId}/finalize, which runs the DailyClosingService closing checks and session close.",
        )
    if ep.method == "POST" and path == "/transactions/reversal":
        return BackendReferenceClass(
            "backend-only/legacy-compat",
            "Legacy transaction-level reversal path; the routed StornoPage uses the /stornos check/request/approve/execute flow with approval and receipt handling.",
        )
    if ep.method == "POST" and path == "/stornos/pos":
        return BackendReferenceClass(
            "integration-or-device",
            "POS-specific storno endpoint; the human routed storno UI uses /stornos/execute after the normal approval flow.",
        )
    if ep.method == "PUT" and path == "/cash-desks/{cashDeskId}/denominations/{denominationId}":
        return BackendReferenceClass(
            "backend-only/alternate-write-api",
            "Single-denomination update helper; the routed DenominationPage persists cashier denominations through the canonical batch endpoint /cash-desks/{cashDeskId}/denominations/batch.",
        )
    if ep.method == "PUT" and path in {"/denominations", "/denominations/bulk"}:
        return BackendReferenceClass(
            "backend-only/legacy-compat",
            "Legacy CIMLET quantity update path; current routed denomination entry uses cash-desk batch persistence and closing wizard denomination submission.",
        )
    if ep.method == "POST" and path == "/error-log":
        return BackendReferenceClass(
            "backend-only/diagnostics",
            "HMAC-signed operational error-log ingest endpoint; unsigned browser UI calls are intentionally rejected.",
        )
    if ep.method == "POST" and path in {"/cash-balances/init-branch/{branchId}", "/cash-balances/init-all-branches"}:
        return BackendReferenceClass(
            "backend-only/admin-maintenance",
            "Idempotent cash-balance initialization/retrofit endpoint; normal branch/session flows auto-initialize balances.",
        )
    if path in {"/nav/closings/validate-amount", "/nav/closings/{id}/approve-discrepancy"}:
        return BackendReferenceClass(
            "ui-candidate/financial-contract-required",
            "NAV closing discrepancy control is a cashier/supervisor workflow; frontend binding requires an approved financial contract/spec.",
        )
    if path in {"/nav/closings/daily", "/nav/closings/{id}/submit"}:
        return BackendReferenceClass(
            "workflow-action/financial-admin",
            "State-changing NAV fiscal workflow action; do not expose without explicit role/approval flow and contract evidence.",
        )
    if ep.method == "POST" and path == "/closing/monthly/{branchId}/{yearMonth}":
        return BackendReferenceClass(
            "workflow-action/financial-admin",
            "State-changing monthly close/archive workflow; the routed MonthlyClosingPage currently reads reports and HRK flows, while exposing canonical monthly close requires explicit role/approval flow and financial contract evidence.",
        )
    if ep.method == "POST" and path in {"/ertektar/transfers", "/ertektar/receipts", "/ertektar/corrections"}:
        return BackendReferenceClass(
            "ui-candidate/financial-contract-required",
            "Értéktár create request endpoint; the routed TreasuryDashboard currently exposes a read-only ledger for transfers/receipts/corrections, and write binding requires an approved stock/finance workflow contract.",
        )
    if ep.method == "POST" and path in {
        "/ertektar/transfers/{id}/supervisor-approve",
        "/ertektar/transfers/{id}/complete",
        "/ertektar/transfers/{id}/reject",
        "/ertektar/receipts/{id}/finalize",
        "/ertektar/corrections/{id}/approve",
        "/ertektar/corrections/{id}/reject",
    }:
        return BackendReferenceClass(
            "workflow-action/financial-admin",
            "Értéktár stock movement/status workflow action; existing UI lists the records but does not execute these actions, and exposing them requires explicit role/approval flow plus financial contract evidence.",
        )
    if path.endswith("/callback"):
        return BackendReferenceClass("integration-or-callback", "External OAuth/webhook callback endpoint; normally reached by third-party redirect, not by frontend REST.")
    if path.startswith("/auth/"):
        return BackendReferenceClass("backend-only/auth-session", "Auth/session bootstrap endpoint; often used indirectly or before app routes.")
    if first in {"actuator", "diagnostics"} or "diagnostics" in owner:
        return BackendReferenceClass("backend-only/diagnostics", "Operational diagnostics/health endpoint.")
    if any(token in path for token in ("/download", "/export", "/excel", "/txt", "/csv")):
        return BackendReferenceClass("ui-candidate/export-download", "Export/download endpoint should have an explicit launcher if user-facing.")
    if first in {"camera", "cash-register", "pos-terminal", "pos-terminal-stub", "nav", "bank-api-config", "western-union-stub"}:
        return BackendReferenceClass("integration-or-device", "External device/integration endpoint; may be driven by Electron/backend jobs.")
    if ep.method in {"POST", "PUT", "PATCH", "DELETE"} and any(
        token in path for token in (
            "/approve", "/reject", "/execute", "/cancel", "/restore", "/retry", "/revoke",
            "/publish", "/acknowledge", "/receive", "/storno", "/toggle", "/assign",
            "/resolve", "/register", "/sync", "/close", "/open",
        )
    ):
        return BackendReferenceClass("workflow-action", "State-changing workflow action; requires matching UI control or documented backend-only trigger.")
    if ep.method == "GET" and re.search(r"/\{[^}]+\}$", path):
        return BackendReferenceClass("ui-candidate/detail", "Detail read endpoint; usually expected behind list/detail navigation if user-facing.")
    if ep.method == "GET":
        return BackendReferenceClass("ui-candidate/list-or-view", "Read endpoint with no literal frontend caller found.")
    return BackendReferenceClass("ui-candidate/mutation", "Mutation endpoint with no literal frontend caller found.")


def unreferenced_summary(unreferenced: list[Endpoint]) -> dict[str, int]:
    summary: dict[str, int] = {}
    for ep in unreferenced:
        category = classify_backend_reference(ep).category
        summary[category] = summary.get(category, 0) + 1
    return dict(sorted(summary.items(), key=lambda item: (-item[1], item[0])))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--show-unreferenced", action="store_true")
    parser.add_argument("--show-unreferenced-summary", action="store_true")
    parser.add_argument("--show-ui-unreferenced", action="store_true")
    parser.add_argument("--show-ui-unreferenced-summary", action="store_true")
    parser.add_argument("--show-unresolved", action="store_true")
    parser.add_argument("--limit", type=int, default=40)
    args = parser.parse_args()

    backend_endpoints = parse_backend_endpoints()
    frontend_calls, unresolved = parse_frontend_calls()
    api_method_spans = collect_api_method_spans()
    ui_referenced_calls = production_ui_referenced_calls(frontend_calls, api_method_spans)
    unmatched = find_unmatched(frontend_calls, backend_endpoints)
    unreferenced = unreferenced_backend(backend_endpoints, frontend_calls)
    ui_unreferenced = unreferenced_backend(backend_endpoints, ui_referenced_calls)

    print("frontend-backend-contract-audit:")
    print(f"  backend endpoints: {len(backend_endpoints)}")
    print(f"  frontend literal REST calls: {len(frontend_calls)}")
    print(f"  frontend production UI/app referenced REST calls: {len(ui_referenced_calls)}")
    print(f"  frontend unresolved dynamic calls: {len(unresolved)}")
    print(f"  unmatched frontend REST calls: {len(unmatched)}")
    print(f"  backend endpoints not referenced by literal calls: {len(unreferenced)}")
    print(f"  backend endpoints not referenced by production UI/app calls: {len(ui_unreferenced)}")

    if unmatched:
        print("\nUNMATCHED FRONTEND CALLS")
        for call, alternatives in unmatched[: args.limit]:
            alt = ""
            if alternatives:
                methods = ", ".join(sorted({ep.method for ep in alternatives}))
                alt = f" (path exists with method(s): {methods})"
            print(f"  {call.method:6s} {call.path:55s} {call.source}:{call.line} [{call.kind}]{alt}")
        if len(unmatched) > args.limit:
            print(f"  ... {len(unmatched) - args.limit} more")

    if args.show_unresolved and unresolved:
        print("\nUNRESOLVED DYNAMIC FRONTEND CALLS")
        for item in unresolved[: args.limit]:
            print(f"  {item.source}:{item.line} {item.reason}: {item.expression}")
        if len(unresolved) > args.limit:
            print(f"  ... {len(unresolved) - args.limit} more")

    if args.show_unreferenced and unreferenced:
        if args.show_unreferenced_summary:
            print("\nUNREFERENCED BACKEND SUMMARY")
            for category, count in unreferenced_summary(unreferenced).items():
                print(f"  {category:32s} {count}")

        print("\nUNREFERENCED BACKEND ENDPOINTS")
        for ep in unreferenced[: args.limit]:
            classification = classify_backend_reference(ep)
            print(f"  {ep.method:6s} {ep.path:55s} {ep.source}:{ep.line} {ep.owner} [{classification.category}]")
        if len(unreferenced) > args.limit:
            print(f"  ... {len(unreferenced) - args.limit} more")

    if args.show_ui_unreferenced and ui_unreferenced:
        if args.show_ui_unreferenced_summary:
            print("\nPRODUCTION UI/APP UNREFERENCED BACKEND SUMMARY")
            for category, count in unreferenced_summary(ui_unreferenced).items():
                print(f"  {category:32s} {count}")

        print("\nPRODUCTION UI/APP UNREFERENCED BACKEND ENDPOINTS")
        for ep in ui_unreferenced[: args.limit]:
            classification = classify_backend_reference(ep)
            print(f"  {ep.method:6s} {ep.path:55s} {ep.source}:{ep.line} {ep.owner} [{classification.category}]")
        if len(ui_unreferenced) > args.limit:
            print(f"  ... {len(ui_unreferenced) - args.limit} more")

    if unmatched:
        return 1

    print("\nOK: every high-confidence frontend REST call matched a backend method/path.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
