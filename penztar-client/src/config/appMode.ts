/**
 * App mód konfiguráció — Pénztár VAGY Értéktár mód.
 *
 * Ugyanaz az Electron alkalmazás, de config alapján más módban indul:
 * - 'penztar': normál pénztár (F1-F12 menü)
 * - 'ertektar': értéktár / regionális központ (bővített menü + pénztár funkciók)
 */

export type AppMode = 'penztar' | 'ertektar';

export interface AppConfig {
  mode: AppMode;
  branchCode: number;
  companyId: number; // -1 Best Change, -4 Expressz
  serverUrl: string;
  offlineEnabled: boolean;
}

const DEFAULT_CONFIG: AppConfig = {
  mode: 'penztar',
  branchCode: 101,
  companyId: -1,
  serverUrl: 'http://localhost:8080/api/v1',
  offlineEnabled: true,
};

let cachedMode: AppMode | null = null;

/**
 * App mód betöltése az Electron config store-ból (SQLite).
 * Ha nincs beállítva, alapértelmezett 'penztar'.
 */
export async function loadAppMode(): Promise<AppMode> {
  if (cachedMode) return cachedMode;

  try {
    if (window.electronAPI) {
      const stored = await window.electronAPI.getConfig('app_mode');
      if (stored === 'penztar' || stored === 'ertektar') {
        cachedMode = stored;
        return stored;
      }
    }
  } catch (err) {
    console.error('[AppMode] Betöltési hiba:', err);
  }

  cachedMode = DEFAULT_CONFIG.mode;
  return cachedMode;
}

/**
 * App mód beállítása — mentés SQLite-ba.
 */
export async function setAppMode(mode: AppMode): Promise<void> {
  try {
    if (window.electronAPI) {
      await window.electronAPI.setConfig('app_mode', mode);
    }
    cachedMode = mode;
  } catch (err) {
    console.error('[AppMode] Mentési hiba:', err);
  }
}

/**
 * Teljes app config betöltése — mode + branchCode + companyId + serverUrl.
 */
export async function loadAppConfig(): Promise<AppConfig> {
  const mode = await loadAppMode();

  let branchCode = DEFAULT_CONFIG.branchCode;
  let companyId = DEFAULT_CONFIG.companyId;
  let serverUrl = DEFAULT_CONFIG.serverUrl;
  let offlineEnabled = DEFAULT_CONFIG.offlineEnabled;

  try {
    if (window.electronAPI) {
      const storedBranch = await window.electronAPI.getConfig('branch_code');
      if (storedBranch) branchCode = parseInt(storedBranch, 10) || DEFAULT_CONFIG.branchCode;

      const storedCompany = await window.electronAPI.getConfig('company_id');
      if (storedCompany) companyId = parseInt(storedCompany, 10) || DEFAULT_CONFIG.companyId;

      const storedServer = await window.electronAPI.getConfig('server_url');
      if (storedServer) serverUrl = storedServer;

      const storedOffline = await window.electronAPI.getConfig('offline_enabled');
      if (storedOffline !== null) offlineEnabled = storedOffline === 'true';
    }
  } catch (err) {
    console.error('[AppMode] Config betöltési hiba:', err);
  }

  return { mode, branchCode, companyId, serverUrl, offlineEnabled };
}

/**
 * React hook az app mód lekérdezéséhez — egyszer tölt be, utána cache-ből.
 */
export { DEFAULT_CONFIG };
