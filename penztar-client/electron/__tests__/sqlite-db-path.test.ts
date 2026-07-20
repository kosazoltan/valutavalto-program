import { randomUUID } from 'node:crypto';
import { existsSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { describe, expect, it, vi } from 'vitest';

vi.mock('electron', () => ({
  app: {
    getPath: vi.fn(() => 'C:\\Users\\test-user'),
    getAppPath: vi.fn(() => 'C:\\app'),
    isPackaged: false,
  },
}));

import { ensureDatabaseDirectory, resolveDatabasePath } from '../sqlite';

describe('resolveDatabasePath', () => {
  const homeDir = path.resolve('C:\\Users\\test-user');
  const productionDatabasePath = path.join(homeDir, '.valuta', 'local.db');

  it('override nélkül pontosan a production home/.valuta/local.db útvonalat adja', () => {
    expect(resolveDatabasePath(homeDir, {}, false)).toBe(productionDatabasePath);
  });

  it('packaged módban figyelmen kívül hagy minden dev override-ot', () => {
    expect(
      resolveDatabasePath(
        homeDir,
        {
          ELECTRON_DEV_USER_DATA: path.resolve('C:\\temp\\valuta-electron-profile'),
        },
        true,
      ),
    ).toBe(productionDatabasePath);
  });

  it('non-packaged módban az Electron dev profil alatt tartja a local.db fájlt', () => {
    const isolatedProfile = path.resolve('C:\\temp\\valuta-electron-profile');

    expect(resolveDatabasePath(homeDir, { ELECTRON_DEV_USER_DATA: isolatedProfile }, false)).toBe(
      path.join(isolatedProfile, 'local.db'),
    );
  });

  it.each([
    ['üres', ''],
    ['csak whitespace', '   '],
    ['relatív', 'relative\\db'],
    ['meghajtó gyökér', path.parse(homeDir).root],
  ])('fail-closed hibát ad %s dev override esetén', (_label, override) => {
    expect(() => resolveDatabasePath(homeDir, { ELECTRON_DEV_USER_DATA: override }, false)).toThrow(
      /ELECTRON_DEV_USER_DATA/,
    );
  });

  it.each([
    ['Windows namespace', '\\\\?\\C:\\Windows\\System32'],
    ['Windows device', '\\\\.\\C:\\Windows'],
    ['sima UNC', '\\\\server\\share\\valuta'],
    ['Windows namespace előre perjeles alak', '//?/C:/Windows/System32'],
    ['Windows device előre perjeles alak', '//./C:/Windows'],
    ['ponttal végződő szegmens', 'C:\\Windows.'],
    ['szóközzel végződő szegmens', 'C:\\Windows '],
  ])('elutasítja a Win32 által veszélyesen normalizálható %s útvonalat', (_label, override) => {
    expect(() => resolveDatabasePath(homeDir, { ELECTRON_DEV_USER_DATA: override }, false)).toThrow(
      /ELECTRON_DEV_USER_DATA/,
    );
  });

  it.each([
    ['TAB + namespace', `\t\\\\?\\C:\\Windows\\System32`],
    ['TAB + device', `\t\\\\.\\C:\\Windows`],
    ['LF + namespace', `\n\\\\?\\C:\\Windows\\System32`],
    ['LF + device', `\n\\\\.\\C:\\Windows`],
    ['CR + namespace', `\r\\\\?\\C:\\Windows\\System32`],
    ['CR + device', `\r\\\\.\\C:\\Windows`],
    ['FF + namespace', `\f\\\\?\\C:\\Windows\\System32`],
    ['FF + device', `\f\\\\.\\C:\\Windows`],
    ['VT + namespace', `\v\\\\?\\C:\\Windows\\System32`],
    ['VT + device', `\v\\\\.\\C:\\Windows`],
    ['normál szóköz + namespace', ` \\\\?\\C:\\Windows\\System32`],
    ['normál szóköz + device', ` \\\\.\\C:\\Windows`],
  ])('elutasítja a vezető %s prefixet', (_label, override) => {
    expect(() => resolveDatabasePath(homeDir, { ELECTRON_DEV_USER_DATA: override }, false)).toThrow(
      /ELECTRON_DEV_USER_DATA/,
    );
  });

  it('engedélyez egy normál, nem létező abszolút dev profilútvonalat', () => {
    const safeNonExistingPath = path
      .join(os.tmpdir(), `valuta-safe-${randomUUID()}`)
      .replaceAll('\\', '/');

    expect(path.isAbsolute(safeNonExistingPath)).toBe(true);
    expect(existsSync(safeNonExistingPath)).toBe(false);

    expect(
      resolveDatabasePath(homeDir, { ELECTRON_DEV_USER_DATA: safeNonExistingPath }, false),
    ).toBe(path.join(path.resolve(safeNonExistingPath), 'local.db'));
  });

  it('normalizálja és engedélyezi az exact pont szegmenst egy biztonságos abszolút útvonalban', () => {
    const systemRoot = path.resolve('C:\\Windows');
    const safeRoot = path.resolve(os.tmpdir(), `valuta-dot-${randomUUID()}`);
    const override = `${safeRoot}${path.sep}.${path.sep}profile`;

    expect(
      resolveDatabasePath(
        homeDir,
        { ELECTRON_DEV_USER_DATA: override, SystemRoot: systemRoot },
        false,
      ),
    ).toBe(path.join(path.resolve(override), 'local.db'));
  });

  it('normalizálja és engedélyezi az exact dupla pont szegmenst egy biztonságos abszolút útvonalban', () => {
    const systemRoot = path.resolve('C:\\Windows');
    const safeRoot = path.resolve(os.tmpdir(), `valuta-dotdot-${randomUUID()}`);
    const override = `${safeRoot}${path.sep}child${path.sep}..${path.sep}profile`;

    expect(
      resolveDatabasePath(
        homeDir,
        { ELECTRON_DEV_USER_DATA: override, SystemRoot: systemRoot },
        false,
      ),
    ).toBe(path.join(path.resolve(override), 'local.db'));
  });

  it('továbbra is elutasítja a ponttal végződő normál útvonalszegmenst', () => {
    const systemRoot = path.resolve('C:\\Windows');
    const safeRoot = path.resolve(os.tmpdir(), `valuta-trailing-dot-${randomUUID()}`);
    const override = `${safeRoot}${path.sep}foo.`;

    expect(() =>
      resolveDatabasePath(
        homeDir,
        { ELECTRON_DEV_USER_DATA: override, SystemRoot: systemRoot },
        false,
      ),
    ).toThrow(/ponttal vagy szóközzel/);
  });

  it('a dupla pont normalizálása után is elutasítja a SystemRoot alá feloldódó útvonalat', () => {
    const systemRoot = path.resolve('C:\\Windows');
    const override = `${systemRoot}${path.sep}child${path.sep}..${path.sep}System32`;

    expect(() =>
      resolveDatabasePath(
        homeDir,
        { ELECTRON_DEV_USER_DATA: override, SystemRoot: systemRoot },
        false,
      ),
    ).toThrow(/védett rendszerkönyvtár/);
  });

  const protectedRoots = [
    ['SystemRoot', path.resolve('C:\\Windows')],
    ['ProgramFiles', path.resolve('D:\\Program Files')],
    ['ProgramFiles(x86)', path.resolve('D:\\Program Files (x86)')],
    ['ProgramData', path.resolve('E:\\ProgramData')],
  ] as const;

  it('SystemRoot és SystemDrive nélkül is elutasítja a fallback C:\\Windows könyvtárat', () => {
    const windowsRoot = path.resolve('C:\\Windows');

    expect(() =>
      resolveDatabasePath(homeDir, { ELECTRON_DEV_USER_DATA: windowsRoot }, false),
    ).toThrow(/védett rendszerkönyvtár/);
  });

  it('SystemRoot nélkül a megadott SystemDrive Windows könyvtárát védi', () => {
    const windowsRoot = path.resolve('D:\\Windows');

    expect(() =>
      resolveDatabasePath(
        homeDir,
        { SystemDrive: 'D:', ELECTRON_DEV_USER_DATA: windowsRoot },
        false,
      ),
    ).toThrow(/védett rendszerkönyvtár/);
  });

  it.each(protectedRoots)('elutasítja a(z) %s pontos rendszerkönyvtárát', (name, root) => {
    expect(() =>
      resolveDatabasePath(homeDir, { [name]: root, ELECTRON_DEV_USER_DATA: root }, false),
    ).toThrow(/védett rendszerkönyvtár/);
  });

  it.each(protectedRoots)('elutasítja a(z) %s rendszerkönyvtár leszármazottját', (name, root) => {
    const descendant = path.join(root, 'Valuta', 'db');

    expect(() =>
      resolveDatabasePath(homeDir, { [name]: root, ELECTRON_DEV_USER_DATA: descendant }, false),
    ).toThrow(/védett rendszerkönyvtár/);
  });

  it.each(protectedRoots)(
    'nem utasítja el a(z) %s rendszerkönyvtárhoz csak névprefixben hasonló útvonalat',
    (name, root) => {
      const nearPrefix = `${root}-dev`;

      expect(
        resolveDatabasePath(homeDir, { [name]: root, ELECTRON_DEV_USER_DATA: nearPrefix }, false),
      ).toBe(path.join(nearPrefix, 'local.db'));
    },
  );

  it('a védett útvonalat kis- és nagybetűtől, valamint lezáró szeparátortól függetlenül felismeri', () => {
    const systemRoot = path.resolve('C:\\Windows');
    const mixedCaseDescendant = path.join(systemRoot.toUpperCase(), 'System32');

    expect(() =>
      resolveDatabasePath(
        homeDir,
        {
          SystemRoot: `${systemRoot.toLowerCase()}${path.sep}`,
          ELECTRON_DEV_USER_DATA: mixedCaseDescendant,
        },
        false,
      ),
    ).toThrow(/védett rendszerkönyvtár/);
  });

  it('a könyvtár-létrehozási hibát érdemi magyar hibával, fail-closed továbbadja', () => {
    const databasePath = path.join(path.resolve('C:\\protected'), 'local.db');
    const cause = new Error('access denied');

    expect(() =>
      ensureDatabaseDirectory(databasePath, {
        existsSync: () => false,
        mkdirSync: () => {
          throw cause;
        },
      }),
    ).toThrow(/Nem sikerült létrehozni a valuta mappát.*access denied/);
  });
});
