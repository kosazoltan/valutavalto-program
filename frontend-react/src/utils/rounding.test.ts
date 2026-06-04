import { describe, it, expect } from 'vitest'
import { roundHuf, multiLinePayable } from './rounding'

describe('roundHuf', () => {
  // Utolsó számjegy 0, 5 — marad
  it('ends in 0 — unchanged', () => {
    expect(roundHuf(1000)).toBe(1000)
    expect(roundHuf(1005)).toBe(1005)
    expect(roundHuf(0)).toBe(0)
  })

  // Utolsó számjegy 1, 2 — lefelé 0-ra
  it('ends in 1 → rounds down to 0', () => {
    expect(roundHuf(1001)).toBe(1000)
  })
  it('ends in 2 → rounds down to 0', () => {
    expect(roundHuf(1002)).toBe(1000)
  })

  // Utolsó számjegy 3, 4 — felfelé 5-re
  it('ends in 3 → rounds up to 5', () => {
    expect(roundHuf(1003)).toBe(1005)
  })
  it('ends in 4 → rounds up to 5', () => {
    expect(roundHuf(1004)).toBe(1005)
    expect(roundHuf(1234)).toBe(1235)
  })

  // Utolsó számjegy 6, 7 — lefelé 5-re
  it('ends in 6 → rounds down to 5', () => {
    expect(roundHuf(1006)).toBe(1005)
  })
  it('ends in 7 → rounds down to 5', () => {
    expect(roundHuf(1007)).toBe(1005)
  })

  // Utolsó számjegy 8, 9 — felfelé 10-re
  it('ends in 8 → rounds up to 10', () => {
    expect(roundHuf(1008)).toBe(1010)
  })
  it('ends in 9 → rounds up to 10', () => {
    expect(roundHuf(1009)).toBe(1010)
  })

  // Negatív számok
  it('negative: -1233 → -1235', () => {
    expect(roundHuf(-1233)).toBe(-1235)
  })
  it('negative: -1008 → -1010', () => {
    expect(roundHuf(-1008)).toBe(-1010)
  })
  it('negative: -1001 → -1000', () => {
    expect(roundHuf(-1001)).toBe(-1000)
  })
  it('negative: -1005 → -1005', () => {
    expect(roundHuf(-1005)).toBe(-1005)
  })

  // Nagy számok
  it('large number 999998 → 1000000', () => {
    expect(roundHuf(999998)).toBe(1000000)
  })
  it('large number 1000003 → 1000005', () => {
    expect(roundHuf(1000003)).toBe(1000005)
  })

  // Float bemenetek (Math.round kereken kezeli)
  it('float 1233.6 → 1235 (rounded to 1234 first, then HUF rounded)', () => {
    expect(roundHuf(1233.6)).toBe(1235)
  })
  it('float 1233.3 → 1235', () => {
    expect(roundHuf(1233.3)).toBe(1235)
  })

  // Határértékek
  it('1 → 0', () => expect(roundHuf(1)).toBe(0))
  it('2 → 0', () => expect(roundHuf(2)).toBe(0))
  it('3 → 5', () => expect(roundHuf(3)).toBe(5))
  it('4 → 5', () => expect(roundHuf(4)).toBe(5))
  it('5 → 5', () => expect(roundHuf(5)).toBe(5))
  it('6 → 5', () => expect(roundHuf(6)).toBe(5))
  it('7 → 5', () => expect(roundHuf(7)).toBe(5))
  it('8 → 10', () => expect(roundHuf(8)).toBe(10))
  it('9 → 10', () => expect(roundHuf(9)).toBe(10))
})

describe('multiLinePayable — backend TransactionMultiLineService képlet tükrözése', () => {
  // BUY: payable = roundHuf( (totalRaw + totalRaw*disc%) - handlingFee )
  // (applyBuyDiscount ADD + calculateBuyGross SUBTRACT fee)
  it('buy: nincs díj/kedvezmény → nyers összeg 5 Ft-ra kerekítve', () => {
    expect(multiLinePayable(100000, 'buy', 0, 0)).toBe(100000)
    expect(multiLinePayable(100003, 'buy', 0, 0)).toBe(100005)
  })
  it('buy: 10% kedvezmény + 500 díj (backend: 110000 - 500 = 109500)', () => {
    expect(multiLinePayable(100000, 'buy', 10, 500)).toBe(109500)
  })
  it('buy: csak kezelési díj (a cég levonja)', () => {
    expect(multiLinePayable(100000, 'buy', 0, 500)).toBe(99500)
  })

  // SELL: payable = roundHuf( (totalRaw - totalRaw*disc%) + handlingFee )
  // (applySellDiscount SUBTRACT + calculateSellGross ADD fee)
  it('sell: 10% kedvezmény + 500 díj (backend: 90000 + 500 = 90500)', () => {
    expect(multiLinePayable(100000, 'sell', 10, 500)).toBe(90500)
  })
  it('sell: csak kezelési díj (hozzáadva)', () => {
    expect(multiLinePayable(100000, 'sell', 0, 500)).toBe(100500)
  })

  // A diszkont-tag a backend HALF_UP, 0 tizedes kerekítését tükrözi, majd EGYSZER 5 Ft kerekítés.
  it('buy: a diszkont HALF_UP kerekül, a végösszeg EGYSZER 5 Ft-ra', () => {
    // totalRaw=100001, 1% → disc=round(1000.01)=1000 → net=101001 → gross=101001 → roundHuf=101000
    expect(multiLinePayable(100001, 'buy', 1, 0)).toBe(101000)
  })
})
