import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import RateMasterWorkflowPage from './RateMasterWorkflowPage'

const mocks = vi.hoisted(() => ({
  list: vi.fn(),
  create: vi.fn(),
  approve: vi.fn(),
  publish: vi.fn(),
  revoke: vi.fn(),
  getDistributionStatus: vi.fn(),
  acknowledgeDistribution: vi.fn(),
  getPendingPrintObligations: vi.fn(),
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
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
    mocks.getPendingPrintObligations.mockResolvedValue([
      {
        distributionId: 'dist-1',
        masterRateId: 'rate-1',
        currencyCode: 'EUR',
        versionNumber: 3,
        baseBuyRate: 390,
        baseSellRate: 399,
        officialRate: 394,
        validFrom: '2026-07-04T09:00:00',
        printProofToken: 'proof-token',
      },
    ])
    mocks.create.mockResolvedValue({
      ...publishedRate,
      id: 'draft-1',
      status: 'DRAFT',
    })
  })

  it('vázlat létrehozáskor meghívja az exchange-rate-master create backend szerződést', async () => {
    const user = userEvent.setup()
    render(<RateMasterWorkflowPage />)

    await user.type(screen.getByLabelText('Valuta ID'), '1')
    await user.type(screen.getByLabelText('Vételi árfolyam'), '390,5')
    await user.type(screen.getByLabelText('Eladási árfolyam'), '399,5')
    await user.type(screen.getByLabelText('MNB árfolyam'), '394')
    await user.type(screen.getByLabelText('Megjegyzés'), 'reggeli központi vázlat')
    await user.click(screen.getByRole('button', { name: 'Vázlat létrehozása' }))

    await waitFor(() => {
      expect(mocks.create).toHaveBeenCalledWith({
        currencyId: 1,
        baseBuyRate: 390.5,
        baseSellRate: 399.5,
        officialRate: 394,
        notes: 'reggeli központi vázlat',
      })
      expect(mocks.list).toHaveBeenCalledWith('DRAFT')
    })
  })

  it('elosztás kártyából nyomtatás után proof tokennel hívja az acknowledge szerződést', async () => {
    const user = userEvent.setup()
    const printSpy = vi.spyOn(window, 'print').mockImplementation(() => {})
    render(<RateMasterWorkflowPage />)

    await user.click(screen.getByRole('button', { name: /Publikálva/i }))
    await screen.findByText('EUR')
    await user.click(screen.getByRole('button', { name: 'Elosztás' }))
    await screen.findByText('BUD01')
    await user.click(screen.getByTestId('exchange-rate-distribution-ack-dist-1'))

    await waitFor(() => {
      expect(printSpy).toHaveBeenCalled()
      expect(mocks.acknowledgeDistribution).toHaveBeenCalledWith('dist-1', 'proof-token')
      expect(mocks.getDistributionStatus).toHaveBeenCalledWith('rate-1')
    })
  })

  it('proof token nélkül hibát jelez és nem hív acknowledge-t', async () => {
    const user = userEvent.setup()
    const printSpy = vi.spyOn(window, 'print').mockImplementation(() => {})
    mocks.getPendingPrintObligations.mockResolvedValue([])
    render(<RateMasterWorkflowPage />)

    await user.click(screen.getByRole('button', { name: /Publikálva/i }))
    await screen.findByText('EUR')
    await user.click(screen.getByRole('button', { name: 'Elosztás' }))
    await screen.findByText('BUD01')
    await user.click(screen.getByTestId('exchange-rate-distribution-ack-dist-1'))

    await screen.findByText(/Proof-of-Print token hiányzik/i)
    expect(printSpy).not.toHaveBeenCalled()
    expect(mocks.acknowledgeDistribution).not.toHaveBeenCalled()
  })
})
