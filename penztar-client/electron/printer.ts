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
  | 'cancelled_transaction'
  | 'conversion'
  | 'closing'
  | 'handling_fee'
  | 'cash_status'
  | 'vault_closing'
  | 'kktg_transfer'
  | 'rate_change';

/**
 * Multi-line aggregált vétel/eladás (2026-06-04) egyetlen valuta-sora.
 * Egy aggregált tranzakció (egy bizonylatszám) több valuta-tételt tartalmazhat.
 */
export interface TransactionReceiptLine {
  currencyCode: string;
  foreignAmount: number;
  rate: number;
  /** A sor nyers (kerekítetlen) HUF-értéke. A teljes bizonylat fejléce hordozza az
   *  összegzett és EGYSZER kerekített végösszeget (lásd `roundedHufAmount`). */
  hufAmount: number;
  /** Penztar-batch C (2026-06-12): a sor deviza-státusza — vegyes B/K nyugtán soronként jelenik meg. */
  foreignStatus?: 'DOMESTIC' | 'FOREIGN';
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
  versionNumber?: number;
  validFrom?: string;
  officialRate?: number | null;
  baseBuyRate?: number;
  baseSellRate?: number;
  limit1Amount?: number | null;
  limit1BuyRate?: number | null;
  limit1SellRate?: number | null;
  limit2Amount?: number | null;
  limit2BuyRate?: number | null;
  limit2SellRate?: number | null;
  limit3Amount?: number | null;
  limit3BuyRate?: number | null;
  limit3SellRate?: number | null;
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
  /**
   * Penztar-batch C.1/C.2 (2026-06-12, user-kérés): deviza-státusz MINDEN vétel/eladás
   * bizonylaton + 300k+ felett PEP-sor és JOGCÍM NYILATKOZAT — a kanonikus backend
   * EscPosReceiptService template-jével egyezően.
   */
  foreignStatus?: 'DOMESTIC' | 'FOREIGN';
  /**
   * Codex PR #1102 P1: a Pmt. 300k-s küszöb az AML-lel azonos FIZETENDŐ összegre
   * (subtotal + kezelési díj − kedvezmény) vonatkozik — egysoros bizonylaton a
   * hufAmount a díj NÉLKÜLI sorérték, ezért a küszöbhöz külön mező kell.
   * Hiányában fallback: roundedHufAmount ?? hufAmount.
   */
  payableHufAmount?: number;
  customerIsPep?: boolean;
  customerPepKind?: string;
  sourceOfFunds?: string;
  customerOnOwnBehalf?: boolean;
  customerActorName?: string;
  customerActorBirthPlace?: string;
  customerActorBirthDate?: string;
  customerActorMotherName?: string;
  customerActorNationality?: string;
  customerActorDocumentType?: string;
  customerActorDocumentNumber?: string;
  customerActorAddress?: string;
  /** V325 (Batch3-C): jogi személy ügyfél (legacy JOGISZEMELY) — a 300k+ bizonylat jogi blokkjához. */
  isLegalEntityCustomer?: boolean;
  legalEntityName?: string;
  legalEntitySeat?: string;
  legalEntityTaxNumber?: string;
  legalDeedNumber?: string;
  /** V325: tényleges tulajdonosok (legacy UJTULAJOK, max 4). */
  beneficialOwners?: Array<{
    name: string;
    address?: string;
    birthPlace?: string;
    birthDate?: string;
    nationality?: string;
    residenceAbroad?: string;
    interestNature?: string;
    interestExtent?: string;
    isPep?: boolean;
  }>;
  /** Penztar-batch A.1 (PR #1101): több-valutás átadólap sorai — ha jelen van, a transfer
   *  bizonylat EZEKET listázza a fejléc currencyCode/foreignAmount helyett. */
  transferLines?: Array<{ currencyCode: string; amount: number }>;
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
  transferDocType?: 'handover' | 'receipt';
  isStorno?: boolean;
  vaultAddress?: string;
  /** Fejléc-javítás 2026-06-11 (FR-2): az értéktár telefonszáma a branch.phone-ból. Hiány → nincs telefon sor (TBD-3). */
  vaultPhone?: string;
  /** Batch2-E (2026-06-12): a kiállító értéktár azonosítója + neve a fejlécben (pl. "BR075 - Békéscsaba Értéktár") — eddig sosem volt a fejléc-template része. */
  vaultBranchLabel?: string;
  denominations?: Array<{ quantity: number; faceValue: number }>;
  /** FR-2 (átadás-átvétel): a kért kézbesítési dátum (a fejléc dátuma a kiállítás dátuma). */
  deliveryDate?: string;
  /** FR-5 (átadás-átvétel): a szállítást végző neve a szállítólevélen. */
  carrierName?: string;
  /**
   * Multi-line aggregált vétel/eladás (2026-06-04): ha jelen van, a bizonylat ezeket a
   * valuta-sorokat listázza EGYETLEN bizonylatszám alatt, és a fejléc
   * hufAmount/roundedHufAmount/roundingDiff a TELJES (összegzett, egyszer kerekített)
   * összeget hordozza. Egysoros bizonylatnál nincs jelen → a viselkedés VÁLTOZATLAN.
   */
  transactionLines?: TransactionReceiptLine[];
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
  cancelled_transaction: 'MEGSZAKÍTOTT TRANZAKCIÓ',
  conversion: 'KONVERZIÓS BIZONYLAT',
  closing: 'NAPI ZÁRÁS',
  handling_fee: 'KEZELÉSI DÍJ BIZONYLAT',
  cash_status: 'PÉNZTÁR ÁLLÁS',
  vault_closing: 'ÉRTÉKTÁRI ZÁRÁS',
  kktg_transfer: 'KKTG ÁTADÁS-ÁTVÉTEL',
  rate_change: 'ÁRFOLYAMVÁLTOZÁS',
};

function getJobTypeLabel(data: PrintReceiptData): string {
  if (data.type === 'transfer') {
    if (data.isStorno) return 'SZTORNÓ BIZONYLAT';
    return data.transferDocType === 'receipt' ? 'ÁTVÉTELI BIZONYLAT' : 'ÁTADÁSI BIZONYLAT';
  }
  return JOB_TYPE_LABELS[data.type];
}

// ============================================================================
// Penztar-batch C (2026-06-12): Pmt.-tartalom segédek — a kanonikus backend
// EscPosReceiptService küszöbével/szövegeivel egyezően.
// ============================================================================

/** Pmt. 300k Ft küszöb: e felett PEP-sor + JOGCÍM NYILATKOZAT kötelező a bizonylaton. */
export const HIGH_VALUE_THRESHOLD = 300000;

