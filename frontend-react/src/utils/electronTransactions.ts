import type { ConversionRequest, Currency, ExchangeRate } from '../services/api/index'
import { logger } from './logger'

export interface ElectronCachedRate {
  currency_code: string
  buy_rate: number
  sell_rate: number
  unit: number
  updated_at: string
}

export interface PendingBuySellInput {
  type: 'BUY' | 'SELL'
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
  /**
   * Devizastatusz tetel-szinten (V226, 2026-05-14). Ha hianyzik, a backend
   * a tranzakcio-szintu erteket hasznalja (default: FOREIGN).
   */
  foreignStatus?: 'DOMESTIC' | 'FOREIGN'
  // V229 + V235 (2026-05-19 HIBA #14 + #15 + #17 + #18): teljes Pmt.
  // customer-snapshot. Mind opcionalis — ha nincs kitoltve a UI-on (pl. 100k
  // alatti tranzakcio), null/undefined erteket adunk.
  customerBirthPlace?: string | null
  customerBirthDate?: string | null
  customerMotherName?: string | null
  customerNationality?: string | null
  customerDocumentType?: string | null
  sourceOfFunds?: string | null
  customerIsPep?: boolean | null
  customerOnOwnBehalf?: boolean | null
  customerActorName?: string | null
  /** V235 NEW (HIBA #15): PEP minoseg — CSALADTAG / KOZELI_MUNKATARS / KORMANYFO / PARLAMENTI / NAV_VEZETO / EGYEB / null. */
  customerPepKind?: string | null
  /** V235 NEW (HIBA #17): actor (kepviselt fel) teljes azonositasa, ha onOwnBehalf=false. */
  customerActorBirthPlace?: string | null
  customerActorBirthDate?: string | null
  customerActorMotherName?: string | null
  customerActorNationality?: string | null
  customerActorDocumentType?: string | null
  customerActorDocumentNumber?: string | null
  customerActorAddress?: string | null
}

export interface PendingConversionInput {
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
  note: string | null
}

export interface PendingTransferInput {
  targetBranchId: string | null
  targetBranchCode: string
  currencyId: number | null
  currencyCode: string
  amount: number
  hufValue: number | null
  transferType: string | null
  denominations: string | null
  note: string | null
}

export interface PendingBankTransactionInput {
  transactionType: 'BUY' | 'SELL'
  currencyCode: string
  amount: number
  exchangeRate: number
  hufAmount: number
  vaultTerritoryId: number | null
  bankName: string | null
  bankReference: string | null
  note: string | null
}

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

export interface PendingHandoverOperationInput {
  operationType: 'GENERATE' | 'PRINT' | 'COMPLETE'
  sheetId?: string | null
  fromCashDeskId?: string | null
  toCashDeskId?: string | null
  transferDate?: string | null
  amounts?: unknown
  note?: string | null
}

export interface LocalAuditEventInput {
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
}

export interface ElectronQueueSyncOutcome {
  savedIds: number[]
  syncedCount: number
  pendingCount: number
  allSavedSynced: boolean
  /**
   * PR #116: a sync-engine utolso ciklusanak hibauzenetei.
   * A TransactionPage toast logikaja hasznalja: pending+errors -> "server-error" toast,
   * pending-no-errors -> "offline" toast, 0-pending -> "success" toast.
   */
  syncErrors: string[]
}

function getElectronAPI() {
  return window.electronAPI ?? null
}

function normalizeOptionalText(value: string | null | undefined): string | null {
  const normalized = value?.trim()
  return normalized || null
}

export function isElectronQueueAvailable(): boolean {
  return Boolean(getElectronAPI()?.savePendingTransaction)
}

export async function getElectronCachedRates(): Promise<ElectronCachedRate[]> {
  const electronAPI = getElectronAPI()
  if (!electronAPI?.getCachedRates) {
    return []
  }

  return electronAPI.getCachedRates()
}

export function buildFallbackCurrenciesFromCachedRates(cachedRates: ElectronCachedRate[]): Currency[] {
  return cachedRates
    .filter((rate) => rate.currency_code && rate.currency_code !== 'HUF')
    .map((rate, index) => ({
      id: -(index + 1),
      code: rate.currency_code,
      name: rate.currency_code,
      decimals: 2,
      active: true,
    }))
}

