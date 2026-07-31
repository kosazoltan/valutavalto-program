import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import ReservationPage from './ReservationPage'

// FKH-027 PR B (RED) — FR-B1..FR-B3: a handleCancelByCustomer a natív prompt() helyett
// a közös TextReasonModal-lal kéri be a lemondás okát, változatlan title-lel és
// változatlan reservationsApi.cancel(id, reason.trim()) hívással.

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

describe('ReservationPage — FR-B1..B3: ügyfél-lemondás oka a TextReasonModal-lal', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
    localStorage.setItem('branchId', 'b-uuid')
    mocks.get.mockResolvedValue({ data: [] })
    mocks.reservationList.mockResolvedValue([activeReservation])
    mocks.reservationReservedStock.mockResolvedValue([])
    mocks.reservationCancel.mockResolvedValue({
      ...activeReservation,
      status: 'CANCELLED_BY_CUSTOMER',
    })
    // A natív promptot lecseréljük, hogy assertálható legyen: az új folyamat NEM hívja
    vi.spyOn(window, 'prompt').mockReturnValue(null)
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  async function openCancelModal(user: ReturnType<typeof userEvent.setup>) {
    render(
      <MemoryRouter>
        <ReservationPage />
      </MemoryRouter>,
    )
    await user.click(await screen.findByRole('button', { name: 'Ügyfél lemondás' }))
    const dialog = await screen.findByRole('alertdialog')
    // FR-B1: a title szó szerint az eddigi prompt-szöveg
    expect(dialog).toHaveAccessibleName('Lemondás oka (ügyfél miatt — a letét nem jár vissza):')
    expect(window.prompt).not.toHaveBeenCalled()
    return dialog
  }

  it('FR-B3 string-ág: a megadott okkal pontosan egyszer hívódik a reservationsApi.cancel', async () => {
    const user = userEvent.setup()
    const dialog = await openCancelModal(user)
    await user.type(within(dialog).getByRole('textbox'), 'Ügyfél elállt a vételtől')
    await user.click(within(dialog).getByRole('button', { name: 'OK' }))
    await waitFor(() =>
      expect(mocks.reservationCancel).toHaveBeenCalledWith(42, 'Ügyfél elállt a vételtől'),
    )
    expect(mocks.reservationCancel).toHaveBeenCalledTimes(1)
    await waitFor(() => expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument())
    expect(window.prompt).not.toHaveBeenCalled()
  })

  it('FR-B3 argumentum-változatlanság: a reason továbbra is trimmelve megy a backendnek', async () => {
    const user = userEvent.setup()
    const dialog = await openCancelModal(user)
    await user.type(within(dialog).getByRole('textbox'), '  Ügyfél elállt  ')
    await user.click(within(dialog).getByRole('button', { name: 'OK' }))
    await waitFor(() => expect(mocks.reservationCancel).toHaveBeenCalledWith(42, 'Ügyfél elállt'))
  })

  it('FR-B2 null-ág: Mégse után nem hívódik a reservationsApi.cancel', async () => {
    const user = userEvent.setup()
    const dialog = await openCancelModal(user)
    await user.click(within(dialog).getByRole('button', { name: 'Mégse' }))
    await waitFor(() => expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument())
    expect(mocks.reservationCancel).not.toHaveBeenCalled()
    expect(window.prompt).not.toHaveBeenCalled()
  })

  it('üres string: a hívó-oldali validáció megmarad — üres okkal nincs API-hívás', async () => {
    const user = userEvent.setup()
    const dialog = await openCancelModal(user)
    await user.click(within(dialog).getByRole('button', { name: 'OK' }))
    await waitFor(() => expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument())
    expect(mocks.reservationCancel).not.toHaveBeenCalled()
  })

  it('csak whitespace: a !reason.trim() őrfeltétel megmarad — nincs API-hívás', async () => {
    const user = userEvent.setup()
    const dialog = await openCancelModal(user)
    await user.type(within(dialog).getByRole('textbox'), '   ')
    await user.click(within(dialog).getByRole('button', { name: 'OK' }))
    await waitFor(() => expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument())
    expect(mocks.reservationCancel).not.toHaveBeenCalled()
  })
})
