import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

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

vi.mock('electron-log', () => ({
  default: {
    warn: vi.fn(),
    info: vi.fn(),
    error: vi.fn(),
  },
}));

vi.mock('../printer', () => ({ printReceipt: vi.fn() }));

vi.mock('../sqlite', () => ({
  getConfig: vi.fn((key: string) => {
    if (key === 'server_url') return 'https://backend.test/api/v1';
    if (key === 'auth_token') return 'token-abc';
    if (key === 'bootstrap_company_code') return 'BEST_CHANGE';
    return null;
  }),
  setConfig: vi.fn(),
  deleteConfig: vi.fn(),
  getDb: vi.fn(() => null),
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
  getPendingTransfers: vi.fn(() => []),
  getPendingTransferStornos: vi.fn(() => []),
  getPendingCircularReplies: vi.fn(() => []),
  getPendingCollections: vi.fn(() => []),
  getPendingStocktakeItems: vi.fn(() => []),
  getPendingHandoverOperations: vi.fn(() => []),
  getPendingShipmentReceipts: vi.fn(() => []),
  markShipmentReceiptSynced: vi.fn(),
  markShipmentReceiptTerminalError: vi.fn(),
  markShipmentReceiptRetryError: vi.fn(),
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
  markStocktakeItemSynced: vi.fn(),
  markStocktakeItemError: vi.fn(),
  markHandoverOperationSynced: vi.fn(),
  saveCachedBranchStatus: vi.fn(),
  saveCachedCashDesk: vi.fn(),
  saveCachedWorker: vi.fn(),
}));

import { SyncEngine } from '../sync-engine';
import {
  getPendingShipmentReceipts,
  markShipmentReceiptRetryError,
  markShipmentReceiptSynced,
  markShipmentReceiptTerminalError,
} from '../sqlite';

const mockedPending = vi.mocked(getPendingShipmentReceipts);
const mockedSynced = vi.mocked(markShipmentReceiptSynced);
const mockedTerminal = vi.mocked(markShipmentReceiptTerminalError);
const mockedRetry = vi.mocked(markShipmentReceiptRetryError);

type PendingReceipt = ReturnType<typeof getPendingShipmentReceipts>[number];

function row(overrides: Partial<PendingReceipt> = {}): PendingReceipt {
  return {
    id: 11,
    shipment_id: '11111111-1111-4111-8111-111111111111',
    request_number: 'FF-000011',
    idempotency_key: 'shipment-receipt-key-11',
    branch_id: '22222222-2222-4222-8222-222222222222',
    worker_id: 42,
    company_code: 'BEST_CHANGE',
    created_at: '2026-07-18 09:00:00',
    synced: 0,
    sync_attempts: 0,
    sync_error: null,
    ...overrides,
  };
}

function response(status: number, body: unknown = {}, statusText = ''): Response {
  const serialized = body === undefined ? '' : JSON.stringify(body);
  return {
    ok: status >= 200 && status < 300,
    status,
    statusText: statusText || (status === 409 ? 'Conflict' : 'OK'),
    json: vi.fn(async () => {
      if (!serialized) throw new SyntaxError('Unexpected end of JSON input');
      return JSON.parse(serialized) as unknown;
    }),
    text: vi.fn(async () => serialized),
  } as unknown as Response;
}

