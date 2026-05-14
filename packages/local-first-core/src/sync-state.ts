/**
 * SyncState: tracks synchronization status for UI display.
 *
 * UI states:
 *   idle       — no sync activity
 *   pulling    — downloading changes from server
 *   pushing    — uploading local changes to server
 *   synced     — last sync succeeded, all caught up
 *   error      — last sync failed (retryable)
 *   offline    — network unavailable
 */

import type { Database } from 'sql.js';

export type SyncStatus = 'idle' | 'pulling' | 'pushing' | 'synced' | 'error' | 'offline';

export interface SyncStateInfo {
  status: SyncStatus;
  lastPullAt: string | null;
  lastPushAt: string | null;
  lastPullCheckpoint: string | null;
  errorMessage: string | null;
  consecutiveFailures: number;
}

export function getSyncState(db: Database): SyncStateInfo {
  const stmt = db.prepare('SELECT * FROM lf_sync_state WHERE id = 1');
  stmt.step();
  const row = stmt.getAsObject() as Record<string, unknown>;
  stmt.free();
  return {
    status: (row.status as SyncStatus) || 'idle',
    lastPullAt: (row.last_pull_at as string) || null,
    lastPushAt: (row.last_push_at as string) || null,
    lastPullCheckpoint: (row.last_pull_checkpoint as string) || null,
    errorMessage: (row.error_message as string) || null,
    consecutiveFailures: (row.consecutive_failures as number) || 0,
  };
}

export function updateSyncStatus(db: Database, status: SyncStatus, errorMessage?: string): void {
  if (status === 'synced' || status === 'idle') {
    db.run(
      `UPDATE lf_sync_state SET status = ?, error_message = NULL, consecutive_failures = 0 WHERE id = 1`,
      [status],
    );
  } else if (status === 'error' || status === 'offline') {
    db.run(
      `UPDATE lf_sync_state
       SET status = ?, error_message = ?, consecutive_failures = consecutive_failures + 1
       WHERE id = 1`,
      [status, errorMessage ?? null],
    );
  } else {
    db.run(`UPDATE lf_sync_state SET status = ? WHERE id = 1`, [status]);
  }
}

export function updatePullCheckpoint(db: Database, checkpoint: string): void {
  db.run(
    `UPDATE lf_sync_state SET last_pull_at = datetime('now'), last_pull_checkpoint = ? WHERE id = 1`,
    [checkpoint],
  );
}

export function updatePushTimestamp(db: Database): void {
  db.run(`UPDATE lf_sync_state SET last_push_at = datetime('now') WHERE id = 1`);
}
