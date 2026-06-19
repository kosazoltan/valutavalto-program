import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import RateMasterWorkflowPage from './RateMasterWorkflowPage'

const mocks = vi.hoisted(() => ({
  list: vi.fn(),
  approve: vi.fn(),
  publish: vi.fn(),
  revoke: vi.fn(),
  getDistributionStatus: vi.fn(),
  acknowledgeDistribution: vi.fn(),
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({ t: (key: string) => key }),
}))

vi.mock('../../utils/logger', () => ({
  logger: { error: vi.fn(), info: vi.fn(), warn: vi.fn(), debug: vi.fn() },
}))

vi.mock('../../services/api/exchangeRateMaster', () => ({
  exchangeRateMasterApi: mocks,
}))

const publishedRate = {
  id: 'rate-1',
  companyId: 'company-1',
  currencyId: 1,
  currencyCode: 'EUR',
  baseBuyRate: 390,
  baseSellRate: 399,
  officialRate: 394,
  status: 'PUBLISHED',
  createdAt: '2026-06-18T08:00:00',
}

describe('RateMasterWorkflowPage backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.list.mockImplementation((status: string) => {
      if (status === 'PUBLISHED') return Promise.resolve([publishedRate])
      return Promise.resolve([])
    })
    mocks.getDistributionStatus.mockResolvedValue([
      {
        id: 'dist-1',
        masterRateId: 'rate-1',
        branchId: 'branch-1',
        branchCode: 'BUD01',
        branchName: 'Budapest 01',
        status: 'DISTRIBUTED',
      },
    ])
    mocks.acknowledgeDistribution.mockResolvedValue(undefined)
  })

  it('elosztás kártyából meghívja az exchange-rate-master acknowledge backend szerződést', async () => {
    const user = userEvent.setup()
    render(<RateMasterWorkflowPage />)

    await user.click(screen.getByRole('button', { name: /Publikálva/i }))
    await screen.findByText('EUR')
    await user.click(screen.getByRole('button', { name: 'Elosztás' }))
    await screen.findByText('BUD01')
    await user.click(screen.getByTestId('exchange-rate-distribution-ack-dist-1'))

    await waitFor(() => {
      expect(mocks.acknowledgeDistribution).toHaveBeenCalledWith('dist-1')
      expect(mocks.getDistributionStatus).toHaveBeenCalledWith('rate-1')
    })
  })
})
