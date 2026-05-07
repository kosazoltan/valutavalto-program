---
title: P2 polish features — design + skeleton (2026-05-06)
type: reference
created: 2026-05-06
status: PLANNED (külön sprint-ekben implementálandó)
---

# P2 features — design + implementation skeleton

## P2-1 VFD (Vacuum Fluorescent Display) ügyfélkijelző

**Cél**: Az Electron pénztár-kliens másodlagos ablakban megjeleníti az ügyfélnek a tranzakció menetét — összeget, valutát, árfolyamot, sztornó figyelmeztetést.

**Architektúra**:
- Új Electron `BrowserWindow` (`customer-display`), második kijelzőn (vagy ugyanazon, ablak-keret nélküli, mindig-felül)
- IPC: `electronAPI.customerDisplay.show(payload)`, `customerDisplay.hide()`, `customerDisplay.update(payload)`
- Renderer: új React route `/customer-display` minimal layout (no sidebar, no header), nagy tipográfia
- Config: SQLite `customer_display_enabled`, `customer_display_screen` (0/1 monitor index)

**Implementációs fájlok (későbbi sprint-ben)**:
- `penztar-client/electron/customer-display.ts` — BrowserWindow management
- `penztar-client/electron/main.ts` — IPC handlers `customer-display:*`
- `frontend-react/src/pages/customer-display/CustomerDisplayPage.tsx` — minimal renderer
- Setup wizard új lépés: 2. monitor választása (opcionális)

**Tesztelés**:
- Manual test 1 monitorral (mindig-felül)
- Manual test 2 monitorral (auto-detect 2nd display)

**Becslés**: 2 nap

---

## P2-2 Supervisor PIN (jelszó helyett 4-6 számjegy)

**Cél**: Sztornó / jóváhagyás műveletekhez gyorsabb supervisor-megerősítés. Jelszó helyett 4-6 számjegy PIN, ami **csak ezekhez az interrupt-ot kérő műveletekhez** használható.

**Architektúra**:
- Új DB oszlop: `worker.supervisor_pin` (BCrypt hashelt, 4-6 számjegy plaintext-ből)
- Migration V188: `ALTER TABLE worker ADD COLUMN supervisor_pin VARCHAR(60)`
- Backend új endpoint: `POST /api/v1/auth/supervisor-pin-verify` body `{workerCode, pin}` → 200 OK or 401
- Frontend új komponens: `<SupervisorPinModal />` 4 input box, auto-focus, on-complete auto-submit
- A supervisor PIN **NEM jelszócsere** — kötelező a jelszó is létezzen (PIN csak gyors-engedély)
- Rate limit: 3 hibás próbálkozás után 5 perc lockout (per workerCode)

**Implementációs fájlok**:
- `backend/.../entity/Worker.java` — új mező + getter
- `backend/.../service/SupervisorPinService.java` — verify + setPin
- `backend/.../controller/SupervisorAuthController.java` — endpoint
- `frontend-react/src/components/auth/SupervisorPinModal.tsx`
- `frontend-react/src/pages/settings/UserPage.tsx` — admin új-PIN beállítás opció

**Becslés**: 1 nap

---

## P2-3 Design token rendszer

**Cél**: Egységes színek, betűtípusok, távolságok, árnyékok. Inter font default.

