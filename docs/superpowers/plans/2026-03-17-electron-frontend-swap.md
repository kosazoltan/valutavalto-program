# Electron → Frontend-react UI csere — Implementációs terv

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Az Electron kliens saját renderer-jét (penztar-client/src/) lecserélni a frontend-react build outputjára, úgy hogy az Electron KIZÁRÓLAG lokális backend szerepet töltsön be (SQLite, offline sync, nyomtatás, kamera, szkenner), a UI-t teljes egészében a frontend-react vezérli.

**Architecture:**
- **Electron = lokális backend.** Csak a `electron/` mappa marad: `main.ts`, `preload.ts`, `sqlite.ts`, `sync-engine.ts`, `printer.ts`, `camera.ts`, `scanner.ts`, `updater.ts`. Semmilyen React renderer kód nincs az Electron projektben.
- **frontend-react = az egyetlen UI.** Böngészőben ÉS Electron-ban ugyanaz a React app fut. Electron-specifikus funkciók `window.electronAPI?.` optional chaining-gel hívódnak — ha nincs Electron, sima webes működés.
- **Build pipeline:** `frontend-react` → `npm run build` → `dist/` → Electron becsomagolja az asar-ba. A penztar-client saját Vite renderer build-je MEGSZŰNIK.

**Tech Stack:** Electron 33, React 19, TypeScript, Vite 5, SQLite (sql.js), electron-builder

---

## ⚠️ FONTOS: A két React app funkciókészlete eltér!

A review során kiderült, hogy a `penztar-client/src/` és a `frontend-react/` **nem azonos funkcionalitást** nyújtja. A penztar-client-nek vannak unikális funkciói, amiket a frontend-react-be kell portolni MIELŐTT a renderer kód törölhető lenne.

### Penztar-client egyedi kód, amit át kell portolni:

| Kategória | Penztar-client fájl(ok) | Frontend-react-be kell? | Megjegyzés |
|-----------|------------------------|------------------------|------------|
| **Auth store** | `stores/authStore.ts` — `branchCode`, `companyId`, `activeRole`, `permissions`, `companyType` | ✅ IGEN | A frontend-react authStore-ja `Worker` típusú, más interface |
| **Token restore** | `App.tsx` — `loadPersistedToken` + JWT dekódolás + `/workers/me` | ✅ IGEN | Frontend-react App.tsx-ben nincs token restore |
| **App mode** | `config/appMode.ts`, `hooks/useAppMode.ts` — pénztár/értéktár mód | ✅ IGEN | Electron config-ból olvas |
| **Rate store** | `stores/rateStore.ts` — limit-aware rate resolution (`getEffectiveBuyRate/SellRate`) | ✅ IGEN | Üzleti kritikus logika |
| **WebSocket rates** | `hooks/useRateUpdates.ts` — STOMP real-time árfolyam | ✅ IGEN | A frontend-react-nek nincs WebSocket rate hook |
| **Online status** | `hooks/useOnlineStatus.ts`, `components/OnlineIndicator.tsx` | ✅ IGEN | Offline detektálás — kritikus Electron funkció |
| **Update notifier** | `hooks/useUpdateNotifier.ts`, `components/UpdateBanner.tsx` | ✅ IGEN | Backend verzió-ellenőrzés |
| **Kamera** | `components/CameraRecorder.tsx`, `CameraExport.tsx` | ✅ IGEN | `electronAPI.cameraSaveRecording` |
| **Szkenner** | `components/DocumentScanner.tsx` | ✅ IGEN | `electronAPI.scanSaveDocument` |
| **Nyomtatás** | `components/ReceiptPreviewModal.tsx`, `utils/receipt.ts` | ✅ IGEN | Bizonylat generálás + nyomtatás |
| **QR kód** | `utils/qrcode.ts` | ✅ IGEN | Bizonylat QR |
| **Típusok** | `types/index.ts` (~50+ interface) | ✅ IGEN | Teljes típusrendszer |
| **API modulok** | `api/rates.ts`, `api/closing.ts`, `api/workers.ts` stb. (~30 modul) | 🔍 ELLENŐRIZNI | Csak ha a frontend-react-ből hiányoznak az equivalens API hívások |

### Route eltérések:
A penztar-client route-jai (`/sell`, `/buy`, `/stock`, `/denom`, `/closing` stb.) és a frontend-react route-jai (`/dashboard`, `/transactions/new`, `/cashdesk/denominations` stb.) **eltérő URL-eket** használnak. Ez nem blokkoló — a frontend-react route-jai lesznek az irányadóak.

---

## Jelenlegi állapot összefoglalása

