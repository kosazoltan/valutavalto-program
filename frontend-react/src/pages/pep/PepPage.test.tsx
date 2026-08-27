import { render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import PepPage from './PepPage'

const mocks = vi.hoisted(() => ({
  dailySummary: vi.fn(),
  overdueReports: vi.fn(),
  pendingReports: vi.fn(),
  rollingWindowAudit: vi.fn(),
  checkTransaction: vi.fn(),
  logger: { error: vi.fn(), info: vi.fn(), warn: vi.fn(), debug: vi.fn() },
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

vi.mock('../../services/api/aml', () => ({
  amlApi: {
    dailySummary: (...args: unknown[]) => mocks.dailySummary(...args),
    overdueReports: (...args: unknown[]) => mocks.overdueReports(...args),
    pendingReports: (...args: unknown[]) => mocks.pendingReports(...args),
    rollingWindowAudit: (...args: unknown[]) => mocks.rollingWindowAudit(...args),
    checkTransaction: (...args: unknown[]) => mocks.checkTransaction(...args),
  },
}))

vi.mock('../../utils/logger', () => ({ logger: mocks.logger }))

describe('PepPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.dailySummary.mockResolvedValue({
      date: '2026-06-19',
      totalReports: 1,
      pendingReports: 1,
      submittedReports: 0,
      flaggedReports: 0,
      standardChecks: 1,
      enhancedChecks: 1,
      suspiciousChecks: 0,
      thresholdChecks: 1,
      totalAmountHuf: 5100000,
    })
    mocks.overdueReports.mockResolvedValue([])
    mocks.pendingReports.mockResolvedValue([])
    mocks.rollingWindowAudit.mockResolvedValue([])
  })

  it('a /pep route-ot a valós AML/compliance backend szerződésekre köti', async () => {
    render(<PepPage />)

    await screen.findByText('Kézi AML tranzakció-ellenőrzés')
    expect(screen.getByText('compliance.complianceDashboard')).toBeInTheDocument()
    expect(screen.queryByText(/nincs külön \/pep backend CRUD API/i)).not.toBeInTheDocument()

    await waitFor(() => {
      expect(mocks.dailySummary).toHaveBeenCalledTimes(1)
      expect(mocks.overdueReports).toHaveBeenCalledTimes(1)
      expect(mocks.pendingReports).toHaveBeenCalledTimes(1)
      expect(mocks.rollingWindowAudit).toHaveBeenCalledTimes(1)
    })
  })
})
