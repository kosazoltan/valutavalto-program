import { describe, it, expect } from 'vitest'
import { receiptTypeLabel } from './ReceiptPage'

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
