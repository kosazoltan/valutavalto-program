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
};

export default logger;
