/**
 * Thermal Receipt Printer — Electron main process.
 *
 * 80mm-es hőnyomtatóra generál bizonylat szöveget ESC/POS parancsokkal,
 * illetve HTML formátumban az Electron beépített nyomtató API-ján keresztül.
 *
 * Nyomtatási architektúra:
 *   1. printReceipt() — fő belépési pont, IPC-ből hívva
 *   2. Megpróbálja printToThermalUsb()-t (ESC/POS közvetlen USB — jövőbeli)
 *   3. Ha nincs USB nyomtató, fallback: printViaElectron() — rejtett ablakban
 *      HTML-t renderel és a rendszer nyomtató-driverén keresztül nyomtat
 *
 * Két cég:
 *   - Best Change: Exclusive Best Change Zrt. (adószám: 32313332-2-02)
 *   - Expressz: Expressz Ékszerház és Minibank Kft. (adószám: 14040535-2-02)
 */

import { BrowserWindow } from 'electron';
import log from 'electron-log/main';

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
  phone: string;
}

const COMPANIES: Record<string, CompanyInfo> = {
  BEST_CHANGE: {
    name: 'BEST CHANGE',
    fullName: 'EXCLUSIVE BEST CHANGE ZRT.',
    taxNumber: '32313332-2-02',
    address: 'Szeged, Kárász u. 5.',
    phone: '06703800161',
  },
  EXPRESSZ: {
    name: 'EXPRESSZ',
    fullName: 'EXPRESSZ ÉKSZERHÁZ ÉS MINIBANK KFT.',
    taxNumber: '14040535-2-02',
    address: 'Szeged, Klauzál tér 3.',
    phone: '',
  },
};

// --- Típusok ---
export type PrintJobType =
  | 'sell'
  | 'buy'
  | 'transfer'
  | 'storno'
  | 'conversion'
  | 'closing'
  | 'handling_fee'
  | 'cash_status'
  | 'vault_closing'
  | 'kktg_transfer';

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
  customerAddress?: string;
  customerMotherName?: string;
  customerBirthPlace?: string;
  customerBirthDate?: string;
  customerNationality?: string;
  sealNumber?: string;
  vatExemptionText?: string;
  companyPhone?: string;
  companyTaxNumber?: string;
  stornoReason?: string;
  originalReceiptNumber?: string;
  sourceCurrencyCode?: string;
  sourceAmount?: number;
  targetCurrencyCode?: string;
  targetAmount?: number;
  note?: string;
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
  conversion: 'KONVERZIÓS BIZONYLAT',
  closing: 'NAPI ZÁRÁS',
  handling_fee: 'KEZELÉSI DÍJ BIZONYLAT',
  cash_status: 'PÉNZTÁR ÁLLÁS',
  vault_closing: 'ÉRTÉKTÁRI ZÁRÁS',
  kktg_transfer: 'KKTG ÁTADÁS-ÁTVÉTEL',
};

// ============================================================================
// ESC/POS tartalom generálás (közvetlen USB hőnyomtatóhoz — jövőbeli)
// ============================================================================

