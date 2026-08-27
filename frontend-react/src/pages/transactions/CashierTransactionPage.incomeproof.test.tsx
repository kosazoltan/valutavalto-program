import { render, screen, fireEvent, waitFor, within } from '@testing-library/react'
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

async function fillLargeBuyAndSubmit() {
  render(<CashierTransactionPage />)

  const currencyInput = await screen.findByTestId('currency-input-0')
  await waitFor(() => expect(currencyInput).toHaveAttribute('data-rates', '1'))

  fireEvent.change(currencyInput, { target: { value: 'EUR' } })
  fireEvent.change(screen.getAllByPlaceholderText('0')[0]!, { target: { value: '30652' } })
  fireEvent.click(screen.getByText('BIZONYLAT KÉSZÍTÉSE'))
}

describe('CashierTransactionPage — jövedelemforrás-igazolás 10M+ vétel', () => {
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
    mocks.checkRequired.mockResolvedValue({ required: true, thresholdHuf: 10_000_000 })
    mocks.sendEmail.mockResolvedValue({ sentTo: 1 })
    mocks.buy.mockResolvedValue({ receiptNumber: 'V076100001', hufAmount: 12_000_260 })
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

  it('12M vételnél required check után modal nyílik, tranzakció még nem készül', async () => {
    await fillLargeBuyAndSubmit()

    expect(await screen.findByText('Jövedelemforrás-igazolás (10M+ vétel)')).toBeInTheDocument()
    expect(mocks.buy).not.toHaveBeenCalled()
  })

  it('capture modal Mégse gombja fail-closed módon zár és nem készít tranzakciót', async () => {
    await fillLargeBuyAndSubmit()

    const modal = await screen.findByTestId('income-proof-capture-modal')
    fireEvent.click(within(modal).getByRole('button', { name: 'Mégse' }))

    await waitFor(() =>
      expect(screen.queryByTestId('income-proof-capture-modal')).not.toBeInTheDocument(),
    )
    expect(mocks.buy).not.toHaveBeenCalled()
    expect(mocks.sendEmail).not.toHaveBeenCalled()
  })

  it('capture után újrahívott submit tranzakciót készít és egyszer küldi az emailt a bizonylat-ref-fel', async () => {
    await fillLargeBuyAndSubmit()

    fireEvent.click(await screen.findByRole('button', { name: 'mock-income-proof-capture' }))

    await waitFor(() => expect(mocks.buy).toHaveBeenCalledTimes(1))
    await waitFor(() => expect(mocks.sendEmail).toHaveBeenCalledTimes(1))
    expect(mocks.sendEmail).toHaveBeenCalledWith(
      expect.objectContaining({
        imageBase64: 'bm9uLWVtcHR5LWltYWdl',
        mimeType: 'image/jpeg',
        transactionRef: 'V076100001',
        hufAmount: 12_000_260,
      }),
    )
  })

  it('email-küldés hibánál retry UI látszik, Mégse auditot ír kép nélkül', async () => {
    mocks.sendEmail.mockRejectedValue(new Error('smtp down'))
    await fillLargeBuyAndSubmit()

    fireEvent.click(await screen.findByRole('button', { name: 'mock-income-proof-capture' }))

    const sendModal = await screen.findByTestId('income-proof-send-modal')
    expect(within(sendModal).getByRole('button', { name: 'Újra' })).toBeInTheDocument()

    fireEvent.click(within(sendModal).getByRole('button', { name: 'Mégse' }))

    await waitFor(() =>
      expect(mocks.recordLocalAuditEvent).toHaveBeenCalledWith(
        expect.objectContaining({
          entityType: 'income_proof',
          eventType: 'INCOME_PROOF_EMAIL_UNFULFILLED',
          status: 'degraded',
        }),
      ),
    )
    const auditPayload = mocks.recordLocalAuditEvent.mock.calls[0]![0].payload
    expect(auditPayload).toMatchObject({
      workerCode: 'FZS',
      hufTotal: 12_000_260,
      transactionRef: 'V076100001',
      reason: 'küldés sikertelen, pénztáros megszakította',
    })
    expect(auditPayload).not.toHaveProperty('imageBase64')
    expect(auditPayload).not.toHaveProperty('image')
  })
})
