import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { vi, describe, beforeEach, afterEach, it, expect } from 'vitest'
import TransferCreatePage from './TransferCreatePage'

/**
 * Transfer-flow egységesítés (Tomi döntése, 2026-08-05 — a csendes auto-print
 * terv elvetve): a TransferReceiptModal (szállítólevél-előnézet) sikeres
 * létrehozás után AUTOMATIKUSAN megnyílik — ugyanúgy, ahogy a
 * CashierTransactionPage (openReceiptModal) és a ShipmentNewPage
 * (buildAndShowReceipt → setShowReceiptModal(true)) ma teszi. A modal
 * "Nyomtatás" gombja VÁLTOZATLANUL kézi kattintásra indítja a printReceipt-et
 * — automatikus/néma nyomtatás NINCS.
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
  printReceipt: vi.fn(),
  saveAndSyncPendingTransfer: vi.fn(),
  // Electron offline-queue ág kapcsolója (tesztenként állítható)
  flags: { electronQueue: false },
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
  isElectronQueueAvailable: () => mocks.flags.electronQueue,
  recordLocalAuditEvent: vi.fn(),
  saveAndSyncPendingTransfer: mocks.saveAndSyncPendingTransfer,
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

const CREATE_RESULT = {
  transferNumber: 'AT105000042',
  toBranchCode: 'BR001',
  toBranchName: 'Budapesti értéktár',
  fromWorkerName: 'Fabulya Zsuzsanna',
  transferDate: '2026-08-05',
  transferTime: '10:00:00',
  currencyCode: 'EUR',
  amount: 100,
  hufValue: 39150,
  carrierName: 'Teszt Szállító Kft',
  sealNumber: 'PL-12345',
}

const electronWindow = window as unknown as {
  electronAPI?: { printReceipt?: (data: string) => Promise<boolean> }
}

/** Új kimenő EUR átadás kitöltése és beküldése (modal-interakció NÉLKÜL). */
async function createTransfer() {
  render(
    <MemoryRouter>
      <TransferCreatePage />
    </MemoryRouter>,
  )

  await screen.findByRole('option', { name: /BR001 - Budapesti értéktár/ })

  fireEvent.change(screen.getByLabelText('Cél iroda'), { target: { value: 'b-target' } })
  fireEvent.change(screen.getByLabelText('Valuta 1'), { target: { value: '1' } })
  fireEvent.change(screen.getByPlaceholderText('0'), { target: { value: '100' } })
  fireEvent.change(screen.getByPlaceholderText('Szállító neve...'), {
    target: { value: 'Teszt Szállító Kft' },
  })
  fireEvent.change(screen.getByPlaceholderText('Plombaszám...'), { target: { value: 'PL-12345' } })
  fireEvent.click(screen.getByText('Átadás létrehozása'))
}

describe('TransferCreatePage — a szállítólevél-előnézet automatikusan megnyílik sikeres létrehozás után', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.flags.electronQueue = false
    mocks.getOutgoing.mockResolvedValue([])
    mocks.getIncoming.mockResolvedValue([])
    mocks.getPending.mockResolvedValue([])
    mocks.countPending.mockResolvedValue(0)
    mocks.getActive.mockResolvedValue(CURRENCIES)
    mocks.listActive.mockResolvedValue(BRANCHES)
    mocks.cashBalanceList.mockResolvedValue([{ currencyCode: 'EUR', currentBalance: 100000 }])
    mocks.create.mockResolvedValue(CREATE_RESULT)
    electronWindow.electronAPI = { printReceipt: mocks.printReceipt }
  })

  afterEach(() => {
    delete electronWindow.electronAPI
  })

  it('online (REST) ág: a modal gombnyomás nélkül megnyílik; a nyomtatás KÉZI marad — csak a modal Nyomtatás gombjára indul', async () => {
    mocks.printReceipt.mockResolvedValue(true)
    await createTransfer()

    await screen.findByText('Átadás létrehozva: AT105000042')

    // A modal AUTOMATIKUSAN nyílik — a siker-banner Nyomtatás gombját NEM nyomtuk meg
    await screen.findByText('Mégse (ESC)')

    // Automatikus/néma nyomtatás NINCS: a printReceipt csak kézi kattintásra fut
    expect(mocks.printReceipt).not.toHaveBeenCalled()

    // A modal Nyomtatás gombja változatlanul működik (a banner gombja is 'Nyomtatás' —
    // a modal a DOM végén renderelődik, ezért az utolsót kattintjuk)
    const printButtons = screen.getAllByRole('button', { name: 'Nyomtatás' })
    fireEvent.click(printButtons[printButtons.length - 1]!)
    await waitFor(() => expect(mocks.printReceipt).toHaveBeenCalledTimes(1))
    const payload = JSON.parse(mocks.printReceipt.mock.calls[0]![0] as string)
    expect(payload.receiptNumber).toBe('AT105000042')
  }, 15000)

  it('offline (Electron queue) ág: a modal a helyi rögzítés után is gombnyomás nélkül megnyílik, néma nyomtatás nélkül', async () => {
    mocks.flags.electronQueue = true
    mocks.saveAndSyncPendingTransfer.mockResolvedValue({
      savedIds: [7],
      syncedCount: 1,
      pendingCount: 0,
      allSavedSynced: true,
      syncErrors: [],
      localReferenceNumbers: ['AT105000099'],
    })
    await createTransfer()

    await screen.findByText('Átadás helyileg rögzítve és azonnal szinkronizálva')

    // A modal AUTOMATIKUSAN nyílik az offline ágon is
    await screen.findByText('Mégse (ESC)')

    // Néma nyomtatás itt sincs
    expect(mocks.printReceipt).not.toHaveBeenCalled()
    expect(mocks.create).not.toHaveBeenCalled()
  }, 15000)
})