/**
 * ESC/POS bizonylat generálása stringként.
 * Közvetlen USB hőnyomtató esetén ezt közvetlenül a port-ra kell küldeni.
 * Jelenleg a printToThermalUsb() stub használja előkészítésre.
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
  const phone = data.companyPhone || company.phone;
  if (phone) {
    lines.push(`Tel: ${phone}`);
  }
  lines.push(`Adószám: ${data.companyTaxNumber || company.taxNumber}`);
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
  } else if (data.type === 'conversion') {
    lines.push(...generateConversionLines(data));
  } else if (data.type === 'transfer') {
    lines.push(...generateTransferLines(data));
  } else if (data.type === 'storno') {
    lines.push(...generateStornoLines(data));
  } else if (data.type === 'closing') {
    lines.push(...generateClosingLines(data));
  } else if (data.type === 'handling_fee') {
    lines.push(...generateHandlingFeeLines(data));
  } else if (data.type === 'cash_status') {
    lines.push(...generateCashStatusLines(data));
  } else if (data.type === 'vault_closing') {
    lines.push(...generateVaultClosingLines(data));
  } else if (data.type === 'kktg_transfer') {
    lines.push(...generateKktgTransferLines(data));
  }

  // Ügyfél adatok (ha van, >300K HUF tranzakciónál kötelező)
  if (data.customerName) {
    lines.push('');
    lines.push(CMD.LINE);
    lines.push(CMD.BOLD_ON);
    lines.push('ÜGYFÉL ADATOK:');
    lines.push(CMD.BOLD_OFF);
    lines.push(`Név:        ${data.customerName}`);
    if (data.customerBirthPlace) {
      lines.push(`Szül.hely:  ${data.customerBirthPlace}`);
    }
    if (data.customerBirthDate) {
      lines.push(`Szül.idő:   ${data.customerBirthDate}`);
    }
    if (data.customerMotherName) {
      lines.push(`Anyja neve: ${data.customerMotherName}`);
    }
    if (data.customerAddress) {
      lines.push(`Lakcím:     ${data.customerAddress}`);
    }
    if (data.customerDocType) {
      lines.push(`Okmány:     ${data.customerDocType}`);
    }
    if (data.customerDocNumber) {
      lines.push(`Okmányszám: ${data.customerDocNumber}`);
    }
    if (data.customerNationality) {
      lines.push(`Államp.:    ${data.customerNationality}`);
    }
  }

  // QR kód szekció (ha van bizonylat szám — KÖTELEZŐ a bizonylaton)
  if (data.receiptNumber && (data.type === 'sell' || data.type === 'buy' || data.type === 'conversion')) {
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
      data.companyTaxNumber || company.taxNumber,
      data.branchCode,
    ].join('|');
    lines.push(`[QR:${qrContent}]`);
    lines.push('');
  }

  // ÁFA-mentességi szöveg (törvényi kötelező)
  lines.push('');
  lines.push(CMD.LINE);
  lines.push(CMD.ALIGN_LEFT);
  lines.push('Szj 67.13.10.0');
  lines.push('Az ÁFA alól mentes:');
  lines.push('2007. évi CXVII tv. 85. § e)');
  lines.push(CMD.LINE);

  // Két aláírás sor
  lines.push('');
  lines.push(CMD.ALIGN_LEFT);
  lines.push('...............    ...............');
  lines.push('  Pénztáros            Ügyfél');

  // Lábléc
  lines.push('');
  lines.push(CMD.DOUBLE_LINE);
  lines.push(CMD.ALIGN_CENTER);
  lines.push('Köszönjük, hogy minket választott!');
  lines.push('');
  lines.push('A bizonylat a pénzmosás elleni');
  lines.push('törvény alapján nem helyettesíti');
  lines.push('a számlát.');
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

function generateConversionLines(data: PrintReceiptData): string[] {
  const lines: string[] = [];

  lines.push('');
  lines.push(CMD.BOLD_ON);
  lines.push('Konverzió:');
  lines.push(CMD.BOLD_OFF);
  lines.push('');
  lines.push(`Forrás:      ${formatAmount(data.sourceAmount)} ${data.sourceCurrencyCode ?? '—'}`);
  lines.push(`Cél:         ${formatAmount(data.targetAmount)} ${data.targetCurrencyCode ?? '—'}`);
  lines.push(`Köztes HUF:  ${formatAmount(data.hufAmount)} Ft`);
  lines.push(`Árfolyam:    ${formatRate(data.rate)}`);

  if (data.note) {
    lines.push(`Megjegyzés:  ${data.note}`);
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

function generateHandlingFeeLines(data: PrintReceiptData): string[] {
  const lines: string[] = [];
  lines.push('');
  lines.push(CMD.BOLD_ON);
  lines.push(`Kezelési díj: ${formatAmount(data.hufAmount)} Ft`);
  lines.push(CMD.BOLD_OFF);
  if (data.sealNumber) lines.push(`Plombaszám:    ${data.sealNumber}`);
  if (data.originalReceiptNumber) lines.push(`Alapbizonylat: ${data.originalReceiptNumber}`);
  return lines;
}

function generateCashStatusLines(data: PrintReceiptData): string[] {
  const lines: string[] = [];
  lines.push('');
  lines.push(CMD.BOLD_ON);
  lines.push('PÉNZTÁR ÁLLÁS');
  lines.push(CMD.BOLD_OFF);
  if (data.hufAmount !== undefined) lines.push(`HUF egyenleg:  ${formatAmount(data.hufAmount)} Ft`);
  if (data.note) lines.push(`Megjegyzés:    ${data.note}`);
  return lines;
}

function generateVaultClosingLines(data: PrintReceiptData): string[] {
  const lines: string[] = [];
  lines.push('');
  lines.push(CMD.BOLD_ON);
  lines.push('ÉRTÉKTÁRI ZÁRÁS');
  lines.push(CMD.BOLD_OFF);
  if (data.hufAmount !== undefined) lines.push(`Összeg:        ${formatAmount(data.hufAmount)} Ft`);
  if (data.sealNumber) lines.push(`Plombaszám:    ${data.sealNumber}`);
  if (data.note) lines.push(`Megjegyzés:    ${data.note}`);
  return lines;
}

function generateKktgTransferLines(data: PrintReceiptData): string[] {
  const lines: string[] = [];
  lines.push('');
  lines.push(CMD.BOLD_ON);
  lines.push('KKTG ÁTADÁS-ÁTVÉTEL');
  lines.push(CMD.BOLD_OFF);
  if (data.hufAmount !== undefined) lines.push(`Összeg:        ${formatAmount(data.hufAmount)} Ft`);
  if (data.sealNumber) lines.push(`Plombaszám:    ${data.sealNumber}`);
  if (data.transferTarget) lines.push(`Cél iroda:     ${data.transferTarget}`);
  if (data.note) lines.push(`Megjegyzés:    ${data.note}`);
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

// ============================================================================
// HTML bizonylat generálás (Electron webContents.print() számára)
// ============================================================================

/**
 * Bizonylat HTML generálása — 80mm szélességre optimalizált.
 * Ezt rendereli a rejtett BrowserWindow a rendszer nyomtató felé.
 */
