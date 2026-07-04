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
  getDb,
  initDatabase,
  queueStocktakeCount,
  saveLocalAuditEvent,
  savePendingBankTransaction,
  savePendingCollection,
  savePendingConversion,
  savePendingConversionV2,
  savePendingDistribution,
  savePendingHandoverOperation,
  savePendingStorno,
  savePendingTransaction,
  savePendingTransactionV2,
  savePendingTransfer,
  savePendingTransferStorno,
  setConfig,
  type PendingConversionInputV2,
  type PendingTransactionInputV2,
} from '../sqlite';

function resetPendingTables(): void {
  const db = getDb();
  if (!db) throw new Error('Database not initialized');
  for (const table of [
    'pending_transactions',
    'pending_conversions',
    'pending_bank_transactions',
    'pending_stornos',
    'pending_transfer_stornos',
    'pending_handover_operations',
    'pending_distributions',
    'pending_collections',
    'pending_transfers',
    'pending_stocktake_items',
    'local_audit_events',
    'local_receipt_sequence',
  ]) {
    db.run(`DELETE FROM ${table}`);
  }
}

function expectReturnedIdMatchesRow(returnedId: number, table: string): void {
  expect(returnedId).toBeGreaterThan(0);
  const db = getDb();
  if (!db) throw new Error('Database not initialized');
  const stmt = db.prepare(`SELECT MAX(id) as id FROM ${table}`);
  stmt.step();
  const row = stmt.getAsObject() as { id?: number | null };
  stmt.free();
  expect(returnedId).toBe(row.id);
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

describe('sqlite save pending functions return inserted rowid', () => {
  beforeAll(async () => {
    mockState.tempHome = fs.mkdtempSync(path.join(os.tmpdir(), 'valuta-save-return-id-'));
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

  it('saveLocalAuditEvent returns the inserted local_audit_events rowid', () => {
    const returnedId = saveLocalAuditEvent({
      entityType: 'TEST_ENTITY',
      eventType: 'CREATE',
      payload: { ok: true },
    });

    expectReturnedIdMatchesRow(returnedId, 'local_audit_events');
  });

  it('savePendingTransaction returns the inserted pending_transactions rowid', () => {
    const returnedId = savePendingTransaction(
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

    expectReturnedIdMatchesRow(returnedId, 'pending_transactions');
  });

  it('savePendingTransactionV2 returns the inserted pending_transactions rowid', () => {
    const returnedId = savePendingTransactionV2(transactionV2Input());

    expectReturnedIdMatchesRow(returnedId, 'pending_transactions');
  });

  it('savePendingConversion returns the inserted pending_conversions rowid', () => {
    const returnedId = savePendingConversion(
      1,
      'EUR',
      2,
      'USD',
      100,
      40000,
      110,
      1.1,
      null,
      null,
      null,
      null,
      null,
    );

    expectReturnedIdMatchesRow(returnedId, 'pending_conversions');
  });

  it('savePendingConversionV2 returns the inserted pending_conversions rowid', () => {
    const returnedId = savePendingConversionV2(conversionV2Input());

    expectReturnedIdMatchesRow(returnedId, 'pending_conversions');
  });

  it('savePendingDistribution returns the inserted pending_distributions rowid', () => {
    const returnedId = savePendingDistribution('105', 'EUR', 100, null, null);

    expectReturnedIdMatchesRow(returnedId, 'pending_distributions');
  });

  it('savePendingTransfer returns the inserted pending_transfers rowid', () => {
    const returnedId = savePendingTransfer(null, '106', 1, 'EUR', 100, 40000, 'OUT', null, null);

    expectReturnedIdMatchesRow(returnedId, 'pending_transfers');
  });

  it('savePendingCollection returns the inserted pending_collections rowid', () => {
    const returnedId = savePendingCollection('105', 'EUR', 100, null);

    expectReturnedIdMatchesRow(returnedId, 'pending_collections');
  });

  it('savePendingBankTransaction returns the inserted pending_bank_transactions rowid', () => {
    const returnedId = savePendingBankTransaction(
      'BUY',
      'EUR',
      100,
      395.5,
      39550,
      null,
      null,
      null,
      null,
    );

    expectReturnedIdMatchesRow(returnedId, 'pending_bank_transactions');
  });

  it('savePendingStorno returns the inserted pending_stornos rowid', () => {
    const returnedId = savePendingStorno({
      transactionId: 1,
      originalReceiptNumber: 'R-1',
      originalTransactionType: 'BUY',
      currencyCode: 'EUR',
      foreignAmount: 100,
      hufAmount: 39550,
      exchangeRate: 395.5,
      reason: 'teszt',
    });

    expectReturnedIdMatchesRow(returnedId, 'pending_stornos');
  });

  it('savePendingTransferStorno returns the inserted pending_transfer_stornos rowid', () => {
    const returnedId = savePendingTransferStorno({ transferId: 1, reason: 'teszt' });

    expectReturnedIdMatchesRow(returnedId, 'pending_transfer_stornos');
  });

  it('savePendingHandoverOperation returns the inserted pending_handover_operations rowid', () => {
    const returnedId = savePendingHandoverOperation({ operationType: 'GENERATE' });

    expectReturnedIdMatchesRow(returnedId, 'pending_handover_operations');
  });

  it('queueStocktakeCount returns the inserted pending_stocktake_items rowid', () => {
    const returnedId = queueStocktakeCount('item-uuid-1', 5, null, 'idem-1');

    expectReturnedIdMatchesRow(returnedId, 'pending_stocktake_items');
  });

  it('savePendingTransaction returns strictly increasing rowids for consecutive inserts', () => {
    const firstId = savePendingTransaction(
      'BUY',
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
    const secondId = savePendingTransaction(
      'SELL',
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

    expect(firstId).toBeGreaterThan(0);
    expect(secondId).toBeGreaterThan(firstId);
  });
});
