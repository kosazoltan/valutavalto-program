/**
 * printer.ts unit tests — receipt content generation, formatting, HTML output.
 *
 * generateReceiptContent() and the formatting functions are pure — they don't
 * need electron at runtime (only BrowserWindow is used in printViaElectron).
 * We mock electron and test the content generators.
 */
import { describe, it, expect, vi } from 'vitest';

// Mock electron before importing printer
vi.mock('electron', () => ({
  BrowserWindow: vi.fn().mockImplementation(() => ({
    loadURL: vi.fn().mockResolvedValue(undefined),
    webContents: {
      print: vi.fn((_opts: unknown, cb: (success: boolean, reason?: string) => void) => cb(true)),
    },
    isDestroyed: vi.fn(() => false),
    close: vi.fn(),
    show: false,
  })),
}));

vi.mock('electron-log/main', () => ({
  default: {
    info: vi.fn(),
    warn: vi.fn(),
    error: vi.fn(),
  },
}));

import {
  generateReceiptContent,
  printReceipt,
  type PrintReceiptData,
  type ClosingPrintData,
} from '../printer';

const baseData: PrintReceiptData = {
  type: 'sell',
  companyType: 'BEST_CHANGE',
  receiptNumber: 'BC-2026-001',
  branchCode: 'SZG-01',
  cashierName: 'Teszt Erika',
  date: '2026.03.24',
  time: '14:30',
  currencyCode: 'EUR',
  foreignAmount: 100,
  rate: 400,
  hufAmount: 40000,
  roundedHufAmount: 40000,
};

