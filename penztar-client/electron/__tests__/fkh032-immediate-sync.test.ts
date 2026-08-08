/**
 * FKH-032 — celzott azonnali konyveles a main-process net.request csatornan.
 *
 * Given: a penztaros rogzit egy valuta vetelt/eladast, a tetel helyben mentodik.
 * When:  a mentes utan lefuto azonnali kiserlet elindul.
 * Then:  (FR-1) a keres a `fetchViaElectronNet` (net.request / api:fetch) csatornan megy,
 *        NEM a globalis undici `fetch`-en;
 *        (FR-2) csak a MEGADOTT tetel megy fel, nem a teljes pending sor;
 *        (FR-3) a timeout 5000 ms, nem a 15 mp-es altalanos httpPost-ertek;
 *        (FR-5) a TAROLT `idempotency_key` megy fel, nem ujonnan generalt;
 *        (FR-4/NFR-3) a tetel-szintu eredmeny konkret hibauzenetet ad es a hiba
 *        perzisztalodik (markTransactionSyncError -> sync_error + kiserlet-naplo).
 */
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';

vi.mock('electron-log', () => ({
  default: { info: vi.fn(), warn: vi.fn(), error: vi.fn(), debug: vi.fn() },
}));

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

// A net.request csatorna: csak ezt szabad hasznalni az azonnali kiserletnel (FR-1).
vi.mock('../api-proxy', () => ({
  isAllowedUrl: vi.fn(() => true),
  fetchViaElectronNet: vi.fn(),
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
import { fetchViaElectronNet } from '../api-proxy';
import {
  getConfig,
  getPendingTransactions,
  markTransactionSynced,
  markTransactionSyncError,
} from '../sqlite';

const mockedGetConfig = vi.mocked(getConfig);
const mockedGetPendingTransactions = vi.mocked(getPendingTransactions);
const mockedFetchViaNet = vi.mocked(fetchViaElectronNet);
const mockedMarkSynced = vi.mocked(markTransactionSynced);
const mockedMarkSyncError = vi.mocked(markTransactionSyncError);

function makeTx(id: number): ReturnType<typeof getPendingTransactions>[number] {
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
    idempotency_key: `stored-ikey-${id}`,
    created_at: '2026-08-08 10:00:00',
    synced: 0,
  };
}

describe('FKH-032 — syncSingleTransactionImmediate (celzott azonnali konyveles)', () => {
  let engine: SyncEngine;
  let globalFetch: ReturnType<typeof vi.fn>;

  beforeEach(() => {
    vi.resetAllMocks();
    engine = new SyncEngine();
    mockedGetConfig.mockImplementation((key: string) => {
      if (key === 'server_url') return 'http://localhost:8080/api/v1';
      if (key === 'auth_token') return 'test-token';
      if (key === 'bootstrap_company_code') return 'EBC';
      return null;
    });
    // A globalis fetch-nek TILOS lefutnia az azonnali agon (FR-1).
    globalFetch = vi.fn();
    vi.stubGlobal('fetch', globalFetch);
  });

  afterEach(() => {
    engine.stop();
    vi.unstubAllGlobals();
  });

  it('FR-1: a net.request csatornan megy, a globalis undici fetch NEM hivodik', async () => {
    mockedGetPendingTransactions.mockReturnValue([makeTx(7)]);
    mockedFetchViaNet.mockResolvedValue({
      ok: true,
      status: 200,
      statusText: 'OK',
      headers: {},
      body: '{"id":123}',
    });

    const result = await engine.syncSingleTransactionImmediate(7);

    expect(result.success).toBe(true);
    expect(mockedFetchViaNet).toHaveBeenCalledTimes(1);
    expect(globalFetch).not.toHaveBeenCalled();
    expect(mockedMarkSynced).toHaveBeenCalledWith(7);
  });

  it('FR-3: az azonnali kiserlet 5000 ms dedikalt timeoutot hasznal', async () => {
    mockedGetPendingTransactions.mockReturnValue([makeTx(7)]);
    mockedFetchViaNet.mockResolvedValue({
      ok: true,
      status: 200,
      statusText: 'OK',
      headers: {},
      body: '{}',
    });

    await engine.syncSingleTransactionImmediate(7);

    const params = mockedFetchViaNet.mock.calls[0]![0]!;
    expect(params.timeoutMs).toBe(5000);
    expect(params.method).toBe('POST');
    expect(params.url).toContain('/transactions/sell');
  });

  it('FR-5: a MENTESKOR generalt, tarolt idempotency_key megy fel (nincs ujragenrealas)', async () => {
    mockedGetPendingTransactions.mockReturnValue([makeTx(7)]);
    mockedFetchViaNet.mockResolvedValue({
      ok: true,
      status: 200,
      statusText: 'OK',
      headers: {},
      body: '{}',
    });

    await engine.syncSingleTransactionImmediate(7);

    const headers = mockedFetchViaNet.mock.calls[0]![0]!.headers ?? {};
    expect(headers['Idempotency-Key']).toBe('stored-ikey-7');
  });

  it('FR-2: CSAK a megadott tetel megy fel, a tobbi pending sor nem', async () => {
    mockedGetPendingTransactions.mockReturnValue([makeTx(7), makeTx(8), makeTx(9)]);
    mockedFetchViaNet.mockResolvedValue({
      ok: true,
      status: 200,
      statusText: 'OK',
      headers: {},
      body: '{}',
    });

    await engine.syncSingleTransactionImmediate(8);

    expect(mockedFetchViaNet).toHaveBeenCalledTimes(1);
    const headers = mockedFetchViaNet.mock.calls[0]![0]!.headers ?? {};
    expect(headers['Idempotency-Key']).toBe('stored-ikey-8');
    expect(mockedMarkSynced).toHaveBeenCalledTimes(1);
    expect(mockedMarkSynced).toHaveBeenCalledWith(8);
  });

  it('FR-4/NFR-3: 4xx eseten a szerver konkret hibauzenete jon vissza es perzisztalodik', async () => {
    mockedGetPendingTransactions.mockReturnValue([makeTx(7)]);
    mockedFetchViaNet.mockResolvedValue({
      ok: false,
      status: 422,
      statusText: 'Unprocessable Entity',
      headers: {},
      body: JSON.stringify({ status: 422, message: 'Arfolyam-elteres: a tetel elutasitva' }),
    });

    const result = await engine.syncSingleTransactionImmediate(7);

    expect(result.success).toBe(false);
    expect(result.error).toContain('HTTP 422');
    expect(result.error).toContain('Arfolyam-elteres');
    expect(mockedMarkSyncError).toHaveBeenCalled();
    const [id, storedError] = mockedMarkSyncError.mock.calls.at(-1)!;
    expect(id).toBe(7);
    expect(String(storedError)).toContain('HTTP 422');
    expect(mockedMarkSynced).not.toHaveBeenCalled();
  });

  it('FR-3: halozati hiba/timeout eseten a tetel a helyi queue-ban marad (nincs markSynced)', async () => {
    mockedGetPendingTransactions.mockReturnValue([makeTx(7)]);
    mockedFetchViaNet.mockRejectedValue(new Error('net::ERR_TIMED_OUT'));

    const result = await engine.syncSingleTransactionImmediate(7);

    expect(result.success).toBe(false);
    expect(result.error).toContain('ERR_TIMED_OUT');
    expect(mockedMarkSynced).not.toHaveBeenCalled();
    expect(mockedMarkSyncError).toHaveBeenCalled();
  });

  it('FR-5 (edge case): mar felkerult tetel eseten SIKERT ad, nem indit ujabb kerest — nincs duplikacio', async () => {
    // A 30 mp-es hatter-ciklus kozben felvitte a tetelt -> mar nincs a pending sorban.
    mockedGetPendingTransactions.mockReturnValue([]);

    const result = await engine.syncSingleTransactionImmediate(7);

    expect(result.success).toBe(true);
    expect(mockedFetchViaNet).not.toHaveBeenCalled();
    expect(globalFetch).not.toHaveBeenCalled();
  });

  it('offline (nincs szerver URL): konkret, tetel-szintu hibauzenet, nincs halozati keres', async () => {
    mockedGetConfig.mockImplementation((key: string) =>
      key === 'auth_token' ? 'test-token' : null,
    );
    mockedGetPendingTransactions.mockReturnValue([makeTx(7)]);

    const result = await engine.syncSingleTransactionImmediate(7);

    expect(result.success).toBe(false);
    expect(result.error).toContain('Offline');
    expect(mockedFetchViaNet).not.toHaveBeenCalled();
  });
});
