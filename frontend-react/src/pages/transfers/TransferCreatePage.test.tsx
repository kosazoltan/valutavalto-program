import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import TransferCreatePage from './TransferCreatePage'

const mocks = vi.hoisted(() => ({
  create: vi.fn(),
  getActive: vi.fn(),
  listActive: vi.fn(),
  cashBalanceList: vi.fn(),
  rateList: vi.fn(),
  denominationList: vi.fn(),
  isElectronQueueAvailable: vi.fn(),
  saveAndSyncPendingTransfer: vi.fn(),
  getElectronCachedRates: vi.fn(),
  toast: { success: vi.fn(), warning: vi.fn(), error: vi.fn(), info: vi.fn() },
}))

vi.mock('../../services/api/index', () => ({
  transferApi: { create: mocks.create },
  currencyApi: { getActive: mocks.getActive },
  branchApi: { listActive: mocks.listActive },
  cashBalanceApi: { list: mocks.cashBalanceList },
  denominationApi: { getByCurrencyId: mocks.denominationList },
  exchangeRateApi: { list: mocks.rateList },
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
  isElectronQueueAvailable: mocks.isElectronQueueAvailable,
  recordLocalAuditEvent: vi.fn(),
  saveAndSyncPendingTransfer: mocks.saveAndSyncPendingTransfer,
  getElectronCachedRates: mocks.getElectronCachedRates,
}))

vi.mock('../../utils/localQueue', () => ({
  getCompanyType: () => 'BEST_CHANGE',
}))

vi.mock('../../components/auth/SupervisorPinModal', () => ({ default: () => null }))

vi.mock('../../components/NumberInput', () => ({
  NumberInput: ({
    value,
    onChange,
    id,
    placeholder,
  }: {
    value: string
    onChange: (v: string) => void
    id?: string
    placeholder?: string
  }) => (
    <input
      id={id}
      placeholder={placeholder}
      value={value}
      onChange={(event) => onChange(event.target.value)}
    />
  ),
}))

vi.mock('../../utils/electron', () => ({ isElectron: () => true }))
vi.mock('../../components/ui/toaster', () => ({ toast: mocks.toast }))

const CURRENCIES = [
  { id: 1, code: 'EUR', name: 'Euró' },
  { id: 2, code: 'HUF', name: 'Forint' },
]

const ownBranch = (isVault: boolean) => ({
  id: 'b-own',
  code: 'BR076',
  name: 'Pécsi értéktár',
  isVault,
  branchTypeCode: isVault ? 'VAULT' : 'CASH_DESK',
  region: 'DD',
  vaultTerritoryId: 1,
})

const targetBranch = {
  id: 'b-target',
  code: 'BR001',
  name: 'Budapesti értéktár',
  isVault: true,
  branchTypeCode: 'VAULT',
  region: 'DD',
  vaultTerritoryId: 1,
}

function renderPage() {
  render(
    <MemoryRouter>
      <TransferCreatePage />
    </MemoryRouter>,
  )
}

