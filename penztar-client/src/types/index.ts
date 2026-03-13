// ============================================================
// Valuta Pénztár — Típusdefiníciók
// ============================================================

// --- Auth ---
export interface LoginRequest {
  companyCode: string;
  workerCode: string;
  password: string;
}

export interface LoginResponse {
  token: string;
  refreshToken: string;
  user: User;
  /** V57: operatív szerepkör kódok */
  roles?: string[];
  /** V57: kiválasztott aktív operatív role */
  activeRole?: string | null;
  /** V57: aktív role-hoz tartozó permission kódok */
  permissions?: string[];
  /** V57: true ha több role van és választani kell */
  roleSelectionRequired?: boolean;
}

/** V57: Operatív szerepkör kódok */
export type OperationalRoleCode =
  | 'CASHIER' | 'COURIER' | 'VAULT_KEEPER' | 'CHIEF_VAULT'
  | 'REGIONAL_MGR' | 'OFFICE_MGR' | 'AUDITOR' | 'SECURITY' | 'DIRECTOR';

/** V57: Operatív szerepkör nevek (magyar) */
export const OPERATIONAL_ROLE_NAMES: Record<OperationalRoleCode, string> = {
  CASHIER: 'Valutapénztáros',
  COURIER: 'Értékszállító',
  VAULT_KEEPER: 'Értéktáros',
  CHIEF_VAULT: 'Főértéktáros',
  REGIONAL_MGR: 'Területi vezető',
  OFFICE_MGR: 'Irodavezető',
  AUDITOR: 'Kontroller',
  SECURITY: 'Biztonsági vezető',
  DIRECTOR: 'Igazgató',
};

export interface User {
  id: number;
  username: string;
  fullName: string;
  role: 'CASHIER' | 'MANAGER' | 'ADMIN';
  branchCode: string;
  companyId: number;
  /** V57: operatív szerepkör kódok */
  roles?: string[];
  /** V57: aktív operatív szerepkör */
  activeRole?: string | null;
  /** V57: aktív role-hoz tartozó permission kódok */
  permissions?: string[];
}

