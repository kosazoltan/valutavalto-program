import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import SystemParameterPage from './SystemParameterPage'

const mocks = vi.hoisted(() => ({
  list: vi.fn(),
  listManaged: vi.fn(),
  getActive: vi.fn(),
  getByCategory: vi.fn(),
  getByKey: vi.fn(),
  getValue: vi.fn(),
  create: vi.fn(),
  update: vi.fn(),
  remove: vi.fn(),
  toggleActive: vi.fn(),
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

vi.mock('../../services/api/index', () => ({
  systemParameterApi: {
    list: mocks.list,
    listManaged: mocks.listManaged,
    getActive: mocks.getActive,
    getByCategory: mocks.getByCategory,
    getByKey: mocks.getByKey,
    getValue: mocks.getValue,
    create: mocks.create,
    update: mocks.update,
    delete: mocks.remove,
    toggleActive: mocks.toggleActive,
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: { error: vi.fn(), warn: vi.fn(), info: vi.fn() },
}))

describe('SystemParameterPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.list.mockResolvedValue([
      {
        id: 'param-1',
        parameterKey: 'RATE_SPREAD_EUR',
        parameterValue: '4',
        parameterType: 'NUMBER',
        category: 'RATE',
        description: 'EUR spread',
        isActive: true,
        updatedAt: '2026-06-18T10:00:00',
      },
    ])
    mocks.listManaged.mockResolvedValue([
      {
        id: 'managed-param-1',
        parameterKey: 'MANAGED_RATE_SPREAD_EUR',
        parameterValue: '6',
        parameterType: 'NUMBER',
        category: 'RATE',
        description: 'Managed EUR spread',
        isActive: true,
        updatedAt: '2026-06-18T10:00:00',
      },
    ])
    mocks.getActive.mockResolvedValue([
      {
        id: 'active-param-1',
        parameterKey: 'ACTIVE_RATE_SPREAD_EUR',
        parameterValue: '4',
        parameterType: 'NUMBER',
        category: 'RATE',
        description: 'Active EUR spread',
        isActive: true,
        updatedAt: '2026-06-18T10:00:00',
      },
    ])
    mocks.getByCategory.mockResolvedValue([
      {
        id: 'category-param-1',
        parameterKey: 'CATEGORY_RATE_SPREAD_EUR',
        parameterValue: '7',
        parameterType: 'NUMBER',
        category: 'RATE',
        description: 'Backend category result',
        isActive: true,
        updatedAt: '2026-06-18T10:00:00',
      },
    ])
    mocks.getByKey.mockResolvedValue({
      id: 'param-1',
      parameterKey: 'RATE_SPREAD_EUR',
      parameterValue: '4',
      parameterType: 'NUMBER',
      category: 'RATE',
      description: 'EUR spread',
      isActive: true,
      updatedAt: '2026-06-18T10:00:00',
    })
    mocks.getValue.mockResolvedValue('4')
    mocks.update.mockResolvedValue({})
    mocks.create.mockResolvedValue({})
    mocks.remove.mockResolvedValue({})
    mocks.toggleActive.mockResolvedValue({})
  })

  it('meglévő paraméter mentésekor id-alapú backend update API-t hív', async () => {
    const user = userEvent.setup()
    render(<SystemParameterPage />)

    expect(await screen.findByText('RATE_SPREAD_EUR')).toBeInTheDocument()
    await user.click(screen.getByRole('button', { name: /common.edit/i }))
    const valueInput = screen.getByDisplayValue('4')
    await user.clear(valueInput)
    await user.type(valueInput, '5')
    await user.click(screen.getByRole('button', { name: /common.save/i }))

    await waitFor(() => {
      expect(mocks.update).toHaveBeenCalledWith('param-1', {
        parameterValue: '5',
        description: 'EUR spread',
      })
    })
  })

  it('kategória választáskor backend kategória endpointot használ', async () => {
    const user = userEvent.setup()
    render(<SystemParameterPage />)

    expect(await screen.findByText('RATE_SPREAD_EUR')).toBeInTheDocument()
    await user.selectOptions(screen.getByLabelText('common.category'), 'RATE')

    await waitFor(() => {
      expect(mocks.getByCategory).toHaveBeenCalledWith('RATE')
    })
    expect(await screen.findByText('CATEGORY_RATE_SPREAD_EUR')).toBeInTheDocument()
  })

  it('kulcs lekérdezéskor backend getByKey és getValue endpointot használ', async () => {
    const user = userEvent.setup()
    render(<SystemParameterPage />)

    expect(await screen.findByText('RATE_SPREAD_EUR')).toBeInTheDocument()
    await user.type(screen.getByLabelText('settings.kulcsEllenorzes'), 'RATE_SPREAD_EUR')
    await user.click(screen.getByRole('button', { name: /settings.lekerdezes/i }))

    await waitFor(() => {
      expect(mocks.getByKey).toHaveBeenCalledWith('RATE_SPREAD_EUR')
      expect(mocks.getValue).toHaveBeenCalledWith('RATE_SPREAD_EUR')
    })
    expect(screen.getByText('organizations.kulcs2:')).toBeInTheDocument()
    expect(screen.getByText('fees.ertek:')).toBeInTheDocument()
  })
})
