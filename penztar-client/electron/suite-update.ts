import { app, BrowserWindow, Notification, dialog, ipcMain } from 'electron';
import log from 'electron-log';
import { createHash } from 'node:crypto';
import { spawn } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
// Kozvetlen modul-import (NEM a barrel): a `src/index.ts` behuzza a vv-loggert is,
// az pedig `electron-log/main`-t -> `electron`-t koveteli meg mar import-idoben, ami
// unit-teszt kontextusban nem letezik. Az `auto-update` modul dontesi resze pure.
import { isInRollout } from '../../packages/electron-platform/src/auto-update';

/**
 * Penztar SUITE-updater — a teljes alairt telepitovel frissit.
 *
 * === MIERT NEM electron-updater ===
 * A penztar telepitesi egysege NEM csak az Electron app: a
 * `installer/Penztar-Setup.nsi` a lokalis backend JAR-t, a jlink JRE-t, a
 * PostgreSQL-t es az NSSM service-eket is felrakja. Az electron-updater a sajat
 * electron-builder GUID-alapu registry-kulcsabol oldja fel a telepitesi
 * konyvtarat, a penztar viszont a `ValutavaltoPenztar` kulccsal telepul — igy egy
 * electron-updater frissites MASODIK, parhuzamos telepitest hozna letre, mikozben
 * a suite tobbi resze a regi helyen, regi verzion maradna (kliens/lokalis-backend
 * verzio-szetcsuszas). Reszletek: `docs/auto-update-terv-es-vegrehajtas.md` 3.2.
 *
 * === ALLAPOTVEZERELT TELEPITESI ABLAK (3.6 szakasz, user-dontes) ===
 * Penztargepen a frissites SOHA nem szakithat meg penzugyi folyamatot, de nem is
 * maradhat a kollega dontesen, hogy egyaltalan frissul-e a gep. Ezert:
 *
 *   - nyitott muszak alatt (SHIFT_OPEN): CSAK JELZES (ertesites + renderer-jelolo),
 *     a letoltes es az ellenorzes a hatterben lefut, telepito NEM indul;
 *   - napzaras UTAN (CLOSED_AFTER_DAY_END) vagy napnyitas ELOTT (IDLE_BEFORE_OPEN):
 *     a telepites felajanlasa dialogussal, felhasznaloi megerositessel.
 *
 * Az allapotot a renderer jelenti (`suiteUpdate:setShiftState`). Ha az allapot NEM
 * megallapithato, konzervativan `SHIFT_OPEN`-nek tekintjuk -> nem telepitunk.
 *
 * === BIZTONSAG (3.3 szakasz) ===
 * Telepito CSAK akkor indul, ha (a) a letoltott fajl SHA-256-ja egyezik a
 * manifesttel, ES (b) az Authenticode alairas `Valid` ES a subject tartalmazza az
 * `EXCLUSIVE BEST Change Zrt.` nevet. Barmelyik bukik -> fajl torles + error-log,
 * telepito SOHA nem fut. Downgrade tilos (szigoruan nagyobb semver).
 */

/** A penztargep munkafolyamat-allapota — ez donti el, telepithetunk-e. */
export type ShiftState =
  /** Az app fut, de a napi muszak/nyitas meg nem kezdodott el. Telepitheto. */
  | 'IDLE_BEFORE_OPEN'
  /** Nyitott penztar/kassza, folyamatban levo tranzakcio vagy napzaras-varazslo. */
  | 'SHIFT_OPEN'
  /** A napzaras lezarva, nincs nyitott kassza. Telepitheto. */
  | 'CLOSED_AFTER_DAY_END';

/** A suite-updater allapotgepe. */
export type SuiteUpdateState =
  | 'IDLE'
  | 'CHECKING'
  | 'DOWNLOADING'
  | 'VERIFYING'
  | 'READY'
  | 'INSTALLING'
  | 'ERROR';

export interface SuiteUpdateManifestEntry {
  file: string;
  url: string;
  sha256: string;
  sizeBytes?: number;
  silentArgs?: string[];
}

export interface SuiteUpdateManifest {
  schemaVersion: number;
  version: string;
  releasedAt?: string;
  rolloutPercent?: number;
  mandatory?: boolean;
  notes?: string;
  penztar: SuiteUpdateManifestEntry;
}

