#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Audit the guarded Scaleway standby disk-cleanup workflow.

Statically asserts (no secrets, no network) that the workflow targets only the
Scaleway standby, defaults to a non-mutating dry run, proves anti-primary and
KEEP-set guards before mutation, and exposes only the two explicitly
whitelisted mutation commands behind execute=true gates.

Exit 0 = all assertions pass; exit 1 = failures listed on stdout.
--self-test: mutate the workflow in memory and require detection.
"""

from __future__ import annotations

import copy
import re
import sys
from pathlib import Path
from typing import Any

import yaml

ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = ROOT / ".github" / "workflows" / "scaleway-disk-cleanup.yml"

CLEANUP_STEP = "Guarded standby disk cleanup"
DELETE_LINE = 'rm -f -- "$FILE"'
JOURNAL_LINE = 'journalctl --vacuum-size="$JOURNAL_VACUUM_SIZE"'
RECOVERY_PROBE = (
    'IN_REC=$(sudo -u postgres psql -tAc "SELECT pg_is_in_recovery();"'
)
STANDBY_GUARD = '[ ! -e "$PGDATA_DIR/standby.signal" ]'

PIPELINE_MUTATION_PATTERN = re.compile(
    r"(?:\||&&|;|\$\(|`|\bxargs\s+(?:-[\w-]+\s+)*)\s*"
    r"(?:sudo\s+(?:-u\s+\S+\s+)?)?"
    r"(?:rm|mv|cp|chmod|chown|ln|touch|mktemp|truncate|dd|tee|shred|unlink)\b"
)

# These patterns are evaluated line-by-line after the two exactly whitelisted
# mutation lines are scrubbed. Echoes and comments are skipped for direct
# command patterns, but PIPELINE_MUTATION_PATTERN is always evaluated.
MUTATION_PATTERNS: list[tuple[re.Pattern[str], str]] = [
    (
        re.compile(
            r"^\s*(?:sudo\s+(?:-u\s+\S+\s+)?)?"
            r"(?:rm|mv|cp|chmod|chown|ln|touch|mktemp|truncate|dd|tee)\b"
        ),
        "filesystem mutation command",
    ),
    (
        re.compile(
            r"\bsystemctl\s+(?:start|stop|restart|reload|try-restart|enable|"
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
    (re.compile(r"\bsed\s+-i\b"), "in-place sed"),
    (
        re.compile(r"\bfind\b[^\n]*\s-(?:delete|exec|execdir|ok|okdir)\b"),
        "find with delete/exec action",
    ),
    (
        re.compile(r"\b(?:apt|apt-get|dpkg|snap|yum|dnf)\b"),
        "package manager action",
    ),
    (re.compile(r"\brm\s+-[a-zA-Z]*r"), "recursive rm"),
    (re.compile(r"\brm[^\n]*\*"), "wildcard rm"),
    (re.compile(r"\brm[^\n]*/var/log/journal"), "manual journal deletion"),
    (re.compile(r"\brm[^\n]*/var/lib/postgresql"), "PGDATA deletion"),
    (re.compile(r"\bjournalctl[^\n]*--vacuum"), "journal vacuum"),
]

REQUIRED_NEEDLES: dict[str, str] = {
    "set -euo pipefail": "strict shell mode missing",
    'EXECUTE="$1"': "remote execute positional argument missing",
    "TARGET_DIR=/opt/valutavalto/backend/target": "target dir binding missing",
    'SYMLINK_PATH="$TARGET_DIR/valuta-backend-current.jar"': (
        "current symlink binding missing"
    ),
    "PGDATA_DIR=/var/lib/postgresql/16/main": "PGDATA binding missing",
    "KEEP_RECENT=3": "rollback retention count missing",
    "MIN_FREE_BYTES=2147483648": "2 GiB free-space gate missing",
    "CURRENT_MIN_BYTES=52428800": "current JAR absolute size floor missing",
    "sudo -u postgres pg_isready -q || READY_EXIT=$?": (
        "pg_isready exit capture missing"
    ),
    RECOVERY_PROBE: "exact pg_is_in_recovery probe missing",
    STANDBY_GUARD: "standby.signal fail-closed guard missing",
    'readlink -f "$SYMLINK_PATH"': "resolved current JAR protection missing",
    "MIN_VALID_BYTES=$(( CURRENT_BYTES * 3 / 4 ))": (
        "relative valid-JAR threshold missing"
    ),
    "find \"$TARGET_DIR\" -maxdepth 1 -type f -name 'valuta-backend-*.jar' -print": (
        "bounded release JAR inventory missing"
    ),
    "sort -V": "version ordering missing",
    "-name '*.incoming'": "incoming artifact inventory missing",
    '[ "$FILE" = "$CURRENT" ] || [ "$FILE" = "$SYMLINK_PATH" ]': (
        "current JAR deletion re-check missing"
    ),
    '[ -L "$FILE" ] || [ ! -f "$FILE" ]': (
        "regular non-symlink candidate re-check missing"
    ),
    "WOULD-DELETE:": "dry-run per-file report missing",
    "DELETED:": "execute per-file report missing",
    "FREED_BYTES=": "freed-byte summary missing",
    'df -B1 --output=avail "$TARGET_DIR"': "post-cleanup free-space probe missing",
    '-lt "$MIN_FREE_BYTES"': "minimum free-space comparison missing",
    "CLEANUP_STATUS=OK": "OK verdict missing",
    "CLEANUP_STATUS=FAILED": "FAILED verdict missing",
    "CLEANUP_STATUS=DRYRUN": "DRYRUN verdict missing",
    '"$TARGET_DIR"/*': "TARGET_DIR prefix guard missing",
    "*../*|*/..*": "parent traversal guard missing",
}


def _require(issues: list[str], condition: bool, message: str) -> None:
    if not condition:
        issues.append(message)


def _trigger_mapping(document: dict[str, Any]) -> Any:
    """Return triggers while accepting PyYAML 1.1's boolean True `on` key."""
    return document.get("on", document.get(True))


