/**
import crypto from 'node:crypto';
 * SyncEngine — Offline → Online szinkronizáció.
 *
 * Feladatai:
 * 1. Pending tranzakciók szinkronizálása (30s intervallum)
 * 2. Árfolyamok letöltése és SQLite cache frissítése
 * 3. Körlevelek letöltése
 *
 * Életciklus:
 * - app.whenReady() → syncEngine.start()
 * - app.on('will-quit') → syncEngine.stop()
 */

import {
  getPendingTransactions,
  getPendingConversions,
  getPendingBankTransactions,
  getPendingStornos,
  getReassertableTransactions,
  getReassertableConversions,
  getReassertableStornos,
  getReassertableBankTransactions,
  markTransactionSynced,
  markTransactionSyncError,
  markConversionSynced,
  markBankTransactionSynced,
  markStornoSynced,
  getConfig,
  setConfig,
  deleteConfig,
  getDb,
  saveDatabase,
  getPendingDistributions,
  markDistributionSynced,
  getPendingTransfers,
  markTransferSynced,
  getPendingTransferStornos,
  markTransferStornoSynced,
  getPendingShipmentReceipts,
  markShipmentReceiptSynced,
  markShipmentReceiptTerminalError,
  markShipmentReceiptRetryError,
  getPendingCircularReplies,
  markCircularReplySynced,
  getPendingCollections,
  markCollectionSynced,
  getPendingStocktakeItems,
  markStocktakeItemSynced,
  markStocktakeItemError,
  getPendingHandoverOperations,
  markHandoverOperationSynced,
  getPendingScannedDocuments,
  markScannedDocumentSynced,
  markScannedDocumentSyncError,
  saveCachedBranchStatus,
  saveCachedCashDesk,
  saveCachedHandlingFeeConfig,
  saveCachedWorker,
  type PendingBankTransactionRow,
  type PendingConversionRow,
  type PendingHandoverOperationRow,
  type PendingStornoRow,
  type PendingTransactionRow,
} from './sqlite';
import { readDecryptedScan, deleteScanFiles } from './scanner';
import { safeStorage } from 'electron';
import log from 'electron-log';
import type { Database, SqlValue } from 'sql.js';
import {
  collectRoleCodes,
  normalizeSetupAppMode,
  preferredRoleCodesForAppMode,
} from './setup-app-mode-roles';
import {
  printReceipt,
  PRINTER_CONFIG_KEY,
  SERIAL_PORT_CONFIG_KEY,
  type PrintReceiptData,
} from './printer';
import { sanitizeStoredServerUrl } from './config-guard';
import { isAllowedUrl, fetchViaElectronNet } from './api-proxy';
import { sanitizeSyncErrorMessage } from './sync-error-sanitizer';
import { isBusinessRetryWithheld } from './business-retry';

// --- Típusok ---

export interface SyncResult {
  synced: number;
  failed: number;
  errors: string[];
}

interface SyncStatus {
  lastSyncAt: string | null;
  lastSyncResult: SyncResult | null;
  isRunning: boolean;
}

type RatePrintOutboxDb = Pick<Database, 'run' | 'exec'>;

// FK-097 WU-13: a /branch-fee-config/own válasz-alakja (csak LIVE mezők — a DRAFT
// sosem hagyja el a szervert; FR-8 első védelmi vonala szerver-oldali, a második a
// syncHandlingFeeConfig kliens-oldali DRAFT-utasítása).
interface BranchFeeConfigLiveResponse {
  branchId: string;
  branchCode: string;
  feeMode: 'NONE' | 'BRACKET' | 'PER_MILLE';
  perMilleRate: number | null;
  perMilleCap: number | null;
  validFrom: string;
  brackets: Array<{
    bracketOrder: number;
    upperLimit: number;
    feeAmount: number;
    active?: boolean;
  }>;
}

interface RateResponse {
  currencyCode: string;
  buyRate: number;
  sellRate: number;
  unit: number;
  updatedAt: string;
  officialRate?: number | null;
  limit1Amount?: number | null;
  limit1BuyRate?: number | null;
  limit1SellRate?: number | null;
  limit2Amount?: number | null;
  limit2BuyRate?: number | null;
  limit2SellRate?: number | null;
  limit3Amount?: number | null;
  limit3BuyRate?: number | null;
  limit3SellRate?: number | null;
}

interface RatePrintObligationResponse {
  distributionId: string;
  masterRateId: string;
  currencyCode: string;
  versionNumber: number;
  baseBuyRate: number;
  baseSellRate: number;
  officialRate?: number | null;
  limit1Amount?: number | null;
  limit1BuyRate?: number | null;
  limit1SellRate?: number | null;
  limit2Amount?: number | null;
  limit2BuyRate?: number | null;
  limit2SellRate?: number | null;
  limit3Amount?: number | null;
  limit3BuyRate?: number | null;
  limit3SellRate?: number | null;
  validFrom: string;
  printProofToken: string;
}

interface CircularResponse {
  id: number;
  subject: string;
  body: string;
  sender: string;
  sentAt: string;
}

interface BranchStatusResponse {
  code: string;
  name: string;
  companyId: number;
  lastSyncAt: string | null;
  onlineStatus: string;
  totalHufValue: number;
  dailyTurnover: number;
  cashBalances: unknown[];
}

interface WorkerResponse {
  id: number;
  workerCode?: string | null;
  fullName: string;
  role?: string | null;
  branchId?: string | null;
  branchCode?: string | null;
  branchName?: string | null;
  companyId?: string | null;
  companyCode?: string | null;
  active?: boolean | null;
}

interface CashDeskResponse {
  id: string;
  code: string;
  name: string;
  companyId?: string | null;
  city?: string | null;
  /** Fejléc-javítás 2026-06-11 (NFR-1 offline): utca/házszám a bizonylat-fejléchez. */
  address?: string | null;
  /** Fejléc-javítás 2026-06-11 (NFR-1 offline): irányítószám a bizonylat-fejléchez. */
  zipCode?: string | null;
  /** Fejléc-javítás 2026-06-11 (NFR-1 offline): telefonszám a bizonylat-fejléchez. */
  phone?: string | null;
  /** Bizonylat-doc 2. kör TBD-5 (2026-06-12): a NUMERIKUS KESZLEX terület-kód (pl. "20") az
   *  "[azonosító]. [név]" fejléc-formátumhoz — a BranchDto.regionCode mező (a .region a
   *  szöveges terület-név, Copilot #1114). */
  regionCode?: string | null;
  isActive?: boolean | null;
}

interface LoginResponse {
  token: string;
  roleSelectionRequired?: boolean;
  roles?: string[];
  availableRoles?: Array<{ roleCode?: string; code?: string }>;
}

interface BootstrapCredentials {
  companyCode: string;
  workerCode: string;
  password: string;
  roleCode?: string | null;
  appMode?: string | null;
}

export function selectBootstrapRoleCode(
  appMode: string | null | undefined,
  explicitRoleCode: string | null | undefined,
  login: Pick<LoginResponse, 'roles' | 'availableRoles'>,
): string | null {
  const roles = collectRoleCodes(login);
  const preferred = preferredRoleCodesForAppMode(appMode);
  const appModeRole = preferred.find((roleCode) => roles.has(roleCode));
  if (appModeRole) {
    return appModeRole;
  }

  const explicit = explicitRoleCode?.trim();
  if (explicit && (roles.size === 0 || roles.has(explicit))) {
    return explicit;
  }

  if (normalizeSetupAppMode(appMode) === 'full' && roles.size > 0) {
    return [...roles][0] ?? null;
  }

  return roles.size === 1 ? ([...roles][0] ?? null) : null;
}

class HttpStatusError extends Error {
  readonly status: number;
  /** FK-071 FR-1: a szerver ErrorResponse.message mezője (ha kiolvasható volt). */
  readonly serverMessage: string | null;

  constructor(status: number, statusText: string, serverMessage?: string | null) {
    super(
      serverMessage
        ? `HTTP ${status}: ${statusText} — ${serverMessage}`
        : `HTTP ${status}: ${statusText}`,
    );
    this.status = status;
    this.serverMessage = serverMessage ?? null;
  }
}

/**
 * FK-071 FR-1: nem-OK válasznál kiolvassa a backend GlobalExceptionHandler
 * egységes ErrorResponse body-jának `message` mezőjét ({ timestamp, status,
 * error, message [, fieldErrors] }), hogy az elutasítás érdemi oka (pl.
 * árfolyam-eltérés, fedezethiány) tartósan tárolható legyen a pending soron.
 * Nem-JSON vagy olvashatatlan body esetén null — a hívó a
 * "HTTP {status}: {statusText}" fallbacket használja.
 */
async function readServerErrorMessage(response: Response): Promise<string | null> {
  try {
    const text = await response.text();
    if (!text.trim()) {
      return null;
    }
    const parsed = JSON.parse(text) as { message?: unknown };
    return typeof parsed.message === 'string' && parsed.message.trim() ? parsed.message : null;
  } catch {
    return null;
  }
}

/**
 * FK-071 MEDIUM-E (Codex security review): hiba-üzenet kettébontása.
 * A NYERS (raw) változaton fut a PR #116 business-error detektor és minden
 * tartalom-alapú osztályozás (auth/hálózat/409/VV-kód), a MASZKOLT (masked)
 * változat kerül minden tartós tárolásba (sync_error, kísérlet-napló),
 * naplóba és a SyncResult-ba. Sorrend: detektor → maszkolás → tárolás/log.
 */
function splitSyncError(err: unknown): { raw: string; masked: string } {
  const raw = err instanceof Error ? err.message : String(err);
  return { raw, masked: sanitizeSyncErrorMessage(raw) };
}

function isAuthStatusError(err: unknown): boolean {
  return err instanceof HttpStatusError && (err.status === 401 || err.status === 403);
}

function isPermanentRatePrintAckError(err: unknown): boolean {
  return (
    err instanceof HttpStatusError &&
    err.status >= 400 &&
    err.status < 500 &&
    err.status !== 401 &&
    err.status !== 403 &&
    err.status !== 408 &&
    err.status !== 429
  );
}

/**
 * Multi-tenant sync guard: TRUE when the pending row's recorded company code is
 * provably different from the active session company code. NULL/empty on either
 * side means no proven mismatch, so legacy rows are not permanently blocked.
 */
export function companyMismatch(
  rowCompanyCode: string | null | undefined,
  sessionCompanyCode: string | null | undefined,
): boolean {
  const row = rowCompanyCode?.trim();
  const session = sessionCompanyCode?.trim();
  return Boolean(row && session && row !== session);
}

function recordCompanyMismatch(
  result: SyncResult,
  entityLabel: string,
  id: number,
  rowCompanyCode: string | null | undefined,
  sessionCompanyCode: string | null | undefined,
): string {
  const row = rowCompanyCode?.trim() ?? '';
  const session = sessionCompanyCode?.trim() ?? '';
  const message = `Cégeltérés: a tétel a(z) '${row}' céghez tartozik, az aktív cég '${session}' — a tétel visszatartva`;
  result.failed++;
  result.errors.push(`${entityLabel} #${id}: ${message}`);
  log.warn('[SyncEngine] Cégeltérés miatt tétel visszatartva', {
    entityLabel,
    id,
    rowCompanyCode: row,
    sessionCompanyCode: session,
  });
  return message;
}

function standaloneCompanyMismatchMessage(
  entityLabel: string,
  id: number,
  rowCompanyCode: string | null | undefined,
  sessionCompanyCode: string | null | undefined,
): string | null {
  if (!companyMismatch(rowCompanyCode, sessionCompanyCode)) {
    return null;
  }
  const row = rowCompanyCode?.trim() ?? '';
  const session = sessionCompanyCode?.trim() ?? '';
  const message = `Cégeltérés: a tétel a(z) '${row}' céghez tartozik, az aktív cég '${session}' — a tétel visszatartva`;
  log.warn('[SyncEngine] Cégeltérés miatt tétel visszatartva', {
    entityLabel,
    id,
    rowCompanyCode: row,
    sessionCompanyCode: session,
  });
  return message;
}

// --- HTTP kliens (lightweight, nincs axios az electron main-ben) ---

async function httpGet<T>(url: string, token: string | null): Promise<T> {
  try {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
    };
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    const response = await fetch(url, {
      method: 'GET',
      headers,
      signal: AbortSignal.timeout(10_000),
    });

    if (!response.ok) {
      throw new HttpStatusError(response.status, response.statusText);
    }

    return response.json() as Promise<T>;
  } catch (err) {
    // FK-071 MEDIUM-E: az err objektum message-e szerver-üzenetet hordozhat — maszkolva logolunk.
    log.error('[SyncEngine] httpGet failed:', { url, err: splitSyncError(err).masked });
    throw err;
  }
}

async function httpPost<T>(
  url: string,
  body: Record<string, unknown>,
  token: string | null,
  idempotencyKey?: string,
  allowEmptyResponse = false,
): Promise<T> {
  try {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      // Idempotency-Key: megakadályozza a duplikált tranzakciókat újrapróbálkozás esetén
      'Idempotency-Key': idempotencyKey ?? crypto.randomUUID(),
    };
    const companyCode = getConfig('bootstrap_company_code')?.trim();
    if (companyCode) {
      headers['X-Company-Code'] = companyCode;
    }
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    const response = await fetch(url, {
      method: 'POST',
      headers,
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(15_000),
    });

    if (!response.ok) {
      // FK-071 FR-1: a szerver érdemi hibaüzenetét (ErrorResponse.message) is
      // továbbvisszük, nem csak a státuszsort — a pending soron ez tárolódik.
      throw new HttpStatusError(
        response.status,
        response.statusText,
        await readServerErrorMessage(response),
      );
    }

    if (allowEmptyResponse) {
      if (response.status === 204) return undefined as T;
      const responseText = await response.text();
      if (!responseText.trim()) return undefined as T;
      return JSON.parse(responseText) as T;
    }
    return response.json() as Promise<T>;
  } catch (err) {
    // FK-071 MEDIUM-E: a HttpStatusError message-e a szerver-üzenetet (PII-t) hordozhatja — maszkolva.
    log.error('[SyncEngine] httpPost failed:', { url, err: splitSyncError(err).masked });
    throw err;
  }
}

/**
 * FKH-032 FR-1/FR-3: azonnali (mentéskori) küldés a main-process `net.request`
 * (`fetchViaElectronNet`) csatornán — UGYANAZON az útvonalon, amit a renderer
 * `useOnlineStatus` health-check-je és az `api:fetch` IPC használ. Az undici
 * `fetch`-et egyes TLS-proxyk (ESET/Kaspersky/Bitdefender) blokkolják, miközben a
 * Chromium network stack átmegy rajtuk — ez okozta az "Online jelző zöld, a küldés
 * mégis hálózati hibával bukik" ellentmondást.
 *
 * <p>Szignatúrája szándékosan azonos a {@link httpPost}-éval, hogy a
 * {@link SyncEngine.syncTransaction} poster-injektálással cserélhesse ki.
 * Timeout: NFR-1 szerint 5000 ms (nem a 15 mp-es általános érték).
 */
const IMMEDIATE_SYNC_TIMEOUT_MS = 5_000;

async function httpPostViaNet<T>(
  url: string,
  body: Record<string, unknown>,
  token: string | null,
  idempotencyKey?: string,
  allowEmptyResponse = false,
): Promise<T> {
  try {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      // FKH-032 FR-5: a mentéskor generált, TÁROLT kulcs megy fel — a backend ez
      // alapján dedupol, így az azonnali kísérlet + háttér-szinkron nem duplikál.
      'Idempotency-Key': idempotencyKey ?? crypto.randomUUID(),
    };
    const companyCode = getConfig('bootstrap_company_code')?.trim();
    if (companyCode) {
      headers['X-Company-Code'] = companyCode;
    }
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    const response = await fetchViaElectronNet({
      method: 'POST',
      url,
      body: JSON.stringify(body),
      headers,
      timeoutMs: IMMEDIATE_SYNC_TIMEOUT_MS,
    });

    if (!response.ok) {
      let serverMessage: string | null = null;
      try {
        const parsed = JSON.parse(response.body) as { message?: unknown };
        if (typeof parsed.message === 'string' && parsed.message.trim()) {
          serverMessage = parsed.message;
        }
      } catch {
        /* nem-JSON body → marad a status-alapú fallback */
      }
      throw new HttpStatusError(response.status, response.statusText, serverMessage);
    }

    if (allowEmptyResponse && !response.body.trim()) {
      return undefined as T;
    }
    return (response.body.trim() ? JSON.parse(response.body) : undefined) as T;
  } catch (err) {
    log.error('[SyncEngine] httpPostViaNet failed:', { url, err: splitSyncError(err).masked });
    throw err;
  }
}

