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
  getPendingCollections: vi.fn(() => []),
  getPendingStocktakeItems: vi.fn(() => []),
  getPendingHandoverOperations: vi.fn(() => []),
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
  getConfig,
  getPendingBankTransactions,
  getPendingCollections,
  getPendingDistributions,
  getPendingHandoverOperations,
  getPendingStornos,
  getPendingStocktakeItems,
  getPendingTransferStornos,
  getPendingTransfers,
  markBankTransactionSynced,
  markCollectionSynced,
  markDistributionSynced,
  markHandoverOperationSynced,
  markStocktakeItemError,
  markStocktakeItemSynced,
  markStornoSynced,
  markTransferStornoSynced,
  markTransferSynced,
} from '../sqlite';

const mockedGetConfig = vi.mocked(getConfig);
const mockedGetPendingBankTransactions = vi.mocked(getPendingBankTransactions);
const mockedGetPendingStornos = vi.mocked(getPendingStornos);
const mockedGetPendingDistributions = vi.mocked(getPendingDistributions);
const mockedGetPendingCollections = vi.mocked(getPendingCollections);
const mockedGetPendingHandoverOperations = vi.mocked(getPendingHandoverOperations);
const mockedGetPendingTransfers = vi.mocked(getPendingTransfers);
const mockedGetPendingTransferStornos = vi.mocked(getPendingTransferStornos);
const mockedGetPendingStocktakeItems = vi.mocked(getPendingStocktakeItems);
const mockedMarkBankTransactionSynced = vi.mocked(markBankTransactionSynced);
const mockedMarkStornoSynced = vi.mocked(markStornoSynced);
const mockedMarkDistributionSynced = vi.mocked(markDistributionSynced);
const mockedMarkCollectionSynced = vi.mocked(markCollectionSynced);
const mockedMarkHandoverOperationSynced = vi.mocked(markHandoverOperationSynced);
const mockedMarkTransferSynced = vi.mocked(markTransferSynced);
const mockedMarkTransferStornoSynced = vi.mocked(markTransferStornoSynced);
const mockedMarkStocktakeItemSynced = vi.mocked(markStocktakeItemSynced);
const mockedMarkStocktakeItemError = vi.mocked(markStocktakeItemError);

type PendingBankTx = ReturnType<typeof getPendingBankTransactions>[number];
type PendingStorno = ReturnType<typeof getPendingStornos>[number];
type PendingDistribution = ReturnType<typeof getPendingDistributions>[number];
type PendingCollection = ReturnType<typeof getPendingCollections>[number];
type PendingHandover = ReturnType<typeof getPendingHandoverOperations>[number];
type PendingTransfer = ReturnType<typeof getPendingTransfers>[number];
type PendingTransferStorno = ReturnType<typeof getPendingTransferStornos>[number];
type PendingStocktakeItem = ReturnType<typeof getPendingStocktakeItems>[number];

function makeBankTx(
  companyCode: string | null,
  overrides: Partial<PendingBankTx> = {},
): PendingBankTx {
  return {
    id: 1,
    transaction_type: 'BUY',
    currency_code: 'EUR',
    amount: 100,
    exchange_rate: 395.5,
    huf_amount: 39550,
    vault_territory_id: null,
    bank_name: null,
    bank_reference: null,
    note: null,
    local_reference_number: 'BANK-1',
    idempotency_key: 'bank-key-1',
    company_code: companyCode,
    created_at: '2026-07-04 10:00:00',
    synced: 0,
    ...overrides,
  };
}

function makeStorno(
  companyCode: string | null,
  overrides: Partial<PendingStorno> = {},
): PendingStorno {
  return {
    id: 2,
    transaction_id: 1,
    original_receipt_number: 'R-1',
    original_transaction_type: 'BUY',
    currency_code: 'EUR',
    foreign_amount: 100,
    huf_amount: 39550,
    exchange_rate: 395.5,
    reason: 'teszt',
    approval_id: null,
    custom_exchange_rate: null,
    payment_method: null,
    customer_name: null,
    customer_document_number: null,
    local_reference_number: 'ST-2',
    idempotency_key: 'storno-key-2',
    company_code: companyCode,
    created_at: '2026-07-04 10:00:00',
    synced: 0,
    ...overrides,
  };
}

function makeDistribution(
  companyCode: string | null,
  overrides: Partial<PendingDistribution> = {},
): PendingDistribution {
  return {
    id: 3,
    target_branch_code: '105',
    currency_code: 'EUR',
    amount: 100,
    denominations: null,
    note: null,
    local_reference_number: 'DIST-3',
    idempotency_key: 'dist-key-3',
    company_code: companyCode,
    created_at: '2026-07-04 10:00:00',
    synced: 0,
    ...overrides,
  };
}

