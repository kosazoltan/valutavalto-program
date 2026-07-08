import { render, screen, fireEvent } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import TransferPage from './TransferPage'

/**
 * FK05 FR-5: az átadás/átvétel forintosítása az ELSZÁMOLÓ árfolyamot (J oszlop,
 * officialRate / cached official_rate) használja a vételi helyett — a legacy
 * atadvet/unit2.pas ELSZAMOLASIARFOLYAM-mintájának tükre. Régi adatnál
 * (official null/0) fallback a vételire (edge-case katalógus: nem crash).
 */

const mocks = vi.hoisted(() => ({
  getOutgoing: vi.fn(),
  getIncoming: vi.fn(),
  getPending: vi.fn(),
  countPending: vi.fn(),
  create: vi.fn(),
  getActive: vi.fn(),
  listActive: vi.fn(),
  cashBalanceList: vi.fn(),
  rateList: vi.fn(),
  getElectronCachedRates: vi.fn(),
  toast: { success: vi.fn(), warning: vi.fn(), error: vi.fn(), info: vi.fn() },
}))

vi.mock('../../services/api/index', () => ({
  transferApi: {
    getOutgoing: mocks.getOutgoing,
    getIncoming: mocks.getIncoming,
    getPending: mocks.getPending,
    countPending: mocks.countPending,
    create: mocks.create,
    receive: vi.fn(),
    reject: vi.fn(),
    cancel: vi.fn(),
    storno: vi.fn(),
    getStornoPreview: vi.fn(),
  },
  currencyApi: { getActive: mocks.getActive },
  branchApi: { listActive: mocks.listActive },
  cashBalanceApi: { list: mocks.cashBalanceList },
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
  isElectronQueueAvailable: () => false,
  recordLocalAuditEvent: vi.fn(),
  saveAndSyncPendingTransfer: vi.fn(),
  getElectronCachedRates: mocks.getElectronCachedRates,
}))

vi.mock('../../utils/localQueue', () => ({
  getLocalPendingTransfers: vi.fn().mockResolvedValue([]),
  getCompanyType: () => 'BEST_CHANGE',
  queueOfflineTransferStorno: vi.fn(),
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
      onChange={(e) => onChange(e.target.value)}
    />
  ),
}))

vi.mock('../../utils/electron', () => ({ isElectron: () => true }))

vi.mock('../../components/ui/toaster', () => ({ toast: mocks.toast }))

const BRANCHES = [
  {
    id: 'b-own',
    code: 'BR076',
    name: 'Pécsi értéktár',
    isVault: true,
    branchTypeCode: 'VAULT',
    region: 'DD',
    vaultTerritoryId: 1,
  },
  {
    id: 'b-target',
    code: 'BR001',
    name: 'Budapesti értéktár',
    isVault: true,
    branchTypeCode: 'VAULT',
    region: 'DD',
    vaultTerritoryId: 1,
  },
]

const CURRENCIES = [
  { id: 1, code: 'EUR', name: 'Euró' },
  { id: 2, code: 'HUF', name: 'Forint' },
]

async function createEurTransfer() {
  render(
    <MemoryRouter>
      <TransferPage />
    </MemoryRouter>,
  )

  fireEvent.click(await screen.findByText('Új átadás'))
  await screen.findByRole('option', { name: /BR001 - Budapesti értéktár/ })

  fireEvent.change(screen.getByLabelText('Cél iroda'), { target: { value: 'b-target' } })
  fireEvent.change(screen.getByLabelText('Valuta 1'), { target: { value: '1' } })
  fireEvent.change(screen.getByPlaceholderText('0'), { target: { value: '100' } })
  fireEvent.change(screen.getByPlaceholderText('Szállító neve...'), {
    target: { value: 'Teszt Szállító Kft' },
  })
  fireEvent.change(screen.getByPlaceholderText('Plombaszám...'), { target: { value: 'PL-12345' } })
  fireEvent.click(screen.getByText('Átadás létrehozása'))
  await screen.findByText(/Átadás létrehozva/)
}

describe('TransferPage — FK05 FR-5: forintosítás elszámoló árfolyammal', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.getOutgoing.mockResolvedValue([])
    mocks.getIncoming.mockResolvedValue([])
    mocks.getPending.mockResolvedValue([])
    mocks.countPending.mockResolvedValue(0)
    mocks.getActive.mockResolvedValue(CURRENCIES)
    mocks.listActive.mockResolvedValue(BRANCHES)
    mocks.cashBalanceList.mockResolvedValue([{ currencyCode: 'EUR', currentBalance: 100000 }])
    mocks.rateList.mockResolvedValue([])
    mocks.create.mockResolvedValue({
      transferNumber: 'AT105000042',
      toBranchCode: 'BR001',
      toBranchName: 'Budapesti értéktár',
      fromWorkerName: 'Fabulya Zsuzsanna',
      transferDate: '2026-06-12',
      transferTime: '10:00:00',
      currencyCode: 'EUR',
      amount: 100,
      hufValue: 35380,
      carrierName: 'Teszt Szállító Kft',
      sealNumber: 'PL-12345',
    })
  })

  it('resolveTransferRate_uses_official_rate: a cache official_rate (J) megy a forintosításba, nem a buy_rate', async () => {
    mocks.getElectronCachedRates.mockResolvedValue([
      {
        currency_code: 'EUR',
        buy_rate: 380,
        sell_rate: 400,
        unit: 1,
        updated_at: '',
        official_rate: 353.8,
      },
    ])

    await createEurTransfer()

    expect(mocks.create).toHaveBeenCalledTimes(1)
    // roundHuf(100 × 353,80) = 35 380 — NEM 38 000 (100 × vételi 380).
    expect(mocks.create.mock.calls[0]![0]).toMatchObject({ hufValue: 35380 })
  })

  it('resolveTransferRate_fallback_to_buy_rate_when_official_null: régi cache-sor (official null) → vételi', async () => {
    mocks.getElectronCachedRates.mockResolvedValue([
      {
        currency_code: 'EUR',
        buy_rate: 380,
        sell_rate: 400,
        unit: 1,
        updated_at: '',
        official_rate: null,
      },
    ])

    await createEurTransfer()

    expect(mocks.create).toHaveBeenCalledTimes(1)
    expect(mocks.create.mock.calls[0]![0]).toMatchObject({ hufValue: 38000 })
  })

  it('online út: exchangeRateApi.list officialRate-je megy a forintosításba (cache-találat nélkül)', async () => {
    mocks.getElectronCachedRates.mockResolvedValue([])
    mocks.rateList.mockResolvedValue([
      { currencyCode: 'EUR', baseBuyRate: 380, baseSellRate: 400, officialRate: 353.8 },
    ])

    await createEurTransfer()

    expect(mocks.create).toHaveBeenCalledTimes(1)
    expect(mocks.create.mock.calls[0]![0]).toMatchObject({ hufValue: 35380 })
  })
})
