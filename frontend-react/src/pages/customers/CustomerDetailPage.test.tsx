/**
 * V.2.7 c) — CustomerDetailPage EDD-badge + Pmt. 30.§ (1) manuális jelölés tesztek (V309/V310).
 */
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import CustomerDetailPage from './CustomerDetailPage'
import { useAuthStore } from '../../stores/authStore'

const mocks = vi.hoisted(() => ({
  customerApi: {
    getById: vi.fn(),
    getStats: vi.fn(),
    getHistory: vi.fn(),
    markEdd: vi.fn(),
    setRiskRating: vi.fn(),
    review: vi.fn(),
    getVersions: vi.fn(),
    getVersion: vi.fn(),
    update: vi.fn(),
    merge: vi.fn(),
  },
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
  documentScannerApi: {
    getCustomerDocuments: vi.fn(),
  },
  persistToken: vi.fn(),
  clearPersistedToken: vi.fn(),
}))

vi.mock('../../services/api/transactions', () => ({
  customerApi: mocks.customerApi,
  customerControlApi: mocks.customerControlApi,
}))

vi.mock('../../services/api/aml', () => ({
  amlApi: mocks.amlApi,
}))

vi.mock('../../services/api/index', () => ({
  documentScannerApi: mocks.documentScannerApi,
  persistToken: mocks.persistToken,
  clearPersistedToken: mocks.clearPersistedToken,
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
      id: 7,
      workerCode: 'W7',
      firstName: 'T',
      lastName: 'T',
      fullName: 'T T',
      role,
      branchId: 'BR-A',
      branchCode: 'EBC',
      branchName: 'Teszt',
      companyId: 'C-1',
      companyCode: 'EXC',
      companyName: 'Exc Valuta',
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
    mocks.customerApi.getStats.mockResolvedValue({
      customerId: 42,
      customerName: 'Teszt Elek',
      totalTransactions: 3,
      totalVolumeHuf: 1250000,
      averageAmount: 416667,
      firstVisit: '2026-01-05',
      lastVisit: '2026-06-18',
      preferredCurrency: 'EUR',
    })
    mocks.customerApi.getHistory.mockResolvedValue({
      customerId: 42,
      customerName: 'Teszt Elek',
      totalTransactions: 2,
      totalVolumeHuf: 850000,
      averageAmount: 425000,
      firstVisit: '2026-06-01',
      lastVisit: '2026-06-18',
      preferredCurrency: 'USD',
    })
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
    mocks.amlApi.structuringCheck.mockResolvedValue({
      customerId: '42',
      structuringDetected: false,
    })
    mocks.documentScannerApi.getCustomerDocuments.mockResolvedValue([])
    mocks.persistToken.mockResolvedValue(undefined)
    mocks.clearPersistedToken.mockResolvedValue(undefined)
    mocks.customerApi.getVersions.mockResolvedValue([])
    mocks.customerApi.getVersion.mockResolvedValue({
      versionNo: 1,
      changedBy: 'W1',
      changedAt: '2026-07-06T10:00:00',
      changeSource: 'CASHIER',
      snapshot: '{"name":"Teszt Elek"}',
    })
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
      ...BASE_CUSTOMER,
      eddActive: true,
      eddUntil: '2027-06-11',
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

  it('HIGH kockázati besorolásnál piros badge látszik', async () => {
    mocks.customerApi.getById.mockResolvedValue({ ...BASE_CUSTOMER, riskRating: 'HIGH' })

    renderPage()

    expect(await screen.findByText('Magas')).toBeInTheDocument()
    expect(screen.getByText('Kockázati besorolás')).toBeInTheDocument()
  })

  it('MANAGER szerepnél a kockázati besorolás állító gomb látszik, CASHIER-nél nem', async () => {
    setRole('MANAGER')
    mocks.customerApi.getById.mockResolvedValue({ ...BASE_CUSTOMER, riskRating: 'LOW' })
    const { unmount } = renderPage()

    expect(await screen.findByText('Kockázati besorolás állítása')).toBeInTheDocument()
    unmount()

    vi.clearAllMocks()
    setRole('CASHIER')
    mocks.customerControlApi.getRestrictions.mockResolvedValue([])
    mocks.customerControlApi.getAnnualTotal.mockResolvedValue(0)
    mocks.customerControlApi.getScreeningLog.mockResolvedValue([])
    mocks.customerApi.getStats.mockResolvedValue({
      customerId: 42,
      customerName: 'Teszt Elek',
      totalTransactions: 0,
      totalVolumeHuf: 0,
      averageAmount: 0,
    })
    mocks.customerApi.getHistory.mockResolvedValue({
      customerId: 42,
      customerName: 'Teszt Elek',
      totalTransactions: 0,
      totalVolumeHuf: 0,
      averageAmount: 0,
    })
    mocks.customerApi.getById.mockResolvedValue({ ...BASE_CUSTOMER, riskRating: 'LOW' })
    renderPage()
    await waitFor(() => expect(mocks.customerApi.getById).toHaveBeenCalledWith(42))
    expect(screen.queryByText('Kockázati besorolás állítása')).not.toBeInTheDocument()
  })

  it('kockázati besorolás modal submitja meghívja a dedikált endpointot az indokkal', async () => {
    setRole('MANAGER')
    mocks.customerApi.getById.mockResolvedValue({ ...BASE_CUSTOMER, riskRating: 'LOW' })
    mocks.customerApi.setRiskRating.mockResolvedValue({ ...BASE_CUSTOMER, riskRating: 'HIGH' })

    renderPage()
    fireEvent.click(await screen.findByText('Kockázati besorolás állítása'))
    fireEvent.change(await screen.findByLabelText('Kockázati besorolás'), {
      target: { value: 'HIGH' },
    })
    fireEvent.change(screen.getByLabelText('Indok'), { target: { value: 'Compliance döntés' } })
    fireEvent.click(screen.getByText('Besorolás mentése'))

    await waitFor(() =>
      expect(mocks.customerApi.setRiskRating).toHaveBeenCalledWith(42, 'HIGH', 'Compliance döntés'),
    )
    expect(await screen.findByText('Magas')).toBeInTheDocument()
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
    expect(await screen.findByTestId('customer-annual-total')).toHaveTextContent('12 500 000 Ft')
    expect(await screen.findByTestId('customer-aml-risk')).toHaveTextContent('Magas')
    expect(screen.getByText('Fokozott figyelés')).toBeInTheDocument()
    expect(screen.getByText('Gyanú-bejelentés teszt')).toBeInTheDocument()
    expect(screen.getByText('Igen')).toBeInTheDocument()
  })

  it('betölti és dátumszűrővel frissíti a CustomerController stats/history read endpointokat', async () => {
    mocks.customerApi.getById.mockResolvedValue({ ...BASE_CUSTOMER })
    mocks.customerApi.getHistory
      .mockResolvedValueOnce({
        customerId: 42,
        customerName: 'Teszt Elek',
        totalTransactions: 2,
        totalVolumeHuf: 850000,
        averageAmount: 425000,
        firstVisit: '2026-06-01',
        lastVisit: '2026-06-18',
        preferredCurrency: 'USD',
      })
      .mockResolvedValueOnce({
        customerId: 42,
        customerName: 'Teszt Elek',
        totalTransactions: 1,
        totalVolumeHuf: 500000,
        averageAmount: 500000,
        firstVisit: '2026-06-10',
        lastVisit: '2026-06-10',
        preferredCurrency: 'CHF',
      })

    renderPage()

    await waitFor(() => expect(mocks.customerApi.getStats).toHaveBeenCalledWith(42))
    expect(mocks.customerApi.getHistory).toHaveBeenCalledWith(42, undefined)
    expect(await screen.findByTestId('customer-backend-stats')).toHaveTextContent('1 250 000 Ft')
    const historyStats = await screen.findByTestId('customer-history-stats')
    expect(historyStats).toHaveTextContent('850 000 Ft')
    expect(historyStats).toHaveTextContent('USD')

    fireEvent.change(screen.getByTestId('customer-history-from'), {
      target: { value: '2026-06-10' },
    })
    fireEvent.change(screen.getByTestId('customer-history-to'), { target: { value: '2026-06-19' } })
    fireEvent.click(screen.getByText('Időszak frissítése'))

    await waitFor(() =>
      expect(mocks.customerApi.getHistory).toHaveBeenLastCalledWith(42, {
        from: '2026-06-10',
        to: '2026-06-19',
      }),
    )
    expect(await screen.findByText('500 000 Ft')).toBeInTheDocument()
    expect(screen.getByText('CHF')).toBeInTheDocument()
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

    fireEvent.change(screen.getByTestId('restriction-type-select'), {
      target: { value: 'BLOCKED' },
    })
    fireEvent.change(screen.getByTestId('restriction-reason-input'), {
      target: { value: 'Tiltás oka' },
    })
    fireEvent.click(screen.getByText('Korlátozás rögzítése'))

    await waitFor(() =>
      expect(mocks.customerControlApi.addRestriction).toHaveBeenCalledWith(42, {
        restrictionType: 'BLOCKED',
        reason: 'Tiltás oka',
        expiresAt: null,
      }),
    )

    fireEvent.click(screen.getByLabelText('Korlátozás deaktiválása'))
    await waitFor(() =>
      expect(mocks.customerControlApi.removeRestriction).toHaveBeenCalledWith('restr-1'),
    )
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

    expect(
      await screen.findByText('Az elsődleges és a duplikált ügyfél nem lehet ugyanaz.'),
    ).toBeInTheDocument()
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

  it('PENDING_REVIEW ügyfélnél látszik az Átnézésre vár badge és az Átnézve gomb', async () => {
    mocks.customerApi.getById.mockResolvedValue({
      ...BASE_CUSTOMER,
      reviewStatus: 'PENDING_REVIEW',
    })

    renderPage()

    expect(await screen.findByText('Átnézésre vár')).toBeInTheDocument()
    expect(screen.getByText('Átnézve')).toBeInTheDocument()
  })

  it('Átnézve gomb kattintás review API-t hív és REVIEWED badge-re frissít', async () => {
    mocks.customerApi.getById.mockResolvedValue({
      ...BASE_CUSTOMER,
      reviewStatus: 'PENDING_REVIEW',
    })
    mocks.customerApi.review.mockResolvedValue({
      ...BASE_CUSTOMER,
      reviewStatus: 'REVIEWED',
      reviewedBy: 'W7',
    })

    renderPage()
    fireEvent.click(await screen.findByText('Átnézve'))

    await waitFor(() => expect(mocks.customerApi.review).toHaveBeenCalledWith(42))
    expect(await screen.findByText('Átnézve: W7')).toBeInTheDocument()
  })

  it('REVIEWED ügyfélnél az Átnézve gomb nem látszik', async () => {
    mocks.customerApi.getById.mockResolvedValue({
      ...BASE_CUSTOMER,
      reviewStatus: 'REVIEWED',
      reviewedBy: 'W7',
    })

    renderPage()

    expect(await screen.findByText('Átnézve: W7')).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Átnézve' })).not.toBeInTheDocument()
  })

  it('kirendereli a verziótörténet metaadatait', async () => {
    mocks.customerApi.getById.mockResolvedValue({ ...BASE_CUSTOMER, reviewStatus: 'REVIEWED' })
    mocks.customerApi.getVersions.mockResolvedValue([
      {
        versionNo: 2,
        changedBy: 'W2',
        changedAt: '2026-07-06T12:00:00',
        changeSource: 'COMPLIANCE',
      },
      { versionNo: 1, changedBy: 'W1', changedAt: '2026-07-06T10:00:00', changeSource: 'CASHIER' },
    ])

    renderPage()

    expect(await screen.findByText('Verziótörténet')).toBeInTheDocument()
    expect(screen.getByText('v2')).toBeInTheDocument()
    expect(screen.getByText('W2')).toBeInTheDocument()
    expect(screen.getByText('COMPLIANCE')).toBeInTheDocument()
  })
})
