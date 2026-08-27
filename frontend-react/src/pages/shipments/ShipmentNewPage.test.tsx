import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import ShipmentNewPage from './ShipmentNewPage'
import { useAuthStore } from '../../stores/authStore'

const mocks = vi.hoisted(() => ({
  branchApi: {
    listActive: vi.fn(),
    listMyTerritory: vi.fn(),
    listCashierShipmentTargets: vi.fn(),
    listVaultCounterparties: vi.fn(),
  },
  currencyApi: { getActive: vi.fn() },
  exchangeRateApi: { getByCurrencyId: vi.fn() },
  shipmentRequestApi: {
    create: vi.fn(),
    createHandlingFee: vi.fn(),
    createVatSupply: vi.fn(),
    submit: vi.fn(),
  },
  persistToken: vi.fn(),
  clearPersistedToken: vi.fn(),
}))

vi.mock('../../services/api/index', () => mocks)

describe('ShipmentNewPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    // Teljes auth-state-reset (CASHIER alap; a 2. teszt értéktáros user-re setState-elheti).
    useAuthStore.setState({
      worker: {
        id: 7,
        workerCode: 'KOSA',
        firstName: 'Zoltán',
        lastName: 'Kósa',
        fullName: 'Kósa Zoltán',
        role: 'CASHIER',
        branchId: 'BR-A',
        branchCode: 'EBC',
        branchName: 'Erzsébet körút',
        companyId: 'C-1',
        companyCode: 'EXC',
        companyName: 'Exc Valuta',
      },
      user: null,
      isAuthenticated: true,
      roles: [],
      activeRole: null,
    })
    mocks.branchApi.listMyTerritory.mockResolvedValue([
      { id: 'BR-A', code: 'EBC', name: 'Erzsébet körút', isActive: true },
      { id: 'BR-B', code: 'BEL', name: 'Belváros', isActive: true },
    ])
    // FK-013 (#897): pénztáros user a szűkített listCashierShipmentTargets- et kapja
    // (NEM a listMyTerritory-t). A teszt 'BR-B'-t választ, ezért itt is szerepelnie kell.
    mocks.branchApi.listCashierShipmentTargets.mockResolvedValue([
      { id: 'BR-A', code: 'EBC', name: 'Erzsébet körút', isActive: true },
      { id: 'BR-B', code: 'BEL', name: 'Belváros', isActive: true },
    ])
    // FK-013 default: üres listák, hogy a teszt-ek ne timeout-oljanak ha valamely teszt
    // értéktáros user-rel fut, de nem mockolja explicit.
    mocks.branchApi.listVaultCounterparties.mockResolvedValue({
      territorialCashiers: [],
      peerVaults: [],
      fixedCounterparties: [],
    })
    mocks.currencyApi.getActive.mockResolvedValue([
      { id: 4, code: 'EUR', name: 'Euró', decimals: 2, active: true },
    ])
    // D követelmény: a valuta-választás után a frontend lekéri az aktuális elszámoló árfolyamot.
    mocks.exchangeRateApi.getByCurrencyId.mockResolvedValue({
      currencyId: 4,
      currencyCode: 'EUR',
      officialRate: 400,
      baseBuyRate: 395,
      baseSellRate: 405,
      validDate: '2026-05-28',
      validTime: '12:00',
      active: true,
    })
    const shipmentResponse = {
      id: 'shipment-1',
      requestNumber: 'AT-000001',
      fromBranchCode: 'BR075',
      fromBranchName: 'Szeged Értéktár',
      toBranchCode: 'BR027',
      toBranchName: 'Szeged Tesco',
      requestedByWorkerName: 'Bali Henriett',
      requestedAt: '2026-06-21T10:00:00',
      requestedDeliveryDate: '2026-06-22',
      carrierName: "Brink's Hungary Kft.",
      sealNumber: 'ABC/12-3',
    }
    mocks.shipmentRequestApi.create.mockResolvedValue(shipmentResponse)
    mocks.shipmentRequestApi.submit.mockResolvedValue({
      ...shipmentResponse,
      requestStatus: 'SUBMITTED',
    })
  })

  it('creates and submits a shipment request from the real form', async () => {
    const user = userEvent.setup()
    render(
      <MemoryRouter>
        <ShipmentNewPage />
      </MemoryRouter>,
    )

    expect(screen.queryByText(/v2\.5\.0-ban érkezik/i)).not.toBeInTheDocument()
    await waitFor(() => expect(screen.getByLabelText(/Átvevő/i)).not.toBeDisabled())
    await user.selectOptions(screen.getByLabelText(/Átvevő/i), 'BR-B')
    await user.selectOptions(screen.getByLabelText(/Valuta/i), '4')
    await user.type(screen.getByLabelText(/Összeg/i), '1250')
    // FK02: a szállító + plombaszám kötelező — kitöltjük, különben a validáció blokkolja a beküldést.
    await user.type(screen.getByLabelText(/Szállító neve/i), "Brink's Hungary Kft.")
    await user.type(screen.getByLabelText(/Plombaszám/i), 'ABC/12-3')
    await user.click(screen.getByRole('button', { name: /Igény beküldése/i }))

    // D követelmény (Codex P1): a payload NEM tartalmazza az appliedRate / hufValue mezőt,
    // a backend a server-oldali aktuális rate-tel autoritatív; a frontend csak display.
    await waitFor(() =>
      expect(mocks.shipmentRequestApi.create).toHaveBeenCalledWith({
        fromBranchId: 'BR-A',
        toBranchId: 'BR-B',
        deliveryDate: undefined,
        notes: '',
        carrierName: "Brink's Hungary Kft.",
        sealNumber: 'ABC/12-3',
        items: [{ currencyId: '4', requestedAmount: 1250 }],
      }),
    )
    expect(mocks.shipmentRequestApi.submit).toHaveBeenCalledWith('shipment-1')
    await waitFor(() => expect(screen.getByText('Átadó:')).toBeInTheDocument())
    expect(screen.getByText(/BR075 - Szeged Értéktár/)).toBeInTheDocument()
    expect(screen.getByText('Átvevő:')).toBeInTheDocument()
    expect(screen.getByText(/BR027 - Szeged Tesco/)).toBeInTheDocument()
  })

  it('a bizonylat fejlécét kizárólag a szerver cím- és telefonadataiból tölti ki', async () => {
    const user = userEvent.setup()
    mocks.branchApi.listCashierShipmentTargets.mockResolvedValue([
      {
        id: 'BR-A',
        code: 'EBC',
        name: 'Erzsébet körút',
        city: 'Elavult város',
        address: 'Elavult cím 1.',
        zipCode: '0000',
        phone: '00 000 0000',
        isActive: true,
      },
      { id: 'BR-B', code: 'BEL', name: 'Belváros', isActive: true },
    ])
    const serverShipment = {
      id: 'shipment-1',
      requestNumber: 'FF-000001',
      fromBranchCode: 'BR075',
      fromBranchName: 'Szeged Értéktár',
      toBranchCode: 'BR027',
      toBranchName: 'Szeged Tesco',
      requestedByWorkerName: 'Bali Henriett',
      requestedAt: '2026-06-21T10:00:00',
      carrierName: "Brink's Hungary Kft.",
      sealNumber: 'ABC/12-3',
      vaultAddress: 'Szeged, Hajnóczy u. 57., 6722',
      vaultPhone: '+36 62 555 010',
    }
    mocks.shipmentRequestApi.create.mockResolvedValue(serverShipment)
    mocks.shipmentRequestApi.submit.mockResolvedValue({
      ...serverShipment,
      requestStatus: 'SUBMITTED',
    })

    render(
      <MemoryRouter>
        <ShipmentNewPage />
      </MemoryRouter>,
    )

    await waitFor(() => expect(screen.getByLabelText(/Átvevő/i)).not.toBeDisabled())
    await user.selectOptions(screen.getByLabelText(/Átvevő/i), 'BR-B')
    await user.selectOptions(screen.getByLabelText(/Valuta/i), '4')
    await user.type(screen.getByLabelText(/Összeg/i), '1250')
    await user.type(screen.getByLabelText(/Szállító neve/i), "Brink's Hungary Kft.")
    await user.type(screen.getByLabelText(/Plombaszám/i), 'ABC/12-3')
    await user.click(screen.getByRole('button', { name: /Igény beküldése/i }))

    expect(await screen.findByText('Szeged, Hajnóczy u. 57., 6722')).toBeInTheDocument()
    expect(screen.getByText('Tel: +36 62 555 010')).toBeInTheDocument()
    expect(screen.queryByText('Elavult város, Elavult cím 1., 0000')).not.toBeInTheDocument()
    expect(screen.queryByText('Tel: 00 000 0000')).not.toBeInTheDocument()
  })

  it('FK02: hiányzó szállító/plombaszám esetén blokkolja a beküldést és hibát mutat', async () => {
    const user = userEvent.setup()
    render(
      <MemoryRouter>
        <ShipmentNewPage />
      </MemoryRouter>,
    )

    await waitFor(() => expect(screen.getByLabelText(/Átvevő/i)).not.toBeDisabled())
    await user.selectOptions(screen.getByLabelText(/Átvevő/i), 'BR-B')
    await user.selectOptions(screen.getByLabelText(/Valuta/i), '4')
    await user.type(screen.getByLabelText(/Összeg/i), '1250')
    // Szándékosan NEM töltjük ki a szállító + plombaszám mezőt.
    await user.click(screen.getByRole('button', { name: /Igény beküldése/i }))

    // A kötelező-validáció blokkol: sem create, sem submit nem hívódik, és megjelenik a hiba.
    await waitFor(() =>
      expect(screen.getByText(/A szállító nevének megadása kötelező!/i)).toBeInTheDocument(),
    )
    expect(mocks.shipmentRequestApi.create).not.toHaveBeenCalled()
    expect(mocks.shipmentRequestApi.submit).not.toHaveBeenCalled()
  })

  it('outbound átadásnál a zárolt Átadó mező a saját értéktár nevét mutatja', async () => {
    useAuthStore.setState({
      worker: {
        id: 99,
        workerCode: 'BALI',
        firstName: 'Henriett',
        lastName: 'Bali',
        fullName: 'Bali Henriett',
        role: 'CASHIER',
        branchId: 'BR-VAULT-SZEGED',
        branchCode: 'BR075',
        branchName: 'Szeged Értéktár',
        companyId: 'C-1',
        companyCode: 'EBC',
        companyName: 'EBC',
      },
      isAuthenticated: true,
      roles: ['ertektar'],
      activeRole: 'ertektar',
    })
    mocks.branchApi.listVaultCounterparties.mockResolvedValue({
      territorialCashiers: [{ id: 'BR-TER-1', code: 'BR026', name: 'Szeged Móra', isActive: true }],
      peerVaults: [],
      fixedCounterparties: [],
    })

    render(
      <MemoryRouter initialEntries={['/shipments/new?direction=outbound']}>
        <ShipmentNewPage />
      </MemoryRouter>,
    )

    const fromSelect = await screen.findByLabelText(/Átadó/i)
    await waitFor(() => expect(fromSelect).toBeDisabled())
    expect(fromSelect).toHaveDisplayValue('BR075 - Szeged Értéktár')
  })

  it('FK-013: értéktáros user esetén 3-csoportos optgroup az Átvevő dropdown-ban', async () => {
    // Értéktáros worker → hasCanonicalRole('ertektar') → listVaultCounterparties
    useAuthStore.setState({
      worker: {
        id: 99,
        workerCode: 'BALI',
        firstName: 'Henriett',
        lastName: 'Bali',
        fullName: 'Bali Henriett',
        role: 'CASHIER',
        branchId: 'BR-VAULT-SZEGED',
        branchCode: 'BR-VAULT-SZEGED',
        branchName: 'Szeged Értéktár',
        companyId: 'C-1',
        companyCode: 'EBC',
        companyName: 'EBC',
      },
      isAuthenticated: true,
      roles: ['ertektar'],
      activeRole: 'ertektar',
    })
    mocks.branchApi.listVaultCounterparties.mockResolvedValue({
      territorialCashiers: [
        { id: 'BR-TER-1', code: 'BR026', name: 'Szeged Móra', isActive: true },
        { id: 'BR-TER-2', code: 'BR027', name: 'Szeged Tesco', isActive: true },
      ],
      peerVaults: [
        { id: 'BR-VAULT-DEB', code: 'BR050', name: 'Debrecen Értéktár', isActive: true },
        { id: 'BR-VAULT-KEC', code: 'BR040', name: 'Kecskemét Értéktár', isActive: true },
      ],
      fixedCounterparties: [
        { id: 'BR-PRB', code: 'PRB', name: 'POS Raiffeisen Bank', isActive: true },
        { id: 'BR-MNB', code: 'MNB', name: 'Magyar Nemzeti Bank', isActive: true },
      ],
    })

    render(
      <MemoryRouter>
        <ShipmentNewPage />
      </MemoryRouter>,
    )

    // Először assertions, hogy az értéktáros user esetén a megfelelő endpoint hívódott.
    await waitFor(() => expect(mocks.branchApi.listVaultCounterparties).toHaveBeenCalled())
    expect(mocks.branchApi.listMyTerritory).not.toHaveBeenCalled()

    // 3 optgroup csoport — <optgroup label="..."> role='group' name-attribute-szel
    // (a getByText az `label` attribute-ot NEM látja text-content-ként). Mind a 2 select-en
    // (Átadó + Átvevő) renderelődik, ezért getAllByRole + length-assert.
    await waitFor(() => {
      const territorialGroups = screen.getAllByRole('group', { name: /Helyi Pénztárak/i })
      expect(territorialGroups.length).toBeGreaterThanOrEqual(1)
    })
    expect(
      screen.getAllByRole('group', { name: /Társ értéktárak/i }).length,
    ).toBeGreaterThanOrEqual(1)
    expect(
      screen.getAllByRole('group', { name: /Banki és speciális partnerek/i }).length,
    ).toBeGreaterThanOrEqual(1)

    // A 6 partner mind option-ként (mindkét select-ben szerepelnek, getAllByRole)
    expect(
      screen.getAllByRole('option', { name: /BR026 - Szeged Móra/ }).length,
    ).toBeGreaterThanOrEqual(1)
    expect(
      screen.getAllByRole('option', { name: /BR050 - Debrecen Értéktár/ }).length,
    ).toBeGreaterThanOrEqual(1)
    expect(
      screen.getAllByRole('option', { name: /PRB - POS Raiffeisen Bank/ }).length,
    ).toBeGreaterThanOrEqual(1)
    expect(
      screen.getAllByRole('option', { name: /MNB - Magyar Nemzeti Bank/ }).length,
    ).toBeGreaterThanOrEqual(1)

    // A régi /branches/my-territory NEM hívódik értéktáros user esetén (már fent asserted)
  })

  it('FKH-018: pénztáros user NEM látja a Kezelési költség tételtípust', async () => {
    render(
      <MemoryRouter>
        <ShipmentNewPage />
      </MemoryRouter>,
    )

    await waitFor(() => expect(screen.getByLabelText(/Átvevő/i)).not.toBeDisabled())
    expect(screen.queryByLabelText(/Tétel típusa/i)).not.toBeInTheDocument()
  })

  it('FKH-018: értéktáros user kiválaszthatja a Kezelési költség tételtípust és a createHandlingFee hívódik', async () => {
    const user = userEvent.setup()
    useAuthStore.setState({
      worker: {
        id: 99,
        workerCode: 'BALI',
        firstName: 'Henriett',
        lastName: 'Bali',
        fullName: 'Bali Henriett',
        role: 'CASHIER',
        branchId: 'BR-VAULT-SZEGED',
        branchCode: 'BR075',
        branchName: 'Szeged Értéktár',
        companyId: 'C-1',
        companyCode: 'EBC',
        companyName: 'EBC',
      },
      isAuthenticated: true,
      roles: ['ertektar'],
      activeRole: 'ertektar',
    })
    mocks.branchApi.listVaultCounterparties.mockResolvedValue({
      territorialCashiers: [{ id: 'BR-TER-1', code: 'BR026', name: 'Szeged Móra', isActive: true }],
      peerVaults: [],
      fixedCounterparties: [],
    })
    mocks.shipmentRequestApi.createHandlingFee.mockResolvedValue({
      shipment: {
        id: 'shipment-1',
        requestNumber: 'KK-000001',
        fromBranchCode: 'BR026',
        fromBranchName: 'Szeged Móra',
        toBranchCode: 'BR075',
        toBranchName: 'Szeged Értéktár',
        requestedByWorkerName: 'Bali Henriett',
        requestedAt: '2026-06-21T10:00:00',
        carrierName: "Brink's Hungary Kft.",
        sealNumber: 'ABC/12-3',
      },
      handlingFee: {
        hufAmount: 125000,
        calculatedFee: 625,
        status: 'DRAFT',
      },
    })

    render(
      <MemoryRouter initialEntries={['/shipments/new?direction=inbound']}>
        <ShipmentNewPage />
      </MemoryRouter>,
    )

    const itemTypeSelect = await screen.findByLabelText(/Tétel típusa/i)
    await waitFor(() => expect(itemTypeSelect).not.toBeDisabled())
    await user.selectOptions(itemTypeSelect, 'handlingFee')

    expect(screen.queryByLabelText(/Valuta/i)).not.toBeInTheDocument()
    await user.selectOptions(screen.getByLabelText(/Átadó/i), 'BR-TER-1')
    await user.type(screen.getByLabelText(/Kezelési költség összege/i), '125000')
    await user.type(screen.getByLabelText(/Szállító neve/i), "Brink's Hungary Kft.")
    await user.type(screen.getByLabelText(/Plombaszám/i), 'ABC/12-3')
    await user.click(screen.getByRole('button', { name: /Igény beküldése/i }))

    await waitFor(() =>
      expect(mocks.shipmentRequestApi.createHandlingFee).toHaveBeenCalledWith({
        fromBranchId: 'BR-TER-1',
        toBranchId: 'BR-VAULT-SZEGED',
        hufAmount: 125000,
        deliveryDate: undefined,
        notes: '',
        carrierName: "Brink's Hungary Kft.",
        sealNumber: 'ABC/12-3',
      }),
    )
    expect(mocks.shipmentRequestApi.submit).toHaveBeenCalledWith('shipment-1')
    expect(mocks.shipmentRequestApi.create).not.toHaveBeenCalled()
  })

  it('FKH-018: kezelési költségnél a nem 5-tel osztható összeg hibát ad', async () => {
    const user = userEvent.setup()
    useAuthStore.setState({
      worker: {
        id: 99,
        workerCode: 'BALI',
        firstName: 'Henriett',
        lastName: 'Bali',
        fullName: 'Bali Henriett',
        role: 'CASHIER',
        branchId: 'BR-VAULT-SZEGED',
        branchCode: 'BR075',
        branchName: 'Szeged Értéktár',
        companyId: 'C-1',
        companyCode: 'EBC',
        companyName: 'EBC',
      },
      isAuthenticated: true,
      roles: ['ertektar'],
      activeRole: 'ertektar',
    })
    mocks.branchApi.listVaultCounterparties.mockResolvedValue({
      territorialCashiers: [{ id: 'BR-TER-1', code: 'BR026', name: 'Szeged Móra', isActive: true }],
      peerVaults: [],
      fixedCounterparties: [],
    })

    render(
      <MemoryRouter initialEntries={['/shipments/new?direction=inbound']}>
        <ShipmentNewPage />
      </MemoryRouter>,
    )

    const itemTypeSelect = await screen.findByLabelText(/Tétel típusa/i)
    await waitFor(() => expect(itemTypeSelect).not.toBeDisabled())
    await user.selectOptions(itemTypeSelect, 'handlingFee')
    await user.selectOptions(screen.getByLabelText(/Átadó/i), 'BR-TER-1')
    await user.type(screen.getByLabelText(/Kezelési költség összege/i), '125003')
    await user.type(screen.getByLabelText(/Szállító neve/i), "Brink's Hungary Kft.")
    await user.type(screen.getByLabelText(/Plombaszám/i), 'ABC/12-3')
    await user.click(screen.getByRole('button', { name: /Igény beküldése/i }))

    await waitFor(() =>
      expect(
        screen.getByText(/pozitív, 5 Ft-ra kerekített érték kell legyen/i),
      ).toBeInTheDocument(),
    )
    expect(mocks.shipmentRequestApi.createHandlingFee).not.toHaveBeenCalled()
  })

  it('FKH-040: értéktáros user kiválaszthatja az ÁFA átadás-átvétel tételtípust és a createVatSupply hívódik', async () => {
    const user = userEvent.setup()
    useAuthStore.setState({
      worker: {
        id: 99,
        workerCode: 'BALI',
        firstName: 'Henriett',
        lastName: 'Bali',
        fullName: 'Bali Henriett',
        role: 'CASHIER',
        branchId: 'BR-VAULT-SZEGED',
        branchCode: 'BR075',
        branchName: 'Szeged Értéktár',
        companyId: 'C-1',
        companyCode: 'EBC',
        companyName: 'EBC',
      },
      isAuthenticated: true,
      roles: ['ertektar'],
      activeRole: 'ertektar',
    })
    mocks.branchApi.listVaultCounterparties.mockResolvedValue({
      territorialCashiers: [{ id: 'BR-TER-1', code: 'BR026', name: 'Szeged Móra', isActive: true }],
      peerVaults: [],
      fixedCounterparties: [],
    })
    mocks.shipmentRequestApi.createVatSupply.mockResolvedValue({
      shipment: {
        id: 'shipment-vat-1',
        requestNumber: 'KK-000002',
        fromBranchCode: 'BR026',
        fromBranchName: 'Szeged Móra',
        toBranchCode: 'BR075',
        toBranchName: 'Szeged Értéktár',
        requestedByWorkerName: 'Bali Henriett',
        requestedAt: '2026-06-21T10:00:00',
        carrierName: "Brink's Hungary Kft.",
        sealNumber: 'ABC/12-3',
      },
      vatSupply: {
        hufAmount: 50000,
        status: 'DRAFT',
      },
    })

    render(
      <MemoryRouter initialEntries={['/shipments/new?direction=inbound']}>
        <ShipmentNewPage />
      </MemoryRouter>,
    )

    const itemTypeSelect = await screen.findByLabelText(/Tétel típusa/i)
    await waitFor(() => expect(itemTypeSelect).not.toBeDisabled())
    await user.selectOptions(itemTypeSelect, 'vatSupply')

    expect(screen.queryByLabelText(/Valuta/i)).not.toBeInTheDocument()
    await user.selectOptions(screen.getByLabelText(/Átadó/i), 'BR-TER-1')
    await user.type(screen.getByLabelText(/ÁFA ellátmány összege/i), '50000')
    await user.type(screen.getByLabelText(/Szállító neve/i), "Brink's Hungary Kft.")
    await user.type(screen.getByLabelText(/Plombaszám/i), 'ABC/12-3')
    await user.click(screen.getByRole('button', { name: /Igény beküldése/i }))

    await waitFor(() =>
      expect(mocks.shipmentRequestApi.createVatSupply).toHaveBeenCalledWith({
        fromBranchId: 'BR-TER-1',
        toBranchId: 'BR-VAULT-SZEGED',
        hufAmount: 50000,
        deliveryDate: undefined,
        notes: '',
        carrierName: "Brink's Hungary Kft.",
        sealNumber: 'ABC/12-3',
      }),
    )
    expect(mocks.shipmentRequestApi.submit).toHaveBeenCalledWith('shipment-vat-1')
    expect(mocks.shipmentRequestApi.create).not.toHaveBeenCalled()
    expect(mocks.shipmentRequestApi.createHandlingFee).not.toHaveBeenCalled()
  })
})
