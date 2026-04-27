# HANDOVER — Valutaváltó Pénztár Repo

> **Élő session-state.** Minden új session ezt olvassa először (BOOT.md S15).
> Frissítendő minden session végén (BOOT.md S14).

---

## ACTIVE_OBJECTIVE

**Professzionális Windows telepítő- és build-folyamat felépítése a teljes Valutaváltó programhoz** (egyetlen `Penztar-Setup-X.Y.Z-YYYYMMDD.exe` fájl, üzemszerű, auditálható, stabil, újraépíthető).

## STATUS — 2026-04-27 20:08

**Build pipeline ✅ KÉSZ.** A v2.3.5 telepítő legyártva, dokumentálva, knowledge persisted. **Kipróbálás (smoke test futtatás) FÜGGŐ — user döntésre vár opció A/B/C közül.**

## DONE (ebben a sessionben)

### 1. v2.3.5 telepítő legyártva
- `dist/release/Penztar-Setup-2.3.5-20260427.exe` (276.23 MB)
  - SHA256: `9D79DEEDC030FC6FA4B2F438571F8D481E753EB5494C46F79D268A47329DD25D`
- `dist/release/Penztar-Eltavolito-2.3.5-20260427.exe` (60 KB)
  - SHA256: `53683D9D48732CD4FBF9B7C2D590469A298460B24708D365193050B569D6B029`
- `dist/release/build-info.json` (machine-readable metadata)
- `dist/release/install-notes.md` (release notes)
- Git commit: `e1121a30`

### 2. 4-way version sync infrastruktúra kiterjesztve
- `installer/build-common.ps1` — új helper függvények:
  - `Get-PomXmlVersion` / `Set-PomXmlVersion` (Maven `<version>` regex-alapú top-level update)
  - `Get-AllProjectVersions` (4-location consistency reader)
- `installer/scripts/check-version-bump.ps1` refactor:
  - Drift detection mind a 4 helyen (exit 2 ha nem egyezik)
  - AUTO-PATCH bumpol mind a 4-et atomikusan
- 4 verzió-hely:
  1. `package.json` (root)
  2. `frontend-react/package.json`
  3. `penztar-client/package.json`
  4. `backend/pom.xml` (top-level `<version>`)
- Git commit: `70753093`

### 3. Tudás 6 formátumban perzisztálva
- `D:\openclaw\.openclaw\workspace\memory\2026-04-27-installer-build-pipeline-v2.3.5.md` — Junior workspace memory
- `D:\openclaw\.openclaw\workspace\MEMORY.md` — index `BUILD_PIPELINES` szekció
- `docs/knowledge/memory/2026-04-27-installer-build-pipeline-v2.3.5.qmd` — Quarto narratív
- `docs/knowledge/memory/2026-04-27-installer-build-pipeline-v2.3.5.yaml` — machine-parseable
- `docs/obsidian-vault/INSTALLER_BUILD_PIPELINE.md` — Obsidian vault
- Cognee dataset `valutavalto-installer-build` (data_id: `b594ef67-e52b-5dd7-b438-1a84dc8e7fea`)
- `.claude/skills/installer-build/SKILL.md` — agent skill (auto-load)
- Git commit: `27cbace9`

### 4. Teljes user-facing dokumentáció duplikáció nélkül
- `docs/BUILD_WINDOWS.md` (255 sor) — fejlesztői build útmutató
- `docs/INSTALL_WINDOWS.md` (214 sor) — végfelhasználói telepítés
- `docs/UPDATE_WINDOWS.md` (270 sor) — frissítés / backup / rollback
- `docs/SECURITY_INSTALLER_CHECKLIST.md` (299 sor) — biztonsági checklist
- `docs/INSTALLER_DOCS_INDEX.md` (83 sor) — navigációs hub
- `installer/README.md` frissítve (verzió-független, cross-reference táblázat)
- `README.md` linkelve az index-re
- `dist/release/install-notes.md` linkek frissítve
- Git commit: `4322965a`

### 5. Verzió-bump
- 2.3.2 (frontend-react drift) / 2.3.3 (root) / 2.3.4 (penztar-client) / 2.3.2 (pom.xml drift) → **mind 2.3.5-re szinkronizálva**

## NEXT — kipróbálás

> **User explicit kérése** (2026-04-27 20:07): "futtasd, próbáljuk ki, hogy működik-e"
> **Junior válasza** (20:07): 3 opciót ajánlott (A/B/C), user válasz nem érkezett — handoff helyett.
> **A kipróbálás a következő sessionre marad.**

