import { afterEach, describe, expect, it, vi } from 'vitest';

vi.mock('vite-plugin-electron', () => {
  throw new Error('A tiszta watch-config import nem töltheti be az Electron plugint.');
});

import path from 'node:path';
import fs from 'node:fs';
import os from 'node:os';
import {
  cleanupLegacyElectronDevAppAsar,
  createElectronDevLaunchArgs,
  createElectronDevServerConfig,
  ELECTRON_DEV_WATCH_IGNORED,
  spawnElectronDevProcess,
} from '../../vite-watch-config';

const sandboxDirs = new Set<string>();

function createSandbox(): string {
  const sandbox = fs.mkdtempSync(path.join(os.tmpdir(), 'electron-dev-cleanup-'));
  sandboxDirs.add(sandbox);
  return sandbox;
}

function createElectronSandboxLayout(sandbox: string): {
  electronExe: string;
  resourcesDir: string;
  legacyAppAsar: string;
  defaultAppAsar: string;
} {
  const electronExe = path.join(sandbox, 'node_modules', 'electron', 'dist', 'electron.exe');
  const resourcesDir = path.join(path.dirname(electronExe), 'resources');

  return {
    electronExe,
    resourcesDir,
    legacyAppAsar: path.join(resourcesDir, 'app.asar'),
    defaultAppAsar: path.join(resourcesDir, 'default_app.asar'),
  };
}

function createNotFoundError(): Error & { code: string } {
  return Object.assign(new Error('not found'), { code: 'ENOENT' as const });
}

function normalizeSlashes(target: string): string {
  return target.replace(/\\/g, '/');
}

function expectNoAbsolutePathLeak(message: string, rootPath: string): void {
  expect(message).not.toContain(rootPath);
}

afterEach(() => {
  for (const sandbox of sandboxDirs) {
    fs.rmSync(sandbox, { recursive: true, force: true });
  }
  sandboxDirs.clear();
});

describe('Vite watcher contract', () => {
  it('pontosan a dev runtime könyvtárakat és a SQLite fájlokat zárja ki', () => {
    expect(typeof createElectronDevServerConfig).toBe('function');
    if (typeof createElectronDevServerConfig !== 'function') {
      throw new Error('A Vite server config nem feloldható tiszta factory.');
    }

    const resolved = createElectronDevServerConfig();
    const ignored = resolved.watch?.ignored;

    expect(ignored).toEqual([
      '**/.dev-user-data/**',
      '**/.dev-app/**',
      '**/local.db',
      '**/local.db-wal',
      '**/local.db-shm',
    ]);
    expect(ignored).toBe(ELECTRON_DEV_WATCH_IGNORED);
  });

  it('a production server config pontosan az exportált mintakészletet használja', () => {
    expect(createElectronDevServerConfig().watch?.ignored).toBe(ELECTRON_DEV_WATCH_IGNORED);
  });

  it('a tiltólista mutációja nem szennyezheti a későbbi factory-hívásokat', () => {
    expect(Object.isFrozen(ELECTRON_DEV_WATCH_IGNORED)).toBe(true);
    expect(() => (ELECTRON_DEV_WATCH_IGNORED as string[]).push('**/.dev-*')).toThrow(TypeError);

    const laterIgnored = createElectronDevServerConfig().watch?.ignored;
    expect(laterIgnored).toBe(ELECTRON_DEV_WATCH_IGNORED);
    expect(laterIgnored).toEqual([
      '**/.dev-user-data/**',
      '**/.dev-app/**',
      '**/local.db',
      '**/local.db-wal',
      '**/local.db-shm',
    ]);
  });
});

