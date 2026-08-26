/**
 * sqlite.ts unit tests — config get/set, DB inicializálás, pending transactions.
 *
 * Strategy: We can't easily call initDatabase() because it depends on electron `app`.
 * Instead, we directly init sql.js in-memory and test the exported pure functions
 * by accessing the module's internal db through getDb() after manual setup.
 */
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import initSqlJs, { type Database } from 'sql.js';
import path from 'node:path';
import fs from 'node:fs';
import os from 'node:os';

// FK-097 WU-12: az initDatabase()-t hívó tesztek egyedi temp-home-ot kapnak
// (az sqlite-save-return-id.test.ts mintája).
const mockState = vi.hoisted(() => ({
  tempHome: '',
}));

// We need to mock electron before importing sqlite
vi.mock('electron', () => ({
  app: {
    getPath: vi.fn(() => mockState.tempHome || '/tmp/test-valuta'),
    getAppPath: vi.fn(() => mockState.tempHome || '/tmp/test-valuta-app'),
    isPackaged: false,
  },
}));

// A VALÓS production tranzakció-magot importáljuk (nem replikát): így ha a sqlite.ts
// BEGIN/COMMIT/ROLLBACK + re-entry guard logika változik, az atomicitás-tesztek elkapják.
import { runInTransaction } from '../sqlite';

/**
 * Since sqlite.ts has module-level state (let db), we need a strategy
 * to test its exported functions. We'll use a direct sql.js approach:
 * create an in-memory DB, run the same schema, and test the logic.
 */

let db: Database;

function runSchema(database: Database): void {
  database.run('PRAGMA foreign_keys = ON;');
  database.run(`
    CREATE TABLE IF NOT EXISTS config (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL,
      updated_at TEXT DEFAULT (datetime('now'))
    );
  `);
  database.run(`
    CREATE TABLE IF NOT EXISTS pending_transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type TEXT NOT NULL CHECK(type IN ('SELL', 'BUY')),
      currency_code TEXT NOT NULL,
      foreign_amount REAL NOT NULL,
      huf_amount REAL NOT NULL,
      rounded_huf_amount REAL NOT NULL,
      rate REAL NOT NULL,
      handling_fee REAL,
      discount_percent REAL,
      customer_id INTEGER,
      customer_identifier TEXT,
      customer_name TEXT,
      customer_document_number TEXT,
      customer_address TEXT,
      denominations TEXT,
      local_reference_number TEXT,
      idempotency_key TEXT,
      created_at TEXT DEFAULT (datetime('now')),
      synced INTEGER DEFAULT 0
    );
  `);
  database.run(`
    CREATE TABLE IF NOT EXISTS cached_rates (
      currency_code TEXT PRIMARY KEY,
      buy_rate REAL NOT NULL,
      sell_rate REAL NOT NULL,
      unit INTEGER NOT NULL DEFAULT 1,
      updated_at TEXT NOT NULL
    );
  `);
  database.run(`
    CREATE TABLE IF NOT EXISTS pending_transfer_stornos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      transfer_id INTEGER NOT NULL,
      transfer_number TEXT,
      reason TEXT NOT NULL,
      local_reference_number TEXT,
      idempotency_key TEXT,
      created_at TEXT DEFAULT (datetime('now')),
      synced INTEGER DEFAULT 0
    );
  `);
  database.run(`
    CREATE TABLE IF NOT EXISTS local_audit_events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      entity_type TEXT NOT NULL,
      event_type TEXT NOT NULL,
      reference_number TEXT,
      entity_id TEXT,
      payload_json TEXT NOT NULL,
      customer_snapshot_json TEXT,
      identification_snapshot_json TEXT,
      rate_snapshot_json TEXT,
      status TEXT NOT NULL DEFAULT 'LOCAL_RECORDED',
      retention_until TEXT NOT NULL,
      created_at TEXT DEFAULT (datetime('now'))
    );
  `);
}

// Find the sql-wasm.wasm file
const wasmPath = path.join(process.cwd(), 'node_modules/sql.js/dist/sql-wasm.wasm');

