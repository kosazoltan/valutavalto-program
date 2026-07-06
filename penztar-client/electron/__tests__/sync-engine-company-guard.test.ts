import { beforeEach, afterEach, describe, expect, it, vi } from 'vitest';

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
  getPendingCircularReplies: vi.fn(() => []),
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
  markCircularReplySynced: vi.fn(),
  markCollectionSynced: vi.fn(),
  markStocktakeItemSynced: vi.fn(),
  markStocktakeItemError: vi.fn(),
  markHandoverOperationSynced: vi.fn(),
  saveCachedBranchStatus: vi.fn(),
  saveCachedCashDesk: vi.fn(),
  saveCachedWorker: vi.fn(),
}));

import { companyMismatch, SyncEngine } from '../sync-engine';
import {
  getConfig,
  getPendingTransactions,
  getPendingConversions,
  getPendingTransfers,
  markTransactionSynced,
  markTransactionSyncError,
  markConversionSynced,
  markTransferSynced,
} from '../sqlite';

const mockedGetConfig = vi.mocked(getConfig);
const mockedGetPendingTransactions = vi.mocked(getPendingTransactions);
const mockedGetPendingConversions = vi.mocked(getPendingConversions);
const mockedGetPendingTransfers = vi.mocked(getPendingTransfers);
const mockedMarkTransactionSynced = vi.mocked(markTransactionSynced);
const mockedMarkTransactionSyncError = vi.mocked(markTransactionSyncError);
const mockedMarkConversionSynced = vi.mocked(markConversionSynced);
const mockedMarkTransferSynced = vi.mocked(markTransferSynced);

type PendingTx = ReturnType<typeof getPendingTransactions>[number];
type PendingConversion = ReturnType<typeof getPendingConversions>[number];
type PendingTransfer = ReturnType<typeof getPendingTransfers>[number];

function makeTx(companyCode: string | null, overrides: Partial<PendingTx> = {}): PendingTx {
  return {
    id: 1,
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
    approver_worker_id: null,
    approval_session_id: null,
    foreign_status: null,
    customer_birth_place: null,
    customer_birth_date: null,
    customer_mother_name: null,
    customer_nationality: null,
    customer_document_type: null,
    customer_on_own_behalf: null,
    customer_actor_name: null,
    customer_pep_kind: null,
    customer_actor_birth_place: null,
    customer_actor_birth_date: null,
    customer_actor_mother_name: null,
    customer_actor_nationality: null,
    customer_actor_document_type: null,
    customer_actor_document_number: null,
    customer_actor_address: null,
    lines: null,
    local_reference_number: 'TX-1',
    idempotency_key: 'tx-key-1',
    company_code: companyCode,
    created_at: '2026-07-04 10:00:00',
    synced: 0,
    ...overrides,
  };
}

function makeConversion(
  companyCode: string | null,
  overrides: Partial<PendingConversion> = {},
): PendingConversion {
  return {
    id: 2,
    from_currency_id: 1,
    from_currency_code: 'EUR',
    to_currency_id: 2,
    to_currency_code: 'USD',
    from_amount: 100,
    calculated_huf_amount: 40000,
    calculated_to_amount: 110,
    conversion_rate: 1.1,
    handling_fee: null,
    customer_id: null,
    customer_name: null,
    customer_document_number: null,
    customer_address: null,
    customer_nationality: null,
    customer_birth_place: null,
    customer_birth_date: null,
    customer_mother_name: null,
    customer_document_type: null,
    source_of_funds: null,
    customer_is_pep: null,
    approver_worker_id: null,
    approval_session_id: null,
    customer_on_own_behalf: null,
    customer_actor_name: null,
    customer_pep_kind: null,
    customer_actor_birth_place: null,
    customer_actor_birth_date: null,
    customer_actor_mother_name: null,
    customer_actor_nationality: null,
    customer_actor_document_type: null,
    customer_actor_document_number: null,
    customer_actor_address: null,
    foreign_status: null,
    note: null,
    local_reference_number: 'CONV-2',
    idempotency_key: 'conv-key-2',
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
    id: 3,
    target_branch_id: null,
    target_branch_code: '106',
    currency_id: 1,
    currency_code: 'EUR',
    amount: 100,
    huf_value: 40000,
    transfer_type: 'OUT',
    denominations: null,
    note: null,
    carrier_name: 'Futar',
    seal_number: 'SEAL-1',
    direction: null,
    lines: null,
    local_reference_number: 'TR-3',
    idempotency_key: 'transfer-key-3',
    company_code: companyCode,
    created_at: '2026-07-04 10:00:00',
    synced: 0,
    ...overrides,
  };
}

