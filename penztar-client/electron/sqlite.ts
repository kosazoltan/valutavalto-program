import initSqlJs, { type Database } from 'sql.js';
import path from 'node:path';
import { app } from 'electron';
import fs from 'node:fs';
import crypto from 'node:crypto';
import type {
  PendingConversionInputV2,
  PendingHandoverOperationInput,
  PendingStornoInput,
  PendingTransactionInputV2,
  PendingCircularReplyInput,
  PendingTransferStornoInput,
  PendingShipmentReceiptInput,
} from '@valuta/shared-ipc';

export type {
  PendingConversionInputV2,
  PendingHandoverOperationInput,
  PendingStornoInput,
  PendingTransactionInputV2,
  PendingCircularReplyInput,
  PendingTransferStornoInput,
  PendingShipmentReceiptInput,
};

let db: Database | null = null;
let dbPath = '';

/**
 * NGM 23/2014 atomicitás-garancia: a szigorú bizonylat-sorszám UPSERT (sequence
 * inkrement) ÉS a hozzá tartozó pending-sor INSERT EGYETLEN SQL tranzakcióban
 * fusson. Ha az INSERT a sequence-inkrement UTÁN dob (constraint/runtime hiba),
 * a ROLLBACK visszacsinálja a sequence-előléptetést is → NINCS hézag a szigorú
 * számadású sorszámozásban (adó/audit-megfelelőség: a sorozat hézagmentes).
 *
 * sql.js NEM támogat egymásba ágyazott BEGIN-t, ezért ezt CSAK top-level
 * (IPC-szintű) mentésekben szabad hívni, soha nem egy másik withTransaction-ön
 * belül. A re-entrancia ellen RUNTIME guard véd: ha egy hívó tévedésből egy már
 * futó tranzakción belül hívja, fail-fast hibát kapunk (nem csendes korrupció).
 */
let inTransaction = false;

/**
 * A tranzakció-MAG: explicit {@link Database}-szel. A production logika (BEGIN /
 * COMMIT / ROLLBACK + re-entry guard) EGYETLEN helyen él, hogy a unit teszt a
 * VALÓS kódot exercise-elje (ne egy viselkedés-replikát). Az electron-független
 * tesztek a saját in-memory db-jükkel hívják; a {@link withTransaction} a modul
 * `db` globáljával delegál ide.
 */
export function runInTransaction<T>(database: Database, fn: () => T): T {
  if (inTransaction) {
    // Re-entry guard: sql.js nem támogat nested BEGIN-t → fail-fast, hogy egy
    // fejlesztői hiba SOHA ne csendben korrumpálja a folyamatban lévő tranzakciót.
    throw new Error('withTransaction nem hívható re-entránsan (sql.js nem támogat nested BEGIN-t)');
  }
  inTransaction = true;
  database.run('BEGIN');
  try {
    const result = fn();
    database.run('COMMIT');
    return result;
  } catch (e) {
    try {
      database.run('ROLLBACK');
    } catch {
      /* rollback best-effort */
    }
    throw e;
  } finally {
    inTransaction = false;
  }
}

/**
 * A frissen beszúrt sor rowid-ja. KRITIKUS: közvetlenül az INSERT után,
 * még BÁRMELY saveDatabase() előtt kell hívni — a sql.js Database.export()
 * (amit a saveDatabase() hív) bezárja és újranyitja az alacsony szintű
 * sqlite3 kapcsolatot, ami után a last_insert_rowid() már 0.
 */
function lastInsertRowId(database: Database): number {
  const stmt = database.prepare('SELECT last_insert_rowid() as id');
  stmt.step();
  const row = stmt.getAsObject();
  stmt.free();
  return (row['id'] as number) ?? 0;
}

function withTransaction<T>(fn: () => T): T {
  if (!db) throw new Error('Database not initialized');
  return runInTransaction(db, fn);
}

export const OUTBOX_TABLES = [
  'pending_transactions',
  'pending_conversions',
  'pending_bank_transactions',
  'pending_stornos',
  'pending_handover_operations',
  'pending_transfers',
  'pending_transfer_stornos',
  'pending_shipment_receipts',
  'pending_circular_replies',
  // 2026-08-11 (FKH-D2/F5 felderites): ez a tabla KIMARADT a listabol, pedig van
  // `company_code` (:849) es `synced` (:852) oszlopa. Emiatt az
  // `ensureOutboxCompanyColumns` multi-tenant backfill kihagyta -> a szinkronizalatlan
  // szkennelt dokumentumok `company_code`-ja NULL maradhatott.
  'pending_scanned_documents',
  'pending_distributions',
  'pending_collections',
  'pending_stocktake_items',
] as const;

/** Additív SQLite oszlopmigráció: kizárólag a várt duplicate-column hibát kezeli idempotensen. */
export function addColumnIfMissing(
  database: Database,
  table: string,
  columnName: string,
  columnDefinition: string,
): void {
  const identifierPattern = /^[A-Za-z_][A-Za-z0-9_]*$/;
  if (!identifierPattern.test(table) || !identifierPattern.test(columnName)) {
    throw new Error('Érvénytelen SQLite migrációs azonosító');
  }
  try {
    database.run(`ALTER TABLE ${table} ADD COLUMN ${columnName} ${columnDefinition}`);
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    if (message.trim().toLowerCase() !== `duplicate column name: ${columnName.toLowerCase()}`) {
      throw err;
    }
  }
}

/**
 * Multi-tenant outbox invariant (2026-07-04): every offline outbox row can carry
 * the company code active when it was recorded. Additive + idempotent repo pattern.
 */
export function ensureOutboxCompanyColumns(
  database: Database,
  activeCompanyCode: string | null,
): void {
  for (const table of OUTBOX_TABLES) {
    try {
      database.run(`ALTER TABLE ${table} ADD COLUMN company_code TEXT`);
    } catch {
      // Column already exists — expected on fresh installs or repeated init.
    }
  }

  const code = activeCompanyCode?.trim();
  if (!code) return;

  for (const table of OUTBOX_TABLES) {
    try {
      database.run(
        `UPDATE ${table} SET company_code = ? WHERE company_code IS NULL AND synced = 0`,
        [code],
      );
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      if (!message.includes('no such table')) {
        throw err;
      }
      // Partially upgraded/legacy local DBs may not have a newly-added outbox table yet.
      // Its CREATE TABLE DDL runs later in normal init; no rows exist to backfill now.
    }
  }
}

interface DatabasePathEnvironment {
  ELECTRON_DEV_USER_DATA?: string;
  SystemDrive?: string;
  SystemRoot?: string;
  ProgramFiles?: string;
  'ProgramFiles(x86)'?: string;
  ProgramData?: string;
}

/**
 * A lokális SQLite fájl útvonala. Packaged módban mindig a változatlan
 * production defaultot használja; kizárólag dev/E2E módban enged izolált
 * Electron profil alatti adatbázist.
 */
export function resolveDatabasePath(
  homeDir: string,
  environment: DatabasePathEnvironment,
  isPackaged: boolean,
): string {
  const productionDatabasePath = path.join(homeDir, '.valuta', 'local.db');
  if (isPackaged) {
    return productionDatabasePath;
  }

  const overrideName = 'ELECTRON_DEV_USER_DATA';
  if (environment[overrideName] !== undefined) {
    const rawOverride = environment[overrideName];
    const overrideDir = rawOverride.trim();
    if (!overrideDir) {
      throw new Error(`${overrideName} nem lehet üres.`);
    }

    if (/^[\\/]{2}/u.test(overrideDir)) {
      throw new Error(
        `${overrideName} nem használhat UNC útvonalat, Windows namespace- vagy device-prefixet.`,
      );
    }
    const hasTerminalSpaceBeforeNormalization = / $/u.test(rawOverride);
    if (
      hasTerminalSpaceBeforeNormalization ||
      overrideDir
        .split(/[\\/]/u)
        .some((segment) => segment !== '.' && segment !== '..' && /[. ]$/u.test(segment))
    ) {
      throw new Error(
        `${overrideName} útvonalszegmense nem végződhet ponttal vagy szóközzel: ${overrideDir}`,
      );
    }

    if (!path.isAbsolute(overrideDir)) {
      throw new Error(`${overrideName} csak abszolút könyvtárútvonal lehet: ${overrideDir}`);
    }

    const resolvedDir = path.resolve(overrideDir);
    if (resolvedDir === path.parse(resolvedDir).root) {
      throw new Error(`${overrideName} nem mutathat fájlrendszer-gyökérre: ${resolvedDir}`);
    }

    const systemDriveMatch = /^([A-Za-z]):[\\/]?$/u.exec(environment.SystemDrive?.trim() ?? '');
    const fallbackWindowsRoot = path.resolve(`${systemDriveMatch?.[1] ?? 'C'}:\\Windows`);
    const protectedRoots = [
      environment.SystemRoot,
      fallbackWindowsRoot,
      environment.ProgramFiles,
      environment['ProgramFiles(x86)'],
      environment.ProgramData,
    ]
      .map((root) => root?.trim())
      .filter(
        (root): root is string =>
          typeof root === 'string' && root.length > 0 && path.isAbsolute(root),
      )
      .map((root) => path.resolve(root));

    const isProtectedPath = protectedRoots.some((protectedRoot) => {
      const relativePath = path.relative(protectedRoot.toLowerCase(), resolvedDir.toLowerCase());
      return (
        relativePath === '' ||
        (relativePath !== '..' &&
          !relativePath.startsWith(`..${path.sep}`) &&
          !path.isAbsolute(relativePath))
      );
    });
    if (isProtectedPath) {
      throw new Error(
        `${overrideName} nem mutathat védett rendszerkönyvtárra vagy annak leszármazottjára: ${resolvedDir}`,
      );
    }

    return path.join(resolvedDir, 'local.db');
  }

  return productionDatabasePath;
}

type DirectoryFileSystem = Pick<typeof fs, 'existsSync' | 'mkdirSync'>;

export function ensureDatabaseDirectory(
  databasePath: string,
  fileSystem: DirectoryFileSystem = fs,
): void {
  const valutaDir = path.dirname(databasePath);
  if (!fileSystem.existsSync(valutaDir)) {
    try {
      fileSystem.mkdirSync(valutaDir, { recursive: true });
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      throw new Error(`Nem sikerült létrehozni a valuta mappát: ${valutaDir}. ${message}`, {
        cause: err,
      });
    }
  }
}

function getDbPath(): string {
  const databasePath = resolveDatabasePath(app.getPath('home'), process.env, app.isPackaged);
  ensureDatabaseDirectory(databasePath);
  return databasePath;
}

function resolveWasmPath(): string {
  const candidates: string[] = [];

  if (app.isPackaged) {
    // Egyetlen stabil cel: extraResources -> resources/sql-wasm.wasm
    candidates.push(path.join(process.resourcesPath, 'sql-wasm.wasm'));
  } else {
    candidates.push(path.join(__dirname, '../node_modules/sql.js/dist/sql-wasm.wasm'));
    candidates.push(path.join(process.cwd(), 'node_modules/sql.js/dist/sql-wasm.wasm'));
  }

  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }

  const mode = app.isPackaged ? 'packaged' : 'dev';
  throw new Error(
    `sql-wasm.wasm nem tal\u00E1lhat\u00F3 (${mode} m\u00F3d). resourcesPath=${process.resourcesPath}, pr\u00F3b\u00E1lt \u00FAtvonalak: ${candidates.join(' | ')}`,
  );
}

