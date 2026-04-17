---
title: "Valutaváltó Pénztár — First-Run Setup Wizard + Telepítő Implementáció Guide"
version: 2.1.1
last_updated: 2026-04-17
status: current
audience: AI coding agents, developers
tags: [installer, first-run-wizard, electron, nsis, architecture, implementation-guide]
related_docs:
  - docs/knowledge/memory/2026-04-17-installer-release-v2.1.0-session.qmd
  - docs/knowledge/memory/2026-04-17-hetzner-deploy-v2.1.1-session.qmd
  - installer/README.md
---

# 0. TL;DR egy AI ügynök számára

Ez a dokumentáció egy komplett leírás arról, **mi a Valuta Pénztár telepítőcsomag és First-Run Setup Wizard** — hogyan épül fel, hol vannak a fájlok, hogyan működik a runtime kapcsolat, és **mit kell tenned, ha módosítani akarod**.

**A projekt egyetlen mondatban:** Magyar valutaváltó ERP pénztár-kliens (Electron desktop app), amelyet `Penztar-Setup-<VER>-<YYYYMMDD>.exe` NSIS telepítő hoz létre, és első indításkor egy 4-lépéses varázsló (`SetupWizard.tsx`) végigvezet a konfiguráción, majd a gép magától újraindul és már normálisan használható.

**Jelenlegi architektúra (v2.1.1, "fat" bundle):** a telepítő 431 MB, mindent magával hoz: PostgreSQL 17.5, custom JRE, Spring Boot backend JAR, Electron Penztár kliens. Ez "gyári be" van állítva mint offline-képes, saját szerverrel rendelkező ügyfél gépre.

**Célállapot (v2.1.2 tervezett, "thin client"):** a telepítő ~150 MB, csak az Electron app + SQLite lokál cache. A backend közvetlenül a Hetzner produkciós szerverre (`https://excvaluta.com/api/v1`) csatlakozik. A wizard lépései ugyanazok.

**Ha változtatsz bármit a wizardon:**
- Backend oldal: `backend/src/main/java/hu/puzzleir/valuta/controller/{AuthController,PublicBranchController}.java`
- Electron main: `penztar-client/electron/first-run.ts`, `main.ts`, `preload.ts`
- Frontend: `frontend-react/src/pages/setup/SetupWizard.tsx`, `frontend-react/src/types/electron.d.ts`, `frontend-react/src/App.tsx` (`SetupGuard`)
- Installer: `installer/Penztar-Setup.nsi`, `installer/Penztar-Cleanup.nsi`, `installer/build-installer.ps1`

---

# 1. Projekt kontextus

## 1.1. Cél és környezet

**Use case:** Magyarországon 60+ valutaváltó iroda pénztárosai a v2.1.1 kliens Electron appjával dolgoznak. Minden nap 6-8 órán át fut, intenzív tranzakció-terheléssel (vétel, eladás, konverzió, sztornó, napzárás, MNB report). A pénztárosnak **nem szabad** semmit konfigurálnia — csak futtatnia kell az EXE-t, a wizard gondoskodik a többiről.

**Multi-tenant:** minden cég (pl. EBC = Exclusive Best Change Zrt.) saját irodákkal + saját kóddal. Jelenleg egyetlen aktív cégünk van (EBC, 2 aktív branch: KORUT, TISZA), de architektúrálisan többtenantos.

**Hungarian domain terms** (tartsd meg!):
- `vétel` = buy (FX from customer)
- `eladás` = sell (FX to customer)
- `konverzió` = conversion (FX-to-FX)
- `sztornó` = storno (reverse/cancel transaction)
- `napzárás` = daily closing
- `címletezés` = denomination tracking
- `árfolyam` = exchange rate

## 1.2. Tech stack

| Komponens | Technológia | Verzió |
|---|---|---|
| Backend | Java + Spring Boot | 21.0.10 + 3.5.13 |
| Persistence | Spring Data JPA + Flyway | 11.7.2 |
| DB (prod) | PostgreSQL | 16.13 Hetzner LUKS |
| DB (bundled) | PostgreSQL (EDB binaries) | 17.5 |
| Frontend (admin + wizard) | React + TypeScript + Vite | 19 + 5 |
| Styling | Tailwind CSS | 3 |
| State | Zustand | — |
| Desktop shell | Electron + electron-builder | 41.1.1 |
| Desktop DB (offline) | SQLite + better-sqlite3 | — |
| Installer | NSIS | 3.x |
| Build | Maven (backend), npm + Vite (frontend + desktop) | — |
| Service | NSSM (Windows service wrapper) | 2.24 |

## 1.3. Repo-szerkezet (wizard szempontjából releváns)

```
valutavalto-program/
├── backend/
│   ├── src/main/java/hu/puzzleir/valuta/
│   │   ├── controller/
│   │   │   ├── AuthController.java                    # /auth/bootstrap-admin, /auth/bootstrap-status
│   │   │   └── PublicBranchController.java            # /public/branches?companyCode=EBC
│   │   ├── dto/
│   │   │   ├── PublicBranchDto.java
│   │   │   └── auth/
│   │   │       ├── BootstrapAdminRequestDto.java
│   │   │       └── BootstrapAdminResponseDto.java
│   │   ├── service/AdminBootstrapService.java
│   │   └── config/SecurityConfig.java                 # permitAll rules
│   └── src/main/resources/db/migration/
│       ├── V143__nav_vat_rate_parameters.sql         # NAV ÁFA kulcsok seed
│       └── V144__admin_bootstrap_flag.sql            # auth.bootstrap-completed flag
│
├── frontend-react/
│   └── src/
│       ├── App.tsx                                     # SetupGuard wrapper
│       ├── pages/setup/SetupWizard.tsx                # 4-lépéses UI
│       ├── types/electron.d.ts                        # contextBridge tipusok
│       └── pages/auth/LoginPage.tsx                   # dinamikus version display
│
├── penztar-client/
│   ├── electron/
│   │   ├── first-run.ts                               # isFirstRun, getBranches, testConnection, saveSetupConfig, bootstrapAdmin, waitForBackend
│   │   ├── main.ts                                    # ipcMain.handle('setup:...')
│   │   └── preload.ts                                 # contextBridge setup* methods
│   └── package.json                                    # productName = "valuta-penztar"
│
├── installer/
│   ├── Penztar-Setup.nsi                              # NSIS full installer
│   ├── Penztar-Cleanup.nsi                            # Standalone uninstaller
│   ├── build-installer.ps1                            # ~10-30 perc full build
│   ├── build-cleanup.ps1                              # ~1 sec cleanup EXE
│   ├── build-final.ps1                                # gyors újrabuild
│   ├── scripts/                                        # init-db.bat, seed-data.sql, ...
│   └── README.md
│
└── docs/knowledge/
    ├── memory/*.qmd, *.yaml                            # session memóriák
    └── installer-wizard-implementation-guide.md       # EZ A FÁJL
```

