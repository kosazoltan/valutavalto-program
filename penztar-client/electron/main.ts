// dotenv only in development — not bundled in production asar
// NOTE: Cannot use top-level await here — CJS output format (vite-plugin-electron/rolldown)
import('dotenv/config').catch(() => {
  /* production: dotenv not available, safe to skip */
});
import {
  app,
  BrowserWindow,
  ipcMain,
  dialog,
  protocol,
  net,
  safeStorage,
  session,
  Menu,
} from 'electron';
import { initSuiteUpdate } from './suite-update';
import { migrateLocalBackendConfigOnStartup } from './local-backend-config-migration';
import { createBeforeInputHandler } from './input-guard';
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

// v2.5.13 NEM-INFORMATIKUS-FELHASZNALO ALAPELV: a Penztar-on belul AUTOMATIKUSAN
// minden hibatuneti kornyezetet kompenzalunk, hogy a felhasznalonak SOHA ne kelljen
// parancssort, ESET-config-ot vagy DNS-flush-t kezzel csinalnia.
//
// Borsi-tunet (2026-05-04 diagnosztika v2): IPv4 OK, IPv6 timeout -> a DNS HappyEyeballs
// algoritmus IPv6-ot probal eloszor, 8 sec-os timeoutok jonnek.
// FIX: a Chromium host-resolver-rules-szel az `excvaluta.com`-ra IPv4-only-t kenyszeritjuk.
// Server-oldali Cloudflare AAAA-rekord automatikus kikapcsolasa is MAR megtortent
// (CF API-n keresztul, 2026-05-05), de defensive client-szintu vedelem is kell.
//
// Plus: defensive TLS-hardening (ECH disable + HTTP/1.1 force) - barmilyen
// AV/firewall-szintu rontas ellen.
//
// Hivatkozas:
//   - https://www.electronjs.org/docs/latest/api/command-line-switches
//   - https://chromium.googlesource.com/chromium/src/+/master/net/dns/README.md
//   - electron/electron#28991 - ESET TLS 1.3 + Cloudflare incompatibility
app.commandLine.appendSwitch('disable-features', 'EncryptedClientHello');
app.commandLine.appendSwitch('disable-http2');
// Megj.: az IPv4-only force-ot a SERVER-oldali Cloudflare IPv6 OFF (2026-05-05 user-direktiva
// alapjan API-n keresztul beallitva) biztositja - innentol az `excvaluta.com` DNS valasza
// CSAK A rekordokat tartalmaz, AAAA NINCS. Igy a HappyEyeballs kotelezo IPv4-en megy.
// Client-szintu `host-resolver-rules EXCLUDE`-ot NEM hasznaljuk, mert a Chromium ott
// system-resolver-re fall-back-el, ami a Windows-szintu IPv6 preferenciat orokli.
import log from 'electron-log/main';
import path from 'node:path';
import fs from 'node:fs';
import { pathToFileURL } from 'node:url';
import {
  IPC_CHANNELS,
  type PendingCircularReplyInput,
  type PendingHandoverOperationInput,
  type PendingShipmentReceiptInput,
  type PendingStornoInput,
  type PendingTransferStornoInput,
  type QueueScannedDocumentInput,
  type SetupWorkerOption,
  type SetupWorkersRequest,
} from '@valuta/shared-ipc';
import {
  initDatabase,
  getConfig,
  setConfig,
  deleteConfig,
  savePendingTransaction,
  savePendingTransactionV2,
  type PendingTransactionInputV2,
  savePendingConversion,
  savePendingConversionV2,
  type PendingConversionInputV2,
  savePendingBankTransaction,
  savePendingStorno,
  savePendingTransferStorno,
  savePendingShipmentReceipt,
  savePendingCircularReply,
  savePendingScannedDocument,
  getPendingTransferStornos,
  getShipmentReceiptOutboxState,
  getPendingTransactions,
  getPendingTransactionRefById,
  getPendingTransferRefById,
  getPendingConversions,
  getPendingBankTransactions,
  getPendingStornos,
  getReprintableTransactions,
  getReprintableConversions,
  getReprintableStornos,
  markTransactionSynced,
  markConversionSynced,
  markBankTransactionSynced,
  markStornoSynced,
  getPendingTransactionCount,
  getUnsyncedSummary,
  factoryResetLocalDatabase,
  type UnsyncedSummary,
  type FactoryResetResult,
  savePendingDistribution,
  savePendingTransfer,
  savePendingCollection,
  queueStocktakeCount,
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
import {
  printReceiptWithStoredConfig,
  type PrintReceiptData,
  SERIAL_PORT_CONFIG_KEY,
} from './printer';
import { syncEngine } from './sync-engine';
import { isConfigKeyReadable, isConfigKeyWritable } from './config-guard';
import { registerCameraHandlers } from './camera';
import { registerVideoManagerHandlers } from './video-manager';
import { registerScannerHandlers, SCAN_DIR } from './scanner';
import { assertInsideBase, validateDocumentType } from './path-guard';
import { registerUpdaterHandlers } from './updater';
import {
  performGoogleOAuthFlow,
  performGoogleOAuthFlowWithBackendLogin,
  performPasswordLoginMainProcess,
  GoogleOAuthFailedException,
} from './google-oauth';
import { initErrorReporter, reportError, setUserIdentifier } from './error-reporter';
import { fetchViaElectronNetWithRetry, type ApiProxyRequest } from './api-proxy';
import {
  createCustomerDisplay,
  updateCustomerDisplay,
  hideCustomerDisplay,
  isCustomerDisplayActive,
  type CustomerDisplayPayload,
} from './customer-display';
import {
  assertSetupAllowed,
  isFirstRun,
  getBranches,
  getWorkers,
  testConnection,
  saveSetupConfig,
  type SetupSavePayload,
} from './first-run';
import {
  decideApiUrl,
  promoteUserDataEnv,
  createMediaPermissionHandler,
} from '../../packages/electron-platform/src';

// SSOT (2026-04-24): Production URL config lazy-load
// Packaged app: process.resourcesPath/production-urls.json (electron-builder extraResources)
// Dev: ../../config/production-urls.json relative a dist-electron-hez
function loadProductionUrls(): { api_url: string; base_url: string; domain: string } {
  const packagedPath = path.join(process.resourcesPath, 'production-urls.json');
  const devPath = path.join(__dirname, '..', '..', 'config', 'production-urls.json');
  const configPath = app.isPackaged ? packagedPath : devPath;
  try {
    const raw = fs.readFileSync(configPath, 'utf8');
    const cfg = JSON.parse(raw);
    return { api_url: cfg.api_url, base_url: cfg.base_url, domain: cfg.domain };
  } catch (err) {
    // Sourcery PR #173: fallback csak EMERGENCY (packaged build-ben nem terjedhetne ide,
    // mert az extraResources kotelezi a production-urls.json-t). Ha megis ide jutunk,
    // biztositjuk, hogy legalabb egy ismert-jo default-tal ujrainduljon az app.
    // Ez NEM SSOT violation - ez szandekos duplikacio utolso menedekkent.
    // AI review (Sourcery PR #174): full error object logging, hogy a stack trace megmaradjon
    log.error(
      `[ProductionUrls] CRITICAL: config load failed (${configPath}). Fallback to hardcoded defaults - ez a build-csomag serult!`,
      err,
    );
    return {
      api_url: 'https://excvaluta.com/api/v1',
      base_url: 'https://excvaluta.com',
      domain: 'excvaluta.com',
    };
  }
}

/**
 * A hasznalando API base URL.
 *
 * VISELKEDES-MEGORZES (platform-refaktor 3. kor): a `fallback` szandekosan
 * EAGER modon szamolodik ki, meg ervenyes `server_url` eseten is — a
 * `loadProductionUrls()` serult csomagnal `log.error` CRITICAL-t ir, es ez a
 * megfigyelheto mellekhatas a penztar-kliensben ELVART. Lusta thunk-ra
 * cserelve a log csendben eltunne.
 *
 * A DONTES a platform `decideApiUrl`-jebol jon; a fallback-agak logolasa
 * kliens-specifikus (a kozponti/arfolyam NEM logol itt).
 */
function resolveConfiguredApiUrl(): string {
  const fallback = loadProductionUrls().api_url;
  // A `getConfig` a sql.js DB-t olvassa (`db.prepare`), ami serult adatbazisnal
  // DOBHAT. Az eredeti implementacio try-blokkja ezt is lefedte, ezert a
  // hivas itt is vedve marad — kulonben serult DB eseten a fallback helyett
  // kivetel szallna fel (viselkedes-valtozas).
  let configured: string | null;
  try {
    configured = getConfig('server_url');
  } catch (err) {
    log.warn(
      '[App] server_url invalid, fallback production URL:',
      err instanceof Error ? err.message : String(err),
    );
    return fallback;
  }
  const decision = decideApiUrl(configured);
  if (decision.kind === 'configured') return decision.url;
  if (decision.reason === 'invalid-protocol') {
    log.warn('[App] server_url invalid protocol, fallback production URL:', decision.detail);
  } else if (decision.reason === 'parse-error') {
    log.warn('[App] server_url invalid, fallback production URL:', decision.detail);
  }
  return fallback;
}

const isDev =
  !app.isPackaged &&
  !process.argv.includes('--force-packaged') &&
  process.env.ELECTRON_FORCE_PACKAGED !== '1';
const devServerUrl = process.env.ELECTRON_RENDERER_URL ?? 'http://127.0.0.1:3000';

const devUserDataDir = process.env.ELECTRON_DEV_USER_DATA;
const shouldAutoOpenDevTools =
  isDev &&
  ['1', 'true', 'yes', 'on'].includes((process.env.ELECTRON_OPEN_DEVTOOLS ?? '').toLowerCase());

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

// ===========================================================================
// Singleton instance lock (Sprint fix: 12+ electron process eseten)
// ===========================================================================
// Ha mar fut egy penztar-client instance, a masodik indulas azonnal kilep,
// es az elso ablakot hozza elotertbe. Ez megszunteti a multi-process bloat-ot
// (12 electron process, 3 main window cacheloda al a Task Manager-ben).
const gotTheLock = app.requestSingleInstanceLock();
if (!gotTheLock) {
  log.info('[Electron] Mar fut egy penztar-client instance, exit.');
  app.quit();
  process.exit(0);
}

app.on('second-instance', (_event, _commandLine, _workingDirectory) => {
  // Masodik indulaskor: az elso ablakot hozza elotertbe es focus-olja
  const allWindows = BrowserWindow.getAllWindows();
  const mainWin = allWindows.length > 0 ? allWindows[0] : undefined;
  if (mainWin) {
    if (mainWin.isMinimized()) mainWin.restore();
    mainWin.focus();
    log.info('[Electron] Second-instance blocked, focused existing window.');
  } else {
    log.warn('[Electron] Second-instance event, but no main window found.');
  }
});

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
    if (level >= 2) {
      // warning és error
      log.warn(`[Renderer] L${level} ${sourceId}:${line} — ${message}`);
    }
  });

  mainWindow.webContents.on(
    'did-fail-load',
    (_event, errorCode, errorDescription, validatedURL) => {
      log.error(`[Renderer] did-fail-load ${errorCode} ${errorDescription} @ ${validatedURL}`);
    },
  );

  // Ha a renderer process crash-el, jelenjen meg hibaüzenet
  mainWindow.webContents.on('render-process-gone', (_event, details) => {
    log.error('[Renderer] Process gone:', details.reason);
    dialog.showErrorBox(
      'Megjelenítési hiba',
      `A program megjelenítő folyamata leállt.\nOk: ${details.reason}\n\nKérjük, indítsa újra az alkalmazást.`,
    );
  });

  // F12 → DevTools (hibakereséshez); Ctrl+P/Cmd+P → böngésző-print TILTVA:
  // bizonylat kizárólag a saját printReceipt (silent) úton nyomtatható.
  mainWindow.webContents.on(
    'before-input-event',
    createBeforeInputHandler({ toggleDevTools: () => mainWindow?.webContents.toggleDevTools() }),
  );

  // Security: blokkolja az ismeretlen URL-ekre való navigálást (XSS/phishing védelem)
  mainWindow.webContents.on('will-navigate', (event, url) => {
    const allowed = ['app://localhost', devServerUrl];
    if (!allowed.some((origin) => url.startsWith(origin))) {
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
    // Config-feloldás + fail-closed a printer.ts-ben (printReceiptWithStoredConfig) —
    // ott tesztelt: tárolt printer.deviceName / printer.serialPort nélkül nincs nyomtatás.
    return await printReceiptWithStoredConfig(data);
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
  if (!isConfigKeyReadable(key)) {
    log.warn('[IPC] get-config blocked key:', key);
    return null;
  }
  return getConfig(key);
});

ipcMain.handle('set-config', async (_event, key: string, value: string): Promise<void> => {
  if (typeof key !== 'string' || !isConfigKeyWritable(key)) {
    throw new Error('set-config: key not allowed: ' + key);
  }
  if (typeof value !== 'string') {
    throw new Error('set-config: value must be a string for key: ' + key);
  }
  setConfig(key, value);
});

ipcMain.handle('delete-config', async (_event, key: string): Promise<void> => {
  // TODO: wave 2b — delete-config needs allowlist (reuse CONFIG_WRITE_ALLOWLIST + SENSITIVE_WRITE_KEY_PATTERN)
  deleteConfig(key);
});

// --- First-Run Setup Wizard IPC ---
ipcMain.handle('setup:check', async () => {
  return isFirstRun();
});

ipcMain.handle(
  'setup:branches',
  async (_event, params?: { apiUrl?: string; companyCode?: string }) => {
    assertSetupAllowed(isFirstRun());
    return await getBranches(params?.apiUrl, params?.companyCode);
  },
);

ipcMain.handle(
  IPC_CHANNELS.SETUP_WORKERS,
  async (_event, params: SetupWorkersRequest): Promise<SetupWorkerOption[]> => {
    assertSetupAllowed(isFirstRun());
    const apiUrl = params?.apiUrl?.trim() ?? '';
    const companyCode = params?.companyCode?.trim() ?? '';
    const branchCode = params?.branchCode?.trim() ?? '';

    if (!apiUrl || !companyCode || !branchCode) {
      log.warn('[IPC] setup:workers hianyos parameterek, ures dolgozoi lista.', {
        hasApiUrl: Boolean(apiUrl),
        hasCompanyCode: Boolean(companyCode),
        hasBranchCode: Boolean(branchCode),
      });
      return [];
    }

    return await getWorkers(apiUrl, companyCode, branchCode);
  },
);

ipcMain.handle(
  'setup:test-connection',
  async (
    _event,
    params: { apiUrl: string; companyCode: string; username: string; password: string },
  ) => {
    assertSetupAllowed(isFirstRun());
    return await testConnection(
      params.apiUrl,
      params.companyCode,
      params.username,
      params.password,
    );
  },
);

ipcMain.handle('setup:save', async (_event, payload: SetupSavePayload) => {
  assertSetupAllowed(isFirstRun());
  return await saveSetupConfig(payload);
});

ipcMain.handle(
  'save-pending-transaction',
  async (
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
    foreignStatus: 'DOMESTIC' | 'FOREIGN' | null,
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
      foreignStatus,
    );
  },
);

