/**
 * Inventory: local stock calculation from transaction movements.
 *
 * CRITICAL DOMAIN RULE: There is NO central inventory.
 * Each cash register and vault has its OWN stock, calculated as:
 *   stock = SUM(incoming) - SUM(outgoing) per currency
 *
 * Movement types:
 *   Cash register: buy_customer (+), receive_vault (+), sell_customer (-), send_vault (-)
 *   Vault:         bank_purchase (+), receive_register (+), bank_sell (-), send_register (-)
 */

import type { Database } from 'sql.js';

export type MovementDirection = 'in' | 'out';

export interface InventoryMovement {
  id?: number;
  currency_code: string;
  amount: number;
  direction: MovementDirection;
  movement_type: string;
  reference_id: string | null;
  branch_code: string;
  created_at?: string;
  synced?: number;
}

export interface StockPosition {
  currency_code: string;
  total_in: number;
  total_out: number;
  balance: number;
}

export function ensureInventoryTable(db: Database): void {
  db.run(`
    CREATE TABLE IF NOT EXISTS lf_inventory_movements (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      currency_code TEXT NOT NULL,
      amount REAL NOT NULL CHECK(amount > 0),
      direction TEXT NOT NULL CHECK(direction IN ('in', 'out')),
      movement_type TEXT NOT NULL,
      reference_id TEXT,
      branch_code TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      synced INTEGER NOT NULL DEFAULT 0
    );
  `);
  db.run('CREATE INDEX IF NOT EXISTS idx_inv_currency ON lf_inventory_movements(currency_code, branch_code);');
  db.run('CREATE INDEX IF NOT EXISTS idx_inv_synced ON lf_inventory_movements(synced);');
}

export function recordMovement(
  db: Database,
  movement: Omit<InventoryMovement, 'id' | 'created_at' | 'synced'>,
): number {
  db.run(
    `INSERT INTO lf_inventory_movements (currency_code, amount, direction, movement_type, reference_id, branch_code)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [movement.currency_code, movement.amount, movement.direction, movement.movement_type, movement.reference_id ?? null, movement.branch_code],
  );
  const result = db.exec('SELECT last_insert_rowid()');
  return Number(result[0].values[0][0]);
}

export function getStockPosition(db: Database, branchCode: string, currencyCode?: string): StockPosition[] {
  const params: (string | null)[] = [branchCode];
  let whereClause = 'WHERE branch_code = ?';
  if (currencyCode) {
    whereClause += ' AND currency_code = ?';
    params.push(currencyCode);
  }

  const stmt = db.prepare(`
    SELECT
      currency_code,
      COALESCE(SUM(CASE WHEN direction = 'in' THEN amount ELSE 0 END), 0) as total_in,
      COALESCE(SUM(CASE WHEN direction = 'out' THEN amount ELSE 0 END), 0) as total_out,
      COALESCE(SUM(CASE WHEN direction = 'in' THEN amount ELSE -amount END), 0) as balance
    FROM lf_inventory_movements
    ${whereClause}
    GROUP BY currency_code
    ORDER BY currency_code
  `);
  stmt.bind(params);

  const results: StockPosition[] = [];
  while (stmt.step()) {
    const row = stmt.getAsObject() as Record<string, unknown>;
    results.push({
      currency_code: row.currency_code as string,
      total_in: row.total_in as number,
      total_out: row.total_out as number,
      balance: row.balance as number,
    });
  }
  stmt.free();
  return results;
}

export function checkSufficientStock(
  db: Database,
  branchCode: string,
  currencyCode: string,
  requiredAmount: number,
): boolean {
  const positions = getStockPosition(db, branchCode, currencyCode);
  if (positions.length === 0) return false;
  return positions[0].balance >= requiredAmount;
}

export function getUnsyncedMovements(db: Database, limit = 100): InventoryMovement[] {
  const stmt = db.prepare(
    `SELECT * FROM lf_inventory_movements WHERE synced = 0 ORDER BY created_at ASC LIMIT ?`,
  );
  stmt.bind([limit]);
  const results: InventoryMovement[] = [];
  while (stmt.step()) {
    results.push(stmt.getAsObject() as unknown as InventoryMovement);
  }
  stmt.free();
  return results;
}

export function markMovementSynced(db: Database, id: number): void {
  db.run(`UPDATE lf_inventory_movements SET synced = 1 WHERE id = ?`, [id]);
}
