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

import { SyncEngine } from '../sync-engine';
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
        denominations: null,
        local_reference_number: 'LS-20260324-ABCD',
        idempotency_key: 'key-1',
        created_at: '2026-03-24 10:00:00',
        synced: 0,
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
        denominations: null, local_reference_number: 'LS-1', idempotency_key: 'k1',
        created_at: '2026-03-24', synced: 0,
      },
      {
        id: 2, type: 'BUY', currency_code: 'USD', foreign_amount: 50,
        huf_amount: 18000, rounded_huf_amount: 18000, rate: 360,
        handling_fee: null, discount_percent: null, customer_id: null,
        customer_identifier: null, customer_name: null,
        customer_document_number: null, customer_address: null,
        denominations: null, local_reference_number: 'LB-2', idempotency_key: 'k2',
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
        denominations: null, local_reference_number: 'LS-1', idempotency_key: 'k1',
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
        denominations: null, local_reference_number: 'LS-1', idempotency_key: 'k1',
        created_at: '2026-03-24', synced: 0,
      },
    ]);

    // No stored token
    mockedGetConfig.mockReturnValue(null);

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
        created_at: '2026-03-24',
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
        denominations: null, local_reference_number: 'LB-1',
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
