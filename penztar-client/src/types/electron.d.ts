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
  getAppVersion: () => Promise<string>;
  getPrinters: () => Promise<PrinterInfo[]>;
  platform: string;
}

declare global {
  interface Window {
    electronAPI: ElectronAPI;
  }
}