def _cleanup_run(document: dict[str, Any]) -> tuple[str, list[str]]:
    """Return the uniquely named cleanup step's run script and shape issues."""
    issues: list[str] = []
    jobs = document.get("jobs")
    if not isinstance(jobs, dict):
        return "", ["workflow: missing jobs mapping"]

    _require(
        issues,
        set(jobs) == {"cleanup"},
        "workflow: expected exactly the cleanup job",
    )
    cleanup = jobs.get("cleanup")
    if not isinstance(cleanup, dict):
        return "", issues + ["workflow: missing cleanup job"]

    _require(
        issues,
        cleanup.get("runs-on") == "ubuntu-latest",
        "cleanup: runs-on must be ubuntu-latest",
    )
    _require(
        issues,
        cleanup.get("timeout-minutes") == 15,
        "cleanup: timeout-minutes must be 15",
    )

    steps = cleanup.get("steps")
    if not isinstance(steps, list):
        return "", issues + ["cleanup: missing steps list"]

    names = [step.get("name") if isinstance(step, dict) else None for step in steps]
    _require(
        issues,
        names == ["Set up SSH", CLEANUP_STEP],
        "cleanup: steps must be exactly Set up SSH then guarded cleanup",
    )
    matches = [
        step
        for step in steps
        if isinstance(step, dict) and step.get("name") == CLEANUP_STEP
    ]
    _require(
        issues,
        len(matches) == 1,
        f"cleanup: expected exactly one {CLEANUP_STEP!r} step",
    )
    if len(matches) != 1:
        return "", issues

    run_text = matches[0].get("run")
    _require(issues, isinstance(run_text, str), "cleanup: run block is not a string")
    return (run_text if isinstance(run_text, str) else ""), issues


def _remote_body(run_text: str, issues: list[str]) -> str:
    """Extract only the quoted ENDSSH heredoc body from the cleanup run block."""
    opener = re.search(r"<<\s*'ENDSSH'[^\n]*\n", run_text)
    _require(issues, opener is not None, "cleanup: missing quoted ENDSSH opener")
    if opener is None:
        return ""

    terminator = re.search(r"^\s*ENDSSH\s*$", run_text[opener.end() :], re.MULTILINE)
    _require(issues, terminator is not None, "cleanup: missing ENDSSH terminator")
    if terminator is None:
        return ""

    return run_text[opener.end() : opener.end() + terminator.start()]