describe('printer — generateReceiptContent (ESC/POS)', () => {
  it('should include company name for BEST_CHANGE', () => {
    const content = generateReceiptContent(baseData);
    expect(content).toContain('BEST CHANGE');
    expect(content).toContain('EXCLUSIVE BEST CHANGE ZRT.');
    expect(content).toContain('32313332-2-02');
  });

  it('should include company name for EXPRESSZ', () => {
    const content = generateReceiptContent({
      ...baseData,
      companyType: 'EXPRESSZ',
    });
    expect(content).toContain('EXPRESSZ');
    expect(content).toContain('EXPRESSZ ÉKSZERHÁZ ÉS MINIBANK KFT.');
    expect(content).toContain('14040535-2-02');
  });

  it('should include receipt number', () => {
    const content = generateReceiptContent(baseData);
    expect(content).toContain('BC-2026-001');
  });

  it('should include cashier name', () => {
    const content = generateReceiptContent(baseData);
    expect(content).toContain('Teszt Erika');
  });

  it('should include branch code', () => {
    const content = generateReceiptContent(baseData);
    expect(content).toContain('SZG-01');
  });

  it('should include date and time', () => {
    const content = generateReceiptContent(baseData);
    expect(content).toContain('2026.03.24');
    expect(content).toContain('14:30');
  });

  it('should show ELADÁSI BIZONYLAT for sell type', () => {
    const content = generateReceiptContent(baseData);
    expect(content).toContain('ELADÁSI BIZONYLAT');
  });

  it('should show VÁSÁRLÁSI BIZONYLAT for buy type', () => {
    const content = generateReceiptContent({ ...baseData, type: 'buy' });
    expect(content).toContain('VÁSÁRLÁSI BIZONYLAT');
  });

  it('should show STORNÓ BIZONYLAT for storno type', () => {
    const content = generateReceiptContent({
      ...baseData,
      type: 'storno',
      stornoReason: 'Hibás összeg',
      originalReceiptNumber: 'BC-2026-000',
    });
    expect(content).toContain('STORNÓ BIZONYLAT');
    expect(content).toContain('Hibás összeg');
    expect(content).toContain('BC-2026-000');
  });

  it('should show KONVERZIÓS BIZONYLAT for conversion type', () => {
    const content = generateReceiptContent({
      ...baseData,
      type: 'conversion',
      sourceCurrencyCode: 'EUR',
      sourceAmount: 100,
      targetCurrencyCode: 'USD',
      targetAmount: 110,
    });
    expect(content).toContain('KONVERZIÓS BIZONYLAT');
    expect(content).toContain('EUR');
    expect(content).toContain('USD');
  });

  it('should show NAPI ZÁRÁS for closing type', () => {
    const closingData: ClosingPrintData = {
      totalTransactions: 25,
      sellCount: 15,
      buyCount: 10,
      totalHufTurnover: 5_000_000,
      totalFees: 25_000,
      openingBalance: 1_000_000,
      closingBalance: 1_200_000,
      discrepancies: [],
    };
    const content = generateReceiptContent({
      ...baseData,
      type: 'closing',
      closingSummary: closingData,
    });
    expect(content).toContain('NAPI ZÁRÁS');
    expect(content).toContain('25');
    expect(content).toContain('15');
    expect(content).toContain('10');
  });

  it('should include currency code and amounts', () => {
    const content = generateReceiptContent(baseData);
    expect(content).toContain('EUR');
    // formatAmount uses hu-HU locale
    expect(content).toContain('FIZETENDŐ');
  });

  it('should include customer data when present', () => {
    const content = generateReceiptContent({
      ...baseData,
      customerName: 'Kovács János',
      customerDocType: 'Személyi ig.',
      customerDocNumber: '123456AB',
    });
    expect(content).toContain('ÜGYFÉL ADATOK');
    expect(content).toContain('Kovács János');
    expect(content).toContain('Személyi ig.');
    expect(content).toContain('123456AB');
  });

  it('should not include customer section when no customer', () => {
    const content = generateReceiptContent(baseData);
    expect(content).not.toContain('ÜGYFÉL ADATOK');
  });

  it('should include rounding information when present', () => {
    const content = generateReceiptContent({
      ...baseData,
      hufAmount: 39997,
      roundedHufAmount: 40000,
      roundingDiff: 3,
    });
    expect(content).toContain('Kerekítés');
    expect(content).toContain('FIZETENDŐ');
  });

  it('should list ALL currency lines under a SINGLE receipt number for a multi-line aggregate', () => {
    // Multi-line aggregate (2026-06-04): egy bizonylatszám, több valuta-sor, összegzett+egyszer kerekített végösszeg.
    const content = generateReceiptContent({
      ...baseData,
      currencyCode: undefined,
      foreignAmount: undefined,
      rate: undefined,
      receiptNumber: 'BC-2026-AGG',
      hufAmount: 70000,
      roundedHufAmount: 70000,
      roundingDiff: 0,
      transactionLines: [
        { currencyCode: 'EUR', foreignAmount: 100, rate: 400, hufAmount: 40000 },
        { currencyCode: 'USD', foreignAmount: 100, rate: 300, hufAmount: 30000 },
      ],
    });
    // Mindkét valuta-sor szerepel
    expect(content).toContain('EUR');
    expect(content).toContain('USD');
    // EGY bizonylatszám-fejléc az egész aggregátumra (nincs per-soros álszám)
    expect(content.match(/Bizonylat: BC-2026-AGG/g)?.length ?? 0).toBe(1);
    // Az összegzett végösszeg jelenik meg
    expect(content).toContain('FIZETENDŐ');
  });

  it('should include footer text', () => {
    const content = generateReceiptContent(baseData);
    expect(content).toContain('Köszönjük, hogy minket választott!');
  });

  it('should include ESC/POS init command', () => {
    const content = generateReceiptContent(baseData);
    // ESC@ is the init sequence
    expect(content).toContain('\x1B@');
  });

  it('should include paper cut command', () => {
    const content = generateReceiptContent(baseData);
    // GS V 01 = partial cut
    expect(content).toContain('\x1DV\x01');
  });

  it('should show discrepancies in closing receipt', () => {
    const content = generateReceiptContent({
      ...baseData,
      type: 'closing',
      closingSummary: {
        totalTransactions: 5,
        sellCount: 3,
        buyCount: 2,
        totalHufTurnover: 500_000,
        totalFees: 5_000,
        openingBalance: 100_000,
        closingBalance: 120_000,
        discrepancies: [
          { currencyCode: 'EUR', expected: 500, actual: 495, difference: -5 },
        ],
      },
    });
    expect(content).toContain('ELTÉRÉSEK');
    expect(content).toContain('EUR');
  });

  it('should include QR code section for sell/buy/conversion', () => {
    const content = generateReceiptContent(baseData);
    expect(content).toContain('QR KÓD');
    expect(content).toContain('[QR:');
    // QR content format: receiptNumber|date|amount|currency|taxNumber|branchCode
    expect(content).toContain('BC-2026-001|2026.03.24|40000|EUR|32313332-2-02|SZG-01');
  });

  it('should show transfer details', () => {
    const content = generateReceiptContent({
      ...baseData,
      type: 'transfer',
      transferTarget: 'SZG-02',
      transferNote: 'Napi készlet feltöltés',
    });
    expect(content).toContain('ÁTADÁS-ÁTVÉTELI BIZONYLAT');
    expect(content).toContain('SZG-02');
    expect(content).toContain('Napi készlet feltöltés');
  });

  it('should print carrier name and seal number on transfer receipt (FR-5)', () => {
    const content = generateReceiptContent({
      ...baseData,
      type: 'transfer',
      transferTarget: 'SZG-02',
      carrierName: "Brink's Hungary Kft.",
      sealNumber: 'ABC/12-3',
    });
    expect(content).toContain('Szállító');
    expect(content).toContain("Brink's Hungary Kft.");
    expect(content).toContain('Plombaszám');
    expect(content).toContain('ABC/12-3');
  });

  it('should print requesting office + forintosított value on transfer receipt (FR-2/NFR-3)', () => {
    const content = generateReceiptContent({
      ...baseData,
      type: 'transfer',
      branchCode: 'BR050 - Debrecen Értéktár',
      transferTarget: 'BR060 - Debrecen Tesco',
      currencyCode: 'EUR',
      foreignAmount: 1000,
      roundedHufAmount: 405000,
      deliveryDate: '2026. 06. 05.',
    });
    expect(content).toContain('Kérő iroda');
    expect(content).toContain('BR050 - Debrecen Értéktár');
    expect(content).toContain('Cél iroda');
    expect(content).toContain('Forint érték');
    expect(content).toContain('Kézbesítési dátum');
    expect(content).toContain('2026. 06. 05.');
    // 5 Ft-ra kerekített forintosított érték (hu-HU ezres tagolás, NBSP-toleráns)
    expect(content.replace(/\s/g, '')).toContain('405000HUF');
  });

  it('transfer receipt always shows Kérő iroda + Cél iroda (FR-2 kötelező, „—" fallback)', () => {
    const content = generateReceiptContent({ ...baseData, type: 'transfer', branchCode: '', transferTarget: '' });
    expect(content).toContain('Kérő iroda');
    expect(content).toContain('Cél iroda');
    expect(content).toContain('—');
  });

  it('transfer receipt uses Átadó/Átvevő + Ügyintéző labels (preview parity, no Pénztáros/Ügyfél)', () => {
    const content = generateReceiptContent({
      ...baseData,
      type: 'transfer',
      branchCode: 'BR050 - Debrecen Értéktár',
      transferTarget: 'BR060 - Debrecen Tesco',
      cashierName: 'Bali Henriett',
    });
    expect(content).toContain('Ügyintéző:');
    expect(content).toContain('Átadó');
    expect(content).toContain('Átvevő');
    expect(content).not.toContain('Pénztáros');
    expect(content).not.toContain('Ügyfél');
  });

  it('non-transfer (sell) receipt keeps Pénztáros/Ügyfél labels (no regression)', () => {
    const content = generateReceiptContent({ ...baseData, type: 'sell' });
    expect(content).toContain('Pénztáros');
    expect(content).toContain('Ügyfél');
  });
});

describe('printer — printReceipt', () => {
  it('should return boolean result', async () => {
    // printToThermalUsb returns false (stub), then printViaElectron is called
    const result = await printReceipt(baseData);
    expect(typeof result).toBe('boolean');
  });

  it('should accept optional printerName', async () => {
    const result = await printReceipt(baseData, 'EPSON TM-T88V');
    expect(typeof result).toBe('boolean');
  });
});

describe('printer — formatAmount edge cases', () => {
  it('should handle undefined amounts gracefully in receipt', () => {
    const content = generateReceiptContent({
      ...baseData,
      foreignAmount: undefined,
      hufAmount: undefined,
    });
    // formatAmount returns '—' for undefined
    expect(content).toContain('—');
  });
});
