import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import StornoPage from './StornoPage'

/**
 * FK-penztar-batch D.1+D.2 (2026-06-12, user-kérés):
 * - D.1: a sztornó űrlapon CSAK az indok marad — az „Egyedi árfolyam" és a „Fizetési mód"
 *   mezők megszűntek (a paymentMethodDid a backenden halott mező volt, az üres
 *   customExchangeRate defaultja az eredeti árfolyam).
 * - D.2: végrehajtás után sztornó-bizonylat előnézet (ReceiptPreviewModal, type='storno'),
 *   a navigáció a modal zárásakor történik.
 */

const mocks = vi.hoisted(() => ({
  useAuthStore: vi.fn(),
  navigate: vi.fn(),
  getById: vi.fn(),
  check: vi.fn(),
  execute: vi.fn(),
  requestApproval: vi.fn(),
  isElectronQueueAvailable: vi.fn(),
  saveAndSyncPendingStorno: vi.fn(),
  recordLocalAuditEvent: vi.fn(),
}))

vi.mock('react-router-dom', () => ({
  useParams: () => ({ id: 'tx-123' }),
  useNavigate: () => mocks.navigate,
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: mocks.useAuthStore,
}))

vi.mock('../../services/api/index', () => ({
  transactionApi: { getById: mocks.getById },
  stornoApi: { check: mocks.check, execute: mocks.execute, requestApproval: mocks.requestApproval },
}))

vi.mock('../../utils/electronTransactions', () => ({
  isElectronQueueAvailable: mocks.isElectronQueueAvailable,
  saveAndSyncPendingStorno: mocks.saveAndSyncPendingStorno,
  recordLocalAuditEvent: mocks.recordLocalAuditEvent,
}))

vi.mock('../../utils/localQueue', () => ({
  getCompanyType: () => 'BEST_CHANGE',
}))

vi.mock('../../components/auth/StornoPinApprovalModal', () => ({
  default: () => null,
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: { success: vi.fn(), error: vi.fn(), warning: vi.fn(), info: vi.fn() },
}))

const mockWorker = {
  id: 9,
  fullName: 'Fabulya Zsuzsanna',
  branchCode: 'BR076',
  companyCode: 'EBC',
}

const mockTransaction = {
  id: 555,
  receiptNumber: 'V076100003',
  transactionType: 'BUY',
  currencyCode: 'EUR',
  currencyAmount: 1000,
  exchangeRate: 343,
  hufAmount: 343000,
  createdAt: '2026-06-12T08:03:08',
  customerName: 'kiss géza',
  customerDocumentNumber: null,
}

async function renderLoaded() {
  render(<StornoPage />)
  await screen.findByText('V076100003')
}

describe('FK-penztar-batch D.1+D.2 — StornoPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.useAuthStore.mockImplementation(
      (selector?: (s: { worker: typeof mockWorker }) => unknown) => {
        const state = { worker: mockWorker }
        return selector ? selector(state) : state
      },
    )
    mocks.getById.mockResolvedValue(mockTransaction)
    mocks.check.mockResolvedValue({ requiresApproval: false, message: 'Sztornó végrehajtható.', dailyStornoCount: 0 })
    mocks.isElectronQueueAvailable.mockReturnValue(false) // online ág
  })

  it('D.1: csak az indok mező van — nincs egyedi árfolyam input, nincs fizetési mód select', async () => {
    await renderLoaded()
    expect(screen.getByPlaceholderText('Részletesen indokolja a sztornó okát...')).toBeInTheDocument()
    // a két eltávolított mező egyik formájában sem létezik
    expect(screen.queryByText(/Egyedi árfolyam/i)).toBeNull()
    expect(screen.queryByText(/Fizetési mód/i)).toBeNull()
    expect(screen.queryByRole('combobox')).toBeNull()
    expect(screen.queryByRole('spinbutton')).toBeNull()
  })

  it('D.1: a végrehajtási request csak transactionId + reason (+approvalId) — nincs customExchangeRate/paymentMethodDid', async () => {
    mocks.execute.mockResolvedValue({ ...mockTransaction, id: 556, receiptNumber: 'V076100004' })
    await renderLoaded()

    fireEvent.change(screen.getByPlaceholderText('Részletesen indokolja a sztornó okát...'), {
      target: { value: 'Teszt' },
    })
    fireEvent.click(screen.getByText('Sztornó végrehajtása'))

    await waitFor(() => expect(mocks.execute).toHaveBeenCalled())
    const request = mocks.execute.mock.calls[0]![0] as Record<string, unknown>
    expect(request).toMatchObject({ transactionId: 'tx-123', reason: 'Teszt' })
    expect(request).not.toHaveProperty('customExchangeRate')
    expect(request).not.toHaveProperty('paymentMethodDid')
  })

  it('D.2: siker után sztornó-bizonylat előnézet nyílik a reversal sorszámával + eredeti bizonylatszámmal; zárásra navigál', async () => {
    mocks.execute.mockResolvedValue({ ...mockTransaction, id: 556, receiptNumber: 'V076100004' })
    await renderLoaded()

    fireEvent.change(screen.getByPlaceholderText('Részletesen indokolja a sztornó okát...'), {
      target: { value: 'Teszt' },
    })
    fireEvent.click(screen.getByText('Sztornó végrehajtása'))

    // a modal megjelenik: a sztornó SAJÁT bizonylatszáma + az eredeti hivatkozás
    // (az eredeti szám a háttér tranzakció-paneljén IS szerepel → legalább 2 találat)
    await screen.findByText(/V076100004/)
    expect(screen.getAllByText(/V076100003/).length).toBeGreaterThanOrEqual(2)
    expect(mocks.navigate).not.toHaveBeenCalled() // navigáció CSAK záráskor

    // zárás → navigate a siker-üzenettel
    fireEvent.click(screen.getByText('Mégse (ESC)'))
    await waitFor(() => expect(mocks.navigate).toHaveBeenCalledWith('/transactions', {
      state: { message: 'Sztornó sikeresen végrehajtva' },
    }))
  })

  it('D.2 offline ág: a pending-mentés customExchangeRate/paymentMethod nélkül (null) megy, és helyi referenciás bizonylat nyílik', async () => {
    mocks.isElectronQueueAvailable.mockReturnValue(true)
    mocks.saveAndSyncPendingStorno.mockResolvedValue({
      savedIds: [1], syncedCount: 1, pendingCount: 0, allSavedSynced: true,
      syncErrors: [], localReferenceNumbers: ['LST-2026-0001'],
    })
    await renderLoaded()

    fireEvent.change(screen.getByPlaceholderText('Részletesen indokolja a sztornó okát...'), {
      target: { value: 'Teszt' },
    })
    fireEvent.click(screen.getByText('Sztornó végrehajtása'))

    await waitFor(() => expect(mocks.saveAndSyncPendingStorno).toHaveBeenCalled())
    const entry = mocks.saveAndSyncPendingStorno.mock.calls[0]![0] as Record<string, unknown>
    expect(entry.customExchangeRate).toBeNull()
    expect(entry.paymentMethod).toBeNull()
    await screen.findByText(/LST-2026-0001/)
  })
})
