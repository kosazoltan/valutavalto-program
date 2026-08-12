import { BrowserWindow, Notification, dialog } from 'electron'

/**
 * Kozos Electron self-update reteg (platform-szintu forras-igazsag).
 *
 * === MIERT VAN ITT ===
 * A `penztar-client/electron/auto-update.ts` volt az egyetlen updater-implementacio
 * a repoban, a `kozponti-client`-ben pedig egyaltalan nem volt. Az updater dontesi
 * logikaja (staged rollout gep-hash, magyar dialogszovegek, event-wiring, logolas)
 * mindket kliensnek AZONOS kell, ezert ide kerult — a kliens -> kliens import tilos.
 *
 * === MIERT NINCS `electron-updater` IMPORT ===
 * A platform SZANDEKOSAN nem vesz fel `electron-updater` dependencyt: a kliens adja
 * at a sajat `autoUpdater` peldanyat (`UpdaterLike`). Indok:
 *   (a) a platform sajat fuggosegeit MINDEN CI-jobnak telepitenie kell, amelyik a
 *       platform-forrast beforditja (v2.28.76 TS2307 lecke) — egy uj dependency itt
 *       harom workflow telepito-lepeset erinti;
 *   (b) az updater I/O-el (halozat + telepito-inditas), ezert interfesz mogott a helye;
 *   (c) igy a dontesi logika unit-tesztelheto electron-updater nelkul.
 *
 * === MIT NEM CSINAL ===
 * Ez a modul az electron-builder NSIS utat (`electron-updater`) tamogatja, ami a
 * KOZPONTI kliens esete. A PENZTAR suite-telepitojehez (backend JAR + JRE +
 * PostgreSQL + NSSM service-ek egy csomagban) ez NEM alkalmas: az electron-updater
 * a sajat electron-builder GUID-alapu registry-kulcsabol oldja fel a telepitesi
 * konyvtarat, a penztar viszont a kezzel irt `installer/Penztar-Setup.nsi`-vel
 * telepul (`ValutavaltoPenztar` kulcs), ezert parhuzamos, masodik telepites jonne
 * letre es a kliens/lokalis backend verzioja szetcsuszna.
 * Reszletek + a penztar suite-updater terve:
 *   `docs/auto-update-terv-es-vegrehajtas.md` 3.2 es 3.6 szakasz.
 */

/** Az `electron-updater` `autoUpdater`-jenek az a resze, amit ez a modul hasznal. */
export interface UpdaterLike {
  logger: unknown
  autoDownload: boolean
  autoInstallOnAppQuit: boolean
  on(event: string, listener: (...args: unknown[]) => void): unknown
  checkForUpdates(): Promise<unknown>
  /**
   * A letoltes explicit inditasa. KELL, mert az `autoDownload` false: a staged
   * rolloutot csak a FELAJANLOTT verzio ismereteben lehet helyesen kiertekelni.
   */
  downloadUpdate(): Promise<unknown>
  quitAndInstall(): void
}

/** Minimalis logger-kontraktus (electron-log kompatibilis). */
export interface UpdateLogger {
  info(...args: unknown[]): void
  warn(...args: unknown[]): void
  error(...args: unknown[]): void
}

/**
 * Telepitesi mod — a `docs/auto-update-terv-es-vegrehajtas.md` 8. szakaszanak
 * 2. dontese szerint a kozponti kliens `on-quit`-tal fut.
 *
 *  - `on-quit`: letoltes utan NEM kerdez es NEM inditja ujra az appot; a telepites
 *    a kovetkezo kilepesnel tortenik (`autoInstallOnAppQuit`). Ertesites tajekoztat.
 *  - `prompt`: letoltes utan modal dialog, elfogadas eseten azonnali ujraindit+telepit.
 */
export type UpdateInstallMode = 'on-quit' | 'prompt'

export interface ElectronUpdaterOptions {
  /** Az `electron-updater` `autoUpdater` peldanya (a kliens adja at). */
  updater: UpdaterLike
  /** A kliens logger-e (electron-log). */
  logger: UpdateLogger
  /** Az aktualisan futo verzio (`app.getVersion()`). */
  currentVersion: string
  /** Telepitesi mod — lasd `UpdateInstallMode`. */
  installMode: UpdateInstallMode
  /**
   * Log- es dialog-prefix, hogy a ket kliens naploja szetvalaszthato legyen
   * (pl. 'kozponti'). Kotelezo: rejtett fajl-szintu default TILOS (a kiemelesi
   * szabaly szerint a kliens-specifikus kulonbseg explicit parameter).
   */
  clientLabel: string
  /** A fo ablak (progress-IPC es dialog szuloje); lehet `null`. */
  mainWindow?: BrowserWindow | null
  /**
   * Staged rollout szazalek (0-100). 0 = kill-switch, a kliens nem frissul.
   * Hivo oldalon jellemzoen `UPDATE_ROLLOUT_PERCENT` env.
   */
  rolloutPercent?: number
  /**
   * A rollout gep-hash stabil bemenete (gepenkent kulonbozo, de idoben allando).
   * Default: `process.env.COMPUTERNAME ?? ''` — Windows-flotta.
   */
  machineId?: string
  /** Elso ellenorzes kesleltetese ms-ban (default 10 000 — ne blokkolja a UI-t). */
  initialDelayMs?: number
  /** Ellenorzesi periodus ms-ban (default 4 ora). */
  intervalMs?: number
}

