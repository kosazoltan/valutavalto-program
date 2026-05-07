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

import { safeStorage } from 'electron';
import {
  isFirstRun,
  persistBootstrapPasswordConfig,
  resolveEffectiveBootstrapCredentials,
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
    vi.mocked(safeStorage.encryptString).mockClear();
    vi.mocked(safeStorage.isEncryptionAvailable).mockClear();
  });

  it('titkositva menti a bootstrap jelszot SQLite configba, ha safeStorage elerheto', () => {
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
});
