import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import TransferPage from './TransferPage'

const mocks = vi.hoisted(() => ({
  getOutgoing: vi.fn(),
  getIncoming: vi.fn(),
  getPending: vi.fn(),
  countPending: vi.fn(),
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
    getById: vi.fn(),
    getByTransferNumber: vi.fn(),
    receive: vi.fn(),
    reject: vi.fn(),
    cancel: vi.fn(),
    storno: vi.fn(),
    getStornoPreview: vi.fn(),
  },
  currencyApi: { getActive: mocks.getActive },
  branchApi: { listActive: mocks.listActive },
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
}))

vi.mock('../../utils/localQueue', () => ({
  getLocalPendingTransfers: vi.fn().mockResolvedValue([]),
  getCompanyType: () => 'BEST_CHANGE',
  queueOfflineTransferStorno: vi.fn(),
}))

vi.mock('../../components/NumberInput', () => ({
  NumberInput: ({
    value,
    onChange,
    id,
  }: {
    value: string
    onChange: (v: string) => void
    id?: string
  }) => <input id={id} value={value} onChange={(event) => onChange(event.target.value)} />,
}))

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

describe('TransferPage — visszaigazolás és létrehozás szétválasztása', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.getOutgoing.mockResolvedValue([])
    mocks.getIncoming.mockResolvedValue([])
    mocks.getPending.mockResolvedValue([pendingTransfer])
    mocks.countPending.mockResolvedValue(1)
    mocks.getActive.mockResolvedValue([{ id: 1, code: 'EUR', name: 'Euró' }])
    mocks.listActive.mockResolvedValue([
      {
        id: 'b-own',
        code: 'BR076',
        name: 'Pécsi értéktár',
        isVault: true,
        branchTypeCode: 'VAULT',
      },
    ])
  })

  it('csak a visszaigazolás-felületet és az új létrehozás linkjét mutatja', async () => {
    render(
      <MemoryRouter>
        <TransferPage />
      </MemoryRouter>,
    )

    await screen.findByText('AT-LIST-007')

    expect(
      screen.getByRole('heading', { name: /Átadás-átvétel visszaigazolás \(aláírás\)/ }),
    ).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /Átvételre váró/ })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Kimenő átadások' })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Bejövő átadások' })).toBeInTheDocument()
    expect(screen.queryByText('Átadás létrehozása')).not.toBeInTheDocument()
    expect(document.querySelector('#transfer-type')).not.toBeInTheDocument()
    expect(screen.getByRole('link', { name: /Új átadás/ })).toHaveAttribute(
      'href',
      '/transfers/new',
    )
  })
})