export function mapCachedRatesToExchangeRates(
  cachedRates: ElectronCachedRate[],
  currencies: Currency[] = [],
): ExchangeRate[] {
  const currencyByCode = new Map(currencies.map((currency) => [currency.code, currency]))

  return cachedRates.map((rate, index) => {
    const matchedCurrency = currencyByCode.get(rate.currency_code)

    return {
      id: -(index + 1),
      currencyId: matchedCurrency?.id ?? -(index + 1),
      currencyCode: rate.currency_code,
      currencyName: matchedCurrency?.name ?? rate.currency_code,
      validDate: rate.updated_at?.slice(0, 10) ?? '',
      validTime: rate.updated_at ?? '',
      baseBuyRate: rate.buy_rate,
      baseSellRate: rate.sell_rate,
      active: true,
      createdAt: rate.updated_at,
    }
  })
}

/**
 * Safe wrapper async fuggvenyekhez — CRITICAL finding fix: hianyzo try/catch
 */
async function safeElectronOp<T>(opName: string, fn: () => Promise<T>): Promise<T> {
  try {
    return await fn()
  } catch (err) {
    logger.error('electronTransactions', opName + ' failed', err)
    throw err
  }
}

async function finalizeSyncOutcome(
  savedIds: number[],
  listPendingIds: () => Promise<number[]>,
): Promise<ElectronQueueSyncOutcome> {
  const electronAPI = getElectronAPI()
  if (!electronAPI) {
    throw new Error('Electron API nem érhető el')
  }

  try {
    await electronAPI.syncOffline()
  } catch {
    // Ha az azonnali szinkron nem sikerül, a lokális mentés ettől még érvényes marad.
  }

  const pendingIds = new Set(await listPendingIds())
  const pendingCount = savedIds.filter((id) => pendingIds.has(id)).length

  // PR #116: sync-engine utolso ciklusanak hibauzeneteit is visszaadjuk,
  // hogy a UI meg tudja kulonboztetni az "offline" vs "server-error" esetet.
  let syncErrors: string[] = []
  try {
    const statusStr = await electronAPI.getSyncStatus()
    const status = typeof statusStr === 'string' ? JSON.parse(statusStr) : statusStr
    syncErrors = status?.lastSyncResult?.errors ?? []
  } catch (err) {
    logger.error('electronTransactions', 'Failed to read syncStatus', err)
  }

  return {
    savedIds,
    syncedCount: savedIds.length - pendingCount,
    pendingCount,
    allSavedSynced: pendingCount === 0,
    syncErrors,
  }
}