### Ami VAN:
- `penztar-client/src/` — saját React renderer, 51+ oldal, saját API kliens (`src/api/client.ts`), saját store-ok
- `penztar-client/electron/` — Electron main process: SQLite, sync-engine, printer, camera, scanner, updater
- `penztar-client/vite.config.ts` — `vite-plugin-electron` plugin-nel buildeli a main + preload + renderer-t együtt
- `frontend-react/` — admin webes felület, 51+ oldal, saját API kliens (`src/services/api.ts`), NINCS Electron hivatkozás
- `penztar-client/electron-builder.json` — `dist/**/*` (renderer build) + `dist-electron/**/*` (main + preload)

### Ami LESZ:
- `penztar-client/src/` — **TÖRLŐDIK** (teljes renderer kód)
- `penztar-client/electron/` — **MARAD** változatlanul (lokális backend)
- `penztar-client/vite.config.ts` — **EGYSZERŰSÖDIK**: csak electron main + preload build, nincs renderer
- `frontend-react/` — **BŐVÜL** `window.electronAPI` detektálással, IPC hívásokkal, és penztar-specifikus logikával
- `penztar-client/electron-builder.json` — `dist/**/*` most a frontend-react build outputjára mutat
- **Új build script**: `frontend-react` build → másolás → Electron package

---

## Fájl struktúra térkép

### Törlendő fájlok (penztar-client renderer):
- `penztar-client/src/**/*` — teljes renderer forráskód (~51 oldal, store-ok, komponensek, hookok, API kliens)
- `penztar-client/dist/` — korábbi renderer build output
- `penztar-client/index.html` — renderer entry point

### Módosítandó fájlok:
- `penztar-client/vite.config.ts` — renderer build eltávolítása, csak electron/ build
- `penztar-client/electron-builder.json` — dist forrás ellenőrzése
- `penztar-client/package.json` — scripts módosítás, renderer függőségek eltávolítása
- `penztar-client/electron/main.ts` — SPA fallback routing + dev URL módosítás
- `frontend-react/src/services/api.ts` — `window.electronAPI` token persist integráció
- `frontend-react/src/App.tsx` — token restore logika Electron-ból
- `frontend-react/src/stores/authStore.ts` — Electron token persist integráció
- `backend/src/main/java/hu/puzzleir/valuta/config/SecurityConfig.java` — CORS `app://localhost`

### Új fájlok:
- `frontend-react/src/types/electron.d.ts` — ElectronAPI interface deklaráció
- `frontend-react/src/utils/electron.ts` — helper a `window.electronAPI` detektálásához
- `frontend-react/src/hooks/useOnlineStatus.ts` — offline detektálás (portolás penztar-client-ből)
- `frontend-react/src/hooks/useUpdateNotifier.ts` — Electron verzió-ellenőrzés (portolás)
- `frontend-react/src/components/OnlineIndicator.tsx` — online/offline jelző (portolás)
- `frontend-react/src/components/UpdateBanner.tsx` — frissítés banner (portolás)
- `scripts/build-electron.sh` — Teljes Electron build pipeline script

---

## FÁZIS 1: Infrastruktúra (Electron-detektálás, build pipeline)

Ezek a task-ok a frontend-react webes működését NEM törik el.

---

### Task 1: ElectronAPI TypeScript típusdefiníció a frontend-react-ben

**Files:**
- Create: `frontend-react/src/types/electron.d.ts`

- [ ] **Step 1: Létrehozni az ElectronAPI interface-t**

A `penztar-client/electron/preload.ts` alapján — ugyanazokat az IPC metódusokat kell deklarálni:

