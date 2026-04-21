// dotenv only in development — not bundled in production asar
// NOTE: Cannot use top-level await here — CJS output format (vite-plugin-electron/rolldown)
import('dotenv/config').catch(() => { /* production: dotenv not available, safe to skip */ });
import { app, BrowserWindow, ipcMain, dialog, protocol, net, safeStorage, session } from 'electron';
import { initAutoUpdate } from './auto-update';
import { release as getOsRelease } from 'node:os';

// Windows 11 Insider (26200+) sandbox compatibility fix — CONDITIONAL
// Only disable sandbox on affected Windows Insider builds (26200+).
// Normal Windows 10/11 keeps sandbox enabled for security.
const osRelease = getOsRelease(); // e.g. "10.0.26200"
const osBuild = parseInt(osRelease.split('.')[2] || '0', 10);
if (osBuild >= 26200) {
  app.commandLine.appendSwitch('no-sandbox');
  app.commandLine.appendSwitch('disable-gpu-sandbox');
}
import log from 'electron-log/main';
import path from 'node:path';
import fs from 'node:fs';
import { pathToFileURL } from 'node:url';
import {
  initDatabase,
  getConfig,
  setConfig,
  deleteConfig,
  savePendingTransaction,
  savePendingConversion,
  savePendingBankTransaction,
  savePendingStorno,
  getPendingTransactions,
  getPendingConversions,
  getPendingBankTransactions,
  getPendingStornos,
  markTransactionSynced,
  markConversionSynced,
  markBankTransactionSynced,
  markStornoSynced,
  getPendingTransactionCount,
  savePendingDistribution,
  savePendingTransfer,
  savePendingCollection,
  getPendingTransfers,
  savePendingHandoverOperation,
  getPendingHandoverOperations,
  saveLocalAuditEvent,
  getLocalAuditEvents,
  getCachedBranchStatuses,
  getCachedBranchStatusTimestamp,
  getCachedRates,
  getCachedCashDesks,
  getCachedCashDeskTimestamp,
  getCachedWorkers,
  getCachedWorkerTimestamp,
} from './sqlite';
import { printReceipt, type PrintReceiptData, PRINTER_CONFIG_KEY, SERIAL_PORT_CONFIG_KEY } from './printer';
import { syncEngine } from './sync-engine';
import { registerCameraHandlers } from './camera';
import { registerVideoManagerHandlers } from './video-manager';
import { registerScannerHandlers } from './scanner';
import { registerUpdaterHandlers } from './updater';
import {
  isFirstRun,
  getBranches,
  testConnection,
  saveSetupConfig,
  type SetupSavePayload,
} from './first-run';

const isDev = !app.isPackaged && !process.argv.includes('--force-packaged') && process.env.ELECTRON_FORCE_PACKAGED !== '1';
const devServerUrl = process.env.ELECTRON_RENDERER_URL ?? 'http://127.0.0.1:3000';

const devUserDataDir = process.env.ELECTRON_DEV_USER_DATA;
const shouldAutoOpenDevTools =
  isDev && ['1', 'true', 'yes', 'on'].includes((process.env.ELECTRON_OPEN_DEVTOOLS ?? '').toLowerCase());

// Force a local writable profile/cache path when ELECTRON_DEV_USER_DATA is set (dev or E2E test).
if (devUserDataDir) {
  app.commandLine.appendSwitch('user-data-dir', devUserDataDir);
  app.setPath('userData', devUserDataDir);
  app.setPath('sessionData', path.join(devUserDataDir, 'session'));
  app.commandLine.appendSwitch('disk-cache-dir', path.join(devUserDataDir, 'cache'));
  app.commandLine.appendSwitch('disable-gpu-shader-disk-cache');
}

// Custom 'app' protocol regisztráció — MUSZÁJ app.whenReady() ELŐTT lennie!
// Ez megoldja a file:// + ES module CORS problémát, ami üres képernyőt okoz.
protocol.registerSchemesAsPrivileged([
  {
    scheme: 'app',
    privileges: {
      standard: true,
      secure: true,
      supportFetchAPI: true,
      corsEnabled: true,
      stream: true,
    },
  },
]);

