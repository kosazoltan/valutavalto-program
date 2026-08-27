import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import ExchangeRateDisplayPage from './ExchangeRateDisplayPage'

const mocks = vi.hoisted(() => ({
  list: vi.fn(),
  updateDisplay: vi.fn(),
  getCurrentRates: vi.fn(),
  toastSuccess: vi.fn(),
  toastWarning: vi.fn(),
  toastError: vi.fn(),
}))

vi.mock('../../services/api/index', () => ({
  exchangeRateDisplayApi: {
    list: mocks.list,
    updateDisplay: mocks.updateDisplay,
    getCurrentRates: mocks.getCurrentRates,
  },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: {
    success: mocks.toastSuccess,
    warning: mocks.toastWarning,
    error: mocks.toastError,
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

describe('ExchangeRateDisplayPage backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.list.mockResolvedValue([
      {
        id: 'display-1',
        displayName: 'Pénztári kijelző',
        currencyIds: '[1,2]',
        refreshInterval: 30,
        isActive: true,
      },
    ])
    mocks.updateDisplay.mockResolvedValue(undefined)
    mocks.getCurrentRates.mockResolvedValue([
      {
        currency: 'EUR',
        buyRate: '390.00',
        sellRate: '402.50',
      },
    ])
  })

  it('szerkesztéskor a backend string currencyIds mezőt nem tömbként kezeli, és stringként menti vissza', async () => {
    render(<ExchangeRateDisplayPage />)

    await screen.findByText('Pénztári kijelző')
    fireEvent.click(screen.getByTitle('Szerkesztés'))

    const currencyInput = screen.getByPlaceholderText('1,2,3,4') as HTMLInputElement
    expect(currencyInput.value).toBe('1,2')

    fireEvent.change(currencyInput, { target: { value: '1,3' } })
    fireEvent.click(screen.getByRole('button', { name: 'Mentés' }))

    await waitFor(() => {
      expect(mocks.updateDisplay).toHaveBeenCalledWith('display-1', {
        displayName: 'Pénztári kijelző',
        currencyIds: '[1,3]',
        refreshInterval: 30,
      })
    })
  })

  it('az előnézet a current-rates service által normalizált backend sorokat jeleníti meg', async () => {
    render(<ExchangeRateDisplayPage />)

    await screen.findByText('Pénztári kijelző')
    fireEvent.click(screen.getByTitle('Előnézet'))

    await waitFor(() => {
      expect(mocks.getCurrentRates).toHaveBeenCalledWith('display-1')
      expect(screen.getByText('display.kijelzoElonezet')).toBeInTheDocument()
      expect(screen.getByText('EUR')).toBeInTheDocument()
      expect(screen.getByText('390.00')).toBeInTheDocument()
      expect(screen.getByText('402.50')).toBeInTheDocument()
    })
  })
})
