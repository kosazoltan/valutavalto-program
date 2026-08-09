import type { BankTransaction, HandoverSheet, Transfer } from '../services/api/index'
import type { Worker } from '../stores/authStore'
import type { PrintReceiptData, TransactionReceiptLine } from '../types/receipt'
import { getElectronAPI } from './electron'
import { logger } from './logger'
import { multiLinePayable } from './rounding'
import { sanitizeSyncErrorMessage } from './syncErrorSanitizer'
import { classifyPendingSyncState } from './pendingSyncState'

export interface PendingReceiptDraft {
  id: string
  referenceNumber: string
  entityType: 'TRANSACTION' | 'CONVERSION' | 'STORNO'
  createdAt: string
  title: string
  statusLabel: string
  canPrint: boolean
  /**
   * Fizikai ujranyomtatas (Codex P2 #1035): ha `true`, ez a tetel egy MAR szinkronizalt
   * (synced = 1) bizonylat, amit egy meghiusult fizikai nyomtatas (papirelakadas) utan
   * az operator ujra ki akar nyomtatni — NEM szinkronra varo vazlat. A nyomtatasi ut
   * azonos (lokalis receiptData → ESC/POS), csak a megjelenites/statusz ter el.
   */
  reprint?: boolean
  /**
   * FKH-031 FR-3: a tetel legutobbi szinkron-hibaja (`pending_transactions.sync_error`),
   * mar PII-maszkolva. Ha ki van toltve, a bizonylat-vazlat lista a fix "Helyben mentve,
   * szinkronra var" felirat helyett a TENYLEGES hibaokot mutatja, piros jelzessel —
   * ugyanugy, ahogy a Tranzakciolista teszi (FK-071, commit 2fbd6fe2).
   */
  syncError?: string | null
  /** FKH-031 FR-3: eddigi sikertelen szinkron-kiserletek szama. */
  syncAttempts?: number | null
  /**
   * FKH-031 NFR-1: `true`, ha a 7 napos automatikus retry-ablak lejart — a
   * sync-engine mar NEM probalkozik magatol, a tetelt csak kezi "Ujrakuldes"
   * viheti fel. A UI ezt megkulonbozteti a "majd ujraprobalja" allapottol.
   */
  needsManualIntervention?: boolean
  /** FKH-031 FR-4: az "Ujrakuldes" gomb ehhez a pending_transactions PK-hoz kotheto. */
  pendingTransactionId?: number
  receiptData: PrintReceiptData
}

export interface LocalPendingHandoverOperation {
  id: string
  operationType: 'GENERATE' | 'PRINT' | 'COMPLETE'
  sheetId: string | null
  fromCashDeskId: string | null
  toCashDeskId: string | null
  transferDate: string | null
  amounts: Record<string, number>
  note: string | null
  referenceNumber: string
  createdAt: string
}

export interface LocalAuditEventView {
  id: number
  entityType: string
  eventType: string
  referenceNumber: string | null
  entityId: string | null
  status: string
  createdAt: string
  retentionUntil: string
  payload: unknown
  customerSnapshot: unknown
  identificationSnapshot: unknown
  rateSnapshot: unknown
}

/**
 * A bizonylat-fejléc cégadatait vezérlő tenant-típus meghatározása a bejelentkezett worker
 * cég-adataiból. A {@link ReceiptPreviewModal} a visszaadott értékhez hardcode-olja a cég
 * teljes nevét / adószámát / címét (jelenleg 2 cég).
 *
 * Leképezés (invariánsok):
 * - **BEST_CHANGE** ← cégkód pontosan `EBC` vagy `BEST` (DB-seed V110: code=`EBC`,
 *   name=`Exclusive Best Change Zrt.`), VAGY a cégnév tartalmazza a `BEST CHANGE` frázist.
 * - **EXPRESSZ** ← minden más (pl. Expressz Ékszerház és Minibank Kft.), illetve hiányzó mezők.
 *
 * Pontos kód-egyezést használunk (nem substring), hogy egy jövőbeli tenant, amelynek kódjában/
 * nevében véletlenül szerepel az „EBC"/„BEST" részlet (pl. „WEBCAM"), NE keveredjen.
 * Korábbi hiba: a `companyCode.includes('BEST')` az EBC-t (kód `EBC`) tévesen EXPRESSZ-nek vette.
 */