function makeCollection(
  companyCode: string | null,
  overrides: Partial<PendingCollection> = {},
): PendingCollection {
  return {
    id: 4,
    source_branch_code: '105',
    currency_code: 'EUR',
    amount: 100,
    note: null,
    local_reference_number: 'COL-4',
    idempotency_key: 'collection-key-4',
    company_code: companyCode,
    created_at: '2026-07-04 10:00:00',
    synced: 0,
    ...overrides,
  };
}

function makeHandover(
  companyCode: string | null,
  overrides: Partial<PendingHandover> = {},
): PendingHandover {
  return {
    id: 5,
    operation_type: 'GENERATE',
    sheet_id: null,
    from_cash_desk_id: null,
    to_cash_desk_id: null,
    transfer_date: null,
    amounts_json: null,
    note: null,
    local_reference_number: 'HND-5',
    idempotency_key: 'handover-key-5',
    company_code: companyCode,
    created_at: '2026-07-04 10:00:00',
    synced: 0,
    ...overrides,
  };
}

function makeTransfer(
  companyCode: string | null,
  overrides: Partial<PendingTransfer> = {},
): PendingTransfer {
  return {
    id: 6,
    target_branch_id: null,
    target_branch_code: '106',
    currency_id: 1,
    currency_code: 'EUR',
    amount: 100,
    huf_value: 39550,
    transfer_type: 'OUT',
    denominations: null,
    note: null,
    carrier_name: 'Futár',
    seal_number: 'SEAL-1',
    direction: null,
    lines: null,
    local_reference_number: 'TR-6',
    idempotency_key: 'transfer-key-6',
    company_code: companyCode,
    created_at: '2026-07-04 10:00:00',
    synced: 0,
    ...overrides,
  };
}

function makeTransferStorno(
  companyCode: string | null,
  overrides: Partial<PendingTransferStorno> = {},
): PendingTransferStorno {
  return {
    id: 7,
    transfer_id: 6,
    transfer_number: 'TR-6',
    reason: 'teszt',
    local_reference_number: 'TST-7',
    idempotency_key: 'transfer-storno-key-7',
    company_code: companyCode,
    created_at: '2026-07-04 10:00:00',
    synced: 0,
    ...overrides,
  };
}

function makeStocktakeItem(
  companyCode: string | null,
  overrides: Partial<PendingStocktakeItem> = {},
): PendingStocktakeItem {
  return {
    id: 8,
    item_id: 'item-uuid-1',
    actual_quantity: 5,
    note: null,
    idempotency_key: 'stocktake-key-8',
    company_code: companyCode,
    created_at: '2026-07-04 10:00:00',
    synced: 0,
    sync_error: null,
    retry_count: 0,
    ...overrides,
  };
}

function successfulFetch(): ReturnType<typeof vi.fn> {
  return vi.fn().mockResolvedValue({ ok: true, json: () => Promise.resolve({ success: true }) });
}

