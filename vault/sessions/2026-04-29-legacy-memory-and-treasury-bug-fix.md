---
date: 2026-04-29
session_type: legacy-memory-build + bug-fix
context: post-reboot Setup #3 SUCCESS után — user-direktíva: "olvasd be Anti/-t és építs memóriát + javítsd a Pénztár UI bug-jait"
priority: P0 — éles teszthez kell
---

# 2026-04-29 — Legacy memória felépítése + TreasuryLayout role-filter bug fix

## User-direktíva

> "D:\repo\valutavalto-program\Anti — Akkor olvast be ebből a könyvtárból a régi szoftver minden egyes mappájának, minden egyes almappáját. Ezzel párhuzamosan keresd meg az esetlegesen töröltnek jelölt QMD, YAML, Cognee, és Vault, és Obsidian memóriákat. ... Ha nincsenek, építs új memóriát ebből a régi programból teljes körülön."

> "Nincs SetupWizard belépett, szerintem főértéktáros módban, de értéktári modult mutat, ahol lehet átfolyamot készíteni, amit csak a főértéktárnak lehet."

## Eredmény

### 1. Legacy memória — NEM TÖRLŐDÖTT, csak nem volt vault-indexálva

A korábbi session-ek mind a `Anti/antivaluta.md` (805 sor), mind a `docs/knowledge/legacy-reverse-engineering/` (27 fájl, ~450 KB) git-élnek. **Egyik sem törlődött** a 2026-04-27-i memória-tisztításnál (csak a `.memory/` SQLite + Cognee + Bence/Eszter/Tamás belső koncepció lett deprecated).

A meglévő dokumentumok:
- `Anti/antivaluta.md` — 805 sor, top-level mapping (110+ DLL katalógus + 90+ DB tábla + Firebird/InterBase architektúra)
- `Anti/ANTI_MODERNIZATION_CAMERA_CASHDESK_MASTERPLAN.md` — modernizáció masterplan
- `docs/knowledge/legacy-reverse-engineering/INDEX.md` — legacy-RE registry (5 expert + 22 specifikus)
- `docs/knowledge/legacy-reverse-engineering/legacy-dll-parity-matrix.md` — legacy → modern modul-mapping
- `docs/knowledge/legacy-reverse-engineering/RE-{junior,tamas,eszter,gabor}-*.md` — 5 fős RE-csapat-elemzés
- `docs/knowledge/legacy-reverse-engineering/firebird-schema-reconstruction-index.md` — DB séma
- `docs/knowledge/legacy-reverse-engineering/aml-bigctrl-rule-parity.md` — AML

### 2. Vault index létrehozva

**`D:\valutavalto-vault\references\legacy-anti-system.md`** (új, 270 sor) — fókuszált indexálás + szerep-szerinti operatív összegzés a jelenlegi bug-okhoz:

- **§1** Top-level mapping (VALUTA, ARFOLYAM, ERTEKTAR, KESZLEX, KORLEVEL_ZIP, SZERVER, camera, firebird)
- **§2** Szerepkörök szigorú szétválasztása (legacy alapján):
  - **Pénztáros** (cashier) → `VALUTA/IBVALTO` + 110 DLL — NEM készít árfolyamot
  - **Helyi értéktáros** → `ERTEKTAR/etdll/` (55 saját DLL: atadolap, atadvet, napzar, pillkesz, kcimlet, ...) — NEM készít árfolyamot, helyi átadás-átvétel, helyi készlet, helyi zárás
  - **Főértéktár** (national main vault) → `ARFOLYAM/Arfolyam.exe` (külön EXE!) + központi szerver — KÉSZÍT árfolyamot, központi KPI, országos készlet, MNB/NAV
  - **Supervisor** → `super.dll` ortogonális jelszós-jóváhagyás bármely szerep mellett
