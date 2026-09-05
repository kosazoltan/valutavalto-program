import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import RetroactiveClosingListPage from './RetroactiveClosingListPage'

/**
 * FKH-051 (Test plan 13-16): plain ISO date input inspects a typed past date and
 * routes by the server kind enum (plan D4): OPEN -> start the existing FKH-050
 * flow; FALSE_CLOSED -> warning + reprocess confirm (reopen, then navigate);
 * other kinds -> render the server message, never navigate. List rows carrying
 * kind FALSE_CLOSED render the reprocess action instead of the start action.
 */

const mocks = vi.hoisted(() => ({
  listOpenDays: vi.fn(),
  inspect: vi.fn(),
  reopen: vi.fn(),
}))

vi.mock('../../services/api/settings', () => ({
  retroactiveClosingApi: {
    listOpenDays: mocks.listOpenDays,
    inspect: mocks.inspect,
    reopen: mocks.reopen,
  },
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (s: unknown) => unknown) =>
    selector({
      worker: { id: 1, fullName: 'Teszt Felhasználó', role: 'CASHIER', branchId: 'b1' },
      activeRole: 'CASHIER',
      roles: ['CASHIER'],
      hasCanonicalRole: () => true,
    }),
}))

function renderListPage() {
  return render(
    <MemoryRouter initialEntries={['/closing/retroactive']}>
      <Routes>
        <Route path="/closing/retroactive" element={<RetroactiveClosingListPage />} />
        <Route path="/closing/retroactive/:date" element={<div>retroactive-flow-page</div>} />
      </Routes>
    </MemoryRouter>,
  )
}

describe('RetroactiveClosingListPage — FKH-051 (date input + inspect)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.listOpenDays.mockResolvedValue([])
  })

  it('T13: OPEN inspection navigates to the existing FKH-050 :date flow', async () => {
    mocks.inspect.mockResolvedValue({
      date: '2026-08-31',
      kind: 'OPEN',
      canStart: true,
      canReprocess: false,
      message: 'A nap nyitott.',
    })
    const user = userEvent.setup()
    renderListPage()

    const input = await screen.findByTestId('retroactive-date-input')
    await user.type(input, '2026-08-31')
    await user.click(screen.getByTestId('retroactive-date-submit'))

    await waitFor(() => expect(mocks.inspect).toHaveBeenCalledWith('b1', '2026-08-31'))
    expect(await screen.findByText('retroactive-flow-page')).toBeInTheDocument()
  })

  it('T14: FALSE_CLOSED shows warning + reprocess confirm; confirm calls reopen then navigates', async () => {
    mocks.inspect.mockResolvedValue({
      date: '2026-08-31',
      kind: 'FALSE_CLOSED',
      canStart: false,
      canReprocess: true,
      message: 'A nap tévesen lett lezárva, újranyitás szükséges.',
    })
    mocks.reopen.mockResolvedValue({ ok: true, sessionDate: '2026-08-31' })
    const user = userEvent.setup()
    renderListPage()

    await user.type(await screen.findByTestId('retroactive-date-input'), '2026-08-31')
    await user.click(screen.getByTestId('retroactive-date-submit'))

    expect(await screen.findByTestId('retroactive-false-closed-warning')).toBeInTheDocument()
    await user.click(screen.getByTestId('retroactive-reprocess-confirm'))

    await waitFor(() => expect(mocks.reopen).toHaveBeenCalledWith('b1', '2026-08-31'))
    expect(await screen.findByText('retroactive-flow-page')).toBeInTheDocument()
  })

  it('T15: GENUINE_CLOSED and NO_SESSION render the server message and do NOT navigate', async () => {
    const user = userEvent.setup()
    mocks.inspect.mockResolvedValue({
      date: '2026-08-31',
      kind: 'GENUINE_CLOSED',
      canStart: false,
      canReprocess: false,
      message: 'Ez a nap szabályosan le van zárva.',
    })
    renderListPage()

    await user.type(await screen.findByTestId('retroactive-date-input'), '2026-08-31')
    await user.click(screen.getByTestId('retroactive-date-submit'))

    expect(await screen.findByTestId('retroactive-date-error')).toHaveTextContent(
      'Ez a nap szabályosan le van zárva.',
    )
    expect(screen.queryByText('retroactive-flow-page')).toBeNull()

    mocks.inspect.mockResolvedValue({
      date: '2026-08-30',
      kind: 'NO_SESSION',
      canStart: false,
      canReprocess: false,
      message: 'Nincs napi munkamenet erre a napra.',
    })
    await user.clear(screen.getByTestId('retroactive-date-input'))
    await user.type(screen.getByTestId('retroactive-date-input'), '2026-08-30')
    await user.click(screen.getByTestId('retroactive-date-submit'))

    expect(await screen.findByTestId('retroactive-date-error')).toHaveTextContent(
      'Nincs napi munkamenet erre a napra.',
    )
    expect(screen.queryByText('retroactive-flow-page')).toBeNull()
  })

  it('T16: a list row with kind FALSE_CLOSED renders the reprocess action', async () => {
    mocks.listOpenDays.mockResolvedValue([
      { date: '2026-09-02', kind: 'FALSE_CLOSED' },
    ])

    renderListPage()

    expect(await screen.findByTestId('open-day-row-2026-09-02')).toBeInTheDocument()
    expect(screen.getByTestId('open-day-reprocess-2026-09-02')).toBeEnabled()
    expect(screen.queryByTestId('open-day-action-2026-09-02')).toBeNull()
  })
})
