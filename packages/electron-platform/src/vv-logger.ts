/**
 * EBC Valutavalto - Electron main process strukturalt logger (V234 modul).
 *
 * === PLATFORM-REteg (2026-08-10) ===
 * Ez a fajl a `packages/electron-platform` KOZOS forras-igazsaga. Korabban HAROM
 * kliensben letezett kulon peldanyban (`penztar-client`, `kozponti-client`,
 * `arfolyam-keszito-client`), amelyek egymastol MINDOSSZE a default
 * `clientContext`-ben tertek el (CASHIER / TREASURY_HQ / RFM) - a logika bajtra
 * azonos volt. A duplikacio megszuntetve; a kliens-specifikus resz mostantol
 * KOTELEZO parameter (l. {@link createVvLogger}), nem rejtett default - igy nem
 * tud csendben elcsuszni.
 *
 * Forras: vault/feedback/valutavalto-belso-log-audit-modul-tervezet-2026-05-18.md (5.3)
 *
 * Wrapper az electron-log/main ele:
 * - lokalisan logol (electron-log -> AppData/logs/main.log)
 * - WARN / ERROR szint a backend /api/v1/diagnostics/audit/log endpointra forwardol
 *   (backend: AuditDiagnosticsController @PostMapping("/log"))
 *
 * Iparagi standard: a kliens-oldali strukturalt logok ugyanazon a sema-ban
 * mennek mint a backend (event_type, error_code, attrs.*) - igy a Loki/Grafana
 * query egysegesen tudja keresni a backend ES Electron klienseket egy trace_id-ra.
 *
 * KULONBSEG az error-reporter.ts-tol:
 * - error-reporter: unhandled exception / crash forward (client_error_log tabla)
 * - vv-logger: STRUKTURALT business event-ek (transaction.committed, voice.error, etc)
 *   -> V234 audit_log tabla (event_type + error_code + AI-olvashato).
 *
 * Hasznalat (kliens main.ts):
 *   import { createVvLogger } from '../../packages/electron-platform/src'
 *   const { vvLogger, setAuthToken } = createVvLogger({ clientContext: 'CASHIER' })
 */

import { app, net } from 'electron'
import log from 'electron-log/main'
import { release as getOsRelease, type as getOsType } from 'node:os'

const ENDPOINT_PATH = '/api/v1/diagnostics/audit/log'
// Copilot PR #681: token-bucket helyett egyszeru "drop counter + summary" minta.
// Az anti-spam fix interval-on belul a forward-okat skip-eljuk, de
// szamoljuk a `droppedSinceLastForward` countert, es a kovetkezo forward-on
// hozzaadjuk az attrs.drop_count mezohoz - igy NEM tunik el nyomtalanul a signal.
const ANTI_SPAM_MIN_INTERVAL_MS = 2_000
const MAX_MESSAGE_LEN = 500
const MAX_STACK_LEN = 4000

const DEFAULT_BACKEND_BASE_URL = 'https://excvaluta.com'

/** Kliens-kontextus a backend audit_log `client_context` mezojehez. */
export type ClientContext = 'CASHIER' | 'TREASURY_HQ' | 'RFM' | 'ADMIN'

export interface VvLogPayload {
  level: 'ERROR' | 'WARN'
  eventType: string
  errorCode?: string
  message: string
  clientTs: string
  traceId?: string
  clientContext: ClientContext
  clientVersion: string
  attrs?: Record<string, unknown>
  stackTrace?: string
}

export interface VvLogger {
  info(eventType: string, attrs?: Record<string, unknown>): void
  debug(eventType: string, attrs?: Record<string, unknown>): void
  warn(eventType: string, errorCode?: string, attrs?: Record<string, unknown>): void
  /**
   * ERROR szintu - lokalis electron-log + backend forward.
   *
   * @param errorCode - kotelezo, AI-olvashato (pl. 'VV-VOICE-001').
   *                    Lasd packages/shared-logging/error-codes.yaml.
   */
  error(
    errorCode: string,
    eventType: string,
    cause?: Error | unknown,
    attrs?: Record<string, unknown>,
  ): void
}

export interface VvLoggerOptions {
  /**
   * KOTELEZO: melyik kliens logol. Korabban ez fajlonkenti rejtett default volt
   * a harom masolatban - ezert kell most explicit megadni.
   */
  clientContext: ClientContext
  /** production: 'https://excvaluta.com' (default). */
  baseUrl?: string
}

export interface VvLoggerHandle {
  vvLogger: VvLogger
  /** A JWT-tokent a renderer kuldi a main-nek IPC-n at, amikor a worker login-ol. */
  setAuthToken(token: string | null): void
  /** Futasidoju atkonfiguralas (baseUrl / context). */
  configure(opts: { baseUrl?: string; clientContext?: ClientContext }): void
}

