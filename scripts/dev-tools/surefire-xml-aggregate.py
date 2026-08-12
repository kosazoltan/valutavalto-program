#!/usr/bin/env python3
"""Surefire XML aggregator.

A `.txt` riportok aggregalasa VAK a @Nested osztalyok tesztjeire (bizonyitva:
.hermes/evidence/2026-08-11/E-surefire-nested-aggregacio-vakfolt.md — a txt GREEN-t
mutat, mikozben az XML FAIL). Ezert a hiteles forras az XML.

Hasznalat: python3 scripts/dev-tools/surefire-xml-aggregate.py [reports_dir]
Exit 0 = zold, 1 = van bukas/hiba.
"""
import sys
import glob
import os
import xml.etree.ElementTree as ET

reports = sys.argv[1] if len(sys.argv) > 1 else "backend/target/surefire-reports"

suites = tests = failures = errors = skipped = 0
bad = []

for path in glob.glob(os.path.join(reports, "*.xml")):
    if not os.path.basename(path).startswith("TEST-"):
        continue
    try:
        root = ET.parse(path).getroot()
    except ET.ParseError as exc:
        bad.append((os.path.basename(path), f"UNPARSEABLE: {exc}"))
        continue
    suites += 1
    tests += int(root.get("tests", 0))
    f = int(root.get("failures", 0))
    e = int(root.get("errors", 0))
    failures += f
    errors += e
    skipped += int(root.get("skipped", 0))
    if f or e:
        bad.append((root.get("name", os.path.basename(path)), f"failures={f} errors={e}"))

print(f"suites={suites} tests={tests} failures={failures} errors={errors} skipped={skipped}")
for name, detail in sorted(bad):
    print(f"  FAIL {name}: {detail}")

sys.exit(1 if (failures or errors or bad) else 0)