- **§3** Modern Java + React + Electron megfeleltetés (mode-hoz tab-mátrix)
- **§4** **4 azonosított Pénztár Electron bug** részletes elemzéssel
- **§5** Adatbázis-szintű forrás-igazságok (Firebird → PostgreSQL)
- **§6** Hivatkozási útmutató
- **§7** Akció-lista a következő session-be

### 3. TreasuryLayout role-filter BUG FIX (in progress → done)

**Bug forrása:** `frontend-react/src/pages/treasury/TreasuryLayout.tsx` (hardkódolt 10 tab role-check NÉLKÜL)

**Tünet (user-jelentés):**
> "Értéktári modult mutat, ahol lehet **árfolyamot készíteni**, amit csak a főértéktárnak lehet."

**A kavarodás oka:**
A `treasuryTabs` tömb tartalmazta az `Árfolyamkészítés F5` (`/treasury/rates`), `Banki Tx F4`, `ÁFA visszatérítés F7`, `TRB Export F8`, `Bankforgalom F10` tabokat **role-szűrés nélkül**. A legacy `Anti/ARFOLYAM/Arfolyam.exe` (külön EXE!) szerint ezek **központi főértéktár / ügyvezető** funkciók — helyi értéktáros (mode='ertektar') NEM látja, NEM használhatja.

**Fix:**
- `canonicalRoles: CENTRAL_VAULT_ROLES = ['foertektar', 'ugyvezeto']` mező hozzáadva 5 tabhoz
- `treasuryTabs` filter `useMemo`-val (deps: `roles`, `activeRole`, `workerRole`)
- F-key hotkey-ok is ellenőrzik a tab láthatóságát (nem viszik el a usert nem-látható tabra)
- Help dialog `treasuryTabs.map(...)`-ra cserélve a hardkódolt 10 sor helyett

**Tesztek:**
- `npx tsc --noEmit` → EXIT=0, 0 hiba
- `MainLayout.menu.test.tsx` → 27/27 pass (regresszió-mentes)
- **ÚJ:** `TreasuryLayout.role-filter.test.ts` (7 teszt) — ertektar/foertektar/ugyvezeto/penztar/empty/mixed role-okra mind PASS

**Fájlok módosítva:**
- `frontend-react/src/pages/treasury/TreasuryLayout.tsx` (hozzáadva: useMemo, useAuthStore, canonicalRoles mező, F-key isVisiblePath check, help dialog refactor)
- `frontend-react/src/pages/treasury/TreasuryLayout.role-filter.test.ts` (új, 7 teszt)
- `D:\valutavalto-vault\references\legacy-anti-system.md` (új, 270 sor index + role-mátrix)
- `D:\valutavalto-vault\sessions\2026-04-29-legacy-memory-and-treasury-bug-fix.md` (ez a session-jegyzet)

## Maradt feladatok

- **P0 (még a sessionben kell)**: SetupWizard kényszerítése — friss telepítés után a `App.tsx` redirectálja `/setup-wizard`-ra, ha az `app_mode` SQLite config nincs beállítva
- **P0**: Bootstrap admin login + VÉTEL teszt (`V<3-jegy>000001` formátum)
- **P1**: NSIS PowerShell `-like` parser bug + ICACLS Hungarian locale fix → v2.3.8 build
- **P2**: Backend startup wait timeout 60s → 90s a NSIS wizardban
- **P2**: DLL memory-lock detection a Setup ELŐTT (REBOOT-javaslat)

## Backend stack (production-stable, változatlan)
- Spring Boot 4.0.6 + Tomcat 11.0.21 (Servlet 6.1)
- Jackson 2 stop-gap + JacksonConfig.java programmatic ObjectMapper
- springdoc 3.0.3 + flyway-database-postgresql 12.4.0
- HTTP 200 stabil (Hetzner monitor)
- V1..V167 Flyway migrations applied

## Workflow-state

- Branch: `determined-liskov-08a877` worktree
- Main HEAD: `70e4a4cd` (változatlan)
- 0 open PR
- Production HTTP 200 stabil
