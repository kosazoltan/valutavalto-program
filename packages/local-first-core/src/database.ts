/**
 * Database: SQLite initialization, atomic persistence, and lifecycle.
 *
 * Uses sql.js (WASM) for cross-platform SQLite in Electron main process.
 * Writes use atomic temp-file + rename pattern to prevent corruption.
 */

import initSqlJs, { type Database } from 'sql.js';
import fs from 'node:fs';
import path from 'node:path';
import log from 'electron-log';
import { runMigrations, getSchemaVersion, CURRENT_SCHEMA_VERSION } from './schema';
import { ensureInventoryTable } from './inventory';

let db: Database | null = null;
let dbPath = '';

export interface DatabaseConfig {
  dbDir: string;
  dbName: string;
  wasmPath: string;
}

export async function initLocalDatabase(config: DatabaseConfig): Promise<Database> {
  if (db) return db;

  if (!fs.existsSync(config.dbDir)) {
    fs.mkdirSync(config.dbDir, { recursive: true });
  }

  dbPath = path.join(config.dbDir, config.dbName);
  const wasmBinary = fs.readFileSync(config.wasmPath) as unknown as ArrayBuffer;
  const SQL = await initSqlJs({ wasmBinary });

  if (fs.existsSync(dbPath)) {
    const buffer = fs.readFileSync(dbPath);
    db = new SQL.Database(buffer);
  } else {
    db = new SQL.Database();
  }

  db.run('PRAGMA foreign_keys = ON;');
  db.run('PRAGMA journal_mode = WAL;');

  const { applied, currentVersion } = runMigrations(db);
  if (applied.length > 0) {
    log.info(`[LocalFirst] Schema migrated: applied V${applied.join(', V')}, now at V${currentVersion}`);
  } else {
    log.info(`[LocalFirst] Schema at V${currentVersion} (current: V${CURRENT_SCHEMA_VERSION})`);
  }

  ensureInventoryTable(db);
  saveDatabase();

  return db;
}

export function getDb(): Database {
  if (!db) throw new Error('Local database not initialized. Call initLocalDatabase() first.');
  return db;
}

export function saveDatabase(): void {
  if (!db || !dbPath) return;

  const data = db.export();
  const buffer = Buffer.from(data);
  const tmpPath = `${dbPath}.tmp`;

  try {
    fs.writeFileSync(tmpPath, buffer);
    fs.renameSync(tmpPath, dbPath);
  } catch (err) {
    log.error('[LocalFirst] Failed to save database:', err);
    try { fs.unlinkSync(tmpPath); } catch { /* ignore cleanup failure */ }
    throw err;
  }
}

export function closeDatabase(): void {
  if (db) {
    saveDatabase();
    db.close();
    db = null;
    dbPath = '';
  }
}

export function getDatabasePath(): string {
  return dbPath;
}
