import type { BankTransaction, HandoverSheet, Transfer } from '../services/api/index'
import type { Worker } from '../stores/authStore'
import type { PrintReceiptData } from '../types/receipt'
import { getElectronAPI } from './electron'
import { logger } from './logger'

export interface PendingReceiptDraft {
  id: string
  referenceNumber: string
  entityType: 'TRANSACTION' | 'CONVERSION' | 'STORNO'
  createdAt: string
  title: string
  statusLabel: string
  canPrint: boolean
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

function getCompanyType(worker: Worker | null): 'BEST_CHANGE' | 'EXPRESSZ' {
  return worker?.companyCode?.toUpperCase().includes('BEST') ? 'BEST_CHANGE' : 'EXPRESSZ'
}

function normalizeTimestamp(value: string): string {
  return value.includes('T') ? value : value.replace(' ', 'T')
}

function toDateParts(value: string): { date: string; time: string } {
  const normalized = normalizeTimestamp(value)
  const date = new Date(normalized)
  return {
    date: Number.isNaN(date.getTime()) ? normalized.slice(0, 10) : date.toLocaleDateString('hu-HU'),
    time: Number.isNaN(date.getTime()) ? normalized.slice(11, 19) : date.toLocaleTimeString('hu-HU'),
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

export async function getPendingReceiptDrafts(worker: Worker | null): Promise<PendingReceiptDraft[]> {
  try {
    const electronAPI = getElectronAPI()
    if (!electronAPI?.getPendingTransactions || !electronAPI.getPendingConversions || !electronAPI.getPendingStornos) {
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
      const parts = toDateParts(createdAt)
      drafts.push({
        id: `tx-${row.id}`,
        referenceNumber: row.local_reference_number ?? `LOCAL-TX-${row.id}`,
        entityType: 'TRANSACTION',
        createdAt,
        title: row.type === 'BUY' ? 'Vételi vázlat' : 'Eladási vázlat',
        statusLabel: 'Helyben mentve, szinkronra vár',
        canPrint: true,
        receiptData: {
          type: row.type === 'BUY' ? 'buy' : 'sell',
          companyType: getCompanyType(worker),
          receiptNumber: row.local_reference_number ?? `LOCAL-TX-${row.id}`,
          branchCode: worker?.branchCode ?? 'LOCAL',
          cashierName: worker?.fullName ?? 'Electron queue',
          date: parts.date,
          time: parts.time,
          currencyCode: row.currency_code,
          foreignAmount: row.foreign_amount,
          rate: row.rate,
          hufAmount: row.huf_amount,
          roundedHufAmount: row.rounded_huf_amount,
          customerName: row.customer_name ?? undefined,
          customerDocNumber: row.customer_document_number ?? undefined,
        },
      })
    }

    for (const row of conversions) {
      const createdAt = normalizeTimestamp(row.created_at)
      const parts = toDateParts(createdAt)
      drafts.push({
        id: `conv-${row.id}`,
        referenceNumber: row.local_reference_number ?? `LOCAL-CONV-${row.id}`,
        entityType: 'CONVERSION',
        createdAt,
        title: 'Konverziós vázlat',
        statusLabel: 'Helyben mentve, szinkronra vár',
        canPrint: true,
        receiptData: {
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
        },
      })
    }

    for (const row of stornoRows) {
      const createdAt = normalizeTimestamp(row.created_at)
      const parts = toDateParts(createdAt)
      drafts.push({
        id: `storno-${row.id}`,
        referenceNumber: row.local_reference_number ?? `LOCAL-STORNO-${row.id}`,
        entityType: 'STORNO',
        createdAt,
        title: 'Sztornó vázlat',
        statusLabel: 'Helyben mentve, szinkronra vár',
        canPrint: true,
        receiptData: {
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
        },
      })
    }

    return drafts.sort((left, right) => right.createdAt.localeCompare(left.createdAt))
  } catch (err) {
    logger.error('localQueue', 'getPendingReceiptDrafts failed', err)
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

export async function getLocalPendingHandoverOperations(): Promise<LocalPendingHandoverOperation[]> {
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
      fromCashDeskName: cashDeskNames.get(operation.fromCashDeskId ?? '') ?? operation.fromCashDeskId ?? 'Ismeretlen',
      toCashDeskId: operation.toCashDeskId ?? '',
      toCashDeskName: cashDeskNames.get(operation.toCashDeskId ?? '') ?? operation.toCashDeskId ?? 'Ismeretlen',
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
