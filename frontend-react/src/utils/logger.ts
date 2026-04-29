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
   * 2026-04-29 v2.3.16 (Sourcery PR #276 P2 follow-up):
   * Dedikált heartbeat marker — production-ban is mindig fut, de NEM warning-szintű
   * (vagyis a monitoring/alerting NEM riasztja false-positive-ként).
   * Direkt `console.log`-ot használ a logger.info bypass-szal — `[HEARTBEAT]` prefix
   * egyértelmű marker a fagyás-detection-hez electron-log fájl-elemzésnél.
   *
   * Use case: App.tsx 60s-onként hívja a renderer életjelhez.
   */
  heartbeat(tag: string, message: string, ...args: unknown[]): void {
    // Bypass shouldLog filter — a heartbeat MINDIG kell logoljon (production is)
    console.log(`[HEARTBEAT] ${formatTag(tag)}`, message, ...args);
  },
};

export default logger;
