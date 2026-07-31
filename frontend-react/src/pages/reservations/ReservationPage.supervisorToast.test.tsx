import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import ReservationPage from './ReservationPage'

// B-csoport (RED) — FR-T8: a natív window.alert() kiváltása a közös toast-tal
// (components/ui/toaster) a hiányzó supervisor-azonosító ágon.
//
// Variáns: toast.warning — a művelet ELUTASÍTVA (nem rendszerhiba, nem kivétel),
// és a szöveg konkrét teendőt ad a felhasználónak. Precedens ugyanerre a mintára:
// ReceiptPrint.tsx:101 `toast.warning('Nyomtatás sikertelen', 'Engedélyezze ...')`.
//
// Szöveg-szerződés (Tomi jóváhagyása, 2026-07-31): a mai szövegben VAN natural
// elválasztó — 'Hiányzó supervisor azonosító — jelentkezzen be újra a jóváhagyáshoz.' —,
// a gondolatjel egy állapot-címet és egy teendő-mondatot választ el. Ezért cím/részlet
// bontás, ugyanúgy, mint a catch-ágaknál. Egyetlen karakter-szintű eltérés: a részlet
// önálló mondatként nagy kezdőbetűt kap ('Jelentkezzen'), a ReceiptPrint.tsx:101
// precedens stílusával egyezően. Más szó nem változik.
//
// FIGYELEM (tudatos, jóváhagyott spec-bővülés): a meglévő
// ReservationPage.cancelByCompanyReason.test.tsx teszt eddig a `window.alert`
// hívását pinnelte ugyanezen az ágon; az az assert EBBEN a körben át lett írva
// toast.warning-ra (nem törlés, nem gyengítés — dokumentált spec-változás).
//
// A kör KIZÁRÓLAG az alert()-hívást cseréli: a `requestReason()` (TextReasonModal),
// a reason-guard és a supervisorWorkerId feloldása VÁLTOZATLAN.

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
  toast: {
    success: vi.fn(),
    error: vi.fn(),
    warning: vi.fn(),
    info: vi.fn(),
    dismiss: vi.fn(),
  },
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

vi.mock('../../components/ui/toaster', () => ({
  toast: mocks.toast,
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

// A mai alert-szöveg bontása: cím (a gondolatjel előtti állapot) + teendő-mondat.
const MISSING_SUPERVISOR_TITLE = 'Hiányzó supervisor azonosító'
const MISSING_SUPERVISOR_DETAIL = 'Jelentkezzen be újra a jóváhagyáshoz.'

describe('ReservationPage — FR-T8: a natív alert() helyett toast', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
    localStorage.setItem('branchId', 'b-uuid')
    mocks.get.mockResolvedValue({ data: [] })
    mocks.reservationList.mockResolvedValue([activeReservation])
    mocks.reservationReservedStock.mockResolvedValue([])
    mocks.reservationCancelByCompany.mockResolvedValue({
      ...activeReservation,
      status: 'CANCELLED_BY_COMPANY',
    })
    vi.spyOn(window, 'alert').mockImplementation(() => {})
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
    await user.click(await screen.findByRole('button', { name: 'EBC lemondás' }))
    const dialog = await screen.findByRole('alertdialog')
    // FKH-027 marad: az ok a TextReasonModal-ból jön, nem natív prompt()-ból.
    expect(dialog).toHaveAccessibleName(
      'Lemondás oka (EBC miatt — dupla letét-visszafizetés, supervisor jóváhagyás):',
    )
    expect(window.prompt).not.toHaveBeenCalled()
    return dialog
  }

  it('FR-T8 (ReservationPage.tsx:200) — hiányzó supervisor-azonosítónál toast.warning, natív alert nélkül', async () => {
    // Nincs workerId a localStorage-ban → a supervisor-guard fog megszólalni.
    const user = userEvent.setup()
    const dialog = await openCancelModal(user)
    await user.type(within(dialog).getByRole('textbox'), 'Árfolyamhiba az EBC oldalán')
    await user.click(within(dialog).getByRole('button', { name: 'OK' }))

    await waitFor(() =>
      expect(mocks.toast.warning).toHaveBeenCalledWith(
        MISSING_SUPERVISOR_TITLE,
        MISSING_SUPERVISOR_DETAIL,
      ),
    )
    expect(mocks.toast.warning).toHaveBeenCalledTimes(1)
    expect(window.alert).not.toHaveBeenCalled()
    // A guard változatlan: a művelet megszakad, nincs API-hívás.
    expect(mocks.reservationCancelByCompany).not.toHaveBeenCalled()
  })

  it('meglévő supervisor-azonosítónál semmilyen toast nem fut, a payload változatlan', async () => {
    localStorage.setItem('workerId', '99')
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
    expect(mocks.toast.warning).not.toHaveBeenCalled()
    expect(window.alert).not.toHaveBeenCalled()
  })

  it('guard-sorrend változatlan: Mégse után se toast, se API-hívás (a reason-guard előbb fut)', async () => {
    const user = userEvent.setup()
    const dialog = await openCancelModal(user)
    await user.click(within(dialog).getByRole('button', { name: 'Mégse' }))

    await waitFor(() => expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument())
    expect(mocks.toast.warning).not.toHaveBeenCalled()
    expect(window.alert).not.toHaveBeenCalled()
    expect(mocks.reservationCancelByCompany).not.toHaveBeenCalled()
  })
})
