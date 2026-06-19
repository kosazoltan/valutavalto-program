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

const approvedShipment = {
  id: 'shipment-1',
  requestNumber: 'SH-001',
  requestingBranchId: 'branch-1',
  requestingBranchName: 'Szeged Értéktár',
  targetBranchId: 'branch-2',
  targetBranchName: 'Belváros',
  shipmentType: 'TRANSFER',
  requestedDeliveryDate: '2026-06-18',
  requestStatus: 'APPROVED',
  requestedByWorkerId: '77',
  requestedByWorkerName: 'Teszt Dolgozó',
  requestedAt: '2026-06-18T10:00:00',
  carrierName: 'Teszt Szállító',
  sealNumber: 'PL-123',
  items: [
    { id: 'item-1', currencyId: 1, currencyCode: 'EUR', requestedAmount: 1000 },
  ],
}

const draftShipment = {
  ...approvedShipment,
  requestStatus: 'DRAFT',
  requestedDeliveryDate: '2026-06-20',
  notes: 'Eredeti megjegyzés',
}

describe('ShipmentListPage backend contract', () => {
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

  it('kézbesítés és visszavonás a backend workflow endpointokra van kötve', async () => {
    const user = userEvent.setup()
    render(<MemoryRouter><ShipmentListPage /></MemoryRouter>)

    await waitFor(() => expect(screen.getByText('SH-001')).toBeInTheDocument())
    await user.click(screen.getByTitle('Kézbesítés'))
    await user.click(screen.getByTitle('Visszavonás'))

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
        deliveryDate: '2026-06-20',
        carrierName: 'Új Szállító',
        sealNumber: 'PL-999',
        notes: 'Módosított megjegyzés',
      })
    })
  })
})
