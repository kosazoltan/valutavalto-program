# Biztonsági Ellenőrzőlista — Telepítő Build & Telepítés

> **Cél:** A Valutaváltó Pénztár Windows telepítő biztonsági auditja. **Build előtti, build utáni, és telepítés utáni** ellenőrző lista. Pénzügyi szoftverhez méltó security posture-t garantál.
>
> **Általános Pénztár biztonsági audit:** lásd [`SECURITY-AUDIT.md`](SECURITY-AUDIT.md).
>
> **Build folyamat:** lásd [`BUILD_WINDOWS.md`](BUILD_WINDOWS.md).

## Tartalom

1. [Build előtti ellenőrzés](#1-build-előtti-ellenőrzés)
2. [Build utáni ellenőrzés](#2-build-utáni-ellenőrzés)
3. [Telepítés utáni ellenőrzés (a céges gépen)](#3-telepítés-utáni-ellenőrzés-a-céges-gépen)
4. [Credential & secret kezelés](#4-credential--secret-kezelés)
5. [Threat model](#5-threat-model)
6. [Incidens response](#6-incidens-response)

---

## 1. Build előtti ellenőrzés

### 1.1 Forrás-integritás

- [ ] **Tiszta repó** — `git status --short` → üres vagy csak az aktuális build-relevant fájlok
- [ ] **Nincs `.claude/worktrees/`** scope pollution — `git diff --cached --name-only | Select-String "claude|worktree"` üres output
- [ ] **Helyes branch** — `git branch --show-current` → `main` vagy hivatalos feature branch (nem `detached HEAD`)
- [ ] **4-way verzió-szinkron OK**:
  ```powershell
  . installer\build-common.ps1
  Get-AllProjectVersions -RepoRoot D:\repo\valutavalto-program | Format-Table
  # IsConsistent oszlop = True
  ```

### 1.2 Build gép környezete

- [ ] **Trusted gép** — nem random fejlesztő laptop, hanem dedikált build gép vagy CI runner
- [ ] **Minden build függőség SHA-256 ellenőrzött**:
  - JDK 21 (Adoptium / Microsoft / Azul — hivatalos forrás)
  - Node.js 20+ (nodejs.org)
  - NSIS 3.x (sourceforge hivatalos)
- [ ] **Nincs malware** a build gépen — recent antivirus scan
- [ ] **Internet kapcsolat trusted** — első buildnél PG/NSSM/VC++ letöltés direkt forrásokból (`get.enterprisedb.com`, `nssm.cc`, `aka.ms`)

### 1.3 Verzió-bump audit

- [ ] **`installer/scripts/check-version-bump.ps1`** futtatható (drift detection)
- [ ] **CHANGELOG.md** frissítve az új verzióhoz
- [ ] **Git tag** előkészítve (push után): `git tag -a vX.Y.Z -m "Release X.Y.Z"`

## 2. Build utáni ellenőrzés

### 2.1 EXE integritás

- [ ] **Mindkét EXE elkészült:**
  ```powershell
  Get-ChildItem installer\build\Penztar-Setup-*.exe, installer\build\Penztar-Eltavolito-*.exe |
      Select-Object Name, Length, LastWriteTime
  ```
- [ ] **SHA-256 hash generált** mindkét EXE-hez (`dist/release/*.sha256`)
- [ ] **Méret reasonable**:
  - Setup: 250–300 MB (~276 MB)
  - Eltavolito: 50–80 KB (~60 KB)
- [ ] **EXE metadata helyes**:
  ```powershell
  (Get-Item installer\build\Penztar-Setup-*.exe).VersionInfo |
      Select-Object FileVersion, ProductVersion, ProductName, FileDescription
  ```
  - `ProductName` = "Valutavalto Penztar"
  - `FileVersion` = aktuális build verzió

### 2.2 Bundled függőségek

- [ ] **Build-time SHA-256 ellenőrzés** lefutott a build során (script logokban):
  - PostgreSQL 17.5 binaries.zip — `795196DF1B2855FD0C7FB52629C6CC16ACAA85819912E732BD4C46863E77EB30`
  - NSSM 2.24
  - VC++ Redistributable
- [ ] **Custom JRE jlink-elt** csak a szükséges modulokkal (~50 MB, nem teljes JDK)
- [ ] **Nincs feleslegesen embedded fájl** (pl. tesztek, dokumentáció, source)

### 2.3 Validation suite

- [ ] **`installer/tests/installer-validation-suite.ps1`** lefuttatva:
  ```powershell
  pwsh -NoLogo -NoProfile -File installer\tests\installer-validation-suite.ps1
  # Minden test PASS
  ```
- [ ] **Manual smoke test** egy izolált VM-en:
  - Win10/11 x64 friss VM
  - Setup futtatás → telepítés sikeres
  - Setup Wizard mind a 4 lépés OK
  - Pénztár alkalmazás indul
  - Backend health: `curl http://127.0.0.1:8080/actuator/health`
  - Eltávolító futtatás → tiszta deinstallation
- [ ] **Automatizált clean VM installer smoke evidence** lefuttatva a disposable VM-en:
  ```powershell
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\installer-clean-vm-smoke.ps1 `
    -ExecuteInstall -AcceptVmMutation -ConfirmDisposableCleanVm
  # Elvárt: 0 FAIL; riport a security-reports/installer-clean-vm-smoke/<timestamp>/report.md alatt
  ```

### 2.4 Code signing (FUTURE — még nincs implementálva)

> **Jelenleg a EXE-k NEM digitálisan aláírtak.** Ez a SmartScreen warning oka a végfelhasználó gépén. Production-ready release-hez **EV Code Signing Certificate** szükséges (~300-500 EUR/év).

- [ ] **Code Signing Certificate** beszerzése (DigiCert / Sectigo / Comodo EV)
- [ ] **`signtool.exe`** integráció a `build-installer.ps1` és `build-cleanup.ps1` végén:
  ```powershell
  signtool sign /f $env:CODE_SIGNING_CERT_PATH /p $env:CODE_SIGNING_CERT_PASSWORD `
      /t http://timestamp.digicert.com /fd SHA256 `
      installer\build\Penztar-Setup-*.exe
  ```
- [ ] **Authenticode signature ellenőrzés**:
  ```powershell
  Get-AuthenticodeSignature installer\build\Penztar-Setup-*.exe |
      Select-Object Status, SignerCertificate
  ```
- [ ] **Fail-closed signed artifact smoke** minden production release artifactra:
  ```powershell
  npm run installer:smoke:signed
  # Elvárt: 0 FAIL; minden EXE Authenticode Status = Valid
  ```

## 3. Telepítés utáni ellenőrzés (a céges gépen)

### 3.1 Service & Firewall

- [ ] **Két szolgáltatás fut és Auto-start**:
  ```powershell
  Get-Service -Name "BestChange-*" | Format-Table Name, Status, StartType
  # BestChange-PostgreSQL: Running, Automatic
  # BestChange-Backend:    Running, Automatic
  ```
- [ ] **Tűzfal-szabály korlátozott** localhost-ra:
  ```powershell
  Get-NetFirewallRule -DisplayName "BestChange-*" |
      Get-NetFirewallAddressFilter | Format-List
  # RemoteAddress = 127.0.0.1 vagy LocalSubnet
  ```
- [ ] **Backend csak localhost-on listen-el**:
  ```powershell
  netstat -ano | findstr "8080"
  # Csak 127.0.0.1:8080 vagy [::1]:8080 (NEM 0.0.0.0:8080!)
  ```
- [ ] **PostgreSQL csak localhost-on listen-el**:
  ```powershell
  netstat -ano | findstr "54320"
  # Csak 127.0.0.1:54320
  ```

### 3.2 Filesystem permissions

- [ ] **`C:\ProgramData\BestChange\config\` ACL inheritance off**:
  ```powershell
  (Get-Acl "C:\ProgramData\BestChange\config").Access |
      Select-Object IdentityReference, FileSystemRights, AccessControlType, IsInherited
  # Inherited = False mindenütt
  # Csak: SYSTEM, Administrators, BestChange-Backend service user
  # Users csoport NINCS a listán
  ```
- [ ] **`.env` fájl olvasható csak service user által**:
  ```powershell
  (Get-Acl "C:\ProgramData\BestChange\config\.env").Access |
      Select-Object IdentityReference, FileSystemRights
  ```
- [ ] **`.pg-postgres-password` fájl restricted**:
  ```powershell
  (Get-Acl "C:\ProgramData\BestChange\config\.pg-postgres-password").Access |
      Select-Object IdentityReference, FileSystemRights
  ```

### 3.3 PostgreSQL hardening

- [ ] **`pg_hba.conf` `scram-sha-256` auth**:
  ```powershell
  Get-Content "C:\ProgramData\BestChange\pgsql\data\pg_hba.conf" |
      Where-Object { $_ -match "^(host|local)" }
  # method oszlop = scram-sha-256 mindenütt (NEM trust, NEM md5)
  ```
- [ ] **Postgres superuser random jelszót kapott**:
  - `.pg-postgres-password` fájl létezik és nem üres
  - Hossz min 32 karakter
- [ ] **`valuta_user` (alkalmazás user) létezik és csak a `valutavalto` DB-hez fér hozzá**:
  ```powershell
  & "C:\ProgramData\BestChange\pgsql\bin\psql.exe" `
      -U postgres -p 54320 -d postgres `
      -c "\du valuta_user"
  # Member of: csak az 'valuta_user' role, NINCS Superuser
  ```

### 3.4 Secrets nem szivárognak

- [ ] **JWT secret nincs logolva** — `C:\ProgramData\BestChange\logs\backend.log` keresése:
  ```powershell
  Select-String -Path "C:\ProgramData\BestChange\logs\backend.log" -Pattern "JWT_SECRET|jwt.secret" |
      Select-Object Line
  # Üres output = OK
  ```
- [ ] **DB jelszó nincs logolva**:
  ```powershell
  Select-String -Path "C:\ProgramData\BestChange\logs\backend.log" -Pattern "password=|spring.datasource.password" |
      Select-Object Line
  # Üres output = OK
  ```

### 3.5 No baked-in credentials

- [ ] **A telepítő EXE-ben NINCSENEK beégetett kulcsok**:
  ```powershell
  # Ellenőrizd, hogy az EXE-ből kicsomagolt fájlokban van-e gyanús string:
  $tempDir = "$env:TEMP\penztar-extract"
  # (manual extract vagy 7-Zip)
  Get-ChildItem $tempDir -Recurse -Include *.env,*.properties,*.json |
      Select-String -Pattern "JWT_SECRET=[^$]" |
      Select-Object Path, Line
  # Üres output = OK (csak placeholder/template van benne, nem éles érték)
  ```
- [ ] **Csomagolt Electron artifact secret-leak scan lefutott**:
  ```powershell
  npm run installer:smoke:artifacts
  # Elvárt: resources + app.asar forbidden filename és high-confidence secret pattern scan PASS
  ```
- [ ] **Minden secret helyben generálódik** telepítéskor:
  - JWT secret (`crypto.randomBytes(32)` az Electron oldalon, vagy `[System.Web.Security.Membership]::GeneratePassword`)
  - PostgreSQL admin jelszó
  - PostgreSQL `valuta_user` jelszó
  - Encryption key (AES-256-GCM)

## 4. Credential & secret kezelés

### 4.1 Soha ne tedd

- ❌ **NE** commitold a `.env` fájlt (gitignored)
- ❌ **NE** logold a JWT secret-et, DB jelszót
- ❌ **NE** emaileld a bootstrap admin credential-ot
- ❌ **NE** használd ugyanazt a JWT secret-et több gépen
- ❌ **NE** beégetett credential a telepítő EXE-be

### 4.2 Mit csinálj

- ✅ **Helyben generálj** minden secret-et telepítéskor
- ✅ **`scram-sha-256`** PG auth (NEM `trust`, NEM `md5`)
- ✅ **`0o600`** perms a `.env` fájlon + atomic rename
- ✅ **ACL hardening** a `config/` mappán (inheritance off)
- ✅ **1Password / secure vault** a bootstrap admin credential-hoz
- ✅ **Code Signing Certificate** EV-vel (jövőbeli követelmény)

## 5. Threat model

### 5.1 Támadási vektorok és védelem

| Támadási vektor | Hatás | Védelem |
|-----------------|-------|---------|
| **Modified installer EXE** (man-in-the-middle, kompromittált fájlszerver) | Backdoor a telepítőben | SHA-256 hash közzététele a release notes-ban + Code Signing (jövőbeli) |
| **Lokális privilege escalation** | Service user → SYSTEM | Backend service NEM SYSTEM (lehet `LocalService` vagy custom user) |
| **DB credential kiszivárgás** | Adatbázis-támadás | `scram-sha-256` + ACL hardening + nincs logolt jelszó |
| **Backend port exposure** | Külső támadás 8080-on | Tűzfal `127.0.0.1`-re korlátozza |
| **PG port exposure** | Külső DB connection | Tűzfal + `pg_hba.conf` localhost-only |
| **JWT secret extraction** | Token forgery | Helyben generált, ACL-restricted |
| **`.env` lopás** | Minden secret kompromittálva | `0o600` perms + ACL inheritance off |

### 5.2 Out of scope (nem fedi a telepítő)

- Network-level attacks (VPN / firewall a vállalati hálózat szintjén)
- Insider threat (a service user maga rosszindulatú)
- OS-level kompromisszum (Windows-on belül a SYSTEM-et nem védjük)
- Side-channel attacks (Spectre/Meltdown — OS patch felelőssége)

## 6. Incidens response

### 6.1 Ha kompromittált EXE gyanú

1. **AZONNAL** állítsd le a `BestChange-Backend` és `BestChange-PostgreSQL` szolgáltatásokat minden érintett gépen.
2. **Backup** a teljes `C:\ProgramData\BestChange\` mappát forensic célra.
3. **Ne futtasd** a kompromittált EXE-t másik gépen.
4. **Hash összehasonlítás** a hivatalos GitHub Release SHA-256-jával.
5. **Értesítsd** az IT-vezetést és a Bence agentet (deploy + security).

### 6.2 Ha credential leak gyanú

1. **AZONNALI rotáció**:
   ```powershell
   # Új JWT secret + encryption key generálás:
   pwsh -File installer\scripts\generate-secrets.ps1 -RotateOnly
   # Restart backend
   Restart-Service BestChange-Backend
   ```
2. **Felhasználói jelszó-reset** kötelező (mind az alkalmazás, mind a PostgreSQL `valuta_user`)
3. **Audit log** átnézése: `C:\ProgramData\BestChange\logs\backend.log`
4. **Forensic backup** + IT-bevonás

### 6.3 Ha PG `pg_hba.conf` `trust` auth-ra állították

**Ez kritikus**: bárki a gépről jelszó nélkül belép a DB-be.

```powershell
# Azonnal állítsd vissza:
$pgHbaPath = "C:\ProgramData\BestChange\pgsql\data\pg_hba.conf"
(Get-Content $pgHbaPath) -replace '^\s*(host|local)\s+\S+\s+\S+\s+\S+\s+trust', '$0  # SECURITY: changed back to scram-sha-256' |
    ForEach-Object { $_ -replace 'trust\s*$','scram-sha-256' } |
    Set-Content $pgHbaPath -Force

Restart-Service BestChange-PostgreSQL
```

Majd: rotáljon minden secret-et + audit log review.

---

## Kapcsolódó dokumentumok

- [`BUILD_WINDOWS.md`](BUILD_WINDOWS.md) — build folyamat
- [`INSTALL_WINDOWS.md`](INSTALL_WINDOWS.md) — clean install
- [`UPDATE_WINDOWS.md`](UPDATE_WINDOWS.md) — frissítés
- [`SECURITY-AUDIT.md`](SECURITY-AUDIT.md) — általános Pénztár biztonsági audit
- [`legacy-analysis/bence-security-compliance-analysis.md`](legacy-analysis/bence-security-compliance-analysis.md) — Bence security baseline
