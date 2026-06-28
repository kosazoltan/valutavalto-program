import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor, within } from '@testing-library/react'
import CompetitorRateEntryPage from './CompetitorRateEntryPage'

const mocks = vi.hoisted(() => ({
  bootstrap: vi.fn(),
  today: vi.fn(),
  submit: vi.fn(),
  toastSuccess: vi.fn(),
  toastError: vi.fn(),
  toastWarning: vi.fn(),
}))

vi.mock('../../services/api/index', () => ({
  competitorRatesApi: {
    bootstrap: mocks.bootstrap,
    today: mocks.today,
    submit: mocks.submit,
  },
  // FK-041/II: a telefon-PWA QR a PUBLIKUS web-URL-t kell használja (Electronban a
  // window.location.origin = app://localhost lokális lenne) → getPublicWebUrl().
  getPublicWebUrl: () => 'https://excvaluta.com',
}))
vi.mock('../../components/ui/toaster', () => ({
  toast: { success: mocks.toastSuccess, error: mocks.toastError, warning: mocks.toastWarning },
}))
vi.mock('../../utils/logger', () => ({
  logger: { error: vi.fn(), info: vi.fn(), warn: vi.fn(), debug: vi.fn() },
}))
vi.mock('../../utils/errorHandling', () => ({ getErrorMessage: (e: unknown) => String(e) }))