/** V57: Role selection request */
export interface SelectRoleRequest {
  token: string;
  roleCode: string;
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
  currencyId: number;
  currencyAmount: number;
  discountPercent?: number;
  handlingFee?: number;
  customerId?: number;
  customerName?: string;
  customerAddress?: string;
  customerDocumentNumber?: string;
  customerNationality?: string;
  notes?: string;
  // Frontend-specifikus mezők (csak UI-hoz):
  currencyCode?: CurrencyCode;
  hufAmount?: number;
  rate?: number;
  roundedHufAmount?: number;
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
  customerType: 'FULL' | 'SIMPLIFIED';
  documentType: 'PERSONAL_ID' | 'PASSPORT' | 'DRIVING_LICENSE';
  documentNumber: string;
  nationality: string;
  birthDate: string;
  birthPlace: string;
  address: string;
  motherName: string;
  // Külön okmányszámok
  idCardNumber?: string;
  idCardExpiry?: string;
  passportNumber?: string;
  passportExpiry?: string;
  // Kontakt
  phone?: string;
  email?: string;
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
  | '/ertektar/reports'
  | '/ertektar/rate-approval'
  | '/daily-report'
  | '/police'
  | '/monthly-closing'
  | '/commissions'
  | '/booking'
  | '/profit';

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
  id: string;
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
export type CircularTypeEnum =
  | 'GENERAL' | 'REGULATION' | 'RATE_POLICY' | 'SECURITY_ALERT'
  | 'INVENTORY' | 'HR' | 'TECHNICAL' | 'BEST_CHANGE' | 'ZALOG'
  | 'MANAGEMENT' | 'APPOINTMENT' | 'NEW_YEAR' | 'YEAR_END'
  | 'MONTHLY_SUMMARY' | 'VIP_NOTICE' | 'AUDIT_NOTICE' | 'TRAINING';

export type CircularPriority = 'LOW' | 'NORMAL' | 'HIGH' | 'URGENT';

export interface Circular {
  id: number;
  subject: string;
  body: string;
  sender: string;
  sentAt: string;
  acknowledged: boolean;
  acknowledgedAt?: string;
  // Sprint 3 — típus rendszer
  circularType?: CircularTypeEnum;
  circularTypeDescription?: string;
  target?: string;
  priority?: CircularPriority;
  registrationNumber?: string;
  attachmentFilename?: string;
  validFrom?: string;
  validTo?: string;
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
  // Külön okmányszámok
  idCardNumber?: string;
  idCardExpiry?: string;
  passportNumber?: string;
  passportExpiry?: string;
  // Kontakt
  phone?: string;
  email?: string;
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

// ============================================================
// Árfolyam engedélyezés (Rate Approval) — Típusdefiníciók
// ============================================================

export type RateApprovalStatus = 'PENDING' | 'APPROVED' | 'REJECTED' | 'APPLIED';

export interface RateApproval {
  id: string;
  branchId: string;
  branchName: string;
  currencyCode: string;
  oldBuyRate: number | null;
  oldSellRate: number | null;
  newBuyRate: number;
  newSellRate: number;
  status: RateApprovalStatus;
  requestedById: number | null;
  requestedByName: string | null;
  approvedById: number | null;
  approvedByName: string | null;
  requestedAt: string | null;
  approvedAt: string | null;
  reason: string | null;
}

export interface RequestRateChangeRequest {
  branchId: string;
  currencyCode: string;
  newBuyRate: number;
  newSellRate: number;
  reason?: string;
}

// ============================================================
// Napi jelentés (Daily Report) — Típusdefiníciók
// ============================================================

export interface DailyReportData {
  id: number;
  branchId: string;
  branchCode: string;
  branchName: string;
  reportDate: string;
  submitted: boolean;
  submittedAt: string | null;
  submittedById: number | null;
  submittedByName: string | null;
  reportData: string | null;
  totalBuyHuf: number;
  totalSellHuf: number;
  totalFeeHuf: number;
  totalProfit: number;
  transactionCount: number;
  createdAt: string | null;
}

// ============================================================
// Rendőrségi adatkérés (Police Request) — Típusdefiníciók
// ============================================================

export type PoliceRequestStatus = 'RECEIVED' | 'PROCESSING' | 'COMPLETED' | 'REJECTED';

export interface PoliceRequestData {
  id: string;
  requestNumber: string;
  requestDate: string;
  requestedBy: string;
  customerName: string | null;
  documentNumber: string | null;
  dateRangeFrom: string | null;
  dateRangeTo: string | null;
  status: PoliceRequestStatus;
  responseData: string | null;
  completedAt: string | null;
  createdAt: string | null;
  createdById: number | null;
  createdByName: string | null;
}

export interface CreatePoliceRequest {
  requestNumber: string;
  requestDate: string;
  requestedBy: string;
  customerName?: string;
  documentNumber?: string;
  dateRangeFrom?: string;
  dateRangeTo?: string;
}

// ============================================================
// Készlet regenerálás — Típusdefiníciók
// ============================================================

export interface RegenerationResult {
  id: number;
  branchId: string;
  discrepancies: RegenerationDiscrepancy[];
  correctedCurrencies: string[];
  discrepancyCount: number;
  correctedCount: number;
  regeneratedAt: string;
  regeneratedByName: string | null;
}

export interface RegenerationDiscrepancy {
  currencyCode: string;
  expectedAmount: string;
  actualAmount: string;
  difference: string;
}

// ============================================================
// LED kijelző — Típusdefiníciók
// ============================================================

export type LedDisplayType = 'RATE_BOARD' | 'SCROLLING_TEXT';

export interface LedDisplayData {
  id: string;
  branchId: string;
  displayType: LedDisplayType;
  content: string | null;
  lastUpdated: string | null;
}

// ============================================================
// Supervisor mód — Típusdefiníciók
// ============================================================

export interface SupervisorAuthRequest {
  password: string;
}

export interface SupervisorAuthResponse {
  authenticated: boolean;
}

export interface OverrideRateRequest {
  branchId: string;
  currency: string;
  newBuyRate: number;
  newSellRate: number;
  reason: string;
}

export interface OverrideFeeRequest {
  transactionId: number;
  newFee: number;
  reason: string;
}

export interface SystemParam {
  id: string;
  key: string;
  value: string;
  type: string;
  category: string;
  description: string;
  updatedAt: string;
}

// ============================================================
// Pénztáros kezelés — Típusdefiníciók
// ============================================================

export interface WorkerDetail {
  id: number;
  companyId: string;
  code: string;
  name: string;
  role: 'CASHIER' | 'SUPERVISOR' | 'MANAGER' | 'ADMIN';
  branchId: string;
  branchCode: string;
  branchName: string;
  active: boolean;
  phone?: string;
  email?: string;
  lastLoginAt?: string;
  createdAt: string;
  updatedAt?: string;
}

export interface WorkerAttendance {
  id: string;
  workerId: number;
  branchId: string;
  loginAt: string;
  logoutAt?: string;
  ipAddress?: string;
}

export interface WorkerBreak {
  id: string;
  workerId: number;
  branchId: string;
  breakStart: string;
  breakEnd?: string;
  reason?: string;
  approvedBy?: string;
}

// ============================================================
// Bizonylat kereső — Típusdefiníciók
// ============================================================

export interface ReceiptSearchResult {
  id: number;
  receiptNumber: string;
  transactionDate: string;
  transactionTime: string;
  transactionType: string;
  transactionTypeDisplay: string;
  currencyCode: string;
  currencyAmount: number;
  hufAmount: number;
  exchangeRate: number;
  customerName?: string;
  cashierName: string;
  status: string;
}

export interface ReceiptDetail {
  id: number;
  receiptNumber: string;
  transactionDate: string;
  transactionTime: string;
  transactionType: string;
  transactionTypeDisplay: string;
  status: string;
  currencyCode: string;
  currencyAmount: number;
  hufAmount: number;
  exchangeRate: number;
  handlingFee: number;
  customerName?: string;
  customerAddress?: string;
  customerDocumentNumber?: string;
  cashierName: string;
  branchCode: string;
  lines: ReceiptLine[];
  qrData?: string;
}

export interface ReceiptLine {
  lineNumber: number;
  currencyCode: string;
  appliedRate: number;
  banknoteCount: number;
  hufValue: number;
  lineDiscount: number;
}

// ============================================================
// Matrica pénztár — Típusdefiníciók
// ============================================================

export interface StampBatch {
  id: string;
  branchId: string;
  serialPrefix: string;
  serialStart: number;
  serialEnd: number;
  totalCount: number;
  usedCount: number;
  receivedAt: string;
  receivedBy?: string;
  note?: string;
}

export interface StampAssignment {
  id: string;
  batchId: string;
  serialNumber: string;
  transactionId?: number;
  assignedAt: string;
  assignedBy?: string;
}

export interface CreateStampBatchRequest {
  branchId: string;
  serialPrefix: string;
  serialStart: number;
  serialEnd: number;
  note?: string;
}

export interface AssignStampRequest {
  serialNumber: string;
  transactionId: number;
}

// ============================================================
// Navigáció kiegészítés (Batch 2B)
// ============================================================

export type PageRouteBatch2B =
  | PageRoute
  | '/supervisor'
  | '/worker-management'
  | '/receipt-search'
  | '/stamps';

// ============================================================
// Batch 3 — Dekádjelentés, Kezelési díj, Forgalom, Verseny, Göngyöleg
// ============================================================

// --- Dekádjelentés ---
export type DecadeReportStatus = 'DRAFT' | 'CLOSED';

export interface DecadeReport {
  id: string;
  branchId: string;
  year: number;
  decade: number;
  totalBuyHuf: number;
  totalSellHuf: number;
  totalHandlingFee: number;
  transactionCount: number;
  status: DecadeReportStatus;
  closedAt: string | null;
  closedBy: number | null;
  createdAt: string;
}

export interface GenerateDecadeReportRequest {
  branchId: string;
  year: number;
  decade: number;
}

// --- Kezelési díj részletes ---
export type HandlingFeeType = 'FIXED' | 'PERCENT' | 'TIERED';

export interface HandlingFeeTransactionItem {
  id: string;
  transactionId: number;
  feeType: HandlingFeeType;
  amount: number;
  discountPercent: number;
  discountReason: string | null;
  netFee: number;
  workerCommissionShare: number;
  createdAt: string;
}

export interface HandlingFeeReport {
  dateFrom: string;
  dateTo: string;
  totalGrossFee: number;
  totalDiscount: number;
  totalNetFee: number;
  totalCommissionShare: number;
  transactionCount: number;
  items: HandlingFeeTransactionItem[];
}

// --- Forgalom összesítő ---
export interface TurnoverReport {
  period: string;
  totalBuy: number;
  totalSell: number;
  spread: number;
  fees: number;
  netProfit: number;
  byCurrency: TurnoverCurrency[];
  byWorker: TurnoverWorker[];
}

export interface TurnoverCurrency {
  currencyCode: string;
  buyVolume: number;
  sellVolume: number;
  buyHuf: number;
  sellHuf: number;
  transactionCount: number;
}

export interface TurnoverWorker {
  workerId: number;
  workerName: string;
  totalVolume: number;
  transactionCount: number;
}

// --- Árfolyam kategória ---
export type RateCategoryType = 'STANDARD' | 'SMALL' | 'LARGE';

export interface RateCategoryData {
  id: string;
  branchId: string;
  currencyCode: string;
  category: RateCategoryType;
  buyRate: number;
  sellRate: number;
  minAmount: number | null;
  maxAmount: number | null;
  validFrom: string;
  validTo: string | null;
}

// --- Verseny ---
export type CompetitionStatus = 'ACTIVE' | 'CLOSED';

export interface Competition {
  id: string;
  competitionName: string;
  startDate: string;
  endDate: string;
  status: CompetitionStatus;
  rules: string | null;
  createdAt: string;
}

export interface CompetitionEntry {
  id: string;
  competitionId: string;
  workerId: number;
  workerName: string;
  totalVolume: number;
  transactionCount: number;
  score: number;
  rank: number;
}

export interface CreateCompetitionRequest {
  competitionName: string;
  startDate: string;
  endDate: string;
  rules?: string;
}

// --- Göngyöleg ---
export interface PackagingRecord {
  id: string;
  branchId: string;
  currencyCode: string;
  packagingDate: string;
  bundleCount: number;
  denomination: number;
  bundleSize: number;
  notes: string | null;
  createdAt: string;
}

export interface CreatePackagingRequest {
  branchId: string;
  currencyCode: string;
  packagingDate: string;
  bundleCount: number;
  denomination: number;
  bundleSize?: number;
  notes?: string;
}

// --- Navigáció kiegészítés (Batch 3) ---
export type PageRouteBatch3 =
  | PageRouteBatch2B
  | '/decade-report'
  | '/competition';

// ============================================================
// Batch 4 — Trade, Sync, Dashboard, Notification, System Params
// ============================================================

// --- Trade (devizakereskedés) ---
export type TradeStatus = 'PROPOSED' | 'ACCEPTED' | 'REJECTED' | 'COMPLETED' | 'CANCELLED';

export interface TradeData {
  id: string;
  fromBranchId: string;
  fromBranchName: string;
  toBranchId: string;
  toBranchName: string;
  currencyCode: string;
  amount: number;
  rate: number;
  status: TradeStatus;
  proposedBy: number;
  acceptedBy: number | null;
  proposedAt: string;
  acceptedAt: string | null;
  completedAt: string | null;
  notes: string | null;
}

// --- Sync ---
export type SyncType = 'RATES' | 'TRANSACTIONS' | 'INVENTORY' | 'CLOSING' | 'FULL';
export type SyncDirection = 'UP' | 'DOWN';
export type SyncStatusType = 'PENDING' | 'RUNNING' | 'COMPLETED' | 'FAILED';

export interface SyncLogData {
  id: string;
  branchId: string;
  syncType: SyncType;
  direction: SyncDirection;
  status: SyncStatusType;
  startedAt: string;
  completedAt: string | null;
  recordCount: number;
  errorMessage: string | null;
}

// --- Dashboard ---
export interface DashboardSummaryData {
  todayVolume: number;
  activeBranches: number;
  openTransactions: number;
  alertCount: number;
  currencyVolumes: Record<string, number>;
  recentTransactions: Array<{
    id: number;
    receiptNumber: string;
    type: string;
    currencyCode: string;
    amount: number;
    hufAmount: number;
    cashierName: string;
    createdAt: string;
  }>;
  branchSyncStatuses: Array<{
    branchCode: string;
    branchName: string;
    lastSyncAt: string;
    status: string;
  }>;
}

// --- Notification (bővített) ---
export type NotificationType = 'INFO' | 'WARNING' | 'ALERT' | 'RATE_CHANGE' | 'CIRCULAR' | 'SYSTEM';

export interface NotificationData {
  id: string;
  title: string;
  message: string;
  type: NotificationType;
  userId: string;
  isRead: boolean;
  createdAt: string;
}

// --- System Parameter kategóriák ---
export type SystemParamCategory = 'GENERAL' | 'RATES' | 'FEES' | 'LIMITS' | 'SYNC' | 'PRINT' | 'SECURITY';

// --- Navigáció kiegészítés (Batch 4) ---
export type PageRouteBatch4 =
  | PageRouteBatch3
  | '/trade'
  | '/dashboard';

// ============================================================
// Batch 4B — Helga locserver + Backup + Licenc + Nyomtatási sablonok
// ============================================================

// --- Fiók monitoring (locserver) ---
export interface BranchStatusData {
  id: string;
  branchId: string;
  lastHeartbeat: string | null;
  lastSync: string | null;
  isOnline: boolean;
  lastTransactionAt: string | null;
  dailyTransactionCount: number;
  dailyVolumeHuf: number;
  openAlerts: number;
}

// --- Backup / Restore ---
export type BackupType = 'FULL' | 'INCREMENTAL' | 'TABLES_ONLY';
export type BackupStatusType = 'RUNNING' | 'COMPLETED' | 'FAILED';

export interface BackupRecordData {
  id: string;
  backupType: BackupType;
  status: BackupStatusType;
  filePath: string | null;
  fileSizeBytes: number | null;
  startedAt: string;
  completedAt: string | null;
  createdBy: string | null;
}

export interface CreateBackupRequest {
  type: BackupType;
}

// --- Licenc kezelés ---
export type LicenseStatusType = 'VALID' | 'EXPIRED' | 'EXCEEDED' | 'NO_LICENSE' | 'NOT_YET_VALID';

export interface LicenseData {
  id: string;
  companyId: number | null;
  licenseKey: string;
  validFrom: string;
  validTo: string;
  maxBranches: number;
  maxWorkers: number;
  features: string | null;
  isActive: boolean;
  remainingDays: number;
}

export interface LicenseStatusData {
  status: LicenseStatusType;
  remainingDays: number;
  maxBranches: number;
  maxWorkers: number;
  features: string | null;
}

export interface LicenseActivateRequest {
  licenseKey: string;
}

// --- Nyomtatási sablonok ---
export type PrintTemplateType = 'RECEIPT' | 'REPORT' | 'LABEL' | 'CLOSING';

export interface PrintTemplateData {
  id: string;
  name: string;
  templateType: PrintTemplateType;
  content: string | null;
  isDefault: boolean;
  companyId: number | null;
  createdAt: string;
  updatedAt: string;
}

export interface PrintTemplateCreateRequest {
  name: string;
  templateType: string;
  content: string;
  isDefault?: boolean;
  companyId?: number;
}

// --- Navigáció kiegészítés (Batch 4B) ---
export type PageRouteBatch4B =
  | PageRouteBatch3
  | '/backup'
  | '/print-templates';

// ============================================================
// Batch 5A — Árfolyam motor + Készlet + Bizonylat + Ügyfélkezelés
// ============================================================

// --- Árfolyam történet ---
export interface RateHistoryData {
  id: number;
  currencyCode: string;
  buyRate: number;
  sellRate: number;
  mnbRate: number | null;
  spread: number | null;
  category: RateCategoryType;
  effectiveFrom: string;
  effectiveTo: string | null;
  setBy: number | null;
  approvedBy: number | null;
  branchId: string | null;
  companyId: string;
  createdAt: string;
}

// --- Készlet mozgás napló ---
export type InventoryMovementType =
  | 'BUY' | 'SELL' | 'TRANSFER_IN' | 'TRANSFER_OUT'
  | 'ADJUSTMENT' | 'OPENING' | 'CLOSING';

export interface InventoryMovementLogItem {
  id: number;
  branchId: string;
  currencyCode: string;
  amount: number;
  movementType: string;
  transactionId: number | null;
  workerId: number | null;
  balanceBefore: number | null;
  balanceAfter: number | null;
  createdAt: string;
  notes: string | null;
}

export interface InventoryBalanceData {
  branchId: string;
  currencyCode: string;
  openingBalance: number;
  closingBalance: number;
  totalIn: number;
  totalOut: number;
  date: string;
}

// --- Bizonylat (Receipt) ---
export type ReceiptType = 'SELL' | 'BUY' | 'TRANSFER' | 'STORNO' | 'CLOSING';

export interface ReceiptDataFull {
  receiptNumber: string;
  receiptType: ReceiptType;
  companyName: string;
  branchName: string;
  workerName: string;
  date: string;
  currencyCode: string | null;
  foreignAmount: number | null;
  rate: number | null;
  hufAmount: number | null;
  handlingFee: number;
  customerName: string | null;
  customerIdNumber: string | null;
  lines: Array<{ label: string; value: string }>;
  qrCode: string | null;
  signatureLine: string;
}

// --- Ügyfél statisztika ---
export interface CustomerStats {
  customerId: number;
  customerName: string;
  totalTransactions: number;
  totalVolumeHuf: number;
  averageAmount: number;
  firstVisit: string | null;
  lastVisit: string | null;
  preferredCurrency: string | null;
}

export interface CustomerRanking {
  customerId: number | null;
  customerName: string;
  transactionCount: number;
  totalVolumeHuf: number;
  rank: number;
}

// --- Navigáció kiegészítés (Batch 5A) ---
export type PageRouteBatch5A =
  | PageRouteBatch4B
  | '/rate-history';

// ============================================================
// Batch 6A — Napi záró wizard + Pénztárnyitás + Kalkulátor + Kerekítés
// ============================================================

// --- Kerekítési szabályok ---
export interface RoundingRule {
  id: number;
  currencyCode: string;
  precisionValue: number;
  smallThreshold: number;
  largeThreshold: number;
  smallRounding: 'UP' | 'DOWN' | 'HALF_UP';
  largeRounding: 'UP' | 'DOWN' | 'HALF_UP';
}

// --- Deviza kalkulátor ---
export interface CalculationResult {
  fromCurrency: string;
  toCurrency: string;
  fromAmount: number;
  toAmount: number;
  appliedRate: number;
  spread: number;
  commission: number;
  direction: string;
  roundingInfo: string;
}

export interface ConvertRequest {
  fromCurrency: string;
  toCurrency: string;
  amount: number;
  direction: 'BUY' | 'SELL';
}

export interface ReverseRequest {
  currency: string;
  hufAmount: number;
}

// --- Pénztárnyitás ---
export interface SessionOpenRequest {
  workerId: number;
  branchId: string;
}

export interface SessionData {
  sessionId: number;
  branchId: string;
  branchName: string;
  workerId: number;
  workerName: string;
  sessionDate: string;
  status: string;
  openedAt: string;
  closedAt?: string;
  openingBalances: Record<string, number>;
  warnings: string[];
}

// --- Navigáció kiegészítés (Batch 6A) ---
export type PageRouteBatch6A =
  | PageRouteBatch5A
  | '/session-open'
  | '/calculator';

// ============================================================
// Batch 8A — Pénztárgép + LED kijelző config + Szkenner + FTP sync
// ============================================================

// --- Pénztárgép (Cash Register) ---
export type CashRegisterEventType = 'OPEN' | 'CLOSE' | 'RECEIPT' | 'STORNO' | 'X_REPORT' | 'Z_REPORT';

export interface CashRegisterEventData {
  id: string;
  branchId: string;
  eventType: CashRegisterEventType;
  receiptNumber: string | null;
  amount: number | null;
  currencyCode: string | null;
  amountHuf: number | null;
  taxNumber: string | null;
  cashRegisterId: string | null;
  eventTimestamp: string;
  rawResponse: string | null;
}

export interface CashRegisterReceiptRequest {
  branchId: string;
  receiptNumber: string;
  amount: number;
  currencyCode: string;
  amountHuf: number;
}

export interface CashRegisterStornoRequest {
  branchId: string;
  originalReceiptId: string;
}

// --- LED kijelző konfiguráció ---
export type LedDisplayConnectionType = 'SERIAL' | 'USB' | 'NETWORK';

export interface LedDisplayConfigData {
  id: string;
  branchId: string;
  displayType: LedDisplayConnectionType;
  connectionString: string | null;
  isActive: boolean;
  refreshIntervalSeconds: number;
  displayedCurrencies: string | null;
  lastUpdatedAt: string | null;
}

export interface SaveLedDisplayConfigRequest {
  branchId: string;
  displayType?: string;
  connectionString?: string;
  isActive?: boolean;
  refreshIntervalSeconds?: number;
  displayedCurrencies?: string;
}

export interface LedDisplayLine {
  currencyCode: string;
  buyRate: number;
  sellRate: number;
  unit: number;
}

// --- Dokumentum szkenner ---
export type ScannedDocumentType = 'ID_CARD' | 'PASSPORT' | 'DRIVERS_LICENSE' | 'OTHER';

export interface ScannedDocumentData {
  id: string;
  customerId: string | null;
  transactionId: string | null;
  documentType: ScannedDocumentType;
  fileName: string;
  mimeType: string | null;
  fileSizeBytes: number | null;
  storagePath: string | null;
  scannedBy: number | null;
  scannedAt: string;
  notes: string | null;
}

// --- FTP szinkronizáció ---
export type FtpSyncDirection = 'UPLOAD' | 'DOWNLOAD';
export type FtpSyncStatusType = 'SUCCESS' | 'FAILED';

export interface FtpSyncLogData {
  id: string;
  branchId: string;
  direction: FtpSyncDirection;
  fileName: string | null;
  status: FtpSyncStatusType;
  fileSizeBytes: number | null;
  startedAt: string;
  completedAt: string | null;
  errorMessage: string | null;
}

export interface FtpSyncResult {
  success: boolean;
  message: string;
  fileName: string | null;
  fileSizeBytes: number | null;
  syncLog: FtpSyncLogData;
}

// ============================================================
// Nyomtatás — Típusdefiníciók (ESC/POS Thermal Printer)
// ============================================================

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