export async function saveAndSyncPendingBuySell(
  entries: PendingBuySellInput[],
): Promise<ElectronQueueSyncOutcome> {
  return safeElectronOp('saveAndSyncPendingBuySell', async () => {
    const electronAPI = getElectronAPI()
    if (!electronAPI?.getPendingTransactions) {
      throw new Error('Electron pending tranzakciós bridge nem érhető el')
    }
    // V235 (2026-05-19 HIBA #14 + #15 + #17 + #18): preferaljuk a V2 API-t a
    // teljes Pmt. customer-snapshot mentesehez. Ha a futtatott Electron build
    // meg nem ismeri (regi telepito), legacy fallback a regi pozicionalis API-ra.
    const hasV2 = typeof electronAPI.savePendingTransactionV2 === 'function'
    if (!hasV2 && !electronAPI.savePendingTransaction) {
      throw new Error('Electron pending tranzakciós bridge nem érhető el')
    }

    const savedIds: number[] = []
    for (const entry of entries) {
      let savedId: number
      if (hasV2) {
        savedId = await electronAPI.savePendingTransactionV2!({
          type: entry.type,
          currencyCode: entry.currencyCode,
          foreignAmount: entry.foreignAmount,
          hufAmount: entry.hufAmount,
          roundedHufAmount: entry.roundedHufAmount,
          rate: entry.rate,
          handlingFee: entry.handlingFee,
          discountPercent: entry.discountPercent,
          customerIdentifier: normalizeOptionalText(entry.customerIdentifier),
          customerName: normalizeOptionalText(entry.customerName),
          customerDocumentNumber: normalizeOptionalText(entry.customerDocumentNumber),
          customerAddress: normalizeOptionalText(entry.customerAddress),
          denominations: entry.denominations,
          foreignStatus: entry.foreignStatus ?? null,
          customerBirthPlace: normalizeOptionalText(entry.customerBirthPlace),
          customerBirthDate: normalizeOptionalText(entry.customerBirthDate),
          customerMotherName: normalizeOptionalText(entry.customerMotherName),
          customerNationality: normalizeOptionalText(entry.customerNationality),
          customerDocumentType: normalizeOptionalText(entry.customerDocumentType),
          sourceOfFunds: normalizeOptionalText(entry.sourceOfFunds),
          customerIsPep: entry.customerIsPep ?? null,
          customerOnOwnBehalf: entry.customerOnOwnBehalf ?? null,
          customerActorName: normalizeOptionalText(entry.customerActorName),
          customerPepKind: normalizeOptionalText(entry.customerPepKind),
          customerActorBirthPlace: normalizeOptionalText(entry.customerActorBirthPlace),
          customerActorBirthDate: normalizeOptionalText(entry.customerActorBirthDate),
          customerActorMotherName: normalizeOptionalText(entry.customerActorMotherName),
          customerActorNationality: normalizeOptionalText(entry.customerActorNationality),
          customerActorDocumentType: normalizeOptionalText(entry.customerActorDocumentType),
          customerActorDocumentNumber: normalizeOptionalText(entry.customerActorDocumentNumber),
          customerActorAddress: normalizeOptionalText(entry.customerActorAddress),
        })
      } else {
        // Legacy pozicionalis API — csak az alapmezok mennek at.
        savedId = await electronAPI.savePendingTransaction(
          entry.type,
          entry.currencyCode,
          entry.foreignAmount,
          entry.hufAmount,
          entry.roundedHufAmount,
          entry.rate,
          entry.handlingFee,
          entry.discountPercent,
          normalizeOptionalText(entry.customerIdentifier),
          normalizeOptionalText(entry.customerName),
          normalizeOptionalText(entry.customerDocumentNumber),
          normalizeOptionalText(entry.customerAddress),
          entry.denominations,
          normalizeOptionalText(entry.sourceOfFunds),
          entry.customerIsPep ?? null,
          entry.foreignStatus ?? null,
        )
      }
      savedIds.push(savedId)
    }

    return finalizeSyncOutcome(savedIds, async () => {
      const pending = await electronAPI.getPendingTransactions()
      return pending.map((row) => row.id)
    })
  })
}

export async function saveAndSyncPendingConversion(
  entry: PendingConversionInput,
): Promise<ElectronQueueSyncOutcome> {
  return safeElectronOp('saveAndSyncPendingConversion', async () => {
    const electronAPI = getElectronAPI()
    if (!electronAPI?.savePendingConversion || !electronAPI.getPendingConversions) {
      throw new Error('Electron pending konverziós bridge nem érhető el')
    }

    const savedId = await electronAPI.savePendingConversion(
      entry.fromCurrencyId,
      entry.fromCurrencyCode,
      entry.toCurrencyId,
      entry.toCurrencyCode,
      entry.fromAmount,
      entry.calculatedHufAmount,
      entry.calculatedToAmount,
      entry.conversionRate,
      entry.handlingFee,
      normalizeOptionalText(entry.customerId),
      normalizeOptionalText(entry.customerName),
      normalizeOptionalText(entry.customerDocumentNumber),
      normalizeOptionalText(entry.note),
    )

    return finalizeSyncOutcome([savedId], async () => {
      const pending = await electronAPI.getPendingConversions()
      return pending.map((row) => row.id)
    })
  })
}

export async function saveAndSyncPendingTransfer(
  entry: PendingTransferInput,
): Promise<ElectronQueueSyncOutcome> {
  return safeElectronOp('saveAndSyncPendingTransfer', async () => {
    const electronAPI = getElectronAPI()
    if (!electronAPI?.savePendingTransfer || !electronAPI.getPendingTransfers) {
      throw new Error('Electron pending transfer bridge nem érhető el')
    }

    const savedId = await electronAPI.savePendingTransfer(
      entry.targetBranchId,
      entry.targetBranchCode,
      entry.currencyId,
      entry.currencyCode,
      entry.amount,
      entry.hufValue,
      entry.transferType,
      entry.denominations,
      normalizeOptionalText(entry.note),
    )

    return finalizeSyncOutcome([savedId], async () => {
      const pending = await electronAPI.getPendingTransfers()
      return pending.map((row) => row.id)
    })
  })
}

