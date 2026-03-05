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
  | '/settings';

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
