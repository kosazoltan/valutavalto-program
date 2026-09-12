/**
 * FKH-067 (spec doc: FKH-063) FR-1 — a sync payload viszi a kliens eredeti rogzitesi idejet.
 *
 * A backend (ExchangeRateService, TTL_NONBLOCKING_CUTOFF) ebbol tudja eldonteni, hogy egy elavult
 * arfolyamu tetel az UJ (nem-blokkolo) vagy a REGI (blokkolo) szabaly ala esik. A `created_at`
 * a helyi rogziteskor kapott, VALTOZATLAN ertek — retry eseten sem frissul (a markTransactionSynced
 * csak a `synced` oszlopot irja), ezert alkalmas a megkulonboztetesre.
 *
 * A sync-engine.test.ts mock-preambulumanak mintajara.
 */
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';

const mockLog = vi.hoisted(() => ({ warn: vi.fn(), info: vi.fn(), error: vi.fn() }));

vi.mock('electron-log', () => ({ default: mockLog }));
vi.mock('electron-log/main', () => ({ default: mockLog }));

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
  net: { request: vi.fn() },
  IncomingMessage: class {},
}));

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
  markConversionSynced: vi.fn(),
  markBankTransactionSynced: vi.fn(),
  markStornoSynced: vi.fn(),
  markDistributionSynced: vi.fn(),
  markTransferSynced: vi.fn(),
  markTransferStornoSynced: vi.fn(),
  markCircularReplySynced: vi.fn(),
  markCollectionSynced: vi.fn(),
  markHandoverOperationSynced: vi.fn(),
  getPendingScannedDocuments: vi.fn(() => []),
  markScannedDocumentSynced: vi.fn(),
  markScannedDocumentSyncError: vi.fn(),
  saveCachedBranchStatus: vi.fn(),
  saveCachedCashDesk: vi.fn(),
  saveCachedWorker: vi.fn(),
}));

import { SyncEngine } from '../sync-engine';
import { getConfig, getPendingTransactions } from '../sqlite';

const mockedGetConfig = vi.mocked(getConfig);
const mockedGetPendingTransactions = vi.mocked(getPendingTransactions);

type PendingRow = Parameters<typeof mockedGetPendingTransactions.mockReturnValue>[0][number];

const baseRow = (overrides: Partial<PendingRow>): PendingRow =>
  ({
    id: 1,
    type: 'BUY',
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
    local_reference_number: 'LV-20260912-0001',
    idempotency_key: 'key-fkh067-1',
    created_at: '2026-09-12 08:15:00',
    synced: 0,
    ...overrides,
  }) as PendingRow;

describe('SyncEngine — FKH-067 FR-1: clientCreatedAt a tranzakcio-payloadban', () => {
  let engine: SyncEngine;
  let mockFetch: ReturnType<typeof vi.fn>;

  beforeEach(() => {
    vi.clearAllMocks();
    mockedGetConfig.mockImplementation((key: string) => {
      if (key === 'server_url') return 'http://localhost:8080/api/v1';
      if (key === 'auth_token') return 'test-token';
      if (key === 'offline_mode') return '';
      return null;
    });
    mockFetch = vi.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ success: true }),
    });
    vi.stubGlobal('fetch', mockFetch);
    engine = new SyncEngine();
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  const syncOneAndReadBody = async (): Promise<Record<string, unknown>> => {
    const result = await engine.syncAll('test-token');
    expect(result.synced).toBe(1);
    const fetchCall = mockFetch.mock.calls[0]!;
    return JSON.parse((fetchCall[1] as { body: string }).body);
  };

  it('a BUY payload a pending sor created_at erteket kuldi ISO-8601-ben', async () => {
    mockedGetPendingTransactions.mockReturnValue([baseRow({})]);

    const body = await syncOneAndReadBody();

    // A pending sor `created_at`-ja SQLite `datetime('now')` = UTC, zona-jelzes nelkul.
    expect(body.clientCreatedAt).toBe('2026-09-12T08:15:00.000Z');
  });

  it('a SELL payload is viszi a mezot (mindket vegpont)', async () => {
    mockedGetPendingTransactions.mockReturnValue([
      baseRow({ id: 2, type: 'SELL', idempotency_key: 'key-fkh067-2' }),
    ]);

    const body = await syncOneAndReadBody();

    // A pending sor `created_at`-ja SQLite `datetime('now')` = UTC, zona-jelzes nelkul.
    expect(body.clientCreatedAt).toBe('2026-09-12T08:15:00.000Z');
  });

  it('a kuldott ertek a ROGZITES ideje, NEM a szinkron pillanata (retry-nal sem csuszik)', async () => {
    // A tetel 3 napja rogzult, a sync most fut. Ha a kliens `Date.now()`-ot kuldene, egy regi,
    // fennakadt tetel a cutoff UTANI-nak latszana es a hatter-retry akaratlanul feloldana (FR-5).
    const recordedAt = new Date(Date.now() - 3 * 24 * 3_600_000);
    const recordedAtSqlite = recordedAt.toISOString().replace('T', ' ').slice(0, 19);
    mockedGetPendingTransactions.mockReturnValue([
      baseRow({ id: 3, created_at: recordedAtSqlite, idempotency_key: 'key-fkh067-3' }),
    ]);

    const body = await syncOneAndReadBody();

    const sent = new Date(body.clientCreatedAt as string).getTime();
    expect(Math.abs(sent - recordedAt.getTime())).toBeLessThan(1000);
    // A sync pillanatatol legalabb 2 nap tavolsagra van — nem a mostani ido ment fel.
    expect(Date.now() - sent).toBeGreaterThan(2 * 24 * 3_600_000);
  });

  it('hianyzo/ertelmezhetetlen created_at eseten a mezo KIMARAD (a backend fail-closed agara esik)', async () => {
    mockedGetPendingTransactions.mockReturnValue([
      baseRow({ id: 4, created_at: 'nem-datum', idempotency_key: 'key-fkh067-4' }),
    ]);

    const body = await syncOneAndReadBody();

    expect(body).not.toHaveProperty('clientCreatedAt');
  });
});
