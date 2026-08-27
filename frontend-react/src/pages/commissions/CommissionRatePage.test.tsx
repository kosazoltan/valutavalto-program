import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import CommissionRatePage from './CommissionRatePage'

const mocks = vi.hoisted(() => ({
  list: vi.fn(),
  getById: vi.fn(),
  create: vi.fn(),
  update: vi.fn(),
  delete: vi.fn(),
  toast: {
    success: vi.fn(),
    warning: vi.fn(),
    error: vi.fn(),
  },
  logger: {
    error: vi.fn(),
  },
}))

vi.mock('../../services/api/index', () => ({
  commissionRateApi: {
    list: mocks.list,
    getById: mocks.getById,
    create: mocks.create,
    update: mocks.update,
    delete: mocks.delete,
  },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: mocks.toast,
}))

vi.mock('../../utils/logger', () => ({
  logger: mocks.logger,
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

describe('CommissionRatePage backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.list.mockResolvedValue([
      {
        id: 'rate-1',
        entityType: 'BRANCH',
        entityName: 'Lista szerinti fiók',
        currencyCode: 'EUR',
        rate: 1.5,
        validFrom: '2026-06-01',
        validTo: '',
        isActive: true,
      },
    ])
    mocks.getById.mockResolvedValue({
      id: 'rate-1',
      entityType: 'WORKER',
      entityName: 'Backend részlet dolgozó',
      currencyCode: 'USD',
      rate: 2.25,
      validFrom: '2026-06-10',
      validTo: '2026-06-30',
      isActive: true,
    })
  })

  it('szerkesztés előtt lekéri a jutalékmérték backend detail reprezentációját', async () => {
    render(<CommissionRatePage />)

    await screen.findByText('Lista szerinti fiók')
    fireEvent.click(screen.getByRole('button', { name: 'common.edit' }))

    await waitFor(() => {
      expect(mocks.getById).toHaveBeenCalledWith('rate-1')
      expect(screen.getByDisplayValue('Backend részlet dolgozó')).toBeInTheDocument()
      expect(screen.getByDisplayValue('USD')).toBeInTheDocument()
      expect(screen.getByDisplayValue('2.25')).toBeInTheDocument()
      expect(screen.getByDisplayValue('2026-06-10')).toBeInTheDocument()
      expect(screen.getByDisplayValue('2026-06-30')).toBeInTheDocument()
    })
  })
})
