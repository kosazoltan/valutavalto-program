#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Audit the Scaleway standby deploy's fail-closed pre-upload safeguards.

The audit intentionally checks the workflow as a behavior contract: recovery
must be proven before remote mutation, rollback pruning must be deterministic,
and uploads must be finalized atomically only after an exact size check.

Exit 0 = all assertions pass; exit 1 = failures are listed on stdout.
"""

from __future__ import annotations

import hashlib
import re
import sys
from pathlib import Path
from typing import Any

import yaml

ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = ROOT / ".github" / "workflows" / "deploy-hetzner.yml"
SWAP_RUN_SHA256 = "6cf0f2076dd5d7f9074714e0b645a31318c0e6862dc9be8ca696f62c620eae43"


def _step_index(steps: list[dict[str, Any]], name: str) -> int:
    return next(
        (index for index, step in enumerate(steps) if step.get("name") == name),
        -1,
    )


def _require(issues: list[str], condition: bool, message: str) -> None:
    if not condition:
        issues.append(message)


def audit_workflow(document: dict[str, Any]) -> list[str]:
    """Return all standby deployment contract violations."""
    issues: list[str] = []
    jobs = document.get("jobs")
    if not isinstance(jobs, dict):
        return ["workflow: missing jobs mapping"]

    job = jobs.get("deploy-standby")
    if not isinstance(job, dict):
        return ["workflow: missing deploy-standby job"]

    steps = job.get("steps")
    if not isinstance(steps, list):
        return ["deploy-standby: missing steps list"]

    preflight_index = _step_index(
        steps, "Standby preflight — recovery guard + prune + disk check"
    )
    upload_index = _step_index(steps, "Upload JAR to standby")
    swap_index = _step_index(
        steps, "Swap symlink + restart (warm, read-only) + health"
    )
    _require(
        issues,
        0 <= preflight_index < upload_index < swap_index,
        "deploy-standby: required order is preflight < upload/finalize < swap "
        f"(actual: {preflight_index}, {upload_index}, {swap_index})",
    )

    preflight = (
        str(steps[preflight_index].get("run", "")) if preflight_index >= 0 else ""
    )
    upload = str(steps[upload_index].get("run", "")) if upload_index >= 0 else ""
    swap = str(steps[swap_index].get("run", "")) if swap_index >= 0 else ""

    recovery_position = preflight.find("pg_is_in_recovery")
    mutation_match = re.search(r"^\s*(?:rm|mv)\s", preflight, re.MULTILINE)
    _require(
        issues,
        recovery_position >= 0,
        "preflight: missing pg_is_in_recovery() guard",
    )
    _require(
        issues,
        'if [ "$IN_REC" != "t" ]' in preflight,
        "preflight: recovery result is not checked fail-closed for exact 't'",
    )
    _require(
        issues,
        mutation_match is None
        or (recovery_position >= 0 and recovery_position < mutation_match.start()),
        "preflight: remote filesystem mutation appears before recovery guard",
    )

    preflight_needles = {
        'stat -c%s "$JAR"': "local JAR size is not measured with stat -c%s",
        '"$TARGET/$JAR_NAME.incoming"': "stale .incoming file is not targeted for cleanup",
        "readlink -f": "current symlink target is not resolved",
        "grep -v current": "JAR listing does not explicitly exclude the current symlink",
        "sort -V": "rollback candidates are not ordered deterministically",
        "KEEP_N=2": "rollback retention is not KEEP_N=2",
        "[ -f": "prune does not restrict deletion to regular files",
        "[ ! -L": "prune does not explicitly reject symlinks",
        "df -h": "human-readable disk report is missing",
        "df -i": "inode report is missing",
        "df -B1 --output=avail": "available capacity is not measured in bytes",
        "JAR_BYTES * 2": "2x JAR byte-capacity margin is missing",
    }
    for needle, message in preflight_needles.items():
        _require(issues, needle in preflight, f"preflight: {message}")

    _require(
        issues,
        "::error::" in preflight,
        "preflight: failure paths do not emit GitHub error annotations",
    )
    _require(
        issues,
        re.search(r'^\s*rm\s+-f\s+"\$TARGET/\$JAR_NAME\.incoming"', preflight, re.MULTILINE)
        is not None,
        "preflight: stale incoming cleanup is missing or not narrowly quoted",
    )

    upload_needles = {
        'stat -c%s "$JAR"': "local JAR size is not measured",
        "target/$JAR_NAME.incoming": "SCP destination is not the .incoming path",
        'INCOMING="$TARGET/$JAR_NAME.incoming"': "remote incoming path is not explicit",
        'REMOTE_BYTES=$(stat -c%s "$INCOMING")': "remote incoming size is not measured",
        'if [ "$REMOTE_BYTES" != "$JAR_BYTES" ]': "remote size is not checked exactly",
        'mv -f "$INCOMING" "$FINAL"': "incoming JAR is not atomically moved to final",
        "::error::": "finalize failure paths do not emit GitHub error annotations",
    }
    for needle, message in upload_needles.items():
        _require(issues, needle in upload, f"upload/finalize: {message}")

    _require(
        issues,
        re.search(r"target/\$JAR_NAME[\"']?\s*$", upload, re.MULTILINE) is None,
        "upload/finalize: SCP still writes the final JAR path directly",
    )
    size_check_position = upload.find('if [ "$REMOTE_BYTES" != "$JAR_BYTES" ]')
    move_position = upload.find('mv -f "$INCOMING" "$FINAL"')
    _require(
        issues,
        size_check_position >= 0
        and move_position >= 0
        and size_check_position < move_position,
        "upload/finalize: atomic move is not ordered after exact size verification",
    )

    _require(
        issues,
        hashlib.sha256(swap.encode("utf-8")).hexdigest() == SWAP_RUN_SHA256,
        "swap step changed; its post-upload guard and restart logic must remain byte-identical",
    )
    _require(
        issues,
        "pg_is_in_recovery" in swap,
        "swap step lost the defense-in-depth recovery guard",
    )

    for step in steps:
        name = str(step.get("name", ""))
        run = str(step.get("run", ""))
        if "SCALEWAY_SSH_PRIVATE_KEY" in run and name != "Set up SSH (standby)":
            issues.append(f"secret hygiene: private key referenced in unexpected step: {name}")
        if re.search(r"^\s*set\s+-x(?:\s|$)", run, re.MULTILINE):
            issues.append(f"secret hygiene: set -x present in step: {name}")

    return issues


def main() -> int:
    try:
        # PyYAML 1.1 parses top-level `on:` as boolean True. This audit only reads
        # `jobs`, so it deliberately does not assert against the `on` key.
        document = yaml.safe_load(WORKFLOW.read_text(encoding="utf-8"))
    except (OSError, yaml.YAMLError) as error:
        print(f"FAIL: cannot parse {WORKFLOW}: {error}")
        return 1

    if not isinstance(document, dict):
        print("FAIL: workflow root is not a mapping")
        return 1

    issues = audit_workflow(document)
    for issue in issues:
        print(f"FAIL: {issue}")
    if issues:
        print(f"{len(issues)} assertion(s) failed")
        return 1

    print("OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