export function getCompanyType(worker: Worker | null): 'BEST_CHANGE' | 'EXPRESSZ' {
  const code = (worker?.companyCode ?? '').trim().toUpperCase()
  const name = (worker?.companyName ?? '').toUpperCase()
  if (code === 'EBC' || code === 'BEST' || name.includes('BEST CHANGE')) {
    return 'BEST_CHANGE'
  }
  return 'EXPRESSZ'
}

function normalizeTimestamp(value: string): string {
  return value.includes('T') ? value : value.replace(' ', 'T')
}

function toDateParts(value: string): { date: string; time: string } {
  const normalized = normalizeTimestamp(value)
  const date = new Date(normalized)
  return {
    date: Number.isNaN(date.getTime()) ? normalized.slice(0, 10) : date.toLocaleDateString('hu-HU'),
    time: Number.isNaN(date.getTime())
      ? normalized.slice(11, 19)
      : date.toLocaleTimeString('hu-HU'),
  }
}

function safeParseJson<T>(value: string | null, fallback: T): T {
  if (!value) {
    return fallback
  }

  try {
    return JSON.parse(value) as T
  } catch {
    return fallback
  }
}

function localNumericId(id: number): number {
  return -(1_000_000 + id)
}

// ─── Bizonylat receiptData epitok (vazlat ES ujranyomtatas kozos utvonala) ──────
//
// A vetel/eladas/konverzio/storno pending-sorbol PrintReceiptData-t epitenek. Mind a vazlat-
// lista (synced = 0), mind a fizikai ujranyomtatas (synced = 1, Codex P2 #1035) ugyanezt
// hasznalja, igy a megjelenites es a nyomtatott tartalom GARANTALTAN egyezik.

/** A builder altal igenyelt minimalis tranzakcios sor-alak (vazlat ES reprint sor is megfelel). */
interface TransactionReceiptRow {
  id: number
  type: string
  currency_code: string
  foreign_amount: number
  huf_amount: number
  rounded_huf_amount: number
  rate: number
  handling_fee?: number | null
  discount_percent?: number | null
  customer_name: string | null
  customer_document_number: string | null
  lines?: string | null
  local_reference_number: string | null
  created_at: string
}

interface ConversionReceiptRow {
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
}

interface StornoReceiptRow {
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
}

/**
 * A `lines` oszlop (multi-line aggregalt vetel/eladas) JSON-jenek atalakitasa receipt-sorokka.
 * A tarolt alak a backend TransactionLineRequestDto-ja:
 * `[{ currencyCode, banknoteCount, customExchangeRate, discountType, foreignStatus }]`.
 * A per-soros nyers HUF = banknoteCount * customExchangeRate (kerekites elott), egyezoen a
 * CashierTransactionPage pont-of-sale szamitasaval. Ervenytelen/ures JSON → null (egysoros ag).
 */