// V235 (2026-05-19 HIBA #14 + #15 + #17 + #18): bővített IPC channel
// objektum-paraméterrel a teljes Pmt. customer-snapshot mentéséhez.
ipcMain.handle(
  'save-pending-transaction-v2',
  async (_event, input: PendingTransactionInputV2): Promise<number> => {
    return savePendingTransactionV2(input);
  },
);

ipcMain.handle(
  'get-pending-transactions',
  async (): Promise<ReturnType<typeof getPendingTransactions>> => {
    return getPendingTransactions();
  },
);

// 2026-06-04 (audit-fix): a nyugta-nyomtatáshoz a TÉNYLEGES szigorú helyi sorszám lekérdezése
// a mentett pending-sor ID-je alapján (nem fabrikált P-<timestamp>).
ipcMain.handle(
  'get-pending-transaction-ref-by-id',
  async (_event, id: number): Promise<string | null> => {
    return getPendingTransactionRefById(id);
  },
);

// 2026-06-04 (audit-fix, buy/sell-paritás): a szállítólevél-nyomtatáshoz a TÉNYLEGES átadólap-
// sorszám lekérdezése a mentett transfer pending-sor ID-je alapján (nem fabrikált LOCAL-<dátum>-#<id>).
ipcMain.handle(
  'get-pending-transfer-ref-by-id',
  async (_event, id: number): Promise<string | null> => {
    return getPendingTransferRefById(id);
  },
);

