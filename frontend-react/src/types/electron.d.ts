import type {
  PendingHandoverOperationInput,
  PendingConversionInputV2,
  PendingShipmentReceiptInput,
  PendingShipmentReceiptRow,
  PendingStornoInput,
  PendingTransactionInputV2,
  PendingTransferStornoInput,
  QueueScannedDocumentInput,
  SavePendingTransferArgs,
} from '@valuta/shared-ipc'

export interface ElectronAPI {
  // --- Google OAuth Desktop Flow (Authorization Code + loopback, RFC 8252) ---
  googleOAuthFlow(): Promise<
    { ok: true; idToken: string; email?: string } | { ok: false; code: string; message: string }
  >

  // --- v2.5.20: Google OAuth + backend `/auth/google-login` POST EGY main-process hivasban ---
  // FK-ÉRTÉKTÁR (V285): supportsVaultWorkerSelection flag + idToken visszaadása a 2. fázishoz.
  googleOAuthFlowWithBackend(
    appMode?: string,
    supportsVaultWorkerSelection?: boolean,
  ): Promise<
    | {
        ok: true
        response: unknown
        email?: string
        idToken?: string
      }
    | { ok: false; code: string; message: string }
  >

  // --- v2.5.21: jelszavas /auth/login is main-process net.request-tel (ESET-tolerans) ---
  passwordLogin(data: {
    companyCode: string
    workerCode: string
    password: string
    appMode?: string
  }): Promise<{ ok: true; response: unknown } | { ok: false; code: string; message: string }>

  // --- v2.5.25: Altalanos API proxy (MINDEN renderer HTTP hivas main process-en at) ---
  apiRequest(params: {
    method: string
    url: string
    body?: string | null
    headers?: Record<string, string>
    timeoutMs?: number
  }): Promise<{
    ok: boolean
    status: number
    statusText: string
    headers: Record<string, string>
    body: string
    isBase64?: boolean
  }>

  // --- v2.5.13 Kliens hibajelentes (send-and-forget) ---
  reportError(payload: {
    component?: string
    message: string
    stack?: string
    context?: Record<string, unknown>
  }): Promise<{ ok: boolean }>
  setDiagnosticUserIdentifier(id: string | null): Promise<{ ok: boolean }>

  // --- Config (token persist) ---
  getConfig(key: string): Promise<string | null>
  setConfig(key: string, value: string): Promise<void>
  deleteConfig(key: string): Promise<void>

  // --- Nyomtatás ---
  printReceipt(data: string): Promise<boolean>
  getPrinters(): Promise<
    Array<{
      name: string
      displayName: string
      description: string
      status: number
      isDefault: boolean
    }>
  >
  listSerialPorts(): Promise<Array<{ path: string; manufacturer?: string; friendlyName?: string }>>

  // --- Offline tranzakciók ---
  savePendingTransaction(
    type: 'SELL' | 'BUY',
    currencyCode: string,
    foreignAmount: number,
    hufAmount: number,
    roundedHufAmount: number,
    rate: number,
    handlingFee: number | null,
    discountPercent: number | null,
    customerIdentifier: string | null,
    customerName: string | null,
    customerDocumentNumber: string | null,
    customerAddress: string | null,
    denominations: string | null,
    sourceOfFunds?: string | null,
    customerIsPep?: boolean | null,
    foreignStatus?: 'DOMESTIC' | 'FOREIGN' | null,
  ): Promise<number>

  // V235 (2026-05-19 HIBA #14 + #15 + #17 + #18): bővített API teljes
  // Pmt. customer-snapshot-tal (szül.hely/idő, anyja neve, állampolgárság,
  // PEP minőség, "más nevében" flag + actor teljes azonosítása).
  savePendingTransactionV2?: (input: PendingTransactionInputV2) => Promise<number>
  savePendingConversion(
    fromCurrencyId: number | null,
    fromCurrencyCode: string,
    toCurrencyId: number | null,
    toCurrencyCode: string,
    fromAmount: number,
    calculatedHufAmount: number,
    calculatedToAmount: number,
    conversionRate: number,
    handlingFee: number | null,
    customerId: string | null,
    customerName: string | null,
    customerDocumentNumber: string | null,
    note: string | null,
  ): Promise<number>

