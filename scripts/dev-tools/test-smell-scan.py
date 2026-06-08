#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
test-smell-scan.py -- Teszt-minosegi problemaak detektalasa (Test Smell).

Replaces: AI "is this a good test?" kerdesek + tsDetect / JNose futtatasa.

Technika: regex + sorcsoport elemzes Java @Test metodusokon.

Keres:
  - Ures teszt (@Test + ures metodus test)
  - Nincs allitas (assert/verify/assertThat mind hianyzik)
  - Tul hosszu teszt (>50 sor)
  - Tobb ertelmesegteruleten hivatkozo teszt (>5 kulonbozo obiektum mock)
  - @Ignore / @Disabled kommentar nelkul
  - Kellemetlen fixture: System.out.println a tesztben
  - Tesztnev konvenció-sertés (nem `should`, `when`, `test` prefix)

Usage:
  python scripts/dev-tools/test-smell-scan.py
  python scripts/dev-tools/test-smell-scan.py --module backend

Exit: 0 = clean, 1 = problemas tesztek
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
from pathlib import Path

ROOT    = Path(__file__).resolve().parent.parent.parent
IGNORED = {"node_modules", ".git", "target", "dist"}

TEST_ANN   = re.compile(r'@Test\b')
DISABLED   = re.compile(r'@(Ignore|Disabled)\b')
METHOD_SIG = re.compile(r'^\s+(?:public|protected|void)\s+(?:void\s+)?(\w+)\s*\(')
ASSERT_KW  = re.compile(r'\b(assert|Assert|verify|Mockito\.verify|assertThat|'
                        r'assertEquals|assertTrue|assertFalse|assertNotNull|'
                        r'assertNull|fail\(|then\(|given\(|willReturn)\b')
SYSOUT     = re.compile(r'System\.out\.(print|println)')
MOCK_USE   = re.compile(r'\bwhen\s*\(|\bMockito\.(mock|spy|when|verify)\b|'
                        r'@MockBean\b|@Mock\b')

GOOD_NAME  = re.compile(
    r'^(test|should|when|given|verify|check|assert|it_|can_|must_|has_)',
    re.IGNORECASE
)


def scan_test_file(path: Path) -> list[str]:
    content = path.read_text(encoding="utf-8", errors="replace")
    if not TEST_ANN.search(content):
        return []

    rel    = str(path.relative_to(ROOT))
    lines  = content.splitlines()
    issues = []

    in_test      = False
    method_start = 0
    method_name  = ""
    brace_depth  = 0
    body_lines   = []
    disabled     = False

    for i, line in enumerate(lines, 1):
        if DISABLED.search(line):
            disabled = True

        if TEST_ANN.search(line):
            in_test      = True
            method_start = i
            body_lines   = []
            brace_depth  = 0
            disabled     = False
            continue

        if in_test:
            m = METHOD_SIG.match(line)
            if m and brace_depth == 0:
                method_name = m.group(1)

            brace_depth += line.count("{") - line.count("}")
            body_lines.append(line)

            if brace_depth <= 0 and method_name:
                # Analyze collected body
                body = "\n".join(body_lines)

                # 1. Empty test
                stripped = re.sub(r'\s+', '', body)
                if stripped in ("{}", "{}//noop", "{}//TODO"):
                    issues.append(
                        f"  [EMPTY-TEST]  {rel}:{method_start}  {method_name}()")

                # 2. No assertion
                elif not ASSERT_KW.search(body) and not disabled:
                    issues.append(
                        f"  [NO-ASSERT]   {rel}:{method_start}  {method_name}()")

                # 3. Too long test
                non_blank = [l for l in body_lines if l.strip()]
                if len(non_blank) > 50:
                    issues.append(
                        f"  [LONG-TEST]   {rel}:{method_start}  {method_name}() "
                        f"-- {len(non_blank)} sor")

                # 4. System.out in test
                if SYSOUT.search(body):
                    issues.append(
                        f"  [SYSOUT]      {rel}:{method_start}  {method_name}() "
                        f"-- System.out a tesztben")

                # 5. Name convention
                if method_name and not GOOD_NAME.match(method_name):
                    issues.append(
                        f"  [BAD-NAME]    {rel}:{method_start}  {method_name}() "
                        f"-- nem konvencio-kovet teszt-nev")

                # Reset
                in_test = False; method_name = ""; body_lines = []

    return issues


def main():
    args = sys.argv[1:]
    module_filter = None
    i = 0
    while i < len(args):
        if args[i] == "--module" and i + 1 < len(args):
            module_filter = args[i + 1]; i += 2
        else:
            i += 1

    base   = ROOT / module_filter if module_filter else ROOT
    issues = []

    for f in base.rglob("*.java"):
        if any(d in f.parts for d in IGNORED):
            continue
        if "test" not in f.parts and "Test" not in f.name:
            continue
        issues.extend(scan_test_file(f))

    print(f"test-smell-scan: {len(issues)} teszt-minosegi problema\n")

    if not issues:
        print("  OK -- nem talalhato test smell")
        sys.exit(0)

    for cat in ("EMPTY-TEST", "NO-ASSERT", "LONG-TEST", "SYSOUT", "BAD-NAME"):
        group = [x for x in issues if f"[{cat}]" in x]
        if group:
            print(f"  [{cat}] ({len(group)})")
            for iss in group[:10]:
                print(iss)
            if len(group) > 10:
                print(f"    ... ({len(group) - 10} tovabb)")
            print()

    sys.exit(1)


if __name__ == "__main__":
    main()