log.initialize();
log.transports.file.level = 'info';
log.transports.console.level = isDev ? 'debug' : 'warn';

process.on('uncaughtException', (err) => {
  log.error('[Process] uncaughtException', err);
});

process.on('unhandledRejection', (reason) => {
  log.error('[Process] unhandledRejection', reason as Error);
});

let mainWindow: BrowserWindow | null = null;

function createWindow(): void {
  mainWindow = new BrowserWindow({
    width: 1280,
    height: 1024,
    resizable: isDev,
    fullscreen: false,
    autoHideMenuBar: true,
    title: 'Valuta Pénztár',
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: osBuild < 26200, // Sandbox ON normal Windows-on, OFF Insider 26200+ builden
      webSecurity: true,
      allowRunningInsecureContent: false,
      experimentalFeatures: false,
    },
  });

  if (isDev) {
    log.info(`[App] Dev renderer URL: ${devServerUrl}`);
    const loadDevUrlWithRetry = async (): Promise<void> => {
      const retries = 20;
      for (let i = 0; i < retries; i += 1) {
        try {
          await mainWindow?.loadURL(devServerUrl);
          return;
        } catch (err) {
          const message = err instanceof Error ? err.message : String(err);
          log.warn(`[DevLoad] attempt ${i + 1}/${retries} failed: ${message}`);
          await new Promise((resolve) => setTimeout(resolve, 500));
        }
      }
      dialog.showErrorBox(
        'Fejlesztői indítási hiba',
        `A renderer nem tudott csatlakozni a dev szerverhez: ${devServerUrl}\n\n` +
        'Ellenőrizze, hogy a Vite szerver fut-e, majd indítsa újra az alkalmazást.',
      );
    };

    void loadDevUrlWithRetry();
    if (shouldAutoOpenDevTools) {
      mainWindow.webContents.openDevTools({ mode: 'detach' });
    }
  } else {
    // Custom 'app' protocol-on keresztül töltjük be — NEM file://-al!
    // A file:// + type="module" (ES module) Chromium CORS policy miatt üres képernyőt ad.
    mainWindow.loadURL('app://localhost/');
  }

  // Renderer process hibák logolása — production-ben is lássuk mi történik
  mainWindow.webContents.on('console-message', (_event, level, message, line, sourceId) => {
    if (level >= 2) { // warning és error
      log.warn(`[Renderer] L${level} ${sourceId}:${line} — ${message}`);
    }
  });

  mainWindow.webContents.on('did-fail-load', (_event, errorCode, errorDescription, validatedURL) => {
    log.error(`[Renderer] did-fail-load ${errorCode} ${errorDescription} @ ${validatedURL}`);
  });

  // Ha a renderer process crash-el, jelenjen meg hibaüzenet
  mainWindow.webContents.on('render-process-gone', (_event, details) => {
    log.error('[Renderer] Process gone:', details.reason);
    dialog.showErrorBox(
      'Megjelenítési hiba',
      `A program megjelenítő folyamata leállt.\nOk: ${details.reason}\n\nKérjük, indítsa újra az alkalmazást.`,
    );
  });

  // F12 → DevTools bármikor (hibakereséshez)
  mainWindow.webContents.on('before-input-event', (_event, input) => {
    if (input.key === 'F12' && input.type === 'keyDown') {
      mainWindow?.webContents.toggleDevTools();
    }
  });

  // Security: blokkolja az ismeretlen URL-ekre való navigálást (XSS/phishing védelem)
  mainWindow.webContents.on('will-navigate', (event, url) => {
    const allowed = ['app://localhost', devServerUrl];
    if (!allowed.some(origin => url.startsWith(origin))) {
      log.warn(`[Security] Blocked navigation to: ${url}`);
      event.preventDefault();
    }
  });

  // Security: blokkolja a popup ablakokat (XSS redirect védelem)
  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    log.warn(`[Security] Blocked popup window: ${url}`);
    return { action: 'deny' };
  });

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