export async function initDatabase(): Promise<void> {
  try {
    dbPath = getDbPath();

    const wasmPath = resolveWasmPath();

    const wasmBinary = fs.readFileSync(wasmPath) as unknown as ArrayBuffer;
    const SQL = await initSqlJs({ wasmBinary });

    // Ha létezik a DB fájl, betöltjük
    if (fs.existsSync(dbPath)) {
      const buffer = fs.readFileSync(dbPath);
      db = new SQL.Database(buffer);
    } else {
      db = new SQL.Database();
    }

    db.run('PRAGMA foreign_keys = ON;');

    // --- PRAGMA user_version schema versioning (local-first mandate) ---
    const versionResult = db.exec('PRAGMA user_version');
    const firstRow = versionResult[0];
    const currentVersion = firstRow?.values?.[0]?.[0] != null ? Number(firstRow.values[0]![0]) : 0;

    // --- Local-first tombstone tracking ---
    db.run(`
      CREATE TABLE IF NOT EXISTS lf_tombstone (
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        deleted_at TEXT NOT NULL DEFAULT (datetime('now')),
        synced INTEGER NOT NULL DEFAULT 0,
        retention_until TEXT NOT NULL,
        PRIMARY KEY (entity_type, entity_id)
      );
    `);

    // --- Local-first sync state ---
    db.run(`
      CREATE TABLE IF NOT EXISTS lf_sync_state (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        status TEXT NOT NULL DEFAULT 'idle',
        last_pull_at TEXT,
        last_push_at TEXT,
        last_pull_checkpoint TEXT,
        error_message TEXT,
        consecutive_failures INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT DEFAULT (datetime('now'))
      );
    `);
    db.run(`INSERT OR IGNORE INTO lf_sync_state (id, status) VALUES (1, 'idle')`);

    // --- Local-first conflict log ---
    db.run(`
      CREATE TABLE IF NOT EXISTS lf_conflict_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        local_version TEXT,
        server_version TEXT,
        resolution TEXT NOT NULL,
        resolved_at TEXT NOT NULL DEFAULT (datetime('now'))
      );
    `);

    // Bump schema version if tables were just created (first run with local-first)
    if (currentVersion < 1) {
      db.run('PRAGMA user_version = 1');
    }

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
      'official_rate',
      'limit1_amount',
      'limit1_buy_rate',
      'limit1_sell_rate',
      'limit2_amount',
      'limit2_buy_rate',
      'limit2_sell_rate',
      'limit3_amount',
      'limit3_buy_rate',
      'limit3_sell_rate',
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
        handling_fee REAL,
        discount_percent REAL,
        customer_id INTEGER,
        customer_identifier TEXT,
        customer_name TEXT,
        customer_document_number TEXT,
        customer_address TEXT,
        denominations TEXT,
        source_of_funds TEXT,
        customer_is_pep INTEGER,
        approver_worker_id INTEGER,
        approval_session_id TEXT,
        lines TEXT,
        local_reference_number TEXT,
        idempotency_key TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0
      );
    `);

    // Migrate: add PEP/source_of_funds columns if they don't exist (for existing installations)
    const pepMigrationColumns = ['source_of_funds', 'customer_is_pep'];
    for (const col of pepMigrationColumns) {
      try {
        db.run(
          `ALTER TABLE pending_transactions ADD COLUMN ${col} ${col === 'customer_is_pep' ? 'INTEGER' : 'TEXT'};`,
        );
      } catch {
        // Column already exists — expected on fresh installs
      }
    }

    // AML vezetoi jovahagyas (2026-06-04): a jovahagyo supervisor/manager/admin workerId-ja.
    // NULL, ha a tranzakcio nem igenyelt felsovezeti jovahagyast. A backend (approverWorkerId=null)
    // backward-compat, igy a meglevo telepitesek migracioja additiv es kockazatmentes.
    try {
      db.run(`ALTER TABLE pending_transactions ADD COLUMN approver_worker_id INTEGER;`);
    } catch {
      // Column already exists — expected on fresh installs
    }
    // AML jovahagyas-session azonosito (Codex P1: receipt-scoping) — a grantot a konkret nyugtahoz koti.
    try {
      db.run(`ALTER TABLE pending_transactions ADD COLUMN approval_session_id TEXT;`);
    } catch {
      // Column already exists — expected on fresh installs
    }

    // V226 (2026-05-14): foreign_status tetel-szinten oszlop
    try {
      db.run(`ALTER TABLE pending_transactions ADD COLUMN foreign_status TEXT;`);
    } catch {
      // Column already exists — expected on fresh installs or repeat migration
    }

    // Multi-line aggregate (2026-06-04): egy tobb-soros vetel/eladas nyugta EGY aggregalt
    // backend-tranzakciokent szinkronizal (egy POST /transactions/buy|sell, `lines[]` tombbel),
    // N fuggetlen egysoros helyett. Egy AML-kapu + egy approval-grant. Ha NULL, a sor egysoros
    // (valtozatlan viselkedes). A tomb a backend TransactionLineRequestDto alakjat hordozza JSON-kent.
    try {
      db.run(`ALTER TABLE pending_transactions ADD COLUMN lines TEXT;`);
    } catch {
      // Column already exists — expected on fresh installs or repeat migration
    }

    // FK-KEZDIJ offline (2026-06-12, penztar-batch B.1/b): kezelesi dij override mezok az
    // offline outboxban — a Felezes/Elenegedes/Ugyfelkartya eddig CSENDBEN elveszett az
    // Electron uton (a szerver a teljes alap-dijat konyvelte).
    const feeOverrideColumns: Array<{ name: string; type: string }> = [
      { name: 'handling_fee_override_type', type: 'TEXT' },
      { name: 'handling_fee_override_reason', type: 'TEXT' },
      { name: 'customer_card_number', type: 'TEXT' },
    ];
    for (const col of feeOverrideColumns) {
      try {
        db.run(`ALTER TABLE pending_transactions ADD COLUMN ${col.name} ${col.type};`);
      } catch {
        // Column already exists — expected on fresh installs or repeat migration
      }
    }

    // V325 (Batch3-C, 2026-06-12): jogi szemely ugyfel + tenyleges tulajdonosok az
    // offline outboxban — a legacy BLOKNYOM jogi aganak adatai a sync-ig itt elnek.
    const legalEntityColumns: Array<{ name: string; type: string }> = [
      { name: 'is_legal_entity_customer', type: 'INTEGER' }, // 0/1 (NULL = nem jogi szemely)
      { name: 'legal_entity_name', type: 'TEXT' },
      { name: 'legal_entity_seat', type: 'TEXT' },
      { name: 'legal_entity_tax_number', type: 'TEXT' },
      { name: 'legal_deed_number', type: 'TEXT' },
      { name: 'beneficial_owners_json', type: 'TEXT' }, // max 4 tulajdonos JSON-kent
    ];
    for (const col of legalEntityColumns) {
      try {
        db.run(`ALTER TABLE pending_transactions ADD COLUMN ${col.name} ${col.type};`);
      } catch {
        // Column already exists — expected on fresh installs or repeat migration
      }
    }

    // V229 + V235 (2026-05-19 HIBA #14 + #17 + #18): teljes Pmt. customer-snapshot
    // a kliens-oldali offline outbox-ban is. A korábbi sync-engine csak 4 alapmezőt
    // küldött át a backend felé, így a bizonylaton hiányzott a szül.hely / szül.idő
    // / anyja neve / állampolgárság / okmány típus / "más nevében" flag és az
    // actor (képviselt fél) teljes azonosítása.
    const customerSnapshotColumns: Array<{ name: string; type: string }> = [
      // 100k+ alapmezők (V229 backend, most kliens-oldalon is)
      { name: 'customer_birth_place', type: 'TEXT' },
      { name: 'customer_birth_date', type: 'TEXT' }, // YYYY-MM-DD
      { name: 'customer_mother_name', type: 'TEXT' },
      { name: 'customer_nationality', type: 'TEXT' },
      { name: 'customer_document_type', type: 'TEXT' }, // ID_CARD / PASSPORT / ...
      // 300k+ JOGCÍM nyilatkozat
      { name: 'customer_on_own_behalf', type: 'INTEGER' }, // 0/1 (NULL = nem kérdezett)
      { name: 'customer_actor_name', type: 'TEXT' },
      // PEP minőség (V235 NEW, HIBA #15)
      { name: 'customer_pep_kind', type: 'TEXT' }, // CSALADTAG / KOZELI_MUNKATARS / ...
      // Actor (képviselt fél) teljes azonosítása (V235 NEW, HIBA #17)
      { name: 'customer_actor_birth_place', type: 'TEXT' },
      { name: 'customer_actor_birth_date', type: 'TEXT' },
      { name: 'customer_actor_mother_name', type: 'TEXT' },
      { name: 'customer_actor_nationality', type: 'TEXT' },
      { name: 'customer_actor_document_type', type: 'TEXT' },
      { name: 'customer_actor_document_number', type: 'TEXT' },
      { name: 'customer_actor_address', type: 'TEXT' },
    ];
    for (const col of customerSnapshotColumns) {
      try {
        db.run(`ALTER TABLE pending_transactions ADD COLUMN ${col.name} ${col.type};`);
      } catch {
        // Column already exists — expected on fresh installs or repeat migration
      }
    }

    db.run(`
      CREATE TABLE IF NOT EXISTS pending_conversions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        from_currency_id INTEGER,
        from_currency_code TEXT NOT NULL,
        to_currency_id INTEGER,
        to_currency_code TEXT NOT NULL,
        from_amount REAL NOT NULL,
        calculated_huf_amount REAL NOT NULL,
        calculated_to_amount REAL NOT NULL,
        conversion_rate REAL NOT NULL,
        handling_fee REAL,
        customer_id TEXT,
        customer_name TEXT,
        customer_document_number TEXT,
        note TEXT,
        local_reference_number TEXT,
        idempotency_key TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0
      );
    `);

    // V235 + V236 (2026-05-19 HIBA #19 + Codex P1 #695): teljes Pmt. customer-
    // snapshot a Konverzio offline outbox-ban is. A korabbi pending_conversions
    // csak 3 customer mezot tartalmazott (id, name, docNumber), igy az offline
    // sync-elt konverzio bizonylatok nem tartalmazhattak a 100k+/300k+ szuk-
    // seges azonositasi adatokat (Pmt. tv. 6.§).
    const conversionSnapshotColumns: Array<{ name: string; type: string }> = [
      { name: 'customer_address', type: 'TEXT' },
      { name: 'customer_nationality', type: 'TEXT' },
      { name: 'customer_birth_place', type: 'TEXT' },
      { name: 'customer_birth_date', type: 'TEXT' },
      { name: 'customer_mother_name', type: 'TEXT' },
      { name: 'customer_document_type', type: 'TEXT' },
      { name: 'source_of_funds', type: 'TEXT' },
      { name: 'customer_is_pep', type: 'INTEGER' },
      // AML vezetoi jovahagyas (2026-06-04): jovahagyo workerId a konverzional is.
      { name: 'approver_worker_id', type: 'INTEGER' },
      { name: 'approval_session_id', type: 'TEXT' },
      { name: 'customer_on_own_behalf', type: 'INTEGER' },
      { name: 'customer_actor_name', type: 'TEXT' },
      { name: 'customer_pep_kind', type: 'TEXT' },
      { name: 'customer_actor_birth_place', type: 'TEXT' },
      { name: 'customer_actor_birth_date', type: 'TEXT' },
      { name: 'customer_actor_mother_name', type: 'TEXT' },
      { name: 'customer_actor_nationality', type: 'TEXT' },
      { name: 'customer_actor_document_type', type: 'TEXT' },
      { name: 'customer_actor_document_number', type: 'TEXT' },
      { name: 'customer_actor_address', type: 'TEXT' },
      // HIBA 2026-05-26 (#2): ugyfel deviza-statusza (DOMESTIC/FOREIGN) a konverzioban is.
      { name: 'foreign_status', type: 'TEXT' },
    ];
    for (const col of conversionSnapshotColumns) {
      try {
        db.run(`ALTER TABLE pending_conversions ADD COLUMN ${col.name} ${col.type};`);
      } catch {
        // Column already exists — expected on fresh installs or repeat migration
      }
    }

    db.run(`
      CREATE TABLE IF NOT EXISTS pending_bank_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_type TEXT NOT NULL CHECK(transaction_type IN ('BUY', 'SELL')),
        currency_code TEXT NOT NULL,
        amount REAL NOT NULL,
        exchange_rate REAL NOT NULL,
        huf_amount REAL NOT NULL,
        vault_territory_id INTEGER,
        bank_name TEXT,
        bank_reference TEXT,
        note TEXT,
        local_reference_number TEXT,
        idempotency_key TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0
      );
    `);

    db.run(`
      CREATE TABLE IF NOT EXISTS pending_stornos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        original_receipt_number TEXT NOT NULL,
        original_transaction_type TEXT NOT NULL,
        currency_code TEXT NOT NULL,
        foreign_amount REAL,
        huf_amount REAL NOT NULL,
        exchange_rate REAL,
        reason TEXT NOT NULL,
        approval_id TEXT,
        custom_exchange_rate REAL,
        payment_method TEXT,
        customer_name TEXT,
        customer_document_number TEXT,
        local_reference_number TEXT,
        idempotency_key TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0
      );
    `);

    db.run(`
      CREATE TABLE IF NOT EXISTS pending_handover_operations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_type TEXT NOT NULL CHECK(operation_type IN ('GENERATE', 'PRINT', 'COMPLETE')),
        sheet_id TEXT,
        from_cash_desk_id TEXT,
        to_cash_desk_id TEXT,
        transfer_date TEXT,
        amounts_json TEXT,
        note TEXT,
        local_reference_number TEXT,
        idempotency_key TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0
      );
    `);

    db.run(`
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

    // Migrate: add idempotency_key column for existing installations
    try {
      db.run('ALTER TABLE pending_transactions ADD COLUMN idempotency_key TEXT');
    } catch {
      // Column already exists — ignore
    }

    const pendingTxColumns = [
      'handling_fee REAL',
      'discount_percent REAL',
      'customer_identifier TEXT',
      'customer_name TEXT',
      'customer_document_number TEXT',
      'customer_address TEXT',
      'local_reference_number TEXT',
      // FK-SYNC (2026-06-02): a sync-hiba TARTÓS tárolása (eddig csak in-memory abandoned-set +
      // log). Így a "Függőben" ragadt tranzakciónál a felhasználó LÁTJA, miért nem ment fel
      // (rate mismatch, AML, insufficient balance stb.), és a tétel nem tűnik el némán.
      'sync_error TEXT',
      'sync_attempts INTEGER DEFAULT 0',
      'last_attempt_at TEXT',
    ];
    for (const colDef of pendingTxColumns) {
      try {
        db.run(`ALTER TABLE pending_transactions ADD COLUMN ${colDef}`);
      } catch {
        // Column already exists — ignore
      }
    }

    // FK-071 FR-5: sync-kísérlet-történet — BELSŐ diagnosztikai napló (nem UI-adat).
    // Minden feltöltési kísérlet (automatikus és kézi újraküldés) egy sora:
    // időbélyeg + eredmény (SUCCESS/ERROR) + hibaüzenet. IF NOT EXISTS → meglévő
    // telepítéseken is migráció nélkül létrejön.
    db.run(`
      CREATE TABLE IF NOT EXISTS pending_transaction_sync_attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pending_transaction_id INTEGER NOT NULL,
        attempted_at TEXT NOT NULL,
        outcome TEXT NOT NULL CHECK(outcome IN ('SUCCESS', 'ERROR')),
        message TEXT
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

    // Értéktár offline mód — pending_transfers
    db.run(`
      CREATE TABLE IF NOT EXISTS pending_transfers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        target_branch_id TEXT,
        target_branch_code TEXT NOT NULL,
        currency_id INTEGER,
        currency_code TEXT NOT NULL,
        amount REAL NOT NULL,
        huf_value REAL,
        transfer_type TEXT,
        denominations TEXT,
        note TEXT,
        carrier_name TEXT,
        seal_number TEXT,
        direction TEXT,
        lines TEXT,
        local_reference_number TEXT,
        idempotency_key TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0
      );
    `);

    // Értéktár offline mód — átadás-átvétel bizonylat SZTORNÓ (internetkimaradáskor is).
    // A backend (POST /transfers/{id}/storno) fordítja vissza a készletet szinkronkor.
    db.run(`
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

    // FKH-018: offline Shipment-átvételi szándék. A készlet csak a backend nyugtája után változik.
    db.run(`
      CREATE TABLE IF NOT EXISTS pending_shipment_receipts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shipment_id TEXT NOT NULL,
        request_number TEXT,
        idempotency_key TEXT NOT NULL UNIQUE,
        branch_id TEXT NOT NULL,
        worker_id INTEGER NOT NULL,
        company_code TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        synced INTEGER NOT NULL DEFAULT 0,
        sync_attempts INTEGER NOT NULL DEFAULT 0,
        sync_error TEXT,
        confirmed_stale INTEGER NOT NULL DEFAULT 0
      );
    `);
    addColumnIfMissing(
      db,
      'pending_shipment_receipts',
      'confirmed_stale',
      'INTEGER NOT NULL DEFAULT 0',
    );
    db.run(`
      CREATE UNIQUE INDEX IF NOT EXISTS idx_pending_shipment_receipt_open
      ON pending_shipment_receipts (shipment_id) WHERE synced = 0;
    `);

    // FS-C: körlevél-válasz outbox (offline is rögzíthető, sync-engine küldi fel).
    db.run(`
      CREATE TABLE IF NOT EXISTS pending_circular_replies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        circular_id INTEGER NOT NULL,
        reply_text TEXT NOT NULL,
        idempotency_key TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0
      );
    `);

    // FS-5: okmány-képpár feltöltési outbox (scan a pénztáron → center, törlés nyugtázás után).
    db.run(`
      CREATE TABLE IF NOT EXISTS pending_scanned_documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        document_type TEXT NOT NULL,
        front_path TEXT NOT NULL,
        back_path TEXT NOT NULL,
        notes TEXT,
        idempotency_key TEXT,
        company_code TEXT,
        sync_error TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0
      );
    `);

    // NGM 23/2014 szigoru szamadasu helyi bizonylat-sorszamozo
    // Formatum: {prefix}{branchCode3}{seq6} (pl. V039000042)
    // Per-branch + per-prefix, folyamatos sorszam az elso indulas ota.
    db.run(`
      CREATE TABLE IF NOT EXISTS local_receipt_sequence (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        branch_code TEXT NOT NULL,
        prefix TEXT NOT NULL,
        last_seq INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT DEFAULT (datetime('now')),
        UNIQUE (branch_code, prefix)
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
        local_reference_number TEXT,
        idempotency_key TEXT,
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

    db.run(`
      CREATE TABLE IF NOT EXISTS cached_cash_desks (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        company_id TEXT,
        city TEXT,
        address TEXT,
        zip_code TEXT,
        phone TEXT,
        is_active INTEGER DEFAULT 1,
        cached_at TEXT DEFAULT (datetime('now'))
      );
    `);

    // Migrate (fejléc-javítás 2026-06-11, NFR-1 offline): cím/IRSZ/telefon a branch mirrorban,
    // hogy az átadás-átvételi bizonylat fejléce offline is a branch-törzs adatait mutassa.
    // + region_code (bizonylat-doc 2. kör TBD-5, 2026-06-12): az értéktár "[azonosító]. [név]"
    // fejléc-formátumához offline is.
    for (const col of ['address', 'zip_code', 'phone', 'region_code']) {
      try {
        db.run(`ALTER TABLE cached_cash_desks ADD COLUMN ${col} TEXT`);
      } catch {
        // Column already exists — ignore
      }
    }

    // FK-097 WU-12 (FR-1): a kezelési díj konfiguráció offline tükre — a szinkron
    // (syncHandlingFeeConfig) írja, a renderer cache-first olvasása (IPC) fogyasztja.
    db.run(`
      CREATE TABLE IF NOT EXISTS cached_handling_fee_config (
        branch_id TEXT PRIMARY KEY,
        branch_code TEXT,
        company_id TEXT,
        fee_mode TEXT NOT NULL,
        per_mille_rate REAL,
        per_mille_cap REAL,
        bracket_json TEXT,
        valid_from TEXT,
        synced_at TEXT DEFAULT (datetime('now'))
      );
    `);

    // Migrate (FK-097): a később hozzáadott oszlopok meglévő telepítéseken is
    // megjelennek — a védekező ALTER-minta (cached_rates/cached_cash_desks paritás).
    for (const col of ['branch_code', 'company_id', 'bracket_json', 'valid_from']) {
      try {
        db.run(`ALTER TABLE cached_handling_fee_config ADD COLUMN ${col} TEXT`);
      } catch {
        // Column already exists — ignore
      }
    }

    db.run(`
      CREATE TABLE IF NOT EXISTS cached_workers (
        id INTEGER PRIMARY KEY,
        worker_code TEXT,
        full_name TEXT NOT NULL,
        role TEXT,
        branch_id TEXT,
        branch_code TEXT,
        branch_name TEXT,
        company_id TEXT,
        company_code TEXT,
        active INTEGER DEFAULT 1,
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
        local_reference_number TEXT,
        idempotency_key TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0
      );
    `);

    // Sprint 7.1: pending_stocktake_items - offline leltar felvetel queue
    db.run(`
      CREATE TABLE IF NOT EXISTS pending_stocktake_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id TEXT NOT NULL,
        actual_quantity INTEGER NOT NULL,
        note TEXT,
        idempotency_key TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0,
        sync_error TEXT,
        retry_count INTEGER DEFAULT 0
      );
    `);
    db.run(
      `CREATE INDEX IF NOT EXISTS idx_pending_stocktake_synced ON pending_stocktake_items(synced);`,
    );

    ensureOutboxCompanyColumns(db, getConfig('bootstrap_company_code'));

    const pendingTransferColumns = [
      'target_branch_id TEXT',
      'currency_id INTEGER',
      'huf_value REAL',
      'transfer_type TEXT',
      'carrier_name TEXT',
      'seal_number TEXT',
      'direction TEXT',
      'lines TEXT',
      'local_reference_number TEXT',
      'idempotency_key TEXT',
    ];
    for (const colDef of pendingTransferColumns) {
      try {
        db.run(`ALTER TABLE pending_transfers ADD COLUMN ${colDef}`);
      } catch {
        // Column already exists — ignore
      }
    }

    const pendingDistributionColumns = ['local_reference_number TEXT', 'idempotency_key TEXT'];
    for (const colDef of pendingDistributionColumns) {
      try {
        db.run(`ALTER TABLE pending_distributions ADD COLUMN ${colDef}`);
      } catch {
        // Column already exists — ignore
      }
    }

    const pendingCollectionColumns = ['local_reference_number TEXT', 'idempotency_key TEXT'];
    for (const colDef of pendingCollectionColumns) {
      try {
        db.run(`ALTER TABLE pending_collections ADD COLUMN ${colDef}`);
      } catch {
        // Column already exists — ignore
      }
    }

    const pendingStornoColumns = [
      'approval_id TEXT',
      'custom_exchange_rate REAL',
      'payment_method TEXT',
      'customer_name TEXT',
      'customer_document_number TEXT',
      'local_reference_number TEXT',
      'idempotency_key TEXT',
    ];
    for (const colDef of pendingStornoColumns) {
      try {
        db.run(`ALTER TABLE pending_stornos ADD COLUMN ${colDef}`);
      } catch {
        // Column already exists — ignore
      }
    }

    const pendingHandoverColumns = [
      'sheet_id TEXT',
      'from_cash_desk_id TEXT',
      'to_cash_desk_id TEXT',
      'transfer_date TEXT',
      'amounts_json TEXT',
      'note TEXT',
      'local_reference_number TEXT',
      'idempotency_key TEXT',
    ];
    for (const colDef of pendingHandoverColumns) {
      try {
        db.run(`ALTER TABLE pending_handover_operations ADD COLUMN ${colDef}`);
      } catch {
        // Column already exists — ignore
      }
    }

    cleanupLocalAuditEvents();

    saveDatabase();
  } catch (err) {
    const error = err as NodeJS.ErrnoException | Error;
    const errorCode = 'code' in error && error.code ? String(error.code) : 'unknown';
    const errorMessage = error instanceof Error ? error.message : String(error);
    const wasmPath = (() => {
      try {
        return resolveWasmPath();
      } catch (resolveErr) {
        const resolveMessage =
          resolveErr instanceof Error ? resolveErr.message : String(resolveErr);
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

function computeRetentionUntil(days: number = 31): string {
  const retentionDate = new Date();
  retentionDate.setDate(retentionDate.getDate() + days);
  return retentionDate.toISOString();
}

function generateLocalReference(prefix: string): string {
  const stamp = new Date().toISOString().replace(/\D/g, '').slice(0, 14);
  const suffix = crypto.randomBytes(2).toString('hex').toUpperCase();
  return `${prefix}-${stamp}-${suffix}`;
}

/**
 * NGM 23/2014 szigoru szamadasu helyi bizonylat-sorszamozo.
 * Formatum: {prefix}{branchCode3}{seq6} pl. V039000042
 * Per-branch + per-prefix folyamatos seq (nincs hezag/duplikacio).
 *
 * @param prefix V (vetel), E (eladas), K (konverzio), F (kimeno), U (bejovo), stb.
 * @param branchCode pl. BR039 -> "039"
 */
export function generateStrictReceiptNumber(prefix: string, branchCode: string): string {
  if (!db) throw new Error('Database not initialized');
  const normBranch = branchCode.replace(/^BR/i, '').padStart(3, '0').slice(-3);

  // UPSERT: ha nincs, hozz letre; ha van, inkrement
  db.run(
    `INSERT INTO local_receipt_sequence (branch_code, prefix, last_seq, updated_at)
     VALUES (?, ?, 1, datetime('now'))
     ON CONFLICT(branch_code, prefix) DO UPDATE SET
       last_seq = last_seq + 1,
       updated_at = datetime('now')`,
    [normBranch, prefix],
  );
  const stmt = db.prepare(
    'SELECT last_seq FROM local_receipt_sequence WHERE branch_code = ? AND prefix = ?',
  );
  stmt.bind([normBranch, prefix]);
  stmt.step();
  const row = stmt.getAsObject();
  stmt.free();
  const seq = Number(row['last_seq'] ?? 1);
  // NGM 23/2014: NINCS kulon save itt - a savePendingTransaction/Conversion atomi save-el egyszerre
  return `${prefix}${normBranch}${String(seq).padStart(6, '0')}`;
}

function toJsonOrNull(value: unknown): string | null {
  if (value === null || value === undefined) {
    return null;
  }

  return JSON.stringify(value);
}

export interface LocalAuditEventRow {
  id: number;
  entity_type: string;
  event_type: string;
  reference_number: string | null;
  entity_id: string | null;
  payload_json: string;
  customer_snapshot_json: string | null;
  identification_snapshot_json: string | null;
  rate_snapshot_json: string | null;
  status: string;
  retention_until: string;
  created_at: string;
}

export function saveLocalAuditEvent(params: {
  entityType: string;
  eventType: string;
  referenceNumber?: string | null;
  entityId?: string | null;
  payload: unknown;
  customerSnapshot?: unknown;
  identificationSnapshot?: unknown;
  rateSnapshot?: unknown;
  status?: string;
  retentionDays?: number;
}): number {
  if (!db) throw new Error('Database not initialized');

  db.run(
    `INSERT INTO local_audit_events (
      entity_type,
      event_type,
      reference_number,
      entity_id,
      payload_json,
      customer_snapshot_json,
      identification_snapshot_json,
      rate_snapshot_json,
      status,
      retention_until
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      params.entityType,
      params.eventType,
      params.referenceNumber ?? null,
      params.entityId ?? null,
      JSON.stringify(params.payload),
      toJsonOrNull(params.customerSnapshot),
      toJsonOrNull(params.identificationSnapshot),
      toJsonOrNull(params.rateSnapshot),
      params.status ?? 'LOCAL_RECORDED',
      computeRetentionUntil(params.retentionDays ?? 31),
    ],
  );
  const insertedId = lastInsertRowId(db);
  saveDatabase();
  return insertedId;
}

