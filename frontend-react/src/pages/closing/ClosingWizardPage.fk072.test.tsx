import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import ClosingWizardPage from './ClosingWizardPage'

/**
 * FK-072_v2 FR-1: a záró-varázsló "Esti pénztár címletezése" lépésében az 1 alatti
 * névértékű címletsorok EGYÁLTALÁN nem jelenhetnek meg (nem disabled — a sor
 * hiányzik a kirajzolásból). FR-7: az 1 és afölötti (EUR 1/2 is) sorok változatlanok.
 */

const mocks = vi.hoisted(() => ({
  navigate: vi.fn(),
  closingWizardApiStart: vi.fn(),
  closingWizardApiGet: vi.fn(),
  closingWizardApiGetStep: vi.fn(),
  closingWizardApiValidateTransactions: vi.fn(),
  closingWizardApiNavigate: vi.fn(),
  closingWizardApiFinalize: vi.fn(),
  closingWizardApiCancel: vi.fn(),
  closingWizardApiSubmitDenominations: vi.fn(),
  closingWizardApiCalculateDifferences: vi.fn(),
  closingWizardApiGetReport: vi.fn(),
  closingWizardApiGetCurrenciesWithBalance: vi.fn(),
  denominationApiList: vi.fn(),
  currencyApiGetActive: vi.fn(),
  dailySessionApiValidateClosing: vi.fn(),
  toast: {
    success: vi.fn(),
    error: vi.fn(),
    warning: vi.fn(),
    info: vi.fn(),
  },
  useAuthStore: vi.fn(),
}))

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual<typeof import('react-router-dom')>('react-router-dom')
  return {
    ...actual,
    useNavigate: () => mocks.navigate,
  }
})

vi.mock('../../services/api/index', () => ({
  closingWizardApi: {
    start: mocks.closingWizardApiStart,
    get: mocks.closingWizardApiGet,
    getStep: mocks.closingWizardApiGetStep,
    validateTransactions: mocks.closingWizardApiValidateTransactions,
    navigate: mocks.closingWizardApiNavigate,
    finalize: mocks.closingWizardApiFinalize,
    cancel: mocks.closingWizardApiCancel,
    submitDenominations: mocks.closingWizardApiSubmitDenominations,
    calculateDifferences: mocks.closingWizardApiCalculateDifferences,
    getReport: mocks.closingWizardApiGetReport,
    getCurrenciesWithBalance: mocks.closingWizardApiGetCurrenciesWithBalance,
  },
  denominationApi: {
    list: mocks.denominationApiList,
  },
  currencyApi: {
    getActive: mocks.currencyApiGetActive,
  },
  dailySessionApi: {
    validateClosing: mocks.dailySessionApiValidateClosing,
  },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: mocks.toast,
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: mocks.useAuthStore,
}))

vi.mock('../../components/cashier/CashierHeader', () => ({
  CashierHeader: () => <div data-testid="cashier-header">Pénztárvezető: Test</div>,
}))

const cashierWorker = {
  id: 1,
  workerCode: 'AB12',
  firstName: 'Teszt',
  lastName: 'Felhasználó',
  fullName: 'Teszt Felhasználó',
  role: 'CASHIER',
  branchId: 'b1',
  branchCode: 'KORUT',
  branchName: 'Korut',
  companyId: 'c1',
}

const vaultWorker = { ...cashierWorker, role: 'ERTEKTAR' }

/** Címlettörzs: HUF egész sorok + EUR-ban tört (0,5) ÉS egész (50/2/1) sorok. */
const DENOMINATION_MASTER = [
  {
    id: 1,
    currencyId: 2,
    currencyCode: 'HUF',
    faceValue: 20000,
    denominationType: 'BANKNOTE',
    active: true,
  },
  {
    id: 2,
    currencyId: 2,
    currencyCode: 'HUF',
    faceValue: 1000,
    denominationType: 'BANKNOTE',
    active: true,
  },
  {
    id: 3,
    currencyId: 4,
    currencyCode: 'EUR',
    faceValue: 50,
    denominationType: 'BANKNOTE',
    active: true,
  },
  {
    id: 4,
    currencyId: 4,
    currencyCode: 'EUR',
    faceValue: 2,
    denominationType: 'COIN',
    active: true,
  },
  {
    id: 5,
    currencyId: 4,
    currencyCode: 'EUR',
    faceValue: 1,
    denominationType: 'COIN',
    active: true,
  },
  {
    id: 6,
    currencyId: 4,
    currencyCode: 'EUR',
    faceValue: 0.5,
    denominationType: 'COIN',
    active: true,
  },
]

function renderPage(worker: typeof cashierWorker) {
  mocks.useAuthStore.mockImplementation((selector: any) => selector({ worker }))

  render(
    <MemoryRouter initialEntries={['/closing/wizard']}>
      <Routes>
        <Route path="/closing/wizard" element={<ClosingWizardPage />} />
        <Route path="/closing/wizard/:wizardId" element={<ClosingWizardPage />} />
      </Routes>
    </MemoryRouter>,
  )
}

