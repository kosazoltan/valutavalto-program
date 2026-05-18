/**
 * EBC Valutavalto belso log+audit modul - publikus API.
 *
 * Kozos package a frontend (React) + Electron 3 kliens szamara.
 * A backend (Spring Boot, Java) NEM importalja, hanem egy mirrorolt
 * Java-implementaciot tart (VVLogger.java + RedactingAppender.java).
 *
 * Forras: vault/feedback/valutavalto-belso-log-audit-modul-tervezet-2026-05-18.md
 */
export type {
  VVLogEntry,
  LogLevel,
  LogService,
  LogEnv,
  ErrorCategory,
  ErrorCodeEntry,
  ErrorCodeCatalog,
} from './log-schema'

export {
  redact,
  __REDACT_PATTERNS_FOR_TESTING,
  __REDACT_FIELDS_FOR_TESTING,
} from './redactor'