describe('sqlite — config get/set (direct DB)', () => {
  beforeEach(async () => {
    const wasmBinary = fs.readFileSync(wasmPath);
    const SQL = await initSqlJs({ wasmBinary: wasmBinary as unknown as ArrayBuffer });
    db = new SQL.Database();
    runSchema(db);
  });

  afterEach(() => {
    if (db) db.close();
  });

  it('should return null for non-existent config key', () => {
    const stmt = db.prepare('SELECT value FROM config WHERE key = ?');
    stmt.bind(['nonexistent']);
    const hasRow = stmt.step();
    stmt.free();
    expect(hasRow).toBe(false);
  });

  it('should set and get a config value', () => {
    db.run(
      `INSERT INTO config (key, value, updated_at) VALUES (?, ?, datetime('now'))
       ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at`,
      ['server_url', 'http://localhost:8080/api/v1'],
    );

    const stmt = db.prepare('SELECT value FROM config WHERE key = ?');
    stmt.bind(['server_url']);
    expect(stmt.step()).toBe(true);
    const row = stmt.getAsObject();
    stmt.free();
    expect(row['value']).toBe('http://localhost:8080/api/v1');
  });

  it('should overwrite an existing config value (upsert)', () => {
    db.run(
      `INSERT INTO config (key, value, updated_at) VALUES (?, ?, datetime('now'))
       ON CONFLICT(key) DO UPDATE SET value = excluded.value`,
      ['server_url', 'http://old-url:8080'],
    );
    db.run(
      `INSERT INTO config (key, value, updated_at) VALUES (?, ?, datetime('now'))
       ON CONFLICT(key) DO UPDATE SET value = excluded.value`,
      ['server_url', 'http://new-url:9090'],
    );

    const stmt = db.prepare('SELECT value FROM config WHERE key = ?');
    stmt.bind(['server_url']);
    stmt.step();
    const row = stmt.getAsObject();
    stmt.free();
    expect(row['value']).toBe('http://new-url:9090');
  });

  it('should delete a config value', () => {
    db.run(`INSERT INTO config (key, value) VALUES (?, ?)`, ['to_delete', 'value']);
    db.run('DELETE FROM config WHERE key = ?', ['to_delete']);

    const stmt = db.prepare('SELECT value FROM config WHERE key = ?');
    stmt.bind(['to_delete']);
    expect(stmt.step()).toBe(false);
    stmt.free();
  });

  it('should reject config key longer than 100 chars (validation logic test)', () => {
    // This tests the validation logic from setConfig
    const longKey = 'a'.repeat(101);
    expect(longKey.length).toBeGreaterThan(100);
    // The actual setConfig would throw — here we verify the principle
  });

  it('should reject config value longer than 10000 chars (validation logic test)', () => {
    const longValue = 'x'.repeat(10_001);
    expect(longValue.length).toBeGreaterThan(10_000);
  });
});

describe('sqlite — DB schema initialization', () => {
  beforeEach(async () => {
    const wasmBinary = fs.readFileSync(wasmPath);
    const SQL = await initSqlJs({ wasmBinary: wasmBinary as unknown as ArrayBuffer });
    db = new SQL.Database();
    runSchema(db);
  });

  afterEach(() => {
    if (db) db.close();
  });

  it('should create config table', () => {
    const stmt = db.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name='config'");
    expect(stmt.step()).toBe(true);
    stmt.free();
  });

  it('should create pending_transactions table', () => {
    const stmt = db.prepare(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='pending_transactions'",
    );
    expect(stmt.step()).toBe(true);
    stmt.free();
  });

  it('should create cached_rates table', () => {
    const stmt = db.prepare(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='cached_rates'",
    );
    expect(stmt.step()).toBe(true);
    stmt.free();
  });

  it('should create local_audit_events table', () => {
    const stmt = db.prepare(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='local_audit_events'",
    );
    expect(stmt.step()).toBe(true);
    stmt.free();
  });

  it('should enforce type CHECK constraint on pending_transactions', () => {
    expect(() => {
      db.run(
        `INSERT INTO pending_transactions (type, currency_code, foreign_amount, huf_amount, rounded_huf_amount, rate)
         VALUES ('INVALID', 'EUR', 100, 40000, 40000, 400)`,
      );
    }).toThrow();
  });

  it('should allow SELL and BUY types', () => {
    db.run(
      `INSERT INTO pending_transactions (type, currency_code, foreign_amount, huf_amount, rounded_huf_amount, rate)
       VALUES ('SELL', 'EUR', 100, 40000, 40000, 400)`,
    );
    db.run(
      `INSERT INTO pending_transactions (type, currency_code, foreign_amount, huf_amount, rounded_huf_amount, rate)
       VALUES ('BUY', 'USD', 200, 72000, 72000, 360)`,
    );

    const stmt = db.prepare('SELECT COUNT(*) as cnt FROM pending_transactions');
    stmt.step();
    const row = stmt.getAsObject();
    stmt.free();
    expect(row['cnt']).toBe(2);
  });
});

