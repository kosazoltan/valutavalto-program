import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import SuspiciousCustomersPanel from './SuspiciousCustomersPanel'

const mocks = vi.hoisted(() => ({
  search: vi.fn(),
  exportXlsx: vi.fn(),
  downloadBlob: vi.fn(),
  toastSuccess: vi.fn(),
  toastError: vi.fn(),
}))

vi.mock('../../services/api/suspiciousCustomers', () => ({
  suspiciousCustomersApi: {
    search: (...args: unknown[]) => mocks.search(...args),
    exportXlsx: (...args: unknown[]) => mocks.exportXlsx(...args),
  },
}))

vi.mock('../../utils/downloadBlob', () => ({
  downloadBlob: (...args: unknown[]) => mocks.downloadBlob(...args),
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: {
    success: (...args: unknown[]) => mocks.toastSuccess(...args),
    error: (...args: unknown[]) => mocks.toastError(...args),
  },
}))

const pagedResult = {
  content: [
    {
      customerId: 'CUST-42',
      customerName: 'Teszt Elek',
      transactionCount: 12,
      totalHufAmount: '12500000',
      branchCount: 4,
      highTransactionCount: true,
      highTotalValue: true,
      manyBranches: true,
    },
  ],
  totalElements: 1,
  totalPages: 1,
  size: 50,
  number: 0,
}

beforeEach(() => {
  vi.clearAllMocks()
  mocks.search.mockResolvedValue(pagedResult)
  mocks.exportXlsx.mockResolvedValue(
    new Blob(['xlsx'], {
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    }),
  )
})

describe('SuspiciousCustomersPanel', () => {
  it('mountkor nem hív API-t', () => {
    render(<SuspiciousCustomersPanel />)

    expect(mocks.search).not.toHaveBeenCalled()
    expect(mocks.exportXlsx).not.toHaveBeenCalled()
  })

  it('Lekérdezés gombra a megadott szűrőkkel hív és rendereli a találatokat', async () => {
    const user = userEvent.setup()
    render(<SuspiciousCustomersPanel />)

    await user.clear(screen.getByTestId('suspicious-start-date'))
    await user.type(screen.getByTestId('suspicious-start-date'), '2026-07-01')
    await user.clear(screen.getByTestId('suspicious-end-date'))
    await user.type(screen.getByTestId('suspicious-end-date'), '2026-07-31')
    await user.clear(screen.getByPlaceholderText('alapért. 10'))
    await user.type(screen.getByPlaceholderText('alapért. 10'), '12')
    await user.click(screen.getByLabelText('Magas össz tranzakciós érték'))
    await user.click(screen.getByTestId('suspicious-search-button'))

    expect(await screen.findByTestId('suspicious-results-table')).toBeInTheDocument()
    expect(screen.getByText('Teszt Elek')).toBeInTheDocument()
    expect(screen.getByText('12 500 000')).toBeInTheDocument()
    expect(mocks.search).toHaveBeenCalledWith(
      expect.objectContaining({
        startDate: '2026-07-01',
        endDate: '2026-07-31',
        byTransactionCount: true,
        minTransactionCount: '12',
        byTotalValue: false,
        byBranchCount: true,
      }),
      0,
      50,
    )
  })

  it('export-gomb blob letöltést indít', async () => {
    const user = userEvent.setup()
    render(<SuspiciousCustomersPanel />)

    await user.clear(screen.getByTestId('suspicious-start-date'))
    await user.type(screen.getByTestId('suspicious-start-date'), '2026-07-01')
    await user.clear(screen.getByTestId('suspicious-end-date'))
    await user.type(screen.getByTestId('suspicious-end-date'), '2026-07-31')
    await user.click(screen.getByTestId('suspicious-export-button'))

    await waitFor(() => expect(mocks.exportXlsx).toHaveBeenCalledWith('2026-07-01', '2026-07-31'))
    expect(mocks.downloadBlob).toHaveBeenCalledWith(
      expect.any(Blob),
      expect.stringMatching(/^gyanus_ugyfelek_ertekhatart_elertek_\d{4}-\d{2}-\d{2}\.xlsx$/),
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    )
    expect(mocks.toastSuccess).toHaveBeenCalledWith('Export letöltve')
  })

  it('API-hiba esetén magyar hibaüzenetet jelenít meg és toastol', async () => {
    const user = userEvent.setup()
    mocks.search.mockRejectedValue(new Error('Szerverhiba'))
    render(<SuspiciousCustomersPanel />)

    await user.click(screen.getByTestId('suspicious-search-button'))

    expect(await screen.findByRole('alert')).toHaveTextContent('Szerverhiba')
    expect(mocks.toastError).toHaveBeenCalledWith('Lekérdezés sikertelen', 'Szerverhiba')
  })
})
