import { describe, it, expect } from 'vitest'
import {
  receiptTypeLabel,
  hasCustomer,
  isAmlThresholdExceeded,
  formatHuf,
  matchesPeriod,
  periodToBackendRange,
  matchesCustomerFilters,
  hasActiveCustomerFilter,
  isCancelledTransactionReceipt,
  buildCancelledTransactionPrintData,
  CUSTOMER_FILTER_FIELDS,
  AML_10M_THRESHOLD_HUF,
} from './ReceiptPage'
import type { Receipt } from '../../services/api/transactions'
import type { Worker } from '../../stores/authStore'

// EXCMD b5b FR-BSZUR-01: a bizonylattípus-szűrő a backend Receipt.receiptType = TransactionType.name()
// enum-nevekre szűr; a megjelenítő-címkének a TransactionType.java magyar leírásaival kell egyeznie.
// Ez a teszt rögzíti a mappinget, hogy ne csússzon el (a szűrő-opció és a tábla-megjelenítés konzisztens).
describe('receiptTypeLabel (EXCMD b5b bizonylattípus)', () => {
  it('a TransactionType enum-neveket magyar címkére képezi', () => {
    expect(receiptTypeLabel('BUY')).toBe('Vétel')
    expect(receiptTypeLabel('SELL')).toBe('Eladás')
    expect(receiptTypeLabel('REVERSAL')).toBe('Sztornó')
    expect(receiptTypeLabel('CANCELLED_TRANSACTION')).toBe('Megszakított tranzakció')
    expect(receiptTypeLabel('CONVERSION')).toBe('Konverzió')
    expect(receiptTypeLabel('TRANSFER_OUT')).toBe('Pénz-átadás')
    expect(receiptTypeLabel('TRANSFER_IN')).toBe('Pénz-átvétel')
  })

  it('case-insensitive, ismeretlen → nyers kód, üres → "—"', () => {
    expect(receiptTypeLabel('buy')).toBe('Vétel')
    expect(receiptTypeLabel('ISMERETLEN_XYZ')).toBe('ISMERETLEN_XYZ')
    expect(receiptTypeLabel(undefined)).toBe('—')
    expect(receiptTypeLabel('')).toBe('—')
  })
})

// EXCMD b5b FR-BSZUR-02: "csak ügyfeles" szűrő-predikátum — ügyfél-jelenlétre szűr (nem típusra).
describe('hasCustomer (EXCMD b5b FR-BSZUR-02 "csak ügyfeles")', () => {
  it('kitöltött névre true', () => {
    expect(hasCustomer('Kovács János')).toBe(true)
  })
  it('üres / whitespace / hiányzó névre false', () => {
    expect(hasCustomer('')).toBe(false)
    expect(hasCustomer('   ')).toBe(false)
    expect(hasCustomer(undefined)).toBe(false)
    expect(hasCustomer(null)).toBe(false)
  })
})

// EXCMD b5b FR-BSZUR-05: 10 M Ft AML-küszöb jelölő — a küszöböt elérő/meghaladó összegek jelöltek.
describe('isAmlThresholdExceeded (EXCMD b5b FR-BSZUR-05 10M Ft)', () => {
  it('a küszöb 10 000 000 Ft', () => {
    expect(AML_10M_THRESHOLD_HUF).toBe(10_000_000)
  })
  it('pontosan a küszöbön és felette true (>= reláció)', () => {
    expect(isAmlThresholdExceeded(10_000_000)).toBe(true)
    expect(isAmlThresholdExceeded(15_000_000)).toBe(true)
  })
  it('küszöb alatt false', () => {
    expect(isAmlThresholdExceeded(9_999_999)).toBe(false)
    expect(isAmlThresholdExceeded(0)).toBe(false)
  })
  it('hiányzó / nem-szám érték false (defenzív)', () => {
    expect(isAmlThresholdExceeded(undefined)).toBe(false)
    expect(isAmlThresholdExceeded(null)).toBe(false)
    expect(isAmlThresholdExceeded(NaN)).toBe(false)
  })
})