async function generateReceiptHtml(data: PrintReceiptData): Promise<string> {
  const company = COMPANIES[data.companyType] ?? COMPANIES['BEST_CHANGE']!;
  const label = JOB_TYPE_LABELS[data.type];

  let bodyContent = '';

  // Fejléc
  bodyContent += `
    <div class="center">
      <div class="company-name">${escHtml(company.name)}</div>
      <div class="company-full">${escHtml(company.fullName)}</div>
      <div>${escHtml(company.address)}</div>
      ${(data.companyPhone || company.phone) ? `<div>Tel: ${escHtml(data.companyPhone || company.phone)}</div>` : ''}
      <div>Adószám: ${escHtml(data.companyTaxNumber || company.taxNumber)}</div>
    </div>
    <div class="double-line"></div>
    <div class="center receipt-type">${escHtml(label)}</div>
    <div class="meta">
      <div>Bizonylat: ${escHtml(data.receiptNumber)}</div>
      <div>Dátum: ${escHtml(data.date)} &nbsp; ${escHtml(data.time)}</div>
      <div>Pénztár: ${escHtml(data.branchCode)}</div>
      <div>Pénztáros: ${escHtml(data.cashierName)}</div>
    </div>
    <div class="line"></div>
  `;

  // Típus-specifikus tartalom
  if (data.type === 'sell' || data.type === 'buy') {
    bodyContent += generateTransactionHtml(data);
  } else if (data.type === 'transfer') {
    bodyContent += generateTransferHtml(data);
  } else if (data.type === 'storno') {
    bodyContent += generateStornoHtml(data);
  } else if (data.type === 'conversion') {
    bodyContent += generateConversionHtml(data);
  } else if (data.type === 'closing') {
    bodyContent += generateClosingHtml(data);
  } else if (data.type === 'handling_fee') {
    bodyContent += generateHandlingFeeHtml(data);
  } else if (data.type === 'cash_status') {
    bodyContent += generateCashStatusHtml(data);
  } else if (data.type === 'vault_closing') {
    bodyContent += generateVaultClosingHtml(data);
  } else if (data.type === 'kktg_transfer') {
    bodyContent += generateKktgTransferHtml(data);
  }

  // Ügyfél adatok (300K felett kötelező)
  if (data.customerName) {
    bodyContent += `
      <div class="line"></div>
      <div class="bold">ÜGYFÉL ADATOK:</div>
      <div class="amount-row"><span>Név:</span><span>${escHtml(data.customerName)}</span></div>
      ${data.customerBirthPlace ? `<div class="amount-row"><span>Szül. hely:</span><span>${escHtml(data.customerBirthPlace)}</span></div>` : ''}
      ${data.customerBirthDate ? `<div class="amount-row"><span>Szül. idő:</span><span>${escHtml(data.customerBirthDate)}</span></div>` : ''}
      ${data.customerMotherName ? `<div class="amount-row"><span>Anyja neve:</span><span>${escHtml(data.customerMotherName)}</span></div>` : ''}
      ${data.customerAddress ? `<div class="amount-row"><span>Lakcím:</span><span>${escHtml(data.customerAddress)}</span></div>` : ''}
      ${data.customerDocType ? `<div class="amount-row"><span>Okmány:</span><span>${escHtml(data.customerDocType)}</span></div>` : ''}
      ${data.customerDocNumber ? `<div class="amount-row"><span>Okmányszám:</span><span>${escHtml(data.customerDocNumber)}</span></div>` : ''}
      ${data.customerNationality ? `<div class="amount-row"><span>Állampolgárság:</span><span>${escHtml(data.customerNationality)}</span></div>` : ''}
    `;
  }

  // ÁFA-mentességi szöveg (törvényi kötelező)
  bodyContent += `
    <div class="line"></div>
    <div style="font-size: 9px; margin: 4px 0;">
      ${data.vatExemptionText
        ? `<div>${escHtml(data.vatExemptionText)}</div>`
        : `<div>Szj 67.13.10.0</div><div>Az ÁFA alól mentes: 2007. évi CXVII tv. 85. § e)</div>`
      }
    </div>
    <div class="line"></div>
  `;

  // Két aláírás sor
  bodyContent += `
    <div style="display: flex; justify-content: space-around; margin: 12px 0;">
      <div style="text-align: center;">
        <div style="border-top: 1px solid #000; width: 90px; display: inline-block;"></div>
        <div style="font-size: 9px;">Pénztáros</div>
      </div>
      <div style="text-align: center;">
        <div style="border-top: 1px solid #000; width: 90px; display: inline-block;"></div>
        <div style="font-size: 9px;">Ügyfél</div>
      </div>
    </div>
  `;

  // QR kód (NAV-kompatibilis)
  const taxNum = data.companyTaxNumber || company.taxNumber;
  const qrText = [
    data.receiptNumber,
    data.date,
    (data.roundedHufAmount ?? data.hufAmount ?? 0).toString(),
    data.currencyCode ?? 'HUF',
    taxNum,
    data.branchCode ?? '',
  ].join('|');
  try {
    const QRCode = await import('qrcode');
    const qrDataUrl = await QRCode.toDataURL(qrText, { width: 120, margin: 1, errorCorrectionLevel: 'M' });
    bodyContent += `
      <div class="center" style="margin: 8px 0;">
        <img src="${qrDataUrl}" style="width: 100px; height: 100px;" alt="QR" />
      </div>
    `;
  } catch {
    bodyContent += `
      <div class="center" style="margin: 8px 0; font-size: 8px; color: #999;">QR: ${escHtml(qrText)}</div>
    `;
  }

  // Lábléc
  bodyContent += `
    <div class="double-line"></div>
    <div class="center footer">Köszönjük, hogy minket választott!</div>
    <div class="center" style="font-size: 8px; color: #666; margin-top: 4px;">
      A bizonylat a pénzmosás elleni törvény alapján nem helyettesíti a számlát.
    </div>
  `;

  return `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    @page {
      size: 80mm auto;
      margin: 2mm;
    }
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: 'Courier New', monospace;
      font-size: 11px;
      line-height: 1.4;
      width: 76mm;
      color: #000;
    }
    .center { text-align: center; }
    .bold { font-weight: bold; }
    .company-name {
      font-size: 18px;
      font-weight: bold;
    }
    .company-full {
      font-size: 11px;
      font-weight: bold;
    }
    .receipt-type {
      font-size: 14px;
      font-weight: bold;
      margin: 4px 0;
    }
    .meta { margin: 4px 0; }
    .line {
      border-top: 1px dashed #000;
      margin: 6px 0;
    }
    .double-line {
      border-top: 2px solid #000;
      margin: 6px 0;
    }
    .amount-row {
      display: flex;
      justify-content: space-between;
    }
    .total {
      font-size: 14px;
      font-weight: bold;
      margin-top: 4px;
    }
    .section { margin: 6px 0; }
    .footer { margin-top: 8px; font-size: 10px; }
    .discrepancy { color: #c00; font-weight: bold; }
  </style>
</head>
<body>${bodyContent}</body>
</html>`;
}

