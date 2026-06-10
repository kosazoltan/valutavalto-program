/**
 * EBC Valutavalto - centralizalt frontend strukturalt logger (V234 modul).
 *
 * Forras: vault/feedback/valutavalto-belso-log-audit-modul-tervezet-2026-05-18.md (5.2)
 *
 * - INFO / DEBUG: csak lokalisan (console)
 * - WARN / ERROR: lokalisan ES forward backend /api/v1/diagnostics/audit/log-ra
 *
 * Iparagi standard: a kliens-oldali strukturalt logok ugyanazon a sema-ban
 * mennek mint a backend (event_type, error_code, attrs.*) - igy a Loki/Grafana
 * query egysegesen tudja keresni a backend ES frontend hibakat egy trace_id-ra.
 *
 * Hasznalat:
 *   import { vvLogger } from '@/utils/vvLogger'
 *   vvLogger.error('VV-VOICE-001', 'voice.token_fetch_failed',
 *                  new Error('429 OpenAI rate limit'),
 *                  { worker_id: 'W-S011', branch: 'MV-001' })
 */
import { auditDiagnosticsApi, type FrontendLogEntry } from '@/services/api/diagnostics'
import { logger as localLogger } from './logger'

type ClientContext = 'CASHIER' | 'TREASURY_HQ' | 'RFM' | 'ADMIN'

/**
 * A kliens-tipus a build-time env-bol jon (Vite). NULL ha nem feliterted.
 *
 * Copilot PR #681 fix: a mapping most a kanonikus AppModeRoleConstants
 * appMode-okat hasznalja (penztar/ertektar/ertekszallito/full/rate-maker).
 * Lasd: frontend-react/src/types/electron.d.ts:428 + auth.test.ts.
 */
function detectClientContext(): ClientContext | undefined {
  const env = import.meta.env
  const mode = env.VITE_APP_MODE as string | undefined
  switch (mode) {
    case 'penztar':
      return 'CASHIER'
    case 'ertektar':
    case 'ertekszallito':
      return 'TREASURY_HQ'
    case 'rate-maker':
      return 'RFM'
    case 'full':
      return 'ADMIN'
    default:
      return undefined
  }
}

const CLIENT_CONTEXT = detectClientContext()
const CLIENT_VERSION = (import.meta.env.VITE_APP_VERSION as string | undefined) ?? 'unknown'
const IS_PROD = import.meta.env.PROD === true

// Copilot PR #681 P2 re-entrancy guard: ha az axios interceptor a 5xx valaszt
// vvLogger.error()-ra fordtja, infinite loop ert keletkezne (vvLogger.error ->
// forwardLog -> 5xx -> interceptor.vvLogger.error -> forwardLog ...). A flag
// megakadalyozza a recursive forward-ot.
let isCurrentlyForwarding = false

/**
 * Defensive: csak ERROR/WARN szintet kuldunk a backend-re.
 * INFO/DEBUG silently elesik (a backend automatikusan elutasitana).
 */
async function forwardToBackend(entry: FrontendLogEntry): Promise<void> {
  if (isCurrentlyForwarding) {
    // Re-entrant hivas (pl. axios interceptor a 5xx valaszbol indit vvLogger.error-t)
    // Csak lokalisan loggoljuk, NEM kuldunk ujabb backend forward-ot.
    if (!IS_PROD) {
      console.warn('[vvLogger] Skipping re-entrant forward:', entry.eventType)
    }
    return
  }
  isCurrentlyForwarding = true
  try {
    await auditDiagnosticsApi.forwardLog(entry)
  } catch (err) {
    if (!IS_PROD) {
      console.warn('[vvLogger] Backend forward failed:', err)
    }
  } finally {
    isCurrentlyForwarding = false
  }
}

function baseEntry(
  level: 'ERROR' | 'WARN',
  eventType: string,
  errorCode: string | undefined,
  message: string,
  attrs: Record<string, unknown> | undefined,
  cause?: Error | unknown,
): FrontendLogEntry {
  const stackTrace =
    cause instanceof Error ? cause.stack : typeof cause === 'string' ? cause : undefined

  return {
    level,
    eventType,
    errorCode,
    message: message.length > 500 ? message.substring(0, 500) : message,
    clientTs: new Date().toISOString(),
    clientContext: CLIENT_CONTEXT,
    clientVersion: CLIENT_VERSION,
    attrs,
    stackTrace,
  }
}

export const vvLogger = {
  /**
   * INFO szintu - csak lokalis console (backend NEM kapja).
   */
  info(eventType: string, attrs?: Record<string, unknown>): void {
    localLogger.info(eventType, JSON.stringify(attrs ?? {}))
  },

  /**
   * DEBUG szintu - csak dev mode-ban (production-ban silently).
   */
  debug(eventType: string, attrs?: Record<string, unknown>): void {
    localLogger.debug(eventType, JSON.stringify(attrs ?? {}))
  },

  /**
   * WARN szintu - lokalis console + backend forward.
   */
  warn(eventType: string, errorCode?: string, attrs?: Record<string, unknown>): void {
    const message = `${eventType}${errorCode ? ` [${errorCode}]` : ''}`
    localLogger.warn(eventType, message, attrs ?? {})
    void forwardToBackend(baseEntry('WARN', eventType, errorCode, message, attrs))
  },

  /**
   * ERROR szintu - lokalis console + backend forward.
   *
   * @param errorCode - kotelezo, AI-olvashato (pl. "VV-VOICE-001")
   *                    lasd packages/shared-logging/error-codes.yaml
   * @param eventType - uzleti esemeny ("voice.token_fetch_failed")
   * @param cause     - Error / hiba-objektum (stack trace a backend-re kuldve)
   * @param attrs     - szabad atributumok (PII-mossuk backend-en)
   */
  error(
    errorCode: string,
    eventType: string,
    cause?: Error | unknown,
    attrs?: Record<string, unknown>,
  ): void {
    const message = `${eventType} [${errorCode}]${cause instanceof Error ? `: ${cause.message}` : ''}`
    localLogger.error(eventType, message, cause)
    void forwardToBackend(baseEntry('ERROR', eventType, errorCode, message, attrs, cause))
  },
}

export default vvLogger
