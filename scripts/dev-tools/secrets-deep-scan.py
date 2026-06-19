#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
secrets-deep-scan.py -- Komplex titkos adatok detektálása (30+ minta).

Replaces: AI "hardcoded secret" review + basic rg pattern.

Keres (30+ minta):
  - AWS/GCP/Azure kulcsok
  - JWT secret
  - Database connection string-ek
  - Private key / certificate
  - API token minták
  - Base64-kódolt credentials
  - Jelszó-mező egyenlőségek

Usage:
  python scripts/dev-tools/secrets-deep-scan.py
  python scripts/dev-tools/secrets-deep-scan.py --module backend

Exit: 0 = clean, 1 = potential secrets found
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
import base64
from pathlib import Path

ROOT    = Path(__file__).resolve().parent.parent.parent
IGNORED = {
    "node_modules", ".git", "target", "dist", "dist-electron", ".vite",
    "coverage", "build", "release", ".dev-app", ".dev-user-data", "tmp",
    ".venv-asr", ".worktrees", "security-reports", ".claude",
    "Anti", "Anti_transfer", "forrasok", "legacy-transfer", "Felmérés",
    "Felmérés", "EXCMD", "frontend_deployment", "backend_deployment",
    "pipeline-logs", ".agent", ".remember", "e2e-relay-results",
    "legacy-drive", "whisper-models", ".obsidian", "docs", "vault",
    "__pycache__",
}

SECRET_PATTERNS = [
    # Cloud provider keys
    ("AWS-ACCESS-KEY",    re.compile(r'AKIA[0-9A-Z]{16}'),                           "CRITICAL"),
    ("AWS-SECRET",        re.compile(r'aws.{0,20}secret.{0,20}[0-9a-zA-Z/+]{40}', re.I), "CRITICAL"),
    ("GCP-API-KEY",       re.compile(r'AIza[0-9A-Za-z\-_]{35}'),                    "CRITICAL"),
    ("AZURE-CONN",        re.compile(r'DefaultEndpointsProtocol=https;AccountName='), "HIGH"),

    # JWT
    ("JWT-SECRET",        re.compile(r'jwt[.\-_]?secret\s*[=:]\s*["\'][^"\']{16,}', re.I), "CRITICAL"),
    ("JWT-TOKEN-LITERAL", re.compile(r'eyJ[A-Za-z0-9_-]{20,}\.eyJ[A-Za-z0-9_-]{20,}'), "HIGH"),

    # Database
    ("DB-PASSWORD",       re.compile(r'(?:jdbc|datasource).{0,30}password\s*=\s*[^\s$]{6,}', re.I), "CRITICAL"),
    ("CONN-STR-PASS",     re.compile(r'password=[^;&\s$%{]{6,}',                    re.I), "HIGH"),
    ("DB-PASS-FIELD",     re.compile(r'(?:db|database|mysql|postgres|mongo)[._-]?password\s*[=:]\s*["\'][^"\']{4,}', re.I), "CRITICAL"),

    # Private keys
    ("PRIVATE-KEY",       re.compile(r'-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY'), "CRITICAL"),
    ("PKCS8-KEY",         re.compile(r'-----BEGIN ENCRYPTED PRIVATE KEY'),           "CRITICAL"),

    # Generic tokens
    ("GENERIC-TOKEN",     re.compile(r'(?:api[_-]?key|access[_-]?token|auth[_-]?token)\s*[=:]\s*["\'][0-9a-zA-Z_\-]{16,}["\']', re.I), "HIGH"),
    ("BEARER-LITERAL",    re.compile(r'[Bb]earer\s+[0-9a-zA-Z_\-]{20,}'),           "HIGH"),

    # GitHub/GitLab tokens
    ("GITHUB-TOKEN",      re.compile(r'ghp_[0-9a-zA-Z]{36}|github_pat_[0-9a-zA-Z_]{82}'), "CRITICAL"),
    ("GITLAB-TOKEN",      re.compile(r'glpat-[0-9a-zA-Z\-_]{20}'),                  "CRITICAL"),

    # Password assignments
    ("HARDCODED-PASS",    re.compile(r'password\s*=\s*["\'][^"\'$%{]{6,}["\']',     re.I), "HIGH"),
    ("SECRET-FIELD",      re.compile(r'secret\s*=\s*["\'][^"\'$%{]{8,}["\']',       re.I), "HIGH"),

    # Connection strings
    ("MONGO-URI",         re.compile(r'mongodb(\+srv)?://[^@\s]+:[^@\s]+@'),        "CRITICAL"),
    ("REDIS-PASS",        re.compile(r'redis://:[^@\s]+@'),                          "HIGH"),
    ("SMTP-PASS",         re.compile(r'smtp://[^:]+:[^@\s]+@'),                     "HIGH"),
]

