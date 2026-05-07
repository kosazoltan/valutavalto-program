import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { EventEmitter } from 'node:events';

const mockState = vi.hoisted(() => ({ userDataDir: '' }));

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
    isEncryptionAvailable: vi.fn(() => true),
    encryptString: vi.fn((value: string) => Buffer.from(`enc:${value}`)),
  },
}));

import { net, safeStorage } from 'electron';
import {
  getWorkers,
  isFirstRun,
  persistBootstrapPasswordConfig,
  resolveBootstrapRoleCodeForAppMode,
  resolveEffectiveBootstrapCredentials,
  selectBootstrapLoginRoleCode,
  shouldUseWorkerFirstTimeSetup,
  type SetupSavePayload,
} from '../first-run';

function writeEnv(content: string): void {
  fs.mkdirSync(mockState.userDataDir, { recursive: true });
  fs.writeFileSync(path.join(mockState.userDataDir, '.env'), content, 'utf8');
}

function validSecret(seed: string): string {
  return seed.repeat(32).slice(0, 64);
}

describe('isFirstRun', () => {
  beforeEach(() => {
    mockState.userDataDir = fs.mkdtempSync(path.join(os.tmpdir(), 'valuta-first-run-'));
  });

  afterEach(() => {
    fs.rmSync(mockState.userDataDir, { recursive: true, force: true });
  });

  it('ujrainditja a wizardot a diagnosztikakban latott stale offline setup allapotnal', () => {
    writeEnv([
      'VITE_API_URL="https://excvaluta.com/api/v1"',
      'JWT_SECRET="' + validSecret('a') + '"',
      'PENZTAR_BOOTSTRAP_WORKER_CODE=""',
      'PENZTAR_BOOTSTRAP_PASSWORD=""',
      'SETUP_COMPLETED=1',
      'SETUP_OFFLINE_MODE=1',
      '',
    ].join('\n'));

    expect(isFirstRun()).toMatchObject({
      isFirstRun: true,
      reason: 'stale-offline-setup',
    });
  });

  it('ujrainditja a wizardot, ha a regi .env csak csupasz https:// URL-t tartalmaz', () => {
    writeEnv([
      'VITE_API_URL="https://"',
      'JWT_SECRET="' + validSecret('b') + '"',
      'SETUP_COMPLETED=1',
      'SETUP_OFFLINE_MODE=0',
      '',
    ].join('\n'));

    expect(isFirstRun()).toMatchObject({
      isFirstRun: true,
      reason: 'api-url-invalid',
    });
  });

  it('nem futtatja ujra a wizardot egy ervenyes online setup utan', () => {
    writeEnv([
      'VITE_API_URL="https://excvaluta.com/api/v1"',
      'JWT_SECRET="' + validSecret('c') + '"',
      'SETUP_COMPLETED=1',
      'SETUP_OFFLINE_MODE=0',
      '',
    ].join('\n'));

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
});

describe('persistBootstrapPasswordConfig', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.mocked(safeStorage.isEncryptionAvailable).mockReturnValue(true);
    vi.mocked(safeStorage.encryptString).mockImplementation((value: string) => Buffer.from(`enc:${value}`));
  });

  it('encrypted configba menti a bootstrap jelszot es torli a plaintext fallbackot', () => {
    const setConfig = vi.fn();
    const deleteConfig = vi.fn();

    persistBootstrapPasswordConfig('NewGlobalPass123', setConfig, deleteConfig);

    expect(setConfig).toHaveBeenCalledWith(
      'bootstrap_password_encrypted',
      Buffer.from('enc:NewGlobalPass123').toString('base64'),
    );
    expect(deleteConfig).toHaveBeenCalledWith('bootstrap_password');
  });

  it('safeStorage hianyaban ideiglenes plaintext fallbackot ment a sync bootstraphoz', () => {
    const setConfig = vi.fn();
    const deleteConfig = vi.fn();
    vi.mocked(safeStorage.isEncryptionAvailable).mockReturnValue(false);

    persistBootstrapPasswordConfig('NewGlobalPass123', setConfig, deleteConfig);

    expect(setConfig).toHaveBeenCalledWith('bootstrap_password', 'NewGlobalPass123');
    expect(deleteConfig).toHaveBeenCalledWith('bootstrap_password_encrypted');
  });

  it('fallback mentesi hiba eseten nem torli a korabbi encrypted bootstrap titkot', () => {
    const setConfig = vi.fn(() => {
      throw new Error('sqlite locked');
    });
    const deleteConfig = vi.fn();
    vi.mocked(safeStorage.isEncryptionAvailable).mockReturnValue(false);

    persistBootstrapPasswordConfig('NewGlobalPass123', setConfig, deleteConfig);

    expect(deleteConfig).not.toHaveBeenCalledWith('bootstrap_password_encrypted');
  });
});

describe('resolveBootstrapRoleCodeForAppMode', () => {
  it('az appMode-hoz illeszkedo canonical role code-ot irja ki bootstrap role-kent', () => {
    expect(resolveBootstrapRoleCodeForAppMode('penztar')).toBe('penztar');
    expect(resolveBootstrapRoleCodeForAppMode('ertektar')).toBe('ertektar');
    expect(resolveBootstrapRoleCodeForAppMode('ertekszallito')).toBe('ertekszallito');
  });

  it('hianyzo appMode eseten penztar role-ra esik vissza', () => {
    expect(resolveBootstrapRoleCodeForAppMode(undefined)).toBe('penztar');
  });
});

describe('selectBootstrapLoginRoleCode', () => {
  it('tobb role eseten az appMode-hoz illo role-t valasztja setup loginhoz', () => {
    expect(selectBootstrapLoginRoleCode('penztar', ['ertektar', 'penztar'])).toBe('penztar');
    expect(selectBootstrapLoginRoleCode('ertektar', ['penztar', 'ertektar'])).toBe('ertektar');
    expect(selectBootstrapLoginRoleCode('ertekszallito', ['COURIER'])).toBe('COURIER');
  });

  it('ertekszallito modban a canonical role-t preferalja a legacy courier fallback elott', () => {
    expect(selectBootstrapLoginRoleCode('ertekszallito', ['COURIER', 'ertekszallito'])).toBe('ertekszallito');
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
    expect(shouldUseWorkerFirstTimeSetup({
      offlineMode: false,
      selectedWorkerCode: 'BORSI',
      bootstrapUsername: 'BORSI',
      bootstrapCompleted: false,
    })).toBe(true);
  });

  it('lezart bootstrap es manualisan beirt worker kod eseten nem esik vissza legacy admin bootstrapra', () => {
    expect(shouldUseWorkerFirstTimeSetup({
      offlineMode: false,
      bootstrapUsername: 'BORSI',
      bootstrapCompleted: true,
    })).toBe(true);
  });

  it('nyitott bootstrap es manualis kod eseten megtartja a legacy admin bootstrap utat', () => {
    expect(shouldUseWorkerFirstTimeSetup({
      offlineMode: false,
      bootstrapUsername: 'ADMIN',
      bootstrapCompleted: false,
    })).toBe(false);
  });

  it('offline modban nem indit backend worker setupot', () => {
    expect(shouldUseWorkerFirstTimeSetup({
      offlineMode: true,
      selectedWorkerCode: 'BORSI',
      bootstrapCompleted: true,
    })).toBe(false);
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
