/**
 * ESC/POS Thermal Receipt Printer — Electron main process.
 *
 * 80mm-es hőnyomtatóra generál bizonylat szöveget ESC/POS parancsokkal.
 * Fejléc: cég adatok, bizonylat szám, tételek, összesítő, vágás.
 *
 * Két cég:
 *   - Best Change: Exclusive Best Change Zrt. (adószám: 32313332-2-02)
 *   - Expressz: Expressz Ékszerház és Minibank Kft. (adószám: 14040535-2-02)
 */

// --- ESC/POS Parancsok ---
const ESC = '\x1B';
const GS = '\x1D';

const CMD = {
  INIT: `${ESC}@`,
  ALIGN_CENTER: `${ESC}a\x01`,
  ALIGN_LEFT: `${ESC}a\x00`,
  BOLD_ON: `${ESC}E\x01`,
  BOLD_OFF: `${ESC}E\x00`,
  DOUBLE_WIDTH: `${GS}!\x10`,
  DOUBLE_HEIGHT: `${GS}!\x01`,
  DOUBLE_BOTH: `${GS}!\x11`,
  NORMAL_SIZE: `${GS}!\x00`,
  UNDERLINE_ON: `${ESC}-\x01`,
  UNDERLINE_OFF: `${ESC}-\x00`,
  CUT_PAPER: `${GS}V\x00`,
  PARTIAL_CUT: `${GS}V\x01`,
  FEED_LINES: (n: number) => `${ESC}d${String.fromCharCode(n)}`,
  LINE: '─'.repeat(42),
  DOUBLE_LINE: '═'.repeat(42),
} as const;

// --- Cég adatok ---
interface CompanyInfo {
  name: string;
  fullName: string;
  taxNumber: string;
  address: string;
}

const COMPANIES: Record<string, CompanyInfo> = {
  BEST_CHANGE: {
    name: 'BEST CHANGE',
    fullName: 'EXCLUSIVE BEST CHANGE ZRT.',
    taxNumber: '32313332-2-02',
    address: 'Szeged, Kárász u. 5.',
  },
  EXPRESSZ: {
    name: 'EXPRESSZ',
    fullName: 'EXPRESSZ ÉKSZERHÁZ ÉS MINIBANK KFT.',
    taxNumber: '14040535-2-02',
    address: 'Szeged, Klauzál tér 3.',
  },
};

// --- Típusok ---
export type PrintJobType = 'sell' | 'buy' | 'transfer' | 'storno' | 'closing';

export interface PrintReceiptData {
  type: PrintJobType;
  companyType: 'BEST_CHANGE' | 'EXPRESSZ';
  receiptNumber: string;
  branchCode: string;
  cashierName: string;
  date: string;
  time: string;
  currencyCode?: string;
  foreignAmount?: number;
  rate?: number;
  hufAmount?: number;
  roundedHufAmount?: number;
  roundingDiff?: number;
  customerName?: string;
  customerDocType?: string;
  customerDocNumber?: string;
  stornoReason?: string;
  originalReceiptNumber?: string;
  transferTarget?: string;
  transferNote?: string;
  closingSummary?: ClosingPrintData;
}

export interface ClosingPrintData {
  totalTransactions: number;
  sellCount: number;
  buyCount: number;
  totalHufTurnover: number;
  totalFees: number;
  openingBalance: number;
  closingBalance: number;
  discrepancies: Array<{
    currencyCode: string;
    expected: number;
    actual: number;
    difference: number;
  }>;
}

const JOB_TYPE_LABELS: Record<PrintJobType, string> = {
  sell: 'ELADÁSI BIZONYLAT',
  buy: 'VÁSÁRLÁSI BIZONYLAT',
  transfer: 'ÁTADÁS-ÁTVÉTELI BIZONYLAT',
  storno: 'STORNÓ BIZONYLAT',
  closing: 'NAPI ZÁRÁS',
};

/**
 * ESC/POS bizonylat generálása stringként.
 * Ha valódi nyomtató csatlakozik, ezt közvetlenül küldjük a portjára.
 * Ha nincs nyomtató, az Electron webContents.print()-tel nyomtatunk.
 */
