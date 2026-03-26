import { describe, it, expect, beforeEach } from 'vitest'
import {
  getPendingReceiptDrafts,
  printPendingReceiptDraft,
  getLocalPendingTransfers,
  getLocalPendingBankTransactions,
  getLocalPendingHandoverOperations,
  mapPendingHandoverGeneratesToSheets,
} from './localQueue'
import type { LocalPendingHandoverOperation } from './localQueue'
import type { PrintReceiptData } from '../types/receipt'

// ─── No electronAPI → all async functions return empty / false ───────────────

describe('localQueue — without electronAPI', () => {
  beforeEach(() => {
    // Ensure electronAPI is not present
    if ('electronAPI' in window) {
      delete (window as any).electronAPI
    }
  })

  it('getPendingReceiptDrafts returns []', async () => {
    const result = await getPendingReceiptDrafts(null)
    expect(result).toEqual([])
  })

  it('printPendingReceiptDraft returns false', async () => {
    const receiptData: PrintReceiptData = {
      type: 'sell',
      companyType: 'EXPRESSZ',
      receiptNumber: 'E001000001',
      branchCode: '001',
      cashierName: 'Test',
      date: '2024-01-01',
      time: '10:00:00',
    }
    const result = await printPendingReceiptDraft(receiptData)
    expect(result).toBe(false)
  })

  it('getLocalPendingTransfers returns []', async () => {
    const result = await getLocalPendingTransfers(null)
    expect(result).toEqual([])
  })

  it('getLocalPendingBankTransactions returns []', async () => {
    const result = await getLocalPendingBankTransactions()
    expect(result).toEqual([])
  })

  it('getLocalPendingHandoverOperations returns []', async () => {
    const result = await getLocalPendingHandoverOperations()
    expect(result).toEqual([])
  })
})

// ─── mapPendingHandoverGeneratesToSheets ────────────────────────────────────

describe('mapPendingHandoverGeneratesToSheets', () => {
  const cashDeskNames = new Map([
    ['desk-1', 'Pénztár 1'],
    ['desk-2', 'Pénztár 2'],
  ])

  const generateOp: LocalPendingHandoverOperation = {
    id: 'handover-1',
    operationType: 'GENERATE',
    sheetId: null,
    fromCashDeskId: 'desk-1',
    toCashDeskId: 'desk-2',
    transferDate: '2024-01-15',
    amounts: { EUR: 1000, USD: 500 },
    note: 'Teszt',
    referenceNumber: 'LOCAL-HANDOVER-1',
    createdAt: '2024-01-15T10:00:00',
  }

  const printOp: LocalPendingHandoverOperation = {
    ...generateOp,
    id: 'handover-2',
    operationType: 'PRINT',
    referenceNumber: 'LOCAL-HANDOVER-2',
  }

  it('maps GENERATE operations to HandoverSheets', () => {
    const sheets = mapPendingHandoverGeneratesToSheets([generateOp], cashDeskNames)
    expect(sheets).toHaveLength(1)
    expect(sheets[0]!.id).toBe('handover-1')
    expect(sheets[0]!.sheetNumber).toBe('LOCAL-HANDOVER-1')
    expect(sheets[0]!.fromCashDeskName).toBe('Pénztár 1')
    expect(sheets[0]!.toCashDeskName).toBe('Pénztár 2')
    expect(sheets[0]!.amounts).toEqual({ EUR: 1000, USD: 500 })
    expect(sheets[0]!.status).toBe('PENDING_SYNC')
    expect(sheets[0]!.notes).toBe('Teszt')
    expect(sheets[0]!.transferDate).toBe('2024-01-15')
  })

  it('filters out non-GENERATE operations', () => {
    const sheets = mapPendingHandoverGeneratesToSheets([printOp], cashDeskNames)
    expect(sheets).toHaveLength(0)
  })

  it('handles empty operations array', () => {
    const sheets = mapPendingHandoverGeneratesToSheets([], cashDeskNames)
    expect(sheets).toEqual([])
  })

  it('uses cashDesk id as name fallback when not in map', () => {
    const emptyMap = new Map<string, string>()
    const sheets = mapPendingHandoverGeneratesToSheets([generateOp], emptyMap)
    expect(sheets[0]!.fromCashDeskName).toBe('desk-1')
    expect(sheets[0]!.toCashDeskName).toBe('desk-2')
  })

  it('uses "Ismeretlen" when fromCashDeskId is null', () => {
    const op: LocalPendingHandoverOperation = {
      ...generateOp,
      fromCashDeskId: null,
      toCashDeskId: null,
    }
    const sheets = mapPendingHandoverGeneratesToSheets([op], cashDeskNames)
    expect(sheets[0]!.fromCashDeskName).toBe('Ismeretlen')
    expect(sheets[0]!.toCashDeskName).toBe('Ismeretlen')
  })

  it('falls back transferDate to createdAt slice when null', () => {
    const op: LocalPendingHandoverOperation = {
      ...generateOp,
      transferDate: null,
      createdAt: '2024-06-01T09:00:00',
    }
    const sheets = mapPendingHandoverGeneratesToSheets([op], cashDeskNames)
    expect(sheets[0]!.transferDate).toBe('2024-06-01')
  })

  it('createdByName is always "Electron queue"', () => {
    const sheets = mapPendingHandoverGeneratesToSheets([generateOp], cashDeskNames)
    expect(sheets[0]!.createdByName).toBe('Electron queue')
  })
})
