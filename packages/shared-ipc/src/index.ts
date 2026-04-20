// ============================================================
// Shared IPC Contract
// ============================================================
// Single source of truth az Electron main <-> renderer IPC
// szerzodeshez. A main process az IpcRoute alapjan registral
// handlereket, a renderer pedig az azonos IpcRoute-ot hasznalja
// tipizaltan (electronAPI).
//
// HASZNALAT:
//
//   main/preload:
//     import type { IpcRoutes } from '@valuta/shared-ipc'
//     ipcMain.handle('setup:save', ...)
//
//   renderer:
//     import type { IpcRoutes } from '@valuta/shared-ipc'
//     const res: IpcRoutes['setup:save']['response'] =
//         await window.electronAPI.setupSave(payload)
//
// Minden uj IPC endpoint csak ide kerul be, es a 3 processz
// mar jatszik egy forrasbol.
// ============================================================

// ---- Setup Wizard IPC ----
export interface SetupSaveRequest {
  branchCode: string
  branchName: string
  apiUrl: string
  companyCode: string
  adminUsername: string
  adminPassword: string
  bootstrapUsername: string
  bootstrapPassword: string
  offlineMode: boolean
  appMode: 'penztar' | 'ertektar' | 'ertekszallito'
}

export interface SetupSaveResponse {
  success: boolean
  errorMessage?: string
  configPath?: string
}

export interface SetupTestConnectionRequest {
  apiUrl: string
  companyCode: string
  username: string
  password: string
}

export interface SetupTestConnectionResponse {
  success: boolean
  httpStatus?: number
  latencyMs?: number
  errorMessage?: string
}

// ---- Sync Engine IPC ----
export interface SyncStatusResponse {
  lastSyncAt: string | null
  pendingCount: number
  isOnline: boolean
  errorMessage?: string
}

// ---- Aggregate contract table ----
// A router-szintu fel-hasznalas: Record<channel, req/res parja>
export interface IpcRoutes {
  'setup:save': {
    request: SetupSaveRequest
    response: SetupSaveResponse
  }
  'setup:test-connection': {
    request: SetupTestConnectionRequest
    response: SetupTestConnectionResponse
  }
  'sync:status': {
    request: void
    response: SyncStatusResponse
  }
}

// Type helper: kihuzza egy channel request/response tipusat
export type IpcRequest<K extends keyof IpcRoutes> = IpcRoutes[K]['request']
export type IpcResponse<K extends keyof IpcRoutes> = IpcRoutes[K]['response']

// Runtime channel nevek konstans-kent - mindhárom process ebbol importál
export const IPC_CHANNELS = {
  SETUP_SAVE: 'setup:save' as const,
  SETUP_TEST_CONNECTION: 'setup:test-connection' as const,
  SYNC_STATUS: 'sync:status' as const,
} satisfies Record<string, keyof IpcRoutes>
