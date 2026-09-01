/**
 * Penztar SUITE-updater — BIZTONSAGI es MUNKAFOLYAMAT-tesztek.
 *
 * MIERT KELL: ez a modul egy alairt telepitot indit el egy penztargepen. Ket dolog
 * elronthatasa jar valos karral:
 *   (1) ha rontott hash-u / hibas alairasu exe-t elfogadna -> tetszoleges kod futna
 *       rendszergazdai kontextusban a penztargepen;
 *   (2) ha nyitott muszak alatt telepitene -> penzugyi folyamat szakadna meg
 *       (napzaras, folyamatban levo tranzakcio).
 * Mindkettot gepileg rogzitjuk, mert a kod olvasasa nem bizonyitek.
 *
 * A modul `electron`-t importal, ezert az mockolva van.
 */

import { describe, it, expect, vi } from 'vitest';
import { createHash, randomBytes } from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

/**
 * Biztonsagos, utkozes-mentes temp konyvtar a teszt-fajlokhoz.
 * (CodeQL js/insecure-temporary-file: a `Date.now()`-alapu nev josolhato, ezert
 * `mkdtemp` + veletlen nev kell — igy symlink/utkozes-tamadas sem lehetseges.)
 */
function makeTempDir(): string {
  return fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), 'suite-update-test-'));
}

vi.mock('electron', () => ({
  app: { getVersion: () => '2.28.78', getPath: () => os.tmpdir(), quit: vi.fn(), isPackaged: true },
  BrowserWindow: class {},
  Notification: class {
    static isSupported() {
      return false;
    }
    show() {}
  },
  dialog: { showMessageBox: vi.fn(() => Promise.resolve({ response: 1 })) },
  ipcMain: { handle: vi.fn(), removeHandler: vi.fn() },
}));

vi.mock('electron-log', () => ({
  default: { info: vi.fn(), warn: vi.fn(), error: vi.fn() },
}));

const {
  isNewerVersion,
  parseManifest,
  isInstallWindow,
  shouldAutoStartInstall,
  canStartInstallOnDemand,
  isSafeInstallerFileName,
  isAcceptableCacheCandidate,
  selectStaleCacheEntries,
  updateCacheDir,
  evaluateInstallAttempt,
  parseInstallMarker,
  INSTALL_MARKER_FILE,
  sha256File,
  verifyAuthenticode,
} = await import('../suite-update');

/** Ervenyes manifest-alap, amibol a tesztek rontott valtozatokat kepeznek. */
function validManifest(overrides: Record<string, unknown> = {}) {
  return {
    schemaVersion: 1,
    version: '2.28.79',
    releasedAt: '2026-08-20T10:00:00Z',
    rolloutPercent: 100,
    mandatory: false,
    notes: 'teszt',
    penztar: {
      file: 'Penztar-Setup-2.28.79-20260820.exe',
      url: 'https://github.com/kosazoltan/valutavalto-program/releases/download/v2.28.79/Penztar-Setup-2.28.79-20260820.exe',
      sha256: 'a'.repeat(64),
      sizeBytes: 293601280,
      silentArgs: ['/S'],
    },
    ...overrides,
  };
}

describe('isInstallWindow — a telepitesi ablak kapuja (3.6 szakasz)', () => {
  it('nyitott muszak alatt NEM telepitheto', () => {
    expect(isInstallWindow('SHIFT_OPEN')).toBe(false);
  });

  it('napnyitas ELOTT telepitheto', () => {
    expect(isInstallWindow('IDLE_BEFORE_OPEN')).toBe(true);
  });

  it('napzaras UTAN telepitheto', () => {
    expect(isInstallWindow('CLOSED_AFTER_DAY_END')).toBe(true);
  });
});