```typescript
// frontend-react/src/types/electron.d.ts

export interface ElectronAPI {
  // --- Config (token persist) ---
  getConfig(key: string): Promise<string | null>;
  setConfig(key: string, value: string): Promise<void>;
  deleteConfig(key: string): Promise<void>;

  // --- Nyomtatás ---
  printReceipt(data: string): Promise<boolean>;
  getPrinters(): Promise<Array<{
    name: string;
    displayName: string;
    description: string;
    status: number;
    isDefault: boolean;
  }>>;

  // --- Offline tranzakciók ---
  savePendingTransaction(
    type: 'SELL' | 'BUY',
    currencyCode: string,
    foreignAmount: number,
    hufAmount: number,
    roundedHufAmount: number,
    rate: number,
    customerId: number | null,
    denominations: string | null,
  ): Promise<number>;
  getPendingTransactions(): Promise<Array<{
    id: number;
    type: string;
    currency_code: string;
    foreign_amount: number;
    huf_amount: number;
    rounded_huf_amount: number;
    rate: number;
    customer_id: number | null;
    denominations: string | null;
    created_at: string;
    synced: number;
  }>>;
  getPendingTransactionCount(): Promise<number>;
  syncOffline(): Promise<number>;
  getSyncStatus(): Promise<string>;

  // --- Értéktár offline ---
  savePendingDistribution(
    targetBranchCode: string,
    currencyCode: string,
    amount: number,
    denominations: string | null,
    note: string | null,
  ): Promise<number>;
  savePendingTransfer(
    targetBranchCode: string,
    currencyCode: string,
    amount: number,
    denominations: string | null,
    note: string | null,
  ): Promise<number>;
  savePendingCollection(
    sourceBranchCode: string,
    currencyCode: string,
    amount: number,
    note: string | null,
  ): Promise<number>;
  getCachedBranchStatuses(): Promise<Array<{
    branch_code: string;
    branch_name: string;
    company_id: number | null;
    last_sync_at: string | null;
    online_status: string;
    total_huf_value: number;
    daily_turnover: number;
    cash_balances: string | null;
    cached_at: string;
  }>>;
  getCachedBranchStatusTimestamp(): Promise<string | null>;
  getCachedRates(): Promise<Array<{
    currency_code: string;
    buy_rate: number;
    sell_rate: number;
    unit: number;
    updated_at: string;
  }>>;

  // --- Kamera ---
  cameraSaveRecording(transactionId: string, buffer: ArrayBuffer, ext: string): Promise<string>;
  cameraExportToUsb(dateFrom: string, dateTo: string): Promise<{ success: boolean; exported: number; error?: string }>;
  cameraListRecordings(transactionId?: string): Promise<string[]>;

  // --- Okmány szkenner ---
  scanSaveDocument(
    transactionId: string,
    documentType: 'szemelyi' | 'utlevel' | 'jogositvany' | 'egyeb',
    imageBase64: string,
  ): Promise<{ path: string; encrypted: boolean }>;
  scanGetDocument(filepath: string): Promise<string>;
  scanListDocuments(transactionId: string): Promise<string[]>;

  // --- App ---
  getAppVersion(): Promise<string>;
  restartApp(): Promise<void>;

  // --- Platform ---
  platform: string;
}

declare global {
  interface Window {
    electronAPI?: ElectronAPI;
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add frontend-react/src/types/electron.d.ts
git commit -m "feat: add ElectronAPI TypeScript type definitions for frontend-react"
```

---

### Task 2: Electron helper utility a frontend-react-ben

**Files:**
- Create: `frontend-react/src/utils/electron.ts`

- [ ] **Step 1: Létrehozni az electron helper-t**

```typescript
// frontend-react/src/utils/electron.ts

/**
 * Electron detektálás — true ha az app Electron-ban fut (preload.ts exposeálta a window.electronAPI-t).
 */
export function isElectron(): boolean {
  return typeof window !== 'undefined' && !!window.electronAPI;
}

/**
 * ElectronAPI elérése — null ha böngészőben fut.
 */
export function getElectronAPI() {
  return window.electronAPI ?? null;
}
```

- [ ] **Step 2: Commit**

```bash
git add frontend-react/src/utils/electron.ts
git commit -m "feat: add Electron detection utility for frontend-react"
```

---

### Task 3: frontend-react API kliens — token persist integráció

**Files:**
- Modify: `frontend-react/src/services/api.ts`

A jelenlegi `api.ts` sima webes — nincs token persist. Hozzá kell adni az Electron token tárolás/visszaolvasás logikát.

- [ ] **Step 1: Bővíteni az api.ts-t Electron token persist-tel**

Az `api.ts` végéhez hozzáadni (a meglévő kódot NEM módosítjuk, csak kiegészítjük):

```typescript
// --- Electron token persist (ha Electron-ban fut) ---

/** Token mentése Electron config store-ba (offline login restore-hoz) */
export async function persistToken(token: string): Promise<void> {
  if (window.electronAPI) {
    await window.electronAPI.setConfig('auth_token', token);
  }
}

/** Token törlése Electron config store-ból */
export async function clearPersistedToken(): Promise<void> {
  if (window.electronAPI) {
    await window.electronAPI.deleteConfig('auth_token');
  }
}

/** Token betöltése Electron config store-ból (app induláskor) */
export async function loadPersistedToken(): Promise<string | null> {
  if (window.electronAPI) {
    return window.electronAPI.getConfig('auth_token');
  }
  return null;
}
```

- [ ] **Step 2: Megkeresni a frontend-react auth flow-t**

Meg kell vizsgálni:
- `frontend-react/src/stores/authStore.ts` — hogyan kezeli a JWT-t (memória? localStorage?)
- `frontend-react/src/App.tsx` vagy `main.tsx` — van-e token restore logika
- A login oldal — hol hívja a `login()` store metódust

- [ ] **Step 3: Login flow-ba integrálni a token persist-et**