function successfulFetch(): ReturnType<typeof vi.fn> {
  return vi.fn().mockResolvedValue({ ok: true, json: () => Promise.resolve({ success: true }) });
}

describe('companyMismatch', () => {
  it.each([
    [null, null, false],
    ['BC', 'BC', false],
    ['BC', 'PV', true],
    [' BC ', 'BC', false],
    [null, 'BC', false],
    ['BC', null, false],
    ['', 'PV', false],
  ] as const)('row=%s session=%s -> %s', (row, session, expected) => {
    expect(companyMismatch(row, session)).toBe(expected);
  });
});

describe('SyncEngine company_code guard', () => {
  let engine: SyncEngine;

  beforeEach(() => {
    vi.clearAllMocks();
    engine = new SyncEngine();
    mockedGetPendingTransactions.mockReturnValue([]);
    mockedGetPendingConversions.mockReturnValue([]);
    mockedGetPendingTransfers.mockReturnValue([]);
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

  it('withholds a transaction from a different company and continues with later queues', async () => {
    mockedGetPendingTransactions.mockReturnValue([makeTx('PV')]);
    mockedGetPendingConversions.mockReturnValue([makeConversion('BC')]);
    const fetchMock = successfulFetch();
    vi.stubGlobal('fetch', fetchMock);

    const result = await engine.syncAll('test-token');

    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(String(fetchMock.mock.calls[0]?.[0])).toBe(
      'http://localhost:8080/api/v1/transactions/conversion',
    );
    expect(mockedMarkTransactionSynced).not.toHaveBeenCalled();
    expect(mockedMarkTransactionSyncError).toHaveBeenCalledWith(
      1,
      expect.stringContaining('PV'),
      expect.any(String),
    );
    expect(mockedMarkTransactionSyncError).toHaveBeenCalledWith(
      1,
      expect.stringContaining('BC'),
      expect.any(String),
    );
    expect(result.failed).toBe(1);
    expect(result.synced).toBe(1);
    expect(result.errors.some((error) => error.includes('PV') && error.includes('BC'))).toBe(true);
  });

  it('syncs a transaction when row and session company codes match', async () => {
    mockedGetPendingTransactions.mockReturnValue([makeTx('BC')]);
    const fetchMock = successfulFetch();
    vi.stubGlobal('fetch', fetchMock);

    const result = await engine.syncAll('test-token');

    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(String(fetchMock.mock.calls[0]?.[0])).toBe(
      'http://localhost:8080/api/v1/transactions/sell',
    );
    expect(mockedMarkTransactionSynced).toHaveBeenCalledWith(1);
    expect(result.synced).toBe(1);
    expect(result.failed).toBe(0);
  });

  it('syncs a legacy transaction when row company code is NULL', async () => {
    mockedGetPendingTransactions.mockReturnValue([makeTx(null)]);
    const fetchMock = successfulFetch();
    vi.stubGlobal('fetch', fetchMock);

    const result = await engine.syncAll('test-token');

    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(mockedMarkTransactionSynced).toHaveBeenCalledWith(1);
    expect(result.synced).toBe(1);
    expect(result.failed).toBe(0);
  });

  it('withholds a conversion from a different company without an HTTP call', async () => {
    mockedGetPendingConversions.mockReturnValue([makeConversion('PV')]);
    const fetchMock = successfulFetch();
    vi.stubGlobal('fetch', fetchMock);

    const result = await engine.syncAll('test-token');

    expect(fetchMock).not.toHaveBeenCalled();
    expect(mockedMarkConversionSynced).not.toHaveBeenCalled();
    expect(result.failed).toBe(1);
    expect(result.errors.some((error) => error.includes('PV') && error.includes('BC'))).toBe(true);
  });

  it('withholds a transfer from a different company without an HTTP call', async () => {
    mockedGetPendingTransfers.mockReturnValue([makeTransfer('PV')]);
    const fetchMock = successfulFetch();
    vi.stubGlobal('fetch', fetchMock);

    const result = await engine.syncAll('test-token');

    expect(fetchMock).not.toHaveBeenCalled();
    expect(mockedMarkTransferSynced).not.toHaveBeenCalled();
    expect(result.failed).toBe(1);
    expect(result.errors.some((error) => error.includes('PV') && error.includes('BC'))).toBe(true);
  });
});
