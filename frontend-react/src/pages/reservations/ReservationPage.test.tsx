import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import ReservationPage from './ReservationPage'

const mocks = vi.hoisted(() => ({
  get: vi.fn(),
  post: vi.fn(),
  reservationList: vi.fn(),
  reservationGetById: vi.fn(),
  reservationCreate: vi.fn(),
  reservationCancel: vi.fn(),
  reservationCancelByCompany: vi.fn(),
  reservationFulfill: vi.fn(),
  reservationReceipt: vi.fn(),
  reservationReservedStock: vi.fn(),
  search: vi.fn(),
}))

vi.mock('@/services/api/index', () => ({
  api: { get: mocks.get, post: mocks.post },
  reservationsApi: {
    list: mocks.reservationList,
    getById: mocks.reservationGetById,
    create: mocks.reservationCreate,
    cancel: mocks.reservationCancel,
    cancelByCompany: mocks.reservationCancelByCompany,
    fulfill: mocks.reservationFulfill,
    receipt: mocks.reservationReceipt,
    reservedStock: mocks.reservationReservedStock,
  },
}))

vi.mock('@/services/api/transactions', () => ({
  customerApi: { search: mocks.search },
}))

const activeReservation = {
  id: 42,
  customerId: 7,
  customerName: 'Teszt Ügyfél',
  branchId: 'b-uuid',
  branchName: 'Teszt fiók',
  currencyCode: 'EUR',
  reservedAmount: 1000,
  exchangeRate: 385.5,
  depositAmount: 19275,
  status: 'ACTIVE',
  expiresAt: '2099-01-01T10:00:00',
  createdAt: '2026-05-22T08:00:00',
  fulfilledAt: null,
  cancelledAt: null,
  receiptNumber: 'B000042',
  cancellationReason: null,
  refundAmount: null,
  notes: null,
  expired: false,
}

const reservedStock = [
  {
    currencyCode: 'EUR',
    reservedAmount: 1500,
    activeCount: 2,
  },
]

describe('ReservationPage — backend kontraktus', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.setItem('branchId', 'b-uuid')
    mocks.get.mockResolvedValue({ data: [activeReservation] })
    mocks.post.mockResolvedValue({ data: activeReservation })
    mocks.reservationList.mockResolvedValue([activeReservation])
    mocks.reservationGetById.mockResolvedValue({
      ...activeReservation,
      notes: 'Backend részlet megjegyzés',
    })
    mocks.reservationCreate.mockResolvedValue(activeReservation)
    mocks.reservationCancel.mockResolvedValue(activeReservation)
    mocks.reservationCancelByCompany.mockResolvedValue(activeReservation)
    mocks.reservationFulfill.mockResolvedValue(activeReservation)
    mocks.reservationReceipt.mockResolvedValue(new Blob(['pdf'], { type: 'application/pdf' }))
    mocks.reservationReservedStock.mockResolvedValue(reservedStock)
  })

  it('az aktív fül a reservationsApi.list({ branchId }) és reservedStock(branchId) backend wrapperre köt', async () => {
    render(
      <MemoryRouter>
        <ReservationPage />
      </MemoryRouter>
    )
    await waitFor(() => {
      expect(mocks.reservationList).toHaveBeenCalledWith({ branchId: 'b-uuid' })
      expect(mocks.reservationReservedStock).toHaveBeenCalledWith('b-uuid')
    })
    // A foglaló sora megjelenik (valutakód nem fordított érték)
    expect(await screen.findByText('B000042')).toBeInTheDocument()
    expect(screen.getAllByText(/EUR/).length).toBeGreaterThan(0)
    expect(screen.getByLabelText('Foglalt készlet összesítő')).toBeInTheDocument()
    expect(screen.getByText('1500')).toBeInTheDocument()
  })

  it('nem hív nem létező /branch/.../active vagy /confirm végpontot', async () => {
    render(
      <MemoryRouter>
        <ReservationPage />
      </MemoryRouter>
    )
    await waitFor(() => expect(mocks.reservationList).toHaveBeenCalled())
    const getUrls = mocks.get.mock.calls.map((c) => String(c[0]))
    expect(getUrls.some((u) => u.includes('/branch/'))).toBe(false)
    expect(getUrls.some((u) => u.includes('/today'))).toBe(false)
    // a megszűnt /confirm végpontot sem GET, sem POST úton nem hívjuk
    const postUrls = mocks.post.mock.calls.map((c) => String(c[0]))
    expect([...getUrls, ...postUrls].some((u) => u.includes('/confirm'))).toBe(false)
  })

  it('a részletek gomb a reservationsApi.getById backend wrapperből tölti a kiválasztott foglalót', async () => {
    render(
      <MemoryRouter>
        <ReservationPage />
      </MemoryRouter>
    )

    expect(await screen.findByText('B000042')).toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: 'Részletek' }))

    await waitFor(() => expect(mocks.reservationGetById).toHaveBeenCalledWith('42'))
    expect(screen.getByTestId('reservation-detail-panel')).toHaveTextContent('Backend részlet megjegyzés')
  })
})
