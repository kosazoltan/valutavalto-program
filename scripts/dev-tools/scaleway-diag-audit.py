#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Audit the read-only Scaleway diag workflow's probe contract.

Statically asserts (no secrets, no network):
  * the remote probe script is strictly read-only (no mutation commands),
  * every required diagnosis field is emitted,
  * psql errors are never discarded (no 2>/dev/null on the recovery probe),
  * stderr is redacted before it is byte-capped,
  * a PG_PROBE_STATUS=OK|FAILED verdict is always produced.

Exit 0 = all assertions pass; exit 1 = failures listed on stdout.
--self-test: mutate the probe text in memory and require detection.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import Any

import yaml

ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = ROOT / ".github" / "workflows" / "scaleway-diag.yml"

PROBE_STEP = "READ-ONLY HA + watchdog health probe"

# Mutation scans run only on the remote heredoc body. The runner-local SSH
# setup legitimately writes ~/.ssh files and is audited separately for secrets.
MUTATION_PATTERNS: list[tuple[re.Pattern[str], str]] = [
    (
        re.compile(
            r"^\s*(?:sudo\s+(?:-u\s+\S+\s+)?)?"
            r"(?:rm|mv|cp|chmod|chown|ln|touch|mktemp|truncate|dd|tee)\b",
            re.MULTILINE,
        ),
        "filesystem mutation command",
    ),
    (
        re.compile(
            r"systemctl\s+(?:start|stop|restart|reload|try-restart|enable|"
            r"disable|mask|unmask|edit|set-property)\b"
        ),
        "systemctl mutation",
    ),
    (
        re.compile(r"\bpg_ctlcluster\b|\bpg_ctl\b|\bpg_promote\b"),
        "cluster control / promote",
    ),
    (
        re.compile(
            r"\b(?:INSERT|UPDATE|DELETE|ALTER|CREATE|DROP|TRUNCATE|GRANT|"
            r"REVOKE|VACUUM|REINDEX)\b"
        ),
        "SQL mutation keyword",
    ),
    (re.compile(r"sed\s+-i\b"), "in-place sed"),
    # Match output redirection preceded by a command boundary, but not >& or
    # /dev/null. This deliberately does not match literals such as <empty>.
    (
        re.compile(r"(?:^|[\s;])[0-9]*>>?(?!&)\s*(?!/dev/null)\S", re.MULTILINE),
        "file write redirection",
    ),
    (
        re.compile(
            r"(?:\||&&|;|\$\(|`|\bxargs\s+(?:-[\w-]+\s+)*)\s*"
            r"(?:sudo\s+(?:-u\s+\S+\s+)?)?"
            r"(?:rm|mv|cp|chmod|chown|ln|touch|mktemp|truncate|dd|tee|shred|unlink)\b",
        ),
        "pipeline-embedded filesystem mutation",
    ),
    (
        re.compile(r"\bfind\b[^\n]*\s-(?:delete|exec|execdir|ok|okdir)\b"),
        "find with delete/exec action",
    ),
    (
        re.compile(r"\b(?:apt|apt-get|dpkg|snap|yum|dnf)\b"),
        "package manager action",
    ),
    (re.compile(r"\bjournalctl\b[^\n]*--vacuum"), "journal vacuum"),
    (
        re.compile(
            r"\b(?:cat|strings|od|xxd|base64|less|more)\b"
            r"[^\n]*(?:\$TARGET_DIR|/opt/valutavalto)"
        ),
        "target file content exposure",
    ),
]

# Raw recovery stdout must never reach a ::warning:: annotation. Matches
# $REC_OUT, ${REC_OUT}, ${REC_OUT:-<empty>}; does NOT match derived
# variables such as $REC_OUT_STATE / ${REC_OUT_STATE}.
FAILED_WARNING_MARKER = "::warning::Scaleway PG probe FAILED"
DISK_WARNING_MARKER = "::warning::Scaleway disk inventory FAILED"
RAW_REC_OUT_PATTERN = re.compile(
    r"\$REC_OUT\b|\$\{REC_OUT(?![A-Za-z0-9_])[^}]*\}"
)

