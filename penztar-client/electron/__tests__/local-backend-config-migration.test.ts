import { describe, expect, it, vi } from 'vitest';
import {
  applyLocalBackendConfigMigration,
  ensureFk091ArtifactSuccessEnabled,
  FK091_PROPERTY_LINE,
  resolveLocalBackendConfigPath,
} from '../local-backend-config-migration';

describe('ensureFk091ArtifactSuccessEnabled', () => {
  it('nem módosít, ha már true', () => {
    const input = 'jwt.secret=abc\nevening.closing.artifact-success-enabled=true\n';
    const result = ensureFk091ArtifactSuccessEnabled(input);
    expect(result.updated).toBe(false);
    expect(result.config).toBe(input);
  });

  it('false -> true upgrade', () => {
    const input = 'evening.closing.artifact-success-enabled=false\n';
    const result = ensureFk091ArtifactSuccessEnabled(input);
    expect(result.updated).toBe(true);
    expect(result.config).toContain('evening.closing.artifact-success-enabled=true');
    expect(result.config).not.toContain('=false');
  });

  it('hiányzó kulcs -> append', () => {
    const input = 'jwt.secret=abc\n';
    const result = ensureFk091ArtifactSuccessEnabled(input);
    expect(result.updated).toBe(true);
    expect(result.config.endsWith(`${FK091_PROPERTY_LINE}\n`)).toBe(true);
  });

  it('üres fájl -> csak az FK-091 sor', () => {
    const result = ensureFk091ArtifactSuccessEnabled('');
    expect(result.updated).toBe(true);
    expect(result.config).toBe(`${FK091_PROPERTY_LINE}\n`);
  });
});

describe('applyLocalBackendConfigMigration', () => {
  it('win32 + létező config: ír és újraindít', async () => {
    const writeFile = vi.fn();
    const restartBackendService = vi.fn().mockResolvedValue(undefined);
    const log = { info: vi.fn(), warn: vi.fn() };

    await applyLocalBackendConfigMigration({
      platform: 'win32',
      programData: 'C:\\ProgramData',
      readFile: () => 'jwt.secret=abc\n',
      writeFile,
      fileExists: (p) => p === resolveLocalBackendConfigPath('C:\\ProgramData'),
      restartBackendService,
      log,
    });

    expect(writeFile).toHaveBeenCalledOnce();
    expect(restartBackendService).toHaveBeenCalledOnce();
    expect(log.info).toHaveBeenCalledWith(
      expect.stringContaining('[FK-091] Lokális backend config frissítve'),
    );
  });

  it('nem win32: no-op', async () => {
    const writeFile = vi.fn();
    await applyLocalBackendConfigMigration({
      platform: 'linux',
      programData: '/var',
      readFile: () => '',
      writeFile,
      fileExists: () => true,
      restartBackendService: vi.fn(),
      log: { info: vi.fn(), warn: vi.fn() },
    });
    expect(writeFile).not.toHaveBeenCalled();
  });

  it('nincs config fájl: no-op', async () => {
    const writeFile = vi.fn();
    await applyLocalBackendConfigMigration({
      platform: 'win32',
      programData: 'C:\\ProgramData',
      readFile: () => '',
      writeFile,
      fileExists: () => false,
      restartBackendService: vi.fn(),
      log: { info: vi.fn(), warn: vi.fn() },
    });
    expect(writeFile).not.toHaveBeenCalled();
  });
});