// --- IPC Handlers ---

ipcMain.handle('print-receipt', async (_event, dataJson: string): Promise<boolean> => {
  try {
    const data = JSON.parse(dataJson) as PrintReceiptData;
    const printerName = getConfig(PRINTER_CONFIG_KEY) ?? undefined;
    const serialPort = getConfig(SERIAL_PORT_CONFIG_KEY) ?? undefined;
    return await printReceipt(data, printerName, serialPort);
  } catch (err) {
    console.error('[IPC] print-receipt hiba:', err);
    return false;
  }
});

ipcMain.handle('list-serial-ports', async (): Promise<unknown[]> => {
  try {
    const { listSerialPorts } = await import('./serial-printer');
    return await listSerialPorts();
  } catch (err) {
    console.error('[IPC] list-serial-ports hiba:', err);
    return [];
  }
});

ipcMain.handle('open-cash-drawer', async (): Promise<boolean> => {
  try {
    const serialPort = getConfig(SERIAL_PORT_CONFIG_KEY);
    if (!serialPort) return false;
    const { openCashDrawer } = await import('./serial-printer');
    return await openCashDrawer({ port: serialPort });
  } catch (err) {
    console.error('[IPC] open-cash-drawer hiba:', err);
    return false;
  }
});

ipcMain.handle('get-config', async (_event, key: string): Promise<string | null> => {
  return getConfig(key);
});

ipcMain.handle('set-config', async (_event, key: string, value: string): Promise<void> => {
  setConfig(key, value);
});

ipcMain.handle('delete-config', async (_event, key: string): Promise<void> => {
  deleteConfig(key);
});

// --- First-Run Setup Wizard IPC ---
ipcMain.handle('setup:check', async () => {
  return isFirstRun();
});

ipcMain.handle('setup:branches', async (
  _event,
  params?: { apiUrl?: string; companyCode?: string },
) => {
  return await getBranches(params?.apiUrl, params?.companyCode);
});

ipcMain.handle('setup:test-connection', async (
  _event,
  params: { apiUrl: string; companyCode: string; username: string; password: string },
) => {
  return await testConnection(params.apiUrl, params.companyCode, params.username, params.password);
});

ipcMain.handle('setup:save', async (_event, payload: SetupSavePayload) => {
  return await saveSetupConfig(payload);
});

ipcMain.handle('save-pending-transaction', async (
  _event,
  type: 'SELL' | 'BUY',
  currencyCode: string,
  foreignAmount: number,
  hufAmount: number,
  roundedHufAmount: number,
  rate: number,
  handlingFee: number | null,
  discountPercent: number | null,
  customerIdentifier: string | null,
  customerName: string | null,
  customerDocumentNumber: string | null,
  customerAddress: string | null,
  denominations: string | null,
  sourceOfFunds: string | null,
  customerIsPep: boolean | null,
): Promise<number> => {
  return savePendingTransaction(
    type,
    currencyCode,
    foreignAmount,
    hufAmount,
    roundedHufAmount,
    rate,
    handlingFee,
    discountPercent,
    customerIdentifier,
    customerName,
    customerDocumentNumber,
    customerAddress,
    denominations,
    sourceOfFunds,
    customerIsPep,
  );
});

ipcMain.handle('get-pending-transactions', async (): Promise<ReturnType<typeof getPendingTransactions>> => {
  return getPendingTransactions();
});

ipcMain.handle('save-pending-conversion', async (
  _event,
  fromCurrencyId: number | null,
  fromCurrencyCode: string,
  toCurrencyId: number | null,
  toCurrencyCode: string,
  fromAmount: number,
  calculatedHufAmount: number,
  calculatedToAmount: number,
  conversionRate: number,
  handlingFee: number | null,
  customerId: string | null,
  customerName: string | null,
  customerDocumentNumber: string | null,
  note: string | null,
): Promise<number> => {
  return savePendingConversion(
    fromCurrencyId,
    fromCurrencyCode,
    toCurrencyId,
    toCurrencyCode,
    fromAmount,
    calculatedHufAmount,
    calculatedToAmount,
    conversionRate,
    handlingFee,
    customerId,
    customerName,
    customerDocumentNumber,
    note,
  );
});

