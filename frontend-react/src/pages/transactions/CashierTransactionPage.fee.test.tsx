import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import CashierTransactionPage from './CashierTransactionPage'

/**
 * FK-097 WU-15 (FR-6): feltöltött helyi cache + elutasító HTTP mellett a díjmező
 * ZÁRT marad és az automatikus díj nem null. A TESZT A VALÓDI loadHandlingFeeConfigot
 * futtatja (nem mockolja): az electronTransactions-cache sorral töltött, a
 * branchFeeConfigApi.own elutasít — így bizonyított, hogy az oldal offline is a
 * cache-ből dolgozik és NEM nyitja ki a kézi díjbeírást.
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
  apiGet: vi.fn(),
  apiPost: vi.fn(),
  checkRequired: vi.fn(),
  sendEmail: vi.fn(),
  recordLocalAuditEvent: vi.fn(),
  // FR-6: a HTTP végpont elutasít — a cache-ből kell jönnie a konfignak.
  branchFeeOwn: vi.fn().mockRejectedValue(new Error('offline')),
  // FR-6: feltöltött SQLite-tükör (PER_MILLE 10‰, sapka nélkül).
  cachedHandlingFeeConfig: vi.fn().mockResolvedValue({
    branch_id: 'b-1',
    branch_code: 'BR076',
    company_id: 'c-1',
    fee_mode: 'PER_MILLE',
    per_mille_rate: 10,
    per_mille_cap: null,
    bracket_json: null,
    valid_from: '2026-08-26',
    synced_at: '2026-08-26T19:00:00Z',
  }),
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

// A VALÓDI loadHandlingFeeConfig fut — csak a HTTP forrása (branchFeeConfigApi.own)
// elutasító, a cache-forrás töltött (lásd az electronTransactions-mockot).
vi.mock('../../services/api/settings', async (importOriginal) => {
  const actual = await importOriginal<typeof import('../../services/api/settings')>()
  return { ...actual, branchFeeConfigApi: { own: mocks.branchFeeOwn } }
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
// Offline pénztár: az Electron-queue elérhető, a díj-cache FELTÖLTÖTT, az árfolyam-cache
// üres (így az árfolyam a mockolt HTTP-listából jön — a díj-ágat ez nem érinti).
vi.mock('../../utils/electronTransactions', () => ({
  isElectronQueueAvailable: () => true,
  getElectronCachedHandlingFeeConfig: mocks.cachedHandlingFeeConfig,
  getElectronCachedRates: vi.fn().mockResolvedValue([]),
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

describe('CashierTransactionPage — FK-097 FR-6 offline cache-first díjmező', () => {
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
    mocks.buy.mockResolvedValue({ receiptNumber: 'V076100001', hufAmount: 39_150 })
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

  it('feltöltött cache + elutasító HTTP → a díjmező ZÁRT, az auto díj nem null, HTTP nem hívódik', async () => {
    render(<CashierTransactionPage />)

    const currencyInput = await screen.findByTestId('currency-input-0')
    await waitFor(() => expect(currencyInput).toHaveAttribute('data-rates', '1'))
    fireEvent.change(currencyInput, { target: { value: 'EUR' } })
    fireEvent.change(screen.getAllByPlaceholderText('0')[0]!, { target: { value: '100' } })
    // subtotal = 100 × 391.5 = 39 150 HUF; PER_MILLE 10‰ → round(391.5) = 392 → 5 Ft-os
    // kerekítéssel 390. A discount-threshold mock az eredeti díjat adja vissza.

    fireEvent.keyDown(document, { key: 'F9', code: 'F9' })
    await screen.findByText('Kezelési díj / Kedvezmény')

    const feeInput = screen.getAllByRole('spinbutton')[0]!
    expect(feeInput).toBeDisabled()
    expect(feeInput).toHaveValue(390)

    // FR-4: a cache-találat miatt a HTTP-fallback meg sem történt.
    expect(mocks.branchFeeOwn).not.toHaveBeenCalled()
    expect(mocks.cachedHandlingFeeConfig).toHaveBeenCalled()
  })
})