A frontend-react authStore `login()` metódusában:
```typescript
// Login sikeres → persist (Electron-ban SQLite-ba menti)
await persistToken(jwt);
```

A `logout()` metódusban:
```typescript
await clearPersistedToken();
```

- [ ] **Step 4: App.tsx-ben token restore logika**

A `frontend-react/src/App.tsx` (vagy `main.tsx`) mount-kor:

```typescript
useEffect(() => {
  const restoreToken = async () => {
    const token = await loadPersistedToken();
    if (token) {
      // JWT validáció: 3 szekció + nem lejárt
      const parts = token.split('.');
      if (parts.length === 3 && parts[1]) {
        const payload = JSON.parse(atob(parts[1])) as { exp?: number };
        const now = Math.floor(Date.now() / 1000);
        if (payload.exp && payload.exp > now) {
          // Token érvényes → restore auth state
          api.defaults.headers.common['Authorization'] = `Bearer ${token}`;
          try {
            const res = await api.get('/workers/me');
            if (res.data) {
              authStore.getState().login(res.data, token, /* ... */);
            }
          } catch {
            // Token szerver oldalon érvénytelen → töröljük
            await clearPersistedToken();
          }
        }
      }
    }
  };
  void restoreToken();
}, []);
```

**Referencia:** `penztar-client/src/App.tsx:94-126` — pontosan ezt a logikát kell adaptálni.

- [ ] **Step 5: Commit**

```bash
git add frontend-react/src/services/api.ts frontend-react/src/App.tsx frontend-react/src/stores/authStore.ts
git commit -m "feat: integrate Electron token persistence in frontend-react auth flow"
```

---

### Task 4: Electron main.ts — SPA fallback routing

**Files:**
- Modify: `penztar-client/electron/main.ts:232-242` (protocol handler)

A jelenlegi protocol handler 1:1 fájl-mapping-et csinál. SPA fallback kell: ha a fájl nem létezik (nincs kiterjesztése), `index.html`-t adunk vissza.

- [ ] **Step 1: Protocol handler módosítása SPA fallback-kel**

```typescript
protocol.handle('app', async (req) => {
  const url = new URL(req.url);
  let filePath = path.join(distPath, decodeURIComponent(url.pathname));

  // Ha gyökér kérés, index.html
  if (url.pathname === '/' || url.pathname === '') {
    filePath = path.join(distPath, 'index.html');
  }

  // SPA fallback: ha nincs fájl kiterjesztés → index.html (React Router route)
  // Assets-nek mindig van kiterjesztése: .js, .css, .png, .svg stb.
  const hasExtension = path.extname(filePath) !== '';
  if (!hasExtension) {
    filePath = path.join(distPath, 'index.html');
  }

  log.info(`[Protocol] ${req.url} → ${filePath}`);
  return net.fetch(pathToFileURL(filePath).toString());
});
```

- [ ] **Step 2: Commit**

```bash
git add penztar-client/electron/main.ts
git commit -m "fix: add SPA fallback routing to Electron protocol handler"
```

---

### Task 5: Vite config egyszerűsítés — renderer build eltávolítása

**Files:**
- Modify: `penztar-client/vite.config.ts`

- [ ] **Step 1: Vite config módosítása — csak electron main + preload build**

```typescript
// penztar-client/vite.config.ts
import { defineConfig } from 'vite';
import electron from 'vite-plugin-electron';

export default defineConfig({
  plugins: [
    electron([
      {
        entry: 'electron/main.ts',
        vite: {
          build: {
            outDir: 'dist-electron',
            rollupOptions: {
              external: ['better-sqlite3', 'sql.js'],
            },
          },
        },
      },
      {
        entry: 'electron/preload.ts',
        onstart(args) {
          args.reload();
        },
        vite: {
          build: {
            outDir: 'dist-electron',
          },
        },
      },
    ]),
  ],
});
```

Eltávolítva: `react()` plugin, `resolve.alias`, `base: '/'`, `remove-crossorigin` plugin.

- [ ] **Step 2: Commit**

```bash
git add penztar-client/vite.config.ts
git commit -m "refactor: simplify Vite config — remove renderer build, keep only Electron main+preload"
```

---

### Task 6: package.json — scripts és függőségek

**Files:**
- Modify: `penztar-client/package.json`

- [ ] **Step 1: Scripts módosítása (cross-platform!)**

**FONTOS:** Windows 11 a fejlesztői gép — `rm -rf` és `cp -r` nem működik natívan. Használjunk `shx` npm csomagot, vagy a package.json scripts-ben Git Bash-t.