ipcMain.handle(
  'save-pending-conversion',
  async (
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
  },
);

// V235 + V236 (2026-05-19 Codex P1 #695): bővített Konverzio IPC channel
// objektum-paraméterrel, teljes Pmt. customer-snapshot mentéséhez.
ipcMain.handle(
  'save-pending-conversion-v2',
  async (_event, input: PendingConversionInputV2): Promise<number> => {
    return savePendingConversionV2(input);
  },
);

ipcMain.handle(
  'get-pending-conversions',
  async (): Promise<ReturnType<typeof getPendingConversions>> => {
    return getPendingConversions();
  },
);

ipcMain.handle(
  'save-pending-bank-transaction',
  async (
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
  },
);

ipcMain.handle(
  'get-pending-bank-transactions',
  async (): Promise<ReturnType<typeof getPendingBankTransactions>> => {
    return getPendingBankTransactions();
  },
);

ipcMain.handle(
  'save-pending-storno',
  async (_event, payload: PendingStornoInput): Promise<number> => {
    return savePendingStorno(payload);
  },
);

ipcMain.handle('get-pending-stornos', async (): Promise<ReturnType<typeof getPendingStornos>> => {
  return getPendingStornos();
});

// Offline átadás-átvétel SZTORNÓ (internetkimaradáskor): queue → sync → backend visszafordítás.
ipcMain.handle(
  'save-pending-transfer-storno',
  async (_event, payload: PendingTransferStornoInput): Promise<number> => {
    return savePendingTransferStorno(payload);
  },
);

// FKH-018: Shipment átvételi szándék offline outbox. A sqlite mentési határ
// futásidőben validálja az UUID/worker/tenant mezőket is.
ipcMain.handle(
  IPC_CHANNELS.QUEUE_SHIPMENT_RECEIPT,
  async (_event, payload: PendingShipmentReceiptInput): Promise<number> => {
    return savePendingShipmentReceipt(payload);
  },
);

