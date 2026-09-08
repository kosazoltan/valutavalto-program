import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import RetroactiveClosingListPage from './RetroactiveClosingListPage'

/**
 * FKH-056: the oldest FALSE_CLOSED row gets a simplified-close button
 * (data-testid open-day-simplified-{date}); clicking opens a local confirm
 * dialog (simplified-confirm-dialog); cancel makes NO API call; confirm calls
 * retroactiveClosingApi.simplifiedClose and reloads the list (the row leaves
 * the FALSE_CLOSED fingerprint server-side, so it disappears). Non-oldest
 * FALSE_CLOSED rows render the button DISABLED (never hidden); OPEN rows never
 * render a simplified button.
 */

const mocks = vi.hoisted(() => ({
  listOpenDays: vi.fn(),
  inspect: vi.fn(),
  reopen: vi.fn(),
  simplifiedClose: vi.fn(),
}))

vi.mock('../../services/api/settings', () => ({
  retroactiveClosingApi: {
    listOpenDays: mocks.listOpenDays,
    inspect: mocks.inspect,
    reopen: mocks.reopen,
    simplifiedClose: mocks.simplifiedClose,
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
        <Route path="/closing/retroactive/:date" element={<div>flow</div>} />
      </Routes>
    </MemoryRouter>,
  )
}

describe('RetroactiveClosingListPage — FKH-056 (simplified close)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.listOpenDays.mockResolvedValue([])
  })

  it('the oldest FALSE_CLOSED row renders the simplified-close button', async () => {
    mocks.listOpenDays.mockResolvedValue([{ date: '2026-08-29', kind: 'FALSE_CLOSED' }])
    renderListPage()

    expect(await screen.findByTestId('open-day-row-2026-08-29')).toBeInTheDocument()
    expect(screen.getByTestId('open-day-simplified-2026-08-29')).toBeEnabled()
  })

  it('clicking the simplified button opens the confirm dialog', async () => {
    mocks.listOpenDays.mockResolvedValue([{ date: '2026-08-29', kind: 'FALSE_CLOSED' }])
    const user = userEvent.setup()
    renderListPage()

    await user.click(await screen.findByTestId('open-day-simplified-2026-08-29'))

    expect(await screen.findByTestId('simplified-confirm-dialog')).toBeInTheDocument()
    expect(mocks.simplifiedClose).not.toHaveBeenCalled()
  })

  it('cancel closes the dialog and makes NO API call', async () => {
    mocks.listOpenDays.mockResolvedValue([{ date: '2026-08-29', kind: 'FALSE_CLOSED' }])
    const user = userEvent.setup()
    renderListPage()

    await user.click(await screen.findByTestId('open-day-simplified-2026-08-29'))
    await user.click(await screen.findByTestId('simplified-confirm-cancel'))

    await waitFor(() =>
      expect(screen.queryByTestId('simplified-confirm-dialog')).toBeNull(),
    )
    expect(mocks.simplifiedClose).not.toHaveBeenCalled()
  })

  it('confirm calls simplifiedClose and the row is gone after reload', async () => {
    mocks.simplifiedClose.mockResolvedValue({ ok: true, sessionDate: '2026-08-29' })
    // First load lists the FALSE_CLOSED day; after the close the reload returns none.
    mocks.listOpenDays
      .mockResolvedValueOnce([{ date: '2026-08-29', kind: 'FALSE_CLOSED' }])
      .mockResolvedValue([])
    const user = userEvent.setup()
    renderListPage()

    await user.click(await screen.findByTestId('open-day-simplified-2026-08-29'))
    await user.click(await screen.findByTestId('simplified-confirm-submit'))

    await waitFor(() => expect(mocks.simplifiedClose).toHaveBeenCalledWith('b1', '2026-08-29'))
    await waitFor(() => expect(screen.queryByTestId('open-day-row-2026-08-29')).toBeNull())
    expect(mocks.listOpenDays).toHaveBeenCalledTimes(2)
  })

  it('a non-oldest FALSE_CLOSED row renders the simplified button DISABLED, not hidden', async () => {
    mocks.listOpenDays.mockResolvedValue([
      { date: '2026-08-29', kind: 'FALSE_CLOSED' },
      { date: '2026-08-30', kind: 'FALSE_CLOSED' },
    ])
    renderListPage()

    expect(await screen.findByTestId('open-day-row-2026-08-30')).toBeInTheDocument()
    expect(screen.getByTestId('open-day-simplified-2026-08-29')).toBeEnabled()
    expect(screen.getByTestId('open-day-simplified-2026-08-30')).toBeDisabled()
  })

  it('an OPEN row renders NO simplified button', async () => {
    mocks.listOpenDays.mockResolvedValue([{ date: '2026-08-29', kind: 'OPEN' }])
    renderListPage()

    expect(await screen.findByTestId('open-day-row-2026-08-29')).toBeInTheDocument()
    expect(screen.queryByTestId('open-day-simplified-2026-08-29')).toBeNull()
    expect(screen.getByTestId('open-day-action-2026-08-29')).toBeEnabled()
  })
})
