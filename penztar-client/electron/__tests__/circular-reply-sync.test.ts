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

vi.mock('../printer', () => ({
  printReceipt: vi.fn(),
}));

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
import { getConfig, getPendingCircularReplies, markCircularReplySynced } from '../sqlite';

const mockedGetConfig = vi.mocked(getConfig);
const mockedGetPendingCircularReplies = vi.mocked(getPendingCircularReplies);
const mockedMarkCircularReplySynced = vi.mocked(markCircularReplySynced);

type PendingCircularReply = ReturnType<typeof getPendingCircularReplies>[number];

function jsonResponse(body: unknown, ok = true, status = 200, statusText = 'OK'): Response {
  return {
    ok,
    status,
    statusText,
    json: vi.fn(async () => body),
  } as unknown as Response;
}

function makeReply(overrides: Partial<PendingCircularReply> = {}): PendingCircularReply {
  return {
    id: 7,
    circular_id: 42,
    reply_text: 'Intézkedtem',
    idempotency_key: 'reply-key-7',
    company_code: 'BEST_CHANGE',
    created_at: '2026-07-06 09:00:00',
    synced: 0,
    ...overrides,
  };
}

describe('SyncEngine — circular reply outbox sync', () => {
  let engine: SyncEngine;

  beforeEach(() => {
    vi.clearAllMocks();
    mockedGetConfig.mockImplementation((key: string) => {
      if (key === 'server_url') return 'https://backend.test/api/v1';
      if (key === 'auth_token') return 'token-abc';
      if (key === 'bootstrap_company_code') return 'BEST_CHANGE';
      return null;
    });
    engine = new SyncEngine();
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('pending reply sort a megfelelő reply endpointtal, bodyval és sor-idempotency kulccsal küldi fel', async () => {
    mockedGetPendingCircularReplies.mockReturnValue([makeReply()]);
    const fetchMock = vi.fn().mockResolvedValue(jsonResponse({ id: 123 }));
    vi.stubGlobal('fetch', fetchMock);

    await engine.syncCircularReplies();

    expect(fetchMock).toHaveBeenCalledWith(
      'https://backend.test/api/v1/circulars/42/reply',
      expect.objectContaining({
        method: 'POST',
        headers: expect.objectContaining({
          Authorization: 'Bearer token-abc',
          'Idempotency-Key': 'reply-key-7',
          'X-Company-Code': 'BEST_CHANGE',
        }),
        body: JSON.stringify({ replyText: 'Intézkedtem' }),
      }),
    );
    expect(mockedMarkCircularReplySynced).toHaveBeenCalledWith(7);
  });

  it('hálózati hiba esetén nem markolja syncedre a sort, hogy a következő ciklus újrapróbálja', async () => {
    mockedGetPendingCircularReplies.mockReturnValue([makeReply()]);
    const fetchMock = vi.fn().mockRejectedValue(new TypeError('network down'));
    vi.stubGlobal('fetch', fetchMock);

    await engine.syncCircularReplies();

    expect(fetchMock).toHaveBeenCalledOnce();
    expect(mockedMarkCircularReplySynced).not.toHaveBeenCalled();
  });

  it('HTTP 409 esetén syncedre markol, mert az idempotens replay kívánt végállapota már fennáll', async () => {
    mockedGetPendingCircularReplies.mockReturnValue([makeReply()]);
    const fetchMock = vi.fn().mockResolvedValue(jsonResponse({}, false, 409, 'Conflict'));
    vi.stubGlobal('fetch', fetchMock);

    await engine.syncCircularReplies();

    expect(fetchMock).toHaveBeenCalledOnce();
    expect(mockedMarkCircularReplySynced).toHaveBeenCalledWith(7);
  });

  it('eltérő company_code esetén nem küldi fel másik cég válaszát', async () => {
    mockedGetPendingCircularReplies.mockReturnValue([makeReply({ company_code: 'MASIK' })]);
    const fetchMock = vi.fn().mockResolvedValue(jsonResponse({ id: 123 }));
    vi.stubGlobal('fetch', fetchMock);

    await engine.syncCircularReplies();

    expect(fetchMock).not.toHaveBeenCalled();
    expect(mockedMarkCircularReplySynced).not.toHaveBeenCalled();
  });
});