ipcMain.handle(
  IPC_CHANNELS.GET_PENDING_SHIPMENT_RECEIPTS,
  async (): Promise<ReturnType<typeof getShipmentReceiptOutboxState>> => {
    return getShipmentReceiptOutboxState();
  },
);

// FS-C: körlevél-válasz offline outbox (sync-engine küldi a backendre).
ipcMain.handle(
  'save-pending-circular-reply',
  async (_event, payload: PendingCircularReplyInput): Promise<number> => {
    return savePendingCircularReply(payload);
  },
);

// FS-5: okmány-képpár feltöltési outbox (scan → center, törlés nyugtázás után).
ipcMain.handle(
  IPC_CHANNELS.QUEUE_SCANNED_DOCUMENT,
  async (_event, input: QueueScannedDocumentInput): Promise<number> => {
    if (!Number.isInteger(input.customerId) || input.customerId <= 0) {
      throw new Error('Invalid customerId');
    }
    validateDocumentType(input.documentType);
    assertInsideBase(input.frontPath, SCAN_DIR, 'frontPath');
    assertInsideBase(input.backPath, SCAN_DIR, 'backPath');
    return savePendingScannedDocument(input);
  },
);

ipcMain.handle(
  'get-pending-transfer-stornos',
  async (): Promise<ReturnType<typeof getPendingTransferStornos>> => {
    return getPendingTransferStornos();
  },
);

// Fizikai ujranyomtatas (Codex P2 #1035): a mar szinkronizalt (synced = 1) bizonylatok
// legutobbi sorai, hogy egy meghiusult fizikai nyomtatas (papirelakadas) utan az operator a
// lokalis receiptData-bol ESC/POS-on UJRA tudja nyomtatni. A sync-engine erintetlen (synced = 0).
ipcMain.handle(
  'get-reprintable-transactions',
  async (_event, limit?: number): Promise<ReturnType<typeof getReprintableTransactions>> => {
    return getReprintableTransactions(limit);
  },
);

ipcMain.handle(
  'get-reprintable-conversions',
  async (_event, limit?: number): Promise<ReturnType<typeof getReprintableConversions>> => {
    return getReprintableConversions(limit);
  },
);

ipcMain.handle(
  'get-reprintable-stornos',
  async (_event, limit?: number): Promise<ReturnType<typeof getReprintableStornos>> => {
    return getReprintableStornos(limit);
  },
);

ipcMain.handle('get-pending-transaction-count', async (): Promise<number> => {
  return getPendingTransactionCount();
});

// --- FKH-D2/F5: sync-gate-elt gyari reset ---
// A telepito NEM torolheti a `~/.valuta/local.db`-t (D2: admin-kontextusban a
// rossz profilra oldodna fel), az app viszont garantaltan a helyes profilban fut.
ipcMain.handle('get-unsynced-summary', async (): Promise<UnsyncedSummary> => {
  return getUnsyncedSummary();
});