```json
{
  "scripts": {
    "dev": "vite",
    "build:electron": "vite build",
    "build:frontend": "cd ../frontend-react && npm run build",
    "copy:frontend": "shx rm -rf dist && shx cp -r ../frontend-react/dist dist",
    "build": "npm run build:frontend && npm run copy:frontend && npm run build:electron",
    "package": "npm run build && electron-builder --win",
    "postinstall": "electron-builder install-app-deps"
  }
}
```

Plusz `devDependencies`-be: `"shx": "^0.3.4"`

- [ ] **Step 2: Renderer-only függőségek eltávolítása**

Először ellenőrizni, mit használ az `electron/` kód:

```bash
grep -r "stomp\|sockjs\|react\|zustand\|dompurify\|qrcode\|axios" penztar-client/electron/
```

Az `electron/` kód által használt csomagok (MARADNAK):
- `electron-log`, `electron-updater`, `sql.js`

TÖRLENDŐ (csak renderer használta):
- `react`, `react-dom`, `react-router-dom`
- `zustand`
- `dompurify`
- `qrcode`, `@types/qrcode`
- `axios`, `axios-retry` (a sync-engine `fetch()`-et használ, nem axios-t)
- `@stomp/stompjs`, `sockjs-client` (csak a renderer `useRateUpdates` hook használta)

- [ ] **Step 3: Commit**

```bash
git add penztar-client/package.json
git commit -m "refactor: update scripts for frontend-react integration, remove renderer-only deps"
```

---

### Task 7: CORS konfiguráció — `app://localhost` hozzáadása

**Files:**
- Modify: `backend/src/main/java/hu/puzzleir/valuta/config/SecurityConfig.java`

- [ ] **Step 1: Ellenőrizni az aktuális CORS config-ot**

```bash
grep -n "allowedOrigins\|cors\|app://localhost" backend/src/main/java/hu/puzzleir/valuta/config/SecurityConfig.java
```

- [ ] **Step 2: Ha hiányzik, hozzáadni `app://localhost`-ot**

Az engedélyezett origin-ök közé:
```java
.allowedOrigins("http://localhost:3000", "http://localhost:5173", "app://localhost")
```

Vagy `application.properties`-ben:
```properties
cors.allowed-origins=http://localhost:3000,http://localhost:5173,app://localhost
```

- [ ] **Step 3: Commit**

```bash
git add backend/src/main/java/hu/puzzleir/valuta/config/SecurityConfig.java
git commit -m "fix: add app://localhost CORS origin for Electron production"
```

---

### Task 8: VITE_API_URL kezelés Electron production-ben

**Files:**
- Modify: `frontend-react/src/services/api.ts`

- [ ] **Step 1: API URL fallback logika Electron-hoz**

A jelenlegi api.ts production-ben hibát dob, ha nincs `VITE_API_URL`. Electron-ban nincs env var → fallback kell:

```typescript
let API_BASE_URL = import.meta.env.VITE_API_URL;
if (!API_BASE_URL) {
  if (import.meta.env.DEV) {
    API_BASE_URL = 'http://localhost:8080/api/v1';
  } else if (window.electronAPI) {
    // Electron production — a szerver URL-t az Electron config-ból olvassuk ki
    // Fallback: a Render deploy URL
    API_BASE_URL = 'https://valutavalto-api.onrender.com/api/v1';
  } else {
    // Webes production — relatív URL (proxy mögött)
    API_BASE_URL = '/api/v1';
  }
}
```

**ALTERNATÍVA:** Az Electron build során a `VITE_API_URL`-t env var-ként beállítani a build script-ben:
```bash
VITE_API_URL=https://valutavalto-api.onrender.com/api/v1 npm run build
```

**MEGJEGYZÉS:** A penztar-client jelenlegi megoldása: a `sync-engine.ts` az SQLite config store-ból olvassa a `server_url`-t (`getConfig('server_url')`). Ugyanezt a mintát lehetne használni a frontend-react API kliensben is (Electron-ban a `window.electronAPI.getConfig('server_url')` hívással).

- [ ] **Step 2: Commit**

```bash
git add frontend-react/src/services/api.ts
git commit -m "fix: add API URL fallback for Electron production environment"
```

---

### Task 9: Build pipeline script (cross-platform)

**Files:**
- Create: `scripts/build-electron.sh`

- [ ] **Step 1: Build script létrehozása**

