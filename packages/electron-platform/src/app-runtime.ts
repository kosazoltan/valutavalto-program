/**
 * Electron main-process INDULASI/RUNTIME primitivek — platform-reteg.
 *
 * === MIERT VAN ITT (platform-refaktor 3. kor, 2026-08-11, U2 szelet) ===
 * Harom, biztonsagilag erzekeny blokk normalizalt (`;` + behuzas strippelt)
 * diffje igazoltan azonos volt tobb kliensben:
 *
 *   userData/.env promocio        penztar:1080-1102 kozponti:586-606 arfolyam:458-478
 *                                 -> k/a BAJTRA AZONOS; penztar 1 log-uzenetben ter el
 *   media permission handler      penztar:1140-1163 kozponti:611-634 arfolyam:483-506
 *                                 -> MIND A HAROM BAJTRA AZONOS
 *   `app:` protokoll-kiszolgalo   kozponti:305-325  arfolyam:200-220
 *                                 -> azonos, csak a `distPath` szamitasa ter el
 *
 * === MIERT FONTOS EZT EGY FORRASBOL ADNI ===
 * A permission-handler az F-006 audit (2026-05-29) eredmenye: a NEM-media
 * permission BIZTONSAGOS DEFAULTJA a DENY, es a `media` (mikrofon) is csak
 * explicit origin-allowlisttel megy at. Harom masolatban ez a szabaly harom
 * helyen driftelhet szet — egy elfelejtett kliens csendben default-allow-ra
 * valthatna. Ugyanez all a protokoll-kiszolgalo path-traversal vedelmere.
 *
 * === AMI SZANDEKOSAN A KLIENSBEN MARAD ===
 * - a `userData` utvonal FELOLDASA (a hivo adja at): a `kozponti-client`
 *   indulas kozben `app.setPath('userData', ...)`-ot hiv (#ERR-INST-01), ezert
 *   a platform NEM oldhatja fel es NEM cache-elheti az utat;
 * - a `distPath` szamitasa: a kozponti dual-bundle (`MODE_DIST_SUBDIR`), az
 *   arfolyam egyetlen `dist`;
 * - a `penztar-client` protokoll-kezeloje kerdesenkent `log.info`-t ir es masik
 *   valtozo-elnevezest hasznal -> NEM azonos, ezert NEM hasznalja ezt a kezelot.
 */

import { net, protocol, type Session } from 'electron'
import * as fs from 'node:fs'
import * as path from 'node:path'
import { pathToFileURL } from 'node:url'

/** A minimalis logger-felulet, amit a kliensek `electron-log` peldanya teljesit. */
export interface PlatformLogger {
  info: (message: string, ...args: unknown[]) => void
  warn: (message: string, ...args: unknown[]) => void
  error: (message: string, ...args: unknown[]) => void
}

/** A `promoteUserDataEnv` bemenete. */
export interface PromoteUserDataEnvOptions {
  /**
   * A userData konyvtar HIVASI IDOBEN feloldott abszolut utja.
   * A platform szandekosan nem oldja fel maga — lasd #ERR-INST-01.
   */
  userDataPath: string
  logger: PlatformLogger
  /**
   * A hianyzo `.env` eseten kiirt figyelmeztetes. Kliensenkent elter
   * (a penztar a SetupWizardra utal), ezert KOTELEZO parameter, nem default.
   */
  missingEnvMessage: string
}

/**
 * A `userData/.env` ertekeinek promotalasa a `process.env`-be.
 *
 * MIERT KELL: production buildben a `dotenv/config` NEM tolti be a userData
 * alatti `.env`-et, ezert a Google OAuth IPC-handlerek `undefined`-ot olvasnanak
 * (2026-05-15 user-direktiva).
 *
 * MAR BEALLITOTT valtozot NEM ir felul (`if (!process.env[k])`) — a
 * kornyezetbol jovo ertek erosebb, mint a fajl.
 */
export function promoteUserDataEnv(options: PromoteUserDataEnvOptions): void {
  const { userDataPath, logger, missingEnvMessage } = options
  try {
    const envPath = path.join(userDataPath, '.env')
    if (fs.existsSync(envPath)) {
      const raw = fs.readFileSync(envPath, 'utf8')
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const dotenv = require('dotenv') as {
        parse: (input: string | Buffer) => Record<string, string>
      }
      const parsed = dotenv.parse(raw)
      for (const [k, v] of Object.entries(parsed)) {
        if (!process.env[k]) process.env[k] = v
      }
      logger.info(`[App] userData/.env betoltve a process.env-be (${Object.keys(parsed).length} kulcs)`)
    } else {
      logger.warn(missingEnvMessage)
    }
  } catch (err) {
    logger.error('[App] userData/.env betoltesi hiba:', err)
  }
}

