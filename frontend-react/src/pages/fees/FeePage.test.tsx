import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import FeePage from './FeePage'

const mocks = vi.hoisted(() => ({
  getTypes: vi.fn(),
  deleteType: vi.fn(),
  getRates: vi.fn(),
  deleteRate: vi.fn(),
  getDiscounts: vi.fn(),
  deleteDiscount: vi.fn(),
  confirm: vi.fn(),
  loggerError: vi.fn(),
}))

vi.mock('../../services/api/index', () => ({
  feeApi: {
    getTypes: mocks.getTypes,
    createType: vi.fn(),
    updateType: vi.fn(),
    deleteType: mocks.deleteType,
    getRates: mocks.getRates,
    createRate: vi.fn(),
    updateRate: vi.fn(),
    deleteRate: mocks.deleteRate,
    getDiscounts: mocks.getDiscounts,
    createDiscount: vi.fn(),
    updateDiscount: vi.fn(),
    deleteDiscount: mocks.deleteDiscount,
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: {
    error: mocks.loggerError,
  },
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => (key === 'common.delete' ? 'Törlés' : key) }),
}))

describe('FeePage delete backend contracts', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.stubGlobal('confirm', mocks.confirm)
    mocks.confirm.mockReturnValue(true)
    mocks.getTypes.mockResolvedValue([
      {
        id: 'fee-type-1',
        code: 'HANDLING',
        name: 'Kezelési díj',
        calculationMethod: 'FIXED',
        isActive: true,
      },
    ])
    mocks.getRates.mockResolvedValue([
      {
        id: 'fee-rate-1',
        feeTypeId: 'fee-type-1',
        feeTypeName: 'Kezelési díj',
        currencyCode: 'EUR',
        rate: 1.5,
        validFrom: '2026-01-01',
        isActive: true,
      },
    ])
    mocks.getDiscounts.mockResolvedValue([
      {
        id: 'fee-discount-1',
        code: 'VIP',
        name: 'VIP kedvezmény',
        discountType: 'PERCENT',
        discountValue: 10,
        validFrom: '2026-01-01',
        isActive: true,
      },
    ])
    mocks.deleteType.mockResolvedValue(undefined)
    mocks.deleteRate.mockResolvedValue(undefined)
    mocks.deleteDiscount.mockResolvedValue(undefined)
  })

  it('díjtípus törléskor a DELETE /fees/types/{id} wrappert hívja', async () => {
    render(<FeePage />)

    await screen.findByText('Kezelési díj')
    fireEvent.click(screen.getByRole('button', { name: /Törlés/i }))

    await waitFor(() => {
      expect(mocks.deleteType).toHaveBeenCalledWith('fee-type-1')
    })
    expect(mocks.confirm).toHaveBeenCalledWith('Biztosan törli a kiválasztott díjbeállítást?')
  })

  it('díjmérték törléskor a DELETE /fees/rates/{id} wrappert hívja', async () => {
    render(<FeePage />)

    fireEvent.click(await screen.findByRole('button', { name: 'Díj mértékek' }))
    await screen.findByText('EUR')
    fireEvent.click(screen.getByRole('button', { name: /Törlés/i }))

    await waitFor(() => {
      expect(mocks.deleteRate).toHaveBeenCalledWith('fee-rate-1')
    })
  })

  it('kedvezmény törléskor a DELETE /fees/discounts/{id} wrappert hívja', async () => {
    render(<FeePage />)

    fireEvent.click(await screen.findByRole('button', { name: 'Kedvezmények' }))
    await screen.findByText('VIP kedvezmény')
    fireEvent.click(screen.getByRole('button', { name: /Törlés/i }))

    await waitFor(() => {
      expect(mocks.deleteDiscount).toHaveBeenCalledWith('fee-discount-1')
    })
  })
})
