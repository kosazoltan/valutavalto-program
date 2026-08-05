import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { vi, describe, beforeEach, afterEach, it, expect } from 'vitest'
import TransferCreatePage from './TransferCreatePage'

/**
 * Copilot PR #1100 (storno-minta átvezetés): a szállítólevél-előnézet
 * (ReceiptPreviewModal) CSAK sikeres nyomtatás után zárhat be (2s auto-close).
 * Sikertelen nyomtatásnál az onPrint THROW-val zárul, így a modal nyitva marad
 * és a nyomtatás újrapróbálható.
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
  isElectronQueueAvailable: () => false,
  recordLocalAuditEvent: vi.fn(),
  saveAndSyncPendingTransfer: vi.fn(),
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
  transferDate: '2026-06-12',
  transferTime: '10:00:00',
  currencyCode: 'EUR',
  amount: 100,
  hufValue: 39150,
  carrierName: 'Teszt Szállító Kft',
  sealNumber: 'PL-12345',
}

// A globális Window.electronAPI a teljes ElectronAPI felületet várja — a teszthez
// csak a printReceipt kell, ezért unknown-on át szűkítünk.
const electronWindow = window as unknown as {
  electronAPI?: { printReceipt?: (data: string) => Promise<boolean> }
}

/** Új kimenő átadás rögzítése a REST úton → siker-banner → Nyomtatás → modal nyílik. */
async function createTransferAndOpenReceiptModal() {
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

  // Spec-változás (Tomi, 2026-08-05, Cashier/Shipment-minta): a szállítólevél-előnézet
  // sikeres létrehozás után AUTOMATIKUSAN nyílik — a banner Nyomtatás gombjára nincs szükség.
  // A tesztek kontraktusa (hibánál nyitva maradó modal + kézi retry) változatlan.
  await screen.findByText('Átadás létrehozva: AT105000042')
  await screen.findByText('Mégse (ESC)')

  // a banner ÉS a modal gombja is 'Nyomtatás' — a modal a DOM végén renderelődik
  const printButtons = screen.getAllByRole('button', { name: 'Nyomtatás' })
  return printButtons[printButtons.length - 1]!
}

describe('TransferCreatePage — sikertelen nyomtatásnál a szállítólevél-modal nyitva marad (PR #1100 minta)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
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

  it('printReceipt=false → error toast, a modal NYITVA marad, majd az újrapróbált sikeres nyomtatás zárja be', async () => {
    mocks.printReceipt.mockResolvedValueOnce(false)
    const printButton = await createTransferAndOpenReceiptModal()

    fireEvent.click(printButton)
    await waitFor(() =>
      expect(mocks.toast.error).toHaveBeenCalledWith(
        'Nyomtatás sikertelen',
        'Ellenőrizze a nyomtatót (Beállítások > Nyomtatás).',
      ),
    )

    // a 2s auto-close CSAK sikeres nyomtatásnál indul — hibánál a modal 2s után is nyitva van
    await new Promise((resolve) => setTimeout(resolve, 2200))
    expect(screen.getByText('Mégse (ESC)')).toBeInTheDocument()

    // újrapróbálás: most sikeres → success toast + 2s múlva auto-close
    mocks.printReceipt.mockResolvedValueOnce(true)
    const retryButtons = screen.getAllByRole('button', { name: 'Nyomtatás' })
    const retryButton = retryButtons[retryButtons.length - 1]!
    expect(retryButton).toBeEnabled()
    fireEvent.click(retryButton)
    await waitFor(() =>
      expect(mocks.toast.success).toHaveBeenCalledWith(
        'Nyomtatás elindítva',
        'Bizonylat: AT105000042',
      ),
    )
    await waitFor(() => expect(screen.queryByText('Mégse (ESC)')).not.toBeInTheDocument(), {
      timeout: 3000,
    })
  }, 15000)

  it('printReceipt kivételt dob → error toast és a modal nyitva marad', async () => {
    mocks.printReceipt.mockRejectedValueOnce(new Error('IPC hiba'))
    const printButton = await createTransferAndOpenReceiptModal()

    fireEvent.click(printButton)
    await waitFor(() =>
      expect(mocks.toast.error).toHaveBeenCalledWith(
        'Nyomtatás sikertelen',
        'A nyomtatási parancs nem futott le.',
      ),
    )

    await new Promise((resolve) => setTimeout(resolve, 2200))
    expect(screen.getByText('Mégse (ESC)')).toBeInTheDocument()
  }, 15000)

  it('hiányzó electronAPI → "Nyomtatás nem elérhető" warning és a modal nyitva marad', async () => {
    delete electronWindow.electronAPI
    const printButton = await createTransferAndOpenReceiptModal()

    fireEvent.click(printButton)
    await waitFor(() =>
      expect(mocks.toast.warning).toHaveBeenCalledWith(
        'Nyomtatás nem elérhető',
        expect.stringContaining('Electron preload'),
      ),
    )

    await new Promise((resolve) => setTimeout(resolve, 2200))
    expect(screen.getByText('Mégse (ESC)')).toBeInTheDocument()
  }, 15000)
})