async function httpPostMultipart(
  url: string,
  body: FormData,
  token: string | null,
  idempotencyKey?: string,
): Promise<Response> {
  try {
    const headers: Record<string, string> = {
      'Idempotency-Key': idempotencyKey ?? crypto.randomUUID(),
    };
    const companyCode = getConfig('bootstrap_company_code')?.trim();
    if (companyCode) {
      headers['X-Company-Code'] = companyCode;
    }
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    const response = await fetch(url, {
      method: 'POST',
      headers,
      body,
      signal: AbortSignal.timeout(15_000),
    });

    if (!response.ok) {
      throw new HttpStatusError(response.status, response.statusText);
    }

    return response;
  } catch (err) {
    log.error('[SyncEngine] httpPostMultipart failed:', { url, err: splitSyncError(err).masked });
    throw err;
  }
}

// --- SyncEngine ---

export class SyncEngine {
  private intervalId: ReturnType<typeof setInterval> | null = null;
  private syncAllInFlight: Promise<SyncResult> | null = null;
  private syncAllInFlightTokenKey: string | null = null;
  private shipmentReceiptSyncInFlight: Promise<SyncResult> | null = null;
  private lastTokenValidationAt = 0;
  private readonly tokenValidationTtlMs = 120_000;

  // PR #116: business-error (HTTP 4xx kivéve 401/403/429) tranzakciók in-memory
  // abandoned-listája. Ezek NEM kerülnek újra sync-elésre a setInterval auto-run-ban,
  // így nem történik végtelen retry rate-mismatch, insufficient-balance stb. üzleti
  // validációs hibákra. Az app restart esetén a set resetelődik — user kézzel is
  // retry-olhat az "offline sync" menüpontban.
  private abandonedTxIds = new Set<number>();
  private abandonedConvIds = new Set<number>();
  private abandonedStornoIds = new Set<number>();
  private abandonedBankTxIds = new Set<number>();
  private abandonedDistribIds = new Set<number>();
  private abandonedTransferIds = new Set<number>();
  private abandonedCollectionIds = new Set<number>();
  private abandonedHandoverIds = new Set<number>();

  private status: SyncStatus = {
    lastSyncAt: null,
    lastSyncResult: null,
    isRunning: false,
  };

  // 2026-04-29 v2.3.11 (E-B6.3 error throttling):
  // 3+ egymást követő hibás runSync után exponenciális backoff (30s → 60s → 120s
  // → max 300s = 5 perc). Sikeres run resetel. Ezzel megakadályozzuk a végtelen
  // 404/500 spam-et, ami az event-loop-ot blokkolhatja.
  private consecutiveFailures = 0;
  private backoffUntilMs = 0;
  // RPO-vedohalo (2026-06-05): a re-assert legalabb egyszer fusson le inditas utan
  // (a kliens failover utan tipikusan ujraindul/ujracsatlakozik), es minden
  // outage-recovery-kor (failover-pillanat). Lasd reassertRecentSynced().
  private reassertedAtStartup = false;
  private static readonly REASSERT_WINDOW_HOURS = 6;
  private readonly maxBackoffMs = 300_000; // 5 perc

  /**
   * Normalizes a stored server URL and rejects hosts outside the outbound allowlist.
   */
  private sanitizeAllowedServerUrl(stored: string, configLabel: string): string | null {
    const sanitized = sanitizeStoredServerUrl(stored);
    if (!sanitized) {
      return null;
    }
    if (!isAllowedUrl(sanitized)) {
      log.warn(`[SyncEngine] stored ${configLabel} rejected by host allowlist — ignored`);
      return null;
    }
    return sanitized;
  }

  /**
   * Primary server URL from SQLite config (or null when missing/offline).
   * HA: runSync tries a configured fallback after a primary failure.
   * Returning null prevents outbound requests while the till is offline.
   */
  private getServerUrl(): string | null {
    const offlineFlag = (getConfig('offline_mode') ?? '').toLowerCase();
    if (offlineFlag === 'true' || offlineFlag === '1') {
      return null;
    }
    const stored = (getConfig('server_url') ?? '').trim();
    if (!stored) {
      return null;
    }
    const sanitized = this.sanitizeAllowedServerUrl(stored, 'server_url');
    if (!sanitized) {
      log.warn('[SyncEngine] invalid stored server_url ignored');
    }
    return sanitized;
  }

  /**
   * Az AKTÍV (failover-feloldott) szerver-URL — MINDIG az aktuális activeServerKind szerint, on-demand
   * számolva (NINCS cache-elés). Így a rotáció (authFailed / catch ág activeServerKind-váltása) után a
   * cikluson KÍVÜL hívott metódusok (pl. sendHeartbeat saját timeren) is konzisztens URL-t kapnak —
   * nem egy korábbi ciklusban befagyott, már elavult URL-t (Codex/Copilot #874 P2). A prioritási
   * sorrend a kiválasztott szinttől indul, majd a többi szintre esik vissza, ha az hiányzik.
   */
  private getActiveServerUrl(): string | null {
    const primaryUrl = this.getServerUrl();
    const fallbackPrimaryUrl = this.getServerUrlFallbackPrimary();
    const fallbackSecondaryUrl = this.getServerUrlFallbackSecondary();
    switch (this.activeServerKind) {
      case 'fallback_primary':
        return fallbackPrimaryUrl ?? primaryUrl ?? fallbackSecondaryUrl;
      case 'fallback_secondary':
        return fallbackSecondaryUrl ?? fallbackPrimaryUrl ?? primaryUrl;
      case 'primary':
      default:
        return primaryUrl ?? fallbackPrimaryUrl ?? fallbackSecondaryUrl;
    }
  }

  /**
   * Fallback-primary (warm standby) - 1. prioritasu fallback.
   * Peldaul: Hetzner primary -> Contabo warm standby (Nurnberg).
   * Config: 'server_url_fallback_primary' vagy backward-compat 'server_url_fallback'.
   */
  private getServerUrlFallbackPrimary(): string | null {
    const stored = (
      getConfig('server_url_fallback_primary') ??
      getConfig('server_url_fallback') ??
      ''
    ).trim();
    const sanitized = this.sanitizeAllowedServerUrl(stored, 'server_url_fallback_primary');
    if (stored && !sanitized) {
      log.warn('[SyncEngine] invalid stored server_url_fallback_primary ignored');
    }
    return sanitized;
  }

  /**
   * Fallback-secondary (cold standby) - 2. prioritasu fallback.
   * Csak akkor probaljuk, ha a warm standby is elerhetetlen.
   * Peldaul: Hetzner + Contabo leallt -> Scaleway (Paris).
   * Config: 'server_url_fallback_secondary'.
   */
  private getServerUrlFallbackSecondary(): string | null {
    const stored = (getConfig('server_url_fallback_secondary') ?? '').trim();
    const sanitized = this.sanitizeAllowedServerUrl(stored, 'server_url_fallback_secondary');
    if (stored && !sanitized) {
      log.warn('[SyncEngine] invalid stored server_url_fallback_secondary ignored');
    }
    return sanitized;
  }

  /**
   * 3-regios HA: primary -> fallback_primary (Contabo) -> fallback_secondary (Scaleway).
   * A runSync hiba eseten lepked egyet az elso irany, sikere eseten visszaprobalja
   * az elozo szintet a kovetkezo ciklusban.
   */
  private activeServerKind: 'primary' | 'fallback_primary' | 'fallback_secondary' = 'primary';

  // #HA-failover (architect-mode audit): az aktív szerver-URL-t a getActiveServerUrl() on-demand
  // számolja az activeServerKind-ból (nincs cache-elt mező), így mindig konzisztens a kiválasztott
  // szinttel — a rotáció után a cikluson kívüli hívók sem kapnak elavult URL-t.

  private getBootstrapCredentials(): BootstrapCredentials | null {
    const companyCode =
      process.env.PENZTAR_BOOTSTRAP_COMPANY_CODE?.trim() ||
      getConfig('bootstrap_company_code')?.trim() ||
      '';
    const workerCode =
      process.env.PENZTAR_BOOTSTRAP_WORKER_CODE?.trim() ||
      getConfig('bootstrap_worker_code')?.trim() ||
      '';
    // Security: regi env var kompatibilitas utan DPAPI/safeStorage titkositott config.
    const password =
      process.env.PENZTAR_BOOTSTRAP_PASSWORD?.trim() || this.getStoredBootstrapPassword();
    // FIGYELEM: a bootstrap_password torlese CSAK sikeres login UTAN tortenjen meg
    // (bootstrapAuthSession success agaban). Itt NE toroljuk, mert ha a login hibazik
    // (pl. rossz companyCode), a user elveszti a plaintext jelszavat es nem tud ujra login-olni.
    const roleCode =
      process.env.PENZTAR_BOOTSTRAP_ROLE_CODE?.trim() ||
      getConfig('bootstrap_role_code')?.trim() ||
      null;
    const appMode = process.env.PENZTAR_APP_MODE?.trim() || getConfig('app_mode')?.trim() || null;

    if (!companyCode || !workerCode || !password) {
      return null;
    }

    return {
      companyCode,
      workerCode,
      password,
      roleCode,
      appMode,
    };
  }

  private getStoredBootstrapPassword(): string {
    const encrypted = getConfig('bootstrap_password_encrypted');
    if (encrypted && safeStorage.isEncryptionAvailable()) {
      try {
        return safeStorage.decryptString(Buffer.from(encrypted, 'base64')).trim();
      } catch (err) {
        log.warn('[SyncEngine] bootstrap_password_encrypted nem dekodolhato, torolve:', err);
        deleteConfig('bootstrap_password_encrypted');
      }
    }
    return getConfig('bootstrap_password')?.trim() || '';
  }

  private persistAuthToken(token: string): void {
    try {
      if (safeStorage.isEncryptionAvailable()) {
        const encrypted = safeStorage.encryptString(token);
        setConfig('auth_token_encrypted', encrypted.toString('base64'));
        deleteConfig('auth_token');
        return;
      }
    } catch (err) {
      log.warn('[SyncEngine] DPAPI titkositas sikertelen:', err);
    }

    // Security: NEM mentjuk plaintext-ben diskre — csak volatile in-memory
    log.warn('[SyncEngine] safeStorage nem elerheto — token csak session-szinten tarolva');
    (global as Record<string, unknown>).__volatile_sync_token = token;
  }

  private clearStoredAuthToken(): void {
    deleteConfig('auth_token_encrypted');
    deleteConfig('auth_token');
    this.lastTokenValidationAt = 0;
  }

  private async validateToken(serverUrl: string, token: string): Promise<boolean> {
    const now = Date.now();
    if (now - this.lastTokenValidationAt < this.tokenValidationTtlMs) {
      return true;
    }

    try {
      await httpGet<unknown>(`${serverUrl}/workers/me`, token);
      this.lastTokenValidationAt = now;
      return true;
    } catch (err) {
      if (isAuthStatusError(err)) {
        return false;
      }
      throw err;
    }
  }

  private async bootstrapAuthSession(serverUrl: string): Promise<string | null> {
    const credentials = this.getBootstrapCredentials();
    if (!credentials) {
      return null;
    }

    try {
      const login = await httpPost<LoginResponse>(
        `${serverUrl}/auth/login`,
        {
          companyCode: credentials.companyCode,
          workerCode: credentials.workerCode,
          password: credentials.password,
        },
        null,
      );

      let token = login.token;

      if (login.roleSelectionRequired) {
        const selectedRoleCode = selectBootstrapRoleCode(
          credentials.appMode,
          credentials.roleCode,
          login,
        );
        if (!selectedRoleCode) {
          log.warn('[SyncEngine] Role selection szukseges, de nincs appMode-hoz illeszkedo role.', {
            appMode: credentials.appMode,
            explicitRoleCode: credentials.roleCode,
            availableRoleCodes: [...collectRoleCodes(login)],
          });
          return null;
        }
        const selected = await httpPost<LoginResponse>(
          `${serverUrl}/auth/login/select-role`,
          {
            token,
            roleCode: selectedRoleCode,
          },
          null,
        );
        token = selected.token;
      }

      this.persistAuthToken(token);
      this.lastTokenValidationAt = Date.now();
      // Security: sikeres login utan torolheto a plaintext bootstrap_password (ha a DB-ben volt)
      if (!process.env.PENZTAR_BOOTSTRAP_PASSWORD && getConfig('bootstrap_password')) {
        deleteConfig('bootstrap_password');
        log.info('[SyncEngine] bootstrap_password torolve (sikeres login utan)');
      }
      log.info('[SyncEngine] Lokális auth/session bootstrap sikeres');
      return token;
    } catch (err) {
      if (isAuthStatusError(err)) {
        log.warn(
          '[SyncEngine] Lokális auth bootstrap sikertelen (401/403). Ellenőrizd a bootstrap credentialöket.',
        );
      } else {
        log.warn('[SyncEngine] Lokális auth bootstrap hiba:', splitSyncError(err).masked);
      }
      return null;
    }
  }

  private getAuthToken(): string | null {
    const encryptedToken = getConfig('auth_token_encrypted');
    if (encryptedToken && safeStorage.isEncryptionAvailable()) {
      try {
        return safeStorage.decryptString(Buffer.from(encryptedToken, 'base64'));
      } catch (err) {
        log.warn('[SyncEngine] Nem sikerült visszafejteni a tárolt auth tokent:', err);
        // Corrupted/foreign DPAPI payload: remove it so sync can continue with plaintext or fresh login token.
        deleteConfig('auth_token_encrypted');
      }
    }
    return getConfig('auth_token');
  }

  /**
   * Szinkronizáció indítása — periodikus (alapértelmezetten 30s).
   */
  start(intervalMs: number = 30_000): void {
    if (this.intervalId) {
      log.info('[SyncEngine] Már fut, újraindítás...');
      this.stop();
    }

    log.info(`[SyncEngine] Indítás — ${intervalMs}ms intervallum`);

    // Első futtatás kis késéssel (5s) — várjuk meg az app inicializálását
    setTimeout(() => {
      void this.runSync();
    }, 5_000);

    this.intervalId = setInterval(() => {
      void this.runSync();
    }, intervalMs);
  }

