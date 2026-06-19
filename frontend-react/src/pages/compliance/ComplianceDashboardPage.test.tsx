import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import ComplianceDashboardPage from './ComplianceDashboardPage'

const mocks = vi.hoisted(() => ({
  dailySummary: vi.fn(),
  overdueReports: vi.fn(),
  pendingReports: vi.fn(),
  rollingWindowAudit: vi.fn(),
  checkTransaction: vi.fn(),
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

describe('ComplianceDashboardPage manual AML check', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.dailySummary.mockResolvedValue({
      date: '2026-06-18',
      totalReports: 0,
      pendingReports: 0,
      submittedReports: 0,
      flaggedReports: 0,
      standardChecks: 1,
      enhancedChecks: 0,
      suspiciousChecks: 0,
      thresholdChecks: 0,
      totalAmountHuf: 0,
    })
    mocks.overdueReports.mockResolvedValue([])
    mocks.pendingReports.mockResolvedValue([])
    mocks.rollingWindowAudit.mockResolvedValue([])
    mocks.checkTransaction.mockResolvedValue({
      transactionType: 5,
      weeklyTotal: 0,
      yearlyMax: 0,
      quarterlyCount: 0,
      quarterlyTotal: 0,
      requiresId: true,
      requiresEnhanced: true,
      blocked: false,
      rollingWindowExceeded: true,
      rollingWindowLimit: 4500000,
      rollingWindowTotal: 5100000,
      rollingWindowDays: 8,
      requiresManagerApproval: true,
      managerApprovalReason: '8 napos limit felett',
      warnings: ['Fokozott átvilágítás szükséges'],
    })
  })

  it('POST /aml/check backend szerződéssel futtat kézi AML ellenőrzést', async () => {
    const user = userEvent.setup()
    render(<ComplianceDashboardPage />)

    await screen.findByText('Kézi AML tranzakció-ellenőrzés')
    await user.type(screen.getByTestId('aml-manual-customer-id'), 'cust-42')
    await user.clear(screen.getByTestId('aml-manual-currency'))
    await user.type(screen.getByTestId('aml-manual-currency'), 'eur')
    await user.type(screen.getByTestId('aml-manual-amount'), '5100000')
    await user.click(screen.getByTestId('aml-manual-check-button'))

    await waitFor(() => expect(mocks.checkTransaction).toHaveBeenCalledWith({
      amountHuf: 5100000,
      customerId: 'cust-42',
      currencyCode: 'EUR',
    }))
    expect(screen.getByTestId('aml-manual-result')).toHaveTextContent('Tranzakció típus: 5')
    expect(screen.getByText('Vezetői jóváhagyás kell')).toBeInTheDocument()
    expect(screen.getByText('Fokozott átvilágítás szükséges')).toBeInTheDocument()
  })
})
