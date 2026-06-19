import { render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import ReservationPage from './ReservationPage'

const mocks = vi.hoisted(() => ({
  get: vi.fn(),
  post: vi.fn(),
  reservationList: vi.fn(),
  reservationCreate: vi.fn(),
  reservationCancel: vi.fn(),
  reservationCancelByCompany: vi.fn(),
  reservationFulfill: vi.fn(),
  reservationReceipt: vi.fn(),
  search: vi.fn(),
}))

vi.mock('@/services/api/index', () => ({
  api: { get: mocks.get, post: mocks.post },
  reservationsApi: {
    list: mocks.reservationList,
    create: mocks.reservationCreate,
    cancel: mocks.reservationCancel,
    cancelByCompany: mocks.reservationCancelByCompany,
    fulfill: mocks.reservationFulfill,
    receipt: mocks.reservationReceipt,
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

describe('ReservationPage — backend kontraktus', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.setItem('branchId', 'b-uuid')
    mocks.get.mockResolvedValue({ data: [activeReservation] })
    mocks.post.mockResolvedValue({ data: activeReservation })
    mocks.reservationList.mockResolvedValue([activeReservation])
    mocks.reservationCreate.mockResolvedValue(activeReservation)
    mocks.reservationCancel.mockResolvedValue(activeReservation)
    mocks.reservationCancelByCompany.mockResolvedValue(activeReservation)
    mocks.reservationFulfill.mockResolvedValue(activeReservation)
    mocks.reservationReceipt.mockResolvedValue(new Blob(['pdf'], { type: 'application/pdf' }))
  })

  it('az aktív fül a reservationsApi.list({ branchId }) backend wrapperre köt', async () => {
    render(
      <MemoryRouter>
        <ReservationPage />
      </MemoryRouter>
    )
    await waitFor(() => {
      expect(mocks.reservationList).toHaveBeenCalledWith({ branchId: 'b-uuid' })
    })
    // A foglaló sora megjelenik (valutakód nem fordított érték)
    expect(await screen.findByText('B000042')).toBeInTheDocument()
    expect(screen.getByText(/EUR/)).toBeInTheDocument()
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
})