  // V235 + V236 (2026-05-19 Codex P1 #695): bővített Konverzio API teljes
  // Pmt. customer-snapshot-tal.
  savePendingConversionV2?: (input: PendingConversionInputV2) => Promise<number>
  savePendingBankTransaction(
    transactionType: 'BUY' | 'SELL',
    currencyCode: string,
    amount: number,
    exchangeRate: number,
    hufAmount: number,
    vaultTerritoryId: number | null,
    bankName: string | null,
    bankReference: string | null,
    note: string | null,
  ): Promise<number>
  savePendingStorno(payload: PendingStornoInput): Promise<number>
  getPendingTransactions(): Promise<
    Array<{
      id: number
      type: string
      currency_code: string
      foreign_amount: number
      huf_amount: number
      rounded_huf_amount: number
      rate: number
      handling_fee: number | null
      discount_percent: number | null
      customer_id: string | number | null
      customer_identifier: string | null
      customer_name: string | null
      customer_document_number: string | null
      customer_address: string | null
      denominations: string | null
      // Multi-line aggregált vétel/eladás sorai JSON-ként (backend TransactionLineRequestDto alak);
      // NULL → egysoros. A vázlat-böngésző ebből rekonstruálja a multi-line nyugtát (localQueue).
      lines: string | null
      local_reference_number: string | null
      idempotency_key: string | null
      created_at: string
      synced: number
      // FK-SYNC (2026-06-02): a tartós sync-hiba állapot (miért nem ment fel a tétel).
      sync_error?: string | null
      sync_attempts?: number | null
      last_attempt_at?: string | null
    }>
  >
  // 2026-06-04 (audit-fix): a TÉNYLEGES szigorú helyi sorszám (local_reference_number)
  // lekérdezése a mentett pending vétel/eladás sor ID-je alapján — a nyugta a valós
  // bizonylatszámot kapja, nem fabrikált P-<timestamp>-et. Opcionális: régi telepítő
  // (preload) még nem ismeri → a renderer fallback-el a fabrikált számra.
  getPendingTransactionRefById?: (id: number) => Promise<string | null>
  // 2026-06-04 (audit-fix, buy/sell-paritás): a TÉNYLEGES átadólap-sorszám (local_reference_number,
  // pl. AT105000042) lekérdezése a mentett transfer pending-sor ID-je alapján — a szállítólevél a
  // valós (rögzített) számot kapja, nem fabrikált LOCAL-<dátum>-#<id>-t. Opcionális: régi telepítő
  // (preload) még nem ismeri → a renderer fallback-el a fabrikált számra.
  getPendingTransferRefById?: (id: number) => Promise<string | null>
  getPendingConversions(): Promise<
    Array<{
      id: number
      from_currency_id: number | null
      from_currency_code: string
      to_currency_id: number | null
      to_currency_code: string
      from_amount: number
      calculated_huf_amount: number
      calculated_to_amount: number
      conversion_rate: number
      handling_fee: number | null
      customer_id: string | null
      customer_name: string | null
      customer_document_number: string | null
      note: string | null
      local_reference_number: string | null
      idempotency_key: string | null
      created_at: string
      synced: number
    }>
  >
  getPendingBankTransactions(): Promise<
    Array<{
      id: number
      transaction_type: 'BUY' | 'SELL'
      currency_code: string
      amount: number
      exchange_rate: number
      huf_amount: number
      vault_territory_id: number | null
      bank_name: string | null
      bank_reference: string | null
      note: string | null
      local_reference_number: string | null
      idempotency_key: string | null
      created_at: string
      synced: number
    }>
  >
  getPendingStornos(): Promise<
    Array<{
      id: number
      transaction_id: number
      original_receipt_number: string
      original_transaction_type: string
      currency_code: string
      foreign_amount: number | null
      huf_amount: number
      exchange_rate: number | null
      reason: string
      approval_id: string | null
      custom_exchange_rate: number | null
      payment_method: string | null
      customer_name: string | null
      customer_document_number: string | null
      local_reference_number: string | null
      idempotency_key: string | null
      created_at: string
      synced: number
    }>
  >
  // Fizikai ujranyomtatas (Codex P2 #1035): mar szinkronizalt (synced = 1) bizonylatok a lokalis
  // receiptData-bol valo ESC/POS ujranyomtatashoz (papirelakadas utan). Opcionalis: regi telepito
  // (preload) meg nem ismeri → a renderer ures listara esik vissza. A `lines` (multi-line) is jon.
  getReprintableTransactions?(limit?: number): Promise<
    Array<{
      id: number
      type: string
      currency_code: string
      foreign_amount: number
      huf_amount: number
      rounded_huf_amount: number
      rate: number
      handling_fee: number | null
      discount_percent: number | null
      customer_name: string | null
      customer_document_number: string | null
      lines: string | null
      local_reference_number: string | null
      created_at: string
      synced: number
    }>
  >
  getReprintableConversions?(limit?: number): Promise<
    Array<{
      id: number
      from_currency_code: string
      to_currency_code: string
      from_amount: number
      calculated_huf_amount: number
      calculated_to_amount: number
      conversion_rate: number
      customer_name: string | null
      customer_document_number: string | null
      note: string | null
      local_reference_number: string | null
      created_at: string
      synced: number
    }>
  >
  getReprintableStornos?(limit?: number): Promise<
    Array<{
      id: number
      original_receipt_number: string
      currency_code: string
      foreign_amount: number | null
      huf_amount: number
      exchange_rate: number | null
      custom_exchange_rate: number | null
      reason: string
      customer_name: string | null
      customer_document_number: string | null
      local_reference_number: string | null
      created_at: string
      synced: number
    }>
  >
  getPendingTransactionCount(): Promise<number>
  syncOffline(): Promise<number>
  /** FK-071 FR-3: egy pending tranzakció célzott, azonnali újraküldése (lokális SQLite id-val). */
  retryPendingTransaction(id: number): Promise<{ success: boolean; error?: string | null }>
  /** FKH-032 FR-2: célzott azonnali könyvelési kísérlet EGY frissen mentett tételre. */
  syncSingleTransactionImmediate?(id: number): Promise<{ success: boolean; error?: string | null }>
  getSyncStatus(): Promise<string>