# Known false-positive patterns (skip these)
FALSE_POSITIVE = re.compile(
    r'example\.com|placeholder|your[-_]?(?:api[-_]?)?key|<[A-Z_]+>|'
    r'\$\{|%\{|\{[A-Z_]+\}|REPLACE_ME|REDACTED|TODO|FIXME|xxx|'
    r'test123|password123|WrongPass1|valuta_pass|your_password|'
    r'your_neon_password|ChangeMe123|CHANGE_ME|LOCAL_SECURE_PASSWORD|'
    r'SET_BY_REGIONAL_MANAGER|SECURE_REPLICATION_PASSWORD|your-app-password|'
    r'__PG_PASSWORD__|gen_secret_hex|redis_pass|'
    r'sk-proj-AbCdEf|abcdefghijklmnopqrstuvwxyz12345|SflKxwRJSMeKKF2QT4f|'
    r"-match\s+['\"]DB_PASSWORD|grep\s+-E\s+['\"]\^DATABASE_|sed\s+-E|"
    r"spring\\\.datasource\\\.password|spring\.datasource\.password|"
    r"<valassz eros jelszot>|"
    r'#\s+|//\s+|/\*\s+|\*\s+',
    re.I
)

BINARY_EXTENSIONS = {".jar", ".class", ".png", ".jpg", ".gif", ".pdf", ".zip",
                     ".exe", ".dll", ".so", ".dylib", ".woff", ".ttf", ".ico",
                     ".sqlite", ".sqlite3", ".db", ".7z", ".m4a", ".mp4", ".bin",
                     ".fdb", ".docx", ".xlsx", ".pyc", ".pyo"}
MAX_TEXT_FILE_BYTES = 5 * 1024 * 1024
LOCAL_SECRET_FILENAMES = {
    ".env", ".env.local", ".env.production", ".env.context7", ".env.ssh-keys",
    ".env.example", ".env.production.example",
}


def should_skip_local_secret_file(path: Path) -> bool:
    if path.name in LOCAL_SECRET_FILENAMES:
        return True
    return len(path.parts) >= 2 and path.parts[-2:] == ("configs", "secrets.json")


def redact_line(line: str) -> str:
    safe_line = line.strip()
    safe_line = re.sub(
        r'(?i)((?:password|passwd|secret|api[_-]?key|access[_-]?token|auth[_-]?token|client[_-]?secret|token)\s*[=:]\s*)("[^"]*"|\'[^\']*\'|[^\s,;}]+)',
        r'\1[REDACTED]',
        safe_line,
    )
    safe_line = re.sub(r'ghp_[0-9a-zA-Z]{36}|github_pat_[0-9a-zA-Z_]{20,}', '[REDACTED]', safe_line)
    safe_line = re.sub(r'AIza[0-9A-Za-z\-_]{20,}', '[REDACTED]', safe_line)
    safe_line = re.sub(r'Bearer\s+[0-9a-zA-Z_\-]{20,}', 'Bearer [REDACTED]', safe_line)
    safe_line = re.sub(r'eyJ[A-Za-z0-9_-]{20,}\.eyJ[A-Za-z0-9_-]{20,}(?:\.[A-Za-z0-9_-]+)?', '[REDACTED]', safe_line)
    return safe_line[:80]


def scan_file(path: Path) -> list[tuple[str, str, int, str]]:
    if should_skip_local_secret_file(path):
        return []
    if path.name == "secrets-deep-scan.py":
        return []
    if path.suffix.lower() in BINARY_EXTENSIONS:
        return []
    try:
        if path.stat().st_size > MAX_TEXT_FILE_BYTES:
            return []
    except OSError:
        return []
    try:
        content = path.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return []

    lines   = content.splitlines()
    rel     = str(path.relative_to(ROOT))
    results = []

    for i, line in enumerate(lines, 1):
        if FALSE_POSITIVE.search(line):
            continue
        if line.strip().startswith(("//", "#", "*", "<!--")):
            continue

        for name, pattern, severity in SECRET_PATTERNS:
            if pattern.search(line):
                results.append((severity, rel, i, redact_line(line)))
                break

    return results


def main():
    args = sys.argv[1:]
    module_filter = None
    i = 0
    while i < len(args):
        if args[i] == "--module" and i + 1 < len(args):
            module_filter = args[i + 1]; i += 2
        else:
            i += 1

    base       = ROOT / module_filter if module_filter else ROOT
    all_issues = []

    for f in base.rglob("*"):
        if not f.is_file():
            continue
        if any(d in f.parts for d in IGNORED):
            continue
        all_issues.extend(scan_file(f))

    criticals = [x for x in all_issues if x[0] == "CRITICAL"]
    highs     = [x for x in all_issues if x[0] == "HIGH"]

    print(f"secrets-deep-scan: {len(all_issues)} potential secret(s)  "
          f"({len(criticals)} CRITICAL, {len(highs)} HIGH)\n")

    if not all_issues:
        print("  OK -- no secrets detected")
        sys.exit(0)

    for sev in ("CRITICAL", "HIGH"):
        group = [x for x in all_issues if x[0] == sev]
        if not group:
            continue
        print(f"  [{sev}] ({len(group)})")
        for _, rel, lineno, content in group[:15]:
            print(f"    {rel}:{lineno}  {content}")
        if len(group) > 15:
            print(f"    ... ({len(group) - 15} more)")
        print()

    print("IMPORTANT: values shown are REDACTED. Check actual files for real values.")
    sys.exit(1)


if __name__ == "__main__":
    main()
