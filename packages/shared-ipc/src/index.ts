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
// X4 minta: IpcRoutes-entry + IPC_CHANNELS-konstans + preload IpcRequest/IpcResponse kötés.
// A maradék pénzmozgás-channel ugyanezt a mintát követi.
// ============================================================

// ---- Setup Wizard IPC ----
export interface SetupSaveRequest {
  branchCode: string
  branchName: string
  apiUrl: string
  companyCode: string
  authMode?: 'password' | 'google'
  adminUsername?: string
  adminPassword?: string
  bootstrapUsername?: string
  bootstrapPassword?: string
  offlineMode: boolean
  appMode: 'penztar' | 'ertektar' | 'rate-maker'
  // v2.3.0: a telepito dolgozoi dropdown-bol kivalasztott worker identity.
  // Ha kitoltve -> /auth/first-time-worker-setup (meglevo worker jelszo
  // beallitas, sajat role-vel). Egyebkent bootstrap-admin (uj admin user).
  selectedWorkerCode?: string
  selectedWorkerName?: string
  selectedWorkerRole?: string
  googleEmail?: string
  googleSub?: string
  googleName?: string
  googlePicture?: string
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

export interface SetupWorkersRequest {
  apiUrl: string
  companyCode: string
  branchCode: string
}

export interface SetupWorkerOption {
  code: string
  name: string
  region?: string
}

// ---- Sync Engine IPC ----
export interface SyncStatusResponse {
  lastSyncAt: string | null
  pendingCount: number
  isOnline: boolean
  errorMessage?: string
}

// ---- Pénzmozgás IPC (X4 2026-07-05): a 4 kritikus channel tipizálása ----
/**
 * V235 (2026-05-19 HIBA #14 + #15 + #17 + #18): bővített input objektum a
 * pending tranzakciók teljes Pmt. customer-snapshot mentéséhez. A korábbi
 * pozicionális paraméterű {@link savePendingTransaction} megmaradt backward
 * compat miatt — az új helyek a `savePendingTransactionV2`-t használják.
 */
export interface PendingTransactionInputV2 {
  type: 'SELL' | 'BUY'
  currencyCode: string
  foreignAmount: number
  hufAmount: number
  roundedHufAmount: number
  rate: number
  handlingFee: number | null
  discountPercent: number | null
  customerIdentifier: string | null
  customerName: string | null
  customerDocumentNumber: string | null
  customerAddress: string | null
  denominations: string | null
  foreignStatus: 'DOMESTIC' | 'FOREIGN' | null
  // V229 100k+ snapshot
  customerBirthPlace: string | null
  customerBirthDate: string | null
  customerMotherName: string | null
  customerNationality: string | null
  customerDocumentType: string | null
  // V229 300k+ JOGCÍM
  sourceOfFunds: string | null
  customerIsPep: boolean | null
  // AML vezetoi jovahagyas (2026-06-04): jovahagyo supervisor/manager/admin workerId.
  approverWorkerId: number | null
  // AML jovahagyas-session azonosito (Codex P1: receipt-scoping).
  approvalSessionId: string | null
  customerOnOwnBehalf: boolean | null
  customerActorName: string | null
  // V235 NEW (HIBA #15): PEP minőség
  customerPepKind: string | null
  // V235 NEW (HIBA #17): actor teljes azonosítása
  customerActorBirthPlace: string | null
  customerActorBirthDate: string | null
  customerActorMotherName: string | null
  customerActorNationality: string | null
  customerActorDocumentType: string | null
  customerActorDocumentNumber: string | null
  customerActorAddress: string | null
  /**
   * Multi-line aggregate (2026-06-04): ha kitoltott, ez a pending sor EGY tobb-soros
   * vetel/eladas nyugtat kepvisel — a backend `lines[]` aggregalt utvonalra kerul (egy
   * AML-kapu, egy approval-grant). JSON-string a backend TransactionLineRequestDto alakjaban
   * ([{ currencyCode, banknoteCount, customExchangeRate, discountType, foreignStatus }]).
   * NULL/undefined → egysoros tranzakcio (valtozatlan viselkedes).
   */
  lines?: string | null
  // FK-KEZDIJ offline (2026-06-12, penztar-batch B.1/b): a Felezes/Elenegedes/Ugyfelkartya
  // override a pending sorban is — a sync-engine a REST-tel azonos mezokkel kuldi fel.
  handlingFeeOverrideType?: string | null
  handlingFeeOverrideReason?: string | null
  customerCardNumber?: string | null
  // V325 (Batch3-C): jogi szemely + tenyleges tulajdonosok (JSON-string, max 4).
  isLegalEntityCustomer?: boolean | null
  legalEntityName?: string | null
  legalEntitySeat?: string | null
  legalEntityTaxNumber?: string | null
  legalDeedNumber?: string | null
  beneficialOwnersJson?: string | null
}

/**
 * V235 + V236 (2026-05-19 Codex P1 #695): bővített input objektum a
 * Konverzio offline outbox-hoz, teljes Pmt. customer-snapshot mentéséhez.
 * A pozicionális {@link savePendingConversion} megmarad backward compat
 * miatt — új helyek a `savePendingConversionV2`-t használják.
 */
export interface PendingConversionInputV2 {
  fromCurrencyId: number | null
  fromCurrencyCode: string
  toCurrencyId: number | null
  toCurrencyCode: string
  fromAmount: number
  calculatedHufAmount: number
  calculatedToAmount: number
  conversionRate: number
  handlingFee: number | null
  customerId: string | null
  customerName: string | null
  customerDocumentNumber: string | null
  customerAddress: string | null
  customerNationality: string | null
  customerBirthPlace: string | null
  customerBirthDate: string | null
  customerMotherName: string | null
  customerDocumentType: string | null
  sourceOfFunds: string | null
  customerIsPep: boolean | null
  approverWorkerId: number | null
  approvalSessionId: string | null
  customerOnOwnBehalf: boolean | null
  customerActorName: string | null
  customerPepKind: string | null
  customerActorBirthPlace: string | null
  customerActorBirthDate: string | null
  customerActorMotherName: string | null
  customerActorNationality: string | null
  customerActorDocumentType: string | null
  customerActorDocumentNumber: string | null
  customerActorAddress: string | null
  // HIBA 2026-05-26 (#2): ugyfel deviza-statusza (DOMESTIC/FOREIGN)
  foreignStatus: string | null
  note: string | null
}

// A pozicionális wire-formátum version-skew miatt VÁLTOZATLAN (régi telepített
// main + új renderer). A tuple címkézett, az utolsó 4 elem opcionális — a
// main-oldali default (= null) paritásban (main.ts save-pending-transfer).
export type SavePendingTransferArgs = [
  targetBranchId: string | null,
  targetBranchCode: string,
  currencyId: number | null,
  currencyCode: string,
  amount: number,
  hufValue: number | null,
  transferType: string | null,
  denominations: string | null,
  note: string | null,
  carrierName?: string | null,
  sealNumber?: string | null,
  direction?: string | null,
  lines?: string | null,
]

// ---- Pénzmozgás IPC X4/B (2026-07-05): további pénzmozgás/leltár írások ----
export interface PendingStornoInput {
  transactionId: number
  originalReceiptNumber: string
  originalTransactionType: string
  currencyCode: string
  foreignAmount: number | null
  hufAmount: number
  exchangeRate: number | null
  reason: string
  approvalId?: string | null
  customExchangeRate?: number | null
  paymentMethod?: string | null
  customerName?: string | null
  customerDocumentNumber?: string | null
}

export interface PendingTransferStornoInput {
  transferId: number
  transferNumber?: string | null
  reason: string
}

// FS-C (Center FS-1): körlevél-válasz offline outbox.
export interface PendingCircularReplyInput {
  circularId: number
  replyText: string
}

// FS-5: okmány-képpár feltöltési outbox (scan a pénztáron → center, törlés nyugtázás után).
export interface QueueScannedDocumentInput {
  customerId: number // SZERVER-oldali customer id
  documentType: 'szemelyi' | 'utlevel' | 'jogositvany' | 'egyeb'
  frontPath: string // scan-save-document visszaadott path
  backPath: string
  notes?: string | null
}

export interface PendingHandoverOperationInput {
  operationType: 'GENERATE' | 'PRINT' | 'COMPLETE'
  sheetId?: string | null
  fromCashDeskId?: string | null
  toCashDeskId?: string | null
  transferDate?: string | null
  amounts?: unknown
  note?: string | null
}

export interface PendingShipmentReceiptInput {
  shipmentId: string
  requestNumber?: string | null
  branchId: string
  workerId: number
  /** Az online próbálkozáskor létrehozott, retry-k között változatlan kulcs. */
  idempotencyKey: string
  /** Régi Shipment tudatos megerősítése; hiányában legacy, nem megerősített átvétel. */
  confirmedStale?: boolean
}

export interface PendingShipmentReceiptRow {
  id: number
  shipment_id: string
  request_number: string | null
  idempotency_key: string
  branch_id: string
  worker_id: number
  company_code: string | null
  created_at: string
  synced: number
  sync_attempts: number
  sync_error: string | null
  /** Legacy preload/sor esetén hiányozhat; az csak megerősítetlen átvételt jelent. */
  confirmed_stale?: number | null
}

// Pozicionális wire (Sprint 7.1) — a tuple címkézett, a formátum változatlan.
export type QueueStocktakeCountArgs = [
  itemId: string,
  actualQuantity: number,
  note: string | null,
  idempotencyKey: string | null,
]

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
  'setup:workers': {
    request: SetupWorkersRequest
    response: SetupWorkerOption[]
  }
  'sync:status': {
    request: void
    response: SyncStatusResponse
  }
  'save-pending-transaction-v2': {
    request: PendingTransactionInputV2
    response: number // SQLite rowid (SPEND-RETID, PR #1301)
  }
  'save-pending-conversion-v2': {
    request: PendingConversionInputV2
    response: number
  }
  'save-pending-transfer': {
    request: SavePendingTransferArgs // pozicionális tuple — lásd D2
    response: number
  }
  'sync-offline': {
    request: void
    response: number // syncAll().synced — NEM a teljes SyncResult
  }
  'save-pending-storno': {
    request: PendingStornoInput
    response: number
  }
  'save-pending-transfer-storno': {
    request: PendingTransferStornoInput
    response: number
  }
  'save-pending-circular-reply': {
    request: PendingCircularReplyInput
    response: number
  }
  'save-pending-handover-operation': {
    request: PendingHandoverOperationInput
    response: number
  }
  'queue-shipment-receipt': {
    request: PendingShipmentReceiptInput
    response: number
  }
  'get-pending-shipment-receipts': {
    request: void
    response: PendingShipmentReceiptRow[]
  }
  'queue-stocktake-count': {
    request: QueueStocktakeCountArgs
    response: number
  }
  'queue-scanned-document': {
    request: QueueScannedDocumentInput
    response: number
  }
  // ---- Read/util channelek (X4-minta folytatás, X4-REMAINDER-READ) ----
  // Pozicionális wire: a request a NYERS invoke-argumentum, nem objektum.
  'get-pending-transaction-ref-by-id': {
    request: number // pending tx rowid
    response: string | null // nyugta-bizonylatszám (SPEND-RETID, PR #1301)
  }
  'get-pending-transfer-ref-by-id': {
    request: number // pending transfer rowid
    response: string | null
  }
  'get-pending-transaction-count': {
    request: void
    response: number
  }
}

