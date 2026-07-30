/**
 * FK-071 MEDIUM-E (Codex security review) — PII-szűrés TÁROLÁS és NAPLÓZÁS előtt.
 *
 * Given: egy 4xx-szel elutasított feltöltés szerver-üzenete PII-t (e-mail,
 *        telefonszám) tartalmaz.
 * When:  a sync-engine feldolgozza a hibát (automatikus sync és kézi újraküldés).
 * Then:  a perzisztált érték (markTransactionSyncError → sync_error + kísérlet-
 *        napló), a SyncResult.errors és a kézi retry visszatérési értéke MASZKOLT
 *        — miközben a PR #116 business-error detektor a NYERS szövegen fut, így
 *        az abandoned-viselkedés változatlan (sorrend: detektor → maszkolás →
 *        tárolás/log).
 */
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';

// Mock electron-log — a log-hívások argumentumait vizsgáljuk (maszkolt-e a tartalom).
vi.mock('electron-log', () => ({
  default: {
    info: vi.fn(),
    warn: vi.fn(),
    error: vi.fn(),
    debug: vi.fn(),
  },
}));

// Mock electron
vi.mock('electron', () => ({
  app: {
    getPath: vi.fn(() => '/tmp/test-valuta'),
    getAppPath: vi.fn(() => '/tmp/test-valuta-app'),
    isPackaged: false,
  },
  safeStorage: {
    isEncryptionAvailable: vi.fn(() => false),
    encryptString: vi.fn(),
    decryptString: vi.fn(),
  },
}));

// Mock sqlite module
vi.mock('../sqlite', () => ({
  getConfig: vi.fn(() => null),
  setConfig: vi.fn(),
  deleteConfig: vi.fn(),
  getDb: vi.fn(() => null),
  saveDatabase: vi.fn(),
  getPendingTransactions: vi.fn(() => []),
  getPendingConversions: vi.fn(() => []),
  getPendingBankTransactions: vi.fn(() => []),
  getPendingStornos: vi.fn(() => []),
  getPendingDistributions: vi.fn(() => []),
  getPendingTransfers: vi.fn(() => []),
  getPendingTransferStornos: vi.fn(() => []),
  getPendingCircularReplies: vi.fn(() => []),
  getPendingCollections: vi.fn(() => []),
  getPendingHandoverOperations: vi.fn(() => []),
  getPendingShipmentReceipts: vi.fn(() => []),
  getReassertableTransactions: vi.fn(() => []),
  getReassertableConversions: vi.fn(() => []),
  getReassertableStornos: vi.fn(() => []),
  getReassertableBankTransactions: vi.fn(() => []),
  markTransactionSynced: vi.fn(),
  markTransactionSyncError: vi.fn(),
  markConversionSynced: vi.fn(),
  markBankTransactionSynced: vi.fn(),
  markStornoSynced: vi.fn(),
  markDistributionSynced: vi.fn(),
  markTransferSynced: vi.fn(),
  markTransferStornoSynced: vi.fn(),
  markCircularReplySynced: vi.fn(),
  markCollectionSynced: vi.fn(),
  markHandoverOperationSynced: vi.fn(),
  saveCachedBranchStatus: vi.fn(),
  saveCachedCashDesk: vi.fn(),
  saveCachedWorker: vi.fn(),
}));

import log from 'electron-log';
import { SyncEngine } from '../sync-engine';
import { sanitizeSyncErrorMessage, EMAIL_MASK, PHONE_MASK } from '../sync-error-sanitizer';
import {
  getConfig,
  getPendingCollections,
  getPendingDistributions,
  getPendingTransactions,
  getPendingTransfers,
  getReassertableTransactions,
  markTransactionSyncError,
} from '../sqlite';

const mockedGetConfig = vi.mocked(getConfig);
const mockedGetPendingTransactions = vi.mocked(getPendingTransactions);
const mockedGetPendingDistributions = vi.mocked(getPendingDistributions);
const mockedGetPendingTransfers = vi.mocked(getPendingTransfers);
const mockedGetPendingCollections = vi.mocked(getPendingCollections);
const mockedGetReassertableTransactions = vi.mocked(getReassertableTransactions);
const mockedMarkTransactionSyncError = vi.mocked(markTransactionSyncError);

