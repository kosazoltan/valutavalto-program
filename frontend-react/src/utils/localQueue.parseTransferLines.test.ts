import { describe, it, expect, vi } from 'vitest'
import { parseTransferLines } from './localQueue'

vi.mock('../utils/logger', () => ({
  logger: { error: vi.fn(), warn: vi.fn(), info: vi.fn() },
}))

/**
 * Penztar-batch A.1 (2026-06-12): a pending_transfers.lines JSON → Transfer.lines
 * parzolása — a több-valutás átadólap offline listázásához.
 */
describe('parseTransferLines', () => {
  it('érvényes több-soros JSON → sorok currencyCode-dal', () => {
    const raw = JSON.stringify([
      { currencyId: 1, amount: 100, currencyCode: 'EUR' },
      { currencyId: 2, amount: 10, currencyCode: 'USD' },
    ])
    expect(parseTransferLines(raw)).toEqual([
      { currencyId: 1, amount: 100, currencyCode: 'EUR' },
      { currencyId: 2, amount: 10, currencyCode: 'USD' },
    ])
  })

  it('régi (kód nélküli) sorok is átmennek — currencyCode undefined', () => {
    const raw = JSON.stringify([{ currencyId: 1, amount: 100 }])
    expect(parseTransferLines(raw)).toEqual([
      { currencyId: 1, amount: 100, currencyCode: undefined },
    ])
  })

  it('hiányzó / üres / hibás JSON → undefined (nem dob)', () => {
    expect(parseTransferLines(null)).toBeUndefined()
    expect(parseTransferLines(undefined)).toBeUndefined()
    expect(parseTransferLines('')).toBeUndefined()
    expect(parseTransferLines('{törött')).toBeUndefined()
    expect(parseTransferLines('[]')).toBeUndefined()
    expect(parseTransferLines('"nem tomb"')).toBeUndefined()
  })

  it('érvénytelen sorokat kiszűri (hiányzó currencyId/amount)', () => {
    const raw = JSON.stringify([
      { currencyId: 1, amount: 100 },
      { currencyId: 'rossz', amount: 5 },
      { amount: 7 },
    ])
    expect(parseTransferLines(raw)).toEqual([
      { currencyId: 1, amount: 100, currencyCode: undefined },
    ])
  })
})
