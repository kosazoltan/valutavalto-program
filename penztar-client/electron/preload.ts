import { contextBridge, ipcRenderer } from 'electron';

contextBridge.exposeInMainWorld('electronAPI', {
  printReceipt: (data: string): Promise<boolean> =>
    ipcRenderer.invoke('print-receipt', data),

  getConfig: (key: string): Promise<string | null> =>
    ipcRenderer.invoke('get-config', key),

  setConfig: (key: string, value: string): Promise<void> =>
    ipcRenderer.invoke('set-config', key, value),

  deleteConfig: (key: string): Promise<void> =>
    ipcRenderer.invoke('delete-config', key),

  savePendingTransaction: (
    type: 'SELL' | 'BUY',
    currencyCode: string,
    foreignAmount: number,
    hufAmount: number,
    roundedHufAmount: number,
    rate: number,
    customerId: number | null,
    denominations: string | null,
  ): Promise<number> =>
    ipcRenderer.invoke(
      'save-pending-transaction',
      type, currencyCode, foreignAmount, hufAmount, roundedHufAmount, rate, customerId, denominations,
    ),

  getPendingTransactions: (): Promise<Array<{
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
  }>> =>
    ipcRenderer.invoke('get-pending-transactions'),

  getPendingTransactionCount: (): Promise<number> =>
    ipcRenderer.invoke('get-pending-transaction-count'),

  syncOffline: (): Promise<number> =>
    ipcRenderer.invoke('sync-offline'),

  getSyncStatus: (): Promise<string> =>
    ipcRenderer.invoke('get-sync-status'),

  getAppVersion: (): Promise<string> =>
    ipcRenderer.invoke('get-app-version'),

  restartApp: (): Promise<void> =>
    ipcRenderer.invoke('restart-app'),

  getPrinters: (): Promise<Array<{
    name: string;
    displayName: string;
    description: string;
    status: number;
    isDefault: boolean;
  }>> =>
    ipcRenderer.invoke('get-printers'),

  // --- Értéktár Offline IPC ---

  savePendingDistribution: (
    targetBranchCode: string,
    currencyCode: string,
    amount: number,
    denominations: string | null,
    note: string | null,
  ): Promise<number> =>
    ipcRenderer.invoke(
      'save-pending-distribution',
      targetBranchCode, currencyCode, amount, denominations, note,
    ),

  savePendingTransfer: (
    targetBranchCode: string,
    currencyCode: string,
    amount: number,
    denominations: string | null,
    note: string | null,
  ): Promise<number> =>
    ipcRenderer.invoke(
      'save-pending-transfer',
      targetBranchCode, currencyCode, amount, denominations, note,
    ),

  savePendingCollection: (
    sourceBranchCode: string,
    currencyCode: string,
    amount: number,
    note: string | null,
  ): Promise<number> =>
    ipcRenderer.invoke(
      'save-pending-collection',
      sourceBranchCode, currencyCode, amount, note,
    ),

  getCachedBranchStatuses: (): Promise<Array<{
    branch_code: string;
    branch_name: string;
    company_id: number | null;
    last_sync_at: string | null;
    online_status: string;
    total_huf_value: number;
    daily_turnover: number;
    cash_balances: string | null;
    cached_at: string;
  }>> =>
    ipcRenderer.invoke('get-cached-branch-statuses'),

  getCachedBranchStatusTimestamp: (): Promise<string | null> =>
    ipcRenderer.invoke('get-cached-branch-status-timestamp'),

  getCachedRates: (): Promise<Array<{
    currency_code: string;
    buy_rate: number;
    sell_rate: number;
    unit: number;
    updated_at: string;
  }>> =>
    ipcRenderer.invoke('get-cached-rates'),

  // Kamera
  cameraSaveRecording: (transactionId: string, buffer: ArrayBuffer, ext: string): Promise<string> =>
    ipcRenderer.invoke('camera-save-recording', transactionId, buffer, ext),

  cameraExportToUsb: (dateFrom: string, dateTo: string): Promise<{ success: boolean; exported: number; error?: string }> =>
    ipcRenderer.invoke('camera-export-to-usb', dateFrom, dateTo),

  cameraListRecordings: (transactionId?: string): Promise<string[]> =>
    ipcRenderer.invoke('camera-list-recordings', transactionId),

  // Okmány scan
  scanSaveDocument: (
    transactionId: string,
    documentType: 'szemelyi' | 'utlevel' | 'jogositvany' | 'egyeb',
    imageBase64: string,
  ): Promise<{ path: string; encrypted: boolean }> =>
    ipcRenderer.invoke('scan-save-document', transactionId, documentType, imageBase64),

  scanGetDocument: (filepath: string): Promise<string> =>
    ipcRenderer.invoke('scan-get-document', filepath),

  scanListDocuments: (transactionId: string): Promise<string[]> =>
    ipcRenderer.invoke('scan-list-documents', transactionId),

  platform: process.platform,
});
