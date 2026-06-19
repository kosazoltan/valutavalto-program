import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import ErrorMonitorPage from './ErrorMonitorPage'

const mocks = vi.hoisted(() => ({
  getErrorSummary: vi.fn(),
  listErrors: vi.fn(),
  getError: vi.fn(),
  loggerError: vi.fn(),
}))

vi.mock('../../services/api/diagnostics', () => ({
  diagnosticsApi: {
    getErrorSummary: mocks.getErrorSummary,
    listErrors: mocks.listErrors,
    getError: mocks.getError,
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: {
    error: mocks.loggerError,
  },
}))

describe('ErrorMonitorPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.getErrorSummary.mockResolvedValue({
      totalAllTime: 1,
      last24h: 1,
      last7d: 1,
      last30d: 1,
      componentBreakdown7d: [{ component: 'CashierTransactionPage', errorCount: 1 }],
      versionBreakdown7d: [{ version: '2.28.11', errorCount: 1 }],
      generatedAt: '2026-06-20T01:00:00',
    })
    mocks.listErrors.mockResolvedValue({
      content: [
        {
          id: 42,
          createdAt: '2026-06-20T01:01:00',
          component: 'CashierTransactionPage',
          version: '2.28.11',
          userIdentifier: 'worker-77',
          errorMessage: 'Lista szerinti rövid hiba',
        },
      ],
      totalElements: 1,
      totalPages: 1,
      number: 0,
      size: 50,
    })
    mocks.getError.mockResolvedValue({
      id: 42,
      createdAt: '2026-06-20T01:01:00',
      component: 'CashierTransactionPage',
      version: '2.28.11',
      osInfo: 'Windows',
      userIdentifier: 'worker-77',
      errorMessage: 'Backend részlet szerinti teljes hiba',
      stackTrace: 'Error: teljes stack',
      contextJson: '{"route":"/cashier"}',
      clientIp: '127.0.0.1',
      userAgent: 'Vitest',
    })
  })

  it('a Részletek gomb backend detail endpointot hív és a részletválaszt jeleníti meg', async () => {
    const user = userEvent.setup()
    render(<ErrorMonitorPage />)

    await screen.findByText('Lista szerinti rövid hiba')
    await user.click(screen.getByRole('button', { name: 'Részletek' }))

    await waitFor(() => expect(mocks.getError).toHaveBeenCalledWith(42))
    expect(await screen.findByText('Backend részlet szerinti teljes hiba')).toBeInTheDocument()
    expect(screen.getByText('Error: teljes stack')).toBeInTheDocument()
    expect(screen.getByText('{"route":"/cashier"}')).toBeInTheDocument()
  })
})