---

# 2. Wizard architektúra

## 2.1. User flow (magas szintű)

```
+-------------------+       +-------------------+
| User futtatja     |       | Penztar-Setup-    |
| Penztar-Setup-    | -----> 2.1.1-*.exe        |
| 2.1.1-*.exe       |       | (NSIS wizard)     |
+-------------------+       +-------------------+
                                    |
                                    | FAZIS 1: cleanup (stop + remove old services)
                                    | FAZIS 2: install (stage bin+data+config)
                                    | FAZIS 3: start services (PG + backend)
                                    v
+-------------------+       +-------------------+
| Desktop shortcut  |       | Penztar.exe       |
| "Valutavalto      | <---- | Electron main     |
|  Penztar"         |       +-------------------+
+-------------------+                |
                                    | check: <userData>/.env exists?
                                    | SETUP_COMPLETED=1?
                                    | JWT_SECRET looks valid?
                                    v
                          +-------------------+
                          | isFirstRun=true   |
                          +-------------------+
                                    |
                                    | IPC: setup:check -> React-land
                                    v
                          +-------------------+
                          | SetupGuard        |
                          | navigate /setup   |
                          +-------------------+
                                    |
                                    v
         +----- SetupWizard.tsx (4 steps) -----+
         |  Step 1: Welcome                    |
         |  Step 2: Branch (2x8 grid)          |
         |  Step 3: Server URL + test / offline|
         |  Step 4: Admin password + summary   |
         |                                     |
         |  "Telepítés befejezése" gomb →      |
         |     setup:save IPC                  |
         +-------------------+-----------------+
                             |
                             | saveSetupConfig()
                             |   1. waitForBackend (health check)
                             |   2. bootstrapAdmin (POST /auth/bootstrap-admin)
                             |   3. generate secrets (JWT, SQLCIPHER, OFFLINE_LICENSE)
                             |   4. atomic .env write (<userData>/.env, 0o600)
                             |   5. app.relaunch() + app.exit(0)
                             v
                  +-------------------+
                  | Penztar.exe újra  |
                  | elindul, .env     |
                  | már tartalmazza a |
                  | SETUP_COMPLETED=1 |
                  | → isFirstRun=false|
                  | → normál login UI |
                  +-------------------+
```

## 2.2. First-run detekció

**Hely:** `penztar-client/electron/first-run.ts`, `isFirstRun()` export.

**Szabályok (bármelyik igaz → first run):**
1. `<userData>/.env` **nem létezik**
2. `.env` létezik, de `SETUP_COMPLETED !== "1"`
3. `JWT_SECRET` hiányzik, rövidebb 32 karakternél, vagy tartalmaz placeholder szöveget (`change-me`, `changeme`, `placeholder`, `your-secret`, `todo`, `replace-me`)

