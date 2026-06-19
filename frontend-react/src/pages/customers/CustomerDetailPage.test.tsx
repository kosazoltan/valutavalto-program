/**
 * V.2.7 c) — CustomerDetailPage EDD-badge + Pmt. 30.§ (1) manuális jelölés tesztek (V309/V310).
 */
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import CustomerDetailPage from './CustomerDetailPage'
import { useAuthStore } from '../../stores/authStore'

const mocks = vi.hoisted(() => ({
  customerApi: { getById: vi.fn(), markEdd: vi.fn(), update: vi.fn(), merge: vi.fn() },
  customerControlApi: {
    getRestrictions: vi.fn(),
    addRestriction: vi.fn(),
    removeRestriction: vi.fn(),
    getAnnualTotal: vi.fn(),
    getScreeningLog: vi.fn(),
  },
  amlApi: {
    customerRisk: vi.fn(),
    structuringCheck: vi.fn(),
  },
}))

vi.mock('../../services/api/transactions', () => ({
  customerApi: mocks.customerApi,
  customerControlApi: mocks.customerControlApi,
}))

vi.mock('../../services/api/aml', () => ({
  amlApi: mocks.amlApi,
}))

const BASE_CUSTOMER = {
  id: 42,
  customerCode: 'C-42',
  name: 'Teszt Elek',
  active: true,
  isVip: false,
  isPep: false,
  transactionCount: 3,
  createdAt: '2026-01-01T10:00:00',
}

function setRole(role: string) {
  useAuthStore.setState({
    worker: {
      id: 7, workerCode: 'W7', firstName: 'T', lastName: 'T', fullName: 'T T',
      role, branchId: 'BR-A', branchCode: 'EBC', branchName: 'Teszt',
      companyId: 'C-1', companyCode: 'EXC', companyName: 'Exc Valuta',
    } as never,
    isAuthenticated: true,
    roles: [],
    activeRole: null,
  })
}

function renderPage() {
  return render(
    <MemoryRouter initialEntries={['/customers/42']}>
      <Routes>
        <Route path="/customers/:id" element={<CustomerDetailPage />} />
      </Routes>
    </MemoryRouter>,
  )
}

