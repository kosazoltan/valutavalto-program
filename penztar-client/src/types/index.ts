// ============================================================
// Valuta Pénztár — Típusdefiníciók
// ============================================================

// --- Auth ---
export interface LoginRequest {
  branchCode: string;
  username: string;
  password: string;
}

export interface LoginResponse {
  token: string;
  refreshToken: string;
  user: User;
}

export interface User {
  id: number;
  username: string;
  fullName: string;
  role: 'CASHIER' | 'MANAGER' | 'ADMIN';
  branchCode: string;
  companyId: number;
}

// --- Company ---
export type CompanyType = 'BEST_CHANGE' | 'EXPRESSZ';

export interface Company {
  id: number;
  name: string;
  taxNumber: string;
  type: CompanyType;
}

// --- Currency ---
export type CurrencyCode =
  | 'AUD' | 'BAM' | 'BGN' | 'BRL' | 'CAD' | 'CHF' | 'CNY' | 'CZK'
  | 'DKK' | 'EUR' | 'GBP' | 'HRK' | 'HUF' | 'ILS' | 'JPY' | 'MXN'
  | 'NOK' | 'NZD' | 'PLN' | 'RON' | 'RSD' | 'RUB' | 'SEK' | 'THB'
  | 'TRY' | 'UAH' | 'USD';

export interface ExchangeRate {
  currencyCode: CurrencyCode;
  buyRate: number;
  sellRate: number;
  unit: number;
  updatedAt: string;
}

// --- Transaction ---
export interface TransactionRequest {
  currencyCode: CurrencyCode;
  foreignAmount: number;
  hufAmount: number;
  rate: number;
  roundedHufAmount: number;
  customerId?: number;
  denominations?: Denomination[];
}

export interface TransactionResponse {
  id: number;
  receiptNumber: string;
  type: 'SELL' | 'BUY';
  currencyCode: CurrencyCode;
  foreignAmount: number;
  hufAmount: number;
  roundedHufAmount: number;
  rate: number;
  fee: number;
  customerId?: number;
  cashierId: number;
  branchCode: string;
  createdAt: string;
}

// --- Customer ---
export interface Customer {
  id: number;
  name: string;
  documentType: 'PERSONAL_ID' | 'PASSPORT' | 'DRIVING_LICENSE';
  documentNumber: string;
  nationality: string;
  birthDate: string;
  birthPlace: string;
  address: string;
  motherName: string;
}

export interface CustomerSearchRequest {
  query: string;
  documentNumber?: string;
}

// --- Cash / Denomination ---
export interface Denomination {
  value: number;
  count: number;
  currencyCode: CurrencyCode | 'HUF';
}

export interface CashBalance {
  currencyCode: CurrencyCode | 'HUF';
  amount: number;
  denominations: Denomination[];
}

// --- Daily Session ---
export interface DailySession {
  id: number;
  branchCode: string;
  cashierId: number;
  openedAt: string;
  closedAt?: string;
  status: 'OPEN' | 'CLOSED';
  openingBalances: CashBalance[];
}

// --- Navigation ---
export type PageRoute =
  | '/'
  | '/login'
  | '/menu'
  | '/sell'
  | '/buy'
  | '/stock'
  | '/denom'
  | '/transfer'
  | '/storno'
  | '/closing'
  | '/circulars'
  | '/rates'
  | '/customer'
  | '/lists'
  | '/settings'
  | '/reservation'
  | '/hrk'
  | '/evening-closing'
  | '/ertektar'
  | '/ertektar/distribution'
  | '/ertektar/collection'
  | '/ertektar/reports';

// --- Menu ---
export interface MenuItem {
  key: string;
  label: string;
  icon: string;
  route: PageRoute;
  hotkey: string;
}

// --- Cash Balance Summary ---
export interface CashBalanceSummary {
  currencyCode: CurrencyCode | 'HUF';
  amount: number;
  banknoteCount: number;
  hufValue: number;
  rate: number;
}

export interface CompanyTotals {
  totalHufValue: number;
  hufCashBalance: number;
  foreignHufValue: number;
  lastUpdated: string;
}

// --- Denomination (extended) ---
export interface DenominationEntry {
  id: number;
  currencyCode: CurrencyCode | 'HUF';
  value: number;
  count: number;
  lastUpdated: string;
}

export interface DenominationBulkRequest {
  currencyCode: CurrencyCode | 'HUF';
  denominations: Array<{ value: number; count: number }>;
}

// --- Transfer ---
export type TransferStatus = 'PENDING' | 'RECEIVED' | 'REJECTED' | 'CANCELLED';

export interface TransferRequest {
  targetBranchCode: string;
  currencyCode: CurrencyCode | 'HUF';
  amount: number;
  denominations?: Denomination[];
  note?: string;
}