/** Varázsló indítása az 1. lépésen át, amíg a címletezés-blokk megjelenik. */
async function startUntilDenominationStep(worker: typeof cashierWorker) {
  renderPage(worker)
  const user = userEvent.setup()

  const startButton = screen.getByRole('button', { name: /ELLENŐRZÉS INDÍTÁSA/i })
  await user.click(startButton)

  await waitFor(() => {
    expect(screen.getByText(/KITOLTÉS SZUKSÉGES/)).toBeInTheDocument()
  })

  return user
}

/**
 * A címletsor beviteli mezője a sor-label (pl. "20 000") span-je melletti input —
 * label-relatív keresés, hogy a tesztek a sorok számától/sorrendjétől függetlenek
 * legyenek (a tört sor eltüntetése után az indexek eltolódnak).
 */
function denomInputByLabel(label: string): HTMLInputElement {
  const span = screen
    .getAllByText(label)
    .find((el) => el.tagName === 'SPAN' && el.className.includes('w-16'))
  expect(span, `Címletsor-label nem található: ${label}`).toBeTruthy()
  const input = span!.parentElement!.querySelector('input')
  expect(input, `Címletsor-input nem található: ${label}`).toBeTruthy()
  return input as HTMLInputElement
}

describe('ClosingWizardPage — FK-072_v2 tört címletek (FR-1, FR-7)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.closingWizardApiStart.mockResolvedValue({
      id: 'wizard-1',
      branchId: 'b1',
      status: 'IN_PROGRESS',
      steps: [],
      createdAt: new Date().toISOString(),
    })
    mocks.closingWizardApiNavigate.mockResolvedValue({
      steps: [{ stepNumber: 1, completed: true, stepDescription: 'OK' }],
    })
    mocks.closingWizardApiValidateTransactions.mockResolvedValue([])
    mocks.closingWizardApiSubmitDenominations.mockResolvedValue({ total: 100000 })
    mocks.closingWizardApiCalculateDifferences.mockResolvedValue([
      { currencyCode: 'HUF', expected: 100000, actual: 100000, difference: 0, status: 'OK' },
    ])
    mocks.closingWizardApiGetReport.mockResolvedValue({
      wizardId: 'wizard-1',
      branchName: 'Korut',
      closingDate: '2026-08-03',
      closingType: 'DAILY',
      transactionCount: 0,
      inventory: [],
    })
    mocks.dailySessionApiValidateClosing.mockResolvedValue({
      validationDate: '2026-08-03',
      errorCode: 0,
      errorMessage: 'OK',
      allValid: true,
    })
    mocks.closingWizardApiGetCurrenciesWithBalance.mockResolvedValue(['HUF', 'EUR'])
    mocks.denominationApiList.mockResolvedValue(DENOMINATION_MASTER)
    mocks.currencyApiGetActive.mockResolvedValue([
      { id: 2, code: 'HUF', name: 'Forint', decimals: 0, active: true },
      { id: 4, code: 'EUR', name: 'Euró', decimals: 2, active: true },
    ])
  })

  it('FR-1 (pénztár): az 1 alatti névértékű sor (EUR 0,5) egyáltalán nincs a DOM-ban', async () => {
    await startUntilDenominationStep(cashierWorker)

    // A tört sor labelje ("0,5") sehol nem jelenhet meg — se aktív, se disabled mezőként.
    expect(screen.queryByText('0,5')).toBeNull()

    // FR-7: az egész sorok (EUR 50, 2, 1 és a HUF sorok) változatlanul renderelődnek.
    expect(denomInputByLabel('20 000')).toBeInTheDocument()
    expect(denomInputByLabel('50')).toBeInTheDocument()
    expect(denomInputByLabel('2')).toBeInTheDocument()
    expect(denomInputByLabel('1')).toBeInTheDocument()
  })

  it('FR-1 (értéktár): vault-kontextusban is hiányzik a tört sor a kirajzolásból', async () => {
    await startUntilDenominationStep(vaultWorker)

    expect(screen.queryByText('0,5')).toBeNull()
    expect(denomInputByLabel('50')).toBeInTheDocument()
    expect(denomInputByLabel('1')).toBeInTheDocument()
  })

  it('FR-7 regresszió (pénztár): egész címletek kitöltése és beküldése változatlanul működik (EUR 1-gyel)', async () => {
    const user = await startUntilDenominationStep(cashierWorker)

    await user.type(denomInputByLabel('20 000'), '5')
    await user.type(denomInputByLabel('1'), '10')

    await user.click(screen.getByRole('button', { name: /Cimletezés rogzitese/i }))

    await waitFor(() => {
      expect(mocks.closingWizardApiSubmitDenominations).toHaveBeenCalledWith('wizard-1', {
        HUF: { 20000: 5 },
        EUR: { 1: 10 },
      })
    })
  })
})
