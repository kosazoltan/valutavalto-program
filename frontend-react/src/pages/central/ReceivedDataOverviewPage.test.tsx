import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import ReceivedDataOverviewPage from './ReceivedDataOverviewPage'

const mockRun = vi.fn()
const mockStatus = vi.fn()

vi.mock('../../services/api', () => ({
  centralReceivedDataApi: {
    status: (...args: unknown[]) => mockStatus(...args),
  },
  transferReconciliationApi: {
    run: (...args: unknown[]) => mockRun(...args),
  },
}))

const result = {
  startDate: '2026-05-22',
  endDate: '2026-05-22',
  totalRows: 2,
  matchedRows: 1,
  discrepancyRows: 1,
  notifiedBranches: 1,
  generatedAt: '2026-05-23T10:00:00',
  rows: [
    {
      transferId: 1, transferNumber: 'AT0001', date: '2026-05-22',
      fromBranchCode: 'BR009', fromBranchName: 'Dombóvár',
      toBranchCode: 'BR020', toBranchName: 'Szeged Értéktár',
      currencyCode: 'EUR', sentAmount: 5000, receivedAmount: 5000,
      status: 'EGYEZIK', discrepancyNote: null,
    },
    {
      transferId: 2, transferNumber: 'AT0002', date: '2026-05-22',
      fromBranchCode: 'BR010', fromBranchName: 'Szekszárd',
      toBranchCode: 'BR020', toBranchName: 'Szeged Értéktár',
      currencyCode: 'USD', sentAmount: 3000, receivedAmount: 2900,
      status: 'ELTERES', discrepancyNote: 'Eltérő összeg: küldött 3000, fogadott 2900',
    },
  ],
}

const receivedDataStatus = {
  reportDate: '2026-05-22',
  totalBranches: 3,
  receivedReports: 2,
  submittedReports: 2,
  missingReports: 1,
  warningClosings: 1,
  criticalClosings: 1,
  totalTransactions: 12,
  totalBuyHuf: 1000000,
  totalSellHuf: 800000,
  totalFeeHuf: 12000,
  totalProfit: 22000,
  generatedAt: '2026-05-23T10:00:00',
  rows: [],
}

describe('ReceivedDataOverviewPage (FK-003 egyeztetés)', () => {
  beforeEach(() => {
    mockRun.mockReset()
    mockStatus.mockReset()
    mockStatus.mockResolvedValue(receivedDataStatus)
  })

  it('alapból nem fut automatikusan — az intervallum-választó prompt jelenik meg', () => {
    render(<ReceivedDataOverviewPage />)
    expect(screen.getByText(/Válasszon intervallumot/i)).toBeInTheDocument()
    expect(mockRun).not.toHaveBeenCalled()
    expect(mockStatus).not.toHaveBeenCalled()
  })

  it('az Ellenőrzés gomb lefuttatja az egyeztetést és megjeleníti az EGYEZIK/ELTÉRÉS sorokat', async () => {
    mockRun.mockResolvedValue(result)
    render(<ReceivedDataOverviewPage />)

    await userEvent.click(screen.getByRole('button', { name: /Ellenőrzés/i }))

    await waitFor(() => expect(mockRun).toHaveBeenCalledTimes(1))
    expect(mockStatus).toHaveBeenCalledWith(expect.stringMatching(/^\d{4}-\d{2}-\d{2}$/))
    expect(screen.getByText('EGYEZIK')).toBeInTheDocument()
    expect(screen.getByText('ELTÉRÉS')).toBeInTheDocument()
    expect(screen.getByText(/Eltérő összeg: küldött 3000, fogadott 2900/)).toBeInTheDocument()
    expect(screen.getByText('Beérkezett jelentés')).toBeInTheDocument()
    expect(screen.getByText('Hiányzó jelentés')).toBeInTheDocument()
  })

  it('az Eltérés szűrő elrejti az egyező sorokat', async () => {
    mockRun.mockResolvedValue(result)
    render(<ReceivedDataOverviewPage />)
    await userEvent.click(screen.getByRole('button', { name: /Ellenőrzés/i }))
    await waitFor(() => expect(screen.getByText('EGYEZIK')).toBeInTheDocument())

    await userEvent.selectOptions(screen.getByRole('combobox'), 'mismatch')

    expect(screen.queryByText('EGYEZIK')).not.toBeInTheDocument()
    expect(screen.getByText('ELTÉRÉS')).toBeInTheDocument()
  })
})
