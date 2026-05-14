import { contextBridge, ipcRenderer } from 'electron'

contextBridge.exposeInMainWorld('electronAPI', {
  googleOAuthFlow: (): Promise<
    | { ok: true; idToken: string; email?: string }
    | { ok: false; code: string; message: string }
  > => ipcRenderer.invoke('auth:google-oauth-flow'),

  googleOAuthFlowWithBackend: (appMode?: string): Promise<
    | { ok: true; response: unknown; email?: string }
    | { ok: false; code: string; message: string }
  > => ipcRenderer.invoke('auth:google-oauth-flow-with-backend', { appMode }),

  apiRequest: (params: {
    method: string
    url: string
    body?: string | null
    headers?: Record<string, string>
    timeoutMs?: number
  }) => ipcRenderer.invoke('api:fetch', params),

  passwordLogin: (data: {
    companyCode: string
    workerCode: string
    password: string
    appMode?: string
  }) => ipcRenderer.invoke('auth:password-login', data),

  reportError: (payload: {
    component?: string
    message: string
    stack?: string
    context?: Record<string, unknown>
  }) => ipcRenderer.invoke('diagnostics:report-error', payload),

  setDiagnosticUserIdentifier: (id: string | null) =>
    ipcRenderer.invoke('diagnostics:set-user-identifier', id),

  getConfig: (key: string) => ipcRenderer.invoke('get-config', key),
  setConfig: (key: string, value: string) => ipcRenderer.invoke('set-config', key, value),
  deleteConfig: (key: string) => ipcRenderer.invoke('delete-config', key),

  secureStoreToken: (token: string) => ipcRenderer.invoke('secure-store-token', token),
  secureLoadToken: () => ipcRenderer.invoke('secure-load-token'),
  secureClearToken: () => ipcRenderer.invoke('secure-clear-token'),

  getAppVersion: () => ipcRenderer.invoke('get-app-version'),
  restartApp: () => ipcRenderer.invoke('restart-app'),

  // --- Local-first API ---
  localFirst: {
    getSyncStatus: () => ipcRenderer.invoke('lf:sync-status'),
    getOutboxStats: () => ipcRenderer.invoke('lf:outbox-stats'),
    triggerSync: () => ipcRenderer.invoke('lf:trigger-sync'),
    saveRateDraft: (draft: Record<string, unknown>) => ipcRenderer.invoke('lf:save-rate-draft', draft),
    updateRateDraft: (draft: Record<string, unknown>) => ipcRenderer.invoke('lf:update-rate-draft', draft),
    deleteRateDraft: (entityId: string) => ipcRenderer.invoke('lf:delete-rate-draft', entityId),
    getRateDrafts: () => ipcRenderer.invoke('lf:get-rate-drafts'),
    getPublishedRates: () => ipcRenderer.invoke('lf:get-published-rates'),
    getCurrencyPairs: () => ipcRenderer.invoke('lf:get-currency-pairs'),
  },

  platform: process.platform,
})