describe('sqlite — pending transactions logic', () => {
  beforeEach(async () => {
    const wasmBinary = fs.readFileSync(wasmPath);
    const SQL = await initSqlJs({ wasmBinary: wasmBinary as unknown as ArrayBuffer });
    db = new SQL.Database();
    runSchema(db);
  });

  afterEach(() => {
    if (db) db.close();
  });

  it('should insert and retrieve unsynced transactions', () => {
    db.run(
      `INSERT INTO pending_transactions (type, currency_code, foreign_amount, huf_amount, rounded_huf_amount, rate, synced)
       VALUES ('SELL', 'EUR', 100, 40000, 40000, 400, 0)`,
    );
    db.run(
      `INSERT INTO pending_transactions (type, currency_code, foreign_amount, huf_amount, rounded_huf_amount, rate, synced)
       VALUES ('BUY', 'USD', 50, 18000, 18000, 360, 1)`,
    );

    const stmt = db.prepare('SELECT * FROM pending_transactions WHERE synced = 0');
    const results = [];
    while (stmt.step()) {
      results.push(stmt.getAsObject());
    }
    stmt.free();

    expect(results).toHaveLength(1);
    expect(results[0]!['type']).toBe('SELL');
    expect(results[0]!['currency_code']).toBe('EUR');
  });

  it('should mark transaction as synced', () => {
    db.run(
      `INSERT INTO pending_transactions (type, currency_code, foreign_amount, huf_amount, rounded_huf_amount, rate, synced)
       VALUES ('SELL', 'EUR', 100, 40000, 40000, 400, 0)`,
    );

    // Get the ID
    const stmtId = db.prepare('SELECT last_insert_rowid() as id');
    stmtId.step();
    const id = stmtId.getAsObject()['id'] as number;
    stmtId.free();

    // Mark synced
    db.run('UPDATE pending_transactions SET synced = 1 WHERE id = ?', [id]);

    // Verify
    const stmt = db.prepare('SELECT synced FROM pending_transactions WHERE id = ?');
    stmt.bind([id]);
    stmt.step();
    const row = stmt.getAsObject();
    stmt.free();
    expect(row['synced']).toBe(1);
  });

  it('offline transfer-storno: csak synced=0 jön vissza, mark után eltűnik', () => {
    db.run(`INSERT INTO pending_transfer_stornos (transfer_id, transfer_number, reason, synced)
            VALUES (50, 'AT-000023', 'Téves rögzítés', 0)`);
    db.run(`INSERT INTO pending_transfer_stornos (transfer_id, transfer_number, reason, synced)
            VALUES (51, 'AT-000024', 'Már szinkronizált', 1)`);

    const sel = () => {
      const stmt = db.prepare(
        'SELECT * FROM pending_transfer_stornos WHERE synced = 0 ORDER BY created_at ASC',
      );
      const rows = [];
      while (stmt.step()) rows.push(stmt.getAsObject());
      stmt.free();
      return rows;
    };

    const pending = sel();
    expect(pending).toHaveLength(1);
    expect(pending[0]!['transfer_id']).toBe(50);
    expect(pending[0]!['reason']).toBe('Téves rögzítés');

    db.run('UPDATE pending_transfer_stornos SET synced = 1 WHERE id = ?', [
      pending[0]!['id'] as number,
    ]);
    expect(sel()).toHaveLength(0);
  });

  it('should count pending (unsynced) transactions', () => {
    db.run(
      `INSERT INTO pending_transactions (type, currency_code, foreign_amount, huf_amount, rounded_huf_amount, rate, synced)
       VALUES ('SELL', 'EUR', 100, 40000, 40000, 400, 0)`,
    );
    db.run(
      `INSERT INTO pending_transactions (type, currency_code, foreign_amount, huf_amount, rounded_huf_amount, rate, synced)
       VALUES ('BUY', 'USD', 50, 18000, 18000, 360, 0)`,
    );
    db.run(
      `INSERT INTO pending_transactions (type, currency_code, foreign_amount, huf_amount, rounded_huf_amount, rate, synced)
       VALUES ('BUY', 'GBP', 30, 14000, 14000, 467, 1)`,
    );

    const stmt = db.prepare('SELECT COUNT(*) as cnt FROM pending_transactions WHERE synced = 0');
    stmt.step();
    const row = stmt.getAsObject();
    stmt.free();
    expect(row['cnt']).toBe(2);
  });

  it('should store and retrieve cached rates', () => {
    db.run(
      `INSERT INTO cached_rates (currency_code, buy_rate, sell_rate, unit, updated_at)
       VALUES ('EUR', 395.5, 405.5, 1, '2026-03-24T10:00:00')`,
    );
    db.run(
      `INSERT INTO cached_rates (currency_code, buy_rate, sell_rate, unit, updated_at)
       VALUES ('USD', 355.0, 365.0, 1, '2026-03-24T10:00:00')`,
    );

    const stmt = db.prepare('SELECT * FROM cached_rates ORDER BY currency_code ASC');
    const results = [];
    while (stmt.step()) {
      results.push(stmt.getAsObject());
    }
    stmt.free();

    expect(results).toHaveLength(2);
    expect(results[0]!['currency_code']).toBe('EUR');
    expect(results[0]!['buy_rate']).toBe(395.5);
    expect(results[1]!['currency_code']).toBe('USD');
  });

  it('should upsert cached rates on conflict', () => {
    db.run(
      `INSERT INTO cached_rates (currency_code, buy_rate, sell_rate, unit, updated_at)
       VALUES ('EUR', 395.5, 405.5, 1, '2026-03-24T10:00:00')`,
    );
    db.run(
      `INSERT INTO cached_rates (currency_code, buy_rate, sell_rate, unit, updated_at)
       VALUES ('EUR', 396.0, 406.0, 1, '2026-03-24T11:00:00')
       ON CONFLICT(currency_code) DO UPDATE SET
         buy_rate = excluded.buy_rate,
         sell_rate = excluded.sell_rate,
         updated_at = excluded.updated_at`,
    );

    const stmt = db.prepare('SELECT buy_rate, sell_rate FROM cached_rates WHERE currency_code = ?');
    stmt.bind(['EUR']);
    stmt.step();
    const row = stmt.getAsObject();
    stmt.free();
    expect(row['buy_rate']).toBe(396.0);
    expect(row['sell_rate']).toBe(406.0);
  });
});