function generateTransactionHtml(data: PrintReceiptData): string {
  const isSell = data.type === 'sell';
  const label = isSell ? 'Deviza eladás (HUF → valuta):' : 'Deviza vásárlás (valuta → HUF):';

  let html = `
    <div class="section">
      <div class="bold">${escHtml(label)}</div>
      <div class="amount-row"><span>Valutanem:</span><span>${escHtml(data.currencyCode ?? '—')}</span></div>
      <div class="amount-row"><span>Összeg:</span><span>${formatAmount(data.foreignAmount)} ${escHtml(data.currencyCode ?? '')}</span></div>
      <div class="amount-row"><span>Árfolyam:</span><span>${formatRate(data.rate)}</span></div>
    </div>
    <div class="line"></div>
    <div class="amount-row bold"><span>HUF összeg:</span><span>${formatAmount(data.hufAmount)} Ft</span></div>
  `;

  if (data.roundedHufAmount !== undefined && data.roundingDiff !== undefined && data.roundingDiff !== 0) {
    html += `
      <div class="amount-row"><span>Kerekítés:</span><span>${formatAmount(data.roundingDiff)} Ft</span></div>
      <div class="amount-row total"><span>FIZETENDŐ:</span><span>${formatAmount(data.roundedHufAmount)} Ft</span></div>
    `;
  } else {
    html += `
      <div class="amount-row total"><span>FIZETENDŐ:</span><span>${formatAmount(data.roundedHufAmount ?? data.hufAmount)} Ft</span></div>
    `;
  }

  return html;
}

