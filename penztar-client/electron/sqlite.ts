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
    try {
      fs.mkdirSync(valutaDir, { recursive: true });
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      throw new Error(`Nem sikerült létrehozni a valuta mappát: ${valutaDir}. ${message}`, { cause: err });
    }
  }
  return path.join(valutaDir, 'local.db');
}

function resolveWasmPath(): string {
  const candidates: string[] = [];

  if (app.isPackaged) {
    candidates.push(path.join(process.resourcesPath, 'sql-wasm.wasm'));
    candidates.push(path.join(app.getAppPath(), 'resources', 'sql-wasm.wasm'));
    candidates.push(path.join(app.getAppPath(), 'sql-wasm.wasm'));
    candidates.push(path.join(__dirname, 'sql-wasm.wasm'));
  } else {
    candidates.push(path.join(__dirname, '../node_modules/sql.js/dist/sql-wasm.wasm'));
    candidates.push(path.join(process.cwd(), 'node_modules/sql.js/dist/sql-wasm.wasm'));
  }

  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }

  throw new Error(`sql-wasm.wasm nem található. Próbált útvonalak: ${candidates.join(' | ')}`);
}

export async function initDatabase(): Promise<void> {
  try {
    dbPath = getDbPath();

    const wasmPath = resolveWasmPath();

    const wasmBinary = fs.readFileSync(wasmPath);
    const SQL = await initSqlJs({ wasmBinary });

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
        updated_at TEXT NOT NULL,
        official_rate REAL,
        limit1_amount REAL,
        limit1_buy_rate REAL,
        limit1_sell_rate REAL,
        limit2_amount REAL,
        limit2_buy_rate REAL,
        limit2_sell_rate REAL,
        limit3_amount REAL,
        limit3_buy_rate REAL,
        limit3_sell_rate REAL
      );
    `);

    // Migrate: add limit columns if they don't exist (for existing installations)
    const limitColumns = [
      'official_rate', 'limit1_amount', 'limit1_buy_rate', 'limit1_sell_rate',
      'limit2_amount', 'limit2_buy_rate', 'limit2_sell_rate',
      'limit3_amount', 'limit3_buy_rate', 'limit3_sell_rate',
    ];
    for (const col of limitColumns) {
      try {
        db.run(`ALTER TABLE cached_rates ADD COLUMN ${col} REAL`);
      } catch {
        // Column already exists — ignore
      }
    }

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
        idempotency_key TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0
      );
    `);

    // Migrate: add idempotency_key column for existing installations
    try {
      db.run('ALTER TABLE pending_transactions ADD COLUMN idempotency_key TEXT');
    } catch {
      // Column already exists — ignore
    }

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

    // Értéktár offline mód — pending_transfers
    db.run(`
      CREATE TABLE IF NOT EXISTS pending_transfers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        target_branch_code TEXT NOT NULL,
        currency_code TEXT NOT NULL,
        amount REAL NOT NULL,
        denominations TEXT,
        note TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0
      );
    `);

    // Értéktár offline mód — pending_distributions
    db.run(`
      CREATE TABLE IF NOT EXISTS pending_distributions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        target_branch_code TEXT NOT NULL,
        currency_code TEXT NOT NULL,
        amount REAL NOT NULL,
        denominations TEXT,
        note TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0
      );
    `);

    // Értéktár offline mód — cached_branch_status
    db.run(`
      CREATE TABLE IF NOT EXISTS cached_branch_status (
        branch_code TEXT PRIMARY KEY,
        branch_name TEXT NOT NULL,
        company_id INTEGER,
        last_sync_at TEXT,
        online_status TEXT DEFAULT 'offline',
        total_huf_value REAL DEFAULT 0,
        daily_turnover REAL DEFAULT 0,
        cash_balances TEXT,
        cached_at TEXT DEFAULT (datetime('now'))
      );
    `);

    // Értéktár offline mód — pending_collections
    db.run(`
      CREATE TABLE IF NOT EXISTS pending_collections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source_branch_code TEXT NOT NULL,
        currency_code TEXT NOT NULL,
        amount REAL NOT NULL,
        note TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0
      );
    `);

    saveDatabase();
  } catch (err) {
    const error = err as NodeJS.ErrnoException | Error;
    const errorCode = 'code' in error && error.code ? String(error.code) : 'unknown';
    const errorMessage = error instanceof Error ? error.message : String(error);
    const wasmPath = (() => {
      try {
        return resolveWasmPath();
      } catch (resolveErr) {
        const resolveMessage = resolveErr instanceof Error ? resolveErr.message : String(resolveErr);
        return `resolve error: ${resolveMessage}`;
      }
    })();

    const details = [
      `dbPath=${dbPath || 'n/a'}`,
      `wasmPath=${wasmPath}`,
      `resourcesPath=${process.resourcesPath}`,
      `appPath=${app.getAppPath()}`,
      `isPackaged=${app.isPackaged}`,
      `errorCode=${errorCode}`,
      `errorMessage=${errorMessage}`,
    ].join('\n');

    throw new Error(`Database init failed:\n${details}`, { cause: err });
  }
}

