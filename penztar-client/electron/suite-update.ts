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

/** Csak allapotvezerelt ablakokban telepitunk. */
const INSTALLABLE_STATES: readonly ShiftState[] = ['IDLE_BEFORE_OPEN', 'CLOSED_AFTER_DAY_END'];

/**
 * A telepito-fajlnev SZIGORU mintaja.
 *
 * MIERT KELL (CodeQL js/command-line-injection, 2026-08-12): a manifest a szerverrol
 * jon, es a `file` mezoje a letoltes celutvonalat ES a `spawn()` elso argumentumat is
 * meghatarozza. Ha csak a `.exe` vegzodest ellenoriznenk, egy `../../../x.exe` ertek
 * kilepne a temp konyvtarbol (`path.join` normalizal), es tetszoleges utvonalon levo
 * fajl indulhatna el. Ezert: (a) csak basename fogadhato el, (b) a nev illeszkedjen a
 * telepito nevkonvenciojara, (c) nincs benne utvonal-elvalaszto, `..`, vagy
 * meghajto-jelzo.
 */
const INSTALLER_FILE_PATTERN = /^Penztar-Setup-[0-9A-Za-z._-]+\.exe$/;

export function isSafeInstallerFileName(file: string): boolean {
  if (typeof file !== 'string' || file.length === 0 || file.length > 128) return false;
  // Utvonal-elvalaszto, meghajto-jelzo, vagy szulo-hivatkozas => elutasitva.
  if (/[\\/]/.test(file)) return false;
  if (file.includes('..')) return false;
  if (/^[A-Za-z]:/.test(file)) return false;
  // A basename-nek onmagaval kell egyeznie (Windows es POSIX szerint egyaránt).
  if (path.basename(file) !== file) return false;
  if (path.win32.basename(file) !== file) return false;
  return INSTALLER_FILE_PATTERN.test(file);
}

export function isInstallWindow(state: ShiftState): boolean {
  return INSTALLABLE_STATES.includes(state);
}

/**
 * A letoltesi/cache konyvtar. Egy helyen definialva, mert HAROM dolog kotodik hozza:
 * a letoltes celutvonala, a cache-feloldas es a `spawn` utvonal-ellenorzese.
 */
export function updateCacheDir(tempDir: string): string {
  return path.join(tempDir, 'valutavalto-update');
}

/**
 * Eldonti, hogy egy MAR A LEMEZEN levo fajl elfogadhato-e cache-kent.
 *
 * FK-084/E2 + E3: a "lemezen van, tehat jo" gondolat itt tilos. A cache pontosan
 * ugyanazt a ket kaput kapja, mint a friss letoltes:
 *   (a) a fajlnev a manifest szerinti, szigoru mintat kovetve (path-traversal ki),
 *   (b) a tartalom SHA-256-ja egyezik a manifesttel.
 * Az Authenticode-ellenorzest a hivo vegzi (I/O), de a hash-kapu itt bukik el, igy
 * egy manipulalt cache-fajl sosem jut el a telepitesig.
 *
 * @returns `true`, ha a fajl elfogadhato es tovabbadhato az alairas-ellenorzesnek.
 */
export function isAcceptableCacheCandidate(
  fileName: string,
  manifestFileName: string,
  actualSha256: string,
  expectedSha256: string,
): boolean {
  if (!isSafeInstallerFileName(fileName)) return false;
  if (fileName !== manifestFileName) return false;
  if (!/^[0-9a-f]{64}$/i.test(actualSha256)) return false;
  return actualSha256.toLowerCase() === expectedSha256.toLowerCase();
}

/** A telepitesi kiserlet markerfajlja a cache-konyvtarban. */
export const INSTALL_MARKER_FILE = 'install-attempt.json';

/**
 * Kivalasztja a cache-konyvtarbol torlendo maradvanyokat.
 *
 * FK-084/E6: a felbemaradt `.part` fajlok (app-leallas letoltes kozben) es a regi
 * verziok telepitoi kulonben 276 MB-os egysegekben halmozodnak a temp konyvtarban.
 * A jelenleg aktualis (manifest szerinti) fajlt SOHA nem torli.
 */