function generateTransferHtml(data: PrintReceiptData): string {
  return `
    <div class="section">
      <div class="bold">Átadás-átvétel:</div>
      <div class="amount-row"><span>Cél pénztár:</span><span>${escHtml(data.transferTarget ?? '—')}</span></div>
      <div class="amount-row"><span>Valutanem:</span><span>${escHtml(data.currencyCode ?? '—')}</span></div>
      <div class="amount-row"><span>Összeg:</span><span>${formatAmount(data.foreignAmount)} ${escHtml(data.currencyCode ?? '')}</span></div>
      ${data.transferNote ? `<div>Megjegyzés: ${escHtml(data.transferNote)}</div>` : ''}
    </div>
  `;
}

function generateStornoHtml(data: PrintReceiptData): string {
  return `
    <div class="section">
      <div class="bold">STORNÓ:</div>
      <div class="amount-row"><span>Eredeti biz.:</span><span>${escHtml(data.originalReceiptNumber ?? '—')}</span></div>
      <div class="amount-row"><span>Valutanem:</span><span>${escHtml(data.currencyCode ?? '—')}</span></div>
      <div class="amount-row"><span>Összeg:</span><span>${formatAmount(data.foreignAmount)} ${escHtml(data.currencyCode ?? '')}</span></div>
      <div class="amount-row"><span>HUF összeg:</span><span>${formatAmount(data.hufAmount)} Ft</span></div>
      ${data.stornoReason ? `<div>Indok: ${escHtml(data.stornoReason)}</div>` : ''}
    </div>
  `;
}

