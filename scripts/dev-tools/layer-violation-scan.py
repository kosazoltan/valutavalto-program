#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
layer-violation-scan.py -- Spring Boot rétegarchitektúra-sértések detektálása
                           + RATCHET-kapu (a technikai adósság nem nőhet).

Replaces: AI "architecture violation" review findings + ArchUnit futtatás.

Keres (Clean Architecture függőségi szabály):
  - Controller osztályokban közvetlen Repository injekció (Service bypass)
  - Service osztályokban Controller import
  - Repository osztályokban Service injekció (fordított irány)
  - Entity osztályokban Service/Repository import

MIÉRT RATCHET, ÉS NEM SIMA KAPU
-------------------------------
A repo mért kiindulóállapota 2026-08-11-en 39 sértés volt (23 controller).
Ezt EGY PR-ben javítani élő pénzügyi rendszerben felmérhetetlen blast radius:
az OSIV ki van kapcsolva (lazy csak service-tranzakción belül) és a
CashLockOrdering lock-sorrend a service-rétegben él, így minden áthelyezés
tranzakcióhatárt mozgat. Ezért a mért adósságot BASELINE-ként rögzítjük:
  - ÚJ sértés  -> exit 1 (a CI bukik)
  - MEGSZŰNT sértés -> exit 0 + felhívás a baseline frissítésére (a racsni
    csak lefelé enged)
Így az audit-eszköz nem "write-only riport", hanem kapu, ami monoton csökkenő
adósságot kényszerít ki.

Usage:
  python scripts/dev-tools/layer-violation-scan.py                 # riport, exit 1 ha van sértés
  python scripts/dev-tools/layer-violation-scan.py --check-baseline # RATCHET (ezt hívja a CI)
  python scripts/dev-tools/layer-violation-scan.py --write-baseline # baseline (újra)rögzítése
  python scripts/dev-tools/layer-violation-scan.py --json           # gépi kimenet

Exit:
  0 = clean / baseline-nal egyezo vagy annal jobb
  1 = sertes (alap mod) vagy UJ sertes (--check-baseline)
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import json
import re
from collections import Counter
from pathlib import Path

ROOT     = Path(__file__).resolve().parent.parent.parent
SRC_JAVA = ROOT / "backend" / "src" / "main" / "java"
BASELINE = Path(__file__).resolve().parent / "layer-violation.baseline.json"

IGNORED = {"node_modules", ".git", "target", "dist"}


CLASS_ANNOTATION = re.compile(
    r'@(RestController|Controller|Service|Repository|Component|Entity)\b'
)

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


def scan() -> tuple[list[dict], int]:
    """Visszaadja a sérteseket es a vizsgalt osztalyok szamat.

    A sertes kulcsa SZANDEKOSAN nem tartalmaz sorszamot: a baseline nem
    torhet el attol, hogy valaki beszur egy sort a fajl elejere. A kulcs
    (posix relativ ut, reteg, szabaly) harmas + darabszam.
    """
    violations: list[dict] = []
    scanned = 0

    for java_file in sorted(SRC_JAVA.rglob("*.java")):
        if any(d in java_file.parts for d in IGNORED):
            continue
        content = java_file.read_text(encoding="utf-8", errors="replace")
        layer   = detect_layer(content)
        if not layer or layer not in LAYER_RULES:
            continue
        scanned += 1
        rules = LAYER_RULES[layer]
        rel   = java_file.relative_to(ROOT).as_posix()
        lines = content.splitlines()

        # Check injections
        for i, line in enumerate(lines, 1):
            for fi in rules["forbidden_inject"]:
                if re.search(rf'\b\w*{fi}\b', line) and re.search(
                        r'@Autowired|@Inject|private\s+final', line):
                    violations.append({
                        "key": f"{rel}::{layer}->INJECT-{fi}",
                        "file": rel, "line": i, "layer": layer,
                        "rule": f"INJECT-{fi}", "code": line.strip()[:120],
                    })

        # Check imports
        for fi in rules["forbidden_import"]:
            for i, line in enumerate(lines, 1):
                if re.search(r'^\s*import\b', line) and fi.lower() in line.lower():
                    violations.append({
                        "key": f"{rel}::{layer}->IMPORT-{fi}",
                        "file": rel, "line": i, "layer": layer,
                        "rule": f"IMPORT-{fi}", "code": line.strip()[:120],
                    })

    return violations, scanned