function parseTransactionReceiptLines(
  linesJson: string | null | undefined,
): TransactionReceiptLine[] | null {
  if (!linesJson) return null
  let parsed: unknown
  try {
    parsed = JSON.parse(linesJson)
  } catch {
    return null
  }
  if (!Array.isArray(parsed) || parsed.length === 0) return null
  const lines: TransactionReceiptLine[] = []
  for (const raw of parsed) {
    const entry = raw as {
      currencyCode?: unknown
      banknoteCount?: unknown
      customExchangeRate?: unknown
    }
    const foreignAmount = Number(entry.banknoteCount)
    const rate = Number(entry.customExchangeRate)
    // Copilot P2: érvénytelen (nem véges) numerikus mező esetén NE essünk csendben 0-ra — az
    // hibás 0-értékű sort és így hibás aggregált összeget adna. A teljes payload-ot érvénytelennek
    // tekintjük → null, amitől a hívó az egysoros (tárolt, ismert-jó) értékekre esik vissza.
    if (!Number.isFinite(foreignAmount) || !Number.isFinite(rate)) {
      return null
    }
    lines.push({
      currencyCode:
        typeof entry.currencyCode === 'string' && entry.currencyCode ? entry.currencyCode : '—',
      foreignAmount,
      rate,
      hufAmount: foreignAmount * rate,
    })
  }
  return lines
}

function buildTransactionReceiptData(
  row: TransactionReceiptRow,
  worker: Worker | null,
): PrintReceiptData {
  const parts = toDateParts(normalizeTimestamp(row.created_at))
  const mode: 'buy' | 'sell' = row.type === 'BUY' ? 'buy' : 'sell'
  const receiptNumber = row.local_reference_number ?? `LOCAL-TX-${row.id}`
  const base: PrintReceiptData = {
    type: mode,
    companyType: getCompanyType(worker),
    receiptNumber,
    branchCode: worker?.branchCode ?? 'LOCAL',
    cashierName: worker?.fullName ?? 'Electron queue',
    date: parts.date,
    time: parts.time,
    customerName: row.customer_name ?? undefined,
    customerDocNumber: row.customer_document_number ?? undefined,
  }

  const lines = parseTransactionReceiptLines(row.lines)
  if (lines && lines.length > 1) {
    // Multi-line aggregalt nyugta: a TELJES tetelsort listazzuk EGY bizonylatszam alatt, es a
    // fejlec fizetendo vegosszeget a backend TransactionMultiLineService kepletevel rekonstrualjuk
    // (nyers Σ → kedvezmeny + kezelesi dij → EGYSZER 5 Ft-ra kerekitve). A tarolt sor huf_amount-ja
    // a fejlec ELSO soranak erteke (NEM az aggregatum), ezert a lines-bol szamolunk ujra.
    const totalRaw = lines.reduce((sum, ln) => sum + ln.hufAmount, 0)
    const payable = multiLinePayable(
      totalRaw,
      mode,
      row.discount_percent ?? 0,
      row.handling_fee ?? 0,
    )
    // Codex P2: a kezelési díj MÁR bele van számolva a `payable`-be (multiLinePayable), ezért NEM
    // adjuk át külön `handlingFee`-ként — különben a ReceiptPreviewModal (paid = roundedHufAmount +
    // handlingFee) duplán számolná a díjat. Így a preview „Kifizetve" összege EGYEZIK a fizikailag
    // nyomtatott FIZETENDŐ-vel (printer.ts a multi-line nyugtán a roundedHufAmount-ot nyomtatja,
    // a díjat nem tételezi külön).
    return {
      ...base,
      hufAmount: payable,
      roundedHufAmount: payable,
      roundingDiff: 0,
      transactionLines: lines,
    }
  }

  // Egysoros bizonylat (valtozatlan): a tarolt per-soros ertekek.
  return {
    ...base,
    currencyCode: row.currency_code,
    foreignAmount: row.foreign_amount,
    rate: row.rate,
    hufAmount: row.huf_amount,
    roundedHufAmount: row.rounded_huf_amount,
  }
}

function buildConversionReceiptData(
  row: ConversionReceiptRow,
  worker: Worker | null,
): PrintReceiptData {
  const parts = toDateParts(normalizeTimestamp(row.created_at))
  return {
    type: 'conversion',
    companyType: getCompanyType(worker),
    receiptNumber: row.local_reference_number ?? `LOCAL-CONV-${row.id}`,
    branchCode: worker?.branchCode ?? 'LOCAL',
    cashierName: worker?.fullName ?? 'Electron queue',
    date: parts.date,
    time: parts.time,
    sourceCurrencyCode: row.from_currency_code,
    sourceAmount: row.from_amount,
    targetCurrencyCode: row.to_currency_code,
    targetAmount: row.calculated_to_amount,
    rate: row.conversion_rate,
    hufAmount: row.calculated_huf_amount,
    customerName: row.customer_name ?? undefined,
    customerDocNumber: row.customer_document_number ?? undefined,
    note: row.note ?? undefined,
  }
}

