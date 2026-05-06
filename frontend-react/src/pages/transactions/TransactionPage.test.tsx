import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import TransactionPage from './TransactionPage'

const mocks = vi.hoisted(() => ({
  navigate: vi.fn(),
  transactionApiBuy: vi.fn(),
  transactionApiSell: vi.fn(),
  toast: {
    success: vi.fn(),
    warning: vi.fn(),
    error: vi.fn(),
  },
  saveAndSyncPendingBuySell: vi.fn(),
}))

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual<typeof import('react-router-dom')>('react-router-dom')
  return {
    ...actual,
    useNavigate: () => mocks.navigate,
  }
})

vi.mock('../../services/api/index', () => ({
  transactionApi: {
    buy: mocks.transactionApiBuy,
    sell: mocks.transactionApiSell,
  },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: mocks.toast,
}))

vi.mock('../../utils/electronTransactions', () => ({
  saveAndSyncPendingBuySell: mocks.saveAndSyncPendingBuySell,
}))

vi.mock('./hooks/useTransactionRates', () => ({
  useTransactionRates: () => ({
    currencyRates: [
      { id: '1', code: 'EUR', name: 'Euró', buyRate: 391.50, sellRate: 398.50, unit: 1 },
      { id: '2', code: 'USD', name: 'US Dollár', buyRate: 358.20, sellRate: 365.80, unit: 1 },
    ],
    electronQueueAvailable: false,
  }),
}))

vi.mock('./hooks/useIdentificationLevel', () => ({
  useIdentificationLevel: () => ({
    identificationLevel: 'SIMPLE',
    minimumLevel: 'SIMPLE',
    setIdentificationLevel: () => {},
    requiresSourceVerification: false,
  }),
}))

vi.mock('./components/CurrencySelector', () => ({
  default: ({ currencyRates, selectedCurrency, onSelect }: any) => (
    <div data-testid="currency-selector">
      {currencyRates.map((c: any) => (
        <button
          key={c.id}
          onClick={() => onSelect(c)}
          data-testid={`currency-${c.code}`}
          className={selectedCurrency?.code === c.code ? 'selected' : ''}
        >
          {c.code}
        </button>
      ))}
    </div>
  ),
}))

vi.mock('./components/CustomerPanel', () => ({
  default: ({ onCustomerChange }: any) => (
    <div data-testid="customer-panel">
      <input
        type="text"
        data-field="customer-name"
        placeholder="Ügyfél"
        onChange={(e) => onCustomerChange(e.target.value ? { id: '1', name: e.target.value, documentNumber: '12345', nationality: 'HU' } : null)}
      />
    </div>
  ),
}))

function renderTransactionPage() {
  render(
    <MemoryRouter>
      <TransactionPage />
    </MemoryRouter>,
  )
}