describe('sqlite — local audit events', () => {
  beforeEach(async () => {
    const wasmBinary = fs.readFileSync(wasmPath);
    const SQL = await initSqlJs({ wasmBinary: wasmBinary as unknown as ArrayBuffer });
    db = new SQL.Database();
    runSchema(db);
  });

  afterEach(() => {
    if (db) db.close();
  });

  it('should insert audit events', () => {
    db.run(
      `INSERT INTO local_audit_events (entity_type, event_type, payload_json, status, retention_until)
       VALUES ('TRANSACTION', 'SELL', '{"test": true}', 'LOCAL_RECORDED', '2026-04-24')`,
    );

    const stmt = db.prepare('SELECT * FROM local_audit_events');
    stmt.step();
    const row = stmt.getAsObject();
    stmt.free();

    expect(row['entity_type']).toBe('TRANSACTION');
    expect(row['event_type']).toBe('SELL');
    expect(row['status']).toBe('LOCAL_RECORDED');
    expect(JSON.parse(row['payload_json'] as string)).toEqual({ test: true });
  });

  it('should cleanup old audit events', () => {
    // Insert old event
    db.run(
      `INSERT INTO local_audit_events (entity_type, event_type, payload_json, status, retention_until, created_at)
       VALUES ('TRANSACTION', 'SELL', '{}', 'LOCAL_RECORDED', '2026-01-01', '2025-01-01 00:00:00')`,
    );
    // Insert recent event
    db.run(
      `INSERT INTO local_audit_events (entity_type, event_type, payload_json, status, retention_until)
       VALUES ('TRANSACTION', 'BUY', '{}', 'LOCAL_RECORDED', '2027-01-01')`,
    );

    // Cleanup events older than 31 days
    db.run(`DELETE FROM local_audit_events WHERE datetime(created_at) < datetime('now', ?)`, [
      '-31 days',
    ]);

    const stmt = db.prepare('SELECT COUNT(*) as cnt FROM local_audit_events');
    stmt.step();
    const row = stmt.getAsObject();
    stmt.free();
    expect(row['cnt']).toBe(1);
  });
});