  /** 2026-04-29 v2.3.11 (E-B6.2): renderer hívja, amikor az ablak inaktívvá válik */
  syncEnginePause(): Promise<void>
  /** 2026-04-29 v2.3.11 (E-B6.2): renderer hívja, amikor az ablak újra aktív */
  syncEngineResume(): Promise<void>

  // --- Értéktár offline ---
  savePendingDistribution(
    targetBranchCode: string,
    currencyCode: string,
    amount: number,
    denominations: string | null,
    note: string | null,
  ): Promise<number>
  savePendingTransfer(...args: SavePendingTransferArgs): Promise<number>
  getPendingTransfers(): Promise<
    Array<{
      id: number
      target_branch_id: string | null
      target_branch_code: string
      currency_id: number | null
      currency_code: string
      amount: number
      huf_value: number | null
      transfer_type: string | null
      denominations: string | null
      note: string | null
      local_reference_number: string | null
      idempotency_key: string | null
      created_at: string
      synced: number
      /** Penztar-batch A.1: a több-valutás sorok JSON-ja (a SQLite `lines TEXT` oszlop — SELECT * adja). */
      lines?: string | null
      /** Verif PR #1101: az irány ('F' átadás / 'U' átvétel) — a bizonylat-orientációhoz (SELECT * adja). */
      direction?: string | null
      /** Batch2-E: szállító + plombaszám az offline bizonylat-előnézethez (SELECT * adja). */
      carrier_name?: string | null
      seal_number?: string | null
    }>
  >
  /** Offline átadás-átvétel SZTORNÓ (internetkimaradáskor): a backend fordítja vissza a készletet szinkronkor. */
  savePendingTransferStorno(payload: PendingTransferStornoInput): Promise<number>
  /** FKH-018: Shipment átvételi szándék tartós offline outboxba írása. */
  queueShipmentReceipt(payload: PendingShipmentReceiptInput): Promise<number>
  getPendingShipmentReceipts(): Promise<PendingShipmentReceiptRow[]>
  /** FS-C: körlevél-válasz offline rögzítése — a sync-engine küldi fel. */
  savePendingCircularReply?(payload: { circularId: number; replyText: string }): Promise<number>
  getPendingTransferStornos(): Promise<
    Array<{
      id: number
      transfer_id: number
      transfer_number: string | null
      reason: string
      local_reference_number: string | null
      idempotency_key: string | null
      created_at: string
      synced: number
    }>
  >
  savePendingCollection(
    sourceBranchCode: string,
    currencyCode: string,
    amount: number,
    note: string | null,
  ): Promise<number>
  savePendingHandoverOperation(payload: PendingHandoverOperationInput): Promise<number>
  getPendingHandoverOperations(): Promise<
    Array<{
      id: number
      operation_type: 'GENERATE' | 'PRINT' | 'COMPLETE'
      sheet_id: string | null
      from_cash_desk_id: string | null
      to_cash_desk_id: string | null
      transfer_date: string | null
      amounts_json: string | null
      note: string | null
      local_reference_number: string | null
      idempotency_key: string | null
      created_at: string
      synced: number
    }>
  >
  getCachedBranchStatuses(): Promise<
    Array<{
      branch_code: string
      branch_name: string
      company_id: number | null
      last_sync_at: string | null
      online_status: string
      total_huf_value: number
      daily_turnover: number
      cash_balances: string | null
      cached_at: string
    }>
  >
  getCachedBranchStatusTimestamp(): Promise<string | null>
  getCachedRates(): Promise<
    Array<{
      currency_code: string
      buy_rate: number
      sell_rate: number
      unit: number
      updated_at: string
      // FK-SÁVOS (2026-06-02): a sávos árfolyam-mezők (a SQLite cached_rates SELECT * visszaadja).
      official_rate?: number | null
      limit1_amount?: number | null
      limit1_buy_rate?: number | null
      limit1_sell_rate?: number | null
      limit2_amount?: number | null
      limit2_buy_rate?: number | null
      limit2_sell_rate?: number | null
      limit3_amount?: number | null
      limit3_buy_rate?: number | null
      limit3_sell_rate?: number | null
    }>
  >
  // FK-097 WU-14 (FR-3): iroda-szintű kezelési díj konfiguráció offline cache (preload bridge).
  getCachedHandlingFeeConfig(): Promise<{
    branch_id: string
    branch_code: string | null
    company_id: string | null
    fee_mode: 'NONE' | 'BRACKET' | 'PER_MILLE'
    per_mille_rate: number | null
    per_mille_cap: number | null
    bracket_json: string | null
    valid_from: string | null
    synced_at: string
  } | null>
  getCachedCashDesks(): Promise<
    Array<{
      id: string
      code: string
      name: string
      company_id: string | null
      city: string | null
      /** Fejléc-javítás 2026-06-11 (NFR-1 offline): utca/házszám — régi mirror-ban hiányozhat. */
      address?: string | null
      /** Fejléc-javítás 2026-06-11 (NFR-1 offline): irányítószám — régi mirror-ban hiányozhat. */
      zip_code?: string | null
      /** Fejléc-javítás 2026-06-11 (NFR-1 offline): telefonszám — régi mirror-ban hiányozhat. */
      phone?: string | null
      /** Bizonylat-doc 2. kör TBD-5 (2026-06-12): region_code az "[azonosító]. [név]" formátumhoz — régi mirror-ban hiányozhat. */
      region_code?: string | null
      is_active: number
      cached_at: string
    }>
  >
  getCachedCashDeskTimestamp(): Promise<string | null>
  getCachedWorkers(): Promise<
    Array<{
      id: number
      worker_code: string | null
      full_name: string
      role: string | null
      branch_id: string | null
      branch_code: string | null
      branch_name: string | null
      company_id: string | null
      company_code: string | null
      active: number
      cached_at: string
    }>
  >
  getCachedWorkerTimestamp(): Promise<string | null>
  saveLocalAuditEvent(payload: {
    entityType: string
    eventType: string
    referenceNumber?: string | null
    entityId?: string | null
    payload: unknown
    customerSnapshot?: unknown
    identificationSnapshot?: unknown
    rateSnapshot?: unknown
    status?: string
    retentionDays?: number
  }): Promise<number>
  getLocalAuditEvents(limit?: number): Promise<
    Array<{
      id: number
      entity_type: string
      event_type: string
      reference_number: string | null
      entity_id: string | null
      payload_json: string
      customer_snapshot_json: string | null
      identification_snapshot_json: string | null
      rate_snapshot_json: string | null
      status: string
      retention_until: string
      created_at: string
    }>
  >

