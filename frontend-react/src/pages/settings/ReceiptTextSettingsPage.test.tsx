import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import ReceiptTextSettingsPage from './ReceiptTextSettingsPage'

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

describe('ReceiptTextSettingsPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.getManagedByCategory.mockResolvedValue([
      {
        id: 'param-1',
        parameterKey: 'RECEIPT_BANK_PARTNER_NAME',
        parameterValue: 'Raiffeisen Bank Zrt.',
        parameterType: 'STRING',
        category: 'RECEIPT',
        isActive: true,
        updatedAt: '2026-06-18T10:00:00',
      },
    ])
    mocks.updateByKey.mockResolvedValue({})
    mocks.bulkUpdate.mockResolvedValue({ updated: '2' })
  })

  it('management kategória API-ból tölt és egy módosítást kulcs alapján ment', async () => {
    const user = userEvent.setup()
    render(<ReceiptTextSettingsPage />)

    const input = await screen.findByDisplayValue('Raiffeisen Bank Zrt.')
    expect(mocks.getManagedByCategory).toHaveBeenCalledWith('RECEIPT')

    await user.clear(input)
    await user.type(input, 'Teszt Bank Zrt.')
    await user.click(screen.getAllByRole('button', { name: /Mentés/i })[0]!)

    await waitFor(() => {
      expect(mocks.updateByKey).toHaveBeenCalledWith('RECEIPT_BANK_PARTNER_NAME', {
        value: 'Teszt Bank Zrt.',
      })
    })
    expect(mocks.bulkUpdate).not.toHaveBeenCalled()
  })
})
