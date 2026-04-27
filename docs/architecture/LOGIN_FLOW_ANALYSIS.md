# Bejelentkezési Flow Mély Analízis — 2026-04-21

## Probléma tömören

A telepítő felhozza a dolgozói törzsadatbázist (worker lista egy branch-re),
de a végén **nem használja fel** a választott dolgozót a login folyamatban.
A telepítő végén a `hardcoded admin + admin jelszó` működik csak — a
telepítőben beállított jelszó **nem megy tovább** a telepített programba.

## Jelenlegi architektúra

### 1. Telepítő wizard — frontend-react/src/pages/setup/SetupWizard.tsx

**5 lépés:**
1. Welcome (üdvözlés)
2. Iroda választás (`GET /api/v1/public/branches?companyCode=EBC`)
3. Program típus (penztar / ertektar)
4. **Szerver lépés**
   - `bootstrapUsername` + `bootstrapPassword` — teszt credentials
   - Worker dropdown **létezik**, de csak **kapcsolat tesztelésre**
   - Ha a user-nek van listája, kiválaszthatja, DE az csak a
     `bootstrapUsername` state-et állítja be (teszt célra)
5. **Admin lépés**
   - `adminUsername` (default: `"admin"`)
   - `adminPassword` (min 8 karakter)
   - `POST /api/v1/auth/bootstrap-admin` — **ÚJ admin worker létrehozás**
   - FONTOS: ez egy KÜLÖN worker, nem a 4. lépésben kiválasztott dolgozó!

### 2. Electron config store — penztar-client/electron/sqlite.ts

**Tárolt kulcsok a `saveSetupConfig()` végén:**
- `server_url` — backend URL
- `branch_code` — kiválasztott iroda (pl. KORUT)
- `bootstrap_company_code` — EBC
- `bootstrap_worker_code` — a **teszt** workerCode (bootstrapUsername, pl. BORSI)
- `app_mode` — penztar vagy ertektar

**HIÁNYZIK:**
- `worker_code` (a ténylegesen bejelentkező dolgozó)
- `worker_name` (megjelenítésre)
- `worker_role` (role-based UI-hoz)
- `admin_worker_code` (vagy szemantikailag tisztább név)

### 3. Backend auth endpoint-ok

**Meglevő:**
- `POST /auth/login` — sima jelszó-login
- `GET /auth/bootstrap-status` — `{ completed: true/false }`
- `POST /auth/bootstrap-admin` — új admin worker ÚJ jelszóval
  - Input: `{ companyCode, workerCode, workerName, newPassword }`
  - Effect: worker + password_hash (BCrypt) létrehozás/update

**HIÁNYZIK:**
- `POST /auth/first-time-worker-setup` — meglevő worker (V111 seed)
  **első jelszóváltása** identity + jelszó kombo-val
  - Input: `{ companyCode, workerCode, currentPassword (vagy bootstrap), newPassword }`
  - Effect: worker.password_hash update + password_changed_at
  - Output: JWT + worker identity

### 4. Frontend login oldal — frontend-react/src/pages/auth/LoginPage.tsx

**Mostani pre-fill logika:**
- `companyCode` default: `'EBC'` (hardcoded)
- `workerCode` default: `''` (üres, user beírja)
- Worker lista lehúzása branch alapján: `GET /public/workers?branchCode=X`
  - Dropdown megjelenik ha `VITE_BRANCH_CODE` env-ben van
- **Nem olvassa** az Electron config store `bootstrap_worker_code`-ot
- **Nem olvassa** a jövőben bevezetendő `worker_code`-ot

---

## Gap analízis — mi nem működik

| # | Gap | Következmény | Prioritás |
|---|---|---|---|
| 1 | A SetupWizard 2 külön user-t kezel (bootstrap vs admin) | A kiválasztott dolgozó neve nem kapcsolódik az admin jelszóhoz | **P0** |
| 2 | Kapcsolat teszt kézi gombra vár | Bosszantó UX, felesleges klikk | P2 |
| 3 | `adminUsername` default "admin" — új worker | A dolgozó (BORSI) helyett egy külön "admin" worker lesz | **P0** |
| 4 | Electron config nem tárolja a bejelentkezett worker identity-t | Login oldal üres mezőkkel indul | **P0** |
| 5 | Login oldal nem pre-fill-el a telepítő választásából | User-nek minden induláskor kézzel kell beírnia | **P1** |
| 6 | Nincs "first-login password change" flow | V111 seed-elt jelszó (`1234`) vagy semmi; nincs átszám flow | **P1** |
| 7 | A hardcoded "admin/admin1234!" csalt | Fejlesztői kényelem, production nem így kell | **P0** |

