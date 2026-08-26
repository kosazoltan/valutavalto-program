import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import CashierTransactionPage from './CashierTransactionPage'

const mocks = vi.hoisted(() => ({
  navigate: vi.fn(),
  buy: vi.fn(),
  sell: vi.fn(),
  getCashierRateQuota: vi.fn(),
  exchangeRateList: vi.fn(),
  dailySessionIsOpen: vi.fn(),
  cashBalanceList: vi.fn(),
  createCancelledTransaction: vi.fn(),
  apiGet: vi.fn(),
  apiPost: vi.fn(),
  checkRequired: vi.fn(),
  sendEmail: vi.fn(),
  recordLocalAuditEvent: vi.fn(),
  // FK-097 WU-15 (W5): a dij-konfigot a cache-first loadHandlingFeeConfig adja —
  // alapertelmezesben elutasitva (offline ag, nincs auto-dij).
  loadHandlingFeeConfig: vi.fn().mockRejectedValue(new Error('not mocked')),
  discountThresholdApply: vi.fn(),
  listActive: vi.fn(),
  submitAnswer: vi.fn(),
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
  incomeSourceDocApi: { checkRequired: mocks.checkRequired, sendEmail: mocks.sendEmail },
  discountThresholdApi: { apply: mocks.discountThresholdApply },
}))

vi.mock('../../services/api/client', () => ({
  api: { get: mocks.apiGet, post: mocks.apiPost },
}))

// FK-097 WU-15 (W5): mock-felulet-migracio — az oldal a dij-konfigot a cache-first
// loadHandlingFeeConfigon at olvassa (utils/handlingFee), nem handlingFeeConfigApi.get-en.
// A tiszta computeHandlingFee valtozatlanul az igazi marad.
vi.mock('../../utils/handlingFee', async (importOriginal) => {
  const actual = await importOriginal<typeof import('../../utils/handlingFee')>()
  return { ...actual, loadHandlingFeeConfig: mocks.loadHandlingFeeConfig }
})

vi.mock('../../services/api/complianceQuestions', () => ({
  complianceQuestionApi: { listActive: mocks.listActive, submitAnswer: mocks.submitAnswer },
}))