export function isHighValueReceipt(data: PrintReceiptData): boolean {
  // Codex PR #1102 P1: az AML-lel azonos fizetendő összeg az alap (díj+kedvezmény után);
  // a payableHufAmount-ot a bizonylat-építő adja át, fallback a fejléc-összegre.
  return (
    Math.abs(data.payableHufAmount ?? data.roundedHufAmount ?? data.hufAmount ?? 0) >=
    HIGH_VALUE_THRESHOLD
  );
}

/** Deviza-státusz szöveg: NULL → „—" (ismeretlen, régi adat), FOREIGN/DOMESTIC explicit. */
export function foreignStatusText(status: 'DOMESTIC' | 'FOREIGN' | undefined): string {
  if (status == null) return '—';
  return status === 'FOREIGN' ? 'Külföldi' : 'Belföldi';
}

/**
 * Batch2-D: a PEP-minőség kód (CustomerPanel PepKind enum) emberi szövege a
 * bizonylatra — a backend ReceiptGeneratorService.buildPepStatusText kategória-
 * szövegeivel egyezően. Ismeretlen kód → maga a kód (defenzív).
 */
export function pepKindReceiptText(kind: string | undefined): string | undefined {
  const k = kind?.trim();
  if (!k) return undefined;
  switch (k) {
    case 'CSALADTAG':
      return 'kiemelt közszereplő családtagja';
    case 'KOZELI_MUNKATARS':
      return 'kiemelt közszereplő közeli munkatársa';
    case 'KORMANYFO':
      return 'kormányfő / miniszter / államtitkár';
    case 'PARLAMENTI':
      return 'országgyűlési / önkormányzati képviselő';
    case 'NAV_VEZETO':
      return 'NAV / állami vállalat felsővezetés';
    case 'EGYEB':
      return 'egyéb kiemelt közszereplő';
    default:
      return k;
  }
}

/** PEP-sor szövege (300k+): minőséggel, ha ismert. */
export function pepStatusText(data: PrintReceiptData): string {
  const kindText = pepKindReceiptText(data.customerPepKind);
  return data.customerIsPep
    ? `Az ügyfél kiemelt közszereplő${kindText ? ` (${kindText})` : ''}`
    : 'Az ügyfél nem közszereplő';
}

/**
 * JOGCÍM NYILATKOZAT sorai (plain text, ESC/POS + soros nyomtatóra is alkalmas
 * rövid sorokkal) — a backend EscPosReceiptService:696-752 logikájának tükre:
 * saját nevemben / képviselt fél adatai + pénzeszköz forrása (tördelt).
 */
export function buildSourceDeclarationLines(data: PrintReceiptData): string[] {
  const lines: string[] = [];
  lines.push('Büntetőjogi felelősségem tudatá-');
  lines.push('ban nyilatkozom, hogy a fenti');
  lines.push('tranzakciót');
  if (data.customerOnOwnBehalf === false && data.customerActorName) {
    lines.push(data.customerActorName);
    lines.push('nevében bonyolítom,');
    // Pmt. 6.§ (2): a képviselt félre is teljes azonosítás — adatai a bizonylatra.
    lines.push('Képviselt fél adatai:');
    if (data.customerActorBirthPlace) lines.push(`  szül.hely: ${data.customerActorBirthPlace}`);
    if (data.customerActorBirthDate) lines.push(`  szül.idő: ${data.customerActorBirthDate}`);
    if (data.customerActorMotherName) lines.push(`  anyja: ${data.customerActorMotherName}`);
    if (data.customerActorNationality) lines.push(`  állampolg.: ${data.customerActorNationality}`);
    if (data.customerActorDocumentNumber) {
      lines.push(
        `  ${data.customerActorDocumentType ?? 'okmány'}: ${data.customerActorDocumentNumber}`,
      );
    }
    if (data.customerActorAddress) lines.push(`  lakcím: ${data.customerActorAddress}`);
  } else {
    lines.push('saját nevemben bonyolítom,');
  }

  // Batch2-D (Fabulya-teszt 2026-06-12): a legacy Jogcimnyilatkozat (BLOKNYOM
  // Unit2.pas:1437-1493) a saját neves/képviselt ág UTÁN kötelezően nyomtatta:
  // (a) az ELSŐ SZEMÉLYŰ közszereplő-nyilatkozatot, (b) az 5 munkanapos
  // adatváltozás-bejelentési klauzulát, (c) a forrás-sort, (d) a dedikált
  // ügyfél-aláírást. Eddig csak a „saját neves" rész volt meg — pótolva.
  // Codex P1 #1110: ISMERETLEN PEP-státusznál (null/undefined — régi queue-sorok,
  // hiányos hívók) SEM pozitív, SEM negatív nyilatkozat nem nyomtatható — a backend
  // EscPos-út azonos guardja (customerIsPep != null) a minta.
  if (data.customerIsPep != null) {
    lines.push('');
    if (data.customerIsPep) {
      lines.push('Kiemelt közszereplő (vagyok),');
      const kindText = pepKindReceiptText(data.customerPepKind);
      if (kindText) {
        lines.push(`mint: ${kindText}`);
      }
    } else {
      lines.push('Nem (vagyok) kiemelt közszereplő.');
    }
  }

  lines.push('');
  lines.push('Tudomásom van arról, hogy 5 (öt)');
  lines.push('munkanapon belül köteles vagyok');
  lines.push('bejelenteni a szolgáltatónak a fenti');
  lines.push('adatokban, vagy a saját adataimban');
  lines.push('bekövetkező esetleges változásokat,');
  lines.push('és e kötelezettség elmulasztásából');
  lines.push('eredő kár engem terhel.');

  if (data.sourceOfFunds && data.sourceOfFunds.trim() !== '') {
    lines.push('');
    lines.push('Pénzeszközöm forrása:');
    const src = data.sourceOfFunds.trim();
    const maxLen = 38; // 40-42 karakteres hőnyomtató-sor, 2 char behúzással
    for (let i = 0; i < src.length; i += maxLen) {
      lines.push(`  ${src.substring(i, Math.min(i + maxLen, src.length))}`);
    }
  }

  // Legacy: dedikált ügyfél-aláírás a nyilatkozat alatt (a bizonylat-végi
  // Pénztáros/Ügyfél kettős aláírástól függetlenül).
  lines.push('');
  lines.push('');
  lines.push('.....................................');
  lines.push('          ügyfél aláírása');
  return lines;
}

/**
 * V325 (Batch3-C): JOGI SZEMÉLY ügyfél + TÉNYLEGES TULAJDONOSOK blokk sorai —
 * a legacy BLOKNYOM Ugyfelnyomtatas jogi ágának (Unit2.pas:1331-1433) tükre,
 * a backend EscPosReceiptService.printLegalEntityBlock-kal egyezően:
 * jogi személy neve/székhelye/okiratszám/adószám + megbízott (= a pultnál álló
 * ügyfél) neve/címe + tényleges tulajdonosok (max 4). A megbízott PEP-státusza
 * a JOGCÍM blokk első személyű nyilatkozatában.
 */
