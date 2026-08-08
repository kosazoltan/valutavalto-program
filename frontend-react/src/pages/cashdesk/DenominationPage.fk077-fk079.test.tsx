import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import DenominationPage from './DenominationPage'

/**
 * FK-077 FR-3 — a Címletezés oldal csendes kiürülésének javítása:
 *   egyetlen sikertelen hívás ne ürítse ki az oldalt, és a felhasználó lásson
 *   magyar nyelvű hibaüzenetet.
 *
 * FK-079 FR-1/FR-2/FR-3 — tört címlet kizárása a Címletjavaslat és a Mentés útról,
 *   valamint a Számított összegből (FK-072 v2 render-szűrésének teljes lezárása).
 *   FR-4 regresszió: az egész névértékű sorok (EUR 1/2 is) változatlanul mennek.
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
  useTranslation: () => ({ t: (key: string) => key }),
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: unknown) => unknown) =>
    selector({
      worker: { branchId: 'branch-1', role: 'ADMIN' },
      activeRole: 'ADMIN',
    }),
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: { success: vi.fn(), warning: vi.fn(), error: vi.fn() },
}))

vi.mock('../../services/api/index', () => ({
  currencyApi: { getActive: mocks.currencyGetActive },
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

/** EUR törzs: egész (50, 2, 1) ÉS tört (0,5 és 0,2) sorok. */
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
  {
    id: 14,
    currencyId: 1,
    currencyCode: 'EUR',
    faceValue: 0.2,
    denominationType: 'COIN',
    quantity: 0,
    active: true,
  },
]

function primeHappyPath() {
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
    coinCount: 4,
    denominationCount: 5,
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
  mocks.balancesSetQuantities.mockResolvedValue([])
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
}

beforeEach(() => {
  vi.clearAllMocks()
  primeHappyPath()
})

describe('FK-077 FR-3 — a betöltés egyetlen hibája nem üríti ki csendben az oldalt', () => {
  it('403/404 az egyik hívásban: a sikeres adatok megjelennek, ÉS látszik magyar hibaüzenet', async () => {
    // A pénztárgép-egyenleg lekérdezés bukik (ez az FR-2 guard tipikus 404-e),
    // a címlettörzs viszont sikeres.
    mocks.balancesGetByCurrency.mockRejectedValue(new Error('Pénztár nem található: branch-1'))

    render(<DenominationPage />)

    // A törzs-sorok NEM tűnnek el (a régi Promise.all-nál az egész oldal kiürült).
    expect(await screen.findByText('50 EUR')).toBeInTheDocument()
    expect(screen.getByText('2 EUR')).toBeInTheDocument()

    const alert = await screen.findByTestId('denomination-load-error')
    expect(alert).toHaveTextContent('nem tölthető be')
  })

  it('minden hívás sikeres: nincs hibaüzenet (FR-4 regresszió)', async () => {
    render(<DenominationPage />)

    await screen.findByText('50 EUR')
    expect(screen.queryByTestId('denomination-load-error')).toBeNull()
  })
})

describe('FK-079 — tört címlet kizárása a javaslat / mentés / összeg útról', () => {
  it('FR-1: a Címletjavaslat tört névértékű sorhoz nem oszt ki mennyiséget', async () => {
    // A backend javaslata SZÁNDÉKOSAN tartalmaz tört névértéket (§2 OUT: a backend
    // válaszát nem módosítjuk, kizárólag a frontend nem alkalmazhatja).
    mocks.suggest.mockResolvedValue({
      currencyCode: 'EUR',
      requestedAmount: 3.7,
      denominations: { '2': 1, '1': 1, '0.5': 1, '0.2': 1 },
      totalAmount: 3.7,
      remainder: 0,
    })

    const user = userEvent.setup()
    render(<DenominationPage />)
    await screen.findByText('50 EUR')

    const amountInput = screen.getByPlaceholderText('Összeg EUR')
    await user.clear(amountInput)
    await user.type(amountInput, '3.7')
    await user.click(screen.getByRole('button', { name: /Javaslat alkalmazása/i }))

    await waitFor(() => expect(mocks.suggest).toHaveBeenCalled())

    // Az egész sorok megkapják a javaslatot…
    await waitFor(() => {
      expect(screen.getByTestId('denomination-qty-11')).toHaveValue('1')
      expect(screen.getByTestId('denomination-qty-12')).toHaveValue('1')
    })
    // …a tört sorok nem is renderelődnek, tehát mennyiséget sem kaphatnak.
    expect(screen.queryByTestId('denomination-qty-13')).toBeNull()
    expect(screen.queryByTestId('denomination-qty-14')).toBeNull()
  })

  it('FR-2: a Mentés payloadjában nincs tört névértékű sor, még ha a state tartalmazna is ilyet', async () => {
    // Korábbi mentésből visszatöltött, tört sorhoz tartozó NEM-NULLA mennyiség.
    mocks.balancesGetByCurrency.mockResolvedValue([
      {
        id: 'b1',
        cashDeskId: 'branch-1',
        denominationId: '13',
        denominationValue: 0.5,
        denominationType: 'COIN',
        currencyCode: 'EUR',
        quantity: 7,
        totalValue: 3.5,
      },
      {
        id: 'b2',
        cashDeskId: 'branch-1',
        denominationId: '11',
        denominationValue: 2,
        denominationType: 'COIN',
        currencyCode: 'EUR',
        quantity: 3,
        totalValue: 6,
      },
    ])

    const user = userEvent.setup()
    render(<DenominationPage />)
    await screen.findByText('50 EUR')

    await user.click(screen.getByRole('button', { name: 'common.save' }))

    await waitFor(() => expect(mocks.balancesSetQuantities).toHaveBeenCalled())
    const [, updates] = mocks.balancesSetQuantities.mock.calls[0] as [
      string,
      Array<{ denominationId: string; quantity: number }>,
    ]
    const sentIds = updates.map((u) => u.denominationId)
    expect(sentIds).not.toContain('13')
    expect(sentIds).not.toContain('14')
    // FR-4 regresszió: az egész sorok (EUR 2 érme is) változatlanul mennek, a 0 is.
    expect(sentIds).toContain('11')
    expect(sentIds).toContain('12')
    expect(sentIds).toContain('10')
    expect(updates.find((u) => u.denominationId === '11')?.quantity).toBe(3)
  })

  it('FR-3: a Számított összeg csak a látható (egész névértékű) sorokból számol', async () => {
    mocks.balancesGetByCurrency.mockResolvedValue([
      // 0,5 × 7 = 3,5 — ez NEM számíthat bele.
      {
        id: 'b1',
        cashDeskId: 'branch-1',
        denominationId: '13',
        denominationValue: 0.5,
        denominationType: 'COIN',
        currencyCode: 'EUR',
        quantity: 7,
        totalValue: 3.5,
      },
      // 2 × 3 = 6 — ez igen.
      {
        id: 'b2',
        cashDeskId: 'branch-1',
        denominationId: '11',
        denominationValue: 2,
        denominationType: 'COIN',
        currencyCode: 'EUR',
        quantity: 3,
        totalValue: 6,
      },
    ])

    render(<DenominationPage />)
    await screen.findByText('50 EUR')

    const total = await screen.findByTestId('denomination-calculated-total')
    // 6, nem 9,5 — a tört sor kimarad.
    await waitFor(() => expect(total).toHaveTextContent('6'))
    expect(total).not.toHaveTextContent('9')
  })
})