  /**
   * Szinkronizáció leállítása.
   */
  stop(): void {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
      log.info('[SyncEngine] Leállítva');
    }
  }

  /**
   * Teljes szinkronizálási ciklus futtatása.
   */
  private async runSync(): Promise<void> {
    if (this.status.isRunning) {
      log.info('[SyncEngine] Előző sync még fut, kihagyás');
      return;
    }

    // 2026-04-29 v2.3.11 (E-B6.3 error throttling):
    // Ha exponenciális backoff aktív, kihagyjuk a futást
    const now = Date.now();
    if (this.backoffUntilMs > now) {
      const remainingS = Math.ceil((this.backoffUntilMs - now) / 1000);
      log.info(
        `[SyncEngine] Backoff aktív, ${remainingS}s múlva próbáljuk újra (consecutive failures: ${this.consecutiveFailures})`,
      );
      return;
    }

    this.status.isRunning = true;

    try {
      // 3-regios HA URL-valasztas az aktualis activeServerKind szerint (primary=Hetzner,
      // fallback_primary=Contabo warm, fallback_secondary=Scaleway cold). Ugyanazt a feloldast
      // hasznalja, mint az osszes sync-metodus → garantalt konzisztencia. Hiba eseten a catch /
      // authFailed ag lepteti az activeServerKind-ot a kovetkezo ciklusra.
      const serverUrl = this.getActiveServerUrl();
      if (!serverUrl) {
        log.debug('[SyncEngine] Offline mód vagy server_url hiányzik — sync kihagyva');
        return;
      }
      let token = this.getAuthToken();
      let authFailed = false;

      if (token) {
        const isValid = await this.validateToken(serverUrl, token);
        if (!isValid) {
          this.clearStoredAuthToken();
          token = await this.bootstrapAuthSession(serverUrl);
          if (!token) authFailed = true;
        }
      } else {
        token = await this.bootstrapAuthSession(serverUrl);
        if (!token) authFailed = true;
      }

      // PP-08: ha a bootstrap null token-t adott vissza (401/403, hiányzó credentials
      // vagy hálózati hiba a bootstrap során), backoff-ot alkalmazunk.
      // A sikeres-sync ág (consecutiveFailures reset) nem fut le.
      // A HA failover rotáció is lefut: bootstrapAuthSession hálózati hibát
      // elnyel és null-t ad vissza, ezért a catch-ágbeli HA-logika itt manuálisan
      // szükséges (ha 401/403 miatt bukott, a rotáció ártalmatlan).
      if (authFailed) {
        if (this.activeServerKind === 'primary' && this.getServerUrlFallbackPrimary()) {
          log.warn('[SyncEngine] Auth bootstrap sikertelen — kovetkezo ciklus: fallback_primary');
          this.activeServerKind = 'fallback_primary';
        } else if (
          this.activeServerKind === 'fallback_primary' &&
          this.getServerUrlFallbackSecondary()
        ) {
          log.warn('[SyncEngine] Auth bootstrap sikertelen — kovetkezo ciklus: fallback_secondary');
          this.activeServerKind = 'fallback_secondary';
        } else if (this.activeServerKind === 'fallback_secondary') {
          log.warn(
            '[SyncEngine] Auth bootstrap sikertelen — kovetkezo ciklus: primary ujraprobalas',
          );
          this.activeServerKind = 'primary';
        }
        this.consecutiveFailures += 1;
        if (this.consecutiveFailures >= 3) {
          const backoffMs = Math.min(
            30_000 * Math.pow(2, this.consecutiveFailures - 3),
            this.maxBackoffMs,
          );
          this.backoffUntilMs = Date.now() + backoffMs;
          log.warn(
            `[SyncEngine] Auth sikertelen (${this.consecutiveFailures}. hiba) — backoff: ${Math.round(backoffMs / 1000)}s`,
          );
        } else {
          log.warn(
            `[SyncEngine] Auth sikertelen (${this.consecutiveFailures}. hiba) — sync kihagyva`,
          );
        }
        return;
      }

      // 1. Tranzakciók szinkronizálása
      const result = await this.syncAll(token);
      this.status.lastSyncResult = result;

      if (result.synced > 0) {
        log.info(`[SyncEngine] ${result.synced} tranzakció szinkronizálva`);
      }
      if (result.failed > 0) {
        log.warn(`[SyncEngine] ${result.failed} tranzakció SIKERTELEN:`, result.errors);
      }

      // 2. Árfolyamok és cache frissítése (csak ha van érvényes token)
      if (token) {
        await this.syncRates();
        await this.syncHandlingFeeConfig();
        await this.syncRatePrintObligations();
        await this.syncCirculars();
        await this.syncCircularReplies();
        // FS-5: okmány-képpár feltöltése a centerbe + helyi fájl törlés nyugtázás után.
        await this.syncScannedDocuments();
        // 3. Értéktár szinkronizáció
        await this.syncDistributions();
        await this.syncTransfers();
        await this.syncTransferStornos();
        await this.syncCollections();
        await this.syncStocktakeItems();
        await this.cacheBranchStatus();
        await this.syncCashDeskMasterData();
        await this.syncWorkerMasterData();
        // Heartbeat: last_seen_at frissitese a backenden (online/offline monitoring).
        await this.sendHeartbeat(serverUrl, token);
      }

      this.status.lastSyncAt = new Date().toISOString();
      // E-B6.3 v2.3.11: sikeres sync resetel a backoff-ot
      const recoveredFromOutage = this.consecutiveFailures > 0;
      if (this.consecutiveFailures > 0) {
        log.info(
          `[SyncEngine] Sikeres sync — backoff reset (volt: ${this.consecutiveFailures} failure)`,
        );
        this.consecutiveFailures = 0;
        this.backoffUntilMs = 0;
      }
      // RPO-vedohalo (2026-06-05): failover/reconnect (outage-recovery) UTAN, vagy az elso
      // sikeres sync-nel (inditas) ujra-asszertaljuk a legutobbi synced tranzakciokat. Ha a
      // failover-ablakban a szerver-oldalon elveszett egy mar nyugtazott tetel, a backend az
      // idempotency-key alapjan VISSZAPOTOLJA; ha megvan, dedupol. Local-first vedohalo a
      // szinkron-replikacio (RPO=0) MELLE, a degradalt-ablak + kettos-hiba esetere.
      if (token && (recoveredFromOutage || !this.reassertedAtStartup)) {
        this.reassertedAtStartup = true;
        try {
          await this.reassertRecentSynced(serverUrl, token);
        } catch (reassertErr) {
          // FK-071 MEDIUM-E 3. kör: defenzív maszkolás — a reassert-lánc hibája
          // szerver-üzenetet hordozhat.
          log.warn(
            '[SyncEngine] Re-assert hiba (nem blokkolo):',
            splitSyncError(reassertErr).masked,
          );
        }
      }
    } catch (err) {
      // 3-regios HA: failover lepked egy szintet tovabb.
      // primary -> fallback_primary (Contabo) -> fallback_secondary (Scaleway) -> (ujra) primary
      if (this.activeServerKind === 'primary' && this.getServerUrlFallbackPrimary()) {
        log.warn(
          '[SyncEngine] Primary hibazott, kovetkezo ciklus: fallback_primary (Contabo warm standby)',
        );
        this.activeServerKind = 'fallback_primary';
      } else if (
        this.activeServerKind === 'fallback_primary' &&
        this.getServerUrlFallbackSecondary()
      ) {
        log.warn(
          '[SyncEngine] Fallback_primary is hibazott, kovetkezo ciklus: fallback_secondary (Scaleway cold standby)',
        );
        this.activeServerKind = 'fallback_secondary';
      } else if (this.activeServerKind === 'fallback_secondary') {
        log.warn(
          '[SyncEngine] Mindharom HA szint hibazott, kovetkezo ciklus: primary ujraprobalas',
        );
        this.activeServerKind = 'primary';
      }

      // E-B6.3 v2.3.11: 3+ egymást követő hiba → exponenciális backoff
      this.consecutiveFailures += 1;
      if (this.consecutiveFailures >= 3) {
        // 30s base, 30s * 2^(n-3) — capped at maxBackoffMs (5 perc)
        const backoffMs = Math.min(
          30_000 * Math.pow(2, this.consecutiveFailures - 3),
          this.maxBackoffMs,
        );
        this.backoffUntilMs = Date.now() + backoffMs;
        log.warn(
          `[SyncEngine] ${this.consecutiveFailures} egymást követő failure — backoff: ${Math.round(backoffMs / 1000)}s`,
        );
      }

      // FK-071 MEDIUM-E: a bubbled hiba message-e szerver-üzenetet hordozhat — maszkolva logolunk.
      log.error('[SyncEngine] Sync hiba:', splitSyncError(err).masked);
    } finally {
      this.status.isRunning = false;
    }
  }

  /**
   * 2026-04-29 v2.3.11 (E-B6.3): aktuális backoff állapot olvasása.
   * Diagnosztikai célokra (renderer status panel, log).
   */
  getBackoffStatus(): { active: boolean; remainingMs: number; consecutiveFailures: number } {
    const remainingMs = Math.max(0, this.backoffUntilMs - Date.now());
    return {
      active: remainingMs > 0,
      remainingMs,
      consecutiveFailures: this.consecutiveFailures,
    };
  }

  /**
   * FK-071 FR-3: EGY pending tranzakció azonnali, explicit újraküldése (kézi
   * "Újraküldés" gomb a Tranzakciólistán). A PR #116 abandoned-set-et szándékosan
   * megkerüli (a kézi retry épp az abandonolt, üzleti hibás tételekre való),
   * sikeres feltöltésnél ki is veszi a tételt az abandoned-setből. Az eredmény
   * (siker/hiba + üzenet) a pending soron tartósan rögzül (markTransaction*).
   */
  async retryPendingTransaction(id: number): Promise<{ success: boolean; error?: string | null }> {
    // FK-071 Bugbot#2: ha éppen fut a háttér-szinkron, megvárjuk a ciklus végét
    // (a syncAllAfterInFlight várakozási mintája szerint) — így nem futhat
    // párhuzamos feltöltés ugyanarra a tételre. A várakozás után FRISSEN nézzük
    // meg a pending sort: ha a háttér-ciklus időközben feltöltötte, nem indítunk
    // újabb HTTP-hívást (a lenti not-found ág fut, a lista-frissítés pedig már
    // a synced állapotot mutatja).
    while (this.syncAllInFlight) {
      try {
        await this.syncAllInFlight;
      } catch {
        // A háttér-futás hibája itt nem releváns — a kézi retry ettől még indulhat.
      }
    }

    const tx = getPendingTransactions().find((row) => row.id === id);
    if (!tx) {
      return { success: false, error: 'A tétel nem található, vagy már szinkronizálva van' };
    }

    const serverUrl = this.getActiveServerUrl();
    if (!serverUrl) {
      return { success: false, error: 'Offline mód — szerver URL nincs beállítva' };
    }

    const sessionCompanyCode = getConfig('bootstrap_company_code');
    const mismatchMessage = standaloneCompanyMismatchMessage(
      'TX',
      tx.id,
      tx.company_code,
      sessionCompanyCode,
    );
    if (mismatchMessage) {
      try {
        markTransactionSyncError(tx.id, mismatchMessage, new Date().toISOString());
      } catch {
        /* best-effort */
      }
      return { success: false, error: mismatchMessage };
    }

    let token = this.getAuthToken();
    if (!token) {
      token = await this.bootstrapAuthSession(serverUrl);
    }
    if (!token) {
      return { success: false, error: 'Nincs auth token — bejelentkezés szükséges' };
    }

    try {
      await this.syncTransaction(serverUrl, token, tx);
      markTransactionSynced(tx.id);
      this.abandonedTxIds.delete(tx.id);
      log.info(`[SyncEngine] TX #${tx.id} kézi újraküldés sikeres`);
      return { success: true, error: null };
    } catch (err) {
      // FK-071 MEDIUM-E: detektor a nyersen; a tárolt/logolt/visszaadott érték maszkolt.
      const { raw: rawErrorMsg, masked: errorMsg } = splitSyncError(err);
      try {
        markTransactionSyncError(tx.id, errorMsg, new Date().toISOString());
      } catch {
        /* best-effort */
      }
      if (this.isBusinessValidationError(rawErrorMsg)) {
        this.abandonedTxIds.add(tx.id);
      }
      log.warn(`[SyncEngine] TX #${tx.id} kézi újraküldés sikertelen: ${errorMsg}`);
      return { success: false, error: errorMsg };
    }
  }

  /**
   * Pending tranzakciók szinkronizálása a szerverrel.
   */

  /**
   * FKH-032 FR-2/FR-3/FR-4/FR-5: CÉLZOTT azonnali könyvelési kísérlet EGY frissen
   * mentett tételre — a teljes `syncAll()` helyett.
   *
   * <ul>
   *   <li>FR-1: a main-process `net.request` csatornán megy ({@link httpPostViaNet}),
   *       ugyanazon, mint a `useOnlineStatus` health-check — a jelző és a küldés
   *       nem mondhat ellent egymásnak.</li>
   *   <li>FR-3: 5 mp-es dedikált timeout; túllépéskor a tétel a helyi queue-ban marad,
   *       a 30 mp-es háttér-szinkron + FKH-031 retry-logika veszi át (NFR-2).</li>
   *   <li>FR-5: a MENTÉSKOR generált, tárolt `idempotency_key` megy fel — a backend
   *       dedupol, nincs kettős könyvelés az azonnali és a háttér-kísérlet között.</li>
   *   <li>NFR-3: siker és hiba is auditálódik (markTransactionSynced /
   *       markTransactionSyncError → `pending_transaction_sync_attempts`).</li>
   * </ul>
   *
   * A háttér-ciklus abandon/backoff állapotát NEM módosítja azon túl, hogy üzleti
   * (nem-retry-olható) 4xx esetén a tételt abandonolja — pontosan úgy, ahogy a
   * háttér-ág tenné, elkerülve a felesleges körökben ismételt elutasítást.
   */
  async syncSingleTransactionImmediate(
    id: number,
  ): Promise<{ success: boolean; error?: string | null }> {
    const tx = getPendingTransactions().find((row) => row.id === id);
    if (!tx) {
      // Már felkerült (pl. egy párhuzamos háttér-ciklus vitte fel) — ez SIKER.
      return { success: true, error: null };
    }

    const serverUrl = this.getActiveServerUrl();
    if (!serverUrl) {
      return { success: false, error: 'Offline mód — szerver URL nincs beállítva' };
    }

    const sessionCompanyCode = getConfig('bootstrap_company_code');
    const mismatchMessage = standaloneCompanyMismatchMessage(
      'TX',
      tx.id,
      tx.company_code,
      sessionCompanyCode,
    );
    if (mismatchMessage) {
      try {
        markTransactionSyncError(tx.id, mismatchMessage, new Date().toISOString());
      } catch {
        /* best-effort */
      }
      return { success: false, error: mismatchMessage };
    }

    let token = this.getAuthToken();
    if (!token) {
      token = await this.bootstrapAuthSession(serverUrl);
    }
    if (!token) {
      return { success: false, error: 'Nincs auth token — bejelentkezés szükséges' };
    }

    try {
      await this.syncTransaction(serverUrl, token, tx, httpPostViaNet);
      markTransactionSynced(tx.id);
      this.abandonedTxIds.delete(tx.id);
      log.info(`[SyncEngine] TX #${tx.id} azonnali könyvelés sikeres (net.request)`);
      return { success: true, error: null };
    } catch (err) {
      const { raw: rawErrorMsg, masked: errorMsg } = splitSyncError(err);
      try {
        markTransactionSyncError(tx.id, errorMsg, new Date().toISOString());
      } catch {
        /* best-effort */
      }
      if (this.isBusinessValidationError(rawErrorMsg)) {
        this.abandonedTxIds.add(tx.id);
      }
      log.warn(`[SyncEngine] TX #${tx.id} azonnali könyvelés sikertelen: ${errorMsg}`);
      return { success: false, error: errorMsg };
    }
  }

  /**
   * PR #116: HTTP 4xx (kivéve auth 401/403 és rate-limit 429) = üzleti validációs hiba.
   * Ezek NEM transient hibák → ne retry-oljuk újra és újra az intervalban.
   *
   * Példák: rate mismatch, insufficient balance, invalid customer data stb.
   */
  private isBusinessValidationError(errorMsg: string): boolean {
    if (!errorMsg) return false;
    // 401/403: auth hiba — más kezeli (break)
    // 429: rate limit — érdemes retry-olni később
    // 4xx egyebek: business validation — NE retry
    const match = errorMsg.match(/HTTP (4\d\d)/);
    if (!match) return false;
    const code = Number(match[1]);
    return (
      code >= 400 && code < 500 && code !== 401 && code !== 403 && code !== 408 && code !== 429
    );
  }

  private syncAllTokenKey(tokenOverride?: string | null): string {
    return tokenOverride == null ? 'stored-auth-token' : `override:${tokenOverride}`;
  }

  async syncAll(tokenOverride?: string | null): Promise<SyncResult> {
    const tokenKey = this.syncAllTokenKey(tokenOverride);

    if (this.syncAllInFlight) {
      if (this.syncAllInFlightTokenKey !== tokenKey) {
        const currentRun = this.syncAllInFlight;
        log.warn(
          '[SyncEngine] syncAll már fut eltérő auth tokennel, az új kérés az aktuális futás után indul',
        );
        return this.syncAllAfterInFlight(tokenOverride, currentRun);
      }
      log.info('[SyncEngine] syncAll már fut, a folyamatban lévő futás eredményére várunk');
      return this.syncAllInFlight;
    }

    this.syncAllInFlightTokenKey = tokenKey;
    this.syncAllInFlight = this.performSyncAllWithShipmentReceipts(tokenOverride);
    try {
      return await this.syncAllInFlight;
    } finally {
      this.syncAllInFlight = null;
      this.syncAllInFlightTokenKey = null;
    }
  }

  private async syncAllAfterInFlight(
    tokenOverride: string | null | undefined,
    inFlight: Promise<SyncResult>,
  ): Promise<SyncResult> {
    try {
      await inFlight;
    } catch (error) {
      // FK-071 MEDIUM-E 3. kör: a nyers Error-objektum message-e szerver-üzenetet
      // hordozhat — maszkolva logolunk.
      log.warn(
        '[SyncEngine] Az előző syncAll futás hibával zárult, az új auth kontextusú futás mégis indul',
        splitSyncError(error).masked,
      );
    }

    await Promise.resolve();
    return this.syncAll(tokenOverride);
  }

  private async performSyncAllWithShipmentReceipts(
    tokenOverride?: string | null,
  ): Promise<SyncResult> {
    const core = await this.performSyncAll(tokenOverride);
    const shipmentReceipts = await this.syncShipmentReceipts(tokenOverride);
    return {
      synced: core.synced + shipmentReceipts.synced,
      failed: core.failed + shipmentReceipts.failed,
      errors: [...core.errors, ...shipmentReceipts.errors],
    };
  }

  private async performSyncAll(tokenOverride?: string | null): Promise<SyncResult> {
    const result: SyncResult = { synced: 0, failed: 0, errors: [] };

    // PR #116 + FKH-031 FR-1/FR-2: a business-validation hibás tételek kizárása az
    // auto-sync-ből mostantól IDŐKAPUZOTT, nem végleges. A tétel a perzisztens
    // sync_attempts/last_attempt_at mezőkből számolt backoff lejárta után újra
    // esélyt kap (app-restart után is), 7 napig; utána kézi beavatkozás kell.
    const nowMs = Date.now();
    const allPendingTx = getPendingTransactions();
    const pendingTransactions = allPendingTx.filter((tx) => {
      // FR-2: a kapuzás forrása perzisztens is lehet — app-restart után az in-memory
      // abandoned-set üres, de a tárolt sync_error megőrzi a "HTTP 4xx" prefixet
      // (lásd sync-error-sanitizer.ts sorrend-invariáns), így a backoff folytatódik.
      const isBusinessRejected =
        this.abandonedTxIds.has(tx.id) || this.isBusinessValidationError(tx.sync_error ?? '');
      if (!isBusinessRejected) return true;
      if (isBusinessRetryWithheld(tx, nowMs)) return false;
      // Backoff lejárt — a tétel visszakerül az auto-sync-be. Ha ismét business
      // hibára fut, a catch-ág újra hozzáadja a set-hez, immár nagyobb attempt-tel.
      this.abandonedTxIds.delete(tx.id);
      log.info(`[SyncEngine] TX #${tx.id} business-retry backoff lejárt — újrapróbálkozás`);
      return true;
    });
    const allPendingConv = getPendingConversions();
    const pendingConversions = allPendingConv.filter((c) => !this.abandonedConvIds.has(c.id));
    const allPendingBankTx = getPendingBankTransactions();
    const pendingBankTransactions = allPendingBankTx.filter(
      (b) => !this.abandonedBankTxIds.has(b.id),
    );
    const allPendingDistrib = getPendingDistributions();
    const pendingDistributions = allPendingDistrib.filter(
      (d) => !this.abandonedDistribIds.has(d.id),
    );
    const allPendingTransfer = getPendingTransfers();
    const pendingTransfers = allPendingTransfer.filter((t) => !this.abandonedTransferIds.has(t.id));
    const allPendingCollect = getPendingCollections();
    const pendingCollections = allPendingCollect.filter(
      (c) => !this.abandonedCollectionIds.has(c.id),
    );
    const allPendingStorno = getPendingStornos();
    const pendingStornos = allPendingStorno.filter((s) => !this.abandonedStornoIds.has(s.id));
    const allPendingHandover = getPendingHandoverOperations();
    const pendingHandoverOperations = allPendingHandover.filter(
      (h) => !this.abandonedHandoverIds.has(h.id),
    );

    const skippedAbandoned =
      allPendingTx.length -
      pendingTransactions.length +
      (allPendingConv.length - pendingConversions.length) +
      (allPendingBankTx.length - pendingBankTransactions.length) +
      (allPendingDistrib.length - pendingDistributions.length) +
      (allPendingTransfer.length - pendingTransfers.length) +
      (allPendingCollect.length - pendingCollections.length) +
      (allPendingStorno.length - pendingStornos.length) +
      (allPendingHandover.length - pendingHandoverOperations.length);
    if (skippedAbandoned > 0) {
      log.info(
        `[SyncEngine] PR #116: ${skippedAbandoned} abandoned (business error) tranzakció kihagyva`,
      );
    }
    const totalPending =
      pendingTransactions.length +
      pendingConversions.length +
      pendingBankTransactions.length +
      pendingDistributions.length +
      pendingTransfers.length +
      pendingCollections.length +
      pendingStornos.length +
      pendingHandoverOperations.length;

    if (totalPending === 0) {
      return result;
    }

    const serverUrl = this.getActiveServerUrl();
    if (!serverUrl) {
      result.errors.push('Offline mód — szerver URL nincs beállítva');
      return result;
    }
    const token = tokenOverride ?? this.getAuthToken();

    if (!token) {
      result.errors.push('Nincs auth token — bejelentkezés szükséges');
      result.failed = totalPending;
      return result;
    }

    const sessionCompanyCode = getConfig('bootstrap_company_code');

    for (const tx of pendingTransactions) {
      if (companyMismatch(tx.company_code, sessionCompanyCode)) {
        const errorMsg = recordCompanyMismatch(
          result,
          'TX',
          tx.id,
          tx.company_code,
          sessionCompanyCode,
        );
        try {
          markTransactionSyncError(tx.id, errorMsg, new Date().toISOString());
        } catch {
          // Best-effort persistence; the in-memory result already reports the withheld row.
        }
        continue;
      }
      try {
        await this.syncTransaction(serverUrl, token, tx);
        markTransactionSynced(tx.id);
        result.synced++;
      } catch (err) {
        // FK-071 MEDIUM-E: detektor/osztályozás a NYERS szövegen, tárolás/log/eredmény maszkolva.
        const { raw: rawErrorMsg, masked: errorMsg } = splitSyncError(err);
        result.failed++;
        result.errors.push(`TX #${tx.id} (${tx.type} ${tx.currency_code}): ${errorMsg}`);
        // FK-SYNC (2026-06-02): a hibát TARTÓSAN a pending soron is rögzítjük (nem csak in-memory +
        // log), hogy a "Függőben" ragadt tételnél a felhasználó lássa, MIÉRT nem ment fel.
        try {
          markTransactionSyncError(tx.id, errorMsg, new Date().toISOString());
        } catch {
          /* best-effort */
        }
        // PR #116: business-validation-error -> abandon (ne retry-oljon végtelenül)
        if (this.isBusinessValidationError(rawErrorMsg)) {
          this.abandonedTxIds.add(tx.id);
          log.warn(`[SyncEngine] TX #${tx.id} abandoned (business error): ${errorMsg}`);
        }
        if (
          isAuthStatusError(err) ||
          rawErrorMsg.includes('HTTP 401') ||
          rawErrorMsg.includes('HTTP 403')
        ) {
          result.errors.push('Auth/session hiba — további próbálkozások leállítva');
          result.failed += totalPending - result.synced - result.failed;
          break;
        }
        // Ha hálózati hiba, a többi se fog menni — megszakítjuk
        if (
          rawErrorMsg.includes('fetch') ||
          rawErrorMsg.includes('network') ||
          rawErrorMsg.includes('timeout')
        ) {
          result.errors.push('Hálózati hiba — további próbálkozások leállítva');
          result.failed += totalPending - result.synced - result.failed;
          break;
        }
      }
    }

    if (result.errors.some((error) => error.includes('Hálózati hiba'))) {
      return result;
    }

    for (const conversion of pendingConversions) {
      if (companyMismatch(conversion.company_code, sessionCompanyCode)) {
        recordCompanyMismatch(
          result,
          'CONV',
          conversion.id,
          conversion.company_code,
          sessionCompanyCode,
        );
        continue;
      }
      try {
        await this.syncConversion(serverUrl, token, conversion);
        markConversionSynced(conversion.id);
        result.synced++;
      } catch (err) {
        const { raw: rawErrorMsg, masked: errorMsg } = splitSyncError(err);
        result.failed++;
        result.errors.push(
          `CONV #${conversion.id} (${conversion.from_currency_code}->${conversion.to_currency_code}): ${errorMsg}`,
        );
        if (this.isBusinessValidationError(rawErrorMsg)) {
          this.abandonedConvIds.add(conversion.id);
          log.warn(`[SyncEngine] CONV #${conversion.id} abandoned (business error): ${errorMsg}`);
        }
        if (
          isAuthStatusError(err) ||
          rawErrorMsg.includes('HTTP 401') ||
          rawErrorMsg.includes('HTTP 403')
        ) {
          result.errors.push('Auth/session hiba — további próbálkozások leállítva');
          result.failed += totalPending - result.synced - result.failed;
          break;
        }
        if (
          rawErrorMsg.includes('fetch') ||
          rawErrorMsg.includes('network') ||
          rawErrorMsg.includes('timeout')
        ) {
          result.errors.push('Hálózati hiba — további próbálkozások leállítva');
          result.failed += totalPending - result.synced - result.failed;
          break;
        }
      }
    }

    if (result.errors.some((error) => error.includes('Hálózati hiba'))) {
      return result;
    }

    for (const bankTransaction of pendingBankTransactions) {
      if (companyMismatch(bankTransaction.company_code, sessionCompanyCode)) {
        recordCompanyMismatch(
          result,
          'BANK',
          bankTransaction.id,
          bankTransaction.company_code,
          sessionCompanyCode,
        );
        continue;
      }
      try {
        await this.syncBankTransaction(serverUrl, token, bankTransaction);
        markBankTransactionSynced(bankTransaction.id);
        result.synced++;
      } catch (err) {
        const { raw: rawErrorMsg, masked: errorMsg } = splitSyncError(err);
        result.failed++;
        result.errors.push(
          `BANK #${bankTransaction.id} (${bankTransaction.transaction_type} ${bankTransaction.currency_code}): ${errorMsg}`,
        );
        if (this.isBusinessValidationError(rawErrorMsg)) {
          this.abandonedBankTxIds.add(bankTransaction.id);
          log.warn(
            `[SyncEngine] BANK #${bankTransaction.id} abandoned (business error): ${errorMsg}`,
          );
        }
        if (
          isAuthStatusError(err) ||
          rawErrorMsg.includes('HTTP 401') ||
          rawErrorMsg.includes('HTTP 403')
        ) {
          result.errors.push('Auth/session hiba — további próbálkozások leállítva');
          result.failed += totalPending - result.synced - result.failed;
          break;
        }
        if (
          rawErrorMsg.includes('fetch') ||
          rawErrorMsg.includes('network') ||
          rawErrorMsg.includes('timeout')
        ) {
          result.errors.push('Hálózati hiba — további próbálkozások leállítva');
          result.failed += totalPending - result.synced - result.failed;
          break;
        }
      }
    }

    if (result.errors.some((error) => error.includes('Hálózati hiba'))) {
      return result;
    }

    for (const distribution of pendingDistributions) {
      if (companyMismatch(distribution.company_code, sessionCompanyCode)) {
        recordCompanyMismatch(
          result,
          'DIST',
          distribution.id,
          distribution.company_code,
          sessionCompanyCode,
        );
        continue;
      }
      try {
        await this.syncDistribution(serverUrl, token, distribution);
        markDistributionSynced(distribution.id);
        result.synced++;
      } catch (err) {
        const { raw: rawErrorMsg, masked: errorMsg } = splitSyncError(err);
        result.failed++;
        result.errors.push(`DIST #${distribution.id} (${distribution.currency_code}): ${errorMsg}`);
        if (this.isBusinessValidationError(rawErrorMsg)) {
          this.abandonedDistribIds.add(distribution.id);
          log.warn(`[SyncEngine] DIST #${distribution.id} abandoned (business error): ${errorMsg}`);
        }
        if (
          isAuthStatusError(err) ||
          rawErrorMsg.includes('HTTP 401') ||
          rawErrorMsg.includes('HTTP 403')
        ) {
          result.errors.push('Auth/session hiba — további próbálkozások leállítva');
          result.failed += totalPending - result.synced - result.failed;
          break;
        }
        if (
          rawErrorMsg.includes('fetch') ||
          rawErrorMsg.includes('network') ||
          rawErrorMsg.includes('timeout')
        ) {
          result.errors.push('Hálózati hiba — további próbálkozások leállítva');
          result.failed += totalPending - result.synced - result.failed;
          break;
        }
      }
    }

    if (result.errors.some((error) => error.includes('Hálózati hiba'))) {
      return result;
    }

    for (const transfer of pendingTransfers) {
      if (companyMismatch(transfer.company_code, sessionCompanyCode)) {
        recordCompanyMismatch(
          result,
          'TRANSFER',
          transfer.id,
          transfer.company_code,
          sessionCompanyCode,
        );
        continue;
      }
      try {
        await this.syncTransfer(serverUrl, token, transfer);
        markTransferSynced(transfer.id);
        result.synced++;
      } catch (err) {
        const { raw: rawErrorMsg, masked: errorMsg } = splitSyncError(err);
        result.failed++;
        result.errors.push(`TRANSFER #${transfer.id} (${transfer.currency_code}): ${errorMsg}`);
        if (this.isBusinessValidationError(rawErrorMsg)) {
          this.abandonedTransferIds.add(transfer.id);
          log.warn(`[SyncEngine] TRANSFER #${transfer.id} abandoned (business error): ${errorMsg}`);
        }
        if (
          isAuthStatusError(err) ||
          rawErrorMsg.includes('HTTP 401') ||
          rawErrorMsg.includes('HTTP 403')
        ) {
          result.errors.push('Auth/session hiba — további próbálkozások leállítva');
          result.failed += totalPending - result.synced - result.failed;
          break;
        }
        if (
          rawErrorMsg.includes('fetch') ||
          rawErrorMsg.includes('network') ||
          rawErrorMsg.includes('timeout')
        ) {
          result.errors.push('Hálózati hiba — további próbálkozások leállítva');
          result.failed += totalPending - result.synced - result.failed;
          break;
        }
      }
    }

    if (result.errors.some((error) => error.includes('Hálózati hiba'))) {
      return result;
    }

    for (const collection of pendingCollections) {
      if (companyMismatch(collection.company_code, sessionCompanyCode)) {
        recordCompanyMismatch(
          result,
          'COLLECTION',
          collection.id,
          collection.company_code,
          sessionCompanyCode,
        );
        continue;
      }
      try {
        await this.syncCollection(serverUrl, token, collection);
        markCollectionSynced(collection.id);
        result.synced++;
      } catch (err) {
        const { raw: rawErrorMsg, masked: errorMsg } = splitSyncError(err);
        result.failed++;
        result.errors.push(
          `COLLECTION #${collection.id} (${collection.currency_code}): ${errorMsg}`,
        );
        if (this.isBusinessValidationError(rawErrorMsg)) {
          this.abandonedCollectionIds.add(collection.id);
          log.warn(
            `[SyncEngine] COLLECTION #${collection.id} abandoned (business error): ${errorMsg}`,
          );
        }
        if (
          isAuthStatusError(err) ||
          rawErrorMsg.includes('HTTP 401') ||
          rawErrorMsg.includes('HTTP 403')
        ) {
          result.errors.push('Auth/session hiba — további próbálkozások leállítva');
          result.failed += totalPending - result.synced - result.failed;
          break;
        }
        if (
          rawErrorMsg.includes('fetch') ||
          rawErrorMsg.includes('network') ||
          rawErrorMsg.includes('timeout')
        ) {
          result.errors.push('Hálózati hiba — további próbálkozások leállítva');
          result.failed += totalPending - result.synced - result.failed;
          break;
        }
      }
    }

    if (result.errors.some((error) => error.includes('Hálózati hiba'))) {
      return result;
    }

    for (const storno of pendingStornos) {
      if (companyMismatch(storno.company_code, sessionCompanyCode)) {
        recordCompanyMismatch(result, 'STORNO', storno.id, storno.company_code, sessionCompanyCode);
        continue;
      }
      try {
        await this.syncStorno(serverUrl, token, storno);
        markStornoSynced(storno.id);
        result.synced++;
      } catch (err) {
        const { raw: rawErrorMsg, masked: errorMsg } = splitSyncError(err);
        result.failed++;
        result.errors.push(`STORNO #${storno.id} (${storno.original_receipt_number}): ${errorMsg}`);
        if (this.isBusinessValidationError(rawErrorMsg)) {
          this.abandonedStornoIds.add(storno.id);
          log.warn(`[SyncEngine] STORNO #${storno.id} abandoned (business error): ${errorMsg}`);
        }
        if (
          isAuthStatusError(err) ||
          rawErrorMsg.includes('HTTP 401') ||
          rawErrorMsg.includes('HTTP 403')
        ) {
          result.errors.push('Auth/session hiba — további próbálkozások leállítva');
          result.failed += totalPending - result.synced - result.failed;
          break;
        }
        if (
          rawErrorMsg.includes('fetch') ||
          rawErrorMsg.includes('network') ||
          rawErrorMsg.includes('timeout')
        ) {
          result.errors.push('Hálózati hiba — további próbálkozások leállítva');
          result.failed += totalPending - result.synced - result.failed;
          break;
        }
      }
    }

    if (result.errors.some((error) => error.includes('Hálózati hiba'))) {
      return result;
    }

    for (const operation of pendingHandoverOperations) {
      if (companyMismatch(operation.company_code, sessionCompanyCode)) {
        recordCompanyMismatch(
          result,
          'HANDOVER',
          operation.id,
          operation.company_code,
          sessionCompanyCode,
        );
        continue;
      }
      try {
        await this.syncHandoverOperation(serverUrl, token, operation);
        markHandoverOperationSynced(operation.id);
        result.synced++;
      } catch (err) {
        const { raw: rawErrorMsg, masked: errorMsg } = splitSyncError(err);
        result.failed++;
        result.errors.push(`HANDOVER #${operation.id} (${operation.operation_type}): ${errorMsg}`);
        if (this.isBusinessValidationError(rawErrorMsg)) {
          this.abandonedHandoverIds.add(operation.id);
          log.warn(
            `[SyncEngine] HANDOVER #${operation.id} abandoned (business error): ${errorMsg}`,
          );
        }
        if (
          isAuthStatusError(err) ||
          rawErrorMsg.includes('HTTP 401') ||
          rawErrorMsg.includes('HTTP 403')
        ) {
          result.errors.push('Auth/session hiba — további próbálkozások leállítva');
          result.failed += totalPending - result.synced - result.failed;
          break;
        }
        if (
          rawErrorMsg.includes('fetch') ||
          rawErrorMsg.includes('network') ||
          rawErrorMsg.includes('timeout')
        ) {
          result.errors.push('Hálózati hiba — további próbálkozások leállítva');
          result.failed += totalPending - result.synced - result.failed;
          break;
        }
      }
    }

    return result;
  }

  /**
   * RPO-vedohalo (2026-06-05): a REASSERT_WINDOW_HOURS-on beluli, idempotency-key-vel
   * rendelkezo SYNCED tranzakciok ujrakuldese. A backend a key alapjan dedupol (ha mar
   * megvan) vagy visszapotol (ha a failover-ablakban a szerver-oldalon elveszett). A
   * lokalis allapotot NEM valtoztatja (a rekordok synced=1 maradnak). Failover/reconnect
   * (outage-recovery) utan + inditaskor fut. A szinkron-replikacio (RPO=0) MELLE: a ritka
   * degradalt-ablak + kettos-hiba esetere local-first vedohalo.
   */
  private async reassertRecentSynced(serverUrl: string, token: string): Promise<number> {
    if (!serverUrl || !token) return 0;
    const since = new Date(Date.now() - SyncEngine.REASSERT_WINDOW_HOURS * 3_600_000).toISOString();
    let count = 0;
    const tryOne = async (label: string, fn: () => Promise<void>): Promise<void> => {
      try {
        await fn();
        count++;
      } catch (err) {
        const { raw: rawMsg, masked: msg } = splitSyncError(err);
        // halozati hiba -> nincs ertelme folytatni; a kovetkezo recovery ujraprobalja
        if (rawMsg.includes('fetch') || rawMsg.includes('network') || rawMsg.includes('timeout')) {
          throw err;
        }
        log.warn(`[Reassert] ${label}: ${msg}`);
      }
    };
    try {
      for (const tx of getReassertableTransactions(since)) {
        await tryOne(`TX#${tx.id}`, () => this.syncTransaction(serverUrl, token, tx));
      }
      for (const c of getReassertableConversions(since)) {
        await tryOne(`CONV#${c.id}`, () => this.syncConversion(serverUrl, token, c));
      }
      for (const s of getReassertableStornos(since)) {
        await tryOne(`STORNO#${s.id}`, () => this.syncStorno(serverUrl, token, s));
      }
      for (const b of getReassertableBankTransactions(since)) {
        await tryOne(`BANK#${b.id}`, () => this.syncBankTransaction(serverUrl, token, b));
      }
    } catch (netErr) {
      // FK-071 MEDIUM-E 3. kör: a tryOne a NYERS err-t dobja tovább (az osztályozás
      // már lefutott rajta) — a terminális log itt is maszkolt kell legyen.
      log.warn(
        '[Reassert] halozati hiba — megszakitva, kovetkezo recovery folytatja:',
        splitSyncError(netErr).masked,
      );
    }
    if (count > 0) {
      log.info(`[SyncEngine] Re-assert: ${count} synced rekord ujra-asszertalva (RPO-vedohalo).`);
    }
    return count;
  }

  /**
   * Egyedi tranzakció szinkronizálása.
   */
  private async syncTransaction(
    serverUrl: string,
    token: string,
    tx: PendingTransactionRow,
    // FKH-032 FR-1: az azonnali kísérlet a net.request csatornára cserélheti a postert.
    poster: typeof httpPost = httpPost,
  ): Promise<void> {
    const endpoint =
      tx.type === 'SELL' ? `${serverUrl}/transactions/sell` : `${serverUrl}/transactions/buy`;

    const body: Record<string, unknown> = {
      currencyCode: tx.currency_code,
      currencyAmount: tx.foreign_amount,
      customExchangeRate: tx.rate,
    };

    // Multi-line aggregate (2026-06-04): ha a pending sor tobb-soros nyugtat kepvisel, a `lines[]`
    // tombot is feltesszuk a body-ba — a backend ekkor az executeMultiLineBuy/Sell aggregalt
    // utvonalra megy (egy AML-kapu, egy approval-grant). A fejlec currencyCode/currencyAmount/
    // customExchangeRate az ELSO sor erteke (backward-compat), de a tenyleges konyveles a sorokbol
    // tortenik. NULL/hianyzo `lines` → valtozatlan egysoros viselkedes.
    if (tx.lines) {
      try {
        const parsedLines = JSON.parse(tx.lines);
        if (Array.isArray(parsedLines) && parsedLines.length > 0) {
          body['lines'] = parsedLines;
        }
      } catch {
        // Nem parsable → kihagyjuk; a fejlec-mezok egysorosként mennek fel (fail-safe).
      }
    }

    if (tx.handling_fee !== null && tx.handling_fee !== undefined) {
      body['handlingFee'] = tx.handling_fee;
    }

    // FK-KEZDIJ offline (2026-06-12, penztar-batch B.1/b): a kezelesi dij override
    // (Felezes/Elenegedes/Ugyfelkartya) a REST-tel azonos mezokkel — eddig CSENDBEN
    // elveszett az Electron uton, a szerver a teljes alap-dijat konyvelte.
    if (tx.handling_fee_override_type) {
      body['handlingFeeOverrideType'] = tx.handling_fee_override_type;
    }
    if (tx.handling_fee_override_reason) {
      body['handlingFeeOverrideReason'] = tx.handling_fee_override_reason;
    }
    if (tx.customer_card_number) {
      body['customerCardNumber'] = tx.customer_card_number;
    }

    if (tx.discount_percent !== null && tx.discount_percent !== undefined) {
      body['discountPercent'] = tx.discount_percent;
    }

    const customerIdentifier =
      tx.customer_identifier ?? (typeof tx.customer_id === 'string' ? tx.customer_id : null);
    if (customerIdentifier && customerIdentifier.trim().length > 0) {
      body['customerId'] = customerIdentifier;
    }

    if (tx.customer_name && tx.customer_name.trim().length > 0) {
      body['customerName'] = tx.customer_name;
    }

    if (tx.customer_document_number && tx.customer_document_number.trim().length > 0) {
      body['customerDocumentNumber'] = tx.customer_document_number;
    }

    if (tx.customer_address && tx.customer_address.trim().length > 0) {
      body['customerAddress'] = tx.customer_address;
    }

    if (tx.denominations !== null) {
      try {
        body['denominations'] = JSON.parse(tx.denominations);
      } catch {
        // Ha nem parsable, string-ként küldjük
        body['denominations'] = tx.denominations;
      }
    }

    // G3-G4: PEP nyilatkozat és pénzeszköz forrás (300k+ HUF tranzakciónál)
    if (tx.source_of_funds && tx.source_of_funds.trim().length > 0) {
      body['sourceOfFunds'] = tx.source_of_funds;
    }
    if (tx.customer_is_pep !== null && tx.customer_is_pep !== undefined) {
      body['customerIsPep'] = tx.customer_is_pep === 1;
    }
    // AML vezetoi jovahagyas: a jovahagyo supervisor/manager/admin workerId-ja (NULL ha nem kellett).
    // A backend csak akkor hasznalja, ha a tranzakcio valoban approval-koteles; egyebkent ignoralja.
    if (tx.approver_worker_id !== null && tx.approver_worker_id !== undefined) {
      body['approverWorkerId'] = tx.approver_worker_id;
    }
    // AML jovahagyas-session (Codex P1: receipt-scoping) — a grantot a konkret nyugtahoz koti.
    if (tx.approval_session_id !== null && tx.approval_session_id !== undefined) {
      body['approvalSessionId'] = tx.approval_session_id;
    }

    // V226 (2026-05-14): per-line devizastatusz — DOMESTIC vagy FOREIGN.
    // Ha hianyzik (regi pending sor), a backend defaultolja a tranzakcio-szintu erteket.
    if (
      tx.foreign_status &&
      (tx.foreign_status === 'DOMESTIC' || tx.foreign_status === 'FOREIGN')
    ) {
      body['foreignStatus'] = tx.foreign_status;
    }

    // V229 + V235 (2026-05-19 HIBA #14 + #17 + #18): teljes Pmt. customer-snapshot
    // a backend felé. A korábbi sync csak 4 alapmezőt küldött át, így a bizonylaton
    // hiányzott a szül.hely / szül.idő / anyja neve / állampolgárság / okmány típus
    // / "más nevében" flag és az actor (képviselt fél) teljes azonosítása.
    const addOptionalText = (key: string, value: string | null | undefined): void => {
      if (value && value.trim().length > 0) {
        body[key] = value;
      }
    };
    addOptionalText('customerBirthPlace', tx.customer_birth_place);
    addOptionalText('customerBirthDate', tx.customer_birth_date);
    addOptionalText('customerMotherName', tx.customer_mother_name);
    addOptionalText('customerNationality', tx.customer_nationality);
    addOptionalText('customerDocumentType', tx.customer_document_type);
    addOptionalText('customerPepKind', tx.customer_pep_kind);
    // 300k+ JOGCÍM nyilatkozat: NULL = nem kérdezett (régi pending sor); TRUE/FALSE = válasz
    if (tx.customer_on_own_behalf !== null && tx.customer_on_own_behalf !== undefined) {
      body['customerOnOwnBehalf'] = tx.customer_on_own_behalf === 1;
    }
    // V235 actor (képviselt fél) teljes azonosítása — csak ha onOwnBehalf=false.
    // Copilot P2 (PR #695): a korábbi pathon a sync-engine MIND a customer_actor_*
    // mezőt MINDIG átküldte, akkor is ha customer_on_own_behalf=1 volt. Stale data
    // veszély (régi pending sor, vagy user visszakapcsolta a flaget). Most:
    // explicit guard, csak customer_on_own_behalf=0 (FALSE) esetén megy fel.
    if (tx.customer_on_own_behalf === 0) {
      addOptionalText('customerActorName', tx.customer_actor_name);
      addOptionalText('customerActorBirthPlace', tx.customer_actor_birth_place);
      addOptionalText('customerActorBirthDate', tx.customer_actor_birth_date);
      addOptionalText('customerActorMotherName', tx.customer_actor_mother_name);
      addOptionalText('customerActorNationality', tx.customer_actor_nationality);
      addOptionalText('customerActorDocumentType', tx.customer_actor_document_type);
      addOptionalText('customerActorDocumentNumber', tx.customer_actor_document_number);
      addOptionalText('customerActorAddress', tx.customer_actor_address);
    }

    // V325 (Batch3-C): jogi szemely ugyfel + tenyleges tulajdonosok — a REST-tel
    // azonos mezokkel. NULL flag = nem jogi szemely (regi pending sor is).
    if (tx.is_legal_entity_customer !== null && tx.is_legal_entity_customer !== undefined) {
      body['isLegalEntityCustomer'] = tx.is_legal_entity_customer === 1;
    }
    if (tx.is_legal_entity_customer === 1) {
      addOptionalText('legalEntityName', tx.legal_entity_name);
      addOptionalText('legalEntitySeat', tx.legal_entity_seat);
      addOptionalText('legalEntityTaxNumber', tx.legal_entity_tax_number);
      addOptionalText('legalDeedNumber', tx.legal_deed_number);
      if (tx.beneficial_owners_json) {
        try {
          const parsedOwners = JSON.parse(tx.beneficial_owners_json);
          if (Array.isArray(parsedOwners) && parsedOwners.length > 0) {
            body['beneficialOwners'] = parsedOwners;
          }
        } catch {
          // Nem parsable → kihagyjuk; a jogi alapmezok igy is felmennek (fail-safe).
        }
      }
    }

    // A tárolt idempotency_key-t használjuk — retry-nál is ugyanazt küldjük
    await poster(endpoint, body, token, tx.idempotency_key ?? undefined);
  }

  private async syncConversion(
    serverUrl: string,
    token: string,
    conversion: PendingConversionRow,
  ): Promise<void> {
    const body: Record<string, unknown> = {
      fromAmount: conversion.from_amount,
    };

    if (conversion.from_currency_id && conversion.from_currency_id > 0) {
      body['fromCurrencyId'] = conversion.from_currency_id;
    } else {
      body['fromCurrencyCode'] = conversion.from_currency_code;
    }

    if (conversion.to_currency_id && conversion.to_currency_id > 0) {
      body['toCurrencyId'] = conversion.to_currency_id;
    } else {
      body['toCurrencyCode'] = conversion.to_currency_code;
    }

    // HIBA 2026-05-26 (#4/#5): a penztaros (cimletezeshez) modositott cel-osszege.
    // A backend felso hatarra vagja (clamp) es a maradek forintot visszajaroként konyveli.
    if (
      conversion.calculated_to_amount !== null &&
      conversion.calculated_to_amount !== undefined &&
      conversion.calculated_to_amount > 0
    ) {
      body['toAmount'] = conversion.calculated_to_amount;
    }

    // HIBA 2026-05-26 (#2): ugyfel deviza-statusza (DOMESTIC/FOREIGN).
    if (conversion.foreign_status && conversion.foreign_status.trim().length > 0) {
      body['foreignStatus'] = conversion.foreign_status;
    }

    if (conversion.handling_fee !== null && conversion.handling_fee !== undefined) {
      body['handlingFee'] = conversion.handling_fee;
    }

    if (conversion.customer_id && conversion.customer_id.trim().length > 0) {
      body['customerId'] = conversion.customer_id;
    }

    if (conversion.customer_name && conversion.customer_name.trim().length > 0) {
      body['customerName'] = conversion.customer_name;
    }

    if (
      conversion.customer_document_number &&
      conversion.customer_document_number.trim().length > 0
    ) {
      body['customerDocumentNumber'] = conversion.customer_document_number;
    }

    // V235 + V236 (2026-05-19 Codex P1 #695): teljes Pmt. customer-snapshot a
    // Konverzio sync payload-ba. A korabbi sync csak 3 customer mezot kuldott,
    // igy a 100k+/300k+ konverzio bizonylatok hianyosak voltak (Pmt. tv. 6.§).
    const addOptionalConvText = (key: string, value: string | null | undefined): void => {
      if (value && value.trim().length > 0) {
        body[key] = value;
      }
    };
    addOptionalConvText('customerAddress', conversion.customer_address);
    addOptionalConvText('customerNationality', conversion.customer_nationality);
    addOptionalConvText('customerBirthPlace', conversion.customer_birth_place);
    addOptionalConvText('customerBirthDate', conversion.customer_birth_date);
    addOptionalConvText('customerMotherName', conversion.customer_mother_name);
    addOptionalConvText('customerDocumentType', conversion.customer_document_type);
    addOptionalConvText('sourceOfFunds', conversion.source_of_funds);
    addOptionalConvText('customerPepKind', conversion.customer_pep_kind);
    if (conversion.customer_is_pep !== null && conversion.customer_is_pep !== undefined) {
      body['customerIsPep'] = conversion.customer_is_pep === 1;
    }
    // AML vezetoi jovahagyas a konverzional is (NULL ha nem kellett).
    if (conversion.approver_worker_id !== null && conversion.approver_worker_id !== undefined) {
      body['approverWorkerId'] = conversion.approver_worker_id;
    }
    // AML jovahagyas-session (Codex P1: receipt-scoping).
    if (conversion.approval_session_id !== null && conversion.approval_session_id !== undefined) {
      body['approvalSessionId'] = conversion.approval_session_id;
    }
    if (
      conversion.customer_on_own_behalf !== null &&
      conversion.customer_on_own_behalf !== undefined
    ) {
      body['customerOnOwnBehalf'] = conversion.customer_on_own_behalf === 1;
    }
    // Actor mezok csak akkor mennek fel, ha onOwnBehalf=0 (FALSE) — Copilot P2 mintaja
    if (conversion.customer_on_own_behalf === 0) {
      addOptionalConvText('customerActorName', conversion.customer_actor_name);
      addOptionalConvText('customerActorBirthPlace', conversion.customer_actor_birth_place);
      addOptionalConvText('customerActorBirthDate', conversion.customer_actor_birth_date);
      addOptionalConvText('customerActorMotherName', conversion.customer_actor_mother_name);
      addOptionalConvText('customerActorNationality', conversion.customer_actor_nationality);
      addOptionalConvText('customerActorDocumentType', conversion.customer_actor_document_type);
      addOptionalConvText('customerActorDocumentNumber', conversion.customer_actor_document_number);
      addOptionalConvText('customerActorAddress', conversion.customer_actor_address);
    }

    await httpPost(
      `${serverUrl}/transactions/conversion`,
      body,
      token,
      conversion.idempotency_key ?? undefined,
    );
  }

  private async syncBankTransaction(
    serverUrl: string,
    token: string,
    bankTransaction: PendingBankTransactionRow,
  ): Promise<void> {
    const body: Record<string, unknown> = {
      transactionType: bankTransaction.transaction_type,
      currencyCode: bankTransaction.currency_code,
      amount: bankTransaction.amount,
      exchangeRate: bankTransaction.exchange_rate,
    };

    if (
      bankTransaction.vault_territory_id !== null &&
      bankTransaction.vault_territory_id !== undefined
    ) {
      body['vaultTerritoryId'] = bankTransaction.vault_territory_id;
    }
    if (bankTransaction.bank_name && bankTransaction.bank_name.trim().length > 0) {
      body['bankName'] = bankTransaction.bank_name;
    }
    if (bankTransaction.bank_reference && bankTransaction.bank_reference.trim().length > 0) {
      body['bankReference'] = bankTransaction.bank_reference;
    }
    if (bankTransaction.note && bankTransaction.note.trim().length > 0) {
      body['note'] = bankTransaction.note;
    }

    await httpPost(
      `${serverUrl}/ertektar/bank-transactions`,
      body,
      token,
      bankTransaction.idempotency_key ?? undefined,
    );
  }

  private async syncStorno(
    serverUrl: string,
    token: string,
    storno: PendingStornoRow,
  ): Promise<void> {
    const body: Record<string, unknown> = {
      transactionId: storno.transaction_id,
      reason: storno.reason,
    };

    if (storno.approval_id) {
      body['approvalId'] = storno.approval_id;
    }
    if (storno.custom_exchange_rate !== null && storno.custom_exchange_rate !== undefined) {
      body['customExchangeRate'] = storno.custom_exchange_rate;
    }
    if (storno.payment_method) {
      body['paymentMethodDid'] = storno.payment_method;
    }

    await httpPost(
      `${serverUrl}/stornos/execute`,
      body,
      token,
      storno.idempotency_key ?? undefined,
    );
  }

  private async syncDistribution(
    serverUrl: string,
    token: string,
    dist: ReturnType<typeof getPendingDistributions>[number],
  ): Promise<void> {
    const body: Record<string, unknown> = {
      targetBranchCode: dist.target_branch_code,
      currencyCode: dist.currency_code,
      amount: dist.amount,
    };
    if (dist.denominations) {
      try {
        body['denominations'] = JSON.parse(dist.denominations);
      } catch {
        /* keep omitted */
      }
    }
    if (dist.note) {
      body['note'] = dist.note;
    }
    await httpPost(
      `${serverUrl}/ertektar/distribution`,
      body,
      token,
      dist.idempotency_key ?? undefined,
    );
  }

  private async syncTransfer(
    serverUrl: string,
    token: string,
    tx: ReturnType<typeof getPendingTransfers>[number],
  ): Promise<void> {
    const body: Record<string, unknown> = {
      amount: tx.amount,
      targetBranchCode: tx.target_branch_code,
      currencyCode: tx.currency_code,
    };
    if (tx.target_branch_id) {
      body['toBranchId'] = tx.target_branch_id;
    }
    if (tx.currency_id !== null && tx.currency_id !== undefined) {
      body['currencyId'] = tx.currency_id;
    }
    if (tx.transfer_type) {
      body['transferType'] = tx.transfer_type;
    }
    if (tx.huf_value !== null && tx.huf_value !== undefined) {
      body['hufValue'] = tx.huf_value;
    }
    if (tx.denominations) {
      try {
        body['denominations'] = JSON.parse(tx.denominations);
      } catch {
        /* keep omitted */
      }
    }
    if (tx.note) {
      body['notes'] = tx.note;
    }
    // Codex P1 (backward-compat): a backend mostantól KÖTELEZŐVÉ teszi a carrier/seal-t (@NotBlank).
    // A frissítés ELŐTT queue-olt régi sorokon ezek null-ok lehetnek — ott sentinel-t küldünk, hogy
    // a sync ne akadjon el (head-of-line block / örök 400). Az új sorok mindig valódi értékkel jönnek.
    body['carrierName'] = tx.carrier_name || 'N/A';
    body['sealNumber'] = tx.seal_number || 'LEGACY';
    if (tx.direction) body['direction'] = tx.direction;
    if (tx.lines) {
      try {
        body['lines'] = JSON.parse(tx.lines);
      } catch {
        /* keep omitted */
      }
    }
    await httpPost(`${serverUrl}/transfers`, body, token, tx.idempotency_key ?? undefined);
  }

  private async syncCollection(
    serverUrl: string,
    token: string,
    col: ReturnType<typeof getPendingCollections>[number],
  ): Promise<void> {
    const body: Record<string, unknown> = {
      sourceBranchCode: col.source_branch_code,
      currencyCode: col.currency_code,
      amount: col.amount,
    };
    if (col.note) {
      body['note'] = col.note;
    }
    await httpPost(
      `${serverUrl}/ertektar/collections`,
      body,
      token,
      col.idempotency_key ?? undefined,
    );
  }

  private async syncHandoverOperation(
    serverUrl: string,
    token: string,
    operation: PendingHandoverOperationRow,
  ): Promise<void> {
    if (operation.operation_type === 'GENERATE') {
      await httpPost(
        `${serverUrl}/handover-sheets/generate`,
        {
          fromCashDeskId: operation.from_cash_desk_id,
          toCashDeskId: operation.to_cash_desk_id,
          transferDate: operation.transfer_date,
          amounts: operation.amounts_json ? JSON.parse(operation.amounts_json) : {},
        },
        token,
        operation.idempotency_key ?? undefined,
      );
      return;
    }

    if (!operation.sheet_id) {
      throw new Error('Hiányzó handover sheet id');
    }

    const endpoint =
      operation.operation_type === 'PRINT'
        ? `${serverUrl}/handover-sheets/${operation.sheet_id}/print`
        : `${serverUrl}/handover-sheets/${operation.sheet_id}/complete`;
    await httpPost(endpoint, {}, token, operation.idempotency_key ?? undefined);
  }

  /**
   * Árfolyamok letöltése és SQLite cache frissítése.
   *
   * Legacy: ArfolyamBeolvasas — FTP szerveren lévő NR*.DAT fájl letöltése
   * és a helyi ARFOLYAM tábla frissítése.
   * Új rendszer: REST API-n keresztül kéri le az aktuális árfolyamokat.
   */
  async syncRates(): Promise<void> {
    try {
      const serverUrl = this.getActiveServerUrl();
      if (!serverUrl) {
        return;
      }
      const token = this.getAuthToken();

      const rates = await httpGet<RateResponse[]>(`${serverUrl}/exchange-rates/pos-current`, token);

      const db = getDb();
      if (!db || !Array.isArray(rates)) return;

      for (const rate of rates) {
        db.run(
          `INSERT INTO cached_rates (currency_code, buy_rate, sell_rate, unit, updated_at,
             official_rate, limit1_amount, limit1_buy_rate, limit1_sell_rate,
             limit2_amount, limit2_buy_rate, limit2_sell_rate,
             limit3_amount, limit3_buy_rate, limit3_sell_rate)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
           ON CONFLICT(currency_code) DO UPDATE SET
             buy_rate = excluded.buy_rate,
             sell_rate = excluded.sell_rate,
             unit = excluded.unit,
             updated_at = excluded.updated_at,
             official_rate = excluded.official_rate,
             limit1_amount = excluded.limit1_amount,
             limit1_buy_rate = excluded.limit1_buy_rate,
             limit1_sell_rate = excluded.limit1_sell_rate,
             limit2_amount = excluded.limit2_amount,
             limit2_buy_rate = excluded.limit2_buy_rate,
             limit2_sell_rate = excluded.limit2_sell_rate,
             limit3_amount = excluded.limit3_amount,
             limit3_buy_rate = excluded.limit3_buy_rate,
             limit3_sell_rate = excluded.limit3_sell_rate`,
          [
            rate.currencyCode,
            rate.buyRate,
            rate.sellRate,
            rate.unit,
            rate.updatedAt,
            rate.officialRate ?? null,
            rate.limit1Amount ?? null,
            rate.limit1BuyRate ?? null,
            rate.limit1SellRate ?? null,
            rate.limit2Amount ?? null,
            rate.limit2BuyRate ?? null,
            rate.limit2SellRate ?? null,
            rate.limit3Amount ?? null,
            rate.limit3BuyRate ?? null,
            rate.limit3SellRate ?? null,
          ],
        );
      }

      saveDatabase();
      log.info(`[SyncEngine] ${rates.length} árfolyam frissítve`);
    } catch (err) {
      // Nem kritikus hiba — legközelebb újrapróbáljuk
      if (isAuthStatusError(err)) {
        this.clearStoredAuthToken();
        log.warn(
          '[SyncEngine] Árfolyam sync auth hiba (401/403), session újra-bootstrap szükséges.',
        );
        return;
      }
      log.warn('[SyncEngine] Árfolyam sync hiba:', splitSyncError(err).masked);
    }
  }

  /**
   * FK-097 (FR-2/FR-8): az iroda-szintű kezelési díj konfiguráció tükrözése a lokális
   * SQLite-ba — a `syncRates`-szel azonos alak (fail-soft, 401 → token-clear).
   * A pénztár offline tranzakciói ebből a cache-ből számítanak (FR-4/FR-5/FR-6).
   */
  async syncHandlingFeeConfig(): Promise<void> {
    try {
      const serverUrl = this.getActiveServerUrl();
      if (!serverUrl) {
        return;
      }
      const token = this.getAuthToken();

      const response = await httpGet<BranchFeeConfigLiveResponse>(
        `${serverUrl}/branch-fee-config/own`,
        token,
      );

      const db = getDb();
      if (!db || typeof response !== 'object' || response === null) return;

      // FR-8 második védelmi vonal: a szerver sosem ad DRAFT-ot az /own-ra; ha mégis
      // DRAFT-státuszú payload jön, a kliens VISSZAUTASÍTJA az írást (nem cache-elhetünk
      // nem-éles díjat).
      const status = (response as { status?: string }).status;
      if (status === 'DRAFT') {
        log.warn(
          '[SyncEngine] Kezelési díj konfiguráció sync: DRAFT payload elutasítva (FR-8).',
        );
        return;
      }

      saveCachedHandlingFeeConfig({
        branch_id: response.branchId,
        branch_code: response.branchCode,
        company_id: null,
        fee_mode: response.feeMode,
        per_mille_rate: response.perMilleRate,
        per_mille_cap: response.perMilleCap,
        bracket_json: JSON.stringify(response.brackets ?? []),
        valid_from: response.validFrom,
      });
      saveDatabase();
      log.info('[SyncEngine] Kezelési díj konfiguráció frissítve');
    } catch (err) {
      // Nem kritikus hiba — legközelebb újrapróbáljuk (syncRates-minta)
      if (isAuthStatusError(err)) {
        this.clearStoredAuthToken();
        log.warn(
          '[SyncEngine] Kezelési díj konfiguráció sync auth hiba (401/403), session újra-bootstrap szükséges.',
        );
        return;
      }
      log.warn('[SyncEngine] Kezelési díj konfiguráció sync hiba:', splitSyncError(err).masked);
    }
  }

  async syncRatePrintObligations(): Promise<void> {
    try {
      const serverUrl = this.getActiveServerUrl();
      if (!serverUrl) return;
      const token = this.getAuthToken();
      if (!token) return;
      const db = getDb();
      if (!db) return;

      this.ensureRatePrintOutboxTable(db);
      await this.flushRatePrintOutbox(serverUrl, token, db);

      const obligations = await httpGet<RatePrintObligationResponse[]>(
        `${serverUrl}/exchange-rate-master/distribution/pending-print`,
        token,
      );
      if (!Array.isArray(obligations) || obligations.length === 0) return;

      for (const obligation of obligations) {
        const printerName = getConfig(PRINTER_CONFIG_KEY)?.trim() || undefined;
        const serialPort = getConfig(SERIAL_PORT_CONFIG_KEY)?.trim() || undefined;
        const printed = await printReceipt(
          this.buildRateChangePrintData(obligation),
          printerName,
          serialPort,
        );
        if (!printed) {
          log.warn(
            `[SyncEngine] Rate-print nyomtatás sikertelen, nincs ACK: ${obligation.distributionId}`,
          );
          continue;
        }

        try {
          await this.acknowledgeRatePrint(
            serverUrl,
            token,
            obligation.distributionId,
            obligation.printProofToken,
          );
        } catch (err) {
          this.enqueueRatePrintOutbox(
            db,
            obligation.distributionId,
            obligation.printProofToken,
            new Date().toISOString(),
          );
          if (isAuthStatusError(err)) {
            this.clearStoredAuthToken();
            log.warn('[SyncEngine] Rate-print ACK auth hiba (401/403), outboxba mentve.');
            break;
          }
          log.warn(
            `[SyncEngine] Rate-print ACK hiba, outboxba mentve: ${obligation.distributionId}`,
            splitSyncError(err).masked,
          );
        }
      }

      saveDatabase();
    } catch (err) {
      if (isAuthStatusError(err)) {
        this.clearStoredAuthToken();
        log.warn(
          '[SyncEngine] Rate-print sync auth hiba (401/403), session újra-bootstrap szükséges.',
        );
        return;
      }
      log.warn('[SyncEngine] Rate-print sync hiba:', splitSyncError(err).masked);
    }
  }

  private ensureRatePrintOutboxTable(db: RatePrintOutboxDb): void {
    db.run(`
      CREATE TABLE IF NOT EXISTS rate_print_outbox (
        distribution_id TEXT PRIMARY KEY,
        token TEXT NOT NULL,
        printed_at TEXT NOT NULL
      )
    `);
  }

  private async flushRatePrintOutbox(
    serverUrl: string,
    token: string,
    db: RatePrintOutboxDb,
  ): Promise<void> {
    const rows = this.readRatePrintOutboxRows(db);
    let mutated = false;
    for (const row of rows) {
      try {
        await this.acknowledgeRatePrint(serverUrl, token, row.distributionId, row.token);
        db.run('DELETE FROM rate_print_outbox WHERE distribution_id = ?', [row.distributionId]);
        mutated = true;
      } catch (err) {
        if (isAuthStatusError(err)) {
          throw err;
        }
        if (isPermanentRatePrintAckError(err)) {
          db.run('DELETE FROM rate_print_outbox WHERE distribution_id = ?', [row.distributionId]);
          mutated = true;
          log.warn(
            `[SyncEngine] Rate-print outbox poison sor eldobva: ${row.distributionId}`,
            splitSyncError(err).masked,
          );
          continue;
        }
        log.warn(
          `[SyncEngine] Rate-print outbox flush átmeneti hiba, sor megtartva: ${row.distributionId}`,
          splitSyncError(err).masked,
        );
        break;
      }
    }
    if (mutated) {
      saveDatabase();
    }
  }

  private readRatePrintOutboxRows(
    db: Pick<Database, 'exec'>,
  ): Array<{ distributionId: string; token: string }> {
    const result = db.exec('SELECT distribution_id, token, printed_at FROM rate_print_outbox');
    const table = result[0];
    if (!table) return [];
    return table.values.map((value) => ({
      distributionId: String(value[0]),
      token: String(value[1]),
    }));
  }

  private enqueueRatePrintOutbox(
    db: Pick<Database, 'run'>,
    distributionId: string,
    token: string,
    printedAt: string,
  ): void {
    const params: SqlValue[] = [distributionId, token, printedAt];
    db.run(
      `INSERT INTO rate_print_outbox (distribution_id, token, printed_at)
       VALUES (?, ?, ?)
       ON CONFLICT(distribution_id) DO UPDATE SET
         token = excluded.token,
         printed_at = excluded.printed_at`,
      params,
    );
  }

  private async acknowledgeRatePrint(
    serverUrl: string,
    token: string,
    distributionId: string,
    printProofToken: string,
  ): Promise<void> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      'Idempotency-Key': `rate-print-${distributionId}`,
      Authorization: `Bearer ${token}`,
    };
    const response = await fetch(
      `${serverUrl}/exchange-rate-master/distribution/${distributionId}/acknowledge`,
      {
        method: 'POST',
        headers,
        body: JSON.stringify({ printProofToken }),
        signal: AbortSignal.timeout(15_000),
      },
    );
    if (!response.ok) {
      throw new HttpStatusError(response.status, response.statusText);
    }
  }

  private buildRateChangePrintData(obligation: RatePrintObligationResponse): PrintReceiptData {
    const now = new Date();
    const companyType = getConfig('company_type') === 'EXPRESSZ' ? 'EXPRESSZ' : 'BEST_CHANGE';
    return {
      type: 'rate_change',
      companyType,
      receiptNumber: `RATE-${obligation.masterRateId}-v${obligation.versionNumber}`,
      branchCode: getConfig('branch_code') ?? 'UNKNOWN',
      cashierName: getConfig('worker_name') ?? 'Ismeretlen dolgozó',
      date: now.toISOString().slice(0, 10),
      time: now.toTimeString().slice(0, 8),
      currencyCode: obligation.currencyCode,
      versionNumber: obligation.versionNumber,
      validFrom: obligation.validFrom,
      rate: obligation.baseSellRate,
      baseBuyRate: obligation.baseBuyRate,
      baseSellRate: obligation.baseSellRate,
      officialRate: obligation.officialRate,
      limit1Amount: obligation.limit1Amount,
      limit1BuyRate: obligation.limit1BuyRate,
      limit1SellRate: obligation.limit1SellRate,
      limit2Amount: obligation.limit2Amount,
      limit2BuyRate: obligation.limit2BuyRate,
      limit2SellRate: obligation.limit2SellRate,
      limit3Amount: obligation.limit3Amount,
      limit3BuyRate: obligation.limit3BuyRate,
      limit3SellRate: obligation.limit3SellRate,
    };
  }

  /**
   * Körlevelek letöltése és SQLite-ba mentése.
   */
  async syncCirculars(): Promise<void> {
    try {
      const serverUrl = this.getActiveServerUrl();
      if (!serverUrl) {
        return;
      }
      const token = this.getAuthToken();

      const circulars = await httpGet<CircularResponse[]>(`${serverUrl}/circulars`, token);

      const db = getDb();
      if (!db || !Array.isArray(circulars)) return;

      // Biztosítsuk, hogy a tábla létezik
      db.run(`
        CREATE TABLE IF NOT EXISTS cached_circulars (
          id INTEGER PRIMARY KEY,
          subject TEXT NOT NULL,
          body TEXT NOT NULL,
          sender TEXT NOT NULL,
          sent_at TEXT NOT NULL,
          acknowledged INTEGER DEFAULT 0,
          cached_at TEXT DEFAULT (datetime('now'))
        )
      `);

      for (const circular of circulars) {
        db.run(
          `INSERT INTO cached_circulars (id, subject, body, sender, sent_at)
           VALUES (?, ?, ?, ?, ?)
           ON CONFLICT(id) DO UPDATE SET
             subject = excluded.subject,
             body = excluded.body,
             sender = excluded.sender,
             sent_at = excluded.sent_at`,
          [circular.id, circular.subject, circular.body, circular.sender, circular.sentAt],
        );
      }

      if (circulars.length > 0) {
        saveDatabase();
        log.info(`[SyncEngine] ${circulars.length} körlevél szinkronizálva`);
      }
    } catch (err) {
      if (isAuthStatusError(err)) {
        this.clearStoredAuthToken();
        log.warn(
          '[SyncEngine] Körlevél sync auth hiba (401/403), session újra-bootstrap szükséges.',
        );
        return;
      }
      log.warn('[SyncEngine] Körlevél sync hiba:', splitSyncError(err).masked);
    }
  }

  /**
   * Értéktár: Pending distributions szinkronizálása.
   */
  async syncDistributions(): Promise<void> {
    try {
      const pending = getPendingDistributions();
      if (pending.length === 0) return;

      const serverUrl = this.getActiveServerUrl();
      if (!serverUrl) {
        return;
      }
      const token = this.getAuthToken();
      if (!token) return;
      const sessionCompanyCode = getConfig('bootstrap_company_code');

      for (const dist of pending) {
        const mismatchMessage = standaloneCompanyMismatchMessage(
          'DIST',
          dist.id,
          dist.company_code,
          sessionCompanyCode,
        );
        if (mismatchMessage) continue;
        try {
          const body: Record<string, unknown> = {
            targetBranchCode: dist.target_branch_code,
            currencyCode: dist.currency_code,
            amount: dist.amount,
          };
          if (dist.denominations) {
            try {
              body['denominations'] = JSON.parse(dist.denominations);
            } catch {
              /* skip */
            }
          }
          if (dist.note) body['note'] = dist.note;

          await httpPost(
            `${serverUrl}/ertektar/distribution`,
            body,
            token,
            dist.idempotency_key ?? undefined,
          );
          markDistributionSynced(dist.id);
        } catch (err) {
          if (isAuthStatusError(err)) {
            this.clearStoredAuthToken();
            log.warn('[SyncEngine] Distribution auth hiba (401/403), ciklus leállítva.');
            break;
          }
          log.warn(`[SyncEngine] Distribution #${dist.id} sync hiba:`, splitSyncError(err).masked);
          break; // Hálózati hiba → kilépés
        }
      }
    } catch (err) {
      log.warn('[SyncEngine] Distribution sync hiba:', splitSyncError(err).masked);
    }
  }

  /**
   * Értéktár: Pending transfers szinkronizálása.
   */
  async syncTransfers(): Promise<void> {
    try {
      const pending = getPendingTransfers();
      if (pending.length === 0) return;

      const serverUrl = this.getActiveServerUrl();
      if (!serverUrl) {
        return;
      }
      const token = this.getAuthToken();
      if (!token) return;
      const sessionCompanyCode = getConfig('bootstrap_company_code');

      for (const tx of pending) {
        const mismatchMessage = standaloneCompanyMismatchMessage(
          'TRANSFER',
          tx.id,
          tx.company_code,
          sessionCompanyCode,
        );
        if (mismatchMessage) continue;
        try {
          const body: Record<string, unknown> = {
            amount: tx.amount,
          };
          if (tx.target_branch_id) {
            body['toBranchId'] = tx.target_branch_id;
          }
          body['targetBranchCode'] = tx.target_branch_code;
          if (tx.currency_id !== null && tx.currency_id !== undefined) {
            body['currencyId'] = tx.currency_id;
          }
          body['currencyCode'] = tx.currency_code;
          if (tx.transfer_type) {
            body['transferType'] = tx.transfer_type;
          }
          if (tx.huf_value !== null && tx.huf_value !== undefined) {
            body['hufValue'] = tx.huf_value;
          }
          if (tx.denominations) {
            try {
              body['denominations'] = JSON.parse(tx.denominations);
            } catch {
              /* skip */
            }
          }
          if (tx.note) body['notes'] = tx.note;
          // Codex P1 (backward-compat): régi, frissítés előtt queue-olt sorokon null carrier/seal →
          // sentinel, hogy a @NotBlank-os backend ne blokkolja a szinkront (head-of-line block).
          body['carrierName'] = tx.carrier_name || 'N/A';
          body['sealNumber'] = tx.seal_number || 'LEGACY';
          if (tx.direction) body['direction'] = tx.direction;
          if (tx.lines) {
            try {
              body['lines'] = JSON.parse(tx.lines);
            } catch {
              /* keep omitted */
            }
          }

          await httpPost(`${serverUrl}/transfers`, body, token, tx.idempotency_key ?? undefined);
          markTransferSynced(tx.id);
        } catch (err) {
          if (isAuthStatusError(err)) {
            this.clearStoredAuthToken();
            log.warn('[SyncEngine] Transfer auth hiba (401/403), ciklus leállítva.');
            break;
          }
          log.warn(`[SyncEngine] Transfer #${tx.id} sync hiba:`, splitSyncError(err).masked);
          break;
        }
      }
    } catch (err) {
      log.warn('[SyncEngine] Transfer sync hiba:', splitSyncError(err).masked);
    }
  }

  /**
   * FS-C: körlevél-válaszok felszinkronizálása (outbox → POST /circulars/{id}/reply).
   * A 409 (idempotency-replay/conflict) és az üzleti validációs hiba (pl. a körlevél
   * időközben válasz-tiltott lett) "elvégzettnek" számít — nem akasztja a queue-t.
   */
  async syncCircularReplies(): Promise<void> {
    try {
      const pending = getPendingCircularReplies();
      if (pending.length === 0) return;

      const serverUrl = this.getActiveServerUrl();
      if (!serverUrl) return;
      const token = this.getAuthToken();
      if (!token) return;
      const sessionCompanyCode = getConfig('bootstrap_company_code');

      for (const reply of pending) {
        const mismatchMessage = standaloneCompanyMismatchMessage(
          'CIRCULAR_REPLY',
          reply.id,
          reply.company_code,
          sessionCompanyCode,
        );
        if (mismatchMessage) continue;
        try {
          await httpPost(
            `${serverUrl}/circulars/${reply.circular_id}/reply`,
            { replyText: reply.reply_text },
            token,
            reply.idempotency_key ?? undefined,
          );
          markCircularReplySynced(reply.id);
        } catch (err) {
          const { raw: rawErrorMsg, masked: errorMsg } = splitSyncError(err);
          if (rawErrorMsg.includes('409')) {
            markCircularReplySynced(reply.id);
            log.info(`[SyncEngine] Körlevél-válasz #${reply.id} már a szerveren → synced.`);
            continue;
          }
          if (isAuthStatusError(err)) {
            this.clearStoredAuthToken();
            log.warn('[SyncEngine] Körlevél-válasz auth hiba (401/403), ciklus leállítva.');
            break;
          }
          if (this.isBusinessValidationError(rawErrorMsg)) {
            markCircularReplySynced(reply.id);
            log.warn(
              `[SyncEngine] Körlevél-válasz #${reply.id} elvetve (business error): ${errorMsg}`,
            );
            continue;
          }
          log.warn(`[SyncEngine] Körlevél-válasz #${reply.id} sync hiba:`, errorMsg);
          break; // hálózati hiba → később újra
        }
      }
    } catch (err) {
      log.warn('[SyncEngine] Körlevél-válasz sync hiba:', splitSyncError(err).masked);
    }
  }

  // FS-5: helyi dokumentumtípus → szerver-oldali enum leképezés.
  private static readonly DOC_TYPE_MAP: Record<string, string> = {
    szemelyi: 'ID_CARD',
    utlevel: 'PASSPORT',
    jogositvany: 'DRIVERS_LICENSE',
    egyeb: 'OTHER',
  };

  /**
   * FS-5: okmány-képpár feltöltése a centerbe + helyi titkosított scan-fájlok
   * törlése SIKERES center-nyugtázás után (fail-closed: sikertelen feltöltésnél
   * SEMMI nem törlődik; a sor synced=1 PERZISZTÁLÁSA után jön csak a fájltörlés).
   */
  async syncScannedDocuments(): Promise<void> {
    try {
      const pending = getPendingScannedDocuments();
      if (pending.length === 0) return;

      const serverUrl = this.getActiveServerUrl();
      if (!serverUrl) return;
      const token = this.getAuthToken();
      if (!token) return;
      const sessionCompanyCode = getConfig('bootstrap_company_code');

      for (const doc of pending) {
        const mismatchMessage = standaloneCompanyMismatchMessage(
          'SCANNED_DOC',
          doc.id,
          doc.company_code,
          sessionCompanyCode,
        );
        if (mismatchMessage) continue;
        try {
          const form = new FormData();
          const frontBytes = new Uint8Array(readDecryptedScan(doc.front_path));
          const backBytes = new Uint8Array(readDecryptedScan(doc.back_path));
          form.append('front', new Blob([frontBytes], { type: 'image/png' }), 'front.png');
          form.append('back', new Blob([backBytes], { type: 'image/png' }), 'back.png');
          form.append('documentType', SyncEngine.DOC_TYPE_MAP[doc.document_type] ?? 'OTHER');
          form.append('customerId', String(doc.customer_id));
          if (doc.notes) form.append('notes', doc.notes);
          await httpPostMultipart(
            `${serverUrl}/scanned-documents/upload-pair`,
            form,
            token,
            doc.idempotency_key ?? undefined,
          );
          // FAIL-CLOSED sorrend: előbb a synced-jelölés PERZISZTÁLVA, utána fájltörlés.
          markScannedDocumentSynced(doc.id);
          deleteScanFiles(doc.front_path);
          deleteScanFiles(doc.back_path);
          log.info(
            `[SyncEngine] Okmány-scan #${doc.id} feltöltve a centerbe, helyi fájlok törölve.`,
          );
        } catch (err) {
          const { raw: rawErrorMsg, masked: errorMsg } = splitSyncError(err);
          if (isAuthStatusError(err)) {
            log.warn('[SyncEngine] Okmány-scan auth hiba (401/403), ciklus leállítva.');
            break;
          }
          if (this.isBusinessValidationError(rawErrorMsg)) {
            markScannedDocumentSyncError(doc.id, errorMsg);
            log.warn(`[SyncEngine] Okmány-scan #${doc.id} üzleti hiba: ${errorMsg}`);
            continue;
          }
          markScannedDocumentSyncError(doc.id, errorMsg);
          log.warn(`[SyncEngine] Okmány-scan #${doc.id} sync hiba:`, errorMsg);
          break; // hálózati hiba → később újra
        }
      }
    } catch (err) {
      log.warn('[SyncEngine] Okmány-scan sync hiba:', splitSyncError(err).masked);
    }
  }

  /**
   * Átadás-átvétel OFFLINE SZTORNÓ szinkronizálása: a queue-olt sztornókat a backend
   * POST /transfers/{id}/storno végpontjára küldi (a backend fordítja vissza a készletet).
   * A „már sztornózva" (409) ÉS az üzleti-validációs hiba „elvégzettnek" számít (mark synced,
   * head-of-line block elkerülése) — nem akad el az egész queue egy nem-újrázható tételen.
   */
  async syncTransferStornos(): Promise<void> {
    try {
      const pending = getPendingTransferStornos();
      if (pending.length === 0) return;

      const serverUrl = this.getActiveServerUrl();
      if (!serverUrl) return;
      const token = this.getAuthToken();
      if (!token) return;
      const sessionCompanyCode = getConfig('bootstrap_company_code');

      for (const st of pending) {
        const mismatchMessage = standaloneCompanyMismatchMessage(
          'TRANSFER_STORNO',
          st.id,
          st.company_code,
          sessionCompanyCode,
        );
        if (mismatchMessage) continue;
        try {
          await httpPost(
            `${serverUrl}/transfers/${st.transfer_id}/storno`,
            { reason: st.reason },
            token,
            st.idempotency_key ?? undefined,
          );
          markTransferStornoSynced(st.id);
        } catch (err) {
          const { raw: rawErrorMsg, masked: errorMsg } = splitSyncError(err);
          // Már sztornózva (409 / VV-TX-003) → a kívánt végállapot már fennáll → kész.
          if (
            rawErrorMsg.includes('409') ||
            rawErrorMsg.includes('VV-TX-003') ||
            rawErrorMsg.includes('már sztornózva')
          ) {
            markTransferStornoSynced(st.id);
            log.info(`[SyncEngine] Transfer-storno #${st.id} már sztornózva a szerveren → synced.`);
            continue;
          }
          if (isAuthStatusError(err)) {
            this.clearStoredAuthToken();
            log.warn('[SyncEngine] Transfer-storno auth hiba (401/403), ciklus leállítva.');
            break;
          }
          // Üzleti validációs hiba (nem-újrázható) → ne blokkolja a queue-t.
          if (this.isBusinessValidationError(rawErrorMsg)) {
            markTransferStornoSynced(st.id);
            log.warn(
              `[SyncEngine] Transfer-storno #${st.id} elvetve (business error): ${errorMsg}`,
            );
            continue;
          }
          log.warn(`[SyncEngine] Transfer-storno #${st.id} sync hiba:`, errorMsg);
          break; // hálózati hiba → később újra
        }
      }
    } catch (err) {
      log.warn('[SyncEngine] Transfer-storno sync hiba:', splitSyncError(err).masked);
    }
  }

  /**
   * FKH-018: az offline rögzített Shipment-átvételi szándékok szinkronizálása.
   * A 409 önmagában soha nem siker: az autoritatív GET bizonyítja a végállapotot.
   */
  async syncShipmentReceipts(tokenOverride?: string | null): Promise<SyncResult> {
    if (this.shipmentReceiptSyncInFlight) {
      return this.shipmentReceiptSyncInFlight;
    }
    this.shipmentReceiptSyncInFlight = this.performSyncShipmentReceipts(tokenOverride);
    try {
      return await this.shipmentReceiptSyncInFlight;
    } finally {
      this.shipmentReceiptSyncInFlight = null;
    }
  }

  private async performSyncShipmentReceipts(tokenOverride?: string | null): Promise<SyncResult> {
    const result: SyncResult = { synced: 0, failed: 0, errors: [] };
    const pending = getPendingShipmentReceipts();
    if (pending.length === 0) return result;

    const serverUrl = this.getActiveServerUrl();
    const token = tokenOverride ?? this.getAuthToken();
    if (!serverUrl || !token) {
      result.failed = pending.length;
      result.errors.push(!serverUrl ? 'Szerver URL nincs beállítva' : 'Nincs auth token');
      return result;
    }
    const sessionCompanyCode = getConfig('bootstrap_company_code');

    for (const receipt of pending) {
      const mismatchMessage = standaloneCompanyMismatchMessage(
        'SHIPMENT_RECEIPT',
        receipt.id,
        receipt.company_code,
        sessionCompanyCode,
      );
      if (mismatchMessage) {
        markShipmentReceiptRetryError(receipt.id, mismatchMessage);
        result.failed++;
        result.errors.push(mismatchMessage);
        continue;
      }

      try {
        await httpPost<Record<string, unknown>>(
          `${serverUrl}/shipments/${receipt.shipment_id}/deliver`,
          receipt.confirmed_stale === 1 ? { confirmedStale: true } : {},
          token,
          receipt.idempotency_key,
          true,
        );
        markShipmentReceiptSynced(receipt.id);
        result.synced++;
      } catch (err) {
        if (isAuthStatusError(err)) {
          const message = splitSyncError(err).masked;
          markShipmentReceiptRetryError(receipt.id, message);
          result.failed++;
          result.errors.push(message);
          this.clearStoredAuthToken();
          break;
        }

        if (err instanceof HttpStatusError && err.status === 409) {
          try {
            const serverState = await httpGet<Record<string, unknown>>(
              `${serverUrl}/shipments/${receipt.shipment_id}`,
              token,
            );
            const status = String(
              serverState['status'] ?? serverState['requestStatus'] ?? 'UNKNOWN',
            );
            if (status === 'DELIVERED') {
              markShipmentReceiptSynced(receipt.id);
              result.synced++;
              continue;
            }
            if (status === 'CANCELLED' || status === 'REJECTED') {
              const message =
                status === 'CANCELLED'
                  ? `Az átvétel nem teljesült: a(z) ${receipt.request_number ?? receipt.shipment_id} tételt a küldő sztornózta.`
                  : `Az átvétel nem teljesült: a(z) ${receipt.request_number ?? receipt.shipment_id} tételt elutasították.`;
              markShipmentReceiptTerminalError(receipt.id, message);
              result.failed++;
              result.errors.push(message);
              continue;
            }
            const message = `A 409 ellenőrzése után a Shipment státusza ${status}; az átvétel nincs bizonyítva.`;
            markShipmentReceiptRetryError(receipt.id, message);
            result.failed++;
            result.errors.push(message);
            continue;
          } catch (verifyError) {
            const message = splitSyncError(verifyError).masked;
            markShipmentReceiptRetryError(receipt.id, message);
            result.failed++;
            result.errors.push(message);
            continue;
          }
        }

        const { raw: rawMessage, masked: message } = splitSyncError(err);
        if (err instanceof HttpStatusError && this.isBusinessValidationError(rawMessage)) {
          markShipmentReceiptTerminalError(receipt.id, message);
        } else {
          markShipmentReceiptRetryError(receipt.id, message);
        }
        result.failed++;
        result.errors.push(message);
      }
    }

    return result;
  }

  /**
   * Értéktár: Pending collections szinkronizálása.
   */
  async syncCollections(): Promise<void> {
    try {
      const pending = getPendingCollections();
      if (pending.length === 0) return;

      const serverUrl = this.getActiveServerUrl();
      if (!serverUrl) {
        return;
      }
      const token = this.getAuthToken();
      if (!token) return;
      const sessionCompanyCode = getConfig('bootstrap_company_code');

      for (const col of pending) {
        const mismatchMessage = standaloneCompanyMismatchMessage(
          'COLLECTION',
          col.id,
          col.company_code,
          sessionCompanyCode,
        );
        if (mismatchMessage) continue;
        try {
          const body: Record<string, unknown> = {
            sourceBranchCode: col.source_branch_code,
            currencyCode: col.currency_code,
            amount: col.amount,
          };
          if (col.note) body['note'] = col.note;

          await httpPost(
            `${serverUrl}/ertektar/collections`,
            body,
            token,
            col.idempotency_key ?? undefined,
          );
          markCollectionSynced(col.id);
        } catch (err) {
          if (isAuthStatusError(err)) {
            this.clearStoredAuthToken();
            log.warn('[SyncEngine] Collection auth hiba (401/403), ciklus leállítva.');
            break;
          }
          log.warn(`[SyncEngine] Collection #${col.id} sync hiba:`, splitSyncError(err).masked);
          break;
        }
      }
    } catch (err) {
      log.warn('[SyncEngine] Collection sync hiba:', splitSyncError(err).masked);
    }
  }

  /**
   * Sprint 7.1 - Offline stocktake item felvetelek sync-elese.
   *
   * A worker offline modban rogzitheti az actualQuantity-t, ami a
   * pending_stocktake_items tablaba kerul. Online-ra visszaterve itt
   * sync-elodik a backend /api/v1/vault-stocktake/items/{itemId}/count endpointra.
   *
   * Hiba eseten retry_count++ es sync_error elmentve. Idempotency-key
   * biztositja a duplikat felvetel elkerutleset.
   */
  async syncStocktakeItems(): Promise<void> {
    try {
      const pending = getPendingStocktakeItems();
      if (pending.length === 0) return;

      const serverUrl = this.getActiveServerUrl();
      if (!serverUrl) {
        return;
      }
      const token = this.getAuthToken();
      if (!token) return;
      const sessionCompanyCode = getConfig('bootstrap_company_code');

      for (const row of pending) {
        const mismatchMessage = standaloneCompanyMismatchMessage(
          'STOCKTAKE',
          row.id,
          row.company_code,
          sessionCompanyCode,
        );
        if (mismatchMessage) {
          markStocktakeItemError(row.id, mismatchMessage);
          continue;
        }
        try {
          const body: Record<string, unknown> = {
            actualQuantity: row.actual_quantity,
          };
          if (row.note) body['note'] = row.note;

          await httpPost(
            `${serverUrl}/vault-stocktake/items/${row.item_id}/count`,
            body,
            token,
            row.idempotency_key ?? undefined,
          );
          markStocktakeItemSynced(row.id);
          log.info(`[SyncEngine] Stocktake item #${row.id} (${row.item_id}) sync OK`);
        } catch (err) {
          if (isAuthStatusError(err)) {
            this.clearStoredAuthToken();
            log.warn('[SyncEngine] Stocktake auth hiba (401/403), ciklus leállítva.');
            break;
          }
          const errMsg = splitSyncError(err).masked;
          markStocktakeItemError(row.id, errMsg);
          log.warn(`[SyncEngine] Stocktake item #${row.id} sync hiba:`, errMsg);
          break;
        }
      }
    } catch (err) {
      log.warn('[SyncEngine] Stocktake sync hiba:', splitSyncError(err).masked);
    }
  }

  /**
   * Értéktár: Pénztár státuszok cache-elése.
   */
  async cacheBranchStatus(): Promise<void> {
    try {
      const serverUrl = this.getActiveServerUrl();
      if (!serverUrl) {
        return;
      }
      const token = this.getAuthToken();

      const branches = await httpGet<BranchStatusResponse[]>(
        `${serverUrl}/ertektar/branches/status`,
        token,
      );

      if (!Array.isArray(branches)) return;

      for (const branch of branches) {
        saveCachedBranchStatus(
          branch.code,
          branch.name,
          branch.companyId,
          branch.lastSyncAt,
          branch.onlineStatus,
          branch.totalHufValue,
          branch.dailyTurnover,
          branch.cashBalances ? JSON.stringify(branch.cashBalances) : null,
        );
      }

      if (branches.length > 0) {
        log.info(`[SyncEngine] ${branches.length} pénztár státusz cache-elve`);
      }
    } catch (err) {
      if (isAuthStatusError(err)) {
        this.clearStoredAuthToken();
        log.warn(
          '[SyncEngine] Branch status auth hiba (401/403), session újra-bootstrap szükséges.',
        );
        return;
      }
      log.warn('[SyncEngine] Branch status cache hiba:', splitSyncError(err).masked);
    }
  }

  /**
   * Pénztár törzs (branch master) cache-elése.
   */
  async syncCashDeskMasterData(): Promise<void> {
    try {
      const serverUrl = this.getActiveServerUrl();
      if (!serverUrl) {
        return;
      }
      const token = this.getAuthToken();

      const cashDesks = await httpGet<CashDeskResponse[]>(
        `${serverUrl}/branches?activeOnly=true`,
        token,
      );

      if (!Array.isArray(cashDesks)) return;

      for (const cashDesk of cashDesks) {
        saveCachedCashDesk(
          cashDesk.id,
          cashDesk.code,
          cashDesk.name,
          cashDesk.companyId ?? null,
          cashDesk.city ?? null,
          cashDesk.isActive ?? true,
          cashDesk.address ?? null,
          cashDesk.zipCode ?? null,
          cashDesk.phone ?? null,
          cashDesk.regionCode ?? null,
        );
      }

      if (cashDesks.length > 0) {
        log.info(`[SyncEngine] ${cashDesks.length} pénztár törzs rekord cache-elve`);
      }
    } catch (err) {
      if (isAuthStatusError(err)) {
        this.clearStoredAuthToken();
        log.warn(
          '[SyncEngine] Pénztár törzs sync auth hiba (401/403), session újra-bootstrap szükséges.',
        );
        return;
      }
      log.warn('[SyncEngine] Pénztár törzs sync hiba:', splitSyncError(err).masked);
    }
  }

  /**
   * Dolgozó törzs cache-elése.
   */
  async syncWorkerMasterData(): Promise<void> {
    try {
      const serverUrl = this.getActiveServerUrl();
      if (!serverUrl) {
        return;
      }
      const token = this.getAuthToken();

      const workers = await httpGet<WorkerResponse[]>(`${serverUrl}/workers/active`, token);

      if (!Array.isArray(workers)) return;

      for (const worker of workers) {
        saveCachedWorker(
          worker.id,
          worker.workerCode ?? null,
          worker.fullName,
          worker.role ?? null,
          worker.branchId ?? null,
          worker.branchCode ?? null,
          worker.branchName ?? null,
          worker.companyId ?? null,
          worker.companyCode ?? null,
          worker.active ?? true,
        );
      }

      if (workers.length > 0) {
        log.info(`[SyncEngine] ${workers.length} dolgozó törzs rekord cache-elve`);
      }
    } catch (err) {
      if (isAuthStatusError(err)) {
        this.clearStoredAuthToken();
        log.warn(
          '[SyncEngine] Dolgozó törzs sync auth hiba (401/403), session újra-bootstrap szükséges.',
        );
        return;
      }
      log.warn('[SyncEngine] Dolgozó törzs sync hiba:', splitSyncError(err).masked);
    }
  }

  /**
   * Aktuális szinkronizáció státusz lekérdezése.
   */
  getStatus(): SyncStatus {
    return { ...this.status };
  }

  /**
   * Szerver → Pénztár visszaállítás — ha helyi adatvesztés történt.
   * A szerveren tárolt tranzakciók visszaolvasása a helyi cache-be.
   */
  async restoreFromServer(
    sinceDaysAgo: number = 180,
  ): Promise<{ restored: number; error: string | null }> {
    try {
      const serverUrl = this.getActiveServerUrl();
      if (!serverUrl) {
        return { restored: 0, error: 'offline' };
      }
      const token = this.getAuthToken();
      if (!token) {
        return { restored: 0, error: 'Nincs auth token — bejelentkezés szükséges' };
      }

      const since = new Date();
      since.setDate(since.getDate() - sinceDaysAgo);
      const sinceStr = since.toISOString().slice(0, 10);

      log.info(`[SyncEngine] Restore szervről: since=${sinceStr}`);

      const status = await httpGet<{ totalTransactions: number; restoreAvailable: boolean }>(
        `${serverUrl}/sync/restore/status`,
        token,
      );
      if (!status.restoreAvailable) {
        return { restored: 0, error: 'Nincs visszaállítható adat a szerveren' };
      }

      const transactions = await httpGet<Array<Record<string, unknown>>>(
        `${serverUrl}/sync/restore/transactions?since=${sinceStr}`,
        token,
      );
      log.info(`[SyncEngine] Restore: ${transactions.length} tranzakció érkezett`);

      // Mentés a helyi SQLite cache-be
      const { saveRestoredTransactions } = await import('./sqlite');
      const saved = saveRestoredTransactions(transactions);
      log.info(`[SyncEngine] Restore: ${saved} tranzakció mentve a helyi cache-be`);

      return { restored: saved, error: null };
    } catch (err) {
      const msg = splitSyncError(err).masked;
      log.error('[SyncEngine] Restore hiba:', msg);
      return { restored: 0, error: msg };
    }
  }

  /**
   * 180 napos retenciós cleanup — szinkronizált pending rekordok törlése.
   * CSAK synced=1, 180+ napos rekordokat töröl.
   * Zoltán döntés: 180 nap (2026-04-08)
   */
  runRetentionCleanup(): void {
    try {
      import('./sqlite')
        .then(({ cleanupSyncedPendingRecords }) => {
          const result = cleanupSyncedPendingRecords(180);
          log.info('[SyncEngine] Retention cleanup (180 nap):', result);
        })
        .catch((err) => {
          log.warn('[SyncEngine] Retention cleanup hiba:', err);
        });
    } catch (err) {
      log.warn('[SyncEngine] Retention cleanup hiba:', err);
    }
  }
  /**
   * Periodikus heartbeat a backend cash_register_device tablara.
   * A cash_register_device_id a SetupWizard online-regisztracio utan kerul a SQLite-ba.
   * Ha nincs device_id -> skip (a wizard offline modban telepult, vagy nem regisztralt).
   * Ritka throttle: csak 5 percenkent kuldunk heartbeat-et (nincs ertelme 30s-enkent, a last_seen granularitasa 5 perc).
   */
  private lastHeartbeatAt = 0;
  private readonly heartbeatIntervalMs = 5 * 60 * 1000; // 5 perc

  private async sendHeartbeat(serverUrl: string, token: string): Promise<void> {
    const now = Date.now();
    if (now - this.lastHeartbeatAt < this.heartbeatIntervalMs) {
      return; // throttle
    }
    const deviceId = getConfig('cash_register_device_id');
    if (!deviceId) {
      return; // nincs regisztralt eszkoz (offline telepites)
    }
    try {
      await httpPost<unknown>(`${serverUrl}/cash-register/device/${deviceId}/heartbeat`, {}, token);
      this.lastHeartbeatAt = now;
      log.debug('[SyncEngine] Heartbeat sikeres:', deviceId);
    } catch (err) {
      log.warn('[SyncEngine] Heartbeat sikertelen (nem blokkolo):', splitSyncError(err).masked);
    }
  }
}

/**
 * Globális SyncEngine példány — az electron main process-ben használjuk.
 */
export const syncEngine = new SyncEngine();
