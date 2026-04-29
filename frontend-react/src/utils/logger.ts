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
   * 2026-04-29 v2.3.17 (Codex P1 PR #280 follow-up):
   * Dedikált heartbeat marker — production-ban is mindig fut.
   *
   * KRITIKUS: a penztar-client Electron `mainWindow.webContents.on('console-message')`
   * handler `level >= 2` (warning/error) szűréssel forward-ol az electron-log fájlba.
   * Ezért `console.log` (level 0=info) NEM kerül a production log-ba, így a
   * fagyás-detection elveszne. A v2.3.16-ben elsőre `console.log`-ra váltottam, de
   * a Codex észrevette → most `console.warn` + `[HEARTBEAT]` prefix.
   *
   * A `[HEARTBEAT]` prefix egyértelmű marker — a monitoring/alerting eszköz
   * (pl. Sentry alert filter) szűrheti, így NEM false-positive-ként kezelődik.
   *
   * Use case: App.tsx 60s-onként hívja a renderer életjelhez.
   * Forrás: penztar-client/electron/main.ts:219-222 (level >= 2 forward)
   */
  heartbeat(tag: string, message: string, ...args: unknown[]): void {
    // console.warn — szükséges, hogy az Electron renderer-console-message
    // forward (level >= 2) felvegye és az electron-log fájlba mentse.
    // A [HEARTBEAT] prefix a monitoring-szűrő számára egyértelmű marker.
    console.warn(`[HEARTBEAT] ${formatTag(tag)}`, message, ...args);
  },
};

export default logger;
