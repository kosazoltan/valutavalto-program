#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
changelog-gen.py -- Conventional Commits alapu CHANGELOG generálas.

Replaces: Kézi changelog összeállítás + AI "summarize changes" kérések.

Feldolgoz: feat/fix/perf/refactor/docs/chore/test/ci konvenciót
Kihagyja:  merge commit-eket, verzió-bump commit-eket

Usage:
  python scripts/dev-tools/changelog-gen.py
  python scripts/dev-tools/changelog-gen.py --from v2.27.90
  python scripts/dev-tools/changelog-gen.py --from HEAD~50 --to HEAD
  python scripts/dev-tools/changelog-gen.py --output CHANGELOG_DRAFT.md

Exit: 0 = OK
"""
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import re
import subprocess
from pathlib import Path
from datetime import datetime

ROOT = Path(__file__).resolve().parent.parent.parent

CONV_COMMIT = re.compile(
    r'^(?P<type>feat|fix|perf|refactor|docs|chore|test|ci|build|style|revert)'
    r'(?:\((?P<scope>[^)]+)\))?(?P<breaking>!)?\s*:\s*(?P<desc>.+)$',
    re.IGNORECASE
)

TYPE_LABELS = {
    "feat":     "Uj funkciok",
    "fix":      "Hibajavitasok",
    "perf":     "Teljesitmeny",
    "refactor": "Refaktoralas",
    "docs":     "Dokumentacio",
    "chore":    "Karbantartas",
    "test":     "Tesztek",
    "ci":       "CI/CD",
    "build":    "Build",
    "style":    "Kodstilus",
    "revert":   "Visszavorasok",
}

SKIP_PATTERNS = re.compile(
    r'^(Merge|chore\(release\)|verzio-bump|version bump)',
    re.IGNORECASE
)


def git_log(from_ref: str | None, to_ref: str) -> list[tuple[str, str]]:
    """Returns [(hash, subject), ...]"""
    ref_range = f"{from_ref}..{to_ref}" if from_ref else to_ref
    cmd = ["git", "log", "--oneline", "--no-merges", ref_range]
    r = subprocess.run(cmd, capture_output=True, text=True,
                       encoding="utf-8", errors="replace", cwd=ROOT)
    results = []
    for line in r.stdout.strip().splitlines():
        parts = line.split(" ", 1)
        if len(parts) == 2:
            results.append((parts[0], parts[1].strip()))
    return results


def main():
    args      = sys.argv[1:]
    from_ref  = None
    to_ref    = "HEAD"
    output    = None
    i = 0
    while i < len(args):
        if args[i] == "--from" and i + 1 < len(args):
            from_ref = args[i + 1]; i += 2
        elif args[i] == "--to" and i + 1 < len(args):
            to_ref = args[i + 1]; i += 2
        elif args[i] == "--output" and i + 1 < len(args):
            output = args[i + 1]; i += 2
        else:
            i += 1

    commits = git_log(from_ref, to_ref)
    if not commits:
        print("changelog-gen: no commits found in range")
        sys.exit(0)

    # Parse and group
    by_type: dict[str, list[tuple[str, str, str]]] = {}  # type -> [(hash, scope, desc)]
    breaking: list[tuple[str, str, str, str]] = []
    unknown:  list[tuple[str, str]] = []

    for h, subject in commits:
        if SKIP_PATTERNS.match(subject):
            continue
        m = CONV_COMMIT.match(subject)
        if m:
            t     = m.group("type").lower()
            scope = m.group("scope") or ""
            desc  = m.group("desc")
            brk   = bool(m.group("breaking"))
            if brk:
                breaking.append((h, t, scope, desc))
            by_type.setdefault(t, []).append((h, scope, desc))
        else:
            unknown.append((h, subject))

    # Build output
    lines: list[str] = []
    today = datetime.now().strftime("%Y-%m-%d")
    range_str = f"{from_ref}..{to_ref}" if from_ref else to_ref
    lines.append(f"# Changelog -- {today}")
    lines.append(f"_Range: {range_str}_\n")

    if breaking:
        lines.append("## BREAKING CHANGES")
        for h, t, scope, desc in breaking:
            scope_str = f"**{scope}**: " if scope else ""
            lines.append(f"- {scope_str}{desc} ({h})")
        lines.append("")

    for t in ("feat", "fix", "perf", "refactor", "docs", "chore", "test", "ci", "build"):
        entries = by_type.get(t, [])
        if not entries:
            continue
        label = TYPE_LABELS.get(t, t)
        lines.append(f"## {label}")
        for h, scope, desc in entries:
            scope_str = f"**{scope}**: " if scope else ""
            lines.append(f"- {scope_str}{desc} ({h})")
        lines.append("")

    if unknown:
        lines.append("## Egyeb")
        for h, subject in unknown[:10]:
            lines.append(f"- {subject} ({h})")
        lines.append("")

    total_entries = sum(len(v) for v in by_type.values())
    lines.append(f"_Total: {total_entries} entry, {len(commits)} commit_")

    content = "\n".join(lines)

    if output:
        Path(output).write_text(content, encoding="utf-8")
        print(f"changelog-gen: {total_entries} entries written to {output}")
    else:
        print(content)

    sys.exit(0)


if __name__ == "__main__":
    main()
