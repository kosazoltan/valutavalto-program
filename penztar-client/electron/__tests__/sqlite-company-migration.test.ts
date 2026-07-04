import { describe, it, expect, beforeEach } from 'vitest';
import initSqlJs, { type Database } from 'sql.js';
import fs from 'node:fs';
import path from 'node:path';

vi.mock('electron', () => ({
  app: {
    getPath: vi.fn(() => '/tmp/test-valuta'),
    getAppPath: vi.fn(() => '/tmp/test-valuta-app'),
    isPackaged: false,
  },
}));

import { ensureOutboxCompanyColumns } from '../sqlite';

const wasmPath = path.join(process.cwd(), 'node_modules/sql.js/dist/sql-wasm.wasm');

const outboxTables = [
  'pending_transactions',
  'pending_conversions',
  'pending_bank_transactions',
  'pending_stornos',
  'pending_handover_operations',
  'pending_transfers',
  'pending_transfer_stornos',
  'pending_distributions',
  'pending_collections',
  'pending_stocktake_items',
] as const;

let db: Database;

function createLegacyOutboxSchema(database: Database): void {
  database.run(`
    CREATE TABLE config (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL,
      updated_at TEXT DEFAULT (datetime('now'))
    );
  `);

  for (const table of outboxTables) {
    database.run(`
      CREATE TABLE ${table} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        idempotency_key TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0,
        payload TEXT
      );
    `);
  }
}

function columnNames(table: string): string[] {
  const result = db.exec(`PRAGMA table_info(${table})`);
  return result[0]?.values.map((row) => String(row[1])) ?? [];
}

function singleRow(table: string): Record<string, unknown> {
  const stmt = db.prepare(`SELECT * FROM ${table} WHERE id = 1`);
  stmt.step();
  const row = stmt.getAsObject() as Record<string, unknown>;
  stmt.free();
  return row;
}

describe('ensureOutboxCompanyColumns', () => {
  beforeEach(async () => {
    const wasmBinary = fs.readFileSync(wasmPath);
    const SQL = await initSqlJs({ wasmBinary: wasmBinary as unknown as ArrayBuffer });
    db = new SQL.Database();
    createLegacyOutboxSchema(db);
  });

  it('adds company_code TEXT column to all pending outbox tables', () => {
    ensureOutboxCompanyColumns(db, 'BC');

    for (const table of outboxTables) {
      expect(columnNames(table)).toContain('company_code');
    }
  });

  it('is idempotent when called twice', () => {
    ensureOutboxCompanyColumns(db, 'BC');
    ensureOutboxCompanyColumns(db, 'BC');

    for (const table of outboxTables) {
      expect(columnNames(table).filter((name) => name === 'company_code')).toHaveLength(1);
    }
  });

  it('backfills unsynced legacy rows with the active company code', () => {
    db.run(
      "INSERT INTO pending_transactions (idempotency_key, synced, payload) VALUES ('k1', 0, 'before')",
    );

    ensureOutboxCompanyColumns(db, 'BC');

    expect(singleRow('pending_transactions').company_code).toBe('BC');
  });

  it('does not overwrite already stamped rows', () => {
    db.run('ALTER TABLE pending_transactions ADD COLUMN company_code TEXT');
    db.run(
      "INSERT INTO pending_transactions (idempotency_key, synced, payload, company_code) VALUES ('k1', 0, 'before', 'PV')",
    );

    ensureOutboxCompanyColumns(db, 'BC');

    expect(singleRow('pending_transactions').company_code).toBe('PV');
  });

  it('leaves NULL company_code unchanged when active company code is missing', () => {
    db.run(
      "INSERT INTO pending_transactions (idempotency_key, synced, payload) VALUES ('k1', 0, 'before')",
    );

    ensureOutboxCompanyColumns(db, null);

    expect(singleRow('pending_transactions').company_code).toBeNull();
  });

  it('does not mutate other row fields during backfill', () => {
    db.run(
      "INSERT INTO pending_transactions (idempotency_key, synced, payload, created_at) VALUES ('k1', 0, 'before', '2026-07-04 10:00:00')",
    );

    ensureOutboxCompanyColumns(db, 'BC');

    expect(singleRow('pending_transactions')).toMatchObject({
      idempotency_key: 'k1',
      synced: 0,
      payload: 'before',
      created_at: '2026-07-04 10:00:00',
      company_code: 'BC',
    });
  });
});
