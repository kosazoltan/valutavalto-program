import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import DenominationPage from './DenominationPage'

const mocks = vi.hoisted(() => ({
  currencyGetActive: vi.fn(),
  denominationGetByCurrencyId: vi.fn(),
  balancesGetAll: vi.fn(),
  balancesGetByCurrency: vi.fn(),
  balancesCalculateTotal: vi.fn(),
  balancesSetQuantities: vi.fn(),
  suggest: vi.fn(),
  suggestBalanced: vi.fn(),
  listOptimizations: vi.fn(),
  listRules: vi.fn(),
  createOptimization: vi.fn(),
  updateOptimization: vi.fn(),
  createRule: vi.fn(),
  deleteRule: vi.fn(),
  previewSelection: vi.fn(),
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string) => key,
  }),
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: unknown) => unknown) => selector({
    worker: {
      branchId: 'branch-1',
      role: 'ADMIN',
    },
    activeRole: 'ADMIN',
  }),
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: {
    success: vi.fn(),
    warning: vi.fn(),
    error: vi.fn(),
  },
}))

vi.mock('../../services/api/index', () => ({
  currencyApi: {
    getActive: mocks.currencyGetActive,
  },
  denominationApi: {
    getByCurrencyId: mocks.denominationGetByCurrencyId,
  },
  denominationBalanceApi: {
    getCashDeskDenominations: mocks.balancesGetAll,
    getCashDeskDenominationsByCurrency: mocks.balancesGetByCurrency,
    calculateTotalFromDenominations: mocks.balancesCalculateTotal,
    setDenominationQuantities: mocks.balancesSetQuantities,
  },
  denominationCalculatorApi: {
    suggest: mocks.suggest,
    suggestBalanced: mocks.suggestBalanced,
  },
  denominationOptimizationApi: {
    listOptimizations: mocks.listOptimizations,
    listRules: mocks.listRules,
    createOptimization: mocks.createOptimization,
    updateOptimization: mocks.updateOptimization,
    createRule: mocks.createRule,
    deleteRule: mocks.deleteRule,
    previewSelection: mocks.previewSelection,
  },
}))

