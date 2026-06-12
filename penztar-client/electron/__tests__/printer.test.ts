/**
 * printer.ts unit tests — receipt content generation, formatting, HTML output.
 *
 * generateReceiptContent() and the formatting functions are pure — they don't
 * need electron at runtime (only BrowserWindow is used in printViaElectron).
 * We mock electron and test the content generators.
 */
import { describe, it, expect, vi, beforeEach, type Mock } from 'vitest';
import { BrowserWindow } from 'electron';

// Mock electron before importing printer.
// FONTOS: `function` kell (nem arrow), mert a printer `new BrowserWindow(...)`-t hív,
// és az arrow function nem konstruktor (Vitest: "is not a constructor" → silent false).
vi.mock('electron', () => ({
  BrowserWindow: vi.fn().mockImplementation(function () {
    return {
      loadURL: vi.fn().mockResolvedValue(undefined),
      webContents: {
        print: vi.fn((_opts: unknown, cb: (success: boolean, reason?: string) => void) => cb(true)),
      },
      isDestroyed: vi.fn(() => false),
      close: vi.fn(),
      show: false,
    };
  }),
}));

vi.mock('electron-log/main', () => ({
  default: {
    info: vi.fn(),
    warn: vi.fn(),
    error: vi.fn(),
  },
}));

// Soros nyomtató mock — a részleges soros hiba (FR-7 fallback) tesztekhez vezérelhető.
vi.mock('../serial-printer', () => ({
  printReceiptToSerial: vi.fn().mockResolvedValue(false),
}));

import { printReceiptToSerial } from '../serial-printer';

