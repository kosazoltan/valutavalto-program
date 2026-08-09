import { describe, it, expect } from 'vitest';
import {
  BUSINESS_RETRY_BASE_MS,
  BUSINESS_RETRY_MAX_MS,
  BUSINESS_RETRY_WINDOW_MS,
  businessRetryBackoffMs,
  isBusinessRetryExpired,
  isBusinessRetryWithheld,
  needsManualIntervention,
} from '../business-retry';

/**
 * FKH-031 FR-1/FR-2 — time-gated business-error retry policy.
 *
 * RED proof: before FKH-031 a business-rejected item was excluded from auto-sync
 * FOREVER. The `releases the item once the backoff elapsed` case below is exactly
 * that regression: with the old `!abandonedTxIds.has(id)` filter the item was
 * never released, so the expectation `false` (= not withheld) could not hold.
 */
describe('FKH-031 business retry backoff', () => {
  const iso = (ms: number) => new Date(ms).toISOString();

  it('starts at the 1 minute base delay and doubles per attempt', () => {
    expect(businessRetryBackoffMs(1)).toBe(BUSINESS_RETRY_BASE_MS);
    expect(businessRetryBackoffMs(2)).toBe(2 * BUSINESS_RETRY_BASE_MS);
    expect(businessRetryBackoffMs(3)).toBe(4 * BUSINESS_RETRY_BASE_MS);
  });

  it('caps a single delay at 1 hour (NFR-1)', () => {
    expect(businessRetryBackoffMs(10)).toBe(BUSINESS_RETRY_MAX_MS);
    expect(businessRetryBackoffMs(9999)).toBe(BUSINESS_RETRY_MAX_MS);
  });

  it('treats a zero/negative/NaN attempt counter as the first attempt', () => {
    expect(businessRetryBackoffMs(0)).toBe(BUSINESS_RETRY_BASE_MS);
    expect(businessRetryBackoffMs(-5)).toBe(BUSINESS_RETRY_BASE_MS);
    expect(businessRetryBackoffMs(Number.NaN)).toBe(BUSINESS_RETRY_BASE_MS);
  });

  it('withholds the item while the backoff is still running', () => {
    const now = 10_000_000_000;
    const state = {
      sync_attempts: 1,
      last_attempt_at: iso(now - 30_000), // 30s ago, backoff is 60s
      created_at: iso(now - 30_000),
    };
    expect(isBusinessRetryWithheld(state, now)).toBe(true);
  });

  it('releases the item once the backoff elapsed (the FKH-031 core fix)', () => {
    const now = 10_000_000_000;
    const state = {
      sync_attempts: 1,
      last_attempt_at: iso(now - 61_000), // 61s ago > 60s backoff
      created_at: iso(now - 61_000),
    };
    expect(isBusinessRetryWithheld(state, now)).toBe(false);
  });

  it('keeps withholding a repeatedly failing item for its longer backoff', () => {
    const now = 10_000_000_000;
    // 5 attempts -> 16 minutes; 10 minutes elapsed is not enough yet.
    const state = {
      sync_attempts: 5,
      last_attempt_at: iso(now - 10 * 60_000),
      created_at: iso(now - 10 * 60_000),
    };
    expect(isBusinessRetryWithheld(state, now)).toBe(true);
  });

  it('retries immediately when no attempt timestamp was ever recorded', () => {
    const now = 10_000_000_000;
    expect(isBusinessRetryWithheld({ sync_attempts: 3, last_attempt_at: null }, now)).toBe(false);
  });

  it('stops auto retry and asks for manual intervention after 7 days', () => {
    const now = 10_000_000_000;
    const state = {
      sync_attempts: 40,
      last_attempt_at: iso(now - 60 * 60_000),
      created_at: iso(now - BUSINESS_RETRY_WINDOW_MS - 1000),
    };
    expect(isBusinessRetryExpired(state, now)).toBe(true);
    expect(needsManualIntervention(state, now)).toBe(true);
    expect(isBusinessRetryWithheld(state, now)).toBe(true);
  });

  it('does not expire an item that is still inside the 7 day window', () => {
    const now = 10_000_000_000;
    const state = {
      sync_attempts: 20,
      last_attempt_at: iso(now - 2 * 60 * 60_000),
      created_at: iso(now - BUSINESS_RETRY_WINDOW_MS + 60_000),
    };
    expect(isBusinessRetryExpired(state, now)).toBe(false);
    // backoff is capped at 1h, 2h elapsed -> released for another attempt
    expect(isBusinessRetryWithheld(state, now)).toBe(false);
  });

  it('fails open (keeps retrying) when both timestamps are unusable', () => {
    const now = 10_000_000_000;
    const state = { sync_attempts: 3, last_attempt_at: 'not-a-date', created_at: 'garbage' };
    expect(isBusinessRetryExpired(state, now)).toBe(false);
    expect(isBusinessRetryWithheld(state, now)).toBe(false);
  });
});
