/**
 * sync-engine — Szimulált hálózati szakadás tesztek.
 *
 * Sprint 8/3: Az offline-first sync engine viselkedése
 * hálózati instabilitás, intermittáló kapcsolat és
 * teljes offline periódus szimulálásával.
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
  getPendingTransferStornos: vi.fn(() => []),
  getPendingCircularReplies: vi.fn(() => []),
  getPendingCollections: vi.fn(() => []),
  getPendingHandoverOperations: vi.fn(() => []),
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

function makeTx(
  id: number,
  overrides: Partial<ReturnType<typeof getPendingTransactions>[number]> = {},
): ReturnType<typeof getPendingTransactions>[number] {
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
    idempotency_key: `ikey-${id}`,
    created_at: '2026-04-03 10:00:00',
    synced: 0,
    ...overrides,
  };
}

function resetAllQueues(): void {
  mockedGetPendingConversions.mockReturnValue([]);
  mockedGetPendingBankTransactions.mockReturnValue([]);
  mockedGetPendingStornos.mockReturnValue([]);
  mockedGetPendingDistributions.mockReturnValue([]);
  mockedGetPendingTransfers.mockReturnValue([]);
  mockedGetPendingCollections.mockReturnValue([]);
  mockedGetPendingHandoverOperations.mockReturnValue([]);
}

// ═══════════════════════════════════════════
// 1. Teljes hálózati szakadás
// ═══════════════════════════════════════════

describe('SyncEngine — Teljes hálózati szakadás', () => {
  let engine: SyncEngine;

  beforeEach(() => {
    vi.resetAllMocks();
    engine = new SyncEngine();
    mockedGetConfig.mockImplementation((key: string) => {
      if (key === 'server_url') return 'http://localhost:8080/api/v1';
      return null;
    });
    resetAllQueues();
  });

  afterEach(() => {
    engine.stop();
    vi.unstubAllGlobals();
  });

  it('DNS feloldási hiba — minden tranzakció megmarad a queue-ban', async () => {
    mockedGetPendingTransactions.mockReturnValue([makeTx(1), makeTx(2), makeTx(3)]);

    const mockFetch = vi
      .fn()
      .mockRejectedValue(new TypeError('fetch failed: getaddrinfo ENOTFOUND localhost'));
    vi.stubGlobal('fetch', mockFetch);

    const result = await engine.syncAll('test-token');

    expect(result.synced).toBe(0);
    expect(result.failed).toBe(3);
    expect(mockedMarkTransactionSynced).not.toHaveBeenCalled();
    expect(result.errors.some((e) => e.includes('fetch') || e.includes('ENOTFOUND'))).toBe(true);
  });

  it('Connection refused — queue megőrzés', async () => {
    mockedGetPendingTransactions.mockReturnValue([makeTx(1)]);

    const mockFetch = vi
      .fn()
      .mockRejectedValue(new TypeError('fetch failed: connect ECONNREFUSED 127.0.0.1:8080'));
    vi.stubGlobal('fetch', mockFetch);

    const result = await engine.syncAll('test-token');

    expect(result.synced).toBe(0);
    expect(result.failed).toBe(1);
    expect(mockedMarkTransactionSynced).not.toHaveBeenCalled();
  });

  it('Timeout (AbortError) — queue megőrzés', async () => {
    mockedGetPendingTransactions.mockReturnValue([makeTx(1), makeTx(2)]);

    const abortError = new DOMException('The operation was aborted', 'AbortError');
    const mockFetch = vi.fn().mockRejectedValue(abortError);
    vi.stubGlobal('fetch', mockFetch);

    const result = await engine.syncAll('test-token');

    expect(result.synced).toBe(0);
    expect(result.failed).toBe(2);
    expect(mockedMarkTransactionSynced).not.toHaveBeenCalled();
  });
});

// ═══════════════════════════════════════════
// 2. Intermittáló kapcsolat
// ═══════════════════════════════════════════

describe('SyncEngine — Intermittáló kapcsolat (flapping)', () => {
  let engine: SyncEngine;

  beforeEach(() => {
    vi.resetAllMocks();
    engine = new SyncEngine();
    mockedGetConfig.mockImplementation((key: string) => {
      if (key === 'server_url') return 'http://localhost:8080/api/v1';
      return null;
    });
    resetAllQueues();
  });

  afterEach(() => {
    engine.stop();
    vi.unstubAllGlobals();
  });

  it('Minden második request sikeres — csak a sikeres tranzakciókat jelöli szinkronizáltnak', async () => {
    mockedGetPendingTransactions.mockReturnValue([
      makeTx(1),
      makeTx(2),
      makeTx(3),
      makeTx(4),
      makeTx(5),
    ]);

    let callCount = 0;
    const mockFetch = vi.fn().mockImplementation(async () => {
      callCount++;
      if (callCount % 2 === 0) {
        // Páros hívás: hálózati hiba
        throw new TypeError('fetch failed: connection reset');
      }
      return { ok: true, json: () => Promise.resolve({ success: true }) };
    });
    vi.stubGlobal('fetch', mockFetch);

    const result = await engine.syncAll('test-token');

    // TX 1 OK, TX 2 fail (stops loop because network error stops remaining)
    expect(result.synced).toBe(1);
    expect(result.failed).toBe(4);
    expect(mockedMarkTransactionSynced).toHaveBeenCalledWith(1);
    expect(mockedMarkTransactionSynced).not.toHaveBeenCalledWith(2);
  });

  it('Szerver 500 → nem auth hiba, a loop megpróbálja a következőt is', async () => {
    mockedGetPendingTransactions.mockReturnValue([makeTx(1), makeTx(2), makeTx(3)]);

    let callCount = 0;
    const mockFetch = vi.fn().mockImplementation(async () => {
      callCount++;
      if (callCount === 2) {
        return { ok: false, status: 500, statusText: 'Internal Server Error' };
      }
      return { ok: true, json: () => Promise.resolve({ success: true }) };
    });
    vi.stubGlobal('fetch', mockFetch);

    const result = await engine.syncAll('test-token');

    // TX 1 OK, TX 2 fail (500 but not auth → loop continues), TX 3 OK
    expect(result.synced).toBe(2);
    expect(result.failed).toBe(1);
    expect(mockedMarkTransactionSynced).toHaveBeenCalledWith(1);
    expect(mockedMarkTransactionSynced).not.toHaveBeenCalledWith(2);
    expect(mockedMarkTransactionSynced).toHaveBeenCalledWith(3);
  });
});

// ═══════════════════════════════════════════
// 3. Offline periódus utáni tömeges szinkron
// ═══════════════════════════════════════════

describe('SyncEngine — Offline periódus után tömeges szinkron', () => {
  let engine: SyncEngine;

  beforeEach(() => {
    vi.resetAllMocks();
    engine = new SyncEngine();
    mockedGetConfig.mockImplementation((key: string) => {
      if (key === 'server_url') return 'http://localhost:8080/api/v1';
      return null;
    });
    resetAllQueues();
  });

  afterEach(() => {
    engine.stop();
    vi.unstubAllGlobals();
  });

  it('500 tranzakció felhalmozódott offline — mind szinkronizálódik', async () => {
    const count = 500;
    const items = Array.from({ length: count }, (_, i) => makeTx(i + 1));
    mockedGetPendingTransactions.mockReturnValue(items);

    const mockFetch = vi.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ success: true }),
    });
    vi.stubGlobal('fetch', mockFetch);

    const result = await engine.syncAll('test-token');

    expect(result.synced).toBe(count);
    expect(result.failed).toBe(0);
    expect(mockedMarkTransactionSynced).toHaveBeenCalledTimes(count);
    expect(mockFetch).toHaveBeenCalledTimes(count);
  });

  it('Offline → online → első 50 OK → újra offline → queue megőrzés', async () => {
    const items = Array.from({ length: 100 }, (_, i) => makeTx(i + 1));
    mockedGetPendingTransactions.mockReturnValue(items);

    let callCount = 0;
    const mockFetch = vi.fn().mockImplementation(async () => {
      callCount++;
      if (callCount > 50) {
        // Hálózat újra elszakad
        throw new TypeError('fetch failed: connection reset');
      }
      return { ok: true, json: () => Promise.resolve({ success: true }) };
    });
    vi.stubGlobal('fetch', mockFetch);

    const result = await engine.syncAll('test-token');

    expect(result.synced).toBe(50);
    expect(result.failed).toBe(50);

    // Pontosan az első 50 van szinkronizálva
    for (let i = 1; i <= 50; i++) {
      expect(mockedMarkTransactionSynced).toHaveBeenCalledWith(i);
    }
    // 51-100 NEM szinkronizálva
    for (let i = 51; i <= 100; i++) {
      expect(mockedMarkTransactionSynced).not.toHaveBeenCalledWith(i);
    }
  });
});

// ═══════════════════════════════════════════
// 4. Idempotencia-kulcsok hálózati szakadásnál
// ═══════════════════════════════════════════

describe('SyncEngine — Idempotencia hálózati szakadás után', () => {
  let engine: SyncEngine;

  beforeEach(() => {
    vi.resetAllMocks();
    engine = new SyncEngine();
    mockedGetConfig.mockImplementation((key: string) => {
      if (key === 'server_url') return 'http://localhost:8080/api/v1';
      return null;
    });
    resetAllQueues();
  });

  afterEach(() => {
    engine.stop();
    vi.unstubAllGlobals();
  });

  it('Újraküldésnél azonos idempotency-key megy — szerver 409-cel ismétlődőt jelez', async () => {
    // Szimuláció: TX-1 elment a szervernek, de a válasz elveszik (hálózati hiba)
    // Újrapróbálkozásnál a szerver 409-cel jelzi, hogy már megkapta
    const tx = makeTx(1, { idempotency_key: 'unique-key-abc' });
    mockedGetPendingTransactions.mockReturnValue([tx]);

    // Első kör: hálózati hiba (a szerver megkapta, de a kliens nem tudja)
    const mockFetch1 = vi.fn().mockRejectedValue(new TypeError('fetch failed'));
    vi.stubGlobal('fetch', mockFetch1);

    const result1 = await engine.syncAll('test-token');
    expect(result1.synced).toBe(0);
    expect(result1.failed).toBe(1);
    expect(mockedMarkTransactionSynced).not.toHaveBeenCalled();

    // Második kör: szerver 409 (már feldolgozta)
    const mockFetch2 = vi.fn().mockResolvedValue({
      ok: false,
      status: 409,
      statusText: 'Conflict',
    });
    vi.stubGlobal('fetch', mockFetch2);

    const result2 = await engine.syncAll('test-token');

    // 409 = failed (szinkronizálatlan marad, kézi beavatkozás kell)
    expect(result2.failed).toBe(1);

    // Ellenőrzés: idempotency key megmaradt
    const fetchCall = mockFetch2.mock.calls[0]!;
    const opts = fetchCall[1] as RequestInit;
    const headers = opts.headers as Record<string, string>;
    expect(headers['Idempotency-Key']).toBe('unique-key-abc');
  });
});

// ═══════════════════════════════════════════
// 5. Szerver válaszidő degradáció
// ═══════════════════════════════════════════

describe('SyncEngine — Szerver lassulás (slow response)', () => {
  let engine: SyncEngine;

  beforeEach(() => {
    vi.resetAllMocks();
    engine = new SyncEngine();
    mockedGetConfig.mockImplementation((key: string) => {
      if (key === 'server_url') return 'http://localhost:8080/api/v1';
      return null;
    });
    resetAllQueues();
  });

  afterEach(() => {
    engine.stop();
    vi.unstubAllGlobals();
  });

  it('Lassú szerver (5s delay) — a sync befejezi, nem timeout-ol 10s-en belül', async () => {
    mockedGetPendingTransactions.mockReturnValue([makeTx(1)]);

    const mockFetch = vi.fn().mockImplementation(async () => {
      await new Promise((resolve) => setTimeout(resolve, 50)); // 50ms szimulált delay
      return { ok: true, json: () => Promise.resolve({ success: true }) };
    });
    vi.stubGlobal('fetch', mockFetch);

    const result = await engine.syncAll('test-token');
    expect(result.synced).toBe(1);
    expect(result.failed).toBe(0);
  });
});

// ═══════════════════════════════════════════
// 6. Multi-entity típus konzisztencia szakadás közben
// ═══════════════════════════════════════════

describe('SyncEngine — Multi-entity hálózati szakadás', () => {
  let engine: SyncEngine;

  beforeEach(() => {
    vi.resetAllMocks();
    engine = new SyncEngine();
    mockedGetConfig.mockImplementation((key: string) => {
      if (key === 'server_url') return 'http://localhost:8080/api/v1';
      return null;
    });
  });

  afterEach(() => {
    engine.stop();
    vi.unstubAllGlobals();
  });

  it('Tranzakciók OK → Konverziók hálózati hiba → a többi entity type is FAIL', async () => {
    mockedGetPendingTransactions.mockReturnValue([makeTx(1), makeTx(2)]);
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
        created_at: '2026-04-03',
        synced: 0,
      },
    ]);
    mockedGetPendingBankTransactions.mockReturnValue([]);
    mockedGetPendingStornos.mockReturnValue([]);
    mockedGetPendingDistributions.mockReturnValue([]);
    mockedGetPendingTransfers.mockReturnValue([]);
    mockedGetPendingCollections.mockReturnValue([]);
    mockedGetPendingHandoverOperations.mockReturnValue([]);

    let callCount = 0;
    const mockFetch = vi.fn().mockImplementation(async () => {
      callCount++;
      if (callCount === 3) {
        // 3. hívás = konverzió → hálózati hiba
        throw new TypeError('fetch failed: ECONNRESET');
      }
      return { ok: true, json: () => Promise.resolve({ success: true }) };
    });
    vi.stubGlobal('fetch', mockFetch);

    const result = await engine.syncAll('test-token');

    // TX 1+2 OK, konverzió FAIL
    expect(result.synced).toBe(2);
    expect(result.failed).toBeGreaterThanOrEqual(1);
    expect(mockedMarkTransactionSynced).toHaveBeenCalledWith(1);
    expect(mockedMarkTransactionSynced).toHaveBeenCalledWith(2);
  });
});

// ═══════════════════════════════════════════
// 7. Queue perzisztencia - engine restart
// ═══════════════════════════════════════════

describe('SyncEngine — Queue perzisztencia engine restart után', () => {
  it('Új engine instance ugyanazokat a pending elemeket látja (SQLite alapú)', async () => {
    const engine1 = new SyncEngine();
    const engine2 = new SyncEngine();

    // Mindkét instance ugyanazt a mock SQLite-ot olvassa
    vi.resetAllMocks();
    mockedGetConfig.mockImplementation((key: string) => {
      if (key === 'server_url') return 'http://localhost:8080/api/v1';
      return null;
    });
    resetAllQueues();

    const items = [makeTx(1), makeTx(2), makeTx(3)];
    mockedGetPendingTransactions.mockReturnValue(items);

    const mockFetch = vi.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ success: true }),
    });
    vi.stubGlobal('fetch', mockFetch);

    // Engine1 szinkronizál
    const result = await engine1.syncAll('test-token');
    expect(result.synced).toBe(3);

    // Engine2 is elindul — SQLite-ból olvassa az adatokat
    // (a mock nem változik, tehát még mindig 3 pending-et lát)
    const result2 = await engine2.syncAll('test-token');
    expect(result2.synced).toBe(3);

    engine1.stop();
    engine2.stop();
    vi.unstubAllGlobals();
  });
});
