/**
 * EBC Valutavalto - Electron main process strukturalt logger (penztaros kliens).
 *
 * PLATFORM-REFAKTOR (2026-08-10): a tenyleges implementacio a kozos
 * platform-retegben el:
 *
 *   packages/electron-platform/src/vv-logger.ts
 *
 * Korabban ez a modul HAROM kliensben letezett kulon peldanyban (193 / 192 / 192
 * sor), amelyek egymastol MINDOSSZE a default `clientContext`-ben tertek el
 * (CASHIER / TREASURY_HQ / RFM) - a logika bajtra azonos volt. A klon-meres
 * (2026-08-10) ezt komponensek kozotti duplikaciokent azonositotta.
 *
 * Ez a fajl mostantol csak a KLIENS-SPECIFIKUS konfiguraciot koti be
 * (`clientContext: 'CASHIER'`), es valtozatlan felulettel exportal tovabb, hogy a
 * hivok ne valtozzanak.
 *
 * Hasznalat (valtozatlan):
 *   import { vvLogger } from './vv-logger'
 *   vvLogger.error('VV-VOICE-001', 'voice.token_fetch_failed', new Error('429'))
 */

import { createVvLogger, type ClientContext } from '../../packages/electron-platform/src'

const handle = createVvLogger({ clientContext: 'CASHIER' })

export type { ClientContext }

/** Strukturalt logger - lokalis electron-log + backend audit-forward. */
export const vvLogger = handle.vvLogger

/** A JWT-tokent a renderer kuldi a main-nek IPC-n at, amikor a worker login-ol. */
export const setAuthToken = handle.setAuthToken

/**
 * Konfiguracio - a main.ts hivhatja inditaskor (baseUrl / context override).
 * A kliens-specifikus default context (`CASHIER`) mar be van allitva.
 */
export const configureVvLogger = handle.configure

export default vvLogger
