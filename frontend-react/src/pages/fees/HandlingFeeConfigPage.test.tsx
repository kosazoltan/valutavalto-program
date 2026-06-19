import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import HandlingFeeConfigPage from './HandlingFeeConfigPage'

const mocks = vi.hoisted(() => ({
  getConfig: vi.fn(),
  updateConfig: vi.fn(),
  saveBrackets: vi.fn(),
  calculateFee: vi.fn(),
  applyDiscount: vi.fn(),
  listActiveDiscounts: vi.fn(),
  resolveDiscount: vi.fn(),
  loggerError: vi.fn(),
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: unknown) => unknown) =>
    selector({ hasCanonicalRole: () => true }),
}))

vi.mock('../../services/api/settings', () => ({
  handlingFeeConfigApi: {
    get: mocks.getConfig,
    update: mocks.updateConfig,
    saveBrackets: mocks.saveBrackets,
  },
  handlingFeeTransactionApi: {
    calculate: mocks.calculateFee,
    applyDiscount: mocks.applyDiscount,
  },
  discountThresholdApi: {
    listActive: mocks.listActiveDiscounts,
    resolve: mocks.resolveDiscount,
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: {
    error: mocks.loggerError,
  },
}))

const handlingFeeConfig = {
  feeType: 'BRACKET',
  perMilleRate: 5,
  perMilleMaxAmount: null,
  brackets: [
    { bracketOrder: 1, upperLimit: 100000, feeAmount: 500, active: true },
    { bracketOrder: 2, upperLimit: 500000, feeAmount: 1500, active: true },
  ],
}

const activeThreshold = {
  id: 'discount-1',
  code: 'NAGY_OSSZEG',
  name: 'Nagy összeg kedvezmény',
  discountType: 'PERCENT',
  discountValue: 10,
  minTransactionAmount: 500000,
  validFrom: '2026-06-18',
  isActive: true,
}

function renderPage() {
  render(<HandlingFeeConfigPage />)
}

describe('HandlingFeeConfigPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.getConfig.mockResolvedValue(handlingFeeConfig)
    mocks.updateConfig.mockResolvedValue(handlingFeeConfig)
    mocks.saveBrackets.mockResolvedValue(handlingFeeConfig.brackets)
    mocks.listActiveDiscounts.mockResolvedValue([activeThreshold])
    mocks.resolveDiscount.mockResolvedValue({
      hasDiscount: true,
      code: 'NAGY_OSSZEG',
      name: 'Nagy összeg kedvezmény',
      type: 'PERCENT',
      value: 10,
    })
    mocks.calculateFee.mockResolvedValue({
      amount: 5000,
      netFee: 5000,
      feeType: 'TIERED',
      transactionId: null,
      discountPercent: 0,
    })
    mocks.applyDiscount.mockResolvedValue({
      amount: 5000,
      netFee: 4500,
      feeType: 'TIERED',
      transactionId: 123,
      discountPercent: 10,
      discountReason: 'VIP',
    })
  })

  it('betölti és megjeleníti az aktív automatikus díjküszöböket', async () => {
    renderPage()

    await screen.findByText('Automatikus díjkedvezmény küszöbök')

    expect(mocks.getConfig).toHaveBeenCalledTimes(1)
    expect(mocks.listActiveDiscounts).toHaveBeenCalledTimes(1)
    expect(screen.getByText('Aktív backend szabályok: 1')).toBeInTheDocument()
    expect(screen.getByText('NAGY_OSSZEG')).toBeInTheDocument()
    expect(screen.getByText('Nagy összeg kedvezmény')).toBeInTheDocument()
    expect(screen.getByText('500 000 Ft')).toBeInTheDocument()
  })

  it('a próbaösszeggel a DiscountThreshold resolve backend szerződésére hív', async () => {
    const user = userEvent.setup()
    renderPage()

    await screen.findByText('Automatikus díjkedvezmény küszöbök')
    const probeInput = screen.getByLabelText('Próbaösszeg forintban')
    await user.clear(probeInput)
    await user.type(probeInput, '750000')
    await user.click(screen.getByRole('button', { name: 'Küszöb próba' }))

    await waitFor(() => {
      expect(mocks.resolveDiscount).toHaveBeenCalledWith(750000)
    })
    expect(screen.getByText('NAGY_OSSZEG - Nagy összeg kedvezmény')).toBeInTheDocument()
    expect(screen.getByText('Automatikus hatás: 10%')).toBeInTheDocument()
  })

  it('a backend kezelési díj kalkulátor a handling-fees calculate szerződésre hív', async () => {
    const user = userEvent.setup()
    renderPage()

    await screen.findByText('Backend kezelési díj kalkulátor')
    await user.clear(screen.getByLabelText('Kalkulációs összeg forintban'))
    await user.type(screen.getByLabelText('Kalkulációs összeg forintban'), '750000')
    await user.type(screen.getByLabelText('Tranzakció azonosító opcionális'), '123')
    await user.click(screen.getByRole('button', { name: 'Backend díj próba' }))

    await waitFor(() => {
      expect(mocks.calculateFee).toHaveBeenCalledWith({
        hufAmount: 750000,
        transactionId: 123,
      })
    })
    expect(await screen.findByTestId('handling-fee-backend-result')).toHaveTextContent('5000 Ft')
    expect(screen.getByText('TIERED')).toBeInTheDocument()
  })

  it('a backend kezelési díj kedvezmény a handling-fees discount szerződésre hív', async () => {
    const user = userEvent.setup()
    renderPage()

    const feeId = '11111111-1111-1111-1111-111111111111'
    await screen.findByText('Backend kezelési díj kedvezmény')
    await user.type(screen.getByLabelText('Kezelési díj azonosító'), feeId)
    await user.clear(screen.getByLabelText('Kedvezmény százalék'))
    await user.type(screen.getByLabelText('Kedvezmény százalék'), '10')
    await user.type(screen.getByLabelText('Kedvezmény indoklás'), 'VIP')
    await user.click(screen.getByRole('button', { name: 'Kedvezmény alkalmazása' }))

    await waitFor(() => {
      expect(mocks.applyDiscount).toHaveBeenCalledWith(feeId, {
        discountPercent: 10,
        reason: 'VIP',
      })
    })
    const result = await screen.findByTestId('handling-fee-discount-result')
    expect(result).toHaveTextContent('4500 Ft')
    expect(within(result).getByText('10%')).toBeInTheDocument()
  })

  it('a díjsávok külön mentése a handling-fee-config brackets szerződésre hív', async () => {
    const user = userEvent.setup()
    renderPage()

    await screen.findByText('Díjsávok')
    await user.click(screen.getByRole('button', { name: 'Díjsávok mentése' }))

    await waitFor(() => {
      expect(mocks.saveBrackets).toHaveBeenCalledWith(handlingFeeConfig.brackets)
    })
    expect(await screen.findByText('Díjsávok mentve!')).toBeInTheDocument()
  })
})