**Architektúra**:
- `tailwind.config.js` `theme.extend` blokk a custom token-ekkel
- Új fájl: `frontend-react/src/styles/design-tokens.css` — CSS custom properties (`--color-primary`, etc.)
- Inter font import: `@fontsource/inter` package + `index.css` `body { font-family: 'Inter', sans-serif }`
- Színpaletta: primary blue (#1E40AF), accent green (#059669), warning amber (#D97706), danger red (#DC2626)
- Spacing skála: Tailwind default + `xs: 0.25rem, sm: 0.5rem, md: 1rem, lg: 1.5rem, xl: 2rem, 2xl: 3rem`

**Implementációs fájlok**:
- `frontend-react/tailwind.config.js` — extend
- `frontend-react/src/styles/design-tokens.css` — CSS vars
- `frontend-react/src/main.tsx` — `import '@fontsource/inter'`
- `package.json` — `@fontsource/inter: ^5.0.0`

**Becslés**: 2 nap (full sweep + comonent audit)

---

## P2-4 Visual regression test (bizonylat-nyomtatás)

**Cél**: A bizonylat (ESC/POS + PDF) print kimenete vizuálisan nem változik PR-ek közt.

**Architektúra**:
- Playwright snapshot tesztek a bizonylat preview-ra
- Bizonylat-render PDF — `pdf-diff` library
- ESC/POS bytes — strukturális diff (assertion equal byte sequence)
- Minden tranzakció-típushoz 1-1 snapshot (vétel, eladás, sztornó, konverzió, sztornó)

**Implementációs fájlok**:
- `frontend-react/playwright/visual/receipt-snapshots.spec.ts`
- `backend/.../EscPosReceiptServiceVisualTest.java`
- CI workflow: `npm run test:visual` build artefactként

**Becslés**: 1 nap

### SKELETON IMPLEMENTED 2026-05-06

- **Fájl**: `D:\repo\valutavalto-program\frontend-react\playwright\visual\receipt-snapshots.spec.ts`
- **Status**: skeleton — 3 fixture-test (BUY/SELL/STORNO) + idempotencia check, mind `test.skip` az env flag mögött
- **Hiányzó (next sprint)**: dedikált `/dev/receipt-fixture/:type` deterministic preview route a frontend-en, ami fix dátummal + fix tranzakció ID-val rendereli a bizonylatot (különben minden snapshot diff lesz a timestamp + ID miatt). A route megvalósítása után a `test.skip` és a TODO kommentekben kommentált `page.goto` + `toHaveScreenshot` aktiválható, és baseline képeket kell generálni (`--update-snapshots`).
- **Run command**:
  ```bash
  PLAYWRIGHT_VISUAL_REGRESSION=1 npx playwright test playwright/visual/receipt-snapshots.spec.ts
  ```
- **Megjegyzés**: A `playwright.config.ts` `testDir: './e2e'` miatt explicit fájl-path kell, vagy egy dedikált config (lásd `playwright.acceptance.config.ts` mintáját).

---

## Ezen 4 P2 feature **NEM blokkolja a Product Ready státuszt**

A vault `legacy-anti-system.md` és `RE-gap-analysis-legacy-vs-modern.md` szerint ezek
"nice-to-have polish" tételek. A core compliance + funkcionális gap-ek (P0/P1) megoldása
után érdemes ezeket sprint-ben tervezni.

**Implementációs sorrend (javaslat)**:
1. P2-3 (Design token) — UI consistency, alapozás minden új komponenshez
2. P2-2 (Supervisor PIN) — gyors UX nyereség
3. P2-1 (VFD) — hardware-specifikus, manual test
4. P2-4 (Visual regression) — CI/CD befektetés

---

## P2-3 IMPLEMENTÁLVA — 2026-05-06 (Design tokens + Inter font)

**Státusz:** KÉSZ (frontend-react admin felület)

### Telepített csomag
- `@fontsource/inter@^5.2.8` (`frontend-react/package.json` dependencies)
- npm install: 1 csomag hozzáadva, 0 vulnerability

### Létrehozott fájlok
- `D:\repo\valutavalto-program\frontend-react\src\styles\design-tokens.css` (új, ~85 sor)
  - CSS custom properties: 5 primary szín, 6 semantic szín, 6 neutral szín
  - Spacing skála (xs to 2xl), Shadows (sm/md/lg), Font sizes (xs to 2xl)
  - Border radius (sm/md/lg), Font families (sans = Inter, mono = JetBrains Mono)
  - Body font-family + font-feature-settings (cv02, cv03, cv04, cv11)

### Módosított fájlok
- `D:\repo\valutavalto-program\frontend-react\src\main.tsx` — 4 db `@fontsource/inter/{400,500,600,700}.css` import (Inter async betöltés)
- `D:\repo\valutavalto-program\frontend-react\src\index.css` — `@import './styles/design-tokens.css';` a Tailwind direktívák ELŐTT
- `D:\repo\valutavalto-program\frontend-react\tailwind.config.js`:
  - `theme.extend.fontFamily.sans` first item: `'Inter'` (utána `ui-sans-serif`, `system-ui`, és a meglévő Segoe UI fallback)
  - `theme.extend.fontFamily.mono` first item: `'JetBrains Mono'` (utána Consolas/Monaco/Courier New)
  - `theme.extend.colors.brand` új scope, CSS variable hivatkozásokkal (pl. `'brand-primary': 'var(--color-primary-500)'`) — additív, a meglévő `primary`/`success`/`danger`/`warning` paletták NEM változtak

### Verifikáció (2026-05-06)
- `npx tsc --noEmit` — clean (exit 0, no output)
- `npm run build` — built in 972ms, minden chunk létrehozva
- Inter woff2 fájlok bundle-ben: dist/assets/inter-{latin,latin-ext,cyrillic,cyrillic-ext,greek,greek-ext,vietnamese}-{400,500,600,700}-normal-*.woff2 (8 latin + további 5 subset × 4 weight)
- index.css bundle: 83.2 KB (Tailwind + @font-face URLs Inter-hez + design-tokens)
- Build nem tört: a meglévő `bg-primary-800`, `text-secondary-700`, `currency-huf` osztályok változatlanul működnek

### Filozófia (additív, nem destruktív)
- A `colors.primary` (HSL #1E3A8A sötétkék brand), `colors.secondary`, `colors.accent`, `colors.success/danger/warning/info` paletták MEGMARADTAK
- Az új `colors.brand.*` scope CSS variable-eken keresztül adja a token rendszert — új design rendszer komponens `bg-brand-primary` vagy `var(--color-primary-500)`-tel dolgozhat
- A meglévő ~51 admin oldal és minden komponens VÁLTOZATLAN módon működik tovább

### Következő lépések (P2-3 follow-up)
- Sourcery/Codex AI review fix-ciklus PR merge után
- Penztar-client Electron renderer ugyanezt a token rendszert kapja meg külön sprintben
- Tailwind text-scale tokenek (font-size CSS var-ok) opcionális használata új komponenseknél
