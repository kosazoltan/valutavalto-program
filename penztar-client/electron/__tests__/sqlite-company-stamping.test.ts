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
  savePendingConversion,
  savePendingConversionV2,
  savePendingTransaction,
  savePendingTransactionV2,
  savePendingTransfer,
  setConfig,
  type PendingConversionInputV2,
  type PendingTransactionInputV2,
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
    'pending_transactions',
    'pending_conversions',
    'pending_transfers',
    'local_audit_events',
    'local_receipt_sequence',
  ]) {
    db.run(`DELETE FROM ${table}`);
  }
}

function transactionV2Input(): PendingTransactionInputV2 {
  return {
    type: 'BUY',
    currencyCode: 'EUR',
    foreignAmount: 100,
    hufAmount: 40000,
    roundedHufAmount: 40000,
    rate: 400,
    handlingFee: null,
    discountPercent: null,
    customerIdentifier: null,
    customerName: null,
    customerDocumentNumber: null,
    customerAddress: null,
    denominations: null,
    foreignStatus: null,
    customerBirthPlace: null,
    customerBirthDate: null,
    customerMotherName: null,
    customerNationality: null,
    customerDocumentType: null,
    sourceOfFunds: null,
    customerIsPep: null,
    approverWorkerId: null,
    approvalSessionId: null,
    customerOnOwnBehalf: null,
    customerActorName: null,
    customerPepKind: null,
    customerActorBirthPlace: null,
    customerActorBirthDate: null,
    customerActorMotherName: null,
    customerActorNationality: null,
    customerActorDocumentType: null,
    customerActorDocumentNumber: null,
    customerActorAddress: null,
  };
}

function conversionV2Input(): PendingConversionInputV2 {
  return {
    fromCurrencyId: 1,
    fromCurrencyCode: 'EUR',
    toCurrencyId: 2,
    toCurrencyCode: 'USD',
    fromAmount: 100,
    calculatedHufAmount: 40000,
    calculatedToAmount: 110,
    conversionRate: 1.1,
    handlingFee: null,
    customerId: null,
    customerName: null,
    customerDocumentNumber: null,
    customerAddress: null,
    customerNationality: null,
    customerBirthPlace: null,
    customerBirthDate: null,
    customerMotherName: null,
    customerDocumentType: null,
    sourceOfFunds: null,
    customerIsPep: null,
    approverWorkerId: null,
    approvalSessionId: null,
    customerOnOwnBehalf: null,
    customerActorName: null,
    customerPepKind: null,
    customerActorBirthPlace: null,
    customerActorBirthDate: null,
    customerActorMotherName: null,
    customerActorNationality: null,
    customerActorDocumentType: null,
    customerActorDocumentNumber: null,
    customerActorAddress: null,
    foreignStatus: null,
    note: null,
  };
}

describe('sqlite pending outbox company_code stamping', () => {
  beforeAll(async () => {
    mockState.tempHome = fs.mkdtempSync(path.join(os.tmpdir(), 'valuta-company-stamping-'));
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

  it('stamps savePendingTransaction rows with the active company code', () => {
    savePendingTransaction(
      'SELL',
      'EUR',
      100,
      40000,
      40000,
      400,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
    );

    expect(latestCompanyCodeFor('pending_transactions')).toBe('BC');
  });

  it('stamps savePendingTransactionV2 rows with the active company code', () => {
    savePendingTransactionV2(transactionV2Input());

    expect(latestCompanyCodeFor('pending_transactions')).toBe('BC');
  });

  it('stamps savePendingConversion and savePendingConversionV2 rows with the active company code', () => {
    savePendingConversion(1, 'EUR', 2, 'USD', 100, 40000, 110, 1.1, null, null, null, null, null);
    expect(latestCompanyCodeFor('pending_conversions')).toBe('BC');

    savePendingConversionV2(conversionV2Input());
    expect(latestCompanyCodeFor('pending_conversions')).toBe('BC');
  });

  it('stamps savePendingTransfer rows with the active company code', () => {
    savePendingTransfer(null, '106', 1, 'EUR', 100, 40000, 'OUT', null, null);

    expect(latestCompanyCodeFor('pending_transfers')).toBe('BC');
  });

  it('does not throw and stores NULL when bootstrap_company_code is missing', () => {
    deleteConfig('bootstrap_company_code');

    savePendingTransaction(
      'BUY',
      'USD',
      50,
      18000,
      18000,
      360,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
    );

    expect(latestCompanyCodeFor('pending_transactions')).toBeNull();
  });
});
