/**
 * Platform auto-update modul — VISELKEDES-tesztek.
 *
 * MIERT KELL: az updater dontesi logikaja (staged rollout kapu + a telepitesi mod)
 * penzugyi flotta-viselkedest szabalyoz. A rollout a kill-switch alapja
 * (`rolloutPercent: 0` allitsa meg a flotta-frissitest), az `on-quit` mod pedig azt
 * garantalja, hogy a kozponti kliens SOHA ne inditson kenyszeritett ujraindulast
 * munka kozben. Mindket szabalyt gepileg rogzitjuk, kulonben egy kesobbi
 * "egyszerusites" csendben visszahozhatna a munkat megszakito viselkedest.
 *
 * A modul `electron`-t importal (`dialog`, `Notification`), ezert az mockolva van.
 * `electron-updater` NEM kell: a platform interfeszt (`UpdaterLike`) vesz at.
 */

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';

const showMessageBoxMock = vi.fn(() => Promise.resolve({ response: 0 }));
const notificationShowMock = vi.fn();

vi.mock('electron', () => ({
  dialog: { showMessageBox: (...args: unknown[]) => showMessageBoxMock(...(args as [])) },
  Notification: class {
    static isSupported() {
      return true;
    }
    show() {
      notificationShowMock();
    }
  },
}));

const { initElectronUpdater, isInRollout } = await import(
  '../../../packages/electron-platform/src/auto-update'
);

type Listener = (...args: unknown[]) => void;

function makeLogger() {
  return { info: vi.fn(), warn: vi.fn(), error: vi.fn() };
}

/** Minimalis `UpdaterLike` teszt-dubla, amelynek eventjei kezzel tuzelhetok. */
function makeUpdater() {
  const listeners = new Map<string, Listener>();
  return {
    logger: null as unknown,
    autoDownload: false,
    autoInstallOnAppQuit: false,
    quitAndInstallCalls: 0,
    checkCalls: 0,
    on(event: string, listener: Listener) {
      listeners.set(event, listener);
      return this;
    },
    checkForUpdates() {
      this.checkCalls += 1;
      return Promise.resolve({});
    },
    quitAndInstall() {
      this.quitAndInstallCalls += 1;
    },
    emit(event: string, payload?: unknown) {
      const listener = listeners.get(event);
      if (!listener) throw new Error(`Nincs listener a(z) "${event}" eventre`);
      listener(payload);
    },
    hasListener(event: string) {
      return listeners.has(event);
    },
  };
}

function init(overrides: Record<string, unknown> = {}) {
  const updater = makeUpdater();
  const logger = makeLogger();
  const handle = initElectronUpdater({
    updater: updater as never,
    logger,
    currentVersion: '2.28.78',
    installMode: 'on-quit',
    clientLabel: 'kozponti',
    machineId: 'TEST-PC',
    ...overrides,
  } as never);
  return { updater, logger, handle };
}

describe('isInRollout — staged rollout kapu', () => {
  it('0% = kill-switch: soha nem frissit', () => {
    for (const machine of ['A', 'B', 'PENZTAR-17', '']) {
      expect(isInRollout('2.28.79', 0, machine)).toBe(false);
    }
  });

  it('negativ vagy ertelmezhetetlen szazalek is kizar (fail-safe)', () => {
    expect(isInRollout('2.28.79', -5, 'A')).toBe(false);
    expect(isInRollout('2.28.79', Number.NaN, 'A')).toBe(false);
  });

  it('100% (es felette) mindig frissit', () => {
    expect(isInRollout('2.28.79', 100, 'A')).toBe(true);
    expect(isInRollout('2.28.79', 250, 'B')).toBe(true);
  });

  it('determinisztikus: ugyanaz a (verzio, gep) par ugyanazt adja', () => {
    const first = isInRollout('2.28.79', 25, 'PENZTAR-17');
    for (let i = 0; i < 50; i++) {
      expect(isInRollout('2.28.79', 25, 'PENZTAR-17')).toBe(first);
    }
  });

  it('reszleges rollout: nem mindenki es nem senki (a flotta megoszlik)', () => {
    const machines = Array.from({ length: 200 }, (_, i) => `PENZTAR-${i}`);
    const included = machines.filter((m) => isInRollout('2.28.79', 50, m));
    expect(included.length).toBeGreaterThan(0);
    expect(included.length).toBeLessThan(machines.length);
  });

  it('monoton: aki 25%-nal bent van, 100%-nal is bent van', () => {
    for (let i = 0; i < 100; i++) {
      const machine = `PENZTAR-${i}`;
      if (isInRollout('2.28.79', 25, machine)) {
        expect(isInRollout('2.28.79', 100, machine)).toBe(true);
      }
    }
  });
});

