/**
 * Centralized logger utility.
 *
 * In production builds console output is suppressed.
 * Replace all direct console.log / console.warn / console.error calls with
 * logger.info / logger.warn / logger.error respectively.
 */

const isDev = import.meta.env.DEV;

type LogLevel = 'debug' | 'info' | 'warn' | 'error';

function shouldLog(level: LogLevel): boolean {
  if (isDev) return true;
  // In production only warn and error are emitted
  return level === 'warn' || level === 'error';
}

function formatTag(tag: string): string {
  return `[${tag}]`;
}

export const logger = {
  debug(tag: string, message: string, ...args: unknown[]): void {
    if (shouldLog('debug')) {
      console.debug(formatTag(tag), message, ...args);
    }
  },

  info(tag: string, message: string, ...args: unknown[]): void {
    if (shouldLog('info')) {
      console.log(formatTag(tag), message, ...args);
    }
  },

  warn(tag: string, message: string, ...args: unknown[]): void {
    if (shouldLog('warn')) {
      console.warn(formatTag(tag), message, ...args);
    }
  },

  error(tag: string, message: string, ...args: unknown[]): void {
    if (shouldLog('error')) {
      console.error(formatTag(tag), message, ...args);
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
   * Rate-limiting: a hívó (App.tsx) 60s-onként hív; a heartbeat-throttle a hívó
   * felelőssége (ne hívja másodpercenként). Ha sűrűbb monitoring kell, a
   * `HEARTBEAT_INTERVAL_MS` env-config állítsa a hívási intervallumot.
   */
  heartbeat(tag: string, message: string, ...args: unknown[]): void {
    // A `[HEARTBEAT]` prefix lehetővé teszi a monitoring-szűrőnek, hogy NEM
    // tényleges warning-ként kezelje. Az Electron renderer-console-message
    // forward warning/error szűrőjén átmegy.
    console.warn(`[HEARTBEAT] ${formatTag(tag)}`, message, ...args);
  },
};

export default logger;