describe('TransactionPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('oldal renderelésének ellenőrzése', () => {
    renderTransactionPage()
    expect(screen.getByText('Új tranzakció')).toBeInTheDocument()
  })

  it('deviza választó és tranzakció típus gombok megjelenése', () => {
    renderTransactionPage()
    expect(screen.getByTestId('currency-selector')).toBeInTheDocument()
    expect(screen.getByText(/VÉTEL/)).toBeInTheDocument()
    expect(screen.getByText(/ELADÁS/)).toBeInTheDocument()
  })

  it('elsőre megjelenítés: EUR kiválasztva', () => {
    renderTransactionPage()
    const eurButton = screen.getByTestId('currency-EUR')
    expect(eurButton).toHaveClass('selected')
  })

  it('számadatok input mezőket megjelenít', () => {
    renderTransactionPage()
    expect(screen.getByText(/EUR összeg/)).toBeInTheDocument()
    expect(screen.getByText(/HUF összeg/)).toBeInTheDocument()
  })

  it('deviza választás módosítja az árfolyamot', async () => {
    renderTransactionPage()
    const user = userEvent.setup()

    const usdButton = screen.getByTestId('currency-USD')
    await user.click(usdButton)

    // Component updates to show USD exchange rate
    expect(usdButton).toHaveClass('selected')
  })

  it('deviza összeg megadásakor HUF automatikusan kiszámítódik', async () => {
    renderTransactionPage()
    const user = userEvent.setup()

    const inputs = screen.getAllByPlaceholderText('0,00')
    const foreignInput = inputs[0]!

    await user.clear(foreignInput)
    await user.type(foreignInput, '100')

    // EUR * 100 * 391.50 = 39150
    await waitFor(() => {
      const hufInputs = screen.getAllByPlaceholderText('0,00')
      expect(hufInputs[1]).toHaveValue('39150')
    })
  })

  it('HUF összeg megadásakor deviza automatikusan kiszámítódik', async () => {
    renderTransactionPage()
    const user = userEvent.setup()

    const inputs = screen.getAllByPlaceholderText('0,00')
    const foreignInput = inputs[0] as HTMLInputElement
    const hufInput = inputs[1] as HTMLInputElement

    await user.clear(hufInput)
    await user.type(hufInput, '1000')

    await waitFor(() => {
      expect(hufInput).toHaveValue('1000')
      expect(foreignInput).toHaveValue('2,55')
    })
  })

  it('Mégsem gomb navigál vissza', async () => {
    renderTransactionPage()
    const user = userEvent.setup()

    const cancelButton = screen.getByText('Mégse')
    await user.click(cancelButton)

    expect(mocks.navigate).toHaveBeenCalledWith('/transactions')
  })

  it('Mentés és nyomtatás gomb összeg nélkül figyelmeztető toast-ot mutat', async () => {
    renderTransactionPage()
    const user = userEvent.setup()

    const saveButton = screen.getByTestId('tx-save-print')
    // Összeg nélkül → toast warning
    await user.click(saveButton)

    // Toast warning hívás ellenőrzés
    expect(mocks.toast.warning).toHaveBeenCalledWith(
      'Érvénytelen összeg',
      'Kérem adjon meg érvényes összeget!',
    )
  })

  it('sikeres BUY tranzakció mentésekor API-t meghívja', async () => {
    mocks.transactionApiBuy.mockResolvedValue({ receiptNumber: 'RCP-001' })
    const user = userEvent.setup()

    renderTransactionPage()

    const inputs = screen.getAllByPlaceholderText('0,00')
    await user.type(inputs[0]!, '100')

    const saveButton = screen.getByTestId('tx-save-print')
    await user.click(saveButton)

    await waitFor(() => {
      expect(mocks.transactionApiBuy).toHaveBeenCalledWith(
        expect.objectContaining({
          currencyId: 1,
          currencyAmount: 100,
          customExchangeRate: 391.50,
        }),
      )
    })
  })

  it('sikeres SELL tranzakció mentésekor API-t meghívja', async () => {
    mocks.transactionApiSell.mockResolvedValue({ receiptNumber: 'RCP-002' })
    const user = userEvent.setup()

    renderTransactionPage()

    const sellButton = screen.getByText(/ELADÁS/)
    await user.click(sellButton)

    const inputs = screen.getAllByPlaceholderText('0,00')
    await user.type(inputs[0]!, '100')

    const saveButton = screen.getByTestId('tx-save-print')
    await user.click(saveButton)

    await waitFor(() => {
      expect(mocks.transactionApiSell).toHaveBeenCalledWith(
        expect.objectContaining({
          currencyId: 1,
          currencyAmount: 100,
          customExchangeRate: 398.50,
        }),
      )
    })
  })

  it('sikeres mentés után toast success mutatódik', async () => {
    mocks.transactionApiBuy.mockResolvedValue({ receiptNumber: 'RCP-001' })
    const user = userEvent.setup()

    renderTransactionPage()

    const inputs = screen.getAllByPlaceholderText('0,00')
    await user.type(inputs[0]!, '100')

    const saveButton = screen.getByTestId('tx-save-print')
    await user.click(saveButton)

    await waitFor(() => {
      expect(mocks.toast.success).toHaveBeenCalled()
    })
  })

  it('érvénytelen összeg (0) esetén toast warning mutatódik', async () => {
    const user = userEvent.setup()
    renderTransactionPage()

    const saveButton = screen.getByTestId('tx-save-print')
    await user.click(saveButton)

    await waitFor(() => {
      expect(mocks.toast.warning).toHaveBeenCalledWith(
        'Érvénytelen összeg',
        'Kérem adjon meg érvényes összeget!',
      )
    })
  })

  it('API hiba esetén toast error mutatódik', async () => {
    mocks.transactionApiBuy.mockRejectedValue(new Error('API hiba'))
    const user = userEvent.setup()

    renderTransactionPage()

    const inputs = screen.getAllByPlaceholderText('0,00')
    await user.type(inputs[0]!, '100')

    const saveButton = screen.getByTestId('tx-save-print')
    await user.click(saveButton)

    await waitFor(() => {
      expect(mocks.toast.error).toHaveBeenCalled()
    })
  })

  it('Escape billentyű mégsem gombként működik', async () => {
    const user = userEvent.setup()
    renderTransactionPage()

    await user.keyboard('{Escape}')

    await waitFor(() => {
      expect(mocks.navigate).toHaveBeenCalledWith('/transactions')
    })
  })

  it('billentyűzet útmutató megjeleníti a gyorsgombokat', () => {
    renderTransactionPage()
    expect(screen.getByText(/Billentyűzet használat:/)).toBeInTheDocument()
    expect(screen.getByText(/Esc/)).toBeInTheDocument()
  })
})