describe('formatHuf (EXCMD b5b hu-HU összegformázás)', () => {
  it('ezres csoportosítás, tört nélkül', () => {
    // hu-HU ezres elválasztó NBSP / keskeny szóköz — a számjegyek és a "10000000" hiánya a lényeg.
    const formatted = formatHuf(10_000_000)
    expect(formatted.replace(/\D/g, '')).toBe('10000000')
  })
  it('hiányzó érték → "—"', () => {
    expect(formatHuf(undefined)).toBe('—')
    expect(formatHuf(null)).toBe('—')
    expect(formatHuf(NaN)).toBe('—')
  })
})

describe('matchesPeriod (EXCMD b5b FR-BSZUR-02 hatókör/időszak)', () => {
  it('ALL: minden dátum átmegy (üres/hiányos is)', () => {
    expect(matchesPeriod('2026-04-29', 'ALL', '2026-04', '', '')).toBe(true)
    expect(matchesPeriod(undefined, 'ALL', '', '', '')).toBe(true)
    expect(matchesPeriod('', 'ALL', '', '', '')).toBe(true)
  })

  it('MONTH: csak az adott naptári hónap bizonylatai (YYYY-MM)', () => {
    expect(matchesPeriod('2026-04-29', 'MONTH', '2026-04', '', '')).toBe(true)
    expect(matchesPeriod('2026-04-01', 'MONTH', '2026-04', '', '')).toBe(true)
    expect(matchesPeriod('2026-05-01', 'MONTH', '2026-04', '', '')).toBe(false)
    expect(matchesPeriod('2026-03-31', 'MONTH', '2026-04', '', '')).toBe(false)
    // ISO timestamp esetén is a nap eleje (első 7 kar.) számít
    expect(matchesPeriod('2026-04-29T10:30:00Z', 'MONTH', '2026-04', '', '')).toBe(true)
  })

  it('MONTH üres hónappal → minden átmegy (nincs szűkítés)', () => {
    expect(matchesPeriod('2026-04-29', 'MONTH', '', '', '')).toBe(true)
  })

  it('CUSTOM: inkluzív dátumtartomány (tól-ig)', () => {
    expect(matchesPeriod('2026-04-10', 'CUSTOM', '', '2026-04-10', '2026-04-20')).toBe(true) // alsó határ inkluzív
    expect(matchesPeriod('2026-04-20', 'CUSTOM', '', '2026-04-10', '2026-04-20')).toBe(true) // felső határ inkluzív
    expect(matchesPeriod('2026-04-15', 'CUSTOM', '', '2026-04-10', '2026-04-20')).toBe(true)
    expect(matchesPeriod('2026-04-09', 'CUSTOM', '', '2026-04-10', '2026-04-20')).toBe(false)
    expect(matchesPeriod('2026-04-21', 'CUSTOM', '', '2026-04-10', '2026-04-20')).toBe(false)
  })

  it('CUSTOM: nyitott végek (csak tól / csak ig / egyik sem)', () => {
    expect(matchesPeriod('2026-12-31', 'CUSTOM', '', '2026-04-10', '')).toBe(true)  // csak tól
    expect(matchesPeriod('2026-01-01', 'CUSTOM', '', '2026-04-10', '')).toBe(false)
    expect(matchesPeriod('2026-01-01', 'CUSTOM', '', '', '2026-04-20')).toBe(true)  // csak ig
    expect(matchesPeriod('2026-12-31', 'CUSTOM', '', '', '2026-04-20')).toBe(false)
    expect(matchesPeriod('2026-06-15', 'CUSTOM', '', '', '')).toBe(true)            // egyik sem → minden átmegy
  })

  it('nem-ALL módban a hiányzó/rövid dátum NEM esik bele (defenzív)', () => {
    expect(matchesPeriod(undefined, 'MONTH', '2026-04', '', '')).toBe(false)
    expect(matchesPeriod(null, 'CUSTOM', '', '2026-04-10', '')).toBe(false)
    expect(matchesPeriod('20', 'MONTH', '2026-04', '', '')).toBe(false)
  })

  it('CUSTOM: csonka "YYYY-MM" (7 kar.) NEM csúszhat át a tartomány-összehasonlításon (Copilot)', () => {
    // 7 karakteres érték korábban a prefix-egyezés miatt félreesett volna; most defenzíven kizárt.
    expect(matchesPeriod('2026-04', 'CUSTOM', '', '2026-04-10', '2026-04-20')).toBe(false)
  })
})

