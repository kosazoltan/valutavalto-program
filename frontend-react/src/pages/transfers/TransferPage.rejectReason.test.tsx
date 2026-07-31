import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import TransferPage from './TransferPage'

// FKH-027 PR B (RED) — FR-B10..FR-B11: a handleReject a natív prompt() helyett a közös
// TextReasonModal-lal kéri be a visszautasítás okát. A jelenlegi kód a reason-nel
// EGYÜTT lokális audit-eseményt is rögzít (recordLocalAuditEvent) — a teszt külön
// pinneli, hogy az audit-hívás is CSAK a string-ágon történik meg.

const mocks = vi.hoisted(() => ({
  getOutgoing: vi.fn(),
  getIncoming: vi.fn(),
  getPending: vi.fn(),
  countPending: vi.fn(),
  getShipmentPending: vi.fn(),
  getById: vi.fn(),
  getByTransferNumber: vi.fn(),
  reject: vi.fn(),
  cancel: vi.fn(),
  getActive: vi.fn(),
  listActive: vi.fn(),
  recordLocalAuditEvent: vi.fn(),
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
    reject: mocks.reject,
    cancel: mocks.cancel,
    storno: vi.fn(),
    getStornoPreview: vi.fn(),
  },
  shipmentRequestApi: {
    getPendingForBranch: mocks.getShipmentPending,
    deliver: vi.fn(),
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
  recordLocalAuditEvent: mocks.recordLocalAuditEvent,
  saveAndSyncPendingTransfer: vi.fn(),
  getElectronCachedRates: vi.fn(),
}))

vi.mock('../../utils/localQueue', () => ({
  getLocalPendingTransfers: vi.fn().mockResolvedValue([]),
  getCompanyType: () => 'BEST_CHANGE',
  getShipmentReceiptOutboxState: vi.fn().mockResolvedValue({ pending: [], issues: [] }),
  queueOfflineShipmentReceipt: vi.fn(),
  queueOfflineTransferStorno: vi.fn(),
}))

vi.mock('../../components/auth/SupervisorPinModal', () => ({ default: () => null }))

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

describe('TransferPage — FR-B10..B11: visszautasítás oka a TextReasonModal-lal', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.getOutgoing.mockResolvedValue([])
    mocks.getIncoming.mockResolvedValue([])
    mocks.getPending.mockResolvedValue([pendingTransfer])
    mocks.countPending.mockResolvedValue(1)
    mocks.getShipmentPending.mockResolvedValue([])
    mocks.getActive.mockResolvedValue([{ id: 1, code: 'EUR', name: 'Euró' }])
    mocks.listActive.mockResolvedValue([
      {
        id: 'b-own',
        code: 'BR076',
        name: 'Pécsi értéktár',
        isVault: true,
        branchTypeCode: 'VAULT',
      },
      {
        id: 'b-source',
        code: 'BR001',
        name: 'Budapesti értéktár',
        isVault: true,
        branchTypeCode: 'VAULT',
      },
    ])
    mocks.reject.mockResolvedValue({ ...pendingTransfer, status: 'REJECTED' })
    vi.spyOn(window, 'prompt').mockReturnValue(null)
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  async function openRejectModal(user: ReturnType<typeof userEvent.setup>) {
    render(
      <MemoryRouter>
        <TransferPage />
      </MemoryRouter>,
    )
    await screen.findByText('AT-LIST-007')
    await user.click(screen.getByTitle('Visszautasítás'))
    const dialog = await screen.findByRole('alertdialog')
    // FR-B10: a title szó szerint az eddigi prompt-szöveg
    expect(dialog).toHaveAccessibleName('Visszautasítás oka:')
    expect(window.prompt).not.toHaveBeenCalled()
    return dialog
  }

  it('FR-B11 string-ág: a megadott okkal pontosan egyszer hívódik a transferApi.reject', async () => {
    const user = userEvent.setup()
    const dialog = await openRejectModal(user)
    await user.type(within(dialog).getByRole('textbox'), 'Sérült zár a csomagon')
    await user.click(within(dialog).getByRole('button', { name: 'OK' }))
    await waitFor(() => expect(mocks.reject).toHaveBeenCalledWith(7, 'Sérült zár a csomagon'))
    expect(mocks.reject).toHaveBeenCalledTimes(1)
    await waitFor(() => expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument())
    expect(window.prompt).not.toHaveBeenCalled()
  })

  it('FR-B11 string-ág: a lokális audit-esemény változatlan payloaddal rögzül', async () => {
    const user = userEvent.setup()
    const dialog = await openRejectModal(user)
    await user.type(within(dialog).getByRole('textbox'), 'Sérült zár a csomagon')
    await user.click(within(dialog).getByRole('button', { name: 'OK' }))
    await waitFor(() =>
      expect(mocks.recordLocalAuditEvent).toHaveBeenCalledWith({
        entityType: 'TRANSFER',
        eventType: 'REJECT',
        entityId: '7',
        referenceNumber: 'AT-LIST-007',
        payload: {
          transferId: 7,
          reason: 'Sérült zár a csomagon',
        },
        status: 'SERVER_FORWARDED',
      }),
    )
    expect(mocks.recordLocalAuditEvent).toHaveBeenCalledTimes(1)
  })

  it('FR-B11 null-ág: Mégse után sem a transferApi.reject, sem az audit-rögzítés nem fut', async () => {
    const user = userEvent.setup()
    const dialog = await openRejectModal(user)
    await user.click(within(dialog).getByRole('button', { name: 'Mégse' }))
    await waitFor(() => expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument())
    expect(mocks.reject).not.toHaveBeenCalled()
    expect(mocks.recordLocalAuditEvent).not.toHaveBeenCalled()
    expect(window.prompt).not.toHaveBeenCalled()
  })

  it('üres string: a hívó-oldali validáció megmarad — sem API-, sem audit-hívás', async () => {
    const user = userEvent.setup()
    const dialog = await openRejectModal(user)
    await user.click(within(dialog).getByRole('button', { name: 'OK' }))
    await waitFor(() => expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument())
    expect(mocks.reject).not.toHaveBeenCalled()
    expect(mocks.recordLocalAuditEvent).not.toHaveBeenCalled()
  })
})