**`<userData>` path (Electron `app.getPath('userData')`):**
- Windows: `%APPDATA%\valuta-penztar\` (pl. `C:\Users\Kósa Zoltán\AppData\Roaming\valuta-penztar\`)
- macOS: `~/Library/Application Support/valuta-penztar/` (nem támogatott, csak Windows build van)
- Linux: `~/.config/valuta-penztar/` (sem támogatott)

Az app name-ét az `electron-builder.json` `productName` mezője vagy a `package.json` `name` mezője adja. **NE változtass itt**, mert akkor a régi `.env`-et nem találja meg a frissített build.

## 2.3. IPC csatornák (main ↔ renderer)

**Fájlok:** `penztar-client/electron/main.ts`, `penztar-client/electron/preload.ts`, `frontend-react/src/types/electron.d.ts`.

| IPC channel | Preload method | Argumentumok | Return | Cél |
|---|---|---|---|---|
| `setup:check` | `setupCheck()` | — | `SetupCheckResult` | First-run detekció |
| `setup:branches` | `setupGetBranches(apiUrl?, companyCode?)` | URL + cégkód | `Branch[]` | Iroda lista (backend vagy fallback) |
| `setup:test-connection` | `setupTestConnection(apiUrl, companyCode, username, password)` | credentials | `SetupConnectionTest` | POST /auth/login a szerverre |
| `setup:save` | `setupSave(payload)` | `SetupSavePayload` | `SetupSaveResult` | Mentés + relaunch |

**Stateless:** minden hívás független, nincs session, nincs persisted state a main process-ben. Ha a user bezárja a window-t a wizard közben, a következő indítás megint `/setup`-ra navigál (mert `.env` még nincs kiírva).

## 2.4. Lépések részletesen

### Step 1 — Üdvözlő

**UI komponens:** `SetupWizard.tsx` első szekció.
**Tartalom:** magyar nyelvű táblát, hogy mi fog történni 4 lépésben, mennyi ideig tart (~2 perc), mit kell a felhasználónak megadnia (fiók + szerver URL + admin jelszó).
**Gombok:** `Tovább` (disable nélkül).
**Backend hívás:** nincs.

### Step 2 — Iroda választás

**UI:** 2×8 = 16 cella/oldal, lapozható, keresőmezővel (code vagy name vagy city substring match). Minden cella: kód, név, város, cím (ha van).

**Data source (sorrendben):**
1. **Backend** (`GET /api/v1/public/branches?companyCode=EBC`) — ha a user már beállította az URL-t + cégkódot (step 3-ban)
2. **DEFAULT_BRANCHES static fallback** (60 iroda, a `first-run.ts`-ben hardcode) — ha backend nincs vagy üres válasz

**Implementáció:**
```ts
// penztar-client/electron/first-run.ts
export async function getBranches(apiUrl?: string, companyCode?: string): Promise<Branch[]> {
  if (!apiUrl || !companyCode) return DEFAULT_BRANCHES.map(b => ({ ...b }));
  try {
    const fetched = await fetchBranchesFromBackend(apiUrl, companyCode);
    return (fetched && fetched.length > 0) ? fetched : DEFAULT_BRANCHES.map(b => ({ ...b }));
  } catch {
    return DEFAULT_BRANCHES.map(b => ({ ...b }));
  }
}
```

**Backend call:** `httpJson(base + '/public/branches?companyCode=' + code, {method:'GET'})`. Timeout 6 sec. `null` return = fallback.

**Gombok:** `Vissza`, `Tovább` (disabled, amíg egy cellát ki nem választ).

### Step 3 — Szerver

**UI mezők:**
- **Szerver URL** — text input, default **`https://excvaluta.com/api/v1`** (Hetzner prod; a 2.1.1 fix: korábban `https://api.excvaluta.com/api/v1` volt, de az nem létezik DNS-ben)
- **Cégkód** — text input, default `EBC`
- **Bootstrap felhasználó** — text input (opcionális teszt-felhasználó — ha megadott, a "Kapcsolat tesztelése" gombbal próbál bejelentkezni)
- **Bootstrap jelszó** — password input
- **Kapcsolat tesztelése** — gomb → `setup:test-connection` IPC
- **Offline mód** — checkbox: ha bejelölve, a szerver URL-t üresre lehet hagyni, és a wizard nem ellenőrzi

**Teszt eredmény UI:**
- Zöld pipa, latency ms (pl. "Sikeres kapcsolat, 342 ms")
- Piros X, hibakód (pl. "Időtúllépés", "HTTP 500", "Hálózati hiba")

**Fontos:** a teszt `POST /auth/login`-t hív, és **minden 2xx ÉS 4xx válasz sikeres kapcsolatnak számít** — csak a network error vagy 5xx kudarc. Így a user rossz jelszóval is továbbléphet (401 = a szerver él, csak a cred hibás).

**Gombok:** `Vissza`, `Tovább` (enabled offline módban VAGY ha URL kitöltve).

### Step 4 — Admin jelszó

**UI mezők:**
- **Admin felhasználói kód** — text input, default `ADMIN`
- **Új admin jelszó** — password input, min 8 karakter
- **Jelszó megerősítése** — password input, live validáció
- **Összefoglaló** — összes beadott érték read-only kijelzése

**Gombok:** `Vissza`, `Telepítés befejezése` (disabled, amíg jelszó < 8 char vagy nem egyezik a megerősítés).

**On-click handler (`handleFinish`):**

```ts
const payload: SetupSavePayload = {
  branchCode, branchName,
  apiUrl, companyCode,
  adminUsername, adminPassword,
  bootstrapUsername, bootstrapPassword,
  offlineMode,
};
const result = await window.electronAPI.setupSave(payload);
if (!result.success) showError(result.errorMessage);
// Sikerre: app.relaunch() miatt az ablak azonnal bezáródik
```

## 2.5. `saveSetupConfig` részletesen

**Hely:** `penztar-client/electron/first-run.ts`, `saveSetupConfig()` export.

**Pszeudo-kód (valódi implementáció 118 sor):**

```ts
export async function saveSetupConfig(payload: SetupSavePayload): Promise<SetupSaveResult> {
  // 1. VALIDÁCIÓ
  if (!payload.branchCode || !payload.branchName) return err('Hiányzó iroda.');
  if (!payload.offlineMode) {
    if (!/^https?:\/\//i.test(payload.apiUrl)) return err('Érvénytelen URL.');
    if (!payload.companyCode) return err('Hiányzó cégkód.');
  }
  if (!payload.adminPassword || payload.adminPassword.length < 8)
    return err('Min 8 karakter.');
  if (!payload.adminUsername?.trim()) return err('Hiányzó admin user.');

  // 2. API URL RESOLVE (offline módban default localhost:8080)
  const apiUrl = payload.offlineMode
    ? (payload.apiUrl || 'http://localhost:8080/api/v1')
    : payload.apiUrl;

  // 3. BACKEND HEALTH CHECK (max 45 sec polling, 1500 ms interval)
  const health = await waitForBackend(apiUrl, 45000, 1500);
  if (!health.healthy) return err(`Backend nem elérhető: ${health.lastError}`);

  // 4. BACKEND BOOTSTRAP-ADMIN HÍVÁS (a user jelszó beírása a DB-be)
  const bootstrap = await bootstrapAdmin(apiUrl, {
    companyCode: normalizedCompanyCode,
    workerCode: adminUsername.toUpperCase(),
    workerName: adminUsername,
    newPassword: adminPassword,
  });
  if (!bootstrap.success) return err(`Admin setup fail: ${bootstrap.errorMessage}`);
  // (bootstrap.alreadyDone === true esetén idempotens no-op, folytatjuk)

  // 5. SECRET GENERÁLÁS (3x 256-bit)
  const jwtSecret = crypto.randomBytes(32).toString('hex');
  const sqlCipherKey = crypto.randomBytes(32).toString('hex');
  const offlineLicenseSecret = crypto.randomBytes(32).toString('hex');

  // 6. .env ÍRÁS (atomikus: .tmp → rename, mode 0o600)
  const content = buildEnvFileContent({...});
  fs.writeFileSync(envPath + '.tmp', content, { encoding: 'utf8', mode: 0o600 });
  fs.renameSync(envPath + '.tmp', envPath);

  // 7. RELAUNCH (500ms delay az UI animation-hez)
  setTimeout(() => { app.relaunch(); app.exit(0); }, 500);
  return { success: true, envPath };
}
```

