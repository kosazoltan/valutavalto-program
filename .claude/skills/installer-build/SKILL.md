---
name: installer-build
description: Use when the task involves building, packaging, or releasing the Valutavalto Penztar Windows installer. Triggers on phrases like 'build a telepítőt', 'készíts buildet', 'új verzió build', 'installer build', 'release készítés', 'telepítő gyártás', 'build the installer', 'new patch release', 'package for windows'. Mandatory: 4-way version sync, 2-step build (Setup + Eltavolito), database protection during upgrade.
location: D:/repo/valutavalto-program/.claude/skills/installer-build/SKILL.md
project: valutavalto-program
version: 2.3.5
---

# SKILL: Installer Build Pipeline (Valutavalto Penztar)

## EXECUTE THIS PIPELINE — NO REINVENTION

The build infrastructure is **already complete and battle-tested**. Don't rewrite it. Just use it correctly.

## STEP 0: PRE-FLIGHT (mandatory)

```powershell
# Working directory check
cd D:\repo\valutavalto-program

# Branch check (must be main or feature branch, never on detached HEAD)
git status --short
git branch --show-current

# Clean state check (no .claude/worktrees in staging!)
git status --short | Select-String -Pattern "claude|worktree" | Out-String
# Empty output = OK
```

If `.claude/worktrees/` shows up → STOP. Add to `.gitignore` first:
```
.claude/worktrees/
.worktrees/
```

## STEP 1: Build Setup EXE (~276 MB, 5-10 min cached)

```powershell
pwsh -NoLogo -NoProfile -File installer\build-installer.ps1
```

**Build flags** for faster rebuilds:
- `-SkipBackendBuild` — if `valuta-backend.jar` already staged
- `-SkipFrontendBuild` — if Electron unpacked already
- `-SkipDownloads` — if PG/NSSM/VC++ already in `installer/build/downloads/`