type PermissionRequestHandler = NonNullable<Parameters<Session['setPermissionRequestHandler']>[0]>

/**
 * A media (mikrofon) permission-kezelo — EGYETLEN FORRAS mind a harom kliensnek.
 *
 * BIZTONSAGI INVARIANS (F-006 audit, 2026-05-29):
 *   1. a `setPermissionRequestHandler` session-global, ezert a NEM-`media`
 *      permission-okra (notifications, geolocation, midi, clipboard, ...) a
 *      BIZTONSAGOS DEFAULT = **DENY**. Penzugyi kliensben nincs default-allow;
 *   2. a `media` is csak explicit origin-allowlisttel megy at:
 *      `app://localhost`, `http://localhost`, `https://excvaluta.com`.
 *      Az ellenorzes URL-parse + PONTOS protocol/hostname egyezes (Codex P1 +
 *      CodeQL + Copilot fix) — NEM `startsWith`/`includes`, mert az
 *      `https://excvaluta.com.evil.tld` atmenne rajta.
 *
 * Ezt a szabalyt NE duplikald vissza a kliensekbe: a
 * `scripts/check-platform-boundaries.mjs` assertje bukik ra.
 */
export function createMediaPermissionHandler(logger: PlatformLogger): PermissionRequestHandler {
  return (_webContents, permission, callback, details) => {
    if (permission !== 'media') {
      logger.warn('[Security] Non-media permission elutasitva (default-deny):', permission)
      callback(false)
      return
    }
    try {
      const url = new URL(String(details?.requestingUrl ?? ''))
      const isLocalApp = url.protocol === 'app:' && url.hostname === 'localhost'
      const isLocalHttp = url.protocol === 'http:' && url.hostname === 'localhost'
      const isProduction = url.protocol === 'https:' && url.hostname === 'excvaluta.com'
      if (isLocalApp || isLocalHttp || isProduction) {
        logger.info('[VoiceAssistant] media (mic) engedely megadva:', url.origin)
        callback(true)
        return
      }
      logger.warn('[VoiceAssistant] media (mic) engedely elutasitva (idegen origin):', url.origin)
    } catch (err) {
      logger.warn('[VoiceAssistant] media (mic) URL parse hiba — elutasitva:', err)
    }
    callback(false)
  }
}

type AppProtocolHandler = Parameters<typeof protocol.handle>[1]

/**
 * Az `app:` sema kiszolgaloja a csomagolt frontend-buildhez (SPA fallback).
 *
 * BIZTONSAGI INVARIANS: path-traversal vedelem. A feloldott utnak a `distPath`
 * ALATT kell maradnia; ellenkezo esetben `index.html`-t szolgalunk ki es
 * figyelmeztetunk. A `resolved !== resolvedDist` ag azert kell, hogy maga a
 * gyoker-konyvtar ne szamitson kileptetesnek.
 *
 * @param distPath a kiszolgalando build gyokere — a HIVO szamitja ki
 *                 (kozponti: `MODE_DIST_SUBDIR[activeAppMode]` dual-bundle,
 *                 arfolyam: egyetlen `dist`).
 */
export function createAppProtocolHandler(
  distPath: string,
  logger: PlatformLogger,
): AppProtocolHandler {
  return (request) => {
    const url = new URL(request.url)
    let filePath = path.join(distPath, decodeURIComponent(url.pathname))
    if (url.pathname === '/' || url.pathname === '') {
      filePath = path.join(distPath, 'index.html')
    }
    if (!path.extname(filePath)) {
      filePath = path.join(distPath, 'index.html')
    }

    const resolved = path.resolve(filePath)
    const resolvedDist = path.resolve(distPath)
    if (!resolved.startsWith(resolvedDist + path.sep) && resolved !== resolvedDist) {
      logger.warn('[Protocol] Path traversal blokkolva:', request.url)
      filePath = path.join(distPath, 'index.html')
    }

    return net.fetch(pathToFileURL(filePath).toString())
  }
}