function buildStornoReceiptData(row: StornoReceiptRow, worker: Worker | null): PrintReceiptData {
  const parts = toDateParts(normalizeTimestamp(row.created_at))
  return {
    type: 'storno',
    companyType: getCompanyType(worker),
    receiptNumber: row.local_reference_number ?? `LOCAL-STORNO-${row.id}`,
    branchCode: worker?.branchCode ?? 'LOCAL',
    cashierName: worker?.fullName ?? 'Electron queue',
    date: parts.date,
    time: parts.time,
    currencyCode: row.currency_code,
    foreignAmount: row.foreign_amount ?? undefined,
    rate: row.custom_exchange_rate ?? row.exchange_rate ?? undefined,
    hufAmount: row.huf_amount,
    roundedHufAmount: row.huf_amount,
    customerName: row.customer_name ?? undefined,
    customerDocNumber: row.customer_document_number ?? undefined,
    stornoReason: row.reason,
    originalReceiptNumber: row.original_receipt_number,
  }
}

export async function getPendingReceiptDrafts(
  worker: Worker | null,
): Promise<PendingReceiptDraft[]> {
  try {
    const electronAPI = getElectronAPI()
    if (
      !electronAPI?.getPendingTransactions ||
      !electronAPI.getPendingConversions ||
      !electronAPI.getPendingStornos
    ) {
      return []
    }

    const [transactions, conversions, stornoRows] = await Promise.all([
      electronAPI.getPendingTransactions(),
      electronAPI.getPendingConversions(),
      electronAPI.getPendingStornos(),
    ])

    const drafts: PendingReceiptDraft[] = []

    for (const row of transactions) {
      const createdAt = normalizeTimestamp(row.created_at)
      // FKH-031 FR-3: a tarolt hibauzenet PII-maszkolva kerul a UI-ra (defense in depth —
      // az Electron oldal mar maszkolva tarol, ez a legacy sorokat is lefedi).
      const rawSyncError = (row as { sync_error?: string | null }).sync_error ?? null
      const syncError = rawSyncError ? sanitizeSyncErrorMessage(rawSyncError) : null
      const syncAttempts = (row as { sync_attempts?: number | null }).sync_attempts ?? null
      // FKH-031 NFR-1: 7 nap utan a sync-engine mar NEM probalkozik automatikusan
      // (business-retry.ts: isBusinessRetryWithheld), ezert a felirat is mast mond —
      // kulonben a penztaros nem tudna, hogy kezi ujrakuldes nelkul a tetel nem megy fel.
      const syncState = classifyPendingSyncState({ syncError, createdAt: row.created_at })
      drafts.push({
        id: `tx-${row.id}`,
        referenceNumber: row.local_reference_number ?? `LOCAL-TX-${row.id}`,
        entityType: 'TRANSACTION',
        createdAt,
        title: row.type === 'BUY' ? 'Vételi vázlat' : 'Eladási vázlat',
        statusLabel: syncState.label,
        needsManualIntervention: syncState.needsManualIntervention,
        syncError,
        syncAttempts,
        pendingTransactionId: row.id,
        canPrint: true,
        receiptData: buildTransactionReceiptData(row, worker),
      })
    }

    for (const row of conversions) {
      const createdAt = normalizeTimestamp(row.created_at)
      drafts.push({
        id: `conv-${row.id}`,
        referenceNumber: row.local_reference_number ?? `LOCAL-CONV-${row.id}`,
        entityType: 'CONVERSION',
        createdAt,
        title: 'Konverziós vázlat',
        statusLabel: 'Helyben mentve, szinkronra vár',
        canPrint: true,
        receiptData: buildConversionReceiptData(row, worker),
      })
    }

    for (const row of stornoRows) {
      const createdAt = normalizeTimestamp(row.created_at)
      drafts.push({
        id: `storno-${row.id}`,
        referenceNumber: row.local_reference_number ?? `LOCAL-STORNO-${row.id}`,
        entityType: 'STORNO',
        createdAt,
        title: 'Sztornó vázlat',
        statusLabel: 'Helyben mentve, szinkronra vár',
        canPrint: true,
        receiptData: buildStornoReceiptData(row, worker),
      })
    }

    return drafts.sort((left, right) => right.createdAt.localeCompare(left.createdAt))
  } catch (err) {
    logger.error('localQueue', 'getPendingReceiptDrafts failed', err)
    throw err
  }
}