  // --- Kamera (lokális Electron rögzítés + keresés) ---
  cameraSaveRecording(transactionId: string, buffer: ArrayBuffer, ext: string): Promise<string>
  cameraExportToUsb(
    dateFrom: string,
    dateTo: string,
  ): Promise<{ success: boolean; exported: number; error?: string }>
  cameraListRecordings(transactionId?: string): Promise<string[]>
  cameraLocalStorageStats?(): Promise<{
    totalUsageBytes: number
    availableSpaceBytes: number
    totalRecordings: number
    oldestDate: string | null
    newestDate: string | null
  }>
  cameraLocalRecordingsByDate?(
    dateFrom: string,
    dateTo: string,
  ): Promise<
    Array<{
      date: string
      transactionId: string
      filePath: string
      fileSizeBytes: number
      createdAt: string
    }>
  >
  cameraLocalReadFile?(filePath: string): Promise<string | null>
  cameraLocalCleanup?(retentionDays: number): Promise<{ deletedCount: number }>

  // --- Okmány szkenner ---
  scanSaveDocument(
    transactionId: string,
    documentType: 'szemelyi' | 'utlevel' | 'jogositvany' | 'egyeb',
    imageBase64: string,
    side?: 'front' | 'back',
  ): Promise<{ path: string; encrypted: boolean }>
  scanGetDocument(filepath: string): Promise<string>
  scanListDocuments(transactionId: string): Promise<string[]>
  // FS-5: okmány-képpár feltöltési outbox (scan → center, törlés nyugtázás után).
  queueScannedDocument(payload: QueueScannedDocumentInput): Promise<number>

