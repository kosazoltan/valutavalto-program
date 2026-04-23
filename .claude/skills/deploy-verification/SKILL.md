---
name: deploy-verification
description: Use before any production deploy (release, container push, binary distribution). Verifies SBOM generation, SLSA artifact attestation via gh attestation verify, container image scanning, environment protection reviewer approval, and release SHA correspondence to green checks SHA.
---

# deploy-verification skill

Implements AGENTS.md / MULTIMODEL_GITHUB_QUALITY_MANDATE_V2.md section 19 (Release artifact bizonyitas).

## Required before any deploy

### Step 1: Verify artifact exists + SHA alignment

```bash
# The artifact SHA must equal the checks-green SHA
ARTIFACT_SHA=$(gh run view $RUN_ID --json headSha -q .headSha)
CHECKS_GREEN_SHA=$(gh pr view $PR --json headRefOid -q .headRefOid)
test "$ARTIFACT_SHA" = "$CHECKS_GREEN_SHA" || { echo "BLOCKED: artifact/checks SHA mismatch"; exit 1; }
```

### Step 2: SBOM generation

SPDX or CycloneDX:
```bash
# SPDX via github
gh api /repos/$OWNER/$REPO/dependency-graph/sbom > sbom.spdx.json
# OR CycloneDX via syft/cyclonedx
```

### Step 3: SLSA artifact attestation

```bash
gh attestation verify ./dist/app --repo "$OWNER/$REPO"
gh attestation verify oci://ghcr.io/$OWNER/$IMAGE:$TAG --repo "$OWNER/$REPO"
```

Expected: attestation bundle found + verification success.

### Step 4: Container image scan

```bash
trivy image --severity HIGH,CRITICAL ghcr.io/$OWNER/$IMAGE:$TAG
# exit=0 required
```

### Step 5: Container signed

```bash
cosign verify --certificate-identity-regexp "^https://github.com/$OWNER/$REPO" \
              --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
              ghcr.io/$OWNER/$IMAGE:$TAG
```

### Step 6: Environment protection gate

Production environment must have:
- `Required reviewers`: 1+ configured
- `Prevent self-review`: ON
- `Wait timer`: optional
- `Deployment branches`: restricted to `main`/tags

Check via API:
```bash
gh api /repos/$OWNER/$REPO/environments/production \
  --jq '{protection_rules, deployment_branch_policy}'
```

### Step 7: Deploy-ready self-review

Include in AGENTS.md section 4 output:
- Build artifact: EXISTS + SHA match
- SBOM: generated (link)
- Attestation: verified
- Container scan: 0 high/critical
- Image signature: verified
- Environment: required reviewer approval GRANTED

If any fails: `BLOCKED: deploy not ready`.

## Never deploy if

- artifact SHA != checks-green SHA
- SBOM missing
- attestation verification fails
- any high/critical container CVE
- image unsigned
- no environment reviewer approval