**Miért atomikus a .env írás?**
- A fájlrendszer bármikor kidolgozhat rossz permissioni. Ha `write` közben crash van és félig lemezen csak `.env.tmp` van, akkor a `renameSync` nem fut le, és a `.env` **nem íródik át** — az előző állapot megmarad (vagy first-run marad).
- 0o600 = user-read-write only, más user-ek (pl. AV szoftver worker) nem olvashatják a titkokat.

## 2.6. `.env` kimeneti formátum

**Minta `.env` (auto-generált, v2.1.1):**

```bash
# Valuta Pénztár — auto-generálva a First-Run Setup Wizard által (2026-04-17T18:45:21.337Z).
# Kézzel NE szerkeszd, csak a wizard futtatásával.

VITE_API_URL="https://excvaluta.com/api/v1"
VITE_BRANCH_CODE="KORUT"
VITE_BRANCH_NAME="Korut"
VITE_COMPANY_CODE="EBC"

PENZTAR_BOOTSTRAP_COMPANY_CODE="EBC"
PENZTAR_BOOTSTRAP_WORKER_CODE="TESZT1"
PENZTAR_BOOTSTRAP_PASSWORD=""
PENZTAR_BOOTSTRAP_ROLE_CODE=CASHIER

# Kriptográfiai titkok — a wizard generálta, minden telepítésen egyedi.
JWT_SECRET="7f3e9a...64-hex-char..."
SQLCIPHER_KEY="3d8c1b...64-hex-char..."
OFFLINE_LICENSE_SECRET="a2e7f4...64-hex-char..."

SETUP_COMPLETED=1
SETUP_COMPLETED_AT="2026-04-17T18:45:21.337Z"
SETUP_OFFLINE_MODE=0
```

**Változók, amelyek a futás alatt használódnak:**
- `VITE_API_URL` — a frontend Axios client ezt olvassa build-timeban (static injection)
- `VITE_BRANCH_CODE`, `VITE_BRANCH_NAME`, `VITE_COMPANY_CODE` — frontend context (pl. current branch display)
- `JWT_SECRET` — backend + Electron side-channel (pl. offline token signing)
- `SQLCIPHER_KEY` — lokál SQLite encryption
- `OFFLINE_LICENSE_SECRET` — offline license validation
- `SETUP_COMPLETED` — first-run flag, ha 0 vagy hiányzik, wizard újra indul
- `SETUP_OFFLINE_MODE` — fut-e sync engine (0 = online, push/pull aktív; 1 = offline, csak lokál)

---

# 3. Backend vég (public endpoints)

## 3.1. Spring Security config

**Hely:** `backend/src/main/java/hu/puzzleir/valuta/config/SecurityConfig.java`.

**`permitAll` szabályok (v2.1.1):**

```java
.requestMatchers("/api/v1/auth/login", "/api/v1/auth/refresh").permitAll()
.requestMatchers("/api/v1/auth/bootstrap-admin").permitAll()
.requestMatchers("/api/v1/auth/bootstrap-status").permitAll()
.requestMatchers("/api/v1/public/**").permitAll()
```

**FONTOS:** az `/actuator/health` és `/actuator/info` **nem** `permitAll` (Spring Boot management port 8081-en lehetne, de nincs szeparálva — jelenleg ugyanazon a 8080-on). Ezért Cloudflare-en át `/actuator/health` 401-et ad — ez **szándékolt** biztonsági viselkedés, nem bug.

## 3.2. PublicBranchController

**Endpoint:** `GET /api/v1/public/branches?companyCode={code}`

**Request:**
```
GET /api/v1/public/branches?companyCode=EBC HTTP/1.1
Host: excvaluta.com
```

**Response 200:**
```json
[
  {"code":"KORUT","name":"Korut","city":"Szeged","address":"Korut 22, Szeged"},
  {"code":"TISZA","name":"Tisza Sarok","city":"Szeged","address":"Tisza Sarok, Szeged"}
]
```

**Response 200, üres tömb:** ha a cégkód hibás vagy nincs aktív branch — a wizard ilyenkor a DEFAULT_BRANCHES-re esik vissza.

**DB query:**
```sql
SELECT b.code, b.name, b.city, b.address
FROM branch b
JOIN company c ON b.company_id = c.id
WHERE c.code = ? AND b.active = true AND c.active = true
ORDER BY b.name;
```

**Multi-tenant guardrail:** a controller kötelezően kiszűri `companyCode`-dal, nincs "show all" opció. Sosem adunk vissza más cég branchjét egy hibás cégkóddal.

## 3.3. AuthController bootstrap endpoints

### 3.3.1. GET /auth/bootstrap-status

**Request:** nincs argumentum.

**Response:**
```json
{"completed": false}
```
vagy
```json
{"completed": true}
```

**DB read:** `system_parameter` tábla, `parameter_key = 'auth.bootstrap-completed'`, `parameter_value` → parse boolean.

### 3.3.2. POST /auth/bootstrap-admin

**Request:**
```json
{
  "companyCode": "EBC",
  "workerCode": "ADMIN",
  "workerName": "Adminisztrator",
  "email": "admin@excvaluta.com",
  "newPassword": "valami-jo-hosszu-jelszo"
}
```

**Response 200:**
```json
{
  "success": true,
  "message": "Admin felhasználó beállítva."
}
```

