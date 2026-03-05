export interface PendingTransactionRecord {
  id: number;
  type: string;
  currency_code: string;
  foreign_amount: number;
  huf_amount: number;
  rounded_huf_amount: number;
  rate: number;
  customer_id: number | null;
  denominations: string | null;
  created_at: string;
  synced: number;
}

export interface PrinterInfo {
  name: string;
  displayName: string;
  description: string;
  status: number;
  isDefault: boolean;
}

export interface CachedBranchStatusRecord {
  branch_code: string;
  branch_name: string;
  company_id: number | null;
  last_sync_at: string | null;
  online_status: string;
  total_huf_value: number;
  daily_turnover: number;
  cash_balances: string | null;
  cached_at: string;
}

export interface CachedRateRecord {
  currency_code: string;
  buy_rate: number;
  sell_rate: number;
  unit: number;
  updated_at: string;
}

export interface ElectronAPI {
  printReceipt: (data: string) => Promise<boolean>;
  getConfig: (key: string) => Promise<string | null>;
  setConfig: (key: string, value: string) => Promise<void>;
  deleteConfig: (key: string) => Promise<void>;
  savePendingTransaction: (
    type: 'SELL' | 'BUY',
    currencyCode: string,
    foreignAmount: number,
    hufAmount: number,
    roundedHufAmount: number,
    rate: number,
    customerId: number | null,
    denominations: string | null,
  ) => Promise<number>;
  getPendingTransactions: () => Promise<PendingTransactionRecord[]>;
  getPendingTransactionCount: () => Promise<number>;
  syncOffline: () => Promise<number>;
  getSyncStatus: () => Promise<string>;
  getAppVersion: () => Promise<string>;
  getPrinters: () => Promise<PrinterInfo[]>;

  // Értéktár offline mód
  savePendingDistribution: (
    targetBranchCode: string,
    currencyCode: string,
    amount: number,
    denominations: string | null,
    note: string | null,
  ) => Promise<number>;
  savePendingTransfer: (
    targetBranchCode: string,
    currencyCode: string,
    amount: number,
    denominations: string | null,
    note: string | null,
  ) => Promise<number>;
  savePendingCollection: (
    sourceBranchCode: string,
    currencyCode: string,
    amount: number,
    note: string | null,
  ) => Promise<number>;
  getCachedBranchStatuses: () => Promise<CachedBranchStatusRecord[]>;
  getCachedBranchStatusTimestamp: () => Promise<string | null>;
  getCachedRates: () => Promise<CachedRateRecord[]>;

  // Batch 2B: Okmány szkenner
  scanDocument: () => Promise<{ imageBase64: string; fileName: string }>;

  platform: string;
}

declare global {
  interface Window {
    electronAPI: ElectronAPI;
  }
}
