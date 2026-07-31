import { act, render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import CashDeskBreakPage from './CashDeskBreakPage'

// FKH-027 PR C (RED) — FR-C5..FR-C7: a handleStartBreak KÉT egymást követő natív
// prompt()-ja helyett a közös TextReasonModal-t használja, SOROS await-tel.
//
// Forrásból igazolt viselkedés (CashDeskBreakPage.tsx:59-75):
//   const breakType = prompt('Szünet típusa (pl: LUNCH, BREAK):')
//   if (!breakType) return
//   const reason = prompt('Ok (opcionális):') || undefined
//   await cashDeskBreakApi.start(selectedCashDeskId, breakType, reason)
//
// - FR-C5: az őr `!breakType`, tehát a null ÉS az üres string EGYARÁNT teljes
//   megszakítás — a második kérdésig el sem jut a művelet.
// - FR-C7: a második érték `prompt() || undefined`, tehát az üres string az
//   "ok nélkül" ágba esik, pontosan ugyanúgy, mint a null → start(id, type, undefined).
// - FR-C6: a hook egyszerre egy aktív kérést kezel, ezért a két kérdés csak sorosan
//   (az első teljesülése után indul a második) valósítható meg.

const mocks = vi.hoisted(() => ({
  cashDeskList: vi.fn(),
  breakList: vi.fn(),
  getActive: vi.fn(),
  start: vi.fn(),
  end: vi.fn(),
  toast: {
    success: vi.fn(),
    error: vi.fn(),
    warning: vi.fn(),
  },
  loggerError: vi.fn(),
}))

vi.mock('../../services/api/index', () => ({
  cashDeskApi: {
    list: mocks.cashDeskList,
  },
  cashDeskBreakApi: {
    list: mocks.breakList,
    getActive: mocks.getActive,
    start: mocks.start,
    end: mocks.end,
  },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: mocks.toast,
}))

vi.mock('../../utils/logger', () => ({
  logger: {
    error: mocks.loggerError,
  },
}))

const TYPE_TITLE = 'Szünet típusa (pl: LUNCH, BREAK):'
const REASON_TITLE = 'Ok (opcionális):'

/** Kirendereli az oldalt aktív szünet nélkül, és megnyitja az ELSŐ (típus) modált. */
async function openTypeModal(user: ReturnType<typeof userEvent.setup>) {
  render(<CashDeskBreakPage />)
  await user.click(await screen.findByRole('button', { name: 'Szünet indítása' }))
  const dialog = await screen.findByRole('alertdialog')
  // FR-C6: az első kérdés címe szó szerint az eddigi prompt-szöveg
  expect(dialog).toHaveAccessibleName(TYPE_TITLE)
  expect(window.prompt).not.toHaveBeenCalled()
  return dialog
}

/** Lezárja az aktuális modált, majd megvárja a második (ok) modál megjelenését. */
async function submitTypeAndAwaitReasonModal(
  user: ReturnType<typeof userEvent.setup>,
  typeDialog: HTMLElement,
  breakType: string,
) {
  await user.type(within(typeDialog).getByRole('textbox'), breakType)
  await user.click(within(typeDialog).getByRole('button', { name: 'OK' }))

  // FR-C6: a második kérdés csak az első teljesülése UTÁN jelenik meg,
  // és egyszerre mindig pontosan egy modal van a DOM-ban.
  const reasonDialog = await screen.findByRole('alertdialog', { name: REASON_TITLE })
  expect(screen.getAllByRole('alertdialog')).toHaveLength(1)
  expect(mocks.start).not.toHaveBeenCalled()
  return reasonDialog
}

/** Megvárja a modal eltűnését, majd egy extra tick után újra ellenőrzi: nem nyílt új modal. */
async function expectNoFurtherModal() {
  await waitFor(() => expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument())
  await act(async () => {
    await Promise.resolve()
  })
  expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument()
}

describe('CashDeskBreakPage — FR-C5..C7: szünetindítás két lépcsős TextReasonModal-lal', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.cashDeskList.mockResolvedValue([
      { id: 'cashdesk-1', name: 'Szeged pénztár', isActive: true },
    ])
    mocks.breakList.mockResolvedValue([])
    // aktív szünet nélkül renderelődik a "Szünet indítása" gomb
    mocks.getActive.mockResolvedValue(null)
    mocks.start.mockResolvedValue({
      id: 'break-2',
      cashDeskId: 'cashdesk-1',
      breakStart: '2026-07-31T10:00:00',
      breakType: 'LUNCH',
      isActive: true,
    })
    vi.spyOn(window, 'prompt').mockReturnValue(null)
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('FR-C5 típus=null: Mégse után a művelet teljesen megszakad — nincs második kérdés, nincs start', async () => {
    const user = userEvent.setup()
    const dialog = await openTypeModal(user)

    await user.click(within(dialog).getByRole('button', { name: 'Mégse' }))

    await expectNoFurtherModal()
    expect(mocks.start).not.toHaveBeenCalled()
    expect(window.prompt).not.toHaveBeenCalled()
  })

  it('FR-C5 típus=üres string: a kötelező mező őre (`!breakType`) fog — nincs második kérdés, nincs start', async () => {
    const user = userEvent.setup()
    const dialog = await openTypeModal(user)

    await user.click(within(dialog).getByRole('button', { name: 'OK' }))

    await expectNoFurtherModal()
    expect(mocks.start).not.toHaveBeenCalled()
    expect(window.prompt).not.toHaveBeenCalled()
  })

  it('FR-C6/C7 típus=van, ok=string: a start a megadott okkal hívódik', async () => {
    const user = userEvent.setup()
    const typeDialog = await openTypeModal(user)
    const reasonDialog = await submitTypeAndAwaitReasonModal(user, typeDialog, 'LUNCH')

    await user.type(within(reasonDialog).getByRole('textbox'), 'Ebédszünet')
    await user.click(within(reasonDialog).getByRole('button', { name: 'OK' }))

    await waitFor(() =>
      expect(mocks.start).toHaveBeenCalledWith('cashdesk-1', 'LUNCH', 'Ebédszünet'),
    )
    expect(mocks.start).toHaveBeenCalledTimes(1)
    await expectNoFurtherModal()
    expect(window.prompt).not.toHaveBeenCalled()
  })

  it('FR-C6/C7 típus=van, ok=null: az opcionális kérdés Mégse-je NEM szakítja meg — start ok nélkül indul', async () => {
    const user = userEvent.setup()
    const typeDialog = await openTypeModal(user)
    const reasonDialog = await submitTypeAndAwaitReasonModal(user, typeDialog, 'BREAK')

    await user.click(within(reasonDialog).getByRole('button', { name: 'Mégse' }))

    await waitFor(() => expect(mocks.start).toHaveBeenCalledWith('cashdesk-1', 'BREAK', undefined))
    expect(mocks.start).toHaveBeenCalledTimes(1)
    await expectNoFurtherModal()
    expect(window.prompt).not.toHaveBeenCalled()
  })

  it('FR-C7 típus=van, ok=üres string: a `|| undefined` miatt az "ok nélkül" ágba esik', async () => {
    const user = userEvent.setup()
    const typeDialog = await openTypeModal(user)
    const reasonDialog = await submitTypeAndAwaitReasonModal(user, typeDialog, 'BREAK')

    await user.click(within(reasonDialog).getByRole('button', { name: 'OK' }))

    await waitFor(() => expect(mocks.start).toHaveBeenCalledWith('cashdesk-1', 'BREAK', undefined))
    expect(mocks.start).toHaveBeenCalledTimes(1)
    await expectNoFurtherModal()
    expect(window.prompt).not.toHaveBeenCalled()
  })

  it('FR-C6 sorrend: a két kérdés sorosan, egymás után jelenik meg (soha nem egyszerre)', async () => {
    const user = userEvent.setup()
    const typeDialog = await openTypeModal(user)
    // az első kérdés alatt még csak egy modal van, és a start még nem indult el
    expect(screen.getAllByRole('alertdialog')).toHaveLength(1)
    expect(mocks.start).not.toHaveBeenCalled()

    const reasonDialog = await submitTypeAndAwaitReasonModal(user, typeDialog, 'LUNCH')
    // a második kérdés megjelenésekor a típus-kérdés már nem látszik
    expect(screen.queryByRole('alertdialog', { name: TYPE_TITLE })).not.toBeInTheDocument()

    await user.click(within(reasonDialog).getByRole('button', { name: 'OK' }))
    await waitFor(() => expect(mocks.start).toHaveBeenCalledTimes(1))
    expect(window.prompt).not.toHaveBeenCalled()
  })
})
