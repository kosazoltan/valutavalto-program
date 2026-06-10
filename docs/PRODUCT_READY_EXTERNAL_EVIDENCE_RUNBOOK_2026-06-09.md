# Product Ready external evidence runbook - 2026-06-09

This runbook is the operator-facing bridge between the local Product Ready gate
and the final Product Ready claim. It must be used only with real staging or
production evidence. Do not paste secrets, raw tokens, customer personal data or
database dumps into the evidence JSON, reports, screenshots or logs.

## Goal

Produce a complete external evidence JSON for:

- staging or production critical-flow acceptance;
- approved compliance go-live decision and environment export;
- real backup restore drill;
- deployed monitoring and alert delivery evidence;
- signed installer artifacts and clean Windows VM smoke;
- final Product Ready owner decision.

The final claim is valid only when:

```powershell
npm run product-ready:final-gate:complete
```

passes with zero failed or review-required checks against the filled evidence
JSON. Use `PRODUCT_READY_EXTERNAL_EVIDENCE_PATH` or the direct
`-ExternalEvidencePath` parameter to point the final gate at that completed
artifact.

## Evidence collection order

1. Refresh the local critical-flow coverage and local evidence bundle:

   ```powershell
   npm run product-ready:acceptance-coverage
   npm run product-ready:local-evidence-bundle
   ```

2. Generate the external evidence handoff pack:

   ```powershell
   npm run product-ready:external-evidence:pack:refresh
   ```

   This refresh command also reruns `product-ready:acceptance-coverage`, builds a
   current local evidence bundle, and injects both
   `localEvidenceBundleRef` and `acceptance.localCoverageReportRef` into the
   draft evidence JSON. The remaining missing checks must still be filled with
   real staging/production evidence and owner decisions.

3. Generate this operator runbook from the latest pack:

   ```powershell
   npm run product-ready:external-evidence:runbook
   ```

4. Run and attach real staging/production evidence for every section below.

5. Fill a copy of `docs/PRODUCT_READY_EXTERNAL_EVIDENCE_TEMPLATE_2026-06-09.json`.