export function getLocalAuditEvents(limit: number = 200): LocalAuditEventRow[] {
  if (!db) return [];

  const results: LocalAuditEventRow[] = [];
  const stmt = db.prepare('SELECT * FROM local_audit_events ORDER BY created_at DESC LIMIT ?');
  stmt.bind([limit]);
  while (stmt.step()) {
    results.push(stmt.getAsObject() as unknown as LocalAuditEventRow);
  }
  stmt.free();
  return results;
}

// ============ RESTORED TRANSACTIONS (szerver → pénztár visszaállítás) ============

/**
 * Szervérről visszaállított tranzakciók mentése a helyi cache-be.
 * Ez read-only cache — a pénztáros láthatja a történetet, de nem módosíthatja.
 */
export function saveRestoredTransactions(transactions: Array<Record<string, unknown>>): number {
  if (!db || transactions.length === 0) return 0;

  db.run(`
    CREATE TABLE IF NOT EXISTS cached_restored_transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      server_id TEXT,
      type TEXT,
      currency_code TEXT,
      currency_amount REAL,
      huf_amount REAL,
      rate REAL,
      handling_fee REAL,
      transaction_date TEXT,
      receipt_number TEXT,
      status TEXT,
      restored_at TEXT DEFAULT (datetime('now'))
    );
  `);

  let saved = 0;
  for (const tx of transactions) {
    try {
      db.run(
        `INSERT OR IGNORE INTO cached_restored_transactions
         (server_id, type, currency_code, currency_amount, huf_amount, rate, handling_fee, transaction_date, receipt_number, status)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          tx.id != null ? String(tx.id) : null,
          tx.type != null ? String(tx.type) : null,
          tx.currencyCode != null ? String(tx.currencyCode) : null,
          tx.currencyAmount != null ? Number(tx.currencyAmount) : null,
          tx.hufAmount != null ? Number(tx.hufAmount) : null,
          tx.rate != null ? Number(tx.rate) : null,
          tx.handlingFee != null ? Number(tx.handlingFee) : null,
          tx.transactionDate != null ? String(tx.transactionDate) : null,
          tx.receiptNumber != null ? String(tx.receiptNumber) : null,
          tx.status != null ? String(tx.status) : null,
        ],
      );
      saved++;
    } catch {
      // Duplikátum (server_id alapján) vagy egyéb hiba — kihagyjuk
    }
  }

  saveDatabase();
  return saved;
}

export function cleanupLocalAuditEvents(retentionDays: number = 31): void {
  if (!db) return;
  db.run(
    `DELETE FROM local_audit_events
     WHERE datetime(created_at) < datetime('now', ?)`,
    [`-${retentionDays} days`],
  );
}

/**
 * Szinkronizált pending rekordok törlése — 180 napos retenciós politika.
 * CSAK synced=1 rekordokat töröl, amelyek régebbiek mint retentionDays nap.
 * Nem szinkronizált (synced=0) rekordok SOHA nem törlődnek.
 *
 * Zoltán döntés: 180 nap (2026-04-08)
 */
export function cleanupSyncedPendingRecords(retentionDays: number = 180): {
  transactions: number;
  conversions: number;
  bankTransactions: number;
  stornos: number;
  transfers: number;
  distributions: number;
  collections: number;
  handoverOperations: number;
} {
  if (!db)
    return {
      transactions: 0,
      conversions: 0,
      bankTransactions: 0,
      stornos: 0,
      transfers: 0,
      distributions: 0,
      collections: 0,
      handoverOperations: 0,
    };

  const tables = [
    { name: 'pending_transactions', key: 'transactions' },
    { name: 'pending_conversions', key: 'conversions' },
    { name: 'pending_bank_transactions', key: 'bankTransactions' },
    { name: 'pending_stornos', key: 'stornos' },
    { name: 'pending_transfers', key: 'transfers' },
    { name: 'pending_distributions', key: 'distributions' },
    { name: 'pending_collections', key: 'collections' },
    { name: 'pending_handover_operations', key: 'handoverOperations' },
  ] as const;

  const result: Record<string, number> = {};

  for (const t of tables) {
    try {
      db.run(
        `DELETE FROM ${t.name}
         WHERE synced = 1
         AND datetime(created_at) < datetime('now', ?)`,
        [`-${retentionDays} days`],
      );
      // sql.js doesn't have changes() easily, count separately
      const countStmt = db.prepare(`SELECT COUNT(*) as cnt FROM ${t.name} WHERE synced = 1`);
      countStmt.step();
      countStmt.free();
      result[t.key] = 0; // We don't know exact deleted count with sql.js
    } catch {
      result[t.key] = 0;
    }
  }

  saveDatabase();
  return result as ReturnType<typeof cleanupSyncedPendingRecords>;
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

function getActiveCompanyCode(): string | null {
  return getConfig('bootstrap_company_code')?.trim() || null;
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
  handling_fee: number | null;
  discount_percent: number | null;
  customer_id: string | number | null;
  customer_identifier: string | null;
  customer_name: string | null;
  customer_document_number: string | null;
  customer_address: string | null;
  denominations: string | null;
  source_of_funds: string | null;
  customer_is_pep: number | null;
  /** AML vezetoi jovahagyas (2026-06-04): jovahagyo workerId, NULL ha nem kellett. */
  approver_worker_id: number | null;
  approval_session_id: string | null;
  /** V226 (2026-05-14): per-line devizastatusz — 'DOMESTIC' / 'FOREIGN' / null. */
  foreign_status: string | null;
  // V229 + V235 (2026-05-19 HIBA #14 + #17 + #18): teljes Pmt. customer-snapshot
  customer_birth_place: string | null;
  customer_birth_date: string | null;
  customer_mother_name: string | null;
  customer_nationality: string | null;
  customer_document_type: string | null;
  customer_on_own_behalf: number | null;
  customer_actor_name: string | null;
  customer_pep_kind: string | null;
  customer_actor_birth_place: string | null;
  customer_actor_birth_date: string | null;
  customer_actor_mother_name: string | null;
  customer_actor_nationality: string | null;
  customer_actor_document_type: string | null;
  customer_actor_document_number: string | null;
  customer_actor_address: string | null;
  /**
   * Multi-line aggregate (2026-06-04): tobb-soros nyugta sorai JSON-kent
   * (backend TransactionLineRequestDto alak). NULL → egysoros (valtozatlan).
   */
  lines: string | null;
  // FK-KEZDIJ offline (2026-06-12, penztar-batch B.1/b): kezelesi dij override mezok —
  // eddig az Electron uton CSENDBEN elvesztek (a szerver a teljes alap-dijat konyvelte).
  handling_fee_override_type?: string | null;
  handling_fee_override_reason?: string | null;
  customer_card_number?: string | null;
  // V325 (Batch3-C): jogi szemely + tenyleges tulajdonosok (JSON, max 4).
  is_legal_entity_customer?: number | null;
  legal_entity_name?: string | null;
  legal_entity_seat?: string | null;
  legal_entity_tax_number?: string | null;
  legal_deed_number?: string | null;
  beneficial_owners_json?: string | null;
  local_reference_number: string | null;
  idempotency_key: string | null;
  company_code?: string | null;
  created_at: string;
  synced: number;
  // FK-SYNC (2026-06-02): a legutóbbi sync-hiba (miért nem ment fel a tétel), próbálkozások száma,
  // utolsó próbálkozás ideje. A UI ezt jeleníti meg a "Függőben" tételeknél.
  sync_error?: string | null;
  sync_attempts?: number | null;
  last_attempt_at?: string | null;
}

export interface PendingConversionRow {
  id: number;
  from_currency_id: number | null;
  from_currency_code: string;
  to_currency_id: number | null;
  to_currency_code: string;
  from_amount: number;
  calculated_huf_amount: number;
  calculated_to_amount: number;
  conversion_rate: number;
  handling_fee: number | null;
  customer_id: string | null;
  customer_name: string | null;
  customer_document_number: string | null;
  // V235 + V236 (2026-05-19 Codex P1 #695): teljes Pmt. customer-snapshot
  customer_address: string | null;
  customer_nationality: string | null;
  customer_birth_place: string | null;
  customer_birth_date: string | null;
  customer_mother_name: string | null;
  customer_document_type: string | null;
  source_of_funds: string | null;
  customer_is_pep: number | null;
  approver_worker_id: number | null;
  approval_session_id: string | null;
  customer_on_own_behalf: number | null;
  customer_actor_name: string | null;
  customer_pep_kind: string | null;
  customer_actor_birth_place: string | null;
  customer_actor_birth_date: string | null;
  customer_actor_mother_name: string | null;
  customer_actor_nationality: string | null;
  customer_actor_document_type: string | null;
  customer_actor_document_number: string | null;
  customer_actor_address: string | null;
  // HIBA 2026-05-26 (#2): ugyfel deviza-statusza
  foreign_status: string | null;
  note: string | null;
  local_reference_number: string | null;
  idempotency_key: string | null;
  company_code?: string | null;
  created_at: string;
  synced: number;
}

export interface PendingBankTransactionRow {
  id: number;
  transaction_type: 'BUY' | 'SELL';
  currency_code: string;
  amount: number;
  exchange_rate: number;
  huf_amount: number;
  vault_territory_id: number | null;
  bank_name: string | null;
  bank_reference: string | null;
  note: string | null;
  local_reference_number: string | null;
  idempotency_key: string | null;
  company_code?: string | null;
  created_at: string;
  synced: number;
}

export interface PendingStornoRow {
  id: number;
  transaction_id: number;
  original_receipt_number: string;
  original_transaction_type: string;
  currency_code: string;
  foreign_amount: number | null;
  huf_amount: number;
  exchange_rate: number | null;
  reason: string;
  approval_id: string | null;
  custom_exchange_rate: number | null;
  payment_method: string | null;
  customer_name: string | null;
  customer_document_number: string | null;
  local_reference_number: string | null;
  idempotency_key: string | null;
  company_code?: string | null;
  created_at: string;
  synced: number;
}

export interface PendingHandoverOperationRow {
  id: number;
  operation_type: 'GENERATE' | 'PRINT' | 'COMPLETE';
  sheet_id: string | null;
  from_cash_desk_id: string | null;
  to_cash_desk_id: string | null;
  transfer_date: string | null;
  amounts_json: string | null;
  note: string | null;
  local_reference_number: string | null;
  idempotency_key: string | null;
  company_code?: string | null;
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
  handlingFee: number | null,
  discountPercent: number | null,
  customerIdentifier: string | null,
  customerName: string | null,
  customerDocumentNumber: string | null,
  customerAddress: string | null,
  denominations: string | null,
  sourceOfFunds: string | null = null,
  customerIsPep: boolean | null = null,
  foreignStatus: 'DOMESTIC' | 'FOREIGN' | null = null,
  approverWorkerId: number | null = null,
  approvalSessionId: string | null = null,
): number {
  if (!db) throw new Error('Database not initialized');

  // Stabil idempotency key — retry-nál is ugyanazt küldjük a szervernek
  const idempotencyKey = crypto.randomUUID();
  // NGM-kompatibilis helyi bizonylatszam: V (vetel) / E (eladas) prefix + branchCode3 + seq6
  const branchCodeForReceipt = getConfig('branch_code');
  if (!branchCodeForReceipt) {
    throw new Error(
      'SetupWizard nem futott le: branch_code SQLite config hianyzik. Ujra-telepites szukseges.',
    );
  }
  const roundFin = (v: number, decimals: number): number => Number(v.toFixed(decimals));
  const roundFinOrNull = (v: number | null, decimals: number): number | null =>
    v === null ? null : roundFin(v, decimals);
  const normalizedCustomerIdentifier = customerIdentifier?.trim() || null;
  const normalizedCustomerName = customerName?.trim() || null;
  const normalizedCustomerDocumentNumber = customerDocumentNumber?.trim() || null;
  const normalizedCustomerAddress = customerAddress?.trim() || null;
  const normalizedSourceOfFunds = sourceOfFunds?.trim() || null;

  // NGM 23/2014 atomicitás: a sorszám-inkrement ÉS a sor INSERT egy tranzakcióban,
  // hogy egy INSERT-hiba ROLLBACK-elje a sorszám-előléptetést is (nincs hézag).
  const { ref: localReferenceNumber, id: insertedId } = withTransaction(() => {
    const ref = generateStrictReceiptNumber(type === 'BUY' ? 'V' : 'E', branchCodeForReceipt);
    db!.run(
      `INSERT INTO pending_transactions (
        type,
        currency_code,
        foreign_amount,
        huf_amount,
        rounded_huf_amount,
        rate,
        handling_fee,
        discount_percent,
        customer_id,
        customer_identifier,
        customer_name,
        customer_document_number,
        customer_address,
        denominations,
        source_of_funds,
        customer_is_pep,
        approver_worker_id,
        approval_session_id,
        foreign_status,
        local_reference_number,
        idempotency_key,
        company_code
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        type,
        currencyCode,
        roundFin(foreignAmount, 8),
        roundFin(hufAmount, 2),
        roundFin(roundedHufAmount, 0),
        roundFin(rate, 10),
        roundFinOrNull(handlingFee, 0),
        roundFinOrNull(discountPercent, 4),
        null,
        normalizedCustomerIdentifier,
        normalizedCustomerName,
        normalizedCustomerDocumentNumber,
        normalizedCustomerAddress,
        denominations,
        normalizedSourceOfFunds,
        customerIsPep === null ? null : customerIsPep ? 1 : 0,
        approverWorkerId ?? null,
        approvalSessionId ?? null,
        foreignStatus,
        ref,
        idempotencyKey,
        getActiveCompanyCode(),
      ],
    );
    return { ref, id: lastInsertRowId(db!) };
  });
  saveDatabase();

  saveLocalAuditEvent({
    entityType: 'TRANSACTION',
    eventType: type,
    referenceNumber: localReferenceNumber,
    entityId: String(insertedId),
    payload: {
      type,
      currencyCode,
      foreignAmount,
      hufAmount,
      roundedHufAmount,
      rate,
      handlingFee,
      discountPercent,
      denominations,
      idempotencyKey,
    },
    customerSnapshot: {
      customerIdentifier: normalizedCustomerIdentifier,
      customerName: normalizedCustomerName,
      customerDocumentNumber: normalizedCustomerDocumentNumber,
      customerAddress: normalizedCustomerAddress,
    },
    identificationSnapshot: {
      customerIdentifier: normalizedCustomerIdentifier,
      customerDocumentNumber: normalizedCustomerDocumentNumber,
    },
    rateSnapshot: {
      currencyCode,
      rate,
      roundedHufAmount,
    },
    status: 'PENDING_UPLOAD',
  });

  return insertedId;
}