describe('periodToBackendRange (EXCMD b5b FR-BSZUR-02 backend from/to)', () => {
  it('ALL → üres (nincs backend dátum-szűrés)', () => {
    expect(periodToBackendRange('ALL', '2026-04', '2026-04-10', '2026-04-20')).toEqual({})
  })

  it('MONTH → a hónap első/utolsó napja (tényleges hónaphossz)', () => {
    expect(periodToBackendRange('MONTH', '2026-04', '', '')).toEqual({ from: '2026-04-01', to: '2026-04-30' })
    expect(periodToBackendRange('MONTH', '2026-02', '', '')).toEqual({ from: '2026-02-01', to: '2026-02-28' }) // 2026 nem szökőév
    expect(periodToBackendRange('MONTH', '2024-02', '', '')).toEqual({ from: '2024-02-01', to: '2024-02-29' }) // 2024 szökőév
    expect(periodToBackendRange('MONTH', '2026-12', '', '')).toEqual({ from: '2026-12-01', to: '2026-12-31' })
  })

  it('MONTH üres hónappal → üres (nincs szűrés)', () => {
    expect(periodToBackendRange('MONTH', '', '', '')).toEqual({})
  })

  it('CUSTOM → from/to átadva, üres vég → undefined (nyitott)', () => {
    expect(periodToBackendRange('CUSTOM', '', '2026-04-10', '2026-04-20')).toEqual({ from: '2026-04-10', to: '2026-04-20' })
    expect(periodToBackendRange('CUSTOM', '', '2026-04-10', '')).toEqual({ from: '2026-04-10', to: undefined })
    expect(periodToBackendRange('CUSTOM', '', '', '2026-04-20')).toEqual({ from: undefined, to: '2026-04-20' })
    expect(periodToBackendRange('CUSTOM', '', '', '')).toEqual({ from: undefined, to: undefined })
  })
})

describe('matchesCustomerFilters / hasActiveCustomerFilter (EXCMD b5b FR-BSZUR-03)', () => {
  const base: Receipt = {
    id: '1', receiptNumber: 'V017000001', receiptType: 'BUY', issueDate: '2026-04-29', isPrinted: true,
    customerName: 'Kovács János', customerMotherName: 'Nagy Erzsébet', customerBirthPlace: 'Budapest',
    customerBirthDate: '1985-03-12', customerNationality: 'magyar', customerAddress: '1011 Budapest, Fő utca 1.',
    customerDocumentType: 'Személyi igazolvány', customerDocumentNumber: 'AB123456',
  }

  it('üres szűrő → minden átmegy', () => {
    expect(matchesCustomerFilters(base, {})).toBe(true)
    expect(hasActiveCustomerFilter({})).toBe(false)
  })

  it('egy mező részleges egyezése (kis/nagybetű-érzéketlen)', () => {
    expect(matchesCustomerFilters(base, { customerName: 'kovács' })).toBe(true)
    expect(matchesCustomerFilters(base, { customerName: 'KOV' })).toBe(true)
    expect(matchesCustomerFilters(base, { customerName: 'Szabó' })).toBe(false)
  })

  it('több mező = ÉS-kapcsolat', () => {
    expect(matchesCustomerFilters(base, { customerName: 'kovács', customerNationality: 'magyar' })).toBe(true)
    expect(matchesCustomerFilters(base, { customerName: 'kovács', customerNationality: 'német' })).toBe(false)
  })

  it('születési idő részleges (hónap-előtag) is egyezik', () => {
    expect(matchesCustomerFilters(base, { customerBirthDate: '1985-03' })).toBe(true)
    expect(matchesCustomerFilters(base, { customerBirthDate: '1990' })).toBe(false)
  })

  it('hiányzó mezőre szűrve NEM egyezik (üres adatlap-mező)', () => {
    const noDoc: Receipt = { ...base, customerDocumentNumber: undefined }
    expect(matchesCustomerFilters(noDoc, { customerDocumentNumber: 'AB' })).toBe(false)
  })

  it('whitespace-only szűrőérték → nem szűkít / nem aktív', () => {
    expect(matchesCustomerFilters(base, { customerName: '   ' })).toBe(true)
    expect(hasActiveCustomerFilter({ customerName: '   ' })).toBe(false)
  })

  it('hasActiveCustomerFilter true, ha legalább egy mező kitöltött', () => {
    expect(hasActiveCustomerFilter({ customerAddress: 'Budapest' })).toBe(true)
  })

  it('a 8 FR-BSZUR-03 mező definiált (LEÁNYKORI NEVE nélkül)', () => {
    expect(CUSTOMER_FILTER_FIELDS.map((f) => f.key)).toEqual([
      'customerName', 'customerMotherName', 'customerBirthPlace', 'customerBirthDate',
      'customerNationality', 'customerAddress', 'customerDocumentType', 'customerDocumentNumber',
    ])
  })
})