describe('shouldAutoStartInstall — belépés nélküli automatikus telepítés', () => {
  it('READY + napnyitás előtt: automatikusan indul (nincs kattintás)', () => {
    expect(shouldAutoStartInstall('READY', 'IDLE_BEFORE_OPEN')).toBe(true);
  });

  it('READY + napzárás után: automatikusan indul', () => {
    expect(shouldAutoStartInstall('READY', 'CLOSED_AFTER_DAY_END')).toBe(true);
  });

  it('READY + nyitott műszak: NEM indul (pénzügyi folyamat védelem)', () => {
    expect(shouldAutoStartInstall('READY', 'SHIFT_OPEN')).toBe(false);
  });

  it('még nincs kész telepítő: NEM indul', () => {
    expect(shouldAutoStartInstall('DOWNLOADING', 'IDLE_BEFORE_OPEN')).toBe(false);
    expect(shouldAutoStartInstall('VERIFYING', 'IDLE_BEFORE_OPEN')).toBe(false);
    expect(shouldAutoStartInstall('IDLE', 'IDLE_BEFORE_OPEN')).toBe(false);
  });
});

describe('canStartInstallOnDemand — explicit banner install (kanban #7)', () => {
  it('T-gate-ready: READY + non-empty path is allowed', () => {
    expect(canStartInstallOnDemand('READY', 'verified-exe-path')).toBe(true);
  });

  it('T-gate-blocked: IDLE/DOWNLOADING/null/empty path is refused', () => {
    expect(canStartInstallOnDemand('IDLE', 'verified-exe-path')).toBe(false);
    expect(canStartInstallOnDemand('DOWNLOADING', 'verified-exe-path')).toBe(false);
    expect(canStartInstallOnDemand('READY', null)).toBe(false);
    expect(canStartInstallOnDemand('READY', '')).toBe(false);
  });
});

describe('isNewerVersion — downgrade tilalom', () => {
  it('nagyobb patch/minor/major frissitheto', () => {
    expect(isNewerVersion('2.28.79', '2.28.78')).toBe(true);
    expect(isNewerVersion('2.29.0', '2.28.78')).toBe(true);
    expect(isNewerVersion('3.0.0', '2.28.78')).toBe(true);
  });

  it('azonos verzio NEM frissitheto (nincs ismetelt telepites)', () => {
    expect(isNewerVersion('2.28.78', '2.28.78')).toBe(false);
  });

  it('kisebb verzio NEM telepitheto (downgrade tilos)', () => {
    expect(isNewerVersion('2.28.77', '2.28.78')).toBe(false);
    expect(isNewerVersion('1.0.0', '2.28.78')).toBe(false);
    expect(isNewerVersion('2.27.99', '2.28.0')).toBe(false);
  });

  it('szamokat hasonlit, nem stringet (10 > 9)', () => {
    expect(isNewerVersion('2.28.100', '2.28.99')).toBe(true);
    expect(isNewerVersion('2.9.0', '2.10.0')).toBe(false);
  });

  it('ertelmezhetetlen verzio elutasitva (fail-closed)', () => {
    expect(isNewerVersion('2.28', '2.28.78')).toBe(false);
    expect(isNewerVersion('v2.28.79', '2.28.78')).toBe(false);
    expect(isNewerVersion('2.28.79-rc1', '2.28.78')).toBe(false);
    expect(isNewerVersion('', '2.28.78')).toBe(false);
  });
});