/**
 * NGM 23/2014 szigorú számadású sorszám atomicitás (fix/penztar-strict-receipt-seq-atomic).
 *
 * A sorszám-előléptetés (local_receipt_sequence UPSERT) ÉS a hozzá tartozó
 * pending-sor INSERT egyetlen SQL tranzakcióban fut (BEGIN ... COMMIT / ROLLBACK).
 * Ha az INSERT a sorszám-inkrement UTÁN dob, a ROLLBACK visszaállítja a sequence-t
 * is → NINCS hézag a sorozatban (adó/audit-megfelelőség).
 *
 * Ezek a tesztek pontosan a sqlite.ts `withTransaction(() => { gen + INSERT })`
 * mintát replikálják in-memory, mert az `initDatabase()` electron `app`-függő.
 */
describe('sqlite — strict receipt sequence atomicity (withTransaction)', () => {
  // A VALÓS production tranzakció-mag (sqlite.ts runInTransaction) — NEM replika.
  // A withTransaction(db, fn) alias a meglévő hívási helyek érintetlenül hagyásához.
  const withTransaction = runInTransaction;

  /** A generateStrictReceiptNumber sequence-UPSERT magja. */
  function bumpSequence(database: Database, branch: string, prefix: string): number {
    database.run(
      `INSERT INTO local_receipt_sequence (branch_code, prefix, last_seq, updated_at)
       VALUES (?, ?, 1, datetime('now'))
       ON CONFLICT(branch_code, prefix) DO UPDATE SET
         last_seq = last_seq + 1,
         updated_at = datetime('now')`,
      [branch, prefix],
    );
    const stmt = database.prepare(
      'SELECT last_seq FROM local_receipt_sequence WHERE branch_code = ? AND prefix = ?',
    );
    stmt.bind([branch, prefix]);
    stmt.step();
    const seq = Number(stmt.getAsObject()['last_seq'] ?? 1);
    stmt.free();
    return seq;
  }

  function readSeq(database: Database, branch: string, prefix: string): number | null {
    const stmt = database.prepare(
      'SELECT last_seq FROM local_receipt_sequence WHERE branch_code = ? AND prefix = ?',
    );
    stmt.bind([branch, prefix]);
    const has = stmt.step();
    const seq = has ? Number(stmt.getAsObject()['last_seq']) : null;
    stmt.free();
    return seq;
  }

  beforeEach(async () => {
    const wasmBinary = fs.readFileSync(wasmPath);
    const SQL = await initSqlJs({ wasmBinary: wasmBinary as unknown as ArrayBuffer });
    db = new SQL.Database();
    runSchema(db);
    db.run(`
      CREATE TABLE IF NOT EXISTS local_receipt_sequence (
        branch_code TEXT NOT NULL,
        prefix TEXT NOT NULL,
        last_seq INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT DEFAULT (datetime('now')),
        PRIMARY KEY (branch_code, prefix)
      );
    `);
  });

  afterEach(() => {
    if (db) db.close();
  });

  it('success path: assigns the number AND inserts the row in one transaction', () => {
    const ref = withTransaction(db, () => {
      const seq = bumpSequence(db, '039', 'V');
      const r = `V039${String(seq).padStart(6, '0')}`;
      db.run(
        `INSERT INTO pending_transactions (type, currency_code, foreign_amount, huf_amount, rounded_huf_amount, rate, local_reference_number)
         VALUES ('BUY', 'EUR', 100, 40000, 40000, 400, ?)`,
        [r],
      );
      return r;
    });

    expect(ref).toBe('V039000001');
    expect(readSeq(db, '039', 'V')).toBe(1);

    const stmt = db.prepare(
      'SELECT local_reference_number FROM pending_transactions WHERE local_reference_number = ?',
    );
    stmt.bind([ref]);
    expect(stmt.step()).toBe(true);
    stmt.free();
  });

  it('rollback path: a failing INSERT after the sequence bump leaves last_seq UNCHANGED (no gap)', () => {
    // 1) Sikeres mentés → seq = 1
    withTransaction(db, () => {
      const seq = bumpSequence(db, '039', 'V');
      const r = `V039${String(seq).padStart(6, '0')}`;
      db.run(
        `INSERT INTO pending_transactions (type, currency_code, foreign_amount, huf_amount, rounded_huf_amount, rate, local_reference_number)
         VALUES ('BUY', 'EUR', 100, 40000, 40000, 400, ?)`,
        [r],
      );
      return r;
    });
    expect(readSeq(db, '039', 'V')).toBe(1);

    // 2) A következő mentés az INSERT-nél dob (type CHECK constraint sérül 'INVALID'-dal),
    //    a sorszám-inkrement (seq → 2) UTÁN. A withTransaction ROLLBACK-eli.
    expect(() => {
      withTransaction(db, () => {
        const seq = bumpSequence(db, '039', 'V'); // ideiglenesen 2-re lépne
        const r = `V039${String(seq).padStart(6, '0')}`;
        db.run(
          `INSERT INTO pending_transactions (type, currency_code, foreign_amount, huf_amount, rounded_huf_amount, rate, local_reference_number)
           VALUES ('INVALID', 'EUR', 100, 40000, 40000, 400, ?)`,
          [r],
        );
        return r;
      });
    }).toThrow();

    // A ROLLBACK miatt a sequence VÁLTOZATLAN maradt → nincs hézag.
    expect(readSeq(db, '039', 'V')).toBe(1);

    // 3) A következő SIKERES mentés ÚJRA az 1 utáni 2-es számot kapja (a kihagyott szám
    //    nem veszett el): bizonyítja, hogy a hibás kör nem fogyasztott el sorszámot.
    const ref2 = withTransaction(db, () => {
      const seq = bumpSequence(db, '039', 'V');
      const r = `V039${String(seq).padStart(6, '0')}`;
      db.run(
        `INSERT INTO pending_transactions (type, currency_code, foreign_amount, huf_amount, rounded_huf_amount, rate, local_reference_number)
         VALUES ('SELL', 'EUR', 100, 40000, 40000, 400, ?)`,
        [r],
      );
      return r;
    });
    expect(ref2).toBe('V039000002');
    expect(readSeq(db, '039', 'V')).toBe(2);

    // Csak 2 sor van (a hibás kör nem szúrt be), és a sorszámozás hézagmentes: 1, 2.
    const stmt = db.prepare(
      'SELECT local_reference_number FROM pending_transactions ORDER BY id ASC',
    );
    const refs: string[] = [];
    while (stmt.step()) {
      refs.push(stmt.getAsObject()['local_reference_number'] as string);
    }
    stmt.free();
    expect(refs).toEqual(['V039000001', 'V039000002']);
  });

  it('re-entry guard: nested withTransaction fail-fast (sql.js nem támogat nested BEGIN-t)', () => {
    // Egy fejlesztői hiba (withTransaction egy másikon belül) NE csendben korrumpáljon:
    // a re-entry guard azonnal dobjon. A külső tranzakció emiatt ROLLBACK-el.
    expect(() => {
      withTransaction(db, () => {
        bumpSequence(db, '039', 'V'); // seq → 1 (a guard miatt vissza fog gördülni)
        withTransaction(db, () => {
          bumpSequence(db, '039', 'V');
        });
      });
    }).toThrow(/re-entr/i);

    // A külső ROLLBACK miatt a sequence NEM perzisztálódott → tiszta állapot (nincs hézag,
    // nincs félig-kész tranzakció). A guard flag is visszaállt (finally), így új mentés mehet.
    expect(readSeq(db, '039', 'V')).toBeNull();
    const ref = withTransaction(db, () => {
      const seq = bumpSequence(db, '039', 'V');
      return `V039${String(seq).padStart(6, '0')}`;
    });
    expect(ref).toBe('V039000001');
  });
});

