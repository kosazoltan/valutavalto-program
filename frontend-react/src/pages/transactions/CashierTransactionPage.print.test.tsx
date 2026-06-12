import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { vi, describe, beforeEach, afterEach, it, expect } from 'vitest'
import CashierTransactionPage from './CashierTransactionPage'

/**
 * Copilot PR #1100 (storno-minta átvezetés): a ReceiptPreviewModal CSAK sikeres
 * nyomtatás után zárhat be (2s auto-close). Sikertelen nyomtatásnál (printReceipt
 * false / hiányzó electronAPI / kivétel) az onPrint THROW-val zárul, így a modal
 * nyitva marad és a pénztáros újrapróbálhatja a nyomtatást.
 */

const mocks = vi.hoisted(() => ({
  navigate: vi.fn(),
  buy: vi.fn(),
  sell: vi.fn(),
  getCashierRateQuota: vi.fn(),
  exchangeRateList: vi.fn(),
  dailySessionIsOpen: vi.fn(),
  cashBalanceList: vi.fn(),
  createCancelledTransaction: vi.fn(),
  apiPost: vi.fn(),
  printReceipt: vi.fn(),
  // FK-KEZDIJ PR #1103: konfig-lekérés — elutasítva (offline ág, nincs auto-díj).
  handlingFeeConfigGet: vi.fn().mockRejectedValue(new Error('not mocked')),
  toast: { success: vi.fn(), warning: vi.fn(), error: vi.fn(), info: vi.fn() },
}))

vi.mock('react-router-dom', () => ({
  useNavigate: () => mocks.navigate,
  useSearchParams: () => [new URLSearchParams()],
}))

vi.mock('../../services/api/index', () => ({
  transactionApi: {
    buy: mocks.buy,
    sell: mocks.sell,
    getCashierRateQuota: mocks.getCashierRateQuota,
  },
  exchangeRateApi: { list: mocks.exchangeRateList },
  dailySessionApi: { isOpen: mocks.dailySessionIsOpen },
  cashBalanceApi: { list: mocks.cashBalanceList },
  receiptApi: { createCancelledTransaction: mocks.createCancelledTransaction },
  // FK-KEZDIJ PR #1103: a konfig-lekérés mockja — elutasítva = offline viselkedés
  // (nincs auto-díj); a print-tesztek viselkedését nem érinti.
  handlingFeeConfigApi: { get: mocks.handlingFeeConfigGet },
}))

vi.mock('../../services/api/client', () => ({
  api: { post: mocks.apiPost },
}))

vi.mock('../../stores/authStore', () => {
  const state = {
    worker: { id: 9, fullName: 'Fabulya Zsuzsanna', branchCode: 'BR076', companyCode: 'EBC', workerCode: 'FZS' },
    hasCanonicalRole: () => false,
  }
  const useAuthStore = Object.assign(
    (selector?: (s: typeof state) => unknown) => (selector ? selector(state) : state),
    { getState: () => state },
  )
  return { useAuthStore }
})

vi.mock('../../components/auth/AmlApproverModal', () => ({
  default: () => null,
  toApprovalCustomer: () => undefined,
}))

vi.mock('../../components/SuspicionReportModal', () => ({ default: () => null }))

vi.mock('./components/RateAuthDialog', () => ({ default: () => null }))

vi.mock('./components/CustomerPanel', () => ({ default: () => null }))

vi.mock('./hooks/useIdentificationLevel', () => ({
  useIdentificationLevel: () => ({
    identificationLevel: 'SIMPLE',
    minimumLevel: 'SIMPLE',
    setIdentificationLevel: () => {},
    requiresSourceVerification: false,
  }),
}))

vi.mock('../../components/cashier/HotkeyBar', () => ({ HotkeyBar: () => null }))

// Egyszerűsített autocomplete: a beírt 3 betűs kódra azonnal kiválasztja a hozzá
// tartozó árfolyamot (a data-rates attribútum jelzi, hogy a rates már betöltődött).
vi.mock('../../components/cashier/CurrencyAutocomplete', () => ({
  CurrencyAutocomplete: ({ rates, value, onChange, 'data-testid': testId }: {
    rates: Array<{ currencyCode: string }>
    value: string
    onChange: (code: string, rate: unknown) => void
    'data-testid'?: string
  }) => (
    <input
      data-testid={testId}
      data-rates={rates.length}
      value={value}
      onChange={(e) => {
        const code = e.target.value.toUpperCase()
        onChange(code, rates.find((r) => r.currencyCode === code) ?? null)
      }}
    />
  ),
}))

vi.mock('../../utils/electronTransactions', () => ({
  isElectronQueueAvailable: () => false,
  getElectronCachedRates: vi.fn(),
  mapCachedRatesToExchangeRates: vi.fn(),
  recordLocalAuditEvent: vi.fn(),
  saveAndSyncPendingBuySell: vi.fn(),
}))

vi.mock('../../utils/electron', () => ({ isElectron: () => true }))

vi.mock('../../components/ui/toaster', () => ({ toast: mocks.toast }))

