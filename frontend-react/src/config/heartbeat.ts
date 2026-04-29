/**
 * Heartbeat config — production-fagyás-detection rate-konfiguráció.
 *
 * 2026-04-29 v2.3.23 (Zod-refaktor — Hallucinációs Kör Megszüntetése mandate):
 * Iparági standard validáció Zod schema-val a 6 iterációs ad-hoc megoldás
 * helyett. Egyetlen schema-validátor lefedi:
 * - Strict numeric parse (`z.coerce.number()` — `'123abc'` reject)
 * - Integer-only (`.int()` — `'12.5'` reject)
 * - Range validation (`.min(MIN).max(MAX)` — out-of-range warn + default)
 * - Default fallback (`.default(DEFAULT)` — hiányzó env)
 * - Type-safe (TypeScript inference)
 * - Hibaüzenet-formázás (`ZodError`)
 *
 * Forrás: Zod 3.22.4 (már `package.json`-ben az `@hookform/resolvers` miatt).
 * Iparági pattern: `dotenv + Zod` env-validation (Vite + TypeScript projektek).
 *
 * Vault: D:\valutavalto-vault\feedback\hallucinacio-megszuntetese.md
 */

import { z } from 'zod'
import { logger } from '../utils/logger'

/** Default heartbeat interval (60s). */
export const DEFAULT_HEARTBEAT_INTERVAL_MS = 60_000

/** Minimum allowed heartbeat interval (10s) — DOS-protekció a renderer-re. */
export const MIN_HEARTBEAT_INTERVAL_MS = 10_000

/** Maximum allowed heartbeat interval (600s) — fagyás-detection felbontás minimum. */
export const MAX_HEARTBEAT_INTERVAL_MS = 600_000

/**
 * Zod schema a heartbeat-intervallum validációjához.
 *
 * `z.coerce.number()` automatikusan stringet → számra konvertál (Vite env-vars
 * mindig string-típusúak `import.meta.env`-ben).
 * `.int()` integer-only constraint (NEM fogad el `12.5`-ot vagy `'123abc'`-t).
 * `.min/.max` range validation.
 * `.default()` fallback hiányzó / undefined env esetén.
 *
 * Type-inferenct: `HeartbeatConfig.intervalMs: number`.
 */
const HeartbeatConfigSchema = z.object({
  intervalMs: z.coerce.number()
    .int()
    .min(MIN_HEARTBEAT_INTERVAL_MS)
    .max(MAX_HEARTBEAT_INTERVAL_MS)
    .default(DEFAULT_HEARTBEAT_INTERVAL_MS),
})

/**
 * Olvassa az `import.meta.env.VITE_HEARTBEAT_INTERVAL_MS` env-változót,
 * Zod schema-val validálja, és valid esetben a parsed értéket adja vissza.
 *
 * Validation-failure esetén `logger.warn` jelzéssel dokumentálja a Zod
 * hibaüzenetet, és a default értékre esik vissza (misconfigured environment
 * detektálható az electron-log fájlban).
 */
export function getHeartbeatIntervalMs(): number {
  const result = HeartbeatConfigSchema.safeParse({
    intervalMs: import.meta.env.VITE_HEARTBEAT_INTERVAL_MS,
  })
  if (!result.success) {
    logger.warn(
      'config/heartbeat',
      `VITE_HEARTBEAT_INTERVAL_MS validáció sikertelen, default ${DEFAULT_HEARTBEAT_INTERVAL_MS} ms használva. Hiba: ${result.error.message}`,
    )
    return DEFAULT_HEARTBEAT_INTERVAL_MS
  }
  return result.data.intervalMs
}

/** Kiszámolt heartbeat-intervallum (modul-szintű, csak egyszer évalulódik). */
export const HEARTBEAT_INTERVAL_MS = getHeartbeatIntervalMs()
