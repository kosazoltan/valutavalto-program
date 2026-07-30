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

import { SyncEngine } from '../sync-engine';
import { sanitizeSyncErrorMessage, EMAIL_MASK, PHONE_MASK } from '../sync-error-sanitizer';
import { getConfig, getPendingTransactions, markTransactionSyncError } from '../sqlite';

const mockedGetConfig = vi.mocked(getConfig);
const mockedGetPendingTransactions = vi.mocked(getPendingTransactions);
const mockedMarkTransactionSyncError = vi.mocked(markTransactionSyncError);

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