/**
 * Atomi adatbázis mentés — temp fájl + rename pattern.
 *
 * Ez véd az áramszünet/crash közbeni korrupció ellen:
 * 1. Írás temp fájlba (dbPath + '.tmp')
 * 2. Rename temp → végleges (atomi művelet a legtöbb fájlrendszeren)
 * Ha a rename sikertelen, a temp fájl marad, az eredeti DB érintetlen.
 */
export function saveDatabase(): void {
  if (!db) return;
  const data = db.export();
  const buffer = Buffer.from(data);
  const tmpPath = dbPath + '.tmp';

  try {
    fs.writeFileSync(tmpPath, buffer);
    fs.renameSync(tmpPath, dbPath);
  } catch (err) {
    // Fallback: ha a rename nem működik (pl. cross-device), közvetlen írás
    try {
      fs.unlinkSync(tmpPath);
    } catch {
      // tmp cleanup hiba nem blokkoló
    }
    fs.writeFileSync(dbPath, buffer);
  }
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
  idempotency_key: string | null;
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

  // Stabil idempotency key — retry-nál is ugyanazt küldjük a szervernek
  const idempotencyKey = crypto.randomUUID();

  db.run(
    `INSERT INTO pending_transactions (type, currency_code, foreign_amount, huf_amount, rounded_huf_amount, rate, customer_id, denominations, idempotency_key)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [type, currencyCode, foreignAmount, hufAmount, roundedHufAmount, rate, customerId, denominations, idempotencyKey],
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

// --- Értéktár Offline: Pending Distributions ---

export interface PendingDistributionRow {
  id: number;
  target_branch_code: string;
  currency_code: string;
  amount: number;
  denominations: string | null;
  note: string | null;
  created_at: string;
  synced: number;
}

export function savePendingDistribution(
  targetBranchCode: string,
  currencyCode: string,
  amount: number,
  denominations: string | null,
  note: string | null,
): number {
  if (!db) throw new Error('Database not initialized');

  db.run(
    `INSERT INTO pending_distributions (target_branch_code, currency_code, amount, denominations, note)
     VALUES (?, ?, ?, ?, ?)`,
    [targetBranchCode, currencyCode, amount, denominations, note],
  );
  saveDatabase();

  const stmt = db.prepare('SELECT last_insert_rowid() as id');
  stmt.step();
  const row = stmt.getAsObject();
  stmt.free();
  return (row['id'] as number) ?? 0;
}

export function getPendingDistributions(): PendingDistributionRow[] {
  if (!db) return [];
  const results: PendingDistributionRow[] = [];
  const stmt = db.prepare('SELECT * FROM pending_distributions WHERE synced = 0 ORDER BY created_at ASC');
  while (stmt.step()) {
    results.push(stmt.getAsObject() as unknown as PendingDistributionRow);
  }
  stmt.free();
  return results;
}

export function markDistributionSynced(id: number): void {
  if (!db) return;
  db.run('UPDATE pending_distributions SET synced = 1 WHERE id = ?', [id]);
  saveDatabase();
}

// --- Értéktár Offline: Pending Transfers ---

export interface PendingTransferRow {
  id: number;
  target_branch_code: string;
  currency_code: string;
  amount: number;
  denominations: string | null;
  note: string | null;
  created_at: string;
  synced: number;
}

export function savePendingTransfer(
  targetBranchCode: string,
  currencyCode: string,
  amount: number,
  denominations: string | null,
  note: string | null,
): number {
  if (!db) throw new Error('Database not initialized');

  db.run(
    `INSERT INTO pending_transfers (target_branch_code, currency_code, amount, denominations, note)
     VALUES (?, ?, ?, ?, ?)`,
    [targetBranchCode, currencyCode, amount, denominations, note],
  );
  saveDatabase();

  const stmt = db.prepare('SELECT last_insert_rowid() as id');
  stmt.step();
  const row = stmt.getAsObject();
  stmt.free();
  return (row['id'] as number) ?? 0;
}

export function getPendingTransfers(): PendingTransferRow[] {
  if (!db) return [];
  const results: PendingTransferRow[] = [];
  const stmt = db.prepare('SELECT * FROM pending_transfers WHERE synced = 0 ORDER BY created_at ASC');
  while (stmt.step()) {
    results.push(stmt.getAsObject() as unknown as PendingTransferRow);
  }
  stmt.free();
  return results;
}

export function markTransferSynced(id: number): void {
  if (!db) return;
  db.run('UPDATE pending_transfers SET synced = 1 WHERE id = ?', [id]);
  saveDatabase();
}

// --- Értéktár Offline: Pending Collections ---

export interface PendingCollectionRow {
  id: number;
  source_branch_code: string;
  currency_code: string;
  amount: number;
  note: string | null;
  created_at: string;
  synced: number;
}

export function savePendingCollection(
  sourceBranchCode: string,
  currencyCode: string,
  amount: number,
  note: string | null,
): number {
  if (!db) throw new Error('Database not initialized');

  db.run(
    `INSERT INTO pending_collections (source_branch_code, currency_code, amount, note)
     VALUES (?, ?, ?, ?)`,
    [sourceBranchCode, currencyCode, amount, note],
  );
  saveDatabase();

  const stmt = db.prepare('SELECT last_insert_rowid() as id');
  stmt.step();
  const row = stmt.getAsObject();
  stmt.free();
  return (row['id'] as number) ?? 0;
}

export function getPendingCollections(): PendingCollectionRow[] {
  if (!db) return [];
  const results: PendingCollectionRow[] = [];
  const stmt = db.prepare('SELECT * FROM pending_collections WHERE synced = 0 ORDER BY created_at ASC');
  while (stmt.step()) {
    results.push(stmt.getAsObject() as unknown as PendingCollectionRow);
  }
  stmt.free();
  return results;
}

export function markCollectionSynced(id: number): void {
  if (!db) return;
  db.run('UPDATE pending_collections SET synced = 1 WHERE id = ?', [id]);
  saveDatabase();
}

// --- Értéktár Offline: Cached Branch Status ---

export interface CachedBranchStatusRow {
  branch_code: string;
  branch_name: string;
  company_id: number | null;
  last_sync_at: string | null;
  online_status: string;
  total_huf_value: number;
  daily_turnover: number;
  cash_balances: string | null;
  cached_at: string;
}

export function saveCachedBranchStatus(
  branchCode: string,
  branchName: string,
  companyId: number | null,
  lastSyncAt: string | null,
  onlineStatus: string,
  totalHufValue: number,
  dailyTurnover: number,
  cashBalances: string | null,
): void {
  if (!db) return;

  db.run(
    `INSERT INTO cached_branch_status (branch_code, branch_name, company_id, last_sync_at, online_status, total_huf_value, daily_turnover, cash_balances, cached_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))
     ON CONFLICT(branch_code) DO UPDATE SET
       branch_name = excluded.branch_name,
       company_id = excluded.company_id,
       last_sync_at = excluded.last_sync_at,
       online_status = excluded.online_status,
       total_huf_value = excluded.total_huf_value,
       daily_turnover = excluded.daily_turnover,
       cash_balances = excluded.cash_balances,
       cached_at = excluded.cached_at`,
    [branchCode, branchName, companyId, lastSyncAt, onlineStatus, totalHufValue, dailyTurnover, cashBalances],
  );
  saveDatabase();
}

export function getCachedBranchStatuses(): CachedBranchStatusRow[] {
  if (!db) return [];
  const results: CachedBranchStatusRow[] = [];
  const stmt = db.prepare('SELECT * FROM cached_branch_status ORDER BY branch_code ASC');
  while (stmt.step()) {
    results.push(stmt.getAsObject() as unknown as CachedBranchStatusRow);
  }
  stmt.free();
  return results;
}

export function getCachedBranchStatusTimestamp(): string | null {
  if (!db) return null;
  const stmt = db.prepare('SELECT MAX(cached_at) as last_cached FROM cached_branch_status');
  stmt.step();
  const row = stmt.getAsObject();
  stmt.free();
  return (row['last_cached'] as string) ?? null;
}

// --- Értéktár Offline: Cached Rates (extended read) ---

export interface CachedRateRow {
  currency_code: string;
  buy_rate: number;
  sell_rate: number;
  unit: number;
  updated_at: string;
  official_rate?: number | null;
  limit1_amount?: number | null;
  limit1_buy_rate?: number | null;
  limit1_sell_rate?: number | null;
  limit2_amount?: number | null;
  limit2_buy_rate?: number | null;
  limit2_sell_rate?: number | null;
  limit3_amount?: number | null;
  limit3_buy_rate?: number | null;
  limit3_sell_rate?: number | null;
}

export function getCachedRates(): CachedRateRow[] {
  if (!db) return [];
  const results: CachedRateRow[] = [];
  const stmt = db.prepare('SELECT * FROM cached_rates ORDER BY currency_code ASC');
  while (stmt.step()) {
    results.push(stmt.getAsObject() as unknown as CachedRateRow);
  }
  stmt.free();
  return results;
}