/**
 * Fizikai ujranyomtatas (Codex P2 #1035): a MAR szinkronizalt (synced = 1) bizonylatok legutobbi
 * sorai, hogy egy meghiusult fizikai nyomtatas (papirelakadas, nyomtato offline) utan az operator
 * a lokalis receiptData-bol ESC/POS-on UJRA ki tudja nyomtatni a bizonylatot.
 *
 * Local-first marad: a fizikai nyomtatas ugyanazon a `printReceipt` (ESC/POS/serial) uton megy, mint
 * a vazlat-nyomtatas (NEM a backend). A multi-currency bizonylatok teljes tetelsora a `lines` oszlopbol
 * rekonstrualodik (lasd `buildTransactionReceiptData`).
 *
 * Visszafele kompatibilis: ha a futtatott Electron build (preload) meg nem ismeri a reprint-API-kat
 * (regi telepito), ures listat ad → a UI nem mutat ujranyomtatas-szekciot, semmi nem torik.
 */
export async function getReprintableReceiptDrafts(
  worker: Worker | null,
): Promise<PendingReceiptDraft[]> {
  try {
    const electronAPI = getElectronAPI()
    if (
      !electronAPI?.getReprintableTransactions ||
      !electronAPI.getReprintableConversions ||
      !electronAPI.getReprintableStornos
    ) {
      return []
    }

    const [transactions, conversions, stornoRows] = await Promise.all([
      electronAPI.getReprintableTransactions(),
      electronAPI.getReprintableConversions(),
      electronAPI.getReprintableStornos(),
    ])

    const REPRINT_STATUS = 'Szinkronizálva — fizikai újranyomtatás'
    const drafts: PendingReceiptDraft[] = []

    for (const row of transactions) {
      drafts.push({
        id: `reprint-tx-${row.id}`,
        referenceNumber: row.local_reference_number ?? `LOCAL-TX-${row.id}`,
        entityType: 'TRANSACTION',
        createdAt: normalizeTimestamp(row.created_at),
        title: row.type === 'BUY' ? 'Vételi bizonylat' : 'Eladási bizonylat',
        statusLabel: REPRINT_STATUS,
        canPrint: true,
        reprint: true,
        receiptData: buildTransactionReceiptData(row, worker),
      })
    }

    for (const row of conversions) {
      drafts.push({
        id: `reprint-conv-${row.id}`,
        referenceNumber: row.local_reference_number ?? `LOCAL-CONV-${row.id}`,
        entityType: 'CONVERSION',
        createdAt: normalizeTimestamp(row.created_at),
        title: 'Konverziós bizonylat',
        statusLabel: REPRINT_STATUS,
        canPrint: true,
        reprint: true,
        receiptData: buildConversionReceiptData(row, worker),
      })
    }

    for (const row of stornoRows) {
      drafts.push({
        id: `reprint-storno-${row.id}`,
        referenceNumber: row.local_reference_number ?? `LOCAL-STORNO-${row.id}`,
        entityType: 'STORNO',
        createdAt: normalizeTimestamp(row.created_at),
        title: 'Sztornó bizonylat',
        statusLabel: REPRINT_STATUS,
        canPrint: true,
        reprint: true,
        receiptData: buildStornoReceiptData(row, worker),
      })
    }

    return drafts.sort((left, right) => right.createdAt.localeCompare(left.createdAt))
  } catch (err) {
    logger.error('localQueue', 'getReprintableReceiptDrafts failed', err)
    throw err
  }
}