ipcMain.handle('get-pending-conversions', async (): Promise<ReturnType<typeof getPendingConversions>> => {
  return getPendingConversions();
});

ipcMain.handle('save-pending-bank-transaction', async (
  _event,
  transactionType: 'BUY' | 'SELL',
  currencyCode: string,
  amount: number,
  exchangeRate: number,
  hufAmount: number,
  vaultTerritoryId: number | null,
  bankName: string | null,
  bankReference: string | null,
  note: string | null,
): Promise<number> => {
  return savePendingBankTransaction(
    transactionType,
    currencyCode,
    amount,
    exchangeRate,
    hufAmount,
    vaultTerritoryId,
    bankName,
    bankReference,
    note,
  );
});

ipcMain.handle('get-pending-bank-transactions', async (): Promise<ReturnType<typeof getPendingBankTransactions>> => {
  return getPendingBankTransactions();
});

ipcMain.handle('save-pending-storno', async (_event, payload: {
  transactionId: number;
  originalReceiptNumber: string;
  originalTransactionType: string;
  currencyCode: string;
  foreignAmount: number | null;
  hufAmount: number;
  exchangeRate: number | null;
  reason: string;
  approvalId?: string | null;
  customExchangeRate?: number | null;
  paymentMethod?: string | null;
  customerName?: string | null;
  customerDocumentNumber?: string | null;
}): Promise<number> => {
  return savePendingStorno(payload);
});

ipcMain.handle('get-pending-stornos', async (): Promise<ReturnType<typeof getPendingStornos>> => {
  return getPendingStornos();
});

ipcMain.handle('get-pending-transaction-count', async (): Promise<number> => {
  return getPendingTransactionCount();
});

ipcMain.handle('mark-transaction-synced', async (_event, id: number): Promise<void> => {
  markTransactionSynced(id);
});

ipcMain.handle('mark-conversion-synced', async (_event, id: number): Promise<void> => {
  markConversionSynced(id);
});

ipcMain.handle('mark-bank-transaction-synced', async (_event, id: number): Promise<void> => {
  markBankTransactionSynced(id);
});

ipcMain.handle('mark-storno-synced', async (_event, id: number): Promise<void> => {
  markStornoSynced(id);
});

ipcMain.handle('sync-offline', async (): Promise<number> => {
  // SyncEngine-en keresztül szinkronizálunk
  const result = await syncEngine.syncAll();
  return result.synced;
});

ipcMain.handle('get-sync-status', async (): Promise<string> => {
  return JSON.stringify(syncEngine.getStatus());
});

ipcMain.handle('get-app-version', async (): Promise<string> => {
  return app.getVersion();
});

ipcMain.handle('get-printers', async (): Promise<Electron.PrinterInfo[]> => {
  if (!mainWindow) return [];
  return mainWindow.webContents.getPrintersAsync();
});

// --- Értéktár Offline IPC Handlers ---

ipcMain.handle('save-pending-distribution', async (
  _event,
  targetBranchCode: string,
  currencyCode: string,
  amount: number,
  denominations: string | null,
  note: string | null,
): Promise<number> => {
  return savePendingDistribution(targetBranchCode, currencyCode, amount, denominations, note);
});

ipcMain.handle('save-pending-transfer', async (
  _event,
  targetBranchId: string | null,
  targetBranchCode: string,
  currencyId: number | null,
  currencyCode: string,
  amount: number,
  hufValue: number | null,
  transferType: string | null,
  denominations: string | null,
  note: string | null,
): Promise<number> => {
  return savePendingTransfer(targetBranchId, targetBranchCode, currencyId, currencyCode, amount, hufValue, transferType, denominations, note);
});

ipcMain.handle('get-pending-transfers', async (): Promise<ReturnType<typeof getPendingTransfers>> => {
  return getPendingTransfers();
});