describe('initElectronUpdater — bekotes es rollout-kizaras', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    showMessageBoxMock.mockClear();
    notificationShowMock.mockClear();
    showMessageBoxMock.mockResolvedValue({ response: 0 });
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('rollout-kizarasnal NEM kot be eventet es nem indit idozitot', () => {
    const { updater, handle } = init({ rolloutPercent: 0 });
    expect(handle.excludedByRollout).toBe(true);
    expect(updater.hasListener('update-downloaded')).toBe(false);
    vi.advanceTimersByTime(24 * 60 * 60 * 1000);
    expect(updater.checkCalls).toBe(0);
  });

  it('bekotesnel autoDownload es autoInstallOnAppQuit is igaz', () => {
    const { updater, handle } = init();
    expect(handle.excludedByRollout).toBe(false);
    expect(updater.autoDownload).toBe(true);
    // Ha a felhasznalo elhalasztja, a frissites a kilepesnel telepul -> nem marad
    // orokre elmaradt verzio a gepen.
    expect(updater.autoInstallOnAppQuit).toBe(true);
  });

  it('elso ellenorzes 10 mp utan, majd 4 orankent', () => {
    const { updater } = init();
    expect(updater.checkCalls).toBe(0);
    vi.advanceTimersByTime(10_000);
    expect(updater.checkCalls).toBe(1);
    vi.advanceTimersByTime(4 * 60 * 60 * 1000);
    expect(updater.checkCalls).toBe(2);
  });

  it('dispose() leallitja az idozitoket', () => {
    const { updater, handle } = init();
    handle.dispose();
    vi.advanceTimersByTime(24 * 60 * 60 * 1000);
    expect(updater.checkCalls).toBe(0);
  });

  it('checkForUpdates hibaja nem dol el (log + tovabbfut)', () => {
    const { updater, logger } = init();
    updater.checkForUpdates = () => Promise.reject(new Error('halozat'));
    vi.advanceTimersByTime(10_000);
    return Promise.resolve().then(() => {
      expect(logger.error).toHaveBeenCalled();
    });
  });
});

describe('initElectronUpdater — telepitesi mod (munkamegszakitas tilalma)', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    showMessageBoxMock.mockClear();
    notificationShowMock.mockClear();
    showMessageBoxMock.mockResolvedValue({ response: 0 });
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('on-quit mod: letoltes utan SEM dialog, SEM azonnali ujraindit', async () => {
    const { updater } = init({ installMode: 'on-quit' });
    updater.emit('update-downloaded', { version: '2.28.79' });
    await vi.runAllTicks?.();
    await Promise.resolve();
    expect(showMessageBoxMock).not.toHaveBeenCalled();
    expect(updater.quitAndInstallCalls).toBe(0);
    // A felhasznalot ertesitjuk, hogy a frissites keszen all.
    expect(notificationShowMock).toHaveBeenCalled();
  });

  it('prompt mod + megerosites: quitAndInstall lefut', async () => {
    showMessageBoxMock.mockResolvedValue({ response: 0 });
    const { updater } = init({ installMode: 'prompt' });
    updater.emit('update-downloaded', { version: '2.28.79' });
    await Promise.resolve();
    await Promise.resolve();
    expect(showMessageBoxMock).toHaveBeenCalled();
    expect(updater.quitAndInstallCalls).toBe(1);
  });

  it('prompt mod + "Kesobb": NEM indit ujra (a munka nem szakad meg)', async () => {
    showMessageBoxMock.mockResolvedValue({ response: 1 });
    const { updater } = init({ installMode: 'prompt' });
    updater.emit('update-downloaded', { version: '2.28.79' });
    await Promise.resolve();
    await Promise.resolve();
    expect(updater.quitAndInstallCalls).toBe(0);
  });

  it('hianyzo verzio-info nem dobja el a folyamatot', async () => {
    const { updater } = init({ installMode: 'on-quit' });
    updater.emit('update-downloaded', undefined);
    await Promise.resolve();
    expect(notificationShowMock).toHaveBeenCalled();
  });

  it('error event csak logol, nem dob', () => {
    const { updater, logger } = init();
    expect(() => updater.emit('error', new Error('boom'))).not.toThrow();
    expect(logger.error).toHaveBeenCalled();
  });
});
