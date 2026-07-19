import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const state = vi.hoisted(() => ({ tempHome: '' }));

vi.mock('electron', () => ({
  app: {
    getPath: vi.fn(() => state.tempHome),
    getAppPath: vi.fn(() => state.tempHome),
    isPackaged: false,
  },
}));

import {
  deleteConfig,
  getDb,
  getPendingShipmentReceipts,
  getShipmentReceiptOutboxState,
  initDatabase,
  markShipmentReceiptTerminalError,
  savePendingShipmentReceipt,
  setConfig,
} from '../sqlite';

describe('pending_shipment_receipts SQLite outbox', () => {
  beforeAll(async () => {
    state.tempHome = fs.mkdtempSync(path.join(os.tmpdir(), 'shipment-receipt-outbox-'));
    await initDatabase();
  });

  beforeEach(() => {
    getDb()?.run('DELETE FROM pending_shipment_receipts');
    setConfig('bootstrap_company_code', 'BEST_CHANGE');
  });

  afterAll(() => fs.rmSync(state.tempHome, { recursive: true, force: true }));

  it('stabil kulccsal és aktív cégbélyeggel menti az átvételi szándékot', () => {
    const idempotencyKey = '33333333-3333-4333-8333-333333333333';
    const id = savePendingShipmentReceipt({
      shipmentId: '11111111-1111-4111-8111-111111111111',
      requestNumber: 'FF-000011',
      branchId: '22222222-2222-4222-8222-222222222222',
      workerId: 42,
      idempotencyKey,
    });

    const [saved] = getPendingShipmentReceipts();
    expect(saved).toMatchObject({
      id,
      shipment_id: '11111111-1111-4111-8111-111111111111',
      request_number: 'FF-000011',
      branch_id: '22222222-2222-4222-8222-222222222222',
      worker_id: 42,
      company_code: 'BEST_CHANGE',
      idempotency_key: idempotencyKey,
      synced: 0,
    });
  });

  it('ugyanarra a nem szinkronizált Shipmentre nem enged második sort', () => {
    const input = {
      shipmentId: '11111111-1111-4111-8111-111111111111',
      requestNumber: 'FF-000011',
      branchId: '22222222-2222-4222-8222-222222222222',
      workerId: 42,
      idempotencyKey: '33333333-3333-4333-8333-333333333333',
    };
    savePendingShipmentReceipt(input);

    expect(() => savePendingShipmentReceipt(input)).toThrow('már van szinkronra váró');
    expect(getPendingShipmentReceipts()).toHaveLength(1);
  });

  it('hibás IPC payloadot és hiányzó tenant-bélyeget fail-closed elutasít', () => {
    expect(() =>
      savePendingShipmentReceipt({
        shipmentId: '../not-a-uuid',
        requestNumber: 'FF-000011',
        branchId: 'bad-branch',
        workerId: 0,
        idempotencyKey: 'bad-key',
      }),
    ).toThrow('Érvénytelen');

    deleteConfig('bootstrap_company_code');
    expect(() =>
      savePendingShipmentReceipt({
        shipmentId: '11111111-1111-4111-8111-111111111111',
        requestNumber: 'FF-000011',
        branchId: '22222222-2222-4222-8222-222222222222',
        workerId: 42,
        idempotencyKey: '33333333-3333-4333-8333-333333333333',
      }),
    ).toThrow('cégkód');
    expect(getPendingShipmentReceipts()).toHaveLength(0);
  });

  it('nem bízik a TypeScript típusokban az IPC-határon és a kontrollkaraktert is tiltja', () => {
    const validInput = {
      shipmentId: '11111111-1111-4111-8111-111111111111',
      requestNumber: 'FF-000011',
      branchId: '22222222-2222-4222-8222-222222222222',
      workerId: 42,
      idempotencyKey: '33333333-3333-4333-8333-333333333333',
    };

    expect(() =>
      savePendingShipmentReceipt({
        ...validInput,
        shipmentId: { toString: () => validInput.shipmentId } as unknown as string,
      }),
    ).toThrow('Érvénytelen Shipment-átvételi azonosító');
    for (const control of ['\u0000', '\t', '\n', '\u001f']) {
      expect(() =>
        savePendingShipmentReceipt({ ...validInput, requestNumber: `FF-000011${control}` }),
      ).toThrow('Érvénytelen Shipment bizonylatszám');
    }
    expect(getPendingShipmentReceipts()).toHaveLength(0);
  });

  it('cégváltás után sem pending, sem terminális sor nem szivárog át az IPC getterbe', () => {
    const id = savePendingShipmentReceipt({
      shipmentId: '11111111-1111-4111-8111-111111111111',
      requestNumber: 'FF-000011',
      branchId: '22222222-2222-4222-8222-222222222222',
      workerId: 42,
      idempotencyKey: '33333333-3333-4333-8333-333333333333',
    });
    markShipmentReceiptTerminalError(id, 'A küldő sztornózta a tételt.');
    setConfig('bootstrap_company_code', 'OTHER_COMPANY');

    expect(getPendingShipmentReceipts()).toEqual([]);
    expect(getShipmentReceiptOutboxState()).toEqual([]);
  });

  it('a terminális üzleti hiba újrapróbálás nélkül, tartósan látható marad', () => {
    const id = savePendingShipmentReceipt({
      shipmentId: '11111111-1111-4111-8111-111111111111',
      requestNumber: 'FF-000011',
      branchId: '22222222-2222-4222-8222-222222222222',
      workerId: 42,
      idempotencyKey: '33333333-3333-4333-8333-333333333333',
    });

    markShipmentReceiptTerminalError(id, 'A küldő sztornózta a tételt.');

    expect(getPendingShipmentReceipts()).toHaveLength(0);
    expect(getShipmentReceiptOutboxState()).toContainEqual(
      expect.objectContaining({
        id,
        synced: 1,
        sync_error: 'A küldő sztornózta a tételt.',
      }),
    );
  });
});