export async function printPendingReceiptDraft(receiptData: PrintReceiptData): Promise<boolean> {
  try {
    const electronAPI = getElectronAPI()
    if (!electronAPI?.printReceipt) {
      return false
    }

    return electronAPI.printReceipt(JSON.stringify(receiptData))
  } catch (err) {
    logger.error('localQueue', 'printPendingReceiptDraft failed', err)
    throw err
  }
}

/**
 * Penztar-batch A.1: a pending_transfers.lines JSON parzolása Transfer.lines-szá.
 * Hibás/hiányzó JSON → undefined (egysoros viselkedés, nem dob).
 */
export function parseTransferLines(raw: string | null | undefined): Transfer['lines'] {
  if (!raw) return undefined
  try {
    const parsed = JSON.parse(raw) as Array<{
      currencyId?: number
      amount?: number
      currencyCode?: string
    }>
    if (!Array.isArray(parsed) || parsed.length === 0) return undefined
    return parsed
      .filter((l) => typeof l?.currencyId === 'number' && typeof l?.amount === 'number')
      .map((l) => ({ currencyId: l.currencyId!, amount: l.amount!, currencyCode: l.currencyCode }))
  } catch {
    return undefined
  }
}

export async function getLocalPendingTransfers(worker: Worker | null): Promise<Transfer[]> {
  try {
    const electronAPI = getElectronAPI()
    if (!electronAPI?.getPendingTransfers) {
      return []
    }

    const pending = await electronAPI.getPendingTransfers()
    return pending.map((row) => ({
      id: localNumericId(row.id),
      transferNumber: row.local_reference_number ?? `LOCAL-TRANSFER-${row.id}`,
      // Penztar-batch A.1 (2026-06-12): a több-valutás sorok a queue-sor lines JSON-jából —
      // a lista offline is minden valutát mutat (a mentés currencyCode-dal dúsítva írja).
      lines: parseTransferLines(row.lines),
      // Verif PR #1101 P2: az irány nélkül az offline 'U' (átvétel) bizonylata a szem-ikonból
      // fordított orientációval (Átadási címmel) nyílt volna — a SQLite sor hordozza.
      direction: (row.direction as Transfer['direction']) ?? undefined,
      fromBranchId: worker?.branchId ?? 'LOCAL',
      fromBranchCode: worker?.branchCode ?? 'LOCAL',
      fromBranchName: worker?.branchName ?? 'Helyi pénztár',
      toBranchId: row.target_branch_id ?? 'PENDING',
      toBranchCode: row.target_branch_code,
      toBranchName: row.target_branch_code,
      fromWorkerId: worker?.id ?? 0,
      fromWorkerName: worker?.fullName ?? 'Electron queue',
      transferType: (row.transfer_type as Transfer['transferType']) ?? 'CURRENCY',
      transferTypeDisplay: row.transfer_type ?? 'Átadás',
      status: 'PENDING',
      statusDisplay: 'Helyben mentve',
      transferDate: row.created_at.slice(0, 10),
      transferTime: row.created_at.slice(11, 19),
      currencyId: row.currency_id ?? 0,
      currencyCode: row.currency_code,
      currencyName: row.currency_code,
      amount: row.amount,
      hufValue: row.huf_value ?? undefined,
      notes: row.note ?? undefined,
      // Batch2-E: a mentés óta tárolt szállító + plombaszám az offline előnézetre is
      // (eddig strukturálisan elveszett — a szem-ikonos bizonylat üresen mutatta).
      carrierName: row.carrier_name ?? undefined,
      sealNumber: row.seal_number ?? undefined,
      handoverPrinted: false,
      receiptPrinted: false,
      createdAt: normalizeTimestamp(row.created_at),
      hasDifference: false,
      isCompleted: false,
      isPending: true,
    }))
  } catch (err) {
    logger.error('localQueue', 'getLocalPendingTransfers failed', err)
    throw err
  }
}

