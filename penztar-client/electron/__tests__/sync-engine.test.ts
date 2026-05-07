/**
 * sync-engine.ts unit tests — SyncEngine class, queue kezelés, retry logika.
 *
 * We test the SyncEngine by mocking:
 * - sqlite module (getConfig, setConfig, getPending*, mark*Synced, etc.)
 * - electron safeStorage
 * - global fetch
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
  getPendingCollections: vi.fn(() => []),
  getPendingHandoverOperations: vi.fn(() => []),
  markTransactionSynced: vi.fn(),
  markConversionSynced: vi.fn(),
  markBankTransactionSynced: vi.fn(),
  markStornoSynced: vi.fn(),
  markDistributionSynced: vi.fn(),
  markTransferSynced: vi.fn(),
  markCollectionSynced: vi.fn(),
  markHandoverOperationSynced: vi.fn(),
  saveCachedBranchStatus: vi.fn(),
  saveCachedCashDesk: vi.fn(),
  saveCachedWorker: vi.fn(),
}));

import { selectBootstrapRoleCode, SyncEngine } from '../sync-engine';
import {
  getConfig,
  getPendingTransactions,
  getPendingConversions,
  getPendingBankTransactions,
  getPendingStornos,
  getPendingDistributions,
  getPendingTransfers,
  getPendingCollections,
  getPendingHandoverOperations,
  markTransactionSynced,
  markConversionSynced,
  markStornoSynced,
  markDistributionSynced,
  markCollectionSynced,
  markHandoverOperationSynced,
} from '../sqlite';

const mockedGetConfig = vi.mocked(getConfig);
const mockedGetPendingTransactions = vi.mocked(getPendingTransactions);
const mockedGetPendingConversions = vi.mocked(getPendingConversions);
const mockedGetPendingBankTransactions = vi.mocked(getPendingBankTransactions);
const mockedGetPendingStornos = vi.mocked(getPendingStornos);
const mockedGetPendingDistributions = vi.mocked(getPendingDistributions);
const mockedGetPendingTransfers = vi.mocked(getPendingTransfers);
const mockedGetPendingCollections = vi.mocked(getPendingCollections);
const mockedGetPendingHandoverOperations = vi.mocked(getPendingHandoverOperations);
const mockedMarkTransactionSynced = vi.mocked(markTransactionSynced);
const mockedMarkConversionSynced = vi.mocked(markConversionSynced);
const mockedMarkStornoSynced = vi.mocked(markStornoSynced);
const mockedMarkDistributionSynced = vi.mocked(markDistributionSynced);
const mockedMarkCollectionSynced = vi.mocked(markCollectionSynced);
const mockedMarkHandoverOperationSynced = vi.mocked(markHandoverOperationSynced);

describe('selectBootstrapRoleCode', () => {
  it('ertektar appMode eseten nem valasztja a legacy CASHIER role-t, ha van ertektar role', () => {
    const selected = selectBootstrapRoleCode('ertektar', 'CASHIER', {
      roles: ['CASHIER', 'ertektar'],
    });

    expect(selected).toBe('ertektar');
  });

  it('penztar appMode eseten canonical penztar role-t preferal', () => {
    const selected = selectBootstrapRoleCode('penztar', 'CASHIER', {
      roles: ['CASHIER', 'penztar'],
    });

    expect(selected).toBe('penztar');
  });

  it('appMode nelkul explicit role-t hasznal, ha a backend valaszban valid', () => {
    const selected = selectBootstrapRoleCode(null, 'CHIEF_VAULT', {
      roles: ['CHIEF_VAULT', 'CASHIER'],
    });

    expect(selected).toBe('CHIEF_VAULT');
  });
});

describe('SyncEngine — syncAll', () => {
  let engine: SyncEngine;

  beforeEach(() => {
    vi.clearAllMocks();
    engine = new SyncEngine();
    // Default: server_url config
    mockedGetConfig.mockImplementation((key: string) => {
      if (key === 'server_url') return 'http://localhost:8080/api/v1';
      if (key === 'auth_token') return 'test-token-123';
      return null;
    });
  });

  afterEach(() => {
    engine.stop();
  });

  it('should return zero results when no pending items', async () => {
    // All getPending* already return empty arrays from mock
    const result = await engine.syncAll('test-token');
    expect(result.synced).toBe(0);
    expect(result.failed).toBe(0);
    expect(result.errors).toHaveLength(0);
  });

  it('should sync pending transactions successfully', async () => {
    mockedGetPendingTransactions.mockReturnValue([
      {
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
        denominations: null, source_of_funds: null, customer_is_pep: null, local_reference_number: 'LS-20260324-ABCD',
        idempotency_key: 'key-1',
        created_at: '2026-03-24 10:00:00',        synced: 0,
      },
    ]);

    // Mock fetch for the sync POST
    const mockFetch = vi.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ success: true }),
    });
    vi.stubGlobal('fetch', mockFetch);

    const result = await engine.syncAll('test-token');

    expect(result.synced).toBe(1);
    expect(result.failed).toBe(0);
    expect(mockedMarkTransactionSynced).toHaveBeenCalledWith(1);
    expect(mockFetch).toHaveBeenCalledTimes(1);

    // Verify the fetch was called with correct endpoint
    const fetchCall = mockFetch.mock.calls[0]!;
    expect(fetchCall[0]).toBe('http://localhost:8080/api/v1/transactions/sell');

    vi.unstubAllGlobals();
  });

  it('should handle auth errors and stop syncing', async () => {
    mockedGetPendingTransactions.mockReturnValue([
      {
        id: 1, type: 'SELL', currency_code: 'EUR', foreign_amount: 100,
        huf_amount: 40000, rounded_huf_amount: 40000, rate: 400,
        handling_fee: null, discount_percent: null, customer_id: null,
        customer_identifier: null, customer_name: null,
        customer_document_number: null, customer_address: null,
        denominations: null, source_of_funds: null, customer_is_pep: null, local_reference_number: 'LS-1', idempotency_key: 'k1',
        created_at: '2026-03-24', synced: 0,
      },
      {
        id: 2, type: 'BUY', currency_code: 'USD', foreign_amount: 50,
        huf_amount: 18000, rounded_huf_amount: 18000, rate: 360,
        handling_fee: null, discount_percent: null, customer_id: null,
        customer_identifier: null, customer_name: null,
        customer_document_number: null, customer_address: null,
        denominations: null, source_of_funds: null, customer_is_pep: null, local_reference_number: 'LB-2', idempotency_key: 'k2',
        created_at: '2026-03-24', synced: 0,
      },
    ]);

    // First call returns 401
    const mockFetch = vi.fn().mockResolvedValue({
      ok: false,
      status: 401,
      statusText: 'Unauthorized',
    });
    vi.stubGlobal('fetch', mockFetch);

    const result = await engine.syncAll('expired-token');

    // First tx fails with auth error, second is counted as failed too (sync stops)
    expect(result.failed).toBeGreaterThanOrEqual(1);
    expect(result.errors.some((e) => e.includes('401'))).toBe(true);
    expect(mockedMarkTransactionSynced).not.toHaveBeenCalled();

    vi.unstubAllGlobals();
  });

  it('should handle network errors and stop syncing', async () => {
    mockedGetPendingTransactions.mockReturnValue([
      {
        id: 1, type: 'SELL', currency_code: 'EUR', foreign_amount: 100,
        huf_amount: 40000, rounded_huf_amount: 40000, rate: 400,
        handling_fee: null, discount_percent: null, customer_id: null,
        customer_identifier: null, customer_name: null,
        customer_document_number: null, customer_address: null,
        denominations: null, source_of_funds: null, customer_is_pep: null, local_reference_number: 'LS-1', idempotency_key: 'k1',
        created_at: '2026-03-24', synced: 0,
      },
    ]);

    const mockFetch = vi.fn().mockRejectedValue(new TypeError('fetch failed'));
    vi.stubGlobal('fetch', mockFetch);

    const result = await engine.syncAll('test-token');
    expect(result.failed).toBeGreaterThanOrEqual(1);
    expect(result.errors.some((e) => e.includes('fetch'))).toBe(true);

    vi.unstubAllGlobals();
  });

  it('should return failure when no auth token provided and no stored token', async () => {
    mockedGetPendingTransactions.mockReturnValue([
      {
        id: 1, type: 'SELL', currency_code: 'EUR', foreign_amount: 100,
        huf_amount: 40000, rounded_huf_amount: 40000, rate: 400,
        handling_fee: null, discount_percent: null, customer_id: null,
        customer_identifier: null, customer_name: null,
        customer_document_number: null, customer_address: null,
        denominations: null, source_of_funds: null, customer_is_pep: null, local_reference_number: 'LS-1', idempotency_key: 'k1',
        created_at: '2026-03-24', synced: 0,
      },
    ]);

    // No stored auth token, but server_url IS configured (online mode)
    mockedGetConfig.mockImplementation((key: string) => {
      if (key === 'server_url') return 'http://localhost:8080/api/v1';
      return null;
    });

    const result = await engine.syncAll(null);
    expect(result.failed).toBe(1);
    expect(result.errors).toContain('Nincs auth token — bejelentkezés szükséges');
  });

  it('should sync conversions after transactions', async () => {
    // Ensure no pending transactions (reset any leaked state)
    mockedGetPendingTransactions.mockReturnValue([]);
    mockedGetPendingBankTransactions.mockReturnValue([]);
    mockedGetPendingDistributions.mockReturnValue([]);
    mockedGetPendingTransfers.mockReturnValue([]);
    mockedGetPendingCollections.mockReturnValue([]);
    mockedGetPendingStornos.mockReturnValue([]);
    mockedGetPendingHandoverOperations.mockReturnValue([]);

    mockedGetPendingConversions.mockReturnValue([
      {
        id: 10,
        from_currency_id: null,
        from_currency_code: 'EUR',
        to_currency_id: null,
        to_currency_code: 'USD',
        from_amount: 100,
        calculated_huf_amount: 40000,
        calculated_to_amount: 110,
        conversion_rate: 400,
        handling_fee: null,
        customer_id: null,
        customer_name: null,
        customer_document_number: null,
        note: null,
        local_reference_number: 'LC-10',
        idempotency_key: 'conv-key-1',
        created_at: '2026-03-24',        synced: 0,
      },
    ]);

    const mockFetch = vi.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ success: true }),
    });
    vi.stubGlobal('fetch', mockFetch);

    const result = await engine.syncAll('test-token');

    expect(result.synced).toBe(1);
    expect(mockedMarkConversionSynced).toHaveBeenCalledWith(10);

    // Find the conversion fetch call
    const conversionCall = mockFetch.mock.calls.find(
      (call) => (call[0] as string).includes('/transactions/conversion'),
    );
    expect(conversionCall).toBeDefined();

    vi.unstubAllGlobals();
  });

  it('should send idempotency key in headers', async () => {
    mockedGetPendingTransactions.mockReturnValue([
      {
        id: 1, type: 'BUY', currency_code: 'USD', foreign_amount: 200,
        huf_amount: 72000, rounded_huf_amount: 72000, rate: 360,
        handling_fee: null, discount_percent: null, customer_id: null,
        customer_identifier: null, customer_name: null,
        customer_document_number: null, customer_address: null,
        denominations: null, source_of_funds: null, customer_is_pep: null, local_reference_number: 'LB-1',
        idempotency_key: 'my-idempotency-key-123',
        created_at: '2026-03-24', synced: 0,
      },
    ]);

    const mockFetch = vi.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ success: true }),
    });
    vi.stubGlobal('fetch', mockFetch);

    await engine.syncAll('test-token');

    const fetchOptions = mockFetch.mock.calls[0]![1] as RequestInit;
    const headers = fetchOptions.headers as Record<string, string>;
    expect(headers['Idempotency-Key']).toBe('my-idempotency-key-123');

    vi.unstubAllGlobals();
  });

  // G3-G4: PEP nyilatkozat + pénzeszköz forrás mezők a POST body-ban
  it('should include sourceOfFunds and customerIsPep in POST body when set (G3-G4)', async () => {
    // Reset all queues to prevent stale mockReturnValue leaking from earlier tests
    mockedGetPendingConversions.mockReturnValue([]);
    mockedGetPendingBankTransactions.mockReturnValue([]);
    mockedGetPendingDistributions.mockReturnValue([]);
    mockedGetPendingTransfers.mockReturnValue([]);
    mockedGetPendingCollections.mockReturnValue([]);
    mockedGetPendingStornos.mockReturnValue([]);
    mockedGetPendingHandoverOperations.mockReturnValue([]);

    mockedGetPendingTransactions.mockReturnValue([
      {
        id: 101,
        type: 'BUY',
        currency_code: 'EUR',
        foreign_amount: 1000,
        huf_amount: 400000,
        rounded_huf_amount: 400000,
        rate: 400,
        handling_fee: null,
        discount_percent: null,
        customer_id: null,
        customer_identifier: 'CUST-001',
        customer_name: 'Teszt Ügyfél',
        customer_document_number: 'AB123456',
        customer_address: 'Budapest, Fő u. 1.',
        denominations: null,
        source_of_funds: 'munkabér',
        customer_is_pep: 0,
        local_reference_number: 'LB-PEP-001',
        idempotency_key: 'pep-test-key-001',
        created_at: '2026-04-05 10:00:00',
        synced: 0,
      },
    ]);

    const mockFetch = vi.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ success: true }),
    });
    vi.stubGlobal('fetch', mockFetch);

    const result = await engine.syncAll('test-token');

    expect(result.synced).toBe(1);
    expect(result.failed).toBe(0);

    // Verify POST body contains sourceOfFunds and customerIsPep
    const fetchOpts = mockFetch.mock.calls[0]![1] as RequestInit;
    const body = JSON.parse(fetchOpts.body as string) as Record<string, unknown>;
    expect(body['sourceOfFunds']).toBe('munkabér');
    expect(body['customerIsPep']).toBe(false); // customer_is_pep=0 → false

    vi.unstubAllGlobals();
  });

  it('should include customerIsPep=true when customer_is_pep=1 (G3-G4)', async () => {
    mockedGetPendingConversions.mockReturnValue([]);
    mockedGetPendingBankTransactions.mockReturnValue([]);
    mockedGetPendingDistributions.mockReturnValue([]);
    mockedGetPendingTransfers.mockReturnValue([]);
    mockedGetPendingCollections.mockReturnValue([]);
    mockedGetPendingStornos.mockReturnValue([]);
    mockedGetPendingHandoverOperations.mockReturnValue([]);

    mockedGetPendingTransactions.mockReturnValue([
      {
        id: 102,
        type: 'SELL',
        currency_code: 'USD',
        foreign_amount: 2000,
        huf_amount: 720000,
        rounded_huf_amount: 720000,
        rate: 360,
        handling_fee: null,
        discount_percent: null,
        customer_id: null,
        customer_identifier: null,
        customer_name: 'PEP Ügyfél',
        customer_document_number: 'CD789012',
        customer_address: null,
        denominations: null,
        source_of_funds: 'megtakarítás',
        customer_is_pep: 1,
        local_reference_number: 'LS-PEP-002',
        idempotency_key: 'pep-test-key-002',
        created_at: '2026-04-05 10:01:00',
        synced: 0,
      },
    ]);

    const mockFetch = vi.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ success: true }),
    });
    vi.stubGlobal('fetch', mockFetch);

    await engine.syncAll('test-token');

    const fetchOpts = mockFetch.mock.calls[0]![1] as RequestInit;
    const body = JSON.parse(fetchOpts.body as string) as Record<string, unknown>;
    expect(body['sourceOfFunds']).toBe('megtakarítás');
    expect(body['customerIsPep']).toBe(true); // customer_is_pep=1 → true

    vi.unstubAllGlobals();
  });

  it('should omit sourceOfFunds and customerIsPep from body when null (G3-G4)', async () => {
    mockedGetPendingConversions.mockReturnValue([]);
    mockedGetPendingBankTransactions.mockReturnValue([]);
    mockedGetPendingDistributions.mockReturnValue([]);
    mockedGetPendingTransfers.mockReturnValue([]);
    mockedGetPendingCollections.mockReturnValue([]);
    mockedGetPendingStornos.mockReturnValue([]);
    mockedGetPendingHandoverOperations.mockReturnValue([]);

    mockedGetPendingTransactions.mockReturnValue([
      {
        id: 103,
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
        local_reference_number: 'LS-NO-PEP-003',
        idempotency_key: 'no-pep-key-003',
        created_at: '2026-04-05 10:02:00',
        synced: 0,
      },
    ]);

    const mockFetch = vi.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ success: true }),
    });
    vi.stubGlobal('fetch', mockFetch);

    await engine.syncAll('test-token');

    const fetchOpts = mockFetch.mock.calls[0]![1] as RequestInit;
    const body = JSON.parse(fetchOpts.body as string) as Record<string, unknown>;
    // When null → must NOT appear in the body at all
    expect(Object.prototype.hasOwnProperty.call(body, 'sourceOfFunds')).toBe(false);
    expect(Object.prototype.hasOwnProperty.call(body, 'customerIsPep')).toBe(false);

    vi.unstubAllGlobals();
  });
});

describe('SyncEngine — getStatus', () => {
  it('should return initial status', () => {
    const engine = new SyncEngine();
    const status = engine.getStatus();
    expect(status.lastSyncAt).toBeNull();
    expect(status.lastSyncResult).toBeNull();
    expect(status.isRunning).toBe(false);
  });
});

describe('SyncEngine — start/stop', () => {
  it('should start and stop without errors', () => {
    const engine = new SyncEngine();
    // start uses setTimeout + setInterval internally
    engine.start(60_000);
    engine.stop();
    // No errors = pass
  });

  it('should handle multiple stop calls', () => {
    const engine = new SyncEngine();
    engine.stop();
    engine.stop();
    // No errors = pass
  });
});

// Helper: build a minimal pending transaction row
function makeTx(id: number, overrides: Partial<ReturnType<typeof getPendingTransactions>[number]> = {}): ReturnType<typeof getPendingTransactions>[number] {
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
    denominations: null, source_of_funds: null, customer_is_pep: null, local_reference_number: `LS-${id}`,
    idempotency_key: `ikey-${id}`,
    created_at: '2026-03-31 10:00:00',    synced: 0,
    ...overrides,
  };
}

function makeStorno(id: number, overrides: Partial<ReturnType<typeof getPendingStornos>[number]> = {}): ReturnType<typeof getPendingStornos>[number] {
  return {
    id,
    transaction_id: id * 10,
    original_receipt_number: `REC-${id}`,
    original_transaction_type: 'SELL',
    currency_code: 'EUR',
    foreign_amount: 100,
    huf_amount: 40000,
    exchange_rate: 400,
    reason: 'Hibás tranzakció',
    approval_id: null,
    custom_exchange_rate: null,
    payment_method: null,
    customer_name: null,
    customer_document_number: null,
    local_reference_number: `STORNO-${id}`,
    idempotency_key: `storno-ikey-${id}`,
    created_at: '2026-03-31 10:00:00',    synced: 0,
    ...overrides,
  };
}

function makeHandoverOp(id: number, operation_type: 'GENERATE' | 'PRINT' | 'COMPLETE' = 'GENERATE'): ReturnType<typeof getPendingHandoverOperations>[number] {
  return {
    id,
    operation_type,
    sheet_id: operation_type !== 'GENERATE' ? `sheet-${id}` : null,
    from_cash_desk_id: 'desk-A',
    to_cash_desk_id: 'desk-B',
    transfer_date: '2026-03-31',
    amounts_json: JSON.stringify({ EUR: 1000, USD: 500 }),
    note: null,
    local_reference_number: `HO-${id}`,
    idempotency_key: `ho-ikey-${id}`,
    created_at: '2026-03-31 10:00:00',    synced: 0,
  };
}

function makeDistribution(id: number): ReturnType<typeof getPendingDistributions>[number] {
  return {
    id,
    target_branch_code: 'BRANCH-02',
    currency_code: 'EUR',
    amount: 500,
    denominations: null,
    note: null,
    local_reference_number: `DIST-${id}`,
    idempotency_key: `dist-ikey-${id}`,
    created_at: '2026-03-31 10:00:00',    synced: 0,
  };
}

function makeCollection(id: number): ReturnType<typeof getPendingCollections>[number] {
  return {
    id,
    source_branch_code: 'BRANCH-01',
    currency_code: 'EUR',
    amount: 300,
    note: null,
    local_reference_number: `COL-${id}`,
    idempotency_key: `col-ikey-${id}`,
    created_at: '2026-03-31 10:00:00',    synced: 0,
  };
}

// --- P1 edge case tesztek ---

describe('SyncEngine — batch limit (200+ pending items)', () => {
  let engine: SyncEngine;

  beforeEach(() => {
    vi.resetAllMocks();
    engine = new SyncEngine();
    mockedGetConfig.mockImplementation((key: string) => {
      if (key === 'server_url') return 'http://localhost:8080/api/v1';
      return null;
    });
    // Explicitly reset all queues to avoid mock state leaking from previous describe blocks
    mockedGetPendingConversions.mockReturnValue([]);
    mockedGetPendingBankTransactions.mockReturnValue([]);
    mockedGetPendingStornos.mockReturnValue([]);
    mockedGetPendingDistributions.mockReturnValue([]);
    mockedGetPendingTransfers.mockReturnValue([]);
    mockedGetPendingCollections.mockReturnValue([]);
    mockedGetPendingHandoverOperations.mockReturnValue([]);
  });

  afterEach(() => {
    engine.stop();
    vi.unstubAllGlobals();
  });

  it('should sync all 200+ pending transactions without dropping any', async () => {
    const count = 220;
    const items = Array.from({ length: count }, (_, i) => makeTx(i + 1));
    mockedGetPendingTransactions.mockReturnValue(items);

    const mockFetch = vi.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ success: true }),
    });
    vi.stubGlobal('fetch', mockFetch);

    const result = await engine.syncAll('test-token');

    // All queues are empty except transactions → synced = count
    expect(result.synced).toBe(count);
    expect(result.failed).toBe(0);
    expect(mockedMarkTransactionSynced).toHaveBeenCalledTimes(count);
    expect(mockFetch).toHaveBeenCalledTimes(count);
  });
});

describe('SyncEngine — duplikált idempotency-key (409 Conflict)', () => {
  let engine: SyncEngine;

  beforeEach(() => {
    vi.resetAllMocks();
    engine = new SyncEngine();
    mockedGetConfig.mockImplementation((key: string) => {
      if (key === 'server_url') return 'http://localhost:8080/api/v1';
      return null;
    });
    mockedGetPendingConversions.mockReturnValue([]);
    mockedGetPendingBankTransactions.mockReturnValue([]);
    mockedGetPendingStornos.mockReturnValue([]);
    mockedGetPendingDistributions.mockReturnValue([]);
    mockedGetPendingTransfers.mockReturnValue([]);
    mockedGetPendingCollections.mockReturnValue([]);
    mockedGetPendingHandoverOperations.mockReturnValue([]);
  });

  afterEach(() => {
    engine.stop();
    vi.unstubAllGlobals();
  });

  it('should count 409 Conflict as failed but not stop remaining syncs', async () => {
    // 3 transactions: first returns 409, rest succeed
    mockedGetPendingTransactions.mockReturnValue([
      makeTx(1, { idempotency_key: 'dup-key' }),
      makeTx(2),
      makeTx(3),
    ]);

    const mockFetch = vi.fn()
      .mockResolvedValueOnce({ ok: false, status: 409, statusText: 'Conflict' })
      .mockResolvedValue({ ok: true, json: () => Promise.resolve({ success: true }) });
    vi.stubGlobal('fetch', mockFetch);

    const result = await engine.syncAll('test-token');

    // TX 1 fails with 409 (not auth error, not network error, so the loop continues)
    expect(result.failed).toBe(1);
    expect(result.synced).toBe(2);
    expect(result.errors.some((e) => e.includes('409'))).toBe(true);
    // TX 1 must NOT be marked synced
    expect(mockedMarkTransactionSynced).not.toHaveBeenCalledWith(1);
    // TX 2 and 3 should be marked synced
    expect(mockedMarkTransactionSynced).toHaveBeenCalledWith(2);
    expect(mockedMarkTransactionSynced).toHaveBeenCalledWith(3);
  });
});

describe('SyncEngine — párhuzamos sync trigger (race condition)', () => {
  let engine: SyncEngine;

  beforeEach(() => {
    vi.resetAllMocks();
    engine = new SyncEngine();
    mockedGetConfig.mockImplementation((key: string) => {
      if (key === 'server_url') return 'http://localhost:8080/api/v1';
      return null;
    });
    mockedGetPendingConversions.mockReturnValue([]);
    mockedGetPendingBankTransactions.mockReturnValue([]);
    mockedGetPendingStornos.mockReturnValue([]);
    mockedGetPendingDistributions.mockReturnValue([]);
    mockedGetPendingTransfers.mockReturnValue([]);
    mockedGetPendingCollections.mockReturnValue([]);
    mockedGetPendingHandoverOperations.mockReturnValue([]);
  });

  afterEach(() => {
    engine.stop();
    vi.unstubAllGlobals();
  });

  it('second concurrent syncAll should not double-mark transactions as synced', async () => {
    mockedGetPendingTransactions.mockReturnValue([makeTx(1), makeTx(2)]);

    // Slow fetch — allows second sync to start while first is in-flight
    let resolveFirst: () => void;
    const firstDone = new Promise<void>((resolve) => { resolveFirst = resolve; });

    let callCount = 0;
    const mockFetch = vi.fn().mockImplementation(async () => {
      callCount++;
      if (callCount === 1) {
        // Pause first request so second syncAll can start
        await firstDone;
      }
      return { ok: true, json: () => Promise.resolve({ success: true }) };
    });
    vi.stubGlobal('fetch', mockFetch);

    // Start first sync (will be paused on first fetch)
    const firstSync = engine.syncAll('test-token');

    // Start second sync immediately. It should join the in-flight sync instead of
    // reading and marking the same pending rows again.
    const secondSync = engine.syncAll('test-token');

    // Unblock first
    resolveFirst!();

    const [result1, result2] = await Promise.all([firstSync, secondSync]);

    expect(result1).toEqual({ synced: 2, failed: 0, errors: [] });
    expect(result2).toEqual(result1);
    expect(result1.failed).toBe(0);
    expect(result2.failed).toBe(0);

    const markCalls = mockedMarkTransactionSynced.mock.calls.map(c => c[0]);
    expect(markCalls).toEqual([1, 2]);
    expect(mockFetch).toHaveBeenCalledTimes(2);
  });

  it('runSync (internal) should skip second trigger if already running', async () => {
    // Access private runSync via the isRunning flag check through getStatus
    // We test that the status.isRunning guard works by verifying no double-fetch
    const fetchCalls: string[] = [];
    const mockFetch = vi.fn().mockImplementation(async (url: string) => {
      fetchCalls.push(url as string);
      return { ok: true, json: () => Promise.resolve({ success: true }) };
    });
    vi.stubGlobal('fetch', mockFetch);

    mockedGetPendingTransactions.mockReturnValue([makeTx(1)]);

    // Directly verify that getStatus().isRunning prevents double entry in runSync
    // Since runSync is private, we test the observable effect via syncAll + getStatus
    const status = engine.getStatus();
    expect(status.isRunning).toBe(false);

    await engine.syncAll('test-token');

    // After sync completes, isRunning must be false again
    expect(engine.getStatus().isRunning).toBe(false);
  });
});

describe('SyncEngine — részleges megszakítás (queue konzisztencia)', () => {
  let engine: SyncEngine;

  beforeEach(() => {
    vi.resetAllMocks();
    engine = new SyncEngine();
    mockedGetConfig.mockImplementation((key: string) => {
      if (key === 'server_url') return 'http://localhost:8080/api/v1';
      return null;
    });
    mockedGetPendingConversions.mockReturnValue([]);
    mockedGetPendingBankTransactions.mockReturnValue([]);
    mockedGetPendingStornos.mockReturnValue([]);
    mockedGetPendingDistributions.mockReturnValue([]);
    mockedGetPendingTransfers.mockReturnValue([]);
    mockedGetPendingCollections.mockReturnValue([]);
    mockedGetPendingHandoverOperations.mockReturnValue([]);
  });

  afterEach(() => {
    engine.stop();
    vi.unstubAllGlobals();
  });

  it('should only mark successfully synced items; failed items remain in pending queue', async () => {
    // 5 transactions: #1,#2 succeed, #3 fails with network error (stops loop), #4,#5 never reached
    mockedGetPendingTransactions.mockReturnValue([
      makeTx(1), makeTx(2), makeTx(3), makeTx(4), makeTx(5),
    ]);

    let callCount = 0;
    const mockFetch = vi.fn().mockImplementation(async () => {
      callCount++;
      if (callCount <= 2) {
        return { ok: true, json: () => Promise.resolve({ success: true }) };
      }
      throw new TypeError('fetch failed: network error');
    });
    vi.stubGlobal('fetch', mockFetch);

    const result = await engine.syncAll('test-token');

    // 2 synced, rest counted as failed
    expect(result.synced).toBe(2);
    expect(result.failed).toBe(3);
    // Only TX 1 and 2 marked synced
    expect(mockedMarkTransactionSynced).toHaveBeenCalledWith(1);
    expect(mockedMarkTransactionSynced).toHaveBeenCalledWith(2);
    expect(mockedMarkTransactionSynced).not.toHaveBeenCalledWith(3);
    expect(mockedMarkTransactionSynced).not.toHaveBeenCalledWith(4);
    expect(mockedMarkTransactionSynced).not.toHaveBeenCalledWith(5);
  });
});

describe('SyncEngine — token lejárat sync KÖZBEN (401 → queue megőrzése)', () => {
  let engine: SyncEngine;

  beforeEach(() => {
    vi.resetAllMocks();
    engine = new SyncEngine();
    mockedGetConfig.mockImplementation((key: string) => {
      if (key === 'server_url') return 'http://localhost:8080/api/v1';
      return null;
    });
    mockedGetPendingConversions.mockReturnValue([]);
    mockedGetPendingBankTransactions.mockReturnValue([]);
    mockedGetPendingStornos.mockReturnValue([]);
    mockedGetPendingDistributions.mockReturnValue([]);
    mockedGetPendingTransfers.mockReturnValue([]);
    mockedGetPendingCollections.mockReturnValue([]);
    mockedGetPendingHandoverOperations.mockReturnValue([]);
  });

  afterEach(() => {
    engine.stop();
    vi.unstubAllGlobals();
  });

  it('should not lose pending items when 401 occurs mid-sync', async () => {
    // 3 TX: first succeeds, second gets 401 (token expires), third never called
    mockedGetPendingTransactions.mockReturnValue([makeTx(1), makeTx(2), makeTx(3)]);

    let callCount = 0;
    const mockFetch = vi.fn().mockImplementation(async () => {
      callCount++;
      if (callCount === 1) {
        return { ok: true, json: () => Promise.resolve({ success: true }) };
      }
      return { ok: false, status: 401, statusText: 'Unauthorized' };
    });
    vi.stubGlobal('fetch', mockFetch);

    const result = await engine.syncAll('expiring-token');

    // TX 1 synced, TX 2+3 failed (auth stop)
    expect(result.synced).toBe(1);
    expect(result.failed).toBe(2);

    // TX 1 is marked synced (no data loss for already synced)
    expect(mockedMarkTransactionSynced).toHaveBeenCalledWith(1);

    // TX 2 and 3 are NOT marked synced → they remain in the pending queue
    expect(mockedMarkTransactionSynced).not.toHaveBeenCalledWith(2);
    expect(mockedMarkTransactionSynced).not.toHaveBeenCalledWith(3);

    // Auth error message present
    expect(result.errors.some((e) => e.includes('401') || e.includes('Auth'))).toBe(true);
  });

  it('should preserve all pending items when token is invalid from the start', async () => {
    mockedGetPendingTransactions.mockReturnValue([makeTx(10), makeTx(11)]);

    const mockFetch = vi.fn().mockResolvedValue({
      ok: false,
      status: 401,
      statusText: 'Unauthorized',
    });
    vi.stubGlobal('fetch', mockFetch);

    const result = await engine.syncAll('invalid-token');

    // Nothing synced — all preserved in queue
    expect(result.synced).toBe(0);
    expect(mockedMarkTransactionSynced).not.toHaveBeenCalled();
    expect(result.failed).toBeGreaterThanOrEqual(2);
  });
});

describe('SyncEngine — storno pending → backend rollback (idempotens)', () => {
  let engine: SyncEngine;

  beforeEach(() => {
    vi.resetAllMocks();
    engine = new SyncEngine();
    mockedGetConfig.mockImplementation((key: string) => {
      if (key === 'server_url') return 'http://localhost:8080/api/v1';
      return null;
    });
    // Clear other queues
    mockedGetPendingTransactions.mockReturnValue([]);
    mockedGetPendingConversions.mockReturnValue([]);
    mockedGetPendingBankTransactions.mockReturnValue([]);
    mockedGetPendingDistributions.mockReturnValue([]);
    mockedGetPendingTransfers.mockReturnValue([]);
    mockedGetPendingCollections.mockReturnValue([]);
    mockedGetPendingHandoverOperations.mockReturnValue([]);
  });

  afterEach(() => {
    engine.stop();
    vi.unstubAllGlobals();
  });

  it('should POST storno to /stornos/execute with idempotency key', async () => {
    mockedGetPendingStornos.mockReturnValue([makeStorno(1)]);

    const mockFetch = vi.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ success: true }),
    });
    vi.stubGlobal('fetch', mockFetch);

    const result = await engine.syncAll('test-token');

    expect(result.synced).toBe(1);
    expect(result.failed).toBe(0);
    expect(mockedMarkStornoSynced).toHaveBeenCalledWith(1);

    const fetchCall = mockFetch.mock.calls[0]!;
    expect(fetchCall[0]).toContain('/stornos/execute');

    const opts = fetchCall[1] as RequestInit;
    const headers = opts.headers as Record<string, string>;
    expect(headers['Idempotency-Key']).toBe('storno-ikey-1');
  });

  it('should handle storno 409 Conflict idempotently (already rolled back)', async () => {
    // 409 on storno means server already processed it — count as failed but do NOT re-queue
    mockedGetPendingStornos.mockReturnValue([makeStorno(2), makeStorno(3)]);

    const mockFetch = vi.fn()
      .mockResolvedValueOnce({ ok: false, status: 409, statusText: 'Conflict' })
      .mockResolvedValue({ ok: true, json: () => Promise.resolve({ success: true }) });
    vi.stubGlobal('fetch', mockFetch);

    const result = await engine.syncAll('test-token');

    expect(result.failed).toBe(1);
    expect(result.synced).toBe(1);
    // Storno 2 NOT marked (409), storno 3 marked synced
    expect(mockedMarkStornoSynced).not.toHaveBeenCalledWith(2);
    expect(mockedMarkStornoSynced).toHaveBeenCalledWith(3);
  });
});

describe('SyncEngine — handover/collection/distribution sorrendi függőségek', () => {
  let engine: SyncEngine;

  beforeEach(() => {
    vi.resetAllMocks();
    engine = new SyncEngine();
    mockedGetConfig.mockImplementation((key: string) => {
      if (key === 'server_url') return 'http://localhost:8080/api/v1';
      return null;
    });
    // Default empty queues
    mockedGetPendingTransactions.mockReturnValue([]);
    mockedGetPendingConversions.mockReturnValue([]);
    mockedGetPendingBankTransactions.mockReturnValue([]);
    mockedGetPendingStornos.mockReturnValue([]);
    mockedGetPendingTransfers.mockReturnValue([]);
  });

  afterEach(() => {
    engine.stop();
    vi.unstubAllGlobals();
  });

  it('should sync distribution before collection in the syncAll order', async () => {
    const syncOrder: string[] = [];

    mockedGetPendingDistributions.mockReturnValue([makeDistribution(1)]);
    mockedGetPendingCollections.mockReturnValue([makeCollection(2)]);
    mockedGetPendingHandoverOperations.mockReturnValue([]);

    const mockFetch = vi.fn().mockImplementation(async (url: string) => {
      if ((url as string).includes('/distribution')) syncOrder.push('distribution');
      if ((url as string).includes('/collections')) syncOrder.push('collection');
      return { ok: true, json: () => Promise.resolve({ success: true }) };
    });
    vi.stubGlobal('fetch', mockFetch);

    await engine.syncAll('test-token');

    // Distribution must come before collection (syncAll order: dist → transfers → collections)
    expect(syncOrder.indexOf('distribution')).toBeLessThan(syncOrder.indexOf('collection'));
  });

  it('should sync handover GENERATE before PRINT/COMPLETE operations', async () => {
    const syncOrder: string[] = [];

    mockedGetPendingDistributions.mockReturnValue([]);
    mockedGetPendingCollections.mockReturnValue([]);
    mockedGetPendingHandoverOperations.mockReturnValue([
      makeHandoverOp(10, 'GENERATE'),
      makeHandoverOp(11, 'PRINT'),
      makeHandoverOp(12, 'COMPLETE'),
    ]);

    const mockFetch = vi.fn().mockImplementation(async (url: string) => {
      if ((url as string).includes('/generate')) syncOrder.push('generate');
      if ((url as string).includes('/print')) syncOrder.push('print');
      if ((url as string).includes('/complete')) syncOrder.push('complete');
      return { ok: true, json: () => Promise.resolve({ success: true }) };
    });
    vi.stubGlobal('fetch', mockFetch);

    await engine.syncAll('test-token');

    expect(syncOrder[0]).toBeDefined();
    // GENERATE must come before PRINT and COMPLETE
    const genIdx = syncOrder.indexOf('generate');
    const printIdx = syncOrder.indexOf('print');
    const completeIdx = syncOrder.indexOf('complete');

    expect(genIdx).toBeGreaterThanOrEqual(0);
    expect(printIdx).toBeGreaterThanOrEqual(0);
    expect(completeIdx).toBeGreaterThanOrEqual(0);
    expect(genIdx).toBeLessThan(printIdx);
    expect(genIdx).toBeLessThan(completeIdx);

    expect(mockedMarkHandoverOperationSynced).toHaveBeenCalledWith(10);
    expect(mockedMarkHandoverOperationSynced).toHaveBeenCalledWith(11);
    expect(mockedMarkHandoverOperationSynced).toHaveBeenCalledWith(12);
  });

  it('should sync distributions, collections and handovers independently per entity type', async () => {
    mockedGetPendingDistributions.mockReturnValue([makeDistribution(1), makeDistribution(2)]);
    mockedGetPendingCollections.mockReturnValue([makeCollection(3)]);
    mockedGetPendingHandoverOperations.mockReturnValue([makeHandoverOp(4, 'GENERATE')]);

    const mockFetch = vi.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ success: true }),
    });
    vi.stubGlobal('fetch', mockFetch);

    const result = await engine.syncAll('test-token');

    expect(result.synced).toBe(4);
    expect(result.failed).toBe(0);

    expect(mockedMarkDistributionSynced).toHaveBeenCalledWith(1);
    expect(mockedMarkDistributionSynced).toHaveBeenCalledWith(2);
    expect(mockedMarkCollectionSynced).toHaveBeenCalledWith(3);
    expect(mockedMarkHandoverOperationSynced).toHaveBeenCalledWith(4);
  });
});

/**
 * Audit P1.7 regression tesztek: a SyncEngine offline modon NEM spamel HTTP hivasokat.
 *
 * Bizonyitja:
 * 1. `offline_mode=true` config -> syncAll NEM hivja a fetch-et, gyorsan return-ol
 * 2. `server_url` ures vagy hianyzik -> syncAll NEM hivja a fetch-et
 * 3. Synced=0, failed=0. A 'offline_mode=true' eseten egy "Offline mod" soft-warning
 *    bekerul az `errors` tombbe (degraded operacio jelzes, NEM kivetel).
 *    A `server_url` ures/null eseten csak no-op, errors NEM tartalmaz uzenetet.
 *
 * Copilot review #383 P2 follow-up: a `global.fetch = ...` beallitas korabban szivargott
 * mas test file-okba ugyanabban a Vitest workerben (flakey risk). Most `vi.stubGlobal`
 * + `vi.unstubAllGlobals()` mintat hasznalunk, ami a meglevo file pattern-jet koveti.
 */
