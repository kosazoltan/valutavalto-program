import { describe, it, expect } from 'vitest'
import {
  receiptTypeLabel,
  hasCustomer,
  isAmlThresholdExceeded,
  formatHuf,
  AML_10M_THRESHOLD_HUF,
} from './ReceiptPage'

// EXCMD b5b FR-BSZUR-01: a bizonylattípus-szűrő a backend Receipt.receiptType = TransactionType.name()
// enum-nevekre szűr; a megjelenítő-címkének a TransactionType.java magyar leírásaival kell egyeznie.
// Ez a teszt rögzíti a mappinget, hogy ne csússzon el (a szűrő-opció és a tábla-megjelenítés konzisztens).
describe('receiptTypeLabel (EXCMD b5b bizonylattípus)', () => {
  it('a TransactionType enum-neveket magyar címkére képezi', () => {
    expect(receiptTypeLabel('BUY')).toBe('Vétel')
    expect(receiptTypeLabel('SELL')).toBe('Eladás')
    expect(receiptTypeLabel('REVERSAL')).toBe('Sztornó')
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
