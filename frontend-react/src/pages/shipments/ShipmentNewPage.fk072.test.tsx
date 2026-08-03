import { describe, it, expect, vi, beforeEach } from 'vitest'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import ShipmentNewPage from './ShipmentNewPage'
import { useAuthStore } from '../../stores/authStore'

/**
 * FK-072_v2 FR-5 (CSAK frontend — a backend-oldal Helga döntésére vár):
 * a Szállítmány-létrehozás címletezési sorában az 1 alatti névérték beírásakor
 * a beküldés tiltott, egyértelmű hibával. Ma a kliens-validáció csak <= 0-t
 * utasít el (ShipmentNewPage:312-319), a 0,5 összeg-egyezéssel átmegy.
 */

const mocks = vi.hoisted(() => ({
  branchApi: {
    listActive: vi.fn(),
    listMyTerritory: vi.fn(),
    listCashierShipmentTargets: vi.fn(),
    listVaultCounterparties: vi.fn(),
  },
  currencyApi: { getActive: vi.fn() },
  exchangeRateApi: { getByCurrencyId: vi.fn() },
  shipmentRequestApi: { create: vi.fn(), createHandlingFee: vi.fn(), submit: vi.fn() },
  persistToken: vi.fn(),
  clearPersistedToken: vi.fn(),
}))

vi.mock('../../services/api/index', () => mocks)

async function fillBaseForm(user: ReturnType<typeof userEvent.setup>) {
  await waitFor(() => expect(screen.getByLabelText(/Átvevő/i)).not.toBeDisabled())
  await user.selectOptions(screen.getByLabelText(/Átvevő/i), 'BR-B')
  await user.selectOptions(screen.getByLabelText(/Valuta/i), '4')
  await user.type(screen.getByLabelText(/Összeg/i), '1250')
  await user.type(screen.getByLabelText(/Szállító neve/i), "Brink's Hungary Kft.")
  await user.type(screen.getByLabelText(/Plombaszám/i), 'ABC/12-3')
}

/** Hozzáad egy címletsort és kitölti (darab × névleges érték). */
async function addDenominationLine(
  user: ReturnType<typeof userEvent.setup>,
  quantity: string,
  faceValue: string,
) {
  await user.click(screen.getByRole('button', { name: /Sor hozzáadása/i }))
  fireEvent.change(screen.getByPlaceholderText('Darab'), { target: { value: quantity } })
  fireEvent.change(screen.getByPlaceholderText('Névleges érték'), {
    target: { value: faceValue },
  })
}

describe('ShipmentNewPage — FK-072_v2 tört címletek (FR-5 frontend, FR-7)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
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
    mocks.branchApi.listCashierShipmentTargets.mockResolvedValue([
      { id: 'BR-A', code: 'EBC', name: 'Erzsébet körút', isActive: true },
      { id: 'BR-B', code: 'BEL', name: 'Belváros', isActive: true },
    ])
    mocks.branchApi.listVaultCounterparties.mockResolvedValue({
      territorialCashiers: [],
      peerVaults: [],
      fixedCounterparties: [],
    })
    mocks.currencyApi.getActive.mockResolvedValue([
      { id: 4, code: 'EUR', name: 'Euró', decimals: 2, active: true },
    ])
    mocks.exchangeRateApi.getByCurrencyId.mockResolvedValue({
      currencyId: 4,
      currencyCode: 'EUR',
      officialRate: 400,
      baseBuyRate: 395,
      baseSellRate: 405,
      validDate: '2026-08-03',
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
      requestedAt: '2026-08-03T10:00:00',
      requestedDeliveryDate: '2026-08-04',
      carrierName: "Brink's Hungary Kft.",
      sealNumber: 'ABC/12-3',
    }
    mocks.shipmentRequestApi.create.mockResolvedValue(shipmentResponse)
    mocks.shipmentRequestApi.submit.mockResolvedValue({
      ...shipmentResponse,
      requestStatus: 'SUBMITTED',
    })
  })

  it('FR-5: 1 alatti névérték (2500 × 0,5) → hiba jelenik meg és a create API NEM hívódik', async () => {
    const user = userEvent.setup()
    render(
      <MemoryRouter>
        <ShipmentNewPage />
      </MemoryRouter>,
    )

    await fillBaseForm(user)
    // 2500 × 0,5 = 1250 — az összeg-egyezés teljesül, kizárólag a >= 1 szabály tilthat.
    await addDenominationLine(user, '2500', '0.5')

    await user.click(screen.getByRole('button', { name: /Igény beküldése/i }))

    await waitFor(() => {
      expect(screen.getByText(/1-nél kisebb/)).toBeInTheDocument()
    })
    expect(mocks.shipmentRequestApi.create).not.toHaveBeenCalled()
  })

  it('FR-7 regresszió: egész névértékű címletezés (25 × 50 = 1250) változatlanul beküldhető', async () => {
    const user = userEvent.setup()
    render(
      <MemoryRouter>
        <ShipmentNewPage />
      </MemoryRouter>,
    )

    await fillBaseForm(user)
    await addDenominationLine(user, '25', '50')

    await user.click(screen.getByRole('button', { name: /Igény beküldése/i }))

    await waitFor(() => {
      expect(mocks.shipmentRequestApi.create).toHaveBeenCalledTimes(1)
    })
    expect(mocks.shipmentRequestApi.submit).toHaveBeenCalledWith('shipment-1')
  })
})
