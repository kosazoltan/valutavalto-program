import 'dotenv/config';
import { app, BrowserWindow, ipcMain, dialog, protocol, net, safeStorage } from 'electron';
import log from 'electron-log/main';
import path from 'node:path';
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
import { printReceipt, type PrintReceiptData } from './printer';
import { syncEngine } from './sync-engine';
import './camera';
import './scanner';
import './updater';

const isDev = !app.isPackaged;

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
      sandbox: true,
      webSecurity: true,
      allowRunningInsecureContent: false,
      experimentalFeatures: false,
    },
  });

  if (isDev) {
    mainWindow.loadURL('http://localhost:3000');
    mainWindow.webContents.openDevTools({ mode: 'detach' });
  } else {
    // Custom 'app' protocol-on keresztül töltjük be — NEM file://-al!
    // A file:// + type="module" (ES module) Chromium CORS policy miatt üres képernyőt ad.
    mainWindow.loadURL('app://localhost/index.html');
  }

  // Renderer process hibák logolása — production-ben is lássuk mi történik
  mainWindow.webContents.on('console-message', (_event, level, message, line, sourceId) => {
    if (level >= 2) { // warning és error
      log.warn(`[Renderer] L${level} ${sourceId}:${line} — ${message}`);
    }
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
    const allowed = ['app://localhost', 'http://localhost:3000'];
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
    return await printReceipt(data);
  } catch (err) {
    console.error('[IPC] print-receipt hiba:', err);
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
      log.warn('[SafeStorage] Encryption not available, falling back to config store');
      setConfig('auth_token', token);
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
      const buffer = Buffer.from(encrypted, 'base64');
      return safeStorage.decryptString(buffer);
    }
    // Fallback: régi plaintext token (migráció)
    const plaintext = getConfig('auth_token');
    if (plaintext) {
      log.info('[SafeStorage] Migrating plaintext token to encrypted storage');
      if (safeStorage.isEncryptionAvailable()) {
        const enc = safeStorage.encryptString(plaintext);
        setConfig('auth_token_encrypted', enc.toString('base64'));
        deleteConfig('auth_token');
      }
      return plaintext;
    }
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

  createWindow();

  // SyncEngine indítás — 30 másodperces intervallum
  syncEngine.start(30_000);
  log.info('[App] SyncEngine elindítva');
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
