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
})
