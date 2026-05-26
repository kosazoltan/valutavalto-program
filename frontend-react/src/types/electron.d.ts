export interface ElectronAPI {
  // --- Google OAuth Desktop Flow (Authorization Code + loopback, RFC 8252) ---
  googleOAuthFlow(): Promise<
    | { ok: true; idToken: string; email?: string }
    | { ok: false; code: string; message: string }
  >;

  // --- v2.5.20: Google OAuth + backend `/auth/google-login` POST EGY main-process hivasban ---
  googleOAuthFlowWithBackend(appMode?: string): Promise<
    | {
        ok: true;
        response: unknown;
        email?: string;
      }
    | { ok: false; code: string; message: string }
  >;

  // --- v2.5.21: jelszavas /auth/login is main-process net.request-tel (ESET-tolerans) ---
  passwordLogin(data: {
    companyCode: string;
    workerCode: string;
    password: string;
    appMode?: string;
  }): Promise<
    | { ok: true; response: unknown }
    | { ok: false; code: string; message: string }
  >;

  // --- v2.5.25: Altalanos API proxy (MINDEN renderer HTTP hivas main process-en at) ---
  apiRequest(params: {
    method: string;
    url: string;
    body?: string | null;
    headers?: Record<string, string>;
    timeoutMs?: number;
  }): Promise<{
    ok: boolean;
    status: number;
    statusText: string;
    headers: Record<string, string>;
    body: string;
    isBase64?: boolean;
  }>;

  // --- v2.5.13 Kliens hibajelentes (send-and-forget) ---
  reportError(payload: {
    component?: string;
    message: string;
    stack?: string;
    context?: Record<string, unknown>;
  }): Promise<{ ok: boolean }>;
  setDiagnosticUserIdentifier(id: string | null): Promise<{ ok: boolean }>;

  // --- Config (token persist) ---
  getConfig(key: string): Promise<string | null>;
  setConfig(key: string, value: string): Promise<void>;
  deleteConfig(key: string): Promise<void>;

  // --- Nyomtatás ---
  printReceipt(data: string): Promise<boolean>;
  getPrinters(): Promise<Array<{
    name: string;
    displayName: string;
    description: string;
    status: number;
    isDefault: boolean;
  }>>;

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
  ): Promise<number>;

  // V235 (2026-05-19 HIBA #14 + #15 + #17 + #18): bővített API teljes
  // Pmt. customer-snapshot-tal (szül.hely/idő, anyja neve, állampolgárság,
  // PEP minőség, "más nevében" flag + actor teljes azonosítása).
  savePendingTransactionV2?: (input: {
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
    customerBirthPlace: string | null
    customerBirthDate: string | null
    customerMotherName: string | null
    customerNationality: string | null
    customerDocumentType: string | null
    sourceOfFunds: string | null
    customerIsPep: boolean | null
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
  }) => Promise<number>;
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
  ): Promise<number>;

  // V235 + V236 (2026-05-19 Codex P1 #695): bővített Konverzio API teljes
  // Pmt. customer-snapshot-tal.
  savePendingConversionV2?: (input: {
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
    foreignStatus: string | null
    note: string | null
  }) => Promise<number>;
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
  ): Promise<number>;
  savePendingStorno(payload: {
    transactionId: number;
    originalReceiptNumber: string;
    originalTransactionType: string;
    currencyCode: string;
    foreignAmount: number | null;
    hufAmount: number;
    exchangeRate: number | null;
    reason: string;
    approvalId?: string | null;
    customExchangeRate?: number | null;
    paymentMethod?: string | null;
    customerName?: string | null;
    customerDocumentNumber?: string | null;
  }): Promise<number>;
  getPendingTransactions(): Promise<Array<{
    id: number;
    type: string;
    currency_code: string;
    foreign_amount: number;
    huf_amount: number;
    rounded_huf_amount: number;
    rate: number;
    handling_fee: number | null;
    discount_percent: number | null;
    customer_id: string | number | null;
    customer_identifier: string | null;
    customer_name: string | null;
    customer_document_number: string | null;
    customer_address: string | null;
    denominations: string | null;
    local_reference_number: string | null;
    idempotency_key: string | null;
    created_at: string;
    synced: number;
  }>>;
  getPendingConversions(): Promise<Array<{
    id: number;
    from_currency_id: number | null;
    from_currency_code: string;
    to_currency_id: number | null;
    to_currency_code: string;
    from_amount: number;
    calculated_huf_amount: number;
    calculated_to_amount: number;
    conversion_rate: number;
    handling_fee: number | null;
    customer_id: string | null;
    customer_name: string | null;
    customer_document_number: string | null;
    note: string | null;
    local_reference_number: string | null;
    idempotency_key: string | null;
    created_at: string;
    synced: number;
  }>>;
  getPendingBankTransactions(): Promise<Array<{
    id: number;
    transaction_type: 'BUY' | 'SELL';
    currency_code: string;
    amount: number;
    exchange_rate: number;
    huf_amount: number;
    vault_territory_id: number | null;
    bank_name: string | null;
    bank_reference: string | null;
    note: string | null;
    local_reference_number: string | null;
    idempotency_key: string | null;
    created_at: string;
    synced: number;
  }>>;
  getPendingStornos(): Promise<Array<{
    id: number;
    transaction_id: number;
    original_receipt_number: string;
    original_transaction_type: string;
    currency_code: string;
    foreign_amount: number | null;
    huf_amount: number;
    exchange_rate: number | null;
    reason: string;
    approval_id: string | null;
    custom_exchange_rate: number | null;
    payment_method: string | null;
    customer_name: string | null;
    customer_document_number: string | null;
    local_reference_number: string | null;
    idempotency_key: string | null;
    created_at: string;
    synced: number;
  }>>;
  getPendingTransactionCount(): Promise<number>;
  syncOffline(): Promise<number>;
  getSyncStatus(): Promise<string>;

  /** 2026-04-29 v2.3.11 (E-B6.2): renderer hívja, amikor az ablak inaktívvá válik */
  syncEnginePause(): Promise<void>;
  /** 2026-04-29 v2.3.11 (E-B6.2): renderer hívja, amikor az ablak újra aktív */
  syncEngineResume(): Promise<void>;

  // --- Értéktár offline ---
  savePendingDistribution(
    targetBranchCode: string,
    currencyCode: string,
    amount: number,
    denominations: string | null,
    note: string | null,
  ): Promise<number>;
  savePendingTransfer(
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
  ): Promise<number>;
  getPendingTransfers(): Promise<Array<{
    id: number;
    target_branch_id: string | null;
    target_branch_code: string;
    currency_id: number | null;
    currency_code: string;
    amount: number;
    huf_value: number | null;
    transfer_type: string | null;
    denominations: string | null;
    note: string | null;
    local_reference_number: string | null;
    idempotency_key: string | null;
    created_at: string;
    synced: number;
  }>>;
  savePendingCollection(
    sourceBranchCode: string,
    currencyCode: string,
    amount: number,
    note: string | null,
  ): Promise<number>;
  savePendingHandoverOperation(payload: {
    operationType: 'GENERATE' | 'PRINT' | 'COMPLETE';
    sheetId?: string | null;
    fromCashDeskId?: string | null;
    toCashDeskId?: string | null;
    transferDate?: string | null;
    amounts?: unknown;
    note?: string | null;
  }): Promise<number>;
  getPendingHandoverOperations(): Promise<Array<{
    id: number;
    operation_type: 'GENERATE' | 'PRINT' | 'COMPLETE';
    sheet_id: string | null;
    from_cash_desk_id: string | null;
    to_cash_desk_id: string | null;
    transfer_date: string | null;
    amounts_json: string | null;
    note: string | null;
    local_reference_number: string | null;
    idempotency_key: string | null;
    created_at: string;
    synced: number;
  }>>;
  getCachedBranchStatuses(): Promise<Array<{
    branch_code: string;
    branch_name: string;
    company_id: number | null;
    last_sync_at: string | null;
    online_status: string;
    total_huf_value: number;
    daily_turnover: number;
    cash_balances: string | null;
    cached_at: string;
  }>>;
  getCachedBranchStatusTimestamp(): Promise<string | null>;
  getCachedRates(): Promise<Array<{
    currency_code: string;
    buy_rate: number;
    sell_rate: number;
    unit: number;
    updated_at: string;
  }>>;
  getCachedCashDesks(): Promise<Array<{
    id: string;
    code: string;
    name: string;
    company_id: string | null;
    city: string | null;
    is_active: number;
    cached_at: string;
  }>>;
  getCachedCashDeskTimestamp(): Promise<string | null>;
  getCachedWorkers(): Promise<Array<{
    id: number;
    worker_code: string | null;
    full_name: string;
    role: string | null;
    branch_id: string | null;
    branch_code: string | null;
    branch_name: string | null;
    company_id: string | null;
    company_code: string | null;
    active: number;
    cached_at: string;
  }>>;
  getCachedWorkerTimestamp(): Promise<string | null>;
  saveLocalAuditEvent(payload: {
    entityType: string;
    eventType: string;
    referenceNumber?: string | null;
    entityId?: string | null;
    payload: unknown;
    customerSnapshot?: unknown;
    identificationSnapshot?: unknown;
    rateSnapshot?: unknown;
    status?: string;
    retentionDays?: number;
  }): Promise<number>;
  getLocalAuditEvents(limit?: number): Promise<Array<{
    id: number;
    entity_type: string;
    event_type: string;
    reference_number: string | null;
    entity_id: string | null;
    payload_json: string;
    customer_snapshot_json: string | null;
    identification_snapshot_json: string | null;
    rate_snapshot_json: string | null;
    status: string;
    retention_until: string;
    created_at: string;
  }>>;

  // --- Kamera (lokális Electron rögzítés + keresés) ---
  cameraSaveRecording(transactionId: string, buffer: ArrayBuffer, ext: string): Promise<string>;
  cameraExportToUsb(dateFrom: string, dateTo: string): Promise<{ success: boolean; exported: number; error?: string }>;
  cameraListRecordings(transactionId?: string): Promise<string[]>;
  cameraLocalStorageStats?(): Promise<{
    totalUsageBytes: number;
    availableSpaceBytes: number;
    totalRecordings: number;
    oldestDate: string | null;
    newestDate: string | null;
  }>;
  cameraLocalRecordingsByDate?(dateFrom: string, dateTo: string): Promise<Array<{
    date: string;
    transactionId: string;
    filePath: string;
    fileSizeBytes: number;
    createdAt: string;
  }>>;
  cameraLocalReadFile?(filePath: string): Promise<string | null>;
  cameraLocalCleanup?(retentionDays: number): Promise<{ deletedCount: number }>;

  // --- Okmány szkenner ---
  scanSaveDocument(
    transactionId: string,
    documentType: 'szemelyi' | 'utlevel' | 'jogositvany' | 'egyeb',
    imageBase64: string,
  ): Promise<{ path: string; encrypted: boolean }>;
  scanGetDocument(filepath: string): Promise<string>;
  scanListDocuments(transactionId: string): Promise<string[]>;

  // --- Secure Token Storage (DPAPI/Keychain titkositott) ---
  secureStoreToken?(token: string): Promise<boolean>;
  secureLoadToken?(): Promise<string | null>;
  secureClearToken?(): Promise<void>;

  // --- First-Run Setup Wizard ---
  setupCheck?(): Promise<{
    isFirstRun: boolean;
    envPath: string;
    reason?: string;
  }>;
  setupGetBranches?(params?: { apiUrl?: string; companyCode?: string }): Promise<Array<{
    code: string;
    name: string;
    city: string;
    address?: string;
    isVault?: boolean;
  }>>;
  setupGetWorkers?(params: {
    apiUrl: string;
    companyCode: string;
    branchCode: string;
  }): Promise<Array<{
    code: string;
    name: string;
    region?: string;
  }>>;
  setupTestConnection?(params: {
    apiUrl: string;
    companyCode: string;
    username: string;
    password: string;
  }): Promise<{
    success: boolean;
    httpStatus?: number;
    errorMessage?: string;
    latencyMs?: number;
  }>;
  setupSave?(payload: {
    branchCode: string;
    branchName: string;
    apiUrl: string;
    companyCode: string;
    authMode?: "password" | "google";
    adminUsername?: string;
    adminPassword?: string;
    bootstrapUsername?: string;
    bootstrapPassword?: string;
    offlineMode: boolean;
    appMode?: "penztar" | "ertektar" | "ertekszallito" | "full" | "rate-maker";
    // v2.3.0: a telepito dolgozoi dropdown-bol kivalasztott worker identity.
    // Ha ez kitoltve -> /auth/first-time-worker-setup. Egyebkent bootstrap-admin.
    selectedWorkerCode?: string;
    selectedWorkerName?: string;
    selectedWorkerRole?: string;
    googleEmail?: string;
    googleSub?: string;
    googleName?: string;
    googlePicture?: string;
  }): Promise<{
    success: boolean;
    envPath: string;
    errorMessage?: string;
  }>;

  // v2.3.0: (megjegyzes) getConfig / setConfig a tetejen, line 3-4 mar
  // kotelezo method-ok. A LoginPage hasznalja a worker_code pre-fill-hez.

  // --- App ---
  getAppVersion(): Promise<string>;
  restartApp(): Promise<void>;

  // --- VFD ügyfélkijelző (P2-1) ---
  customerDisplay?: {
    /** Megnyitja az ügyfélkijelző-ablakot (második monitor vagy alwaysOnTop overlay). */
    show(preferSecondMonitor: boolean): Promise<boolean>;
    /** Tranzakció részleteinek átadása az ügyfélkijelzőnek. */
    update(payload: CustomerDisplayPayload): Promise<void>;
    /** Bezárja az ügyfélkijelző ablakát. */
    hide(): Promise<void>;
    /** Visszaadja, hogy nyitva van-e az ügyfélkijelző. */
    status(): Promise<boolean>;
    /**
     * IPC listener — CSAK a customer-display renderer oldalán használandó!
     * Visszatér egy unsubscribe függvénnyel.
     */
    onUpdate(cb: (payload: CustomerDisplayPayload) => void): () => void;
  };

  // --- Platform ---
  platform: string;
}

export interface CustomerDisplayPayload {
  transactionType?: 'BUY' | 'SELL' | 'CONVERSION' | 'STORNO';
  currencyCode?: string;
  amount?: number;
  hufAmount?: number;
  rate?: number;
  handlingFee?: number;
  totalHuf?: number;
  message?: string;
}

declare global {
  interface Window {
    electronAPI?: ElectronAPI;
  }
}