export interface Transfer {
  id: number;
  receiptNumber: string;
  sourceBranchCode: string;
  targetBranchCode: string;
  currencyCode: CurrencyCode | 'HUF';
  amount: number;
  denominations: Denomination[];
  status: TransferStatus;
  note?: string;
  createdAt: string;
  receivedAt?: string;
  cashierName: string;
}

// --- Storno ---
export interface StornoCheck {
  transaction: TransactionResponse;
  canStorno: boolean;
  requiresSupervisor: boolean;
  reason?: string;
}

export interface StornoRequest {
  transactionId: number;
  reason: string;
  supervisorPassword?: string;
}

export interface StornoResponse {
  id: number;
  originalTransactionId: number;
  newReceiptNumber: string;
  reason: string;
  createdAt: string;
}

// --- Closing Wizard ---
export type ClosingStep = 1 | 2 | 3 | 4 | 5;

export interface ClosingWizardState {
  sessionId: string;
  currentStep: ClosingStep;
  balanceCheck: BalanceCheckItem[];
  denominations: DenominationEntry[];
  discrepancies: DiscrepancyItem[];
  summary: ClosingSummary | null;
  canFinalize: boolean;
}

export interface BalanceCheckItem {
  currencyCode: CurrencyCode | 'HUF';
  expected: number;
  actual: number;
  difference: number;
}

export interface DiscrepancyItem {
  currencyCode: CurrencyCode | 'HUF';
  expected: number;
  actual: number;
  difference: number;
  hufDifference: number;
}

export interface ClosingSummary {
  date: string;
  totalTransactions: number;
  sellCount: number;
  buyCount: number;
  totalHufTurnover: number;
  totalFees: number;
  openingBalance: number;
  closingBalance: number;
}

// --- Exchange Rate (extended) ---
export interface ExchangeRateDetail {
  currencyCode: CurrencyCode;
  buyRate: number;
  sellRate: number;
  accountingRate: number;
  mnbMiddleRate: number;
  unit: number;
  updatedAt: string;
}

export interface ExchangeRateHistory {
  currencyCode: CurrencyCode;
  date: string;
  buyRate: number;
  sellRate: number;
  mnbMiddleRate: number;
}

// --- Branch ---
export interface Branch {
  code: string;
  name: string;
  companyId: number;
}

// --- Flags ---
export interface CurrencyInfo {
  code: CurrencyCode;
  name: string;
  flag: string;
  unit: number;
}

// --- Circular (Körlevél) ---
export interface Circular {
  id: number;
  subject: string;
  body: string;
  sender: string;
  sentAt: string;
  acknowledged: boolean;
  acknowledgedAt?: string;
}

// --- Customer Detail (Ügyfél bővített) ---
export interface CustomerDetail extends Customer {
  taxNumber?: string;
  createdAt: string;
  updatedAt: string;
}

export interface CustomerCreateRequest {
  name: string;
  documentType: 'PERSONAL_ID' | 'PASSPORT' | 'DRIVING_LICENSE';
  documentNumber: string;
  nationality: string;
  birthDate: string;
  birthPlace: string;
  address: string;
  motherName: string;
  taxNumber?: string;
}

// --- Reports (Riportok) ---
export interface ReportFilter {
  dateFrom: string;
  dateTo: string;
  type?: 'SELL' | 'BUY';
  currencyCode?: CurrencyCode;
  customerId?: number;
}

export interface DailySummary {
  date: string;
  totalTransactions: number;
  sellCount: number;
  buyCount: number;
  totalHufTurnover: number;
  totalFees: number;
  currencyBreakdown: Array<{
    currencyCode: CurrencyCode;
    sellCount: number;
    buyCount: number;
    sellVolume: number;
    buyVolume: number;
  }>;
}

export interface TransactionListItem {
  id: number;
  receiptNumber: string;
  type: 'SELL' | 'BUY';
  currencyCode: CurrencyCode;
  foreignAmount: number;
  hufAmount: number;
  roundedHufAmount: number;
  rate: number;
  fee: number;
  customerName?: string;
  cashierName: string;
  createdAt: string;
}

// ============================================================
// Szankciós szűrés (TERROR) — Típusdefiníciók
// ============================================================

export type SanctionRiskLevel = 'CLEAR' | 'POSSIBLE' | 'CONFIRMED';
export type SanctionMatchType = 'EXACT' | 'PARTIAL' | 'ALIAS';

export interface SanctionScreeningRequest {
  name: string;
  documentNumber?: string;
  dateOfBirth?: string;
}

export interface SanctionMatch {
  entryId: string;
  fullName: string;
  aliases: string | null;
  dateOfBirth: string | null;
  nationality: string | null;
  documentNumber: string | null;
  listType: string;
  listReference: string | null;
  matchType: SanctionMatchType;
  score: number;
}

export interface SanctionScreeningResult {
  matched: boolean;
  matches: SanctionMatch[];
  riskLevel: SanctionRiskLevel;
}

