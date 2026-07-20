import { describe, expect, it, vi } from 'vitest';

vi.mock('vite-plugin-electron', () => {
  throw new Error('A tiszta watch-config import nem töltheti be az Electron plugint.');
});

import path from 'node:path';
import {
  createElectronDevLaunchArgs,
  createElectronDevServerConfig,
  ELECTRON_DEV_WATCH_IGNORED,
} from '../../vite-watch-config';

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
});
