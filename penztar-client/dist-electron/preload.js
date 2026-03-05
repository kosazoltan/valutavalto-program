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
  platform: process.platform
});
