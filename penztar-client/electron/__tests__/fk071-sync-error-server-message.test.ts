/**
 * FK-071 FR-1 — RED-fázis specifikációs teszt (implementáció nélkül, buknia kell).
 *
 * Given: egy offline tranzakció feltöltése 4xx válasszal elutasításra kerül,
 *        és a szerver a GlobalExceptionHandler egységes ErrorResponse JSON-jét
 *        adja vissza ({ timestamp, status, error, message [, fieldErrors] }).
 * When:  a sync-engine feldolgozza a hibát.
 * Then:  a helyi pending soron (markTransactionSyncError) a szerver-válasz
 *        `message` mezőjének tényleges szövege kerül tárolásra, nem csak a
 *        HTTP-státuszkód + statusText.
 *
 * Jelenlegi (bukó) viselkedés: a sync-engine httpPost() a response body
 * beolvasása NÉLKÜL dob HttpStatusError-t (`HTTP ${status}: ${statusText}`),
 * így a sync_error mezőbe csak pl. "HTTP 400: Bad Request" kerül — a szerver
 * érdemi hibaüzenete (pl. árfolyam-eltérés, fedezethiány) elveszik.
 *
 * Megjegyzés: a sync-engine NEM axios-t használ, hanem natív fetch-et, ezért a
 * feladatban említett `error.response?.data?.message` konvenció itt a válasz
 * JSON-body `message` mezőjének beolvasását jelenti (Fázis 0/B + 0/E felderítés).
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
import {
  getConfig,
  getPendingTransactions,
  markTransactionSynced,
  markTransactionSyncError,
} from '../sqlite';

const mockedGetConfig = vi.mocked(getConfig);
const mockedGetPendingTransactions = vi.mocked(getPendingTransactions);
const mockedMarkTransactionSynced = vi.mocked(markTransactionSynced);
const mockedMarkTransactionSyncError = vi.mocked(markTransactionSyncError);

function makeTx(
  id: number,
  overrides: Partial<ReturnType<typeof getPendingTransactions>[number]> = {},
): ReturnType<typeof getPendingTransactions>[number] {
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
    created_at: '2026-07-29 10:00:00',
    synced: 0,
    ...overrides,
  };
}

/**
 * A backend GlobalExceptionHandler tényleges ErrorResponse formátumát utánzó
 * fetch-válasz (Fázis 0/E: { timestamp, status, error, message }).
 */
function make4xxResponse(status: number, statusText: string, errorCode: string, message: string) {
  const body = {
    timestamp: '2026-07-29T10:00:01',
    status,
    error: errorCode,
    message,
  };
  return {
    ok: false,
    status,
    statusText,
    json: () => Promise.resolve(body),
    text: () => Promise.resolve(JSON.stringify(body)),
  };
}

describe('FK-071 FR-1 — 4xx szerver-hibaüzenet tartós tárolása', () => {
  let engine: SyncEngine;

  beforeEach(() => {
    vi.resetAllMocks();
    engine = new SyncEngine();
    mockedGetConfig.mockImplementation((key: string) => {
      if (key === 'server_url') return 'http://localhost:8080/api/v1';
      return null;
    });
  });

  afterEach(() => {
    engine.stop();
    vi.unstubAllGlobals();
  });

  it('FR-1: 400-as üzleti validációs hibánál a szerver ErrorResponse.message szövege kerül a sync_error-ba, nem csak a HTTP-státuszkód', async () => {
    const serverMessage =
      'Az árfolyam nem egyezik az érvényes kihirdetett árfolyammal — kérjük frissítse az árfolyamokat';
    mockedGetPendingTransactions.mockReturnValue([makeTx(1)]);

    const mockFetch = vi
      .fn()
      .mockResolvedValue(make4xxResponse(400, 'Bad Request', 'BAD_REQUEST', serverMessage));
    vi.stubGlobal('fetch', mockFetch);

    const result = await engine.syncAll('test-token');

    expect(result.synced).toBe(0);
    expect(result.failed).toBe(1);
    expect(mockedMarkTransactionSynced).not.toHaveBeenCalled();

    // A hibát tartósan rögzíteni kell a pending soron…
    expect(mockedMarkTransactionSyncError).toHaveBeenCalled();
    const [txId, storedError] = mockedMarkTransactionSyncError.mock.calls.at(-1)!;
    expect(txId).toBe(1);

    // …és a tárolt szövegnek a szerver TÉNYLEGES üzenetét kell tartalmaznia,
    // nem csak a "HTTP 400: Bad Request" státuszsort.
    expect(String(storedError)).toContain(serverMessage);
  });

  it('FR-1: 422-es BusinessException-nél is a szerver message mező kerül tárolásra', async () => {
    const serverMessage = 'Fedezethiány: a pénztárban nincs elegendő EUR készlet a tranzakcióhoz';
    mockedGetPendingTransactions.mockReturnValue([makeTx(7, { type: 'BUY' })]);

    const mockFetch = vi
      .fn()
      .mockResolvedValue(
        make4xxResponse(422, 'Unprocessable Entity', 'INSUFFICIENT_BALANCE', serverMessage),
      );
    vi.stubGlobal('fetch', mockFetch);

    const result = await engine.syncAll('test-token');

    expect(result.failed).toBe(1);
    expect(mockedMarkTransactionSyncError).toHaveBeenCalled();
    const [txId, storedError] = mockedMarkTransactionSyncError.mock.calls.at(-1)!;
    expect(txId).toBe(7);
    expect(String(storedError)).toContain(serverMessage);
  });
});