describe('parseManifest — fail-closed validalas', () => {
  it('ervenyes manifestet elfogad es normalizal', () => {
    const parsed = parseManifest(validManifest());
    expect(parsed).not.toBeNull();
    expect(parsed?.version).toBe('2.28.79');
    expect(parsed?.penztar.silentArgs).toEqual(['/S']);
  });

  it('ismeretlen schemaVersion elutasitva', () => {
    expect(parseManifest(validManifest({ schemaVersion: 2 }))).toBeNull();
    expect(parseManifest(validManifest({ schemaVersion: undefined }))).toBeNull();
  });

  it('nem-https URL elutasitva (csak HTTPS feed)', () => {
    const bad = validManifest();
    bad.penztar.url = 'http://example.com/Penztar-Setup.exe';
    expect(parseManifest(bad)).toBeNull();
  });

  it('rontott hash-formatum elutasitva (rovid / nem hexa)', () => {
    const short = validManifest();
    short.penztar.sha256 = 'abc123';
    expect(parseManifest(short)).toBeNull();

    const nonHex = validManifest();
    nonHex.penztar.sha256 = 'z'.repeat(64);
    expect(parseManifest(nonHex)).toBeNull();
  });

  it('hianyzo hash elutasitva (nem lehet ellenorzes nelkul telepiteni)', () => {
    const noHash = validManifest();
    delete (noHash.penztar as Record<string, unknown>).sha256;
    expect(parseManifest(noHash)).toBeNull();
  });

  it('nem .exe fajlnev elutasitva', () => {
    const bad = validManifest();
    bad.penztar.file = 'Penztar-Setup.zip';
    expect(parseManifest(bad)).toBeNull();
  });

  it('hianyzo penztar-blokk elutasitva', () => {
    const bad = validManifest();
    delete (bad as Record<string, unknown>).penztar;
    expect(parseManifest(bad)).toBeNull();
  });

  it('szemet bemenet elutasitva', () => {
    expect(parseManifest(null)).toBeNull();
    expect(parseManifest('nem objektum')).toBeNull();
    expect(parseManifest(42)).toBeNull();
  });

  it('rolloutPercent: 0 (kill-switch) megorzodik, nem valik 100-ra', () => {
    const parsed = parseManifest(validManifest({ rolloutPercent: 0 }));
    expect(parsed?.rolloutPercent).toBe(0);
  });

  it('hianyzo rolloutPercent -> 100 (default teljes flotta)', () => {
    const parsed = parseManifest(validManifest({ rolloutPercent: undefined }));
    expect(parsed?.rolloutPercent).toBe(100);
  });
});

describe('isSafeInstallerFileName — path traversal / command-injection vedelem', () => {
  it('a valos telepito-nevet elfogadja', () => {
    expect(isSafeInstallerFileName('Penztar-Setup-2.28.79-20260812.exe')).toBe(true);
    expect(isSafeInstallerFileName('Penztar-Setup-2.28.100.exe')).toBe(true);
  });

  it('path-traversal ELUTASITVA (ez volt a CodeQL critical talalat)', () => {
    const attacks = [
      '../Penztar-Setup-1.0.0.exe',
      '../../Penztar-Setup-1.0.0.exe',
      '../../../Windows/System32/Penztar-Setup-1.0.0.exe',
      '..\\..\\Penztar-Setup-1.0.0.exe',
      'sub/Penztar-Setup-1.0.0.exe',
      'sub\\Penztar-Setup-1.0.0.exe',
      '/tmp/Penztar-Setup-1.0.0.exe',
      'C:\\Temp\\Penztar-Setup-1.0.0.exe',
      '\\\\halozat\\share\\Penztar-Setup-1.0.0.exe',
    ];
    for (const attack of attacks) {
      expect(isSafeInstallerFileName(attack), attack).toBe(false);
    }
  });

  it('idegen fajlnev ELUTASITVA (csak a telepito-nevkonvencio)', () => {
    const rejected = [
      'evil.exe',
      'cmd.exe',
      'powershell.exe',
      'Kozponti-Munkaallomas-Setup-2.28.79.exe',
      'Penztar-Eltavolito-2.28.79.exe',
      'Penztar-Setup.exe.bat',
      'Penztar-Setup-1.0.0.dll',
      'Penztar-Setup-1.0.0.exe ',
      '',
    ];
    for (const name of rejected) {
      expect(isSafeInstallerFileName(name), name).toBe(false);
    }
  });

  it('parancssori metakarakterek ELUTASITVA', () => {
    for (const name of [
      'Penztar-Setup-1.0.0.exe & calc',
      'Penztar-Setup-1.0.0.exe|calc',
      'Penztar-Setup-1.0.0.exe;calc',
      'Penztar-Setup-$(whoami).exe',
      'Penztar-Setup-`id`.exe',
    ]) {
      expect(isSafeInstallerFileName(name), name).toBe(false);
    }
  });

  it('tulzottan hosszu nev ELUTASITVA', () => {
    expect(isSafeInstallerFileName('Penztar-Setup-' + 'a'.repeat(200) + '.exe')).toBe(false);
  });

  it('parseManifest is elutasitja a traversal-t (nem csak a helper)', () => {
    const attack = validManifest();
    attack.penztar.file = '../../../evil.exe';
    expect(parseManifest(attack)).toBeNull();

    const attack2 = validManifest();
    attack2.penztar.file = 'C:\\Windows\\System32\\cmd.exe';
    expect(parseManifest(attack2)).toBeNull();
  });
});