---

## Elvárt flow (user specifikáció)

```
Telepítő indul
   ↓
Iroda választás (meglevő)
   ↓
Program típus (meglevő)
   ↓
[ÚJ] Auto connection test
   - Wizard belép a step-be → fetch /auth/bootstrap-status
   - Ha 200: "🟢 Kapcsolódva" banner (no button)
   - Ha fail: "🔴 Nincs kapcsolat: retry gomb"
   ↓
[ÚJ] Dolgozó + jelszó beállítás (egyesített step)
   - Worker dropdown: GET /public/workers?branchCode=X lista
   - User kiválasztja: "Borsi Tamás (BORSI)"
   - Jelszó mező + confirm (min 8 kar)
   - Submit: POST /auth/first-time-worker-setup
     { companyCode, workerCode: "BORSI", newPassword: "Uj1234!" }
   - Response: JWT + worker identity → TÁROLNI
   ↓
Telepítő befejeződik
   - Electron config store:
     worker_code="BORSI"
     worker_name="Borsi Tamás"
     worker_role="MANAGER"
     company_code="EBC"
     branch_code="KORUT"
     (password_hash NEM tárolódik lokálisan!)
   ↓
Program indul (penztár vagy értéktár)
   ↓
Login oldal megjelenik
   - companyCode: "EBC" (read-only, config-ból)
   - workerCode: "BORSI" (pre-filled, szerkeszthető)
   - workerName megjelenítve: "Borsi Tamás"
   - Jelszó mező: csak ezt kell beírnia
   ↓
POST /auth/login → JWT
   ↓
Pénztár / értéktár dashboard
```

---

## Javítási terv 3 fázisban

### Fázis 1 — Backend endpoint kiegészítés (1-2 óra)
- Új `AuthController.firstTimeWorkerSetup(...)` endpoint
- Input validation: worker létezik + nincs még aktív jelszó (first-time flag)
- BCrypt hash generation + save
- JWT token return

### Fázis 2 — Electron config + SetupWizard refaktor (3-4 óra)
- SetupWizard step-ek átrendezése:
  - "Teszt pénztáros" lépés eltávolítva (vagy egyesítve)
  - "Dolgozó + jelszó" új step
  - Auto connection test
- Electron config store bővítés:
  - `worker_code`, `worker_name`, `worker_role` tárolása
- IPC handler `setupSave` frissítése az új adatokra

### Fázis 3 — Login pre-fill + E2E (1-2 óra)
- LoginPage.tsx: config-ból pre-fill
- LoginPage.tsx: worker name megjelenítés
- E2E teszt:
  1. Friss installer
  2. Wizard: iroda, mode, auto-connect, worker select, jelszó beállítás
  3. Backend: worker.password_hash frissül
  4. App indít, login oldal pre-filled
  5. Sikeres belépés a wizard-ban beállított jelszóval

**Összesen:** ~6-8 óra munka

---

## Kockázatok

1. **Meglevő telepítések** — a verzióváltás miatt a jelenlegi dev/test user-eknek ismételten be kell állítaniuk. Mitigáció: V2.3.0 release notes.
2. **V111 seed jelszó (`1234`)** — a backend csak akkor engedi az első login-t, ha a wizard-ban csináltak jelszót. A V111 seed-et vissza kell vonnunk, vagy a `/first-time-worker-setup` endpoint-on a `1234`-gyel lehet belépni default-ként, ami biztonsági veszély. Megoldás: V161 migration ami `password_hash = NULL`-lá teszi, force-olva a first-time-setup-ot.
3. **Multi-tenant** — a wizard jelenleg hardcoded EBC-re. A multi-company future-proof design-hoz config-ban kellene lennie.

---

## Dokumentum verzió

- **v1.0 (2026-04-21):** első analízis + terv
- Felelős implementátor: következő Claude session
- Érintett fájlok: ~6 backend + ~4 frontend
- Becsült PR-ek: 3 (backend, installer, login)