**Response 400 (idempotens no-op):**
```json
{
  "success": false,
  "message": "Az admin bootstrap már lezajlott ezen a rendszeren."
}
```
(A wizard ezt NEM hibának tekinti — a `bootstrapAdmin()` TS funkció `alreadyDone: true`-val tér vissza.)

**Service logic:** `AdminBootstrapService.java`:
1. Ellenőrzi `system_parameter.auth.bootstrap-completed` flaget → ha `true`, `IllegalStateException` (400)
2. Megkeresi a cégkódot → ha nincs, 404
3. Megkeresi az admin workert a cég alatt `workerCode`-dal → ha nincs, létrehozza; ha van, csak `password_hash` frissítés
4. `password_hash = BCryptPasswordEncoder.encode(newPassword)`
5. `system_parameter.auth.bootstrap-completed = true` + audit log
6. Response success

## 3.4. Flyway seed migrációk

**V143 (`nav_vat_rate_parameters.sql`):** 4 sor `system_parameter`-be:
- `nav.vat-rate.STANDARD = 0.27` (általános 27% ÁFA)
- `nav.vat-rate.REDUCED_18 = 0.18`
- `nav.vat-rate.REDUCED_5 = 0.05`
- `nav.vat-rate.ZERO = 0.00`

Forrás: `NavClosingService` ezeket olvassa napzáráskor, a hardcoded `0.27` konstans helyett.

**V144 (`admin_bootstrap_flag.sql`):** 1 sor:
- `auth.bootstrap-completed = false` (kezdeti állapot, BOOLEAN típus)

**FONTOS:** mindkettőbe **explicit `gen_random_uuid()`** kell az `id` oszlopra, mert a `system_parameter.id` UUID NOT NULL **default nélkül**. Ez a 2026-04-17-es session egyik javítása volt (`47acfab6`).

---

# 4. NSIS telepítő

## 4.1. Telepítő szerepe

A NSIS telepítő **nem azonos** a First-Run Setup Wizarddal. Különböző felelősségi köreik vannak:

| Szempont | NSIS telepítő | Setup Wizard |
|---|---|---|
| Cél | bináris telepítés gépre | felhasználói konfiguráció |
| Mikor fut | a user duplán kattintva az `.exe`-re | első Penztár indításkor |
| Mit ír | `C:\Program Files\...`, `C:\ProgramData\...`, Windows service-ek | `%APPDATA%\valuta-penztar\.env` |
| Admin jog | igen, UAC-val | nem, user jog elég |
| Nyelv | NSIS script (`.nsi`) | React TypeScript (`.tsx`) |
| Verzió | v2.1.1 | v2.1.1 (coupled) |

## 4.2. 3 fázis (Penztar-Setup.nsi)

### FAZIS 1 — Cleanup (előző telepítés eltávolítása)

1. NSSM-en keresztül stop `BestChange-Backend` + `BestChange-PostgreSQL` service-ek
2. `pg_ctl stop -D "C:\ProgramData\BestChange\pgsql\data" -m fast` (postgres graceful)
3. KILL minden `postgres.exe`, `java.exe` process, ami a mi mappáinkból fut
4. LockedList plugin: WAIT, amíg a `C:\Program Files\Valutavalto Penztar\*` fájlok nincsenek lockolva
5. REMOVE services NSSM-mel
6. `RMDir /r /REBOOTOK "C:\Program Files\Valutavalto Penztar"` + `...\BestChange`
7. Desktop shortcut törlése

### FAZIS 2 — Install (staging → produkció)

1. `SetOutPath` + `File /r` rekurzívan másol a stage mappából:
   - `C:\Program Files\Valutavalto Penztar\` ← Electron app (Penztar.exe + resources + node_modules)
   - `C:\ProgramData\BestChange\pgsql\` ← PostgreSQL 17.5 binaries
   - `C:\ProgramData\BestChange\jre\` ← custom JRE
   - `C:\ProgramData\BestChange\backend\valuta-backend.jar`
   - `C:\ProgramData\BestChange\tools\nssm.exe`
   - `C:\ProgramData\BestChange\config\application-local.properties` (template)
   - `C:\ProgramData\BestChange\scripts\*.bat`, `*.sql`, `*.ps1`
2. `powershell -File generate-secrets.ps1` — feltölti az `__PG_PASSWORD__` + `__JWT_SECRET__` placeholder-eket a config fájlokban (NSIS oldali generation, NEM egyezik meg a wizard oldali secrets-sel, azok later wizard-ban generálódnak)
3. `init-db.bat` futtatás:
   - `pg_ctl initdb` a data dirre
   - `pg_ctl start`
   - `psql`: `CREATE USER valuta WITH PASSWORD '<generated>'`
   - `psql`: `CREATE DATABASE valuta OWNER valuta`
   - `seed-data.sql` futtatás (default companies + default branches seed, csak ha üres a DB)

### FAZIS 3 — Windows service regisztráció (NSSM)

1. `nssm install BestChange-PostgreSQL "C:\ProgramData\BestChange\pgsql\bin\pg_ctl.exe"` + args
2. `nssm install BestChange-Backend "C:\ProgramData\BestChange\jre\bin\java.exe"` + `-jar ...\backend\valuta-backend.jar`
3. `nssm set BestChange-Backend DependOnService BestChange-PostgreSQL` (start order)
4. `nssm start BestChange-PostgreSQL`; `nssm start BestChange-Backend`
5. Windows tűzfal: csak `127.0.0.1:8080` + `127.0.0.1:54320` (PG port 54320-on fut a gépen, hogy ne ütközzön más PG-vel)

**Result:** Windows service-ek futnak, `http://127.0.0.1:8080/actuator/health` 200-zal válaszol. Desktop shortcut létrejön: `Valutavalto Penztar.lnk` → `C:\Program Files\Valutavalto Penztar\Penztar.exe`.

