import { app, BrowserWindow, ipcMain } from 'electron';
import path from 'node:path';
import {
  initDatabase,
  getConfig,
  setConfig,
  deleteConfig,
  savePendingTransaction,
  getPendingTransactions,
  markTransactionSynced,
  getPendingTransactionCount,
} from './sqlite';
import { printReceipt, type PrintReceiptData } from './printer';
import { syncEngine } from './sync-engine';

const isDev = !app.isPackaged;

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
    mainWindow.loadURL('http://localhost:5173');
    mainWindow.webContents.openDevTools({ mode: 'detach' });
  } else {
    mainWindow.loadFile(path.join(__dirname, '../dist/index.html'));
  }

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

// --- App Lifecycle ---

app.whenReady().then(async () => {
  await initDatabase();
  createWindow();

  // SyncEngine indítás — 30 másodperces intervallum
  syncEngine.start(30_000);
  console.log('[App] SyncEngine elindítva');
});

app.on('will-quit', () => {
  // SyncEngine leállítás
  syncEngine.stop();
  console.log('[App] SyncEngine leállítva');
});

app.on('window-all-closed', () => {
  app.quit();
});

app.on('activate', () => {
  if (mainWindow === null) {
    createWindow();
  }
});