REQUIRED_NEEDLES: dict[str, str] = {
    "primary-watchdog.timer": "watchdog timer state missing",
    "-p Result --value": "watchdog service Result missing",
    "-p ExecMainStatus --value": "watchdog ExecMainStatus missing",
    "${WD_STATE:-<empty>}": "empty watchdog state file is not rendered as <empty>",
    "systemctl is-active postgresql 2>&1": "generic postgresql unit state missing",
    "postgresql@16-main": "versioned postgresql@16-main unit state missing",
    "pg_lsclusters 2>&1": "cluster inventory missing or its errors are discarded",
    "pg_isready": "pg_isready probe missing",
    "pg_isready exit: $READY_EXIT": "pg_isready exit code is not reported",
    "psql exit: $PSQL_EXIT": "psql exit code is not reported",
    "pg_is_in_recovery": "recovery probe missing",
    "recovery stdout: ${REC_OUT:-<empty>}": (
        "empty recovery stdout is not rendered as <empty>"
    ),
    "${SAFE_STDERR:-<none>}": "sanitized stderr line missing",
    "PG_PROBE_STATUS=OK": "OK verdict missing",
    "PG_PROBE_STATUS=FAILED": "FAILED verdict missing",
    'REC_OUT_STATE="present"': "present recovery state is not derived",
    'REC_OUT_STATE="empty"': "empty recovery state is not derived",
    "recovery stdout=$REC_OUT_STATE": (
        "FAILED warning must report derived recovery state, not raw stdout"
    ),
    "head -c 600": "stderr byte cap missing",
    "<REDACTED": "stderr redaction missing",
}

DISK_REQUIRED_NEEDLES: dict[str, str] = {
    "TARGET_DIR=/opt/valutavalto/backend/target": "target dir binding missing",
    'df -B1 / "$TARGET_DIR" 2>&1': (
        "byte df for / and target fs missing or errors discarded"
    ),
    'df -i / "$TARGET_DIR" 2>&1': (
        "inode df for / and target fs missing or errors discarded"
    ),
    '"$TARGET_DIR" /var/log /var/lib/postgresql/16/main': (
        "footprint directory set missing"
    ),
    "du -x -B1 --max-depth=1": "bounded du inventory missing",
    "valuta-backend-*.jar": "release jar inventory missing",
    "*.incoming": "incoming artifact inventory missing",
    "shopt -s lastpipe": "count pipelines do not preserve read results",
    "find \"$TARGET_DIR\" -maxdepth 1 -type f -name 'valuta-backend-*.jar' | wc -l | read -r JAR_COUNT": (
        "JAR count probe missing or find stderr is not observable"
    ),
    "find \"$TARGET_DIR\" -maxdepth 1 -type f -name '*.incoming' | wc -l | read -r INCOMING_COUNT": (
        "incoming count probe missing or find stderr is not observable"
    ),
    'readlink "$TARGET_DIR/valuta-backend-current.jar"': (
        "active symlink readlink missing"
    ),
    "${LINK_TARGET:-<nincs symlink>}": (
        "missing symlink is not rendered as <nincs symlink>"
    ),
    'if [ "$DISK_FAIL" -eq 0 ]': (
        "OK verdict must require zero disk probe failures"
    ),
    "DISK_INVENTORY_STATUS=OK": "disk OK verdict missing",
    "DISK_INVENTORY_STATUS=FAILED": "disk FAILED verdict missing",
}


def _require(issues: list[str], condition: bool, message: str) -> None:
    if not condition:
        issues.append(message)


def _probe_run(document: dict[str, Any]) -> tuple[str, list[str]]:
    """Return the uniquely named probe step's run script and shape issues."""
    issues: list[str] = []
    jobs = document.get("jobs")
    if not isinstance(jobs, dict):
        return "", ["workflow: missing jobs mapping"]

    _require(
        issues,
        set(jobs) == {"diag"},
        "workflow: expected exactly the diag job",
    )
    diag = jobs.get("diag")
    if not isinstance(diag, dict):
        return "", issues + ["workflow: missing diag job"]

    steps = diag.get("steps")
    if not isinstance(steps, list):
        return "", issues + ["diag: missing steps list"]

    matches = [step for step in steps if step.get("name") == PROBE_STEP]
    _require(
        issues,
        len(matches) == 1,
        f"diag: expected exactly one {PROBE_STEP!r} step",
    )
    if len(matches) != 1:
        return "", issues

    run_text = matches[0].get("run")
    _require(issues, isinstance(run_text, str), "probe: run block is not a string")
    return (run_text if isinstance(run_text, str) else ""), issues


def _remote_body(run_text: str, issues: list[str]) -> str:
    """Extract only the quoted ENDSSH heredoc body from the probe run block."""
    opener = re.search(r"<<\s*'ENDSSH'[^\n]*\n", run_text)
    _require(issues, opener is not None, "probe: missing quoted ENDSSH opener")
    if opener is None:
        return ""

    terminator = re.search(r"^\s*ENDSSH\s*$", run_text[opener.end() :], re.MULTILINE)
    _require(issues, terminator is not None, "probe: missing ENDSSH terminator")
    if terminator is None:
        return ""

    return run_text[opener.end() : opener.end() + terminator.start()]