const EUR_RATE = {
  currencyId: 1,
  currencyCode: 'EUR',
  currencyName: 'Euró',
  baseBuyRate: 391.5,
  baseSellRate: 398.5,
  active: true,
  officialRate: 395,
}

// A globális Window.electronAPI a teljes ElectronAPI felületet várja — a teszthez
// csak a printReceipt kell, ezért unknown-on át szűkítünk.
const electronWindow = window as unknown as { electronAPI?: { printReceipt?: (data: string) => Promise<boolean> } }

/** Egysoros EUR vétel rögzítése a REST úton → a bizonylat-előnézet modal megnyílik. */
async function submitBuyAndOpenReceiptModal() {
  render(<CashierTransactionPage />)

  const currencyInput = await screen.findByTestId('currency-input-0')
  await waitFor(() => expect(currencyInput).toHaveAttribute('data-rates', '1'))

  fireEvent.change(currencyInput, { target: { value: 'EUR' } })
  fireEvent.change(screen.getAllByPlaceholderText('0')[0]!, { target: { value: '100' } })
  fireEvent.click(screen.getByText('BIZONYLAT KÉSZÍTÉSE'))

  // a modal a sikeres mentés után nyílik — a Nyomtatás gomb a modal print gombja
  const printButton = await screen.findByRole('button', { name: 'Nyomtatás' })
  expect(screen.getByText('Mégse (ESC)')).toBeInTheDocument()
  return printButton
}

describe('CashierTransactionPage — sikertelen nyomtatásnál a bizonylat-modal nyitva marad (PR #1100 minta)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.dailySessionIsOpen.mockResolvedValue(true)
    mocks.exchangeRateList.mockResolvedValue([EUR_RATE])
    mocks.getCashierRateQuota.mockResolvedValue({ limit: 5, used: 0, remaining: 5, minAmountHuf: 400000 })
    mocks.cashBalanceList.mockResolvedValue([{ currencyCode: 'HUF', currentBalance: 10_000_000 }])
    mocks.apiPost.mockResolvedValue({ data: { requiresApproval: false } })
    mocks.buy.mockResolvedValue({ receiptNumber: 'V076100001' })
    electronWindow.electronAPI = { printReceipt: mocks.printReceipt }
  })

  afterEach(() => {
    delete electronWindow.electronAPI
  })

  it('printReceipt=false → error toast, a modal NYITVA marad, majd az újrapróbált sikeres nyomtatás zárja be', async () => {
    mocks.printReceipt.mockResolvedValueOnce(false)
    const printButton = await submitBuyAndOpenReceiptModal()

    fireEvent.click(printButton)
    await waitFor(() => expect(mocks.toast.error).toHaveBeenCalledWith(
      'Nyomtatás sikertelen',
      expect.stringContaining('A nyomtató offline'),
    ))

    // a 2s auto-close CSAK sikeres nyomtatásnál indul — hibánál a modal 2s után is nyitva van
    await new Promise((resolve) => setTimeout(resolve, 2200))
    expect(screen.getByText('Mégse (ESC)')).toBeInTheDocument()
    const retryButton = screen.getByRole('button', { name: 'Nyomtatás' })
    expect(retryButton).toBeEnabled()

    // újrapróbálás: most sikeres → success toast + 2s múlva auto-close
    mocks.printReceipt.mockResolvedValueOnce(true)
    fireEvent.click(retryButton)
    await waitFor(() => expect(mocks.toast.success).toHaveBeenCalledWith(
      'Nyomtatás elindítva',
      'Bizonylat: V076100001',
    ))
    await waitFor(
      () => expect(screen.queryByText('Mégse (ESC)')).not.toBeInTheDocument(),
      { timeout: 3000 },
    )
  }, 15000)

  it('printReceipt kivételt dob → "Nyomtatás váratlan hiba" toast és a modal nyitva marad', async () => {
    mocks.printReceipt.mockRejectedValueOnce(new Error('Soros port hiba'))
    const printButton = await submitBuyAndOpenReceiptModal()

    fireEvent.click(printButton)
    await waitFor(() => expect(mocks.toast.error).toHaveBeenCalledWith('Nyomtatás váratlan hiba', 'Soros port hiba'))

    await new Promise((resolve) => setTimeout(resolve, 2200))
    expect(screen.getByText('Mégse (ESC)')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Nyomtatás' })).toBeEnabled()
  }, 15000)

  it('hiányzó electronAPI → "Nyomtatás nem elérhető" warning és a modal nyitva marad', async () => {
    delete electronWindow.electronAPI
    const printButton = await submitBuyAndOpenReceiptModal()

    fireEvent.click(printButton)
    await waitFor(() => expect(mocks.toast.warning).toHaveBeenCalledWith(
      'Nyomtatás nem elérhető',
      expect.stringContaining('Electron preload'),
    ))

    await new Promise((resolve) => setTimeout(resolve, 2200))
    expect(screen.getByText('Mégse (ESC)')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Nyomtatás' })).toBeEnabled()
  }, 15000)
})