describe('DenominationPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.currencyGetActive.mockResolvedValue([
      { id: 1, code: 'EUR', name: 'Euró', decimals: 2, active: true },
    ])
    mocks.denominationGetByCurrencyId.mockResolvedValue([
      { id: 10, currencyId: 1, currencyCode: 'EUR', faceValue: 50, denominationType: 'BANKNOTE', quantity: 0, active: true },
      { id: 11, currencyId: 1, currencyCode: 'EUR', faceValue: 20, denominationType: 'BANKNOTE', quantity: 0, active: true },
      { id: 12, currencyId: 1, currencyCode: 'EUR', faceValue: 10, denominationType: 'BANKNOTE', quantity: 0, active: true },
    ])
    mocks.balancesGetAll.mockResolvedValue([
      { denominationId: '10', currencyCode: 'EUR', quantity: 2, totalValue: 100 },
      { denominationId: '11', currencyCode: 'EUR', quantity: 1, totalValue: 20 },
    ])
    mocks.balancesGetByCurrency.mockResolvedValue([
      { denominationId: '10', quantity: 2, totalValue: 100 },
      { denominationId: '11', quantity: 1, totalValue: 20 },
    ])
    mocks.balancesCalculateTotal.mockResolvedValue(120)
    mocks.suggest.mockResolvedValue({
      currencyCode: 'EUR',
      requestedAmount: 130,
      denominations: { '50': 2, '20': 1, '10': 1 },
      totalAmount: 130,
      remainder: 0,
    })
    mocks.suggestBalanced.mockResolvedValue({
      currencyCode: 'EUR',
      requestedAmount: 130,
      denominations: { '50': 1, '20': 3, '10': 2 },
      totalAmount: 130,
      remainder: 0,
    })
    mocks.listOptimizations.mockResolvedValue([
      {
        id: 'opt-1',
        name: 'Alap mohó stratégia',
        strategy: 'GREEDY',
        isDefault: true,
        isActive: true,
      },
    ])
    mocks.listRules.mockResolvedValue([
      {
        id: 'rule-1',
        ruleName: 'Nagy összegű EUR',
        currencyId: 1,
        ruleType: 'AMOUNT_BASED',
        minAmount: 1_000_000,
        maxAmount: null,
        branchId: null,
        optimization: {
          id: 'opt-1',
          name: 'Alap mohó stratégia',
          strategy: 'GREEDY',
          isDefault: true,
          isActive: true,
        },
        priority: 10,
        isActive: true,
      },
    ])
    mocks.previewSelection.mockResolvedValue({
      strategy: 'GREEDY',
      ruleId: 'rule-1',
      ruleName: 'Nagy összegű EUR',
      optimizationName: 'Alap mohó stratégia',
      source: 'RULE_MATCH',
    })
    mocks.createOptimization.mockResolvedValue({
      id: 'opt-2',
      name: 'Mobil stratégia',
      strategy: 'MIN_TOTAL',
      isDefault: false,
      isActive: true,
    })
    mocks.updateOptimization.mockResolvedValue({
      id: 'opt-1',
      name: 'Frissített stratégia',
      strategy: 'GREEDY',
      isDefault: true,
      isActive: true,
    })
    mocks.createRule.mockResolvedValue({
      id: 'rule-2',
      ruleName: 'Mobil szabály',
      currencyId: 1,
      ruleType: 'AMOUNT_BASED',
      minAmount: 500000,
      branchId: 'branch-1',
      priority: 25,
      isActive: true,
    })
    mocks.deleteRule.mockResolvedValue(undefined)
  })

  it('backend címletkalkulátor javaslatából tölti a darabszámokat', async () => {
    render(<DenominationPage />)

    await screen.findByText('50 EUR')
    expect(mocks.balancesGetAll).toHaveBeenCalledWith('branch-1')
    expect(mocks.balancesCalculateTotal).toHaveBeenCalledWith('branch-1', '1')
    expect(screen.getByText('120,00')).toBeInTheDocument()
    expect(screen.getAllByText('2')).toHaveLength(2)
    fireEvent.change(screen.getByPlaceholderText('Összeg EUR'), { target: { value: '130' } })
    fireEvent.click(screen.getByText('Javaslat alkalmazása'))

    await waitFor(() => {
      expect(mocks.suggest).toHaveBeenCalledWith('EUR', 130)
      expect(screen.getByDisplayValue('2')).toBeInTheDocument()
      expect(screen.getAllByDisplayValue('1')).toHaveLength(2)
      expect(screen.getByText('Címletjavaslat alkalmazva.')).toBeInTheDocument()
    })
  })

  it('készletfigyelő címletjavaslatnál az aktuális darabszámokat küldi a backendnek', async () => {
    mocks.balancesGetByCurrency.mockResolvedValue([
      { denominationId: '10', quantity: 6 },
      { denominationId: '11', quantity: 4 },
      { denominationId: '12', quantity: 2 },
    ])

    render(<DenominationPage />)

    await screen.findByText('50 EUR')
    fireEvent.change(screen.getByPlaceholderText('Összeg EUR'), { target: { value: '130' } })
    fireEvent.click(screen.getByLabelText('Készletfigyelő algoritmus az aktuális darabszámokkal'))
    fireEvent.click(screen.getByText('Javaslat alkalmazása'))

    await waitFor(() => {
      expect(mocks.suggestBalanced).toHaveBeenCalledWith({
        currencyCode: 'EUR',
        amount: 130,
        availableStock: { '50': 6, '20': 4, '10': 2 },
      })
      expect(screen.getByText('Készletfigyelő címletjavaslat alkalmazva.')).toBeInTheDocument()
    })
  })

  it('megjeleníti és teszteli a backend címletezési szabálymotort', async () => {
    render(<DenominationPage />)

    await screen.findByText('Címletezési szabálymotor')

    expect(mocks.listOptimizations).toHaveBeenCalled()
    expect(mocks.listRules).toHaveBeenCalled()
    expect(screen.getAllByText('Alap mohó stratégia').length).toBeGreaterThan(0)
    expect(screen.getByText('Nagy összegű EUR')).toBeInTheDocument()

    fireEvent.change(screen.getByPlaceholderText('HUF összeg'), { target: { value: '1000000' } })
    fireEvent.click(screen.getByText('Teszt'))

    await waitFor(() => {
      expect(mocks.previewSelection).toHaveBeenCalledWith({
        branchId: 'branch-1',
        currencyId: 1,
        hufAmount: 1_000_000,
      })
      expect(screen.getByText('RULE_MATCH')).toBeInTheDocument()
    })
  })

  it('admin nézetből beköti a címletezési stratégia és szabály módosító backend műveleteket', async () => {
    render(<DenominationPage />)

    await screen.findByText('Stratégia szerkesztése')

    fireEvent.change(screen.getByPlaceholderText('Stratégianév'), { target: { value: 'Mobil stratégia' } })
    fireEvent.change(screen.getByLabelText('Optimalizációs algoritmus'), { target: { value: 'MIN_TOTAL' } })
    fireEvent.click(screen.getByRole('button', { name: 'Stratégia mentése' }))

    await waitFor(() => {
      expect(mocks.createOptimization).toHaveBeenCalledWith({
        name: 'Mobil stratégia',
        description: null,
        strategy: 'MIN_TOTAL',
        priorityOrderJson: null,
        minCoins: false,
        minBanknotes: false,
        minTotalCount: false,
        isDefault: false,
      })
    })

    fireEvent.change(screen.getByLabelText('Címletezési stratégia kiválasztása'), { target: { value: 'opt-1' } })
    fireEvent.change(screen.getByPlaceholderText('Stratégianév'), { target: { value: 'Frissített stratégia' } })
    fireEvent.click(screen.getByRole('button', { name: 'Stratégia mentése' }))

    await waitFor(() => {
      expect(mocks.updateOptimization).toHaveBeenCalledWith('opt-1', expect.objectContaining({
        name: 'Frissített stratégia',
        strategy: 'GREEDY',
      }))
    })

    fireEvent.change(screen.getByPlaceholderText('Szabálynév'), { target: { value: 'Mobil szabály' } })
    fireEvent.change(screen.getByLabelText('Szabály stratégiája'), { target: { value: 'opt-1' } })
    fireEvent.change(screen.getByPlaceholderText('Min. HUF'), { target: { value: '500000' } })
    fireEvent.change(screen.getByPlaceholderText('Prioritás'), { target: { value: '25' } })
    fireEvent.click(screen.getByRole('button', { name: 'Szabály létrehozása' }))

    await waitFor(() => {
      expect(mocks.createRule).toHaveBeenCalledWith({
        ruleName: 'Mobil szabály',
        currencyId: 1,
        ruleType: 'AMOUNT_BASED',
        minAmount: 500000,
        maxAmount: null,
        branchId: 'branch-1',
        optimizationId: 'opt-1',
        ruleConfigJson: null,
        priority: 25,
      })
    })

    fireEvent.click(screen.getByRole('button', { name: 'Inaktiválás' }))

    await waitFor(() => {
      expect(mocks.deleteRule).toHaveBeenCalledWith('rule-1')
    })
  })
})
