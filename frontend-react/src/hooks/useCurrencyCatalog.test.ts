import { describe, it, expect, vi, beforeEach } from 'vitest'
import { act, renderHook, waitFor } from '@testing-library/react'
import { useCurrencyCatalog, selectCatalogCurrencies, CROSS_BASE_MAP, getCrossBase } from './useCurrencyCatalog'
import { currencyApi } from '../services/api/exchange-rates'
import type { Currency } from '../services/api/exchange-rates'

vi.mock('../services/api/exchange-rates', () => ({
  currencyApi: {
    getAll: vi.fn(),
  },
}))

vi.mock('../utils/logger', () => ({
  logger: { error: vi.fn(), warn: vi.fn(), info: vi.fn() },
}))

const cur = (code: string, displayOrder: number, active = true): Currency => ({
  id: displayOrder + 1,
  code,
  name: code,
  decimals: 2,
  displayOrder,
  active,
})

/** FK04 kanonikus sorrend (V317): EUR=1 … RUB=14, EUA=15, TRY=16 … NZD=22. */
const CANONICAL: Currency[] = [
  cur('HUF', 0),
  cur('EUR', 1), cur('USD', 2), cur('GBP', 3), cur('CHF', 4), cur('AUD', 5),
  cur('CAD', 6), cur('JPY', 7), cur('CZK', 8), cur('PLN', 9), cur('RON', 10),
  cur('RSD', 11), cur('ILS', 12), cur('UAH', 13), cur('RUB', 14),
  cur('EUA', 15, false), // EUA szándékosan inaktív (V298) — mégis a katalógus része
  cur('TRY', 16), cur('CNY', 17), cur('BAM', 18), cur('THB', 19), cur('BRL', 20),
  cur('MXN', 21), cur('NZD', 22),
  cur('DKK', 101, false), // inaktív maradvány — NEM kerülhet a katalógusba
]

describe('FK04 — useCurrencyCatalog', () => {
  beforeEach(() => {
    vi.mocked(currencyApi.getAll).mockReset()
  })

  it('returns_sorted_active_currencies_plus_eua: aktív + EUA, HUF/inaktív nélkül, displayOrder-rendben', async () => {
    // Szándékosan kevert sorrendben adjuk vissza — a hooknak kell rendeznie.
    vi.mocked(currencyApi.getAll).mockResolvedValue([...CANONICAL].reverse())

    const { result } = renderHook(() => useCurrencyCatalog())
    await waitFor(() => expect(result.current.loading).toBe(false))

    const codes = result.current.currencies.map(c => c.code)
    expect(codes).toHaveLength(22)
    expect(codes[0]).toBe('EUR')
    expect(codes[codes.length - 1]).toBe('NZD')
    // FR-5: EUA a RUB és TRY között (15. pozíció = index 14)
    expect(codes.indexOf('EUA')).toBe(codes.indexOf('RUB') + 1)
    expect(codes.indexOf('TRY')).toBe(codes.indexOf('EUA') + 1)
    expect(codes).not.toContain('HUF')
    expect(codes).not.toContain('DKK')
    expect(result.current.error).toBeNull()
  })

  it('cross_base_map_contains_all_22_currencies: minden katalógus-kód le van fedve', () => {
    const catalogCodes = selectCatalogCurrencies(CANONICAL).map(c => c.code)
    for (const code of catalogCodes) {
      expect(CROSS_BASE_MAP, `hiányzó crossBase: ${code}`).toHaveProperty(code)
    }
    expect(Object.keys(CROSS_BASE_MAP)).toHaveLength(22)
    // Szúrópróba a korábbi DEFAULT_CURRENCIES értékekre (TBD-1):
    expect(getCrossBase('CZK')).toBe('EUR')
    expect(getCrossBase('RUB')).toBe('USD')
    expect(getCrossBase('EUA')).toBeNull()
    expect(getCrossBase('ISMERETLEN')).toBeNull()
  })

  it('returns_empty_on_api_error: hiba esetén error nem null, currencies üres', async () => {
    vi.mocked(currencyApi.getAll).mockRejectedValue(new Error('network down'))

    const { result } = renderHook(() => useCurrencyCatalog())
    await waitFor(() => expect(result.current.loading).toBe(false))

    expect(result.current.error).not.toBeNull()
    expect(result.current.currencies).toEqual([])
  })

  it('out_of_order_reload: a régebbi (lassabb) válasz nem írja felül az újabbat (last-requested-wins)', async () => {
    let resolveFirst: (v: Currency[]) => void = () => {}
    let resolveSecond: (v: Currency[]) => void = () => {}
    const first = new Promise<Currency[]>(r => { resolveFirst = r })
    const second = new Promise<Currency[]>(r => { resolveSecond = r })
    vi.mocked(currencyApi.getAll).mockReturnValueOnce(first).mockReturnValueOnce(second)

    const { result } = renderHook(() => useCurrencyCatalog())
    // 2. kérés (reload) még az 1. válasza ELŐTT elindul
    act(() => result.current.reload())
    // a 2. (frissebb) válasz érkezik előbb…
    await act(async () => { resolveSecond([cur('EUR', 1)]) })
    // …majd az 1. (elavult) válasz — ennek már NEM szabad érvényesülnie
    await act(async () => { resolveFirst(CANONICAL) })

    await waitFor(() => expect(result.current.loading).toBe(false))
    expect(result.current.currencies.map(c => c.code)).toEqual(['EUR'])
  })

  it('reload: a Valutakezelő módosítása után friss listát húz', async () => {
    vi.mocked(currencyApi.getAll).mockResolvedValueOnce(CANONICAL.slice(0, 3))
    const { result } = renderHook(() => useCurrencyCatalog())
    await waitFor(() => expect(result.current.loading).toBe(false))
    const firstLen = result.current.currencies.length

    vi.mocked(currencyApi.getAll).mockResolvedValueOnce(CANONICAL)
    result.current.reload()
    await waitFor(() => expect(result.current.currencies.length).toBeGreaterThan(firstLen))
    expect(vi.mocked(currencyApi.getAll)).toHaveBeenCalledTimes(2)
  })
})
