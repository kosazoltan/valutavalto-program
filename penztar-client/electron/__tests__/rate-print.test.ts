import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';

vi.mock('electron', () => ({
  safeStorage: {
    isEncryptionAvailable: vi.fn(() => false),
    decryptString: vi.fn(),
  },
}));

const dbRun = vi.fn();
const dbExec = vi.fn(() => []);
const db = { run: dbRun, exec: dbExec };

vi.mock('../sqlite', () => ({
  getConfig: vi.fn((key: string) => {
    if (key === 'server_url') return 'https://backend.test/api/v1';
    if (key === 'auth_token') return 'token-abc';
    if (key === 'branch_code') return 'BR001';
    if (key === 'worker_name') return 'Teszt Pénztáros';
    if (key === 'company_type') return 'BEST_CHANGE';
    return null;
  }),
  setConfig: vi.fn(),
  deleteConfig: vi.fn(),
  getDb: vi.fn(() => db),
  saveDatabase: vi.fn(),
  getPendingTransactions: vi.fn(() => []),
  getPendingConversions: vi.fn(() => []),
  getPendingBankTransactions: vi.fn(() => []),
  getPendingStornos: vi.fn(() => []),
  getReassertableTransactions: vi.fn(() => []),
  getReassertableConversions: vi.fn(() => []),
  getReassertableStornos: vi.fn(() => []),
  getReassertableBankTransactions: vi.fn(() => []),
  getPendingDistributions: vi.fn(() => []),
  markDistributionSynced: vi.fn(),
  getPendingTransfers: vi.fn(() => []),
  markTransferSynced: vi.fn(),
  getPendingTransferStornos: vi.fn(() => []),
  getPendingCircularReplies: vi.fn(() => []),
  markTransferStornoSynced: vi.fn(),
  markCircularReplySynced: vi.fn(),
  getPendingCollections: vi.fn(() => []),
  markCollectionSynced: vi.fn(),
  getPendingStocktakeItems: vi.fn(() => []),
  markStocktakeItemSynced: vi.fn(),
  markStocktakeItemError: vi.fn(),
  getPendingHandoverOperations: vi.fn(() => []),
  markHandoverOperationSynced: vi.fn(),
  saveCachedBranchStatus: vi.fn(),
  saveCachedCashDesk: vi.fn(),
  saveCachedWorker: vi.fn(),
}));

vi.mock('../printer', () => ({
  printReceipt: vi.fn(),
}));

import { SyncEngine } from '../sync-engine';
import { printReceipt } from '../printer';
import { deleteConfig } from '../sqlite';

const mockedPrintReceipt = vi.mocked(printReceipt);
const mockedDeleteConfig = vi.mocked(deleteConfig);

const obligation = {
  distributionId: 'dist-1',
  masterRateId: 'master-1',
  currencyCode: 'EUR',
  versionNumber: 3,
  baseBuyRate: 390.1,
  baseSellRate: 401.2,
  officialRate: 395.5,
  limit1Amount: 1000,
  limit1BuyRate: 389,
  limit1SellRate: 402,
  limit2Amount: null,
  limit2BuyRate: null,
  limit2SellRate: null,
  limit3Amount: null,
  limit3BuyRate: null,
  limit3SellRate: null,
  validFrom: '2026-07-04T09:00:00',
  printProofToken: 'proof-token',
};

function jsonResponse(body: unknown, ok = true, status = 200): Response {
  return {
    ok,
    status,
    statusText: ok ? 'OK' : 'ERR',
    json: vi.fn(async () => body),
  } as unknown as Response;
}

function outboxRows(values: Array<[string, string, string]>): Array<{
  columns: string[];
  values: Array<[string, string, string]>;
}> {
  return [{ columns: ['distribution_id', 'token', 'printed_at'], values }];
}

const pendingPrintUrl =
  'https://backend.test/api/v1/exchange-rate-master/distribution/pending-print';

