/**
 * Heartbeat config — production-fagyás-detection rate-konfiguráció.
 *
 * 2026-04-29 v2.3.24 (Codex P1 + Sourcery 2 P2 PR #287 follow-up):
 *
 * KRITIKUS Codex P1 #287: a v2.3.23 `z.coerce.number()` JavaScript Number(...)
 * coerciót használt, ami silently elfogadta a `' 120000 '` (whitespace),
 * `'1e5'` (scientific), `'0x2710'` (hex) formátumokat. Ez VISELKEDÉSI
 * REGRESSZIÓ a v2.3.22 STRICT_INTEGER_PATTERN-hez képest, ami ezeket explicit
 * elutasította. Production-ban silently változtathatja a heartbeat cadence-et.
 *
 * Megoldás: **Zod idiomatic strict pattern** —
 * `z.string().regex().transform().pipe()`. Ez iparági Zod-pattern (NEM ad-hoc),
 * és:
 * - Strict integer regex (csak `^\d+$`, NEM `' 100 '`, `'1e5'`, `'0x2710'`)
 * - `transform(Number)` után Zod number constraints (`.int().min().max()`)
 * - Type-safe pipeline
 *
 * Sourcery PR #287 P2 follow-up:
 * 1. Raw value visszahozva a log üzenetbe (debug a misconfigured environment-hez)
 * 2. NINCS duplicate default — schema NEM tartalmaz `.default()`, helyette a
 *    function-szintű early-return kezeli a hiányzó env-et
 *
 * Iparági Zod-pattern referenciák:
 * - https://zod.dev/?id=transformations
 * - https://zod.dev/?id=pipe
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
 * Zod schema strict integer-string-validációhoz.
 *
 * `z.string().regex(/^\d+$/)` — CSAK pozitív, vezető-zero-mentes tiszta integer
 * string fogadható el. Nem fogad el:
 * - `' 100 '` (whitespace) — Codex P1 regression-szóró
 * - `'1e5'` (scientific notation) — Codex P1 regression-szóró
 * - `'0x2710'` (hex) — Codex P1 regression-szóró
 * - `'12.5'` (decimal) — `\d+` reject
 * - `'-100'` (negatív) — `\d+` reject
 *
 * `.transform((s) => parseInt(s, 10))` — string → number a regex után
 * (parseInt safe, mert a regex már garantálja a strict-integer formátumot).
 *
 * `.pipe(z.number().int().min().max())` — Zod number constraints range validation
 * + integer constraint (defensive, redundáns a regex-szel de explicit).
 */
const HeartbeatIntervalSchema = z.string()
  .regex(/^\d+$/, 'NEM strict-integer string')
  .transform((s) => parseInt(s, 10))
  .pipe(
    z.number()
      .int()
      .min(MIN_HEARTBEAT_INTERVAL_MS, `< ${MIN_HEARTBEAT_INTERVAL_MS} (DOS-protekció)`)
      .max(MAX_HEARTBEAT_INTERVAL_MS, `> ${MAX_HEARTBEAT_INTERVAL_MS} (fagyás-detection felbontás)`),
  )

/**
 * Olvassa az `import.meta.env.VITE_HEARTBEAT_INTERVAL_MS` env-változót,
 * Zod schema-val validálja, és valid esetben a parsed értéket adja vissza.
 *
 * Hiányzó env (typeof !== string vagy üres) → silent fallback (várt eset,
 * NEM warning, NEM schema-validáció).
 * Invalid format/range → `logger.warn` a raw value-val (debug-friendly) +
 * default fallback.
 */
export function getHeartbeatIntervalMs(): number {
  const raw = import.meta.env.VITE_HEARTBEAT_INTERVAL_MS
  // Hiányzó env: silent default (NEM schema-default — schema csak invalid format-ot kezel)
  if (typeof raw !== 'string' || raw.trim().length === 0) {
    return DEFAULT_HEARTBEAT_INTERVAL_MS
  }
  const result = HeartbeatIntervalSchema.safeParse(raw)
  if (!result.success) {
    logger.warn(
      'config/heartbeat',
      `VITE_HEARTBEAT_INTERVAL_MS='${raw}' invalid: ${result.error.message}, default ${DEFAULT_HEARTBEAT_INTERVAL_MS} ms használva.`,
    )
    return DEFAULT_HEARTBEAT_INTERVAL_MS
  }
  return result.data
}

/** Kiszámolt heartbeat-intervallum (modul-szintű, csak egyszer évalulódik). */
export const HEARTBEAT_INTERVAL_MS = getHeartbeatIntervalMs()