/**
 * Egy log-argumentum teljes szöveges reprezentációja — Error-TUDATOSAN.
 *
 * FK-071 MEDIUM-E 3. kör (Codex teszt-vakfolt): a natív JSON.stringify az
 * Error-objektumot üres `{}`-ként írja ki (a .message/.stack nem saját
 * enumerable property), így a korábbi, JSON.stringify-alapú szkennelés a
 * NYERS Error-objektumként logolt PII-t nem látta volna. A javított változat
 * az Error-t (közvetlen argumentumként ÉS beágyazott property-ként is)
 * name+message+stack formában bontja ki.
 */
function logArgToText(a: unknown): string {
  if (typeof a === 'string') return a;
  if (a instanceof Error) {
    return `${a.name}: ${a.message}\n${a.stack ?? ''}`;
  }
  try {
    return (
      JSON.stringify(a, (_key, value: unknown) =>
        value instanceof Error ? `${value.name}: ${value.message} ${value.stack ?? ''}` : value,
      ) ?? String(a)
    );
  } catch {
    return String(a);
  }
}

/**
 * Az ÖSSZES electron-log hívás (warn/error/info/debug) minden argumentuma,
 * egyetlen szövegként — így a teszt a teljes log-felületet szkenneli PII-re,
 * beleértve a httpPost-réteg `{ url, err }` logját is, nem csak az ág saját
 * log-sorát.
 */
function allLoggedText(): string {
  return [log.warn, log.error, log.info, log.debug]
    .flatMap((fn) => vi.mocked(fn).mock.calls)
    .map((args) => args.map(logArgToText).join(' '))
    .join('\n');
}

const PII_EMAIL = 'kovacs.bela@example.com';
const PII_PHONE = '+36 20 123 4567';
const SERVER_MESSAGE_WITH_PII = `Érvénytelen címzett email: ${PII_EMAIL}, telefonszám: ${PII_PHONE}`;

function makeTx(id: number): ReturnType<typeof getPendingTransactions>[number] {
  return {
    id,
    type: 'SELL',
    currency_code: 'EUR',
    foreign_amount: 100,
    huf_amount: 40000,
    rounded_huf_amount: 40000,
    rate: 400,
    handling_fee: null,
    discount_percent: null,
    customer_id: null,
    customer_identifier: null,
    customer_name: null,
    customer_document_number: null,
    customer_address: null,
    denominations: null,
    source_of_funds: null,
    customer_is_pep: null,
    foreign_status: null,
    local_reference_number: `LS-${id}`,
    idempotency_key: `ikey-${id}`,
    created_at: '2026-07-30 10:00:00',
    synced: 0,
  };
}

function make4xxWithPiiResponse() {
  const body = {
    timestamp: '2026-07-30T10:00:01',
    status: 400,
    error: 'BAD_REQUEST',
    message: SERVER_MESSAGE_WITH_PII,
  };
  return {
    ok: false,
    status: 400,
    statusText: 'Bad Request',
    json: () => Promise.resolve(body),
    text: () => Promise.resolve(JSON.stringify(body)),
  };
}

describe('FK-071 MEDIUM-E — sanitizer egység (Electron main oldali modul)', () => {
  it('e-mail-címet és telefonszámot maszkol, a lényegi tartalom megmarad', () => {
    const masked = sanitizeSyncErrorMessage(`HTTP 400: Bad Request — ${SERVER_MESSAGE_WITH_PII}`);
    expect(masked).not.toContain(PII_EMAIL);
    expect(masked).not.toContain(PII_PHONE);
    expect(masked).toContain(EMAIL_MASK);
    expect(masked).toContain(PHONE_MASK);
    expect(masked).toContain('Érvénytelen címzett email');
  });

  it('a "HTTP {status}: {statusText}" prefixet változatlanul hagyja (PR #116 detektor-invariáns)', () => {
    // A detektor a /HTTP (4\d\d)/ prefixre épül — a maszkolás ezt nem érintheti.
    // A "HTTP 406" határeset is védett: a számjegy-lookbehind miatt a '06' nem
    // telefonszám-kezdet.
    for (const prefix of [
      'HTTP 400: Bad Request',
      'HTTP 406: Not Acceptable',
      'HTTP 422: Unprocessable Entity',
    ]) {
      expect(sanitizeSyncErrorMessage(`${prefix} — ${SERVER_MESSAGE_WITH_PII}`)).toContain(prefix);
    }
  });
});