  // --- Secure Token Storage (DPAPI/Keychain titkositott) ---
  secureStoreToken?(token: string): Promise<boolean>
  secureLoadToken?(): Promise<string | null>
  secureClearToken?(): Promise<void>

  // --- First-Run Setup Wizard ---
  setupCheck?(): Promise<{
    isFirstRun: boolean
    envPath: string
    reason?: string
  }>
  setupGetBranches?(params?: { apiUrl?: string; companyCode?: string }): Promise<
    Array<{
      code: string
      name: string
      city: string
      address?: string
      isVault?: boolean
    }>
  >
  setupGetWorkers?(params: { apiUrl: string; companyCode: string; branchCode: string }): Promise<
    Array<{
      code: string
      name: string
      region?: string
    }>
  >
  setupTestConnection?(params: {
    apiUrl: string
    companyCode: string
    username: string
    password: string
  }): Promise<{
    success: boolean
    httpStatus?: number
    errorMessage?: string
    latencyMs?: number
  }>
  setupSave?(payload: {
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
    appMode?: 'penztar' | 'ertektar' | 'full' | 'rate-maker'
    // v2.3.0: a telepito dolgozoi dropdown-bol kivalasztott worker identity.
    // Ha ez kitoltve -> /auth/first-time-worker-setup. Egyebkent bootstrap-admin.
    selectedWorkerCode?: string
    selectedWorkerName?: string
    selectedWorkerRole?: string
    googleEmail?: string
    googleSub?: string
    googleName?: string
    googlePicture?: string
  }): Promise<{
    success: boolean
    envPath: string
    errorMessage?: string
  }>

