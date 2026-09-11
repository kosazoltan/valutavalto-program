import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import ReceivedDataOverviewPage from './ReceivedDataOverviewPage'
import hu from '../../i18n/hu.json'

const mockRun = vi.fn()

vi.mock('../../services/api', () => ({
  transferReconciliationApi: {
    run: (...args: unknown[]) => mockRun(...args),
  },
}))

vi.mock('./ReceivedDenominationsView', () => ({
  default: () => <div data-testid="denominations-view-stub" />,
}))

/**
 * FK-111 FR-2: the page gains a second tab; the FK-003 reconciliation view stays the
 * default and is not modified.
 */
describe('ReceivedDataOverviewPage — fülek (FK-111)', () => {
  beforeEach(() => {
    mockRun.mockReset()
  })

  it('alapértelmezetten az egyeztetés fül aktív, a címletek nézet nincs kirenderelve', () => {
    render(<ReceivedDataOverviewPage />)

    expect(screen.getByTestId('received-data-tab-reconciliation')).toHaveAttribute(
      'aria-selected',
      'true',
    )
    expect(screen.getByTestId('received-data-tab-denominations')).toHaveAttribute(
      'aria-selected',
      'false',
    )
    expect(screen.getByText(/Válasszon intervallumot/i)).toBeInTheDocument()
    expect(screen.queryByTestId('denominations-view-stub')).not.toBeInTheDocument()
  })

  it('a fülváltás lekérdezés nélkül jeleníti meg a címletek nézetet', async () => {
    render(<ReceivedDataOverviewPage />)

    await userEvent.click(screen.getByTestId('received-data-tab-denominations'))

    expect(screen.getByTestId('denominations-view-stub')).toBeInTheDocument()
    expect(screen.queryByText(/Válasszon intervallumot/i)).not.toBeInTheDocument()
    expect(mockRun).not.toHaveBeenCalled()
  })

  it('TBD-1: a CSV és Frissítés gombok csak az egyeztetés fülön látszanak', async () => {
    mockRun.mockResolvedValue({
      startDate: '2026-09-10',
      endDate: '2026-09-10',
      totalRows: 0,
      matchedRows: 0,
      discrepancyRows: 0,
      notifiedBranches: 0,
      generatedAt: '2026-09-11T08:00:00',
      rows: [],
    })
    render(<ReceivedDataOverviewPage />)
    await userEvent.click(screen.getByRole('button', { name: /Ellenőrzés/i }))
    expect(await screen.findByRole('button', { name: /Frissítés/i })).toBeInTheDocument()

    await userEvent.click(screen.getByTestId('received-data-tab-denominations'))

    expect(screen.queryByRole('button', { name: hu.literals.csv })).not.toBeInTheDocument()
    expect(screen.queryByRole('button', { name: /Frissítés/i })).not.toBeInTheDocument()
  })

  it('vissza az egyeztetés fülre: a korábbi eredmény megmarad, újra-lekérdezés nélkül', async () => {
    mockRun.mockResolvedValue({
      startDate: '2026-09-10',
      endDate: '2026-09-10',
      totalRows: 1,
      matchedRows: 1,
      discrepancyRows: 0,
      notifiedBranches: 0,
      generatedAt: '2026-09-11T08:00:00',
      rows: [
        {
          transferId: 1,
          transferNumber: 'AT0001',
          date: '2026-09-10',
          fromBranchCode: 'BR009',
          fromBranchName: 'Dombóvár',
          toBranchCode: 'BR020',
          toBranchName: 'Szeged Értéktár',
          currencyCode: 'EUR',
          sentAmount: 5000,
          receivedAmount: 5000,
          status: 'EGYEZIK',
          discrepancyNote: null,
        },
      ],
    })
    render(<ReceivedDataOverviewPage />)
    await userEvent.click(screen.getByRole('button', { name: /Ellenőrzés/i }))
    expect(await screen.findByTestId('recon-row-AT0001')).toBeInTheDocument()

    await userEvent.click(screen.getByTestId('received-data-tab-denominations'))
    await userEvent.click(screen.getByTestId('received-data-tab-reconciliation'))

    expect(screen.getByTestId('recon-row-AT0001')).toBeInTheDocument()
    expect(mockRun).toHaveBeenCalledTimes(1)
  })
})
