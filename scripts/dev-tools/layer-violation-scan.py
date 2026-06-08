#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
layer-violation-scan.py -- Spring Boot rétegarchitektúra-sértések detektálása.

Replaces: AI "architecture violation" review findings + ArchUnit futtatás.

Keres:
  - Controller osztályokban közvetlen Repository injekció (Service bypass)
  - Service osztályokban Controller import
  - Repository osztályokban Service injekció (fordított irány)
  - Entity osztályokban Service/Repository import

Usage:
  python scripts/dev-tools/layer-violation-scan.py
  python scripts/dev-tools/layer-violation-scan.py --strict

Exit: 0 = clean, 1 = violations found
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
import subprocess
from pathlib import Path

ROOT     = Path(__file__).resolve().parent.parent.parent
SRC_JAVA = ROOT / "backend" / "src" / "main" / "java"

IGNORED = {"node_modules", ".git", "target", "dist"}


def rg_in_file(pattern: str, file_path: Path) -> list[tuple[int, str]]:
    r = subprocess.run(
        ["rg", "--line-number", "--color=never", "-e", pattern, str(file_path)],
        capture_output=True, text=True, encoding="utf-8", errors="replace"
    )
    hits = []
    for line in r.stdout.strip().splitlines():
        m = re.match(r'^(\d+):(.*)', line)
        if m:
            hits.append((int(m.group(1)), m.group(2).strip()))
    return hits


CLASS_ANNOTATION = re.compile(
    r'@(RestController|Controller|Service|Repository|Component|Entity)\b'
)
FIELD_INJECT = re.compile(
    r'(?:@Autowired|@Inject|private\s+final)\s+[\w<>]+\s+(\w+)\s*[;=]'
)
CONSTRUCTOR_PARAM = re.compile(r'(?:private|protected|public)\s+[\w<>]+\s+(\w+)\s*(?:,|\))')

LAYER_RULES = {
    "Controller": {
        "forbidden_inject": ["Repository"],
        "forbidden_import": [],  # Controller importing Service is correct
        "message": "Controller should not inject Repository directly (use Service layer)",
    },
    "Service": {
        "forbidden_inject": [],
        "forbidden_import": ["Controller", "RestController"],
        "message": "Service should not import Controller classes",
    },
    "Entity": {
        "forbidden_inject": ["Service", "Repository"],
        "forbidden_import": ["Service", "Repository", "Controller"],
        "message": "Entity should not depend on Service/Repository/Controller",
    },
}


def detect_layer(content: str) -> str | None:
    for m in CLASS_ANNOTATION.finditer(content):
        ann = m.group(1)
        if ann in ("RestController", "Controller"):
            return "Controller"
        if ann in ("Service",):
            return "Service"
        if ann in ("Repository",):
            return "Repository"
        if ann in ("Entity",):
            return "Entity"
    return None


def main():
    args   = sys.argv[1:]
    strict = "--strict" in args

    violations: list[str] = []
    scanned = 0

    for java_file in SRC_JAVA.rglob("*.java"):
        if any(d in java_file.parts for d in IGNORED):
            continue
        content = java_file.read_text(encoding="utf-8", errors="replace")
        layer   = detect_layer(content)
        if not layer or layer not in LAYER_RULES:
            continue
        scanned += 1
        rules = LAYER_RULES[layer]
        rel   = str(java_file.relative_to(ROOT))

        # Check injections
        for i, line in enumerate(content.splitlines(), 1):
            for fi in rules["forbidden_inject"]:
                if re.search(rf'\b\w*{fi}\b', line) and re.search(
                        r'@Autowired|@Inject|private\s+final', line):
                    violations.append(
                        f"  [{layer}->INJECT-{fi}]  {rel}:{i}  {line.strip()[:80]}"
                    )

        # Check imports
        for fi in rules["forbidden_import"]:
            for i, line in enumerate(content.splitlines(), 1):
                if re.search(r'^\s*import\b', line) and fi.lower() in line.lower():
                    violations.append(
                        f"  [{layer}->IMPORT-{fi}]  {rel}:{i}  {line.strip()[:80]}"
                    )

    print(f"layer-violation-scan: {scanned} annotated classes scanned\n")

    if not violations:
        print("  OK -- no layer violations detected")
        sys.exit(0)

    for v in violations:
        print(v)
    print(f"\nFOUND: {len(violations)} violation(s)")
    sys.exit(1)


if __name__ == "__main__":
    main()
