import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { AxiosError } from 'axios'
import CurrencyManagerModal, { computeNextDisplayOrder } from './CurrencyManagerModal'
import { currencyApi, currencyDenominationImageApi } from '../../../services/api/exchange-rates'
import { toast } from '../../../components/ui/toaster'
import type { Currency } from '../../../services/api/exchange-rates'

vi.mock('../../../services/api/exchange-rates', () => ({
  currencyApi: {
    getAll: vi.fn(),
    getByCode: vi.fn(),
    getById: vi.fn(),
    search: vi.fn(),
    create: vi.fn(),
    setActive: vi.fn(),
    setZeroRatePolicy: vi.fn(),
  },
  currencyDenominationImageApi: {
    list: vi.fn().mockResolvedValue([]),
    upload: vi.fn(),
    getThumbnail: vi.fn(),
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
    expect(computeNextDisplayOrder([cur('EUR', 1), cur('NZD', 22), cur('DKK', 101, false)])).toBe(
      102,
    )
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
    vi.mocked(currencyApi.getById).mockResolvedValue(cur('EUR', 1))
    vi.mocked(currencyDenominationImageApi.list).mockResolvedValue([])
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

  it('sor részlet megnyitásakor ID szerinti detailt kér és megtartja a kód szerinti backend ellenőrzést', async () => {
    vi.mocked(currencyApi.getAll).mockResolvedValue([cur('EUR', 1)])
    vi.mocked(currencyApi.getById).mockResolvedValue({
      ...cur('EUR', 1),
      name: 'Backend EUR ID detail',
      symbol: 'EUR',
    })
    vi.mocked(currencyApi.getByCode).mockResolvedValue({
      ...cur('EUR', 1),
      name: 'Backend EUR code check',
      symbol: 'EUR',
    })

    render(<CurrencyManagerModal isOpen onClose={() => {}} />)
    await screen.findByText('EUR valuta')

    fireEvent.click(screen.getByTestId('detail-EUR'))

    await waitFor(() => expect(vi.mocked(currencyApi.getById)).toHaveBeenCalledWith(2))
    await waitFor(() => expect(vi.mocked(currencyApi.getByCode)).toHaveBeenCalledWith('EUR'))
    expect(await screen.findByTestId('currency-manager-detail')).toHaveTextContent(
      'Backend EUR ID detail',
    )
    expect(screen.getByTestId('currency-manager-code-check')).toHaveTextContent(
      'Kód-ellenőrzés: EUR / #2',
    )
  })

  it('címletképek panel megjelenik ha ki van jelölve valuta', async () => {
    vi.mocked(currencyApi.getAll).mockResolvedValue([cur('EUR', 1)])
    vi.mocked(currencyApi.getById).mockResolvedValue(cur('EUR', 1))
    vi.mocked(currencyApi.getByCode).mockResolvedValue(cur('EUR', 1))

    render(<CurrencyManagerModal isOpen onClose={() => {}} />)
    await screen.findByText('EUR valuta')

    fireEvent.click(screen.getByTestId('detail-EUR'))

    await waitFor(() =>
      expect(screen.queryByTestId('denomination-image-upload-button')).toBeInTheDocument(),
    )
  })
})

/**
 * FK13 (FR-10) — valutánkénti, irányonkénti "0 engedélyezett" checkboxok a Valutakezelőben, a meglévő
 * pendingToggle/toggleNote/confirmToggle minta újrahasználásával (megerősítő panel + indoklás → audit note).
 *
 * Test-id szerződés (RED-döntés, Tomival egyeztetendő):
 *  - `zero-rate-buy-<KÓD>` / `zero-rate-sell-<KÓD>`  — checkbox soronként (checked = engedélyezett)
 *  - `zero-rate-policy-confirm`                       — megerősítő panel
 *  - `zero-rate-policy-note`                          — indoklás input
 *  - `zero-rate-policy-confirm-btn`                   — megerősítés
 */
describe('FK13 (FR-10) — "0 engedélyezett" irány-kapcsolók a Valutakezelőben', () => {
  const uah = (policy: Partial<Currency> = {}): Currency => ({
    ...cur('UAH', 20),
    name: 'Ukrán hrivnya',
    ...policy,
  })

  beforeEach(() => {
    vi.clearAllMocks()
    vi.mocked(currencyDenominationImageApi.list).mockResolvedValue([])
    vi.mocked(currencyApi.search).mockResolvedValue([])
  })

  it('a checkboxok soronként megjelennek, és a currency policy-ját tükrözik (nem beállított = kikapcsolt)', async () => {
    vi.mocked(currencyApi.getAll).mockResolvedValue([
      uah({ buyZeroAllowed: true, sellZeroAllowed: false }),
      { ...cur('EUR', 1), name: 'Euró' },
    ])

    render(<CurrencyManagerModal isOpen onClose={() => {}} />)
    await screen.findByText('Ukrán hrivnya')

    expect((screen.getByTestId('zero-rate-buy-UAH') as HTMLInputElement).checked).toBe(true)
    expect((screen.getByTestId('zero-rate-sell-UAH') as HTMLInputElement).checked).toBe(false)
    // EUR-on nincs beállítva (undefined) → mindkettő kikapcsolt
    expect((screen.getByTestId('zero-rate-buy-EUR') as HTMLInputElement).checked).toBe(false)
    expect((screen.getByTestId('zero-rate-sell-EUR') as HTMLInputElement).checked).toBe(false)
  })

  it('vétel-0 engedélyezése: megerősítő panel + indoklás → setZeroRatePolicy(id, {buy: true, sell: false}, note), siker-toast, lista frissül', async () => {
    vi.mocked(currencyApi.getAll).mockResolvedValue([uah()])
    vi.mocked(currencyApi.setZeroRatePolicy).mockResolvedValue(
      uah({ buyZeroAllowed: true, sellZeroAllowed: false }),
    )
    const onChanged = vi.fn()

    render(<CurrencyManagerModal isOpen onClose={() => {}} onCurrencyChanged={onChanged} />)
    await screen.findByText('Ukrán hrivnya')

    fireEvent.click(screen.getByTestId('zero-rate-buy-UAH'))
    // NEM hív API-t azonnal: megerősítés + indoklás (a setActive mintája, window.prompt Electronban nem megy)
    expect(vi.mocked(currencyApi.setZeroRatePolicy)).not.toHaveBeenCalled()
    expect(screen.getByTestId('zero-rate-policy-confirm')).toBeInTheDocument()

    fireEvent.change(screen.getByTestId('zero-rate-policy-note'), {
      target: { value: 'UAH-t csak eladjuk' },
    })
    fireEvent.click(screen.getByTestId('zero-rate-policy-confirm-btn'))

    await waitFor(() =>
      expect(vi.mocked(currencyApi.setZeroRatePolicy)).toHaveBeenCalledWith(
        21,
        { buyZeroAllowed: true, sellZeroAllowed: false },
        'UAH-t csak eladjuk',
      ),
    )
    await waitFor(() => expect(vi.mocked(toast.success)).toHaveBeenCalled())
    expect(vi.mocked(currencyApi.getAll).mock.calls.length).toBeGreaterThanOrEqual(2)
    expect(onChanged).toHaveBeenCalled()
    expect(screen.queryByTestId('zero-rate-policy-confirm')).not.toBeInTheDocument()
  })

  it('eladás-0 kapcsoló külön irány: a meglévő vétel-engedély megmarad a payloadban', async () => {
    vi.mocked(currencyApi.getAll).mockResolvedValue([uah({ buyZeroAllowed: true })])
    vi.mocked(currencyApi.setZeroRatePolicy).mockResolvedValue(
      uah({ buyZeroAllowed: true, sellZeroAllowed: true }),
    )

    render(<CurrencyManagerModal isOpen onClose={() => {}} />)
    await screen.findByText('Ukrán hrivnya')

    fireEvent.click(screen.getByTestId('zero-rate-sell-UAH'))
    fireEvent.click(screen.getByTestId('zero-rate-policy-confirm-btn'))

    await waitFor(() =>
      expect(vi.mocked(currencyApi.setZeroRatePolicy)).toHaveBeenCalledWith(
        21,
        { buyZeroAllowed: true, sellZeroAllowed: true },
        undefined,
      ),
    )
  })

  it('backend-hiba (403 / VV-AUTH) → a felhasználó a backend üzenetét látja, nincs success-toast', async () => {
    vi.mocked(currencyApi.getAll).mockResolvedValue([uah()])
    const forbidden = new AxiosError('Request failed with status code 403')
    forbidden.response = {
      status: 403,
      data: { code: 'ACCESS_DENIED', message: 'Nincs jogosultsága a művelet végrehajtásához' },
    } as AxiosError['response']
    vi.mocked(currencyApi.setZeroRatePolicy).mockRejectedValue(forbidden)

    render(<CurrencyManagerModal isOpen onClose={() => {}} />)
    await screen.findByText('Ukrán hrivnya')

    fireEvent.click(screen.getByTestId('zero-rate-buy-UAH'))
    fireEvent.click(screen.getByTestId('zero-rate-policy-confirm-btn'))

    await waitFor(() =>
      expect(vi.mocked(toast.error)).toHaveBeenCalledWith(
        'Hiba',
        'Nincs jogosultsága a művelet végrehajtásához',
      ),
    )
    expect(vi.mocked(toast.success)).not.toHaveBeenCalled()
    // a checkbox nem billen át hiba esetén (server-authority)
    expect((screen.getByTestId('zero-rate-buy-UAH') as HTMLInputElement).checked).toBe(false)
  })
})
