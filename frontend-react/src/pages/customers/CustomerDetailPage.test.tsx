/**
 * V.2.7 c) — CustomerDetailPage EDD-badge + Pmt. 30.§ (1) manuális jelölés tesztek (V309/V310).
 */
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import CustomerDetailPage from './CustomerDetailPage'
import { useAuthStore } from '../../stores/authStore'

const mocks = vi.hoisted(() => ({
  customerApi: { getById: vi.fn(), markEdd: vi.fn(), update: vi.fn() },
}))

vi.mock('../../services/api/transactions', () => ({
  customerApi: mocks.customerApi,
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
  })

  it('aktív EDD-ablaknál piros badge látszik a lejárattal', async () => {
    mocks.customerApi.getById.mockResolvedValue({
      ...BASE_CUSTOMER,
      eddActive: true,
      eddUntil: '2027-06-30',
      eddReason: 'V.2.7 b): >=100M Ft havi készpénzforgalom',
    })
    renderPage()
    await waitFor(() => expect(screen.getByText('EDD 2027-06-30-ig')).toBeInTheDocument())
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
    await waitFor(() => expect(screen.getByText('EDD 2027-06-11-ig')).toBeInTheDocument())
  })

  it('pénztárosnak az EDD-jelölés gomb nem jelenik meg', async () => {
    setRole('CASHIER')
    mocks.customerApi.getById.mockResolvedValue({ ...BASE_CUSTOMER })
    renderPage()
    await waitFor(() => expect(mocks.customerApi.getById).toHaveBeenCalled())
    expect(screen.queryByText('EDD-jelölés (Pmt. 30.§)')).not.toBeInTheDocument()
  })
})
