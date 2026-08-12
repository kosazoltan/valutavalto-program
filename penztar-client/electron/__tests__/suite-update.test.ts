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
import { createHash } from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

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

const { isNewerVersion, parseManifest, isInstallWindow, sha256File, verifyAuthenticode } =
  await import('../suite-update');

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

describe('sha256File — streamelt hash', () => {
  it('a tenyleges fajltartalom hash-et adja', async () => {
    const tmp = path.join(os.tmpdir(), `suite-update-hash-${Date.now()}.bin`);
    const payload = Buffer.from('valutavalto teszt tartalom');
    fs.writeFileSync(tmp, payload);
    try {
      const expected = createHash('sha256').update(payload).digest('hex');
      await expect(sha256File(tmp)).resolves.toBe(expected);
    } finally {
      fs.unlinkSync(tmp);
    }
  });

  it('kulonbozo tartalom kulonbozo hash (a hash-ellenorzes ertelmes)', async () => {
    const a = path.join(os.tmpdir(), `suite-a-${Date.now()}.bin`);
    const b = path.join(os.tmpdir(), `suite-b-${Date.now()}.bin`);
    fs.writeFileSync(a, 'eredeti telepito');
    fs.writeFileSync(b, 'modositott telepito');
    try {
      const [ha, hb] = await Promise.all([sha256File(a), sha256File(b)]);
      expect(ha).not.toBe(hb);
    } finally {
      fs.unlinkSync(a);
      fs.unlinkSync(b);
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
