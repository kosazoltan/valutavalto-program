---
tags: [installer, build, release, pipeline, nsis, postgresql, security]
date: 2026-04-27
version: 2.3.5
status: confirmed-working
related:
  - "[[MANDATE_V2]]"
---

# Installer Build Pipeline (v2.3.5)

> **Quick reference:** A teljes telepítő-build folyamat a Valutaváltó Pénztárhoz.
> Évek óta működő infrastruktúra; ez a doksi a 2026-04-27-i v2.3.5 build alapján.

## TL;DR

```powershell
# 2-step build (~5-10 min cached)
pwsh -File installer\build-installer.ps1
pwsh -File installer\build-cleanup.ps1
```

A `build-installer.ps1` **automatikusan** kezeli a verzió-emelést mind a 4 helyen ([[#4-way Version Sync]]).

## 4-way Version Sync

> **KRITIKUS**: 4 helyen kell egyeznie a verziónak!

1. `package.json` (root)
2. `frontend-react/package.json`
3. `penztar-client/package.json`
4. `backend/pom.xml` (top-level `<version>`)

A `installer/scripts/check-version-bump.ps1` automatikusan kezeli mind a 4-et:
- npm version patch x3
- pom.xml regex update (top-level only)
- drift detection → exit 2 ha 4 hely nem egyezik

Forrás: `[[CLAUDE.md]]` line 370 + PR #103/#104 + PR #177

## 2-step Build

| # | Script | Output | Idő |
|---|--------|--------|-----|
| 1 | `build-installer.ps1` | `Penztar-Setup-X.Y.Z.exe` (276 MB) | 5-10 min |
| 2 | `build-cleanup.ps1` | `Penztar-Eltavolito-X.Y.Z.exe` (60 KB) | 1 sec |

A Setup **MÁR TARTALMAZ** auto-cleanup logikát. Az Eltavolito csak akkor kell, ha a Setup auto-cleanup-ja fennakad.

## Build Pipeline Belül (`build-installer.ps1`)

1. Verzió-emelő gate (4-way)
2. Backend Maven build → JAR
3. Custom JRE jlink (~50 MB)
4. Frontend (React/Vite) + Electron build
5. PG 17.5 + NSSM + VC++ download (cached, SHA-256 verified)
6. Config + scripts staging
7. NSIS compile → egyfájlos EXE

## Tipikus Hibák

### PostgreSQL ZIP CHECKSUM MISMATCH
```powershell
Remove-Item installer\build\downloads\postgresql-binaries.zip -Force
```

### PG download truncated (`Invoke-WebRequest`)
```powershell
curl.exe -L -o postgresql-binaries.zip --retry 5 'https://...'
```

### WinPS 5.1 `[version]` cache bug
**Fix:** `[version]::Parse().CompareTo()` not `-le`

### `.claude/worktrees/` scope pollution
**Fix:** `.gitignore`:
```
.claude/worktrees/
.worktrees/
```

### NSIS encoding error
**Fix:** `.nsi` fájl Windows-1252 ASCII; ékezetek tilos

## Adatbázis-Védelem

PR #222 (v2.3.0) fix-eli az upgrade-kor DB-törlést:
- `$UPGRADE_MODE` flag a `Penztar-Setup.nsi` `.onInit`-ben
- `SetRegView 64` lookup
- Conditional `RMDir /r` a `C:\ProgramData\BestChange`-en

**Frissítés** = DB megőrzve. **Tiszta install** = teljes törlés. **Standalone Eltavolito** = TÖRLI a DB-t! `pg_dump` kötelező előtte ha menteni akarjuk.

## Security

- SHA-256 verified bundled deps
- PG `scram-sha-256` auth
- Config ACL hardening
- `.env` `0o600` + atomic rename
- Tűzfal localhost-only (127.0.0.1)
- **Nincs beégetett credential** — minden helyben generálódik

## Evidence v2.3.5

| Artifact | SHA256 |
|----------|--------|
| Setup | `9D79DEED...329DD25D` |
| Eltavolito | `53683D9D...69D6B029` |

Git commit: `e1121a30`. Eszter review: APPROVED.

## Related

- [[CLAUDE.md]] line 370 - dot-source pattern
- [[CHANGELOG.md]] - PR #177 4-way bump
- `installer/README.md` - installer-developer docs
- `.claude/skills/installer-build/SKILL.md` - agent skill
- `docs/knowledge/memory/2026-04-27-installer-build-pipeline-v2.3.5.{qmd,yaml}` - canonical
