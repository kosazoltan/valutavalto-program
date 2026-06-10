#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
dto-entity-sync.py -- Entity <-> DTO mezo-lefedettseg ellenorzese.

Replaces: AI "are all fields covered in the DTO?" kerdesek.

Keres:
  - Java Entity mezok (privat fieldek, @Column / @Id nev)
  - Kapcsolodo DTO osztaly (SameName + DTO/Request/Response/Dto vegzodes)
  - Mezo-elteres: Entity-ben van, DTO-ban nincs (vagy fordiva)

Korlatai:
  - Egyszeru nev-egyeztetes (nem tipusellenorzos)
  - Oroklott mezok nem kovetve (parent entity)
  - @Embedded / @Embeddable nem boncolva

Usage:
  python scripts/dev-tools/dto-entity-sync.py
  python scripts/dev-tools/dto-entity-sync.py --entity Product

Exit: 0 = szinkronban, 1 = elteres talalhato
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
from pathlib import Path
from collections import defaultdict

ROOT    = Path(__file__).resolve().parent.parent.parent
BACKEND = ROOT / "backend" / "src" / "main" / "java"

ENTITY_ANN   = re.compile(r'@Entity\b')
FIELD_LINE   = re.compile(r'^\s+(?:private|protected)\s+\S+\s+(\w+)\s*[;=]')
TRANSIENT    = re.compile(r'@Transient\b')
CLASS_NAME   = re.compile(r'\bclass\s+(\w+)\b')
ID_ANN       = re.compile(r'@Id\b')

SKIP_FIELDS  = {"serialVersionUID", "logger", "log"}


def parse_fields(path: Path) -> list[str]:
    content = path.read_text(encoding="utf-8", errors="replace")
    lines   = content.splitlines()
    fields  = []
    skip_next = False
    for line in lines:
        if TRANSIENT.search(line):
            skip_next = True
            continue
        if skip_next:
            skip_next = False
            continue
        m = FIELD_LINE.match(line)
        if m:
            name = m.group(1)
            if name not in SKIP_FIELDS and not name.startswith("_"):
                fields.append(name)
    return fields


def find_entities(base: Path, entity_filter: str | None) -> dict[str, Path]:
    entities = {}
    for f in base.rglob("*.java"):
        content = f.read_text(encoding="utf-8", errors="replace")
        if not ENTITY_ANN.search(content):
            continue
        m = CLASS_NAME.search(content)
        if not m:
            continue
        name = m.group(1)
        if entity_filter and entity_filter.lower() not in name.lower():
            continue
        entities[name] = f
    return entities


def find_dto(base: Path, entity_name: str) -> dict[str, list[str]]:
    suffixes = ("DTO", "Dto", "Request", "Response", "Form")
    results  = {}
    for f in base.rglob("*.java"):
        stem = f.stem
        if not any(stem.startswith(entity_name) and stem.endswith(s) for s in suffixes):
            continue
        fields = parse_fields(f)
        if fields:
            results[stem] = fields
    return results


def main():
    args = sys.argv[1:]
    entity_filter = None
    i = 0
    while i < len(args):
        if args[i] == "--entity" and i + 1 < len(args):
            entity_filter = args[i + 1]; i += 2
        else:
            i += 1

    entities  = find_entities(BACKEND, entity_filter)
    issues    = []
    pairs     = 0

    for entity_name, entity_path in sorted(entities.items()):
        e_fields = set(parse_fields(entity_path))
        dtos     = find_dto(BACKEND, entity_name)
        if not dtos:
            continue
        pairs += 1
        for dto_name, d_fields_list in dtos.items():
            d_fields = set(d_fields_list)
            missing_in_dto    = e_fields - d_fields
            unexpected_in_dto = d_fields - e_fields
            if missing_in_dto or unexpected_in_dto:
                issues.append((entity_name, dto_name,
                               sorted(missing_in_dto),
                               sorted(unexpected_in_dto)))

    print(f"dto-entity-sync: {len(entities)} entity, {pairs} entity-DTO par, "
          f"{len(issues)} elteres\n")

    if not issues:
        print("  OK -- minden DTO szinkronban az Entityvel")
        sys.exit(0)

    for entity_name, dto_name, missing, extra in issues:
        print(f"  [{entity_name} <-> {dto_name}]")
        if missing:
            print(f"    Entity-ben van, DTO-ban NINCS: {', '.join(missing)}")
        if extra:
            print(f"    DTO-ban van, Entity-ben NINCS:  {', '.join(extra)}")
        print()

    sys.exit(1)


if __name__ == "__main__":
    main()
