import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import ShipmentListPage from './ShipmentListPage'
import { toast } from '../../components/ui/toaster'

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
  initReactI18next: { type: '3rdParty' },
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
  ReceiptPreviewModal: ({
    isOpen,
    receiptData,
  }: {
    isOpen: boolean
    receiptData: {
      receiptNumber?: string
      cashierName?: string
      date?: string
      branchCode?: string
      transferTarget?: string
      vaultAddress?: string
      vaultPhone?: string
      transferDocType?: 'handover' | 'receipt'
      isStorno?: boolean
      stornoReason?: string
    } | null
  }) =>
    isOpen ? (
      <div data-testid="receipt-modal">
        {receiptData?.receiptNumber}|{receiptData?.cashierName}|{receiptData?.date}|
        {receiptData?.branchCode}|{receiptData?.transferTarget}|{receiptData?.vaultAddress}|
        {receiptData?.vaultPhone ? `Tel: ${receiptData.vaultPhone}` : ''}|
        {receiptData?.isStorno ? 'SZTORNÓ' : ''}|{receiptData?.stornoReason}|
        {receiptData?.transferDocType === 'receipt' && !receiptData?.isStorno
          ? 'Büntetőjogi felelősségem tudatában, kijelentem'
          : ''}
      </div>
    ) : null,
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
    mocks.update.mockResolvedValue({
      ...draftShipment,
      notes: 'Módosított megjegyzés',
      sealNumber: 'PL-999',
    })
    mocks.approve.mockResolvedValue({ ...approvedShipment, requestStatus: 'APPROVED' })
    mocks.reject.mockResolvedValue({ ...approvedShipment, requestStatus: 'REJECTED' })
    mocks.deliver.mockResolvedValue({ ...approvedShipment, requestStatus: 'DELIVERED' })
    mocks.cancel.mockResolvedValue({
      ...approvedShipment,
      requestStatus: 'CANCELLED',
      cancelledByWorkerName: 'Teszt Sztornózó',
      cancelledAt: `${TODAY}T11:30:00`,
    })
    vi.spyOn(window, 'confirm').mockReturnValue(true)
    vi.spyOn(window, 'prompt').mockReturnValue('Teszt elutasítás')
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('a részletek gomb a GET /shipments/{id} backend szerződést hívja és panelt nyit', async () => {
    const user = userEvent.setup()
    render(
      <MemoryRouter>
        <ShipmentListPage />
      </MemoryRouter>,
    )

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
    // FR-6: a "Megérkezett" gomb csak az ÁTVEVŐ (target) fióknak látszik. A bejelentkezett user
    // branchId='branch-1', így a shipmentet ide (target=branch-1) irányítjuk, hogy a gomb látszódjon.
    const incoming = { ...approvedShipment, targetBranchId: 'branch-1' }
    mocks.findByStatus.mockResolvedValue([incoming])
    const user = userEvent.setup()
    render(
      <MemoryRouter>
        <ShipmentListPage />
      </MemoryRouter>,
    )

    await waitFor(() => expect(screen.getByText('SH-001')).toBeInTheDocument())
    expect(screen.queryByTitle('Visszavonás')).toBeNull()
    await user.click(screen.getByTitle('Megérkezett'))
    await user.click(screen.getByTitle('shipments.sztorno'))

    await waitFor(() => {
      expect(mocks.deliver).toHaveBeenCalledWith('shipment-1', expect.any(String))
      expect(mocks.cancel).toHaveBeenCalledWith('shipment-1')
    })
  })

  it('stale Shipmentnél app-dialógust nyit, Mégse esetén nincs mutáció', async () => {
    const staleIncoming = {
      ...approvedShipment,
      targetBranchId: 'branch-1',
      staleForDelivery: true,
      staleThresholdHours: 48,
    }
    mocks.findByStatus.mockResolvedValue([staleIncoming])
    const user = userEvent.setup()
    render(
      <MemoryRouter>
        <ShipmentListPage />
      </MemoryRouter>,
    )

    await user.click(await screen.findByTitle('Megérkezett'))

    expect(window.confirm).not.toHaveBeenCalled()
    expect(screen.getByRole('alertdialog')).toHaveTextContent('SH-001')
    expect(mocks.deliver).not.toHaveBeenCalled()

    await user.click(screen.getByRole('button', { name: 'Mégse' }))
    expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument()
    expect(screen.getByText('SH-001')).toBeInTheDocument()
    expect(mocks.deliver).not.toHaveBeenCalled()
  })

  it('stale Shipment tudatos megerősítése confirmedStale bodyval kézbesít', async () => {
    const staleIncoming = {
      ...approvedShipment,
      targetBranchId: 'branch-1',
      staleForDelivery: true,
      staleThresholdHours: 48,
    }
    mocks.findByStatus.mockResolvedValue([staleIncoming])
    const user = userEvent.setup()
    render(
      <MemoryRouter>
        <ShipmentListPage />
      </MemoryRouter>,
    )

    await user.click(await screen.findByTitle('Megérkezett'))
    await user.click(screen.getByRole('button', { name: 'Igen, folytatás' }))

    await waitFor(() =>
      expect(mocks.deliver).toHaveBeenCalledWith('shipment-1', expect.any(String), {
        confirmedStale: true,
      }),
    )
    expect(window.confirm).not.toHaveBeenCalled()
  })

  it('FR-6: a "Megérkezett" gomb csak az ÁTVEVŐ (target) fiók felhasználójának látszik', async () => {
    // A bejelentkezett user branchId='branch-1'; a shipment ÁTVEVŐJE is branch-1 → gomb látható.
    mocks.findByStatus.mockResolvedValue([{ ...approvedShipment, targetBranchId: 'branch-1' }])
    render(
      <MemoryRouter>
        <ShipmentListPage />
      </MemoryRouter>,
    )

    await waitFor(() => expect(screen.getByText('SH-001')).toBeInTheDocument())
    expect(screen.getByTitle('Megérkezett')).toBeInTheDocument()
  })

  it('FR-6: az ÁTADÓ fiók felhasználójának a "Megérkezett" gomb NEM látszik (teljesen elrejtve)', async () => {
    // A bejelentkezett user branchId='branch-1', de a shipment ÁTVEVŐJE branch-2 → ő az átadó
    // oldalon van, a gombot egyáltalán nem szabad látnia (FR-6: rejtve, nem disabled).
    mocks.findByStatus.mockResolvedValue([{ ...approvedShipment, targetBranchId: 'branch-2' }])
    render(
      <MemoryRouter>
        <ShipmentListPage />
      </MemoryRouter>,
    )

    await waitFor(() => expect(screen.getByText('SH-001')).toBeInTheDocument())
    expect(screen.queryByTitle('Megérkezett')).toBeNull()
  })

  it('KK-sor saját rögzítőjénél sincs jóváhagyás UI', async () => {
    mocks.findByStatus.mockResolvedValue([
      { ...baseShipment, requestNumber: 'KK-000001', requestStatus: 'SUBMITTED' },
    ])
    render(
      <MemoryRouter>
        <ShipmentListPage />
      </MemoryRouter>,
    )

    await screen.findByText('KK-000001')
    expect(screen.queryByTitle('Jóváhagyás')).not.toBeInTheDocument()
    expect(screen.queryByRole('option', { name: 'shipments.jovahagyva' })).not.toBeInTheDocument()
    expect(mocks.approve).not.toHaveBeenCalled()
  })

  it('KK-sor más rögzítőjénél sincs jóváhagyás UI', async () => {
    mocks.findByStatus.mockResolvedValue([
      {
        ...baseShipment,
        requestNumber: 'KK-000002',
        requestStatus: 'SUBMITTED',
        requestedByWorkerId: '88',
      },
    ])
    render(
      <MemoryRouter>
        <ShipmentListPage />
      </MemoryRouter>,
    )

    await screen.findByText('KK-000002')
    expect(screen.queryByTitle('Jóváhagyás')).not.toBeInTheDocument()
    expect(mocks.approve).not.toHaveBeenCalled()
  })

  it('SUBMITTED nem-KK sor célfiókja közvetlenül kézbesíthet approve nélkül', async () => {
    mocks.findByStatus.mockResolvedValue([
      {
        ...baseShipment,
        requestNumber: 'FF-000001',
        requestStatus: 'SUBMITTED',
        targetBranchId: 'branch-1',
      },
    ])
    const user = userEvent.setup()
    render(
      <MemoryRouter>
        <ShipmentListPage />
      </MemoryRouter>,
    )

    expect(screen.queryByTitle('Jóváhagyás')).not.toBeInTheDocument()
    await user.click(await screen.findByTitle('Megérkezett'))
    await waitFor(() =>
      expect(mocks.deliver).toHaveBeenCalledWith('shipment-1', expect.any(String)),
    )
    expect(mocks.approve).not.toHaveBeenCalled()
  })

  it('DRAFT részletpanelen a szerkesztés a PUT /shipments/{id} szerződést hívja', async () => {
    mocks.findByStatus.mockResolvedValue([draftShipment])
    mocks.get.mockResolvedValue(draftShipment)
    const user = userEvent.setup()
    render(
      <MemoryRouter>
        <ShipmentListPage />
      </MemoryRouter>,
    )

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
    render(
      <MemoryRouter>
        <ShipmentListPage />
      </MemoryRouter>,
    )
    await waitFor(() => expect(screen.getByText('SH-001')).toBeInTheDocument())

    expect(screen.getByTestId('shipment-tab-today')).toBeInTheDocument()
    expect(screen.getByTestId('shipment-tab-past')).toBeInTheDocument()
    // "Ma" fülön van státuszszűrő (combobox), és látszik a mai bizonylat
    expect(screen.getByRole('combobox')).toBeInTheDocument()
  })

  it('FR-2: a "Ma" fülön csak az aznapi bizonylat látszik, a másik napi nem', async () => {
    mocks.findByStatus.mockResolvedValue([
      approvedShipment,
      {
        ...approvedShipment,
        id: 'shipment-2',
        requestNumber: 'SH-OLD',
        requestedDeliveryDate: OTHER_DAY,
      },
    ])
    render(
      <MemoryRouter>
        <ShipmentListPage />
      </MemoryRouter>,
    )

    await waitFor(() => expect(screen.getByText('SH-001')).toBeInTheDocument())
    expect(screen.queryByText('SH-OLD')).toBeNull()
  })

  it('FR-12: a REJECTED státusz szűrhető és "Elutasítva" badge-dzsel jelenik meg', async () => {
    const user = userEvent.setup()
    mocks.findByStatus.mockResolvedValue([{ ...approvedShipment, requestStatus: 'REJECTED' }])
    render(
      <MemoryRouter>
        <ShipmentListPage />
      </MemoryRouter>,
    )

    await waitFor(() => expect(screen.getByText('SH-001')).toBeInTheDocument())
    await user.selectOptions(screen.getByRole('combobox'), 'REJECTED')

    await waitFor(() => expect(mocks.findByStatus).toHaveBeenCalledWith('REJECTED'))
    expect(screen.getByText('Elutasítva')).toBeInTheDocument()
  })

  it.each(['DRAFT', 'SUBMITTED', 'APPROVED', 'IN_TRANSIT'])(
    'a saját küldő %s Shipmentjén látható a sztornó gomb',
    async (requestStatus) => {
      mocks.findByStatus.mockResolvedValue([{ ...baseShipment, requestStatus }])
      render(
        <MemoryRouter>
          <ShipmentListPage />
        </MemoryRouter>,
      )

      await screen.findByText('SH-001')
      expect(screen.getByTitle('shipments.sztorno')).toBeInTheDocument()
    },
  )

  it.each(['REJECTED', 'DELIVERED', 'CANCELLED'])(
    '%s Shipmentnél rejtett a sztornó gomb',
    async (requestStatus) => {
      mocks.findByStatus.mockResolvedValue([{ ...baseShipment, requestStatus }])
      render(
        <MemoryRouter>
          <ShipmentListPage />
        </MemoryRouter>,
      )

      await screen.findByText('SH-001')
      expect(screen.queryByTitle('shipments.sztorno')).not.toBeInTheDocument()
    },
  )

  it('másik küldő fiók Shipmentjén rejtett a sztornó gomb', async () => {
    mocks.findByStatus.mockResolvedValue([
      { ...baseShipment, requestStatus: 'SUBMITTED', requestingBranchId: 'branch-foreign' },
    ])
    render(
      <MemoryRouter>
        <ShipmentListPage />
      </MemoryRouter>,
    )

    await screen.findByText('SH-001')
    expect(screen.queryByTitle('shipments.sztorno')).not.toBeInTheDocument()
  })

  it('FR-10: a "Korábbi" fülön nincs státuszszűrő, naptár + üres állapot jelenik meg', async () => {
    const user = userEvent.setup()
    render(
      <MemoryRouter>
        <ShipmentListPage />
      </MemoryRouter>,
    )
    await waitFor(() => expect(screen.getByText('SH-001')).toBeInTheDocument())

    await user.click(screen.getByTestId('shipment-tab-past'))

    await waitFor(() => expect(mocks.findByBranch).toHaveBeenCalledWith('branch-1'))
    expect(screen.queryByRole('combobox')).toBeNull()
    expect(screen.getByTestId('shipment-calendar')).toBeInTheDocument()
    expect(screen.getByTestId('past-empty-state')).toBeInTheDocument()
  })

  it('FR-8/FR-9/FR-11: "Korábbi" fülön napra kattintva az újranyomtatás GET /shipments/{id}-t hív', async () => {
    const user = userEvent.setup()
    render(
      <MemoryRouter>
        <ShipmentListPage />
      </MemoryRouter>,
    )
    await waitFor(() => expect(screen.getByText('SH-001')).toBeInTheDocument())

    await user.click(screen.getByTestId('shipment-tab-past'))
    await waitFor(() => expect(screen.getByTestId('shipment-calendar')).toBeInTheDocument())

    await user.click(screen.getByTestId(`calendar-day-${TODAY}-active`))

    // A történeti lista továbbra is ad részleteket és újranyomtatást; approve/deliver nincs rajta.
    await waitFor(() => expect(screen.getByText('SH-001')).toBeInTheDocument())
    expect(screen.getByTitle('Részletek')).toBeInTheDocument()
    expect(screen.getByTitle('shipments.ujranyomtatas')).toBeInTheDocument()
    expect(screen.queryByTitle('Jóváhagyás')).toBeNull()
    expect(screen.queryByTitle('Megérkezett')).toBeNull()

    mocks.get.mockClear()
    await user.click(screen.getByTitle('shipments.ujranyomtatas'))

    await waitFor(() => {
      expect(mocks.get).toHaveBeenCalledWith('shipment-1')
      expect(screen.getByTestId('receipt-modal')).toHaveTextContent('SH-001')
    })
  })

  it('FKH-006: reprintnél a szerver fejlécét és a kód-név iroda-címkéket mutatja UUID nélkül', async () => {
    const reprintShipment = {
      ...baseShipment,
      requestingBranchId: '11111111-1111-1111-1111-111111111111',
      targetBranchId: '22222222-2222-2222-2222-222222222222',
      fromBranchCode: 'BR075',
      fromBranchName: 'Szeged Értéktár',
      toBranchCode: 'BR027',
      toBranchName: 'Szeged Tesco',
      vaultAddress: 'Szeged, Hajnóczy u. 57., 6722',
      vaultPhone: '+36 62 555 010',
    }
    mocks.findByBranch.mockResolvedValue([reprintShipment])
    mocks.get.mockResolvedValue(reprintShipment)
    const user = userEvent.setup()
    render(
      <MemoryRouter>
        <ShipmentListPage />
      </MemoryRouter>,
    )

    await user.click(screen.getByTestId('shipment-tab-past'))
    await user.click(await screen.findByTestId(`calendar-day-${TODAY}-active`))
    await user.click(await screen.findByTitle('shipments.ujranyomtatas'))

    const receipt = await screen.findByTestId('receipt-modal')
    expect(receipt).toHaveTextContent('Szeged, Hajnóczy u. 57., 6722')
    expect(receipt).toHaveTextContent('Tel: +36 62 555 010')
    expect(receipt).toHaveTextContent('BR075 - Szeged Értéktár')
    expect(receipt).toHaveTextContent('BR027 - Szeged Tesco')
    expect(receipt).not.toHaveTextContent('11111111-1111-1111-1111-111111111111')
    expect(receipt).not.toHaveTextContent('22222222-2222-2222-2222-222222222222')
  })

  it('FKH-006: célfióki DELIVERED reprint átvételi nyilatkozatot mutat', async () => {
    const deliveredToCurrentBranch = {
      ...baseShipment,
      requestStatus: 'DELIVERED',
      targetBranchId: 'branch-1',
    }
    mocks.findByBranch.mockResolvedValue([deliveredToCurrentBranch])
    mocks.get.mockResolvedValue(deliveredToCurrentBranch)
    const user = userEvent.setup()
    render(
      <MemoryRouter>
        <ShipmentListPage />
      </MemoryRouter>,
    )

    await user.click(screen.getByTestId('shipment-tab-past'))
    await user.click(await screen.findByTestId(`calendar-day-${TODAY}-active`))
    await user.click(await screen.findByTitle('shipments.ujranyomtatas'))

    expect(await screen.findByTestId('receipt-modal')).toHaveTextContent(
      'Büntetőjogi felelősségem tudatában, kijelentem',
    )
  })

  it.each([
    ['küldő oldali DELIVERED', { requestStatus: 'DELIVERED', targetBranchId: 'branch-2' }],
    ['célfióki nem kézbesített', { requestStatus: 'APPROVED', targetBranchId: 'branch-1' }],
  ])('FKH-006: %s reprint nem mutat átvételi nyilatkozatot', async (_case, overrides) => {
    const shipment = { ...baseShipment, ...overrides }
    mocks.findByBranch.mockResolvedValue([shipment])
    mocks.get.mockResolvedValue(shipment)
    const user = userEvent.setup()
    render(
      <MemoryRouter>
        <ShipmentListPage />
      </MemoryRouter>,
    )

    await user.click(screen.getByTestId('shipment-tab-past'))
    await user.click(await screen.findByTestId(`calendar-day-${TODAY}-active`))
    await user.click(await screen.findByTitle('shipments.ujranyomtatas'))

    expect(await screen.findByTestId('receipt-modal')).not.toHaveTextContent(
      'Büntetőjogi felelősségem tudatában, kijelentem',
    )
  })

  it('FKH-018: a küldő a korábbi fülön is sztornózhat át nem vett Shipmentet, majd irattári bizonylatot kap', async () => {
    const historical = {
      ...baseShipment,
      requestedDeliveryDate: TODAY,
      requestedAt: `${TODAY}T10:00:00`,
      requestStatus: 'SUBMITTED',
    }
    mocks.findByBranch.mockResolvedValue([historical])
    mocks.cancel.mockResolvedValue({
      ...historical,
      requestStatus: 'CANCELLED',
      cancelledByWorkerName: 'Sztornózó Pénztáros',
      cancelledAt: '2020-01-15T11:30:00',
    })
    const user = userEvent.setup()
    render(
      <MemoryRouter>
        <ShipmentListPage />
      </MemoryRouter>,
    )

    await user.click(screen.getByTestId('shipment-tab-past'))
    await waitFor(() => expect(screen.getByTestId('shipment-calendar')).toBeInTheDocument())
    await user.click(screen.getByTestId(`calendar-day-${TODAY}-active`))
    await user.click(await screen.findByTitle('shipments.sztorno'))

    await waitFor(() => expect(mocks.cancel).toHaveBeenCalledWith('shipment-1'))
    expect(screen.getByTestId('receipt-modal')).toHaveTextContent('SH-001-SZ')
    expect(screen.getByTestId('receipt-modal')).toHaveTextContent('Sztornózó Pénztáros')
    expect(screen.getByTestId('receipt-modal')).toHaveTextContent(
      new Date('2020-01-15T11:30:00').toLocaleDateString('hu-HU'),
    )
    expect(screen.getByTestId('receipt-modal')).toHaveTextContent('SZTORNÓ')
    expect(screen.getByTestId('receipt-modal')).toHaveTextContent('Küldői sztornó átvétel előtt')
  })

  it('sikeres sztornó után a lista-frissítés hibája sem nyeli el az irattári bizonylatot', async () => {
    mocks.findByStatus
      .mockResolvedValueOnce([{ ...baseShipment, requestStatus: 'SUBMITTED' }])
      .mockRejectedValueOnce(new Error('refresh failed'))
    const user = userEvent.setup()
    render(
      <MemoryRouter>
        <ShipmentListPage />
      </MemoryRouter>,
    )

    await user.click(await screen.findByTitle('shipments.sztorno'))

    expect(await screen.findByTestId('receipt-modal')).toHaveTextContent('SH-001-SZ')
    expect(screen.getByTestId('receipt-modal')).toHaveTextContent('SZTORNÓ')
  })

  it('CANCELLED történeti Shipment újranyomtatása a sztornó-bizonylatot építi fel', async () => {
    const cancelled = {
      ...baseShipment,
      requestStatus: 'CANCELLED',
      cancelledByWorkerName: 'Archív Sztornózó',
      cancelledAt: '2020-01-15T14:20:30',
      vaultAddress: 'Szeged, Hajnóczy u. 57., 6722',
      vaultPhone: '+36 62 555 010',
    }
    mocks.findByBranch.mockResolvedValue([cancelled])
    mocks.get.mockResolvedValue(cancelled)
    const user = userEvent.setup()
    render(
      <MemoryRouter>
        <ShipmentListPage />
      </MemoryRouter>,
    )

    await user.click(screen.getByTestId('shipment-tab-past'))
    await user.click(await screen.findByTestId(`calendar-day-${TODAY}-active`))
    await user.click(await screen.findByTitle('shipments.ujranyomtatas'))

    expect(await screen.findByTestId('receipt-modal')).toHaveTextContent('SH-001-SZ')
    expect(screen.getByTestId('receipt-modal')).toHaveTextContent('Archív Sztornózó')
    expect(screen.getByTestId('receipt-modal')).toHaveTextContent('SZTORNÓ')
    expect(screen.getByTestId('receipt-modal')).toHaveTextContent('Szeged, Hajnóczy u. 57., 6722')
    expect(screen.getByTestId('receipt-modal')).toHaveTextContent('Tel: +36 62 555 010')
    expect(screen.getByTestId('receipt-modal')).not.toHaveTextContent(
      'Büntetőjogi felelősségem tudatában, kijelentem',
    )
  })

  it('FKH-018: auditadat nélkül nem fabrikál bizonylatot, de a sikeres sztornót sikeresnek jelzi', async () => {
    mocks.findByStatus.mockResolvedValue([{ ...baseShipment, requestStatus: 'SUBMITTED' }])
    mocks.cancel.mockResolvedValue({ ...baseShipment, requestStatus: 'CANCELLED' })
    const user = userEvent.setup()
    render(
      <MemoryRouter>
        <ShipmentListPage />
      </MemoryRouter>,
    )

    await user.click(await screen.findByTitle('shipments.sztorno'))

    await waitFor(() => expect(mocks.cancel).toHaveBeenCalledWith('shipment-1'))
    expect(screen.queryByTestId('receipt-modal')).not.toBeInTheDocument()
    expect(screen.queryByText(/auditadatai hiányoznak/)).not.toBeInTheDocument()
    expect(toast.success).toHaveBeenCalledWith(
      'Sztornó sikeres',
      expect.stringMatching(/bizonylat később újranyomtatható/i),
    )
    expect(toast.error).not.toHaveBeenCalled()
  })
})