def audit_body(body: str) -> list[str]:
    """Return all remote cleanup-body contract violations."""
    issues: list[str] = []
    _require(issues, bool(body.strip()), "cleanup: remote body is empty")
    if not body:
        return issues

    for needle, message in REQUIRED_NEEDLES.items():
        _require(issues, needle in body, f"cleanup: {message}")

    for needle, label in (
        (DELETE_LINE, "file deletion"),
        (JOURNAL_LINE, "journal vacuum"),
    ):
        _require(
            issues,
            body.count(needle) == 1,
            f"cleanup: {label} line must occur exactly once",
        )

    _require(
        issues,
        re.search(
            r'if \[ "\$EXECUTE" = "true" \]; then\s*\n\s*rm -f -- "\$FILE"',
            body,
        )
        is not None,
        "cleanup: file deletion is not directly gated by execute=true",
    )
    _require(
        issues,
        re.search(
            r'if \[ "\$EXECUTE" = "true" \]; then\s*\n\s*'
            r'journalctl --vacuum-size="\$JOURNAL_VACUUM_SIZE"',
            body,
        )
        is not None,
        "cleanup: journal vacuum is not directly gated by execute=true",
    )

    scrubbed = body.replace(DELETE_LINE, "").replace(JOURNAL_LINE, "")
    for line in scrubbed.splitlines():
        pipeline_match = PIPELINE_MUTATION_PATTERN.search(line)
        if pipeline_match is not None:
            issues.append(
                "cleanup: pipeline-embedded filesystem mutation: " + line.strip()
            )

        stripped = line.strip()
        if stripped.startswith("echo ") or stripped.startswith("#"):
            continue
        for pattern, label in MUTATION_PATTERNS:
            if pattern.search(line) is not None:
                issues.append(f"cleanup: {label}: {stripped}")

    delete_pos = body.find(DELETE_LINE)
    journal_pos = body.find(JOURNAL_LINE)
    recovery_pos = body.find(RECOVERY_PROBE)
    standby_pos = body.find(STANDBY_GUARD)
    _require(
        issues,
        recovery_pos >= 0 and delete_pos >= 0 and recovery_pos < delete_pos,
        "cleanup: recovery guard must precede file deletion",
    )
    _require(
        issues,
        standby_pos >= 0 and delete_pos >= 0 and standby_pos < delete_pos,
        "cleanup: standby.signal guard must precede file deletion",
    )
    _require(
        issues,
        recovery_pos >= 0 and journal_pos >= 0 and recovery_pos < journal_pos,
        "cleanup: recovery guard must precede journal vacuum",
    )
    return issues


def audit_workflow(document: dict[str, Any], raw_text: str) -> list[str]:
    """Return all workflow and guarded-cleanup contract violations."""
    issues: list[str] = []
    _require(issues, bool(raw_text.strip()), "workflow: source text is empty")

    triggers = _trigger_mapping(document)
    _require(
        issues,
        isinstance(triggers, dict) and set(triggers) == {"workflow_dispatch"},
        "workflow: only workflow_dispatch trigger is allowed",
    )
    dispatch = triggers.get("workflow_dispatch") if isinstance(triggers, dict) else None
    inputs = dispatch.get("inputs") if isinstance(dispatch, dict) else None
    _require(
        issues,
        isinstance(inputs, dict) and set(inputs) == {"execute"},
        "workflow: execute must be the only input",
    )
    execute = inputs.get("execute") if isinstance(inputs, dict) else None
    _require(
        issues,
        isinstance(execute, dict)
        and execute.get("type") == "boolean"
        and execute.get("default") is False
        and execute.get("required") is True,
        "workflow: execute must be required boolean with default false",
    )

    _require(
        issues,
        document.get("permissions") == {"contents": "read"},
        "workflow: permissions must be contents: read only",
    )
    concurrency = document.get("concurrency")
    _require(
        issues,
        isinstance(concurrency, dict)
        and concurrency.get("group") == "deploy-hetzner-production"
        and concurrency.get("cancel-in-progress") is False,
        "workflow: concurrency must serialize with production deploys",
    )

    run_text, shape_issues = _cleanup_run(document)
    issues.extend(shape_issues)
    if run_text:
        runner_guard = 'if [ "$EXECUTE" != "true" ] && [ "$EXECUTE" != "false" ]'
        ssh_pass = 'bash -s -- "$EXECUTE"'
        guard_pos = run_text.find(runner_guard)
        ssh_pos = run_text.find(ssh_pass)
        _require(issues, guard_pos >= 0, "cleanup: runner execute validation missing")
        _require(issues, ssh_pos >= 0, "cleanup: execute flag is not passed positionally")
        _require(
            issues,
            guard_pos >= 0 and ssh_pos >= 0 and guard_pos < ssh_pos,
            "cleanup: runner execute validation must precede SSH",
        )
        body_issues: list[str] = []
        body = _remote_body(run_text, body_issues)
        issues.extend(body_issues)
        if body:
            issues.extend(audit_body(body))

    _require(
        issues,
        "SCALEWAY_SERVER_IP" in raw_text,
        "target isolation: SCALEWAY_SERVER_IP missing",
    )
    for forbidden in (
        "VPS_SERVER_IP",
        "VPS_SSH_PRIVATE_KEY",
        "VPS_SSH_USER",
        "HETZNER",
    ):
        _require(
            issues,
            forbidden not in raw_text,
            f"target isolation: forbidden token present: {forbidden}",
        )

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


