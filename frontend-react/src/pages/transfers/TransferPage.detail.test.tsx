import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import TransferPage from './TransferPage'

const mocks = vi.hoisted(() => ({
  getOutgoing: vi.fn(),
  getIncoming: vi.fn(),
  getPending: vi.fn(),
  countPending: vi.fn(),
  getById: vi.fn(),
  getByTransferNumber: vi.fn(),
  getActive: vi.fn(),
  listActive: vi.fn(),
  toast: { success: vi.fn(), warning: vi.fn(), error: vi.fn(), info: vi.fn() },
}))

vi.mock('../../services/api/index', () => ({
  transferApi: {
    getOutgoing: mocks.getOutgoing,
    getIncoming: mocks.getIncoming,
    getPending: mocks.getPending,
    countPending: mocks.countPending,
    getById: mocks.getById,
    getByTransferNumber: mocks.getByTransferNumber,
    create: vi.fn(),
    receive: vi.fn(),
    reject: vi.fn(),
    cancel: vi.fn(),
    storno: vi.fn(),
    getStornoPreview: vi.fn(),
  },
  currencyApi: { getActive: mocks.getActive },
  branchApi: { listActive: mocks.listActive },
  cashBalanceApi: { list: vi.fn() },
  denominationApi: { getByCurrency: vi.fn() },
  exchangeRateApi: { list: vi.fn() },
}))

vi.mock('../../stores/authStore', () => {
  const state = {
    worker: {
      id: 9,
      fullName: 'Fabulya Zsuzsanna',
      branchId: 'b-own',
      branchCode: 'BR076',
      branchName: 'Pécsi értéktár',
      companyCode: 'EBC',
    },
  }
  return {
    useAuthStore: (selector?: (s: typeof state) => unknown) => (selector ? selector(state) : state),
  }
})

vi.mock('../../utils/electronTransactions', () => ({
  isElectronQueueAvailable: () => false,
  recordLocalAuditEvent: vi.fn(),
  saveAndSyncPendingTransfer: vi.fn(),
  getElectronCachedRates: vi.fn(),
}))

vi.mock('../../utils/localQueue', () => ({
  getLocalPendingTransfers: vi.fn().mockResolvedValue([]),
  getCompanyType: () => 'BEST_CHANGE',
  queueOfflineTransferStorno: vi.fn(),
}))

vi.mock('../../components/auth/SupervisorPinModal', () => ({ default: () => null }))

vi.mock('../../components/NumberInput', () => ({
  NumberInput: ({ value, onChange, id }: {
    value: string
    onChange: (v: string) => void
    id?: string
  }) => (
    <input id={id} value={value} onChange={(event) => onChange(event.target.value)} />
  ),
}))

vi.mock('../../utils/electron', () => ({ isElectron: () => true }))

vi.mock('../../components/ui/toaster', () => ({ toast: mocks.toast }))

const pendingTransfer = {
  id: 7,
  transferNumber: 'AT-LIST-007',
  fromBranchCode: 'BR001',
  fromBranchName: 'Budapesti értéktár',
  toBranchCode: 'BR076',
  toBranchName: 'Pécsi értéktár',
  fromWorkerName: 'Lista Béla',
  transferDate: '2026-06-19',
  transferTime: '10:00:00',
  currencyCode: 'EUR',
  amount: 100,
  hufValue: 39000,
  status: 'PENDING',
  statusDisplay: 'Átvételre vár',
  isPending: true,
  isCompleted: false,
  direction: 'U',
  transferType: 'CURRENCY',
  transferTypeDisplay: 'Deviza',
}

describe('TransferPage — átadás részlet betöltése átvételhez', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.getOutgoing.mockResolvedValue([])
    mocks.getIncoming.mockResolvedValue([])
    mocks.getPending.mockResolvedValue([pendingTransfer])
    mocks.countPending.mockResolvedValue(1)
    mocks.getActive.mockResolvedValue([{ id: 1, code: 'EUR', name: 'Euró' }])
    mocks.listActive.mockResolvedValue([
      { id: 'b-own', code: 'BR076', name: 'Pécsi értéktár', isVault: true, branchTypeCode: 'VAULT' },
      { id: 'b-source', code: 'BR001', name: 'Budapesti értéktár', isVault: true, branchTypeCode: 'VAULT' },
    ])
    mocks.getById.mockResolvedValue({
      ...pendingTransfer,
      transferNumber: 'AT-BACKEND-007',
      fromWorkerName: 'Backend Anna',
      amount: 125.5,
      hufValue: 48945,
    })
    mocks.getByTransferNumber.mockResolvedValue({
      ...pendingTransfer,
      id: 8,
      transferNumber: 'AT-NUMBER-008',
      fromWorkerName: 'Keresett Anna',
      amount: 75,
      hufValue: 29250,
    })
  })

  it('az Átvétel gomb a backend transfer detail endpointból frissíti a modalt', async () => {
    render(
      <MemoryRouter>
        <TransferPage />
      </MemoryRouter>,
    )

    await screen.findByText('AT-LIST-007')
    fireEvent.click(screen.getByTitle('Átvétel'))

    await waitFor(() => expect(mocks.getById).toHaveBeenCalledWith(7))
    await screen.findByText('AT-BACKEND-007')

    expect(screen.getByText('Backend Anna')).toBeInTheDocument()
    expect(screen.getByDisplayValue('125,5')).toBeInTheDocument()
  })

  it('átadólap szám alapján backend detailből nyitja meg a bizonylat-előnézetet', async () => {
    render(
      <MemoryRouter>
        <TransferPage />
      </MemoryRouter>,
    )

    await screen.findByText('AT-LIST-007')
    fireEvent.change(screen.getByLabelText('Átadólap keresése'), { target: { value: 'AT-SEARCH-008' } })
    fireEvent.click(screen.getByRole('button', { name: 'Keresés' }))

    await waitFor(() => expect(mocks.getByTransferNumber).toHaveBeenCalledWith('AT-SEARCH-008'))
    await screen.findByText('AT-NUMBER-008')
    expect(screen.getByText('Átvételi bizonylat')).toBeInTheDocument()
  })
})