```bash
#!/bin/bash
# scripts/build-electron.sh — Teljes Electron build pipeline
# Használat: bash scripts/build-electron.sh
# Windows-on: Git Bash-ben futtatandó

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FRONTEND_DIR="$REPO_ROOT/frontend-react"
ELECTRON_DIR="$REPO_ROOT/penztar-client"

echo "=== 1/4 Frontend-react build ==="
cd "$FRONTEND_DIR"
npm ci --ignore-scripts
# VITE_API_URL beállítása a production szerverhez
VITE_API_URL="${VITE_API_URL:-https://valutavalto-api.onrender.com/api/v1}" npm run build
echo "✅ Frontend build kész: $FRONTEND_DIR/dist/"

echo "=== 2/4 Frontend dist másolása Electron-ba ==="
rm -rf "$ELECTRON_DIR/dist"
cp -r "$FRONTEND_DIR/dist" "$ELECTRON_DIR/dist"
echo "✅ Dist másolva: $ELECTRON_DIR/dist/"

echo "=== 3/4 Electron main+preload build ==="
cd "$ELECTRON_DIR"
npm ci --ignore-scripts
npx vite build
echo "✅ Electron build kész: $ELECTRON_DIR/dist-electron/"

echo "=== 4/4 Electron package (installer) ==="
npx electron-builder --win
echo "✅ Installer kész: $ELECTRON_DIR/release/"
```

- [ ] **Step 2: Commit**

```bash
git add scripts/build-electron.sh
git commit -m "chore: add cross-platform Electron build pipeline script"
```

---

### Task 10: Dev workflow beállítás

**Files:**
- Modify: `penztar-client/electron/main.ts` (dev mód URL)

- [ ] **Step 1: Frontend-react vite dev szerver port ellenőrzése**

```bash
grep -n "port" frontend-react/vite.config.ts
```

A frontend-react `vite.config.ts`-ben be van állítva `port: 3000`.

- [ ] **Step 2: Electron main.ts dev URL módosítása**

```typescript
if (isDev) {
  mainWindow.loadURL('http://localhost:3000'); // ← frontend-react vite dev szerver
  mainWindow.webContents.openDevTools({ mode: 'detach' });
}
```

**Dev workflow:**
1. Terminál 1: `cd frontend-react && npm run dev` (port 3000)
2. Terminál 2: `cd penztar-client && npm run dev` (Electron indul, betölti localhost:3000-et)

- [ ] **Step 3: Commit**

```bash
git add penztar-client/electron/main.ts
git commit -m "fix: update Electron dev URL to frontend-react dev server (port 3000)"
```

---

## FÁZIS 2: Penztar-specifikus logika portolása a frontend-react-be

Ezek a task-ok a penztar-client/src/ egyedi funkcionalitását portolják a frontend-react-be. Minden új kód `window.electronAPI?.` optional chaining-gel hívja az Electron API-t — böngészőben ezek a funkciók inaktívak.

---

### Task 11: Online/offline detektálás portolása

**Files:**
- Source (referencia): `penztar-client/src/hooks/useOnlineStatus.ts`, `penztar-client/src/components/OnlineIndicator.tsx`
- Create: `frontend-react/src/hooks/useOnlineStatus.ts`
- Create: `frontend-react/src/components/OnlineIndicator.tsx`

- [ ] **Step 1: Átolvasni a penztar-client implementációt**

```bash
cat penztar-client/src/hooks/useOnlineStatus.ts
cat penztar-client/src/components/OnlineIndicator.tsx
```

- [ ] **Step 2: Frontend-react-ben létrehozni a hook-ot**

A hook `navigator.onLine` + backend health check kombináció. Electron-ban az offline detektálás kiemelten fontos — ha offline, a pending tranzakciók SQLite-ba mennek.

```typescript
// frontend-react/src/hooks/useOnlineStatus.ts
import { useState, useEffect } from 'react';
import { isElectron } from '@/utils/electron';

export function useOnlineStatus() {
  const [isOnline, setIsOnline] = useState(navigator.onLine);

  useEffect(() => {
    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    // Electron-ban aktív health check is (30s intervallum)
    let healthCheckInterval: ReturnType<typeof setInterval> | null = null;
    if (isElectron()) {
      healthCheckInterval = setInterval(async () => {
        try {
          const res = await fetch('/api/v1/actuator/health', { signal: AbortSignal.timeout(5000) });
          setIsOnline(res.ok);
        } catch {
          setIsOnline(false);
        }
      }, 30_000);
    }

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
      if (healthCheckInterval) clearInterval(healthCheckInterval);
    };
  }, []);

  return isOnline;
}
```

**FONTOS:** A pontos implementáció a penztar-client fájl átnézése után dől el. A fenti minta a koncepciót mutatja.

- [ ] **Step 3: OnlineIndicator komponens létrehozása**

A meglévő penztar-client komponens alapján — kis zöld/piros pötty a fejlécben.

- [ ] **Step 4: Commit**

```bash
git add frontend-react/src/hooks/useOnlineStatus.ts frontend-react/src/components/OnlineIndicator.tsx
git commit -m "feat: port online/offline detection from penztar-client to frontend-react"
```