describe('SyncEngine — rate print obligations', () => {
  let engine: SyncEngine;

  beforeEach(() => {
    vi.clearAllMocks();
    dbExec.mockReturnValue([]);
    engine = new SyncEngine();
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('lekéri a pending-print kötelezettségeket, nyomtat, majd proof tokennel ACK-ol', async () => {
    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce(jsonResponse([obligation]))
      .mockResolvedValueOnce({ ok: true, status: 200, statusText: 'OK' } as Response);
    vi.stubGlobal('fetch', fetchMock);
    mockedPrintReceipt.mockResolvedValue(true);

    await engine.syncRatePrintObligations();

    expect(fetchMock).toHaveBeenNthCalledWith(
      1,
      'https://backend.test/api/v1/exchange-rate-master/distribution/pending-print',
      expect.objectContaining({ method: 'GET' }),
    );
    expect(mockedPrintReceipt).toHaveBeenCalledWith(
      expect.objectContaining({
        type: 'rate_change',
        currencyCode: 'EUR',
        rate: 401.2,
        receiptNumber: 'RATE-master-1-v3',
      }),
    );
    expect(fetchMock).toHaveBeenNthCalledWith(
      2,
      'https://backend.test/api/v1/exchange-rate-master/distribution/dist-1/acknowledge',
      expect.objectContaining({
        method: 'POST',
        headers: expect.objectContaining({ Authorization: 'Bearer token-abc' }),
        body: JSON.stringify({ printProofToken: 'proof-token' }),
      }),
    );
  });

  it('nyomtatási hiba esetén nem küld acknowledge POST-ot', async () => {
    const fetchMock = vi.fn().mockResolvedValueOnce(jsonResponse([obligation]));
    vi.stubGlobal('fetch', fetchMock);
    mockedPrintReceipt.mockResolvedValue(false);

    await engine.syncRatePrintObligations();

    expect(mockedPrintReceipt).toHaveBeenCalledOnce();
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(dbRun).not.toHaveBeenCalledWith(
      expect.stringContaining('INSERT INTO rate_print_outbox'),
      expect.any(Array),
    );
  });

  it('acknowledge hálózati hiba esetén outboxba ment, majd következő sync elején flusholja', async () => {
    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce(jsonResponse([obligation]))
      .mockRejectedValueOnce(new TypeError('network down'))
      .mockResolvedValueOnce({ ok: true, status: 200, statusText: 'OK' } as Response)
      .mockResolvedValueOnce(jsonResponse([]));
    vi.stubGlobal('fetch', fetchMock);
    mockedPrintReceipt.mockResolvedValue(true);

    await engine.syncRatePrintObligations();

    expect(dbRun).toHaveBeenCalledWith(expect.stringContaining('INSERT INTO rate_print_outbox'), [
      'dist-1',
      'proof-token',
      expect.any(String),
    ]);

    dbExec.mockReturnValueOnce([
      {
        columns: ['distribution_id', 'token', 'printed_at'],
        values: [['dist-1', 'proof-token', '2026-07-04T09:05:00.000Z']],
      },
    ]);
    await engine.syncRatePrintObligations();

    expect(fetchMock).toHaveBeenCalledWith(
      'https://backend.test/api/v1/exchange-rate-master/distribution/dist-1/acknowledge',
      expect.objectContaining({
        method: 'POST',
        body: JSON.stringify({ printProofToken: 'proof-token' }),
      }),
    );
    expect(dbRun).toHaveBeenCalledWith('DELETE FROM rate_print_outbox WHERE distribution_id = ?', [
      'dist-1',
    ]);
  });
});

describe('SyncEngine — rate print outbox poison isolation', () => {
  let engine: SyncEngine;

  beforeEach(() => {
    vi.clearAllMocks();
    dbExec.mockReturnValue([]);
    engine = new SyncEngine();
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('poison (400) sor DROP-olódik, a következő valid sor ACK-olódik, a fetch lefut', async () => {
    dbExec.mockReturnValueOnce(
      outboxRows([
        ['dist-poison', 'poison-token', '2026-07-04T09:05:00.000Z'],
        ['dist-ok', 'ok-token', '2026-07-04T09:06:00.000Z'],
      ]),
    );
    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce({ ok: false, status: 400, statusText: 'Bad Request' } as Response)
      .mockResolvedValueOnce({ ok: true, status: 200, statusText: 'OK' } as Response)
      .mockResolvedValueOnce(jsonResponse([]));
    vi.stubGlobal('fetch', fetchMock);

    await engine.syncRatePrintObligations();

    expect(dbRun).toHaveBeenCalledWith('DELETE FROM rate_print_outbox WHERE distribution_id = ?', [
      'dist-poison',
    ]);
    expect(dbRun).toHaveBeenCalledWith('DELETE FROM rate_print_outbox WHERE distribution_id = ?', [
      'dist-ok',
    ]);
    expect(fetchMock).toHaveBeenCalledTimes(3);
    expect(fetchMock).toHaveBeenNthCalledWith(
      3,
      pendingPrintUrl,
      expect.objectContaining({ method: 'GET' }),
    );
  });

  it('csak poison sor esetén nincs throw a hívóig és a fetch lefut', async () => {
    dbExec.mockReturnValueOnce(
      outboxRows([['dist-poison', 'poison-token', '2026-07-04T09:05:00.000Z']]),
    );
    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce({ ok: false, status: 400, statusText: 'Bad Request' } as Response)
      .mockResolvedValueOnce(jsonResponse([]));
    vi.stubGlobal('fetch', fetchMock);

    await expect(engine.syncRatePrintObligations()).resolves.toBeUndefined();

    expect(dbRun).toHaveBeenCalledWith('DELETE FROM rate_print_outbox WHERE distribution_id = ?', [
      'dist-poison',
    ]);
    expect(fetchMock).toHaveBeenNthCalledWith(
      2,
      pendingPrintUrl,
      expect.objectContaining({ method: 'GET' }),
    );
    expect(dbRun).not.toHaveBeenCalledWith(
      expect.stringContaining('INSERT INTO rate_print_outbox'),
      expect.any(Array),
    );
  });

  it('HTTP 503 esetén a sor megmarad, és a fetch lefut', async () => {
    dbExec.mockReturnValueOnce(
      outboxRows([['dist-transient', 'transient-token', '2026-07-04T09:05:00.000Z']]),
    );
    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce({
        ok: false,
        status: 503,
        statusText: 'Service Unavailable',
      } as Response)
      .mockResolvedValueOnce(jsonResponse([]));
    vi.stubGlobal('fetch', fetchMock);

    await engine.syncRatePrintObligations();

    expect(dbRun).not.toHaveBeenCalledWith(
      'DELETE FROM rate_print_outbox WHERE distribution_id = ?',
      ['dist-transient'],
    );
    expect(fetchMock).toHaveBeenNthCalledWith(
      2,
      pendingPrintUrl,
      expect.objectContaining({ method: 'GET' }),
    );
  });

  it('hálózati hiba (TypeError) esetén a sor megmarad, és a fetch lefut', async () => {
    dbExec.mockReturnValueOnce(
      outboxRows([['dist-network', 'network-token', '2026-07-04T09:05:00.000Z']]),
    );
    const fetchMock = vi
      .fn()
      .mockRejectedValueOnce(new TypeError('network down'))
      .mockResolvedValueOnce(jsonResponse([]));
    vi.stubGlobal('fetch', fetchMock);

    await engine.syncRatePrintObligations();

    expect(dbRun).not.toHaveBeenCalledWith(
      'DELETE FROM rate_print_outbox WHERE distribution_id = ?',
      ['dist-network'],
    );
    expect(fetchMock).toHaveBeenNthCalledWith(
      2,
      pendingPrintUrl,
      expect.objectContaining({ method: 'GET' }),
    );
  });

  it('429 nem poison: a sor megmarad, és a fetch lefut', async () => {
    dbExec.mockReturnValueOnce(
      outboxRows([['dist-rate-limited', 'rate-limit-token', '2026-07-04T09:05:00.000Z']]),
    );
    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce({
        ok: false,
        status: 429,
        statusText: 'Too Many Requests',
      } as Response)
      .mockResolvedValueOnce(jsonResponse([]));
    vi.stubGlobal('fetch', fetchMock);

    await engine.syncRatePrintObligations();

    expect(dbRun).not.toHaveBeenCalledWith(
      'DELETE FROM rate_print_outbox WHERE distribution_id = ?',
      ['dist-rate-limited'],
    );
    expect(fetchMock).toHaveBeenNthCalledWith(
      2,
      pendingPrintUrl,
      expect.objectContaining({ method: 'GET' }),
    );
  });

  it('auth-hiba a meglévő külső auth ágon fut: outbox marad, fetch nem fut, token törlődik', async () => {
    dbExec.mockReturnValueOnce(
      outboxRows([['dist-auth', 'auth-token', '2026-07-04T09:05:00.000Z']]),
    );
    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce({ ok: false, status: 401, statusText: 'Unauthorized' } as Response);
    vi.stubGlobal('fetch', fetchMock);

    await engine.syncRatePrintObligations();

    expect(dbRun).not.toHaveBeenCalledWith(
      'DELETE FROM rate_print_outbox WHERE distribution_id = ?',
      ['dist-auth'],
    );
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(mockedDeleteConfig).toHaveBeenCalledWith('auth_token');
  });
});
