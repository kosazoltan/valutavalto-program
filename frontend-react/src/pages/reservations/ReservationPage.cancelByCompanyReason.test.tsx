import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import ReservationPage from './ReservationPage'

// FKH-027 PR B (RED) — FR-B4..FR-B5: a handleCancelByCompany a natív prompt() helyett
// a közös TextReasonModal-lal kéri be a lemondás okát. A supervisor-azonosító
// feloldása és a jóváhagyási logika EBBEN A KÖRBEN NEM változik — a teszt ezt
// változatlan localStorage('workerId') mockkal pinneli.

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

describe('ReservationPage — FR-B4..B5: EBC-lemondás oka a TextReasonModal-lal', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
    localStorage.setItem('branchId', 'b-uuid')
    // supervisor-mock: változatlan út (localStorage workerId), a kör NEM nyúl hozzá
    localStorage.setItem('workerId', '99')
    mocks.get.mockResolvedValue({ data: [] })
    mocks.reservationList.mockResolvedValue([activeReservation])
    mocks.reservationReservedStock.mockResolvedValue([])
    mocks.reservationCancelByCompany.mockResolvedValue({
      ...activeReservation,
      status: 'CANCELLED_BY_COMPANY',
    })
    vi.spyOn(window, 'prompt').mockReturnValue(null)
    vi.spyOn(window, 'alert').mockImplementation(() => {})
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
    await user.click(await screen.findByRole('button', { name: 'EBC lemondás' }))
    const dialog = await screen.findByRole('alertdialog')
    // FR-B4: a title szó szerint az eddigi prompt-szöveg
    expect(dialog).toHaveAccessibleName(
      'Lemondás oka (EBC miatt — dupla letét-visszafizetés, supervisor jóváhagyás):',
    )
    expect(window.prompt).not.toHaveBeenCalled()
    return dialog
  }

  it('FR-B5 string-ág: változatlan payload-dal hívódik a reservationsApi.cancelByCompany', async () => {
    const user = userEvent.setup()
    const dialog = await openCancelModal(user)
    await user.type(within(dialog).getByRole('textbox'), 'Árfolyamhiba az EBC oldalán')
    await user.click(within(dialog).getByRole('button', { name: 'OK' }))
    await waitFor(() =>
      expect(mocks.reservationCancelByCompany).toHaveBeenCalledWith(42, {
        reason: 'Árfolyamhiba az EBC oldalán',
        supervisorWorkerId: 99,
      }),
    )
    expect(mocks.reservationCancelByCompany).toHaveBeenCalledTimes(1)
    expect(window.alert).not.toHaveBeenCalled()
    await waitFor(() => expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument())
    expect(window.prompt).not.toHaveBeenCalled()
  })

  it('FR-B5 null-ág: Mégse után nem hívódik a reservationsApi.cancelByCompany', async () => {
    const user = userEvent.setup()
    const dialog = await openCancelModal(user)
    await user.click(within(dialog).getByRole('button', { name: 'Mégse' }))
    await waitFor(() => expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument())
    expect(mocks.reservationCancelByCompany).not.toHaveBeenCalled()
    expect(window.prompt).not.toHaveBeenCalled()
  })

  it('üres string: a hívó-oldali validáció megmarad — üres okkal nincs API-hívás', async () => {
    const user = userEvent.setup()
    const dialog = await openCancelModal(user)
    await user.click(within(dialog).getByRole('button', { name: 'OK' }))
    await waitFor(() => expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument())
    expect(mocks.reservationCancelByCompany).not.toHaveBeenCalled()
  })

  it('supervisor-logika változatlan: hiányzó workerId-nél alert és nincs API-hívás', async () => {
    localStorage.removeItem('workerId')
    const user = userEvent.setup()
    const dialog = await openCancelModal(user)
    await user.type(within(dialog).getByRole('textbox'), 'Árfolyamhiba az EBC oldalán')
    await user.click(within(dialog).getByRole('button', { name: 'OK' }))
    await waitFor(() =>
      expect(window.alert).toHaveBeenCalledWith(
        'Hiányzó supervisor azonosító — jelentkezzen be újra a jóváhagyáshoz.',
      ),
    )
    expect(mocks.reservationCancelByCompany).not.toHaveBeenCalled()
  })
})