describe('FK-084 cache — ujraindulas utan ne toltsunk le ujra 276 MB-ot', () => {
  const manifestFile = 'Penztar-Setup-2.28.80-20260813.exe';
  const goodHash = 'a'.repeat(64);

  it('egyezo nev + egyezo hash -> elfogadva (E1)', () => {
    expect(isAcceptableCacheCandidate(manifestFile, manifestFile, goodHash, goodHash)).toBe(true);
  });

  it('kis/nagybetus hash-eltéres nem szamit (hexa normalizalas)', () => {
    expect(
      isAcceptableCacheCandidate(manifestFile, manifestFile, 'A'.repeat(64), 'a'.repeat(64)),
    ).toBe(true);
  });

  it('ELTERO hash -> ELUTASITVA (E2: serult vagy manipulalt cache)', () => {
    expect(isAcceptableCacheCandidate(manifestFile, manifestFile, 'b'.repeat(64), goodHash)).toBe(
      false,
    );
  });

  it('csonka / ertelmezhetetlen hash -> ELUTASITVA (E2)', () => {
    expect(isAcceptableCacheCandidate(manifestFile, manifestFile, 'abc', goodHash)).toBe(false);
    expect(isAcceptableCacheCandidate(manifestFile, manifestFile, '', goodHash)).toBe(false);
    expect(isAcceptableCacheCandidate(manifestFile, manifestFile, 'z'.repeat(64), goodHash)).toBe(
      false,
    );
  });

  it('MAS verzio telepitoje -> ELUTASITVA (nem a manifest szerinti fajl)', () => {
    expect(
      isAcceptableCacheCandidate(
        'Penztar-Setup-2.28.79-20260812.exe',
        manifestFile,
        goodHash,
        goodHash,
      ),
    ).toBe(false);
  });

  it('path-traversal a cache-nevben -> ELUTASITVA (E3)', () => {
    for (const attack of [
      '../Penztar-Setup-2.28.80-20260813.exe',
      '..\\Penztar-Setup-2.28.80-20260813.exe',
      'sub/Penztar-Setup-2.28.80-20260813.exe',
      'C:\\Temp\\Penztar-Setup-2.28.80-20260813.exe',
    ]) {
      expect(isAcceptableCacheCandidate(attack, manifestFile, goodHash, goodHash), attack).toBe(
        false,
      );
    }
  });

  it('idegen fajlnev -> ELUTASITVA (E3)', () => {
    expect(isAcceptableCacheCandidate('cmd.exe', manifestFile, goodHash, goodHash)).toBe(false);
    expect(isAcceptableCacheCandidate('evil.exe', manifestFile, goodHash, goodHash)).toBe(false);
  });

  it('a cache-konyvtar a temp alatti dedikalt alkonyvtar', () => {
    const dir = updateCacheDir('/tmp');
    expect(dir).toContain('valutavalto-update');
    // A `spawn` utvonal-ellenorzese ugyanezt hasznalja -> egy forras.
    expect(updateCacheDir('/tmp')).toBe(dir);
  });
});

