import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import ShipmentNewPage from './ShipmentNewPage'
import { useAuthStore } from '../../stores/authStore'

const mocks = vi.hoisted(() => ({
  branchApi: { listActive: vi.fn(), listMyTerritory: vi.fn(), listCashierShipmentTargets: vi.fn(), listVaultCounterparties: vi.fn() },
  currencyApi: { getActive: vi.fn() },
  exchangeRateApi: { getByCurrencyId: vi.fn() },
  shipmentRequestApi: { create: vi.fn(), submit: vi.fn() },
  persistToken: vi.fn(),
  clearPersistedToken: vi.fn(),
}))

vi.mock('../../services/api/index', () => mocks)

describe('ShipmentNewPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    // Teljes auth-state-reset (CASHIER alap; a 2. teszt értéktáros user-re setState-elheti).
    useAuthStore.setState({
      worker: { id: 7, workerCode: 'KOSA', firstName: 'Zoltán', lastName: 'Kósa', fullName: 'Kósa Zoltán', role: 'CASHIER', branchId: 'BR-A', branchCode: 'EBC', branchName: 'Erzsébet körút', companyId: 'C-1', companyCode: 'EXC', companyName: 'Exc Valuta' },
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
    mocks.currencyApi.getActive.mockResolvedValue([{ id: 4, code: 'EUR', name: 'Euró', decimals: 2, active: true }])
    // D követelmény: a valuta-választás után a frontend lekéri az aktuális elszámoló árfolyamot.
    mocks.exchangeRateApi.getByCurrencyId.mockResolvedValue({ currencyId: 4, currencyCode: 'EUR', officialRate: 400, baseBuyRate: 395, baseSellRate: 405, validDate: '2026-05-28', validTime: '12:00', active: true })
    mocks.shipmentRequestApi.create.mockResolvedValue({ id: 'shipment-1' })
    mocks.shipmentRequestApi.submit.mockResolvedValue({ id: 'shipment-1', requestStatus: 'SUBMITTED' })
  })

  it('creates and submits a shipment request from the real form', async () => {
    const user = userEvent.setup()
    render(<MemoryRouter><ShipmentNewPage /></MemoryRouter>)

    expect(screen.queryByText(/v2\.5\.0-ban érkezik/i)).not.toBeInTheDocument()
    await waitFor(() => expect(screen.getByLabelText(/Cél iroda/i)).not.toBeDisabled())
    await user.selectOptions(screen.getByLabelText(/Cél iroda/i), 'BR-B')
    await user.selectOptions(screen.getByLabelText(/Valuta/i), '4')
    await user.type(screen.getByLabelText(/Összeg/i), '1250')
    // FK02: a szállító + plombaszám kötelező — kitöltjük, különben a validáció blokkolja a beküldést.
    await user.type(screen.getByLabelText(/Szállító neve/i), "Brink's Hungary Kft.")
    await user.type(screen.getByLabelText(/Plombaszám/i), 'ABC/12-3')
    await user.click(screen.getByRole('button', { name: /Igény beküldése/i }))

    // D követelmény (Codex P1): a payload NEM tartalmazza az appliedRate / hufValue mezőt,
    // a backend a server-oldali aktuális rate-tel autoritatív; a frontend csak display.
    await waitFor(() => expect(mocks.shipmentRequestApi.create).toHaveBeenCalledWith({
      fromBranchId: 'BR-A',
      toBranchId: 'BR-B',
      deliveryDate: undefined,
      notes: '',
      carrierName: "Brink's Hungary Kft.",
      sealNumber: 'ABC/12-3',
      items: [{ currencyId: '4', requestedAmount: 1250 }],
    }))
    expect(mocks.shipmentRequestApi.submit).toHaveBeenCalledWith('shipment-1')
  })

  it('FK-013: értéktáros user esetén 3-csoportos optgroup a Cél iroda dropdown-ban', async () => {
    // Értéktáros worker → hasCanonicalRole('ertektar') → listVaultCounterparties
    useAuthStore.setState({
      worker: { id: 99, workerCode: 'BALI', firstName: 'Henriett', lastName: 'Bali', fullName: 'Bali Henriett', role: 'CASHIER', branchId: 'BR-VAULT-SZEGED', branchCode: 'BR-VAULT-SZEGED', branchName: 'Szeged Értéktár', companyId: 'C-1', companyCode: 'EBC', companyName: 'EBC' },
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

    render(<MemoryRouter><ShipmentNewPage /></MemoryRouter>)

    // Először assertions, hogy az értéktáros user esetén a megfelelő endpoint hívódott.
    await waitFor(() => expect(mocks.branchApi.listVaultCounterparties).toHaveBeenCalled())
    expect(mocks.branchApi.listMyTerritory).not.toHaveBeenCalled()

    // 3 optgroup csoport — <optgroup label="..."> role='group' name-attribute-szel
    // (a getByText az `label` attribute-ot NEM látja text-content-ként). Mind a 2 select-en
    // (Kérő iroda + Cél iroda) renderelődik, ezért getAllByRole + length-assert.
    await waitFor(() => {
      const territorialGroups = screen.getAllByRole('group', { name: /Helyi Pénztárak/i })
      expect(territorialGroups.length).toBeGreaterThanOrEqual(1)
    })
    expect(screen.getAllByRole('group', { name: /Társ értéktárak/i }).length).toBeGreaterThanOrEqual(1)
    expect(screen.getAllByRole('group', { name: /Banki és speciális partnerek/i }).length).toBeGreaterThanOrEqual(1)

    // A 6 partner mind option-ként (mindkét select-ben szerepelnek, getAllByRole)
    expect(screen.getAllByRole('option', { name: /BR026 - Szeged Móra/ }).length).toBeGreaterThanOrEqual(1)
    expect(screen.getAllByRole('option', { name: /BR050 - Debrecen Értéktár/ }).length).toBeGreaterThanOrEqual(1)
    expect(screen.getAllByRole('option', { name: /PRB - POS Raiffeisen Bank/ }).length).toBeGreaterThanOrEqual(1)
    expect(screen.getAllByRole('option', { name: /MNB - Magyar Nemzeti Bank/ }).length).toBeGreaterThanOrEqual(1)

    // A régi /branches/my-territory NEM hívódik értéktáros user esetén (már fent asserted)
  })
})
