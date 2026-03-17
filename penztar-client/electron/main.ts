import { app, BrowserWindow, ipcMain, dialog, protocol, net } from 'electron';
import log from 'electron-log/main';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import {
  initDatabase,
  getConfig,
  setConfig,
  deleteConfig,
  savePendingTransaction,
  getPendingTransactions,
  markTransactionSynced,
  getPendingTransactionCount,
  savePendingDistribution,
  savePendingTransfer,
  savePendingCollection,
  getCachedBranchStatuses,
  getCachedBranchStatusTimestamp,
  getCachedRates,
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
      sandbox: false,
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
  customerId: number | null,
  denominations: string | null,
): Promise<number> => {
  return savePendingTransaction(type, currencyCode, foreignAmount, hufAmount, roundedHufAmount, rate, customerId, denominations);
});

ipcMain.handle('get-pending-transactions', async (): Promise<ReturnType<typeof getPendingTransactions>> => {
  return getPendingTransactions();
});

ipcMain.handle('get-pending-transaction-count', async (): Promise<number> => {
  return getPendingTransactionCount();
});

ipcMain.handle('mark-transaction-synced', async (_event, id: number): Promise<void> => {
  markTransactionSynced(id);
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
  targetBranchCode: string,
  currencyCode: string,
  amount: number,
  denominations: string | null,
  note: string | null,
): Promise<number> => {
  return savePendingTransfer(targetBranchCode, currencyCode, amount, denominations, note);
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

ipcMain.handle('get-cached-branch-statuses', async () => {
  return getCachedBranchStatuses();
});

ipcMain.handle('get-cached-branch-status-timestamp', async () => {
  return getCachedBranchStatusTimestamp();
});

ipcMain.handle('get-cached-rates', async () => {
  return getCachedRates();
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
