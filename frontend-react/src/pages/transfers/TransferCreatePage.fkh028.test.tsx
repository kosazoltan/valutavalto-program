import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import TransferCreatePage from './TransferCreatePage'

/**
 * FKH-028 Fázis 1: dupla-beküldés védelem. A handleCreateTransfer ma a
 * setLoading(true)-t csak a készlet-ellenőrző await (cashBalanceApi.list) és az
 * árfolyam-feloldó await UTÁN állítja be — az async ablakban a gomb kattintható
 * marad, két gyors kattintás KÉT transfert hoz létre.
 *
 * Elvárt új viselkedés: a letiltás a függvény legelején aktiválódik, két gyors
 * kattintásból pontosan EGY create API-hívás születik; hibaágon a loading
 * visszaáll (a gomb újra használható).
 */

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
      fullName: 'Teszt Értéktáros',
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

const ownBranch = {
  id: 'b-own',
  code: 'BR076',
  name: 'Pécsi értéktár',
  isVault: true,
  branchTypeCode: 'VAULT',
  region: 'DD',
  vaultTerritoryId: 1,
}

const targetBranch = {
  id: 'b-target',
  code: 'BR001',
  name: 'Budapesti értéktár',
  isVault: true,
  branchTypeCode: 'VAULT',
  region: 'DD',
  vaultTerritoryId: 1,
}

async function fillBaseForm() {
  await screen.findByRole('option', { name: /BR001 - Budapesti értéktár/ })
  fireEvent.change(screen.getByLabelText('Cél iroda'), { target: { value: 'b-target' } })
  fireEvent.change(screen.getByLabelText('Valuta 1'), { target: { value: '1' } })
  fireEvent.change(screen.getByPlaceholderText('0'), { target: { value: '100' } })
  fireEvent.change(screen.getByPlaceholderText('Szállító neve...'), {
    target: { value: 'Teszt Szállító Kft' },
  })
  fireEvent.change(screen.getByPlaceholderText('Plombaszám...'), { target: { value: 'PL-12345' } })
}

describe('TransferCreatePage — FKH-028 dupla-beküldés védelem (Fázis 1)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.isElectronQueueAvailable.mockReturnValue(false)
    mocks.getActive.mockResolvedValue(CURRENCIES)
    mocks.listActive.mockResolvedValue([ownBranch, targetBranch])
    mocks.rateList.mockResolvedValue([])
    mocks.getElectronCachedRates.mockResolvedValue([])
    mocks.denominationList.mockResolvedValue([])
    mocks.create.mockResolvedValue({
      transferNumber: 'AT-000009',
      toBranchCode: 'BR001',
      toBranchName: 'Budapesti értéktár',
      fromWorkerName: 'Teszt Értéktáros',
      transferDate: '2026-08-04',
      transferTime: '10:00:00',
      currencyCode: 'EUR',
      amount: 100,
      carrierName: 'Teszt Szállító Kft',
      sealNumber: 'PL-12345',
    })
  })

  it('FKH-028: két gyors kattintás a készlet-ellenőrzés függő ideje alatt → PONTOSAN EGY create hívás', async () => {
    // A készlet-ellenőrző hívást felfüggesztjük, hogy a mai kódban a loading=false
    // ablak (a setLoading(true) előtti szakasz) determinisztikusan nyitva legyen.
    // MINDEN hívás saját resolvert kap (tömbben), és mindet feloldjuk — különben a
    // teszt hamis-zölden menne át (csak az egyik handler futna végig).
    const balanceResolvers: Array<(v: unknown) => void> = []
    mocks.cashBalanceList.mockImplementation(
      () =>
        new Promise((resolve) => {
          balanceResolvers.push(resolve)
        }),
    )

    render(
      <MemoryRouter>
        <TransferCreatePage />
      </MemoryRouter>,
    )

    await fillBaseForm()

    const submit = screen.getByRole('button', { name: /Átadás létrehozása/ })
    fireEvent.click(submit)
    fireEvent.click(submit)

    for (const resolve of balanceResolvers) {
      resolve([{ currencyCode: 'EUR', currentBalance: 100000 }])
    }

    await waitFor(() => {
      expect(mocks.create).toHaveBeenCalled()
    })
    expect(mocks.create).toHaveBeenCalledTimes(1)
  })

  it('FKH-028: hibaágon (készlet-ellenőrzés bukik) a gomb újra használható, és a retry lefut', async () => {
    mocks.cashBalanceList.mockRejectedValueOnce(new Error('halozati hiba'))
    mocks.cashBalanceList.mockResolvedValueOnce([{ currencyCode: 'EUR', currentBalance: 100000 }])

    render(
      <MemoryRouter>
        <TransferCreatePage />
      </MemoryRouter>,
    )

    await fillBaseForm()

    const submit = screen.getByRole('button', { name: /Átadás létrehozása/ })
    fireEvent.click(submit)

    await screen.findByText('Készlet-ellenőrzés sikertelen. Próbálja újra!')
    expect(submit).not.toBeDisabled()

    fireEvent.click(submit)
    await waitFor(() => {
      expect(mocks.create).toHaveBeenCalledTimes(1)
    })
  })
})
