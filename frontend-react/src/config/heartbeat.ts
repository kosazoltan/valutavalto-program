/**
 * Heartbeat config — production-fagyás-detection rate-konfiguráció.
 *
 * 2026-04-29 v2.3.20 (Sourcery PR #283 P2 follow-up):
 * Központi config module a heartbeat-intervallumhoz, hogy:
 * 1) audit-elhető legyen az érték (NEM inline App.tsx-ben)
 * 2) tesztelhető override-olható (test setup, e2e)
 * 3) production-ban env-flag-szel finomhangolható (VITE_HEARTBEAT_INTERVAL_MS)
 *
 * Default: 60s (60_000 ms) — 1 percenként 1 üzenet, ~1440 sor/nap user-enként.
 * Min: 10s (10_000 ms) — DOS-protekció (renderer-re).
 * Max: 600s (600_000 ms) — fagyás-detection-felbontás minimum.
 */

const DEFAULT_HEARTBEAT_INTERVAL_MS = 60_000
const MIN_HEARTBEAT_INTERVAL_MS = 10_000
const MAX_HEARTBEAT_INTERVAL_MS = 600_000

/**
 * Olvassa az `import.meta.env.VITE_HEARTBEAT_INTERVAL_MS` env-változót,
 * és validálja a [MIN, MAX] tartományba. Hibás vagy hiányzó érték esetén
 * a DEFAULT_HEARTBEAT_INTERVAL_MS-t adja vissza.
 */
export function getHeartbeatIntervalMs(): number {
  const raw = import.meta.env.VITE_HEARTBEAT_INTERVAL_MS
  if (typeof raw !== 'string' || raw.trim().length === 0) {
    return DEFAULT_HEARTBEAT_INTERVAL_MS
  }
  const parsed = parseInt(raw, 10)
  if (!Number.isFinite(parsed) || parsed < MIN_HEARTBEAT_INTERVAL_MS || parsed > MAX_HEARTBEAT_INTERVAL_MS) {
    return DEFAULT_HEARTBEAT_INTERVAL_MS
  }
  return parsed
}

/** Kiszámolt heartbeat-intervallum (modul-szintű, csak egyszer évalulódik). */
export const HEARTBEAT_INTERVAL_MS = getHeartbeatIntervalMs()
