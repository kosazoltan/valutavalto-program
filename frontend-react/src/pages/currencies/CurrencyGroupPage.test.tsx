import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import CurrencyGroupPage from './CurrencyGroupPage'

const mocks = vi.hoisted(() => ({
  list: vi.fn(),
  getById: vi.fn(),
  create: vi.fn(),
  update: vi.fn(),
  remove: vi.fn(),
  logger: {
    error: vi.fn(),
  },
}))

vi.mock('../../services/api/index', () => ({
  currencyGroupApi: {
    list: mocks.list,
    getById: mocks.getById,
    create: mocks.create,
    update: mocks.update,
    remove: mocks.remove,
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: mocks.logger,
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

describe('CurrencyGroupPage backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.list.mockResolvedValue([
      {
        id: 'group-1',
        code: 'LIST',
        name: 'Lista szerinti valutacsoport',
        description: 'Lista leírás',
        currencyIds: '[1]',
        isActive: true,
      },
    ])
    mocks.getById.mockResolvedValue({
      id: 'group-1',
      code: 'DETAIL',
      name: 'Backend részlet valutacsoport',
      description: 'Backend részlet leírás',
      currencyIds: '[1,2,3]',
      isActive: false,
    })
  })

  it('szerkesztés előtt lekéri a valutacsoport backend detail reprezentációját', async () => {
    render(<CurrencyGroupPage />)

    await screen.findByText('Lista szerinti valutacsoport')
    fireEvent.click(screen.getByTitle('Szerkesztés'))

    await waitFor(() => {
      expect(mocks.getById).toHaveBeenCalledWith('group-1')
      expect(screen.getByDisplayValue('DETAIL')).toBeInTheDocument()
      expect(screen.getByDisplayValue('Backend részlet valutacsoport')).toBeInTheDocument()
      expect(screen.getByDisplayValue('Backend részlet leírás')).toBeInTheDocument()
      expect(screen.getByDisplayValue('[1,2,3]')).toBeInTheDocument()
    })
  })
})