def _self_test(
    document: dict[str, Any], raw_text: str, run_text: str
) -> list[str]:
    """Return self-test failures when an in-memory regression goes undetected."""
    failures: list[str] = []
    run_mutations: list[tuple[str, str]] = [
        ("recursive root deletion", _insert_before_terminator(run_text, "rm -rf /")),
        (
            "unconditional duplicate deletion",
            _insert_before_terminator(run_text, DELETE_LINE),
        ),
        (
            "PGDATA deletion",
            _insert_before_terminator(
                run_text,
                "rm -f -- /var/lib/postgresql/16/main/pg_wal/"
                "0000000100000000000000AA",
            ),
        ),
        (
            "missing anti-primary recovery probe",
            re.sub(
                r"^\s*IN_REC=.*pg_is_in_recovery.*\n",
                "",
                run_text,
                count=1,
                flags=re.MULTILINE,
            ),
        ),
        (
            "missing resolved-current protection",
            re.sub(
                r"^\s*CURRENT=\$\(readlink -f .*\n",
                "",
                run_text,
                count=1,
                flags=re.MULTILINE,
            ),
        ),
        (
            "missing standby.signal guard",
            run_text.replace(STANDBY_GUARD, "[ false ]", 1),
        ),
        (
            "manual journal deletion",
            _insert_before_terminator(run_text, "rm -rf /var/log/journal"),
        ),
    ]

    for label, mutated in run_mutations:
        if mutated == run_text:
            failures.append(f"self-test: {label} mutation was not applied")
            continue
        mutation_issues: list[str] = []
        body = _remote_body(mutated, mutation_issues)
        if body:
            mutation_issues.extend(audit_body(body))
        if not mutation_issues:
            failures.append(f"self-test: {label} mutation was not detected")

    mutated_document = copy.deepcopy(document)
    triggers = _trigger_mapping(mutated_document)
    if isinstance(triggers, dict):
        dispatch = triggers.get("workflow_dispatch")
        if isinstance(dispatch, dict):
            inputs = dispatch.get("inputs")
            if isinstance(inputs, dict):
                execute = inputs.get("execute")
                if isinstance(execute, dict):
                    execute["default"] = True
    if mutated_document == document:
        failures.append("self-test: execute-default mutation was not applied")
    elif not audit_workflow(mutated_document, raw_text):
        failures.append("self-test: execute-default mutation was not detected")

    return failures


def main() -> int:
    self_test = sys.argv[1:] == ["--self-test"]
    if sys.argv[1:] not in ([], ["--self-test"]):
        print("FAIL: usage: scaleway-cleanup-audit.py [--self-test]")
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
        run_text, shape_issues = _cleanup_run(document)
        issues.extend(shape_issues)
        if run_text:
            issues.extend(_self_test(document, raw_text, run_text))

    for issue in issues:
        print(f"FAIL: {issue}")
    if issues:
        print(f"{len(issues)} assertion(s) failed")
        return 1

    print("OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
