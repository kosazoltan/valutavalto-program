import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import RateCategoryPage from './RateCategoryPage'

const mocks = vi.hoisted(() => ({
  apiGet: vi.fn(),
  apiPost: vi.fn(),
}))

vi.mock('../../services/api/index', () => ({
  api: {
    get: (...args: unknown[]) => mocks.apiGet(...args),
    post: (...args: unknown[]) => mocks.apiPost(...args),
  },
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: () => ({
    user: {
      id: 11,
      branchId: '11111111-1111-1111-1111-111111111111',
    },
  }),
}))

describe('RateCategoryPage backend kapcsolatok', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.apiGet.mockImplementation((url: string) => {
      if (url === '/rate-categories/all') {
        return Promise.resolve({
          data: [
            {
              id: 'cat-1',
              branchId: '11111111-1111-1111-1111-111111111111',
              currencyCode: 'EUR',
              category: 'STANDARD',
              buyRate: 391.5,
              sellRate: 398.5,
              minAmount: 500,
              maxAmount: 5000,
            },
          ],
        })
      }
      if (url === '/rate-categories') {
        return Promise.resolve({
          data: {
            id: 'cat-1',
            currencyCode: 'EUR',
            category: 'STANDARD',
            buyRate: 391.5,
            sellRate: 398.5,
          },
        })
      }
      return Promise.resolve({ data: [] })
    })
  })

  it('betölti a listát és az összeg-alapú kategória próbát a backend GET /rate-categories végpontról kéri', async () => {
    const user = userEvent.setup()
    render(<RateCategoryPage />)

    await waitFor(() => {
      expect(mocks.apiGet).toHaveBeenCalledWith('/rate-categories/all', {
        params: { branchId: '11111111-1111-1111-1111-111111111111' },
      })
      expect(screen.getAllByText('STANDARD').length).toBeGreaterThan(0)
    })

    await user.clear(screen.getByLabelText('Összeg'))
    await user.type(screen.getByLabelText('Összeg'), '1500')
    await user.click(screen.getByRole('button', { name: 'Kategória próba' }))

    await waitFor(() => {
      expect(mocks.apiGet).toHaveBeenCalledWith('/rate-categories', {
        params: {
          branchId: '11111111-1111-1111-1111-111111111111',
          currency: 'EUR',
          amount: '1500',
        },
      })
      expect(screen.getByText(/Kategória:/)).toBeInTheDocument()
      expect(screen.getAllByText('STANDARD').length).toBeGreaterThan(0)
    })
  })
})