def counts(violations: list[dict]) -> Counter:
    return Counter(v["key"] for v in violations)


def load_baseline() -> dict | None:
    if not BASELINE.exists():
        return None
    return json.loads(BASELINE.read_text(encoding="utf-8"))


def write_baseline(violations: list[dict], scanned: int) -> None:
    c = counts(violations)
    payload = {
        "_comment": (
            "Layer-violation RATCHET baseline. A technikai adossag itt rogzitett "
            "merteke NEM NOHET. Uj sertes -> CI bukik. Ha javitottal, futtasd: "
            "python scripts/dev-tools/layer-violation-scan.py --write-baseline "
            "es commitold a csokkent szamokat. A szamok NOVELESE code review-ban "
            "indoklas nelkul elutasitando."
        ),
        "_generated_by": "scripts/dev-tools/layer-violation-scan.py --write-baseline",
        "total": sum(c.values()),
        "scanned_classes": scanned,
        "violations": dict(sorted(c.items())),
    }
    BASELINE.write_text(
        json.dumps(payload, indent=2, ensure_ascii=True) + "\n", encoding="utf-8"
    )
    print(f"baseline written: {BASELINE.relative_to(ROOT).as_posix()}  "
          f"({payload['total']} violation(s) in {len(c)} location(s))")


def check_baseline(violations: list[dict], scanned: int) -> int:
    base = load_baseline()
    if base is None:
        print("ERROR: baseline missing. Run --write-baseline first.", file=sys.stderr)
        return 1

    cur  = counts(violations)
    prev = Counter(base.get("violations", {}))

    new_keys   = sorted(set(cur) - set(prev))
    fixed_keys = sorted(set(prev) - set(cur))
    grown      = sorted(k for k in set(cur) & set(prev) if cur[k] > prev[k])
    shrunk     = sorted(k for k in set(cur) & set(prev) if cur[k] < prev[k])

    total_cur, total_prev = sum(cur.values()), sum(prev.values())
    print(f"layer-violation RATCHET: {scanned} annotated classes scanned")
    print(f"  baseline: {total_prev} violation(s) | current: {total_cur} violation(s)\n")

    if new_keys or grown:
        print("REGRESSION -- the architecture debt GREW. This is a blocking failure.\n")
        for k in new_keys:
            print(f"  [NEW]   {k}  (x{cur[k]})")
            for v in violations:
                if v["key"] == k:
                    print(f"          {v['file']}:{v['line']}  {v['code']}")
        for k in grown:
            print(f"  [GROWN] {k}  {prev[k]} -> {cur[k]}")
        print(
            "\nFix: route the call through the Service layer (Controller must not\n"
            "inject a Repository). The transaction boundary and CashLockOrdering\n"
            "live in the Service layer; OSIV is disabled, so a Controller-level\n"
            "repository read has no transaction and can hit lazy-init or lock-order\n"
            "problems. See vault/elvi/mernoki-alapelvek-valutavalto-kontextus.md."
        )
        return 1

    if fixed_keys or shrunk:
        print("IMPROVED -- architecture debt shrank. Refresh the baseline:\n")
        for k in fixed_keys:
            print(f"  [FIXED]  {k}  (was x{prev[k]})")
        for k in shrunk:
            print(f"  [SHRUNK] {k}  {prev[k]} -> {cur[k]}")
        print("\n  python scripts/dev-tools/layer-violation-scan.py --write-baseline")
        return 0

    print("  OK -- no new layer violations (debt unchanged at baseline).")
    return 0


def main():
    args = sys.argv[1:]
    violations, scanned = scan()

    if "--json" in args:
        print(json.dumps(
            {"scanned": scanned, "total": len(violations), "violations": violations},
            indent=2, ensure_ascii=False))
        return 0 if not violations else 1

    if "--write-baseline" in args:
        write_baseline(violations, scanned)
        return 0

    if "--check-baseline" in args:
        return check_baseline(violations, scanned)

    print(f"layer-violation-scan: {scanned} annotated classes scanned\n")
    if not violations:
        print("  OK -- no layer violations detected")
        return 0
    for v in violations:
        print(f"  [{v['layer']}->{v['rule']}]  {v['file']}:{v['line']}  {v['code'][:80]}")
    print(f"\nFOUND: {len(violations)} violation(s)")
    return 1


if __name__ == "__main__":
    sys.exit(main())