## 4.3. Telepítő tartalom (2.1.1 fat bundle)

| Komponens | Méret | Forrás |
|---|---|---|
| PostgreSQL 17.5 binaries | ~200 MB | EDB download, SHA-256 verified |
| Custom JRE (jlink, 19 modul) | ~50 MB | local JDK 21 + `jlink --module-path` |
| Backend Spring Boot JAR | ~90 MB | Maven `mvn package -DskipTests` |
| Electron Penztár client | ~85 MB | electron-builder `--win dir` |
| NSSM 2.24 | 0.5 MB | SHA-256 verified |
| VC++ 2015-2022 x64 Redist | 13 MB | SHA-256 verified |
| Config templates + scripts | <1 MB | repo `installer/scripts/` |
| **Total input** | **1.38 GB** | — |
| **NSIS LZMA output** | **431 MB** | compression ratio 32.7% |

## 4.4. Build pipeline

**Main entry:** `installer/build-installer.ps1`, ~340 sor PowerShell.

**Fázisok:**
1. **Preflight check** — Java 21, Node 24, NSIS 3.x, makensis.exe location
2. **Download phase** (skip-pelhető `-SkipDownloads` flag-gel):
   - `installer/build/downloads/postgresql-binaries.zip` (EDB)
   - `installer/build/downloads/nssm.zip`
   - `installer/build/downloads/vc_redist.x64.exe`
   - SHA-256 check mindegyikre (ha mismatch → throw)
3. **Extract + stage** — `installer/build/stage/{pgsql,jre,tools,backend,electron,config,scripts}/`
4. **Backend build** — `cd backend && mvn -q package -DskipTests` → `target/valuta-backend-<VER>.jar`
5. **JRE build** — `jlink` 19 moduleal → `installer/build/stage/jre/` (skip-pelhető ha cache)
6. **Frontend+Electron build** — `cd frontend-react && npm run build`, then `cd penztar-client && npm run build && electron-builder --win dir`
7. **Config template processing** — placeholderek, scripts másolása
8. **NSIS compile** — `makensis /DVERSION=<VER> /DBUILD_DATE=<YYYYMMDD> /DSTAGE_DIR=... Penztar-Setup.nsi`
9. **Output** — `installer/build/Penztar-Setup-<VER>-<YYYYMMDD>.exe`

**Cleanup build:** `installer/build-cleanup.ps1` csak a 6. és 8. fázist futtatja (a standalone `Penztar-Cleanup.nsi` scriptet fordítja), ~1 sec.

## 4.5. Encoding szabály (NSIS)

A `.nsi` fájlok **nem tartalmazhatnak UTF-8 ékezeteket**, mert a NSIS 3.x Windows-on ACP (Windows-1252) kódlappal olvassa őket. Szabályok:

| Karakter | Helyes NSIS forrás |
|---|---|
| `á é í ó ú` → `a e i o u` |
| `ö ő` → `o` |
| `ü ű` → `u` |
| `—` (em-dash) → `-` |
| `…` (ellipsis) → `...` |
| `„ "` → `"` |
| `©` (U+00A9) | **marad** (valid Windows-1252 byte 0xA9) |

**Teszt:** build után a `Penztar-Setup-<VER>.exe` Properties → Details → FileDescription **nem** tartalmazhat `�` karaktert.

---

# 5. Jelenlegi állapot (v2.1.1)

## 5.1. Ami működik

- ✅ NSIS installer 2.1.1 létrehozható (build pipeline zöld)
- ✅ Telepítő cleanup helyesen eltávolítja az előző telepítést
- ✅ Windows service-ek NSSM-en át elindulnak
- ✅ Bundled PostgreSQL inicializálódik (init-db.bat)
- ✅ Bundled backend feláll a helyi PG-vel
- ✅ Electron app indul, First-Run Setup Wizard megjelenik
- ✅ Wizard 4 lépés végig
- ✅ Branch lista backend-ről (ha online mód) — 2026-04-17-es session után
- ✅ Admin jelszó a backend-be íródik (bootstrap-admin) — 2026-04-17-es session után
- ✅ `.env` atomikusan kiíródik 0o600 perm-mel
- ✅ Electron relaunch → normál login UI → sikeres belépés a wizardban beadott jelszóval
- ✅ **Hetzner prod backend** él, v2.1.1, `/public/branches` valós adatot ad
- ✅ Verzió unifikáció — minden modul 2.1.1-en

## 5.2. Ami NEM működik / gyenge

- ⚠️ **Google OAuth login** — local bundled backend-ben `google.client.id=none`, ezért Internal Server Error. Offline módban a Google login gombot el kell rejteni, vagy be kell tölteni a Google kliens ID-t a telepítőből (jelenleg user supply szükséges).
- ⚠️ **Telepítő méret 431 MB** — user panasz; v2.1.2 thin client átalakítás tervezve (r3–r7 task).
- ⚠️ **Systemd JAR hardcode Hetzneren** — a unit `1.0.0-SNAPSHOT` path-ra mutat. Deploy-nál minden rebuild után cp kell. Symlink refactor ajánlott.
- ⚠️ **GitHub Actions deploy workflow hiányzik** — a 2026-04-17 session direktben SSH-zott. Lásd QMD session memória.
- ⚠️ **LUKS unit idempotency fix** csak a szerveren, **nem a repo-ban**. `deploy/hetzner/systemd/` path létrehozás ajánlott.

## 5.3. Known bug backlog

| ID | Leírás | Érintett fájl | Severity |
|---|---|---|---|
| CB-016 | VAT_RATE tax_code mapping — napzáráskor minden tax kategóriát 27%-kal számol | `backend/service/NavClosingService.java` | medium |
| — | Google OAuth local fallback hiánya | `backend/config/OAuth2Config.java` | medium (only online mode) |
| — | `electron-builder.json` UAC config ellenőrzés | `penztar-client/electron-builder.json` | low |

