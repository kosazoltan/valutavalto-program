import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { EventEmitter } from 'node:events';

const mockState = vi.hoisted(() => ({
  userDataDir: '',
  safeStorageEncryptionAvailable: true,
}));

vi.mock('electron-log/main', () => ({
  default: { warn: vi.fn(), info: vi.fn(), error: vi.fn() },
}));

vi.mock('electron', () => ({
  app: {
    getPath: vi.fn(() => mockState.userDataDir),
  },
  net: {
    request: vi.fn(() => {
      const request = new EventEmitter() as EventEmitter & {
        setHeader: ReturnType<typeof vi.fn>;
        write: ReturnType<typeof vi.fn>;
        end: ReturnType<typeof vi.fn>;
        abort: ReturnType<typeof vi.fn>;
      };
      request.setHeader = vi.fn();
      request.write = vi.fn();
      request.end = vi.fn();
      request.abort = vi.fn();
      return request;
    }),
  },
  safeStorage: {
    isEncryptionAvailable: vi.fn(() => mockState.safeStorageEncryptionAvailable),
    encryptString: vi.fn((value: string) => Buffer.from(`encrypted:${value}`)),
  },
}));

import { net, safeStorage } from 'electron';
import {
  DEFAULT_BRANCHES,
  assertSetupAllowed,
  fetchBranchesFromBackend,
  getBranches,
  getWorkers,
  isFirstRun,
  persistBootstrapPasswordConfig,
  resolveBootstrapRoleCodeForAppMode,
  resolveEffectiveBootstrapCredentials,
  selectBootstrapLoginRoleCode,
  saveSetupConfig,
  shouldUseWorkerFirstTimeSetup,
  testConnection,
  type SetupSavePayload,
} from '../first-run';

function writeEnv(content: string): void {
  fs.mkdirSync(mockState.userDataDir, { recursive: true });
  fs.writeFileSync(path.join(mockState.userDataDir, '.env'), content, 'utf8');
}

function validSecret(seed: string): string {
  return seed.repeat(32).slice(0, 64);
}

function mockHttpResponse(statusCode: number): void {
  vi.mocked(net.request).mockImplementationOnce(() => {
    const request = new EventEmitter() as EventEmitter & {
      setHeader: ReturnType<typeof vi.fn>;
      write: ReturnType<typeof vi.fn>;
      end: ReturnType<typeof vi.fn>;
      abort: ReturnType<typeof vi.fn>;
    };
    request.setHeader = vi.fn();
    request.write = vi.fn();
    request.abort = vi.fn();
    request.end = vi.fn(() => {
      const response = new EventEmitter() as EventEmitter & {
        statusCode: number;
        headers: Record<string, string>;
      };
      response.statusCode = statusCode;
      response.headers = { 'content-type': 'application/json' };
      queueMicrotask(() => {
        request.emit('response', response);
        response.emit('data', Buffer.from('{}'));
        response.emit('end');
      });
    });
    return request;
  });
}

