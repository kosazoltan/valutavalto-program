/**
 * Tombstone: soft-delete tracking for local-first replication.
 *
 * When an entity is deleted, a tombstone record is created instead of
 * a hard delete. This ensures offline replicas learn about deletions
 * when they reconnect. Tombstones are cleaned up after the retention period.
 */

import type { Database } from 'sql.js'

export interface TombstoneEntry {
  id: number
  entity_type: string
  entity_id: string
  deleted_at: string
  synced: number
  retention_until: string
}

export function markDeleted(
  db: Database,
  entityType: string,
  entityId: string,
  retentionDays = 30,
): void {
  db.run(
    `INSERT OR REPLACE INTO lf_tombstone (entity_type, entity_id, deleted_at, retention_until)
     VALUES (?, ?, datetime('now'), datetime('now', '+' || ? || ' days'))`,
    [entityType, entityId, retentionDays],
  )
}

export function isDeleted(db: Database, entityType: string, entityId: string): boolean {
  const stmt = db.prepare(
    `SELECT COUNT(*) as cnt FROM lf_tombstone WHERE entity_type = ? AND entity_id = ?`,
  )
  stmt.bind([entityType, entityId])
  stmt.step()
  const row = stmt.getAsObject() as { cnt: number }
  stmt.free()
  return row.cnt > 0
}

export function getUnsyncedTombstones(db: Database, limit = 100): TombstoneEntry[] {
  const stmt = db.prepare(
    `SELECT * FROM lf_tombstone WHERE synced = 0 ORDER BY deleted_at ASC LIMIT ?`,
  )
  stmt.bind([limit])
  const results: TombstoneEntry[] = []
  while (stmt.step()) {
    results.push(stmt.getAsObject() as unknown as TombstoneEntry)
  }
  stmt.free()
  return results
}

export function markTombstoneSynced(db: Database, entityType: string, entityId: string): void {
  db.run(`UPDATE lf_tombstone SET synced = 1 WHERE entity_type = ? AND entity_id = ?`, [
    entityType,
    entityId,
  ])
}

export function cleanupExpired(db: Database): number {
  db.run(`DELETE FROM lf_tombstone WHERE synced = 1 AND retention_until < datetime('now')`)
  return db.getRowsModified()
}

export function getTombstonesAfter(
  db: Database,
  entityType: string,
  since: string,
): TombstoneEntry[] {
  const stmt = db.prepare(
    `SELECT * FROM lf_tombstone WHERE entity_type = ? AND deleted_at > ? ORDER BY deleted_at ASC`,
  )
  stmt.bind([entityType, since])
  const results: TombstoneEntry[] = []
  while (stmt.step()) {
    results.push(stmt.getAsObject() as unknown as TombstoneEntry)
  }
  stmt.free()
  return results
}