describe('CustomerDetailPage — EDD-badge + Pmt.30.§ jelölés', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    setRole('SUPERVISOR')
    mocks.customerControlApi.getRestrictions.mockResolvedValue([])
    mocks.customerControlApi.getAnnualTotal.mockResolvedValue(0)
    mocks.customerControlApi.getScreeningLog.mockResolvedValue([])
    mocks.amlApi.customerRisk.mockResolvedValue({
      customerId: '42',
      customerName: 'Teszt Elek',
      riskLevel: 'LOW',
      last30DaysTotal: 0,
      last30DaysTransactionCount: 0,
      dailyTotal: 0,
      dailyTransactionCount: 0,
      annualTotal: 0,
      structuringDetected: false,
      highFrequency: false,
      highVolume: false,
    })
    mocks.amlApi.structuringCheck.mockResolvedValue({ customerId: '42', structuringDetected: false })
  })

  it('aktív EDD-ablaknál piros badge látszik a lejárattal', async () => {
    mocks.customerApi.getById.mockResolvedValue({
      ...BASE_CUSTOMER,
      eddActive: true,
      eddUntil: '2027-06-30',
      eddReason: 'V.2.7 b): >=100M Ft havi készpénzforgalom',
    })
    renderPage()
    // hu-HU lokalizált dátum a badge-ben (Sourcery review)
    await waitFor(() => expect(screen.getByText('EDD 2027. 06. 30.-ig')).toBeInTheDocument())
  })

  it('EDD-jelölés gomb supervisor-nak látszik, indokkal POST-ol és frissíti az ügyfelet', async () => {
    mocks.customerApi.getById.mockResolvedValue({ ...BASE_CUSTOMER, eddActive: false })
    mocks.customerApi.markEdd.mockResolvedValue({
      ...BASE_CUSTOMER, eddActive: true, eddUntil: '2027-06-11',
      eddReason: 'Pmt. 30.§ (1) bejelentés (V.2.7 c): NAV 2026/123',
    })
    renderPage()
    await waitFor(() => expect(screen.getByText('EDD-jelölés (Pmt. 30.§)')).toBeInTheDocument())

    fireEvent.click(screen.getByText('EDD-jelölés (Pmt. 30.§)'))
    const textarea = await screen.findByLabelText('Indok (pl. bejelentés azonosító)')
    fireEvent.change(textarea, { target: { value: 'NAV 2026/123' } })
    fireEvent.click(screen.getByText('EDD-jelölés rögzítése'))

    await waitFor(() => expect(mocks.customerApi.markEdd).toHaveBeenCalledWith(42, 'NAV 2026/123'))
    await waitFor(() => expect(screen.getByText('EDD 2027. 06. 11.-ig')).toBeInTheDocument())
  })

  it('pénztárosnak az EDD-jelölés gomb nem jelenik meg', async () => {
    setRole('CASHIER')
    mocks.customerApi.getById.mockResolvedValue({ ...BASE_CUSTOMER })
    renderPage()
    await waitFor(() => expect(mocks.customerApi.getById).toHaveBeenCalled())
    expect(screen.queryByText('EDD-jelölés (Pmt. 30.§)')).not.toBeInTheDocument()
  })

  it('betölti az ügyfél-ellenőrzés backend adatait az ügyfél részletezőn', async () => {
    mocks.customerApi.getById.mockResolvedValue({ ...BASE_CUSTOMER })
    mocks.customerControlApi.getRestrictions.mockResolvedValue([
      {
        id: 'restr-1',
        customerId: 42,
        restrictionType: 'WATCH_LIST',
        reason: 'Fokozott figyelés',
        addedAt: '2026-06-18T08:00:00',
        active: true,
      },
    ])
    mocks.customerControlApi.getAnnualTotal.mockResolvedValue(12500000)
    mocks.customerControlApi.getScreeningLog.mockResolvedValue([
      {
        id: 'log-1',
        customerId: 42,
        screeningType: 'SUSPICION',
        result: 'FLAGGED',
        details: 'Gyanú-bejelentés teszt',
        screenedAt: '2026-06-18T09:00:00',
      },
    ])
    mocks.amlApi.customerRisk.mockResolvedValue({
      customerId: '42',
      customerName: 'Teszt Elek',
      riskLevel: 'HIGH',
      last30DaysTotal: 6500000,
      last30DaysTransactionCount: 6,
      dailyTotal: 900000,
      dailyTransactionCount: 2,
      annualTotal: 12500000,
      structuringDetected: true,
      highFrequency: true,
      highVolume: true,
    })
    mocks.amlApi.structuringCheck.mockResolvedValue({ customerId: '42', structuringDetected: true })

    renderPage()

    await waitFor(() => expect(mocks.customerControlApi.getRestrictions).toHaveBeenCalledWith(42))
    expect(mocks.customerControlApi.getAnnualTotal).toHaveBeenCalledWith(42)
    expect(mocks.customerControlApi.getScreeningLog).toHaveBeenCalledWith(42)
    expect(mocks.amlApi.customerRisk).toHaveBeenCalledWith('42')
    expect(mocks.amlApi.structuringCheck).toHaveBeenCalledWith('42')
    expect(screen.getByTestId('customer-annual-total')).toHaveTextContent('12 500 000 Ft')
    expect(screen.getByTestId('customer-aml-risk')).toHaveTextContent('Magas')
    expect(screen.getByText('Fokozott figyelés')).toBeInTheDocument()
    expect(screen.getByText('Gyanú-bejelentés teszt')).toBeInTheDocument()
    expect(screen.getByText('Igen')).toBeInTheDocument()
  })

  it('supervisor korlátozást rögzít és deaktivál a customer-control API-n', async () => {
    mocks.customerApi.getById.mockResolvedValue({ ...BASE_CUSTOMER })
    mocks.customerControlApi.getRestrictions.mockResolvedValue([
      {
        id: 'restr-1',
        customerId: 42,
        restrictionType: 'WATCH_LIST',
        reason: 'Fokozott figyelés',
        active: true,
      },
    ])
    mocks.customerControlApi.addRestriction.mockResolvedValue({
      id: 'restr-2',
      customerId: 42,
      restrictionType: 'BLOCKED',
      reason: 'Tiltás oka',
      active: true,
    })
    mocks.customerControlApi.removeRestriction.mockResolvedValue(undefined)

    renderPage()
    await screen.findByText('Fokozott figyelés')

    fireEvent.change(screen.getByTestId('restriction-type-select'), { target: { value: 'BLOCKED' } })
    fireEvent.change(screen.getByTestId('restriction-reason-input'), { target: { value: 'Tiltás oka' } })
    fireEvent.click(screen.getByText('Korlátozás rögzítése'))

    await waitFor(() => expect(mocks.customerControlApi.addRestriction).toHaveBeenCalledWith(42, {
      restrictionType: 'BLOCKED',
      reason: 'Tiltás oka',
      expiresAt: null,
    }))

    fireEvent.click(screen.getByLabelText('Korlátozás deaktiválása'))
    await waitFor(() => expect(mocks.customerControlApi.removeRestriction).toHaveBeenCalledWith('restr-1'))
  })

  it('manager ügyfél-összevonásnál meghívja a /customers/merge backend szerződést', async () => {
    setRole('MANAGER')
    const confirmSpy = vi.spyOn(window, 'confirm').mockReturnValue(true)
    mocks.customerApi.getById.mockResolvedValue({ ...BASE_CUSTOMER })
    mocks.customerApi.merge.mockResolvedValue({
      ...BASE_CUSTOMER,
      transactionCount: 8,
      lastTransactionDate: '2026-06-18',
    })

    renderPage()

    await screen.findByTestId('customer-merge-panel')
    fireEvent.change(screen.getByTestId('duplicate-customer-id-input'), { target: { value: '99' } })
    fireEvent.click(screen.getByText('Ügyfelek összevonása'))

    await waitFor(() => expect(mocks.customerApi.merge).toHaveBeenCalledWith(42, 99))
    expect(confirmSpy).toHaveBeenCalled()
    await waitFor(() => expect(screen.getByText('8')).toBeInTheDocument())
    confirmSpy.mockRestore()
  })

  it('ügyfél-összevonás nem hív backend-et, ha a duplikált ID azonos az aktuális ügyféllel', async () => {
    setRole('MANAGER')
    const confirmSpy = vi.spyOn(window, 'confirm').mockReturnValue(true)
    mocks.customerApi.getById.mockResolvedValue({ ...BASE_CUSTOMER })

    renderPage()

    await screen.findByTestId('customer-merge-panel')
    fireEvent.change(screen.getByTestId('duplicate-customer-id-input'), { target: { value: '42' } })
    fireEvent.click(screen.getByText('Ügyfelek összevonása'))

    expect(await screen.findByText('Az elsődleges és a duplikált ügyfél nem lehet ugyanaz.')).toBeInTheDocument()
    expect(mocks.customerApi.merge).not.toHaveBeenCalled()
    expect(confirmSpy).not.toHaveBeenCalled()
    confirmSpy.mockRestore()
  })

  it('pénztárosnak az ügyfél-összevonási panel nem jelenik meg', async () => {
    setRole('CASHIER')
    mocks.customerApi.getById.mockResolvedValue({ ...BASE_CUSTOMER })

    renderPage()

    await waitFor(() => expect(mocks.customerApi.getById).toHaveBeenCalledWith(42))
    expect(screen.queryByTestId('customer-merge-panel')).not.toBeInTheDocument()
  })
})