---

### Task 12: Update notifier portolása

**Files:**
- Source: `penztar-client/src/hooks/useUpdateNotifier.ts`, `penztar-client/src/components/UpdateBanner.tsx`
- Create: `frontend-react/src/hooks/useUpdateNotifier.ts`
- Create: `frontend-react/src/components/UpdateBanner.tsx`

- [ ] **Step 1: Átolvasni a penztar-client implementációt**
- [ ] **Step 2: Portolni a hook-ot és komponenst** — csak Electron-ban aktív (`isElectron()` guard)
- [ ] **Step 3: App.tsx-ben beépíteni** — `<UpdateBanner />` a legfelső szinten
- [ ] **Step 4: Commit**

```bash
git add frontend-react/src/hooks/useUpdateNotifier.ts frontend-react/src/components/UpdateBanner.tsx frontend-react/src/App.tsx
git commit -m "feat: port update notifier from penztar-client to frontend-react"
```

---

### Task 13: Rate store és WebSocket rate updates portolása

**Files:**
- Source: `penztar-client/src/stores/rateStore.ts`, `penztar-client/src/hooks/useRateUpdates.ts`
- Create/Modify: `frontend-react/src/stores/rateStore.ts` (vagy meglévő bővítése)
- Create: `frontend-react/src/hooks/useRateUpdates.ts`

- [ ] **Step 1: Átolvasni a penztar-client rate store-t**

Különösen fontos a limit-aware rate resolution logika (`getEffectiveBuyRate`, `getEffectiveSellRate`) — ez üzleti kritikus.

- [ ] **Step 2: Ellenőrizni, van-e már rate store a frontend-react-ben**

```bash
find frontend-react/src -name "*rate*" -o -name "*Rate*" | head -20
```

- [ ] **Step 3: Rate store portolása/bővítése**

Ha a frontend-react-nek van saját rate kezelése, azt kell bővíteni a limit-aware logikával. Ha nincs, a penztar-client store-ját kell adaptálni.

- [ ] **Step 4: WebSocket STOMP hook portolása**

A `useRateUpdates` hook STOMP-on keresztül real-time árfolyam frissítést kap. Ez mindkét platformon (web + Electron) hasznos.

**Függőség:** `@stomp/stompjs` + `sockjs-client` csomagok kellenek a frontend-react-ben is!

```bash
cd frontend-react && npm install @stomp/stompjs sockjs-client
```

- [ ] **Step 5: Commit**

```bash
git add frontend-react/src/stores/rateStore.ts frontend-react/src/hooks/useRateUpdates.ts frontend-react/package.json
git commit -m "feat: port rate store with limit-aware resolution and WebSocket updates"
```

---

### Task 14: Kamera, szkenner, nyomtatás komponensek portolása

**Files:**
- Source: `penztar-client/src/components/CameraRecorder.tsx`, `CameraExport.tsx`, `DocumentScanner.tsx`, `ReceiptPreviewModal.tsx`
- Source: `penztar-client/src/utils/receipt.ts`, `penztar-client/src/utils/qrcode.ts`
- Create: ugyanezek a `frontend-react/src/components/electron/` mappában

- [ ] **Step 1: Átolvasni a penztar-client komponenseket**
- [ ] **Step 2: Létrehozni `frontend-react/src/components/electron/` mappát**

Ez a mappa tartalmazza az Electron-only komponenseket. Mindegyik `isElectron()` guard-dal védi magát.

- [ ] **Step 3: Portolni a komponenseket**

Minden komponens:
- `isElectron()` guard → ha böngészőben fut, nem renderel semmit (vagy disabled állapot)
- `window.electronAPI?.` optional chaining az IPC hívásokra

- [ ] **Step 4: receipt.ts és qrcode.ts utils portolása**

```bash
cp penztar-client/src/utils/receipt.ts frontend-react/src/utils/receipt.ts
cp penztar-client/src/utils/qrcode.ts frontend-react/src/utils/qrcode.ts
```

QR kód függőség: `npm install qrcode @types/qrcode` a frontend-react-ben.

- [ ] **Step 5: Commit**

```bash
git add frontend-react/src/components/electron/ frontend-react/src/utils/receipt.ts frontend-react/src/utils/qrcode.ts frontend-react/package.json
git commit -m "feat: port camera, scanner, printer, receipt components from penztar-client"
```

---

### Task 15: App mode (pénztár/értéktár) portolása

**Files:**
- Source: `penztar-client/src/config/appMode.ts`, `penztar-client/src/hooks/useAppMode.ts`
- Create: `frontend-react/src/hooks/useAppMode.ts`

- [ ] **Step 1: Átolvasni a penztar-client implementációt**