6. Verify the filled evidence:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/product-ready-external-evidence-verify.ps1 -EvidencePath <filled-evidence.json> -RequireComplete
   $env:PRODUCT_READY_EXTERNAL_EVIDENCE_PATH = '<filled-evidence.json>'
   npm run product-ready:final-gate:complete
   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/product-ready-final-gate.ps1 -RequireComplete -ExternalEvidencePath <filled-evidence.json>
   ```

## Required evidence sections

### Owner approvals

Required result: product owner, operations owner and compliance owner approvals
recorded in a structured report that references the completed external evidence
artifact being approved.

Use the structured approvals verifier so final sign-off does not depend on three
free-form text fields:

```powershell
npm run product-ready:approvals:preflight
npm run product-ready:approvals:complete
```

For the final evidence JSON, set `approvals.reportRef` to the generated
`summary.json` from `security-reports/product-ready-approvals/<run>/` or to an
equivalent immutable structured report. The external verifier checks that the
report is PASS, has zero failed and zero review-required checks, declares a
staging or production environment, records a completed evidence reference, has
named approvers, timestamps, `approved = true`, evidence references for
product/operations/compliance owner sign-off, and explicit
redaction/no-secret/no-customer-personal-data safety declarations.

Keep `approvals.productOwner`, `approvals.operationsOwner` and
`approvals.complianceOwner` aligned with the structured report for quick human
reading. These text fields are not enough without `approvals.reportRef`.

### Acceptance

Required result: `acceptance.status = PASS`, `acceptance.failed = 0`,
`acceptance.criticalFlowsPassed = true`.

Attach a staging or production acceptance report that explicitly covers:

- buy;
- sell;
- conversion;
- transfer;
- storno;
- dayClosing;
- navCashRegister;
- receiptPrint;
- offlineSync.

Local acceptance reports are useful supporting evidence, but they do not replace
staging or production execution evidence.

Use the structured acceptance evidence verifier so the final evidence does not
depend on a free-form document:

```powershell
npm run product-ready:staging-acceptance:preflight
npm run product-ready:staging-acceptance:complete
```

For the final evidence JSON, set `acceptance.reportRef` to the generated
`summary.json` from `security-reports/product-ready-staging-acceptance/<run>/`
or to an equivalent immutable structured report. Set `acceptance.failed` and
`acceptance.criticalFlowsPassed` from the same verified summary, not from manual
retyping.

Set `acceptance.coveredFlows` to the same full critical-flow list:
`buy`, `sell`, `conversion`, `transfer`, `storno`, `dayClosing`,
`navCashRegister`, `receiptPrint`, `offlineSync`.

Set `acceptance.localCoverageReportRef` to the generated `summary.json` from
`npm run product-ready:acceptance-coverage`. The external verifier checks that
the local critical-flow coverage summary has zero failed checks and includes
mapped command, file and pattern-level evidence for buy, sell, conversion,
transfer, storno, day closing, NAV cash-register command, receipt print and
offline sync. This local coverage report is supporting evidence only; it does
not replace the staging or production acceptance execution report.

### Compliance

Required result: approved compliance decision plus staging/production
`system_parameter` export from the same environment declared at top level.

Use:

```powershell
npm run compliance:golive:export
npm run compliance:golive:decision:approved
```

with real staging/production database connectivity and an approved, redacted
decision artifact.

For the final evidence JSON, set `compliance.approvedDecisionRef` to the
`summary.json` generated by `npm run compliance:golive:decision:approved` or to
an equivalent immutable structured report. The external verifier checks that the
decision gate ran in approved-decision mode, has zero failed and zero
review-required checks, records `decisionStatus`, environment, `decidedAt`,
decision owner, compliance approver, and every required go-live flag with an
approved value and rationale.

Set `compliance.exportReportRef` to the `summary.json` generated by
`npm run compliance:golive:export` against the staging or production database.
The external verifier checks query-mode execution, recorded database target
metadata, zero failed and zero review-required results, approved decision status,
query execution, PASS status for every required flag, and rejects synthetic
`updatedBy=synthetic` flag evidence as final Product Ready proof.

### DR restore

Required result: real backup restored into an isolated target, Flyway verified,
audit hash-chain smoke verified, row counts recorded, and measured RTO recorded.

Use the restore drill script with explicit execution parameters. The restore
target must be a scratch database, not a live operational database.

For the final evidence JSON, set `drRestore.reportRef` to a structured
`summary.json` generated by the DR restore drill. The external verifier checks
that this report is execute-mode, has zero failed steps, uses a safe
`valuta_dr_*` scratch target, contains the restore step, contains row counts for
`transactions`, `audit_log`, `aml_report`, `customer` and `flyway_success`, and
has clean `missing_hash,broken_chain=0,0` audit hash-chain smoke evidence.

### Monitoring

Required result: at least 168 observed hours, scrape verified, dashboard loaded,
and alert delivery tested.

Use the structured monitoring evidence verifier so the final evidence does not
depend on a free-form document:

```powershell
npm run product-ready:monitoring-evidence:preflight
npm run product-ready:monitoring-evidence:complete
```

For the final evidence JSON, set `monitoring.reportRef` to the generated
`summary.json` from `security-reports/product-ready-monitoring-evidence/<run>/`
or to an equivalent immutable structured report. The external verifier checks
that this report is PASS, has zero failed and zero review-required checks,
declares a staging or production environment, covers at least 168 observed
hours, verifies scrape/dashboard/alert delivery, backend and Postgres health,
host metrics, ClientErrorLog observability, evidence references, and explicit
redaction/no-secret/no-customer-personal-data safety declarations.

### Installer

Required result: signed artifact verification plus clean Windows VM install,
launch and uninstall proof for:

- penztar;
- arfolyam-keszito;
- kozponti.

Use signed release artifacts for the final Product Ready claim.

For the final evidence JSON, set `installer.signedArtifactReportRef` to the
`summary.json` from `npm run installer:smoke:signed` or to an equivalent
immutable structured report. The external verifier checks that artifact
verification ran with `-CheckArtifacts` and `-RequireSignature`, has zero failed
and zero skipped checks, and includes PASS results for artifact existence, age,
SHA-256, Authenticode signature, packaged secret filename scans, packaged text
secret scans, and ASAR secret scans for all three clients.

Set `installer.cleanVmReportRef` to the `summary.json` generated by
`scripts/installer-clean-vm-smoke.ps1 -ExecuteInstall -AcceptVmMutation -ConfirmDisposableCleanVm`
on a disposable clean Windows VM. The external verifier checks that the report is not
a preflight-only run, has zero failed and zero skipped checks, does not skip
uninstall, and includes install, launch, runtime secret scan, uninstall and
post-uninstall removal PASS evidence for all three clients.

### Final decision

Required result: product owner, operations owner and compliance owner approvals
plus final `readyForProductReadyClaim = true` decision.

The final decision must reference the completed evidence JSON and, after the
final gate succeeds, may also reference the successful final gate report.

Set `finalDecision.externalEvidenceRef` to the completed external evidence JSON
that is being approved. The verifier checks that it is a local structured JSON
artifact with `schemaVersion = 1`, `evidenceStatus = COMPLETE`, staging or
production environment, an existing local evidence bundle reference, and
`finalDecision.readyForProductReadyClaim = true`.

`finalDecision.finalGateSummaryRef` is post-run proof. It is produced after
`npm run product-ready:final-gate:complete` succeeds, so it must not be treated
as a prerequisite of the same final gate run. If this field is filled later, the
verifier checks that the referenced summary ran with `requireComplete = true`,
has zero failed steps, includes the local gate, local evidence bundle and
external evidence gate steps as passed, contains the complete Product Ready
verdict, and points back to the same completed evidence JSON referenced by the
final decision.

## Evidence reference rules

Every `*Ref` field must point to one of:

- a repo-relative report path;
- an absolute local report path;
- an HTTPS URL to an immutable/redacted evidence artifact.

Do not reference transient terminal output that is not captured in a report file.
Do not reference private chat text as evidence.

## Safety rules

- Do not commit secrets or credentials.
- Do not include live customer personal data in generated reports.
- Redact database connection strings, JWTs, cookies, OAuth values, webhook URLs
  and API keys before attaching evidence.
- Do not mark the external evidence as `COMPLETE` until the fail-closed verifier
  passes.
