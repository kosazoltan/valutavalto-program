import type { ConversionRequest, Currency, ExchangeRate } from '../services/api/index'
import { logger } from './logger'

export interface ElectronCachedRate {
  currency_code: string
  buy_rate: number
  sell_rate: number
  unit: number
  updated_at: string
  // FK-SÁVOS (2026-06-02): a sávos (limit) árfolyammezők. A SQLite cached_rates tárolja és az IPC
  // (SELECT *) visszaadja, de eddig az interface + a mapper eldobta → a pénztári képernyő nem látta
  // a sávokat Electron cache útvonalon. (official_rate + limit1/2/3 amount/buy/sell.)
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
  /**
   * AML vezetoi jovahagyas (2026-06-04): a jovahagyo supervisor/manager/admin workerId-ja, ha a
   * tranzakcio felsovezetoi jovahagyast igenyelt (FATF / eves limit / BIGCTRL 4+). NULL/undefined,
   * ha nem kellett. A backend (approverWorkerId=null) backward-compat → opcionalis, additiv.
   */
  approverWorkerId?: number | null
  /** AML jovahagyas-session azonosito — a grantot a konkret nyugtahoz koti (Codex P1: receipt-scoping). */
  approvalSessionId?: string | null
  /**
   * Multi-line aggregate (2026-06-04): ha kitoltott, ez az entry EGY tobb-soros vetel/eladas
   * nyugtat kepvisel — a backend `lines[]` aggregalt utvonalra megy (egy AML-kapu, egy approval-
   * grant), N fuggetlen egysoros helyett. JSON-string a backend TransactionLineRequestDto alakjaban:
   * [{ currencyCode, banknoteCount, customExchangeRate, discountType, foreignStatus }].
   * A fejlec-mezok (currencyCode/foreignAmount/hufAmount/rate) az ELSO sor erteket hordozzak.
   * NULL/hianyzo → egysoros tranzakcio (valtozatlan viselkedes).
   */
  lines?: string | null
  /**
   * FK-KEZDIJ offline (2026-06-12, penztar-batch B.1/b): a kezelesi dij override
   * (HALF/WAIVED/SPECIAL + indok + ugyfelkartya-szam) az offline outboxban is —
   * eddig CSENDBEN elveszett az Electron uton (a szerver a teljes alap-dijat konyvelte).
   */
  handlingFeeOverrideType?: string | null
  handlingFeeOverrideReason?: string | null
  customerCardNumber?: string | null
  /** V325 (Batch3-C): jogi szemely ugyfel + tenyleges tulajdonosok (JSON) az offline outboxban. */
  isLegalEntityCustomer?: boolean | null
  legalEntityName?: string | null
  legalEntitySeat?: string | null
  legalEntityTaxNumber?: string | null
  legalDeedNumber?: string | null
  beneficialOwnersJson?: string | null
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
  // V235 + V236 (2026-05-19 Codex P1 #695): teljes Pmt. customer-snapshot
  // a Konverzio offline outbox-ban. Mind opcionalis (100k alatti tx esete).
  customerAddress?: string | null
  customerNationality?: string | null
  customerBirthPlace?: string | null
  customerBirthDate?: string | null
  customerMotherName?: string | null
  customerDocumentType?: string | null
  sourceOfFunds?: string | null
  customerIsPep?: boolean | null
  customerOnOwnBehalf?: boolean | null
  customerActorName?: string | null
  customerPepKind?: string | null
  customerActorBirthPlace?: string | null
  customerActorBirthDate?: string | null
  customerActorMotherName?: string | null
  customerActorNationality?: string | null
  customerActorDocumentType?: string | null
  customerActorDocumentNumber?: string | null
  customerActorAddress?: string | null
  // HIBA 2026-05-26 (#2): ugyfel deviza-statusza (DOMESTIC/FOREIGN)
  foreignStatus?: string | null
  /** AML vezetoi jovahagyas (2026-06-04): jovahagyo workerId, ha a konverzio felsovezetoi jovahagyast igenyelt. */
  approverWorkerId?: number | null
  /** AML jovahagyas-session azonosito — a grantot a konkret nyugtahoz koti (Codex P1: receipt-scoping). */
  approvalSessionId?: string | null
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
  carrierName?: string | null
  sealNumber?: string | null
  direction?: string | null
  /** #6: több-valutás átadólap sorai JSON-stringként ([{currencyId, amount}]). */
  lines?: string | null
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
  /**
   * 2026-06-04 (audit-fix): a mentett pending-sorok TÉNYLEGES szigorú helyi sorszámai
   * (local_reference_number), `savedIds`-szel azonos sorrendben. A nyugta-nyomtatás ezt
   * bélyegzi a bizonylatra a fabrikált `P-<timestamp>` helyett, így a kinyomtatott szám
   * EGYEZIK a rögzített tranzakcióval. Egy-egy elem null lehet, ha a régi Electron-preload
   * nem ismeri a lekérdező IPC-t (offline-first fallback). Csak a vétel/eladás úton töltjük.
   */
  localReferenceNumbers: (string | null)[]
  /**
   * FKH-032 FR-4: tétel-szintű eredmény a MENTÉSKOR lefutó, célzott azonnali
   * könyvelési kísérletről (`syncSingleTransactionImmediate`). Kulcs: a helyi
   * pending id, érték: a konkrét hibaüzenet (siker esetén a tétel nem szerepel benne).
   * Üres objektum, ha a futtatott Electron build még nem ismeri a célzott IPC-t
   * (ekkor a régi, összesített `syncOffline()` útvonal futott — offline-first fallback).
   */
  immediateErrors: Record<number, string>
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

// FK-097 WU-15 (FR-3/FR-4): az iroda-szintu kezelesi dij konfiguracio offline tukre.
export interface ElectronCachedHandlingFeeConfig {
  branch_id: string
  branch_code: string | null
  company_id: string | null
  fee_mode: 'NONE' | 'BRACKET' | 'PER_MILLE'
  per_mille_rate: number | null
  per_mille_cap: number | null
  bracket_json: string | null
  valid_from: string | null
  synced_at: string
}

export async function getElectronCachedHandlingFeeConfig(): Promise<ElectronCachedHandlingFeeConfig | null> {
  const electronAPI = getElectronAPI()
  if (!electronAPI?.getCachedHandlingFeeConfig) {
    return null
  }
  try {
    return await electronAPI.getCachedHandlingFeeConfig()
  } catch {
    return null
  }
}

export function buildFallbackCurrenciesFromCachedRates(
  cachedRates: ElectronCachedRate[],
): Currency[] {
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
      // FK-SÁVOS (2026-06-02): a sávos árfolyam-mezők átadása, hogy a getBandForAmount() Electron
      // cache útvonalon is megkapja a valós sávokat (null → undefined a típus-kompatibilitásért).
      officialRate: rate.official_rate ?? undefined,
      limit1Amount: rate.limit1_amount ?? undefined,
      limit1BuyRate: rate.limit1_buy_rate ?? undefined,
      limit1SellRate: rate.limit1_sell_rate ?? undefined,
      limit2Amount: rate.limit2_amount ?? undefined,
      limit2BuyRate: rate.limit2_buy_rate ?? undefined,
      limit2SellRate: rate.limit2_sell_rate ?? undefined,
      limit3Amount: rate.limit3_amount ?? undefined,
      limit3BuyRate: rate.limit3_buy_rate ?? undefined,
      limit3SellRate: rate.limit3_sell_rate ?? undefined,
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
  localReferenceNumbers: (string | null)[] = [],
  // FKH-032 FR-2: csak a vétel/eladás (pending_transactions) úton értelmezett —
  // a savedIds ott helyi pending-tranzakció id, amit a célzott IPC vár.
  useImmediateTargetedSync = false,
): Promise<ElectronQueueSyncOutcome> {
  const electronAPI = getElectronAPI()
  if (!electronAPI) {
    throw new Error('Electron API nem érhető el')
  }

  // FKH-032 FR-1/FR-2/FR-3/FR-4: a mentéskori kísérlet CÉLZOTT (csak a frissen mentett
  // tételekre) és a main-process net.request csatornán megy, 5 mp timeouttal. A régi,
  // teljes-sort küldő syncOffline() marad a fallback, ha a futtatott Electron build még
  // nem ismeri a célzott IPC-t (régi telepítő) — offline-first kompatibilitás.
  const immediateErrors: Record<number, string> = {}
  const canTargetImmediate =
    useImmediateTargetedSync &&
    savedIds.length > 0 &&
    typeof electronAPI.syncSingleTransactionImmediate === 'function'

  if (canTargetImmediate) {
    for (const id of savedIds) {
      try {
        const result = await electronAPI.syncSingleTransactionImmediate!(id)
        if (!result?.success) {
          immediateErrors[id] = result?.error || 'Ismeretlen hiba az azonnali könyvelésnél'
        }
      } catch (err) {
        immediateErrors[id] = err instanceof Error ? err.message : String(err)
      }
    }
  } else {
    try {
      await electronAPI.syncOffline()
    } catch {
      // Ha az azonnali szinkron nem sikerül, a lokális mentés ettől még érvényes marad.
    }
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

  // FKH-032 FR-4: a célzott kísérlet konkrét hibái elsőbbséget élveznek az összesített,
  // ciklus-szintű üzenetek felett — a felhasználó a TÉNYLEGES okot lássa.
  const immediateErrorList = Object.values(immediateErrors)
  if (immediateErrorList.length > 0) {
    syncErrors = immediateErrorList
  }

  return {
    savedIds,
    syncedCount: savedIds.length - pendingCount,
    pendingCount,
    allSavedSynced: pendingCount === 0,
    syncErrors,
    localReferenceNumbers,
    immediateErrors,
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
          approverWorkerId: entry.approverWorkerId ?? null,
          approvalSessionId: entry.approvalSessionId ?? null,
          lines: entry.lines ?? null,
          // FK-KEZDIJ offline (2026-06-12): a dij-override mezok is atmennek a queue-ba.
          handlingFeeOverrideType: normalizeOptionalText(entry.handlingFeeOverrideType),
          handlingFeeOverrideReason: normalizeOptionalText(entry.handlingFeeOverrideReason),
          customerCardNumber: normalizeOptionalText(entry.customerCardNumber),
          // V325 (Batch3-C): jogi szemely + tenyleges tulajdonosok az offline queue-ba.
          isLegalEntityCustomer: entry.isLegalEntityCustomer ?? null,
          legalEntityName: normalizeOptionalText(entry.legalEntityName),
          legalEntitySeat: normalizeOptionalText(entry.legalEntitySeat),
          legalEntityTaxNumber: normalizeOptionalText(entry.legalEntityTaxNumber),
          legalDeedNumber: normalizeOptionalText(entry.legalDeedNumber),
          beneficialOwnersJson: entry.beneficialOwnersJson ?? null,
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

    // 2026-06-04 (audit-fix): a TÉNYLEGES szigorú helyi sorszámok lekérdezése a mentett
    // ID-k alapján — a nyugta a valós (rögzített) bizonylatszámot kapja, nem fabrikált
    // P-<timestamp>-et. A lekérdezést a sync ELŐTT végezzük (a sor még biztosan elérhető;
    // a getPendingTransactionRefById szándékosan nem szűr synced-re, így sync után is jó).
    // Régi telepítő (a query-IPC nélkül) → null fallback, a renderer megőrzi a régi viselkedést.
    let localReferenceNumbers: (string | null)[] = savedIds.map(() => null)
    if (typeof electronAPI.getPendingTransactionRefById === 'function') {
      localReferenceNumbers = await Promise.all(
        savedIds.map((id) => electronAPI.getPendingTransactionRefById!(id).catch(() => null)),
      )
    }

    return finalizeSyncOutcome(
      savedIds,
      async () => {
        const pending = await electronAPI.getPendingTransactions()
        return pending.map((row) => row.id)
      },
      localReferenceNumbers,
      // FKH-032 FR-2: a vétel/eladás úton célzott, egy-tételes azonnali kísérlet fut.
      true,
    )
  })
}

export async function saveAndSyncPendingConversion(
  entry: PendingConversionInput,
): Promise<ElectronQueueSyncOutcome> {
  return safeElectronOp('saveAndSyncPendingConversion', async () => {
    const electronAPI = getElectronAPI()
    if (!electronAPI?.getPendingConversions) {
      throw new Error('Electron pending konverziós bridge nem érhető el')
    }
    // V235 + V236 (2026-05-19 Codex P1 #695): preferaljuk a V2 API-t a teljes
    // Pmt. customer-snapshot mentesehez. Ha a futtatott Electron build meg nem
    // ismeri (regi telepito), legacy fallback a regi pozicionalis API-ra.
    const hasV2 = typeof electronAPI.savePendingConversionV2 === 'function'
    if (!hasV2 && !electronAPI.savePendingConversion) {
      throw new Error('Electron pending konverziós bridge nem érhető el')
    }

    let savedId: number
    if (hasV2) {
      savedId = await electronAPI.savePendingConversionV2!({
        fromCurrencyId: entry.fromCurrencyId,
        fromCurrencyCode: entry.fromCurrencyCode,
        toCurrencyId: entry.toCurrencyId,
        toCurrencyCode: entry.toCurrencyCode,
        fromAmount: entry.fromAmount,
        calculatedHufAmount: entry.calculatedHufAmount,
        calculatedToAmount: entry.calculatedToAmount,
        conversionRate: entry.conversionRate,
        handlingFee: entry.handlingFee,
        customerId: normalizeOptionalText(entry.customerId),
        customerName: normalizeOptionalText(entry.customerName),
        customerDocumentNumber: normalizeOptionalText(entry.customerDocumentNumber),
        customerAddress: normalizeOptionalText(entry.customerAddress),
        customerNationality: normalizeOptionalText(entry.customerNationality),
        customerBirthPlace: normalizeOptionalText(entry.customerBirthPlace),
        customerBirthDate: normalizeOptionalText(entry.customerBirthDate),
        customerMotherName: normalizeOptionalText(entry.customerMotherName),
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
        foreignStatus: normalizeOptionalText(entry.foreignStatus),
        note: normalizeOptionalText(entry.note),
        approverWorkerId: entry.approverWorkerId ?? null,
        approvalSessionId: entry.approvalSessionId ?? null,
      })
    } else {
      // Legacy positional API — csak alapmezok.
      savedId = await electronAPI.savePendingConversion(
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
    }

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
      normalizeOptionalText(entry.carrierName ?? null),
      normalizeOptionalText(entry.sealNumber ?? null),
      entry.direction ?? null,
      entry.lines ?? null,
    )

    // 2026-06-04 (audit-fix, buy/sell-paritás): a TÉNYLEGES átadólap-sorszám (local_reference_number,
    // pl. AT105000042) lekérdezése a mentett ID alapján — a szállítólevél a valós (rögzített) számot
    // kapja, nem fabrikált LOCAL-<dátum>-#<id>-t. Régi telepítő (a query-IPC nélkül) → null fallback.
    let localReferenceNumbers: (string | null)[] = [null]
    if (typeof electronAPI.getPendingTransferRefById === 'function') {
      localReferenceNumbers = [
        await electronAPI.getPendingTransferRefById(savedId).catch(() => null),
      ]
    }

    return finalizeSyncOutcome(
      [savedId],
      async () => {
        const pending = await electronAPI.getPendingTransfers()
        return pending.map((row) => row.id)
      },
      localReferenceNumbers,
    )
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

    // Codex PR #1100 P2: a TÉNYLEGES helyi sztornó-referencia (local_reference_number,
    // pl. LST...) lekérdezése a sync ELŐTT — az azonnal nyomtatott offline bizonylat a
    // perzisztált/auditálható számot kapja (a reprint-listával egyezően), nem fabrikáltat.
    // A transfer-úttal azonos minta; lekérdezés-hiba → null fallback.
    let localReferenceNumbers: (string | null)[] = [null]
    try {
      const rows = await electronAPI.getPendingStornos()
      localReferenceNumbers = [
        rows.find((row) => row.id === savedId)?.local_reference_number ?? null,
      ]
    } catch {
      /* régi telepítő / IPC-hiba → null fallback */
    }

    return finalizeSyncOutcome(
      [savedId],
      async () => {
        const pending = await electronAPI.getPendingStornos()
        return pending.map((row) => row.id)
      },
      localReferenceNumbers,
    )
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
  toAmount?: number
  foreignStatus?: 'DOMESTIC' | 'FOREIGN'
  customerId?: string
  customerName?: string
  customerDocumentNumber?: string
  notes?: string
}): ConversionRequest {
  const request: ConversionRequest = {
    fromAmount: params.fromAmount,
  }

  if (params.toAmount && params.toAmount > 0) {
    request.toAmount = params.toAmount
  }
  if (params.foreignStatus) {
    request.foreignStatus = params.foreignStatus
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
