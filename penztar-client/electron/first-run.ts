// First-Run Setup Wizard — main process oldali logika.
//
// Feladatok:
//   * isFirstRun(): detektálja, hogy a gépen még nincs konfigurált .env (vagy placeholder)
//   * getBranches(): ~60 iroda fix törzslistáját adja (offline-first, a wizard 2×8 rácshoz)
//   * testConnection(): egy egyszerű HTTP POST /auth/login-nal ellenőrzi a szerver elérhetőségét
//   * saveSetupConfig(): generálja a titkokat, kiírja a .env-et, (opcionálisan) admin jelszót állít,
//     majd app.relaunch() + app.exit(0)
//
// A .env fájl helye: <userData>/.env  (pl. Windowson: %APPDATA%\valuta-penztar\.env)
// A <userData> path az Electron app nevétől függ (electron-builder.json → productName).

import { app, net, safeStorage } from 'electron';
import log from 'electron-log/main';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

// ---------------------------------------------------------------------------
// Típusok
// ---------------------------------------------------------------------------

export interface Branch {
  code: string;
  name: string;
  city: string;
  address?: string;
}

export interface SetupCheckResult {
  isFirstRun: boolean;
  envPath: string;
  reason?: string;
}

export interface SetupConnectionTest {
  success: boolean;
  httpStatus?: number;
  errorMessage?: string;
  latencyMs?: number;
}

export interface SetupSavePayload {
  branchCode: string;
  branchName: string;
  apiUrl: string;                // pl. https://valuta.example.com/api/v1
  companyCode: string;
  adminUsername: string;
  adminPassword: string;         // új admin jelszó (min 8 kar.)
  bootstrapUsername?: string;    // wizardbeli teszt-felhasználó (opcionális, csak offline módban üres)
  bootstrapPassword?: string;
  offlineMode: boolean;          // ha true, a szerver kapcsolatot kihagyjuk a wizardban
  appMode?: 'penztar' | 'ertektar' | 'ertekszallito';  // v2.1.4: program-tipus
  // v2.3.0: a telepito dolgozoi dropdown-bol kivalasztott worker identity.
  // Ha kitoltve -> /auth/first-time-worker-setup (meglevo worker jelszo beallitas,
  // megtartott role-lel), egyebkent /auth/bootstrap-admin (uj admin letrehozas).
  selectedWorkerCode?: string;
  selectedWorkerName?: string;
  selectedWorkerRole?: string;
}

export interface SetupSaveResult {
  success: boolean;
  envPath: string;
  errorMessage?: string;
}

// ---------------------------------------------------------------------------
// Fix iroda törzs (~60 iroda) — a telepítőbe szánt baseline.
// A lista sorrendben, 2×8 rácshoz igazítva jelenik meg a wizardban.
// Szükség esetén a telepítés előtt ez a fájl frissíthető.
// ---------------------------------------------------------------------------

export const DEFAULT_BRANCHES: readonly Branch[] = Object.freeze([
  { code: 'KORUT', name: 'Korut',       city: 'Szeged', address: 'Korut 22, Szeged'   },
  { code: 'TISZA', name: 'Tisza Sarok', city: 'Szeged', address: 'Tisza Sarok, Szeged' },
]);

// ---------------------------------------------------------------------------
// Segédfüggvények
// ---------------------------------------------------------------------------

function getEnvFilePath(): string {
  // <userData>/.env — pl. %APPDATA%\valuta-penztar\.env
  return path.join(app.getPath('userData'), '.env');
}

