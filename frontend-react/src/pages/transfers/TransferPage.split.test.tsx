import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import TransferPage from './TransferPage'

const mocks = vi.hoisted(() => ({
  getOutgoing: vi.fn(),
  getIncoming: vi.fn(),
  getPending: vi.fn(),
  countPending: vi.fn(),
  getShipmentPending: vi.fn(),
  deliverShipment: vi.fn(),
  getActive: vi.fn(),
  listActive: vi.fn(),
  electronQueueAvailable: false,
  queueShipmentReceipt: vi.fn(),
  getQueuedShipmentReceiptIds: vi.fn(),
  getShipmentReceiptIssues: vi.fn(),
  getShipmentReceiptOutboxState: vi.fn(),
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
  shipmentRequestApi: {
    getPendingForBranch: mocks.getShipmentPending,
    deliver: mocks.deliverShipment,
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
  isElectronQueueAvailable: () => mocks.electronQueueAvailable,
  recordLocalAuditEvent: vi.fn(),
}))

vi.mock('../../utils/localQueue', () => ({
  getLocalPendingTransfers: vi.fn().mockResolvedValue([]),
  getCompanyType: () => 'BEST_CHANGE',
  queueOfflineTransferStorno: vi.fn(),
  queueOfflineShipmentReceipt: mocks.queueShipmentReceipt,
  getQueuedShipmentReceiptIds: mocks.getQueuedShipmentReceiptIds,
  getShipmentReceiptIssues: mocks.getShipmentReceiptIssues,
  getShipmentReceiptOutboxState: mocks.getShipmentReceiptOutboxState,
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

const pendingShipment = {
  id: 'shipment-1',
  requestNumber: 'FF-000123',
  requestingBranchId: 'b-source',
  requestingBranchName: 'Budapesti értéktár',
  targetBranchId: 'b-own',
  targetBranchName: 'Pécsi értéktár',
  requestStatus: 'SUBMITTED',
  requestedDeliveryDate: '2026-06-19',
  requestedAt: '2026-06-19T10:05:00',
  requestedByWorkerId: '9',
  requestedByWorkerName: 'Küldő Anna',
  shipmentType: 'TRANSFER',
  items: [{ id: 'si-1', currencyId: 1, currencyCode: 'EUR', requestedAmount: 250 }],
}

describe('TransferPage — visszaigazolás és létrehozás szétválasztása', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.electronQueueAvailable = false
    mocks.getOutgoing.mockResolvedValue([])
    mocks.getIncoming.mockResolvedValue([])
    mocks.getPending.mockResolvedValue([pendingTransfer])
    mocks.countPending.mockResolvedValue(1)
    mocks.getShipmentPending.mockResolvedValue([pendingShipment])
    mocks.deliverShipment.mockResolvedValue({ ...pendingShipment, requestStatus: 'DELIVERED' })
    mocks.queueShipmentReceipt.mockResolvedValue(true)
    mocks.getQueuedShipmentReceiptIds.mockResolvedValue(new Set())
    mocks.getShipmentReceiptIssues.mockResolvedValue([])
    mocks.getShipmentReceiptOutboxState.mockResolvedValue({ pending: [], issues: [] })
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

  it('a Transfer és Shipment pending tételeket egy listában mutatja és Shipmentet approve nélkül fogad', async () => {
    render(
      <MemoryRouter>
        <TransferPage />
      </MemoryRouter>,
    )

    await screen.findByText('AT-LIST-007')
    expect(screen.getByText('FF-000123')).toBeInTheDocument()
    const pendingTab = screen.getByRole('button', { name: /Átvételre váró/ })
    expect(pendingTab).toHaveTextContent('2')
    expect(screen.queryByText(/Jóváhagy/)).not.toBeInTheDocument()

    fireEvent.click(screen.getByTitle('Shipment átvétele'))
    await waitFor(() =>
      expect(mocks.deliverShipment).toHaveBeenCalledWith('shipment-1', expect.any(String)),
    )
  })

  it('stale Shipmentnél ugyanazt az app-dialógust nyitja, Mégse esetén nincs mutáció', async () => {
    mocks.getShipmentPending.mockResolvedValue([
      { ...pendingShipment, staleForDelivery: true, staleThresholdHours: 48 },
    ])
    render(
      <MemoryRouter>
        <TransferPage />
      </MemoryRouter>,
    )

    await screen.findByText('FF-000123')
    fireEvent.click(screen.getByTitle('Shipment átvétele'))

    expect(screen.getByRole('alertdialog')).toHaveTextContent('FF-000123')
    expect(mocks.deliverShipment).not.toHaveBeenCalled()
    fireEvent.click(screen.getByRole('button', { name: 'Mégse' }))

    expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument()
    expect(screen.getByText('FF-000123')).toBeInTheDocument()
    expect(mocks.deliverShipment).not.toHaveBeenCalled()
  })

  it('stale Shipment megerősítése confirmedStale bodyval kézbesít', async () => {
    mocks.getShipmentPending.mockResolvedValue([
      { ...pendingShipment, staleForDelivery: true, staleThresholdHours: 48 },
    ])
    render(
      <MemoryRouter>
        <TransferPage />
      </MemoryRouter>,
    )

    await screen.findByText('FF-000123')
    fireEvent.click(screen.getByTitle('Shipment átvétele'))
    fireEvent.click(screen.getByRole('button', { name: 'Igen, folytatás' }))

    await waitFor(() =>
      expect(mocks.deliverShipment).toHaveBeenCalledWith('shipment-1', expect.any(String), {
        confirmedStale: true,
      }),
    )
  })

  it('stale megerősítés hálózati hibánál a megerősítés tényével együtt kerül az outboxba', async () => {
    mocks.electronQueueAvailable = true
    mocks.getShipmentPending.mockResolvedValue([
      { ...pendingShipment, staleForDelivery: true, staleThresholdHours: 48 },
    ])
    mocks.deliverShipment.mockRejectedValue({ code: 'ERR_NETWORK' })
    render(
      <MemoryRouter>
        <TransferPage />
      </MemoryRouter>,
    )

    await screen.findByText('FF-000123')
    fireEvent.click(screen.getByTitle('Shipment átvétele'))
    fireEvent.click(screen.getByRole('button', { name: 'Igen, folytatás' }))

    await waitFor(() =>
      expect(mocks.queueShipmentReceipt).toHaveBeenCalledWith(
        'shipment-1',
        'FF-000123',
        'b-own',
        9,
        expect.any(String),
        true,
      ),
    )
  })

  it('hálózati hibánál Electron outboxba ír és szinkronra váróként jelöl, készletet nem könyvel lokálisan', async () => {
    mocks.electronQueueAvailable = true
    mocks.deliverShipment.mockRejectedValue({ code: 'ERR_NETWORK' })

    render(
      <MemoryRouter>
        <TransferPage />
      </MemoryRouter>,
    )

    await screen.findByText('FF-000123')
    fireEvent.click(screen.getByTitle('Shipment átvétele'))

    await waitFor(() =>
      expect(mocks.queueShipmentReceipt).toHaveBeenCalledWith(
        'shipment-1',
        'FF-000123',
        'b-own',
        9,
        expect.any(String),
      ),
    )
    expect(await screen.findByText('Szinkronra vár')).toBeInTheDocument()
    expect(screen.getByTitle('Shipment átvétele')).toBeDisabled()
  })

  it('Axios timeoutnál is ugyanazt az online idempotenciakulcsot adja át az outboxnak', async () => {
    mocks.electronQueueAvailable = true
    mocks.deliverShipment.mockRejectedValue({ code: 'ECONNABORTED' })

    render(
      <MemoryRouter>
        <TransferPage />
      </MemoryRouter>,
    )

    await screen.findByText('FF-000123')
    fireEvent.click(screen.getByTitle('Shipment átvétele'))

    await waitFor(() => expect(mocks.deliverShipment).toHaveBeenCalledTimes(1))
    const onlineKey = mocks.deliverShipment.mock.calls[0]?.[1]
    await waitFor(() =>
      expect(mocks.queueShipmentReceipt).toHaveBeenCalledWith(
        'shipment-1',
        'FF-000123',
        'b-own',
        9,
        onlineKey,
      ),
    )
  })

  it('a terminális offline átvételi hibát láthatóan jelzi az operátornak', async () => {
    mocks.electronQueueAvailable = true
    mocks.getShipmentReceiptOutboxState.mockResolvedValue({
      pending: [],
      issues: [{ requestNumber: 'FF-000099', message: 'A küldő sztornózta a tételt.' }],
    })

    render(
      <MemoryRouter>
        <TransferPage />
      </MemoryRouter>,
    )

    expect(await screen.findByText(/FF-000099: A küldő sztornózta a tételt/)).toBeInTheDocument()
  })

  it('újraindítás után távoli hiba mellett is megőrzi és számolja a tartós Shipment-átvételi szándékot', async () => {
    mocks.electronQueueAvailable = true
    mocks.getShipmentReceiptOutboxState.mockResolvedValue({
      pending: [
        {
          shipmentId: 'shipment-offline-1',
          requestNumber: 'FF-OFFLINE-001',
          branchId: 'b-own',
          workerId: 9,
          createdAt: '2026-07-18 12:00:00',
        },
      ],
      issues: [],
    })
    const offline = new Error('network unavailable')
    mocks.getOutgoing.mockRejectedValue(offline)
    mocks.getIncoming.mockRejectedValue(offline)
    mocks.getPending.mockRejectedValue(offline)
    mocks.countPending.mockRejectedValue(offline)
    mocks.getShipmentPending.mockRejectedValue(offline)
    mocks.getActive.mockRejectedValue(offline)

    render(
      <MemoryRouter>
        <TransferPage />
      </MemoryRouter>,
    )

    expect(await screen.findByText('FF-OFFLINE-001')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /Átvételre váró/ })).toHaveTextContent('1')
    expect(screen.getByText('Szinkronra vár')).toBeInTheDocument()
  })
})

// ─────────────────────────────────────────────────────────────────────────────
// FKH-026 v3 — FR-7/FR-8 (RED-fázis 2. kör, 2026-07-30).
//
// FR-7: a fejléc-gomb felirata "+ Új átadás"-ra módosul (v3: a gomb MÁR LÉTEZIK
// — PR #274, v2.3.12 —, kizárólag a felirat változik). A teszt ma a felirat-
// eltérés miatt bukik ("Új átadás" ≠ "+ Új átadás") → RED.
//
// FR-8: REGRESSZIÓ-ŐR, nem új funkció — a kattintás már ma is a /transfers/new
// route-ra visz (ld. fenti pin: href='/transfers/new'), ezért ez a teszt MA IS
// ZÖLD, és a felirat-módosítás közben is zöldnek kell maradnia. A locator itt
// szándékosan felirat-agnosztikus (/Új átadás/ regex), hogy az átcímkézés előtt
// és után is ugyanazt a viselkedést őrizze.
// ─────────────────────────────────────────────────────────────────────────────
describe('FKH-026 v3 — "+ Új átadás" gomb (FR-7 felirat + FR-8 regresszió-őr)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.electronQueueAvailable = false
    mocks.getOutgoing.mockResolvedValue([])
    mocks.getIncoming.mockResolvedValue([])
    mocks.getPending.mockResolvedValue([])
    mocks.countPending.mockResolvedValue(0)
    mocks.getShipmentPending.mockResolvedValue([])
    mocks.getQueuedShipmentReceiptIds.mockResolvedValue(new Set())
    mocks.getShipmentReceiptIssues.mockResolvedValue([])
    mocks.getShipmentReceiptOutboxState.mockResolvedValue({ pending: [], issues: [] })
    mocks.getActive.mockResolvedValue([])
    mocks.listActive.mockResolvedValue([])
  })

  it('FR-7: a fejléc-gomb felirata "+ Új átadás", és változatlanul a /transfers/new-ra mutat', async () => {
    render(
      <MemoryRouter>
        <TransferPage />
      </MemoryRouter>,
    )

    // A fejléc-eszközsor a lista-betöltéstől függetlenül renderel; a findByRole
    // az effektek lefutását is kivárja.
    const link = await screen.findByRole('link', { name: '+ Új átadás' })
    expect(link).toHaveAttribute('href', '/transfers/new')
  })

  it('FR-8 (regresszió-őr, ma is zöld): a gombra kattintva a /transfers/new route töltődik be', async () => {
    render(
      <MemoryRouter initialEntries={['/transfers']}>
        <Routes>
          <Route path="/transfers" element={<TransferPage />} />
          <Route path="/transfers/new" element={<div data-testid="transfer-create-probe" />} />
        </Routes>
      </MemoryRouter>,
    )

    fireEvent.click(await screen.findByRole('link', { name: /Új átadás/ }))
    expect(await screen.findByTestId('transfer-create-probe')).toBeInTheDocument()
  })
})