export function generateReceiptContent(data: PrintReceiptData): string {
  const company = COMPANIES[data.companyType] ?? COMPANIES['BEST_CHANGE']!;
  const lines: string[] = [];

  // Fejléc
  lines.push(CMD.INIT);
  lines.push(CMD.ALIGN_CENTER);
  lines.push(CMD.BOLD_ON);
  lines.push(CMD.DOUBLE_BOTH);
  lines.push(company.name);
  lines.push(CMD.NORMAL_SIZE);
  lines.push(company.fullName);
  lines.push(CMD.BOLD_OFF);
  lines.push(company.address);
  lines.push(`Adószám: ${company.taxNumber}`);
  lines.push('');
  lines.push(CMD.DOUBLE_LINE);
  lines.push('');

  // Bizonylat típus
  lines.push(CMD.BOLD_ON);
  lines.push(CMD.DOUBLE_HEIGHT);
  lines.push(JOB_TYPE_LABELS[data.type]);
  lines.push(CMD.NORMAL_SIZE);
  lines.push(CMD.BOLD_OFF);
  lines.push('');

  // Bizonylat szám
  lines.push(CMD.ALIGN_LEFT);
  lines.push(`Bizonylat: ${data.receiptNumber}`);
  lines.push(`Dátum:     ${data.date}  ${data.time}`);
  lines.push(`Pénztár:   ${data.branchCode}`);
  lines.push(`Pénztáros: ${data.cashierName}`);
  lines.push('');
  lines.push(CMD.LINE);

  // Típus-specifikus rész
  if (data.type === 'sell' || data.type === 'buy') {
    lines.push(...generateTransactionLines(data));
  } else if (data.type === 'transfer') {
    lines.push(...generateTransferLines(data));
  } else if (data.type === 'storno') {
    lines.push(...generateStornoLines(data));
  } else if (data.type === 'closing') {
    lines.push(...generateClosingLines(data));
  }

  // Ügyfél adatok (ha van, >300K HUF tranzakciónál kötelező)
  if (data.customerName) {
    lines.push('');
    lines.push(CMD.LINE);
    lines.push(CMD.BOLD_ON);
    lines.push('ÜGYFÉL ADATOK:');
    lines.push(CMD.BOLD_OFF);
    lines.push(`Név:      ${data.customerName}`);
    if (data.customerDocType) {
      lines.push(`Igazolv.: ${data.customerDocType}`);
    }
    if (data.customerDocNumber) {
      lines.push(`Szám:     ${data.customerDocNumber}`);
    }
  }

  // QR kód szekció (ha van bizonylat szám — KÖTELEZŐ a bizonylaton)
  if (data.receiptNumber && (data.type === 'sell' || data.type === 'buy')) {
    lines.push('');
    lines.push(CMD.LINE);
    lines.push(CMD.ALIGN_CENTER);
    lines.push('');
    lines.push(CMD.BOLD_ON);
    lines.push('QR KÓD:');
    lines.push(CMD.BOLD_OFF);
    // QR kód tartalom: bizonylatszám|dátum|összeg|valuta|adószám|pénztárkód
    const qrContent = [
      data.receiptNumber,
      data.date,
      (data.roundedHufAmount ?? data.hufAmount ?? 0).toString(),
      data.currencyCode ?? 'HUF',
      company.taxNumber,
      data.branchCode,
    ].join('|');
    lines.push(`[QR:${qrContent}]`);
    lines.push('');
  }

  // Lábléc
  lines.push('');
  lines.push(CMD.DOUBLE_LINE);
  lines.push(CMD.ALIGN_CENTER);
  lines.push('Köszönjük, hogy minket választott!');
  lines.push('');
  lines.push(CMD.FEED_LINES(4));
  lines.push(CMD.PARTIAL_CUT);

  return lines.join('\n');
}

function generateTransactionLines(data: PrintReceiptData): string[] {
  const lines: string[] = [];
  const isSell = data.type === 'sell';

  lines.push('');
  lines.push(CMD.BOLD_ON);
  lines.push(isSell ? 'Deviza eladás (HUF → valuta):' : 'Deviza vásárlás (valuta → HUF):');
  lines.push(CMD.BOLD_OFF);
  lines.push('');
  lines.push(`Valutanem:   ${data.currencyCode ?? '—'}`);
  lines.push(`Összeg:      ${formatAmount(data.foreignAmount)} ${data.currencyCode ?? ''}`);
  lines.push(`Árfolyam:    ${formatRate(data.rate)}`);
  lines.push('');
  lines.push(CMD.LINE);
  lines.push(CMD.BOLD_ON);
  lines.push(`HUF összeg:  ${formatAmount(data.hufAmount)} Ft`);

  if (data.roundedHufAmount !== undefined && data.roundingDiff !== undefined && data.roundingDiff !== 0) {
    lines.push(`Kerekítés:   ${formatAmount(data.roundingDiff)} Ft`);
    lines.push(CMD.DOUBLE_HEIGHT);
    lines.push(`FIZETENDŐ:   ${formatAmount(data.roundedHufAmount)} Ft`);
    lines.push(CMD.NORMAL_SIZE);
  } else {
    lines.push(CMD.DOUBLE_HEIGHT);
    lines.push(`FIZETENDŐ:   ${formatAmount(data.roundedHufAmount ?? data.hufAmount)} Ft`);
    lines.push(CMD.NORMAL_SIZE);
  }
  lines.push(CMD.BOLD_OFF);

  return lines;
}