describe('FK-084 takaritas — felbemaradt es elavult letoltesek (E6)', () => {
  const keep = 'Penztar-Setup-2.28.80-20260813.exe';

  it('az AKTUALIS telepitot NEM torli', () => {
    expect(selectStaleCacheEntries([keep], keep)).toEqual([]);
  });

  it('felbemaradt .part fajlt torol (app-leallas letoltes kozben)', () => {
    expect(selectStaleCacheEntries([`${keep}.part`], keep)).toEqual([`${keep}.part`]);
  });

  it('regi verziok telepitoit torli', () => {
    const stale = selectStaleCacheEntries(
      ['Penztar-Setup-2.28.78-20260811.exe', 'Penztar-Setup-2.28.79-20260812.exe', keep],
      keep,
    );
    expect(stale).toEqual([
      'Penztar-Setup-2.28.78-20260811.exe',
      'Penztar-Setup-2.28.79-20260812.exe',
    ]);
  });

  it('nem-telepito fajlokat nem bant (nem a mi dolgunk)', () => {
    expect(selectStaleCacheEntries(['jegyzet.txt', 'valami.log'], keep)).toEqual([]);
  });

  it('vegyes konyvtar: csak a maradvanyokat valasztja ki', () => {
    const stale = selectStaleCacheEntries(
      [keep, `${keep}.part`, 'Penztar-Setup-2.28.79-20260812.exe', 'olvasd.txt'],
      keep,
    );
    expect(stale.sort()).toEqual(['Penztar-Setup-2.28.79-20260812.exe', `${keep}.part`].sort());
  });
});

describe('FK-084 telepites-kimenet felismerese (E4-E5)', () => {
  // MIERT NEM in-process watchdog (PR #1620 review, P1): a suite-telepito leallitja a
  // Penztar.exe-t, ezert a main process 1 masodperccel a spawn utan kilep. Egy 15 perces
  // timer vagy egy `child.on('exit')` listener SOSEM futna le — a telepites kimenete a
  // processzunk halala UTAN dol el. A felismeres ezert markerfajl + a KOVETKEZO indulas
  // futo verzioja alapjan tortenik. Ezek a tesztek EZT a logikat merik, nem egy konstanst.
  const marker = {
    version: '2.28.80',
    startedAt: '2026-08-13T04:00:00Z',
    installerFile: 'Penztar-Setup-2.28.80-20260813.exe',
  };

  it('nincs marker -> NONE (nem volt telepitesi kiserlet)', () => {
    expect(evaluateInstallAttempt(null, '2.28.79')).toBe('NONE');
  });

  it('a CEL verzio fut -> SUCCESS (a telepito lefutott)', () => {
    expect(evaluateInstallAttempt(marker, '2.28.80')).toBe('SUCCESS');
  });

  it('MEG UJABB verzio fut -> SUCCESS (kozben tovabbi telepites is volt)', () => {
    expect(evaluateInstallAttempt(marker, '2.28.81')).toBe('SUCCESS');
  });

  it('a REGI verzio fut -> FAILED (elakadt vagy hibara futott a csendes telepito)', () => {
    // Ez a riasztas EGYETLEN forrasa: enelkul egy "fagyott telepito" nyom nelkul marad.
    expect(evaluateInstallAttempt(marker, '2.28.79')).toBe('FAILED');
  });

  it('ures verzio a markerben -> NONE (nem riasztunk talalgatasbol)', () => {
    expect(evaluateInstallAttempt({ ...marker, version: '' }, '2.28.79')).toBe('NONE');
  });

  it('a marker parse-olasa: ervenyes bemenet elfogadva', () => {
    expect(parseInstallMarker(marker)).not.toBeNull();
  });

  it('a marker parse-olasa: hibas verzio-formatum ELUTASITVA', () => {
    expect(parseInstallMarker({ ...marker, version: 'v2.28.80' })).toBeNull();
    expect(parseInstallMarker({ ...marker, version: '2.28' })).toBeNull();
  });

  it('a marker parse-olasa: path-traversal a fajlnevben ELUTASITVA', () => {
    // A markerbol torles-utvonal szarmazik, tehat itt is kell a nev-ellenorzes.
    expect(parseInstallMarker({ ...marker, installerFile: '../../evil.exe' })).toBeNull();
    expect(parseInstallMarker({ ...marker, installerFile: 'C:\\Windows\\cmd.exe' })).toBeNull();
  });

  it('a marker parse-olasa: szemet bemenet ELUTASITVA', () => {
    expect(parseInstallMarker(null)).toBeNull();
    expect(parseInstallMarker('nem objektum')).toBeNull();
    expect(parseInstallMarker({})).toBeNull();
  });

  it('a takaritas a MARKERT nem torli (a kovetkezo indulas ertekeli ki)', () => {
    expect(
      selectStaleCacheEntries([INSTALL_MARKER_FILE], 'Penztar-Setup-2.28.80-20260813.exe'),
    ).toEqual([]);
  });
});

