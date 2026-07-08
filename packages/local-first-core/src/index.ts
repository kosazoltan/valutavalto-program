/**
 * @valuta/local-first-core — Shared local-first infrastructure
 *
 * Provides: SQLite database, outbox queue, tombstone tracking,
 * sync state management, cached entity store, conflict policies,
 * inventory movements, and abstract sync engine.
 */

export { initLocalDatabase, getDb, saveDatabase, closeDatabase, getDatabasePath } from './database'
export type { DatabaseConfig } from './database'

export { runMigrations, getSchemaVersion, CURRENT_SCHEMA_VERSION } from './schema'

export * as outbox from './outbox'
export type { OutboxEntry } from './outbox'

export * as tombstone from './tombstone'
export type { TombstoneEntry } from './tombstone'

export * as syncState from './sync-state'
export type { SyncStatus, SyncStateInfo } from './sync-state'

export * as cachedEntities from './cached-entities'
export type { CachedEntity } from './cached-entities'

export * as conflictPolicy from './conflict-policy'
export type { ConflictPolicy, ConflictResolution } from './conflict-policy'
export { SERVER_AUTHORITY, LAST_WRITE_WINS, fieldMerge } from './conflict-policy'

export * as inventory from './inventory'
export type { InventoryMovement, StockPosition, MovementDirection } from './inventory'

export { SyncEngineBase } from './sync-engine-base'
export type { SyncResult } from './sync-engine-base'
