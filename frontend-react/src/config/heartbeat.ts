/**
 * Heartbeat config — production-fagyás-detection rate-konfiguráció.
 *
 * 2026-04-29 v2.3.20 (Sourcery PR #283 P2 follow-up):
 * Központi config module a heartbeat-intervallumhoz, hogy:
 * 1) audit-elhető legyen az érték (NEM inline App.tsx-ben)
 * 2) tesztelhető override-olható (test setup, e2e)
 * 3) production-ban env-flag-szel finomhangolható (VITE_HEARTBEAT_INTERVAL_MS)
 *
 * 2026-04-29 v2.3.21 (Sourcery PR #284 P2 follow-up):
 * - MIN/MAX/DEFAULT konstansok EXPORTÁLVA (single source of truth a tesztekhez,
 *   a tooling-hez, a docs-hoz)
 * - Invalid env-flag esetén `logger.warn` loggolás (NEM silent fallback) —
 *   misconfigured environment-ek detektálhatók
 *
 * 2026-04-29 v2.3.22 (Sourcery PR #285 P2 follow-up):
 * - Strict numerikus parse: regex-alapú teljes-string validáció (`/^-?\d+$/`)
 *   a `parseInt(raw, 10)` helyett, hogy NE fogadja el silently a `'123abc'`
 *   vagy `' 123 '` értékeket
 * - Header komment frissítve: `logger.warn` (NEM `console.warn`)
 */

import { logger } from '../utils/logger'

/** Default heartbeat interval (60s). */
export const DEFAULT_HEARTBEAT_INTERVAL_MS = 60_000

/** Minimum allowed heartbeat interval (10s) — DOS-protekció a renderer-re. */
export const MIN_HEARTBEAT_INTERVAL_MS = 10_000

/** Maximum allowed heartbeat interval (600s) — fagyás-detection felbontás minimum. */
export const MAX_HEARTBEAT_INTERVAL_MS = 600_000

/** Strict numeric pattern: csak teljes-string ASCII pozitív/negatív integer (NEM fogad el szóközt vagy postfix-et) */
const STRICT_INTEGER_PATTERN = /^-?\d+$/

/**
 * Olvassa az `import.meta.env.VITE_HEARTBEAT_INTERVAL_MS` env-változót,
 * és validálja a [MIN, MAX] tartományba. Invalid vagy hiányzó érték esetén
 * a DEFAULT_HEARTBEAT_INTERVAL_MS-t adja vissza, és `logger.warn` jelzéssel
 * dokumentálja az okot (misconfigured environment detektálható).
 *
 * Hiányzó env (typeof !== string vagy üres) → silent fallback (várt eset,
 * NEM warning).
 * NEM strict-integer (pl. '123abc', ' 123 ', '12.5') → `logger.warn`.
 * Tartományon-kívüli érték → `logger.warn`.
 */
export function getHeartbeatIntervalMs(): number {
  const raw = import.meta.env.VITE_HEARTBEAT_INTERVAL_MS
  // Hiányzó env: nem warning (várt default)
  if (typeof raw !== 'string' || raw.trim().length === 0) {
    return DEFAULT_HEARTBEAT_INTERVAL_MS
  }
  // Strict numeric validation: csak teljes-string integer fogadható el
  // (parseInt('123abc', 10) === 123 lenne, ami NEM kívánatos)
  if (!STRICT_INTEGER_PATTERN.test(raw)) {
    logger.warn(
      'config/heartbeat',
      `VITE_HEARTBEAT_INTERVAL_MS NEM strict-integer ('${raw}'), default ${DEFAULT_HEARTBEAT_INTERVAL_MS} ms használva.`,
    )
    return DEFAULT_HEARTBEAT_INTERVAL_MS
  }
  const parsed = Number(raw)
  // Number.isFinite + integer-check biztosítja, hogy NaN/Infinity kizárva
  if (!Number.isFinite(parsed)) {
    logger.warn(
      'config/heartbeat',
      `VITE_HEARTBEAT_INTERVAL_MS NEM-finite ('${raw}'), default ${DEFAULT_HEARTBEAT_INTERVAL_MS} ms használva.`,
    )
    return DEFAULT_HEARTBEAT_INTERVAL_MS
  }
  if (parsed < MIN_HEARTBEAT_INTERVAL_MS || parsed > MAX_HEARTBEAT_INTERVAL_MS) {
    logger.warn(
      'config/heartbeat',
      `VITE_HEARTBEAT_INTERVAL_MS=${parsed} a [${MIN_HEARTBEAT_INTERVAL_MS}, ${MAX_HEARTBEAT_INTERVAL_MS}] tartományon kívül, default ${DEFAULT_HEARTBEAT_INTERVAL_MS} ms használva.`,
    )
    return DEFAULT_HEARTBEAT_INTERVAL_MS
  }
  return parsed
}

/** Kiszámolt heartbeat-intervallum (modul-szintű, csak egyszer évalulódik). */
export const HEARTBEAT_INTERVAL_MS = getHeartbeatIntervalMs()