describe('setup IPC guards', () => {
  beforeEach(() => {
    mockState.userDataDir = fs.mkdtempSync(path.join(os.tmpdir(), 'valuta-setup-guard-'));
    vi.clearAllMocks();
  });

  afterEach(() => {
    fs.rmSync(mockState.userDataDir, { recursive: true, force: true });
  });

  it('blocks setup IPC after provisioning and allows it during first run', () => {
    expect(() => assertSetupAllowed({ isFirstRun: false, envPath: 'x' })).toThrow(
      /setup IPC blokkolva/,
    );
    expect(() =>
      assertSetupAllowed({ isFirstRun: true, envPath: 'x', reason: 'env-missing' }),
    ).not.toThrow();
  });

  it('rejects a non-allowlisted test URL before any network request', async () => {
    await expect(
      testConnection('https://evil.example/api', 'EBC', 'USER', 'password'),
    ).resolves.toMatchObject({ success: false, errorMessage: expect.stringMatching(/allowlist/i) });
    expect(net.request).not.toHaveBeenCalled();
  });

  it.each(['https://excvaluta.com', 'http://192.168.1.50:8080'])(
    'allows `%s` to reach the request path',
    async (apiUrl) => {
      mockHttpResponse(401);
      await testConnection(apiUrl, 'EBC', 'USER', 'password');
      expect(net.request).toHaveBeenCalledTimes(1);
    },
  );

  it('uses the static branch fallback for a non-allowlisted URL without a network request', async () => {
    await expect(getBranches('https://evil.example', 'EBC')).resolves.toEqual(DEFAULT_BRANCHES);
    expect(net.request).not.toHaveBeenCalled();
  });

  it('returns no workers for a non-allowlisted URL without a network request', async () => {
    await expect(getWorkers('https://evil.example', 'EBC', 'B001')).resolves.toEqual([]);
    expect(net.request).not.toHaveBeenCalled();
  });

  it('rejects a non-allowlisted branch fetch before any network request', async () => {
    await expect(fetchBranchesFromBackend('https://evil.example', 'EBC')).rejects.toThrow(
      /allowlist/i,
    );
    expect(net.request).not.toHaveBeenCalled();
  });

  it('allows an allowlisted branch URL to reach the request path', async () => {
    mockHttpResponse(200);
    await getBranches('https://excvaluta.com', 'EBC');
    expect(net.request).toHaveBeenCalledTimes(1);
  });

  it('rejects a non-allowlisted online setup URL without writing .env', async () => {
    await expect(
      saveSetupConfig(setupPayload({ apiUrl: 'https://evil.example' })),
    ).resolves.toMatchObject({
      success: false,
      errorMessage: expect.stringMatching(/allowlist/i),
    });
    expect(fs.existsSync(path.join(mockState.userDataDir, '.env'))).toBe(false);
  });

  it('skips the apiUrl allowlist check in offline mode', async () => {
    const result = await saveSetupConfig(
      setupPayload({ apiUrl: 'https://evil.example', offlineMode: true, adminPassword: '' }),
    );

    expect(result.errorMessage ?? '').not.toMatch(/allowlist/i);
    expect(result).toMatchObject({
      success: false,
      errorMessage: 'Az admin jelszónak legalább 8 karakteresnek kell lennie.',
    });
  });
});

describe('isFirstRun', () => {
  beforeEach(() => {
    mockState.userDataDir = fs.mkdtempSync(path.join(os.tmpdir(), 'valuta-first-run-'));
  });

  afterEach(() => {
    fs.rmSync(mockState.userDataDir, { recursive: true, force: true });
  });

  it('ujrainditja a wizardot a diagnosztikakban latott stale offline setup allapotnal', () => {
    writeEnv(
      [
        'VITE_API_URL="https://excvaluta.com/api/v1"',
        'JWT_SECRET="' + validSecret('a') + '"',
        'PENZTAR_BOOTSTRAP_WORKER_CODE=""',
        'PENZTAR_BOOTSTRAP_PASSWORD=""',
        'SETUP_COMPLETED=1',
        'SETUP_OFFLINE_MODE=1',
        '',
      ].join('\n'),
    );

    expect(isFirstRun()).toMatchObject({
      isFirstRun: true,
      reason: 'stale-offline-setup',
    });
  });

  it('ujrainditja a wizardot, ha a regi .env csak csupasz https:// URL-t tartalmaz', () => {
    writeEnv(
      [
        'VITE_API_URL="https://"',
        'JWT_SECRET="' + validSecret('b') + '"',
        'SETUP_COMPLETED=1',
        'SETUP_OFFLINE_MODE=0',
        '',
      ].join('\n'),
    );

    expect(isFirstRun()).toMatchObject({
      isFirstRun: true,
      reason: 'api-url-invalid',
    });
  });

  it('nem futtatja ujra a wizardot egy ervenyes online setup utan', () => {
    writeEnv(
      [
        'VITE_API_URL="https://excvaluta.com/api/v1"',
        'JWT_SECRET="' + validSecret('c') + '"',
        'SETUP_COMPLETED=1',
        'SETUP_OFFLINE_MODE=0',
        '',
      ].join('\n'),
    );

    expect(isFirstRun()).toMatchObject({
      isFirstRun: false,
    });
  });
});

