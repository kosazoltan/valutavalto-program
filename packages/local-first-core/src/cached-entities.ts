/**
 * CachedEntities: local replica store for server-synced data.
 *
 * Stores entities pulled from the server with version tracking.
 * Supports soft-delete via _deleted flag for tombstone awareness.
 * Queries automatically filter out deleted entities unless explicitly requested.
 */

import type { Database } from 'sql.js';

export interface CachedEntity<T = unknown> {
  entity_type: string;
  entity_id: string;
  data: T;
  version: number;
  server_updated_at: string | null;
  local_cached_at: string;
  _deleted: boolean;
}

export function upsertCached<T>(
  db: Database,
  entityType: string,
  entityId: string,
  data: T,
  version: number,
  serverUpdatedAt?: string,
): void {
  db.run(
    `INSERT INTO lf_cached_entities (entity_type, entity_id, data, version, server_updated_at, _deleted)
     VALUES (?, ?, ?, ?, ?, 0)
     ON CONFLICT(entity_type, entity_id) DO UPDATE SET
       data = excluded.data,
       version = excluded.version,
       server_updated_at = excluded.server_updated_at,
       local_cached_at = datetime('now'),
       _deleted = 0`,
    [entityType, entityId, JSON.stringify(data), version, serverUpdatedAt ?? null],
  );
}

export function softDeleteCached(db: Database, entityType: string, entityId: string): void {
  db.run(
    `UPDATE lf_cached_entities SET _deleted = 1, local_cached_at = datetime('now')
     WHERE entity_type = ? AND entity_id = ?`,
    [entityType, entityId],
  );
}

export function getCached<T>(db: Database, entityType: string, entityId: string): CachedEntity<T> | null {
  const stmt = db.prepare(
    `SELECT * FROM lf_cached_entities WHERE entity_type = ? AND entity_id = ? AND _deleted = 0`,
  );
  stmt.bind([entityType, entityId]);
  if (!stmt.step()) {
    stmt.free();
    return null;
  }
  const row = stmt.getAsObject() as Record<string, unknown>;
  stmt.free();
  return rowToEntity<T>(row);
}

export function listCached<T>(db: Database, entityType: string, includeDeleted = false): CachedEntity<T>[] {
  const sql = includeDeleted
    ? `SELECT * FROM lf_cached_entities WHERE entity_type = ? ORDER BY entity_id`
    : `SELECT * FROM lf_cached_entities WHERE entity_type = ? AND _deleted = 0 ORDER BY entity_id`;
  const stmt = db.prepare(sql);
  stmt.bind([entityType]);
  const results: CachedEntity<T>[] = [];
  while (stmt.step()) {
    results.push(rowToEntity<T>(stmt.getAsObject() as Record<string, unknown>));
  }
  stmt.free();
  return results;
}

export function clearCachedByType(db: Database, entityType: string): void {
  db.run(`DELETE FROM lf_cached_entities WHERE entity_type = ?`, [entityType]);
}

function rowToEntity<T>(row: Record<string, unknown>): CachedEntity<T> {
  return {
    entity_type: row.entity_type as string,
    entity_id: row.entity_id as string,
    data: JSON.parse(row.data as string) as T,
    version: row.version as number,
    server_updated_at: (row.server_updated_at as string) || null,
    local_cached_at: row.local_cached_at as string,
    _deleted: (row._deleted as number) === 1,
  };
}
