import { render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import RetroactiveClosingPage from './RetroactiveClosingPage'

/**
 * FKH-050: user-initiated simplified retroactive closing flow (3 steps).
 *
 * FR-4: prominent amber "UTÓLAGOS ZÁRÁS - <date>" banner on every screen.
 * FR-3: the flow has fewer than nine steps (exactly 3).
 * FR-5: reconciliation table shows expected from the PAST day's daily_balance.
 * FR-6: the close button stays disabled while any currency row is blocking.
 */

const mocks = vi.hoisted(() => ({
  reconcile: vi.fn(),
  close: vi.fn(),
  listOpenDays: vi.fn(),
}))

vi.mock('../../services/api/settings', () => ({
  retroactiveClosingApi: {
    listOpenDays: mocks.listOpenDays,
    reconcile: mocks.reconcile,
    close: mocks.close,
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

function reconciliationPayload(overrides: { anyBlocking?: boolean } = {}) {
  return {
    date: '2026-08-31',
    rows: [
      {
        currencyCode: 'HUF',
        expected: 100000,
        actual: 100000,
        difference: 0,
        blocking: false,
      },
    ],
    anyBlocking: overrides.anyBlocking ?? false,
  }
}

function renderPage(date = '2026-08-31') {
  return render(
    <MemoryRouter initialEntries={[`/closing/retroactive/${date}`]}>
      <Routes>
        <Route path="/closing/retroactive/:date" element={<RetroactiveClosingPage />} />
      </Routes>
    </MemoryRouter>,
  )
}

describe('RetroactiveClosingPage — FKH-050', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.reconcile.mockResolvedValue(reconciliationPayload())
    mocks.close.mockResolvedValue({ ok: true })
  })

  it('FR-4: the banner shows "UTÓLAGOS ZÁRÁS - <date>" with the amber styling', async () => {
    renderPage()

    const banner = await screen.findByTestId('retroactive-closing-banner')
    expect(banner).toHaveTextContent('UTÓLAGOS ZÁRÁS - 2026-08-31')
    // Distinct amber look, not the default page chrome.
    expect(banner.className).toContain('bg-amber-100')
    expect(banner.className).toContain('border-amber-500')
  })

  it('FR-3: the retroactive flow has fewer than nine steps (exactly 3)', async () => {
    renderPage()

    await screen.findByTestId('retroactive-closing-banner')
    const steps = await screen.findAllByTestId('retroactive-step')
    expect(steps.length).toBe(3)
    expect(steps.length).toBeLessThan(9)
  })

  it('FR-5: the reconciliation table renders expected/actual/difference from the API', async () => {
    mocks.reconcile.mockResolvedValue(
      reconciliationPayload({ anyBlocking: false }),
    )

    renderPage()

    expect(await screen.findByText('HUF')).toBeInTheDocument()
    // Expected from the past day's daily_balance closing balance.
    expect(screen.getByTestId('retroactive-expected-HUF')).toHaveTextContent('100000')
    expect(screen.getByTestId('retroactive-actual-HUF')).toHaveTextContent('100000')
    expect(screen.getByTestId('retroactive-difference-HUF')).toHaveTextContent('0')
    expect(mocks.reconcile).toHaveBeenCalledWith('b1', '2026-08-31')
  })

  it('FR-6: the close button is disabled while any row is blocking', async () => {
    mocks.reconcile.mockResolvedValue(
      reconciliationPayload({ anyBlocking: true }),
    )

    renderPage()

    const closeButton = await screen.findByTestId('retroactive-close-button')
    expect(closeButton).toBeDisabled()

    // Non-blocking reconciliation enables the close button.
    mocks.reconcile.mockResolvedValue(reconciliationPayload({ anyBlocking: false }))
    renderPage()
    const enabledClose = await screen.findAllByTestId('retroactive-close-button')
    expect(enabledClose[enabledClose.length - 1]).toBeEnabled()
  })
})