describe('SyncEngine company_code guard slice 2 - performSyncAll queues', () => {
  let engine: SyncEngine;

  beforeEach(() => {
    vi.clearAllMocks();
    engine = new SyncEngine();
    mockedGetPendingBankTransactions.mockReturnValue([]);
    mockedGetPendingStornos.mockReturnValue([]);
    mockedGetPendingDistributions.mockReturnValue([]);
    mockedGetPendingCollections.mockReturnValue([]);
    mockedGetPendingHandoverOperations.mockReturnValue([]);
    mockedGetPendingTransfers.mockReturnValue([]);
    mockedGetPendingTransferStornos.mockReturnValue([]);
    mockedGetPendingStocktakeItems.mockReturnValue([]);
    mockedGetConfig.mockImplementation((key: string) => {
      if (key === 'server_url') return 'http://localhost:8080/api/v1';
      if (key === 'auth_token') return 'test-token';
      if (key === 'bootstrap_company_code') return 'BC';
      return null;
    });
  });

  afterEach(() => {
    engine.stop();
    vi.unstubAllGlobals();
  });

  it('withholds a bank transaction from a different company without an HTTP call', async () => {
    mockedGetPendingBankTransactions.mockReturnValue([makeBankTx('PV')]);
    const fetchMock = successfulFetch();
    vi.stubGlobal('fetch', fetchMock);

    const result = await engine.syncAll('test-token');

    expect(fetchMock).not.toHaveBeenCalled();
    expect(mockedMarkBankTransactionSynced).not.toHaveBeenCalled();
    expect(result.failed).toBe(1);
    expect(result.errors.some((error) => error.includes('PV') && error.includes('BC'))).toBe(true);
  });

  it('withholds a storno from a different company without an HTTP call', async () => {
    mockedGetPendingStornos.mockReturnValue([makeStorno('PV')]);
    const fetchMock = successfulFetch();
    vi.stubGlobal('fetch', fetchMock);

    const result = await engine.syncAll('test-token');

    expect(fetchMock).not.toHaveBeenCalled();
    expect(mockedMarkStornoSynced).not.toHaveBeenCalled();
    expect(result.failed).toBe(1);
    expect(result.errors.some((error) => error.includes('PV') && error.includes('BC'))).toBe(true);
  });

  it('withholds a distribution from a different company without an HTTP call', async () => {
    mockedGetPendingDistributions.mockReturnValue([makeDistribution('PV')]);
    const fetchMock = successfulFetch();
    vi.stubGlobal('fetch', fetchMock);

    const result = await engine.syncAll('test-token');

    expect(fetchMock).not.toHaveBeenCalled();
    expect(mockedMarkDistributionSynced).not.toHaveBeenCalled();
    expect(result.failed).toBe(1);
    expect(result.errors.some((error) => error.includes('PV') && error.includes('BC'))).toBe(true);
  });

  it('withholds a collection from a different company without an HTTP call', async () => {
    mockedGetPendingCollections.mockReturnValue([makeCollection('PV')]);
    const fetchMock = successfulFetch();
    vi.stubGlobal('fetch', fetchMock);

    const result = await engine.syncAll('test-token');

    expect(fetchMock).not.toHaveBeenCalled();
    expect(mockedMarkCollectionSynced).not.toHaveBeenCalled();
    expect(result.failed).toBe(1);
    expect(result.errors.some((error) => error.includes('PV') && error.includes('BC'))).toBe(true);
  });

  it('withholds a handover operation from a different company without an HTTP call', async () => {
    mockedGetPendingHandoverOperations.mockReturnValue([makeHandover('PV')]);
    const fetchMock = successfulFetch();
    vi.stubGlobal('fetch', fetchMock);

    const result = await engine.syncAll('test-token');

    expect(fetchMock).not.toHaveBeenCalled();
    expect(mockedMarkHandoverOperationSynced).not.toHaveBeenCalled();
    expect(result.failed).toBe(1);
    expect(result.errors.some((error) => error.includes('PV') && error.includes('BC'))).toBe(true);
  });

  it('syncs bank transactions when company codes match or the row is legacy NULL', async () => {
    mockedGetPendingBankTransactions.mockReturnValue([
      makeBankTx('BC', { id: 10, idempotency_key: 'bank-key-10' }),
      makeBankTx(null, { id: 11, idempotency_key: 'bank-key-11' }),
    ]);
    const fetchMock = successfulFetch();
    vi.stubGlobal('fetch', fetchMock);

    const result = await engine.syncAll('test-token');

    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(mockedMarkBankTransactionSynced).toHaveBeenCalledWith(10);
    expect(mockedMarkBankTransactionSynced).toHaveBeenCalledWith(11);
    expect(result.synced).toBe(2);
    expect(result.failed).toBe(0);
  });

  it('continues after a mismatched storno and syncs a later handover operation', async () => {
    mockedGetPendingStornos.mockReturnValue([makeStorno('PV', { id: 20 })]);
    mockedGetPendingHandoverOperations.mockReturnValue([makeHandover('BC', { id: 21 })]);
    const fetchMock = successfulFetch();
    vi.stubGlobal('fetch', fetchMock);

    const result = await engine.syncAll('test-token');

    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(mockedMarkStornoSynced).not.toHaveBeenCalled();
    expect(mockedMarkHandoverOperationSynced).toHaveBeenCalledWith(21);
    expect(result.synced).toBe(1);
    expect(result.failed).toBe(1);
  });
});