def audit_probe(run_text: str) -> list[str]:
    """Return all remote probe contract violations for a full step run string."""
    issues: list[str] = []
    body = _remote_body(run_text, issues)
    if not body:
        return issues

    for needle, message in REQUIRED_NEEDLES.items():
        _require(issues, needle in body, f"probe: {message}")

    for needle, message in DISK_REQUIRED_NEEDLES.items():
        _require(issues, needle in body, f"probe: {message}")

    for pattern, label in MUTATION_PATTERNS:
        match = pattern.search(body)
        if match is not None:
            offending_line = body[match.start() :].splitlines()[0].strip()
            issues.append(f"probe: {label}: {offending_line}")

    failed_warning_lines = [
        line for line in body.splitlines() if FAILED_WARNING_MARKER in line
    ]
    _require(
        issues,
        bool(failed_warning_lines),
        "probe: FAILED path does not annotate the run",
    )
    for line in failed_warning_lines:
        _require(
            issues,
            RAW_REC_OUT_PATTERN.search(line) is None,
            f"probe: warning line leaks raw recovery stdout: {line.strip()}",
        )

    _require(
        issues,
        any(DISK_WARNING_MARKER in line for line in body.splitlines()),
        "probe: disk FAILED path does not annotate the run",
    )

    du_token = re.compile(r"(?:^|[\s;|&(])du\s")
    find_token = re.compile(r"(?:^|[\s;|&($])find\s")
    for line in body.splitlines():
        stripped = line.strip()
        if stripped.startswith("#") or stripped.startswith("echo "):
            continue
        if du_token.search(line):
            _require(
                issues,
                "--max-depth=1" in line and " -x " in line and "| head -n" in line,
                f"probe: unbounded du invocation: {stripped}",
            )
        if find_token.search(line):
            _require(
                issues,
                "-maxdepth 1" in line,
                f"probe: unbounded find invocation: {stripped}",
            )

    for count_variable, label in (
        ("JAR_COUNT", "JAR"),
        ("INCOMING_COUNT", "incoming"),
    ):
        _require(
            issues,
            re.search(
                rf"\|\s*read -r {count_variable}\s*\n\s*"
                r'\[ "\$\{PIPESTATUS\[0\]\}" -ne 0 \] && DISK_FAIL=1',
                body,
            )
            is not None,
            f"probe: {label} count find failure is not checked immediately",
        )

    _require(
        issues,
        re.search(
            r"psql[^\n]*pg_is_in_recovery[^\n]*2>/dev/null",
            body,
        )
        is None,
        "probe: psql recovery errors are discarded again",
    )
    _require(
        issues,
        re.search(
            r"^\s*SAFE_STDERR=.*sed .*\|\s*head -c 600",
            body,
            re.MULTILINE,
        )
        is not None,
        "probe: stderr must be redacted before the 600-byte cap",
    )
    _require(
        issues,
        'if [ "$PSQL_EXIT" -eq 0 ] && [ -n "$REC_OUT" ]' in body,
        "probe: OK verdict must require psql exit 0 and non-empty recovery stdout",
    )
    return issues


def audit_workflow(document: dict[str, Any], raw_text: str) -> list[str]:
    """Return all workflow and read-only probe contract violations."""
    issues: list[str] = []
    _require(issues, bool(raw_text.strip()), "workflow: source text is empty")

    triggers = document.get("on", document.get(True))
    _require(
        issues,
        isinstance(triggers, dict) and set(triggers) == {"workflow_dispatch"},
        "workflow: only workflow_dispatch trigger is allowed",
    )

    run_text, shape_issues = _probe_run(document)
    issues.extend(shape_issues)
    if run_text:
        issues.extend(audit_probe(run_text))

    jobs = document.get("jobs")
    if isinstance(jobs, dict):
        for job in jobs.values():
            if not isinstance(job, dict):
                continue
            steps = job.get("steps")
            if not isinstance(steps, list):
                continue
            for step in steps:
                if not isinstance(step, dict):
                    continue
                name = str(step.get("name", ""))
                run = str(step.get("run", ""))
                if name not in ("Set up SSH", PROBE_STEP):
                    issues.append(f"workflow: unexpected step: {name or '<unnamed>'}")
                if name != "Set up SSH":
                    for pattern, label in MUTATION_PATTERNS:
                        match = pattern.search(run)
                        if match is not None:
                            offending = run[match.start() :].splitlines()[0].strip()
                            issues.append(
                                f"workflow step {name!r}: {label}: {offending}"
                            )
                if "SCALEWAY_SSH_PRIVATE_KEY" in run and name != "Set up SSH":
                    issues.append(
                        "secret hygiene: private key referenced in unexpected step: "
                        f"{name}"
                    )
                if re.search(r"^\s*set\s+-x(?:\s|$)", run, re.MULTILINE):
                    issues.append(f"secret hygiene: set -x present in step: {name}")

    return issues