describe('sha256File — streamelt hash', () => {
  it('a tenyleges fajltartalom hash-et adja', async () => {
    const dir = makeTempDir();
    const tmp = path.join(dir, 'payload.bin');
    const payload = Buffer.from('valutavalto teszt tartalom');
    fs.writeFileSync(tmp, payload);
    try {
      const expected = createHash('sha256').update(payload).digest('hex');
      await expect(sha256File(tmp)).resolves.toBe(expected);
    } finally {
      fs.rmSync(dir, { recursive: true, force: true });
    }
  });

  it('kulonbozo tartalom kulonbozo hash (a hash-ellenorzes ertelmes)', async () => {
    const dir = makeTempDir();
    const a = path.join(dir, 'a.bin');
    const b = path.join(dir, 'b.bin');
    fs.writeFileSync(a, 'eredeti telepito');
    fs.writeFileSync(b, 'modositott telepito');
    try {
      const [ha, hb] = await Promise.all([sha256File(a), sha256File(b)]);
      expect(ha).not.toBe(hb);
    } finally {
      fs.rmSync(dir, { recursive: true, force: true });
    }
  });

  it('veletlen tartalomra is a hivatalos hash-t adja (nem cache-el)', async () => {
    const dir = makeTempDir();
    const file = path.join(dir, 'random.bin');
    const payload = randomBytes(4096);
    fs.writeFileSync(file, payload);
    try {
      const expected = createHash('sha256').update(payload).digest('hex');
      await expect(sha256File(file)).resolves.toBe(expected);
    } finally {
      fs.rmSync(dir, { recursive: true, force: true });
    }
  });
});

describe('verifyAuthenticode — KETTOS feltetel (status ES subject)', () => {
  const subject = 'CN=EXCLUSIVE BEST Change Zrt., O=EXCLUSIVE BEST Change Zrt., C=HU';

  it('Valid status + helyes subject -> elfogadva', async () => {
    const result = await verifyAuthenticode('x.exe', 'EXCLUSIVE BEST Change Zrt.', () =>
      Promise.resolve({ status: 'Valid', subject }),
    );
    expect(result.ok).toBe(true);
  });

  it('nem-Valid status -> ELUTASITVA (akkor is, ha a subject stimmel)', async () => {
    for (const status of ['NotSigned', 'HashMismatch', 'UnknownError', 'NotTrusted']) {
      const result = await verifyAuthenticode('x.exe', 'EXCLUSIVE BEST Change Zrt.', () =>
        Promise.resolve({ status, subject }),
      );
      expect(result.ok).toBe(false);
    }
  });

  it('mas ceg tanusitvanya -> ELUTASITVA (akkor is, ha Valid)', async () => {
    const result = await verifyAuthenticode('x.exe', 'EXCLUSIVE BEST Change Zrt.', () =>
      Promise.resolve({ status: 'Valid', subject: 'CN=Evil Corp, C=RU' }),
    );
    expect(result.ok).toBe(false);
  });

  it('ures kimenet -> ELUTASITVA (fail-closed)', async () => {
    const result = await verifyAuthenticode('x.exe', 'EXCLUSIVE BEST Change Zrt.', () =>
      Promise.resolve({ status: '', subject: '' }),
    );
    expect(result.ok).toBe(false);
  });

  it('kis/nagybetu-fuggetlen subject-egyezes', async () => {
    const result = await verifyAuthenticode('x.exe', 'exclusive best change zrt.', () =>
      Promise.resolve({ status: 'Valid', subject }),
    );
    expect(result.ok).toBe(true);
  });
});
