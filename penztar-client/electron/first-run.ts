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

import { app, net } from 'electron';
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
  { code: '101', name: 'Központi Pénztár',        city: 'Budapest',       address: 'Belváros' },
  { code: '102', name: 'Váci úti Fiók',           city: 'Budapest',       address: 'Váci út' },
  { code: '103', name: 'Deák tér',                city: 'Budapest' },
  { code: '104', name: 'Nyugati pályaudvar',      city: 'Budapest' },
  { code: '105', name: 'Keleti pályaudvar',       city: 'Budapest' },
  { code: '106', name: 'Déli pályaudvar',         city: 'Budapest' },
  { code: '107', name: 'Blaha Lujza tér',         city: 'Budapest' },
  { code: '108', name: 'Móricz Zsigmond körtér',  city: 'Budapest' },
  { code: '109', name: 'Ferenciek tere',          city: 'Budapest' },
  { code: '110', name: 'Astoria',                 city: 'Budapest' },
  { code: '111', name: 'Árkád (Örs vezér tere)',  city: 'Budapest' },
  { code: '112', name: 'Mammut',                  city: 'Budapest' },
  { code: '113', name: 'WestEnd',                 city: 'Budapest' },
  { code: '114', name: 'Allee',                   city: 'Budapest' },
  { code: '115', name: 'Aréna Mall',              city: 'Budapest' },
  { code: '116', name: 'Campona',                 city: 'Budapest' },
  { code: '201', name: 'Debrecen Fő tér',         city: 'Debrecen' },
  { code: '202', name: 'Debrecen Fórum',          city: 'Debrecen' },
  { code: '301', name: 'Szeged Kárász utca',      city: 'Szeged' },
  { code: '302', name: 'Szeged Árkád',            city: 'Szeged' },
  { code: '401', name: 'Pécs Széchenyi tér',      city: 'Pécs' },
  { code: '402', name: 'Pécs Árkád',              city: 'Pécs' },
  { code: '501', name: 'Győr Belváros',           city: 'Győr' },
  { code: '502', name: 'Győr Árkád',              city: 'Győr' },
  { code: '601', name: 'Miskolc Széchenyi',       city: 'Miskolc' },
  { code: '602', name: 'Miskolc Plaza',           city: 'Miskolc' },
  { code: '701', name: 'Nyíregyháza Belváros',    city: 'Nyíregyháza' },
  { code: '801', name: 'Kecskemét Főtér',         city: 'Kecskemét' },
  { code: '802', name: 'Kecskemét Malom',         city: 'Kecskemét' },
  { code: '901', name: 'Székesfehérvár',          city: 'Székesfehérvár' },
  { code: '902', name: 'Székesfehérvár Alba',     city: 'Székesfehérvár' },
  { code: '1001', name: 'Veszprém',               city: 'Veszprém' },
  { code: '1101', name: 'Zalaegerszeg',           city: 'Zalaegerszeg' },
  { code: '1201', name: 'Szombathely',            city: 'Szombathely' },
  { code: '1202', name: 'Szombathely Árkád',      city: 'Szombathely' },
  { code: '1301', name: 'Sopron',                 city: 'Sopron' },
  { code: '1401', name: 'Tatabánya',              city: 'Tatabánya' },
  { code: '1501', name: 'Kaposvár',               city: 'Kaposvár' },
  { code: '1601', name: 'Eger',                   city: 'Eger' },
  { code: '1701', name: 'Salgótarján',            city: 'Salgótarján' },
  { code: '1801', name: 'Szolnok',                city: 'Szolnok' },
  { code: '1901', name: 'Békéscsaba',             city: 'Békéscsaba' },
  { code: '2001', name: 'Hódmezővásárhely',       city: 'Hódmezővásárhely' },
  { code: '2101', name: 'Szekszárd',              city: 'Szekszárd' },
  { code: '2201', name: 'Dunaújváros',            city: 'Dunaújváros' },
  { code: '2301', name: 'Érd',                    city: 'Érd' },
  { code: '2401', name: 'Vác',                    city: 'Vác' },
  { code: '2501', name: 'Gödöllő',                city: 'Gödöllő' },
  { code: '2601', name: 'Cegléd',                 city: 'Cegléd' },
  { code: '2701', name: 'Nagykanizsa',            city: 'Nagykanizsa' },
  { code: '2801', name: 'Hatvan',                 city: 'Hatvan' },
  { code: '2901', name: 'Gyöngyös',               city: 'Gyöngyös' },
  { code: '3001', name: 'Ózd',                    city: 'Ózd' },
  { code: '3101', name: 'Baja',                   city: 'Baja' },
  { code: '3201', name: 'Siófok',                 city: 'Siófok' },
  { code: '3301', name: 'Balatonfüred',           city: 'Balatonfüred' },
  { code: '3401', name: 'Keszthely',              city: 'Keszthely' },
  { code: '3501', name: 'Hévíz',                  city: 'Hévíz' },
  { code: '3601', name: 'Sárvár',                 city: 'Sárvár' },
  { code: '3701', name: 'Esztergom',              city: 'Esztergom' },
  { code: '3801', name: 'Komárom',                city: 'Komárom' },
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

