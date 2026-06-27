import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import ShipmentListPage from './ShipmentListPage'

const mocks = vi.hoisted(() => ({
  findByStatus: vi.fn(),
  findByBranch: vi.fn(),
  get: vi.fn(),
  update: vi.fn(),
  approve: vi.fn(),
  reject: vi.fn(),
  deliver: vi.fn(),
  cancel: vi.fn(),
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string, options?: Record<string, string>) =>
      options?.requestNumber ? `${key} ${options.requestNumber}` : key,
  }),
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: unknown) => unknown) =>
    selector({ worker: { id: 77, branchId: 'branch-1' } }),
}))

vi.mock('../../services/api/index', () => ({
  shipmentRequestApi: {
    findByStatus: mocks.findByStatus,
    findByBranch: mocks.findByBranch,
    get: mocks.get,
    update: mocks.update,
    approve: mocks.approve,
    reject: mocks.reject,
    deliver: mocks.deliver,
    cancel: mocks.cancel,
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: { error: vi.fn(), warn: vi.fn(), info: vi.fn() },
}))

// A FK-11 újranyomtatás a meglévő (változatlan) ReceiptPreviewModal-t használja; itt stubbal
// helyettesítjük, hogy a ShipmentListPage logikáját (lekérés + modal nyitás) izoláltan teszteljük.
vi.mock('../../components/electron', () => ({
  ReceiptPreviewModal: ({ isOpen, receiptData }: { isOpen: boolean; receiptData: { receiptNumber?: string } | null }) =>
    isOpen ? <div data-testid="receipt-modal">{receiptData?.receiptNumber}</div> : null,
}))
vi.mock('../../utils/electron', () => ({ isElectron: () => false }))
vi.mock('../../components/ui/toaster', () => ({
  toast: { error: vi.fn(), success: vi.fn(), warning: vi.fn(), info: vi.fn() },
}))
vi.mock('../../utils/localQueue', () => ({ getCompanyType: () => 'BEST_CHANGE' }))

const TODAY = new Intl.DateTimeFormat('sv-SE', { timeZone: 'Europe/Budapest' }).format(new Date())
const OTHER_DAY = '2020-01-15'

const baseShipment = {
  id: 'shipment-1',
  requestNumber: 'SH-001',
  requestingBranchId: 'branch-1',
  requestingBranchName: 'Szeged Értéktár',
  targetBranchId: 'branch-2',
  targetBranchName: 'Belváros',
  shipmentType: 'TRANSFER',
  requestedDeliveryDate: TODAY,
  requestStatus: 'APPROVED',
  requestedByWorkerId: '77',
  requestedByWorkerName: 'Teszt Dolgozó',
  requestedAt: `${TODAY}T10:00:00`,
  carrierName: 'Teszt Szállító',
  sealNumber: 'PL-123',
  items: [{ id: 'item-1', currencyId: 1, currencyCode: 'EUR', requestedAmount: 1000 }],
}

const approvedShipment = { ...baseShipment }
const draftShipment = {
  ...baseShipment,
  requestStatus: 'DRAFT',
  notes: 'Eredeti megjegyzés',
}

describe('ShipmentListPage backend contract + FK kétfüles nézet', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.findByStatus.mockResolvedValue([approvedShipment])
    mocks.findByBranch.mockResolvedValue([approvedShipment])
    mocks.get.mockResolvedValue(approvedShipment)
    mocks.update.mockResolvedValue({ ...draftShipment, notes: 'Módosított megjegyzés', sealNumber: 'PL-999' })
    mocks.approve.mockResolvedValue({ ...approvedShipment, requestStatus: 'APPROVED' })
    mocks.reject.mockResolvedValue({ ...approvedShipment, requestStatus: 'REJECTED' })
    mocks.deliver.mockResolvedValue({ ...approvedShipment, requestStatus: 'DELIVERED' })
    mocks.cancel.mockResolvedValue({ ...approvedShipment, requestStatus: 'CANCELLED' })
    vi.spyOn(window, 'confirm').mockReturnValue(true)
    vi.spyOn(window, 'prompt').mockReturnValue('Teszt elutasítás')
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('a részletek gomb a GET /shipments/{id} backend szerződést hívja és panelt nyit', async () => {
    const user = userEvent.setup()
    render(<MemoryRouter><ShipmentListPage /></MemoryRouter>)

    await waitFor(() => expect(mocks.findByStatus).toHaveBeenCalledWith('SUBMITTED'))
    await user.click(await screen.findByTitle('Részletek'))

    await waitFor(() => {
      expect(mocks.get).toHaveBeenCalledWith('shipment-1')
      expect(screen.getByTestId('shipment-detail-panel')).toHaveTextContent('SH-001')
      expect(screen.getByTestId('shipment-detail-panel')).toHaveTextContent('PL-123')
      expect(screen.getByTestId('shipment-detail-panel')).toHaveTextContent('EUR')
    })
  })

  it('kézbesítés és sztornó a backend workflow endpointokra van kötve (FR-13 átnevezés)', async () => {
    const user = userEvent.setup()
    render(<MemoryRouter><ShipmentListPage /></MemoryRouter>)

    await waitFor(() => expect(screen.getByText('SH-001')).toBeInTheDocument())
    expect(screen.queryByTitle('Visszavonás')).toBeNull()
    await user.click(screen.getByTitle('Kézbesítés'))
    await user.click(screen.getByTitle('shipments.sztorno'))

    await waitFor(() => {
      expect(mocks.deliver).toHaveBeenCalledWith('shipment-1')
      expect(mocks.cancel).toHaveBeenCalledWith('shipment-1')
    })
  })

  it('DRAFT részletpanelen a szerkesztés a PUT /shipments/{id} szerződést hívja', async () => {
    mocks.findByStatus.mockResolvedValue([draftShipment])
    mocks.get.mockResolvedValue(draftShipment)
    const user = userEvent.setup()
    render(<MemoryRouter><ShipmentListPage /></MemoryRouter>)

    await waitFor(() => expect(screen.getByText('SH-001')).toBeInTheDocument())
    await user.click(screen.getByTitle('Részletek'))
    await user.click(await screen.findByTestId('shipment-start-edit'))
    await user.clear(screen.getByTestId('shipment-edit-carrier'))
    await user.type(screen.getByTestId('shipment-edit-carrier'), 'Új Szállító')
    await user.clear(screen.getByTestId('shipment-edit-seal'))
    await user.type(screen.getByTestId('shipment-edit-seal'), 'PL-999')
    await user.clear(screen.getByTestId('shipment-edit-notes'))
    await user.type(screen.getByTestId('shipment-edit-notes'), 'Módosított megjegyzés')
    await user.click(screen.getByTestId('shipment-save-edit'))

    await waitFor(() => {
      expect(mocks.update).toHaveBeenCalledWith('shipment-1', {
        fromBranchId: 'branch-1',
        toBranchId: 'branch-2',
        deliveryDate: TODAY,
        carrierName: 'Új Szállító',
        sealNumber: 'PL-999',
        notes: 'Módosított megjegyzés',
      })
    })
  })

  it('FR-1: két fül látható, alapból a "Ma" aktív', async () => {
    render(<MemoryRouter><ShipmentListPage /></MemoryRouter>)
    await waitFor(() => expect(screen.getByText('SH-001')).toBeInTheDocument())

    expect(screen.getByTestId('shipment-tab-today')).toBeInTheDocument()
    expect(screen.getByTestId('shipment-tab-past')).toBeInTheDocument()
    // "Ma" fülön van státuszszűrő (combobox), és látszik a mai bizonylat
    expect(screen.getByRole('combobox')).toBeInTheDocument()
  })

  it('FR-2: a "Ma" fülön csak az aznapi bizonylat látszik, a másik napi nem', async () => {
    mocks.findByStatus.mockResolvedValue([
      approvedShipment,
      { ...approvedShipment, id: 'shipment-2', requestNumber: 'SH-OLD', requestedDeliveryDate: OTHER_DAY },
    ])
    render(<MemoryRouter><ShipmentListPage /></MemoryRouter>)

    await waitFor(() => expect(screen.getByText('SH-001')).toBeInTheDocument())
    expect(screen.queryByText('SH-OLD')).toBeNull()
  })

  it('FR-12: a REJECTED státusz szűrhető és "Elutasítva" badge-dzsel jelenik meg', async () => {
    const user = userEvent.setup()
    mocks.findByStatus.mockResolvedValue([{ ...approvedShipment, requestStatus: 'REJECTED' }])
    render(<MemoryRouter><ShipmentListPage /></MemoryRouter>)

    await waitFor(() => expect(screen.getByText('SH-001')).toBeInTheDocument())
    await user.selectOptions(screen.getByRole('combobox'), 'REJECTED')

    await waitFor(() => expect(mocks.findByStatus).toHaveBeenCalledWith('REJECTED'))
    expect(screen.getByText('Elutasítva')).toBeInTheDocument()
  })

  it('FR-10: a "Korábbi" fülön nincs státuszszűrő, naptár + üres állapot jelenik meg', async () => {
    const user = userEvent.setup()
    render(<MemoryRouter><ShipmentListPage /></MemoryRouter>)
    await waitFor(() => expect(screen.getByText('SH-001')).toBeInTheDocument())

    await user.click(screen.getByTestId('shipment-tab-past'))

    await waitFor(() => expect(mocks.findByBranch).toHaveBeenCalledWith('branch-1'))
    expect(screen.queryByRole('combobox')).toBeNull()
    expect(screen.getByTestId('shipment-calendar')).toBeInTheDocument()
    expect(screen.getByTestId('past-empty-state')).toBeInTheDocument()
  })

  it('FR-8/FR-9/FR-11: "Korábbi" fülön napra kattintva a lista csak megtekintés + újranyomtatás gombot ad, és az újranyomtatás GET /shipments/{id}-t hív', async () => {
    const user = userEvent.setup()
    render(<MemoryRouter><ShipmentListPage /></MemoryRouter>)
    await waitFor(() => expect(screen.getByText('SH-001')).toBeInTheDocument())

    await user.click(screen.getByTestId('shipment-tab-past'))
    await waitFor(() => expect(screen.getByTestId('shipment-calendar')).toBeInTheDocument())

    await user.click(screen.getByTestId(`calendar-day-${TODAY}-active`))

    // Napi lista megjelenik, csak megtekintés + újranyomtatás — nincs operatív gomb
    await waitFor(() => expect(screen.getByText('SH-001')).toBeInTheDocument())
    expect(screen.getByTitle('Részletek')).toBeInTheDocument()
    expect(screen.getByTitle('shipments.ujranyomtatas')).toBeInTheDocument()
    expect(screen.queryByTitle('shipments.sztorno')).toBeNull()
    expect(screen.queryByTitle('Jóváhagyás')).toBeNull()
    expect(screen.queryByTitle('Kézbesítés')).toBeNull()

    mocks.get.mockClear()
    await user.click(screen.getByTitle('shipments.ujranyomtatas'))

    await waitFor(() => {
      expect(mocks.get).toHaveBeenCalledWith('shipment-1')
      expect(screen.getByTestId('receipt-modal')).toHaveTextContent('SH-001')
    })
  })
})