vi.mock('../../stores/authStore', () => {
  const state = {
    worker: {
      id: 9,
      fullName: 'Fabulya Zsuzsanna',
      branchCode: 'BR076',
      companyCode: 'EBC',
      workerCode: 'FZS',
    },
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
vi.mock('./components/CustomerPanel', () => ({
  default: ({ onCustomerReady }: { onCustomerReady: (d: unknown) => void }) => (
    <div>
      <button
        type="button"
        onClick={() =>
          onCustomerReady({
            id: 42,
            name: 'Teszt Elek',
            documentType: 'ID_CARD',
            documentNumber: 'AB123456',
            nationality: 'Magyar',
          })
        }
      >
        mock-customer-select
      </button>
      <button
        type="button"
        onClick={() =>
          onCustomerReady({
            name: 'Kézi Ügyfél',
            documentType: 'ID_CARD',
            documentNumber: '',
            nationality: 'Magyar',
          })
        }
      >
        mock-customer-manual
      </button>
      <button type="button" onClick={() => onCustomerReady(null)}>
        mock-customer-clear
      </button>
    </div>
  ),
}))
vi.mock('./hooks/useIdentificationLevel', () => ({
  useIdentificationLevel: () => ({
    identificationLevel: 'SIMPLE',
    minimumLevel: 'SIMPLE',
    setIdentificationLevel: () => {},
    requiresSourceVerification: false,
  }),
}))
vi.mock('../../components/cashier/HotkeyBar', () => ({ HotkeyBar: () => null }))
vi.mock('../../components/documents/IncomeSourceDocCapture', () => ({
  default: ({ onCaptured, onClear }: { onCaptured(base64: string): void; onClear(): void }) => (
    <div>
      <button type="button" onClick={() => onCaptured('bm9uLWVtcHR5LWltYWdl')}>
        mock-income-proof-capture
      </button>
      <button type="button" onClick={onClear}>
        mock-income-proof-clear
      </button>
    </div>
  ),
}))
vi.mock('../../components/cashier/CurrencyAutocomplete', () => ({
  CurrencyAutocomplete: ({
    rates,
    value,
    onChange,
    'data-testid': testId,
  }: {
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
  recordLocalAuditEvent: mocks.recordLocalAuditEvent,
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

const q = (over: Record<string, unknown> = {}) => ({
  id: 'q-1',
  questionText: 'Politikai közszereplő-e Ön?',
  questionType: 'YES_NO',
  displayOrder: 1,
  active: true,
  createdByWorkerCode: 'W1',
  createdAt: '2026-07-08T10:00:00',
  updatedAt: '2026-07-08T10:00:00',
  ...over,
})

async function fillBuyAndSubmit() {
  const currencyInput = await screen.findByTestId('currency-input-0')
  await waitFor(() => expect(currencyInput).toHaveAttribute('data-rates', '1'))
  fireEvent.change(currencyInput, { target: { value: 'EUR' } })
  fireEvent.change(screen.getAllByPlaceholderText('0')[0]!, { target: { value: '1000' } })
  fireEvent.click(screen.getByText('BIZONYLAT KÉSZÍTÉSE'))
}

describe('CashierTransactionPage — compliance kérdések', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.dailySessionIsOpen.mockResolvedValue(true)
    mocks.exchangeRateList.mockResolvedValue([EUR_RATE])
    mocks.getCashierRateQuota.mockResolvedValue({
      limit: 5,
      used: 0,
      remaining: 5,
      minAmountHuf: 400000,
    })
    mocks.cashBalanceList.mockResolvedValue([{ currencyCode: 'HUF', currentBalance: 20_000_000 }])
    mocks.apiGet.mockResolvedValue({ data: { canApprove: true } })
    mocks.apiPost.mockResolvedValue({ data: { requiresApproval: false } })
    mocks.checkRequired.mockResolvedValue({ required: false })
    mocks.sendEmail.mockResolvedValue({ sentTo: 1 })
    mocks.listActive.mockResolvedValue([q()])
    mocks.buy.mockResolvedValue({ receiptNumber: 'V076100001', hufAmount: 391_500 })
    mocks.discountThresholdApply.mockImplementation((_hufAmount: number, originalFee: number) =>
      Promise.resolve({
        originalFee,
        adjustedFee: originalFee,
        discountCode: '',
        discountName: 'Nincs automatikus kedvezmény',
      }),
    )
    mocks.recordLocalAuditEvent.mockResolvedValue(1)
  })

  it('mentett ügyfél nélkül a blokk nem jelenik meg és listActive sem hívódik', async () => {
    render(<CashierTransactionPage />)
    await screen.findByTestId('currency-input-0')
    expect(screen.queryByTestId('compliance-questions-block')).not.toBeInTheDocument()
    expect(mocks.listActive).not.toHaveBeenCalled()
  })

  it('id NÉLKÜLI (kézi) ügyfél-adatnál sem jelenik meg a blokk — fail-closed', async () => {
    render(<CashierTransactionPage />)
    fireEvent.click(await screen.findByRole('button', { name: 'mock-customer-manual' }))
    await waitFor(() =>
      expect(screen.queryByTestId('compliance-questions-block')).not.toBeInTheDocument(),
    )
    expect(mocks.listActive).not.toHaveBeenCalled()
  })

  it('mentett ügyfélnél a blokk megjelenik az aktív kérdésekkel', async () => {
    render(<CashierTransactionPage />)
    fireEvent.click(await screen.findByRole('button', { name: 'mock-customer-select' }))
    expect(await screen.findByTestId('compliance-questions-block')).toBeInTheDocument()
    expect(screen.getByText('Politikai közszereplő-e Ön?')).toBeInTheDocument()
    expect(mocks.listActive).toHaveBeenCalledTimes(1)
  })

  it('listActive-hiba NEM blokkolja a buy submitet', async () => {
    mocks.listActive.mockRejectedValue(new Error('compliance down'))
    render(<CashierTransactionPage />)
    fireEvent.click(await screen.findByRole('button', { name: 'mock-customer-select' }))
    await fillBuyAndSubmit()
    await waitFor(() => expect(mocks.buy).toHaveBeenCalledTimes(1))
    expect(screen.queryByTestId('compliance-questions-block')).not.toBeInTheDocument()
  })

  it('ügyfél törlésekor a blokk eltűnik', async () => {
    render(<CashierTransactionPage />)
    fireEvent.click(await screen.findByRole('button', { name: 'mock-customer-select' }))
    await screen.findByTestId('compliance-questions-block')
    fireEvent.click(screen.getByRole('button', { name: 'mock-customer-clear' }))
    await waitFor(() =>
      expect(screen.queryByTestId('compliance-questions-block')).not.toBeInTheDocument(),
    )
  })

  it('sikeres buy után a blokk resetel (eltűnik az ügyféllel együtt)', async () => {
    render(<CashierTransactionPage />)
    fireEvent.click(await screen.findByRole('button', { name: 'mock-customer-select' }))
    await screen.findByTestId('compliance-questions-block')
    await fillBuyAndSubmit()
    await waitFor(() => expect(mocks.buy).toHaveBeenCalledTimes(1))
    await waitFor(() =>
      expect(screen.queryByTestId('compliance-questions-block')).not.toBeInTheDocument(),
    )
  })
})