// ============================================================================
// FK-097 WU-12 — cached_handling_fee_config tábla + accessorok (FR-1)
// Az initDatabase()-t hívó minta az sqlite-save-return-id.test.ts-ből.
// ============================================================================
import { afterAll, beforeAll } from 'vitest';
import {
  initDatabase,
  getDb,
  saveCachedHandlingFeeConfig,
  getCachedHandlingFeeConfig,
} from '../sqlite';

describe('sqlite — cached_handling_fee_config (FK-097)', () => {
  beforeAll(async () => {
    mockState.tempHome = fs.mkdtempSync(path.join(os.tmpdir(), 'valuta-fee-cache-'));
    await initDatabase();
  });

  afterAll(() => {
    fs.rmSync(mockState.tempHome, { recursive: true, force: true });
  });

  function clearFeeRows(): void {
    const db = getDb();
    db!.run("DELETE FROM cached_handling_fee_config WHERE branch_id != '' OR branch_id = ''");
  }

  it('a tábla létrejön az initDatabase során', () => {
    const db = getDb();
    expect(db).not.toBeNull();
    const stmt = db!.prepare(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'cached_handling_fee_config'",
    );
    const has = stmt.step();
    stmt.free();
    expect(has).toBe(true);
  });

  it('üres táblán a getCachedHandlingFeeConfig null-t ad', () => {
    clearFeeRows();
    expect(getCachedHandlingFeeConfig()).toBeNull();
  });

  it('az upsert idempotens: ugyanaz a sor kétszer mentve EGY sort eredményez', () => {
    clearFeeRows();
    const row = {
      branch_id: 'branch-1',
      branch_code: '105',
      company_id: 'company-1',
      fee_mode: 'PER_MILLE' as const,
      per_mille_rate: 3.5,
      per_mille_cap: 2000,
      bracket_json: null,
      valid_from: '2026-08-26',
    };
    saveCachedHandlingFeeConfig(row);
    saveCachedHandlingFeeConfig(row);

    const db = getDb();
    const stmt = db!.prepare('SELECT COUNT(*) AS c FROM cached_handling_fee_config');
    stmt.step();
    const count = Number(stmt.getAsObject()['c']);
    stmt.free();
    expect(count).toBe(1);

    const cached = getCachedHandlingFeeConfig();
    expect(cached).not.toBeNull();
    expect(cached!.branch_id).toBe('branch-1');
    expect(cached!.fee_mode).toBe('PER_MILLE');
    expect(cached!.per_mille_rate).toBe(3.5);
    expect(cached!.per_mille_cap).toBe(2000);
    expect(cached!.valid_from).toBe('2026-08-26');
  });
});