/** Csak az allapotvezerelt ablakokban telepitunk. */
const INSTALLABLE_STATES: readonly ShiftState[] = ['IDLE_BEFORE_OPEN', 'CLOSED_AFTER_DAY_END'];

export function isInstallWindow(state: ShiftState): boolean {
  return INSTALLABLE_STATES.includes(state);
}

/**
 * Szigoru semver-osszehasonlitas: `a > b`?
 *
 * Downgrade tilos (3.3/3. pont), ezert egyenloseg es kisebb verzio egyaránt false.
 * Csak a `major.minor.patch` szamharmast hasonlitja; a pre-release suffix
 * (`-rc1`) tudatosan NEM frissitheto ra a flottan.
 */
export function isNewerVersion(candidate: string, current: string): boolean {
  const parse = (value: string): [number, number, number] | null => {
    const match = /^(\d+)\.(\d+)\.(\d+)$/.exec(value.trim());
    if (!match) return null;
    return [Number(match[1]), Number(match[2]), Number(match[3])];
  };
  const next = parse(candidate);
  const now = parse(current);
  if (!next || !now) return false;
  for (let i = 0; i < 3; i++) {
    const a = next[i] as number;
    const b = now[i] as number;
    if (a > b) return true;
    if (a < b) return false;
  }
  return false;
}

/**
 * Manifest-validalas. Hibas/ismeretlen manifest eseten `null` — a hivo ilyenkor
 * NEM tolt le semmit (fail-closed).
 */
export function parseManifest(raw: unknown): SuiteUpdateManifest | null {
  if (typeof raw !== 'object' || raw === null) return null;
  const obj = raw as Record<string, unknown>;
  if (obj.schemaVersion !== 1) return null;
  if (typeof obj.version !== 'string' || !/^\d+\.\d+\.\d+$/.test(obj.version)) return null;

  const entry = obj.penztar;
  if (typeof entry !== 'object' || entry === null) return null;
  const e = entry as Record<string, unknown>;
  if (typeof e.file !== 'string' || !e.file.toLowerCase().endsWith('.exe')) return null;
  if (typeof e.url !== 'string' || !e.url.startsWith('https://')) return null;
  // A hash 64 hexa karakter — rovid/rontott hash eseten nem indulunk el.
  if (typeof e.sha256 !== 'string' || !/^[0-9a-f]{64}$/i.test(e.sha256)) return null;

  const rollout = typeof obj.rolloutPercent === 'number' ? obj.rolloutPercent : 100;
  return {
    schemaVersion: 1,
    version: obj.version,
    releasedAt: typeof obj.releasedAt === 'string' ? obj.releasedAt : undefined,
    rolloutPercent: rollout,
    mandatory: obj.mandatory === true,
    notes: typeof obj.notes === 'string' ? obj.notes : undefined,
    penztar: {
      file: e.file,
      url: e.url,
      sha256: (e.sha256 as string).toLowerCase(),
      sizeBytes: typeof e.sizeBytes === 'number' ? e.sizeBytes : undefined,
      silentArgs: Array.isArray(e.silentArgs)
        ? (e.silentArgs as unknown[]).filter((a): a is string => typeof a === 'string')
        : ['/S'],
    },
  };
}

/** Streamelt SHA-256 (a telepito ~280 MB — nem olvassuk memoriaba). */
export function sha256File(filePath: string): Promise<string> {
  return new Promise((resolve, reject) => {
    const hash = createHash('sha256');
    const stream = fs.createReadStream(filePath);
    stream.on('error', reject);
    stream.on('data', (chunk) => hash.update(chunk));
    stream.on('end', () => resolve(hash.digest('hex')));
  });
}

/**
 * Authenticode-ellenorzes PowerShell-lel.
 *
 * KETTOS feltetel: `Status` == `Valid` ES a subject tartalmazza a ceg nevet —
 * egy masik (akar ervenyes) tanusitvannyal alairt exe NEM fogadhato el.
 */