import {
  generateReceiptContent,
  generateReceiptHtml,
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

  it('should show MEGSZAKÍTOTT TRANZAKCIÓ with no financial effect for cancelled transaction type', () => {
    const content = generateReceiptContent({
      ...baseData,
      type: 'cancelled_transaction',
      hufAmount: 70000,
      roundedHufAmount: 70000,
      stornoReason: 'MEGSEM',
      note: 'Pénzmozgás nem történt. Mód: SELL.',
      transactionLines: [
        { currencyCode: 'EUR', foreignAmount: 100, rate: 400, hufAmount: 40000 },
        { currencyCode: 'USD', foreignAmount: 100, rate: 300, hufAmount: 30000 },
      ],
    });
    expect(content).toContain('MEGSZAKÍTOTT TRANZAKCIÓ');
    expect(content).toContain('Pénzmozgás nem történt.');
    expect(content).toContain('EUR');
    expect(content).toContain('USD');
    expect(content).toContain('MEGSEM');
    expect(content.replace(/\s/g, '')).toContain('70000Ft');
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
      transferDocType: 'handover',
      transferTarget: 'SZG-02',
      transferNote: 'Napi készlet feltöltés',
    });
    expect(content).toContain('ÁTADÁSI BIZONYLAT');
    expect(content).toContain('SZG-02');
    expect(content).toContain('Napi készlet feltöltés');
  });

  it('should show receipt transfer title and vault address', () => {
    const content = generateReceiptContent({
      ...baseData,
      type: 'transfer',
      transferDocType: 'receipt',
      vaultAddress: 'Szeged, Hajnóczy u. 57., 6722',
      transferTarget: 'SZG-02',
    });
    expect(content).toContain('ÁTVÉTELI BIZONYLAT');
    expect(content).toContain('Szeged, Hajnóczy u. 57., 6722');
  });

  it('should print transfer denominations only when provided', () => {
    const withoutDenominations = generateReceiptContent({
      ...baseData,
      type: 'transfer',
      transferDocType: 'handover',
      transferTarget: 'SZG-02',
    });
    expect(withoutDenominations).not.toContain('Címletezés');

    const withDenominations = generateReceiptContent({
      ...baseData,
      type: 'transfer',
      transferDocType: 'handover',
      transferTarget: 'SZG-02',
      denominations: [
        { quantity: 2, faceValue: 100 },
        { quantity: 3, faceValue: 50 },
      ],
    });
    expect(withDenominations).toContain('Címletezés');
    expect(withDenominations).toContain('2 x 100');
    expect(withDenominations).toContain('3 x 50');
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

  // === Fejléc-javítás 2026-06-11 (FR-1..FR-7) ===

  it('fejléc-javítás FR-1/FR-3: transfer bizonylaton hiányzó vaultAddress esetén NINCS hardcode-olt székhelycím', () => {
    const content = generateReceiptContent({
      ...baseData,
      type: 'transfer',
      transferDocType: 'handover',
      transferTarget: 'SZG-02',
    });
    expect(content).not.toContain('Kárász');
  });

  it('fejléc-javítás FR-2: transfer bizonylaton a vaultPhone jelenik meg, NEM a hardcode-olt cég-telefonszám', () => {
    const content = generateReceiptContent({
      ...baseData,
      type: 'transfer',
      transferDocType: 'handover',
      transferTarget: 'SZG-02',
      vaultPhone: '06-62-123-456',
    });
    expect(content).toContain('Tel: 06-62-123-456');
    expect(content).not.toContain('06703800161');
  });

  it('fejléc-javítás TBD-3: transfer bizonylaton hiányzó vaultPhone esetén NINCS telefon sor', () => {
    const content = generateReceiptContent({
      ...baseData,
      type: 'transfer',
      transferDocType: 'handover',
      transferTarget: 'SZG-02',
    });
    expect(content).not.toContain('Tel:');
  });

  it('non-transfer (sell) bizonylaton a cég-székhelycím és telefonszám változatlanul megjelenik (no regression)', () => {
    const content = generateReceiptContent(baseData);
    expect(content).toContain('Szeged, Kárász u. 5.');
    expect(content).toContain('Tel: 06703800161');
  });

  it('fejléc-javítás FR-5: átvételi bizonylaton megjelenik a kötelező jogi nyilatkozat', () => {
    const content = generateReceiptContent({
      ...baseData,
      type: 'transfer',
      transferDocType: 'receipt',
      transferTarget: 'SZG-02',
    });
    expect(content).toContain('Büntetőjogi felelősségem tudatában,');
    expect(content).toContain('pénzkészletet a szállítóktól átvettem,');
    expect(content).toContain('azt tökéletesen átszámoltam.');
  });

  it('fejléc-javítás FR-5: átadási bizonylaton a jogi nyilatkozat NEM jelenik meg', () => {
    const content = generateReceiptContent({
      ...baseData,
      type: 'transfer',
      transferDocType: 'handover',
      transferTarget: 'SZG-02',
    });
    expect(content).not.toContain('Büntetőjogi felelősségem tudatában');
  });

  it('fejléc-javítás FR-5: sztornó bizonylaton a jogi nyilatkozat NEM jelenik meg (átvételi irány esetén sem)', () => {
    const content = generateReceiptContent({
      ...baseData,
      type: 'transfer',
      transferDocType: 'receipt',
      isStorno: true,
      stornoReason: 'Téves rögzítés',
      transferTarget: 'SZG-02',
    });
    expect(content).not.toContain('Büntetőjogi felelősségem tudatában');
  });

  it('fejléc-javítás FR-6: átvételi bizonylaton a nyilatkozat UTÁN következnek az Átadó/Átvevő aláírás sorok', () => {
    const content = generateReceiptContent({
      ...baseData,
      type: 'transfer',
      transferDocType: 'receipt',
      transferTarget: 'SZG-02',
    });
    const declarationIdx = content.indexOf('Büntetőjogi felelősségem tudatában,');
    const signatureIdx = content.indexOf('  Átadó                Átvevő');
    expect(declarationIdx).toBeGreaterThan(-1);
    expect(signatureIdx).toBeGreaterThan(declarationIdx);
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

describe('printer — fejléc-javítás FR-7: HUF transfer dupla példány', () => {
  beforeEach(() => {
    (BrowserWindow as unknown as Mock).mockClear();
  });

  it('HUF valutanemű transfer bizonylat KÉT példányban nyomtat', async () => {
    const result = await printReceipt({
      ...baseData,
      type: 'transfer',
      transferDocType: 'handover',
      currencyCode: 'HUF',
      transferTarget: 'SZG-02',
    });
    expect(result).toBe(true);
    expect((BrowserWindow as unknown as Mock).mock.calls.length).toBe(2);
  });

  it('deviza (EUR) transfer bizonylat EGY példányban nyomtat', async () => {
    const result = await printReceipt({
      ...baseData,
      type: 'transfer',
      transferDocType: 'receipt',
      currencyCode: 'EUR',
      transferTarget: 'SZG-02',
    });
    expect(result).toBe(true);
    expect((BrowserWindow as unknown as Mock).mock.calls.length).toBe(1);
  });

  it('nem-transfer (sell) HUF-os bizonylat EGY példányban nyomtat (a dupla szabály csak transferre vonatkozik)', async () => {
    const result = await printReceipt({ ...baseData, type: 'sell', currencyCode: 'HUF' });
    expect(result).toBe(true);
    expect((BrowserWindow as unknown as Mock).mock.calls.length).toBe(1);
  });

  it('részleges soros hiba: 1 soros példány OK + 2. hibás → fallback csak a MARADÉK 1 példányt nyomtatja (összesen 2, nem 3)', async () => {
    (printReceiptToSerial as Mock)
      .mockResolvedValueOnce(true)
      .mockResolvedValueOnce(false);
    const result = await printReceipt(
      { ...baseData, type: 'transfer', transferDocType: 'handover', currencyCode: 'HUF', transferTarget: 'SZG-02' },
      undefined,
      'COM3',
    );
    expect(result).toBe(true);
    expect((printReceiptToSerial as Mock).mock.calls.length).toBe(2);
    // Electron fallback csak a hiányzó 1 példányra fut, nem mind a 2-re
    expect((BrowserWindow as unknown as Mock).mock.calls.length).toBe(1);
  });

  it('teljes soros siker: 2 soros példány OK → nincs Electron fallback', async () => {
    (printReceiptToSerial as Mock)
      .mockResolvedValueOnce(true)
      .mockResolvedValueOnce(true);
    const result = await printReceipt(
      { ...baseData, type: 'transfer', transferDocType: 'handover', currencyCode: 'HUF', transferTarget: 'SZG-02' },
      undefined,
      'COM3',
    );
    expect(result).toBe(true);
    expect((BrowserWindow as unknown as Mock).mock.calls.length).toBe(0);
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

// ============================================================================
// Penztar-batch C.1/C.2 (2026-06-12, user-kérés): deviza-státusz + Pmt.-nyilatkozatok
// ============================================================================
describe('printer — deviza-státusz + 300k+ nyilatkozatok (C.1/C.2)', () => {
  it('deviza-státusz sor MINDEN vétel/eladás bizonylaton — FOREIGN → Külföldi', () => {
    const content = generateReceiptContent({
      ...baseData,
      hufAmount: 40000, // 300k ALATT is kötelező
      foreignStatus: 'FOREIGN',
    });
    expect(content).toContain('Az ügyletet készpénzben teljesítjük');
    expect(content).toContain('Deviza-státusz: Külföldi');
  });

  it('deviza-státusz: DOMESTIC → Belföldi, hiányzó → —', () => {
    expect(generateReceiptContent({ ...baseData, foreignStatus: 'DOMESTIC' }))
      .toContain('Deviza-státusz: Belföldi');
    expect(generateReceiptContent({ ...baseData, foreignStatus: undefined }))
      .toContain('Deviza-státusz: —');
  });

  it('deviza-státusz sor transzfer-bizonylaton NEM jelenik meg', () => {
    const content = generateReceiptContent({
      ...baseData,
      type: 'transfer',
      transferDocType: 'handover',
      transferTarget: 'SZG-02',
      foreignStatus: 'FOREIGN',
    });
    expect(content).not.toContain('Deviza-státusz:');
  });

  it('300k+ bizonylaton: PEP-sor (nem közszereplő) + JOGCÍM NYILATKOZAT saját névben', () => {
    const content = generateReceiptContent({
      ...baseData,
      hufAmount: 343000,
      roundedHufAmount: 343000,
      customerName: 'Kiss Géza',
      customerIsPep: false,
      customerOnOwnBehalf: true,
      sourceOfFunds: 'munkabér',
      foreignStatus: 'FOREIGN',
    });
    expect(content).toContain('Az ügyfél nem közszereplő');
    expect(content).toContain('JOGCÍM NYILATKOZAT');
    expect(content).toContain('saját nevemben bonyolítom,');
    expect(content).toContain('Pénzeszközöm forrása:');
    expect(content).toContain('munkabér');
  });

  it('300k+ PEP ügyfél: kiemelt közszereplő sor a minőséggel (emberi szöveg, nem kód)', () => {
    const content = generateReceiptContent({
      ...baseData,
      hufAmount: 500000,
      roundedHufAmount: 500000,
      customerName: 'Kiss Géza',
      customerIsPep: true,
      customerPepKind: 'PARLAMENTI',
    });
    // Batch2-D: a PepKind kód a backend buildPepStatusText kategória-szövegére fordul.
    expect(content).toContain('Az ügyfél kiemelt közszereplő (országgyűlési / önkormányzati képviselő)');
    // Első személyű nyilatkozat a JOGCÍM blokkban (legacy KozszerepNyilatkozat).
    expect(content).toContain('Kiemelt közszereplő (vagyok),');
    expect(content).toContain('mint: országgyűlési / önkormányzati képviselő');
  });

  it('Batch2-D: 300k+ JOGCÍM blokk — 5 munkanapos klauzula + ügyfél-aláírás + nem-PEP első személyű sor', () => {
    const content = generateReceiptContent({
      ...baseData,
      hufAmount: 343000,
      roundedHufAmount: 343000,
      customerName: 'Kiss Géza',
      customerIsPep: false,
      customerOnOwnBehalf: true,
      sourceOfFunds: 'munkabér',
    });
    expect(content).toContain('Nem (vagyok) kiemelt közszereplő.');
    expect(content).toContain('Tudomásom van arról, hogy 5 (öt)');
    expect(content).toContain('eredő kár engem terhel.');
    expect(content).toContain('ügyfél aláírása');
  });

  it('Batch2-D: orosz állampolgár EUR-vásárlása 300k+ → kétnyelvű NYILATKOZAT/DECLARATION', () => {
    const content = generateReceiptContent({
      ...baseData,
      type: 'sell',
      currencyCode: 'EUR',
      hufAmount: 400000,
      roundedHufAmount: 400000,
      customerName: 'Ivanov Ivan',
      customerNationality: 'orosz',
    });
    expect(content).toContain('NYILATKOZAT/DECLARATION');
    expect(content).toContain('személyes használatra váltottam');
    expect(content).toContain('for my personal usage');
    expect(content).toContain('ügyfél aláírása/signature of buyer');
  });

  it('Batch2-D: orosz nyilatkozat NEM jelenik meg vételnél / nem-EUR-nál / nem-orosz ügyfélnél', () => {
    // buy módban (a pénztár VESZI a valutát) nincs orosz nyilatkozat
    expect(generateReceiptContent({
      ...baseData, type: 'buy', currencyCode: 'EUR', hufAmount: 400000,
      roundedHufAmount: 400000, customerNationality: 'orosz', customerName: 'Ivanov Ivan',
    })).not.toContain('NYILATKOZAT/DECLARATION');
    // nem-EUR eladásnál sincs
    expect(generateReceiptContent({
      ...baseData, type: 'sell', currencyCode: 'USD', hufAmount: 400000,
      roundedHufAmount: 400000, customerNationality: 'orosz', customerName: 'Ivanov Ivan',
    })).not.toContain('NYILATKOZAT/DECLARATION');
    // magyar ügyfélnél sincs
    expect(generateReceiptContent({
      ...baseData, type: 'sell', currencyCode: 'EUR', hufAmount: 400000,
      roundedHufAmount: 400000, customerNationality: 'Magyar', customerName: 'Kiss Géza',
    })).not.toContain('NYILATKOZAT/DECLARATION');
  });

  it('300k+ képviselt fél: actor neve + adatai a nyilatkozatban', () => {
    const content = generateReceiptContent({
      ...baseData,
      hufAmount: 400000,
      roundedHufAmount: 400000,
      customerName: 'Kiss Géza',
      customerOnOwnBehalf: false,
      customerActorName: 'Nagy Béla',
      customerActorBirthPlace: 'Pécs',
      customerActorDocumentType: 'szem.ig.',
      customerActorDocumentNumber: 'AB123456',
    });
    expect(content).toContain('Nagy Béla');
    expect(content).toContain('nevében bonyolítom,');
    expect(content).toContain('Képviselt fél adatai:');
    expect(content).toContain('szül.hely: Pécs');
    expect(content).toContain('szem.ig.: AB123456');
  });

  it('300k ALATT: nincs PEP-sor és nincs JOGCÍM blokk', () => {
    const content = generateReceiptContent({
      ...baseData,
      hufAmount: 40000,
      roundedHufAmount: 40000,
      customerName: 'Kiss Géza',
      customerIsPep: false,
      sourceOfFunds: 'munkabér',
    });
    expect(content).not.toContain('JOGCÍM NYILATKOZAT');
    expect(content).not.toContain('közszereplő');
  });

  it('vegyes B/K többsoros nyugta: soronkénti deviza-státusz suffix, fejléc —', () => {
    const content = generateReceiptContent({
      ...baseData,
      hufAmount: 100000,
      foreignStatus: undefined, // vegyes → a fejléc nem hordozza
      transactionLines: [
        { currencyCode: 'EUR', foreignAmount: 100, rate: 400, hufAmount: 40000, foreignStatus: 'FOREIGN' },
        { currencyCode: 'USD', foreignAmount: 150, rate: 400, hufAmount: 60000, foreignStatus: 'DOMESTIC' },
      ],
    });
    expect(content).toContain('EUR (Külföldi):');
    expect(content).toContain('USD (Belföldi):');
    expect(content).toContain('Deviza-státusz: —');
  });
});

// Codex PR #1102 P1 + Copilot: payable-küszöb + HTML-útvonal tesztek
describe('printer — payable-küszöb (Codex #1102 P1) + HTML útvonal', () => {
  it('a küszöb a FIZETENDŐ összegre számol: 295k sorérték + 10k díj → nyilatkozatok IGEN', () => {
    const content = generateReceiptContent({
      ...baseData,
      hufAmount: 295000,
      roundedHufAmount: 295000,
      payableHufAmount: 305000, // sorérték + kezelési díj (AML-paritás)
      customerName: 'Kiss Géza',
      customerIsPep: false,
    });
    expect(content).toContain('JOGCÍM NYILATKOZAT');
    expect(content).toContain('Az ügyfél nem közszereplő');
  });

  it('payableHufAmount nélkül fallback a roundedHufAmount-ra (változatlan viselkedés)', () => {
    const content = generateReceiptContent({
      ...baseData,
      hufAmount: 295000,
      roundedHufAmount: 295000,
      customerName: 'Kiss Géza',
    });
    expect(content).not.toContain('JOGCÍM NYILATKOZAT');
  });

  it('HTML útvonal: deviza-státusz + JOGCÍM blokk pre-wrap behúzással', async () => {
    const html = await generateReceiptHtml({
      ...baseData,
      hufAmount: 343000,
      roundedHufAmount: 343000,
      payableHufAmount: 343000,
      foreignStatus: 'FOREIGN',
      customerName: 'Kiss Géza',
      customerOnOwnBehalf: true,
      sourceOfFunds: 'munkabér',
    });
    expect(html).toContain('Deviza-státusz: Külföldi');
    expect(html).toContain('JOGCÍM NYILATKOZAT');
    expect(html).toContain('white-space: pre-wrap');
    expect(html).toContain('munkabér');
  });

  it('HTML útvonal: 300k alatt nincs JOGCÍM, de a deviza-státusz sor megvan', async () => {
    const html = await generateReceiptHtml({
      ...baseData,
      foreignStatus: 'DOMESTIC',
    });
    expect(html).toContain('Deviza-státusz: Belföldi');
    expect(html).not.toContain('JOGCÍM NYILATKOZAT');
  });
});

// A.1 (PR #1101 follow-up): több-valutás átadólap a nyomtató-template-ekben
describe('printer — több-valutás átadólap sorok (A.1)', () => {
  const transferBase: PrintReceiptData = {
    ...baseData,
    type: 'transfer',
    transferDocType: 'handover',
    currencyCode: 'EUR',
    foreignAmount: 100,
    transferTarget: 'BR075 - Békéscsaba Értéktár',
  };

  it('ESC/POS: transferLines jelenlétekor minden sor listázva, a fejléc-mezős nézet helyett', () => {
    const content = generateReceiptContent({
      ...transferBase,
      transferLines: [
        { currencyCode: 'EUR', amount: 100 },
        { currencyCode: 'USD', amount: 10 },
      ],
    });
    expect(content).toContain('Valuták és összegek:');
    expect(content).toContain('EUR: 100');
    expect(content).toContain('USD: 10');
    expect(content).not.toContain('Valutanem:');
  });

  it('ESC/POS: transferLines nélkül a korábbi egysoros nézet változatlan', () => {
    const content = generateReceiptContent(transferBase);
    expect(content).toContain('Valutanem:   EUR');
    expect(content).not.toContain('Valuták és összegek:');
  });

  it('HTML: transferLines soronként', async () => {
    const html = await generateReceiptHtml({
      ...transferBase,
      transferLines: [
        { currencyCode: 'EUR', amount: 100 },
        { currencyCode: 'USD', amount: 10 },
      ],
    });
    expect(html).toContain('Valuták és összegek:');
    expect(html).toContain('USD:');
  });
});
