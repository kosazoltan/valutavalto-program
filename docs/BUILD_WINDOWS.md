# Build Windows — Valutaváltó Pénztár Telepítő

> **Cél:** ez a dokumentum a Valutaváltó Pénztár Windows telepítőjének (`Penztar-Setup-X.Y.Z-YYYYMMDD.exe` + `Penztar-Eltavolito-X.Y.Z-YYYYMMDD.exe`) **fejlesztői build útmutatója**. Ki kell tudnia gyártani a telepítőt egy clean build gépen.
>
> **Forrásigazság:** a `installer/README.md` tartalmazza az installer belső struktúráját és a fejlesztői részleteket. Ez a doksi **a build folyamatra fókuszál**, és arra hivatkozik.
>
> **Verzióhoz kötött release notes:** `dist/release/install-notes.md` (verziókonkrét SHA256-okkal).

## Tartalom

1. [Áttekintés](#1-áttekintés)
2. [Build gép előfeltételei](#2-build-gép-előfeltételei)
3. [Build folyamat (2 lépés)](#3-build-folyamat-2-lépés)
4. [4-way verzió-szinkron](#4-4-way-verzió-szinkron)
5. [Build flag-ek és gyorsítások](#5-build-flag-ek-és-gyorsítások)
6. [Release artifact bundle](#6-release-artifact-bundle)
7. [Validáció](#7-validáció)
8. [Tipikus hibák és javítás](#8-tipikus-hibák-és-javítás)
9. [Kapcsolódó dokumentumok](#9-kapcsolódó-dokumentumok)

---

## 1. Áttekintés

A telepítő **két EXE-ből** áll:

| Fájl | Méret | Szerep |
|------|-------|--------|
| `Penztar-Setup-X.Y.Z-YYYYMMDD.exe` | ~276 MB | Egyfájlos teljes telepítő (PostgreSQL 17.5 + backend + frontend + Electron + Windows szolgáltatások + auto-cleanup) |
| `Penztar-Eltavolito-X.Y.Z-YYYYMMDD.exe` | ~60 KB | Standalone Eltávolító (csak akkor kell, ha a Setup auto-cleanup-ja fennakad egy nagyon sérült telepítésen) |

A Setup EXE **MÁR TARTALMAZ** auto-cleanup logikát — a standalone Eltávolító csak végső eszköz.

## 2. Build gép előfeltételei

> **Fontos:** ezek **NEM** szükségesek a végfelhasználó gépén — kizárólag a build gépen.

| Komponens | Verzió | Megjegyzés |
|-----------|--------|------------|
| OS | Windows 10/11 x64 | |
| JDK | **21** | backend Maven build + jlink |
| Node.js | **20+** | frontend (Vite) + Electron build |
| npm | bundled with Node | |
| Maven | via `backend/mvnw.cmd` | nem kell külön telepíteni |
| NSIS | **3.x** | `C:\Program Files (x86)\NSIS\makensis.exe` — telepítés: <https://nsis.sourceforge.io/Download> |
| PowerShell | **7+ (`pwsh`)** ajánlott | WinPS 5.1 működik, de cache-bug (lásd [§8](#8-tipikus-hibák-és-javítás)) |
| Internet | első buildhez | PostgreSQL 17.5 + NSSM + VC++ letöltés (~150 MB, SHA-256 verifikált, cache-elve) |

NSIS plugin függőségek a repóban (nem kell külön):
- `installer/plugins/x86-unicode/` (nsProcess, LockedList)
- `installer/include/` (helper makrók)

## 3. Build folyamat (2 lépés)

### 3.1 Setup EXE

```powershell
cd D:\repo\valutavalto-program
pwsh -NoLogo -NoProfile -File installer\build-installer.ps1
```

**Idő:** 5–10 perc cached, 30+ perc first-run (PG/NSSM/VC++ letöltés miatt).

**Belső fázisok** (`installer/build-installer.ps1`, ~340 sor):

1. **Verzió-emelő gate** (`installer/scripts/check-version-bump.ps1`) — 4-way sync + auto-patch ([§4](#4-4-way-verzió-szinkron))
2. **Backend Maven build** → `valuta-backend.jar` (Spring Boot 3.5.13)
3. **Custom JRE jlink** (~50 MB, csak szükséges modulok)
4. **Frontend (React/Vite) + Electron (electron-builder) build**
5. **PostgreSQL 17.5 + NSSM + VC++ Redistributable letöltés** (cached, SHA-256 verifikált)
6. **Config + scripts staging** (`installer/scripts/init-db.bat`, `start-services.bat`, `generate-secrets.ps1`, stb.)
7. **NSIS compile** → egyfájlos `Penztar-Setup-X.Y.Z-YYYYMMDD.exe`

**Output:** `installer\build\Penztar-Setup-X.Y.Z-YYYYMMDD.exe`

### 3.2 Eltávolító EXE

```powershell
pwsh -NoLogo -NoProfile -File installer\build-cleanup.ps1
```

**Idő:** ~1 másodperc.

**Output:** `installer\build\Penztar-Eltavolito-X.Y.Z-YYYYMMDD.exe`

## 4. 4-way verzió-szinkron

> **KRITIKUS:** A repo **4 helyen** tartja a verziót, és **mind a 4-nek egyeznie kell**. Történelmi forrás: `CLAUDE.md` line 370 + PR #103/#104 + PR #177 (CHANGELOG.md release process).

| # | Fájl | Szerep |
|---|------|--------|
| 1 | `package.json` | monorepo root |
| 2 | `frontend-react/package.json` | admin frontend |
| 3 | `penztar-client/package.json` | Electron pénztáros kliens |
| 4 | `backend/pom.xml` | Spring Boot Maven artifact (top-level `<version>` tag, **NEM** parent / dependency / plugin) |

A `installer/scripts/check-version-bump.ps1` automatikusan kezeli mind a 4-et:

- **Drift detection:** ha a 4 hely nem egyezik → exit 2 + diagnostic
- **AUTO-PATCH default:** ha `current ≤ max(existing build/*.exe)` → bump
- **STRICT mode** (`-NoAutoPatch`): exit 1 helyett bump nélkül
- **Bump mechanizmus:** `npm version patch --no-git-tag-version` x3 (root + frontend-react + penztar-client) + regex-alapú `pom.xml <version>` update

A gate-et a `build-installer.ps1` **automatikusan** futtatja a build elején — kézzel nem kell hívni.

### Kézi verzió-állapot ellenőrzés

```powershell
. installer\build-common.ps1
Get-AllProjectVersions -RepoRoot D:\repo\valutavalto-program | Format-Table
```

Ha `IsConsistent: False` → drift van, **manuálisan szinkronizáld** a build előtt.

## 5. Build flag-ek és gyorsítások

```powershell
# Csak NSIS compile (pár másodperc, ha minden stage kész):
pwsh -File installer\build-installer.ps1 -SkipBackendBuild -SkipFrontendBuild -SkipDownloads

# Csak letöltést skip (backend + frontend újrabuild):
pwsh -File installer\build-installer.ps1 -SkipDownloads

# Backend skip (frontend + electron újrabuild + NSIS):
pwsh -File installer\build-installer.ps1 -SkipBackendBuild
```

## 6. Release artifact bundle

A `dist/release/` directory tartalmazza a kiadásra kész fájlokat:

```
dist/release/
├── Penztar-Setup-X.Y.Z-YYYYMMDD.exe          (276 MB, gitignored)
├── Penztar-Eltavolito-X.Y.Z-YYYYMMDD.exe     (60 KB, gitignored)
├── Penztar-Setup-X.Y.Z-YYYYMMDD.exe.sha256
├── Penztar-Eltavolito-X.Y.Z-YYYYMMDD.exe.sha256
├── build-info.json                            # machine-readable build metadata
└── install-notes.md                           # human-readable release notes (verziókonkrét)
```

A binary EXE-k és `.sha256` fájlok **gitignored** — 276 MB nem mehet repo-ba. GitHub Release-en publikálva.

### Bundle stage-elése build után

```powershell
$version = (Get-Content package.json -Raw | ConvertFrom-Json).version
$buildDate = Get-Date -Format "yyyyMMdd"

New-Item -ItemType Directory -Path "dist\release" -Force | Out-Null

Copy-Item "installer\build\Penztar-Setup-$version-$buildDate.exe" "dist\release\" -Force
Copy-Item "installer\build\Penztar-Eltavolito-$version-$buildDate.exe" "dist\release\" -Force

foreach ($f in Get-ChildItem dist\release\*.exe) {
    $hash = (Get-FileHash $f -Algorithm SHA256).Hash
    "$hash *$($f.Name)" | Out-File "dist\release\$($f.Name).sha256" -Encoding ascii -NoNewline
    Write-Host "$($f.Name): $hash"
}
```

A `build-info.json` és `install-notes.md` minden release után frissítendő (verzió, hash, dátum).

## 7. Validáció

```powershell
pwsh -NoLogo -NoProfile -File installer\tests\installer-validation-suite.ps1
```

A 30K-bytes 5-textbook validation suite (NSIS Manual + Tricentis + SoftwareTestingHelp + GeeksForGeeks + Advanced QA) ellenőrzi:

- EXE metadata (Product Name, File Version, Description)
- NSIS belső struktúra
- Staged binary fájlok (PG, NSSM, JRE)
- SHA-256 hash konzisztenciát

Lásd: [SECURITY_INSTALLER_CHECKLIST.md](SECURITY_INSTALLER_CHECKLIST.md) a teljes biztonsági ellenőrzőlistáért.

## 8. Tipikus hibák és javítás

### 8.1 PostgreSQL ZIP cache `CHECKSUM MISMATCH`

**Tünet:**
```
Expected: 795196DF1B2855FD0C7FB52629C6CC16ACAA85819912E732BD4C46863E77EB30
Actual:   46903BB56BB0A40A81768703FA7420F0690095685DA040BED2C584B900A1124C
```

**Javítás:**
```powershell
Remove-Item installer\build\downloads\postgresql-binaries.zip -Force
# A következő build automatikusan letölti újra
```

### 8.2 PostgreSQL letöltés `ResponseEnded prematurely`

`Invoke-WebRequest` nagy fájloknál instabil. **Curl-lel resume-os letöltés:**

```powershell
cd installer\build\downloads
curl.exe -L -o postgresql-binaries.zip --retry 5 --retry-delay 5 --connect-timeout 30 --progress-bar `
    'https://get.enterprisedb.com/postgresql/postgresql-17.5-1-windows-x64-binaries.zip'
```

### 8.3 WinPS 5.1 `[version]` operator caching bug

**Tünet:** `check-version-bump.ps1` bumpol amikor nem kéne (csak WinPS 5.1-en).

**Javítás:** `[version]::Parse(...).CompareTo(...)` használata `-le` helyett. A jelenlegi `check-version-bump.ps1` már így van implementálva. Ha módosítani kell: ne használj `-le`, `-ge` operátort `[version]` típusokon WinPS 5.1-ben.

### 8.4 `.claude/worktrees/**` scope pollution

**Tünet:** `git commit` 28000+ fájlt tartalmaz (Cursor IDE worktree-k).

**Javítás:** `.gitignore`-ban legyen:
```
.claude/worktrees/
.worktrees/
```

Build előtti ellenőrzés:
```powershell
git status --short | Select-String -Pattern "claude|worktree" | Out-String
# Üres output = OK
```

### 8.5 NSIS encoding error

**Tünet:** `Penztar-Setup.nsi` nem fordul (mojibake hibák).

**Javítás:** A `.nsi` fájl **Windows-1252 ASCII** kell legyen. Ékezetek tilos. Em-dash (`—`) → sima `-`. Idézőjelek: ASCII (`"`), nem typographic (`""`).

### 8.6 Build hangs at NSIS compile

NSIS LZMA compression 758 MB → várhatóan 5-10 perc. **Ne öld meg a folyamatot** — különösen az utolsó fázisban.

### 8.7 First-run build túl lassú

Várható: 30+ perc, mert `installer/build/downloads/` üres és letöltés szükséges (~150 MB).

Második buildtől fogva (cached): 5-10 perc.

## 9. Kapcsolódó dokumentumok

| Doksi | Mit tartalmaz |
|-------|---------------|
| [`installer/README.md`](../installer/README.md) | Installer belső struktúra, fejlesztői forrásigazság |
| [`docs/INSTALL_WINDOWS.md`](INSTALL_WINDOWS.md) | Végfelhasználói telepítési útmutató |
| [`docs/UPDATE_WINDOWS.md`](UPDATE_WINDOWS.md) | Frissítési protokoll |
| [`docs/SECURITY_INSTALLER_CHECKLIST.md`](SECURITY_INSTALLER_CHECKLIST.md) | Biztonsági ellenőrzőlista |
| [`docs/knowledge/installer-wizard-implementation-guide.md`](knowledge/installer-wizard-implementation-guide.md) | First-Run Setup Wizard részletei |
| [`docs/knowledge/memory/2026-04-27-installer-build-pipeline-v2.3.5.qmd`](knowledge/memory/2026-04-27-installer-build-pipeline-v2.3.5.qmd) | Lessons learned + build evidence |
| [`CHANGELOG.md`](../CHANGELOG.md) | Verzió-tortenet |
| [`.claude/skills/installer-build/SKILL.md`](../.claude/skills/installer-build/SKILL.md) | Agent skill (auto-loaded) |
| [`dist/release/install-notes.md`](../dist/release/install-notes.md) | Adott release-hez tartozó install notes (SHA256-okkal) |