describe('TransferCreatePage — szerepkör szerinti típusok és offline queue', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.isElectronQueueAvailable.mockReturnValue(false)
    mocks.getActive.mockResolvedValue(CURRENCIES)
    mocks.listActive.mockResolvedValue([ownBranch(true), targetBranch])
    mocks.cashBalanceList.mockResolvedValue([{ currencyCode: 'EUR', currentBalance: 100000 }])
    mocks.rateList.mockResolvedValue([])
    mocks.getElectronCachedRates.mockResolvedValue([])
    mocks.denominationList.mockResolvedValue([])
    mocks.create.mockResolvedValue({
      transferNumber: 'AT105000099',
      toBranchCode: 'BR001',
      toBranchName: 'Budapesti értéktár',
      fromWorkerName: 'Fabulya Zsuzsanna',
      transferDate: '2026-07-14',
      transferTime: '10:00:00',
      currencyCode: 'EUR',
      amount: 100,
      carrierName: 'Teszt Szállító Kft',
      sealNumber: 'PL-12345',
    })
  })

  it('pénztári felhasználónak csak a három alap átadástípust kínálja', async () => {
    mocks.listActive.mockResolvedValue([ownBranch(false), targetBranch])
    renderPage()

    await screen.findByRole('option', { name: /BR001 - Budapesti értéktár/ })

    expect(screen.getByRole('option', { name: 'Forint (HUF) átadás' })).toBeInTheDocument()
    expect(screen.getByRole('option', { name: 'Valuta átadás' })).toBeInTheDocument()
    expect(screen.getByRole('option', { name: 'Kezelési költség átadás' })).toBeInTheDocument()
    expect(screen.queryByRole('option', { name: 'Értéktár feltöltés' })).not.toBeInTheDocument()
    expect(
      screen.queryByRole('option', { name: 'ERB — Fixing valuta mozgás RB' }),
    ).not.toBeInTheDocument()
    expect(
      screen.queryByRole('option', { name: 'PRB — POS átvétel banktól' }),
    ).not.toBeInTheDocument()
  })

  it('értéktári felhasználónak az RB-típusokat irányhelyesen kínálja', async () => {
    renderPage()

    await screen.findByRole('option', { name: /BR001 - Budapesti értéktár/ })

    expect(
      screen.getByRole('option', { name: 'ERB — Fixing valuta mozgás RB' }),
    ).toBeInTheDocument()
    expect(screen.getByRole('option', { name: 'FRB — Forint mozgás RB' })).toBeInTheDocument()
    expect(screen.getByRole('option', { name: 'TRB — Egyedi kötés RB' })).toBeInTheDocument()
    expect(
      screen.queryByRole('option', { name: 'PRB — POS átvétel banktól' }),
    ).not.toBeInTheDocument()

    fireEvent.click(screen.getByRole('button', { name: 'Átvétel (bejövő)' }))

    expect(
      await screen.findByRole('option', { name: 'PRB — POS átvétel banktól' }),
    ).toBeInTheDocument()
  })

  it('offline Electron queue-ban helyileg ment és nem hívja a REST create végpontot', async () => {
    mocks.isElectronQueueAvailable.mockReturnValue(true)
    mocks.saveAndSyncPendingTransfer.mockResolvedValue({
      allSavedSynced: true,
      savedIds: [1],
      localReferenceNumbers: ['AT105000099'],
    })
    renderPage()

    await screen.findByRole('option', { name: /BR001 - Budapesti értéktár/ })
    fireEvent.change(screen.getByLabelText('Cél iroda'), { target: { value: 'b-target' } })
    fireEvent.change(screen.getByLabelText('Valuta 1'), { target: { value: '1' } })
    fireEvent.change(screen.getByPlaceholderText('0'), { target: { value: '100' } })
    fireEvent.change(screen.getByPlaceholderText('Szállító neve...'), {
      target: { value: 'Teszt Szállító Kft' },
    })
    fireEvent.change(screen.getByPlaceholderText('Plombaszám...'), {
      target: { value: 'PL-12345' },
    })
    fireEvent.click(screen.getByText('Átadás létrehozása'))

    await waitFor(() => expect(mocks.saveAndSyncPendingTransfer).toHaveBeenCalledTimes(1))
    expect(mocks.saveAndSyncPendingTransfer).toHaveBeenCalledWith(
      expect.objectContaining({
        targetBranchId: 'b-target',
        currencyCode: 'EUR',
        amount: 100,
        carrierName: 'Teszt Szállító Kft',
        sealNumber: 'PL-12345',
      }),
    )
    expect(
      await screen.findByText('Átadás helyileg rögzítve és azonnal szinkronizálva'),
    ).toBeInTheDocument()
    expect(mocks.create).not.toHaveBeenCalled()
  })
})