describe('SyncEngine company_code guard slice 2 - standalone queues', () => {
  let engine: SyncEngine;

  beforeEach(() => {
    vi.clearAllMocks();
    engine = new SyncEngine();
    mockedGetPendingBankTransactions.mockReturnValue([]);
    mockedGetPendingStornos.mockReturnValue([]);
    mockedGetPendingDistributions.mockReturnValue([]);
    mockedGetPendingCollections.mockReturnValue([]);
    mockedGetPendingHandoverOperations.mockReturnValue([]);
    mockedGetPendingTransfers.mockReturnValue([]);
    mockedGetPendingTransferStornos.mockReturnValue([]);
    mockedGetPendingStocktakeItems.mockReturnValue([]);
    mockedGetConfig.mockImplementation((key: string) => {
      if (key === 'server_url') return 'http://localhost:8080/api/v1';
      if (key === 'auth_token') return 'test-token';
      if (key === 'bootstrap_company_code') return 'BC';
      return null;
    });
  });

  afterEach(() => {
    engine.stop();
    vi.unstubAllGlobals();
  });

  it('withholds standalone transfers from a different company without posting them', async () => {
    mockedGetPendingTransfers.mockReturnValue([makeTransfer('PV')]);
    const fetchMock = successfulFetch();
    vi.stubGlobal('fetch', fetchMock);

    await engine.syncTransfers();

    expect(fetchMock).not.toHaveBeenCalled();
    expect(mockedMarkTransferSynced).not.toHaveBeenCalled();
  });

  it('withholds standalone transfer-stornos from a different company without marking them synced', async () => {
    mockedGetPendingTransferStornos.mockReturnValue([makeTransferStorno('PV')]);
    const fetchMock = successfulFetch();
    vi.stubGlobal('fetch', fetchMock);

    await engine.syncTransferStornos();

    expect(fetchMock).not.toHaveBeenCalled();
    expect(mockedMarkTransferStornoSynced).not.toHaveBeenCalled();
  });

  it('withholds standalone stocktake items from a different company and records a persistent item error', async () => {
    mockedGetPendingStocktakeItems.mockReturnValue([makeStocktakeItem('PV')]);
    const fetchMock = successfulFetch();
    vi.stubGlobal('fetch', fetchMock);

    await engine.syncStocktakeItems();

    expect(fetchMock).not.toHaveBeenCalled();
    expect(mockedMarkStocktakeItemSynced).not.toHaveBeenCalled();
    expect(mockedMarkStocktakeItemError).toHaveBeenCalledWith(8, expect.stringContaining('PV'));
    expect(mockedMarkStocktakeItemError).toHaveBeenCalledWith(8, expect.stringContaining('BC'));
  });

  it('withholds standalone distributions from a different company without posting them', async () => {
    mockedGetPendingDistributions.mockReturnValue([makeDistribution('PV')]);
    const fetchMock = successfulFetch();
    vi.stubGlobal('fetch', fetchMock);

    await engine.syncDistributions();

    expect(fetchMock).not.toHaveBeenCalled();
    expect(mockedMarkDistributionSynced).not.toHaveBeenCalled();
  });

  it('withholds standalone collections from a different company without posting them', async () => {
    mockedGetPendingCollections.mockReturnValue([makeCollection('PV')]);
    const fetchMock = successfulFetch();
    vi.stubGlobal('fetch', fetchMock);

    await engine.syncCollections();

    expect(fetchMock).not.toHaveBeenCalled();
    expect(mockedMarkCollectionSynced).not.toHaveBeenCalled();
  });

  it('continues after a mismatched transfer-storno and syncs a later matching transfer-storno', async () => {
    mockedGetPendingTransferStornos.mockReturnValue([
      makeTransferStorno('PV', {
        id: 30,
        transfer_id: 30,
        idempotency_key: 'transfer-storno-key-30',
      }),
      makeTransferStorno('BC', {
        id: 31,
        transfer_id: 31,
        idempotency_key: 'transfer-storno-key-31',
      }),
    ]);
    const fetchMock = successfulFetch();
    vi.stubGlobal('fetch', fetchMock);

    await engine.syncTransferStornos();

    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(String(fetchMock.mock.calls[0]?.[0])).toBe(
      'http://localhost:8080/api/v1/transfers/31/storno',
    );
    expect(mockedMarkTransferStornoSynced).toHaveBeenCalledTimes(1);
    expect(mockedMarkTransferStornoSynced).toHaveBeenCalledWith(31);
  });

  it('syncs legacy NULL stocktake rows', async () => {
    mockedGetPendingStocktakeItems.mockReturnValue([makeStocktakeItem(null)]);
    const fetchMock = successfulFetch();
    vi.stubGlobal('fetch', fetchMock);

    await engine.syncStocktakeItems();

    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(mockedMarkStocktakeItemSynced).toHaveBeenCalledWith(8);
    expect(mockedMarkStocktakeItemError).not.toHaveBeenCalled();
  });
});