function generateClosingHtml(data: PrintReceiptData): string {
  const summary = data.closingSummary;
  if (!summary) return '<div class="section">(Nincs zárási adat)</div>';

  let discrepancyHtml = '';
  if (summary.discrepancies.length > 0) {
    discrepancyHtml = `
      <div class="bold discrepancy">ELTÉRÉSEK:</div>
      ${summary.discrepancies
        .map(
          (d) =>
            `<div class="discrepancy">&nbsp;&nbsp;${escHtml(d.currencyCode)}: várt ${formatAmount(d.expected)} → tény ${formatAmount(d.actual)} (${formatAmount(d.difference)})</div>`,
        )
        .join('')}
    `;
  }

  return `
    <div class="section">
      <div class="bold">FORGALMI ÖSSZESÍTŐ:</div>
      <div class="amount-row"><span>Összes tranzakció:</span><span>${summary.totalTransactions}</span></div>
      <div class="amount-row"><span>&nbsp;&nbsp;- Eladás:</span><span>${summary.sellCount}</span></div>
      <div class="amount-row"><span>&nbsp;&nbsp;- Vásárlás:</span><span>${summary.buyCount}</span></div>
      <br/>
      <div class="amount-row"><span>HUF forgalom:</span><span>${formatAmount(summary.totalHufTurnover)} Ft</span></div>
      <div class="amount-row"><span>Díjbevétel:</span><span>${formatAmount(summary.totalFees)} Ft</span></div>
    </div>
    <div class="line"></div>
    <div class="amount-row"><span>Nyitó egyenleg:</span><span>${formatAmount(summary.openingBalance)} Ft</span></div>
    <div class="amount-row"><span>Záró egyenleg:</span><span>${formatAmount(summary.closingBalance)} Ft</span></div>
    ${discrepancyHtml}
  `;
}

function generateConversionHtml(data: PrintReceiptData): string {
  return `
    <div class="section">
      <div class="amount-row"><span>Forrás:</span><span>${formatAmount(data.sourceAmount)} ${escHtml(data.sourceCurrencyCode ?? '—')}</span></div>
      <div class="amount-row"><span>Cél:</span><span>${formatAmount(data.targetAmount)} ${escHtml(data.targetCurrencyCode ?? '—')}</span></div>
      <div class="amount-row"><span>Köztes HUF:</span><span>${formatAmount(data.hufAmount)} Ft</span></div>
      <div class="amount-row"><span>Árfolyam:</span><span>${formatRate(data.rate)}</span></div>
      ${data.note ? `<div class="amount-row"><span>Megjegyzés:</span><span>${escHtml(data.note)}</span></div>` : ''}
    </div>
  `;
}