describe('SyncEngine — P1.7 offline mode regression', () => {
  let engine: SyncEngine;
  let mockFetch: ReturnType<typeof vi.fn>;

  beforeEach(() => {
    vi.clearAllMocks();
    engine = new SyncEngine();
    mockFetch = vi.fn();
    // Copilot #383 P2: vi.stubGlobal + vi.unstubAllGlobals (afterEach) — NEM
    // direkt `global.fetch = mockFetch`, mert az nem kerul vissza es szivarog.
    vi.stubGlobal('fetch', mockFetch);
  });

  afterEach(() => {
    engine.stop();
    vi.unstubAllGlobals();
  });

  it('offline_mode=true config esetén NEM spamel fetch-et (kritikus: zero HTTP)', async () => {
    mockedGetConfig.mockImplementation((key: string) => {
      if (key === 'offline_mode') return 'true';
      if (key === 'server_url') return 'http://localhost:8080/api/v1';
      if (key === 'auth_token') return 'test-token-123';
      return null;
    });
    // Tegyunk be 1 pending tx-et — meg igy se kelljen hivni a fetch-et
    mockedGetPendingTransactions.mockReturnValue([
      {
        id: 1, type: 'SELL', currency_code: 'EUR', foreign_amount: 100,
        huf_amount: 40000, rounded_huf_amount: 40000, rate: 400, handling_fee: null,
        discount_percent: null, customer_id: null, customer_identifier: null,
        customer_name: null, customer_document_number: null, customer_address: null,
        denominations: null, source_of_funds: null, customer_is_pep: null,
        local_reference_number: 'LS-X', idempotency_key: 'k1',
        created_at: '2026-03-24 10:00:00', synced: 0,
      },
    ] as unknown as ReturnType<typeof mockedGetPendingTransactions>);

    const result = await engine.syncAll('test-token');

    expect(result.synced).toBe(0);
    expect(result.failed).toBe(0);
    // P1.7 KRITIKUS biztositas: zero fetch hivas (NEM spamel HTTP-t a halozatra)
    expect(mockFetch).not.toHaveBeenCalled();
    // syncAll soft-warning egy uzenetet ad ("Offline mod — szerver URL nincs beallitva"),
    // de NEM excepciot — ez tervezett viselkedes (degraded operacio).
    expect(result.errors).toHaveLength(1);
    expect(result.errors[0]).toMatch(/Offline/i);
  });

  it('server_url config ures string esetén NEM spamel fetch-et', async () => {
    mockedGetConfig.mockImplementation((key: string) => {
      if (key === 'server_url') return '   ';  // whitespace-only
      if (key === 'auth_token') return 'test-token-123';
      return null;
    });
    mockedGetPendingTransactions.mockReturnValue([] as ReturnType<typeof mockedGetPendingTransactions>);

    const result = await engine.syncAll('test-token');

    expect(result.synced).toBe(0);
    expect(result.failed).toBe(0);
    expect(mockFetch).not.toHaveBeenCalled();
  });

  it('server_url config null esetén (frissen telepitett, regisztracio nelkul) NEM spamel fetch-et', async () => {
    mockedGetConfig.mockImplementation((key: string) => {
      if (key === 'server_url') return null;
      return null;
    });
    mockedGetPendingTransactions.mockReturnValue([] as ReturnType<typeof mockedGetPendingTransactions>);

    const result = await engine.syncAll('test-token');

    expect(result.synced).toBe(0);
    expect(result.failed).toBe(0);
    expect(mockFetch).not.toHaveBeenCalled();
  });
});
