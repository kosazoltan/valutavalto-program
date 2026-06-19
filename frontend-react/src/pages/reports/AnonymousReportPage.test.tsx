import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import AnonymousReportPage from './AnonymousReportPage'

const mocks = vi.hoisted(() => ({
  list: vi.fn(),
  getById: vi.fn(),
  create: vi.fn(),
  assign: vi.fn(),
  resolve: vi.fn(),
  toast: {
    success: vi.fn(),
    warning: vi.fn(),
    error: vi.fn(),
  },
}))

vi.mock('../../services/api/index', () => ({
  anonymousReportApi: {
    list: mocks.list,
    getById: mocks.getById,
    create: mocks.create,
    assign: mocks.assign,
    resolve: mocks.resolve,
  },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: mocks.toast,
}))

vi.mock('../../utils/logger', () => ({
  logger: { error: vi.fn(), warn: vi.fn(), info: vi.fn() },
}))

describe('AnonymousReportPage backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.list.mockResolvedValue([
      {
        id: 'report-1',
        reportType: 'COMPLAINT',
        subject: 'Lista szerinti tárgy',
        description: 'Lista szerinti rövid leírás',
        reportedAt: '2026-06-19T08:00:00.000Z',
        status: 'NEW',
      },
    ])
    mocks.getById.mockResolvedValue({
      id: 'report-1',
      reportType: 'COMPLAINT',
      subject: 'Backend részletes tárgy',
      description: 'Backendből betöltött részletes leírás',
      reportedAt: '2026-06-19T08:00:00.000Z',
      status: 'NEW',
      assignedToName: 'Felelős dolgozó',
    })
  })

  it('részletek megnyitásakor a backend detail endpointot használja', async () => {
    const user = userEvent.setup()
    render(<AnonymousReportPage />)

    await waitFor(() => expect(mocks.list).toHaveBeenCalled())
    await user.click(screen.getByRole('button', { name: /Részletek/i }))

    await waitFor(() => {
      expect(mocks.getById).toHaveBeenCalledWith('report-1')
    })
    expect(await screen.findByText(/Backendből betöltött részletes leírás/i)).toBeInTheDocument()
    expect(screen.getByText(/Felelős dolgozó/i)).toBeInTheDocument()
  })
})