ipcMain.handle('save-pending-collection', async (
  _event,
  sourceBranchCode: string,
  currencyCode: string,
  amount: number,
  note: string | null,
): Promise<number> => {
  return savePendingCollection(sourceBranchCode, currencyCode, amount, note);
});

ipcMain.handle('save-pending-handover-operation', async (_event, payload: {
  operationType: 'GENERATE' | 'PRINT' | 'COMPLETE';
  sheetId?: string | null;
  fromCashDeskId?: string | null;
  toCashDeskId?: string | null;
  transferDate?: string | null;
  amounts?: unknown;
  note?: string | null;
}): Promise<number> => {
  return savePendingHandoverOperation(payload);
});

ipcMain.handle('get-pending-handover-operations', async (): Promise<ReturnType<typeof getPendingHandoverOperations>> => {
  return getPendingHandoverOperations();
});

ipcMain.handle('get-cached-branch-statuses', async () => {
  return getCachedBranchStatuses();
});

ipcMain.handle('get-cached-branch-status-timestamp', async () => {
  return getCachedBranchStatusTimestamp();
});

ipcMain.handle('get-cached-rates', async () => {
  return getCachedRates();
});

ipcMain.handle('get-cached-cash-desks', async () => {
  return getCachedCashDesks();
});

ipcMain.handle('get-cached-cash-desk-timestamp', async () => {
  return getCachedCashDeskTimestamp();
});

ipcMain.handle('get-cached-workers', async () => {
  return getCachedWorkers();
});

ipcMain.handle('get-cached-worker-timestamp', async () => {
  return getCachedWorkerTimestamp();
});

ipcMain.handle('save-local-audit-event', async (_event, payload: {
  entityType: string;
  eventType: string;
  referenceNumber?: string | null;
  entityId?: string | null;
  payload: unknown;
  customerSnapshot?: unknown;
  identificationSnapshot?: unknown;
  rateSnapshot?: unknown;
  status?: string;
  retentionDays?: number;
}): Promise<number> => {
  return saveLocalAuditEvent(payload);
});

ipcMain.handle('get-local-audit-events', async (_event, limit?: number) => {
  return getLocalAuditEvents(limit ?? 200);
});

// --- Secure Token Storage (safeStorage — Windows DPAPI / macOS Keychain / Linux libsecret) ---

ipcMain.handle('secure-store-token', async (_event, token: string): Promise<boolean> => {
  try {
    if (!safeStorage.isEncryptionAvailable()) {
      log.warn('[SafeStorage] Encryption not available — token stored in-memory only, NOT persisted to disk');
      // Security: NEM mentjuk plaintext-ben a diskre. Csak session-szintu valtozo.
      (global as Record<string, unknown>).__volatile_auth_token = token;
      return true;
    }
    const encrypted = safeStorage.encryptString(token);
    setConfig('auth_token_encrypted', encrypted.toString('base64'));
    // Régi plaintext token törlése (migráció)
    deleteConfig('auth_token');
    return true;
  } catch (err) {
    log.error('[SafeStorage] store-token error:', err);
    return false;
  }
});

ipcMain.handle('secure-load-token', async (): Promise<string | null> => {
  try {
    // Először a titkosított tokent próbáljuk
    const encrypted = getConfig('auth_token_encrypted');
    if (encrypted && safeStorage.isEncryptionAvailable()) {
      try {
        const buffer = Buffer.from(encrypted, 'base64');
        return safeStorage.decryptString(buffer);
      } catch (err) {
        // Corrupted token from another machine/user profile or old encryption context.
        log.warn('[SafeStorage] Corrupted encrypted token removed');
        deleteConfig('auth_token_encrypted');
      }
    }
    // Fallback: régi plaintext token (migráció) — torlés + encrypt
    const plaintext = getConfig('auth_token');
    if (plaintext) {
      log.info('[SafeStorage] Migrating plaintext token to encrypted storage');
      deleteConfig('auth_token'); // AZONNAL torlés — ne maradjon plaintext a DB-ben
      if (safeStorage.isEncryptionAvailable()) {
        const enc = safeStorage.encryptString(plaintext);
        setConfig('auth_token_encrypted', enc.toString('base64'));
      }
      return plaintext;
    }
    // In-memory volatile fallback (safeStorage nem elerheto)
    const volatile = (global as Record<string, unknown>).__volatile_auth_token;
    if (typeof volatile === 'string') return volatile;
    return null;
  } catch (err) {
    log.error('[SafeStorage] load-token error:', err);
    return null;
  }
});