function generateSecretHex(bytes: number): string {
  return crypto.randomBytes(bytes).toString('hex');
}

function escapeEnvValue(value: string): string {
  // Sor-szeparáló karaktereket nem engedünk meg; double-quote-olva tárolunk
  // hogy a dotenv parser megbízhatóan visszaolvassa.
  const cleaned = value.replace(/[\r\n]/g, ' ');
  return `"${cleaned.replace(/"/g, '\\"')}"`;
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
  return { isFirstRun: false, envPath };
}

export function getBranches(): Branch[] {
  return DEFAULT_BRANCHES.map((b) => ({ ...b }));
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
  const loginUrl = `${normalizedUrl}/auth/login`;

  return await new Promise<SetupConnectionTest>((resolve) => {
    let settled = false;
    const safeResolve = (v: SetupConnectionTest) => {
      if (settled) return;
      settled = true;
      resolve({ ...v, latencyMs: Date.now() - started });
    };

    let request: Electron.ClientRequest;
    try {
      request = net.request({ method: 'POST', url: loginUrl });
    } catch (err: unknown) {
      safeResolve({
        success: false,
        errorMessage: err instanceof Error ? err.message : String(err),
      });
      return;
    }

    const timer = setTimeout(() => {
      try { request.abort(); } catch { /* ignore */ }
      safeResolve({ success: false, errorMessage: `Időtúllépés (${timeoutMs} ms)` });
    }, timeoutMs);

    request.setHeader('Content-Type', 'application/json');
    request.on('response', (response) => {
      clearTimeout(timer);
      // Bármilyen 2xx/4xx válasz azt jelenti, hogy a szerver elérhető.
      // 401 ugyanolyan jó ebben a kontextusban, mint 200 — csak a rossz jelszót jelzi.
      if (response.statusCode >= 200 && response.statusCode < 500) {
        safeResolve({ success: true, httpStatus: response.statusCode });
      } else {
        safeResolve({
          success: false,
          httpStatus: response.statusCode,
          errorMessage: `Szerverhiba: HTTP ${response.statusCode}`,
        });
      }
      // Tartalom eldobható, csak a statusCode érdekes itt.
      response.on('data', () => { /* drain */ });
      response.on('end', () => { /* drain */ });
    });
    request.on('error', (err) => {
      clearTimeout(timer);
      safeResolve({
        success: false,
        errorMessage: err instanceof Error ? err.message : String(err),
      });
    });

    try {
      request.write(JSON.stringify({
        companyCode,
        workerCode: username,
        password,
      }));
      request.end();
    } catch (err: unknown) {
      clearTimeout(timer);
      safeResolve({
        success: false,
        errorMessage: err instanceof Error ? err.message : String(err),
      });
    }
  });
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
      apiUrl: payload.offlineMode ? (payload.apiUrl || 'http://localhost:8080/api/v1') : payload.apiUrl,
      companyCode: payload.companyCode,
      bootstrapUsername: payload.bootstrapUsername ?? '',
      bootstrapPassword: payload.bootstrapPassword ?? '',
      jwtSecret,
      sqlCipherKey,
      offlineLicenseSecret,
      offlineMode: payload.offlineMode,
    });

    const tmpPath = `${envPath}.tmp`;
    fs.writeFileSync(tmpPath, content, { encoding: 'utf8', mode: 0o600 });
    fs.renameSync(tmpPath, envPath);

    log.info('[Setup] .env sikeresen kiírva:', envPath);

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
