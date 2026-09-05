import { render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import RetroactiveClosingListPage from './RetroactiveClosingListPage'

/**
 * FKH-050 (FR-1/D3): the retroactive closing entry point lists the caller's own
 * open past days oldest-first, and ONLY the oldest day is actionable (the
 * opening-balance chain requires chronological closing).
 */

const mocks = vi.hoisted(() => ({
  listOpenDays: vi.fn(),
}))

vi.mock('../../services/api/settings', () => ({
  retroactiveClosingApi: {
    listOpenDays: mocks.listOpenDays,
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

describe('RetroactiveClosingListPage — FKH-050 (FR-1)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('FR-1/D3: lists open past days oldest first and only the oldest is actionable', async () => {
    mocks.listOpenDays.mockResolvedValue([
      { date: '2026-08-29', sessionDate: '2026-08-29', status: 'OPEN' },
      { date: '2026-08-31', sessionDate: '2026-08-31', status: 'OPEN' },
    ])

    renderListPage()

    // Both days are listed, oldest first.
    const older = await screen.findByTestId('open-day-row-2026-08-29')
    const newer = await screen.findByTestId('open-day-row-2026-08-31')
    const position = older.compareDocumentPosition(newer)
    expect(position & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy()

    // Only the oldest row is actionable.
    expect(screen.getByTestId('open-day-action-2026-08-29')).toBeEnabled()
    expect(screen.getByTestId('open-day-action-2026-08-31')).toBeDisabled()
  })

  it('FR-1: empty state when there is no open past day', async () => {
    mocks.listOpenDays.mockResolvedValue([])

    renderListPage()

    expect(await screen.findByTestId('retroactive-empty-state')).toBeInTheDocument()
    expect(screen.queryByTestId(/open-day-row/)).toBeNull()
  })
})
