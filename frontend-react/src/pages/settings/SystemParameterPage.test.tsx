import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import SystemParameterPage from './SystemParameterPage'

const mocks = vi.hoisted(() => ({
  list: vi.fn(),
  create: vi.fn(),
  update: vi.fn(),
  remove: vi.fn(),
  toggleActive: vi.fn(),
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({ t: (key: string) => key }),
}))

vi.mock('../../services/api/index', () => ({
  systemParameterApi: {
    list: mocks.list,
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
})
