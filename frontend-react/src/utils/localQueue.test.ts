import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import {
  getPendingReceiptDrafts,
  getReprintableReceiptDrafts,
  printPendingReceiptDraft,
  getLocalPendingTransfers,
  getLocalPendingBankTransactions,
  getLocalPendingHandoverOperations,
  mapPendingHandoverGeneratesToSheets,
} from './localQueue'
import type { LocalPendingHandoverOperation } from './localQueue'
import type { PrintReceiptData } from '../types/receipt'
import type { Worker } from '../stores/authStore'
import { multiLinePayable } from './rounding'

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

  it('getReprintableReceiptDrafts returns []', async () => {
    const result = await getReprintableReceiptDrafts(null)
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

// ─── getReprintableReceiptDrafts — fizikai újranyomtatás (Codex P2 #1035) ────────

describe('getReprintableReceiptDrafts — with electronAPI', () => {
  const worker = {
    fullName: 'Teszt Pénztáros',
    branchCode: 'BR105',
    companyCode: 'BEST',
  } as unknown as Worker

  afterEach(() => {
    if ('electronAPI' in window) {
      delete (window as any).electronAPI
    }
  })

  function installElectronAPI(overrides: {
    transactions?: unknown[]
    conversions?: unknown[]
    stornos?: unknown[]
  }) {
    ;(window as any).electronAPI = {
      getReprintableTransactions: async () => overrides.transactions ?? [],
      getReprintableConversions: async () => overrides.conversions ?? [],
      getReprintableStornos: async () => overrides.stornos ?? [],
    }
  }

  it('maps a single-line synced transaction to a reprintable draft', async () => {
    installElectronAPI({
      transactions: [{
        id: 7,
        type: 'BUY',
        currency_code: 'EUR',
        foreign_amount: 100,
        huf_amount: 39000,
        rounded_huf_amount: 39000,
        rate: 390,
        handling_fee: null,
        discount_percent: null,
        customer_name: 'Nagy Anna',
        customer_document_number: 'AB123456',
        lines: null,
        local_reference_number: 'V105000042',
        created_at: '2026-06-04 10:15:00',
        synced: 1,
      }],
    })

    const result = await getReprintableReceiptDrafts(worker)
    expect(result).toHaveLength(1)
    const draft = result[0]!
    expect(draft.reprint).toBe(true)
    expect(draft.entityType).toBe('TRANSACTION')
    expect(draft.referenceNumber).toBe('V105000042')
    expect(draft.title).toBe('Vételi bizonylat')
    expect(draft.receiptData.type).toBe('buy')
    expect(draft.receiptData.companyType).toBe('BEST_CHANGE')
    expect(draft.receiptData.receiptNumber).toBe('V105000042')
    expect(draft.receiptData.currencyCode).toBe('EUR')
    expect(draft.receiptData.foreignAmount).toBe(100)
    expect(draft.receiptData.rate).toBe(390)
    expect(draft.receiptData.hufAmount).toBe(39000)
    expect(draft.receiptData.transactionLines).toBeUndefined()
    expect(draft.receiptData.customerName).toBe('Nagy Anna')
  })

  it('reconstructs the full line set + aggregate total for a multi-line synced transaction', async () => {
    // A `lines` oszlop a backend TransactionLineRequestDto alakjában tárolódik. A tárolt sor
    // huf_amount-ja a fejléc ELSŐ sorának értéke (NEM az aggregátum) → a teljes fizetendőt a
    // lines-ból kell rekonstruálni (multiLinePayable), pontosan ahogy a pont-of-sale teszi.
    const lines = [
      { currencyCode: 'EUR', banknoteCount: 100, customExchangeRate: 390, discountType: 0, foreignStatus: 'DOMESTIC' },
      { currencyCode: 'USD', banknoteCount: 200, customExchangeRate: 360, discountType: 0, foreignStatus: 'DOMESTIC' },
    ]
    installElectronAPI({
      transactions: [{
        id: 9,
        type: 'SELL',
        currency_code: 'EUR',
        foreign_amount: 100,
        huf_amount: 39000, // csak az első sor — NEM az aggregátum
        rounded_huf_amount: 39000,
        rate: 390,
        handling_fee: 500,
        discount_percent: 2,
        customer_name: null,
        customer_document_number: null,
        lines: JSON.stringify(lines),
        local_reference_number: 'E105000099',
        created_at: '2026-06-04 11:00:00',
        synced: 1,
      }],
    })

    const result = await getReprintableReceiptDrafts(worker)
    expect(result).toHaveLength(1)
    const rd = result[0]!.receiptData
    expect(rd.type).toBe('sell')
    expect(rd.transactionLines).toHaveLength(2)
    expect(rd.transactionLines![0]).toEqual({ currencyCode: 'EUR', foreignAmount: 100, rate: 390, hufAmount: 39000 })
    expect(rd.transactionLines![1]).toEqual({ currencyCode: 'USD', foreignAmount: 200, rate: 360, hufAmount: 72000 })

    const totalRaw = 100 * 390 + 200 * 360 // 111000
    const expectedPayable = multiLinePayable(totalRaw, 'sell', 2, 500)
    expect(rd.hufAmount).toBe(expectedPayable)
    expect(rd.roundedHufAmount).toBe(expectedPayable)
    expect(rd.roundingDiff).toBe(0)
    // Codex P2: a kezelési díj MÁR a payable-ben van — NEM adjuk át külön handlingFee-ként,
    // különben a ReceiptPreviewModal (paid = roundedHufAmount + handlingFee) duplán számolná.
    expect(rd.handlingFee).toBeUndefined()
  })

  it('falls back to single-line stored values when lines JSON has invalid numeric entries', async () => {
    // Copilot P2: hibás (nem véges) banknoteCount/customExchangeRate → a teljes payload érvénytelen,
    // így a tárolt egysoros (ismert-jó) értékekre esünk vissza, NEM 0-értékű hibás sorokra.
    installElectronAPI({
      transactions: [{
        id: 11,
        type: 'BUY',
        currency_code: 'EUR',
        foreign_amount: 100,
        huf_amount: 39000,
        rounded_huf_amount: 39000,
        rate: 390,
        handling_fee: null,
        discount_percent: null,
        customer_name: null,
        customer_document_number: null,
        lines: JSON.stringify([{ currencyCode: 'EUR', banknoteCount: 'NEM_SZAM', customExchangeRate: 390 }]),
        local_reference_number: 'V105000111',
        created_at: '2026-06-04 10:30:00',
        synced: 1,
      }],
    })

    const result = await getReprintableReceiptDrafts(worker)
    expect(result).toHaveLength(1)
    const rd = result[0]!.receiptData
    expect(rd.transactionLines).toBeUndefined()
    expect(rd.currencyCode).toBe('EUR')
    expect(rd.foreignAmount).toBe(100)
    expect(rd.hufAmount).toBe(39000)
  })

  it('maps synced conversions and stornos with reprint flag', async () => {
    installElectronAPI({
      conversions: [{
        id: 3,
        from_currency_code: 'EUR',
        to_currency_code: 'USD',
        from_amount: 100,
        calculated_huf_amount: 39000,
        calculated_to_amount: 108,
        conversion_rate: 1.08,
        customer_name: null,
        customer_document_number: null,
        note: 'teszt',
        local_reference_number: 'K105000001',
        created_at: '2026-06-04 09:00:00',
        synced: 1,
      }],
      stornos: [{
        id: 4,
        original_receipt_number: 'V105000010',
        currency_code: 'EUR',
        foreign_amount: 50,
        huf_amount: 19500,
        exchange_rate: 390,
        custom_exchange_rate: null,
        reason: 'téves rögzítés',
        customer_name: null,
        customer_document_number: null,
        local_reference_number: 'S105000002',
        created_at: '2026-06-04 12:00:00',
        synced: 1,
      }],
    })

    const result = await getReprintableReceiptDrafts(worker)
    expect(result).toHaveLength(2)
    // DESC sorrend created_at szerint → a storno (12:00) az első.
    const storno = result.find((d) => d.entityType === 'STORNO')!
    expect(storno.reprint).toBe(true)
    expect(storno.receiptData.type).toBe('storno')
    expect(storno.receiptData.originalReceiptNumber).toBe('V105000010')
    expect(storno.receiptData.stornoReason).toBe('téves rögzítés')
    const conv = result.find((d) => d.entityType === 'CONVERSION')!
    expect(conv.reprint).toBe(true)
    expect(conv.receiptData.type).toBe('conversion')
    expect(conv.receiptData.sourceCurrencyCode).toBe('EUR')
    expect(conv.receiptData.targetCurrencyCode).toBe('USD')
  })

  it('returns [] when only some reprint APIs are present (old installer)', async () => {
    ;(window as any).electronAPI = {
      getReprintableTransactions: async () => [],
      // getReprintableConversions / getReprintableStornos hiányoznak → graceful []
    }
    const result = await getReprintableReceiptDrafts(worker)
    expect(result).toEqual([])
  })
})
