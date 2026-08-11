/**
 * Electron main-process CONFIG + TOKEN store — platform-reteg.
 *
 * === MIERT VAN ITT (platform-refaktor, 2026-08-10, S1 szelet) ===
 * A `kozponti-client` es az `arfolyam-keszito-client` main.ts-e ezeket a
 * primitiveket BAJTRA AZONOSAN tartalmazta (fuggveny-szintu diff igazolta:
 * configPath k:81-83 / a:52-54, tokenPath k:85-87 / a:56-58,
 * readConfig k:89-99 / a:60-70, writeConfig k:101-107 / a:72-78,
 * valamint a secure-store/load/clear-token IPC-handlerek torzse).
 *
 * ============================================================================
 * !!! KRITIKUS INVARIANS - CALL-TIME UTVONAL-FELOLDAS (#ERR-INST-01) !!!
 * ============================================================================
 * A `configPath()` es `tokenPath()` az utvonalat MINDEN HIVASKOR ujra feloldja
 * az `app.getPath('userData')`-bol. EZT TILOS modul-szintu konstansba
 * cache-elni (`const CONFIG_PATH = ...`), mert:
 *
 *   A `kozponti-client/electron/main.ts` INDULAS KOZBEN ATALLITJA a userData-t:
 *     :653  activeAppMode = await determineStartupMode()   // BASE userData
 *     :660  app.setPath('userData', base/<mod>)            // mod-izolacio
 *     :666  registerIpcHandlers()                          // innentol a mod-almappa
 *
 *   Ha az utvonal import-idoben dolne el, a `setPath` UTANI hivasok a REGI
 *   (base) konyvtarra mutatnanak -> a `full` es a `rate-maker` mod config.json-ja
 *   es auth-token.bin-je CSENDBEN OSSZEOLVADNA (#ERR-INST-01 megszunne).
 *
 * A szokasos kapusor (typecheck / boundary / build) ezt a hibat NEM detektalna,
 * ezert a `scripts/check-platform-boundaries.mjs` kulon assertel ra.
 *
 * ============================================================================
 * !!! ADAT-SZEPARACIO ALAPJA - package.json `name` !!!
 * ============================================================================
 * A ket kliens azert NEM osztozik a config/token fajlon, mert az Electron a
 * `userData` utat az alkalmazas NEVEBOL oldja fel (`package.json` productName
 * ?? name) - NEM az electron-builder `appId`-bol:
 *   kozponti-client/package.json  name = "valuta-kozponti-client"
 *   arfolyam-keszito-client/...   name = "valuta-arfolyam-keszito-client"
 * Ha ezeket valaha "harmonizaljak", a ket kliens auth-tokenje es configja
 * osszeolvadna -> biztonsagi incidens. A boundary-kapu ezt is assertelja.
 *
 * ============================================================================
 * MI NEM KERULT IDE (szandekosan)
 * ============================================================================
 * - `getConfig` / `setConfig`: kliens-specifikus `app_mode` logika
 *   (kozponti: `activeAppMode` + `isWorkstationMode` validacio;
 *    arfolyam: hardcode 'rate-maker').
 * - `deleteConfig`: `app_mode` guardot tartalmaz -> kliens-oldali wrapper marad,
 *   ami a lenti `deleteConfigKey` primitivet hivja.
 * - A `secure-store-token` IPC-HANDLER: a torzse ugyan azonos, de `setAuthToken`-t
 *   is hiv, ami a KLIENS sajat `./local-first` moduljabol jon. A platform nem
 *   importalhat klienst (iranyszabaly), ezert a handler a kliensben marad es a
 *   lenti primitiveket hasznalja.
 * - `loadProductionUrls`: NEM azonos (log-prefix `[CentralWorkstation]` vs
 *   `[RateMaker]`).
 */

import { app, safeStorage } from 'electron'
import * as fs from 'node:fs'
import * as path from 'node:path'

const CONFIG_FILE_NAME = 'config.json'
const TOKEN_FILE_NAME = 'auth-token.bin'
/** Titkot tartalmazo fajlok jogosultsaga (owner read/write). */
const SECRET_FILE_MODE = 0o600