The build **automatically** runs the version-bump gate (`installer/scripts/check-version-bump.ps1`) which:
- Validates 9-way version sync (drift → exit 2)
- Baseline = **max(local installer/build/*.exe, latest GitHub Release tag)**
- AUTO-PATCH bumps if current ≤ baseline (duplicate release = auto-update failure)
- Updates ALL 4 locations:
  1. `package.json`
  2. `frontend-react/package.json`
  3. `penztar-client/package.json`
  4. `backend/pom.xml` (top-level `<version>` only)

## STEP 2: Build Eltavolito EXE (~60 KB, 1 sec)

```powershell
pwsh -NoLogo -NoProfile -File installer\build-cleanup.ps1
```

Output: `installer\build\Penztar-Eltavolito-X.Y.Z-YYYYMMDD.exe`

## STEP 3: Stage Release Bundle

```powershell
$version = (Get-Content package.json -Raw | ConvertFrom-Json).version
$buildDate = Get-Date -Format "yyyyMMdd"

# Create release dir
New-Item -ItemType Directory -Path "dist\release" -Force | Out-Null

# Copy artifacts
Copy-Item "installer\build\Penztar-Setup-$version-$buildDate.exe" "dist\release\" -Force
Copy-Item "installer\build\Penztar-Eltavolito-$version-$buildDate.exe" "dist\release\" -Force

# Generate SHA256 hashes
foreach ($f in Get-ChildItem dist\release\*.exe) {
    $hash = (Get-FileHash $f -Algorithm SHA256).Hash
    "$hash *$($f.Name)" | Out-File "dist\release\$($f.Name).sha256" -Encoding ascii -NoNewline
    Write-Host "$($f.Name): $hash"
}
```

## STEP 4: Validate (optional but recommended)

```powershell
pwsh -File installer\tests\installer-validation-suite.ps1
```

This 30K-byte 5-textbook validation suite checks the EXE metadata, signature, structure, and staged binaries.

## STEP 5: Commit (Junior phase, BEFORE Bence push)

```powershell
git add .gitignore installer/build-common.ps1 installer/scripts/check-version-bump.ps1 `
        backend/pom.xml frontend-react/package.json frontend-react/package-lock.json `
        package.json package-lock.json `
        penztar-client/package.json penztar-client/package-lock.json `
        dist/release/install-notes.md dist/release/build-info.json

git commit -m "release(vX.Y.Z): 4-way version sync + dist/release artifact bundle

- All 4 version locations bumped via npm version patch + pom.xml regex
- Setup-X.Y.Z SHA256: <hash>
- Eltavolito-X.Y.Z SHA256: <hash>
"
```

## CRITICAL RULES

1. **NEVER hard-code version numbers** in scripts. Always read from `package.json`.
2. **NEVER commit `installer/build/*.exe`** — gitignored, GitHub Release only.
3. **NEVER commit `.claude/worktrees/`** — Cursor IDE pollution.
4. **NEVER use WinPS 5.1 `-le` operator on `[version]`** — caching bug. Use `[version]::Parse().CompareTo()`.
5. **NEVER use the standalone Eltavolito on a production machine** without a `pg_dump` first — it deletes the database!

## TYPICAL ERRORS — FAST FIXES

### PG ZIP CHECKSUM MISMATCH

```
Expected: 795196DF1B2855FD0C7FB52629C6CC16ACAA85819912E732BD4C46863E77EB30
Actual:   46903BB56BB0A40A81768703FA7420F0690095685DA040BED2C584B900A1124C
```

**Fix:**
```powershell
Remove-Item installer\build\downloads\postgresql-binaries.zip -Force
```

### PG download truncated

```powershell
cd installer\build\downloads
curl.exe -L -o postgresql-binaries.zip --retry 5 --retry-delay 5 --connect-timeout 30 --progress-bar 'https://get.enterprisedb.com/postgresql/postgresql-17.5-1-windows-x64-binaries.zip'
```

### Build hangs at NSIS compile

NSIS LZMA compression on 758 MB → expect 5-10 min. Don't kill the process.

### Build fails on first run with no cache

Expect 30+ min (PG/NSSM/VC++ download = ~150 MB).

### Version drift (4 locations not in sync)

Check current state:
```powershell
. (Join-Path D:\repo\valutavalto-program\installer\build-common.ps1)
Get-AllProjectVersions -RepoRoot D:\repo\valutavalto-program | Format-Table
```

If `IsConsistent: False` → align manually before running build.

## DOCS REFERENCED

- `D:\repo\valutavalto-program\installer\README.md` — installer-developer docs
- `D:\repo\valutavalto-program\CLAUDE.md` line 370 — dot-source pattern
- `D:\repo\valutavalto-program\CHANGELOG.md` — release notes (PR #177 4-way bump)
- `D:\repo\valutavalto-program\docs\knowledge\memory\2026-04-27-installer-build-pipeline-v2.3.5.qmd` — canonical
- `D:\repo\valutavalto-program\docs\knowledge\installer-wizard-implementation-guide.md` — SetupWizard context

## EVIDENCE OF SUCCESS — V2.3.5 (2026-04-27)

- `Penztar-Setup-2.3.5-20260427.exe` (276 MB), SHA256: `9D79DEED...329DD25D`
- `Penztar-Eltavolito-2.3.5-20260427.exe` (60 KB), SHA256: `53683D9D...69D6B029`
- Git commit: `e1121a30`
- Eszter F2 review: BLOCKER → APPROVED (all findings resolved)

## ON DELEGATION TO ESZTER (F2 review)

Pass these to controller agent:
- 4-way version sync evidence (`Get-AllProjectVersions` output)
- All 4 test cases for `check-version-bump.ps1` (AUTO-PATCH, KEPT, STRICT, DryRun)
- Drift detection test
- Anchored regex for `Get-LatestExistingBuildVersion`
- `.claude/worktrees/` NOT in commit (`git diff --cached --name-only | Select-String "claude|worktree"`)

## ON DELEGATION TO BENCE (F4 ship)

Pass these:
- Final commit hash
- `dist/release/build-info.json` SHA256 hashes
- `dist/release/install-notes.md` for end users
- GitHub Release notes draft (use `install-notes.md` as base)
