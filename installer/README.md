# Valutaváltó Pénztár — telepítő build & használat

Ebben a mappában található minden ami egyetlen `.exe` fájlba csomagolja a teljes
Valutaváltó Pénztár rendszert (PostgreSQL + backend JAR + bundled JRE + Electron
kliens + NSSM service manager), valamint egy külön **Eltávolító** segédprogramot,
amivel a régi, törött telepítések gyorsan megtisztíthatók a kollégák gépéről.

---

## 1. Telepítő fájlok — amit a kollégák kapnak

A build után két Windows telepítő EXE keletkezik, és **ezt a kettőt kell
szétküldeni** a munkaállomásokra:

| Fájl                                  | Méret    | Mit csinál |
|---------------------------------------|----------|------------|
| `Penztar-Eltavolito-2.1.0-*.exe`      | ~60 KB   | Leállítja és eltávolítja a régi BestChange szolgáltatásokat, törli a `C:\ProgramData\BestChange` mappát, a Program Files-t, a tűzfalszabályokat és a registry bejegyzéseket. Egy öntisztító eszköz a "rossz" telepítések nyomainak eltüntetésére. |
| `Penztar-Setup-2.1.0-*.exe`           | ~350 MB  | A teljes egyfájlos telepítő: **automatikusan cleanup-olja a régi telepítést**, majd tiszta új telepítést hajt végre (PostgreSQL 17.5, backend, Electron kliens, Windows szolgáltatások, tűzfal, asztali ikon). |

> **Fontos:** A `Penztar-Setup` már tartalmazza ugyanazt a cleanup logikát amit az
> Eltávolító önmagában végrehajt (`FAZIS 1: Regi telepites cleanup` az
> `Penztar-Setup.nsi` elején). A külön **Eltavolito** csak akkor szükséges, ha a
> régi telepítés annyira sérült, hogy a Setup cleanup fázisa akad fenn rajta,
> vagy ha csak eltávolítani akarunk mindent telepítés nélkül.

---

## 2. Ajánlott workflow a kollégáknak

Ezt küldd el nekik e-mailben a két EXE-vel együtt:

> **Telepítési útmutató**
>
> 1. Zárjátok be a Pénztár alkalmazást.
> 2. **Jobb klikk** a `Penztar-Setup-2.1.0-*.exe` fájlra → **"Futtatás rendszergazdaként"**.
> 3. Kövessétek a varázsló lépéseit (Következő → Következő → Telepítés).
> 4. Amikor először elindul a Pénztár kliens, egy **4 lépéses beállító varázsló**
>    jön be — ebben kiválasztjátok az irodát, beállítjátok a központi szerver
>    URL-t (vagy offline módot), és megadtok egy admin jelszót.
> 5. Kész — az alkalmazás ezután használható.
>
> **Ha a telepítés hibaüzenettel megáll** (pl. "BestChange-PostgreSQL service cannot be removed"):
>
> 1. Futtasd **rendszergazdaként** az `Penztar-Eltavolito-2.1.0-*.exe`-t.
> 2. Várd meg amíg "KESZ! A regi telepites teljesen eltavolitva" üzenet jön.
> 3. Indítsd újra a gépet (biztos, ami biztos).
> 4. Utána futtasd újra a `Penztar-Setup-*.exe`-t rendszergazdaként.

---

## 3. Build — hogyan gyártsuk le a két EXE-t

### 3.1 Előfeltételek a build-géphez (NEM a kollégák gépe!)

- Windows 10/11 x64
- **JDK 21** (backend build + jlink-hez)
- **Node.js 20+** és npm (frontend + Electron build-hez)
- **Maven** (a `backend/mvnw.cmd` használható, önálló telepítés nem szükséges)
- **NSIS 3.x** — telepítés: <https://nsis.sourceforge.io/Download>
  - Alapértelmezett útvonal: `C:\Program Files (x86)\NSIS\makensis.exe`
  - Szükséges pluginek (nsProcess, LockedList) a repóban:
    `installer/plugins/x86-unicode/` és `installer/include/`
- Internet (első buildnél PostgreSQL 17.5 + NSSM + VC++ Redistributable letöltéshez, ~150 MB, SHA-256 ellenőrzött)

### 3.2 Az **Eltávolító** (cleanup) exe lefordítása — gyors, ~1 másodperc

```powershell
powershell -ExecutionPolicy Bypass -File installer\build-cleanup.ps1
```

Kimenet: `installer\build\Penztar-Eltavolito-2.1.0-<yyyymmdd>.exe` (~60 KB)

### 3.3 A **teljes telepítő** lefordítása — ~10-30 perc (first run)

```powershell
powershell -ExecutionPolicy Bypass -File installer\build-installer.ps1
```

Kimenet: `installer\build\Penztar-Setup-2.1.0-<yyyymmdd>.exe` (~350 MB)

