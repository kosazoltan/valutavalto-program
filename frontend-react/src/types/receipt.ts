/**
 * Bizonylat-related shared types.
 * Portolva a penztar-client/src/types/index.ts fájlból.
 */

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

export interface QRData {
  bizonylatSzam: string;
  datum: string;
  osszeg: number;
  valuta: string;
  adoszam: string;
  penztarKod: number;
}
