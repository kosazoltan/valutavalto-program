import { render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import ReservationPage from './ReservationPage'

const mocks = vi.hoisted(() => ({
  get: vi.fn(),
  post: vi.fn(),
  search: vi.fn(),
}))

vi.mock('@/services/api/index', () => ({
  api: { get: mocks.get, post: mocks.post },
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
  })

  it('az aktív fül a GET /reservations/active?branchId=... végpontot hívja', async () => {
    render(
      <MemoryRouter>
        <ReservationPage />
      </MemoryRouter>
    )
    await waitFor(() => {
      expect(mocks.get).toHaveBeenCalledWith('/reservations/active', {
        params: { branchId: 'b-uuid' },
      })
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
    await waitFor(() => expect(mocks.get).toHaveBeenCalled())
    const calledUrls = mocks.get.mock.calls.map((c) => String(c[0]))
    expect(calledUrls.some((u) => u.includes('/branch/'))).toBe(false)
    expect(calledUrls.some((u) => u.includes('/today'))).toBe(false)
  })
})
