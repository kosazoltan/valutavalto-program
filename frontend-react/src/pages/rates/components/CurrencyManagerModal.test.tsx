import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { AxiosError } from 'axios'
import CurrencyManagerModal, { computeNextDisplayOrder } from './CurrencyManagerModal'
import { currencyApi } from '../../../services/api/exchange-rates'
import { toast } from '../../../components/ui/toaster'
import type { Currency } from '../../../services/api/exchange-rates'

vi.mock('../../../services/api/exchange-rates', () => ({
  currencyApi: {
    getAll: vi.fn(),
    getByCode: vi.fn(),
    search: vi.fn(),
    create: vi.fn(),
    setActive: vi.fn(),
  },
}))

vi.mock('../../../components/ui/toaster', () => ({
  toast: { success: vi.fn(), error: vi.fn(), warning: vi.fn() },
}))

vi.mock('../../../utils/logger', () => ({
  logger: { error: vi.fn(), warn: vi.fn(), info: vi.fn() },
}))

const cur = (code: string, displayOrder: number, active = true): Currency => ({
  id: displayOrder + 1,
  code,
  name: `${code} valuta`, // a kódtól eltérő név, hogy a findByText egyértelmű legyen
  decimals: 2,
  displayOrder,
  active,
})

describe('FK04 (FR-8) — computeNextDisplayOrder', () => {
  it('new_currency_default_order_is_max_plus_one', () => {
    expect(computeNextDisplayOrder([cur('EUR', 1), cur('NZD', 22), cur('DKK', 101, false)])).toBe(102)
  })

  it('üres lista → 1 (nem fix 99)', () => {
    expect(computeNextDisplayOrder([])).toBe(1)
  })

  it('hiányzó displayOrder mezőt 0-nak tekint', () => {
    expect(computeNextDisplayOrder([{ displayOrder: undefined }, { displayOrder: 5 }])).toBe(6)
  })
})

describe('FK04 (FR-8) — CurrencyManagerModal', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.mocked(currencyApi.search).mockResolvedValue([cur('EUR', 1)])
    vi.mocked(currencyApi.getByCode).mockResolvedValue(cur('EUR', 1))
  })

  it('az "Új valuta" form a max(displayOrder)+1 defaulttal nyílik (nem 99-cel)', async () => {
    vi.mocked(currencyApi.getAll).mockResolvedValue([cur('EUR', 1), cur('NZD', 22)])
    render(<CurrencyManagerModal isOpen onClose={() => {}} />)
    await waitFor(() => expect(vi.mocked(currencyApi.getAll)).toHaveBeenCalled())
    // megvárjuk, hogy a lista renderelődjön (refresh kész)
    await screen.findByText('NZD')

    fireEvent.click(screen.getByTestId('currency-manager-toggle-add'))

    const orderInput = screen.getByTestId('new-currency-display-order') as HTMLInputElement
    expect(orderInput.value).toBe('23')
  })

  it('duplicate_display_order_shows_409_error: 409 + VV-VALID-003 → hiba-toast a backend-üzenettel, a form nyitva marad', async () => {
    vi.mocked(currencyApi.getAll).mockResolvedValue([cur('EUR', 1)])
    // Valódi AxiosError, ahogy az api-réteg dobja — a getErrorMessage a response.data.message-t adja vissza.
    const backendMessage = 'A megjelenitesi sorrend (5) mar foglalt — valassz masik erteket'
    const conflict = new AxiosError('Request failed with status code 409')
    conflict.response = {
      status: 409,
      data: { code: 'VV-VALID-003', message: backendMessage },
    } as AxiosError['response']
    vi.mocked(currencyApi.create).mockRejectedValue(conflict)

    render(<CurrencyManagerModal isOpen onClose={() => {}} />)
    await screen.findByText('EUR valuta')

    fireEvent.click(screen.getByTestId('currency-manager-toggle-add'))
    fireEvent.change(screen.getByTestId('new-currency-code'), { target: { value: 'AED' } })
    fireEvent.change(screen.getByTestId('new-currency-name'), { target: { value: 'Dirham' } })
    fireEvent.click(screen.getByTestId('new-currency-submit'))

    // A felhasználó a BACKEND magyar üzenetét látja (nem generikus hibát) — silent fail tilos.
    await waitFor(() => expect(vi.mocked(toast.error)).toHaveBeenCalledWith('Hiba', backendMessage))
    // a sikeres-ág nem futott: nincs success toast, a form input megmaradt
    expect(vi.mocked(toast.success)).not.toHaveBeenCalled()
    expect((screen.getByTestId('new-currency-code') as HTMLInputElement).value).toBe('AED')
  })

  it('backend keresést használ a valuta kereső gombbal', async () => {
    vi.mocked(currencyApi.getAll).mockResolvedValue([cur('EUR', 1), cur('USD', 2)])
    vi.mocked(currencyApi.search).mockResolvedValue([cur('EUR', 1)])

    render(<CurrencyManagerModal isOpen onClose={() => {}} />)
    await screen.findByText('USD valuta')

    fireEvent.change(screen.getByTestId('currency-manager-search'), { target: { value: 'eur' } })
    fireEvent.click(screen.getByTestId('currency-manager-search-submit'))

    await waitFor(() => expect(vi.mocked(currencyApi.search)).toHaveBeenCalledWith('eur'))
    expect(await screen.findByText('EUR valuta')).toBeInTheDocument()
    expect(screen.queryByText('USD valuta')).not.toBeInTheDocument()
  })

  it('sor részlet megnyitásakor kód szerinti backend detailt kér', async () => {
    vi.mocked(currencyApi.getAll).mockResolvedValue([cur('EUR', 1)])
    vi.mocked(currencyApi.getByCode).mockResolvedValue({
      ...cur('EUR', 1),
      name: 'Backend EUR detail',
      symbol: 'EUR',
    })

    render(<CurrencyManagerModal isOpen onClose={() => {}} />)
    await screen.findByText('EUR valuta')

    fireEvent.click(screen.getByTestId('detail-EUR'))

    await waitFor(() => expect(vi.mocked(currencyApi.getByCode)).toHaveBeenCalledWith('EUR'))
    expect(await screen.findByTestId('currency-manager-detail')).toHaveTextContent('Backend EUR detail')
  })
})
