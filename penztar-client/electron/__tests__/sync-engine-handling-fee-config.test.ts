/**
 * FK-097 WU-13 — syncHandlingFeeConfig a 30 s szinkron-ciklusban (FR-2/FR-8).
 *
 * A sync-engine.test.ts:9-70 mock-preambulumának mintájára:
 * - fetch sikeres → saveCachedHandlingFeeConfig a leképezett sorral;
 * - 401 → token törlés, írás nélkül;
 * - hálózati hiba → warn, nem dob, a későbbi tickek tovább futnak;
 * - FR-8 kliens-oldali védelem: a DRAFT státuszú payload írása VISSZAUTASÍTVA
 *   (a szerver sosem ad DRAFT-ot az /own-ra — ez második védelmi vonal).
 */
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';

const mockLog = vi.hoisted(() => ({ warn: vi.fn(), info: vi.fn(), error: vi.fn() }));

vi.mock('electron-log', () => ({ default: mockLog }));
vi.mock('electron-log/main', () => ({ default: mockLog }));

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
  net: { request: vi.fn() },
  IncomingMessage: class {},
}));

vi.mock('../sqlite', () => ({
  getConfig: vi.fn(() => null),
  setConfig: vi.fn(),
  deleteConfig: vi.fn(),
  getDb: vi.fn(() => ({})),
  saveDatabase: vi.fn(),
  saveCachedHandlingFeeConfig: vi.fn(),
}));

import { SyncEngine } from '../sync-engine';
import { getConfig, deleteConfig, getDb, saveCachedHandlingFeeConfig } from '../sqlite';

const mockedGetConfig = vi.mocked(getConfig);
const mockedDeleteConfig = vi.mocked(deleteConfig);
const mockedGetDb = vi.mocked(getDb);
const mockedSave = vi.mocked(saveCachedHandlingFeeConfig);

const LIVE_RESPONSE = {
  branchId: 'branch-1',
  branchCode: '105',
  feeMode: 'PER_MILLE' as const,
  perMilleRate: 3.5,
  perMilleCap: 2000,
  validFrom: '2026-08-26',
  brackets: [{ bracketOrder: 1, upperLimit: 10000, feeAmount: 300, active: true }],
};

describe('SyncEngine.syncHandlingFeeConfig (FK-097)', () => {
  let engine: SyncEngine;
  let mockFetch: ReturnType<typeof vi.fn>;

  beforeEach(() => {
    vi.clearAllMocks();
    mockedGetConfig.mockImplementation((key: string) => {
      if (key === 'server_url') return 'http://localhost:8080/api/v1';
      if (key === 'auth_token') return 'test-token';
      if (key === 'offline_mode') return '';
      return null;
    });
    mockedGetDb.mockReturnValue({} as never);
    mockFetch = vi.fn();
    vi.stubGlobal('fetch', mockFetch);
    engine = new SyncEngine();
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('sikeres szinkron: fetch az /branch-fee-config/own-ra, majd a leképezett sor mentése', async () => {
    mockFetch.mockResolvedValue({ ok: true, json: async () => LIVE_RESPONSE });

    await engine.syncHandlingFeeConfig();

    const url = mockFetch.mock.calls[0]![0];
    expect(url).toBe('http://localhost:8080/api/v1/branch-fee-config/own');
    expect(mockedSave).toHaveBeenCalledTimes(1);
    expect(mockedSave).toHaveBeenCalledWith({
      branch_id: 'branch-1',
      branch_code: '105',
      company_id: null,
      fee_mode: 'PER_MILLE',
      per_mille_rate: 3.5,
      per_mille_cap: 2000,
      bracket_json: JSON.stringify(LIVE_RESPONSE.brackets),
      valid_from: '2026-08-26',
    });
  });

  it('401 → token törlés, írás NÉLKÜL', async () => {
    mockFetch.mockResolvedValue({ ok: false, status: 401, statusText: 'Unauthorized' });

    await engine.syncHandlingFeeConfig();

    expect(mockedDeleteConfig).toHaveBeenCalledWith('auth_token_encrypted');
    expect(mockedDeleteConfig).toHaveBeenCalledWith('auth_token');
    expect(mockedSave).not.toHaveBeenCalled();
    expect(mockLog.warn).toHaveBeenCalled();
  });

  it('hálózati hiba → warn, nem dob, a későbbi tickek tovább futnak', async () => {
    mockFetch.mockRejectedValue(new TypeError('fetch failed'));

    await expect(engine.syncHandlingFeeConfig()).resolves.toBeUndefined();

    expect(mockLog.warn).toHaveBeenCalled();
    expect(mockedSave).not.toHaveBeenCalled();

    // A következő tick (hibajavítás után) újra működik — a motor nem kerül holtállapotba.
    mockFetch.mockResolvedValue({ ok: true, json: async () => LIVE_RESPONSE });
    await engine.syncHandlingFeeConfig();
    expect(mockedSave).toHaveBeenCalledTimes(1);
  });

  it('FR-8: DRAFT státuszú payload írása VISSZAUTASÍTVA (második védelmi vonal)', async () => {
    mockFetch.mockResolvedValue({
      ok: true,
      json: async () => ({ ...LIVE_RESPONSE, status: 'DRAFT' }),
    });

    await engine.syncHandlingFeeConfig();

    expect(mockedSave).not.toHaveBeenCalled();
    expect(mockLog.warn).toHaveBeenCalled();
  });
});
