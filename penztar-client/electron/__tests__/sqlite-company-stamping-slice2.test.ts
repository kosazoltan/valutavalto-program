import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const mockState = vi.hoisted(() => ({
  tempHome: '',
}));

vi.mock('electron', () => ({
  app: {
    getPath: vi.fn(() => mockState.tempHome),
    getAppPath: vi.fn(() => mockState.tempHome),
    isPackaged: false,
  },
}));

import {
  deleteConfig,
  getDb,
  initDatabase,
  queueStocktakeCount,
  savePendingBankTransaction,
  savePendingCollection,
  savePendingDistribution,
  savePendingHandoverOperation,
  savePendingStorno,
  savePendingTransferStorno,
  setConfig,
} from '../sqlite';

function latestCompanyCodeFor(table: string): string | null {
  const db = getDb();
  if (!db) throw new Error('Database not initialized');
  const stmt = db.prepare(`SELECT company_code FROM ${table} ORDER BY id DESC LIMIT 1`);
  const found = stmt.step();
  if (!found) {
    stmt.free();
    throw new Error(`Missing ${table} row`);
  }
  const row = stmt.getAsObject() as { company_code?: string | null };
  stmt.free();
  return row.company_code ?? null;
}

function resetPendingTables(): void {
  const db = getDb();
  if (!db) throw new Error('Database not initialized');
  for (const table of [
    'pending_bank_transactions',
    'pending_stornos',
    'pending_transfer_stornos',
    'pending_handover_operations',
    'pending_distributions',
    'pending_collections',
    'pending_stocktake_items',
    'local_audit_events',
  ]) {
    db.run(`DELETE FROM ${table}`);
  }
}

describe('sqlite pending outbox company_code stamping slice 2', () => {
  beforeAll(async () => {
    mockState.tempHome = fs.mkdtempSync(path.join(os.tmpdir(), 'valuta-company-stamping-slice2-'));
    await initDatabase();
  });

  beforeEach(() => {
    resetPendingTables();
    setConfig('branch_code', '105');
    setConfig('bootstrap_company_code', 'BC');
  });

  afterAll(() => {
    fs.rmSync(mockState.tempHome, { recursive: true, force: true });
  });

  it('stamps pending bank transaction rows with the active company code', () => {
    savePendingBankTransaction('BUY', 'EUR', 100, 395.5, 39550, null, null, null, null);

    expect(latestCompanyCodeFor('pending_bank_transactions')).toBe('BC');
  });

  it('stamps pending storno rows with the active company code', () => {
    savePendingStorno({
      transactionId: 1,
      originalReceiptNumber: 'R-1',
      originalTransactionType: 'BUY',
      currencyCode: 'EUR',
      foreignAmount: 100,
      hufAmount: 39550,
      exchangeRate: 395.5,
      reason: 'teszt',
    });

    expect(latestCompanyCodeFor('pending_stornos')).toBe('BC');
  });

  it('stamps pending transfer-storno rows with the active company code', () => {
    savePendingTransferStorno({ transferId: 1, reason: 'teszt' });

    expect(latestCompanyCodeFor('pending_transfer_stornos')).toBe('BC');
  });

  it('stamps pending handover operation rows with the active company code', () => {
    savePendingHandoverOperation({ operationType: 'GENERATE' });

    expect(latestCompanyCodeFor('pending_handover_operations')).toBe('BC');
  });

  it('stamps pending distribution rows with the active company code', () => {
    savePendingDistribution('105', 'EUR', 100, null, null);

    expect(latestCompanyCodeFor('pending_distributions')).toBe('BC');
  });

  it('stamps pending collection rows with the active company code', () => {
    savePendingCollection('105', 'EUR', 100, null);

    expect(latestCompanyCodeFor('pending_collections')).toBe('BC');
  });

  it('stamps pending stocktake item rows with the active company code', () => {
    queueStocktakeCount('item-uuid-1', 5, null, 'idem-1');

    expect(latestCompanyCodeFor('pending_stocktake_items')).toBe('BC');
  });

  it('does not throw and stores NULL when bootstrap_company_code is missing', () => {
    deleteConfig('bootstrap_company_code');

    savePendingBankTransaction('SELL', 'USD', 50, 360, 18000, null, null, null, null);

    expect(latestCompanyCodeFor('pending_bank_transactions')).toBeNull();
  });
});
