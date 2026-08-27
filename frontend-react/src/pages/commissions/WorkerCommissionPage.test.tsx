import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import WorkerCommissionPage from './WorkerCommissionPage'

const mockList = vi.fn()
const mockGetById = vi.fn()
const mockGetByPeriod = vi.fn()
const mockCalculatePeriod = vi.fn()
const mockGetAccountingList = vi.fn()
const mockCommissionReport = vi.fn()
const mockCommissionCalculate = vi.fn()
const mockCommissionCalculateAll = vi.fn()
const mockCommissionApprove = vi.fn()

vi.mock('../../services/api/index', () => ({
  workerCommissionApi: {
    list: (...args: unknown[]) => mockList(...args),
    getById: (...args: unknown[]) => mockGetById(...args),
    getByPeriod: (...args: unknown[]) => mockGetByPeriod(...args),
    calculate: (...args: unknown[]) => mockCalculatePeriod(...args),
    getAccountingList: (...args: unknown[]) => mockGetAccountingList(...args),
  },
  commissionCalculationApi: {
    calculate: (...args: unknown[]) => mockCommissionCalculate(...args),
    calculateAll: (...args: unknown[]) => mockCommissionCalculateAll(...args),
    approve: (...args: unknown[]) => mockCommissionApprove(...args),
    report: (...args: unknown[]) => mockCommissionReport(...args),
  },
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: unknown) => unknown) =>
    selector({ worker: { branchId: 'branch-123', branchName: 'Szeged Értéktár' } }),
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: {
    warning: vi.fn(),
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: {
    error: vi.fn(),
  },
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

const getDateInputs = (container: HTMLElement): [HTMLInputElement, HTMLInputElement] => {
  const inputs = Array.from(container.querySelectorAll<HTMLInputElement>('input[type="date"]'))
  if (!inputs[0] || !inputs[1]) {
    throw new Error('Expected start and end date inputs')
  }
  return [inputs[0], inputs[1]]
}

describe('WorkerCommissionPage backend contract', () => {
  beforeEach(() => {
    mockList.mockReset()
    mockGetById.mockReset()
    mockGetByPeriod.mockReset()
    mockCalculatePeriod.mockReset()
    mockGetAccountingList.mockReset()
    mockCommissionReport.mockReset()
    mockCommissionCalculate.mockReset()
    mockCommissionCalculateAll.mockReset()
    mockCommissionApprove.mockReset()
    mockList.mockResolvedValue([])
    mockGetById.mockResolvedValue({
      id: '11111111-1111-1111-1111-111111111111',
      workerId: '77',
      workerName: 'Backend Béla',
      branchId: 'branch-123',
      branchName: 'Szeged Értéktár',
      periodStart: '2026-06-01',
      periodEnd: '2026-06-30',
      transactionCount: 12,
      totalTransactionAmount: 1500000,
      commissionRate: 0.0125,
      commissionAmount: 18750,
      currencyCode: 'HUF',
      statusDid: 'APPROVED',
      statusName: 'Jóváhagyva',
      calculationDate: '2026-06-30',
      approvedByName: 'Vezető Vera',
    })
    mockGetByPeriod.mockResolvedValue([])
    mockCalculatePeriod.mockResolvedValue([
      {
        id: '22222222-2222-2222-2222-222222222222',
        workerId: '88',
        workerName: 'Számolt Sára',
        branchId: 'branch-123',
        branchName: 'Szeged Értéktár',
        periodStart: '2026-06-01',
        periodEnd: '2026-06-30',
        transactionCount: 9,
        totalTransactionAmount: 900000,
        commissionRate: 0.01,
        commissionAmount: 9000,
        currencyCode: 'HUF',
        statusDid: 'CALCULATED',
        statusName: 'Számított',
      },
    ])
    mockGetAccountingList.mockResolvedValue([])
    mockCommissionReport.mockResolvedValue([])
    mockCommissionCalculate.mockResolvedValue({
      id: 'calc-single',
      workerId: 77,
      branchId: 'branch-123',
      period: '2026-06',
      calculationType: 'MONTHLY',
      totalTransactions: 1,
      totalVolumeHuf: 100000,
      status: 'CALCULATED',
    })
    mockCommissionCalculateAll.mockResolvedValue([
      {
        id: 'calc-all',
        workerId: 88,
        branchId: 'branch-123',
        period: '2026-06',
        calculationType: 'MONTHLY',
        totalTransactions: 2,
        totalVolumeHuf: 200000,
        status: 'CALCULATED',
      },
    ])
    mockCommissionApprove.mockResolvedValue({
      id: 'calc-1',
      workerId: 77,
      branchId: 'branch-123',
      period: '2026-06',
      calculationType: 'MONTHLY',
      totalTransactions: 12,
      totalVolumeHuf: 1500000,
      commissionRate: 0.01,
      commissionAmount: 15000,
      bonusAmount: 5000,
      deductions: 0,
      netCommission: 20000,
      status: 'APPROVED',
    })
  })

  it('időszakos szűrésnél elküldi a backend által kötelező branchId paramétert', async () => {
    const { container } = render(<WorkerCommissionPage />)

    await waitFor(() => expect(mockList).toHaveBeenCalledTimes(1))

    const [startInput, endInput] = getDateInputs(container)
    fireEvent.change(startInput, { target: { value: '2026-06-01' } })
    fireEvent.change(endInput, { target: { value: '2026-06-30' } })
    fireEvent.click(screen.getByRole('button', { name: /common.filter/i }))

    await waitFor(() =>
      expect(mockGetByPeriod).toHaveBeenCalledWith('branch-123', '2026-06-01', '2026-06-30'),
    )
  })

  it('exportnál elküldi a backend által kötelező branchId paramétert', async () => {
    const { container } = render(<WorkerCommissionPage />)

    await waitFor(() => expect(mockList).toHaveBeenCalledTimes(1))

    const [startInput, endInput] = getDateInputs(container)
    fireEvent.change(startInput, { target: { value: '2026-06-01' } })
    fireEvent.change(endInput, { target: { value: '2026-06-30' } })
    fireEvent.click(screen.getByRole('button', { name: /commissions.export/i }))

    await waitFor(() =>
      expect(mockGetAccountingList).toHaveBeenCalledWith('branch-123', '2026-06-01', '2026-06-30'),
    )
  })

  it('időszaki számításnál meghívja a /worker-commissions/calculate backend szerződést', async () => {
    const { container } = render(<WorkerCommissionPage />)

    await waitFor(() => expect(mockList).toHaveBeenCalledTimes(1))

    const [startInput, endInput] = getDateInputs(container)
    fireEvent.change(startInput, { target: { value: '2026-06-01' } })
    fireEvent.change(endInput, { target: { value: '2026-06-30' } })
    fireEvent.click(screen.getByRole('button', { name: /Időszaki számítás/i }))

    await waitFor(() => {
      expect(mockCalculatePeriod).toHaveBeenCalledWith('branch-123', '2026-06-01', '2026-06-30')
      expect(screen.getAllByText('Számolt Sára').length).toBeGreaterThan(0)
    })
  })

  it('részletek megnyitásakor meghívja a /worker-commissions/{id} backend detail végpontot', async () => {
    mockList.mockResolvedValue([
      {
        id: '11111111-1111-1111-1111-111111111111',
        workerId: '77',
        workerName: 'Lista Lajos',
        branchId: 'branch-123',
        branchName: 'Szeged Értéktár',
        periodStart: '2026-06-01',
        periodEnd: '2026-06-30',
        transactionCount: 8,
        totalTransactionAmount: 800000,
        commissionRate: 0.01,
        commissionAmount: 8000,
        currencyCode: 'HUF',
        statusDid: 'CALCULATED',
        statusName: 'Számított',
        calculationDate: '2026-06-29',
      },
    ])

    render(<WorkerCommissionPage />)

    await waitFor(() => expect(mockList).toHaveBeenCalledTimes(1))
    fireEvent.click(screen.getAllByRole('button', { name: /Jutalék részletek: Lista Lajos/i })[0]!)

    await waitFor(() => {
      expect(mockGetById).toHaveBeenCalledWith('11111111-1111-1111-1111-111111111111')
      expect(screen.getByTestId('worker-commission-detail')).toHaveTextContent('Backend Béla')
      expect(screen.getByTestId('worker-commission-detail')).toHaveTextContent('18 750 HUF')
    })
  })

  it('havi számítási riportnál meghívja a /commissions/report backend szerződést', async () => {
    mockCommissionReport.mockResolvedValue([
      {
        id: 'calc-1',
        workerId: 77,
        branchId: 'branch-123',
        period: '2026-06',
        calculationType: 'MONTHLY',
        totalTransactions: 12,
        totalVolumeHuf: 1500000,
        commissionRate: 0.01,
        commissionAmount: 15000,
        bonusAmount: 5000,
        deductions: 0,
        netCommission: 20000,
        status: 'CALCULATED',
      },
    ])

    const { container } = render(<WorkerCommissionPage />)

    await waitFor(() => expect(mockList).toHaveBeenCalledTimes(1))

    const monthInput = container.querySelector<HTMLInputElement>('input[type="month"]')
    if (!monthInput) throw new Error('Expected month input')
    fireEvent.change(monthInput, { target: { value: '2026-06' } })
    fireEvent.click(screen.getByRole('button', { name: /Riport betöltése/i }))

    await waitFor(() => {
      expect(mockCommissionReport).toHaveBeenCalledWith('2026-06')
      expect(screen.getAllByText('2026-06').length).toBeGreaterThan(0)
      expect(screen.getAllByText('CALCULATED').length).toBeGreaterThan(0)
    })
  })

  it('saját havi jutalékszámításnál meghívja a /commissions/calculate backend szerződést', async () => {
    const { container } = render(<WorkerCommissionPage />)

    await waitFor(() => expect(mockList).toHaveBeenCalledTimes(1))

    const monthInput = container.querySelector<HTMLInputElement>('input[type="month"]')
    if (!monthInput) throw new Error('Expected month input')
    fireEvent.change(monthInput, { target: { value: '2026-06' } })
    fireEvent.click(screen.getByRole('button', { name: /Saját számítás/i }))

    await waitFor(() => {
      expect(mockCommissionCalculate).toHaveBeenCalledWith('2026-06')
      expect(screen.getAllByText('77').length).toBeGreaterThan(0)
    })
  })

  it('fiókszintű havi jutalékszámításnál meghívja a /commissions/calculate-all backend szerződést', async () => {
    const { container } = render(<WorkerCommissionPage />)

    await waitFor(() => expect(mockList).toHaveBeenCalledTimes(1))

    const monthInput = container.querySelector<HTMLInputElement>('input[type="month"]')
    if (!monthInput) throw new Error('Expected month input')
    fireEvent.change(monthInput, { target: { value: '2026-06' } })
    fireEvent.click(screen.getByRole('button', { name: /Fiók számítása/i }))

    await waitFor(() => {
      expect(mockCommissionCalculateAll).toHaveBeenCalledWith('2026-06', 'branch-123')
      expect(screen.getAllByText('88').length).toBeGreaterThan(0)
    })
  })

  it('havi jutalék jóváhagyásnál meghívja a /commissions/{id}/approve backend szerződést', async () => {
    mockCommissionReport.mockResolvedValue([
      {
        id: 'calc-1',
        workerId: 77,
        branchId: 'branch-123',
        period: '2026-06',
        calculationType: 'MONTHLY',
        totalTransactions: 12,
        totalVolumeHuf: 1500000,
        commissionRate: 0.01,
        commissionAmount: 15000,
        bonusAmount: 5000,
        deductions: 0,
        netCommission: 20000,
        status: 'CALCULATED',
      },
    ])

    const { container } = render(<WorkerCommissionPage />)

    await waitFor(() => expect(mockList).toHaveBeenCalledTimes(1))

    const monthInput = container.querySelector<HTMLInputElement>('input[type="month"]')
    if (!monthInput) throw new Error('Expected month input')
    fireEvent.change(monthInput, { target: { value: '2026-06' } })
    fireEvent.click(screen.getByRole('button', { name: /Riport betöltése/i }))

    await waitFor(() => expect(screen.getAllByText('CALCULATED').length).toBeGreaterThan(0))
    fireEvent.click(screen.getAllByRole('button', { name: /common.approve/i })[0]!)

    await waitFor(() => {
      expect(mockCommissionApprove).toHaveBeenCalledWith('calc-1')
      expect(screen.getAllByText('APPROVED').length).toBeGreaterThan(0)
    })
  })
})
