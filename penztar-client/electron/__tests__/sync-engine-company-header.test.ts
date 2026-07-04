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
  getPendingTransactions,
  getPendingTransfers,
  markTransactionSynced,
  markTransferSynced,
} from '../sqlite';

const mockedGetConfig = vi.mocked(getConfig);
const mockedGetPendingTransactions = vi.mocked(getPendingTransactions);
const mockedGetPendingTransfers = vi.mocked(getPendingTransfers);
const mockedMarkTransactionSynced = vi.mocked(markTransactionSynced);
const mockedMarkTransferSynced = vi.mocked(markTransferSynced);

type PendingTx = ReturnType<typeof getPendingTransactions>[number];
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
    handling_fee_override_type: null,
    handling_fee_override_reason: null,
    customer_card_number: null,
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
    is_legal_entity_customer: null,
    legal_entity_name: null,
    legal_entity_seat: null,
    legal_entity_tax_number: null,
    legal_deed_number: null,
    beneficial_owners_json: null,
    local_reference_number: 'TX-1',
    idempotency_key: 'tx-key-1',
    company_code: companyCode,
    created_at: '2026-07-04 10:00:00',
    synced: 0,
    ...overrides,
  };
}

function makeTransfer(companyCode: string | null, overrides: Partial<PendingTransfer> = {}): PendingTransfer {
  return {
    id: 2,
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
    local_reference_number: 'TR-2',
    idempotency_key: 'transfer-key-2',
    company_code: companyCode,
    created_at: '2026-07-04 10:00:00',
    synced: 0,
    ...overrides,
  };
}

function successfulFetch(): ReturnType<typeof vi.fn> {
  return vi.fn().mockResolvedValue({ ok: true, json: () => Promise.resolve({ success: true }) });
}

describe('SyncEngine X-Company-Code HTTP header', () => {
  let engine: SyncEngine;

  beforeEach(() => {
    vi.clearAllMocks();
    engine = new SyncEngine();
    mockedGetPendingTransactions.mockReturnValue([]);
    mockedGetPendingTransfers.mockReturnValue([]);
  });

  afterEach(() => {
    engine.stop();
    vi.unstubAllGlobals();
  });

  it('sends trimmed bootstrap_company_code as X-Company-Code on transaction and transfer POSTs', async () => {
    mockedGetPendingTransactions.mockReturnValue([makeTx('BC')]);
    mockedGetPendingTransfers.mockReturnValue([makeTransfer('BC')]);
    mockedGetConfig.mockImplementation((key: string) => {
      if (key === 'server_url') return 'http://localhost:8080/api/v1';
      if (key === 'auth_token') return 'test-token';
      if (key === 'bootstrap_company_code') return ' BC ';
      return null;
    });
    const fetchMock = successfulFetch();
    vi.stubGlobal('fetch', fetchMock);

    const result = await engine.syncAll('test-token');

    expect(result.failed).toBe(0);
    expect(result.synced).toBe(2);
    expect(mockedMarkTransactionSynced).toHaveBeenCalledWith(1);
    expect(mockedMarkTransferSynced).toHaveBeenCalledWith(2);
    expect(fetchMock).toHaveBeenCalledTimes(2);
    for (const call of fetchMock.mock.calls) {
      const headers = (call[1] as { headers: Record<string, string> }).headers;
      expect(headers['X-Company-Code']).toBe('BC');
    }
  });

  it('does not send X-Company-Code when bootstrap_company_code is missing or blank', async () => {
    mockedGetPendingTransactions.mockReturnValue([makeTx(null)]);
    mockedGetConfig.mockImplementation((key: string) => {
      if (key === 'server_url') return 'http://localhost:8080/api/v1';
      if (key === 'auth_token') return 'test-token';
      if (key === 'bootstrap_company_code') return '   ';
      return null;
    });
    const fetchMock = successfulFetch();
    vi.stubGlobal('fetch', fetchMock);

    const result = await engine.syncAll('test-token');

    expect(result.failed).toBe(0);
    expect(result.synced).toBe(1);
    const headers = (fetchMock.mock.calls[0]?.[1] as { headers: Record<string, string> }).headers;
    expect(headers).not.toHaveProperty('X-Company-Code');
  });
});
