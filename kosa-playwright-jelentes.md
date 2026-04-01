# KOSA Playwright ellenőrzési jelentés

Időpont: 2026-04-01  
Környezet: Windows + Electron dev stack (`penztar-client`)  
Tesztelő felhasználó: `EBC / KOSA / 1234`

## Végrehajtott teszt
- Playwright szkript: `penztar-client/scripts/kosa-playwright-audit.mjs`
- Cél URL: `http://127.0.0.1:3000`
- Bejárás:
  - `/dashboard`
  - `/transactions`
  - `/rates/creation`
  - `/cashdesk`
  - `/reports`
- Nyers riport: `penztar-client/playwright-artifacts/kosa-playwright-report.json`

## Feltárt hibák és javítások

### 1) Funkcionális hiba: login 502 (belépés nem működött)
- Tünet: `Request failed with status code 502` bejelentkezéskor.
- Ok: frontend dev proxy lokál backendre mutatott (`localhost:8080`), ami nem futott.
- Javítás:
  - `frontend-react/vite.config.ts`
  - `frontend-react/vite.config.js`
  - proxy target env-ből (`VITE_PROXY_TARGET`) olvas.
  - `penztar-client/package.json` dev renderer indításnál:
    - `VITE_PROXY_TARGET=https://excvaluta.com`

### 2) Működési hiba: üres képernyő Electronban
- Tünet: fehér/üres képernyő.
- Ok: Electron a `5173` dev shellt/placeholdert töltötte, nem a valódi renderert.
- Javítás:
  - `penztar-client/electron/main.ts`
    - renderer URL dedikált env-ből: `ELECTRON_RENDERER_URL`
  - `penztar-client/vite.config.ts`
    - spawn env: `ELECTRON_RENDERER_URL=http://127.0.0.1:3000`
  - `penztar-client/package.json`
    - `dev` script párhuzamosan indítja a renderert és electron main-t

### 3) Működési hiba: CashDesk oldal runtime crash
- Tünet: `Cannot read properties of undefined (reading 'toLocaleString')`
- Ok: `todayStats` részmezők néha `undefined` értéket kaptak API-ból.
- Javítás:
  - `frontend-react/src/pages/cashdesk/CashDeskPage.tsx`
  - `transactionCount`, `buyTurnoverHuf`, `sellTurnoverHuf`, `handlingFeeTotal` null-safe fallback (`?? 0`).

### 4) Operatív hiba: sérült encrypted token zaj/szinkron hiba
- Tünet: `safeStorage.decryptString` hiba, ismétlődő token decrypt warning.
- Ok: régi/sérült `auth_token_encrypted` payload.
- Javítás:
  - `penztar-client/electron/main.ts` (`secure-load-token`):
    - sérült encrypted token törlése fallback előtt.
  - `penztar-client/electron/sync-engine.ts` (`getAuthToken`):
    - decrypt hiba esetén `auth_token_encrypted` törlése.

## Aktuális eredmény (retest)
- Playwright audit lefutott: `ISSUE_COUNT=0`
- Login státusz: `200`
- Üres oldal: nem reprodukálható a renderer URL-en (`3000`)
- Kritikus route-ok betöltöttek, vizsgált oldalaknál nem jött új blokkolo hiba

## Maradék nem-blokkoló zaj
- DevTools protokoll üzenetek (`Autofill.enable`, `Unknown VE context`) továbbra is megjelenhetnek.
- React Router v7 future warningok dev módban láthatók.