function parseEnvFile(filePath: string): Record<string, string> {
  try {
    const raw = fs.readFileSync(filePath, 'utf8');
    const out: Record<string, string> = {};
    for (const rawLine of raw.split(/\r?\n/)) {
      const line = rawLine.trim();
      if (!line || line.startsWith('#')) continue;
      const eq = line.indexOf('=');
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
}

function looksLikeValidSecret(value: string | undefined): boolean {
  if (!value) return false;
  const trimmed = value.trim();
  if (trimmed.length < 32) return false;
  // Ne fogadjuk el a nyilvánvaló placeholder értékeket.
  const forbidden = ['change-me', 'changeme', 'placeholder', 'your-secret', 'todo', 'replace-me'];
  return !forbidden.some((bad) => trimmed.toLowerCase().includes(bad));
}

function looksLikeValidApiUrl(value: string | undefined): boolean {
  if (!value) return false;
  const trimmed = value.trim();
  if (trimmed === 'https://' || trimmed === 'http://' || trimmed === 'https' || trimmed === 'http') {
    return false;
  }
  try {
    const parsed = new URL(trimmed);
    return (parsed.protocol === 'https:' || parsed.protocol === 'http:')
      && parsed.hostname.trim().length > 0;
  } catch {
    return false;
  }
}

function looksLikeStaleOfflineSetup(values: Record<string, string>): boolean {
  if (values.SETUP_OFFLINE_MODE !== '1') {
    return false;
  }

  // 2026-05-04/05 diagnostics: legacy installs had SETUP_COMPLETED=1,
  // SETUP_OFFLINE_MODE=1, VITE_API_URL="https://", and empty bootstrap identity.
  // That state must run the wizard again; otherwise no global backend password
  // is written for the selected worker.
  const workerCode = values.PENZTAR_BOOTSTRAP_WORKER_CODE?.trim() ?? '';
  const password = values.PENZTAR_BOOTSTRAP_PASSWORD?.trim() ?? '';
  return workerCode.length === 0 && password.length === 0;
}

function generateSecretHex(bytes: number): string {
  return crypto.randomBytes(bytes).toString('hex');
}

function escapeEnvValue(value: string): string {
  // Sor-szeparáló karaktereket nem engedünk meg; double-quote-olva tárolunk
  // hogy a dotenv parser megbízhatóan visszaolvassa.
  // Audit-iter3 P0 (CodeQL js/incomplete-sanitization fix, 2026-04-27):
  // a backslash karakter NEM volt escape-elve, igy `\"` input-ot a parser
  // `"`-kent ertelmezte (early termination). A teljes escape sorrend:
  // 1) backslash duplazasa, 2) double-quote escape-eles.
  const cleaned = value.replace(/[\r\n]/g, ' ');
  const escaped = cleaned.replace(/\\/g, '\\\\').replace(/"/g, '\\"');
  return `"${escaped}"`;
}

function buildEnvFileContent(params: {
  branchCode: string;
  branchName: string;
  apiUrl: string;
  companyCode: string;
  bootstrapUsername: string;
  bootstrapPassword: string;
  jwtSecret: string;
  sqlCipherKey: string;
  offlineLicenseSecret: string;
  offlineMode: boolean;
}): string {
  const ts = new Date().toISOString();
  return [
    `# Valuta Pénztár — auto-generálva a First-Run Setup Wizard által (${ts}).`,
    `# Kézzel NE szerkeszd, csak a wizard futtatásával.`,
    ``,
    `VITE_API_URL=${escapeEnvValue(params.apiUrl)}`,
    `VITE_BRANCH_CODE=${escapeEnvValue(params.branchCode)}`,
    `VITE_BRANCH_NAME=${escapeEnvValue(params.branchName)}`,
    `VITE_COMPANY_CODE=${escapeEnvValue(params.companyCode)}`,
    ``,
    `PENZTAR_BOOTSTRAP_COMPANY_CODE=${escapeEnvValue(params.companyCode)}`,
    `PENZTAR_BOOTSTRAP_WORKER_CODE=${escapeEnvValue(params.bootstrapUsername)}`,
    `PENZTAR_BOOTSTRAP_PASSWORD=${escapeEnvValue(params.bootstrapPassword)}`,
    `PENZTAR_BOOTSTRAP_ROLE_CODE=CASHIER`,
    ``,
    `# Kriptográfiai titkok — a wizard generálta, minden telepítésen egyedi.`,
    `JWT_SECRET=${escapeEnvValue(params.jwtSecret)}`,
    `SQLCIPHER_KEY=${escapeEnvValue(params.sqlCipherKey)}`,
    `OFFLINE_LICENSE_SECRET=${escapeEnvValue(params.offlineLicenseSecret)}`,
    ``,
    `SETUP_COMPLETED=1`,
    `SETUP_COMPLETED_AT=${escapeEnvValue(ts)}`,
    `SETUP_OFFLINE_MODE=${params.offlineMode ? '1' : '0'}`,
    ``,
  ].join('\n');
}

export function resolveEffectiveBootstrapCredentials(
  payload: Pick<SetupSavePayload, 'adminUsername' | 'adminPassword' | 'bootstrapUsername' | 'bootstrapPassword'>,
  resolvedWorkerIdentity: { workerCode?: string } | null,
  options: { preserveExistingPassword?: boolean } = {},
): { bootstrapUsername: string; bootstrapPassword: string } {
  // Worker code precedence follows the backend identity that actually owns the password:
  // server-confirmed worker, then the login/test worker typed in the wizard, then admin fallback.
  const workerCode = [
    resolvedWorkerIdentity?.workerCode,
    payload.bootstrapUsername,
    payload.adminUsername,
  ].find((value) => value != null && value.trim().length > 0)?.trim().toUpperCase() ?? '';
  const currentBootstrapPassword = payload.bootstrapPassword?.trim() ?? '';
  const bootstrapPassword = options.preserveExistingPassword && currentBootstrapPassword
    ? currentBootstrapPassword
    : payload.adminPassword;
  return {
    bootstrapUsername: workerCode,
    bootstrapPassword,
  };
}

function encryptConfigSecret(value: string): string | null {
  if (!value) return null;
  try {
    if (!safeStorage.isEncryptionAvailable()) {
      return null;
    }
    return safeStorage.encryptString(value).toString('base64');
  } catch (err) {
    log.warn('[Setup] safeStorage titkositas sikertelen:', err);
    return null;
  }
}

export function persistBootstrapPasswordConfig(
  bootstrapPassword: string,
  setConfig: (key: string, value: string) => void,
  deleteConfig: (key: string) => void,
): void {
  if (!bootstrapPassword) {
    deleteConfig('bootstrap_password');
    deleteConfig('bootstrap_password_encrypted');
    return;
  }

  const encryptedBootstrapPassword = encryptConfigSecret(bootstrapPassword);
  if (encryptedBootstrapPassword) {
    setConfig('bootstrap_password_encrypted', encryptedBootstrapPassword);
    deleteConfig('bootstrap_password');
    return;
  }

  try {
    setConfig('bootstrap_password', bootstrapPassword);
    deleteConfig('bootstrap_password_encrypted');
    log.warn('[Setup] safeStorage nem elerheto, bootstrap jelszo ideiglenesen plaintext SQLite configban marad; sikeres bootstrap login utan torlodik.');
  } catch (err) {
    log.warn('[Setup] bootstrap jelszo fallback mentese sikertelen; meglevo bootstrap titok erintetlen marad:', err);
  }
}

// ---------------------------------------------------------------------------
// HTTP helper (Electron net.request alapú, timeout + JSON parse)
// ---------------------------------------------------------------------------

export interface HttpResponse<T = unknown> {
  ok: boolean;
  status: number;
  body?: T;
  errorMessage?: string;
  latencyMs: number;
}

function normalizeApiBase(apiUrl: string): string {
  let url = apiUrl.trim().replace(/\/+$/, '');
  if (!url.endsWith('/api/v1')) {
    url = `${url}/api/v1`;
  }
  return url;
}

/**
 * Általános HTTP segédfüggvény net.request alapon, timeouttal és JSON parse-al.
 *
 * <p>A wizard használja a public branches lekéréshez és a bootstrap-admin
 * híváshoz. Szándékosan NEM axios/fetch, mert az Electron main process-ben
 * a net modul tiszteletben tartja a rendszer proxy-beállításait és a Windows
 * certificate store-t.</p>
 */
async function httpJson<T = unknown>(
  fullUrl: string,
  options: {
    method: 'GET' | 'POST';
    body?: Record<string, unknown>;
    timeoutMs?: number;
    headers?: Record<string, string>;
  },
): Promise<HttpResponse<T>> {
  const { method, body, timeoutMs = 8000, headers: customHeaders } = options;
  const started = Date.now();

  return await new Promise<HttpResponse<T>>((resolve) => {
    let settled = false;
    const safeResolve = (r: HttpResponse<T>) => {
      if (settled) return;
      settled = true;
      resolve({ ...r, latencyMs: Date.now() - started });
    };

    let request: Electron.ClientRequest;
    try {
      request = net.request({ method, url: fullUrl });
    } catch (err: unknown) {
      safeResolve({
        ok: false,
        status: 0,
        errorMessage: err instanceof Error ? err.message : String(err),
        latencyMs: 0,
      });
      return;
    }

    const timer = setTimeout(() => {
      try { request.abort(); } catch { /* ignore */ }
      safeResolve({
        ok: false,
        status: 0,
        errorMessage: `Időtúllépés (${timeoutMs} ms)`,
        latencyMs: 0,
      });
    }, timeoutMs);

    request.setHeader('Accept', 'application/json');
    if (body !== undefined) {
      request.setHeader('Content-Type', 'application/json');
    }
    if (customHeaders) {
      for (const [k, v] of Object.entries(customHeaders)) {
        try { request.setHeader(k, v); } catch { /* ignore header errors */ }
      }
    }

    request.on('response', (response) => {
      clearTimeout(timer);
      const chunks: Buffer[] = [];
      response.on('data', (chunk: Buffer) => chunks.push(chunk));
      response.on('end', () => {
        const status = response.statusCode || 0;
        const raw = Buffer.concat(chunks).toString('utf8');
        let parsed: T | undefined;
        try {
          parsed = raw ? (JSON.parse(raw) as T) : undefined;
        } catch {
          parsed = undefined;
        }
        if (status >= 200 && status < 300) {
          safeResolve({ ok: true, status, body: parsed, latencyMs: 0 });
        } else {
          const message = typeof parsed === 'object' && parsed !== null && 'message' in parsed
            ? String((parsed as { message: unknown }).message)
            : `HTTP ${status}`;
          safeResolve({ ok: false, status, body: parsed, errorMessage: message, latencyMs: 0 });
        }
      });
    });

    request.on('error', (err) => {
      clearTimeout(timer);
      safeResolve({
        ok: false,
        status: 0,
        errorMessage: err instanceof Error ? err.message : String(err),
        latencyMs: 0,
      });
    });

    try {
      if (body !== undefined) {
        request.write(JSON.stringify(body));
      }
      request.end();
    } catch (err: unknown) {
      clearTimeout(timer);
      safeResolve({
        ok: false,
        status: 0,
        errorMessage: err instanceof Error ? err.message : String(err),
        latencyMs: 0,
      });
    }
  });
}

/**
 * httpJson hivasok retry wrapper-je ESET TLS proxy gepekhez.
 *
 * Ugyanaz a 3x retry minta mint az `api:fetch` IPC handler-ben (1s, 3s, 5s backoff).
 * Csak network error / timeout / 5xx eseten retry-zunk — 4xx (business hiba) NEM
 * megy ujra.
 */
async function httpJsonWithRetry<T = unknown>(
  fullUrl: string,
  options: {
    method: 'GET' | 'POST';
    body?: Record<string, unknown>;
    timeoutMs?: number;
    headers?: Record<string, string>;
  },
): Promise<HttpResponse<T>> {
  const MAX_RETRIES = 3;
  const RETRY_DELAYS = [1000, 3000, 5000];
  let last: HttpResponse<T> | null = null;

  for (let attempt = 0; attempt < MAX_RETRIES; attempt += 1) {
    last = await httpJson<T>(fullUrl, options);
    if (last.ok) return last;
    const status = last.status;
    const isNetworkErr = status === 0;
    const isServerErr = status >= 500 && status < 600;
    if (!isNetworkErr && !isServerErr) {
      return last; // 4xx business error — NE retry
    }
    if (attempt === MAX_RETRIES - 1) break;
    log.warn('[first-run httpJsonWithRetry] retry', attempt + 1, '/', MAX_RETRIES,
        'status=', status, 'error=', last.errorMessage, 'url=', fullUrl);
    await new Promise((r) => setTimeout(r, RETRY_DELAYS[attempt] ?? 5000));
  }
  return last as HttpResponse<T>;
}

// ---------------------------------------------------------------------------
// Publikus API
// ---------------------------------------------------------------------------

export function isFirstRun(): SetupCheckResult {
  const envPath = getEnvFilePath();
  if (!fs.existsSync(envPath)) {
    return { isFirstRun: true, envPath, reason: 'env-missing' };
  }
  const values = parseEnvFile(envPath);
  if (values.SETUP_COMPLETED !== '1') {
    return { isFirstRun: true, envPath, reason: 'setup-not-completed' };
  }
  if (!looksLikeValidSecret(values.JWT_SECRET)) {
    return { isFirstRun: true, envPath, reason: 'jwt-secret-invalid' };
  }
  if (!looksLikeValidApiUrl(values.VITE_API_URL)) {
    return { isFirstRun: true, envPath, reason: 'api-url-invalid' };
  }
  if (looksLikeStaleOfflineSetup(values)) {
    return { isFirstRun: true, envPath, reason: 'stale-offline-setup' };
  }
  return { isFirstRun: false, envPath };
}

/**
 * Iroda-lista lekérése a wizard 2. lépéshez.
 *
 * <p>Stratégia:</p>
 * <ol>
 *   <li>Ha van megadva {@code apiUrl} + {@code companyCode}, próbáljuk
 *       a backend <code>GET /api/v1/public/branches</code> endpointját.</li>
 *   <li>Ha a backend visszaad legalább 1 elemet → azt adjuk vissza.</li>
 *   <li>Ha üres válasz vagy hálózati hiba → fallback a statikus
 *       {@link DEFAULT_BRANCHES} listára, hogy a wizard ne akadjon el.</li>
 * </ol>
 *
 * <p>A válasz mindig legalább 1 elemet tartalmaz — a DEFAULT_BRANCHES-ban
 * 60 iroda van, és a backend sem indulhat fel branch nélkül.</p>
 */
export async function getBranches(apiUrl?: string, companyCode?: string): Promise<Branch[]> {
  const fallback = (): Branch[] => DEFAULT_BRANCHES.map((b) => ({ ...b }));

  if (!apiUrl || !companyCode) {
    log.info('[Setup] getBranches: nincs apiUrl/companyCode, static fallback.');
    return fallback();
  }

  try {
    const fetched = await fetchBranchesFromBackend(apiUrl, companyCode);
    if (fetched && fetched.length > 0) {
      log.info(`[Setup] getBranches: backend adott ${fetched.length} branch-et.`);
      return fetched;
    }
    log.info('[Setup] getBranches: backend 0 branch — static fallback.');
    return fallback();
  } catch (err: unknown) {
    log.warn('[Setup] getBranches: backend hiba, static fallback:',
      err instanceof Error ? err.message : String(err));
    return fallback();
  }
}

/**
 * Backend public branches endpoint hívása.
 *
 * @return a válasz tömb, vagy null ha hálózati hiba / nem 2xx.
 */
export async function fetchBranchesFromBackend(
  apiUrl: string,
  companyCode: string,
  timeoutMs = 6000,
): Promise<Branch[] | null> {
  const base = normalizeApiBase(apiUrl);
  const url = `${base}/public/branches?companyCode=${encodeURIComponent(companyCode)}`;
  const response = await httpJsonWithRetry<Array<{ code: string; name: string; city?: string; address?: string }>>(
    url,
    { method: 'GET', timeoutMs },
  );
  if (!response.ok || !Array.isArray(response.body)) {
    return null;
  }
  return response.body.map((b) => ({
    code: b.code,
    name: b.name,
    city: b.city ?? '',
    address: b.address,
  }));
}

/**
 * Megvárja a backend-et a {@code /actuator/health} endpointon.
 *
 * <p>Polling: 1000 ms-onként, max {@code maxWaitMs} ms-ig. Akkor sikeres,
 * ha a status 200 és a body {@code UP}.</p>
 */
export async function waitForBackend(
  apiUrl: string,
  maxWaitMs = 60000,
  pollIntervalMs = 1000,
): Promise<{ healthy: boolean; attempts: number; lastError?: string }> {
  const base = apiUrl.trim().replace(/\/+$/, '').replace(/\/api\/v1$/, '');
  // A production Caddy az /actuator/* path-ot 403-mal blokkolja (management csak 127.0.0.1).
  // Ezert publikus /api/v1/auth/bootstrap-status-t hasznaljuk health checkhez.
  const healthUrl = `${base}/api/v1/auth/bootstrap-status`;
  const deadline = Date.now() + maxWaitMs;
  let attempts = 0;
  let lastError: string | undefined;

  while (Date.now() < deadline) {
    attempts += 1;
    const resp = await httpJson<{ status?: string }>(healthUrl, {
      method: 'GET',
      timeoutMs: Math.min(pollIntervalMs + 500, 3000),
    });
    if (resp.ok) {
      // bootstrap-status 200 = backend el, status mezo nem kell
      return { healthy: true, attempts };
    } else {
      lastError = resp.errorMessage || `HTTP ${resp.status}`;
    }
    await new Promise((r) => setTimeout(r, pollIntervalMs));
  }
  return { healthy: false, attempts, lastError };
}

/**
 * Bootstrap admin hívás: a wizardban megadott admin jelszó elküldése a
 * backendnek, hogy beállítsa / frissítse az ADMIN role-ú workert.
 *
 * <p>A backend idempotens — második hívásnál HTTP 400. Ezt a hibát mi nem
 * tekintjük blokkolónak (már megtörtént), csak logoljuk.</p>
 */
export async function bootstrapAdmin(
  apiUrl: string,
  payload: {
    companyCode: string;
    workerCode: string;
    workerName: string;
    email?: string;
    newPassword: string;
  },
  timeoutMs = 15000,
): Promise<{ success: boolean; alreadyDone: boolean; errorMessage?: string }> {
  const base = normalizeApiBase(apiUrl);
  const url = `${base}/auth/bootstrap-admin`;

  const response = await httpJsonWithRetry<{ success?: boolean; message?: string }>(url, {
    method: 'POST',
    body: payload,
    timeoutMs,
  });

  if (response.ok && response.body?.success === true) {
    return { success: true, alreadyDone: false };
  }

  // 400 "beállítás már lezajlott" → idempotens no-op (ha valaki újra futtatja a wizardot)
  const msg = (response.body as { message?: string } | undefined)?.message || response.errorMessage || '';
  if (response.status === 400 && msg.includes('már lezajlott')) {
    log.warn('[Setup] Bootstrap admin már lezajlott — továbbmegyünk a .env írással.');
    return { success: true, alreadyDone: true };
  }

  return {
    success: false,
    alreadyDone: false,
    errorMessage: msg || `HTTP ${response.status}`,
  };
}

async function getBootstrapCompleted(apiUrl: string, timeoutMs = 8000): Promise<boolean | null> {
  const base = normalizeApiBase(apiUrl);
  const response = await httpJsonWithRetry<{ completed?: boolean }>(`${base}/auth/bootstrap-status`, {
    method: 'GET',
    timeoutMs,
  });
  if (!response.ok || typeof response.body?.completed !== 'boolean') {
    return null;
  }
  return response.body.completed;
}

// ============ v2.3.0: WORKER FIRST-TIME SETUP (valodi dolgozo + jelszo) ============

/**
 * POST /auth/first-time-worker-setup — a telepito wizard dolgozoi dropdown-bol
 * kivalasztott worker-hez allit be jelszot. NEM erolteti ADMIN role-t; a worker
 * sajat role-ja (CASHIER, MANAGER, SUPERVISOR stb.) megmarad.
 *
 * Ellentet a bootstrapAdmin-nal:
 *  - NEM one-shot (minden worker-nek sajat setup)
 *  - NEM ir rendszer-flag-et
 *  - JWT token-t ad vissza auto-login-hoz (most nem hasznaljuk, de keszen van)
 */
export async function workerFirstTimeSetup(
  apiUrl: string,
  payload: {
    companyCode: string;
    workerCode: string;
    newPassword: string;
    currentPassword?: string;
  },
  timeoutMs = 15000,
): Promise<{
  success: boolean;
  errorMessage?: string;
  workerIdentity?: {
    workerCode: string;
    workerName?: string;
    workerRole?: string;
    branchCode?: string;
  };
}> {
  const base = normalizeApiBase(apiUrl);
  const url = `${base}/auth/first-time-worker-setup`;

  const response = await httpJsonWithRetry<{
    success?: boolean;
    message?: string;
    workerCode?: string;
    workerName?: string;
    workerRole?: string;
    branchCode?: string;
  }>(url, {
    method: 'POST',
    body: payload,
    timeoutMs,
  });

  if (response.ok && response.body?.success === true) {
    return {
      success: true,
      workerIdentity: {
        workerCode: response.body.workerCode || payload.workerCode,
        workerName: response.body.workerName,
        workerRole: response.body.workerRole,
        branchCode: response.body.branchCode,
      },
    };
  }

  const msg = (response.body as { message?: string } | undefined)?.message || response.errorMessage || '';
  return {
    success: false,
    errorMessage: msg || `HTTP ${response.status}`,
  };
}


// ============ PENZTAR-ESZKOZ ONLINE REGISZTRACIO (V100) ============

/**
 * Pentarar-client eszkoz bejelentese a backend cash_register_device tablajaba.
 * A SetupWizard sikeres bootstrap-admin utan hivja, hogy a szerver tudja melyik
 * fizikai penztar telepult fel ehhez a branch-hez.
 */
export async function registerCashRegisterDevice(
  apiUrl: string,
  token: string,
  payload: {
    branchCode: string;    // NEM UUID - a code (pl. BR039), a szerver lookup-olja az id-t
    code: string;          // Egyedi eszkoz kod pl. BR039-penztar-3f2a9b0c
    name?: string;
    appMode: string;       // penztar | ertektar | ertekszallito | full
    appVersion?: string;
    deviceFingerprint?: string;
    osInfo?: string;
  },
  timeoutMs = 15000,
): Promise<{ success: boolean; deviceId?: string; errorMessage?: string }> {
  const base = normalizeApiBase(apiUrl);

  // A backend UUID-t var, nem branchCode-ot -> elso lepes: branch lookup a /public endpoint-on
  // (vagy masik endpoint). De a bootstrap-token-t birtokoljuk -> a /branches keresunk.
  try {
    // Step 1: branch UUID lookup by code
    const branchResp = await httpJsonWithRetry<Array<{ id: string; code: string }>>(
      `${base}/branches?code=${encodeURIComponent(payload.branchCode)}`,
      { method: 'GET', headers: { Authorization: `Bearer ${token}` }, timeoutMs },
    );
    if (!branchResp.ok || !Array.isArray(branchResp.body) || branchResp.body.length === 0) {
      return { success: false, errorMessage: `Branch lookup sikertelen: ${payload.branchCode}` };
    }
    const matchedBranch = branchResp.body.find((b) => b.code === payload.branchCode);
    if (!matchedBranch) {
      return { success: false, errorMessage: `Branch code nem egyezik a szerver valaszaval: ${payload.branchCode}` };
    }
    const branchId = matchedBranch.id;

    // Step 2: POST /cash-register/register
    const regResp = await httpJsonWithRetry<{ id: string }>(
      `${base}/cash-register/register`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Idempotency-Key': `setup-${payload.code}-${Date.now()}`,
        },
        body: {
          branchId,
          code: payload.code,
          name: payload.name,
          appMode: payload.appMode,
          appVersion: payload.appVersion,
          deviceFingerprint: payload.deviceFingerprint,
          osInfo: payload.osInfo,
        },
        timeoutMs,
      },
    );
    if (!regResp.ok || !regResp.body?.id) {
      const msg = (regResp.body as { message?: string } | undefined)?.message || regResp.errorMessage || `HTTP ${regResp.status}`;
      return { success: false, errorMessage: msg };
    }
    return { success: true, deviceId: regResp.body.id };
  } catch (err: unknown) {
    return { success: false, errorMessage: err instanceof Error ? err.message : String(err) };
  }
}

/**
 * Bootstrap-credentialokkel valo gyors login, hogy tokent szerezzunk a register hivashoz.
 */
export async function bootstrapLogin(
  apiUrl: string,
  payload: { companyCode: string; workerCode: string; password: string },
  timeoutMs = 10000,
): Promise<{ success: boolean; token?: string; errorMessage?: string }> {
  const base = normalizeApiBase(apiUrl);
  try {
    const resp = await httpJsonWithRetry<{ token?: string; roleSelectionRequired?: boolean; availableRoles?: Array<{ roleCode: string }> }>(
      `${base}/auth/login`,
      {
        method: 'POST',
        body: {
          companyCode: payload.companyCode,
          workerCode: payload.workerCode,
          password: payload.password,
        },
        timeoutMs,
      },
    );
    if (!resp.ok || !resp.body?.token) {
      const msg = (resp.body as { message?: string } | undefined)?.message || resp.errorMessage || `HTTP ${resp.status}`;
      return { success: false, errorMessage: msg };
    }
    // Ha role selection kell, vegyuk az elso rendelkezesre allot
    let token = resp.body.token;
    const firstRole = resp.body.availableRoles?.[0];
    if (resp.body.roleSelectionRequired && firstRole) {
      const selectedResp = await httpJsonWithRetry<{ token?: string }>(
        `${base}/auth/login/select-role`,
        {
          method: 'POST',
          body: { token, roleCode: firstRole.roleCode },
          timeoutMs,
        },
      );
      if (selectedResp.ok && selectedResp.body?.token) {
        token = selectedResp.body.token;
      }
    }
    return { success: true, token };
  } catch (err: unknown) {
    return { success: false, errorMessage: err instanceof Error ? err.message : String(err) };
  }
}
export async function testConnection(
  apiUrl: string,
  companyCode: string,
  username: string,
  password: string,
  timeoutMs = 5000,
): Promise<SetupConnectionTest> {
  const started = Date.now();

  let normalizedUrl = apiUrl.trim().replace(/\/+$/, '');
  if (!/^https?:\/\//i.test(normalizedUrl)) {
    return { success: false, errorMessage: 'A szerver URL-nek http:// vagy https:// előtaggal kell kezdődnie.' };
  }
  if (!normalizedUrl.endsWith('/api/v1')) {
    normalizedUrl = `${normalizedUrl}/api/v1`;
  }

  if (!username.trim() || !password) {
    const response = await httpJsonWithRetry<{ completed?: boolean }>(
      `${normalizedUrl}/auth/bootstrap-status`,
      { method: 'GET', timeoutMs },
    );
    return {
      success: response.ok,
      httpStatus: response.status || undefined,
      latencyMs: response.latencyMs,
      errorMessage: response.ok ? undefined : (response.errorMessage || `HTTP ${response.status}`),
    };
  }

  const loginUrl = `${normalizedUrl}/auth/login`;
  const response = await httpJsonWithRetry(loginUrl, {
    method: 'POST',
    body: {
        companyCode,
        workerCode: username,
        password,
    },
    timeoutMs,
  });

  // Barmilyen 2xx/4xx valasz azt jelenti, hogy a szerver elerheto.
  // 401/400 ebben a setup kontextusban ugyanugy kapcsolat-siker, csak
  // credential/business hiba.
  const reachable = response.status >= 200 && response.status < 500;
  return {
    success: reachable,
    httpStatus: response.status || undefined,
    latencyMs: response.latencyMs || (Date.now() - started),
    errorMessage: reachable ? undefined : (response.errorMessage || `Szerverhiba: HTTP ${response.status}`),
  };
}

export async function saveSetupConfig(payload: SetupSavePayload): Promise<SetupSaveResult> {
  const envPath = getEnvFilePath();
  const envDir = path.dirname(envPath);

  try {
    // --- Validáció ---
    if (!payload.branchCode || !payload.branchName) {
      return { success: false, envPath, errorMessage: 'Hiányzó iroda.' };
    }
    if (!payload.offlineMode) {
      if (!/^https?:\/\//i.test(payload.apiUrl)) {
        return { success: false, envPath, errorMessage: 'Érvénytelen szerver URL.' };
      }
      if (!payload.companyCode) {
        return { success: false, envPath, errorMessage: 'Hiányzó cégkód.' };
      }
    }
    if (!payload.adminPassword || payload.adminPassword.length < 8) {
      return { success: false, envPath, errorMessage: 'Az admin jelszónak legalább 8 karakteresnek kell lennie.' };
    }
    if (!payload.adminUsername || payload.adminUsername.trim().length === 0) {
      return { success: false, envPath, errorMessage: 'Hiányzó admin felhasználói kód.' };
    }

    // --- Végleges apiUrl resolve ---
    // Offline módban a lokál backend a default, online módban a user által
    // megadott Hetzner URL. A bootstrap-admin hívás ugyanezt az URL-t használja.
    const resolvedApiUrl = payload.offlineMode
      ? (payload.apiUrl && /^https?:\/\//i.test(payload.apiUrl) ? payload.apiUrl : 'http://localhost:8080/api/v1')
      : payload.apiUrl;

    // --- Backend bootstrap-admin hívás ---
    // Ez a 2.1.1 kritikus bugfix: a wizard admin jelszó most már valóban
    // eljut a backend-hez, és beíródik a worker.password_hash oszlopba.
    // Ha a backend nem elérhető (offline mód és nincs felhúzva a local service),
    // a wizard HIBÁT jelez, nem némán dobja el a jelszót, mint a 2.1.0-ban.

    log.info('[Setup] Backend elérés ellenőrzése:', resolvedApiUrl);
    const health = await waitForBackend(resolvedApiUrl, 45000, 1500);
    if (!health.healthy) {
      const detail = health.lastError ?? 'ismeretlen ok';
      const hint = payload.offlineMode
        ? 'Offline módban a lokális backend service-nek futnia kell. Ellenőrizd a "BestChange-Backend" Windows service-t (services.msc).'
        : 'Ellenőrizd a hálózatot és a Hetzner VPS elérhetőségét.';
      return {
        success: false,
        envPath,
        errorMessage: `A backend (${resolvedApiUrl}) ${health.attempts} próbálkozás után sem elérhető. ${hint} (Részletek: ${detail})`,
      };
    }
    log.info(`[Setup] Backend felhúzva ${health.attempts} próbálkozás után.`);

    const normalizedCompanyCode = (payload.companyCode || 'EBC').trim().toUpperCase();

    // v2.3.0: Eldontes — worker first-time setup vagy legacy admin bootstrap?
    // Ha a wizard-ban kivalasztott worker (selectedWorkerCode), az uj flow-t
    // hasznaljuk. Ha nincs, fallback a legacy bootstrap-admin-ra.
    let resolvedWorkerIdentity: {
      workerCode: string;
      workerName?: string;
      workerRole?: string;
      branchCode?: string;
    } | null = null;
    let preserveExistingBootstrapPassword = false;

    if (payload.selectedWorkerCode && payload.selectedWorkerCode.trim().length > 0) {
      log.info('[Setup] Worker first-time-setup uton (kivalasztott dolgozo):', payload.selectedWorkerCode);
      // Lezart bootstrap utan a backend a jelenlegi/kezdo worker jelszot is
      // keri, hogy worker kod ismeretevel ne lehessen publikus fiokot atvenni.
      const workerSetup = await workerFirstTimeSetup(resolvedApiUrl, {
        companyCode: normalizedCompanyCode,
        workerCode: payload.selectedWorkerCode.trim().toUpperCase(),
        newPassword: payload.adminPassword,
        currentPassword: payload.bootstrapPassword?.trim() || undefined,
      });
      if (!workerSetup.success) {
        const bootstrapCompleted = await getBootstrapCompleted(resolvedApiUrl);
        const hint = bootstrapCompleted === true
          ? ' Add meg a jelenlegi vagy kezdo dolgozoi jelszot a szerver lepesen.'
          : '';
        return {
          success: false,
          envPath,
          errorMessage: `A dolgozoi jelszo beallitasa nem sikerult: ${workerSetup.errorMessage ?? 'ismeretlen hiba'}${hint}`,
        };
      }
      if (workerSetup.success) {
        resolvedWorkerIdentity = workerSetup.workerIdentity ?? {
          workerCode: payload.selectedWorkerCode.trim().toUpperCase(),
          workerName: payload.selectedWorkerName,
          workerRole: payload.selectedWorkerRole,
        };
        log.info('[Setup] Worker first-time setup sikeres:', resolvedWorkerIdentity);
      }
    } else {
      // Legacy: bootstrap-admin (uj admin worker + rendszer-flag)
      const bootstrap = await bootstrapAdmin(resolvedApiUrl, {
        companyCode: normalizedCompanyCode,
        workerCode: payload.adminUsername.trim().toUpperCase(),
        workerName: payload.adminUsername.trim(),
        email: undefined,
        newPassword: payload.adminPassword,
      });
      if (!bootstrap.success) {
        return {
          success: false,
          envPath,
          errorMessage: `Az admin jelszó beállítása nem sikerült a backend-en: ${bootstrap.errorMessage ?? 'ismeretlen hiba'}`,
        };
      }
      if (bootstrap.alreadyDone) {
        log.info('[Setup] Bootstrap már lefutott ezen a rendszeren — folytatjuk.');
        preserveExistingBootstrapPassword = true;
      } else {
        log.info('[Setup] Bootstrap admin sikeresen beállítva a backend-ben.');
      }
      resolvedWorkerIdentity = {
        workerCode: payload.adminUsername.trim().toUpperCase(),
        workerName: 'Rendszer Admin',
        workerRole: 'ADMIN',
      };
    }

    const effectiveBootstrapCredentials =
      resolveEffectiveBootstrapCredentials(
        payload,
        resolvedWorkerIdentity,
        { preserveExistingPassword: preserveExistingBootstrapPassword },
      );

    // --- Kulcs generálás ---
    const jwtSecret = generateSecretHex(32);               // 256 bit
    const sqlCipherKey = generateSecretHex(32);            // 256 bit
    const offlineLicenseSecret = generateSecretHex(32);    // 256 bit

    // --- .env írás (atomikus: .env.tmp → rename) ---
    if (!fs.existsSync(envDir)) {
      fs.mkdirSync(envDir, { recursive: true });
    }
    const content = buildEnvFileContent({
      branchCode: payload.branchCode,
      branchName: payload.branchName,
      apiUrl: resolvedApiUrl,
      companyCode: normalizedCompanyCode,
      bootstrapUsername: effectiveBootstrapCredentials.bootstrapUsername,
      bootstrapPassword: effectiveBootstrapCredentials.bootstrapPassword,
      jwtSecret,
      sqlCipherKey,
      offlineLicenseSecret,
      offlineMode: payload.offlineMode,
    });

    const tmpPath = `${envPath}.tmp`;
    fs.writeFileSync(tmpPath, content, { encoding: 'utf8', mode: 0o600 });
    fs.renameSync(tmpPath, envPath);

    log.info('[Setup] .env sikeresen kiírva:', envPath);

    // v2.1.4: Az SQLite server_url config-ba is beirjuk, a syncEngine ezt olvassa
    // NGM: az installUuid-t a try BLOKK ELOTT generaljuk, hogy kivetel eseten se legyen ures.
    let installUuid: string = crypto.randomUUID();
    try {
      const { setConfig, getConfig, deleteConfig } = await import('./sqlite');
      setConfig('server_url', resolvedApiUrl);
      if (payload.branchCode) {
        setConfig('branch_code', payload.branchCode);
      }
      if (payload.appMode) {
        setConfig('app_mode', payload.appMode);
        log.info('[Setup] SQLite app_mode elmentve:', payload.appMode);
      }
      setConfig('bootstrap_company_code', normalizedCompanyCode);
      if (effectiveBootstrapCredentials.bootstrapUsername) {
        setConfig('bootstrap_worker_code', effectiveBootstrapCredentials.bootstrapUsername);
      }
      persistBootstrapPasswordConfig(effectiveBootstrapCredentials.bootstrapPassword, setConfig, deleteConfig);
      // v2.3.0: a telepito-ban kivalasztott (es jelszot beallitott) dolgozo identity
      // tarolasa — ezt olvassa a LoginPage prefill-hez es UI displayhez.
      if (resolvedWorkerIdentity) {
        setConfig('worker_code', resolvedWorkerIdentity.workerCode);
        if (resolvedWorkerIdentity.workerName) {
          setConfig('worker_name', resolvedWorkerIdentity.workerName);
        }
        if (resolvedWorkerIdentity.workerRole) {
          setConfig('worker_role', resolvedWorkerIdentity.workerRole);
        }
        log.info('[Setup] Worker identity mentve SQLite configba:', resolvedWorkerIdentity);
      }
      // V100: offline_mode flag — a SyncEngine ezt nezi, es offline modban NEM kuld
      setConfig('offline_mode', payload.offlineMode ? 'true' : 'false');
      // V100: stabil install uuid — eszkoz-azonositohoz
      const existingUuid = getConfig('install_uuid');
      if (existingUuid) {
        installUuid = existingUuid; // re-install eseten megtartjuk a regit
      } else {
        setConfig('install_uuid', installUuid); // mar generalva a try elott
      }
      log.info('[Setup] SQLite server_url elmentve:', resolvedApiUrl, 'offline_mode:', payload.offlineMode);
    } catch (err) {
      log.warn('[Setup] SQLite server_url mentes sikertelen:', err);
    }

    // V100: Online-modban regisztraljuk a penztar-eszkozt a backend-en
    if (!payload.offlineMode
        && effectiveBootstrapCredentials.bootstrapUsername
        && effectiveBootstrapCredentials.bootstrapPassword) {
      try {
        log.info('[Setup] V100 device-reg: az effektív bootstrap worker/jelszó párossal loginolunk.');
        const login = await bootstrapLogin(resolvedApiUrl, {
          companyCode: normalizedCompanyCode,
          workerCode: effectiveBootstrapCredentials.bootstrapUsername,
          password: effectiveBootstrapCredentials.bootstrapPassword,
        });
        if (login.success && login.token) {
          const deviceCode = `${payload.branchCode}-${payload.appMode ?? 'penztar'}-${installUuid.slice(0, 8)}`;
          const reg = await registerCashRegisterDevice(resolvedApiUrl, login.token, {
            branchCode: payload.branchCode,
            code: deviceCode,
            name: payload.branchName ? `${payload.branchName} — ${payload.appMode ?? 'penztar'}` : deviceCode,
            appMode: payload.appMode ?? 'penztar',
            appVersion: app.getVersion(),
            deviceFingerprint: installUuid,
            osInfo: `${process.platform} ${process.arch}`,
          });
          if (reg.success && reg.deviceId) {
            const { setConfig } = await import('./sqlite');
            setConfig('cash_register_device_id', reg.deviceId);
            setConfig('cash_register_device_code', deviceCode);
            log.info('[Setup] Penztar-eszkoz online regisztralva:', reg.deviceId);
          } else {
            log.warn('[Setup] Penztar-eszkoz regisztracio sikertelen:', reg.errorMessage);
            // Nem blokkolo — a telepites tovabb megy offline modban
          }
        } else {
          log.warn('[Setup] Bootstrap-login sikertelen a device regisztraciohoz:', login.errorMessage);
        }
      } catch (err: unknown) {
        log.warn('[Setup] Penztar-eszkoz regisztracio kivetel:', err instanceof Error ? err.message : err);
      }
    }

    // --- Relaunch ---
    setTimeout(() => {
      try {
        app.relaunch();
        app.exit(0);
      } catch (err) {
        log.error('[Setup] Relaunch hiba:', err);
      }
    }, 500);

    return { success: true, envPath };
  } catch (err: unknown) {
    log.error('[Setup] saveSetupConfig hiba:', err);
    return {
      success: false,
      envPath,
      errorMessage: err instanceof Error ? err.message : String(err),
    };
  }
}