ipcMain.handle('secure-clear-token', async (): Promise<void> => {
  deleteConfig('auth_token_encrypted');
  deleteConfig('auth_token');
});

// --- App Lifecycle ---

app.whenReady().then(async () => {
  if (isDev) {
    const devCsp = [
      "default-src 'self' app: data: blob: http: https:",
      "script-src 'self' 'unsafe-inline' http: https:",
      "style-src 'self' 'unsafe-inline' http: https:",
      "img-src 'self' data: blob: http: https:",
      "font-src 'self' data: http: https:",
      "connect-src 'self' data: blob: http: https: ws: wss:",
      "worker-src 'self' blob:",
      "object-src 'none'",
      "base-uri 'self'",
      "frame-ancestors 'none'",
    ].join('; ');

    session.defaultSession.webRequest.onHeadersReceived((details, callback) => {
      const headers = details.responseHeaders ?? {};
      callback({
        responseHeaders: {
          ...headers,
          'Content-Security-Policy': [devCsp],
        },
      });
    });
  }

  // IPC handlers regisztráció (app.whenReady() UTÁN, hogy ipcMain elérhető legyen)
  registerCameraHandlers();
  registerVideoManagerHandlers();
  registerScannerHandlers();
  registerUpdaterHandlers();

  // Custom 'app' protocol handler regisztráció
  // Ez a dist/ mappából szolgálja ki a fájlokat, mint egy webszerver
  const distPath = path.join(__dirname, '../dist');
  protocol.handle('app', (req) => {
    const url = new URL(req.url);
    let filePath = path.join(distPath, decodeURIComponent(url.pathname));

    // Ha gyökér kérés, index.html-t adjunk vissza
    if (url.pathname === '/' || url.pathname === '') {
      filePath = path.join(distPath, 'index.html');
    }

    // SPA fallback: ha nincs fájl kiterjesztés → index.html (React Router route)
    // Assets-nek mindig van kiterjesztése: .js, .css, .png, .svg stb.
    const hasExtension = path.extname(filePath) !== '';
    if (!hasExtension) {
      filePath = path.join(distPath, 'index.html');
    }

    // Path traversal védelem — a resolved path MUSZÁJ distPath-on belül maradjon
    const resolved = path.resolve(filePath);
    const resolvedDist = path.resolve(distPath);
    if (!resolved.startsWith(resolvedDist + path.sep) && resolved !== resolvedDist) {
      log.warn(`[Protocol] Path traversal blokkolva: ${req.url} → ${resolved}`);
      filePath = path.join(distPath, 'index.html');
    }

    log.info(`[Protocol] ${req.url} → ${filePath}`);
    return net.fetch(pathToFileURL(filePath).toString());
  });
  log.info('[App] Custom "app" protocol regisztrálva, distPath:', distPath);

  try {
    await initDatabase();
  } catch (err) {
    log.error('[App] initDatabase failed', err);
    const details = err instanceof Error ? err.message : String(err);
    dialog.showErrorBox(
      'Adatbázis hiba',
      `A helyi adatbázist nem sikerült inicializálni.\n\nRészletek:\n${details}`,
    );
    app.quit();
    return;
  }

  // v2.1.6 Auto-migration: regebbi SetupWizard verziok (v2.1.3 elott) NEM irtak
  // be a branch_code-ot az SQLite config tablaba, csak a .env-be.
  //
  // AI REVIEW FIX (PR #97 Codex P1): packaged Electron appban a dotenv CSAK dev modban
  // fut le (main.ts:3: import('dotenv/config').catch(...)). Production buildben a
  // process.env NEM tartalmazza a VITE_BRANCH_CODE-ot - az userData/.env-bol kell olvasni.
  const readPersistedEnv = (): Record<string, string> => {
    try {
      const envPath = path.join(app.getPath("userData"), ".env");
      if (!fs.existsSync(envPath)) return {};
      const raw = fs.readFileSync(envPath, "utf8");
      const out: Record<string, string> = {};
      for (const rawLine of raw.split(/\r?\n/)) {
        const line = rawLine.trim();
        if (!line || line.startsWith("#")) continue;
        const eq = line.indexOf("=");
        if (eq <= 0) continue;
        const key = line.slice(0, eq).trim();
        let value = line.slice(eq + 1).trim();
        if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
          value = value.slice(1, -1);
        }
        out[key] = value;
      }
      return out;
    } catch {
      return {};
    }
  };
  const persistedEnv = readPersistedEnv();
  const envBranchCode = (process.env.VITE_BRANCH_CODE ?? persistedEnv.VITE_BRANCH_CODE ?? "").trim();
  const envCompanyCode = (process.env.VITE_COMPANY_CODE ?? process.env.PENZTAR_BOOTSTRAP_COMPANY_CODE
    ?? persistedEnv.VITE_COMPANY_CODE ?? persistedEnv.PENZTAR_BOOTSTRAP_COMPANY_CODE ?? "").trim();
  const envApiUrl = (process.env.VITE_API_URL ?? persistedEnv.VITE_API_URL ?? "").trim();

  try {
    const existingBranchCode = getConfig("branch_code");
    if (!existingBranchCode) {
      if (envBranchCode) {
        setConfig("branch_code", envBranchCode);
        log.info(`[App] Auto-migration: branch_code='${envBranchCode}' atmasolva a .env-bol az SQLite config-ba.`);
      } else {
        log.warn("[App] branch_code hianyzik az SQLite config-bol ES a .env VITE_BRANCH_CODE-bol is. A tranzakciok elszalnak - futtasd a SetupWizardot vagy toltsd ki a .env-et.");
      }
    }
    const existingCompany = getConfig("bootstrap_company_code");
    if (!existingCompany && envCompanyCode) {
      setConfig("bootstrap_company_code", envCompanyCode);
      log.info(`[App] Auto-migration: bootstrap_company_code='${envCompanyCode}' atmasolva a .env-bol.`);
    }
  } catch (migrationErr) {
    log.warn("[App] Auto-migration warning (nem kritikus):", migrationErr);
  }

  // v2.1.6 Production-first alaptorveny: TILOS lokalis divergens fejlesztes.
  // Dev modban is a VITE_API_URL-t hasznaljuk (default: Hetzner production).
  {
    const currentServerUrl = getConfig("server_url");
    if (envApiUrl && currentServerUrl !== envApiUrl) {
      setConfig("server_url", envApiUrl);
      log.info(`[App] server_url szinkronizalva a .env VITE_API_URL-rel: ${envApiUrl}`);
    } else if (!currentServerUrl) {
      setConfig("server_url", "https://excvaluta.com/api/v1");
      log.info("[App] server_url default: https://excvaluta.com/api/v1 (Hetzner production)");
    }
  }

  createWindow();

  // SyncEngine indítás — 30 másodperces intervallum
  syncEngine.start(30_000);
  log.info('[App] SyncEngine elindítva');

  // Electron auto-update (vezerlokonyv par.29)
  if (app.isPackaged) {
    initAutoUpdate(mainWindow);
  } else {
    log.info('[App] Auto-update kihagyva (dev mode)');
  }
});

app.on('will-quit', () => {
  // SyncEngine leállítás
  syncEngine.stop();
  log.info('[App] SyncEngine leállítva');
});

app.on('window-all-closed', () => {
  app.quit();
});

app.on('activate', () => {
  if (mainWindow === null) {
    createWindow();
  }
});