export interface SanctionStatusResponse {
  lastUpdateDate: string | null;
  activeEntryCount: number;
}

// ============================================================
// QR kód — Típusdefiníciók
// ============================================================

export interface QRData {
  bizonylatSzam: string;
  datum: string;
  osszeg: number;
  valuta: string;
  adoszam: string;
  penztarKod: number;
}

// ============================================================
// Értéktár — Típusdefiníciók
// ============================================================

// --- Értéktár: Alárendelt pénztár státusz ---
export type BranchOnlineStatus = 'online' | 'warning' | 'offline';

export interface SubordinateBranch {
  code: string;
  name: string;
  companyId: number;
  lastSyncAt: string | null;
  onlineStatus: BranchOnlineStatus;
  cashBalances: CashBalanceSummary[];
  totalHufValue: number;
  dailyTurnover: number;
}

// --- Értéktár: Szétosztás (Distribution) ---
export interface DistributionItem {
  targetBranchCode: string;
  currencyCode: CurrencyCode | 'HUF';
  amount: number;
  denominations?: Denomination[];
}

export interface DistributionBatch {
  items: DistributionItem[];
  note?: string;
}

export interface DistributionResult {
  receiptNumbers: string[];
  successCount: number;
  failedCount: number;
  errors: string[];
}

// --- Értéktár: Begyűjtés (Collection) ---
export type CollectionStatus = 'REQUESTED' | 'IN_PROGRESS' | 'COMPLETED' | 'REJECTED';

export interface CollectionRequest {
  sourceBranchCode: string;
  currencyCode: CurrencyCode | 'HUF';
  amount: number;
  note?: string;
}

export interface CollectionRecord {
  id: number;
  sourceBranchCode: string;
  sourceBranchName: string;
  currencyCode: CurrencyCode | 'HUF';
  amount: number;
  status: CollectionStatus;
  requestedAt: string;
  completedAt?: string;
  note?: string;
}

// --- Értéktár: Összevont riport ---
export interface ConsolidatedReportFilter {
  dateFrom: string;
  dateTo: string;
  branchCodes?: string[];
}

export interface BranchDailyReport {
  branchCode: string;
  branchName: string;
  date: string;
  sellCount: number;
  buyCount: number;
  totalTransactions: number;
  sellHufVolume: number;
  buyHufVolume: number;
  totalHufTurnover: number;
  totalFees: number;
}

export interface ConsolidatedReport {
  dateFrom: string;
  dateTo: string;
  branches: BranchDailyReport[];
  totals: {
    totalTransactions: number;
    totalSellCount: number;
    totalBuyCount: number;
    totalHufTurnover: number;
    totalFees: number;
  };
}

// ============================================================
// Foglalás (Reservation) — Típusdefiníciók
// ============================================================

export type ReservationStatus = 'ACTIVE' | 'COMPLETED' | 'EXPIRED' | 'CANCELLED';

export interface Reservation {
  id: number;
  receiptNumber: string;
  customerId: number;
  customerName: string;
  currencyCode: CurrencyCode;
  amount: number;
  rate: number;
  hufAmount: number;
  status: ReservationStatus;
  expiresAt: string;
  createdAt: string;
  completedAt?: string;
  cancelledAt?: string;
  cancelReason?: string;
}

export interface CreateReservationRequest {
  customerId: number;
  currencyCode: CurrencyCode;
  amount: number;
  rate: number;
  hufAmount: number;
  expiresInMinutes?: number;
}

export interface RedeemReservationResponse {
  reservation: Reservation;
  transactionReceiptNumber: string;
}

// ============================================================
// HRK (Házipénztári Kezelés) — Típusdefiníciók
// ============================================================

export type HrkType = 'HANDOVER' | 'RECEIVE';
export type HrkStatus = 'PENDING' | 'COMPLETED' | 'CANCELLED';

export interface HrkTransaction {
  id: string;
  branchId: string;
  type: HrkType;
  currencyCode: string;
  amount: number;
  hufAmount: number;
  bankAccountNumber?: string;
  reference: string;
  note?: string;
  status: HrkStatus;
  workerId: number;
  createdAt: string;
  completedAt?: string;
}

export interface CreateHrkRequest {
  currencyCode: string;
  amount: number;
  hufAmount: number;
  bankAccountNumber?: string;
  note?: string;
}

// ============================================================
// Esti zárás (Evening Closing) — Típusdefiníciók
// ============================================================

export type EveningClosingStatus = 'PREPARING' | 'READY' | 'SENT' | 'CONFIRMED';

export interface EveningClosingData {
  id: string;
  branchId: string;
  closingDate: string;
  status: EveningClosingStatus;
  packageData?: string;
  transactionCount: number;
  totalBuyHuf: number;
  totalSellHuf: number;
  inventorySnapshot?: string;
  sentAt?: string;
  confirmedAt?: string;
  createdAt: string;
}