  // v2.3.0: (megjegyzes) getConfig / setConfig a tetejen, line 3-4 mar
  // kotelezo method-ok. A LoginPage hasznalja a worker_code pre-fill-hez.

  // --- App ---
  getAppVersion(): Promise<string>
  restartApp(): Promise<void>

  // --- VFD ügyfélkijelző (P2-1) ---
  customerDisplay?: {
    /** Megnyitja az ügyfélkijelző-ablakot (második monitor vagy alwaysOnTop overlay). */
    show(preferSecondMonitor: boolean): Promise<boolean>
    /** Tranzakció részleteinek átadása az ügyfélkijelzőnek. */
    update(payload: CustomerDisplayPayload): Promise<void>
    /** Bezárja az ügyfélkijelző ablakát. */
    hide(): Promise<void>
    /** Visszaadja, hogy nyitva van-e az ügyfélkijelző. */
    status(): Promise<boolean>
    /**
     * IPC listener — CSAK a customer-display renderer oldalán használandó!
     * Visszatér egy unsubscribe függvénnyel.
     */
    onUpdate(cb: (payload: CustomerDisplayPayload) => void): () => void
  }

  // --- Suite-frissítés (docs/auto-update-terv-es-vegrehajtas.md 3.6) ---
  // A pénztár a TELJES aláírt suite-telepítővel frissül (Electron + backend JAR +
  // JRE + PostgreSQL + NSSM service-ek), és a telepítés CSAK állapotvezérelt
  // ablakban indul: napnyitás ELŐTT vagy napzárás UTÁN. Nyitott műszak alatt a
  // main process csak jelez. Az állapotot a renderer jelenti, mert csak itt
  // tudható, van-e nyitott napi munkamenet.
  suiteUpdate?: {
    /** Jelenti a műszak-állapotot a main processnek (ez engedi/tiltja a telepítést). */
    setShiftState(
      state: 'IDLE_BEFORE_OPEN' | 'SHIFT_OPEN' | 'CLOSED_AFTER_DAY_END',
    ): Promise<{ accepted: boolean; shiftState: string }>
    /** Az updater aktuális állapota + a készen álló verzió (ha van). */
    status(): Promise<{
      state: string
      shiftState: string
      readyVersion: string | null
      mandatory: boolean
    }>
    /** Akkor tüzel, amikor egy ellenőrzött frissítés készen áll. Unsubscribe-ot ad vissza. */
    onReady(
      cb: (payload: {
        version: string
        mandatory: boolean
        notes: string | null
        installableNow: boolean
      }) => void,
    ): () => void
    /** Letöltési folyamat. Unsubscribe-ot ad vissza. */
    onProgress(cb: (payload: unknown) => void): () => void
  }

  // --- Platform ---
  platform: string
}

export interface CustomerDisplayPayload {
  transactionType?: 'BUY' | 'SELL' | 'CONVERSION' | 'STORNO'
  currencyCode?: string
  amount?: number
  hufAmount?: number
  rate?: number
  handlingFee?: number
  totalHuf?: number
  message?: string
}

declare global {
  interface Window {
    electronAPI?: ElectronAPI
  }
}