function truncate(s: string | undefined, max: number): string | undefined {
  if (!s) return s
  return s.length > max ? `${s.substring(0, max)}...[truncated]` : s
}

/**
 * Logger-peldany letrehozasa. Peldanyonkent zart allapot (token, anti-spam
 * counter) - a korabbi modul-szintu globalis valtozok helyett, hogy a kozos
 * platform-modul tobb kliensben (es tesztben) egymastol fuggetlenul mukodjon.
 */
export function createVvLogger(options: VvLoggerOptions): VvLoggerHandle {
  let backendBaseUrl = (options.baseUrl ?? DEFAULT_BACKEND_BASE_URL).replace(/\/+$/, '')
  let clientContext: ClientContext = options.clientContext
  let authBearerToken: string | null = null
  let lastForwardMs = 0
  let droppedSinceLastForward = 0

  function buildPayload(
    level: VvLogPayload['level'],
    eventType: string,
    errorCode: string | undefined,
    message: string,
    attrs: Record<string, unknown> | undefined,
    cause?: Error | unknown,
  ): VvLogPayload {
    const stack =
      cause instanceof Error ? cause.stack : typeof cause === 'string' ? cause : undefined
    return {
      level,
      eventType,
      errorCode,
      message: truncate(message, MAX_MESSAGE_LEN) ?? message,
      clientTs: new Date().toISOString(),
      clientContext,
      clientVersion: app.getVersion(),
      attrs: {
        ...attrs,
        // Copilot PR #681 P1: dynamic OS label (NEM hardcoded Windows)
        'electron.os': `${getOsType()} ${getOsRelease()}`,
      },
      stackTrace: truncate(stack, MAX_STACK_LEN),
    }
  }

  /** Backend forward - send-and-forget, NE blokkolj. */
  function forwardToBackend(payload: VvLogPayload): void {
    if (!authBearerToken) {
      // A kliens nincs bejelentkezve - a backend /log endpoint @PreAuthorize('isAuthenticated()')
      // elutasitana. Csak lokalisan logoljunk.
      return
    }
    const now = Date.now()
    if (now - lastForwardMs < ANTI_SPAM_MIN_INTERVAL_MS) {
      // Copilot PR #681 P1: dropolt event-eket szamoljuk, NEM dobjuk el silently
      droppedSinceLastForward += 1
      return
    }
    lastForwardMs = now

    // Hozzaadjuk a drop_count-ot az attrs-hoz hogy a backend lassa a missing signalt
    const enrichedPayload: VvLogPayload =
      droppedSinceLastForward > 0
        ? {
            ...payload,
            attrs: { ...payload.attrs, 'vv.dropped_since_last': droppedSinceLastForward },
          }
        : payload
    droppedSinceLastForward = 0

    try {
      const req = net.request({ method: 'POST', url: `${backendBaseUrl}${ENDPOINT_PATH}` })
      req.setHeader('Content-Type', 'application/json')
      req.setHeader('Authorization', `Bearer ${authBearerToken}`)
      req.setHeader('User-Agent', `ValutaElectronVVLogger/${app.getVersion()}`)
      req.on('error', () => {
        /* csendben */
      })
      req.on('response', (res) => {
        res.on('data', () => {
          /* drain */
        })
        res.on('end', () => {
          /* finished */
        })
      })
      req.write(JSON.stringify(enrichedPayload))
      req.end()
    } catch {
      /* csendben */
    }
  }

  const vvLogger: VvLogger = {
    info(eventType: string, attrs?: Record<string, unknown>): void {
      log.info(`[VV] event=${eventType}`, attrs ?? {})
    },

    debug(eventType: string, attrs?: Record<string, unknown>): void {
      log.debug(`[VV] event=${eventType}`, attrs ?? {})
    },

    warn(eventType: string, errorCode?: string, attrs?: Record<string, unknown>): void {
      const msg = `${eventType}${errorCode ? ` [${errorCode}]` : ''}`
      log.warn(`[VV] ${msg}`, attrs ?? {})
      forwardToBackend(buildPayload('WARN', eventType, errorCode, msg, attrs))
    },

    error(
      errorCode: string,
      eventType: string,
      cause?: Error | unknown,
      attrs?: Record<string, unknown>,
    ): void {
      const causeMsg = cause instanceof Error ? `: ${cause.message}` : ''
      const msg = `${eventType} [${errorCode}]${causeMsg}`
      log.error(`[VV] ${msg}`, cause, attrs ?? {})
      forwardToBackend(buildPayload('ERROR', eventType, errorCode, msg, attrs, cause))
    },
  }

  return {
    vvLogger,
    setAuthToken(token: string | null): void {
      authBearerToken = token
    },
    configure(opts: { baseUrl?: string; clientContext?: ClientContext }): void {
      if (opts.baseUrl) backendBaseUrl = opts.baseUrl.replace(/\/+$/, '')
      if (opts.clientContext) clientContext = opts.clientContext
    },
  }
}
