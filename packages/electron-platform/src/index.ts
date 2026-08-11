/**
 * `@valuta/electron-platform` — kozos Electron main-process platform-reteg
 * a Valutavalto kliensekhez (penztar / kozponti / arfolyam-keszito).
 *
 * === MIERT LETEZIK EZ A CSOMAG ===
 * A 2026-08-10-i klon-meres (10 001 indexelt fuggvenytorzs) 102 bajtra azonos
 * duplikatumot talalt, amelybol 27 komponensek KOZOTTI. A duplikacio tomege NEM
 * a penzugyi magban van, hanem az Electron-kliensek infrastrukturajaban.
 * Ez a csomag ennek a kozos retegnek a forras-igazsaga.
 *
 * Testvercsomagok (azonos minta, mar bevalt):
 *   - `packages/local-first-core`  - offline/local-first mag
 *   - `packages/shared-logging`    - kozos log-sema + PII redactor
 *   - `packages/shared-ipc`        - Electron IPC kontraktus
 *   - `packages/shared-api`        - OpenAPI -> TS tipusok
 *
 * === IRANYSZABALY (kotelezo) ===
 * Kliens -> platform importalhat. Kliens -> KLIENS SOHA.
 * Ha ket kliensnek ugyanaz kell, az a platformba kerul.
 *
 * === MI KERULHET IDE ===
 * Csak BIZONYITOTTAN azonos logika. A "hasonlo, de nem azonos" kod osszevonasa
 * penzugyi rendszerben regresszios kockazat, nem nyereseg - pl. az `api-proxy`
 * harom valtozata (345 / 330 / 201 sor) tudatosan elter (a kozponti FK-051 v2
 * whitelist `isBinary` fixet tartalmaz, ami .xlsx-korrupciot javitott), ezert
 * NEM kerult ide.
 */

export {
  createVvLogger,
  type ClientContext,
  type VvLogger,
  type VvLoggerHandle,
  type VvLoggerOptions,
  type VvLogPayload,
} from './vv-logger'

export {
  GoogleOAuthFailedException,
  performGoogleOAuthFlow,
  performGoogleOAuthFlowWithBackendLogin,
  performPasswordLoginMainProcess,
  type GoogleOAuthResult,
  type GoogleOAuthError,
} from './google-oauth'

export {
  configPath,
  tokenPath,
  readConfig,
  writeConfig,
  deleteConfigKey,
  storeToken,
  loadToken,
  clearToken,
} from './config-store'

export { resolveWasmPath } from './local-first-paths'