/**
 * Offline átadás-átvétel SZTORNÓ queue-olása (internetkimaradáskor). A backend a szinkronkor
 * fordítja vissza a készletet (POST /transfers/{id}/storno). True, ha lokálisan rögzült.
 */
export async function queueOfflineTransferStorno(
  transferId: number,
  transferNumber: string | null,
  reason: string,
): Promise<boolean> {
  const electronAPI = getElectronAPI()
  if (!electronAPI?.savePendingTransferStorno) return false
  await electronAPI.savePendingTransferStorno({ transferId, transferNumber, reason })
  return true
}

/** FKH-018: szerveroldali Shipment meglévő állapotának offline átvételi szándéka. */
export async function queueOfflineShipmentReceipt(
  shipmentId: string,
  requestNumber: string | null,
  branchId: string,
  workerId: number,
  idempotencyKey: string,
  confirmedStale?: boolean,
): Promise<boolean> {
  const electronAPI = getElectronAPI()
  if (!electronAPI?.queueShipmentReceipt) return false
  await electronAPI.queueShipmentReceipt({
    shipmentId,
    requestNumber,
    branchId,
    workerId,
    idempotencyKey,
    ...(confirmedStale === true ? { confirmedStale: true } : {}),
  })
  return true
}

export interface LocalShipmentReceiptIntent {
  shipmentId: string
  requestNumber: string
  branchId: string
  workerId: number
  createdAt: string
}

export interface LocalShipmentReceiptOutboxState {
  pending: LocalShipmentReceiptIntent[]
  issues: Array<{ requestNumber: string; message: string }>
}

/**
 * A teljes, tenant-szűrt outbox állapot egy IPC-olvasással. A pending sorok nem csak ID-ként
 * térnek vissza: így renderer-újraindítás és REST-kiesés után is megjeleníthető a tartós szándék.
 */
export async function getShipmentReceiptOutboxState(): Promise<LocalShipmentReceiptOutboxState> {
  const electronAPI = getElectronAPI()
  if (!electronAPI?.getPendingShipmentReceipts) return { pending: [], issues: [] }
  const state = await electronAPI.getPendingShipmentReceipts()
  return {
    pending: state
      .filter((row) => row.synced === 0)
      .map((row) => ({
        shipmentId: row.shipment_id,
        requestNumber: row.request_number || row.shipment_id,
        branchId: row.branch_id,
        workerId: row.worker_id,
        createdAt: row.created_at,
      })),
    issues: state
      .filter((row) => row.synced !== 0 && Boolean(row.sync_error))
      .map((row) => ({
        requestNumber: row.request_number || row.shipment_id,
        message: row.sync_error || 'Az offline Shipment-átvétel sikertelen.',
      })),
  }
}

/** A tartós outboxban még nyugtázatlan Shipment-azonosítók a "szinkronra vár" UI-hoz. */
export async function getQueuedShipmentReceiptIds(): Promise<Set<string>> {
  const state = await getShipmentReceiptOutboxState()
  return new Set(state.pending.map((row) => row.shipmentId))
}

/** Tartós, terminális Shipment-átvételi hibák az operátori felülethez. */
export async function getShipmentReceiptIssues(): Promise<
  Array<{ requestNumber: string; message: string }>
> {
  return (await getShipmentReceiptOutboxState()).issues
}