function generateHandlingFeeHtml(data: PrintReceiptData): string {
  return `
    <div class="section">
      <div class="bold total">Kezelési díj: ${formatAmount(data.hufAmount ?? 0)} Ft</div>
      ${data.sealNumber ? `<div class="amount-row"><span>Plombaszám:</span><span>${escHtml(data.sealNumber)}</span></div>` : ''}
      ${data.originalReceiptNumber ? `<div class="amount-row"><span>Alapbizonylat:</span><span>${escHtml(data.originalReceiptNumber)}</span></div>` : ''}
    </div>
  `;
}

function generateCashStatusHtml(data: PrintReceiptData): string {
  return `
    <div class="section">
      <div class="bold">PÉNZTÁR ÁLLÁS</div>
      ${data.hufAmount !== undefined ? `<div class="amount-row"><span>HUF egyenleg:</span><span>${formatAmount(data.hufAmount)} Ft</span></div>` : ''}
      ${data.note ? `<div class="amount-row"><span>Megjegyzés:</span><span>${escHtml(data.note)}</span></div>` : ''}
    </div>
  `;
}

function generateVaultClosingHtml(data: PrintReceiptData): string {
  return `
    <div class="section">
      <div class="bold">ÉRTÉKTÁRI ZÁRÁS</div>
      ${data.hufAmount !== undefined ? `<div class="amount-row"><span>Összeg:</span><span>${formatAmount(data.hufAmount)} Ft</span></div>` : ''}
      ${data.sealNumber ? `<div class="amount-row"><span>Plombaszám:</span><span>${escHtml(data.sealNumber)}</span></div>` : ''}
      ${data.note ? `<div class="amount-row"><span>Megjegyzés:</span><span>${escHtml(data.note)}</span></div>` : ''}
    </div>
  `;
}

function generateKktgTransferHtml(data: PrintReceiptData): string {
  return `
    <div class="section">
      <div class="bold total">Összeg: ${formatAmount(data.hufAmount ?? 0)} Ft</div>
      ${data.sealNumber ? `<div class="amount-row"><span>Plombaszám:</span><span>${escHtml(data.sealNumber)}</span></div>` : ''}
      ${data.transferTarget ? `<div class="amount-row"><span>Cél iroda:</span><span>${escHtml(data.transferTarget)}</span></div>` : ''}
      ${data.note ? `<div class="amount-row"><span>Megjegyzés:</span><span>${escHtml(data.note)}</span></div>` : ''}
    </div>
  `;
}

