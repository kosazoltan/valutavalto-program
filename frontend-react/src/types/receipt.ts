/**
 * Bizonylat-related shared types.
 * Portolva a penztar-client/src/types/index.ts fájlból.
 */

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
  foreignStatus?: 'DOMESTIC' | 'FOREIGN';
  handlingFee?: number;
  customerIsPep?: boolean;
  sourceOfFunds?: string;
  navReceiptNumber?: string;
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
  /** FR-5 (átadás-átvétel): a szállítást végző neve a szállítólevélen. */
  carrierName?: string;
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