Az app mode az Electron SQLite config store-ból olvas (`window.electronAPI.getConfig('app_mode')`). Böngészőben nincs értelme — a webes admin felület mindig teljes.

- [ ] **Step 2: Portolni a hook-ot**

```typescript
export function useAppMode() {
  // Electron-ban: SQLite-ból olvassuk a módot
  // Böngészőben: mindig 'full' (admin felület)
  if (!isElectron()) return { mode: 'full', isLoading: false };
  // ... Electron implementáció
}
```

- [ ] **Step 3: Commit**

```bash
git add frontend-react/src/hooks/useAppMode.ts
git commit -m "feat: port app mode detection (penztar/ertektar) from penztar-client"
```

---

## FÁZIS 3: Cleanup és véglegesítés

Ezek a task-ok CSAK akkor futtathatók, ha Fázis 1 és 2 KÉSZ és TESZTELVE van.

---

### Task 16: penztar-client/src/ renderer kód törlése

**Files:**
- Delete: `penztar-client/src/**/*`
- Delete: `penztar-client/index.html`
- Delete: `penztar-client/dist/`

**⚠️ DESTRUKTÍV LÉPÉS — csak ha minden más működik!**

- [ ] **Step 1: Ellenőrizni, hogy az electron/ kód nem importál src/-ból**

```bash
grep -r "from.*@/" penztar-client/electron/
grep -r "from.*src/" penztar-client/electron/
grep -r "from.*\.\./src/" penztar-client/electron/
```

Várható: nincs találat.

- [ ] **Step 2: Renderer fájlok törlése**

```bash
rm -rf penztar-client/src/
rm -f penztar-client/index.html
rm -rf penztar-client/dist/
```

- [ ] **Step 3: tsconfig.json módosítása**

Az `include` szekciójából eltávolítani `src/**/*`-ot. Csak `electron/**/*` maradjon.

- [ ] **Step 4: Commit**

```bash
git add -A penztar-client/
git commit -m "refactor: remove penztar-client renderer — frontend-react is now the sole UI"
```

---

### Task 17: Verzió bump + teljes build teszt

**Files:**
- Modify: `penztar-client/package.json` (version → 1.1.0)

- [ ] **Step 1: Verzió bump**

```json
{ "version": "1.1.0" }
```

- [ ] **Step 2: Teljes build teszt**

```bash
bash scripts/build-electron.sh
```

Várt:
- ✅ frontend-react build sikerül
- ✅ dist másolás sikerül
- ✅ Electron main+preload build sikerül
- ✅ Installer készül

- [ ] **Step 3: Működési teszt**

1. ✅ App elindul, frontend-react login képernyő
2. ✅ Bejelentkezés működik (API → backend)
3. ✅ SPA navigáció működik (`/rates`, `/sell`, `/transactions` stb.)
4. ✅ Token persist: bejelentkezés → újraindítás → automatikus bejelentkezés
5. ✅ Online/offline jelző megjelenik (Electron-ban)
6. ✅ F12 → DevTools
7. ✅ Offline sync nem dob hibát

- [ ] **Step 4: Commit**

```bash
git add penztar-client/package.json
git commit -m "chore: bump version to v1.1.0 — Electron uses frontend-react as sole UI"
```

---

## Végrehajtási sorrend és függőségek

```
FÁZIS 1 — Infrastruktúra (nem töri el a meglévő működést):

  Csoport A (frontend-react):     Task 1 → 2 → 3
  Csoport B (Electron):           Task 4, 5 (párhuzamos)
  Csoport C (Config):             Task 6 → 7, 8 (párhuzamos Task 7-tel)
  Csoport D (Infra):              Task 9, 10 (párhuzamos)

FÁZIS 2 — Penztar logika portolása (frontend-react bővítése):

  Task 11 (online/offline)        ─── Task 2 után
  Task 12 (update notifier)       ─── Task 2 után
  Task 13 (rate store + WS)       ─── Task 2 után
  Task 14 (kamera/szkenner/print) ─── Task 1, 2 után
  Task 15 (app mode)              ─── Task 2 után

  Task 11-15 egymástól FÜGGETLENEK → párhuzamosíthatók!

FÁZIS 3 — Cleanup (destruktív, csak ha F1+F2 kész):

  Task 16 (renderer törlés)       ─── Task 1-15 MIND kész + tesztelve
  Task 17 (verzió + végső teszt)  ─── Task 16 után
```

**Becsült komplexitás:**
- Fázis 1: Közepes (~10 fájl módosítás, jól definiált)
- Fázis 2: **NAGY** (~20-30 fájl portolás, üzleti logika adaptálás, tesztelés)
- Fázis 3: Egyszerű (törlés + build teszt)