export function selectStaleCacheEntries(entries: string[], keepFileName: string): string[] {
  return entries.filter((name) => {
    if (name === keepFileName) return false;
    // A telepitesi marker NEM maradvany: a kovetkezo indulas ertekeli ki.
    if (name === INSTALL_MARKER_FILE) return false;
    return name.endsWith('.part') || name.toLowerCase().endsWith('.exe');
  });
}

/** A telepito-watchdog kuszobe: ennyi ido utan mar rendellenes, hogy meg fut. */
export const INSTALL_WATCHDOG_MS = 15 * 60 * 1000;

export interface InstallAttemptMarker {
  version: string;
  startedAt: string;
  installerFile: string;
}

/**
 * Egy korabbi telepitesi kiserlet kimenete, a KOVETKEZO app-indulaskor ertekelve.
 *
 * MIERT IGY (PR #1620 review, P1): a telepitest NEM lehet a futo processzbol
 * felugyelni. A suite-telepito eppen a Penztar.exe-t allitja le, hogy felulirhassa
 * a fajlokat, ezert a main process 1 masodperccel a `spawn` utan kilep (`app.quit()`).
 * Egy in-process watchdog vagy `exit` listener SOHA nem futna le — se a 15 perces
 * elakadas-riasztas, se a nem-nulla exit-kod naplozasa. (Ez a hiba a PR elso
 * valtozataban benne volt: a tesztek a konstanst es a kodszerkezetet mertek, nem a
 * valos viselkedest.)
 *
 * Helyette: a telepites INDITASA elott markert irunk, es a kovetkezo indulaskor a
 * FUTO VERZIOBOL derul ki, mi tortent:
 *   - a verzio a markerben szereplo cel-verzio  -> SUCCESS (a telepites lefutott)
 *   - a verzio valtozatlanul a regi             -> FAILED (elakadt vagy hibara futott)
 */
export type InstallAttemptOutcome = 'NONE' | 'SUCCESS' | 'FAILED';

/**
 * Kiertekeli az elozo telepitesi kiserletet a MOST futo verzio alapjan.
 *
 * @param marker a beolvasott markerfajl tartalma (`null`, ha nincs)
 * @param runningVersion az eppen futo app verzioja (`app.getVersion()`)
 */
export function evaluateInstallAttempt(
  marker: InstallAttemptMarker | null,
  runningVersion: string,
): InstallAttemptOutcome {
  if (!marker || typeof marker.version !== 'string' || marker.version === '') return 'NONE';
  // A cel-verzio fut -> a telepito vegzett. (Egyenloseg ES a nagyobb verzio is siker:
  // ha kozben egy ujabb telepites is lefutott, a kiserlet biztosan nem akadt el.)
  if (runningVersion === marker.version || isNewerVersion(runningVersion, marker.version)) {
    return 'SUCCESS';
  }
  return 'FAILED';
}