/** Egyszerű HTML escape az XSS elkerülésére. */
function escHtml(str: string): string {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

// ============================================================================
// Nyomtatási stratégiák
// ============================================================================

/** A konfig kulcs, amiben a preferált nyomtató neve van tárolva (SQLite config). */
export const PRINTER_CONFIG_KEY = 'printer.deviceName';

/** Soros (COM) port konfig kulcs — ha be van állítva, a blokknyomtató soros porton nyomtat. */
export const SERIAL_PORT_CONFIG_KEY = 'printer.serialPort';

/**
 * Soros blokknyomtató küldés (Star SP500 vagy kompatibilis).
 * Ha van konfigurált COM port, közvetlenül soros portra küldi az ESC/POS adatot.
 *
 * @returns true ha sikerült nyomtatni, false ha nincs soros nyomtató konfigurálva
 */
async function printToSerialPrinter(data: PrintReceiptData, serialPort?: string): Promise<boolean> {
  if (!serialPort) return false;

  try {
    const { printReceiptToSerial } = await import('./serial-printer');
    return await printReceiptToSerial(data, { port: serialPort });
  } catch (err) {
    log.warn('[PRINTER] Soros nyomtató hiba, fallback Electron print-re:', err);
    return false;
  }
}

/**
 * Nyomtatás Electron beépített webContents.print() API-n keresztül.
 * Rejtett BrowserWindow-ban rendereli a bizonylat HTML-t, majd a rendszer
 * nyomtató-driverén keresztül kinyomtatja.
 *
 * @param html - A bizonylat HTML tartalma
 * @param printerName - Opcionális nyomtató név; ha nincs megadva, az alapértelmezett nyomtatót használja
 * @returns true ha a nyomtatás sikerült
 */
async function printViaElectron(html: string, printerName?: string): Promise<boolean> {
  let printWindow: BrowserWindow | null = null;

  try {
    // Rejtett ablak létrehozása a bizonylat rendereléshez
    printWindow = new BrowserWindow({
      show: false,
      width: 302,   // ~80mm @ 96 DPI
      height: 800,
      webPreferences: {
        contextIsolation: true,
        nodeIntegration: false,
      },
    });

    // HTML tartalom betöltése data URL-ként
    await printWindow.loadURL(
      `data:text/html;charset=utf-8,${encodeURIComponent(html)}`,
    );

    // Nyomtatási opciók — csendes nyomtatás (nincs dialógus)
    const printOptions: Electron.WebContentsPrintOptions = {
      silent: true,
      printBackground: true,
      margins: { marginType: 'none' },
      pageSize: { width: 80000, height: 297000 }, // 80mm x 297mm mikronban
    };

    // Ha van megadott nyomtató név, azt használjuk
    if (printerName) {
      printOptions.deviceName = printerName;
    }

    // Nyomtatás végrehajtása
    const success = await new Promise<boolean>((resolve) => {
      printWindow!.webContents.print(printOptions, (success, failureReason) => {
        if (!success) {
          log.warn(`[PRINTER] Nyomtatás sikertelen: ${failureReason}`);
        }
        resolve(success);
      });
    });

    return success;
  } catch (err) {
    log.error('[PRINTER] printViaElectron hiba:', err);
    return false;
  } finally {
    // Rejtett ablak bezárása
    if (printWindow && !printWindow.isDestroyed()) {
      printWindow.close();
    }
  }
}

// ============================================================================
// Fő belépési pont — IPC handler-ből hívva
// ============================================================================

/**
 * Bizonylat nyomtatás — fő belépési pont.
 *
 * Nyomtatási sorrend:
 *   1. Ha USB hőnyomtató konfigurálva van → ESC/POS közvetlen nyomtatás
 *   2. Egyébként → Electron webContents.print() rendszer nyomtatón keresztül
 *
 * Hibajelzések:
 *   - Nyomtató offline / nem elérhető → false visszatérés, log üzenet
 *   - Papír kifogyott → a rendszer driver kezeli, false visszatérés
 *
 * @param data - A bizonylat adatai
 * @param printerName - Opcionális nyomtató név felülírás
 * @returns true ha a nyomtatás sikeresen elindult
 */
export async function printReceipt(
  data: PrintReceiptData,
  printerName?: string,
  serialPort?: string,
): Promise<boolean> {
  try {
    log.info(`[PRINTER] Nyomtatás indítása: ${data.type} ${data.receiptNumber}`);

    // 1. Próbáljuk soros blokknyomtatón (Star SP500 / kompatibilis)
    if (serialPort) {
      const serialSuccess = await printToSerialPrinter(data, serialPort);
      if (serialSuccess) {
        log.info(`[PRINTER] Soros blokknyomtató (${serialPort}): OK — ${data.receiptNumber}`);
        return true;
      }
      log.warn(`[PRINTER] Soros port ${serialPort} sikertelen, Electron fallback...`);
    }

    // 2. Fallback: Electron rendszer nyomtató (HTML alapú)
    log.info('[PRINTER] Electron print fallback...');
    const html = await generateReceiptHtml(data);
    const electronSuccess = await printViaElectron(html, printerName);

    if (electronSuccess) {
      log.info(`[PRINTER] Electron print: OK — ${data.receiptNumber}`);
    } else {
      log.error(`[PRINTER] Nyomtatás sikertelen — ${data.receiptNumber}. Ellenőrizd a nyomtató állapotát (offline / papír kifogyott).`);
    }

    return electronSuccess;
  } catch (err) {
    log.error('[PRINTER] Váratlan nyomtatási hiba:', err);
    return false;
  }
}