---

# 6. Célállapot roadmap (v2.1.2 thin client)

## 6.1. Célok

- Telepítő méret: **431 MB → ~150 MB** (PG + bundled backend kivonás)
- Telepítési idő: **~3 perc → ~30 sec** (főleg PG initdb elmarad)
- `VITE_API_URL` default **build-timeban** `https://excvaluta.com/api/v1`-re hardcode (wizard felülírható)
- SyncEngine: periodikus push a Hetznerre lokális SQLite queue-ból, exchange rate pull 5 perces pollinggal
- Offline képesség: megmarad — SQLite lokál cache, amikor a hálózat kiesik, a cashier tud folytatni (eventually consistent sync)

## 6.2. Feladatok (user priority lista)

### r3 — Thin client installer átírás

**Érintett fájlok:**
- `installer/Penztar-Setup.nsi` — kivenni FAZIS 2 PG + backend másolás blokkokat
- `installer/build-installer.ps1` — kihagyni PG download, JRE build, backend Maven build
- `installer/scripts/init-db.bat` — törölni
- `installer/scripts/seed-data.sql` — törölni (backend csinálja)

**Eredmény:** a telepítő csak az Electron appot rakja fel, plusz SQLite DB default cache helyét (`%APPDATA%\valuta-penztar\cache\`).

### r4 — Build-time API URL

**Érintett fájlok:**
- `penztar-client/vite.config.ts` vagy `penztar-client/package.json` — `VITE_API_URL` build-time
- `penztar-client/.env.production` — új fájl, `VITE_API_URL=https://excvaluta.com/api/v1`
- `frontend-react/src/pages/setup/SetupWizard.tsx` — default érték `import.meta.env.VITE_API_URL ?? 'https://excvaluta.com/api/v1'`

### r5 — SyncEngine

**Érintett fájlok:**
- `penztar-client/electron/sync-engine.ts` — már létezik, de csak váz → teljes push/pull loop
- `backend/controller/SyncController.java` — új endpoint `/api/v1/sync/push` + `/api/v1/sync/pull/exchange-rates`
- `backend/service/SyncService.java` — új service, outbox/inbox pattern
- `penztar-client/electron/sqlite-outbox.ts` — új, lokál SQLite queue

**Protokoll:**
- Push: 5 perces interval, `POST /api/v1/sync/push` body: `{transactions: [...], idempotencyKeys: [...]}`
- Pull: 5 perces interval, `GET /api/v1/sync/pull/exchange-rates?lastFetched=<timestamp>`
- Conflict resolution: server wins (last-write-wins mellé audit log)

### r6 — Méret csökkentés

**Targeted reductions:**
- Electron runtime: `electron-builder --asar` + `compression: "maximum"`
- Unused npm deps tree shake
- Azonos méret max: **~150 MB**

### r7 — v2.1.2 release

**Pre-req:** r3 + r4 + r5 + r6 kész.
**Lépések:**
1. CHANGELOG.md új bejegyzés `## [2.1.2] - YYYY-MM-DD`
2. Verzió bump mindenhol (lásd `docs/knowledge/memory/2026-04-17-installer-release-v2.1.0-session.qmd` version-bump protokoll)
3. `installer/build-installer.ps1 -SkipDownloads` + `build-cleanup.ps1`
4. Copy EXE Downloads-ba
5. Git commit + tag + push
6. Hetzner deploy (lásd r1 playbook a v2.1.1 session QMD-ben)

---

# 7. Build + futtatás (szívességből AI ügynököknek)

## 7.1. Lokal fejlesztés

```bash
# Backend (Windows, CMD)
cd backend
.\mvnw.cmd spring-boot:run

# Frontend (admin dashboard)
cd frontend-react
npm install
npm run dev
# http://localhost:5173

# Pénztár Electron kliens (dev mode)
cd penztar-client
npm install
npm run dev
# Electron window + hot reload
```

## 7.2. Installer build

```powershell
# Full build ~10-30 perc (első alkalom), ~8 perc cache-ből
cd d:\repo\valutavalto-program
powershell -ExecutionPolicy Bypass -File installer\build-installer.ps1 -SkipDownloads

# Output:
# installer\build\Penztar-Setup-2.1.1-20260417.exe

# Standalone cleanup EXE (~1 sec)
powershell -ExecutionPolicy Bypass -File installer\build-cleanup.ps1

# Output:
# installer\build\Penztar-Eltavolito-2.1.1-20260417.exe

# Copy to Downloads
Copy-Item installer\build\Penztar-*.exe -Destination $env:USERPROFILE\Downloads
```

## 7.3. Hetzner deploy (a session utáni stabil playbook)

```powershell
# SSH key az ~\.ssh\hetzner_ed25519 alatt
$key = "$env:USERPROFILE\.ssh\hetzner_ed25519"
$server = "root@95.216.191.162"

# 1. Pull + build
ssh -i $key $server 'cd /opt/valutavalto && git fetch origin main && git reset --hard origin/main && chown -R valuta:valuta /opt/valutavalto && cd backend && /usr/bin/mvn -q -DskipTests package'

# 2. Deploy: rename új JAR-t a systemd-path-ra
ssh -i $key $server 'cp /opt/valutavalto/backend/target/valuta-backend-*.jar /opt/valutavalto/backend/target/valuta-backend-1.0.0-SNAPSHOT.jar && chown valuta:valuta /opt/valutavalto/backend/target/valuta-backend-*.jar'

# 3. Restart + wait
ssh -i $key $server 'systemctl restart valuta-backend && for i in 1..15; do sleep 3; if ss -tlnp | grep -q ":8080"; then echo "UP"; break; fi; done'

# 4. Smoke test
Invoke-WebRequest "https://excvaluta.com/api/v1/auth/bootstrap-status" -UseBasicParsing
# Expected: {"completed": true|false}
```

## 7.4. Tesztelés

```bash
# Backend tesztek
cd backend
.\mvnw.cmd test
# ~957 test, cumulative session

# Frontend tesztek
cd frontend-react
npm test
# ~505 test

# Penztar client tesztek
cd penztar-client
npm test
# ~97 test

# IPC cross-check
cd penztar-client
npm run check:ipc
# expected: "68 invoke <-> 72 handle, 0 missing"
```

---

# 8. Változás-történelem (ebben a doksiban rögzített session-ök)

| Dátum | Session | Fő eredmény |
|---|---|---|
| 2026-04-17 | First-Run Setup Wizard implementáció | `87b9a56a` — 4 lépéses UI, atomic .env, secrets |
| 2026-04-17 | v2.1.0 release + installer unifikáció | `ba425304` — all modules 2.1.0, Git tag v2.1.0 |
| 2026-04-17 | v2.1.1 bugfix (Hetzner URL + dynamic branches + admin bootstrap) | `70c42b55` — `api.excvaluta.com` → `excvaluta.com`, bootstrap endpoint |
| 2026-04-17 | Hetzner direct SSH deploy + LUKS patch + Flyway fix | `47acfab6` — V143+V144 UUID fix, PG resurrection |

---

# 9. Fájl-hivatkozások gyors-kereső

Ha fejleszteni akarsz, itt találod:

**Wizard UI:**
- `frontend-react/src/pages/setup/SetupWizard.tsx` (754 sor)
- `frontend-react/src/App.tsx` — `SetupGuard` wrapper

**Wizard main-process logika:**
- `penztar-client/electron/first-run.ts` (718 sor) — ALL core functions
- `penztar-client/electron/main.ts` — IPC handlers
- `penztar-client/electron/preload.ts` — contextBridge

**TypeScript tipusok:**
- `frontend-react/src/types/electron.d.ts`

**Backend:**
- `backend/src/main/java/hu/puzzleir/valuta/controller/AuthController.java`
- `backend/src/main/java/hu/puzzleir/valuta/controller/PublicBranchController.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/AdminBootstrapService.java`
- `backend/src/main/java/hu/puzzleir/valuta/dto/PublicBranchDto.java`
- `backend/src/main/java/hu/puzzleir/valuta/dto/auth/BootstrapAdmin{Request,Response}Dto.java`
- `backend/src/main/java/hu/puzzleir/valuta/config/SecurityConfig.java`

**Flyway:**
- `backend/src/main/resources/db/migration/V143__nav_vat_rate_parameters.sql`
- `backend/src/main/resources/db/migration/V144__admin_bootstrap_flag.sql`

**Installer:**
- `installer/Penztar-Setup.nsi` (~1040 sor)
- `installer/Penztar-Cleanup.nsi` (~130 sor)
- `installer/build-installer.ps1` (~340 sor)
- `installer/build-cleanup.ps1` (~45 sor)
- `installer/build-final.ps1`
- `installer/scripts/init-db.bat`
- `installer/scripts/seed-data.sql`
- `installer/scripts/start-services.bat`
- `installer/scripts/stop-services.bat`
- `installer/scripts/generate-secrets.ps1`
- `installer/scripts/fix-backend-acl.ps1`
- `installer/scripts/fix-running-instance.ps1`
- `installer/README.md`

**Session memóriák:**
- `docs/knowledge/memory/2026-04-17-installer-release-v2.1.0-session.{qmd,yaml}`
- `docs/knowledge/memory/2026-04-17-hetzner-deploy-v2.1.1-session.{qmd,yaml}`

**Infra (NEM a repo-ban, csak Hetzneren):**
- `/etc/systemd/system/valuta-backend.service`
- `/etc/systemd/system/pgdata-luks.service` (**idempotens patch elhelyezve 2026-04-17**)
- `/etc/systemd/system/postgresql@16-main.service.d/luks-dependency.conf`
- `/opt/valutavalto/backend/.env` (production secrets, redacted)
- `/opt/pgdata-encrypted.img` (2 GB LUKS image)
- `/root/.pgdata-luks-key` (90 byte, 0600)

---

# 10. Összefoglaló AI ügynöknek

**1 perc alatt megérteni a projektet:**
- Magyar valutaváltó desktop app (Electron) + Spring Boot backend.
- Telepítő 431 MB "fat bundle" v2.1.1, Első indításkor 4-lépéses wizard konfigurál.
- Wizard → `.env` → `app.relaunch()` → normál login.
- Hetzner `95.216.191.162` szerveren prod backend + local PostgreSQL 16 LUKS-titkosítva.

**Legrögtönebb teendő bármely változtatáson:**
1. `npm test` + `./mvnw test` futtatás — zöld?
2. Backend Flyway: ha új migráció `system_parameter`-be ír → `gen_random_uuid()` kötelező!
3. NSIS: ha ékezet kell → ASCII-ra cserélni (csak `©` marad)
4. Wizard: `SetupSavePayload` breaking change → `first-run.ts` + `SetupWizard.tsx` + `electron.d.ts` 3 helyen szinkron
5. Hetzner deploy: SSH-val direkt (lásd 7.3.)

**Legkockázatosabb területek:**
- `penztar-client/electron/first-run.ts` — 718 sor, 4 IPC handler, crypto, net.request — itt TDD kötelező
- `installer/Penztar-Setup.nsi` — 1040 sor, FAZIS 1-2-3 state machine, Windows service lifecycle — idempotency kritikus
- `backend/config/SecurityConfig.java` — `permitAll` szabályok → ha elrontod, admin login nem működik vagy public endpoint védett lesz

**Következő session javasolt első lépései:**
1. Commit a Hetzner systemd unitokat repo-ba (`deploy/hetzner/systemd/`)
2. `.github/workflows/deploy-hetzner.yml` létrehozás
3. Azután user r3 task: thin client installer átírás

— dokumentum vége —