export function buildLegalEntityLines(data: PrintReceiptData): string[] {
  if (!data.isLegalEntityCustomer) return [];
  const lines: string[] = [];
  lines.push('');
  if (data.legalEntityName) {
    lines.push('Jogi személy neve:');
    lines.push(`  ${data.legalEntityName}`);
  }
  if (data.legalEntitySeat) {
    lines.push('Jogi személy székhelye:');
    lines.push(`  ${data.legalEntitySeat}`);
  }
  if (data.legalDeedNumber) lines.push(`Okiratszám: ${data.legalDeedNumber}`);
  if (data.legalEntityTaxNumber) lines.push(`Adószám: ${data.legalEntityTaxNumber}`);
  if (data.customerName) {
    lines.push('Megbízott neve:');
    lines.push(`  ${data.customerName}`);
  }
  if (data.customerAddress) {
    lines.push('Megbízott címe:');
    lines.push(`  ${data.customerAddress}`);
  }
  const owners = data.beneficialOwners ?? [];
  if (owners.length > 0) {
    lines.push('----------------------------------------');
    lines.push('Tényleges tulajdonosok adatai:');
    owners.forEach((o, i) => {
      lines.push('');
      lines.push(`${i + 1}. tulajdonos:`);
      lines.push(`  ${o.name}`);
      if (o.address) lines.push(`  ${o.address}`);
      const szul = `${o.birthPlace ?? ''} ${o.birthDate ?? ''}`.trim();
      if (szul) lines.push(`  ${szul}`);
      if (o.nationality) lines.push(`  ${o.nationality}`);
      if (o.residenceAbroad) lines.push(`  ${o.residenceAbroad}`);
      if (o.interestNature) lines.push(`  ${o.interestNature}`);
      if (o.interestExtent) lines.push(`  ${o.interestExtent}`);
      lines.push(o.isPep ? '  A tulaj közszereplő' : '  Nem közszereplő');
    });
  }
  return lines;
}

/**
 * Batch2-D: orosz EUR-vásárlási nyilatkozat triggere — a legacy EzoroszUgyfel
 * (BLOKNYOM Unit2.pas:1929-1938) tükre: EUR eladás (az ügyfél EUR-t VESZ)
 * + orosz állampolgár + fizetendő >= 300 000 Ft.
 */
export function isRussianEurPurchase(data: PrintReceiptData): boolean {
  if (data.type !== 'sell') return false;
  if (!isHighValueReceipt(data)) return false;
  const nat = (data.customerNationality ?? '').trim().toLowerCase();
  if (nat !== 'ru' && nat !== 'rus' && !nat.includes('orosz') && !nat.includes('russia'))
    return false;
  const hasEur =
    data.currencyCode === 'EUR' ||
    (data.transactionLines ?? []).some((l) => l.currencyCode === 'EUR');
  return hasEur;
}

/**
 * Batch2-D: kétnyelvű személyes-használat nyilatkozat (legacy OroszNyilatkozat,
 * BLOKNYOM Unit2.pas:1940-1963 tükre).
 */
