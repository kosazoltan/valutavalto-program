export interface ElectronAPI {
  // --- Config (token persist) ---
  getConfig(key: string): Promise<string | null>;
  setConfig(key: string, value: string): Promise<void>;
  deleteConfig(key: string): Promise<void>;

  // --- Nyomtatás ---
  printReceipt(data: string): Promise<boolean>;
  getPrinters(): Promise<Array<{
    name: string;
    displayName: string;
    description: string;
    status: number;
    isDefault: boolean;
  }>>;

  // --- Offline tranzakciók ---
  savePendingTransaction(
    type: 'SELL' | 'BUY',
    currencyCode: string,
    foreignAmount: number,
    hufAmount: number,
    roundedHufAmount: number,
    rate: number,
    customerId: number | null,
    denominations: string | null,
  ): Promise<number>;
  getPendingTransactions(): Promise<Array<{
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
  }>>;
  getPendingTransactionCount(): Promise<number>;
  syncOffline(): Promise<number>;
  getSyncStatus(): Promise<string>;

  // --- Értéktár offline ---
  savePendingDistribution(
    targetBranchCode: string,
    currencyCode: string,
    amount: number,
    denominations: string | null,
    note: string | null,
  ): Promise<number>;
  savePendingTransfer(
    targetBranchCode: string,
    currencyCode: string,
    amount: number,
    denominations: string | null,
    note: string | null,
  ): Promise<number>;
  savePendingCollection(
    sourceBranchCode: string,
    currencyCode: string,
    amount: number,
    note: string | null,
  ): Promise<number>;
  getCachedBranchStatuses(): Promise<Array<{
    branch_code: string;
    branch_name: string;
    company_id: number | null;
    last_sync_at: string | null;
    online_status: string;
    total_huf_value: number;
    daily_turnover: number;
    cash_balances: string | null;
    cached_at: string;
  }>>;
  getCachedBranchStatusTimestamp(): Promise<string | null>;
  getCachedRates(): Promise<Array<{
    currency_code: string;
    buy_rate: number;
    sell_rate: number;
    unit: number;
    updated_at: string;
  }>>;

  // --- Kamera (lokális Electron rögzítés + keresés) ---
  cameraSaveRecording(transactionId: string, buffer: ArrayBuffer, ext: string): Promise<string>;
  cameraExportToUsb(dateFrom: string, dateTo: string): Promise<{ success: boolean; exported: number; error?: string }>;
  cameraListRecordings(transactionId?: string): Promise<string[]>;
  cameraLocalStorageStats?(): Promise<{
    totalUsageBytes: number;
    availableSpaceBytes: number;
    totalRecordings: number;
    oldestDate: string | null;
    newestDate: string | null;
  }>;
  cameraLocalRecordingsByDate?(dateFrom: string, dateTo: string): Promise<Array<{
    date: string;
    transactionId: string;
    filePath: string;
    fileSizeBytes: number;
    createdAt: string;
  }>>;
  cameraLocalReadFile?(filePath: string): Promise<string | null>;
  cameraLocalCleanup?(retentionDays: number): Promise<{ deletedCount: number }>;

  // --- Okmány szkenner ---
  scanSaveDocument(
    transactionId: string,
    documentType: 'szemelyi' | 'utlevel' | 'jogositvany' | 'egyeb',
    imageBase64: string,
  ): Promise<{ path: string; encrypted: boolean }>;
  scanGetDocument(filepath: string): Promise<string>;
  scanListDocuments(transactionId: string): Promise<string[]>;

  // --- Secure Token Storage (DPAPI/Keychain titkositott) ---
  secureStoreToken?(token: string): Promise<boolean>;
  secureLoadToken?(): Promise<string | null>;
  secureClearToken?(): Promise<void>;

  // --- App ---
  getAppVersion(): Promise<string>;
  restartApp(): Promise<void>;

  // --- Platform ---
  platform: string;
}

declare global {
  interface Window {
    electronAPI?: ElectronAPI;
  }
}