def _insert_before_terminator(run_text: str, text: str) -> str:
    terminator = re.search(r"^\s*ENDSSH\s*$", run_text, re.MULTILINE)
    if terminator is None:
        return run_text
    return run_text[: terminator.start()] + text + "\n" + run_text[terminator.start() :]


def _self_test(run_text: str) -> list[str]:
    """Return self-test failures when an in-memory regression goes undetected."""
    failures: list[str] = []
    mutations: list[tuple[str, str]] = [
        (
            "systemctl restart",
            _insert_before_terminator(
                run_text, "systemctl restart postgresql@16-main"
            ),
        ),
        (
            "discarded psql stderr",
            re.sub(
                r"(^[^\n]*psql[^\n]*pg_is_in_recovery[^\n]*)(\n)",
                r"\1 2>/dev/null\2",
                run_text,
                count=1,
                flags=re.MULTILINE,
            ),
        ),
        (
            "missing FAILED verdict",
            run_text.replace("PG_PROBE_STATUS=FAILED", "", 1),
        ),
        (
            "missing empty recovery rendering",
            run_text.replace(
                "recovery stdout: ${REC_OUT:-<empty>}",
                "recovery stdout: $REC_OUT",
                1,
            ),
        ),
        (
            "raw recovery leak in FAILED warning",
            _insert_before_terminator(
                run_text,
                'echo "::warning::Scaleway PG probe FAILED: '
                'psql exit=$PSQL_EXIT, recovery stdout=${REC_OUT:-<empty>}"',
            ),
        ),
        (
            "disk: injected rm -rf",
            _insert_before_terminator(run_text, 'rm -rf "$TARGET_DIR"'),
        ),
        (
            "disk: find -delete",
            _insert_before_terminator(
                run_text,
                "find \"$TARGET_DIR\" -maxdepth 1 -name '*.incoming' -delete",
            ),
        ),
        (
            "disk: pipeline-embedded rm via xargs",
            _insert_before_terminator(
                run_text,
                "find \"$TARGET_DIR\" -maxdepth 1 -name '*.incoming' "
                "2>/dev/null | xargs rm -f",
            ),
        ),
        (
            "disk: unbounded du",
            run_text.replace(
                'du -x -B1 --max-depth=1 "$DIR" 2>&1 | sort -rn | head -n 15',
                'du -x -B1 "$DIR" 2>&1 | sort -rn',
                1,
            ),
        ),
        (
            "disk: missing JAR count find guard",
            re.sub(
                r"(\|\s*read -r JAR_COUNT\s*\n)\s*"
                r'\[ "\$\{PIPESTATUS\[0\]\}" -ne 0 \] && DISK_FAIL=1\s*\n',
                r"\1",
                run_text,
                count=1,
            ),
        ),
        (
            "disk: missing incoming count find guard",
            re.sub(
                r"(\|\s*read -r INCOMING_COUNT\s*\n)\s*"
                r'\[ "\$\{PIPESTATUS\[0\]\}" -ne 0 \] && DISK_FAIL=1\s*\n',
                r"\1",
                run_text,
                count=1,
            ),
        ),
        (
            "disk: missing FAILED verdict",
            run_text.replace("DISK_INVENTORY_STATUS=FAILED", "", 1),
        ),
        (
            "disk: secret content exposure",
            _insert_before_terminator(run_text, 'cat "$TARGET_DIR/../.env"'),
        ),
    ]

    for label, mutated in mutations:
        if mutated == run_text:
            failures.append(f"self-test: {label} mutation was not applied")
        elif not audit_probe(mutated):
            failures.append(f"self-test: {label} mutation was not detected")
    return failures


def main() -> int:
    self_test = sys.argv[1:] == ["--self-test"]
    if sys.argv[1:] not in ([], ["--self-test"]):
        print("FAIL: usage: scaleway-diag-audit.py [--self-test]")
        return 1

    try:
        raw_text = WORKFLOW.read_text(encoding="utf-8")
        # PyYAML 1.1 parses top-level `on:` as boolean True. audit_workflow
        # deliberately accepts either representation when checking triggers.
        document = yaml.safe_load(raw_text)
    except (OSError, yaml.YAMLError) as error:
        print(f"FAIL: cannot parse {WORKFLOW}: {error}")
        return 1

    if not isinstance(document, dict):
        print("FAIL: workflow root is not a mapping")
        return 1

    issues = audit_workflow(document, raw_text)
    if self_test and not issues:
        run_text, shape_issues = _probe_run(document)
        issues.extend(shape_issues)
        if run_text:
            issues.extend(_self_test(run_text))

    for issue in issues:
        print(f"FAIL: {issue}")
    if issues:
        print(f"{len(issues)} assertion(s) failed")
        return 1

    print("OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
