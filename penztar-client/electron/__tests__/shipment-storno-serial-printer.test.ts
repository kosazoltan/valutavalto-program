import { describe, expect, it, vi } from 'vitest';

vi.mock('electron', () => ({ BrowserWindow: vi.fn() }));
vi.mock('electron-log/main', () => ({
  default: { info: vi.fn(), warn: vi.fn(), error: vi.fn(), debug: vi.fn() },
}));

import { buildReceiptForSerial } from '../serial-printer';

describe('Shipment sztornó — soros nyomtatási sablon', () => {
  it('az autoritatív actor/time/ok és mindkét aláíráshely rákerül a blokknyomtató kimenetére', () => {
    const output = buildReceiptForSerial({
      type: 'transfer',
      companyType: 'BEST_CHANGE',
      receiptNumber: 'FF-000123-SZ',
      branchCode: 'Szeged Ertektar',
      cashierName: 'Kosa Zoltan',
      date: '2026. 07. 18.',
      time: '11:30:00',
      transferTarget: 'Szeged Tisza Sarok',
      transferDocType: 'handover',
      isStorno: true,
      stornoReason: 'Kuldoi storno atvetel elott',
      currencyCode: 'HUF',
      foreignAmount: 125000,
    });

    const ascii = output.toString('latin1');
    expect(ascii).toContain('SZTORN');
    expect(ascii).toContain('FF-000123-SZ');
    expect(ascii).toContain('Kosa Zoltan');
    expect(ascii).toContain('2026. 07. 18.');
    expect(ascii).toContain('11:30:00');
    expect(ascii).toContain('Kuldoi storno atvetel elott');
    expect(output.includes(Buffer.from([0xb5, 0x74, 0x61, 0x64, 0xa2]))).toBe(true); // Átadó
    expect(output.includes(Buffer.from([0xb5, 0x74, 0x76, 0x65, 0x76, 0x8b]))).toBe(true); // Átvevő
  });
});