export async function verifyAuthenticode(
  exePath: string,
  expectedSubjectFragment: string,
  runner: (exePath: string) => Promise<{ status: string; subject: string }> = defaultSignatureReader,
): Promise<{ ok: boolean; status: string; subject: string }> {
  const result = await runner(exePath);
  const ok =
    result.status.trim().toLowerCase() === 'valid' &&
    result.subject.toLowerCase().includes(expectedSubjectFragment.toLowerCase());
  return { ok, status: result.status, subject: result.subject };
}

function defaultSignatureReader(exePath: string): Promise<{ status: string; subject: string }> {
  return new Promise((resolve, reject) => {
    const ps = spawn(
      'powershell',
      [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        `$s = Get-AuthenticodeSignature -LiteralPath '${exePath.replace(/'/g, "''")}'; ` +
          `Write-Output $s.Status; Write-Output $s.SignerCertificate.Subject`,
      ],
      { windowsHide: true },
    );
    let out = '';
    ps.stdout.on('data', (chunk) => {
      out += String(chunk);
    });
    ps.on('error', reject);
    ps.on('close', () => {
      const [status = '', ...rest] = out.split(/\r?\n/).filter((line) => line.trim() !== '');
      resolve({ status, subject: rest.join(' ') });
    });
  });
}

const MANIFEST_URL =
  'https://github.com/kosazoltan/valutavalto-program/releases/latest/download/update-manifest.json';
const EXPECTED_SUBJECT = 'EXCLUSIVE BEST Change Zrt.';
const INITIAL_DELAY_MS = 10_000;
const POLL_INTERVAL_MS = 4 * 60 * 60 * 1000;

interface SuiteUpdateRuntime {
  state: SuiteUpdateState;
  shiftState: ShiftState;
  manifest: SuiteUpdateManifest | null;
  verifiedExePath: string | null;
  promptedForVersion: string | null;
}

export interface SuiteUpdateHandle {
  dispose(): void;
  /** Teszt/diagnosztika: az aktualis allapot. */
  getState(): SuiteUpdateState;
}

/**
 * Bekoti a suite-updatert.
 *
 * A renderer a `suiteUpdate:setShiftState` csatornan jelenti a muszak-allapotot;
 * minden allapotvaltasnal ujraertekeljuk, telepitheto-e a keszen allo frissites.
 */
