/**
 * Centralized logger utility.
 *
 * In production builds console output is suppressed.
 * Replace all direct console.log / console.warn / console.error calls with
 * logger.info / logger.warn / logger.error respectively.
 */

const isDev = import.meta.env.DEV

type LogLevel = 'debug' | 'info' | 'warn' | 'error'

function shouldLog(level: LogLevel): boolean {
  if (isDev) return true
  // In production only warn and error are emitted
  return level === 'warn' || level === 'error'
}

function formatTag(tag: string): string {
  return `[${tag}]`
}

/**
 * TD1 biztonsági sanitizáló (LOGGER-RAW-ERR + PIN-IN-LOGS).
 * Error/AxiosError → biztonságos string; plain objektum → érzékeny-kulcs-redaktált
 * mély klón; primitívek változatlanul. Fail-closed: dev és production azonos.
 * SZÁNDÉKOSAN nincs errorHandling/axios import — a logger leaf modul marad
 * (kör-import-kockázat kizárva), az AxiosError-t duck-typing ismeri fel.
 */
const SENSITIVE_KEYS = new Set([
  'config',
  'headers',
  'authorization',
  'token',
  'password',
  'pin',
  'data',
  'secret',
  'cookie',
  'accesstoken',
  'refreshtoken',
  'credentials',
])
const MAX_DEPTH = 3

interface AxiosLikeError extends Error {
  isAxiosError?: boolean
  code?: string
  response?: { status?: number; data?: unknown }
  config?: { method?: string; url?: string }
}

function describeError(err: Error): string {
  const parts: string[] = [`${err.name}: ${err.message}`]
  const ax = err as AxiosLikeError
  if (ax.isAxiosError === true) {
    if (typeof ax.code === 'string') parts.push(`code=${ax.code}`)
    const status = ax.response?.status
    if (typeof status === 'number') parts.push(`status=${status}`)
    const url = ax.config?.url
    if (typeof url === 'string') {
      const method = (ax.config?.method ?? 'get').toUpperCase()
      parts.push(`${method} ${url.split('?')[0]}`)
    }
    const data = ax.response?.data
    if (data && typeof data === 'object') {
      const msg = (data as { message?: unknown }).message ?? (data as { error?: unknown }).error
      if (typeof msg === 'string') parts.push(`server: ${msg}`)
    }
    return parts.join(' | ')
  }
  const out = parts.join(' | ')
  return typeof err.stack === 'string' ? `${out}\n${err.stack}` : out
}

function sanitizeValue(value: unknown, depth: number, seen: WeakSet<object>): unknown {
  if (value === null || value === undefined) return value
  const t = typeof value
  if (t === 'string' || t === 'number' || t === 'boolean' || t === 'bigint') return value
  if (value instanceof Error) return describeError(value)
  if (value instanceof Date) return value.toISOString()
  if (t === 'function') return '[Function]'
  if (t !== 'object') return String(value)
  const obj = value as object
  if (seen.has(obj)) return '[Circular]'
  if (depth >= MAX_DEPTH) return '[Object]'
  seen.add(obj)
  try {
    if (Array.isArray(obj)) {
      return obj.map((item) => sanitizeValue(item, depth + 1, seen))
    }
    const out: Record<string, unknown> = {}
    for (const [key, val] of Object.entries(obj)) {
      out[key] = SENSITIVE_KEYS.has(key.toLowerCase())
        ? '[REDACTED]'
        : sanitizeValue(val, depth + 1, seen)
    }
    return out
  } catch {
    // pl. dobó getter az Object.entries alatt — fail-closed placeholder
    return '[Unserializable]'
  } finally {
    seen.delete(obj) // path-alapú ciklusdetektálás: DAG-újralátogatás engedett
  }
}

function sanitizeArgs(args: unknown[]): unknown[] {
  return args.map((arg) => {
    try {
      return sanitizeValue(arg, 0, new WeakSet())
    } catch {
      return '[Unloggable]'
    }
  })
}

export const logger = {
  debug(tag: string, message: string, ...args: unknown[]): void {
    if (shouldLog('debug')) {
      console.debug(formatTag(tag), message, ...sanitizeArgs(args))
    }
  },

  info(tag: string, message: string, ...args: unknown[]): void {
    if (shouldLog('info')) {
      console.log(formatTag(tag), message, ...sanitizeArgs(args))
    }
  },

  warn(tag: string, message: string, ...args: unknown[]): void {
    if (shouldLog('warn')) {
      console.warn(formatTag(tag), message, ...sanitizeArgs(args))
    }
  },

  error(tag: string, message: string, ...args: unknown[]): void {
    if (shouldLog('error')) {
      console.error(formatTag(tag), message, ...sanitizeArgs(args))
    }
  },

  /**
   * Dedikált heartbeat marker production-fagyás-detection-hez.
   *
   * Az Electron renderer→main console-message forward csak warning/error-szintet
   * továbbít az electron-log fájlba (info-szintű üzenetek silently elsüllyednek
   * production-ban). Ezért `console.warn` szükséges, hogy a heartbeat eljusson
   * a fájl-szintű loghoz, ahol a fagyás-detection elemzi.
   *
   * A `[HEARTBEAT]` prefix egyértelmű marker — a monitoring/alerting tooling
   * szűrheti, így NEM false-positive warning-ként kezelődik.
   *
   * Rate-konfiguráció: a hívási intervallumot a `config/heartbeat.ts` központi
   * modul határozza meg (`HEARTBEAT_INTERVAL_MS`). Env-flag override:
   * `VITE_HEARTBEAT_INTERVAL_MS` (10s..600s tartományban validálva).
   */
  heartbeat(tag: string, message: string, ...args: unknown[]): void {
    // A `[HEARTBEAT]` prefix lehetővé teszi a monitoring-szűrőnek, hogy NEM
    // tényleges warning-ként kezelje. Az Electron renderer-console-message
    // forward warning/error szűrőjén átmegy.
    console.warn(`[HEARTBEAT] ${formatTag(tag)}`, message, ...sanitizeArgs(args))
  },
}

export default logger
