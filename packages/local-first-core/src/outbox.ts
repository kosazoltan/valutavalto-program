/**
 * Outbox: unified mutation queue for local-first sync.
 *
 * Every write operation first commits to the local outbox with a stable
 * mutation_id (idempotency key). The sync engine drains pending entries
 * and pushes them to the server. Failed entries use exponential backoff.
 */

import type { Database } from 'sql.js'
import crypto from 'node:crypto'

export interface OutboxEntry {
  id: number
  mutation_id: string
  entity_type: string
  entity_id: string | null
  action: 'CREATE' | 'UPDATE' | 'DELETE' | 'CUSTOM'
  payload: string
  status: 'pending' | 'syncing' | 'synced' | 'failed' | 'abandoned'
  retry_count: number
  max_retries: number
  error_message: string | null
  created_at: string
  synced_at: string | null
  next_retry_at: string | null
}

export function enqueue(
  db: Database,
  entityType: string,
  action: OutboxEntry['action'],
  payload: Record<string, unknown>,
  entityId?: string,
  mutationId?: string,
): string {
  const mid = mutationId ?? crypto.randomUUID()
  db.run(
    `INSERT INTO lf_outbox (mutation_id, entity_type, entity_id, action, payload)
     VALUES (?, ?, ?, ?, ?)`,
    [mid, entityType, entityId ?? null, action, JSON.stringify(payload)],
  )
  return mid
}

export function getPending(db: Database, limit = 50): OutboxEntry[] {
  const stmt = db.prepare(
    `SELECT * FROM lf_outbox
     WHERE status IN ('pending', 'failed')
       AND (next_retry_at IS NULL OR next_retry_at <= datetime('now'))
     ORDER BY created_at ASC
     LIMIT ?`,
  )
  stmt.bind([limit])

  const results: OutboxEntry[] = []
  while (stmt.step()) {
    results.push(stmt.getAsObject() as unknown as OutboxEntry)
  }
  stmt.free()
  return results
}

export function markSyncing(db: Database, mutationId: string): void {
  db.run(`UPDATE lf_outbox SET status = 'syncing' WHERE mutation_id = ?`, [mutationId])
}

export function markSynced(db: Database, mutationId: string): void {
  db.run(
    `UPDATE lf_outbox SET status = 'synced', synced_at = datetime('now') WHERE mutation_id = ?`,
    [mutationId],
  )
}

export function markFailed(db: Database, mutationId: string, errorMessage: string): void {
  db.run(
    `UPDATE lf_outbox
     SET status = CASE WHEN retry_count + 1 >= max_retries THEN 'abandoned' ELSE 'failed' END,
         retry_count = retry_count + 1,
         error_message = ?,
         next_retry_at = datetime('now', '+' || CAST(MIN(POWER(2, retry_count + 1), 3600) AS INTEGER) || ' seconds')
     WHERE mutation_id = ?`,
    [errorMessage, mutationId],
  )
}

export function cleanupSynced(db: Database, retentionDays = 30): number {
  const result = db.run(
    `DELETE FROM lf_outbox
     WHERE status = 'synced'
       AND synced_at < datetime('now', '-' || ? || ' days')`,
    [retentionDays],
  )
  return db.getRowsModified()
}

export function getStats(db: Database): Record<string, number> {
  const stmt = db.prepare(`SELECT status, COUNT(*) as count FROM lf_outbox GROUP BY status`)
  const stats: Record<string, number> = {}
  while (stmt.step()) {
    const row = stmt.getAsObject() as { status: string; count: number }
    stats[row.status] = row.count
  }
  stmt.free()
  return stats
}
