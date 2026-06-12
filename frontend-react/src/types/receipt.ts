/**
 * Bizonylat-related shared types.
 * Portolva a penztar-client/src/types/index.ts fájlból.
 */

export type PrintJobType =
  | 'sell'
  | 'buy'
  | 'transfer'
  | 'storno'
  | 'cancelled_transaction'
  | 'conversion'
  | 'closing'
  | 'handling_fee'
  | 'cash_status'
  | 'vault_closing'
  | 'kktg_transfer';

/**
 * Multi-line aggregált vétel/eladás (2026-06-04) egyetlen valuta-sora.
 * Egy aggregált tranzakció (egy bizonylatszám) több valuta-tételt tartalmazhat.
 */
export interface TransactionReceiptLine {
  currencyCode: string;
  foreignAmount: number;
  rate: number;
  /** A sor nyers (kerekítetlen) HUF-értéke — a teljes bizonylat fejléce hordozza az
   *  összegzett és EGYSZER kerekített végösszeget (lásd `PrintReceiptData.roundedHufAmount`). */
  hufAmount: number;
}

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
  /**
   * Multi-line aggregált vétel/eladás (2026-06-04): ha jelen van, a bizonylat ezeket a
   * valuta-sorokat listázza EGYETLEN bizonylatszám alatt, és a fejléc
   * hufAmount/roundedHufAmount/roundingDiff a TELJES (összegzett, egyszer kerekített)
   * összeget hordozza — pontosan ahogy a backend TransactionMultiLineService rögzíti.
   * Egysoros bizonylatnál nincs jelen → a viselkedés VÁLTOZATLAN.
   */
  transactionLines?: TransactionReceiptLine[];
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
  /** FR-2 (átadás-átvétel): a kért kézbesítési dátum (a fejléc `date` a kiállítás dátuma). */
  deliveryDate?: string;
  /** FR-5 (átadás-átvétel): a szállítást végző neve a szállítólevélen. */
  carrierName?: string;
  /** FR-1: a bejelentkezett értéktár SAJÁT helyi címe a fejléchez (a cégnév marad, csak a cím dinamikus). */
  vaultAddress?: string;
  /** FR-2 (fejléc-javítás 2026-06-11): az értéktár telefonszáma a `branch.phone`-ból. Hiány esetén nincs telefon sor (TBD-3). */
  vaultPhone?: string;
  /** FR-2: a bizonylat típusa — 'handover' → „Átadási bizonylat", 'receipt' → „Átvételi bizonylat". */
  transferDocType?: 'handover' | 'receipt';
  /** FR-13..15: sztornó bizonylat-e (fejléc „SZTORNÓ BIZONYLAT" + indoklás). A `stornoReason` hordozza az indoklást. */
  isStorno?: boolean;
  /** FR-17..19: opcionális címletezés sorai (darab × névleges érték). Üres/hiány → a bizonylaton nem jelenik meg. */
  denominations?: TransferDenominationLine[];
  /**
   * Penztar-batch A.1/A.2 (2026-06-12): több-valutás átadólap sorai a bizonylaton.
   * Ha jelen van (≥1 sor), az átadás-átvétel bizonylat EZEKET listázza a fejléc
   * currencyCode/foreignAmount helyett (amely az első sort hordozza — kompatibilitás).
   */
  transferLines?: TransferReceiptLine[];
  closingSummary?: ClosingPrintData;
}

/** Penztar-batch A.1: egy valuta-sor a több-valutás átadás-átvétel bizonylaton. */
export interface TransferReceiptLine {
  currencyCode: string;
  amount: number;
}

/** FR-17..19: egy címletezési sor a bizonylaton (darab × névleges érték = összesen). */
export interface TransferDenominationLine {
  quantity: number;
  faceValue: number;
  currencyCode?: string;
  lineTotal: number;
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
