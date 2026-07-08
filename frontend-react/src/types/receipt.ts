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
  | 'kktg_transfer'

/**
 * Multi-line aggregált vétel/eladás (2026-06-04) egyetlen valuta-sora.
 * Egy aggregált tranzakció (egy bizonylatszám) több valuta-tételt tartalmazhat.
 */
export interface TransactionReceiptLine {
  currencyCode: string
  foreignAmount: number
  rate: number
  /** A sor nyers (kerekítetlen) HUF-értéke — a teljes bizonylat fejléce hordozza az
   *  összegzett és EGYSZER kerekített végösszeget (lásd `PrintReceiptData.roundedHufAmount`). */
  hufAmount: number
  /** Penztar-batch C (2026-06-12): a sor deviza-státusza — többsoros nyugtán a sorok
   *  eltérhetnek (soronkénti B/K toggle); a fejléc `foreignStatus` csak akkor kitöltött,
   *  ha minden sor azonos. */
  foreignStatus?: 'DOMESTIC' | 'FOREIGN'
}

export interface PrintReceiptData {
  type: PrintJobType
  companyType: 'BEST_CHANGE' | 'EXPRESSZ'
  receiptNumber: string
  branchCode: string
  cashierName: string
  date: string
  time: string
  currencyCode?: string
  foreignAmount?: number
  rate?: number
  hufAmount?: number
  roundedHufAmount?: number
  roundingDiff?: number
  customerName?: string
  customerDocType?: string
  customerDocNumber?: string
  customerAddress?: string
  customerMotherName?: string
  customerBirthPlace?: string
  customerBirthDate?: string
  customerNationality?: string
  foreignStatus?: 'DOMESTIC' | 'FOREIGN'
  handlingFee?: number
  /**
   * Multi-line aggregált vétel/eladás (2026-06-04): ha jelen van, a bizonylat ezeket a
   * valuta-sorokat listázza EGYETLEN bizonylatszám alatt, és a fejléc
   * hufAmount/roundedHufAmount/roundingDiff a TELJES (összegzett, egyszer kerekített)
   * összeget hordozza — pontosan ahogy a backend TransactionMultiLineService rögzíti.
   * Egysoros bizonylatnál nincs jelen → a viselkedés VÁLTOZATLAN.
   */
  transactionLines?: TransactionReceiptLine[]
  /**
   * Codex PR #1102 P1: a Pmt. 300k-s küszöb az AML-lel azonos FIZETENDŐ összegre
   * (subtotal + kezelési díj − kedvezmény) vonatkozik — egysoros bizonylaton a
   * hufAmount a díj nélküli sorérték. Hiányában fallback: roundedHufAmount ?? hufAmount.
   */
  payableHufAmount?: number
  customerIsPep?: boolean
  sourceOfFunds?: string
  /** Penztar-batch C.1 (2026-06-12): PEP-minőség (pl. CSALADTAG / PARLAMENTI) — a PEP-sorban jelenik meg. */
  customerPepKind?: string
  /** C.1: saját nevében jár-e el (Pmt. jogcím nyilatkozat); false + actorName → képviselt fél adatai. */
  customerOnOwnBehalf?: boolean
  customerActorName?: string
  customerActorBirthPlace?: string
  customerActorBirthDate?: string
  customerActorMotherName?: string
  customerActorNationality?: string
  customerActorDocumentType?: string
  customerActorDocumentNumber?: string
  customerActorAddress?: string
  /** V325 (Batch3-C): jogi személy ügyfél (legacy JOGISZEMELY) — a 300k+ bizonylat jogi blokkjához. */
  isLegalEntityCustomer?: boolean
  legalEntityName?: string
  legalEntitySeat?: string
  legalEntityTaxNumber?: string
  legalDeedNumber?: string
  /** V325: tényleges tulajdonosok (legacy UJTULAJOK, max 4). */
  beneficialOwners?: ReceiptBeneficialOwner[]
  navReceiptNumber?: string
  sealNumber?: string
  vatExemptionText?: string
  companyPhone?: string
  companyTaxNumber?: string
  stornoReason?: string
  originalReceiptNumber?: string
  sourceCurrencyCode?: string
  sourceAmount?: number
  targetCurrencyCode?: string
  targetAmount?: number
  note?: string
  transferTarget?: string
  transferNote?: string
  /** FR-2 (átadás-átvétel): a kért kézbesítési dátum (a fejléc `date` a kiállítás dátuma). */
  deliveryDate?: string
  /** FR-5 (átadás-átvétel): a szállítást végző neve a szállítólevélen. */
  carrierName?: string
  /** FR-1: a bejelentkezett értéktár SAJÁT helyi címe a fejléchez (a cégnév marad, csak a cím dinamikus). */
  vaultAddress?: string
  /** FR-2 (fejléc-javítás 2026-06-11): az értéktár telefonszáma a `branch.phone`-ból. Hiány esetén nincs telefon sor (TBD-3). */
  vaultPhone?: string
  /** Batch2-E (2026-06-12): a kiállító értéktár azonosítója + neve a fejlécben (pl. "BR075 - Békéscsaba Értéktár") — eddig sosem volt a fejléc-template része. */
  vaultBranchLabel?: string
  /** FR-2: a bizonylat típusa — 'handover' → „Átadási bizonylat", 'receipt' → „Átvételi bizonylat". */
  transferDocType?: 'handover' | 'receipt'
  /** FR-13..15: sztornó bizonylat-e (fejléc „SZTORNÓ BIZONYLAT" + indoklás). A `stornoReason` hordozza az indoklást. */
  isStorno?: boolean
  /** FR-17..19: opcionális címletezés sorai (darab × névleges érték). Üres/hiány → a bizonylaton nem jelenik meg. */
  denominations?: TransferDenominationLine[]
  /**
   * Penztar-batch A.1/A.2 (2026-06-12): több-valutás átadólap sorai a bizonylaton.
   * Ha jelen van (≥1 sor), az átadás-átvétel bizonylat EZEKET listázza a fejléc
   * currencyCode/foreignAmount helyett (amely az első sort hordozza — kompatibilitás).
   */
  transferLines?: TransferReceiptLine[]
  closingSummary?: ClosingPrintData
}

/** V325 (Batch3-C): egy tényleges tulajdonos a bizonylaton (legacy UJTULAJOK mezők). */
export interface ReceiptBeneficialOwner {
  name: string
  address?: string
  birthPlace?: string
  birthDate?: string
  nationality?: string
  residenceAbroad?: string
  interestNature?: string
  interestExtent?: string
  isPep?: boolean
}

/** Penztar-batch A.1: egy valuta-sor a több-valutás átadás-átvétel bizonylaton. */
export interface TransferReceiptLine {
  currencyCode: string
  amount: number
}

/** FR-17..19: egy címletezési sor a bizonylaton (darab × névleges érték = összesen). */
export interface TransferDenominationLine {
  quantity: number
  faceValue: number
  currencyCode?: string
  lineTotal: number
}

export interface ClosingPrintData {
  totalTransactions: number
  sellCount: number
  buyCount: number
  totalHufTurnover: number
  totalFees: number
  openingBalance: number
  closingBalance: number
  discrepancies: Array<{
    currencyCode: string
    expected: number
    actual: number
    difference: number
  }>
}

export interface QRData {
  bizonylatSzam: string
  datum: string
  osszeg: number
  valuta: string
  adoszam: string
  penztarKod: number
}