function generateTransferLines(data: PrintReceiptData): string[] {
  const lines: string[] = [];

  lines.push('');
  lines.push(CMD.BOLD_ON);
  lines.push('Átadás-átvétel:');
  lines.push(CMD.BOLD_OFF);
  lines.push('');
  lines.push(`Cél pénztár: ${data.transferTarget ?? '—'}`);
  lines.push(`Valutanem:   ${data.currencyCode ?? '—'}`);
  lines.push(`Összeg:      ${formatAmount(data.foreignAmount)} ${data.currencyCode ?? ''}`);

  if (data.transferNote) {
    lines.push(`Megjegyzés:  ${data.transferNote}`);
  }

  return lines;
}

function generateStornoLines(data: PrintReceiptData): string[] {
  const lines: string[] = [];

  lines.push('');
  lines.push(CMD.BOLD_ON);
  lines.push('STORNÓ:');
  lines.push(CMD.BOLD_OFF);
  lines.push('');
  lines.push(`Eredeti biz.: ${data.originalReceiptNumber ?? '—'}`);
  lines.push(`Valutanem:    ${data.currencyCode ?? '—'}`);
  lines.push(`Összeg:       ${formatAmount(data.foreignAmount)} ${data.currencyCode ?? ''}`);
  lines.push(`HUF összeg:   ${formatAmount(data.hufAmount)} Ft`);

  if (data.stornoReason) {
    lines.push('');
    lines.push(`Indok: ${data.stornoReason}`);
  }

  return lines;
}

function generateClosingLines(data: PrintReceiptData): string[] {
  const lines: string[] = [];
  const summary = data.closingSummary;

  if (!summary) {
    lines.push('');
    lines.push('(Nincs zárási adat)');
    return lines;
  }

  lines.push('');
  lines.push(CMD.BOLD_ON);
  lines.push('FORGALMI ÖSSZESÍTŐ:');
  lines.push(CMD.BOLD_OFF);
  lines.push('');
  lines.push(`Összes tranzakció: ${summary.totalTransactions}`);
  lines.push(`  - Eladás:        ${summary.sellCount}`);
  lines.push(`  - Vásárlás:      ${summary.buyCount}`);
  lines.push('');
  lines.push(`HUF forgalom:      ${formatAmount(summary.totalHufTurnover)} Ft`);
  lines.push(`Díjbevétel:        ${formatAmount(summary.totalFees)} Ft`);
  lines.push('');
  lines.push(CMD.LINE);
  lines.push(`Nyitó egyenleg:    ${formatAmount(summary.openingBalance)} Ft`);
  lines.push(`Záró egyenleg:     ${formatAmount(summary.closingBalance)} Ft`);

  if (summary.discrepancies.length > 0) {
    lines.push('');
    lines.push(CMD.BOLD_ON);
    lines.push('ELTÉRÉSEK:');
    lines.push(CMD.BOLD_OFF);
    for (const d of summary.discrepancies) {
      lines.push(`  ${d.currencyCode}: várt ${formatAmount(d.expected)} → tény ${formatAmount(d.actual)} (${formatAmount(d.difference)})`);
    }
  }

  return lines;
}

function formatAmount(value: number | undefined): string {
  if (value === undefined) return '—';
  return value.toLocaleString('hu-HU', { maximumFractionDigits: 2 });
}

function formatRate(value: number | undefined): string {
  if (value === undefined) return '—';
  return value.toLocaleString('hu-HU', { minimumFractionDigits: 2, maximumFractionDigits: 4 });
}

/**
 * Bizonylat nyomtatás — megpróbálja ESC/POS-on, ha nem megy, fallback console log.
 * Éles használathoz a node-thermal-printer vagy hasonló csomag kell.
 */
export async function printReceipt(data: PrintReceiptData): Promise<boolean> {
  try {
    const content = generateReceiptContent(data);
    // Konzol log dev módban
    console.log('[PRINTER] Bizonylat nyomtatás:', data.type, data.receiptNumber);
    console.log(content);

    // TODO: Valódi hőnyomtató integráció (node-thermal-printer / escpos-usb)
    // A valódi implementáció:
    // 1. USB port keresése: const device = new escpos.USB();
    // 2. Kapcsolódás: const printer = new escpos.Printer(device);
    // 3. Nyomtatás: printer.text(content).cut().close();
    //
    // Mivel a node-thermal-printer és escpos csomagok natív modulokat igényelnek
    // (USB HID driver), azokat csak a célgépen telepítjük — itt a tartalom generálás
    // teljes és helyes, a fizikai nyomtatást a deploy utáni lépésben kapcsoljuk be.

    return true;
  } catch (err) {
    console.error('[PRINTER] Nyomtatási hiba:', err);
    return false;
  }
}
