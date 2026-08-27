import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import ContributionPage from './ContributionPage'

const mockList = vi.fn()
const mockGetById = vi.fn()
const mockGetByPeriod = vi.fn()
const mockCalculate = vi.fn()

vi.mock('../../services/api/index', () => ({
  contributionApi: {
    list: (...args: unknown[]) => mockList(...args),
    getById: (...args: unknown[]) => mockGetById(...args),
    getByPeriod: (...args: unknown[]) => mockGetByPeriod(...args),
    calculate: (...args: unknown[]) => mockCalculate(...args),
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

describe('ContributionPage backend contract', () => {
  beforeEach(() => {
    mockList.mockReset()
    mockGetById.mockReset()
    mockGetByPeriod.mockReset()
    mockCalculate.mockReset()
    mockList.mockResolvedValue([])
    mockGetById.mockResolvedValue({
      id: 'contribution-1',
      workerFullName: 'Teszt Elek',
      branchName: 'Szeged Értéktár',
      periodStart: '2026-06-01',
      periodEnd: '2026-06-30',
      contributionTypeName: 'Jutalék',
      baseAmount: 100000,
      calculatedAmount: 12000,
      currencyCode: 'HUF',
      statusName: 'Jóváhagyva',
      transactionCount: 7,
      totalVolume: 100000,
      calculationDate: '2026-06-19',
      calculationDetails: 'Backend részletszámítás',
    })
    mockGetByPeriod.mockResolvedValue([])
    mockCalculate.mockResolvedValue([
      {
        id: 'contribution-2',
        workerFullName: 'Számolt Sára',
        branchName: 'Szeged Értéktár',
        periodStart: '2026-06-01',
        periodEnd: '2026-06-30',
        contributionTypeName: 'Járulék',
        baseAmount: 200000,
        calculatedAmount: 24000,
        currencyCode: 'HUF',
        statusName: 'Számított',
        calculationDate: '2026-06-19',
      },
    ])
  })

  it('időszakos szűrésnél elküldi a backend által kötelező branchId paramétert', async () => {
    const { container } = render(<ContributionPage />)

    await waitFor(() => expect(mockList).toHaveBeenCalledTimes(1))

    const [startInput, endInput] = getDateInputs(container)
    fireEvent.change(startInput, { target: { value: '2026-06-01' } })
    fireEvent.change(endInput, { target: { value: '2026-06-30' } })
    fireEvent.click(screen.getByRole('button', { name: /common.filter/i }))

    await waitFor(() =>
      expect(mockGetByPeriod).toHaveBeenCalledWith('branch-123', '2026-06-01', '2026-06-30'),
    )
  })

  it('időszaki számításnál meghívja a /contributions/calculate backend szerződést', async () => {
    const { container } = render(<ContributionPage />)

    await waitFor(() => expect(mockList).toHaveBeenCalledTimes(1))

    const [startInput, endInput] = getDateInputs(container)
    fireEvent.change(startInput, { target: { value: '2026-06-01' } })
    fireEvent.change(endInput, { target: { value: '2026-06-30' } })
    fireEvent.click(screen.getByRole('button', { name: /Időszaki számítás/i }))

    await waitFor(() => {
      expect(mockCalculate).toHaveBeenCalledWith('branch-123', '2026-06-01', '2026-06-30')
      expect(screen.getByText('Számolt Sára')).toBeInTheDocument()
    })
  })

  it('részletek gombra a backend getById végpontról tölti a kiválasztott járulékot', async () => {
    mockList.mockResolvedValue([
      {
        id: 'contribution-1',
        workerFullName: 'Teszt Elek',
        branchName: 'Szeged Értéktár',
        periodStart: '2026-06-01',
        periodEnd: '2026-06-30',
        contributionTypeName: 'Jutalék',
        baseAmount: 100000,
        calculatedAmount: 12000,
        currencyCode: 'HUF',
        statusName: 'Jóváhagyva',
        calculationDate: '2026-06-19',
      },
    ])

    render(<ContributionPage />)

    await waitFor(() => expect(screen.getByText('Teszt Elek')).toBeInTheDocument())
    fireEvent.click(screen.getByRole('button', { name: 'Részletek' }))

    await waitFor(() => expect(mockGetById).toHaveBeenCalledWith('contribution-1'))
    expect(await screen.findByTestId('contribution-detail-panel')).toHaveTextContent(
      'Backend részletszámítás',
    )
  })
})
