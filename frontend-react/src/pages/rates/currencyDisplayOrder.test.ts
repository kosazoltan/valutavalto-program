import { describe, it, expect } from 'vitest'
import { sortByDisplayOrder } from './currencyDisplayOrder'

/**
 * FK04 (FR-4): a munkacsoport-lap valuta-rendezése a currency tábla displayOrder
 * mezőjéből — a hard-coded MAIN_SHEET_CURRENCY_ORDER kiváltása.
 */
const row = (currencyCode: string, displayOrder?: number | null) => ({ currencyCode, displayOrder })

describe('FK04 — sortByDisplayOrder', () => {
  it('currencies_sorted_by_display_order: displayOrder szerint növekvő', () => {
    const input = [row('TRY', 16), row('EUR', 1), row('RUB', 14), row('USD', 2)]
    expect(sortByDisplayOrder(input).map((r) => r.currencyCode)).toEqual([
      'EUR',
      'USD',
      'RUB',
      'TRY',
    ])
  })

  it('eua_appears_between_rub_and_try: az EUA (15) a RUB (14) és TRY (16) közé kerül', () => {
    // A backend getRateOverview az EUA-t (inaktív törzs) a lista VÉGÉRE fűzi —
    // a kliens-rendezésnek kell a kanonikus 15. helyre tennie.
    const backendOrder = [
      row('EUR', 1),
      row('RUB', 14),
      row('TRY', 16),
      row('NZD', 22),
      row('EUA', 15),
    ]
    const sorted = sortByDisplayOrder(backendOrder).map((r) => r.currencyCode)
    expect(sorted.indexOf('EUA')).toBe(sorted.indexOf('RUB') + 1)
    expect(sorted.indexOf('TRY')).toBe(sorted.indexOf('EUA') + 1)
  })

  it('ismeretlen (displayOrder nélküli) kód a végére, ABC-rendben — korábbi viselkedés', () => {
    const input = [row('ZZZ', null), row('AAA', undefined), row('EUR', 1)]
    expect(sortByDisplayOrder(input).map((r) => r.currencyCode)).toEqual(['EUR', 'AAA', 'ZZZ'])
  })

  it('nem mutálja a bemenetet', () => {
    const input = [row('TRY', 16), row('EUR', 1)]
    sortByDisplayOrder(input)
    expect(input.map((r) => r.currencyCode)).toEqual(['TRY', 'EUR'])
  })
})