describe('SyncEngine — offline Shipment-átvételi outbox', () => {
  let engine: SyncEngine;

  beforeEach(() => {
    vi.clearAllMocks();
    mockedPending.mockReturnValue([row()]);
    engine = new SyncEngine();
  });

  afterEach(() => vi.unstubAllGlobals());

  it('2xx után nyugtáz, és a perzisztált idempotenciakulcsot küldi', async () => {
    const fetchMock = vi.fn().mockResolvedValue(response(200, { status: 'DELIVERED' }));
    vi.stubGlobal('fetch', fetchMock);

    const result = await engine.syncShipmentReceipts();

    expect(fetchMock).toHaveBeenCalledWith(
      'https://backend.test/api/v1/shipments/11111111-1111-4111-8111-111111111111/deliver',
      expect.objectContaining({
        method: 'POST',
        headers: expect.objectContaining({
          Authorization: 'Bearer token-abc',
          'Idempotency-Key': 'shipment-receipt-key-11',
          'X-Company-Code': 'BEST_CHANGE',
        }),
      }),
    );
    expect(mockedSynced).toHaveBeenCalledWith(11);
    expect(result).toEqual({ synced: 1, failed: 0, errors: [] });
  });

  it('üres 204 sikeres válasz után is nyugtáz', async () => {
    const emptyResponse = response(204);
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(emptyResponse));

    const result = await engine.syncShipmentReceipts();

    expect(mockedSynced).toHaveBeenCalledWith(11);
    expect(result).toEqual({ synced: 1, failed: 0, errors: [] });
  });

  it('üres 200 sikeres válasz után is nyugtáz', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(response(200, undefined)));

    const result = await engine.syncShipmentReceipts();

    expect(mockedSynced).toHaveBeenCalledWith(11);
    expect(result).toEqual({ synced: 1, failed: 0, errors: [] });
  });

  it('hibás nem üres JSON-választ nem nyugtáz csendben', async () => {
    const malformed = response(200);
    vi.mocked(malformed.text).mockResolvedValue('{');
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(malformed));

    const result = await engine.syncShipmentReceipts();

    expect(mockedSynced).not.toHaveBeenCalled();
    expect(mockedRetry).toHaveBeenCalledWith(11, expect.stringContaining('JSON'));
    expect(result.failed).toBe(1);
  });

  it('409 után GET-tel bizonyított DELIVERED állapotot nyugtáz', async () => {
    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce(response(409))
      .mockResolvedValueOnce(response(200, { status: 'DELIVERED' }));
    vi.stubGlobal('fetch', fetchMock);

    const result = await engine.syncShipmentReceipts();

    expect(fetchMock).toHaveBeenNthCalledWith(
      2,
      'https://backend.test/api/v1/shipments/11111111-1111-4111-8111-111111111111',
      expect.objectContaining({ method: 'GET' }),
    );
    expect(mockedSynced).toHaveBeenCalledWith(11);
    expect(result.synced).toBe(1);
  });

  it('409 után nem nyugtáz, ha a GET még SUBMITTED állapotot mutat', async () => {
    vi.stubGlobal(
      'fetch',
      vi
        .fn()
        .mockResolvedValueOnce(response(409))
        .mockResolvedValueOnce(response(200, { status: 'SUBMITTED' })),
    );

    const result = await engine.syncShipmentReceipts();

    expect(mockedSynced).not.toHaveBeenCalled();
    expect(mockedTerminal).not.toHaveBeenCalled();
    expect(mockedRetry).toHaveBeenCalledWith(11, expect.stringContaining('SUBMITTED'));
    expect(result.failed).toBe(1);
  });

  it('409 után CANCELLED állapotot látható terminális hibaként zár le, nem sikernek', async () => {
    vi.stubGlobal(
      'fetch',
      vi
        .fn()
        .mockResolvedValueOnce(response(409))
        .mockResolvedValueOnce(response(200, { status: 'CANCELLED' })),
    );

    const result = await engine.syncShipmentReceipts();

    expect(mockedSynced).not.toHaveBeenCalled();
    expect(mockedTerminal).toHaveBeenCalledWith(11, expect.stringContaining('sztornózta'));
    expect(result).toMatchObject({ synced: 0, failed: 1 });
  });

  it('hálózati hibánál retry-zható marad, és nem generál új kulcsot', async () => {
    const fetchMock = vi.fn().mockRejectedValue(new TypeError('network down'));
    vi.stubGlobal('fetch', fetchMock);

    const first = await engine.syncShipmentReceipts();
    const second = await engine.syncShipmentReceipts();

    expect(mockedSynced).not.toHaveBeenCalled();
    expect(mockedRetry).toHaveBeenCalledTimes(2);
    expect(first.failed).toBe(1);
    expect(second.failed).toBe(1);
    for (const [, options] of fetchMock.mock.calls) {
      expect((options as RequestInit).headers).toMatchObject({
        'Idempotency-Key': 'shipment-receipt-key-11',
      });
    }
  });

  it('HTTP 408 timeout retry-zható marad és nem lesz terminális hiba', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(response(408, {}, 'Request Timeout')));

    const result = await engine.syncShipmentReceipts();

    expect(mockedSynced).not.toHaveBeenCalled();
    expect(mockedTerminal).not.toHaveBeenCalled();
    expect(mockedRetry).toHaveBeenCalledWith(11, expect.stringContaining('HTTP 408'));
    expect(result.failed).toBe(1);
  });

  it('átfedő manuális és periodikus hívás ugyanazt a sort csak egyszer POST-olja', async () => {
    const fetchMock = vi.fn().mockResolvedValue(response(200, { status: 'DELIVERED' }));
    vi.stubGlobal('fetch', fetchMock);

    const [first, second] = await Promise.all([
      engine.syncShipmentReceipts(),
      engine.syncShipmentReceipts(),
    ]);

    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(first).toEqual(second);
    expect(mockedSynced).toHaveBeenCalledTimes(1);
  });

  it('a nyilvános syncAll eredményébe beolvasztja a Shipment-átvételi queue eredményét', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(response(200, { status: 'DELIVERED' })));

    const result = await engine.syncAll();

    expect(result).toEqual({ synced: 1, failed: 0, errors: [] });
    expect(mockedSynced).toHaveBeenCalledWith(11);
  });

  it('másik cég sora nem küldhető fel', async () => {
    mockedPending.mockReturnValue([row({ company_code: 'OTHER_COMPANY' })]);
    const fetchMock = vi.fn();
    vi.stubGlobal('fetch', fetchMock);

    const result = await engine.syncShipmentReceipts();

    expect(fetchMock).not.toHaveBeenCalled();
    expect(mockedRetry).toHaveBeenCalledWith(11, expect.stringContaining('Cégeltérés'));
    expect(result.failed).toBe(1);
  });
});
