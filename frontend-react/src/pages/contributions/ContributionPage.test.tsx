import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import ContributionPage from './ContributionPage'

const mockList = vi.fn()
const mockGetByPeriod = vi.fn()

vi.mock('../../services/api/index', () => ({
  contributionApi: {
    list: (...args: unknown[]) => mockList(...args),
    getByPeriod: (...args: unknown[]) => mockGetByPeriod(...args),
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
    mockGetByPeriod.mockReset()
    mockList.mockResolvedValue([])
    mockGetByPeriod.mockResolvedValue([])
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
})