/** Az `initElectronUpdater` visszateresi erteke — a timerek leallithatosaga miatt. */
export interface ElectronUpdaterHandle {
  /**
   * Mindig `false`. Megtartva a visszamenoleges kompatibilitas miatt: a rollout-kapu
   * 2026-08-12 ota NEM a bekotesnel dont (az tartos kizarast okozott), hanem
   * verziankent, az `update-available` eventben — igy az updater mindig elindul.
   */
  excludedByRollout: boolean
  /** Leallitja az idozitoket (teszt / app-shutdown). */
  dispose(): void
}

const DEFAULT_INITIAL_DELAY_MS = 10_000
const DEFAULT_INTERVAL_MS = 4 * 60 * 60 * 1000
const DEFAULT_ROLLOUT_PERCENT = 100

/**
 * Determinisztikus staged-rollout kapu.
 *
 * Ugyanaz a `(version, machineId)` par MINDIG ugyanazt az eredmenyt adja — igy egy
 * gep nem "villog" be-ki a rolloutba ujraindulasok kozott. A hash a penztar
 * `auto-update.ts` (v2.28.78, 29-37. sor) logikaja, valtozatlanul atemelve.
 *
 * `percent <= 0` -> mindig false (kill-switch), `percent >= 100` -> mindig true.
 */
export function isInRollout(version: string, percent: number, machineId = ''): boolean {
  if (!Number.isFinite(percent) || percent <= 0) return false
  if (percent >= 100) return true
  const input = version + machineId
  let hash = 0
  for (let i = 0; i < input.length; i++) {
    hash = ((hash << 5) - hash + input.charCodeAt(i)) | 0
  }
  return Math.abs(hash) % 100 < percent
}

/**
 * Bekoti az `electron-updater` alapu onfrissitest.
 *
 * A hivo felelossege az `electron-updater` behuzasa es az `app.getVersion()` atadasa
 * — a platform nem importal se `app`-ot, se updater-csomagot, hogy unit-tesztelheto
 * es CI-semleges maradjon.
 */