ipcMain.handle('factory-reset-local-database', async (): Promise<FactoryResetResult> => {
  const result = factoryResetLocalDatabase();
  if (!result.ok) {
    log.warn(
      `[FactoryReset] BLOKKOLVA: ${result.blockedBy?.total ?? 0} szinkronizalatlan sor - ${JSON.stringify(result.blockedBy?.byTable ?? {})}`,
    );
  } else if (result.deletedPath) {
    log.info('[FactoryReset] Lokalis adatbazis torolve.');
  } else {
    log.info('[FactoryReset] Nem volt lokalis adatbazis.');
  }
  return result;
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

// FK-071 FR-3: egy pending tranzakció célzott, azonnali újraküldése a
// Tranzakciólista "Újraküldés" gombjáról (az abandoned-setet megkerülve).
ipcMain.handle(
  'retry-pending-transaction',
  async (_event, id: number): Promise<{ success: boolean; error?: string | null }> => {
    const localId = Number(id);
    if (!Number.isInteger(localId) || localId <= 0) {
      return { success: false, error: 'Érvénytelen tétel-azonosító' };
    }
    return syncEngine.retryPendingTransaction(localId);
  },
);

// FKH-032 FR-2: célzott, EGY-tételes azonnali könyvelési kísérlet a mentés után
// (a teljes syncAll() helyett), a main-process net.request csatornán, 5 mp timeouttal.
ipcMain.handle(
  'sync-single-transaction-immediate',
  async (_event, id: number): Promise<{ success: boolean; error?: string | null }> => {
    const localId = Number(id);
    if (!Number.isInteger(localId) || localId <= 0) {
      return { success: false, error: 'Érvénytelen tétel-azonosító' };
    }
    return syncEngine.syncSingleTransactionImmediate(localId);
  },
);

ipcMain.handle('get-sync-status', async (): Promise<string> => {
  return JSON.stringify(syncEngine.getStatus());
});

// 2026-04-29 v2.3.11 (E-B6.2 Page Visibility API):
// A renderer hív ki, amikor az ablak láthatatlanná válik (visibilitychange event).
// A sync-engine leáll, hogy ne pollozzon 30 másodpercenként inaktív állapotban.
// A 'sync-engine-resume' visszaaktiválja, ha az ablak újra látszik.
ipcMain.handle('sync-engine-pause', async (): Promise<void> => {
  syncEngine.stop();
});

ipcMain.handle('sync-engine-resume', async (): Promise<void> => {
  // 30 másodperces alapértelmezett intervallum (sync-engine.ts default)
  syncEngine.start();
});

ipcMain.handle('get-app-version', async (): Promise<string> => {
  return app.getVersion();
});

ipcMain.handle('get-printers', async (): Promise<Electron.PrinterInfo[]> => {
  if (!mainWindow) return [];
  return mainWindow.webContents.getPrintersAsync();
});

// --- Értéktár Offline IPC Handlers ---

ipcMain.handle(
  'save-pending-distribution',
  async (
    _event,
    targetBranchCode: string,
    currencyCode: string,
    amount: number,
    denominations: string | null,
    note: string | null,
  ): Promise<number> => {
    return savePendingDistribution(targetBranchCode, currencyCode, amount, denominations, note);
  },
);

ipcMain.handle(
  'save-pending-transfer',
  async (
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
    carrierName: string | null = null,
    sealNumber: string | null = null,
    direction: string | null = null,
    lines: string | null = null,
  ): Promise<number> => {
    return savePendingTransfer(
      targetBranchId,
      targetBranchCode,
      currencyId,
      currencyCode,
      amount,
      hufValue,
      transferType,
      denominations,
      note,
      carrierName,
      sealNumber,
      direction,
      lines,
    );
  },
);

ipcMain.handle(
  'get-pending-transfers',
  async (): Promise<ReturnType<typeof getPendingTransfers>> => {
    return getPendingTransfers();
  },
);

ipcMain.handle(
  'save-pending-collection',
  async (
    _event,
    sourceBranchCode: string,
    currencyCode: string,
    amount: number,
    note: string | null,
  ): Promise<number> => {
    return savePendingCollection(sourceBranchCode, currencyCode, amount, note);
  },
);

// Sprint 7.1: offline stocktake item count queue
ipcMain.handle(
  'queue-stocktake-count',
  async (
    _event,
    itemId: string,
    actualQuantity: number,
    note: string | null,
    idempotencyKey: string | null,
  ): Promise<number> => {
    return queueStocktakeCount(itemId, actualQuantity, note, idempotencyKey);
  },
);

ipcMain.handle(
  'save-pending-handover-operation',
  async (_event, payload: PendingHandoverOperationInput): Promise<number> => {
    return savePendingHandoverOperation(payload);
  },
);

ipcMain.handle(
  'get-pending-handover-operations',
  async (): Promise<ReturnType<typeof getPendingHandoverOperations>> => {
    return getPendingHandoverOperations();
  },
);

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

ipcMain.handle(
  'save-local-audit-event',
  async (
    _event,
    payload: {
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
    },
  ): Promise<number> => {
    return saveLocalAuditEvent(payload);
  },
);

ipcMain.handle('get-local-audit-events', async (_event, limit?: number) => {
  return getLocalAuditEvents(limit ?? 200);
});

// --- Secure Token Storage (safeStorage — Windows DPAPI / macOS Keychain / Linux libsecret) ---

ipcMain.handle('secure-store-token', async (_event, token: string): Promise<boolean> => {
  try {
    if (!safeStorage.isEncryptionAvailable()) {
      log.warn(
        '[SafeStorage] Encryption not available — token stored in-memory only, NOT persisted to disk',
      );
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
  // 2026-05-15 user-direktiva (Google OAuth fix): production buildben a
  // `import('dotenv/config')` (main.ts:3) NEM tolti be a userData/.env-et,
  // ezert a Google OAuth IPC handlers `process.env.VITE_GOOGLE_DESKTOP_*`
  // UNDEFINED-ra olvasnak es "Google Desktop OAuth client nincs konfiguralva"
  // hibat dobnak. A promocio a platform-retegben van (egyetlen forras).
  promoteUserDataEnv({
    userDataPath: app.getPath('userData'),
    logger: log,
    missingEnvMessage:
      '[App] userData/.env nem letezik — Google OAuth lehet sikertelen amig a SetupWizard be nem allitja.',
  });

  // FK-091: meglévő pénztár gépek — automatikus lokális backend config patch induláskor.
  try {
    await migrateLocalBackendConfigOnStartup(log);
  } catch (migrationErr) {
    log.warn('[App] FK-091 local backend config migration warning (nem kritikus):', migrationErr);
  }

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

  // EBC Hangsegéd Phase 9.5 — mikrofon engedély a renderer-ben futo
  // VoiceAssistantPanel WebRTC szessziohoz (OpenAI Realtime API).
  //
  // A kezelo a PLATFORM-retegben van (`createMediaPermissionHandler`), egyetlen
  // forrasbol mind a harom kliensnek — a szabaly nem driftelhet szet:
  //   1. Codex P1 + CodeQL + Copilot: NE startsWith()-tel ellenorizzuk az origin-t —
  //      `https://excvaluta.com.attacker.example/...` atmenne. `new URL()` parse +
  //      exact `hostname` + `protocol` compare.
  //   2. F-006 (audit 2026-05-29): a `setPermissionRequestHandler` session-global; a non-media
  //      permission-okra (notifications, geolocation, midi, clipboard, ...) a BIZTONSAGOS
  //      DEFAULT = DENY. Penzugyi kliensben nincs default-allow; csak a `media` (mic,
  //      voice-assistant) engedelyezett, az is csak explicit origin-allowlisttel.
  session.defaultSession.setPermissionRequestHandler(createMediaPermissionHandler(log));

  // IPC handlers regisztráció (app.whenReady() UTÁN, hogy ipcMain elérhető legyen)
  registerCameraHandlers();
  registerVideoManagerHandlers();
  registerScannerHandlers();
  registerUpdaterHandlers();

  // v2.5.13 NEM-INFORMATIKUS-FELHASZNALO ALAPELV: automatikus hibajelentes indul
  initErrorReporter();
  log.info(
    '[App] Error reporter initialized -> POST excvaluta.com/api/v1/diagnostics/error-report',
  );

  // IPC: a renderer (axios interceptor + window.onerror) ide kuldi a JS hibakat
  ipcMain.handle(
    'diagnostics:report-error',
    async (
      _event,
      payload: {
        component?: string;
        message: string;
        stack?: string;
        context?: Record<string, unknown>;
      },
    ) => {
      const component = (payload.component ?? 'electron-renderer') as
        | 'electron-main'
        | 'electron-renderer'
        | 'nsis-installer'
        | 'axios-http'
        | 'setup-wizard'
        | 'sync-engine'
        | 'other';
      const err = new Error(payload.message);
      if (payload.stack) err.stack = payload.stack;
      reportError(component, err, payload.context);
      return { ok: true };
    },
  );

  // IPC: a Login flow utan a renderer atadhatja a felhasznalo email-jet (audit)
  ipcMain.handle('diagnostics:set-user-identifier', async (_event, id: string | null) => {
    setUserIdentifier(id);
    return { ok: true };
  });

  // Google OAuth Authorization Code Flow + loopback redirect (RFC 8252).
  // A Web SDK (`<GoogleLogin>`) NEM mukodik Electron-ban (`app://localhost` origin reject),
  // ezert a renderer ezt az IPC handler-t hivja meg ha a user a "Belepes Google-lel"
  // gombra kattint az Electron Login oldalon. A handler vegigviszi a Google Desktop
  // OAuth flow-t es a vegen vissza-adja a Google ID tokent — a renderer ezt elkuldi a
  // backend `/api/v1/auth/google-login` endpointnak (ugyanaz mint a webes felulet).
  ipcMain.handle('auth:google-oauth-flow', async () => {
    const clientId =
      process.env.VITE_GOOGLE_DESKTOP_CLIENT_ID ?? process.env.GOOGLE_DESKTOP_CLIENT_ID ?? '';
    const clientSecret =
      process.env.VITE_GOOGLE_DESKTOP_CLIENT_SECRET ??
      process.env.GOOGLE_DESKTOP_CLIENT_SECRET ??
      '';
    if (!clientId || !clientSecret) {
      log.error(
        '[main] auth:google-oauth-flow MISCONFIGURED — VITE_GOOGLE_DESKTOP_CLIENT_ID/SECRET hianyzik',
      );
      throw new Error('Google Desktop OAuth client nincs konfiguralva. Kerd az adminisztratort.');
    }
    try {
      const result = await performGoogleOAuthFlow({ clientId, clientSecret });
      return { ok: true, idToken: result.idToken, email: result.email };
    } catch (err) {
      if (err instanceof GoogleOAuthFailedException) {
        log.warn('[main] Google OAuth flow failed:', err.code, err.message);
        return { ok: false, code: err.code, message: err.message };
      }
      log.error('[main] Google OAuth flow unexpected error:', err);
      return { ok: false, code: 'UNEXPECTED', message: (err as Error).message };
    }
  });

  // v2.5.20 Borsi-fix: Google OAuth flow + backend POST EGY MAIN-PROCESS hivasban.
  // A renderer axios.post az ESET MITM-mel terhelt gepeken nehany POST connection-t
  // a TLS handshake utan leejti. A main-process electron.net.request megbizhatobb
  // (Windows certificate store + Chromium switches mind alkalmazva, NEM renderer fetch).
  // Plus: 3-szor probalja a backend POST-ot (1s, 3s, 5s wait) ha network-level error.
  ipcMain.handle(
    'auth:google-oauth-flow-with-backend',
    async (_evt, payload?: { appMode?: string; supportsVaultWorkerSelection?: boolean }) => {
      const clientId =
        process.env.VITE_GOOGLE_DESKTOP_CLIENT_ID ?? process.env.GOOGLE_DESKTOP_CLIENT_ID ?? '';
      const clientSecret =
        process.env.VITE_GOOGLE_DESKTOP_CLIENT_SECRET ??
        process.env.GOOGLE_DESKTOP_CLIENT_SECRET ??
        '';
      if (!clientId || !clientSecret) {
        log.error('[main] auth:google-oauth-flow-with-backend MISCONFIGURED');
        return {
          ok: false,
          code: 'MISCONFIGURED',
          message: 'Google Desktop OAuth client nincs konfiguralva. Kerd az adminisztratort.',
        };
      }
      const apiBaseUrl = resolveConfiguredApiUrl();
      try {
        const result = await performGoogleOAuthFlowWithBackendLogin({
          clientId,
          clientSecret,
          apiBaseUrl,
          appMode: payload?.appMode,
          supportsVaultWorkerSelection: payload?.supportsVaultWorkerSelection === true,
        });
        log.info('[main] Google OAuth + backend login OK for:', result.email ?? '(unknown)');
        // FK-ÉRTÉKTÁR (V285): idToken visszaadva, hogy a renderer a dolgozóválasztó 2. fázist
        // (select-worker) ugyanazzal a Google ID tokennel tudja hívni.
        return {
          ok: true,
          response: result.response,
          email: result.email,
          idToken: result.idToken,
        };
      } catch (err) {
        if (err instanceof GoogleOAuthFailedException) {
          log.warn('[main] Google OAuth + backend login failed:', err.code, err.message);
          return { ok: false, code: err.code, message: err.message };
        }
        log.error('[main] Google OAuth + backend login unexpected error:', err);
        return { ok: false, code: 'UNEXPECTED', message: (err as Error).message };
      }
    },
  );

  // v2.5.21 ALTALANOS BEJELENTKEZESI FIX: a sima jelszavas /auth/login is main process-en,
  // ESET MITM kompatibilis Windows cert store + Schannel-en, 3x retry network errorra.
  // A renderer axios.post (Chromium fetch) nehany kliensen leejti a POST connection-t
  // (Borsi laptop, Fabuja Zsuzsa) — a main-process net.request megbizhatobb stack.
  ipcMain.handle(
    'auth:password-login',
    async (
      _evt,
      payload: {
        companyCode: string;
        workerCode: string;
        password: string;
        appMode?: string;
      },
    ) => {
      if (!payload || !payload.companyCode || !payload.workerCode || !payload.password) {
        return {
          ok: false,
          code: 'BAD_REQUEST',
          message: 'companyCode, workerCode, password kotelezo',
        };
      }
      const apiBaseUrl = resolveConfiguredApiUrl();
      try {
        const response = await performPasswordLoginMainProcess({
          apiBaseUrl,
          companyCode: payload.companyCode,
          workerCode: payload.workerCode,
          password: payload.password,
          appMode: payload.appMode,
        });
        log.info('[main] Password login OK for worker:', payload.workerCode);
        return { ok: true, response };
      } catch (err) {
        if (err instanceof GoogleOAuthFailedException) {
          const code = err.code ?? 'UNKNOWN';
          const isHttp4xx = code.startsWith('HTTP_4');
          if (!isHttp4xx) {
            log.warn('[main] Password login network/timeout failed:', code, err.message);
          }
          return { ok: false, code, message: err.message };
        }
        log.error('[main] Password login unexpected error:', err);
        return { ok: false, code: 'UNEXPECTED', message: (err as Error).message };
      }
    },
  );

  // v2.5.25 ALTALANOS API PROXY: MINDEN renderer HTTP hivas a main process electron.net.request-en
  // megy at, NEM renderer Chromium fetch/axios. Ez a vegleges megoldas az ESET/Kaspersky/Bitdefender
  // MITM TLS proxy-k altal okozott "Network Error" hibakra (Borsi, Helga, Zsuzsa, Tomi gepek).
  // A v2.5.21-ben CSAK a login ment main process-en — most MINDEN: selectRole, napnyitas,
  // arfolyam-lekerdezes, tranzakcio-rogzites, stb.
  ipcMain.handle('api:fetch', async (_evt, params: ApiProxyRequest) => {
    if (!params || !params.url || !params.method) {
      return {
        ok: false,
        status: 0,
        statusText: 'BAD_REQUEST',
        headers: {},
        body: '{"error":"url and method required"}',
      };
    }
    const apiBaseUrl = resolveConfiguredApiUrl();
    const fullUrl = params.url.startsWith('http') ? params.url : `${apiBaseUrl}${params.url}`;

    // ESET-MITM hidegindítás-reset ellen: 5 próba növekvő backoff-fal. A retry CSAK hálózati
    // hibára fut (HTTP 4xx/5xx érintetlen) — lásd api-proxy.ts isRetryableNetworkError.
    // (2026-06-01 értéktár-eset: net::ERR_CONNECTION_RESET a `/public/setup/google-identify` végponton.)
    try {
      return await fetchViaElectronNetWithRetry({ ...params, url: fullUrl });
    } catch (err) {
      const msg = (err instanceof Error ? err.message : String(err)) || 'Unknown error';
      log.warn(
        '[main] api:fetch failed (retries exhausted) for',
        params.method,
        params.url,
        ':',
        msg,
      );
      return {
        ok: false,
        status: 0,
        statusText: 'NETWORK_ERROR',
        headers: {},
        body: JSON.stringify({ error: msg }),
      };
    }
  });

  // --- VFD ügyfélkijelző IPC handlerek (P2-1) ---
  // Az ügyfélkijelző egy második BrowserWindow ablakot nyit a nem-elsődleges
  // monitoron (vagy keret-nélküli alwaysOnTop overlay-t, ha csak egy monitor van)
  // és a tranzakció részleteit (típus, valuta, összeg, árfolyam, díj, HUF végösszeg)
  // jeleníti meg az ügyfél számára.
  ipcMain.handle(
    'customer-display:show',
    async (_evt, preferSecondMonitor?: boolean): Promise<boolean> => {
      try {
        const rendererUrl = isDev ? devServerUrl : 'app://localhost/';
        createCustomerDisplay(rendererUrl, preferSecondMonitor !== false);
        return true;
      } catch (err) {
        log.error('[IPC] customer-display:show error:', err);
        return false;
      }
    },
  );

  ipcMain.handle(
    'customer-display:update',
    async (_evt, payload: CustomerDisplayPayload): Promise<void> => {
      updateCustomerDisplay(payload ?? {});
    },
  );

  ipcMain.handle('customer-display:hide', async (): Promise<void> => {
    hideCustomerDisplay();
  });

  ipcMain.handle('customer-display:status', async (): Promise<boolean> => {
    return isCustomerDisplayActive();
  });

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

  // v2.5.11 KRITIKUS: regi mojibake / hibas userData .env javitasa MIGRATION-nel
  // Helga + Borsi-tunet (2026-05-04): a userData `.env` 2 hete tarolt, mojibake-os
  // (`PĂ©nztĂˇr`) + `VITE_API_URL="https://"` (URES URL!) + `SETUP_COMPLETED=1`.
  // A regi eltavolitok NEM toroltek a `%APPDATA%\valuta-penztar`-t, igy a Penztar.exe
  // a regi config-ot olvasta es Network Error-t adott.
  // Migration logika: ha az `.env` `VITE_API_URL`-je ures-https vagy hianyzik a prod URL,
  // ATIRJUK a helyes prod URL-re (nem deletjuk az egesz fajlt - megtartjuk a JWT_SECRET-eket
  // a v2.5.11 utani tovabbi instabil-modot ne triggereljen).
  try {
    const userDataEnvPath = path.join(app.getPath('userData'), '.env');
    if (fs.existsSync(userDataEnvPath)) {
      const rawEnv = fs.readFileSync(userDataEnvPath, 'utf8');
      const apiUrlMatch = rawEnv.match(/^VITE_API_URL\s*=\s*"?([^"\r\n]*)"?\s*$/m);
      // TS2532 fix: a regex .match capture group `apiUrlMatch[1]` lehet undefined,
      // ha a group nem fogott meg semmit. Optional chaining + nullish coalescing.
      const currentApiUrl = (apiUrlMatch?.[1] ?? '').trim();
      const needsMigration =
        !currentApiUrl ||
        currentApiUrl === 'https://' ||
        currentApiUrl === 'http://' ||
        currentApiUrl === 'https' ||
        /^https?:\/\/?$/.test(currentApiUrl);
      if (needsMigration) {
        log.warn(
          `[App] userData .env migration: VITE_API_URL="${currentApiUrl}" -> https://excvaluta.com/api/v1`,
        );
        const fixedEnv = rawEnv.replace(
          /^VITE_API_URL\s*=.*$/m,
          'VITE_API_URL="https://excvaluta.com/api/v1"',
        );
        const tmpPath = `${userDataEnvPath}.tmp`;
        fs.writeFileSync(tmpPath, fixedEnv, { encoding: 'utf8', mode: 0o600 });
        fs.renameSync(tmpPath, userDataEnvPath);
        log.info('[App] userData .env migration KESZ.');
      }
    }
  } catch (migrationErr) {
    log.warn(
      '[App] userData .env migration kihagyva (nem kritikus):',
      migrationErr instanceof Error ? migrationErr.message : migrationErr,
    );
  }

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
  // Sourcery AI P2 fix: manualis .env parser reimplementalja dotenv-et es divergalhat
  // (escaping, multiline, quote-folding). Delegaljuk a dotenv.parse-nak a konzisztens
  // parsing szemantika erdekeben (dev+packaged egyforman viselkedik).
  const readPersistedEnv = (): Record<string, string> => {
    try {
      const envPath = path.join(app.getPath('userData'), '.env');
      if (!fs.existsSync(envPath)) return {};
      const raw = fs.readFileSync(envPath, 'utf8');
      // Dinamikus import - dev modban dotenv elerheto, production ASAR-ban is bundle-olva.
      // Ha valami miatt nem elerheto (pl. regressio), fallback a korabbi manualis parserra.
      try {
        // eslint-disable-next-line @typescript-eslint/no-require-imports
        const dotenv = require('dotenv') as {
          parse: (input: string | Buffer) => Record<string, string>;
        };
        return dotenv.parse(raw);
      } catch {
        // Fallback: minimal inline parser (csak ha dotenv nem elerheto)
        const out: Record<string, string> = {};
        for (const rawLine of raw.split(/\r?\n/)) {
          const line = rawLine.trim();
          if (!line || line.startsWith('#')) continue;
          const eq = line.indexOf('=');
          if (eq <= 0) continue;
          const key = line.slice(0, eq).trim();
          let value = line.slice(eq + 1).trim();
          if (
            (value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'"))
          ) {
            value = value.slice(1, -1);
          }
          out[key] = value;
        }
        return out;
      }
    } catch {
      return {};
    }
  };
  const persistedEnv = readPersistedEnv();
  const envBranchCode = (
    process.env.VITE_BRANCH_CODE ??
    persistedEnv.VITE_BRANCH_CODE ??
    ''
  ).trim();
  const envCompanyCode = (
    process.env.VITE_COMPANY_CODE ??
    process.env.PENZTAR_BOOTSTRAP_COMPANY_CODE ??
    persistedEnv.VITE_COMPANY_CODE ??
    persistedEnv.PENZTAR_BOOTSTRAP_COMPANY_CODE ??
    ''
  ).trim();
  const envApiUrl = (process.env.VITE_API_URL ?? persistedEnv.VITE_API_URL ?? '').trim();

  try {
    const existingBranchCode = getConfig('branch_code');
    if (!existingBranchCode) {
      if (envBranchCode) {
        setConfig('branch_code', envBranchCode);
        log.info(
          `[App] Auto-migration: branch_code='${envBranchCode}' atmasolva a .env-bol az SQLite config-ba.`,
        );
      } else {
        log.warn(
          '[App] branch_code hianyzik az SQLite config-bol ES a .env VITE_BRANCH_CODE-bol is. A tranzakciok elszalnak - futtasd a SetupWizardot vagy toltsd ki a .env-et.',
        );
      }
    }
    const existingCompany = getConfig('bootstrap_company_code');
    if (!existingCompany && envCompanyCode) {
      setConfig('bootstrap_company_code', envCompanyCode);
      log.info(
        `[App] Auto-migration: bootstrap_company_code='${envCompanyCode}' atmasolva a .env-bol.`,
      );
    }
  } catch (migrationErr) {
    log.warn('[App] Auto-migration warning (nem kritikus):', migrationErr);
  }

  // v2.3.0 kritikus bugfix: Electron Network Error (localhost:8080) megoldasa.
  //
  // A korabbi logika minden indulaskor felulirta a SQLite server_url-t a .env
  // VITE_API_URL-lel. Ez toerte a telepito-wizard-ban megadott URL-t, ha a .env
  // localhost-ot tartalmazott (dev build / .env.local maradvany).
  //
  // Uj logika:
  // 1. Ha offline_mode=true -> MEGTARTJUK a server_url-t (lokalis backend legitim)
  // 2. Ha van SQLite server_url es prod URL -> megtartjuk (user-beallitas)
  // 3. Ha nincs -> SSOT production-urls.json default-ra allitjuk
  // 4. A .env VITE_API_URL csak dev mode-ban szamit, production-ban ignore
  {
    const currentServerUrl = getConfig('server_url');
    const isDev = !app.isPackaged;
    // v2.3.1 Codex P1 fix #219: offline mode eseten a SetupWizard szandekosan
    // localhost/LAN URL-t ment. Ezt NEM szabad prod URL-re felulirni!
    const offlineMode = getConfig('offline_mode') === 'true';

    const isLocalhost = (url: string | null | undefined): boolean => {
      if (!url) return false;
      const lower = url.toLowerCase();
      return (
        lower.includes('localhost') || lower.includes('127.0.0.1') || lower.includes('192.168.')
      );
    };

    if (offlineMode && currentServerUrl) {
      // v2.3.1 Codex P1 fix #219: offline install - a user szandekkal lokalis
      // backend-et hasznal, NE irjuk felul prod URL-re indulaskor.
      log.info(`[App] offline_mode=true -> server_url megtartva: ${currentServerUrl}`);
    } else if (currentServerUrl && !isLocalhost(currentServerUrl)) {
      // User-beallitott prod URL -> megtartjuk, ne irja felul a .env
      log.info(`[App] server_url megtartva (user-beallitas): ${currentServerUrl}`);
    } else if (isDev && envApiUrl) {
      // Dev mode: .env VITE_API_URL-t respektaljuk (gyakori dev override)
      setConfig('server_url', envApiUrl);
      log.info(`[App] server_url (dev): ${envApiUrl}`);
    } else {
      // Production + ures / localhost server_url -> SSOT prod URL-re
      const prodUrls = loadProductionUrls();
      setConfig('server_url', prodUrls.api_url);
      log.info(`[App] server_url default (SSOT prod): ${prodUrls.api_url}`);
      if (isLocalhost(currentServerUrl)) {
        log.warn(
          `[App] Elozo server_url (${currentServerUrl}) localhost volt -> felulirva prod-ra`,
        );
      }
    }
  }

  // Default app-menü eltávolítása production-ben: a rejtett menü accelerator-ai
  // (Ctrl+R state-vesztő reload, Ctrl+Shift+I, F11, zoom) éles pénztár-kliensben
  // nem élhetnek. Dev-ben marad (Ctrl+R / Ctrl+Shift+I a fejlesztői workflow része).
  if (!isDev) {
    Menu.setApplicationMenu(null);
  }

  createWindow();

  // SyncEngine indítás — 30 másodperces intervallum
  syncEngine.start(30_000);
  log.info('[App] SyncEngine elindítva');

  // Suite-frissites (docs/auto-update-terv-es-vegrehajtas.md 3.2 + 3.6):
  // a penztar frissitesi EGYSEGE a teljes alairt suite-telepito (Electron +
  // backend JAR + JRE + PostgreSQL + NSSM service-ek), NEM az electron-updater —
  // az ugyanis parhuzamos, masodik telepitest hozna letre es szetcsuszna a
  // kliens/lokalis-backend verzio. A telepites CSAK allapotvezerelt ablakban
  // indul (napnyitas ELOTT vagy napzaras UTAN), nyitott muszak alatt csak jelez.
  if (app.isPackaged) {
    initSuiteUpdate(mainWindow);
  } else {
    log.info('[App] Suite-update kihagyva (dev mode)');
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