/**
 * V235 (2026-05-19 HIBA #14 + #15 + #17 + #18): bővített pending tranzakció
 * mentés. A teljes Pmt. customer-snapshot (szül.hely, szül.idő, anyja neve,
 * állampolgárság, okmány típus, PEP minőség, "más nevében" flag + actor teljes
 * azonosítása) bekerül a kliens-oldali outbox-ba, így a későbbi sync teljes
 * adatcsomagot tud felküldeni a backend felé.
 *
 * Az eredeti pozicionális-paraméterű {@link savePendingTransaction} megmarad
 * backward compat miatt (dist-bundle, tesztek). Új helyek a V2-t használják.
 */
export function savePendingTransactionV2(input: PendingTransactionInputV2): number {
  if (!db) throw new Error('Database not initialized');

  const idempotencyKey = crypto.randomUUID();
  const branchCodeForReceipt = getConfig('branch_code');
  if (!branchCodeForReceipt) {
    throw new Error(
      'SetupWizard nem futott le: branch_code SQLite config hianyzik. Ujra-telepites szukseges.',
    );
  }
  const trimOrNull = (v: string | null | undefined): string | null => {
    const t = v?.trim();
    return t && t.length > 0 ? t : null;
  };
  const boolToInt = (v: boolean | null | undefined): number | null =>
    v === null || v === undefined ? null : v ? 1 : 0;
  // PP-09: tárolás előtt kerekítés a megadott tizedesjegyre, floating-point noise levágása.
  // Pl. 0.30000000000000004 → roundFin(v,2) → 0.3; 1250.0000000002 → roundFin(v,0) → 1250.
  // Cél: determinisztikus DB-tartalom, nem a teljes IEEE 754 pontosság megőrzése.
  const roundFin = (v: number, decimals: number): number => Number(v.toFixed(decimals));
  const roundFinOrNull = (v: number | null, decimals: number): number | null =>
    v === null ? null : roundFin(v, decimals);

  const normalized = {
    customerIdentifier: trimOrNull(input.customerIdentifier),
    customerName: trimOrNull(input.customerName),
    customerDocumentNumber: trimOrNull(input.customerDocumentNumber),
    customerAddress: trimOrNull(input.customerAddress),
    sourceOfFunds: trimOrNull(input.sourceOfFunds),
    customerBirthPlace: trimOrNull(input.customerBirthPlace),
    customerBirthDate: trimOrNull(input.customerBirthDate),
    customerMotherName: trimOrNull(input.customerMotherName),
    customerNationality: trimOrNull(input.customerNationality),
    customerDocumentType: trimOrNull(input.customerDocumentType),
    customerActorName: trimOrNull(input.customerActorName),
    customerPepKind: trimOrNull(input.customerPepKind),
    customerActorBirthPlace: trimOrNull(input.customerActorBirthPlace),
    customerActorBirthDate: trimOrNull(input.customerActorBirthDate),
    customerActorMotherName: trimOrNull(input.customerActorMotherName),
    customerActorNationality: trimOrNull(input.customerActorNationality),
    customerActorDocumentType: trimOrNull(input.customerActorDocumentType),
    customerActorDocumentNumber: trimOrNull(input.customerActorDocumentNumber),
    customerActorAddress: trimOrNull(input.customerActorAddress),
  };

  // NGM 23/2014 atomicitás: sorszám-inkrement + sor INSERT egy tranzakcióban.
  const { ref: localReferenceNumber, id: insertedId } = withTransaction(() => {
    const ref = generateStrictReceiptNumber(input.type === 'BUY' ? 'V' : 'E', branchCodeForReceipt);
    db!.run(
      `INSERT INTO pending_transactions (
        type, currency_code, foreign_amount, huf_amount, rounded_huf_amount, rate,
        handling_fee, discount_percent,
        customer_id, customer_identifier, customer_name, customer_document_number, customer_address,
        denominations,
        source_of_funds, customer_is_pep, approver_worker_id, approval_session_id, foreign_status,
        customer_birth_place, customer_birth_date, customer_mother_name,
        customer_nationality, customer_document_type,
        customer_on_own_behalf, customer_actor_name,
        customer_pep_kind,
        customer_actor_birth_place, customer_actor_birth_date, customer_actor_mother_name,
        customer_actor_nationality, customer_actor_document_type,
        customer_actor_document_number, customer_actor_address,
        lines,
        handling_fee_override_type, handling_fee_override_reason, customer_card_number,
        is_legal_entity_customer, legal_entity_name, legal_entity_seat,
        legal_entity_tax_number, legal_deed_number, beneficial_owners_json,
        local_reference_number, idempotency_key, company_code
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        input.type,
        input.currencyCode,
        roundFin(input.foreignAmount, 8),
        roundFin(input.hufAmount, 2),
        roundFin(input.roundedHufAmount, 0),
        roundFin(input.rate, 10),
        roundFinOrNull(input.handlingFee, 0),
        roundFinOrNull(input.discountPercent, 4),
        null, // customer_id (legacy oszlop, ID-t nem kezeljük itt)
        normalized.customerIdentifier,
        normalized.customerName,
        normalized.customerDocumentNumber,
        normalized.customerAddress,
        input.denominations,
        normalized.sourceOfFunds,
        boolToInt(input.customerIsPep),
        input.approverWorkerId ?? null,
        input.approvalSessionId ?? null,
        input.foreignStatus,
        normalized.customerBirthPlace,
        normalized.customerBirthDate,
        normalized.customerMotherName,
        normalized.customerNationality,
        normalized.customerDocumentType,
        boolToInt(input.customerOnOwnBehalf),
        normalized.customerActorName,
        normalized.customerPepKind,
        normalized.customerActorBirthPlace,
        normalized.customerActorBirthDate,
        normalized.customerActorMotherName,
        normalized.customerActorNationality,
        normalized.customerActorDocumentType,
        normalized.customerActorDocumentNumber,
        normalized.customerActorAddress,
        input.lines ?? null,
        trimOrNull(input.handlingFeeOverrideType),
        trimOrNull(input.handlingFeeOverrideReason),
        trimOrNull(input.customerCardNumber),
        boolToInt(input.isLegalEntityCustomer),
        trimOrNull(input.legalEntityName),
        trimOrNull(input.legalEntitySeat),
        trimOrNull(input.legalEntityTaxNumber),
        trimOrNull(input.legalDeedNumber),
        input.beneficialOwnersJson ?? null,
        ref,
        idempotencyKey,
        getActiveCompanyCode(),
      ],
    );
    return { ref, id: lastInsertRowId(db!) };
  });
  saveDatabase();

  saveLocalAuditEvent({
    entityType: 'TRANSACTION',
    eventType: input.type,
    referenceNumber: localReferenceNumber,
    entityId: String(insertedId),
    payload: {
      type: input.type,
      currencyCode: input.currencyCode,
      foreignAmount: roundFin(input.foreignAmount, 8),
      hufAmount: roundFin(input.hufAmount, 2),
      roundedHufAmount: roundFin(input.roundedHufAmount, 0),
      rate: roundFin(input.rate, 10),
      handlingFee: roundFinOrNull(input.handlingFee, 0),
      discountPercent: roundFinOrNull(input.discountPercent, 4),
      denominations: input.denominations,
      idempotencyKey,
    },
    customerSnapshot: {
      customerIdentifier: normalized.customerIdentifier,
      customerName: normalized.customerName,
      customerDocumentNumber: normalized.customerDocumentNumber,
      customerAddress: normalized.customerAddress,
      customerBirthPlace: normalized.customerBirthPlace,
      customerBirthDate: normalized.customerBirthDate,
      customerMotherName: normalized.customerMotherName,
      customerNationality: normalized.customerNationality,
      customerDocumentType: normalized.customerDocumentType,
      customerIsPep: input.customerIsPep,
      customerPepKind: normalized.customerPepKind,
      customerOnOwnBehalf: input.customerOnOwnBehalf,
      customerActorName: normalized.customerActorName,
      actorIdentity:
        input.customerOnOwnBehalf === false
          ? {
              birthPlace: normalized.customerActorBirthPlace,
              birthDate: normalized.customerActorBirthDate,
              motherName: normalized.customerActorMotherName,
              nationality: normalized.customerActorNationality,
              documentType: normalized.customerActorDocumentType,
              documentNumber: normalized.customerActorDocumentNumber,
              address: normalized.customerActorAddress,
            }
          : null,
    },
    identificationSnapshot: {
      customerIdentifier: normalized.customerIdentifier,
      customerDocumentNumber: normalized.customerDocumentNumber,
    },
    rateSnapshot: {
      currencyCode: input.currencyCode,
      rate: input.rate,
      roundedHufAmount: input.roundedHufAmount,
    },
    status: 'PENDING_UPLOAD',
  });

  return insertedId;
}

export function getPendingTransactions(): PendingTransactionRow[] {
  if (!db) return [];

  const results: PendingTransactionRow[] = [];
  const stmt = db.prepare(
    'SELECT * FROM pending_transactions WHERE synced = 0 ORDER BY created_at ASC',
  );
  while (stmt.step()) {
    const row = stmt.getAsObject() as unknown as PendingTransactionRow;
    results.push(row);
  }
  stmt.free();
  return results;
}

/**
 * Egy mentett vétel/eladás pending-sor szigorú helyi sorszámának (local_reference_number)
 * lekérdezése ID alapján.
 *
 * 2026-06-04 (audit-fix): a nyugta-nyomtatás a TÉNYLEGES, rögzített szigorú sorszámot
 * kell hogy a bizonylatra bélyegezze — nem fabrikált `P-<timestamp>`-et. A
 * `savePendingTransactionV2` csak a beszúrt sor ID-jét adja vissza; ez a kis lekérdezés
 * a hozzá tartozó helyi sorszámot adja vissza. SZÁNDÉKOSAN NEM szűr `synced = 0`-ra,
 * így a sorszám akkor is lekérdezhető, ha a sor azonnal felszinkronizálódott (synced=1).
 */
export function getPendingTransactionRefById(id: number): string | null {
  if (!db) return null;
  const stmt = db.prepare('SELECT local_reference_number FROM pending_transactions WHERE id = ?');
  stmt.bind([id]);
  let ref: string | null = null;
  if (stmt.step()) {
    const row = stmt.getAsObject() as { local_reference_number?: string | null };
    ref = row.local_reference_number ?? null;
  }
  stmt.free();
  return ref;
}

/**
 * Egy mentett átadás/átvétel (transfer) pending-sor szigorú átadólap-sorszámának
 * (local_reference_number, pl. AT105000042) lekérdezése ID alapján.
 *
 * 2026-06-04 (audit-fix, buy/sell-paritás): a szállítólevél-nyomtatás a TÉNYLEGES,
 * rögzített átadólap-számot kell hogy a bizonylatra bélyegezze — nem fabrikált
 * `LOCAL-<dátum>-#<id>`-t. A `savePendingTransfer` csak a beszúrt sor ID-jét adja
 * vissza; ez a kis lekérdezés a hozzá tartozó helyi sorszámot adja vissza.
 * SZÁNDÉKOSAN NEM szűr `synced = 0`-ra, így a sorszám akkor is lekérdezhető, ha a
 * sor azonnal felszinkronizálódott (synced=1).
 */
export function getPendingTransferRefById(id: number): string | null {
  if (!db) return null;
  const stmt = db.prepare('SELECT local_reference_number FROM pending_transfers WHERE id = ?');
  stmt.bind([id]);
  let ref: string | null = null;
  if (stmt.step()) {
    const row = stmt.getAsObject() as { local_reference_number?: string | null };
    ref = row.local_reference_number ?? null;
  }
  stmt.free();
  return ref;
}

export function savePendingConversion(
  fromCurrencyId: number | null,
  fromCurrencyCode: string,
  toCurrencyId: number | null,
  toCurrencyCode: string,
  fromAmount: number,
  calculatedHufAmount: number,
  calculatedToAmount: number,
  conversionRate: number,
  handlingFee: number | null,
  customerId: string | null,
  customerName: string | null,
  customerDocumentNumber: string | null,
  note: string | null,
): number {
  if (!db) throw new Error('Database not initialized');

  const idempotencyKey = crypto.randomUUID();
  // NGM-kompatibilis: K (konverzio) prefix
  const branchCodeForReceipt = getConfig('branch_code');
  if (!branchCodeForReceipt) {
    throw new Error(
      'SetupWizard nem futott le: branch_code SQLite config hianyzik. Ujra-telepites szukseges.',
    );
  }
  const roundFin = (v: number, decimals: number): number => Number(v.toFixed(decimals));
  const roundFinOrNull = (v: number | null, decimals: number): number | null =>
    v === null ? null : roundFin(v, decimals);

  // NGM 23/2014 atomicitás: sorszám-inkrement + sor INSERT egy tranzakcióban.
  const { ref: localReferenceNumber, id: insertedId } = withTransaction(() => {
    const ref = generateStrictReceiptNumber('K', branchCodeForReceipt);
    db!.run(
      `INSERT INTO pending_conversions (
        from_currency_id,
        from_currency_code,
        to_currency_id,
        to_currency_code,
        from_amount,
        calculated_huf_amount,
        calculated_to_amount,
        conversion_rate,
        handling_fee,
        customer_id,
        customer_name,
        customer_document_number,
        note,
        local_reference_number,
        idempotency_key,
        company_code
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        fromCurrencyId,
        fromCurrencyCode,
        toCurrencyId,
        toCurrencyCode,
        roundFin(fromAmount, 8),
        roundFin(calculatedHufAmount, 2),
        roundFin(calculatedToAmount, 8),
        roundFin(conversionRate, 10),
        roundFinOrNull(handlingFee, 0),
        customerId?.trim() || null,
        customerName?.trim() || null,
        customerDocumentNumber?.trim() || null,
        note?.trim() || null,
        ref,
        idempotencyKey,
        getActiveCompanyCode(),
      ],
    );
    return { ref, id: lastInsertRowId(db!) };
  });
  saveDatabase();

  saveLocalAuditEvent({
    entityType: 'CONVERSION',
    eventType: 'CREATE',
    referenceNumber: localReferenceNumber,
    entityId: String(insertedId),
    payload: {
      fromCurrencyId,
      fromCurrencyCode,
      toCurrencyId,
      toCurrencyCode,
      fromAmount,
      calculatedHufAmount,
      calculatedToAmount,
      conversionRate,
      handlingFee,
      note: note?.trim() || null,
      idempotencyKey,
    },
    customerSnapshot: {
      customerId: customerId?.trim() || null,
      customerName: customerName?.trim() || null,
      customerDocumentNumber: customerDocumentNumber?.trim() || null,
    },
    identificationSnapshot: {
      customerId: customerId?.trim() || null,
      customerDocumentNumber: customerDocumentNumber?.trim() || null,
    },
    rateSnapshot: {
      fromCurrencyCode,
      toCurrencyCode,
      conversionRate,
      calculatedHufAmount,
      calculatedToAmount,
    },
    status: 'PENDING_UPLOAD',
  });

  return insertedId;
}

/**
 * V235 + V236 (2026-05-19 Codex P1 #695): bővített Konverzio pending-mentés
 * objektum-paraméterrel. A teljes Pmt. customer-snapshot (szül.hely, szül.idő,
 * anyja neve, állampolgárság, okmány típus, PEP minőség, "más nevében" flag
 * + actor teljes azonosítása) bekerül a kliens-oldali outbox-ba.
 */
export function savePendingConversionV2(input: PendingConversionInputV2): number {
  if (!db) throw new Error('Database not initialized');

  const idempotencyKey = crypto.randomUUID();
  const branchCodeForReceipt = getConfig('branch_code');
  if (!branchCodeForReceipt) {
    throw new Error(
      'SetupWizard nem futott le: branch_code SQLite config hianyzik. Ujra-telepites szukseges.',
    );
  }
  const trimOrNull = (v: string | null | undefined): string | null => {
    const t = v?.trim();
    return t && t.length > 0 ? t : null;
  };
  const boolToInt = (v: boolean | null | undefined): number | null =>
    v === null || v === undefined ? null : v ? 1 : 0;
  const roundFin = (v: number, decimals: number): number => Number(v.toFixed(decimals));
  const roundFinOrNull = (v: number | null, decimals: number): number | null =>
    v === null ? null : roundFin(v, decimals);

  // NGM 23/2014 atomicitás: sorszám-inkrement + sor INSERT egy tranzakcióban.
  const { ref: localReferenceNumber, id: insertedId } = withTransaction(() => {
    const ref = generateStrictReceiptNumber('K', branchCodeForReceipt);
    db!.run(
      `INSERT INTO pending_conversions (
        from_currency_id, from_currency_code, to_currency_id, to_currency_code,
        from_amount, calculated_huf_amount, calculated_to_amount, conversion_rate,
        handling_fee,
        customer_id, customer_name, customer_document_number,
        customer_address, customer_nationality, customer_birth_place, customer_birth_date,
        customer_mother_name, customer_document_type,
        source_of_funds, customer_is_pep, approver_worker_id, approval_session_id, customer_on_own_behalf, customer_actor_name,
        customer_pep_kind,
        customer_actor_birth_place, customer_actor_birth_date, customer_actor_mother_name,
        customer_actor_nationality, customer_actor_document_type,
        customer_actor_document_number, customer_actor_address,
        foreign_status,
        note, local_reference_number, idempotency_key, company_code
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        input.fromCurrencyId,
        input.fromCurrencyCode,
        input.toCurrencyId,
        input.toCurrencyCode,
        roundFin(input.fromAmount, 8),
        roundFin(input.calculatedHufAmount, 2),
        roundFin(input.calculatedToAmount, 8),
        roundFin(input.conversionRate, 10),
        roundFinOrNull(input.handlingFee, 0),
        trimOrNull(input.customerId),
        trimOrNull(input.customerName),
        trimOrNull(input.customerDocumentNumber),
        trimOrNull(input.customerAddress),
        trimOrNull(input.customerNationality),
        trimOrNull(input.customerBirthPlace),
        trimOrNull(input.customerBirthDate),
        trimOrNull(input.customerMotherName),
        trimOrNull(input.customerDocumentType),
        trimOrNull(input.sourceOfFunds),
        boolToInt(input.customerIsPep),
        input.approverWorkerId ?? null,
        input.approvalSessionId ?? null,
        boolToInt(input.customerOnOwnBehalf),
        trimOrNull(input.customerActorName),
        trimOrNull(input.customerPepKind),
        trimOrNull(input.customerActorBirthPlace),
        trimOrNull(input.customerActorBirthDate),
        trimOrNull(input.customerActorMotherName),
        trimOrNull(input.customerActorNationality),
        trimOrNull(input.customerActorDocumentType),
        trimOrNull(input.customerActorDocumentNumber),
        trimOrNull(input.customerActorAddress),
        trimOrNull(input.foreignStatus),
        trimOrNull(input.note),
        ref,
        idempotencyKey,
        getActiveCompanyCode(),
      ],
    );
    return { ref, id: lastInsertRowId(db!) };
  });
  saveDatabase();

  saveLocalAuditEvent({
    entityType: 'CONVERSION',
    eventType: 'CREATE',
    referenceNumber: localReferenceNumber,
    entityId: String(insertedId),
    payload: {
      fromCurrencyId: input.fromCurrencyId,
      fromCurrencyCode: input.fromCurrencyCode,
      toCurrencyId: input.toCurrencyId,
      toCurrencyCode: input.toCurrencyCode,
      fromAmount: roundFin(input.fromAmount, 8),
      calculatedHufAmount: roundFin(input.calculatedHufAmount, 2),
      calculatedToAmount: roundFin(input.calculatedToAmount, 8),
      conversionRate: roundFin(input.conversionRate, 10),
      handlingFee: roundFinOrNull(input.handlingFee, 0),
      note: trimOrNull(input.note),
      idempotencyKey,
    },
    customerSnapshot: {
      customerId: trimOrNull(input.customerId),
      customerName: trimOrNull(input.customerName),
      customerDocumentNumber: trimOrNull(input.customerDocumentNumber),
      customerBirthPlace: trimOrNull(input.customerBirthPlace),
      customerBirthDate: trimOrNull(input.customerBirthDate),
      customerMotherName: trimOrNull(input.customerMotherName),
      customerNationality: trimOrNull(input.customerNationality),
      customerDocumentType: trimOrNull(input.customerDocumentType),
      customerIsPep: input.customerIsPep,
      customerPepKind: trimOrNull(input.customerPepKind),
      customerOnOwnBehalf: input.customerOnOwnBehalf,
      customerActorName:
        input.customerOnOwnBehalf === false ? trimOrNull(input.customerActorName) : null,
      actorIdentity:
        input.customerOnOwnBehalf === false
          ? {
              birthPlace: trimOrNull(input.customerActorBirthPlace),
              birthDate: trimOrNull(input.customerActorBirthDate),
              motherName: trimOrNull(input.customerActorMotherName),
              nationality: trimOrNull(input.customerActorNationality),
              documentType: trimOrNull(input.customerActorDocumentType),
              documentNumber: trimOrNull(input.customerActorDocumentNumber),
              address: trimOrNull(input.customerActorAddress),
            }
          : null,
    },
    identificationSnapshot: {
      customerId: trimOrNull(input.customerId),
      customerDocumentNumber: trimOrNull(input.customerDocumentNumber),
    },
    rateSnapshot: {
      fromCurrencyCode: input.fromCurrencyCode,
      toCurrencyCode: input.toCurrencyCode,
      conversionRate: input.conversionRate,
      calculatedHufAmount: input.calculatedHufAmount,
      calculatedToAmount: input.calculatedToAmount,
    },
    status: 'PENDING_UPLOAD',
  });

  return insertedId;
}

export function getPendingConversions(): PendingConversionRow[] {
  if (!db) return [];

  const results: PendingConversionRow[] = [];
  const stmt = db.prepare(
    'SELECT * FROM pending_conversions WHERE synced = 0 ORDER BY created_at ASC',
  );
  while (stmt.step()) {
    const row = stmt.getAsObject() as unknown as PendingConversionRow;
    results.push(row);
  }
  stmt.free();
  return results;
}

export function markConversionSynced(id: number): void {
  if (!db) return;
  db.run('UPDATE pending_conversions SET synced = 1 WHERE id = ?', [id]);
  saveDatabase();
}

/** FK-071 FR-5: egy sync-kísérlet eredménye a belső kísérlet-történetben. */
export interface TransactionSyncAttempt {
  attemptedAt: string;
  outcome: 'SUCCESS' | 'ERROR';
  message: string | null;
}

/**
 * FK-071 FR-5: tételenként legfeljebb ennyi kísérlet-bejegyzést őrzünk meg —
 * egy napokig ragadt tétel 30 mp-es auto-sync mellett is korlátos naplót adjon.
 */
const SYNC_ATTEMPT_HISTORY_LIMIT = 100;

/**
 * FK-071 FR-5: kísérlet hozzáfűzése a belső naplóhoz. Best-effort: a napló
 * hibája nem akadályozhatja magát a szinkron-folyamatot.
 */
function appendTransactionSyncAttempt(
  pendingTransactionId: number,
  outcome: 'SUCCESS' | 'ERROR',
  attemptedAt: string,
  message: string | null,
): void {
  if (!db) return;
  try {
    db.run(
      `INSERT INTO pending_transaction_sync_attempts
         (pending_transaction_id, attempted_at, outcome, message)
       VALUES (?, ?, ?, ?)`,
      [pendingTransactionId, attemptedAt, outcome, message],
    );
    db.run(
      `DELETE FROM pending_transaction_sync_attempts
        WHERE pending_transaction_id = ?
          AND id NOT IN (
            SELECT id FROM pending_transaction_sync_attempts
             WHERE pending_transaction_id = ?
             ORDER BY id DESC LIMIT ${SYNC_ATTEMPT_HISTORY_LIMIT})`,
      [pendingTransactionId, pendingTransactionId],
    );
  } catch {
    // Belső diagnosztikai napló — best-effort, a sync-folyamatot nem blokkolja.
  }
}

/**
 * FK-071 FR-5: egy pending tranzakció sync-kísérlet-története, időrendben.
 * KIZÁRÓLAG belső diagnosztikára — a UI-nak nem exponáljuk (a renderer felé
 * nincs IPC-csatorna hozzá; a TransactionListPage guard-teszt is ezt rögzíti).
 */
export function getTransactionSyncAttemptHistory(id: number): TransactionSyncAttempt[] {
  if (!db) return [];
  const stmt = db.prepare(
    `SELECT attempted_at, outcome, message
       FROM pending_transaction_sync_attempts
      WHERE pending_transaction_id = ?
      ORDER BY id ASC`,
  );
  stmt.bind([id]);
  const rows: TransactionSyncAttempt[] = [];
  while (stmt.step()) {
    const row = stmt.getAsObject() as {
      attempted_at?: string;
      outcome?: string;
      message?: string | null;
    };
    rows.push({
      attemptedAt: String(row.attempted_at ?? ''),
      outcome: row.outcome === 'SUCCESS' ? 'SUCCESS' : 'ERROR',
      message: row.message ?? null,
    });
  }
  stmt.free();
  return rows;
}

export function markTransactionSynced(id: number): void {
  if (!db) return;
  db.run('UPDATE pending_transactions SET synced = 1 WHERE id = ?', [id]);
  // FK-071 FR-5: a sikeres kísérlet is a belső kísérlet-történetbe kerül.
  appendTransactionSyncAttempt(id, 'SUCCESS', new Date().toISOString(), null);
  saveDatabase();
}

/** FK-071: a tárolt sync-hibaüzenet maximális hossza (korábban 500). */
const SYNC_ERROR_MAX_LENGTH = 2000;

/**
 * FK-SYNC (2026-06-02): sikertelen tranzakció-sync TARTÓS rögzítése a pending soron. A tétel
 * synced=0 marad (látható "Függőben"-ként), de a felhasználó/diagnosztika látja a hibaüzenetet,
 * a próbálkozások számát és az utolsó próbálkozás idejét. Így a tranzakció nem tűnik el némán.
 */
export function markTransactionSyncError(id: number, error: string, attemptIso: string): void {
  if (!db) return;
  const storedError = error.slice(0, SYNC_ERROR_MAX_LENGTH);
  db.run(
    // FK-071: 500 → 2000 karakteres vágás — a szerver ErrorResponse.message-e is
    // beleférjen (a TEXT oszlopnak nincs hossz-korlátja, séma-migráció nem kell).
    'UPDATE pending_transactions SET sync_error = ?, sync_attempts = COALESCE(sync_attempts, 0) + 1, last_attempt_at = ? WHERE id = ?',
    [storedError, attemptIso, id],
  );
  // FK-071 FR-5: a hibás kísérlet a belső kísérlet-történetbe is bekerül.
  appendTransactionSyncAttempt(id, 'ERROR', attemptIso, storedError);
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
  local_reference_number: string | null;
  idempotency_key: string | null;
  company_code?: string | null;
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
  const localReferenceNumber = generateLocalReference('LD');
  const idempotencyKey = crypto.randomUUID();

  db.run(
    `INSERT INTO pending_distributions (
      target_branch_code,
      currency_code,
      amount,
      denominations,
      note,
      local_reference_number,
      idempotency_key,
      company_code
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      targetBranchCode,
      currencyCode,
      amount,
      denominations,
      note,
      localReferenceNumber,
      idempotencyKey,
      getActiveCompanyCode(),
    ],
  );
  const insertedId = lastInsertRowId(db);
  saveDatabase();

  saveLocalAuditEvent({
    entityType: 'TREASURY_DISTRIBUTION',
    eventType: 'CREATE',
    referenceNumber: localReferenceNumber,
    entityId: String(insertedId),
    payload: {
      targetBranchCode,
      currencyCode,
      amount,
      denominations,
      note,
      idempotencyKey,
    },
    rateSnapshot: { currencyCode },
    status: 'PENDING_UPLOAD',
  });

  return insertedId;
}

export function getPendingDistributions(): PendingDistributionRow[] {
  if (!db) return [];
  const results: PendingDistributionRow[] = [];
  const stmt = db.prepare(
    'SELECT * FROM pending_distributions WHERE synced = 0 ORDER BY created_at ASC',
  );
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
  target_branch_id: string | null;
  target_branch_code: string;
  currency_id: number | null;
  currency_code: string;
  amount: number;
  huf_value: number | null;
  transfer_type: string | null;
  denominations: string | null;
  note: string | null;
  carrier_name: string | null;
  seal_number: string | null;
  direction: string | null;
  lines: string | null;
  local_reference_number: string | null;
  idempotency_key: string | null;
  company_code?: string | null;
  created_at: string;
  synced: number;
}

export function savePendingTransfer(
  targetBranchId: string | null,
  targetBranchCode: string,
  currencyId: number | null,
  currencyCode: string,
  amount: number,
  hufValue: number | null,
  transferType: string | null,
  denominations: string | null,
  note: string | null,
  carrierName: string | null = null,
  sealNumber: string | null = null,
  direction: string | null = null,
  lines: string | null = null,
): number {
  if (!db) throw new Error('Database not initialized');
  const roundFin = (v: number, decimals: number): number => Number(v.toFixed(decimals));
  const roundFinOrNull = (v: number | null, decimals: number): number | null =>
    v === null ? null : roundFin(v, decimals);
  // v2.3.52 B30: Átadólap-szám AT<branch>NNNNNN (legacy parity), LT-fallback ha config hiányzik.
  // v2.3.54 (Sourcery #317 P3): trim + non-empty validate — empty/whitespace branch_code-ra
  // NEM generálunk "AT  000001" malformed számot, hanem LT-fallback-re esik vissza.
  const rawBranchCode = getConfig('branch_code');
  const sourceBranchCode = rawBranchCode != null ? rawBranchCode.trim() : '';
  const idempotencyKey = crypto.randomUUID();

  // NGM 23/2014 atomicitás: a szigorú átadólap-sorszám (AT-prefix) inkrement +
  // sor INSERT egy tranzakcióban, hogy egy INSERT-hiba ROLLBACK-elje a sorszám-
  // előléptetést is (nincs hézag). Az LT-fallback nem érinti a sequence-t.
  const { ref: localReferenceNumber, id: insertedId } = withTransaction(() => {
    const ref = sourceBranchCode
      ? generateStrictReceiptNumber('AT', sourceBranchCode)
      : generateLocalReference('LT');
    db!.run(
      `INSERT INTO pending_transfers (
        target_branch_id,
        target_branch_code,
        currency_id,
        currency_code,
        amount,
        huf_value,
        transfer_type,
        denominations,
        note,
        carrier_name,
        seal_number,
        direction,
        lines,
        local_reference_number,
        idempotency_key,
        company_code
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        targetBranchId,
        targetBranchCode,
        currencyId,
        currencyCode,
        roundFin(amount, 8),
        roundFinOrNull(hufValue, 2),
        transferType,
        denominations,
        note,
        carrierName,
        sealNumber,
        direction,
        lines,
        ref,
        idempotencyKey,
        getActiveCompanyCode(),
      ],
    );
    return { ref, id: lastInsertRowId(db!) };
  });
  saveDatabase();

  saveLocalAuditEvent({
    entityType: 'TRANSFER',
    eventType: transferType ?? 'CREATE',
    referenceNumber: localReferenceNumber,
    entityId: String(insertedId),
    payload: {
      targetBranchId,
      targetBranchCode,
      currencyId,
      currencyCode,
      amount,
      hufValue,
      transferType,
      denominations,
      note,
      carrierName,
      sealNumber,
      direction,
      lines,
      idempotencyKey,
    },
    rateSnapshot: {
      currencyCode,
      hufValue,
    },
    status: 'PENDING_UPLOAD',
  });

  return insertedId;
}

export function getPendingTransfers(): PendingTransferRow[] {
  if (!db) return [];
  const results: PendingTransferRow[] = [];
  const stmt = db.prepare(
    'SELECT * FROM pending_transfers WHERE synced = 0 ORDER BY created_at ASC',
  );
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

export interface PendingShipmentReceiptRow {
  id: number;
  shipment_id: string;
  request_number: string | null;
  idempotency_key: string;
  branch_id: string;
  worker_id: number;
  company_code: string | null;
  created_at: string;
  synced: number;
  sync_attempts: number;
  sync_error: string | null;
  confirmed_stale?: number | null;
}

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function isUuidString(value: unknown): value is string {
  return typeof value === 'string' && UUID_PATTERN.test(value);
}

function containsAsciiControlCharacter(value: string): boolean {
  for (let index = 0; index < value.length; index += 1) {
    if (value.charCodeAt(index) <= 0x1f) return true;
  }
  return false;
}

export function savePendingShipmentReceipt(input: PendingShipmentReceiptInput): number {
  if (!db) throw new Error('Database not initialized');
  if (
    !input ||
    !isUuidString(input.shipmentId) ||
    !isUuidString(input.branchId) ||
    !isUuidString(input.idempotencyKey)
  ) {
    throw new Error('Érvénytelen Shipment-átvételi azonosító.');
  }
  if (!Number.isInteger(input.workerId) || input.workerId <= 0) {
    throw new Error('Érvénytelen Shipment-átvételi dolgozóazonosító.');
  }
  if (input.confirmedStale != null && typeof input.confirmedStale !== 'boolean') {
    throw new Error('Érvénytelen Shipment stale megerősítés.');
  }
  if (
    input.requestNumber != null &&
    (typeof input.requestNumber !== 'string' ||
      input.requestNumber.length > 128 ||
      containsAsciiControlCharacter(input.requestNumber))
  ) {
    throw new Error('Érvénytelen Shipment bizonylatszám.');
  }
  const companyCode = getActiveCompanyCode();
  if (!companyCode) {
    throw new Error('A Shipment-átvétel nem rögzíthető aktív cégkód nélkül.');
  }
  const open = db.exec(
    'SELECT id FROM pending_shipment_receipts WHERE shipment_id = ? AND synced = 0 LIMIT 1',
    [input.shipmentId],
  );
  if (open[0]?.values.length) {
    throw new Error('Ehhez a Shipmenthez már van szinkronra váró átvétel.');
  }
  db.run(
    `INSERT INTO pending_shipment_receipts
      (shipment_id, request_number, idempotency_key, branch_id, worker_id, company_code, confirmed_stale)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [
      input.shipmentId,
      input.requestNumber?.trim() || null,
      input.idempotencyKey,
      input.branchId,
      input.workerId,
      companyCode,
      input.confirmedStale === true ? 1 : 0,
    ],
  );
  const id = lastInsertRowId(db);
  saveDatabase();
  return id;
}

export function getPendingShipmentReceipts(): PendingShipmentReceiptRow[] {
  if (!db) return [];
  const companyCode = getActiveCompanyCode();
  if (!companyCode) return [];
  const results: PendingShipmentReceiptRow[] = [];
  const stmt = db.prepare(
    `SELECT * FROM pending_shipment_receipts
     WHERE synced = 0 AND company_code = ?
     ORDER BY created_at ASC`,
  );
  stmt.bind([companyCode]);
  while (stmt.step()) results.push(stmt.getAsObject() as unknown as PendingShipmentReceiptRow);
  stmt.free();
  return results;
}

/**
 * Renderer-láthatóság: a retry-zandó sorok mellett a lezárt üzleti hibák is megmaradnak,
 * miközben a sync-engine továbbra is kizárólag a getPendingShipmentReceipts synced=0
 * sorait dolgozza fel.
 */
export function getShipmentReceiptOutboxState(): PendingShipmentReceiptRow[] {
  if (!db) return [];
  const companyCode = getActiveCompanyCode();
  if (!companyCode) return [];
  const results: PendingShipmentReceiptRow[] = [];
  const stmt = db.prepare(
    `SELECT * FROM pending_shipment_receipts
     WHERE company_code = ? AND (synced = 0 OR sync_error IS NOT NULL)
     ORDER BY created_at ASC`,
  );
  stmt.bind([companyCode]);
  while (stmt.step()) results.push(stmt.getAsObject() as unknown as PendingShipmentReceiptRow);
  stmt.free();
  return results;
}

export function markShipmentReceiptSynced(id: number): void {
  if (!db) return;
  db.run('UPDATE pending_shipment_receipts SET synced = 1, sync_error = NULL WHERE id = ?', [id]);
  saveDatabase();
}

export function markShipmentReceiptTerminalError(id: number, message: string): void {
  if (!db) return;
  db.run(
    `UPDATE pending_shipment_receipts
     SET synced = 1, sync_attempts = sync_attempts + 1, sync_error = ? WHERE id = ?`,
    [message, id],
  );
  saveDatabase();
}

export function markShipmentReceiptRetryError(id: number, message: string): void {
  if (!db) return;
  db.run(
    `UPDATE pending_shipment_receipts
     SET sync_attempts = sync_attempts + 1, sync_error = ? WHERE id = ?`,
    [message, id],
  );
  saveDatabase();
}

// --- Értéktár Offline: Pending Collections ---

export interface PendingCollectionRow {
  id: number;
  source_branch_code: string;
  currency_code: string;
  amount: number;
  note: string | null;
  local_reference_number: string | null;
  idempotency_key: string | null;
  company_code?: string | null;
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
  const localReferenceNumber = generateLocalReference('LCOL');
  const idempotencyKey = crypto.randomUUID();

  db.run(
    `INSERT INTO pending_collections (
      source_branch_code,
      currency_code,
      amount,
      note,
      local_reference_number,
      idempotency_key,
      company_code
    ) VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [
      sourceBranchCode,
      currencyCode,
      amount,
      note,
      localReferenceNumber,
      idempotencyKey,
      getActiveCompanyCode(),
    ],
  );
  const insertedId = lastInsertRowId(db);
  saveDatabase();

  saveLocalAuditEvent({
    entityType: 'TREASURY_COLLECTION',
    eventType: 'CREATE',
    referenceNumber: localReferenceNumber,
    entityId: String(insertedId),
    payload: {
      sourceBranchCode,
      currencyCode,
      amount,
      note,
      idempotencyKey,
    },
    rateSnapshot: { currencyCode },
    status: 'PENDING_UPLOAD',
  });

  return insertedId;
}

export function savePendingBankTransaction(
  transactionType: 'BUY' | 'SELL',
  currencyCode: string,
  amount: number,
  exchangeRate: number,
  hufAmount: number,
  vaultTerritoryId: number | null,
  bankName: string | null,
  bankReference: string | null,
  note: string | null,
): number {
  if (!db) throw new Error('Database not initialized');
  const roundFin = (v: number, decimals: number): number => Number(v.toFixed(decimals));

  const localReferenceNumber = generateLocalReference('LBANK');
  const idempotencyKey = crypto.randomUUID();

  db.run(
    `INSERT INTO pending_bank_transactions (
      transaction_type,
      currency_code,
      amount,
      exchange_rate,
      huf_amount,
      vault_territory_id,
      bank_name,
      bank_reference,
      note,
      local_reference_number,
      idempotency_key,
      company_code
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      transactionType,
      currencyCode,
      roundFin(amount, 8),
      roundFin(exchangeRate, 10),
      roundFin(hufAmount, 2),
      vaultTerritoryId,
      bankName?.trim() || null,
      bankReference?.trim() || null,
      note?.trim() || null,
      localReferenceNumber,
      idempotencyKey,
      getActiveCompanyCode(),
    ],
  );
  const insertedId = lastInsertRowId(db);
  saveDatabase();

  saveLocalAuditEvent({
    entityType: 'BANK_TRANSACTION',
    eventType: transactionType,
    referenceNumber: localReferenceNumber,
    entityId: String(insertedId),
    payload: {
      transactionType,
      currencyCode,
      amount,
      exchangeRate,
      hufAmount,
      vaultTerritoryId,
      bankName: bankName?.trim() || null,
      bankReference: bankReference?.trim() || null,
      note: note?.trim() || null,
      idempotencyKey,
    },
    rateSnapshot: {
      currencyCode,
      exchangeRate,
      hufAmount,
    },
    status: 'PENDING_UPLOAD',
  });

  return insertedId;
}

export function getPendingBankTransactions(): PendingBankTransactionRow[] {
  if (!db) return [];
  const results: PendingBankTransactionRow[] = [];
  const stmt = db.prepare(
    'SELECT * FROM pending_bank_transactions WHERE synced = 0 ORDER BY created_at ASC',
  );
  while (stmt.step()) {
    results.push(stmt.getAsObject() as unknown as PendingBankTransactionRow);
  }
  stmt.free();
  return results;
}

export function markBankTransactionSynced(id: number): void {
  if (!db) return;
  db.run('UPDATE pending_bank_transactions SET synced = 1 WHERE id = ?', [id]);
  saveDatabase();
}

export function savePendingStorno(params: PendingStornoInput): number {
  if (!db) throw new Error('Database not initialized');
  const roundFin = (v: number, decimals: number): number => Number(v.toFixed(decimals));
  const roundFinOrNull = (v: number | null, decimals: number): number | null =>
    v === null ? null : roundFin(v, decimals);

  const localReferenceNumber = generateLocalReference('LST');
  const idempotencyKey = crypto.randomUUID();

  db.run(
    `INSERT INTO pending_stornos (
      transaction_id,
      original_receipt_number,
      original_transaction_type,
      currency_code,
      foreign_amount,
      huf_amount,
      exchange_rate,
      reason,
      approval_id,
      custom_exchange_rate,
      payment_method,
      customer_name,
      customer_document_number,
      local_reference_number,
      idempotency_key,
      company_code
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      params.transactionId,
      params.originalReceiptNumber,
      params.originalTransactionType,
      params.currencyCode,
      roundFinOrNull(params.foreignAmount, 8),
      roundFin(params.hufAmount, 2),
      roundFinOrNull(params.exchangeRate, 10),
      params.reason.trim(),
      params.approvalId ?? null,
      roundFinOrNull(params.customExchangeRate ?? null, 10),
      params.paymentMethod ?? null,
      params.customerName?.trim() || null,
      params.customerDocumentNumber?.trim() || null,
      localReferenceNumber,
      idempotencyKey,
      getActiveCompanyCode(),
    ],
  );
  const insertedId = lastInsertRowId(db);
  saveDatabase();

  saveLocalAuditEvent({
    entityType: 'STORNO',
    eventType: 'EXECUTE',
    referenceNumber: localReferenceNumber,
    entityId: String(insertedId),
    payload: {
      transactionId: params.transactionId,
      originalReceiptNumber: params.originalReceiptNumber,
      originalTransactionType: params.originalTransactionType,
      currencyCode: params.currencyCode,
      foreignAmount: params.foreignAmount,
      hufAmount: params.hufAmount,
      exchangeRate: params.exchangeRate,
      reason: params.reason.trim(),
      approvalId: params.approvalId ?? null,
      customExchangeRate: params.customExchangeRate ?? null,
      paymentMethod: params.paymentMethod ?? null,
      idempotencyKey,
    },
    customerSnapshot: {
      customerName: params.customerName?.trim() || null,
      customerDocumentNumber: params.customerDocumentNumber?.trim() || null,
    },
    identificationSnapshot: {
      customerDocumentNumber: params.customerDocumentNumber?.trim() || null,
    },
    rateSnapshot: {
      currencyCode: params.currencyCode,
      exchangeRate: params.customExchangeRate ?? params.exchangeRate,
      hufAmount: params.hufAmount,
    },
    status: 'PENDING_UPLOAD',
  });

  return insertedId;
}

export function getPendingStornos(): PendingStornoRow[] {
  if (!db) return [];
  const results: PendingStornoRow[] = [];
  const stmt = db.prepare('SELECT * FROM pending_stornos WHERE synced = 0 ORDER BY created_at ASC');
  while (stmt.step()) {
    results.push(stmt.getAsObject() as unknown as PendingStornoRow);
  }
  stmt.free();
  return results;
}

export function markStornoSynced(id: number): void {
  if (!db) return;
  db.run('UPDATE pending_stornos SET synced = 1 WHERE id = ?', [id]);
  saveDatabase();
}

// ============================================================================
// Átadás-átvétel bizonylat OFFLINE SZTORNÓ (pending_transfer_stornos)
// ============================================================================

export interface PendingTransferStornoRow {
  id: number;
  transfer_id: number;
  transfer_number: string | null;
  reason: string;
  local_reference_number: string | null;
  idempotency_key: string | null;
  company_code?: string | null;
  created_at: string;
  synced: number;
}

/**
 * Offline átadás-átvétel sztornó rögzítése. A backend (POST /transfers/{id}/storno) fordítja
 * vissza a készletet a szinkronkor — a penztar-client nem tart külön cash_balance-t (a lokális
 * pozíció a backendről szinkronizálódik), így az offline tranzakció-sztornóval AZONOS minta.
 */
export function savePendingTransferStorno(params: PendingTransferStornoInput): number {
  if (!db) throw new Error('Database not initialized');
  const localReferenceNumber = generateLocalReference('LTS');
  const idempotencyKey = crypto.randomUUID();

  db.run(
    `INSERT INTO pending_transfer_stornos (transfer_id, transfer_number, reason, local_reference_number, idempotency_key, company_code)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [
      params.transferId,
      params.transferNumber ?? null,
      params.reason.trim(),
      localReferenceNumber,
      idempotencyKey,
      getActiveCompanyCode(),
    ],
  );
  const insertedId = lastInsertRowId(db);
  saveDatabase();

  saveLocalAuditEvent({
    entityType: 'TRANSFER',
    eventType: 'STORNO',
    referenceNumber: params.transferNumber ?? localReferenceNumber,
    entityId: String(params.transferId),
    payload: { transferId: params.transferId, reason: params.reason.trim(), idempotencyKey },
    status: 'PENDING_UPLOAD',
  });

  return insertedId;
}

export function getPendingTransferStornos(): PendingTransferStornoRow[] {
  if (!db) return [];
  const results: PendingTransferStornoRow[] = [];
  const stmt = db.prepare(
    'SELECT * FROM pending_transfer_stornos WHERE synced = 0 ORDER BY created_at ASC',
  );
  while (stmt.step()) {
    results.push(stmt.getAsObject() as unknown as PendingTransferStornoRow);
  }
  stmt.free();
  return results;
}

export function markTransferStornoSynced(id: number): void {
  if (!db) return;
  db.run('UPDATE pending_transfer_stornos SET synced = 1 WHERE id = ?', [id]);
  saveDatabase();
}

// ============================================================================
// Körlevél-válasz outbox (FS-C, Center FS-1)
// ============================================================================

export interface PendingCircularReplyRow {
  id: number;
  circular_id: number;
  reply_text: string;
  idempotency_key: string | null;
  company_code?: string | null;
  created_at: string;
  synced: number;
}

export function savePendingCircularReply(params: PendingCircularReplyInput): number {
  if (!db) throw new Error('Database not initialized');
  const idempotencyKey = crypto.randomUUID();
  db.run(
    `INSERT INTO pending_circular_replies (circular_id, reply_text, idempotency_key, company_code)
     VALUES (?, ?, ?, ?)`,
    [params.circularId, params.replyText.trim(), idempotencyKey, getActiveCompanyCode()],
  );
  const insertedId = lastInsertRowId(db);
  saveDatabase();
  return insertedId;
}

export function getPendingCircularReplies(): PendingCircularReplyRow[] {
  if (!db) return [];
  const results: PendingCircularReplyRow[] = [];
  const stmt = db.prepare(
    'SELECT * FROM pending_circular_replies WHERE synced = 0 ORDER BY created_at ASC',
  );
  while (stmt.step()) {
    results.push(stmt.getAsObject() as unknown as PendingCircularReplyRow);
  }
  stmt.free();
  return results;
}

export function markCircularReplySynced(id: number): void {
  if (!db) return;
  db.run('UPDATE pending_circular_replies SET synced = 1 WHERE id = ?', [id]);
  saveDatabase();
}

// ============================================================================
// Okmány-képpár outbox (FS-5, Center FS-1)
// ============================================================================

export interface PendingScannedDocumentRow {
  id: number;
  customer_id: number;
  document_type: string;
  front_path: string;
  back_path: string;
  notes: string | null;
  idempotency_key: string | null;
  company_code: string | null;
  sync_error: string | null;
  created_at: string;
  synced: number;
}

export function savePendingScannedDocument(params: {
  customerId: number;
  documentType: string;
  frontPath: string;
  backPath: string;
  notes?: string | null;
}): number {
  if (!db) throw new Error('Database not initialized');
  const idempotencyKey = crypto.randomUUID();
  db.run(
    `INSERT INTO pending_scanned_documents
       (customer_id, document_type, front_path, back_path, notes, idempotency_key, company_code)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [
      params.customerId,
      params.documentType,
      params.frontPath,
      params.backPath,
      params.notes ?? null,
      idempotencyKey,
      getActiveCompanyCode(),
    ],
  );
  const insertedId = lastInsertRowId(db);
  saveDatabase();
  return insertedId;
}

export function getPendingScannedDocuments(): PendingScannedDocumentRow[] {
  if (!db) return [];
  const results: PendingScannedDocumentRow[] = [];
  const stmt = db.prepare(
    'SELECT * FROM pending_scanned_documents WHERE synced = 0 ORDER BY created_at ASC',
  );
  while (stmt.step()) {
    results.push(stmt.getAsObject() as unknown as PendingScannedDocumentRow);
  }
  stmt.free();
  return results;
}

export function markScannedDocumentSynced(id: number): void {
  if (!db) return;
  db.run('UPDATE pending_scanned_documents SET synced = 1 WHERE id = ?', [id]);
  saveDatabase();
}

export function markScannedDocumentSyncError(id: number, errorMsg: string): void {
  if (!db) return;
  db.run('UPDATE pending_scanned_documents SET sync_error = ? WHERE id = ?', [errorMsg, id]);
  saveDatabase();
}

// ============================================================================
// Fizikai ujranyomtatas — mar szinkronizalt (synced = 1) bizonylatok
// ============================================================================
//
// VALOS operativ hianyossag (Codex P2, #1035): ha egy bizonylat MAR felszinkronizalt
// (synced = 1) es a fizikai nyomtatas meghiusul (papirelakadas, nyomtato offline),
// a vazlat-bongeszobol eltunik (getPendingTransactions/Conversions/Stornos CSAK
// synced = 0-t listaz), igy nincs tiszta fizikai-ujranyomtatasi ut.
//
// Ezek a lekerdezesek a LEGUTOBBI szinkronizalt sorokat adjak vissza (DESC, limitelve),
// hogy az operator a lokalis receiptData-bol (local-first) ESC/POS-on ujra tudja nyomtatni
// a bizonylatot. A sync-engine TOVABBRA is a synced = 0 lekerdezeseket hasznalja —
// ezeket NEM erintik.
//
// A `lines` oszlop (multi-line aggregalt vetel/eladas) is visszaadasra kerul a SELECT *
// reven, igy az ujranyomtatas a TELJES tetelsort rekonstrualni tudja.

/** Alapertelmezett ujranyomtatasi ablak: a legutobbi N szinkronizalt bizonylat. */
const REPRINT_DEFAULT_LIMIT = 50;

function clampReprintLimit(limit?: number): number {
  if (typeof limit !== 'number' || !Number.isFinite(limit) || limit <= 0) {
    return REPRINT_DEFAULT_LIMIT;
  }
  return Math.min(Math.floor(limit), 200);
}

export function getReprintableTransactions(limit?: number): PendingTransactionRow[] {
  if (!db) return [];
  const results: PendingTransactionRow[] = [];
  const stmt = db.prepare(
    'SELECT * FROM pending_transactions WHERE synced = 1 ORDER BY created_at DESC, id DESC LIMIT ?',
  );
  stmt.bind([clampReprintLimit(limit)]);
  while (stmt.step()) {
    results.push(stmt.getAsObject() as unknown as PendingTransactionRow);
  }
  stmt.free();
  return results;
}

export function getReprintableConversions(limit?: number): PendingConversionRow[] {
  if (!db) return [];
  const results: PendingConversionRow[] = [];
  const stmt = db.prepare(
    'SELECT * FROM pending_conversions WHERE synced = 1 ORDER BY created_at DESC, id DESC LIMIT ?',
  );
  stmt.bind([clampReprintLimit(limit)]);
  while (stmt.step()) {
    results.push(stmt.getAsObject() as unknown as PendingConversionRow);
  }
  stmt.free();
  return results;
}

export function getReprintableStornos(limit?: number): PendingStornoRow[] {
  if (!db) return [];
  const results: PendingStornoRow[] = [];
  const stmt = db.prepare(
    'SELECT * FROM pending_stornos WHERE synced = 1 ORDER BY created_at DESC, id DESC LIMIT ?',
  );
  stmt.bind([clampReprintLimit(limit)]);
  while (stmt.step()) {
    results.push(stmt.getAsObject() as unknown as PendingStornoRow);
  }
  stmt.free();
  return results;
}

// ============================================================================
// RPO-vedohalo (2026-06-05): re-assert lekerdezok. Failover/reconnect utan a
// kliens ujrakuldi a legutobbi (idempotency-key-vel rendelkezo) SYNCED rekordokat;
// a backend a key alapjan dedupol (ha mar megvan) vagy visszapotol (ha a failover-
// ablakban elveszett). A `sinceIso` ablak < a backend 24h idempotency-TTL-jenel.
// A lokalis allapotot NEM valtoztatjak (a rekordok synced=1 maradnak).
// ============================================================================
export function getReassertableTransactions(sinceIso: string): PendingTransactionRow[] {
  if (!db) return [];
  const results: PendingTransactionRow[] = [];
  const stmt = db.prepare(
    'SELECT * FROM pending_transactions WHERE synced = 1 AND idempotency_key IS NOT NULL AND created_at >= ? ORDER BY created_at ASC, id ASC',
  );
  stmt.bind([sinceIso]);
  while (stmt.step()) results.push(stmt.getAsObject() as unknown as PendingTransactionRow);
  stmt.free();
  return results;
}

export function getReassertableConversions(sinceIso: string): PendingConversionRow[] {
  if (!db) return [];
  const results: PendingConversionRow[] = [];
  const stmt = db.prepare(
    'SELECT * FROM pending_conversions WHERE synced = 1 AND idempotency_key IS NOT NULL AND created_at >= ? ORDER BY created_at ASC, id ASC',
  );
  stmt.bind([sinceIso]);
  while (stmt.step()) results.push(stmt.getAsObject() as unknown as PendingConversionRow);
  stmt.free();
  return results;
}

export function getReassertableStornos(sinceIso: string): PendingStornoRow[] {
  if (!db) return [];
  const results: PendingStornoRow[] = [];
  const stmt = db.prepare(
    'SELECT * FROM pending_stornos WHERE synced = 1 AND idempotency_key IS NOT NULL AND created_at >= ? ORDER BY created_at ASC, id ASC',
  );
  stmt.bind([sinceIso]);
  while (stmt.step()) results.push(stmt.getAsObject() as unknown as PendingStornoRow);
  stmt.free();
  return results;
}

export function getReassertableBankTransactions(sinceIso: string): PendingBankTransactionRow[] {
  if (!db) return [];
  const results: PendingBankTransactionRow[] = [];
  const stmt = db.prepare(
    'SELECT * FROM pending_bank_transactions WHERE synced = 1 AND idempotency_key IS NOT NULL AND created_at >= ? ORDER BY created_at ASC, id ASC',
  );
  stmt.bind([sinceIso]);
  while (stmt.step()) results.push(stmt.getAsObject() as unknown as PendingBankTransactionRow);
  stmt.free();
  return results;
}

export function savePendingHandoverOperation(params: PendingHandoverOperationInput): number {
  if (!db) throw new Error('Database not initialized');

  const localReferenceNumber = generateLocalReference(
    params.operationType === 'GENERATE' ? 'LHS' : `LHS-${params.operationType}`,
  );
  const idempotencyKey = crypto.randomUUID();

  db.run(
    `INSERT INTO pending_handover_operations (
      operation_type,
      sheet_id,
      from_cash_desk_id,
      to_cash_desk_id,
      transfer_date,
      amounts_json,
      note,
      local_reference_number,
      idempotency_key,
      company_code
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      params.operationType,
      params.sheetId ?? null,
      params.fromCashDeskId ?? null,
      params.toCashDeskId ?? null,
      params.transferDate ?? null,
      toJsonOrNull(params.amounts),
      params.note?.trim() || null,
      localReferenceNumber,
      idempotencyKey,
      getActiveCompanyCode(),
    ],
  );
  const insertedId = lastInsertRowId(db);
  saveDatabase();

  saveLocalAuditEvent({
    entityType: 'HANDOVER_SHEET',
    eventType: params.operationType,
    referenceNumber: localReferenceNumber,
    entityId: String(insertedId),
    payload: {
      sheetId: params.sheetId ?? null,
      fromCashDeskId: params.fromCashDeskId ?? null,
      toCashDeskId: params.toCashDeskId ?? null,
      transferDate: params.transferDate ?? null,
      amounts: params.amounts ?? null,
      note: params.note?.trim() || null,
      idempotencyKey,
    },
    status: 'PENDING_UPLOAD',
  });

  return insertedId;
}

export function getPendingHandoverOperations(): PendingHandoverOperationRow[] {
  if (!db) return [];
  const results: PendingHandoverOperationRow[] = [];
  const stmt = db.prepare(
    'SELECT * FROM pending_handover_operations WHERE synced = 0 ORDER BY created_at ASC',
  );
  while (stmt.step()) {
    results.push(stmt.getAsObject() as unknown as PendingHandoverOperationRow);
  }
  stmt.free();
  return results;
}

export function markHandoverOperationSynced(id: number): void {
  if (!db) return;
  db.run('UPDATE pending_handover_operations SET synced = 1 WHERE id = ?', [id]);
  saveDatabase();
}

export function getPendingCollections(): PendingCollectionRow[] {
  if (!db) return [];
  const results: PendingCollectionRow[] = [];
  const stmt = db.prepare(
    'SELECT * FROM pending_collections WHERE synced = 0 ORDER BY created_at ASC',
  );
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

// Sprint 7.1: Stocktake offline queue API
export interface PendingStocktakeItemRow {
  id: number;
  item_id: string;
  actual_quantity: number;
  note: string | null;
  idempotency_key: string | null;
  company_code?: string | null;
  created_at: string;
  synced: number;
  sync_error: string | null;
  retry_count: number;
}

export function queueStocktakeCount(
  itemId: string,
  actualQuantity: number,
  note: string | null,
  idempotencyKey: string | null,
): number {
  if (!db) return 0;
  const stmt = db.prepare(
    'INSERT INTO pending_stocktake_items (item_id, actual_quantity, note, idempotency_key, company_code) VALUES (?, ?, ?, ?, ?)',
  );
  stmt.run([itemId, actualQuantity, note, idempotencyKey, getActiveCompanyCode()]);
  const insertedId = lastInsertRowId(db);
  stmt.free();
  saveDatabase();
  return insertedId;
}

export function getPendingStocktakeItems(): PendingStocktakeItemRow[] {
  if (!db) return [];
  const results: PendingStocktakeItemRow[] = [];
  const stmt = db.prepare(
    'SELECT * FROM pending_stocktake_items WHERE synced = 0 ORDER BY created_at ASC LIMIT 100',
  );
  while (stmt.step()) {
    results.push(stmt.getAsObject() as unknown as PendingStocktakeItemRow);
  }
  stmt.free();
  return results;
}

export function markStocktakeItemSynced(id: number): void {
  if (!db) return;
  db.run('UPDATE pending_stocktake_items SET synced = 1 WHERE id = ?', [id]);
  saveDatabase();
}

export function markStocktakeItemError(id: number, error: string): void {
  if (!db) return;
  db.run(
    'UPDATE pending_stocktake_items SET sync_error = ?, retry_count = retry_count + 1 WHERE id = ?',
    [error, id],
  );
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
    [
      branchCode,
      branchName,
      companyId,
      lastSyncAt,
      onlineStatus,
      totalHufValue,
      dailyTurnover,
      cashBalances,
    ],
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

// --- Master Cache: Cash desks (branch master) ---

export interface CachedCashDeskRow {
  id: string;
  code: string;
  name: string;
  company_id: string | null;
  city: string | null;
  /** Fejléc-javítás 2026-06-11 (NFR-1 offline): utca/házszám a bizonylat-fejléchez. */
  address: string | null;
  /** Fejléc-javítás 2026-06-11 (NFR-1 offline): irányítószám a bizonylat-fejléchez. */
  zip_code: string | null;
  /** Fejléc-javítás 2026-06-11 (NFR-1 offline): telefonszám a bizonylat-fejléchez. */
  phone: string | null;
  /** Bizonylat-doc 2. kör TBD-5 (2026-06-12): numerikus KESZLEX terület-kód az "[azonosító]. [név]" formátumhoz (Copilot #1114). */
  region_code?: string | null;
  is_active: number;
  cached_at: string;
}

export function saveCachedCashDesk(
  id: string,
  code: string,
  name: string,
  companyId: string | null,
  city: string | null,
  isActive: boolean,
  address: string | null = null,
  zipCode: string | null = null,
  phone: string | null = null,
  regionCode: string | null = null,
): void {
  if (!db) return;

  db.run(
    `INSERT INTO cached_cash_desks (id, code, name, company_id, city, address, zip_code, phone, region_code, is_active, cached_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))
     ON CONFLICT(id) DO UPDATE SET
       code = excluded.code,
       name = excluded.name,
       company_id = excluded.company_id,
       city = excluded.city,
       address = excluded.address,
       zip_code = excluded.zip_code,
       phone = excluded.phone,
       region_code = excluded.region_code,
       is_active = excluded.is_active,
       cached_at = excluded.cached_at`,
    [id, code, name, companyId, city, address, zipCode, phone, regionCode, isActive ? 1 : 0],
  );
  saveDatabase();
}

export function getCachedCashDesks(): CachedCashDeskRow[] {
  if (!db) return [];
  const results: CachedCashDeskRow[] = [];
  const stmt = db.prepare('SELECT * FROM cached_cash_desks ORDER BY code ASC');
  while (stmt.step()) {
    results.push(stmt.getAsObject() as unknown as CachedCashDeskRow);
  }
  stmt.free();
  return results;
}

export function getCachedCashDeskTimestamp(): string | null {
  if (!db) return null;
  const stmt = db.prepare('SELECT MAX(cached_at) as last_cached FROM cached_cash_desks');
  stmt.step();
  const row = stmt.getAsObject();
  stmt.free();
  return (row['last_cached'] as string) ?? null;
}

// --- Master Cache: Workers ---

export interface CachedWorkerRow {
  id: number;
  worker_code: string | null;
  full_name: string;
  role: string | null;
  branch_id: string | null;
  branch_code: string | null;
  branch_name: string | null;
  company_id: string | null;
  company_code: string | null;
  active: number;
  cached_at: string;
}

export function saveCachedWorker(
  id: number,
  workerCode: string | null,
  fullName: string,
  role: string | null,
  branchId: string | null,
  branchCode: string | null,
  branchName: string | null,
  companyId: string | null,
  companyCode: string | null,
  active: boolean,
): void {
  if (!db) return;

  db.run(
    `INSERT INTO cached_workers (id, worker_code, full_name, role, branch_id, branch_code, branch_name, company_id, company_code, active, cached_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))
     ON CONFLICT(id) DO UPDATE SET
       worker_code = excluded.worker_code,
       full_name = excluded.full_name,
       role = excluded.role,
       branch_id = excluded.branch_id,
       branch_code = excluded.branch_code,
       branch_name = excluded.branch_name,
       company_id = excluded.company_id,
       company_code = excluded.company_code,
       active = excluded.active,
       cached_at = excluded.cached_at`,
    [
      id,
      workerCode,
      fullName,
      role,
      branchId,
      branchCode,
      branchName,
      companyId,
      companyCode,
      active ? 1 : 0,
    ],
  );
  saveDatabase();
}

export function getCachedWorkers(): CachedWorkerRow[] {
  if (!db) return [];
  const results: CachedWorkerRow[] = [];
  const stmt = db.prepare('SELECT * FROM cached_workers ORDER BY full_name ASC');
  while (stmt.step()) {
    results.push(stmt.getAsObject() as unknown as CachedWorkerRow);
  }
  stmt.free();
  return results;
}

export function getCachedWorkerTimestamp(): string | null {
  if (!db) return null;
  const stmt = db.prepare('SELECT MAX(cached_at) as last_cached FROM cached_workers');
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

// --- FK-097 WU-12: cached_handling_fee_config accessorok (FR-1) ---

export interface CachedHandlingFeeConfigRow {
  branch_id: string;
  branch_code: string | null;
  company_id: string | null;
  fee_mode: 'NONE' | 'BRACKET' | 'PER_MILLE';
  per_mille_rate: number | null;
  per_mille_cap: number | null;
  bracket_json: string | null;
  valid_from: string | null;
  synced_at: string;
}

/**
 * FK-097: a szinkron-válasz tükrözése a lokális SQLite-ba.
 * INSERT ... ON CONFLICT(branch_id) DO UPDATE (upsert), majd saveDatabase() —
 * a sql.js írás memóriában marad a perzisztálásig (pitfall #19).
 */
export function saveCachedHandlingFeeConfig(row: {
  branch_id: string;
  branch_code: string | null;
  company_id: string | null;
  fee_mode: 'NONE' | 'BRACKET' | 'PER_MILLE';
  per_mille_rate: number | null;
  per_mille_cap: number | null;
  bracket_json: string | null;
  valid_from: string | null;
}): void {
  if (!db) return;
  db.run(
    `INSERT INTO cached_handling_fee_config
       (branch_id, branch_code, company_id, fee_mode, per_mille_rate, per_mille_cap,
        bracket_json, valid_from, synced_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))
     ON CONFLICT(branch_id) DO UPDATE SET
       branch_code = excluded.branch_code,
       company_id = excluded.company_id,
       fee_mode = excluded.fee_mode,
       per_mille_rate = excluded.per_mille_rate,
       per_mille_cap = excluded.per_mille_cap,
       bracket_json = excluded.bracket_json,
       valid_from = excluded.valid_from,
       synced_at = excluded.synced_at`,
    [
      row.branch_id,
      row.branch_code,
      row.company_id,
      row.fee_mode,
      row.per_mille_rate,
      row.per_mille_cap,
      row.bracket_json,
      row.valid_from,
    ],
  );
  saveDatabase();
}

/** A legfrissebb (synced_at) cache-sor; üres táblán null. */
export function getCachedHandlingFeeConfig(): CachedHandlingFeeConfigRow | null {
  if (!db) return null;
  const stmt = db.prepare(
    'SELECT * FROM cached_handling_fee_config ORDER BY synced_at DESC LIMIT 1',
  );
  const has = stmt.step();
  const row = has ? (stmt.getAsObject() as unknown as CachedHandlingFeeConfigRow) : null;
  stmt.free();
  return row;
}

// --- Local-first: Tombstone API ---

export function markTombstone(
  entityType: string,
  entityId: string,
  retentionDays: number = 30,
): void {
  if (!db) return;
  const retentionUntil = new Date();
  retentionUntil.setDate(retentionUntil.getDate() + retentionDays);
  db.run(
    `INSERT OR REPLACE INTO lf_tombstone (entity_type, entity_id, deleted_at, synced, retention_until)
     VALUES (?, ?, datetime('now'), 0, ?)`,
    [entityType, entityId, retentionUntil.toISOString()],
  );
  saveDatabase();
}

export function isTombstoned(entityType: string, entityId: string): boolean {
  if (!db) return false;
  const stmt = db.prepare('SELECT 1 FROM lf_tombstone WHERE entity_type = ? AND entity_id = ?');
  stmt.bind([entityType, entityId]);
  const exists = stmt.step();
  stmt.free();
  return exists;
}

export function getUnsyncedTombstones(): Array<{
  entity_type: string;
  entity_id: string;
  deleted_at: string;
}> {
  if (!db) return [];
  const results: Array<{ entity_type: string; entity_id: string; deleted_at: string }> = [];
  const stmt = db.prepare(
    'SELECT entity_type, entity_id, deleted_at FROM lf_tombstone WHERE synced = 0',
  );
  while (stmt.step()) {
    results.push(
      stmt.getAsObject() as unknown as {
        entity_type: string;
        entity_id: string;
        deleted_at: string;
      },
    );
  }
  stmt.free();
  return results;
}

export function markTombstoneSynced(entityType: string, entityId: string): void {
  if (!db) return;
  db.run('UPDATE lf_tombstone SET synced = 1 WHERE entity_type = ? AND entity_id = ?', [
    entityType,
    entityId,
  ]);
  saveDatabase();
}

export function cleanupExpiredTombstones(): void {
  if (!db) return;
  db.run(
    `DELETE FROM lf_tombstone WHERE synced = 1 AND datetime(retention_until) < datetime('now')`,
  );
  saveDatabase();
}

// --- Local-first: Sync State API ---

export interface LfSyncState {
  status: string;
  lastPullAt: string | null;
  lastPushAt: string | null;
  lastPullCheckpoint: string | null;
  errorMessage: string | null;
  consecutiveFailures: number;
}

export function getLfSyncState(): LfSyncState {
  if (!db)
    return {
      status: 'idle',
      lastPullAt: null,
      lastPushAt: null,
      lastPullCheckpoint: null,
      errorMessage: null,
      consecutiveFailures: 0,
    };
  const stmt = db.prepare('SELECT * FROM lf_sync_state WHERE id = 1');
  if (!stmt.step()) {
    stmt.free();
    return {
      status: 'idle',
      lastPullAt: null,
      lastPushAt: null,
      lastPullCheckpoint: null,
      errorMessage: null,
      consecutiveFailures: 0,
    };
  }
  const row = stmt.getAsObject() as Record<string, unknown>;
  stmt.free();
  return {
    status: String(row['status'] ?? 'idle'),
    lastPullAt: row['last_pull_at'] as string | null,
    lastPushAt: row['last_push_at'] as string | null,
    lastPullCheckpoint: row['last_pull_checkpoint'] as string | null,
    errorMessage: row['error_message'] as string | null,
    consecutiveFailures: Number(row['consecutive_failures'] ?? 0),
  };
}

export function updateLfSyncStatus(status: string, errorMessage?: string): void {
  if (!db) return;
  db.run(
    `UPDATE lf_sync_state SET status = ?, error_message = ?, updated_at = datetime('now'),
     consecutive_failures = CASE WHEN ? = 'error' THEN consecutive_failures + 1 ELSE 0 END
     WHERE id = 1`,
    [status, errorMessage ?? null, status],
  );
}

export function updateLfPullCheckpoint(checkpoint: string): void {
  if (!db) return;
  db.run(
    `UPDATE lf_sync_state SET last_pull_checkpoint = ?, last_pull_at = datetime('now'), updated_at = datetime('now') WHERE id = 1`,
    [checkpoint],
  );
  saveDatabase();
}

export function updateLfPushTimestamp(): void {
  if (!db) return;
  db.run(
    `UPDATE lf_sync_state SET last_push_at = datetime('now'), updated_at = datetime('now') WHERE id = 1`,
  );
}

// --- Local-first: Conflict Log API ---

export function logConflict(
  entityType: string,
  entityId: string,
  localVersion: string | null,
  serverVersion: string | null,
  resolution: string,
): void {
  if (!db) return;
  db.run(
    `INSERT INTO lf_conflict_log (entity_type, entity_id, local_version, server_version, resolution)
     VALUES (?, ?, ?, ?, ?)`,
    [entityType, entityId, localVersion, serverVersion, resolution],
  );
  saveDatabase();
}

export function getSchemaVersion(): number {
  if (!db) return 0;
  const result = db.exec('PRAGMA user_version');
  const firstRow = result[0];
  return firstRow?.values?.[0]?.[0] != null ? Number(firstRow.values[0]![0]) : 0;
}

// =============================================================================
// FKH-D2/F5 — sync-gate-elt gyari reset (2026-08-11)
// =============================================================================
// A telepito NEM torolheti a `~/.valuta/local.db`-t: admin-kontextusban a rossz
// felhasznaloi profilra oldodna fel (D2), es szinkronizalatlan valodi penzugyi
// tranzakciokat semmisitene meg. Az app viszont GARANTALTAN a helyes profilban
// fut (`getDbPath()` -> `app.getPath('home')`), ezert a wipe itt a helye.
//
// FONTOS: a `getPendingTransactionCount()` CSAK a `pending_transactions` tablat
// nezi — az offline outbox viszont 13 uzleti tablat hasznal (l. `OUTBOX_TABLES`,
// :93). Egy csak arra epulo gate hamis biztonsagot adna, ezert itt MINDET
// ellenorizzuk. Ujrahasznositjuk a meglevo, mar multi-tenant celra hasznalt
// listat, hogy ne keletkezzen ket, egymastol elsodrodo forras.

export interface UnsyncedSummary {
  total: number;
  byTable: Record<string, number>;
}

/**
 * Megszamolja MINDEN offline outbox-tabla szinkronizalatlan sorait.
 * Ez a gyari reset kapuja — nem a szukebb `getPendingTransactionCount()`.
 */
export function getUnsyncedSummary(): UnsyncedSummary {
  const byTable: Record<string, number> = {};
  let total = 0;
  if (!db) return { total: 0, byTable };

  for (const table of OUTBOX_TABLES) {
    // A tabla hianyozhat regebbi sema mellett — ilyenkor 0-nak vesszuk.
    const exists = db.exec(
      `SELECT name FROM sqlite_master WHERE type='table' AND name='${table}'`,
    );
    if (!exists.length) continue;

    const stmt = db.prepare(`SELECT COUNT(*) AS cnt FROM ${table} WHERE synced = 0`);
    stmt.step();
    const row = stmt.getAsObject();
    stmt.free();
    const count = (row['cnt'] as number) ?? 0;
    if (count > 0) {
      byTable[table] = count;
      total += count;
    }
  }
  return { total, byTable };
}

export interface FactoryResetResult {
  ok: boolean;
  /** Ha `ok === false`, itt van, mi tartja vissza a torlest. */
  blockedBy?: UnsyncedSummary;
  deletedPath?: string;
}

/**
 * Sync-gate-elt gyari reset: CSAK akkor torli a lokalis adatbazist, ha egyetlen
 * szinkronizalatlan sor sincs. Kulonben FAIL-LOUD: visszaadja, mi tartja vissza.
 *
 * Szandekosan NEM tesz mentest: titkositatlan `.bak` egy „gyari reset" utan
 * pontosan az a hamis biztonsag lenne, amit az FKH-036 F2 review elvetett.
 */
export function factoryResetLocalDatabase(): FactoryResetResult {
  const summary = getUnsyncedSummary();
  if (summary.total > 0) {
    // Szandekosan nem naplozunk itt: ez a modul (eddig) logger-mentes, a
    // naplozas a hivo `main.ts` IPC-handler feladata.
    return { ok: false, blockedBy: summary };
  }

  const dbPath = getDbPath();

  // A sql.js memoriaban dolgozik; ha nyitva hagyjuk, egy kesobbi saveDatabase()
  // visszairna a torolt fajlt. Ezert eloszor elengedjuk a handle-t.
  if (db) {
    db.close();
    db = null;
  }

  const existed = fs.existsSync(dbPath);
  if (existed) {
    fs.unlinkSync(dbPath);
  }

  return { ok: true, deletedPath: existed ? dbPath : undefined };
}
