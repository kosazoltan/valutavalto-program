import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import TransferCreatePage from './TransferCreatePage'

/**
 * FK-072_v2 FR-4 (frontend, oldal-szint): az Átvezetés-létrehozás címletezési
 * sorában az 1 alatti névérték beírásakor a mentés tiltott, egyértelmű hibával —
 * a create API nem hívódhat meg. (Ma a 200 × 0,5 = 100 összeg-egyező sor átmegy.)
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

/** Kitölti a kötelező fejléc-mezőket (cél iroda, valuta, összeg, szállító, plomba). */
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

/** Bekapcsolja a címletezést és kitölti az első sort (darab × névleges érték). */
function fillDenominationLine(quantity: string, faceValue: string) {
  fireEvent.click(screen.getByLabelText(/Címletezés megadása/))
  fireEvent.change(screen.getByPlaceholderText('db'), { target: { value: quantity } })
  // A címletezés bekapcsolása után két '0' placeholderű mező van: [összeg, névleges érték].
  const zeroPlaceholders = screen.getAllByPlaceholderText('0')
  fireEvent.change(zeroPlaceholders[zeroPlaceholders.length - 1]!, {
    target: { value: faceValue },
  })
}

describe('TransferCreatePage — FK-072_v2 tört címletek (FR-4, FR-7)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.isElectronQueueAvailable.mockReturnValue(false)
    mocks.getActive.mockResolvedValue(CURRENCIES)
    mocks.listActive.mockResolvedValue([ownBranch, targetBranch])
    mocks.cashBalanceList.mockResolvedValue([{ currencyCode: 'EUR', currentBalance: 100000 }])
    mocks.rateList.mockResolvedValue([])
    mocks.getElectronCachedRates.mockResolvedValue([])
    mocks.denominationList.mockResolvedValue([])
    mocks.create.mockResolvedValue({
      transferNumber: 'AT105000099',
      toBranchCode: 'BR001',
      toBranchName: 'Budapesti értéktár',
      fromWorkerName: 'Fabulya Zsuzsanna',
      transferDate: '2026-08-03',
      transferTime: '10:00:00',
      currencyCode: 'EUR',
      amount: 100,
      carrierName: 'Teszt Szállító Kft',
      sealNumber: 'PL-12345',
    })
  })

  it('FR-4: 1 alatti névérték (200 × 0,5) → hiba jelenik meg és a create API NEM hívódik', async () => {
    render(
      <MemoryRouter>
        <TransferCreatePage />
      </MemoryRouter>,
    )

    await fillBaseForm()
    // 200 × 0,5 = 100 — az összeg-egyezés teljesül, kizárólag a >= 1 szabály tilthat.
    fillDenominationLine('200', '0,5')

    fireEvent.click(screen.getByText('Átadás létrehozása'))

    await waitFor(() => {
      expect(screen.getByText(/1-nél kisebb/)).toBeInTheDocument()
    })
    expect(mocks.create).not.toHaveBeenCalled()
    expect(mocks.saveAndSyncPendingTransfer).not.toHaveBeenCalled()
  })

  it('FR-7 regresszió: egész névértékű címletezés (50×1 + 25×2) változatlanul beküldhető', async () => {
    render(
      <MemoryRouter>
        <TransferCreatePage />
      </MemoryRouter>,
    )

    await fillBaseForm()
    fireEvent.click(screen.getByLabelText(/Címletezés megadása/))

    // 1. sor: 50 × 1
    fireEvent.change(screen.getByPlaceholderText('db'), { target: { value: '50' } })
    const zeroInputs = screen.getAllByPlaceholderText('0')
    fireEvent.change(zeroInputs[zeroInputs.length - 1]!, { target: { value: '1' } })

    // 2. sor hozzáadása: 25 × 2
    fireEvent.click(screen.getByRole('button', { name: /Sor hozzáadása/ }))
    const dbInputs = screen.getAllByPlaceholderText('db')
    fireEvent.change(dbInputs[dbInputs.length - 1]!, { target: { value: '25' } })
    const zeroInputs2 = screen.getAllByPlaceholderText('0')
    fireEvent.change(zeroInputs2[zeroInputs2.length - 1]!, { target: { value: '2' } })

    fireEvent.click(screen.getByText('Átadás létrehozása'))

    await waitFor(() => {
      expect(mocks.create).toHaveBeenCalledTimes(1)
    })
    expect(mocks.create).toHaveBeenCalledWith(
      expect.objectContaining({
        denominations: [
          { quantity: 50, faceValue: 1 },
          { quantity: 25, faceValue: 2 },
        ],
      }),
    )
  })
})