export function initElectronUpdater(options: ElectronUpdaterOptions): ElectronUpdaterHandle {
  const {
    updater,
    logger,
    currentVersion,
    installMode,
    clientLabel,
    mainWindow = null,
    rolloutPercent = DEFAULT_ROLLOUT_PERCENT,
    machineId = process.env.COMPUTERNAME ?? '',
    initialDelayMs = DEFAULT_INITIAL_DELAY_MS,
    intervalMs = DEFAULT_INTERVAL_MS,
  } = options

  const tag = `[autoUpdate:${clientLabel}]`
  logger.info(`${tag} Current version: ${currentVersion}`)
  logger.info(`${tag} Staged rollout: ${rolloutPercent}% | install mode: ${installMode}`)

  updater.logger = logger
  // FONTOS (PR #1618 review, P2): az `autoDownload` SZANDEKOSAN false.
  //
  // A staged rolloutot a FELAJANLOTT verziora kell hashelni, nem a telepitettre.
  // A korabbi valtozat a bekotes ELOTT dontott a `currentVersion` alapjan, es
  // kizaras eseten idozito NELKUL visszatert — igy az a gep soha nem tudta meg,
  // milyen verzio van kinalva, es MINDEN kovetkezo release-nel ugyanabban a kizart
  // bucketben maradt (valtozatlan szazalek mellett), mikozben a frissult gepek az
  // uj verziojukkal ujra-bucketelodtek. Ez a flotta egy fix reszen tartos, csendes
  // lemaradast okozott volna.
  //
  // Ezert: MINDIG ellenorzunk, es a rollout-kaput az `update-available` eventben,
  // a felajanlott verziora ertekeljuk ki; a letoltes csak azutan indul.
  updater.autoDownload = false
  // `prompt` modban is igaz: ha a felhasznalo a "Kesobb"-et valasztja, a frissites
  // a kovetkezo kilepesnel telepul — igy nem marad orokre elmaradt verzio.
  updater.autoInstallOnAppQuit = true

  updater.on('checking-for-update', () => {
    logger.info(`${tag} checking-for-update`)
  })

  updater.on('update-available', (...args: unknown[]) => {
    const version = readVersion(args[0])
    logger.info(`${tag} update-available: ${version}`)
    // A kapu a CEL verziora vonatkozik (lasd a fenti indoklast) — igy egy kizart
    // gep a KOVETKEZO verziot ujra kiertekeli, nem ragad be a bucketjebe.
    if (!isInRollout(version, rolloutPercent, machineId)) {
      logger.info(
        `${tag} a staged rollout (${rolloutPercent}%) kizarta ezt a gepet a v${version} verziobol — ` +
          'letoltes nem indul; a kovetkezo verzio ujra ertekelesre kerul.',
      )
      return
    }
    notify('Frissítés érhető el', `A v${version} letöltése megkezdődött a háttérben.`)
    void updater.downloadUpdate().catch((err) => {
      logger.error(`${tag} downloadUpdate failed:`, err)
    })
  })
  updater.on('update-not-available', () => {
    logger.info(`${tag} update-not-available`)
  })

  updater.on('download-progress', (...args: unknown[]) => {
    const progress = args[0] as { percent?: number; bytesPerSecond?: number } | undefined
    const percent = Math.round(progress?.percent ?? 0)
    const kbps = Math.round((progress?.bytesPerSecond ?? 0) / 1024)
    logger.info(`${tag} download ${percent}% (${kbps} KB/s)`)
    if (mainWindow && !mainWindow.isDestroyed()) {
      mainWindow.webContents.send('autoUpdate:progress', progress)
    }
  })

  updater.on('update-downloaded', (...args: unknown[]) => {
    const version = readVersion(args[0])
    logger.info(`${tag} update-downloaded: ${version}`)
    void handleDownloaded(version)
  })

  updater.on('error', (...args: unknown[]) => {
    logger.error(`${tag} error:`, args[0])
  })

  const initialTimer = setTimeout(() => {
    void check()
  }, initialDelayMs)
  const intervalTimer = setInterval(() => {
    void check()
  }, intervalMs)

  return {
    excludedByRollout: false,
    dispose: () => {
      clearTimeout(initialTimer)
      clearInterval(intervalTimer)
    },
  }

  async function check(): Promise<void> {
    try {
      await updater.checkForUpdates()
    } catch (err) {
      logger.error(`${tag} checkForUpdates failed:`, err)
    }
  }

  async function handleDownloaded(version: string): Promise<void> {
    if (installMode === 'on-quit') {
      // A 2. dontes: a kozponti gepen nincs penztari munkafolyamat, ezert nem
      // szakitjuk meg a munkat — a telepites a kovetkezo kilepesnel fut le.
      notify(
        'Frissítés készen áll',
        `A v${version} telepítése automatikusan megtörténik, amikor bezárja a programot.`,
      )
      logger.info(`${tag} on-quit mode: telepites a kovetkezo app-kilepesnel.`)
      return
    }

    // A ket overloadot KULON kell hivni (PR #1618 review): a 2-arg-os valtozatnak
    // `undefined!`-t atadni futasidoben hibazhat, ha nincs elo ablak.
    const options = {
      type: 'info' as const,
      buttons: ['Újraindítás és telepítés', 'Később'],
      defaultId: 0,
      cancelId: 1,
      title: 'Frissítés telepítése',
      message: `Új verzió érhető el: v${version}`,
      detail:
        'A telepítéshez az alkalmazás újraindul. Kérjük, mentse el a munkát. ' +
        'A „Később" választásával a frissítés a program bezárásakor települ.',
    }
    const parent = mainWindow && !mainWindow.isDestroyed() ? mainWindow : null
    const choice = parent
      ? await dialog.showMessageBox(parent, options)
      : await dialog.showMessageBox(options)
    if (choice.response === 0) {
      logger.info(`${tag} felhasznaloi megerosites -> quitAndInstall()`)
      updater.quitAndInstall()
    } else {
      logger.info(`${tag} felhasznalo elhalasztotta -> telepites app-kilepesnel.`)
    }
  }

  function notify(title: string, body: string): void {
    try {
      if (Notification.isSupported()) {
        new Notification({ title, body }).show()
      }
    } catch (err) {
      // Az ertesites soha ne dontse el a frissitesi folyamatot.
      logger.warn(`${tag} notification failed:`, err)
    }
  }
}

function readVersion(info: unknown): string {
  const version = (info as { version?: unknown } | undefined)?.version
  return typeof version === 'string' ? version : 'ismeretlen'
}