export async function saveAndSyncPendingBankTransaction(
  entry: PendingBankTransactionInput,
): Promise<ElectronQueueSyncOutcome> {
  return safeElectronOp('saveAndSyncPendingBankTransaction', async () => {
    const electronAPI = getElectronAPI()
    if (!electronAPI?.savePendingBankTransaction || !electronAPI.getPendingBankTransactions) {
      throw new Error('Electron pending bank transaction bridge nem érhető el')
    }

    const savedId = await electronAPI.savePendingBankTransaction(
      entry.transactionType,
      entry.currencyCode,
      entry.amount,
      entry.exchangeRate,
      entry.hufAmount,
      entry.vaultTerritoryId,
      normalizeOptionalText(entry.bankName),
      normalizeOptionalText(entry.bankReference),
      normalizeOptionalText(entry.note),
    )

    return finalizeSyncOutcome([savedId], async () => {
      const pending = await electronAPI.getPendingBankTransactions()
      return pending.map((row) => row.id)
    })
  })
}

export async function saveAndSyncPendingStorno(
  entry: PendingStornoInput,
): Promise<ElectronQueueSyncOutcome> {
  return safeElectronOp('saveAndSyncPendingStorno', async () => {
    const electronAPI = getElectronAPI()
    if (!electronAPI?.savePendingStorno || !electronAPI.getPendingStornos) {
      throw new Error('Electron pending sztornó bridge nem érhető el')
    }

    const savedId = await electronAPI.savePendingStorno(entry)

    return finalizeSyncOutcome([savedId], async () => {
      const pending = await electronAPI.getPendingStornos()
      return pending.map((row) => row.id)
    })
  })
}

export async function saveAndSyncPendingHandoverOperation(
  entry: PendingHandoverOperationInput,
): Promise<ElectronQueueSyncOutcome> {
  return safeElectronOp('saveAndSyncPendingHandoverOperation', async () => {
    const electronAPI = getElectronAPI()
    if (!electronAPI?.savePendingHandoverOperation || !electronAPI.getPendingHandoverOperations) {
      throw new Error('Electron pending handover bridge nem érhető el')
    }

    const savedId = await electronAPI.savePendingHandoverOperation(entry)

    return finalizeSyncOutcome([savedId], async () => {
      const pending = await electronAPI.getPendingHandoverOperations()
      return pending.map((row) => row.id)
    })
  })
}

export async function recordLocalAuditEvent(entry: LocalAuditEventInput): Promise<number | null> {
  const electronAPI = getElectronAPI()
  if (!electronAPI?.saveLocalAuditEvent) {
    return null
  }

  return electronAPI.saveLocalAuditEvent(entry)
}

export function buildConversionRequestFromSelection(params: {
  fromCurrencyId: number | null
  fromCurrencyCode: string
  toCurrencyId: number | null
  toCurrencyCode: string
  fromAmount: number
  customerId?: string
  customerName?: string
  customerDocumentNumber?: string
  notes?: string
}): ConversionRequest {
  const request: ConversionRequest = {
    fromAmount: params.fromAmount,
  }

  if (params.fromCurrencyId && params.fromCurrencyId > 0) {
    request.fromCurrencyId = params.fromCurrencyId
  } else {
    request.fromCurrencyCode = params.fromCurrencyCode
  }

  if (params.toCurrencyId && params.toCurrencyId > 0) {
    request.toCurrencyId = params.toCurrencyId
  } else {
    request.toCurrencyCode = params.toCurrencyCode
  }

  const customerName = normalizeOptionalText(params.customerName)
  if (customerName) {
    request.customerName = customerName
  }

  const customerId = normalizeOptionalText(params.customerId)
  if (customerId) {
    request.customerId = customerId
  }

  const customerDocumentNumber = normalizeOptionalText(params.customerDocumentNumber)
  if (customerDocumentNumber) {
    request.customerDocumentNumber = customerDocumentNumber
  }

  const notes = normalizeOptionalText(params.notes)
  if (notes) {
    request.notes = notes
  }

  return request
}