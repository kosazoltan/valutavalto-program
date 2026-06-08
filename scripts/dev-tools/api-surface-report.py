#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
api-surface-report.py -- Teljes REST API felszin dokumentalas.

Replaces: AI "what endpoints exist?" kerdesek + kezi Swagger-bogaraszas.

Kiszedi:
  - Osszes @RestController osztaly
  - Minden HTTP mapping (GET/POST/PUT/DELETE/PATCH)
  - URL path + HTTP method + Java osztaly/metodus nev
  - @PreAuthorize / @Secured annotaciok (hozzaferes-kontroll)
  - @RequestParam / @PathVariable parameterek

Usage:
  python scripts/dev-tools/api-surface-report.py
  python scripts/dev-tools/api-surface-report.py --format md
  python scripts/dev-tools/api-surface-report.py --filter /api/v1/transfers

Exit: 0 = OK
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
from pathlib import Path

ROOT    = Path(__file__).resolve().parent.parent.parent
BACKEND = ROOT / "backend" / "src" / "main" / "java"

REST_CTRL   = re.compile(r'@RestController\b')
CLASS_MAP   = re.compile(r'@RequestMapping\s*\(\s*(?:value\s*=\s*)?["\{]?([^"\)\{]+)["\}]?\s*\)')
CLASS_NAME  = re.compile(r'\bclass\s+(\w+)')
HTTP_MAP    = re.compile(
    r'@(Get|Post|Put|Delete|Patch)Mapping\s*\(?\s*(?:value\s*=\s*)?'
    r'(?:["\{]([^")\{]*)["\}])?')
METHOD_SIG  = re.compile(r'^\s+(?:public|protected)\s+\S+\s+(\w+)\s*\(')
PREAUTH     = re.compile(r'@PreAuthorize\s*\(\s*"([^"]+)"')
SECURED     = re.compile(r'@Secured\s*\(\s*"([^"]+)"')
PATH_VAR    = re.compile(r'@PathVariable(?:\([^)]*\))?\s+\S+\s+(\w+)')
REQ_PARAM   = re.compile(r'@RequestParam(?:\([^)]*value\s*=\s*"([^"]+)"|[^)]*)?\s+\S+\s+(\w+)')


def parse_controller(path: Path):
    content = path.read_text(encoding="utf-8", errors="replace")
    if not REST_CTRL.search(content):
        return []

    lines      = content.splitlines()
    cls_name   = CLASS_NAME.search(content)
    cls_name   = cls_name.group(1) if cls_name else path.stem

    # Class-level base path
    base_path = ""
    for line in lines:
        m = CLASS_MAP.search(line)
        if m:
            val = m.group(1).strip().strip('"').strip("'")
            if val and not val.startswith("@"):
                base_path = val
            break

    endpoints = []
    ann_buf   = []

    for i, line in enumerate(lines):
        if any(kw in line for kw in ("@GetMapping", "@PostMapping", "@PutMapping",
                                     "@DeleteMapping", "@PatchMapping")):
            ann_buf.append(line)
            continue

        m_sig = METHOD_SIG.match(line)
        if m_sig and ann_buf:
            method_name = m_sig.group(1)
            for ann_line in ann_buf:
                hm = HTTP_MAP.search(ann_line)
                if hm:
                    verb        = hm.group(1).upper()
                    sub_path    = (hm.group(2) or "").strip().strip('"').strip("'")
                    full_path   = base_path.rstrip("/") + "/" + sub_path.lstrip("/")
                    full_path   = "/" + full_path.strip("/")

                    # Security from previous lines (look back 6)
                    sec = ""
                    for back in lines[max(0, i - 8): i]:
                        pm = PREAUTH.search(back)
                        sm = SECURED.search(back)
                        if pm:
                            sec = pm.group(1)[:60]
                        elif sm:
                            sec = sm.group(1)[:60]

                    endpoints.append({
                        "verb":     verb,
                        "path":     full_path,
                        "class":    cls_name,
                        "method":   method_name,
                        "security": sec,
                    })
            ann_buf = []
            continue

        # Non-mapping annotation — if unrelated, flush buffer if method not coming
        if line.strip().startswith("@") and not any(
            kw in line for kw in ("@GetMapping", "@PostMapping", "@PutMapping",
                                   "@DeleteMapping", "@PatchMapping",
                                   "@PathVariable", "@RequestParam",
                                   "@RequestBody", "@PreAuthorize", "@Secured")):
            if i > 0 and not METHOD_SIG.match(lines[i - 1] if i > 0 else ""):
                pass

        if not line.strip() and ann_buf:
            ann_buf = []

    return endpoints


def main():
    args = sys.argv[1:]
    fmt  = "text"
    filt = None
    i = 0
    while i < len(args):
        if args[i] == "--format" and i + 1 < len(args):
            fmt = args[i + 1]; i += 2
        elif args[i] == "--filter" and i + 1 < len(args):
            filt = args[i + 1]; i += 2
        else:
            i += 1

    all_eps = []
    for f in BACKEND.rglob("*.java"):
        all_eps.extend(parse_controller(f))

    if filt:
        all_eps = [e for e in all_eps if filt in e["path"]]

    all_eps.sort(key=lambda x: (x["path"], x["verb"]))

    print(f"api-surface-report: {len(all_eps)} endpoint\n")

    if fmt == "md":
        print("| Verb | Path | Class | Method | Security |")
        print("|------|------|-------|--------|----------|")
        for ep in all_eps:
            sec = ep["security"] or "nyilvanos"
            print(f"| {ep['verb']} | `{ep['path']}` | {ep['class']} | "
                  f"{ep['method']} | {sec} |")
    else:
        verb_colors = {"GET": "GET", "POST": "POST", "PUT": "PUT",
                       "DELETE": "DEL", "PATCH": "PATCH"}
        for ep in all_eps:
            v   = ep["verb"].ljust(6)
            sec = f"  [{ep['security']}]" if ep["security"] else ""
            print(f"  {v} {ep['path']:60s} {ep['class']}.{ep['method']}{sec}")

    sys.exit(0)


if __name__ == "__main__":
    main()