function setupPayload(overrides: Partial<SetupSavePayload> = {}): SetupSavePayload {
  return {
    branchCode: 'KORUT',
    branchName: 'Korut',
    apiUrl: 'https://excvaluta.com/api/v1',
    companyCode: 'EBC',
    adminUsername: 'ADMIN',
    adminPassword: 'NewGlobalPass123',
    bootstrapUsername: 'BORSI',
    bootstrapPassword: 'seed-1234',
    offlineMode: false,
    appMode: 'penztar',
    ...overrides,
  };
}

describe('resolveEffectiveBootstrapCredentials', () => {
  beforeEach(() => {
    mockState.safeStorageEncryptionAvailable = true;
  });

  it('worker-first-time setup után az új globális jelszót perzisztálja, nem a kezdő jelszót', () => {
    const result = resolveEffectiveBootstrapCredentials(
      setupPayload({ selectedWorkerCode: 'BORSI' }),
      { workerCode: 'BORSI' },
    );

    expect(result).toEqual({
      bootstrapUsername: 'BORSI',
      bootstrapPassword: 'NewGlobalPass123',
    });
  });

  it('legacy bootstrap-admin úton az admin user új jelszavát perzisztálja', () => {
    const result = resolveEffectiveBootstrapCredentials(
      setupPayload({ bootstrapUsername: '', bootstrapPassword: '' }),
      { workerCode: 'ADMIN' },
    );

    expect(result).toEqual({
      bootstrapUsername: 'ADMIN',
      bootstrapPassword: 'NewGlobalPass123',
    });
  });

  it('legacy bootstrap-admin rerun eseten megtartja a jelenlegi bootstrap jelszot', () => {
    const result = resolveEffectiveBootstrapCredentials(
      setupPayload({
        adminPassword: 'NewButNotApplied123',
        bootstrapUsername: 'ADMIN',
        bootstrapPassword: 'ExistingPassword123',
      }),
      { workerCode: 'ADMIN' },
      { preserveExistingPassword: true },
    );

    expect(result).toEqual({
      bootstrapUsername: 'ADMIN',
      bootstrapPassword: 'ExistingPassword123',
    });
  });
});

describe('persistBootstrapPasswordConfig', () => {
  beforeEach(() => {
    mockState.safeStorageEncryptionAvailable = true;
    vi.clearAllMocks();
    vi.mocked(safeStorage.isEncryptionAvailable).mockImplementation(
      () => mockState.safeStorageEncryptionAvailable,
    );
    vi.mocked(safeStorage.encryptString).mockImplementation((value: string) =>
      Buffer.from(`encrypted:${value}`),
    );
  });

  it('encrypted configba menti a bootstrap jelszot es torli a plaintext fallbackot', () => {
    const setConfig = vi.fn();
    const deleteConfig = vi.fn();

    persistBootstrapPasswordConfig('NewGlobalPass123', setConfig, deleteConfig);

    expect(setConfig).toHaveBeenCalledWith(
      'bootstrap_password_encrypted',
      Buffer.from('encrypted:NewGlobalPass123').toString('base64'),
    );
    expect(deleteConfig).toHaveBeenCalledWith('bootstrap_password');
    expect(setConfig).not.toHaveBeenCalledWith('bootstrap_password', expect.any(String));
  });

  it('safeStorage hianyaban ideiglenes plaintext fallbackot ment a sync bootstraphoz', () => {
    const setConfig = vi.fn();
    const deleteConfig = vi.fn();
    mockState.safeStorageEncryptionAvailable = false;

    persistBootstrapPasswordConfig('NewGlobalPass123', setConfig, deleteConfig);

    expect(setConfig).toHaveBeenCalledWith('bootstrap_password', 'NewGlobalPass123');
    expect(deleteConfig).toHaveBeenCalledWith('bootstrap_password_encrypted');
  });

  it('fallback mentesi hiba eseten nem torli a korabbi encrypted bootstrap titkot', () => {
    const setConfig = vi.fn(() => {
      throw new Error('sqlite locked');
    });
    const deleteConfig = vi.fn();
    mockState.safeStorageEncryptionAvailable = false;

    persistBootstrapPasswordConfig('NewGlobalPass123', setConfig, deleteConfig);

    expect(deleteConfig).not.toHaveBeenCalledWith('bootstrap_password_encrypted');
  });
});

