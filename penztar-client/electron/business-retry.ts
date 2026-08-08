/**
 * FKH-031 FR-1/FR-2: time-gated retry policy for pending transactions that were
 * rejected by a BUSINESS validation error (HTTP 4xx, except 401/403/408/429).
 *
 * Before FKH-031 such a transaction was added to the in-memory `abandonedTxIds`
 * set and was NEVER retried automatically again — even after the root cause
 * disappeared (e.g. a fresh exchange rate arrived). The item stayed silently in
 * "waiting for sync" state forever.
 *
 * This module keeps the abandon-set idea (no tight retry loop) but makes the
 * exclusion TIME-GATED and PERSISTENT: the decision is derived from the already
 * existing `sync_attempts` / `last_attempt_at` columns of `pending_transactions`,
 * so it survives an application restart. No new DB column, no Flyway migration.
 *
 * NFR-1: exponential backoff with a dedicated per-item constant, capped at 1 hour.
 * The engine-level network/auth backoff (`maxBackoffMs`, 300s) is a SEPARATE
 * branch and is intentionally left untouched.
 */

/** Base delay of the business-error backoff ladder (1 minute). */
export const BUSINESS_RETRY_BASE_MS = 60_000;

/** NFR-1: upper cap of a single business-retry delay — 1 hour. */
export const BUSINESS_RETRY_MAX_MS = 3_600_000;

/** NFR-1: after this window the item stops auto-retrying and needs manual action — 7 days. */
export const BUSINESS_RETRY_WINDOW_MS = 7 * 24 * 3_600_000;

/** Minimal shape this policy needs from a `pending_transactions` row. */
export interface BusinessRetryState {
  sync_attempts?: number | null;
  last_attempt_at?: string | null;
  created_at?: string | null;
}

/**
 * Exponential backoff for the Nth business-error attempt, capped at 1 hour.
 * attempts <= 1 -> 1 min, 2 -> 2 min, 3 -> 4 min ... capped at 60 min.
 */
export function businessRetryBackoffMs(attempts: number): number {
  const normalized = Number.isFinite(attempts) && attempts > 1 ? Math.floor(attempts) : 1;
  // Guard against Infinity from a corrupted counter before the cap is applied.
  const exponent = Math.min(normalized - 1, 32);
  const delay = BUSINESS_RETRY_BASE_MS * 2 ** exponent;
  return Math.min(delay, BUSINESS_RETRY_MAX_MS);
}

function parseIso(value: string | null | undefined): number | null {
  if (!value) return null;
  const ms = Date.parse(value);
  return Number.isNaN(ms) ? null : ms;
}

/**
 * FR-2 / NFR-1: has the item exhausted the 7-day auto-retry window?
 * Measured from `created_at` (the moment the transaction was recorded locally);
 * if that is missing/unparseable we fall back to `last_attempt_at`, and if both
 * are unusable we do NOT expire the item (fail-open towards retrying, so a
 * corrupted timestamp can never silently swallow a financial record).
 */
export function isBusinessRetryExpired(state: BusinessRetryState, nowMs: number): boolean {
  const anchor = parseIso(state.created_at) ?? parseIso(state.last_attempt_at);
  if (anchor === null) return false;
  return nowMs - anchor >= BUSINESS_RETRY_WINDOW_MS;
}

/**
 * FR-1/FR-2 core decision: should this business-error item be WITHHELD from the
 * current auto-sync round?
 *
 * - not in the abandoned set -> never withheld (normal item)
 * - retry window expired      -> withheld permanently (manual action required)
 * - within backoff            -> withheld until `last_attempt_at + backoff(attempts)`
 * - backoff elapsed           -> released, one more automatic attempt is made
 */
export function isBusinessRetryWithheld(state: BusinessRetryState, nowMs: number): boolean {
  if (isBusinessRetryExpired(state, nowMs)) return true;
  const lastAttempt = parseIso(state.last_attempt_at);
  // No recorded attempt timestamp -> nothing to wait for, let it try.
  if (lastAttempt === null) return false;
  const dueAt = lastAttempt + businessRetryBackoffMs(state.sync_attempts ?? 1);
  return nowMs < dueAt;
}

/**
 * True when the item needs explicit human intervention: it failed with a business
 * error and its 7-day automatic retry window has elapsed. The UI surfaces this
 * distinctly from "will be retried automatically".
 */
export function needsManualIntervention(state: BusinessRetryState, nowMs: number): boolean {
  return isBusinessRetryExpired(state, nowMs);
}
