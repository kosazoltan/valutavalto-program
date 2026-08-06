/**
 * printer.ts unit tests — receipt content generation, formatting, HTML output.
 *
 * generateReceiptContent() and the formatting functions are pure — they don't
 * need electron at runtime (only BrowserWindow is used in printViaElectron).
 * We mock electron and test the content generators.
 */
import { describe, it, expect, vi, beforeEach, type Mock } from 'vitest';
import { BrowserWindow } from 'electron';

const { printMock, getPrintersMock, logErrorMock } = vi.hoisted(() => ({
  printMock: vi.fn((_opts: unknown, cb: (success: boolean, reason?: string) => void) => cb(true)),
  logErrorMock: vi.fn(),
  getPrintersMock: vi.fn().mockResolvedValue([
    {
      name: 'EPSON TM-T88V',
      displayName: 'EPSON TM-T88V',
      description: '',
      status: 0,
      isDefault: false,
    },
    {
      name: 'Microsoft Print to PDF',
      displayName: 'Microsoft Print to PDF',
      description: '',
      status: 0,
      isDefault: true,
    },
  ]),
}));

// Mock electron before importing printer.
// FONTOS: `function` kell (nem arrow), mert a printer `new BrowserWindow(...)`-t hív,
// és az arrow function nem konstruktor (Vitest: "is not a constructor" → silent false).
vi.mock('electron', () => ({
  BrowserWindow: vi.fn().mockImplementation(function () {
    return {
      loadURL: vi.fn().mockResolvedValue(undefined),
      webContents: {
        print: printMock,
        getPrintersAsync: getPrintersMock,
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
    error: logErrorMock,
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
  isVirtualPrinterName,
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
        discrepancies: [{ currencyCode: 'EUR', expected: 500, actual: 495, difference: -5 }],
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

  it('Batch2-E: kiállító értéktár kód+név a transfer fejlécben (csak ha kitöltött)', () => {
    const withLabel = generateReceiptContent({
      ...baseData,
      type: 'transfer',
      transferDocType: 'handover',
      transferTarget: 'SZG-02',
      vaultBranchLabel: 'BR075 - Békéscsaba Értéktár',
    });
    expect(withLabel).toContain('BR075 - Békéscsaba Értéktár');

    const withoutLabel = generateReceiptContent({
      ...baseData,
      type: 'transfer',
      transferDocType: 'handover',
      transferTarget: 'SZG-02',
    });
    expect(withoutLabel).not.toContain('BR075');
  });

  it('Batch2-E: árfolyam sor a deviza-átadólapon, HUF-on viszont nincs', () => {
    const eur = generateReceiptContent({
      ...baseData,
      type: 'transfer',
      transferDocType: 'handover',
      transferTarget: 'SZG-02',
      currencyCode: 'EUR',
      foreignAmount: 1000,
      rate: 391.5,
      roundedHufAmount: 391500,
    });
    // Copilot #1111: a közös formatRate() hu-HU formázása (tizedesvessző).
    expect(eur).toContain('Árfolyam:    391,50');
    expect(eur).toContain('Forint érték: ');

    const huf = generateReceiptContent({
      ...baseData,
      type: 'transfer',
      transferDocType: 'handover',
      transferTarget: 'SZG-02',
      currencyCode: 'HUF',
      foreignAmount: 500000,
      rate: 1,
      roundedHufAmount: 500000,
    });
    expect(huf).not.toContain('Árfolyam:');
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
    const content = generateReceiptContent({
      ...baseData,
      type: 'transfer',
      branchCode: '',
      transferTarget: '',
    });
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
    expect(content).toContain('azt tételesen átszámoltam.');
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

  it('FKH-018: Shipment-sztornó actor/time/ok és aláírásblokk az ESC/POS és HTML sablonban is nyomtatható', async () => {
    const data = {
      ...baseData,
      type: 'transfer' as const,
      transferDocType: 'handover' as const,
      receiptNumber: 'FF-000123-SZ',
      branchCode: 'Szeged Értéktár',
      transferTarget: 'Szeged Tisza Sarok',
      cashierName: 'Sztornózó Pénztáros',
      date: '2026. 07. 18.',
      time: '11:30:00',
      isStorno: true,
      stornoReason: 'Küldői sztornó átvétel előtt',
    };

    const escpos = generateReceiptContent(data);
    const html = await generateReceiptHtml(data);

    for (const output of [escpos, html]) {
      expect(output).toContain('SZTORNÓ BIZONYLAT');
      expect(output).toContain('FF-000123-SZ');
      expect(output).toContain('Sztornózó Pénztáros');
      expect(output).toContain('2026. 07. 18.');
      expect(output).toContain('11:30:00');
      expect(output).toContain('Küldői sztornó átvétel előtt');
      expect(output).toContain('Átadó');
      expect(output).toContain('Átvevő');
    }
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
    (BrowserWindow as unknown as Mock).mockClear();
    printMock.mockClear();
    const result = await printReceipt(baseData);
    expect(result).toBe(false);
    expect(BrowserWindow).not.toHaveBeenCalled();
    expect(printMock).not.toHaveBeenCalled();
  });

  it('should accept optional printerName', async () => {
    const result = await printReceipt(baseData, 'EPSON TM-T88V');
    expect(typeof result).toBe('boolean');
  });
});

describe('printer — FAIL-CLOSED (default printer/PDF fallback tiltás)', () => {
  beforeEach(() => {
    (BrowserWindow as unknown as Mock).mockClear();
    printMock.mockClear();
    getPrintersMock.mockClear();
    logErrorMock.mockClear();
    (printReceiptToSerial as Mock).mockReset().mockResolvedValue(false);
  });

  it('konfiguráció nélkül megtagadja a nyomtatást az ablak létrehozása előtt', async () => {
    const result = await printReceipt(baseData);

    expect(result).toBe(false);
    expect(BrowserWindow).not.toHaveBeenCalled();
    expect(printMock).not.toHaveBeenCalled();
    expect(logErrorMock).toHaveBeenCalledWith(
      '[PRINTER][FAIL-CLOSED] NO_PRINTER_CONFIGURED receiptNumber=BC-2026-001 ' +
        'printedCopies=0 copies=1: nincs printer.deviceName, a soros út nincs konfigurálva. ' +
        'Nyomtatás megtagadva; konfiguráljon valós nyomtatót (Beállítások > Nyomtatás / set-config).',
    );
  });

  it('virtuális PDF nyomtatót elutasít', async () => {
    const result = await printReceipt(baseData, 'Microsoft Print to PDF');

    expect(result).toBe(false);
    expect(printMock).not.toHaveBeenCalled();
    expect(logErrorMock).toHaveBeenCalledWith(
      '[PRINTER][FAIL-CLOSED] VIRTUAL_PRINTER_REJECTED receiptNumber=BC-2026-001 ' +
        'printedCopies=0 copies=1 printerName="Microsoft Print to PDF": virtuális ' +
        '(fájlba nyomtató) eszköz — bizonylat nem mehet PDF-be/fájlba.',
    );
  });

  it('nem létező nyomtatót elutasít', async () => {
    const result = await printReceipt(baseData, 'Nemletezo Nyomtato');

    expect(result).toBe(false);
    expect(printMock).not.toHaveBeenCalled();
    expect(logErrorMock).toHaveBeenCalledWith(
      '[PRINTER][FAIL-CLOSED] PRINTER_NOT_FOUND receiptNumber=BC-2026-001 ' +
        'printedCopies=0 copies=1 printerName="Nemletezo Nyomtato": nincs a rendszer ' +
        'nyomtatói között — nyomtatás megtagadva.',
    );
  });

  it('valid fizikai nyomtatóra silent módban, explicit deviceName-mel nyomtat', async () => {
    const result = await printReceipt(baseData, 'EPSON TM-T88V');

    expect(result).toBe(true);
    expect(printMock.mock.calls[0][0]).toMatchObject({
      silent: true,
      deviceName: 'EPSON TM-T88V',
    });
  });

  it('serial-only siker esetén nem indít Electron nyomtatást', async () => {
    (printReceiptToSerial as Mock).mockResolvedValue(true);

    const result = await printReceipt(baseData, undefined, 'COM3');

    expect(result).toBe(true);
    expect(BrowserWindow).not.toHaveBeenCalled();
  });

  it('serial hiba és deviceName hiány esetén nincs default printer fallback', async () => {
    const result = await printReceipt(baseData, undefined, 'COM3');

    expect(result).toBe(false);
    expect(printMock).not.toHaveBeenCalled();
    expect(logErrorMock).toHaveBeenCalledWith(
      '[PRINTER][FAIL-CLOSED] NO_PRINTER_CONFIGURED receiptNumber=BC-2026-001 ' +
        'printedCopies=0 copies=1: nincs printer.deviceName, a soros út sikertelen ' +
        '(0/1 példány kész). Nyomtatás megtagadva; konfiguráljon valós nyomtatót ' +
        '(Beállítások > Nyomtatás / set-config).',
    );
  });

  it('részleges soros nyomtatás után a fail-closed log a kész és kért példányszámot is tartalmazza', async () => {
    (printReceiptToSerial as Mock).mockResolvedValueOnce(true).mockResolvedValueOnce(false);
    const result = await printReceipt(
      {
        ...baseData,
        type: 'transfer',
        transferDocType: 'handover',
        currencyCode: 'HUF',
      },
      undefined,
      'COM3',
    );

    expect(result).toBe(false);
    expect(logErrorMock).toHaveBeenCalledWith(
      '[PRINTER][FAIL-CLOSED] NO_PRINTER_CONFIGURED receiptNumber=BC-2026-001 ' +
        'printedCopies=1 copies=2: nincs printer.deviceName, a soros út sikertelen ' +
        '(1/2 példány kész). Nyomtatás megtagadva; konfiguráljon valós nyomtatót ' +
        '(Beállítások > Nyomtatás / set-config).',
    );
  });

  it('serial hiba után valid deviceName-mel Electron úton nyomtat', async () => {
    const result = await printReceipt(baseData, 'EPSON TM-T88V', 'COM3');

    expect(result).toBe(true);
    expect(printMock).toHaveBeenCalledOnce();
  });

  it.each([
    'Microsoft XPS Document Writer',
    'OneNote (Desktop)',
    'Foxit PDF Printer',
    'Fax',
    'Send To File',
  ])('virtuális eszköznévként felismeri: %s', (printerName) => {
    expect(isVirtualPrinterName(printerName)).toBe(true);
  });

  it.each(['EPSON TM-T88V', 'Star TSP100', 'Send To Hub'])(
    'fizikai eszköznévként engedi: %s',
    (printerName) => {
      expect(isVirtualPrinterName(printerName)).toBe(false);
    },
  );
});

// SP512 papírméret (2026-08-06 fizikai teszt): a Star SP500/SP512 Windows-driver
// KIZÁRÓLAG saját, névvel ellátott formákat kínál (alapértelmezett: "63mm x Receipt",
// 62,7 mm nyomtatható szélesség, változó hossz) — 80 mm-es forma nem létezik. A korábbi
// hardcode-olt pageSize {80mm × 297mm} + fix 76mm body-szélesség üres lapot + feedet
// adott (a Windows-tesztoldal driver-szinten hibátlan volt). A javítás: a print hívás
// a nyomtató SAJÁT alapértelmezett formájára deferál (usePrinterDefaultPageSize),
// a HTML pedig nem rögzít lapszélességet — mikron-érték találgatása TILOS.
describe('printer — SP512 papírméret: driver-default form, nem hardcode-olt pageSize', () => {
  beforeEach(() => {
    (BrowserWindow as unknown as Mock).mockClear();
    printMock.mockClear();
    (printReceiptToSerial as Mock).mockReset().mockResolvedValue(false);
  });

  it('a webContents.print a nyomtató alapértelmezett lapméretét használja (usePrinterDefaultPageSize), pageSize nélkül', async () => {
    const result = await printReceipt(baseData, 'EPSON TM-T88V');

    expect(result).toBe(true);
    const opts = printMock.mock.calls[0][0] as Record<string, unknown>;
    expect(opts.usePrinterDefaultPageSize).toBe(true);
    expect(opts).not.toHaveProperty('pageSize');
  });

  it('a bizonylat-HTML nem rögzít 80mm-es lap- és 76mm-es body-szélességet, a @page a driver-formára deferál', async () => {
    const html = await generateReceiptHtml(baseData);

    expect(html).not.toMatch(/size:\s*80mm/);
    expect(html).not.toMatch(/width:\s*76mm/);
    expect(html).toMatch(/size:\s*auto/);
  });
});

describe('printer — fejléc-javítás FR-7: HUF transfer dupla példány', () => {
  beforeEach(() => {
    (BrowserWindow as unknown as Mock).mockClear();
  });

  it('HUF valutanemű transfer bizonylat KÉT példányban nyomtat', async () => {
    const result = await printReceipt(
      {
        ...baseData,
        type: 'transfer',
        transferDocType: 'handover',
        currencyCode: 'HUF',
        transferTarget: 'SZG-02',
      },
      'EPSON TM-T88V',
    );
    expect(result).toBe(true);
    expect((BrowserWindow as unknown as Mock).mock.calls.length).toBe(2);
  });

  it('deviza (EUR) transfer bizonylat EGY példányban nyomtat', async () => {
    const result = await printReceipt(
      {
        ...baseData,
        type: 'transfer',
        transferDocType: 'receipt',
        currencyCode: 'EUR',
        transferTarget: 'SZG-02',
      },
      'EPSON TM-T88V',
    );
    expect(result).toBe(true);
    expect((BrowserWindow as unknown as Mock).mock.calls.length).toBe(1);
  });

  it('KK sorszámú HUF Shipment bizonylat KÉT példányban nyomtat', async () => {
    const result = await printReceipt(
      {
        ...baseData,
        type: 'transfer',
        receiptNumber: 'KK-000123',
        transferDocType: 'handover',
        currencyCode: 'HUF',
        transferTarget: 'BR027 - Szeged Tesco',
        vaultAddress: 'Szeged, Hajnóczy u. 57., 6722',
      },
      'EPSON TM-T88V',
    );
    expect(result).toBe(true);
    expect((BrowserWindow as unknown as Mock).mock.calls.length).toBe(2);
  });

  it('FF sorszámú deviza Shipment bizonylat EGY példányban nyomtat', async () => {
    const result = await printReceipt(
      {
        ...baseData,
        type: 'transfer',
        receiptNumber: 'FF-000124',
        transferDocType: 'receipt',
        currencyCode: 'EUR',
        transferTarget: 'BR075 - Szeged Értéktár',
        vaultAddress: 'Szeged, Hajnóczy u. 57., 6722',
      },
      'EPSON TM-T88V',
    );
    expect(result).toBe(true);
    expect((BrowserWindow as unknown as Mock).mock.calls.length).toBe(1);
  });

  it('nem-transfer (sell) HUF-os bizonylat EGY példányban nyomtat (a dupla szabály csak transferre vonatkozik)', async () => {
    const result = await printReceipt(
      { ...baseData, type: 'sell', currencyCode: 'HUF' },
      'EPSON TM-T88V',
    );
    expect(result).toBe(true);
    expect((BrowserWindow as unknown as Mock).mock.calls.length).toBe(1);
  });

  it('részleges soros hiba: 1 soros példány OK + 2. hibás → fallback csak a MARADÉK 1 példányt nyomtatja (összesen 2, nem 3)', async () => {
    (printReceiptToSerial as Mock).mockResolvedValueOnce(true).mockResolvedValueOnce(false);
    const result = await printReceipt(
      {
        ...baseData,
        type: 'transfer',
        transferDocType: 'handover',
        currencyCode: 'HUF',
        transferTarget: 'SZG-02',
      },
      'EPSON TM-T88V',
      'COM3',
    );
    expect(result).toBe(true);
    expect((printReceiptToSerial as Mock).mock.calls.length).toBe(2);
    // Electron fallback csak a hiányzó 1 példányra fut, nem mind a 2-re
    expect((BrowserWindow as unknown as Mock).mock.calls.length).toBe(1);
  });

  it('teljes soros siker: 2 soros példány OK → nincs Electron fallback', async () => {
    (printReceiptToSerial as Mock).mockResolvedValueOnce(true).mockResolvedValueOnce(true);
    const result = await printReceipt(
      {
        ...baseData,
        type: 'transfer',
        transferDocType: 'handover',
        currencyCode: 'HUF',
        transferTarget: 'SZG-02',
      },
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
    expect(generateReceiptContent({ ...baseData, foreignStatus: 'DOMESTIC' })).toContain(
      'Deviza-státusz: Belföldi',
    );
    expect(generateReceiptContent({ ...baseData, foreignStatus: undefined })).toContain(
      'Deviza-státusz: —',
    );
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
    expect(content).toContain(
      'Az ügyfél kiemelt közszereplő (országgyűlési / önkormányzati képviselő)',
    );
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

  it('V325 (Batch3-C): 300k+ jogi személy blokk — entitás-adatok + megbízott + tényleges tulajdonosok', () => {
    const content = generateReceiptContent({
      ...baseData,
      hufAmount: 400000,
      roundedHufAmount: 400000,
      customerName: 'Kiss Géza',
      customerAddress: '6722 Szeged, Tisza u. 1.',
      customerIsPep: false,
      isLegalEntityCustomer: true,
      legalEntityName: 'Példa Kft.',
      legalEntitySeat: '6720 Szeged, Fő tér 2.',
      legalEntityTaxNumber: '12345678-2-06',
      legalDeedNumber: 'Cg.06-09-123456',
      beneficialOwners: [
        {
          name: 'Nagy Anna',
          address: '6721 Szeged, Kossuth u. 3.',
          birthPlace: 'Szeged',
          birthDate: '1980-01-01',
          nationality: 'magyar',
          interestNature: 'tulajdonos',
          interestExtent: '60%',
          isPep: false,
        },
        {
          name: 'Tóth Béla',
          isPep: true,
        },
      ],
    });
    expect(content).toContain('Jogi személy neve:');
    expect(content).toContain('Példa Kft.');
    expect(content).toContain('Jogi személy székhelye:');
    expect(content).toContain('6720 Szeged, Fő tér 2.');
    expect(content).toContain('Okiratszám: Cg.06-09-123456');
    expect(content).toContain('Adószám: 12345678-2-06');
    expect(content).toContain('Megbízott neve:');
    expect(content).toContain('Tényleges tulajdonosok adatai:');
    expect(content).toContain('1. tulajdonos:');
    expect(content).toContain('Nagy Anna');
    expect(content).toContain('2. tulajdonos:');
    expect(content).toContain('Tóth Béla');
    expect(content).toContain('Nem közszereplő');
    expect(content).toContain('A tulaj közszereplő');
  });

  it('V325 (Batch3-C): nem jogi személy ügyfélnél NINCS jogi blokk', () => {
    const content = generateReceiptContent({
      ...baseData,
      hufAmount: 400000,
      roundedHufAmount: 400000,
      customerName: 'Kiss Géza',
      customerIsPep: false,
    });
    expect(content).not.toContain('Jogi személy neve:');
    expect(content).not.toContain('Tényleges tulajdonosok adatai:');
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

  it('Batch2-D (Codex P1 #1110): ISMERETLEN PEP-státusznál nincs se pozitív, se negatív PEP-mondat', () => {
    const content = generateReceiptContent({
      ...baseData,
      hufAmount: 343000,
      roundedHufAmount: 343000,
      customerName: 'Kiss Géza',
      customerOnOwnBehalf: true,
      sourceOfFunds: 'munkabér',
      // customerIsPep szándékosan kitöltetlen (régi queue-sor / hiányos hívó)
    });
    expect(content).toContain('JOGCÍM NYILATKOZAT');
    expect(content).not.toContain('Nem (vagyok) kiemelt közszereplő.');
    expect(content).not.toContain('Kiemelt közszereplő (vagyok),');
  });

  it('Batch2-D (Sourcery #1110): orosz nyilatkozat transactionLines-ban lévő EUR-ra és "ru" ISO-kódra is', () => {
    // EUR csak a többsoros lines-ban, a fejléc-valuta USD; nationality ISO 'ru'
    const content = generateReceiptContent({
      ...baseData,
      type: 'sell',
      currencyCode: 'USD',
      hufAmount: 400000,
      roundedHufAmount: 400000,
      customerName: 'Ivanov Ivan',
      customerNationality: 'RU',
      transactionLines: [
        { currencyCode: 'USD', foreignAmount: 500, rate: 350, hufAmount: 175000 },
        { currencyCode: 'EUR', foreignAmount: 600, rate: 400, hufAmount: 240000 },
      ],
    });
    expect(content).toContain('NYILATKOZAT/DECLARATION');
  });

  it('Batch2-D: orosz nyilatkozat NEM jelenik meg vételnél / nem-EUR-nál / nem-orosz ügyfélnél', () => {
    // buy módban (a pénztár VESZI a valutát) nincs orosz nyilatkozat
    expect(
      generateReceiptContent({
        ...baseData,
        type: 'buy',
        currencyCode: 'EUR',
        hufAmount: 400000,
        roundedHufAmount: 400000,
        customerNationality: 'orosz',
        customerName: 'Ivanov Ivan',
      }),
    ).not.toContain('NYILATKOZAT/DECLARATION');
    // nem-EUR eladásnál sincs
    expect(
      generateReceiptContent({
        ...baseData,
        type: 'sell',
        currencyCode: 'USD',
        hufAmount: 400000,
        roundedHufAmount: 400000,
        customerNationality: 'orosz',
        customerName: 'Ivanov Ivan',
      }),
    ).not.toContain('NYILATKOZAT/DECLARATION');
    // magyar ügyfélnél sincs
    expect(
      generateReceiptContent({
        ...baseData,
        type: 'sell',
        currencyCode: 'EUR',
        hufAmount: 400000,
        roundedHufAmount: 400000,
        customerNationality: 'Magyar',
        customerName: 'Kiss Géza',
      }),
    ).not.toContain('NYILATKOZAT/DECLARATION');
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
        {
          currencyCode: 'EUR',
          foreignAmount: 100,
          rate: 400,
          hufAmount: 40000,
          foreignStatus: 'FOREIGN',
        },
        {
          currencyCode: 'USD',
          foreignAmount: 150,
          rate: 400,
          hufAmount: 60000,
          foreignStatus: 'DOMESTIC',
        },
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