describe('resolveBootstrapRoleCodeForAppMode', () => {
  it('az appMode-hoz illeszkedo canonical role code-ot irja ki bootstrap role-kent', () => {
    expect(resolveBootstrapRoleCodeForAppMode('penztar')).toBe('penztar');
    expect(resolveBootstrapRoleCodeForAppMode('ertektar')).toBe('ertektar');
  });

  it('kivezetett vagy ismeretlen appMode eseten legacy CASHIER fallbacket ad', () => {
    expect(resolveBootstrapRoleCodeForAppMode('ertekszallito')).toBe('CASHIER');
    expect(resolveBootstrapRoleCodeForAppMode('unknown')).toBe('CASHIER');
  });

  it('hianyzo appMode eseten megtartja a legacy CASHIER bootstrap role-t', () => {
    expect(resolveBootstrapRoleCodeForAppMode(undefined)).toBe('CASHIER');
  });

  it('full appMode eseten server oldali canonical role-t ir bootstrap role-kent', () => {
    expect(resolveBootstrapRoleCodeForAppMode('full')).toBe('ugyvezeto');
  });
});

describe('selectBootstrapLoginRoleCode', () => {
  it('tobb role eseten az appMode-hoz illo role-t valasztja setup loginhoz', () => {
    expect(selectBootstrapLoginRoleCode('penztar', ['ertektar', 'penztar'])).toBe('penztar');
    expect(selectBootstrapLoginRoleCode('ertektar', ['penztar', 'ertektar'])).toBe('ertektar');
  });

  it('courier role-t nem valaszt penztar bootstrap loginhoz', () => {
    expect(selectBootstrapLoginRoleCode('penztar', ['COURIER'])).toBeNull();
  });

  it('lokalis appban server role-lal is tud setup device regisztraciot folytatni', () => {
    expect(selectBootstrapLoginRoleCode('penztar', ['foertektar'])).toBe('foertektar');
    expect(selectBootstrapLoginRoleCode('ertektar', ['ADMIN'])).toBe('ADMIN');
    expect(selectBootstrapLoginRoleCode('penztar', ['admin'])).toBe('admin');
  });

  it('nem valaszt masik lokalis apphoz tartozo role-t', () => {
    expect(selectBootstrapLoginRoleCode('penztar', ['ertektar'])).toBeNull();
  });
});

describe('shouldUseWorkerFirstTimeSetup', () => {
  it('kivalasztott worker eseten mindig worker first-time setupot hasznal online modban', () => {
    expect(
      shouldUseWorkerFirstTimeSetup({
        offlineMode: false,
        selectedWorkerCode: 'BORSI',
        bootstrapUsername: 'BORSI',
        bootstrapCompleted: false,
      }),
    ).toBe(true);
  });

  it('lezart bootstrap es manualisan beirt worker kod eseten nem esik vissza legacy admin bootstrapra', () => {
    expect(
      shouldUseWorkerFirstTimeSetup({
        offlineMode: false,
        bootstrapUsername: 'BORSI',
        bootstrapCompleted: true,
      }),
    ).toBe(true);
  });

  it('nyitott bootstrap es manualis kod eseten megtartja a legacy admin bootstrap utat', () => {
    expect(
      shouldUseWorkerFirstTimeSetup({
        offlineMode: false,
        bootstrapUsername: 'ADMIN',
        bootstrapCompleted: false,
      }),
    ).toBe(false);
  });

  it('offline modban nem indit backend worker setupot', () => {
    expect(
      shouldUseWorkerFirstTimeSetup({
        offlineMode: true,
        selectedWorkerCode: 'BORSI',
        bootstrapCompleted: true,
      }),
    ).toBe(false);
  });
});

describe('getWorkers', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('nem indit backend worker lekerest hianyzo cegkodnal', async () => {
    await expect(getWorkers('https://excvaluta.com/api/v1', '   ', 'KORUT')).resolves.toEqual([]);

    expect(net.request).not.toHaveBeenCalled();
  });

  it('nem indit backend worker lekerest hianyzo fiokkodnal', async () => {
    await expect(getWorkers('https://excvaluta.com/api/v1', 'EBC', '   ')).resolves.toEqual([]);

    expect(net.request).not.toHaveBeenCalled();
  });
});
