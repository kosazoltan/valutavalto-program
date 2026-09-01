import { contextBridge, ipcRenderer } from 'electron';
import { IPC_CHANNELS, type IpcRequest, type IpcResponse } from '@valuta/shared-ipc';

contextBridge.exposeInMainWorld('electronAPI', {
  /**
   * Google OAuth Authorization Code Flow + loopback redirect (RFC 8252).
   */
  googleOAuthFlow: (): Promise<
    { ok: true; idToken: string; email?: string } | { ok: false; code: string; message: string }
  > => ipcRenderer.invoke('auth:google-oauth-flow'),

  /**
   * v2.5.20 Borsi-fix: Google OAuth flow + backend `/auth/google-login` POST EGY main-process hivasban.
   * Megbizhatobb mint a renderer axios.post (electron.net.request, Windows cert store, Chromium switches).
   * Plusz: 3-szor probalja a backend POST-ot (1s, 3s, 5s wait) ha network-level error.
   */
  googleOAuthFlowWithBackend: (
    appMode?: string,
    supportsVaultWorkerSelection?: boolean,
  ): Promise<
    | { ok: true; response: unknown; email?: string; idToken?: string }
    | { ok: false; code: string; message: string }
  > =>
    ipcRenderer.invoke('auth:google-oauth-flow-with-backend', {
      appMode,
      supportsVaultWorkerSelection,
    }),

  /**
   * v2.5.21 ALTALANOS BEJELENTKEZESI FIX: a sima jelszavas /auth/login POST is main process-en
   * (electron.net.request) megy, NEM renderer axios.post. ESET MITM TLS-handshake nehany
   * kliensen leejti a POST connection-t (Borsi laptop, Fabuja Zsuzsa) — a main-process
   * Windows cert store + Chromium switches stack megbizhatobb. 3x retry (1s, 3s, 5s).
   */
  passwordLogin: (data: {
    companyCode: string;
    workerCode: string;
    password: string;
    appMode?: string;
  }): Promise<{ ok: true; response: unknown } | { ok: false; code: string; message: string }> =>
    ipcRenderer.invoke('auth:password-login', data),

  /**
   * v2.5.25 ALTALANOS API PROXY: minden renderer HTTP hivas a main process electron.net.request-en
   * megy at. ESET/Kaspersky/Bitdefender MITM TLS proxy-k altal okozott "Network Error" vegleges fix.
   */
  apiRequest: (params: {
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
  }> => ipcRenderer.invoke('api:fetch', params),

  /**
   * v2.5.13 KLIENS-OLDALI HIBAJELENTES (window.onerror + axios interceptor a renderer-ben).
   * Send-and-forget — soha nem dob, a Penztar futasat nem akadályozza.
   */
  reportError: (payload: {
    component?: string;
    message: string;
    stack?: string;
    context?: Record<string, unknown>;
  }): Promise<{ ok: boolean }> => ipcRenderer.invoke('diagnostics:report-error', payload),

  /**
   * v2.5.13 — A Login flow utan a renderer atadja a felhasznalo email-jet,
   * hogy a hibajelentesekben szerepeljen ki kuldte (audit + targetalt fix).
   */
  setDiagnosticUserIdentifier: (id: string | null): Promise<{ ok: boolean }> =>
    ipcRenderer.invoke('diagnostics:set-user-identifier', id),

  printReceipt: (data: string): Promise<boolean> => ipcRenderer.invoke('print-receipt', data),

  listSerialPorts: (): Promise<
    Array<{ path: string; manufacturer?: string; friendlyName?: string }>
  > => ipcRenderer.invoke('list-serial-ports'),

  openCashDrawer: (): Promise<boolean> => ipcRenderer.invoke('open-cash-drawer'),

  getConfig: (key: string): Promise<string | null> => ipcRenderer.invoke('get-config', key),

  setConfig: (key: string, value: string): Promise<void> =>
    ipcRenderer.invoke('set-config', key, value),

  deleteConfig: (key: string): Promise<void> => ipcRenderer.invoke('delete-config', key),

  savePendingTransaction: (
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
    sourceOfFunds: string | null = null,
    customerIsPep: boolean | null = null,
    foreignStatus: 'DOMESTIC' | 'FOREIGN' | null = null,
  ): Promise<number> =>
    ipcRenderer.invoke(
      'save-pending-transaction',
      type,
      currencyCode,
      foreignAmount,
      hufAmount,
      roundedHufAmount,
      rate,
      handlingFee,
      discountPercent,
      customerIdentifier,
      customerName,
      customerDocumentNumber,
      customerAddress,
      denominations,
      sourceOfFunds,
      customerIsPep,
      foreignStatus,
    ),

  // V235 (2026-05-19 HIBA #14 + #15 + #17 + #18): bővített API objektum-
  // paraméterrel a teljes Pmt. customer-snapshot mentéséhez.
  savePendingTransactionV2: (
    input: IpcRequest<'save-pending-transaction-v2'>,
  ): Promise<IpcResponse<'save-pending-transaction-v2'>> =>
    ipcRenderer.invoke('save-pending-transaction-v2', input),

  savePendingConversion: (
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
  ): Promise<number> =>
    ipcRenderer.invoke(
      'save-pending-conversion',
      fromCurrencyId,
      fromCurrencyCode,
      toCurrencyId,
      toCurrencyCode,
      fromAmount,
      calculatedHufAmount,
      calculatedToAmount,
      conversionRate,
      handlingFee,
      customerId,
      customerName,
      customerDocumentNumber,
      note,
    ),

  // V235 + V236 (2026-05-19 Codex P1 #695): bővített Konverzio API teljes
  // Pmt. customer-snapshot-tal.
  savePendingConversionV2: (
    input: IpcRequest<'save-pending-conversion-v2'>,
  ): Promise<IpcResponse<'save-pending-conversion-v2'>> =>
    ipcRenderer.invoke('save-pending-conversion-v2', input),

  savePendingBankTransaction: (
    transactionType: 'BUY' | 'SELL',
    currencyCode: string,
    amount: number,
    exchangeRate: number,
    hufAmount: number,
    vaultTerritoryId: number | null,
    bankName: string | null,
    bankReference: string | null,
    note: string | null,
  ): Promise<number> =>
    ipcRenderer.invoke(
      'save-pending-bank-transaction',
      transactionType,
      currencyCode,
      amount,
      exchangeRate,
      hufAmount,
      vaultTerritoryId,
      bankName,
      bankReference,
      note,
    ),

  savePendingStorno: (
    payload: IpcRequest<'save-pending-storno'>,
  ): Promise<IpcResponse<'save-pending-storno'>> =>
    ipcRenderer.invoke('save-pending-storno', payload),

  getPendingTransactions: (): Promise<
    Array<{
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
      // Multi-line aggregalt vetel/eladas sorai JSON-kent (backend TransactionLineRequestDto alak);
      // NULL → egysoros. A vazlat-bongeszo ebbol rekonstrualja a multi-line nyugtat (localQueue).
      lines: string | null;
      local_reference_number: string | null;
      idempotency_key: string | null;
      created_at: string;
      synced: number;
    }>
  > => ipcRenderer.invoke('get-pending-transactions'),

  // 2026-06-04 (audit-fix): a TÉNYLEGES szigorú helyi sorszám lekérdezése a mentett pending-sor
  // ID-je alapján, hogy a nyugta a valós (rögzített) bizonylatszámot kapja.
  getPendingTransactionRefById: (id: number): Promise<string | null> =>
    ipcRenderer.invoke('get-pending-transaction-ref-by-id', id),

  // 2026-06-04 (audit-fix, buy/sell-paritás): a TÉNYLEGES átadólap-sorszám lekérdezése a mentett
  // transfer pending-sor ID-je alapján, hogy a szállítólevél a valós (rögzített) számot kapja.
  getPendingTransferRefById: (id: number): Promise<string | null> =>
    ipcRenderer.invoke('get-pending-transfer-ref-by-id', id),

  getPendingTransactionCount: (): Promise<number> =>
    ipcRenderer.invoke('get-pending-transaction-count'),

  // FKH-D2/F5: sync-gate-elt gyari reset. A `getUnsyncedSummary` MINDEN offline
  // outbox-tablat nez (13 db), nem csak a `pending_transactions`-t.
  getUnsyncedSummary: (): Promise<{ total: number; byTable: Record<string, number> }> =>
    ipcRenderer.invoke('get-unsynced-summary'),

  factoryResetLocalDatabase: (): Promise<{
    ok: boolean;
    blockedBy?: { total: number; byTable: Record<string, number> };
    deletedPath?: string;
  }> => ipcRenderer.invoke('factory-reset-local-database'),

  getPendingConversions: (): Promise<
    Array<{
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
      idempotency_key: string | null;
      created_at: string;
      synced: number;
    }>
  > => ipcRenderer.invoke('get-pending-conversions'),

  getPendingBankTransactions: (): Promise<
    Array<{
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
    }>
  > => ipcRenderer.invoke('get-pending-bank-transactions'),

  getPendingStornos: (): Promise<
    Array<{
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
    }>
  > => ipcRenderer.invoke('get-pending-stornos'),

  // Offline átadás-átvétel SZTORNÓ (internetkimaradáskor): a backend fordítja vissza a készletet szinkronkor.
  savePendingTransferStorno: (
    payload: IpcRequest<'save-pending-transfer-storno'>,
  ): Promise<IpcResponse<'save-pending-transfer-storno'>> =>
    ipcRenderer.invoke('save-pending-transfer-storno', payload),
  queueShipmentReceipt: (
    payload: IpcRequest<'queue-shipment-receipt'>,
  ): Promise<IpcResponse<'queue-shipment-receipt'>> =>
    ipcRenderer.invoke(IPC_CHANNELS.QUEUE_SHIPMENT_RECEIPT, payload),
  getPendingShipmentReceipts: (): Promise<IpcResponse<'get-pending-shipment-receipts'>> =>
    ipcRenderer.invoke(IPC_CHANNELS.GET_PENDING_SHIPMENT_RECEIPTS),
  // FS-C: körlevél-válasz offline rögzítése (a sync-engine küldi fel a centernek).
  savePendingCircularReply: (
    payload: IpcRequest<'save-pending-circular-reply'>,
  ): Promise<IpcResponse<'save-pending-circular-reply'>> =>
    ipcRenderer.invoke('save-pending-circular-reply', payload),
  // FS-5: okmány-képpár feltöltési outbox (scan → center, törlés nyugtázás után).
  queueScannedDocument: (
    payload: IpcRequest<'queue-scanned-document'>,
  ): Promise<IpcResponse<'queue-scanned-document'>> =>
    ipcRenderer.invoke(IPC_CHANNELS.QUEUE_SCANNED_DOCUMENT, payload),
  getPendingTransferStornos: (): Promise<
    Array<{
      id: number;
      transfer_id: number;
      transfer_number: string | null;
      reason: string;
      local_reference_number: string | null;
      idempotency_key: string | null;
      created_at: string;
      synced: number;
    }>
  > => ipcRenderer.invoke('get-pending-transfer-stornos'),

  // Fizikai ujranyomtatas (Codex P2 #1035): mar szinkronizalt (synced = 1) bizonylatok lekerdezese,
  // hogy egy meghiusult fizikai nyomtatas utan a lokalis receiptData-bol ESC/POS-on ujra lehessen
  // nyomtatni. A `lines` oszlop (multi-line aggregalt vetel/eladas) is visszajon, igy az ujranyomtatas
  // a TELJES tetelsort rekonstrualja.
  getReprintableTransactions: (
    limit?: number,
  ): Promise<
    Array<{
      id: number;
      type: string;
      currency_code: string;
      foreign_amount: number;
      huf_amount: number;
      rounded_huf_amount: number;
      rate: number;
      handling_fee: number | null;
      discount_percent: number | null;
      customer_name: string | null;
      customer_document_number: string | null;
      lines: string | null;
      local_reference_number: string | null;
      created_at: string;
      synced: number;
    }>
  > => ipcRenderer.invoke('get-reprintable-transactions', limit),

  getReprintableConversions: (
    limit?: number,
  ): Promise<
    Array<{
      id: number;
      from_currency_code: string;
      to_currency_code: string;
      from_amount: number;
      calculated_huf_amount: number;
      calculated_to_amount: number;
      conversion_rate: number;
      customer_name: string | null;
      customer_document_number: string | null;
      note: string | null;
      local_reference_number: string | null;
      created_at: string;
      synced: number;
    }>
  > => ipcRenderer.invoke('get-reprintable-conversions', limit),

  getReprintableStornos: (
    limit?: number,
  ): Promise<
    Array<{
      id: number;
      original_receipt_number: string;
      currency_code: string;
      foreign_amount: number | null;
      huf_amount: number;
      exchange_rate: number | null;
      custom_exchange_rate: number | null;
      reason: string;
      customer_name: string | null;
      customer_document_number: string | null;
      local_reference_number: string | null;
      created_at: string;
      synced: number;
    }>
  > => ipcRenderer.invoke('get-reprintable-stornos', limit),

  syncOffline: (): Promise<IpcResponse<'sync-offline'>> => ipcRenderer.invoke('sync-offline'),

  // FK-071 FR-3: egy pending tranzakció célzott, azonnali újraküldése a
  // Tranzakciólista "Újraküldés" gombjáról (kliens-újraindítás nélkül).
  retryPendingTransaction: (id: number): Promise<{ success: boolean; error?: string | null }> =>
    ipcRenderer.invoke('retry-pending-transaction', id),

  // FKH-032 FR-2/FR-4: célzott azonnali könyvelési kísérlet EGY frissen mentett
  // tételre — tétel-szintű, konkrét eredménnyel (nem összesített logikai jelzés).
  syncSingleTransactionImmediate: (
    id: number,
  ): Promise<{ success: boolean; error?: string | null }> =>
    ipcRenderer.invoke('sync-single-transaction-immediate', id),

  getSyncStatus: (): Promise<string> => ipcRenderer.invoke('get-sync-status'),

  // 2026-04-29 v2.3.11 (E-B6.2 Page Visibility API):
  // A renderer hív, amikor az Electron ablak inaktívvá / aktívvá válik —
  // a sync-engine leáll / újraindul, hogy ne pollozzon háttérben 30s-onként.
  syncEnginePause: (): Promise<void> => ipcRenderer.invoke('sync-engine-pause'),

  syncEngineResume: (): Promise<void> => ipcRenderer.invoke('sync-engine-resume'),

  getAppVersion: (): Promise<string> => ipcRenderer.invoke('get-app-version'),

  restartApp: (): Promise<void> => ipcRenderer.invoke('restart-app'),

  getPrinters: (): Promise<
    Array<{
      name: string;
      displayName: string;
      description: string;
      status: number;
      isDefault: boolean;
    }>
  > => ipcRenderer.invoke('get-printers'),

  // --- Értéktár Offline IPC ---

  savePendingDistribution: (
    targetBranchCode: string,
    currencyCode: string,
    amount: number,
    denominations: string | null,
    note: string | null,
  ): Promise<number> =>
    ipcRenderer.invoke(
      'save-pending-distribution',
      targetBranchCode,
      currencyCode,
      amount,
      denominations,
      note,
    ),

  savePendingTransfer: (
    targetBranchId: string | null,
    targetBranchCode: string,
    currencyId: number | null,
    currencyCode: string,
    amount: number,
    hufValue: number | null,
    transferType: string | null,
    denominations: string | null,
    note: string | null,
    carrierName: string | null = null,
    sealNumber: string | null = null,
    direction: string | null = null,
    lines: string | null = null,
  ): Promise<IpcResponse<'save-pending-transfer'>> => {
    const args: IpcRequest<'save-pending-transfer'> = [
      targetBranchId,
      targetBranchCode,
      currencyId,
      currencyCode,
      amount,
      hufValue,
      transferType,
      denominations,
      note,
      carrierName,
      sealNumber,
      direction,
      lines,
    ];
    return ipcRenderer.invoke('save-pending-transfer', ...args);
  },

  getPendingTransfers: (): Promise<
    Array<{
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
    }>
  > => ipcRenderer.invoke('get-pending-transfers'),

  savePendingCollection: (
    sourceBranchCode: string,
    currencyCode: string,
    amount: number,
    note: string | null,
  ): Promise<number> =>
    ipcRenderer.invoke('save-pending-collection', sourceBranchCode, currencyCode, amount, note),

  // Sprint 7.1: offline stocktake count
  queueStocktakeCount: (
    itemId: string,
    actualQuantity: number,
    note: string | null,
    idempotencyKey: string | null,
  ): Promise<IpcResponse<'queue-stocktake-count'>> => {
    const args: IpcRequest<'queue-stocktake-count'> = [
      itemId,
      actualQuantity,
      note,
      idempotencyKey,
    ];
    return ipcRenderer.invoke('queue-stocktake-count', ...args);
  },

  savePendingHandoverOperation: (
    payload: IpcRequest<'save-pending-handover-operation'>,
  ): Promise<IpcResponse<'save-pending-handover-operation'>> =>
    ipcRenderer.invoke('save-pending-handover-operation', payload),

  getPendingHandoverOperations: (): Promise<
    Array<{
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
    }>
  > => ipcRenderer.invoke('get-pending-handover-operations'),

  getCachedBranchStatuses: (): Promise<
    Array<{
      branch_code: string;
      branch_name: string;
      company_id: number | null;
      last_sync_at: string | null;
      online_status: string;
      total_huf_value: number;
      daily_turnover: number;
      cash_balances: string | null;
      cached_at: string;
    }>
  > => ipcRenderer.invoke('get-cached-branch-statuses'),

  getCachedBranchStatusTimestamp: (): Promise<string | null> =>
    ipcRenderer.invoke('get-cached-branch-status-timestamp'),

  getCachedRates: (): Promise<
    Array<{
      currency_code: string;
      buy_rate: number;
      sell_rate: number;
      unit: number;
      updated_at: string;
    }>
  > => ipcRenderer.invoke('get-cached-rates'),

  // FK-097 WU-14 (FR-3): iroda-szintű kezelési díj konfiguráció offline cache-olvasás.
  getCachedHandlingFeeConfig: (): Promise<{
    branch_id: string;
    branch_code: string | null;
    company_id: string | null;
    fee_mode: 'NONE' | 'BRACKET' | 'PER_MILLE';
    per_mille_rate: number | null;
    per_mille_cap: number | null;
    bracket_json: string | null;
    valid_from: string | null;
    synced_at: string;
  } | null> => ipcRenderer.invoke('get-cached-handling-fee-config'),

  getCachedCashDesks: (): Promise<
    Array<{
      id: string;
      code: string;
      name: string;
      company_id: string | null;
      city: string | null;
      address: string | null;
      zip_code: string | null;
      phone: string | null;
      is_active: number;
      cached_at: string;
    }>
  > => ipcRenderer.invoke('get-cached-cash-desks'),

  getCachedCashDeskTimestamp: (): Promise<string | null> =>
    ipcRenderer.invoke('get-cached-cash-desk-timestamp'),

  getCachedWorkers: (): Promise<
    Array<{
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
    }>
  > => ipcRenderer.invoke('get-cached-workers'),

  getCachedWorkerTimestamp: (): Promise<string | null> =>
    ipcRenderer.invoke('get-cached-worker-timestamp'),

  saveLocalAuditEvent: (payload: {
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
  }): Promise<number> => ipcRenderer.invoke('save-local-audit-event', payload),

  getLocalAuditEvents: (
    limit?: number,
  ): Promise<
    Array<{
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
    }>
  > => ipcRenderer.invoke('get-local-audit-events', limit),

  // Kamera
  cameraSaveRecording: (transactionId: string, buffer: ArrayBuffer, ext: string): Promise<string> =>
    ipcRenderer.invoke('camera-save-recording', transactionId, buffer, ext),

  cameraExportToUsb: (
    dateFrom: string,
    dateTo: string,
  ): Promise<{ success: boolean; exported: number; error?: string }> =>
    ipcRenderer.invoke('camera-export-to-usb', dateFrom, dateTo),

  cameraListRecordings: (transactionId?: string): Promise<string[]> =>
    ipcRenderer.invoke('camera-list-recordings', transactionId),

  cameraLocalStorageStats: (): Promise<{
    totalUsageBytes: number;
    availableSpaceBytes: number;
    totalRecordings: number;
    oldestDate: string | null;
    newestDate: string | null;
  }> => ipcRenderer.invoke('camera-local-storage-stats'),

  cameraLocalRecordingsByDate: (
    dateFrom: string,
    dateTo: string,
  ): Promise<
    Array<{
      date: string;
      transactionId: string;
      filePath: string;
      fileSizeBytes: number;
      createdAt: string;
    }>
  > => ipcRenderer.invoke('camera-local-recordings-by-date', dateFrom, dateTo),

  cameraLocalReadFile: (filePath: string): Promise<string | null> =>
    ipcRenderer.invoke('camera-local-read-file', filePath),

  cameraLocalCleanup: (retentionDays: number): Promise<{ deletedCount: number }> =>
    ipcRenderer.invoke('camera-local-cleanup', retentionDays),

  // --- RTSP IP kamera ---
  cameraRtspStart: (
    cameras: Array<{
      id: string;
      name: string;
      rtspUrl: string;
      type: 'public' | 'private';
      fps: number;
      resolution: { width: number; height: number };
      segmentDurationSeconds: number;
      retentionDays: number;
    }>,
    encryption?: { enabled: boolean; masterKeyBase64: string },
  ): Promise<{ started: number; errors: string[] }> =>
    ipcRenderer.invoke('camera-rtsp-start', cameras, encryption),

  cameraRtspStop: (): Promise<{ stopped: boolean }> => ipcRenderer.invoke('camera-rtsp-stop'),

  cameraRtspStatus: (): Promise<{
    running: boolean;
    cameras: Array<{
      cameraId: string;
      name: string;
      type: 'public' | 'private';
      recording: boolean;
      currentSegment?: {
        cameraId: string;
        segmentPath: string;
        startTime: string;
        fileSizeBytes: number;
        encrypted: boolean;
      };
    }>;
  }> => ipcRenderer.invoke('camera-rtsp-status'),

  cameraRtspSegments: (
    limit?: number,
  ): Promise<
    Array<{
      cameraId: string;
      segmentPath: string;
      startTime: string;
      endTime?: string;
      fileSizeBytes: number;
      sha256Hash?: string;
      encrypted: boolean;
      nonce?: string;
    }>
  > => ipcRenderer.invoke('camera-rtsp-segments', limit),

  // --- Titkosítás / hash ---
  cameraEncryptFile: (
    plainPath: string,
    encryptedPath: string,
    config: { enabled: boolean; masterKeyBase64: string },
  ): Promise<{ nonce: string }> =>
    ipcRenderer.invoke('camera-encrypt-file', plainPath, encryptedPath, config),

  cameraDecryptFile: (
    encryptedPath: string,
    plainPath: string,
    config: { enabled: boolean; masterKeyBase64: string },
  ): Promise<{ success: boolean }> =>
    ipcRenderer.invoke('camera-decrypt-file', encryptedPath, plainPath, config),

  cameraVerifyHash: (
    filePath: string,
    expectedHash: string,
  ): Promise<{ valid: boolean; actualHash: string }> =>
    ipcRenderer.invoke('camera-verify-hash', filePath, expectedHash),

  cameraGenerateKey: (): Promise<{ keyBase64: string }> =>
    ipcRenderer.invoke('camera-generate-key'),

  // --- Videókezelő motor ---
  videoFindSegments: (
    dateFrom: string,
    dateTo: string,
    cameraId?: string,
  ): Promise<
    Array<{
      cameraId: string;
      date: string;
      filePath: string;
      fileName: string;
      fileSizeBytes: number;
      createdAt: string;
      encrypted: boolean;
    }>
  > => ipcRenderer.invoke('video-find-segments', dateFrom, dateTo, cameraId),

  videoFindByTransaction: (
    transactionTime: string,
    cameraId?: string,
    windowMinutes?: number,
  ): Promise<
    Array<{
      cameraId: string;
      date: string;
      filePath: string;
      fileName: string;
      fileSizeBytes: number;
      createdAt: string;
      encrypted: boolean;
    }>
  > => ipcRenderer.invoke('video-find-by-transaction', transactionTime, cameraId, windowMinutes),

  videoDecryptForPlayback: (
    encryptedPath: string,
    encryptionConfig: { enabled: boolean; masterKeyBase64: string },
    user?: string,
  ): Promise<{ tempPath: string } | { error: string }> =>
    ipcRenderer.invoke('video-decrypt-for-playback', encryptedPath, encryptionConfig, user),

  videoVerifyIntegrity: (
    filePath: string,
    expectedHash: string,
    user?: string,
  ): Promise<{ valid: boolean; actualHash: string }> =>
    ipcRenderer.invoke('video-verify-integrity', filePath, expectedHash, user),

  videoRetentionCleanup: (
    retentionDays?: number,
    user?: string,
  ): Promise<{ deletedFiles: number; freedBytes: number }> =>
    ipcRenderer.invoke('video-retention-cleanup', retentionDays, user),

  videoAuditLog: (
    date?: string,
    limit?: number,
  ): Promise<
    Array<{
      timestamp: string;
      action: string;
      user?: string;
      cameraId?: string;
      segmentPath?: string;
      transactionId?: string;
      receiptNumber?: string;
      details?: string;
      machineId: string;
    }>
  > => ipcRenderer.invoke('video-audit-log', date, limit),

  videoStorageStats: (): Promise<{
    totalBytes: number;
    segmentCount: number;
    encryptedCount: number;
    oldestDate: string | null;
    newestDate: string | null;
    availableBytes: number;
  }> => ipcRenderer.invoke('video-storage-stats'),

  videoCleanupTemp: (): Promise<{ cleaned: number }> => ipcRenderer.invoke('video-cleanup-temp'),

  // Okmány scan
  scanSaveDocument: (
    transactionId: string,
    documentType: 'szemelyi' | 'utlevel' | 'jogositvany' | 'egyeb',
    imageBase64: string,
  ): Promise<{ path: string; encrypted: boolean }> =>
    ipcRenderer.invoke('scan-save-document', transactionId, documentType, imageBase64),

  scanGetDocument: (filepath: string): Promise<string> =>
    ipcRenderer.invoke('scan-get-document', filepath),

  scanListDocuments: (transactionId: string): Promise<string[]> =>
    ipcRenderer.invoke('scan-list-documents', transactionId),

  // --- Secure Token Storage (DPAPI/Keychain titkosított) ---
  secureStoreToken: (token: string): Promise<boolean> =>
    ipcRenderer.invoke('secure-store-token', token),

  secureLoadToken: (): Promise<string | null> => ipcRenderer.invoke('secure-load-token'),

  secureClearToken: (): Promise<void> => ipcRenderer.invoke('secure-clear-token'),

  // --- First-Run Setup Wizard ---
  setupCheck: (): Promise<{
    isFirstRun: boolean;
    envPath: string;
    reason?: string;
  }> => ipcRenderer.invoke('setup:check'),

  setupGetBranches: (params?: {
    apiUrl?: string;
    companyCode?: string;
  }): Promise<
    Array<{
      code: string;
      name: string;
      city: string;
      address?: string;
      isVault?: boolean;
    }>
  > => ipcRenderer.invoke('setup:branches', params),

  setupGetWorkers: (params: IpcRequest<'setup:workers'>): Promise<IpcResponse<'setup:workers'>> =>
    ipcRenderer.invoke(IPC_CHANNELS.SETUP_WORKERS, params),

  setupTestConnection: (
    params: IpcRequest<'setup:test-connection'>,
  ): Promise<IpcResponse<'setup:test-connection'>> =>
    ipcRenderer.invoke(IPC_CHANNELS.SETUP_TEST_CONNECTION, params),

  setupSave: (payload: IpcRequest<'setup:save'>): Promise<IpcResponse<'setup:save'>> =>
    ipcRenderer.invoke(IPC_CHANNELS.SETUP_SAVE, payload),

  // --- VFD ügyfélkijelző (P2-1) ---
  // A penztaros oldal (Buy/Sell/Conversion) hivja meg, hogy az ugyfel
  // a masodik kijelzon lassa a tranzakcio reszleteit. Az `onUpdate` listener
  // a customer-display renderer oldalon (nem a fo-renderer-ben) hasznalando.
  customerDisplay: {
    show: (preferSecondMonitor: boolean): Promise<boolean> =>
      ipcRenderer.invoke('customer-display:show', preferSecondMonitor),
    update: (payload: {
      transactionType?: 'BUY' | 'SELL' | 'CONVERSION' | 'STORNO';
      currencyCode?: string;
      amount?: number;
      hufAmount?: number;
      rate?: number;
      handlingFee?: number;
      totalHuf?: number;
      message?: string;
    }): Promise<void> => ipcRenderer.invoke('customer-display:update', payload),
    hide: (): Promise<void> => ipcRenderer.invoke('customer-display:hide'),
    status: (): Promise<boolean> => ipcRenderer.invoke('customer-display:status'),
    onUpdate: (cb: (payload: unknown) => void): (() => void) => {
      const handler = (_e: unknown, p: unknown): void => cb(p);
      ipcRenderer.on('customer-display:update', handler);
      return () => ipcRenderer.removeListener('customer-display:update', handler);
    },
  },

  // Suite-frissites (docs/auto-update-terv-es-vegrehajtas.md 3.6):
  // a renderer jelenti a muszak-allapotot, mert CSAK a renderer/backend tudja,
  // van-e nyitott kassza, folyamatban levo tranzakcio vagy aktiv napzaras-varazslo.
  // A telepites kizarolag `IDLE_BEFORE_OPEN` (napnyitas elott) vagy
  // `CLOSED_AFTER_DAY_END` (napzaras utan) allapotban indulhat el; ha a renderer
  // sosem jelent, a main process konzervativan `SHIFT_OPEN`-nek tekinti -> nem telepit.
  suiteUpdate: {
    setShiftState: (
      state: 'IDLE_BEFORE_OPEN' | 'SHIFT_OPEN' | 'CLOSED_AFTER_DAY_END',
    ): Promise<{ accepted: boolean; shiftState: string }> =>
      ipcRenderer.invoke('suiteUpdate:setShiftState', state),
    status: (): Promise<{
      state: string;
      shiftState: string;
      readyVersion: string | null;
      mandatory: boolean;
    }> => ipcRenderer.invoke('suiteUpdate:status'),
    startInstall: (): Promise<{ started: boolean; reason?: string }> =>
      ipcRenderer.invoke('suiteUpdate:startInstall'),
    /** Akkor tuzel, amikor egy ellenorzott frissites keszen all (jelolo a felulethez). */
    onReady: (
      cb: (payload: {
        version: string;
        mandatory: boolean;
        notes: string | null;
        installableNow: boolean;
      }) => void,
    ): (() => void) => {
      const handler = (_e: unknown, p: unknown): void =>
        cb(p as { version: string; mandatory: boolean; notes: string | null; installableNow: boolean });
      ipcRenderer.on('suiteUpdate:ready', handler);
      return () => ipcRenderer.removeListener('suiteUpdate:ready', handler);
    },
    /** Letoltesi folyamat (a meglevo autoUpdate:progress csatornat hasznalja ujra). */
    onProgress: (cb: (payload: unknown) => void): (() => void) => {
      const handler = (_e: unknown, p: unknown): void => cb(p);
      ipcRenderer.on('autoUpdate:progress', handler);
      return () => ipcRenderer.removeListener('autoUpdate:progress', handler);
    },
  },

  platform: process.platform,
});
