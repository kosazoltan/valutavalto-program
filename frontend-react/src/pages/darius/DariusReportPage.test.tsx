import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import DariusReportPage from './DariusReportPage'

const mocks = vi.hoisted(() => ({
  getRange: vi.fn(),
  getMonthly: vi.fn(),
  getMissingDates: vi.fn(),
  generate: vi.fn(),
  approve: vi.fn(),
  submit: vi.fn(),
  retryFailed: vi.fn(),
  getByDate: vi.fn(),
}))

vi.mock('../../services/api/index', () => ({
  dariusApi: mocks,
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({ t: (key: string) => key }),
}))

const dailyReport = {
  id: 'darius-1',
  reportDate: '2026-06-19',
  status: 'GENERATED',
  companyId: 'company-1',
  totalBuyHuf: 100000,
  totalSellHuf: 50000,
  totalHandlingFeeHuf: 1200,
  transactionCount: 3,
  branchCount: 1,
  payloadHash: 'abcdef1234567890abcdef',
  retryCount: 0,
  maxRetries: 3,
  lines: [
    {
      id: 'line-1',
      branchId: 'branch-1',
      branchCode: 'BUD01',
      currencyCode: 'EUR',
      buyCount: 2,
      buyCurrencyAmount: 100,
      buyHufAmount: 40000,
      sellCount: 1,
      sellCurrencyAmount: 50,
      sellHufAmount: 20000,
      avgBuyRate: 400,
      avgSellRate: 410,
      handlingFeeHuf: 1200,
    },
  ],
}

describe('DariusReportPage backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.getRange.mockResolvedValue({ data: [] })
    mocks.getMonthly.mockResolvedValue({ data: null })
    mocks.getMissingDates.mockResolvedValue({ data: [] })
    mocks.generate.mockResolvedValue({ data: dailyReport })
    mocks.approve.mockResolvedValue({ data: dailyReport })
    mocks.submit.mockResolvedValue({ data: dailyReport })
    mocks.retryFailed.mockResolvedValue({ data: [] })
    mocks.getByDate.mockResolvedValue({ data: dailyReport })
  })

  it('napi lekérdezéskor a backend by-date reprezentációját jeleníti meg', async () => {
    const user = userEvent.setup()
    render(<DariusReportPage />)

    const dateInputs = await screen.findAllByDisplayValue(/\d{4}-\d{2}-\d{2}/)
    await user.clear(dateInputs[2]!)
    await user.type(dateInputs[2]!, '2026-06-19')
    await user.click(screen.getByRole('button', { name: /Napi lekérdezés/i }))

    await waitFor(() => {
      expect(mocks.getByDate).toHaveBeenCalledWith('2026-06-19')
      expect(screen.getByText(/darius.reszletek/)).toBeInTheDocument()
      expect(screen.getByText('EUR')).toBeInTheDocument()
      expect(screen.getByText('BUD01')).toBeInTheDocument()
      expect(screen.getByText(/abcdef1234567890/)).toBeInTheDocument()
    })
  })
})
