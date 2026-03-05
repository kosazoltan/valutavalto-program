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

  getPrinters: (): Promise<Array<{
    name: string;
    displayName: string;
    description: string;
    status: number;
    isDefault: boolean;
  }>> =>
    ipcRenderer.invoke('get-printers'),

  platform: process.platform,
});