describe('CompetitorRateEntryPage (FK-041/II)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.bootstrap.mockResolvedValue({
      competitors: [{ id: 'c1', name: 'Rivál Change', branchName: 'Tisza Sarok' }],
      currencies: [
        { id: 1, code: 'EUR', name: 'Euró' },
        { id: 2, code: 'USD', name: 'US dollár' },
      ],
    })
    mocks.today.mockResolvedValue([])
    mocks.submit.mockResolvedValue(undefined)
  })

  it('betölti a régió versenyhelyeit + valutakosarat, és beküldi a kitöltött árfolyamot', async () => {
    render(<CompetitorRateEntryPage />)

    const select = await screen.findByTestId('competitor-select')
    expect(within(select).getByText(/Rivál Change/)).toBeInTheDocument()

    fireEvent.change(select, { target: { value: 'c1' } })
    await waitFor(() => expect(mocks.today).toHaveBeenCalledWith('c1'))

    // Csak az EUR-t töltjük ki (a USD üres marad → kimarad a beküldésből).
    fireEvent.change(await screen.findByTestId('buy-EUR'), { target: { value: '390' } })
    fireEvent.change(screen.getByTestId('sell-EUR'), { target: { value: '400' } })

    fireEvent.click(screen.getByTestId('submit-competitor-rates'))

    await waitFor(() => expect(mocks.submit).toHaveBeenCalled())
    expect(mocks.submit).toHaveBeenCalledWith({
      competitorId: 'c1',
      rates: [{ currencyId: 1, buyRate: 390, sellRate: 400 }],
    })
    expect(mocks.toastSuccess).toHaveBeenCalled()
  })

  it('FK-041/II regresszió: a telefon-PWA QR a PUBLIKUS web-URL-t mutatja (nem a lokális window.location.origin-t)', async () => {
    // Élesben (Electron) a window.location.origin = app://localhost, amit a telefon nem tud megnyitni.
    // A beíró oldalnak getPublicWebUrl()-t kell átadnia a PwaInstallHelp-nek (mint a TreasuryDashboard).
    render(<CompetitorRateEntryPage />)
    await screen.findByTestId('competitor-select')

    fireEvent.click(screen.getByTestId('pwa-install-toggle'))

    // A megjelenített megosztandó URL a publikus web-origin…
    expect(screen.getByText('https://excvaluta.com')).toBeInTheDocument()
    // …és NEM a lokális origin (jsdom-ban http://localhost, Electronban app://localhost).
    expect(screen.queryByText(window.location.origin)).not.toBeInTheDocument()
  })

  it('üres versenyhely-lista esetén üzenetet mutat, form nélkül', async () => {
    mocks.bootstrap.mockResolvedValue({ competitors: [], currencies: [] })
    render(<CompetitorRateEntryPage />)

    expect(await screen.findByTestId('no-competitors')).toBeInTheDocument()
    expect(screen.queryByTestId('submit-competitor-rates')).not.toBeInTheDocument()
  })

  it('versenyhely választása nélkül a beküldés gomb tiltott', async () => {
    render(<CompetitorRateEntryPage />)
    await screen.findByTestId('competitor-select')
    expect(screen.getByTestId('submit-competitor-rates')).toBeDisabled()
  })

  it('részlegesen kitöltött sor (csak vétel) → figyelmeztet, NEM küld be', async () => {
    render(<CompetitorRateEntryPage />)
    const select = await screen.findByTestId('competitor-select')
    fireEvent.change(select, { target: { value: 'c1' } })

    // Csak a vételt töltjük ki EUR-ra, az eladást üresen hagyjuk.
    fireEvent.change(await screen.findByTestId('buy-EUR'), { target: { value: '390' } })
    fireEvent.click(screen.getByTestId('submit-competitor-rates'))

    await waitFor(() => expect(mocks.toastWarning).toHaveBeenCalled())
    expect(mocks.submit).not.toHaveBeenCalled()
  })

  it('semmi kitöltve → figyelmeztet (legalább egy árfolyamot), NEM küld be', async () => {
    render(<CompetitorRateEntryPage />)
    const select = await screen.findByTestId('competitor-select')
    fireEvent.change(select, { target: { value: 'c1' } })
    await screen.findByTestId('buy-EUR')

    fireEvent.click(screen.getByTestId('submit-competitor-rates'))

    await waitFor(() => expect(mocks.toastWarning).toHaveBeenCalled())
    expect(mocks.submit).not.toHaveBeenCalled()
  })

  it('előtölti egy versenyhely MAI bevitt árfolyamait', async () => {
    mocks.today.mockResolvedValue([
      { currencyId: 1, currencyCode: 'EUR', buyRate: 388, sellRate: 402 },
    ])
    render(<CompetitorRateEntryPage />)

    const select = await screen.findByTestId('competitor-select')
    fireEvent.change(select, { target: { value: 'c1' } })

    const buyEur = await screen.findByTestId('buy-EUR')
    await waitFor(() => expect((buyEur as HTMLInputElement).value).toBe('388'))
    expect((screen.getByTestId('sell-EUR') as HTMLInputElement).value).toBe('402')
  })

  it('FK-041/II: a today() prefill hibája toastot mutat (nem nyeli el némán)', async () => {
    mocks.today.mockRejectedValue(new Error('network'))
    render(<CompetitorRateEntryPage />)
    const select = await screen.findByTestId('competitor-select')

    fireEvent.change(select, { target: { value: 'c1' } })

    await waitFor(() => expect(mocks.toastError).toHaveBeenCalled())
  })

  it('FK-041/II race-guard: gyors versenyhely-váltás után a STALE válasz NEM írja felül az új állapotot', async () => {
    mocks.bootstrap.mockResolvedValue({
      competitors: [
        { id: 'c1', name: 'Rivál Egy', branchName: 'Tisza' },
        { id: 'c2', name: 'Rivál Kettő', branchName: 'Tisza' },
      ],
      currencies: [{ id: 1, code: 'EUR', name: 'Euró' }],
    })
    // c1 today() KÉSŐN resolve-ol (stale), c2 today() azonnal üres.
    let resolveC1: (
      value: { currencyId: number; currencyCode: string; buyRate: number; sellRate: number }[],
    ) => void = () => {}
    mocks.today.mockImplementation((id: string) => {
      if (id === 'c1') return new Promise((res) => (resolveC1 = res))
      return Promise.resolve([])
    })

    render(<CompetitorRateEntryPage />)
    const select = await screen.findByTestId('competitor-select')

    fireEvent.change(select, { target: { value: 'c1' } }) // c1 today() függőben marad
    fireEvent.change(select, { target: { value: 'c2' } }) // c2 today() üresen resolve-ol
    await waitFor(() => expect(mocks.today).toHaveBeenCalledWith('c2'))
    await screen.findByTestId('buy-EUR')

    // A KÉSEI c1 válasz beérkezik (EUR=388), de már c2 van kiválasztva → a guardnak el kell dobnia.
    resolveC1([{ currencyId: 1, currencyCode: 'EUR', buyRate: 388, sellRate: 402 }])
    await new Promise((r) => setTimeout(r, 20))

    // c2 üres maradt — a stale c1 (388) NEM írta felül.
    expect((screen.getByTestId('buy-EUR') as HTMLInputElement).value).toBe('')
  })
})