export function initSuiteUpdate(mainWindow: BrowserWindow | null): SuiteUpdateHandle {
  const runtime: SuiteUpdateRuntime = {
    state: 'IDLE',
    // Fail-safe default: amig a renderer nem jelentett, ugy kezeljuk, mintha
    // nyitott muszak lenne -> nem telepitunk.
    shiftState: 'SHIFT_OPEN',
    manifest: null,
    verifiedExePath: null,
    promptedForVersion: null,
  };

  ipcMain.handle('suiteUpdate:setShiftState', (_event, state: unknown) => {
    const next = normaliseShiftState(state);
    if (next !== runtime.shiftState) {
      log.info(`[suiteUpdate] muszak-allapot: ${runtime.shiftState} -> ${next}`);
      runtime.shiftState = next;
      // Allapotatmenet a kivalto, nem az idozito (3.6/1. szabaly).
      if (runtime.state === 'READY') void maybeOfferInstall();
    }
    return { accepted: true, shiftState: runtime.shiftState };
  });

  ipcMain.handle('suiteUpdate:status', () => ({
    state: runtime.state,
    shiftState: runtime.shiftState,
    readyVersion: runtime.state === 'READY' ? runtime.manifest?.version ?? null : null,
    mandatory: runtime.manifest?.mandatory === true,
  }));

  const initialTimer = setTimeout(() => void check(), INITIAL_DELAY_MS);
  const intervalTimer = setInterval(() => void check(), POLL_INTERVAL_MS);

  return {
    getState: () => runtime.state,
    dispose: () => {
      clearTimeout(initialTimer);
      clearInterval(intervalTimer);
      ipcMain.removeHandler('suiteUpdate:setShiftState');
      ipcMain.removeHandler('suiteUpdate:status');
    },
  };

  async function check(): Promise<void> {
    if (runtime.state === 'DOWNLOADING' || runtime.state === 'VERIFYING' || runtime.state === 'INSTALLING') {
      return;
    }
    // Mar van ellenorzott, keszen allo telepito: ne toltsuk le ujra (280 MB).
    if (runtime.state === 'READY') {
      await maybeOfferInstall();
      return;
    }
    runtime.state = 'CHECKING';
    try {
      const response = await fetch(MANIFEST_URL, { redirect: 'follow' });
      if (!response.ok) throw new Error(`manifest HTTP ${response.status}`);
      const manifest = parseManifest(await response.json());
      if (!manifest) {
        log.warn('[suiteUpdate] ertelmezhetetlen manifest — kihagyva.');
        runtime.state = 'IDLE';
        return;
      }
      const currentVersion = app.getVersion();
      if (!isNewerVersion(manifest.version, currentVersion)) {
        log.info(`[suiteUpdate] nincs ujabb verzio (manifest ${manifest.version} <= ${currentVersion}).`);
        runtime.state = 'IDLE';
        return;
      }
      if (!isInRollout(manifest.version, manifest.rolloutPercent ?? 100, process.env.COMPUTERNAME ?? '')) {
        log.info(`[suiteUpdate] rollout (${manifest.rolloutPercent}%) kizarta ezt a gepet.`);
        runtime.state = 'IDLE';
        return;
      }
      runtime.manifest = manifest;
      await downloadAndVerify(manifest);
    } catch (err) {
      log.error('[suiteUpdate] check hiba:', err);
      runtime.state = 'IDLE';
    }
  }

  async function downloadAndVerify(manifest: SuiteUpdateManifest): Promise<void> {
    const targetDir = path.join(app.getPath('temp'), 'valutavalto-update');
    fs.mkdirSync(targetDir, { recursive: true });
    const finalPath = path.join(targetDir, manifest.penztar.file);
    const tempPath = `${finalPath}.part`;

    runtime.state = 'DOWNLOADING';
    log.info(`[suiteUpdate] letoltes: ${manifest.penztar.url}`);
    try {
      const response = await fetch(manifest.penztar.url, { redirect: 'follow' });
      if (!response.ok || !response.body) throw new Error(`letoltes HTTP ${response.status}`);
      const total = Number(response.headers.get('content-length') ?? manifest.penztar.sizeBytes ?? 0);
      let received = 0;
      const out = fs.createWriteStream(tempPath);
      // @ts-expect-error — a Node 20+ fetch body aszinkron iteralhato.
      for await (const chunk of response.body) {
        received += (chunk as Uint8Array).length;
        out.write(chunk);
        if (total > 0 && mainWindow && !mainWindow.isDestroyed()) {
          mainWindow.webContents.send('autoUpdate:progress', {
            percent: (received / total) * 100,
            transferred: received,
            total,
          });
        }
      }
      await new Promise<void>((resolve, reject) => {
        out.end((err?: Error | null) => (err ? reject(err) : resolve()));
      });
      // Atomikus rename csak a teljes letoltes utan.
      fs.renameSync(tempPath, finalPath);
    } catch (err) {
      safeUnlink(tempPath);
      log.error('[suiteUpdate] letoltes sikertelen:', err);
      runtime.state = 'IDLE';
      return;
    }

    runtime.state = 'VERIFYING';
    try {
      const actualHash = await sha256File(finalPath);
      if (actualHash !== manifest.penztar.sha256) {
        log.error(
          `[suiteUpdate] SHA-256 ELTERES — elutasitva. manifest=${manifest.penztar.sha256} tenyleges=${actualHash}`,
        );
        safeUnlink(finalPath);
        runtime.state = 'IDLE';
        return;
      }
      const signature = await verifyAuthenticode(finalPath, EXPECTED_SUBJECT);
      if (!signature.ok) {
        log.error(
          `[suiteUpdate] ALAIRAS ELUTASITVA — status=${signature.status} subject=${signature.subject}`,
        );
        safeUnlink(finalPath);
        runtime.state = 'IDLE';
        return;
      }
      log.info(`[suiteUpdate] hash + alairas OK: ${finalPath}`);
      runtime.verifiedExePath = finalPath;
      runtime.state = 'READY';
      await maybeOfferInstall();
    } catch (err) {
      log.error('[suiteUpdate] ellenorzes hiba:', err);
      safeUnlink(finalPath);
      runtime.state = 'IDLE';
    }
  }

  /**
   * A READY -> INSTALLING atmenet KAPUJA: csak telepitesi ablakban, felhasznaloi
   * megerositessel. Nyitott muszak alatt csak jelez.
   */
  async function maybeOfferInstall(): Promise<void> {
    const manifest = runtime.manifest;
    const exePath = runtime.verifiedExePath;
    if (runtime.state !== 'READY' || !manifest || !exePath) return;

    // A renderer-jelolo MINDIG frissul, hogy a kollega lassa: van kesz frissites.
    if (mainWindow && !mainWindow.isDestroyed()) {
      mainWindow.webContents.send('suiteUpdate:ready', {
        version: manifest.version,
        mandatory: manifest.mandatory === true,
        notes: manifest.notes ?? null,
        installableNow: isInstallWindow(runtime.shiftState),
      });
    }

    if (!isInstallWindow(runtime.shiftState)) {
      // Egy verziora egyszer ertesitunk, hogy ne legyen zavaro.
      if (runtime.promptedForVersion !== `notified:${manifest.version}`) {
        runtime.promptedForVersion = `notified:${manifest.version}`;
        notify(
          'Frissítés készen áll',
          `A v${manifest.version} letöltve. A telepítés a következő napnyitás előtt vagy napzárás után indítható.`,
        );
        log.info('[suiteUpdate] nyitott muszak — csak jelzes, telepito NEM indul.');
      }
      return;
    }

    if (runtime.promptedForVersion === `asked:${manifest.version}`) return;
    runtime.promptedForVersion = `asked:${manifest.version}`;

    const windowLabel =
      runtime.shiftState === 'CLOSED_AFTER_DAY_END' ? 'a napzárás lezárult' : 'a nap még nem indult el';
    const choice = await dialog.showMessageBox(
      mainWindow && !mainWindow.isDestroyed() ? mainWindow : undefined!,
      {
        type: 'info',
        buttons: ['Frissítés most', 'Később'],
        defaultId: manifest.mandatory ? 0 : 1,
        cancelId: 1,
        title: 'Frissítés telepítése',
        message: `Új verzió érhető el: v${manifest.version}`,
        detail:
          `Most biztonságos telepíteni, mert ${windowLabel}. ` +
          'A program bezár, a frissítés kb. 2-3 percig tart, utána automatikusan elindul. ' +
          'Az adatbázis és a beállítások megmaradnak.' +
          (manifest.notes ? `\n\nÚjdonságok: ${manifest.notes}` : ''),
      },
    );
    if (choice.response !== 0) {
      log.info('[suiteUpdate] felhasznalo elhalasztotta — a kovetkezo ablakban ujra kerdezunk.');
      // A kovetkezo allapotatmenetnel megint felajanljuk.
      runtime.promptedForVersion = null;
      return;
    }
    startSilentInstall(exePath, manifest);
  }

  function startSilentInstall(exePath: string, manifest: SuiteUpdateManifest): void {
    runtime.state = 'INSTALLING';
    const args = manifest.penztar.silentArgs?.length ? manifest.penztar.silentArgs : ['/S'];
    log.info(`[suiteUpdate] csendes telepites indul: ${exePath} ${args.join(' ')}`);
    try {
      const child = spawn(exePath, args, { detached: true, stdio: 'ignore', windowsHide: true });
      child.unref();
      // A telepito allitja le/inditja a service-eket es a vegen a Penztar.exe-t.
      setTimeout(() => app.quit(), 1_000);
    } catch (err) {
      log.error('[suiteUpdate] a telepito nem indult el:', err);
      runtime.state = 'READY';
      runtime.promptedForVersion = null;
    }
  }

  function notify(title: string, body: string): void {
    try {
      if (Notification.isSupported()) new Notification({ title, body }).show();
    } catch (err) {
      log.warn('[suiteUpdate] notification hiba:', err);
    }
  }
}

function normaliseShiftState(value: unknown): ShiftState {
  if (value === 'IDLE_BEFORE_OPEN' || value === 'CLOSED_AFTER_DAY_END' || value === 'SHIFT_OPEN') {
    return value;
  }
  // Ismeretlen ertek -> konzervativ (nem telepitunk).
  return 'SHIFT_OPEN';
}

function safeUnlink(filePath: string): void {
  try {
    if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
  } catch {
    // A takaritas hibaja soha ne dontse el a folyamatot.
  }
}