export async function getLocalPendingBankTransactions(): Promise<BankTransaction[]> {
  try {
    const electronAPI = getElectronAPI()
    if (!electronAPI?.getPendingBankTransactions) {
      return []
    }

    const pending = await electronAPI.getPendingBankTransactions()
    return pending.map((row) => ({
      id: localNumericId(row.id),
      transactionType: row.transaction_type,
      currencyCode: row.currency_code,
      amount: row.amount,
      exchangeRate: row.exchange_rate,
      hufAmount: row.huf_amount,
      bankName: row.bank_name ?? undefined,
      bankReference: row.bank_reference ?? undefined,
      status: 'PENDING_SYNC',
      note: row.note ?? undefined,
      createdAt: normalizeTimestamp(row.created_at),
      vaultTerritoryId: row.vault_territory_id ?? undefined,
    }))
  } catch (err) {
    logger.error('localQueue', 'getLocalPendingBankTransactions failed', err)
    throw err
  }
}

export async function getLocalPendingHandoverOperations(): Promise<
  LocalPendingHandoverOperation[]
> {
  try {
    const electronAPI = getElectronAPI()
    if (!electronAPI?.getPendingHandoverOperations) {
      return []
    }

    const operations = await electronAPI.getPendingHandoverOperations()
    return operations.map((row) => ({
      id: `handover-${row.id}`,
      operationType: row.operation_type,
      sheetId: row.sheet_id,
      fromCashDeskId: row.from_cash_desk_id,
      toCashDeskId: row.to_cash_desk_id,
      transferDate: row.transfer_date,
      amounts: safeParseJson<Record<string, number>>(row.amounts_json, {}),
      note: row.note,
      referenceNumber: row.local_reference_number ?? `LOCAL-HANDOVER-${row.id}`,
      createdAt: normalizeTimestamp(row.created_at),
    }))
  } catch (err) {
    logger.error('localQueue', 'getLocalPendingHandoverOperations failed', err)
    throw err
  }
}

export function mapPendingHandoverGeneratesToSheets(
  operations: LocalPendingHandoverOperation[],
  cashDeskNames: Map<string, string>,
): HandoverSheet[] {
  return operations
    .filter((operation) => operation.operationType === 'GENERATE')
    .map((operation) => ({
      id: operation.id,
      sheetNumber: operation.referenceNumber,
      fromCashDeskId: operation.fromCashDeskId ?? '',
      fromCashDeskName:
        cashDeskNames.get(operation.fromCashDeskId ?? '') ??
        operation.fromCashDeskId ??
        'Ismeretlen',
      toCashDeskId: operation.toCashDeskId ?? '',
      toCashDeskName:
        cashDeskNames.get(operation.toCashDeskId ?? '') ?? operation.toCashDeskId ?? 'Ismeretlen',
      transferDate: operation.transferDate ?? operation.createdAt.slice(0, 10),
      amounts: operation.amounts,
      notes: operation.note ?? undefined,
      status: 'PENDING_SYNC',
      createdByName: 'Electron queue',
    }))
}

export async function getLocalAuditEvents(limit: number = 100): Promise<LocalAuditEventView[]> {
  try {
    const electronAPI = getElectronAPI()
    if (!electronAPI?.getLocalAuditEvents) {
      return []
    }

    const events = await electronAPI.getLocalAuditEvents(limit)
    return events.map((event) => ({
      id: event.id,
      entityType: event.entity_type,
      eventType: event.event_type,
      referenceNumber: event.reference_number,
      entityId: event.entity_id,
      status: event.status,
      createdAt: normalizeTimestamp(event.created_at),
      retentionUntil: normalizeTimestamp(event.retention_until),
      payload: safeParseJson(event.payload_json, null),
      customerSnapshot: safeParseJson(event.customer_snapshot_json, null),
      identificationSnapshot: safeParseJson(event.identification_snapshot_json, null),
      rateSnapshot: safeParseJson(event.rate_snapshot_json, null),
    }))
  } catch (err) {
    logger.error('localQueue', 'getLocalAuditEvents failed', err)
    throw err
  }
}
