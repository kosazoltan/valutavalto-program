"use strict";
const electron = require("electron");
electron.contextBridge.exposeInMainWorld("electronAPI", {
  printReceipt: (data) => electron.ipcRenderer.invoke("print-receipt", data),
  getConfig: (key) => electron.ipcRenderer.invoke("get-config", key),
  setConfig: (key, value) => electron.ipcRenderer.invoke("set-config", key, value),
  deleteConfig: (key) => electron.ipcRenderer.invoke("delete-config", key),
  savePendingTransaction: (type, currencyCode, foreignAmount, hufAmount, roundedHufAmount, rate, customerId, denominations) => electron.ipcRenderer.invoke(
    "save-pending-transaction",
    type,
    currencyCode,
    foreignAmount,
    hufAmount,
    roundedHufAmount,
    rate,
    customerId,
    denominations
  ),
  getPendingTransactions: () => electron.ipcRenderer.invoke("get-pending-transactions"),
  getPendingTransactionCount: () => electron.ipcRenderer.invoke("get-pending-transaction-count"),
  syncOffline: () => electron.ipcRenderer.invoke("sync-offline"),
  getSyncStatus: () => electron.ipcRenderer.invoke("get-sync-status"),
  getAppVersion: () => electron.ipcRenderer.invoke("get-app-version"),
  getPrinters: () => electron.ipcRenderer.invoke("get-printers"),
  // --- Értéktár Offline IPC ---
  savePendingDistribution: (targetBranchCode, currencyCode, amount, denominations, note) => electron.ipcRenderer.invoke(
    "save-pending-distribution",
    targetBranchCode,
    currencyCode,
    amount,
    denominations,
    note
  ),
  savePendingTransfer: (targetBranchCode, currencyCode, amount, denominations, note) => electron.ipcRenderer.invoke(
    "save-pending-transfer",
    targetBranchCode,
    currencyCode,
    amount,
    denominations,
    note
  ),
  savePendingCollection: (sourceBranchCode, currencyCode, amount, note) => electron.ipcRenderer.invoke(
    "save-pending-collection",
    sourceBranchCode,
    currencyCode,
    amount,
    note
  ),
  getCachedBranchStatuses: () => electron.ipcRenderer.invoke("get-cached-branch-statuses"),
  getCachedBranchStatusTimestamp: () => electron.ipcRenderer.invoke("get-cached-branch-status-timestamp"),
  getCachedRates: () => electron.ipcRenderer.invoke("get-cached-rates"),
  platform: process.platform
});
