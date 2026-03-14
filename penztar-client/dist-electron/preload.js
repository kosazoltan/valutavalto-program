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
  restartApp: () => electron.ipcRenderer.invoke("restart-app"),
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
  // Kamera
  cameraSaveRecording: (transactionId, buffer, ext) => electron.ipcRenderer.invoke("camera-save-recording", transactionId, buffer, ext),
  cameraExportToUsb: (dateFrom, dateTo) => electron.ipcRenderer.invoke("camera-export-to-usb", dateFrom, dateTo),
  cameraListRecordings: (transactionId) => electron.ipcRenderer.invoke("camera-list-recordings", transactionId),
  // Okmány scan
  scanSaveDocument: (transactionId, documentType, imageBase64) => electron.ipcRenderer.invoke("scan-save-document", transactionId, documentType, imageBase64),
  scanGetDocument: (filepath) => electron.ipcRenderer.invoke("scan-get-document", filepath),
  scanListDocuments: (transactionId) => electron.ipcRenderer.invoke("scan-list-documents", transactionId),
  platform: process.platform
});