// Type helper: kihuzza egy channel request/response tipusat
export type IpcRequest<K extends keyof IpcRoutes> = IpcRoutes[K]['request']
export type IpcResponse<K extends keyof IpcRoutes> = IpcRoutes[K]['response']

// Runtime channel nevek konstans-kent - mindhárom process ebbol importál
export const IPC_CHANNELS = {
  SETUP_SAVE: 'setup:save' as const,
  SETUP_TEST_CONNECTION: 'setup:test-connection' as const,
  SETUP_WORKERS: 'setup:workers' as const,
  SYNC_STATUS: 'sync:status' as const,
  SAVE_PENDING_TRANSACTION_V2: 'save-pending-transaction-v2' as const,
  SAVE_PENDING_CONVERSION_V2: 'save-pending-conversion-v2' as const,
  SAVE_PENDING_TRANSFER: 'save-pending-transfer' as const,
  SYNC_OFFLINE: 'sync-offline' as const,
  SAVE_PENDING_STORNO: 'save-pending-storno' as const,
  SAVE_PENDING_TRANSFER_STORNO: 'save-pending-transfer-storno' as const,
  SAVE_PENDING_CIRCULAR_REPLY: 'save-pending-circular-reply' as const,
  SAVE_PENDING_HANDOVER_OPERATION: 'save-pending-handover-operation' as const,
  QUEUE_SHIPMENT_RECEIPT: 'queue-shipment-receipt' as const,
  GET_PENDING_SHIPMENT_RECEIPTS: 'get-pending-shipment-receipts' as const,
  QUEUE_STOCKTAKE_COUNT: 'queue-stocktake-count' as const,
  QUEUE_SCANNED_DOCUMENT: 'queue-scanned-document' as const,
  GET_PENDING_TRANSACTION_REF_BY_ID: 'get-pending-transaction-ref-by-id' as const,
  GET_PENDING_TRANSFER_REF_BY_ID: 'get-pending-transfer-ref-by-id' as const,
  GET_PENDING_TRANSACTION_COUNT: 'get-pending-transaction-count' as const,
} satisfies Record<string, keyof IpcRoutes>