A script az alábbi lépéseket végzi el:
1. Backend Maven build → `valuta-backend.jar`
2. Custom JRE jlink-kel (~50 MB, csak a szükséges modulok)
3. Frontend (React/Vite) + Electron (electron-builder) build
4. PostgreSQL 17.5 + NSSM + VC++ Redistributable letöltése (cache-elve,
   SHA-256 integrity check-kel)
5. Config template + init/start/stop scriptek staging
6. NSIS compile → egyfájlos `Penztar-Setup-*.exe`

#### Build flag-ek gyorsabb újrabuild-hez

```powershell
# Ha már jól működik egy stage:
powershell -ExecutionPolicy Bypass -File installer\build-installer.ps1 `
  -SkipBackendBuild -SkipFrontendBuild -SkipDownloads
# (Csak az NSIS-t fordítja újra - néhány másodperc)
```

### 3.4 Validáció

```powershell
powershell -ExecutionPolicy Bypass -File installer\tests\installer-validation-suite.ps1
```

A suite (~30 KB) végigellenőrzi a generated EXE metaadatait, aláírását, belső
struktúráját és a staged bináris fájlokat.

---

## 4. Amit a telepítő automatikusan elvégez a kollégák gépén

A `Penztar-Setup-*.exe` futtatása után a gépen létrejön:

| Komponens             | Helye |
|-----------------------|-------|
| Program Files         | `C:\Program Files\Valutavalto Penztar\` (Electron kliens + uninstaller) |
| Adatok + PostgreSQL   | `C:\ProgramData\BestChange\` (pgsql data, backend JAR, JRE, NSSM) |
| `BestChange-PostgreSQL` Windows szolgáltatás | `54320` porton, NSSM-mel, random `scram-sha-256` jelszóval |
| `BestChange-Backend`  Windows szolgáltatás   | `8080` porton, NSSM-mel, generated JWT secret + encryption key |
| Windows tűzfal        | `localhost`-ra (127.0.0.1) korlátozva, 8080 + 54320 port |
| Asztali ikon          | "Valutavalto Penztar" |
| Első indítás          | Electron kliens → **First-Run Setup Wizard** (iroda választás, szerver URL, admin jelszó) |

Az összes titkos kulcs (`JWT_SECRET`, `app.encryption.key`, PG admin + user
jelszó) telepítéskor generálódik helyben (`generate-secrets.ps1` +
`crypto.randomBytes`-szal a wizard-ban), **nincsenek beégetett credential-ek** a
telepítő EXE-ben.

---

## 5. Biztonsági szempontok

- Minden bundled dependency **SHA-256 checksum**-mal validált build-időben (PG, NSSM, VC++).
- `pg_hba.conf` `scram-sha-256` auth-ra van hardenelve telepítés után (a
  `postgres` superuser is kap random jelszót).
- A `C:\ProgramData\BestChange\config\` mappa ACL-jei explicit korlátozva
  vannak (inheritance off, csak SYSTEM + Administrators + BestChange-Backend
  service user kap olvasási jogot).
- `.env` a Pénztár kliens oldalon `0o600` jogokkal + atomikus rename-mel íródik.
- A Windows tűzfal a 8080 + 54320 portot `remoteip=127.0.0.1`-re korlátozza.

---

## 6. Kapcsolódó fájlok

| Fájl | Mit csinál |
|------|------------|
| `Penztar-Setup.nsi` | Fő telepítő script (v7.0, ~1040 sor) — cleanup + new install |
| `Penztar-Cleanup.nsi` | Standalone Eltávolító script |
| `build-installer.ps1` | Fő build pipeline (backend + frontend + electron + NSIS) |
| `build-cleanup.ps1` | Csak a cleanup EXE build-je (gyors, 1 mp) |
| `build-final.ps1` | Gyors újra-build (feltételezi hogy van már stage-elt PG/JRE) |
| `scripts/generate-secrets.ps1` | Cryptographically-strong titkos kulcs generáló |
| `scripts/init-db.bat` | PG init + seed |
| `scripts/start-services.bat` / `stop-services.bat` | Service management |
| `scripts/fix-backend-acl.ps1` | Post-install ACL hardening |
| `scripts/fix-running-instance.ps1` | Ha fut a backend/PG akkor gracefully leállítja |
| `tests/installer-validation-suite.ps1` | Build post-validation suite |

---

## 7. Verziózás

A build alapértelmezés szerint `2.1.0` verziót készít (a `CHANGELOG.md`-hoz igazítva —
ez a hivatalos program-verzió, korábban az installer 1.9.2-n rekedt míg a szoftver már
2.0.0 volt). Új verziót build-elni:

```powershell
powershell -ExecutionPolicy Bypass -File installer\build-installer.ps1 -Version 2.1.1
powershell -ExecutionPolicy Bypass -File installer\build-cleanup.ps1   -Version 2.1.1
```

A verzió beég az EXE-be (Windows Properties → Details → File/Product Version),
és a generated `.exe` neve is tartalmazza.
