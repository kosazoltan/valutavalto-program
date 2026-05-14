/**
 * Local-first SQLite schema definition with versioned migrations.
 *
 * PRAGMA user_version tracks the current schema version.
 * Each migration is idempotent and runs only once.
 */

import type { Database } from 'sql.js';

export const CURRENT_SCHEMA_VERSION = 2;

export interface Migration {
  version: number;
  description: string;
  up: (db: Database) => void;
}

const migrations: Migration[] = [
  {
    version: 1,
    description: 'Initial local-first schema: outbox, tombstone, sync_state, config',
    up(db) {
      db.run(`
        CREATE TABLE IF NOT EXISTS lf_config (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updated_at TEXT DEFAULT (datetime('now'))
        );
      `);

      db.run(`
        CREATE TABLE IF NOT EXISTS lf_outbox (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          mutation_id TEXT NOT NULL UNIQUE,
          entity_type TEXT NOT NULL,
          entity_id TEXT,
          action TEXT NOT NULL CHECK(action IN ('CREATE','UPDATE','DELETE','CUSTOM')),
          payload TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','syncing','synced','failed','abandoned')),
          retry_count INTEGER NOT NULL DEFAULT 0,
          max_retries INTEGER NOT NULL DEFAULT 10,
          error_message TEXT,
          created_at TEXT NOT NULL DEFAULT (datetime('now')),
          synced_at TEXT,
          next_retry_at TEXT
        );
      `);
      db.run('CREATE INDEX IF NOT EXISTS idx_outbox_status ON lf_outbox(status);');
      db.run('CREATE INDEX IF NOT EXISTS idx_outbox_entity ON lf_outbox(entity_type, entity_id);');

      db.run(`
        CREATE TABLE IF NOT EXISTS lf_tombstone (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          entity_type TEXT NOT NULL,
          entity_id TEXT NOT NULL,
          deleted_at TEXT NOT NULL DEFAULT (datetime('now')),
          synced INTEGER NOT NULL DEFAULT 0,
          retention_until TEXT NOT NULL,
          UNIQUE(entity_type, entity_id)
        );
      `);
      db.run('CREATE INDEX IF NOT EXISTS idx_tombstone_entity ON lf_tombstone(entity_type, entity_id);');
      db.run('CREATE INDEX IF NOT EXISTS idx_tombstone_retention ON lf_tombstone(retention_until);');

      db.run(`
        CREATE TABLE IF NOT EXISTS lf_sync_state (
          id INTEGER PRIMARY KEY CHECK(id = 1),
          last_pull_at TEXT,
          last_push_at TEXT,
          last_pull_checkpoint TEXT,
          status TEXT NOT NULL DEFAULT 'idle' CHECK(status IN ('idle','pulling','pushing','synced','error','offline')),
          error_message TEXT,
          consecutive_failures INTEGER NOT NULL DEFAULT 0
        );
      `);
      db.run(`INSERT OR IGNORE INTO lf_sync_state(id, status) VALUES (1, 'idle');`);

      db.run(`
        CREATE TABLE IF NOT EXISTS lf_conflict_log (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          entity_type TEXT NOT NULL,
          entity_id TEXT NOT NULL,
          local_version TEXT,
          server_version TEXT,
          resolution TEXT NOT NULL CHECK(resolution IN ('local_wins','server_wins','merged','manual_pending')),
          resolved_at TEXT NOT NULL DEFAULT (datetime('now')),
          details TEXT
        );
      `);
    },
  },
  {
    version: 2,
    description: 'Add cached entity store for server-synced data with change tracking',
    up(db) {
      db.run(`
        CREATE TABLE IF NOT EXISTS lf_cached_entities (
          entity_type TEXT NOT NULL,
          entity_id TEXT NOT NULL,
          data TEXT NOT NULL,
          version INTEGER NOT NULL DEFAULT 1,
          server_updated_at TEXT,
          local_cached_at TEXT NOT NULL DEFAULT (datetime('now')),
          _deleted INTEGER NOT NULL DEFAULT 0,
          PRIMARY KEY(entity_type, entity_id)
        );
      `);
      db.run('CREATE INDEX IF NOT EXISTS idx_cached_type ON lf_cached_entities(entity_type, _deleted);');
    },
  },
];

export function getSchemaVersion(db: Database): number {
  const result = db.exec('PRAGMA user_version;');
  if (result.length > 0 && result[0].values.length > 0) {
    return Number(result[0].values[0][0]) || 0;
  }
  return 0;
}

export function runMigrations(db: Database): { applied: number[]; currentVersion: number } {
  const currentVersion = getSchemaVersion(db);
  const applied: number[] = [];

  for (const migration of migrations) {
    if (migration.version > currentVersion) {
      db.run('BEGIN TRANSACTION;');
      try {
        migration.up(db);
        db.run(`PRAGMA user_version = ${migration.version};`);
        db.run('COMMIT;');
        applied.push(migration.version);
      } catch (err) {
        db.run('ROLLBACK;');
        throw new Error(
          `Schema migration V${migration.version} (${migration.description}) failed: ${err instanceof Error ? err.message : String(err)}`,
          { cause: err },
        );
      }
    }
  }

  return { applied, currentVersion: getSchemaVersion(db) };
}