/** A marker tartalmanak biztonsagos ertelmezese (serult JSON eseten `null`). */
export function parseInstallMarker(raw: unknown): InstallAttemptMarker | null {
  if (typeof raw !== 'object' || raw === null) return null;
  const obj = raw as Record<string, unknown>;
  if (typeof obj.version !== 'string' || !/^\d+\.\d+\.\d+$/.test(obj.version)) return null;
  if (typeof obj.installerFile !== 'string' || !isSafeInstallerFileName(obj.installerFile)) {
    return null;
  }
  return {
    version: obj.version,
    startedAt: typeof obj.startedAt === 'string' ? obj.startedAt : '',
    installerFile: obj.installerFile,
  };
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
  // SZIGORU fajlnev-ellenorzes: ez a nev a letoltes celutvonala ES a `spawn()`
  // elso argumentuma is lesz, ezert path-traversal itt kizarando (nem eleg a .exe).
  if (typeof e.file !== 'string' || !isSafeInstallerFileName(e.file)) return null;
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
  runner: (
    exePath: string,
  ) => Promise<{ status: string; subject: string }> = defaultSignatureReader,
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
/**
 * A telepito felso meretkorlatja (600 MB). A valos suite ~280 MB; a duplaja feletti
 * ertek mar hibara utal. Enelkul egy manipulalt vagy hibasan valaszolo szerver
 * teleirhatna a penztargep lemezét a `.part` fajllal.
 */
const MAX_INSTALLER_BYTES = 600 * 1024 * 1024;

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
    readyVersion: runtime.state === 'READY' ? (runtime.manifest?.version ?? null) : null,
    mandatory: runtime.manifest?.mandatory === true,
  }));

  const initialTimer = setTimeout(() => void check(), INITIAL_DELAY_MS);
  const intervalTimer = setInterval(() => void check(), POLL_INTERVAL_MS);

  // FK-084/E4-E5: az ELOZO telepitesi kiserlet kiertekelese — ez az egyetlen hely,
  // ahol egy elakadt csendes telepites felismerheto (a kimenet a mi processzunk
  // halala UTAN dol el). Azonnal fut, nem varunk vele a poll-ciklusra.
  try {
    reviewPreviousInstallAttempt();
  } catch (err) {
    log.warn('[suiteUpdate] az elozo telepites kiertekelese sikertelen:', err);
  }

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
    if (
      runtime.state === 'DOWNLOADING' ||
      runtime.state === 'VERIFYING' ||
      runtime.state === 'INSTALLING'
    ) {
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
        log.info(
          `[suiteUpdate] nincs ujabb verzio (manifest ${manifest.version} <= ${currentVersion}).`,
        );
        runtime.state = 'IDLE';
        return;
      }
      if (
        !isInRollout(
          manifest.version,
          manifest.rolloutPercent ?? 100,
          process.env.COMPUTERNAME ?? '',
        )
      ) {
        log.info(`[suiteUpdate] rollout (${manifest.rolloutPercent}%) kizarta ezt a gepet.`);
        runtime.state = 'IDLE';
        return;
      }
      runtime.manifest = manifest;
      // CACHE (FK-084/E1): ha ezt a verziot mar letoltottuk es ellenoriztuk, ne
      // toltsuk le ujra 276 MB-ot. A penztargepet naponta ujrainditjak, es a
      // `verifiedExePath` csak memoriaban elt -> minden reggel ujra letoltott
      // volna, amig a kollega nem telepit (nyitott muszak alatt nem telepitunk).
      // A cache elfogadasa UGYANAZON a ket kapun megy at, mint a friss letoltes
      // (SHA-256 + Authenticode) — nincs "megbizom benne, mert a lemezen van".
      const cached = await resolveVerifiedCache(manifest);
      if (cached) {
        log.info(`[suiteUpdate] mar letoltott es ellenorzott telepito hasznalata: ${cached}`);
        runtime.verifiedExePath = cached;
        runtime.state = 'READY';
        await maybeOfferInstall();
        return;
      }
      await downloadAndVerify(manifest);
    } catch (err) {
      log.error('[suiteUpdate] check hiba:', err);
      runtime.state = 'IDLE';
    }
  }

  async function downloadAndVerify(manifest: SuiteUpdateManifest): Promise<void> {
    const targetDir = updateCacheDir(app.getPath('temp'));
    fs.mkdirSync(targetDir, { recursive: true });
    // FK-084/E6: a regi verziok telepitoi es a felbemaradt `.part` fajlok torlese,
    // MIELOTT ujabb 276 MB-ot irunk a lemezre.
    cleanupStaleCache(targetDir, manifest.penztar.file);
    // MASODIK VEDELMI VONAL (defense in depth): a `parseManifest` mar szurte a nevet,
    // de itt is bizonyitjuk, hogy a celutvonal a sajat konyvtarunkon BELUL van —
    // igy egy jovobeli validalas-lazitas sem vezethet konyvtaron kivuli irashoz vagy
    // idegen utvonalon levo exe inditasahoz.
    const finalPath = path.resolve(targetDir, path.basename(manifest.penztar.file));
    if (path.dirname(finalPath) !== path.resolve(targetDir)) {
      log.error(
        `[suiteUpdate] utvonal-ellenorzes bukott, letoltes megszakitva: ${manifest.penztar.file}`,
      );
      runtime.state = 'IDLE';
      return;
    }
    const tempPath = `${finalPath}.part`;

    runtime.state = 'DOWNLOADING';
    log.info(`[suiteUpdate] letoltes: ${manifest.penztar.url}`);
    try {
      const response = await fetch(manifest.penztar.url, { redirect: 'follow' });
      if (!response.ok || !response.body) throw new Error(`letoltes HTTP ${response.status}`);
      const total = Number(
        response.headers.get('content-length') ?? manifest.penztar.sizeBytes ?? 0,
      );
      let received = 0;
      const out = fs.createWriteStream(tempPath);
      // A letoltott bajtok TARTALMA itt meg nem megbizhato (CodeQL js/http-to-file-access):
      // ez a modul lenyege — a telepitot le KELL tolteni ahhoz, hogy ellenorizni tudjuk.
      // A vedelem nem az iras megakadalyozasa, hanem hogy a fajl SOHA nem fut le
      // SHA-256 + Authenticode ellenorzes nelkul (lasd lentebb), az utvonal a sajat
      // temp-alkonyvtarunkhoz van kotve, es a meret felso korlatos: enelkul egy
      // manipulalt vagy hibas szerver teleirhatna a penztargep lemezét (a `.part`
      // fajl a lemez megtelteig nott volna).
      for await (const chunk of response.body as unknown as AsyncIterable<Uint8Array>) {
        received += chunk.length;
        if (received > MAX_INSTALLER_BYTES) {
          throw new Error(
            `a letoltes tullepte a megengedett meretet (${received} > ${MAX_INSTALLER_BYTES} bajt)`,
          );
        }
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
      runtime.shiftState === 'CLOSED_AFTER_DAY_END'
        ? 'a napzárás lezárult'
        : 'a nap még nem indult el';
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

  /**
   * FK-084/E1-E3: feloldja a lemezen mar meglevo, ELLENORZOTT telepitot.
   *
   * Az app ujraindulasa utan a `verifiedExePath` (memoria) elveszik, a 276 MB-os fajl
   * viszont ott van. Enelkul a gep MINDEN reggel ujra letoltene, amig a kollega nem
   * telepit (nyitott muszak alatt nem telepitunk) — 72 gepes flottan uzleti
   * savszelesseget eget.
   *
   * A cache elfogadasa NEM bizalmi kerdes: ugyanaz a ket kapu fut le, mint friss
   * letoltesnel (SHA-256 a manifesthez, majd Authenticode + subject). Barmelyik bukik
   * -> a fajl torlodik es null-t adunk vissza (ujra letoltunk).
   */
  async function resolveVerifiedCache(manifest: SuiteUpdateManifest): Promise<string | null> {
    const dir = updateCacheDir(app.getPath('temp'));
    if (!fs.existsSync(dir)) return null;
    cleanupStaleCache(dir, manifest.penztar.file);

    const candidate = path.resolve(dir, path.basename(manifest.penztar.file));
    if (path.dirname(candidate) !== path.resolve(dir)) return null;
    if (!fs.existsSync(candidate)) return null;

    try {
      const actualHash = await sha256File(candidate);
      if (
        !isAcceptableCacheCandidate(
          path.basename(candidate),
          manifest.penztar.file,
          actualHash,
          manifest.penztar.sha256,
        )
      ) {
        log.warn('[suiteUpdate] a cache-elt telepito hash-e NEM egyezik — torles, ujratoltes.');
        safeUnlink(candidate);
        return null;
      }
      const signature = await verifyAuthenticode(candidate, EXPECTED_SUBJECT);
      if (!signature.ok) {
        log.error(
          `[suiteUpdate] a cache-elt telepito alairasa ELUTASITVA — status=${signature.status} subject=${signature.subject}`,
        );
        safeUnlink(candidate);
        return null;
      }
      return candidate;
    } catch (err) {
      log.warn('[suiteUpdate] a cache ellenorzese sikertelen — ujratoltes:', err);
      safeUnlink(candidate);
      return null;
    }
  }

  /** FK-084/E6: regi verziok + felbemaradt `.part` fajlok torlese. */
  function cleanupStaleCache(dir: string, keepFileName: string): void {
    // A FUTO telepito fajljat nem bantjuk.
    if (runtime.state === 'INSTALLING') return;
    try {
      const stale = selectStaleCacheEntries(fs.readdirSync(dir), keepFileName);
      for (const name of stale) {
        safeUnlink(path.join(dir, name));
        log.info(`[suiteUpdate] elavult letoltes-maradvany torolve: ${name}`);
      }
    } catch (err) {
      // A takaritas hibaja soha ne allitsa meg a frissitest.
      log.warn('[suiteUpdate] cache-takaritas sikertelen:', err);
    }
  }

  function startSilentInstall(exePath: string, manifest: SuiteUpdateManifest): void {
    // HARMADIK VEDELMI VONAL: csak a MAGUNK altal letoltott, ellenorzott es a sajat
    // temp-alkonyvtarunkban levo fajl indithato. A `spawn` argumentumai fix konstansok
    // (`/S`) — a manifest `silentArgs`-ebol csak engedelyezett zaszlot fogadunk el, hogy
    // szerverrol jott ertek ne kerulhessen a parancssorba.
    const expectedDir = path.resolve(updateCacheDir(app.getPath('temp')));
    const resolved = path.resolve(exePath);
    if (
      path.dirname(resolved) !== expectedDir ||
      !isSafeInstallerFileName(path.basename(resolved))
    ) {
      log.error(
        `[suiteUpdate] BIZTONSAGI ELUTASITAS — nem sajat, ellenorzott telepito: ${exePath}`,
      );
      runtime.state = 'IDLE';
      return;
    }
    if (!fs.existsSync(resolved)) {
      log.error(`[suiteUpdate] a telepito eltunt a lemezrol: ${resolved}`);
      runtime.state = 'IDLE';
      return;
    }
    const ALLOWED_SILENT_ARGS = new Set(['/S', '/NCRC']);
    const requested = manifest.penztar.silentArgs ?? ['/S'];
    const rejected = requested.filter((arg) => !ALLOWED_SILENT_ARGS.has(arg));
    if (rejected.length > 0) {
      log.warn(`[suiteUpdate] nem engedelyezett silentArgs eldobva: ${rejected.join(' ')}`);
    }
    const args = requested.filter((arg) => ALLOWED_SILENT_ARGS.has(arg));
    if (args.length === 0) args.push('/S');

    runtime.state = 'INSTALLING';
    log.info(`[suiteUpdate] csendes telepites indul: ${resolved} ${args.join(' ')}`);

    // FK-084/E4-E5 — a telepites kimenetet a KOVETKEZO indulaskor ertekeljuk.
    //
    // In-process watchdog itt NEM mukodhet (PR #1620 review, P1): a suite-telepito
    // leallitja a Penztar.exe-t, ezert 1 masodperc mulva `app.quit()` kovetkezik —
    // egy 15 perces timer vagy egy `child.on('exit')` listener sosem futna le.
    // Ezert a telepites INDITASA elott markert irunk; a kovetkezo indulaskor a futo
    // verziobol derul ki, lefutott-e (lasd `evaluateInstallAttempt`).
    writeInstallMarker(manifest);

    try {
      const child = spawn(resolved, args, {
        detached: true,
        stdio: 'ignore',
        windowsHide: true,
        shell: false,
      });

      // Az `error` event AZONNALI (a spawn maga bukik: hianyzo fajl, EACCES), tehat
      // ez a listener meg a kilepes elott lefut — ellentetben az `exit`-tel.
      child.on('error', (err) => {
        log.error('[suiteUpdate] a telepito-folyamat NEM indult el:', err);
        clearInstallMarker();
        runtime.state = 'READY';
        runtime.promptedForVersion = null;
      });

      child.unref();
      // A telepito allitja le/inditja a service-eket es a vegen a Penztar.exe-t.
      setTimeout(() => app.quit(), 1_000);
    } catch (err) {
      log.error('[suiteUpdate] a telepito nem indult el:', err);
      clearInstallMarker();
      runtime.state = 'READY';
      runtime.promptedForVersion = null;
    }
  }

  /** A telepitesi kiserlet markerjenek kiirasa (a kimenet utolagos felismereséhez). */
  function writeInstallMarker(manifest: SuiteUpdateManifest): void {
    try {
      const dir = updateCacheDir(app.getPath('temp'));
      fs.mkdirSync(dir, { recursive: true });
      const marker: InstallAttemptMarker = {
        version: manifest.version,
        startedAt: new Date().toISOString(),
        installerFile: manifest.penztar.file,
      };
      fs.writeFileSync(path.join(dir, INSTALL_MARKER_FILE), JSON.stringify(marker), 'utf8');
    } catch (err) {
      // A marker hibaja ne akadalyozza meg a telepitest — csak a kesobbi felismerest.
      log.warn('[suiteUpdate] a telepitesi marker kiirasa sikertelen:', err);
    }
  }

  function clearInstallMarker(): void {
    try {
      safeUnlink(path.join(updateCacheDir(app.getPath('temp')), INSTALL_MARKER_FILE));
    } catch {
      // szandekosan elnyomva — takaritas
    }
  }

  /**
   * FK-084/E4-E5: az ELOZO telepitesi kiserlet kiertekelese indulaskor.
   *
   * Ez az egyetlen pont, ahol egy elakadt vagy bukott csendes telepites egyaltalan
   * felismerheto — a telepites ugyanis a mi processzunk halala UTAN dol el.
   */
  function reviewPreviousInstallAttempt(): void {
    const markerPath = path.join(updateCacheDir(app.getPath('temp')), INSTALL_MARKER_FILE);
    if (!fs.existsSync(markerPath)) return;
    let marker: InstallAttemptMarker | null;
    try {
      marker = parseInstallMarker(JSON.parse(fs.readFileSync(markerPath, 'utf8')));
    } catch (err) {
      log.warn('[suiteUpdate] a telepitesi marker ertelmezhetetlen — torles:', err);
      safeUnlink(markerPath);
      return;
    }
    const outcome = evaluateInstallAttempt(marker, app.getVersion());
    if (outcome === 'SUCCESS') {
      log.info(`[suiteUpdate] az elozo frissites SIKERES volt (v${marker?.version} fut).`);
      safeUnlink(markerPath);
      // A telepito mar nem kell.
      if (marker) safeUnlink(path.join(updateCacheDir(app.getPath('temp')), marker.installerFile));
      return;
    }
    if (outcome === 'FAILED') {
      log.error(
        `[suiteUpdate] RIASZTAS: az elozo frissitesi kiserlet (v${marker?.version}, inditva: ` +
          `${marker?.startedAt || 'ismeretlen'}) NEM fejezodott be — a gep tovabbra is ` +
          `v${app.getVersion()}-en fut. Valoszinu ok: a csendes telepito elakadt (pl. rejtett ` +
          'dialogus) vagy hibara futott. A gepen kezi ellenorzes indokolt.',
      );
      // A markert toroljuk, hogy ne riasszon vegtelenul; a frissites ujra felajanlhato.
      safeUnlink(markerPath);
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