describe('buildCancelledTransactionPrintData (MEGSEM fizikai nyomtatás)', () => {
  const worker: Worker = {
    id: 7,
    workerCode: 'P001',
    firstName: 'Teszt',
    lastName: 'Erika',
    fullName: 'Teszt Erika',
    role: 'CASHIER',
    branchId: 'BR01',
    branchCode: 'SZG-01',
    branchName: 'Szeged',
    companyId: 'C1',
    companyCode: 'EBC',
    companyName: 'Exclusive Best Change Zrt.',
  }

  const cancelledReceipt: Receipt = {
    id: 'cancelled-1',
    receiptNumber: 'M-20260609-101530-ABC12345',
    receiptType: 'CANCELLED_TRANSACTION',
    issueDate: '2026-06-09T10:15:30',
    isPrinted: false,
    content: JSON.stringify({
      receiptNumber: 'M-20260609-101530-ABC12345',
      mode: 'SELL',
      reason: 'MEGSEM',
      cancelledAt: '2026-06-09T10:15:30',
      workerCode: 'P001',
      customerName: 'Kovács János',
      customerDocumentNumber: 'AB123456',
      lines: [
        { currencyCode: 'EUR', foreignAmount: 100, rate: 400, hufAmount: 40000 },
        { currencyCode: 'USD', foreignAmount: 100, rate: 300, hufAmount: 30000 },
      ],
    }),
  }

  it('felismeri a megszakított tranzakció bizonylatot', () => {
    expect(isCancelledTransactionReceipt(cancelledReceipt)).toBe(true)
    expect(isCancelledTransactionReceipt({ ...cancelledReceipt, receiptType: 'SELL' })).toBe(false)
  })

  it('szerveres Receipt.content JSON-ból nyomtatható PrintReceiptData-t képez', () => {
    const data = buildCancelledTransactionPrintData(cancelledReceipt, worker)

    expect(data).not.toBeNull()
    expect(data?.type).toBe('cancelled_transaction')
    expect(data?.companyType).toBe('BEST_CHANGE')
    expect(data?.receiptNumber).toBe('M-20260609-101530-ABC12345')
    expect(data?.branchCode).toBe('SZG-01')
    expect(data?.cashierName).toBe('Teszt Erika')
    expect(data?.customerName).toBe('Kovács János')
    expect(data?.customerDocNumber).toBe('AB123456')
    expect(data?.transactionLines).toHaveLength(2)
    expect(data?.hufAmount).toBe(70000)
    expect(data?.roundedHufAmount).toBe(70000)
    expect(data?.stornoReason).toBe('MEGSEM')
    expect(data?.note).toContain('Pénzmozgás nem történt')
  })

  it('sérült vagy hiányos tartalmat nem enged nyomtatható adatként tovább', () => {
    expect(buildCancelledTransactionPrintData({ ...cancelledReceipt, content: '{bad-json' }, worker)).toBeNull()
    expect(buildCancelledTransactionPrintData({ ...cancelledReceipt, content: JSON.stringify({ lines: [] }) }, worker)).toBeNull()
    expect(buildCancelledTransactionPrintData({ ...cancelledReceipt, receiptType: 'BUY' }, worker)).toBeNull()
  })
})
