import { render, screen } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import DenominationPage from './DenominationPage'

/**
 * FK-072_v2 FR-2: a "Címletezés" menüpont táblázatából az 1 alatti névértékű sorok
 * teljesen hiányozzanak (ma némán renderelődnek és menthetők — a tört sor a
 * formatInteger floor-ja miatt "0 EUR" labellel jelenik meg).
 * FR-7: az 1 és afölötti sorok (EUR 1/2 is) változatlanul megjelennek.
 */

const mocks = vi.hoisted(() => ({
  currencyGetActive: vi.fn(),
  denominationList: vi.fn(),
  denominationGetByCurrencyId: vi.fn(),
  denominationGetByCurrencyCode: vi.fn(),
  denominationGetLowStockAlerts: vi.fn(),
  denominationGetSummary: vi.fn(),
  denominationGetOptimalChange: vi.fn(),
  denominationValidate: vi.fn(),
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
  useAuthStore: (selector: (state: unknown) => unknown) =>
    selector({
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
    list: mocks.denominationList,
    getByCurrencyId: mocks.denominationGetByCurrencyId,
    getByCurrencyCode: mocks.denominationGetByCurrencyCode,
    getLowStockAlerts: mocks.denominationGetLowStockAlerts,
    getSummary: mocks.denominationGetSummary,
    getOptimalChange: mocks.denominationGetOptimalChange,
    validate: mocks.denominationValidate,
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

/** EUR törzs: egész (50, 2, 1) ÉS tört (0,5) címletsor — a tört nem jelenhet meg. */
const EUR_DENOMINATIONS = [
  {
    id: 10,
    currencyId: 1,
    currencyCode: 'EUR',
    faceValue: 50,
    denominationType: 'BANKNOTE',
    quantity: 0,
    active: true,
  },
  {
    id: 11,
    currencyId: 1,
    currencyCode: 'EUR',
    faceValue: 2,
    denominationType: 'COIN',
    quantity: 0,
    active: true,
  },
  {
    id: 12,
    currencyId: 1,
    currencyCode: 'EUR',
    faceValue: 1,
    denominationType: 'COIN',
    quantity: 0,
    active: true,
  },
  {
    id: 13,
    currencyId: 1,
    currencyCode: 'EUR',
    faceValue: 0.5,
    denominationType: 'COIN',
    quantity: 0,
    active: true,
  },
]

describe('DenominationPage — FK-072_v2 tört címletek (FR-2, FR-7)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.currencyGetActive.mockResolvedValue([
      { id: 1, code: 'EUR', name: 'Euró', decimals: 2, active: true },
    ])
    mocks.denominationGetByCurrencyId.mockResolvedValue(EUR_DENOMINATIONS)
    mocks.denominationList.mockResolvedValue(EUR_DENOMINATIONS)
    mocks.denominationGetByCurrencyCode.mockResolvedValue(EUR_DENOMINATIONS)
    mocks.denominationGetLowStockAlerts.mockResolvedValue([])
    mocks.denominationGetSummary.mockResolvedValue({
      currencyId: 1,
      currencyCode: 'EUR',
      currencyName: 'Euró',
      totalValue: 0,
      banknoteCount: 1,
      coinCount: 3,
      denominationCount: 4,
    })
    mocks.denominationGetOptimalChange.mockResolvedValue({})
    mocks.denominationValidate.mockResolvedValue({
      currencyId: 1,
      currencyCode: 'EUR',
      expectedBalance: 0,
      actualBalance: 0,
      difference: 0,
      isValid: true,
    })
    mocks.balancesGetAll.mockResolvedValue([])
    mocks.balancesGetByCurrency.mockResolvedValue([])
    mocks.balancesCalculateTotal.mockResolvedValue(0)
    mocks.suggest.mockResolvedValue({
      currencyCode: 'EUR',
      requestedAmount: 0,
      denominations: {},
      totalAmount: 0,
      remainder: 0,
    })
    mocks.suggestBalanced.mockResolvedValue({
      currencyCode: 'EUR',
      requestedAmount: 0,
      denominations: {},
      totalAmount: 0,
      remainder: 0,
    })
    mocks.listOptimizations.mockResolvedValue([])
    mocks.listRules.mockResolvedValue([])
    mocks.previewSelection.mockResolvedValue(null)
  })

  it('FR-2: az 1 alatti névértékű sor (EUR 0,5) egyáltalán nem kerül a táblázatba', async () => {
    render(<DenominationPage />)

    await screen.findByText('50 EUR')

    // A tört sor ma a formatInteger floor-ja miatt "0 EUR" címkével renderelődik —
    // az elvárt viselkedés szerint a sor EGYÁLTALÁN nincs a DOM-ban.
    expect(screen.queryByText('0 EUR')).toBeNull()
  })

  it('FR-7 regresszió: az egész sorok (EUR 50, 2, 1) változatlanul megjelennek', async () => {
    render(<DenominationPage />)

    await screen.findByText('50 EUR')

    expect(screen.getByText('2 EUR')).toBeInTheDocument()
    expect(screen.getByText('1 EUR')).toBeInTheDocument()
  })
})