/**
 * A config.json abszolut utja.
 *
 * FIGYELEM: minden hivaskor ujra feloldja a userData-t - ez SZANDEKOS.
 * Lasd a fajl elejen a #ERR-INST-01 invarianst. NE cache-eld.
 */
export function configPath(): string {
  return path.join(app.getPath('userData'), CONFIG_FILE_NAME)
}

/**
 * A titkositott auth-token fajl abszolut utja.
 *
 * FIGYELEM: minden hivaskor ujra feloldja a userData-t - ez SZANDEKOS.
 * Lasd a fajl elejen a #ERR-INST-01 invarianst. NE cache-eld.
 */
export function tokenPath(): string {
  return path.join(app.getPath('userData'), TOKEN_FILE_NAME)
}

/** A teljes config beolvasasa; hianyzo/serult fajl eseten ures objektum. */
export function readConfig(): Record<string, string> {
  try {
    const raw = fs.readFileSync(configPath(), 'utf8')
    const parsed = JSON.parse(raw) as unknown
    return parsed && typeof parsed === 'object' && !Array.isArray(parsed)
      ? (parsed as Record<string, string>)
      : {}
  } catch {
    return {}
  }
}

/**
 * A teljes config atomikus kiirasa (tmp fajl + rename), 0600 jogosultsaggal.
 * Az atomikussag azert kell, hogy egy megszakadt iras ne hagyjon fel-config-ot.
 */
export function writeConfig(config: Record<string, string>): void {
  const target = configPath()
  fs.mkdirSync(path.dirname(target), { recursive: true })
  const tmp = `${target}.tmp`
  fs.writeFileSync(tmp, JSON.stringify(config, null, 2), {
    encoding: 'utf8',
    mode: SECRET_FILE_MODE,
  })
  fs.renameSync(tmp, target)
}

/**
 * EGY kulcs torlese a configbol - PRIMITIV, guard NELKUL.
 *
 * A kliensek `deleteConfig` wrappere adja hozza a sajat vedelmet (pl. a
 * kozponti/arfolyam nem engedi torolni az `app_mode` kulcsot).
 * A nev szandekosan `deleteConfigKey`, hogy ne utkozzon a
 * `penztar-client/electron/sqlite.ts` sajat, SQLite-alapu `deleteConfig`-javal.
 */
export function deleteConfigKey(key: string): void {
  const config = readConfig()
  delete config[key]
  writeConfig(config)
}

/**
 * Token titkositott perzisztalasa az OS kulcstarolojaval.
 *
 * @returns false, ha a platformon nincs elerheto titkositas (ilyenkor NEM irunk
 *          plaintext tokent lemezre - ez tudatos biztonsagi dontes).
 *
 * FONTOS: a hivo kliens felelossege, hogy sikeres tarolas utan a sajat
 * `setAuthToken(token)`-jet is meghivja (local-first / sync reteg), kulonben a
 * token nem jut el a szinkron-motorhoz. A platform ezt NEM teheti meg, mert az
 * a kliens modulja (kliens -> platform irany).
 */
export function storeToken(token: string): boolean {
  if (!safeStorage.isEncryptionAvailable()) {
    return false
  }
  fs.mkdirSync(app.getPath('userData'), { recursive: true })
  fs.writeFileSync(tokenPath(), safeStorage.encryptString(token), { mode: SECRET_FILE_MODE })
  return true
}

/** Perzisztalt token visszafejtese; hiba/hianyzo fajl eseten null. */
export function loadToken(): string | null {
  try {
    if (!safeStorage.isEncryptionAvailable() || !fs.existsSync(tokenPath())) return null
    return safeStorage.decryptString(fs.readFileSync(tokenPath()))
  } catch {
    return null
  }
}

/**
 * Perzisztalt token torlese.
 * @returns false, ha a torles hibaba utkozott (a hivo logolhatja).
 */
export function clearToken(): boolean {
  try {
    if (fs.existsSync(tokenPath())) fs.unlinkSync(tokenPath())
    return true
  } catch {
    return false
  }
}