export function buildRussianDeclarationLines(data: PrintReceiptData): string[] {
  const name = (data.customerName ?? '').trim().substring(0, 30);
  return [
    '----------------------------------------',
    '        NYILATKOZAT/DECLARATION',
    '----------------------------------------',
    '',
    `Alulírott ${name}`,
    'kijelentem, hogy az általam vásárolt EUR',
    'valutát személyes használatra váltottam.',
    '',
    '/I declare that the just purchased',
    'EUR currency is for my personal usage.',
    '',
    '',
    '.....................................',
    '  ügyfél aláírása/signature of buyer',
  ];
}

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
  // Batch2-E (Fabulya-teszt 2026-06-12): a kiállító értéktár azonosítója + neve a fejlécben
  // — eddig sosem volt a template része (az értéktár neve csak a Kérő/Cél sorokban szerepelt).
  if (data.type === 'transfer' && data.vaultBranchLabel) {
    lines.push(data.vaultBranchLabel);
  }
  // FR-1/FR-3 (fejléc-javítás 2026-06-11): átadás-átvételnél a cím KIZÁRÓLAG a branch táblából
  // jövő vaultAddress; ha hiányzik, inkább nincs cím sor, mint félrevezető hardcode-olt székhely.
  const headerAddress = data.type === 'transfer' ? (data.vaultAddress ?? '') : company.address;
  if (headerAddress) {
    lines.push(headerAddress);
  }
  // FR-2/FR-3: átadás-átvételnél a telefonszám KIZÁRÓLAG a branch.phone-ból jön (vaultPhone);
  // hiány esetén nincs telefon sor (TBD-3) — a hardcode-olt cég-telefonszám transfer bizonylatra
  // nem kerülhet.
  const phone =
    data.type === 'transfer' ? (data.vaultPhone ?? '') : data.companyPhone || company.phone;
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
  lines.push(getJobTypeLabel(data));
  lines.push(CMD.NORMAL_SIZE);
  lines.push(CMD.BOLD_OFF);
  lines.push('');

  // Bizonylat szám
  lines.push(CMD.ALIGN_LEFT);
  lines.push(`Bizonylat: ${data.receiptNumber}`);
  lines.push(`Dátum:     ${data.date}  ${data.time}`);
  // Átadási bizonylaton a kérő iroda a törzsben „Kérő iroda" néven szerepel (nem duplikáljuk „Pénztár"-ként),
  // és a felelős neve „Ügyintéző" (nem „Pénztáros") — a bizonylat-előnézettel egyezően.
  if (data.type !== 'transfer') {
    lines.push(`Pénztár:   ${data.branchCode}`);
  }
  lines.push(`${data.type === 'transfer' ? 'Ügyintéző:' : 'Pénztáros:'} ${data.cashierName}`);
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
  } else if (data.type === 'cancelled_transaction') {
    lines.push(...generateCancelledTransactionLines(data));
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
  } else if (data.type === 'rate_change') {
    lines.push(...generateRateChangeLines(data));
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
    // C.1: PEP-sor 300k+ vétel/eladás bizonylaton (backend EscPosReceiptService:651-654 tükre).
    if ((data.type === 'sell' || data.type === 'buy') && isHighValueReceipt(data)) {
      lines.push(pepStatusText(data));
      // V325 (Batch3-C): jogi személy + tényleges tulajdonosok blokk.
      lines.push(...buildLegalEntityLines(data));
    }
  }

  // C.2 (user-kérés 2026-06-12): deviza-státusz MINDEN vétel/eladás bizonylaton —
  // azonosítási szinttől és összegtől FÜGGETLENÜL (backend EscPosReceiptService:659-671).
  if (data.type === 'sell' || data.type === 'buy') {
    lines.push('');
    lines.push(CMD.ALIGN_LEFT);
    lines.push('Az ügyletet készpénzben teljesítjük');
    lines.push(`Deviza-státusz: ${foreignStatusText(data.foreignStatus)}`);

    // C.1: JOGCÍM NYILATKOZAT — 300k+ Ft felett kötelező (Pmt.).
    if (isHighValueReceipt(data)) {
      lines.push('');
      lines.push(CMD.LINE);
      lines.push(CMD.BOLD_ON);
      lines.push('JOGCÍM NYILATKOZAT');
      lines.push(CMD.BOLD_OFF);
      lines.push(...buildSourceDeclarationLines(data));
    }

    // Batch2-D: orosz állampolgár EUR-vásárlása 300k+ felett → kétnyelvű
    // személyes-használat nyilatkozat (legacy OroszNyilatkozat tükre).
    if (isRussianEurPurchase(data)) {
      lines.push('');
      lines.push(...buildRussianDeclarationLines(data));
    }
  }

  // QR kód szekció (ha van bizonylat szám — KÖTELEZŐ a bizonylaton)
  if (
    data.receiptNumber &&
    (data.type === 'sell' || data.type === 'buy' || data.type === 'conversion')
  ) {
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

  // FR-5 (fejléc-javítás 2026-06-11): kötelező jogi nyilatkozat — KIZÁRÓLAG átvételi
  // bizonylaton (transferDocType === 'receipt'), átadásin és sztornón NEM.
  if (data.type === 'transfer' && data.transferDocType === 'receipt' && !data.isStorno) {
    lines.push('');
    lines.push(CMD.ALIGN_LEFT);
    lines.push('Büntetőjogi felelősségem tudatában,');
    lines.push('kijelentem, hogy a fentiekben felsorolt');
    lines.push('pénzkészletet a szállítóktól átvettem,');
    // FR-7 (bizonylat-doc 2. kör, 2026-06-12): "tökéletesen" → "tételesen".
    lines.push('azt tételesen átszámoltam.');
  }

  // Két aláírás sor (FR-6: átvételi bizonylaton a nyilatkozat ALATT — Átadó/Átvevő)
  lines.push('');
  lines.push(CMD.ALIGN_LEFT);
  lines.push('...............    ...............');
  lines.push(
    data.type === 'transfer' ? '  Átadó                Átvevő' : '  Pénztáros            Ügyfél',
  );

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

  const txLines = data.transactionLines;
  if (txLines && txLines.length > 0) {
    // Multi-line aggregate: minden valuta-sor listázva EGY bizonylatszám alatt.
    txLines.forEach((ln) => {
      // C.2: vegyes B/K nyugtán a sor deviza-státusza a valutakód mellett.
      const statusSuffix =
        data.foreignStatus == null && ln.foreignStatus != null
          ? ` (${foreignStatusText(ln.foreignStatus)})`
          : '';
      lines.push(`${ln.currencyCode}${statusSuffix}:`);
      lines.push(
        `  ${formatAmount(ln.foreignAmount)} × ${formatRate(ln.rate)} = ${formatAmount(ln.hufAmount)} Ft`,
      );
    });
  } else {
    lines.push(`Valutanem:   ${data.currencyCode ?? '—'}`);
    lines.push(`Összeg:      ${formatAmount(data.foreignAmount)} ${data.currencyCode ?? ''}`);
    lines.push(`Árfolyam:    ${formatRate(data.rate)}`);
  }
  lines.push('');
  lines.push(CMD.LINE);
  lines.push(CMD.BOLD_ON);
  lines.push(`HUF összeg:  ${formatAmount(data.hufAmount)} Ft`);

  if (
    data.roundedHufAmount !== undefined &&
    data.roundingDiff !== undefined &&
    data.roundingDiff !== 0
  ) {
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
  // FR-2 (átadási bizonylat): kérő iroda + cél iroda (kötelező mezők → mindig, „—" fallback) + valuta/összeg + forintosított érték.
  lines.push(`Kérő iroda:  ${data.branchCode || '—'}`);
  lines.push(`Cél iroda:   ${data.transferTarget ?? '—'}`);
  // A.1 (PR #1101): több-valutás átadólapon MINDEN sor a bizonylatra kerül.
  if (data.transferLines && data.transferLines.length > 0) {
    lines.push('Valuták és összegek:');
    for (const tl of data.transferLines) {
      lines.push(`  ${tl.currencyCode}: ${formatAmount(tl.amount)}`);
    }
  } else {
    lines.push(`Valutanem:   ${data.currencyCode ?? '—'}`);
    lines.push(`Összeg:      ${formatAmount(data.foreignAmount)} ${data.currencyCode ?? ''}`);
  }
  // Batch2-E: árfolyam a deviza-bizonylaton (HUF-átadásnál nincs árfolyam sor).
  // Copilot #1111: a fájl közös formatRate() formázójával (hu-HU, 2-4 tizedes).
  if (data.rate != null && data.currencyCode !== 'HUF') {
    lines.push(`Árfolyam:    ${formatRate(data.rate)}`);
  }
  // NFR-3: 5 Ft-ra kerekített forintosított érték (a kérő-oldalon számolt roundedHufAmount).
  if (data.roundedHufAmount !== undefined || data.hufAmount !== undefined) {
    lines.push(`Forint érték: ${formatAmount(data.roundedHufAmount ?? data.hufAmount)} HUF`);
  }
  // FR-5: szállító neve és plombaszám a szállítólevélen.
  if (data.carrierName) {
    lines.push(`Szállító:    ${data.carrierName}`);
  }
  if (data.sealNumber) {
    lines.push(`Plombaszám:  ${data.sealNumber}`);
  }
  // FR-2: kért kézbesítési dátum (a fejléc dátuma a kiállítás dátuma).
  if (data.deliveryDate) {
    lines.push(`Kézbesítési dátum: ${data.deliveryDate}`);
  }
  if (data.isStorno && data.stornoReason) {
    lines.push(`Sztornó indoklása: ${data.stornoReason}`);
  }
  if (data.denominations && data.denominations.length > 0) {
    lines.push('');
    lines.push('Címletezés:');
    for (const denomination of data.denominations) {
      const lineTotal = denomination.quantity * denomination.faceValue;
      lines.push(
        `  ${denomination.quantity} x ${formatAmount(denomination.faceValue)} = ${formatAmount(lineTotal)}`,
      );
    }
  }

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

function generateCancelledTransactionLines(data: PrintReceiptData): string[] {
  const lines: string[] = [];
  lines.push('');
  lines.push(CMD.BOLD_ON);
  lines.push('MEGSZAKÍTOTT TRANZAKCIÓ:');
  lines.push(CMD.BOLD_OFF);
  lines.push('');
  lines.push('Pénzmozgás nem történt.');
  lines.push('');

  if (data.transactionLines && data.transactionLines.length > 0) {
    for (const ln of data.transactionLines) {
      lines.push(`${ln.currencyCode}:`);
      lines.push(
        `  ${formatAmount(ln.foreignAmount)} × ${formatRate(ln.rate)} = ${formatAmount(ln.hufAmount)} Ft`,
      );
    }
  } else {
    lines.push(`Valutanem:   ${data.currencyCode ?? '—'}`);
    lines.push(`Összeg:      ${formatAmount(data.foreignAmount)} ${data.currencyCode ?? ''}`);
    lines.push(`Árfolyam:    ${formatRate(data.rate)}`);
  }

  lines.push('');
  lines.push(`HUF érték:   ${formatAmount(data.roundedHufAmount ?? data.hufAmount)} Ft`);
  if (data.stornoReason) {
    lines.push(`Indok:       ${data.stornoReason}`);
  }
  if (data.note) {
    lines.push(`Megjegyzés:  ${data.note}`);
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
      lines.push(
        `  ${d.currencyCode}: várt ${formatAmount(d.expected)} → tény ${formatAmount(d.actual)} (${formatAmount(d.difference)})`,
      );
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

function generateRateChangeLines(data: PrintReceiptData): string[] {
  const lines: string[] = [];
  lines.push('');
  lines.push(CMD.BOLD_ON);
  lines.push('ÁRFOLYAMVÁLTOZÁS');
  lines.push(CMD.BOLD_OFF);
  if (data.currencyCode) lines.push(`Valuta:        ${data.currencyCode}`);
  if (data.versionNumber !== undefined) lines.push(`Verzió:        v${data.versionNumber}`);
  if (data.validFrom) lines.push(`Érvényes:      ${data.validFrom}`);
  lines.push(`Vételi árf.:   ${formatRate(data.baseBuyRate ?? data.rate)}`);
  lines.push(`Eladási árf.:  ${formatRate(data.baseSellRate ?? data.rate)}`);
  if (data.officialRate !== undefined && data.officialRate !== null) {
    lines.push(`MNB árf.:      ${formatRate(data.officialRate)}`);
  }
  pushRateLimitLine(lines, 'Limit 1', data.limit1Amount, data.limit1BuyRate, data.limit1SellRate);
  pushRateLimitLine(lines, 'Limit 2', data.limit2Amount, data.limit2BuyRate, data.limit2SellRate);
  pushRateLimitLine(lines, 'Limit 3', data.limit3Amount, data.limit3BuyRate, data.limit3SellRate);
  lines.push('');
  lines.push('PÉLDÁNY LEFŰZENDŐ — Pmt./MNB előírás');
  return lines;
}

function pushRateLimitLine(
  lines: string[],
  label: string,
  amount: number | null | undefined,
  buyRate: number | null | undefined,
  sellRate: number | null | undefined,
): void {
  if (
    amount === undefined ||
    amount === null ||
    (buyRate === undefined && sellRate === undefined)
  ) {
    return;
  }
  lines.push(
    `${label}: ${formatAmount(amount)} — V:${formatRate(buyRate ?? undefined)} E:${formatRate(sellRate ?? undefined)}`,
  );
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
 * Bizonylat HTML generálása — a nyomtató driver-alapértelmezett papírformájára
 * illeszkedik (@page size: auto + usePrinterDefaultPageSize; SP512: "63mm x Receipt",
 * 62,7 mm nyomtatható szélesség), szélesebb nyomtatóknál max-width: 80mm korláttal.
 * Ezt rendereli a rejtett BrowserWindow a rendszer nyomtató felé.
 */
// Copilot PR #1102: exportált a HTML-útvonal unit-tesztjeihez (deviza-státusz + JOGCÍM blokk).
export async function generateReceiptHtml(data: PrintReceiptData): Promise<string> {
  const company = COMPANIES[data.companyType] ?? COMPANIES['BEST_CHANGE']!;
  const label = getJobTypeLabel(data);

  let bodyContent = '';

  // Fejléc — FR-1/FR-2/FR-3 (fejléc-javítás 2026-06-11): átadás-átvételnél a cím és a telefonszám
  // KIZÁRÓLAG a branch táblából jövő vaultAddress/vaultPhone; hiány esetén nincs cím/telefon sor
  // (TBD-3), hardcode-olt székhely/telefon transfer bizonylatra nem kerülhet.
  const htmlHeaderAddress = data.type === 'transfer' ? (data.vaultAddress ?? '') : company.address;
  const htmlHeaderPhone =
    data.type === 'transfer' ? (data.vaultPhone ?? '') : data.companyPhone || company.phone;
  bodyContent += `
    <div class="center">
      <div class="company-name">${escHtml(company.name)}</div>
      <div class="company-full">${escHtml(company.fullName)}</div>
      ${data.type === 'transfer' && data.vaultBranchLabel ? `<div><b>${escHtml(data.vaultBranchLabel)}</b></div>` : ''}
      ${htmlHeaderAddress ? `<div>${escHtml(htmlHeaderAddress)}</div>` : ''}
      ${htmlHeaderPhone ? `<div>Tel: ${escHtml(htmlHeaderPhone)}</div>` : ''}
      <div>Adószám: ${escHtml(data.companyTaxNumber || company.taxNumber)}</div>
    </div>
    <div class="double-line"></div>
    <div class="center receipt-type">${escHtml(label)}</div>
    <div class="meta">
      <div>Bizonylat: ${escHtml(data.receiptNumber)}</div>
      <div>Dátum: ${escHtml(data.date)} &nbsp; ${escHtml(data.time)}</div>
      ${
        data.type === 'transfer'
          ? `<div>Ügyintéző: ${escHtml(data.cashierName)}</div>`
          : `<div>Pénztár: ${escHtml(data.branchCode)}</div><div>Pénztáros: ${escHtml(data.cashierName)}</div>`
      }
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
  } else if (data.type === 'cancelled_transaction') {
    bodyContent += generateCancelledTransactionHtml(data);
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
  } else if (data.type === 'rate_change') {
    bodyContent += generateRateChangeHtml(data);
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
      ${
        (data.type === 'sell' || data.type === 'buy') && isHighValueReceipt(data)
          ? `<div>${escHtml(pepStatusText(data))}</div>
           <div style="white-space: pre-wrap;">${buildLegalEntityLines(data)
             .map((l) => `<div>${escHtml(l)}</div>`)
             .join('')}</div>`
          : ''
      }
    `;
  }

  // C.2 (user-kérés 2026-06-12): deviza-státusz MINDEN vétel/eladás bizonylaton +
  // C.1: 300k+ felett JOGCÍM NYILATKOZAT (a kanonikus backend template tükre).
  if (data.type === 'sell' || data.type === 'buy') {
    bodyContent += `
      <div style="margin: 4px 0;">
        <div>Az ügyletet készpénzben teljesítjük</div>
        <div>Deviza-státusz: ${escHtml(foreignStatusText(data.foreignStatus))}</div>
      </div>
    `;
    if (isHighValueReceipt(data)) {
      // Copilot PR #1102: white-space: pre-wrap — a 2 szóközös behúzások (képviselt fél
      // adatai, forrás-sorok) HTML-ben is látszanak, nem csukódnak össze.
      bodyContent += `
        <div class="line"></div>
        <div class="bold">JOGCÍM NYILATKOZAT</div>
        <div style="font-size: 9px; margin: 2px 0; white-space: pre-wrap;">
          ${buildSourceDeclarationLines(data)
            .map((l) => `<div>${escHtml(l)}</div>`)
            .join('')}
        </div>
      `;
    }
    // Batch2-D: orosz állampolgár EUR-vásárlása 300k+ felett → kétnyelvű
    // személyes-használat nyilatkozat (legacy OroszNyilatkozat tükre).
    if (isRussianEurPurchase(data)) {
      bodyContent += `
        <div style="font-size: 9px; margin: 2px 0; white-space: pre-wrap;">
          ${buildRussianDeclarationLines(data)
            .map((l) => `<div>${escHtml(l)}</div>`)
            .join('')}
        </div>
      `;
    }
  }

  // ÁFA-mentességi szöveg (törvényi kötelező)
  bodyContent += `
    <div class="line"></div>
    <div style="font-size: 9px; margin: 4px 0;">
      ${
        data.vatExemptionText
          ? `<div>${escHtml(data.vatExemptionText)}</div>`
          : `<div>Szj 67.13.10.0</div><div>Az ÁFA alól mentes: 2007. évi CXVII tv. 85. § e)</div>`
      }
    </div>
    <div class="line"></div>
  `;

  // FR-5 (fejléc-javítás 2026-06-11): kötelező jogi nyilatkozat — KIZÁRÓLAG átvételi
  // bizonylaton (transferDocType === 'receipt'), átadásin és sztornón NEM.
  if (data.type === 'transfer' && data.transferDocType === 'receipt' && !data.isStorno) {
    bodyContent += `
      <div class="line"></div>
      <div style="font-size: 9px; margin: 4px 0;">
        Büntetőjogi felelősségem tudatában, kijelentem, hogy a fentiekben felsorolt
        pénzkészletet a szállítóktól átvettem, azt tételesen átszámoltam.
      </div>
    `;
  }

  // Két aláírás sor (FR-6: átvételi bizonylaton a nyilatkozat ALATT — Átadó/Átvevő)
  bodyContent += `
    <div style="display: flex; justify-content: space-around; margin: 12px 0;">
      <div style="text-align: center;">
        <div style="border-top: 1px solid #000; width: 90px; display: inline-block;"></div>
        <div style="font-size: 9px;">${data.type === 'transfer' ? 'Átadó' : 'Pénztáros'}</div>
      </div>
      <div style="text-align: center;">
        <div style="border-top: 1px solid #000; width: 90px; display: inline-block;"></div>
        <div style="font-size: 9px;">${data.type === 'transfer' ? 'Átvevő' : 'Ügyfél'}</div>
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
    const qrDataUrl = await QRCode.toDataURL(qrText, {
      width: 120,
      margin: 1,
      errorCorrectionLevel: 'M',
    });
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
    /* Lapméret: a tényleges nyomtató-forma (print settings) adja — fix mm-szélesség
       tilos, mert az SP512 nyomtatható szélessége 62,7 mm (a korábbi 80/76 mm levágást
       vagy üres lapot okozott); a body a teljes nyomtatható szélességet tölti ki. */
    @page {
      size: auto;
      margin: 2mm;
    }
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: 'Courier New', monospace;
      font-size: 11px;
      line-height: 1.4;
      /* Széles (pl. A4) driver-forma esetén ne terüljön szét a bizonylat; az SP512
         nyomtatható szélességét (62,7 mm < 80 mm) nem korlátozza. */
      max-width: 80mm;
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

  const txLines = data.transactionLines;
  const bodyRows =
    txLines && txLines.length > 0
      ? // Multi-line aggregate: minden valuta-sor listázva EGY bizonylatszám alatt.
        // C.2: vegyes B/K nyugtán a sor deviza-státusza a valutakód mellett.
        txLines
          .map((ln) => {
            const statusSuffix =
              data.foreignStatus == null && ln.foreignStatus != null
                ? ` (${foreignStatusText(ln.foreignStatus)})`
                : '';
            return `
        <div class="amount-row"><span>${escHtml(ln.currencyCode)}${escHtml(statusSuffix)}: ${formatAmount(ln.foreignAmount)} × ${formatRate(ln.rate)}</span><span>${formatAmount(ln.hufAmount)} Ft</span></div>
      `;
          })
          .join('')
      : `
      <div class="amount-row"><span>Valutanem:</span><span>${escHtml(data.currencyCode ?? '—')}</span></div>
      <div class="amount-row"><span>Összeg:</span><span>${formatAmount(data.foreignAmount)} ${escHtml(data.currencyCode ?? '')}</span></div>
      <div class="amount-row"><span>Árfolyam:</span><span>${formatRate(data.rate)}</span></div>
    `;

  let html = `
    <div class="section">
      <div class="bold">${escHtml(label)}</div>
      ${bodyRows}
    </div>
    <div class="line"></div>
    <div class="amount-row bold"><span>HUF összeg:</span><span>${formatAmount(data.hufAmount)} Ft</span></div>
  `;

  if (
    data.roundedHufAmount !== undefined &&
    data.roundingDiff !== undefined &&
    data.roundingDiff !== 0
  ) {
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
  const denominationRows =
    data.denominations && data.denominations.length > 0
      ? `
      <div class="bold mt">Címletezés:</div>
      ${data.denominations
        .map((denomination) => {
          const lineTotal = denomination.quantity * denomination.faceValue;
          return `<div class="amount-row"><span>${denomination.quantity} x ${formatAmount(denomination.faceValue)}</span><span>${formatAmount(lineTotal)}</span></div>`;
        })
        .join('')}
    `
      : '';

  return `
    <div class="section">
      <div class="bold">Átadás-átvétel:</div>
      <div class="amount-row"><span>Kérő iroda:</span><span>${escHtml(data.branchCode || '—')}</span></div>
      <div class="amount-row"><span>Cél iroda:</span><span>${escHtml(data.transferTarget ?? '—')}</span></div>
      ${
        data.transferLines && data.transferLines.length > 0
          ? `<div class="bold">Valuták és összegek:</div>${data.transferLines
              .map(
                (tl) =>
                  `<div class="amount-row"><span>${escHtml(tl.currencyCode)}:</span><span>${formatAmount(tl.amount)}</span></div>`,
              )
              .join('')}`
          : `<div class="amount-row"><span>Valutanem:</span><span>${escHtml(data.currencyCode ?? '—')}</span></div>
      <div class="amount-row"><span>Összeg:</span><span>${formatAmount(data.foreignAmount)} ${escHtml(data.currencyCode ?? '')}</span></div>`
      }
      ${data.rate != null && data.currencyCode !== 'HUF' ? `<div class="amount-row"><span>Árfolyam:</span><span>${formatRate(data.rate)}</span></div>` : ''}
      ${data.roundedHufAmount !== undefined || data.hufAmount !== undefined ? `<div class="amount-row"><span>Forint érték:</span><span>${formatAmount(data.roundedHufAmount ?? data.hufAmount)} HUF</span></div>` : ''}
      ${data.carrierName ? `<div class="amount-row"><span>Szállító:</span><span>${escHtml(data.carrierName)}</span></div>` : ''}
      ${data.sealNumber ? `<div class="amount-row"><span>Plombaszám:</span><span>${escHtml(data.sealNumber)}</span></div>` : ''}
      ${data.deliveryDate ? `<div class="amount-row"><span>Kézbesítési dátum:</span><span>${escHtml(data.deliveryDate)}</span></div>` : ''}
      ${data.isStorno && data.stornoReason ? `<div>Sztornó indoklása: ${escHtml(data.stornoReason)}</div>` : ''}
      ${denominationRows}
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

function generateCancelledTransactionHtml(data: PrintReceiptData): string {
  const rows =
    data.transactionLines && data.transactionLines.length > 0
      ? data.transactionLines
          .map(
            (ln) => `
      <div class="amount-row"><span>${escHtml(ln.currencyCode)}: ${formatAmount(ln.foreignAmount)} × ${formatRate(ln.rate)}</span><span>${formatAmount(ln.hufAmount)} Ft</span></div>
    `,
          )
          .join('')
      : `
      <div class="amount-row"><span>Valutanem:</span><span>${escHtml(data.currencyCode ?? '—')}</span></div>
      <div class="amount-row"><span>Összeg:</span><span>${formatAmount(data.foreignAmount)} ${escHtml(data.currencyCode ?? '')}</span></div>
      <div class="amount-row"><span>Árfolyam:</span><span>${formatRate(data.rate)}</span></div>
    `;

  return `
    <div class="section">
      <div class="bold">MEGSZAKÍTOTT TRANZAKCIÓ:</div>
      <div class="bold">Pénzmozgás nem történt.</div>
      ${rows}
      <div class="line"></div>
      <div class="amount-row bold"><span>HUF érték:</span><span>${formatAmount(data.roundedHufAmount ?? data.hufAmount)} Ft</span></div>
      ${data.stornoReason ? `<div>Indok: ${escHtml(data.stornoReason)}</div>` : ''}
      ${data.note ? `<div>Megjegyzés: ${escHtml(data.note)}</div>` : ''}
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

function generateRateChangeHtml(data: PrintReceiptData): string {
  const limitRows = [
    rateLimitHtml('Limit 1', data.limit1Amount, data.limit1BuyRate, data.limit1SellRate),
    rateLimitHtml('Limit 2', data.limit2Amount, data.limit2BuyRate, data.limit2SellRate),
    rateLimitHtml('Limit 3', data.limit3Amount, data.limit3BuyRate, data.limit3SellRate),
  ].join('');
  return `
    <div class="section">
      <div class="bold">ÁRFOLYAMVÁLTOZÁS</div>
      ${data.currencyCode ? `<div class="amount-row"><span>Valuta:</span><span>${escHtml(data.currencyCode)}</span></div>` : ''}
      ${data.versionNumber !== undefined ? `<div class="amount-row"><span>Verzió:</span><span>v${data.versionNumber}</span></div>` : ''}
      ${data.validFrom ? `<div class="amount-row"><span>Érvényes:</span><span>${escHtml(data.validFrom)}</span></div>` : ''}
      <div class="amount-row"><span>Vételi árfolyam:</span><span>${formatRate(data.baseBuyRate ?? data.rate)}</span></div>
      <div class="amount-row"><span>Eladási árfolyam:</span><span>${formatRate(data.baseSellRate ?? data.rate)}</span></div>
      ${data.officialRate !== undefined && data.officialRate !== null ? `<div class="amount-row"><span>MNB árfolyam:</span><span>${formatRate(data.officialRate)}</span></div>` : ''}
      ${limitRows}
      <div class="bold" style="margin-top: 8px;">PÉLDÁNY LEFŰZENDŐ — Pmt./MNB előírás</div>
    </div>
  `;
}

function rateLimitHtml(
  label: string,
  amount: number | null | undefined,
  buyRate: number | null | undefined,
  sellRate: number | null | undefined,
): string {
  if (
    amount === undefined ||
    amount === null ||
    (buyRate === undefined && sellRate === undefined)
  ) {
    return '';
  }
  return `<div class="amount-row"><span>${label}:</span><span>${formatAmount(amount)} — V:${formatRate(buyRate ?? undefined)} E:${formatRate(sellRate ?? undefined)}</span></div>`;
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

/** Virtuális (fájlba nyomtató) eszközök tiltólistája — FAIL-CLOSED (2026-07-11).
 * PDF/XPS/OneNote/Fax/print-to-file család: bizonylat SOHA nem mehet fájlba. */
export const VIRTUAL_PRINTER_NAME_PATTERN =
  /pdf|xps|onenote|fax|print to file|send to file|document writer/i;

export function isVirtualPrinterName(name: string): boolean {
  return VIRTUAL_PRINTER_NAME_PATTERN.test(name);
}

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
 * @param printerName - Kötelező, explicit fizikai nyomtatónév; rendszer-default fallback nincs
 * @returns true ha a nyomtatás sikerült
 */
async function printViaElectron(
  html: string,
  printerName: string,
  receiptContext: { receiptNumber: string; printedCopies: number; copies: number },
): Promise<boolean> {
  let printWindow: BrowserWindow | null = null;

  try {
    // Rejtett ablak létrehozása a bizonylat rendereléshez
    printWindow = new BrowserWindow({
      show: false,
      width: 302, // ~80mm @ 96 DPI
      height: 800,
      webPreferences: {
        contextIsolation: true,
        nodeIntegration: false,
      },
    });

    // Defense-in-depth: csak a rendszer által enumerált, nem virtuális eszköz engedélyezett.
    const printers = await printWindow.webContents.getPrintersAsync();
    const target = printers.find((printer) => printer.name === printerName);
    if (!target) {
      log.error(
        `[PRINTER][FAIL-CLOSED] PRINTER_NOT_FOUND receiptNumber=${receiptContext.receiptNumber} ` +
          `printedCopies=${receiptContext.printedCopies} copies=${receiptContext.copies} ` +
          `printerName="${printerName}": nincs a rendszer nyomtatói között — nyomtatás megtagadva.`,
      );
      return false;
    }
    if (isVirtualPrinterName(target.name) || isVirtualPrinterName(target.displayName ?? '')) {
      log.error(
        `[PRINTER][FAIL-CLOSED] VIRTUAL_PRINTER_REJECTED receiptNumber=${receiptContext.receiptNumber} ` +
          `printedCopies=${receiptContext.printedCopies} copies=${receiptContext.copies} ` +
          `printerName="${printerName}": virtuális (fájlba nyomtató) eszköz — bizonylat nem mehet PDF-be/fájlba.`,
      );
      return false;
    }

    // HTML tartalom betöltése data URL-ként
    await printWindow.loadURL(`data:text/html;charset=utf-8,${encodeURIComponent(html)}`);

    // Nyomtatási opciók — csendes nyomtatás (nincs dialógus).
    // Lapméret: a nyomtató driver-alapértelmezett formája (SP512: "63mm x Receipt",
    // 62,7 mm nyomtatható szélesség, változó hossz). Hardcode-olt mikron-pageSize
    // TILOS: a 80mm × 297mm érték egyetlen SP512-formával sem egyezett, ezért a
    // driver üres lapot adott ki (2026-08-06 fizikai teszt).
    const printOptions: Electron.WebContentsPrintOptions = {
      silent: true,
      printBackground: true,
      margins: { marginType: 'none' },
      usePrinterDefaultPageSize: true,
      deviceName: printerName,
    };

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
 *   2. Egyébként → explicit, validált fizikai nyomtatón Electron webContents.print()
 *   3. Explicit printerName és serialPort nélkül fail-closed; nincs rendszer-default fallback
 *
 * Hibajelzések:
 *   - Nyomtató offline / nem elérhető → false visszatérés, log üzenet
 *   - Papír kifogyott → a rendszer driver kezeli, false visszatérés
 *
 * @param data - A bizonylat adatai
 * @param printerName - Explicit fizikai nyomtató név; Electron úthoz kötelező
 * @param serialPort - Opcionális soros nyomtatóport
 * @returns true ha a nyomtatás sikeresen elindult
 */
export async function printReceipt(
  data: PrintReceiptData,
  printerName?: string,
  serialPort?: string,
): Promise<boolean> {
  try {
    // FR-7 (fejléc-javítás 2026-06-11): HUF valutanemű átadás-átvételi bizonylat (átadási és
    // átvételi egyaránt) automatikusan KÉT példányban nyomtat (1. iratározás, 2. könyvelés);
    // deviza esetén egy példány. Más bizonylat-típusokra nem vonatkozik.
    const copies = data.type === 'transfer' && data.currencyCode === 'HUF' ? 2 : 1;
    log.info(
      `[PRINTER] Nyomtatás indítása: ${data.type} ${data.receiptNumber} (${copies} példány)`,
    );

    // 1. Próbáljuk soros blokknyomtatón (Star SP500 / kompatibilis)
    // A sikeresen kinyomtatott példányokat számoljuk, hogy részleges soros hiba
    // esetén a fallback NE nyomtassa újra a már elkészült példányokat (különben
    // HUF transfernél 3 példány születhetne 2 helyett).
    let printedCopies = 0;
    if (serialPort) {
      for (let copy = 1; copy <= copies; copy++) {
        const ok = await printToSerialPrinter(data, serialPort);
        if (!ok) {
          break;
        }
        printedCopies++;
      }
      if (printedCopies === copies) {
        log.info(
          `[PRINTER] Soros blokknyomtató (${serialPort}): OK — ${data.receiptNumber} (${copies} példány)`,
        );
        return true;
      }
      log.warn(
        `[PRINTER] Soros port ${serialPort} sikertelen (${printedCopies}/${copies} példány kész), Electron fallback a maradékra...`,
      );
    }

    // FAIL-CLOSED (2026-07-11): explicit fizikai deviceName nélkül NINCS Electron út —
    // a Windows default printer (tipikusan Microsoft Print to PDF) fallback tiltott.
    if (!printerName) {
      log.error(
        `[PRINTER][FAIL-CLOSED] NO_PRINTER_CONFIGURED receiptNumber=${data.receiptNumber} ` +
          `printedCopies=${printedCopies} copies=${copies}: ` +
          `nincs printer.deviceName, a soros út ${serialPort ? `sikertelen (${printedCopies}/${copies} példány kész)` : 'nincs konfigurálva'}. ` +
          'Nyomtatás megtagadva; konfiguráljon valós nyomtatót (Beállítások > Nyomtatás / set-config).',
      );
      return false;
    }

    // 2. Fallback: explicit Electron nyomtató (HTML alapú) — csak a hiányzó példányokra
    log.info('[PRINTER] Electron print fallback...');
    const html = await generateReceiptHtml(data);
    let electronSuccess = true;
    for (let copy = printedCopies + 1; copy <= copies; copy++) {
      const ok = await printViaElectron(html, printerName, {
        receiptNumber: data.receiptNumber,
        printedCopies: copy - 1,
        copies,
      });
      if (!ok) {
        electronSuccess = false;
        break;
      }
    }

    if (electronSuccess) {
      log.info(`[PRINTER] Electron print: OK — ${data.receiptNumber} (${copies} példány)`);
    } else {
      log.error(
        `[PRINTER] Nyomtatás sikertelen — ${data.receiptNumber}. Ellenőrizd a nyomtató állapotát (offline / papír kifogyott).`,
      );
    }

    return electronSuccess;
  } catch (err) {
    log.error('[PRINTER] Váratlan nyomtatási hiba:', err);
    return false;
  }
}

/**
 * Nyomtatás a SQLite config-ban tárolt beállítással (printer.deviceName /
 * printer.serialPort) — a print-receipt IPC handler belépési pontja.
 * FAIL-CLOSED: tárolt konfiguráció nélkül nincs nyomtatás; a Windows default
 * printer fallback tiltott (PDF-mentés veszély, 2026-07-11).
 * A sqlite dinamikus importtal töltődik, hogy a tisztán tartalom-generáló
 * tesztutak ne húzzák be a DB-réteget.
 */
export async function printReceiptWithStoredConfig(data: PrintReceiptData): Promise<boolean> {
  const { getConfig } = await import('./sqlite');
  const printerName = getConfig(PRINTER_CONFIG_KEY)?.trim() || undefined;
  const serialPort = getConfig(SERIAL_PORT_CONFIG_KEY)?.trim() || undefined;
  if (!printerName && !serialPort) {
    log.error(
      `[PRINTER][FAIL-CLOSED] print-receipt megtagadva receiptNumber=${data.receiptNumber}: ` +
        'sem printer.deviceName, sem printer.serialPort nincs konfigurálva. ' +
        'Windows default printer fallback TILTVA (PDF-mentés veszély).',
    );
    return false;
  }
  return printReceipt(data, printerName, serialPort);
}