### Opció A — Production install a build gépen (DESKTOP-76D16LK)
- Backup ELŐSZÖR (`pg_dump` + `Copy-Item C:\ProgramData\BestChange ...`)
- Setup futtatás rendszergazdaként → upgrade módba megy (PR #222)
- Verifikáció: services running, port-ok listen-elnek (8080 + 54320), health endpoint
- Lásd: `docs/UPDATE_WINDOWS.md § 2-3`

### Opció B — Izolált silent install + auto-uninstall (smoke test)
- Setup `/S` flag-gel
- Verifikáció ugyanúgy
- Eltavolito futtatás utána

### Opció C — Tiszta Win10/11 VM (legbiztonságosabb)
- Hyper-V VM létrehozása szükséges
- Snapshot előtt → install → smoke test → snapshot revert

## BLOCKED

**Smoke test kipróbálás** — user döntésre vár opció A/B/C közül (lásd a `2026-04-27 20:07` ↔ `20:08` üzenetváltást a chat history-ban).

## DO_NOT_REPEAT

- ❌ **NE** próbálkozz újra felfedezni a 4-way version sync-et — már `BUILD_WINDOWS.md § 4`-ben dokumentálva van + `.claude/skills/installer-build/SKILL.md`-ben agent-skill-ként
- ❌ **NE** futtasd a `Penztar-Setup-*.exe`-t backup nélkül a build gépen
- ❌ **NE** írj felül `version` mezőket egyenként — használd `installer/scripts/check-version-bump.ps1`-et
- ❌ **NE** commit-olj `.claude/worktrees/**`-t (scope pollution, lásd `BUILD_WINDOWS.md § 8.4`)
- ❌ **NE** próbáld újra duplikálni a doksikat — `docs/INSTALLER_DOCS_INDEX.md` listázza a single-source-of-truth-okat

## CRITICAL_CONTEXT

### Saját build gép állapot (2026-04-27 20:00)
- DESKTOP-76D16LK
- `BestChange-PostgreSQL`: **Running**, Auto-start
- `BestChange-Backend`: **Paused**, Auto-start (figyelem: Paused, nem Stopped — manuálisan szüneteltetve volt valamiért)
- `C:\Program Files\Valutavalto Penztar\` exists: **True**
- `C:\ProgramData\BestChange\` exists: **True**
- A meglévő telepítés verziója: ismeretlen (registry-vel ellenőrizhető — `(Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Penztar-Setup").DisplayVersion`)

### Verzió állapot (commit `e1121a30` után)
- `package.json`: 2.3.5
- `frontend-react/package.json`: 2.3.5
- `penztar-client/package.json`: 2.3.5
- `backend/pom.xml`: 2.3.5

### Build artifact-ok a repoban
- `installer/build/Penztar-Setup-2.3.2-20260425.exe` (régi)
- `installer/build/Penztar-Setup-2.3.3-20260427.exe` (régi, test)
- `installer/build/Penztar-Setup-2.3.4-20260427.exe` (régi, test)
- `installer/build/Penztar-Setup-2.3.5-20260427.exe` (**aktuális**)
- `installer/build/Penztar-Eltavolito-2.3.5-20260427.exe` (**aktuális**)
- A `dist/release/` mappában csak v2.3.5 van (gitignored, GitHub Release-en publikálva)

## ENTRY_POINT_FOR_NEXT_SESSION

```
1. memory_search "valutavalto installer v2.3.5 smoke test"
2. read this HANDOVER.md
3. read .claude/skills/installer-build/SKILL.md (auto-load, agent skill)
4. git log --oneline -5 (legutóbbi commitok)
5. user-decision: opció A/B/C közül a smoke test-hez
```

**Aktív cél:** v2.3.5 telepítő smoke test (futtatás + ellenőrzés).
**Tiltott irányok:** doksi újraírás, version sync újrafelfedezés, backup nélküli install a build gépen.
**Következő lépés:** user válasza opció A/B/C közül (chat history-ban a `20:07` üzenet után).

## REFERENCES

- `docs/INSTALLER_DOCS_INDEX.md` — minden installer-doksi linkje
- `.claude/skills/installer-build/SKILL.md` — agent build skill
- `D:\openclaw\.openclaw\workspace\memory\2026-04-27-installer-build-pipeline-v2.3.5.md` — Junior memory
- `CHANGELOG.md` — verzió-tortenet (PR #177 4-way bump, PR #222 `$UPGRADE_MODE`)