describe('Electron dev launcher contract', () => {
  it('az elokeszitett dev appot explicit alkalmazascelkent adja at', () => {
    const tmpAppDir = path.resolve('.dev-app');

    const launchArgs = createElectronDevLaunchArgs(tmpAppDir);

    expect(launchArgs).toEqual([tmpAppDir]);
    expect(launchArgs).not.toContain(path.resolve('node_modules/electron/dist/resources/app.asar'));
  });

  it('torli a stale legacy resources/app.asar fajlt a spawn elott', () => {
    const sandbox = createSandbox();
    const { electronExe, resourcesDir, legacyAppAsar, defaultAppAsar } =
      createElectronSandboxLayout(sandbox);

    fs.mkdirSync(resourcesDir, { recursive: true });
    fs.writeFileSync(legacyAppAsar, 'stale');
    fs.writeFileSync(defaultAppAsar, 'default');

    cleanupLegacyElectronDevAppAsar(electronExe, { projectRoot: sandbox });

    expect(fs.existsSync(legacyAppAsar)).toBe(false);
    expect(fs.readFileSync(defaultAppAsar, 'utf8')).toBe('default');
  });

  it('no-op, ha nincs legacy resources/app.asar fajl', () => {
    const sandbox = createSandbox();
    const { electronExe, resourcesDir, defaultAppAsar } = createElectronSandboxLayout(sandbox);

    fs.mkdirSync(resourcesDir, { recursive: true });
    fs.writeFileSync(defaultAppAsar, 'default');

    expect(() =>
      cleanupLegacyElectronDevAppAsar(electronExe, { projectRoot: sandbox }),
    ).not.toThrow();
    expect(fs.readFileSync(defaultAppAsar, 'utf8')).toBe('default');
  });

  it('platformfuggetlenul csak a project node_modules/electron/dist/electron(.exe) path-ot fogadja el', () => {
    const projectRoot = '/sandbox/project';
    const validLinuxElectronExe = '/sandbox/project/node_modules/electron/dist/electron';
    const invalidElectronExe = '/sandbox/project/random/dist/electron.exe';

    expect(() =>
      cleanupLegacyElectronDevAppAsar(validLinuxElectronExe, {
        projectRoot,
        fsOps: {
          lstatSync: () => {
            throw createNotFoundError();
          },
          unlinkSync: vi.fn(),
        },
      }),
    ).not.toThrow();

    expect(() =>
      cleanupLegacyElectronDevAppAsar(invalidElectronExe, {
        projectRoot,
      }),
    ).toThrow(/Invalid electron executable path/i);
  });

  it('fail-closed modon elutasitja a random dist/electron.exe path-ot path leak nelkul', () => {
    const sandbox = createSandbox();
    const invalidElectronExe = path.join(sandbox, 'random', 'dist', 'electron.exe');

    try {
      cleanupLegacyElectronDevAppAsar(invalidElectronExe, { projectRoot: sandbox });
      throw new Error('A random dist pathnak itt fail-closed modon el kellett volna buknia.');
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      expect(message).toMatch(/Invalid electron executable path/i);
      expect(message).toContain('random/dist/electron.exe');
      expectNoAbsolutePathLeak(message, sandbox);
    }
  });

  it('fail-closed modon nem torol, ha a sibling default_app.asar hianyzik', () => {
    const sandbox = createSandbox();
    const { electronExe, resourcesDir, legacyAppAsar } = createElectronSandboxLayout(sandbox);

    fs.mkdirSync(resourcesDir, { recursive: true });
    fs.writeFileSync(legacyAppAsar, 'stale');

    expect(() => cleanupLegacyElectronDevAppAsar(electronExe, { projectRoot: sandbox })).toThrow(
      /without sibling regular file: resources\/default_app\.asar/i,
    );
    expect(fs.existsSync(legacyAppAsar)).toBe(true);
  });

  it('fail-closed modon nem torol, ha a sibling default_app.asar nem normal fajl', () => {
    const sandbox = createSandbox();
    const { electronExe, resourcesDir, legacyAppAsar, defaultAppAsar } =
      createElectronSandboxLayout(sandbox);

    fs.mkdirSync(resourcesDir, { recursive: true });
    fs.writeFileSync(legacyAppAsar, 'stale');
    fs.mkdirSync(defaultAppAsar, { recursive: true });

    expect(() => cleanupLegacyElectronDevAppAsar(electronExe, { projectRoot: sandbox })).toThrow(
      /without sibling regular file: resources\/default_app\.asar/i,
    );
    expect(fs.existsSync(legacyAppAsar)).toBe(true);
  });

  it('symlink legacy app.asar eseten csak a linket torli, a targethoz nem nyul', () => {
    const sandbox = createSandbox();
    const { electronExe } = createElectronSandboxLayout(sandbox);
    const symlinkTarget = path.join(sandbox, 'kept-target.asar');
    const unlinkCalls: string[] = [];

    cleanupLegacyElectronDevAppAsar(electronExe, {
      projectRoot: sandbox,
      fsOps: {
        lstatSync: (target) => {
          const normalizedTarget = normalizeSlashes(target);
          if (normalizedTarget.endsWith('/resources/app.asar')) {
            return {
              isFile: () => false,
              isSymbolicLink: () => true,
            } as fs.Stats;
          }
          if (normalizedTarget.endsWith('/resources/default_app.asar')) {
            return {
              isFile: () => true,
              isSymbolicLink: () => false,
            } as fs.Stats;
          }
          throw createNotFoundError();
        },
        unlinkSync: (target) => {
          if (target === symlinkTarget) {
            throw new Error('unexpected target delete');
          }
          unlinkCalls.push(target);
        },
      },
    });

    expect(unlinkCalls).toHaveLength(1);
    expect(normalizeSlashes(unlinkCalls[0]).endsWith('/resources/app.asar')).toBe(true);
  });

  it('fail-closed modon hibazik, ha a cleanup nem sikerul', () => {
    const sandbox = createSandbox();
    const { electronExe } = createElectronSandboxLayout(sandbox);

    try {
      cleanupLegacyElectronDevAppAsar(electronExe, {
        projectRoot: sandbox,
        fsOps: {
          lstatSync: (target) => {
            const normalizedTarget = normalizeSlashes(target);
            if (normalizedTarget.endsWith('/resources/app.asar')) {
              return {
                isFile: () => true,
                isSymbolicLink: () => false,
              } as fs.Stats;
            }
            if (normalizedTarget.endsWith('/resources/default_app.asar')) {
              return {
                isFile: () => true,
                isSymbolicLink: () => false,
              } as fs.Stats;
            }
            throw createNotFoundError();
          },
          unlinkSync: () => {
            throw new Error('access denied');
          },
        },
      });
      throw new Error('A cleanup hibának itt fel kellett volna robbannia.');
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      expect(message).toMatch(/Failed to remove legacy Electron dev app\.asar.*access denied/i);
      expect(message).toContain('resources/app.asar');
      expectNoAbsolutePathLeak(message, sandbox);
    }
  });

  it('path leak nelkul hibazik, ha a cleanup-guard a default_app.asar-t sem tudja inspectalni', () => {
    const sandbox = createSandbox();
    const { electronExe } = createElectronSandboxLayout(sandbox);

    try {
      cleanupLegacyElectronDevAppAsar(electronExe, {
        projectRoot: sandbox,
        fsOps: {
          lstatSync: (target) => {
            const normalizedTarget = normalizeSlashes(target);
            if (normalizedTarget.endsWith('/resources/app.asar')) {
              return {
                isFile: () => true,
                isSymbolicLink: () => false,
              } as fs.Stats;
            }
            if (normalizedTarget.endsWith('/resources/default_app.asar')) {
              throw Object.assign(new Error('permission denied'), { code: 'EACCES' as const });
            }
            throw createNotFoundError();
          },
          unlinkSync: vi.fn(),
        },
      });
      throw new Error('A default_app.asar inspect hibának itt fel kellett volna robbannia.');
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      expect(message).toMatch(/Failed to inspect resources\/default_app\.asar: EACCES/i);
      expectNoAbsolutePathLeak(message, sandbox);
    }
  });

  it('a launch helper fail-closed modon blokkolja a spawn-t, ha a cleanup dob', () => {
    const spawnFn = vi.fn();
    const cleanupFn = vi.fn(() => {
      throw new Error('cleanup blocked');
    });

    expect(() =>
      spawnElectronDevProcess({
        electronExe: 'C:/project/node_modules/electron/dist/electron.exe',
        tmpAppDir: 'C:/project/.dev-app',
        devUserData: 'C:/project/.dev-user-data',
        cwd: 'C:/project',
        env: { TEST_ENV: '1' },
        spawnFn,
        cleanupFn,
      }),
    ).toThrow(/cleanup blocked/i);

    expect(cleanupFn).toHaveBeenCalledTimes(1);
    expect(spawnFn).not.toHaveBeenCalled();
  });

  it('a launch helper cleanup utan spawnolja az explicit tmp appot', () => {
    const cleanupFn = vi.fn();
    const spawnFn = vi.fn(() => ({ pid: 1234 }));

    const childProcess = spawnElectronDevProcess({
      electronExe: 'C:/project/node_modules/electron/dist/electron.exe',
      tmpAppDir: 'C:/project/.dev-app',
      devUserData: 'C:/project/.dev-user-data',
      cwd: 'C:/project',
      env: { TEST_ENV: '1' },
      spawnFn,
      cleanupFn,
    });

    expect(childProcess).toEqual({ pid: 1234 });
    expect(cleanupFn).toHaveBeenCalledWith('C:/project/node_modules/electron/dist/electron.exe');
    expect(spawnFn).toHaveBeenCalledWith(
      'C:/project/node_modules/electron/dist/electron.exe',
      ['C:/project/.dev-app'],
      {
        stdio: 'inherit',
        cwd: 'C:/project',
        env: {
          TEST_ENV: '1',
          ELECTRON_RENDERER_URL: 'http://127.0.0.1:3000',
          ELECTRON_DEV_USER_DATA: 'C:/project/.dev-user-data',
        },
      },
    );
  });
});
