import initSqlJs, { type Database } from 'sql.js';
import path from 'node:path';
import { app } from 'electron';
import fs from 'node:fs';

let db: Database | null = null;
let dbPath = '';

function getDbPath(): string {
  const userDir = app.getPath('home');
  const valutaDir = path.join(userDir, '.valuta');
  if (!fs.existsSync(valutaDir)) {
    fs.mkdirSync(valutaDir, { recursive: true });
  }
  return path.join(valutaDir, 'local.db');
}

export async function initDatabase(): Promise<void> {
  dbPath = getDbPath();

  const SQL = await initSqlJs();

  // Ha létezik a DB fájl, betöltjük
  if (fs.existsSync(dbPath)) {
    const buffer = fs.readFileSync(dbPath);
    db = new SQL.Database(buffer);
  } else {
    db = new SQL.Database();
  }

  db.run('PRAGMA foreign_keys = ON;');

  db.run(`
    CREATE TABLE IF NOT EXISTS config (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL,
      updated_at TEXT DEFAULT (datetime('now'))
    );
  `);

  db.run(`
    CREATE TABLE IF NOT EXISTS cached_rates (
      currency_code TEXT PRIMARY KEY,
      buy_rate REAL NOT NULL,
      sell_rate REAL NOT NULL,
      unit INTEGER NOT NULL DEFAULT 1,
      updated_at TEXT NOT NULL
    );
  `);

  db.run(`
    CREATE TABLE IF NOT EXISTS pending_transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type TEXT NOT NULL CHECK(type IN ('SELL', 'BUY')),
      currency_code TEXT NOT NULL,
      foreign_amount REAL NOT NULL,
      huf_amount REAL NOT NULL,
      rounded_huf_amount REAL NOT NULL,
      rate REAL NOT NULL,
      customer_id INTEGER,
      denominations TEXT,
      created_at TEXT DEFAULT (datetime('now')),
      synced INTEGER DEFAULT 0
    );
  `);

  db.run(`
    CREATE TABLE IF NOT EXISTS cached_customers (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      document_type TEXT NOT NULL,
      document_number TEXT NOT NULL,
      nationality TEXT,
      birth_date TEXT,
      cached_at TEXT DEFAULT (datetime('now'))
    );
  `);

  saveDatabase();
}

function saveDatabase(): void {
  if (!db) return;
  const data = db.export();
  const buffer = Buffer.from(data);
  fs.writeFileSync(dbPath, buffer);
}

export function getConfig(key: string): string | null {
  if (!db) return null;
  const stmt = db.prepare('SELECT value FROM config WHERE key = ?');
  stmt.bind([key]);
  if (stmt.step()) {
    const row = stmt.getAsObject();
    stmt.free();
    return (row['value'] as string) ?? null;
  }
  stmt.free();
  return null;
}

export function setConfig(key: string, value: string): void {
  if (!db) return;

  // M2: Input validáció — key max 100 char, value max 10 000 char
  if (key.length > 100) {
    throw new Error(`Config key too long: ${key.length} chars (max 100)`);
  }
  if (value.length > 10_000) {
    throw new Error(`Config value too long: ${value.length} chars (max 10000)`);
  }

  db.run(
    `INSERT INTO config (key, value, updated_at) VALUES (?, ?, datetime('now'))
     ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at`,
    [key, value],
  );
  saveDatabase();
}

export function deleteConfig(key: string): void {
  if (!db) return;
  db.run('DELETE FROM config WHERE key = ?', [key]);
  saveDatabase();
}

// --- Offline Pending Transactions ---

export interface PendingTransactionRow {
  id: number;
  type: string;
  currency_code: string;
  foreign_amount: number;
  huf_amount: number;
  rounded_huf_amount: number;
  rate: number;
  customer_id: number | null;
  denominations: string | null;
  created_at: string;
  synced: number;
}

export function savePendingTransaction(
  type: 'SELL' | 'BUY',
  currencyCode: string,
  foreignAmount: number,
  hufAmount: number,
  roundedHufAmount: number,
  rate: number,
  customerId: number | null,
  denominations: string | null,
): number {
  if (!db) throw new Error('Database not initialized');

  db.run(
    `INSERT INTO pending_transactions (type, currency_code, foreign_amount, huf_amount, rounded_huf_amount, rate, customer_id, denominations)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    [type, currencyCode, foreignAmount, hufAmount, roundedHufAmount, rate, customerId, denominations],
  );
  saveDatabase();

  // Get last inserted ID
  const stmt = db.prepare('SELECT last_insert_rowid() as id');
  stmt.step();
  const row = stmt.getAsObject();
  stmt.free();
  return (row['id'] as number) ?? 0;
}

export function getPendingTransactions(): PendingTransactionRow[] {
  if (!db) return [];

  const results: PendingTransactionRow[] = [];
  const stmt = db.prepare('SELECT * FROM pending_transactions WHERE synced = 0 ORDER BY created_at ASC');
  while (stmt.step()) {
    const row = stmt.getAsObject() as unknown as PendingTransactionRow;
    results.push(row);
  }
  stmt.free();
  return results;
}

export function markTransactionSynced(id: number): void {
  if (!db) return;
  db.run('UPDATE pending_transactions SET synced = 1 WHERE id = ?', [id]);
  saveDatabase();
}

export function getPendingTransactionCount(): number {
  if (!db) return 0;
  const stmt = db.prepare('SELECT COUNT(*) as cnt FROM pending_transactions WHERE synced = 0');
  stmt.step();
  const row = stmt.getAsObject();
  stmt.free();
  return (row['cnt'] as number) ?? 0;
}

export function getDb(): Database | null {
  return db;
}