describe('FK-071 MEDIUM-E — maszkolt tárolás + nyers detektor a sync-engine-ben', () => {
  let engine: SyncEngine;

  beforeEach(() => {
    vi.resetAllMocks();
    engine = new SyncEngine();
    mockedGetConfig.mockImplementation((key: string) => {
      if (key === 'server_url') return 'http://localhost:8080/api/v1';
      if (key === 'auth_token') return 'test-token'; // a kézi retry-hoz (getAuthToken)
      return null;
    });
  });

  afterEach(() => {
    engine.stop();
    vi.unstubAllGlobals();
  });

  it('automatikus sync: a sync_error-ba maszkolt üzenet kerül, a SyncResult.errors is maszkolt', async () => {
    mockedGetPendingTransactions.mockReturnValue([makeTx(1)]);
    const mockFetch = vi.fn().mockResolvedValue(make4xxWithPiiResponse());
    vi.stubGlobal('fetch', mockFetch);

    const result = await engine.syncAll('test-token');

    expect(result.failed).toBe(1);

    // Perzisztált érték (sync_error + a kísérlet-napló ugyanezt a stringet kapja
    // a markTransactionSyncError-ön belül): maszkolt, PII nélkül.
    expect(mockedMarkTransactionSyncError).toHaveBeenCalled();
    const [, storedError] = mockedMarkTransactionSyncError.mock.calls.at(-1)!;
    expect(String(storedError)).not.toContain(PII_EMAIL);
    expect(String(storedError)).not.toContain(PII_PHONE);
    expect(String(storedError)).toContain(EMAIL_MASK);
    // A lényegi tartalom és a HTTP-prefix megmarad (FR-1 + FR-2 nem sérül).
    expect(String(storedError)).toContain('HTTP 400');
    expect(String(storedError)).toContain('Érvénytelen címzett email');

    // A SyncResult.errors (log + renderer-státusz felé) szintén maszkolt.
    const joinedErrors = result.errors.join(' | ');
    expect(joinedErrors).not.toContain(PII_EMAIL);
    expect(joinedErrors).not.toContain(PII_PHONE);
  });

  it('a PR #116 business-error detektor a nyers szövegen fut: a 4xx-es tétel abandoned marad', async () => {
    mockedGetPendingTransactions.mockReturnValue([makeTx(1)]);
    const mockFetch = vi.fn().mockResolvedValue(make4xxWithPiiResponse());
    vi.stubGlobal('fetch', mockFetch);

    await engine.syncAll('test-token');
    const callsAfterFirstRun = mockFetch.mock.calls.length;
    expect(callsAfterFirstRun).toBeGreaterThan(0);

    // Második auto-sync kör: az abandoned (business error) tétel kimarad,
    // nincs újabb feltöltési kísérlet.
    const result2 = await engine.syncAll('test-token');
    expect(mockFetch.mock.calls.length).toBe(callsAfterFirstRun);
    expect(result2.failed).toBe(0);
  });

  // ───────────────────────────────────────────────────────────────────────
  // MEDIUM-E maradék (Codex 2. kör): az önálló értéktár-sync ágak logja is
  // maszkolt. Minden teszt a TELJES log-felületet szkenneli (allLoggedText),
  // így a httpPost-réteg `{ url, err }` logját is lefedi.
  // ───────────────────────────────────────────────────────────────────────

  it('syncDistributions: 4xx+PII válasznál a log maszkolt, nyers PII sehol nem jelenik meg', async () => {
    mockedGetPendingDistributions.mockReturnValue([
      {
        id: 7,
        company_code: null,
        target_branch_code: 'BUD02',
        currency_code: 'EUR',
        amount: 1000,
        denominations: null,
        note: null,
        idempotency_key: 'ikey-d7',
      },
    ] as unknown as ReturnType<typeof getPendingDistributions>);
    const mockFetch = vi.fn().mockResolvedValue(make4xxWithPiiResponse());
    vi.stubGlobal('fetch', mockFetch);

    await engine.syncDistributions();

    const logged = allLoggedText();
    expect(logged).toContain('Distribution #7 sync hiba');
    expect(logged).toContain(EMAIL_MASK);
    expect(logged).not.toContain(PII_EMAIL);
    expect(logged).not.toContain(PII_PHONE);
  });

  it('syncTransfers: 4xx+PII válasznál a log maszkolt, nyers PII sehol nem jelenik meg', async () => {
    mockedGetPendingTransfers.mockReturnValue([
      {
        id: 9,
        company_code: null,
        amount: 500,
        target_branch_id: null,
        target_branch_code: 'BUD03',
        currency_id: 1,
        currency_code: 'EUR',
        transfer_type: null,
        huf_value: null,
        denominations: null,
        note: null,
        carrier_name: 'Futár',
        seal_number: 'SEAL-1',
        direction: null,
        lines: null,
        idempotency_key: 'ikey-t9',
      },
    ] as unknown as ReturnType<typeof getPendingTransfers>);
    const mockFetch = vi.fn().mockResolvedValue(make4xxWithPiiResponse());
    vi.stubGlobal('fetch', mockFetch);

    await engine.syncTransfers();

    const logged = allLoggedText();
    expect(logged).toContain('Transfer #9 sync hiba');
    expect(logged).toContain(EMAIL_MASK);
    expect(logged).not.toContain(PII_EMAIL);
    expect(logged).not.toContain(PII_PHONE);
  });

  it('syncCollections: 4xx+PII válasznál a log maszkolt, nyers PII sehol nem jelenik meg', async () => {
    mockedGetPendingCollections.mockReturnValue([
      {
        id: 11,
        company_code: null,
        source_branch_code: 'BUD04',
        currency_code: 'EUR',
        amount: 250,
        note: null,
        idempotency_key: 'ikey-c11',
      },
    ] as unknown as ReturnType<typeof getPendingCollections>);
    const mockFetch = vi.fn().mockResolvedValue(make4xxWithPiiResponse());
    vi.stubGlobal('fetch', mockFetch);

    await engine.syncCollections();

    const logged = allLoggedText();
    expect(logged).toContain('Collection #11 sync hiba');
    expect(logged).toContain(EMAIL_MASK);
    expect(logged).not.toContain(PII_EMAIL);
    expect(logged).not.toContain(PII_PHONE);
  });

  // ───────────────────────────────────────────────────────────────────────
  // MEDIUM-E 3. kör (Codex): reassert hálózati-újradobás ág + szkenner-vakfolt.
  // ───────────────────────────────────────────────────────────────────────

  it('log-szkenner vakfolt-bizonyíték: a nyers Error-objektum message-ét a javított szkenner látja', () => {
    const rawError = new Error(`HTTP 400: Bad Request — ${SERVER_MESSAGE_WITH_PII}`);

    // A dokumentált vakfolt oka: a natív JSON.stringify az Error-t üres
    // objektummá írja (a .message nem saját enumerable property) — a korábbi,
    // JSON.stringify-alapú szkennelés ezért NEM látta volna a PII-t.
    expect(JSON.stringify(rawError)).toBe('{}');

    // Szimulált, javítás ELŐTTI production-hibák: nyers Error közvetlen
    // argumentumként (reassert 1671-es sor mintája) és beágyazva ({ url, err }).
    log.warn('szimulált nyers Error-log', rawError);
    log.error('szimulált beágyazott nyers Error-log', { url: 'http://x', err: rawError });

    // A javított szkenner MINDKÉT formában látja a PII-t — tehát ha a
    // production-kód bárhol nyers Error-t logolna, a többi teszt
    // not.toContain(PII) assertje ténylegesen elbukna.
    const logged = allLoggedText();
    const emailOccurrences = logged.split(PII_EMAIL).length - 1;
    expect(emailOccurrences).toBeGreaterThanOrEqual(2);
  });

  it('reassertRecentSynced: hálózati-kulcsszavas 4xx+PII válasznál az újradobási ág logja is maszkolt', async () => {
    // A tryOne a 'timeout' kulcsszó miatt a NYERS err-t dobja tovább — a külső
    // catch (netErr) terminális logjának maszkoltnak kell lennie.
    const body = {
      timestamp: '2026-07-30T10:00:01',
      status: 400,
      error: 'BAD_REQUEST',
      message: `Átjáró timeout a feldolgozás közben — értesítés küldve: ${PII_EMAIL}`,
    };
    const mockFetch = vi.fn().mockResolvedValue({
      ok: false,
      status: 400,
      statusText: 'Bad Request',
      json: () => Promise.resolve(body),
      text: () => Promise.resolve(JSON.stringify(body)),
    });
    vi.stubGlobal('fetch', mockFetch);
    mockedGetReassertableTransactions.mockReturnValue([makeTx(5)]);

    const reassert = (
      engine as unknown as {
        reassertRecentSynced(serverUrl: string, token: string): Promise<number>;
      }
    ).reassertRecentSynced.bind(engine);
    const count = await reassert('http://localhost:8080/api/v1', 'test-token');

    expect(count).toBe(0);
    const logged = allLoggedText();
    expect(logged).toContain('[Reassert] halozati hiba');
    expect(logged).toContain(EMAIL_MASK);
    expect(logged).not.toContain(PII_EMAIL);
  });

  it('bootstrapAuthSession + httpPost-réteg: 4xx+PII login-válasznál a teljes log-felület maszkolt', async () => {
    // Nincs auth_token → a kézi retry bootstrapAuthSession-t hív, a /auth/login
    // 4xx+PII választ ad → a bootstrap catch ÉS a httpPost-réteg `{ url, err }`
    // logja is maszkolt kell legyen.
    mockedGetConfig.mockImplementation((key: string) => {
      if (key === 'server_url') return 'http://localhost:8080/api/v1';
      if (key === 'bootstrap_company_code') return 'EBC';
      if (key === 'bootstrap_worker_code') return 'PENZTAR-7';
      if (key === 'bootstrap_password') return 'test-password';
      return null;
    });
    mockedGetPendingTransactions.mockReturnValue([makeTx(42)]);
    const mockFetch = vi.fn().mockResolvedValue(make4xxWithPiiResponse());
    vi.stubGlobal('fetch', mockFetch);

    const result = await engine.retryPendingTransaction(42);

    expect(result.success).toBe(false);
    const logged = allLoggedText();
    expect(logged).toContain(EMAIL_MASK);
    expect(logged).not.toContain(PII_EMAIL);
    expect(logged).not.toContain(PII_PHONE);
  });

  it('Bugbot#2: kézi retry futó háttér-szinkron alatt megvárja a ciklus végét — nincs párhuzamos HTTP-hívás ugyanarra a tételre', async () => {
    mockedGetPendingTransactions.mockReturnValue([makeTx(1)]);

    // Az 1. (háttér-) feltöltés kézzel feloldható deferred-en függ.
    let resolveFirstUpload: (value: unknown) => void = () => undefined;
    const firstUpload = new Promise((resolve) => {
      resolveFirstUpload = resolve;
    });
    const mockFetch = vi.fn().mockImplementation(() => firstUpload);
    vi.stubGlobal('fetch', mockFetch);

    // Háttér-szinkron elindul, és a deferred miatt in-flight marad.
    const backgroundSync = engine.syncAll('test-token');
    await vi.waitFor(() => expect(mockFetch).toHaveBeenCalledTimes(1));

    // Kézi retry a futó ciklus ALATT: nem indíthat második HTTP-hívást.
    const manualRetry = engine.retryPendingTransaction(1);
    await new Promise((resolve) => setTimeout(resolve, 20));
    expect(mockFetch).toHaveBeenCalledTimes(1);

    // A háttér-ciklus sikeresen befejeződik, a tétel synced lesz (kikerül a pendingből).
    mockedGetPendingTransactions.mockReturnValue([]);
    resolveFirstUpload({
      ok: true,
      status: 200,
      statusText: 'OK',
      json: () => Promise.resolve({}),
      text: () => Promise.resolve('{}'),
    });
    await backgroundSync;
    const retryResult = await manualRetry;

    // A retry a várakozás UTÁN frissen nézte meg a tételt: már nincs pending
    // sor, ezért nem indított új feltöltést — összesen 1 HTTP-hívás történt.
    expect(mockFetch).toHaveBeenCalledTimes(1);
    expect(retryResult.success).toBe(false);
    expect(String(retryResult.error)).toContain('már szinkronizálva');
  });

  it('kézi újraküldés: a visszaadott error és a perzisztált érték is maszkolt', async () => {
    mockedGetPendingTransactions.mockReturnValue([makeTx(42)]);
    const mockFetch = vi.fn().mockResolvedValue(make4xxWithPiiResponse());
    vi.stubGlobal('fetch', mockFetch);

    const result = await engine.retryPendingTransaction(42);

    expect(result.success).toBe(false);
    expect(String(result.error)).not.toContain(PII_EMAIL);
    expect(String(result.error)).not.toContain(PII_PHONE);
    expect(String(result.error)).toContain(EMAIL_MASK);

    const [, storedError] = mockedMarkTransactionSyncError.mock.calls.at(-1)!;
    expect(String(storedError)).not.toContain(PII_EMAIL);
    expect(String(storedError)).toContain(EMAIL_MASK);
  });
});
