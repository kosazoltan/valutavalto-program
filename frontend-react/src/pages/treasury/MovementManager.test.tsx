import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import MovementManager from './MovementManager'

const mocks = vi.hoisted(() => ({
  transferGetPending: vi.fn(),
  transferSearch: vi.fn(),
  currencyList: vi.fn(),
  branchListVaultCounterparties: vi.fn(),
  sealGetNext: vi.fn(),
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string) => key,
  }),
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: unknown) => unknown) =>
    selector({
      worker: {
        id: 1,
        workerCode: 'W0001',
        fullName: 'Teszt Admin',
        role: 'ADMIN',
        branchId: 'branch-1',
        branchCode: 'SZEGED',
        branchName: 'Szeged Értéktár',
        companyId: 'company-1',
        companyCode: 'EBC',
        companyName: 'EBC Valutaváltó',
      },
    }),
}))

vi.mock('../../utils/electronTransactions', () => ({
  isElectronQueueAvailable: () => false,
  recordLocalAuditEvent: vi.fn(),
  saveAndSyncPendingTransfer: vi.fn(),
}))

vi.mock('../../utils/localQueue', () => ({
  getLocalPendingTransfers: vi.fn().mockResolvedValue([]),
}))

vi.mock('../../services/api/index', () => ({
  transferApi: {
    getPending: mocks.transferGetPending,
    search: mocks.transferSearch,
  },
  currencyApi: {
    list: mocks.currencyList,
  },
  branchApi: {
    listVaultCounterparties: mocks.branchListVaultCounterparties,
  },
  sealNumberApi: {
    getNext: mocks.sealGetNext,
  },
}))

describe('MovementManager', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.transferGetPending.mockResolvedValue([])
    mocks.transferSearch.mockResolvedValue({
      content: [],
      totalElements: 0,
      totalPages: 0,
      size: 50,
      number: 0,
    })
    mocks.currencyList.mockResolvedValue([{ id: 1, code: 'EUR', name: 'Euró', active: true }])
    mocks.branchListVaultCounterparties.mockResolvedValue({
      territorialCashiers: [],
      peerVaults: [],
      fixedCounterparties: [],
    })
    mocks.sealGetNext.mockResolvedValue({ sealNumber: 'SZEGED-20260618-001' })
  })

  it('backend plombaszám preview endpointból tölti ki az új mozgás plombaszámát', async () => {
    render(<MovementManager />)

    await screen.findByText('treasury.ujMozgas')
    fireEvent.click(screen.getByText('treasury.ujMozgas'))
    fireEvent.click(screen.getByText('Generálás'))

    await waitFor(() => {
      expect(mocks.sealGetNext).toHaveBeenCalledWith('SZEGED')
      expect(screen.getByDisplayValue('SZEGED-20260618-001')).toBeInTheDocument()
    })
  })
})
