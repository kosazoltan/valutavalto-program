"use strict";
const electron = require("electron");
electron.contextBridge.exposeInMainWorld("electronAPI", {
  printReceipt: (data) => electron.ipcRenderer.invoke("print-receipt", data),
  getConfig: (key) => electron.ipcRenderer.invoke("get-config", key),
  setConfig: (key, value) => electron.ipcRenderer.invoke("set-config", key, value),
  syncOffline: () => electron.ipcRenderer.invoke("sync-offline"),
  getAppVersion: () => electron.ipcRenderer.invoke("get-app-version"),
  platform: process.platform
});
