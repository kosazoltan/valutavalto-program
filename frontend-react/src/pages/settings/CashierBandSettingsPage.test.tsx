import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import CashierBandSettingsPage from './CashierBandSettingsPage'

const mocks = vi.hoisted(() => ({
  getManagedByCategory: vi.fn(),
  updateByKey: vi.fn(),
  bulkUpdate: vi.fn(),
  toastSuccess: vi.fn(),
  toastError: vi.fn(),
}))

vi.mock('../../services/api/settings', () => ({
  systemParameterApi: {
    getManagedByCategory: mocks.getManagedByCategory,
    updateByKey: mocks.updateByKey,
    bulkUpdate: mocks.bulkUpdate,
  },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: {
    success: mocks.toastSuccess,
    error: mocks.toastError,
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: { error: vi.fn(), warn: vi.fn(), info: vi.fn() },
}))

describe('CashierBandSettingsPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.getManagedByCategory.mockResolvedValue([
      {
        id: 'param-1',
        parameterKey: 'CASHIER_CUSTOM_RATE_MIN_AMOUNT',
        parameterValue: '400000',
        parameterType: 'NUMBER',
        category: 'TRANSACTION',
        isActive: true,
        updatedAt: '2026-06-18T10:00:00',
      },
      {
        id: 'param-2',
        parameterKey: 'CASHIER_CUSTOM_RATE_DAILY_LIMIT',
        parameterValue: '5',
        parameterType: 'NUMBER',
        category: 'TRANSACTION',
        isActive: true,
        updatedAt: '2026-06-18T10:00:00',
      },
    ])
    mocks.updateByKey.mockResolvedValue({})
    mocks.bulkUpdate.mockResolvedValue({ updated: '2' })
  })

  it('management kategória API-ból tölt és több módosítást bulk API-val ment', async () => {
    const user = userEvent.setup()
    render(<CashierBandSettingsPage />)

    const minAmount = await screen.findByDisplayValue('400000')
    const dailyLimit = screen.getByDisplayValue('5')
    expect(mocks.getManagedByCategory).toHaveBeenCalledWith('TRANSACTION')

    await user.clear(minAmount)
    await user.type(minAmount, '500000')
    await user.clear(dailyLimit)
    await user.type(dailyLimit, '6')
    await user.click(screen.getAllByRole('button', { name: /Mentés/i })[0]!)

    await waitFor(() => {
      expect(mocks.bulkUpdate).toHaveBeenCalledWith({
        CASHIER_CUSTOM_RATE_MIN_AMOUNT: '500000',
        CASHIER_CUSTOM_RATE_DAILY_LIMIT: '6',
      })
    })
    expect(mocks.updateByKey).not.toHaveBeenCalled()
  })
})
