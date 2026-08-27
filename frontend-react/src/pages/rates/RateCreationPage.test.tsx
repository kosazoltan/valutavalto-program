import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { saveGroupFormulas } from './workgroupSheetStorage'

const apiMocks = vi.hoisted(() => ({
  getLocalRateMakerBootstrap: vi.fn(),
  getLocalRateMakerSheet: vi.fn(),
  putLocalRateMakerSheet: vi.fn(),
}))

const publishMocks = vi.hoisted(() => ({
  publishAllWorkgroups: vi.fn(),
  summarizePublishAll: vi.fn(),
}))

const toastMocks = vi.hoisted(() => ({
  success: vi.fn(),
  error: vi.fn(),
  warning: vi.fn(),
  info: vi.fn(),
}))

vi.mock('../../services/api/index', () => ({
  rateCreationApi: {
    getLocalRateMakerBootstrap: apiMocks.getLocalRateMakerBootstrap,
    getLocalRateMakerSheet: apiMocks.getLocalRateMakerSheet,
    putLocalRateMakerSheet: apiMocks.putLocalRateMakerSheet,
    getOverview: vi.fn(),
    getWorkgroupDetails: vi.fn(),
    prepareRateCreation: vi.fn(),
    prepareAllCurrencies: vi.fn(),
    updateWorkgroupLimits: vi.fn(),
    getBranches: vi.fn(),
    updateWorkgroupBranches: vi.fn(),
  },
  rateWorkgroupApi: {
    create: vi.fn(),
    update: vi.fn(),
    remove: vi.fn(),
  },
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))
vi.mock('react-router-dom', () => ({ useNavigate: () => vi.fn() }))
vi.mock('../../stores/authStore', () => ({
  useAuthStore: Object.assign(
    (selector: (state: unknown) => unknown) =>
      selector({ hasRole: vi.fn(() => true), hasCanonicalRole: vi.fn(() => true) }),
    { getState: () => ({ logout: vi.fn() }) },
  ),
}))
vi.mock('../../components/ui/toaster', () => ({
  toast: toastMocks,
}))
vi.mock('../../utils/logger', () => ({
  logger: { error: vi.fn(), info: vi.fn(), warn: vi.fn(), debug: vi.fn() },
}))
vi.mock('./publishAllWorkgroups', () => ({
  publishAllWorkgroups: publishMocks.publishAllWorkgroups,
  summarizePublishAll: publishMocks.summarizePublishAll,
}))
vi.mock('./components/RateGrid', () => ({
  default: ({
    onCommitCell,
    rates = [],
    validationErrors = {},
    cellErrors = {},
  }: {
    onCommitCell?: (index: number, field: 'buyRate', raw: string) => void
    rates?: Array<{ buyRate: string; sellRate: string }>
    validationErrors?: Record<number, string[]>
    cellErrors?: Record<string, string>
  }) => (
    <div data-testid="rate-grid-stub">
      <button type="button" onClick={() => onCommitCell?.(0, 'buyRate', '405')}>
        EUR vétel commit
      </button>
      <div data-testid="current-buy">{rates[0]?.buyRate}</div>
      <div data-testid="current-sell">{rates[0]?.sellRate}</div>
      <div data-testid="validation-errors">{JSON.stringify(validationErrors)}</div>
      <div data-testid="cell-errors">{JSON.stringify(cellErrors)}</div>
    </div>
  ),
}))
vi.mock('./components/BranchPickerModal', () => ({ default: () => null }))

const overview = {
  generatedAt: '2026-07-16T10:00:00.000Z',
  currencies: [
    {
      currencyId: 1,
      currencyCode: 'EUR',
      currencyName: 'Euró',
      displayOrder: 1,
      currentBuyRate: 395,
      currentSellRate: 420,
      officialRate: 400,
      limit1Amount: 50000,
      limit1BuyRate: null,
      limit1SellRate: null,
      limit2Amount: 300000,
      limit2BuyRate: null,
      limit2SellRate: null,
      limit3Amount: 1000000,
      limit3BuyRate: null,
      limit3SellRate: null,
      buyMarginPercent: null,
      sellMarginPercent: null,
      spreadPercent: null,
      middleRate: 400,
      lastUpdated: null,
      hasRate: true,
    },
  ],
}

function workgroup(protectionEnabled: boolean) {
  return {
    id: 'wg-1',
    code: 'WG01',
    name: 'Budapest központ',
    legacyGroupNumber: 1,
    active: true,
    branches: [],
    limit1Boundary: 50000,
    limit2Boundary: 300000,
    limit3Boundary: 1000000,
    tileColor: 'sky',
    protectionEnabled,
  }
}

async function renderEditor(protectionEnabled: boolean, overviewData = overview) {
  apiMocks.getLocalRateMakerBootstrap.mockResolvedValue({
    overview: overviewData,
    workgroups: [workgroup(protectionEnabled)],
  })
  const Page = (await import('./RateCreationPage')).default
  render(<Page />)
  fireEvent.click(
    await screen.findByRole('button', {
      name: /Budapest központ.*árfolyamlap megnyitása/i,
    }),
  )
  await screen.findByTestId('rate-grid-stub')
}

const overviewWithSellRate = (currentSellRate: number) => ({
  ...overview,
  currencies: overview.currencies.map((item) => ({ ...item, currentSellRate })),
})

async function refreshAndReopenEditor() {
  fireEvent.click(screen.getByRole('button', { name: 'Csempés nézet' }))
  const refreshButton = await screen.findByTitle('Frissítés')
  fireEvent.click(refreshButton)
  await waitFor(() => expect(refreshButton).not.toBeDisabled())
  fireEvent.click(
    await screen.findByRole('button', {
      name: /Budapest központ.*árfolyamlap megnyitása/i,
    }),
  )
  await screen.findByTestId('rate-grid-stub')
}

describe('RateCreationPage folyamatos árfolyamvédelmi validáció', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.stubEnv('VITE_APP_FLAVOR', 'rate-maker')
    localStorage.clear()
    apiMocks.getLocalRateMakerSheet.mockResolvedValue(null)
    apiMocks.putLocalRateMakerSheet.mockResolvedValue({ version: 1 })
  })

  it('védett munkacsoportban cella-commit után azonnal jelzi az L vétel > J hibát', async () => {
    await renderEditor(true)

    expect(screen.getByTestId('validation-errors')).toHaveTextContent('{}')
    fireEvent.click(screen.getByRole('button', { name: 'EUR vétel commit' }))

    await waitFor(() =>
      expect(screen.getByTestId('validation-errors')).toHaveTextContent(
        '1-es csoport EUR L vétel nem lehet magasabb az elszámolónál (405 > 400).',
      ),
    )
  })

  it('kikapcsolt védelemnél ugyanaz a cella-commit nem jelez védelmi hibát', async () => {
    await renderEditor(false)

    fireEvent.click(screen.getByRole('button', { name: 'EUR vétel commit' }))

    await waitFor(() => expect(screen.getByTestId('current-buy')).toHaveTextContent('405'))
    expect(screen.getByTestId('validation-errors')).toHaveTextContent('{}')
  })

  describe('FK10 — 0-s lap kontextus frissítése', () => {
    it('FR-4: Frissítés után a 0-s lap kontextus újratöltődik és újraszámol', async () => {
      localStorage.setItem(
        'arfolyamkeszito.mainSheet.v1',
        JSON.stringify([{ currency: 'EUR', weakMultiSell: 405 }]),
      )
      saveGroupFormulas('wg-1', { '1.sellRate': 'F' })
      await renderEditor(false, overviewWithSellRate(405))
      await waitFor(() => expect(screen.getByTestId('current-sell')).not.toHaveTextContent(''))
      const before = screen.getByTestId('current-sell').textContent

      localStorage.setItem(
        'arfolyamkeszito.mainSheet.v1',
        JSON.stringify([{ currency: 'EUR', weakMultiSell: 0 }]),
      )
      await refreshAndReopenEditor()

      await waitFor(() =>
        expect(screen.getByTestId('cell-errors')).toHaveTextContent(
          'Nincs érték a 0-s lap F oszlopában',
        ),
      )
      expect(screen.getByTestId('current-sell')).toHaveTextContent(before!)
    })

    it('edge: két egymás utáni Frissítés stabil', async () => {
      localStorage.setItem(
        'arfolyamkeszito.mainSheet.v1',
        JSON.stringify([{ currency: 'EUR', weakMultiSell: 405 }]),
      )
      saveGroupFormulas('wg-1', { '1.sellRate': 'F' })
      await renderEditor(false, overviewWithSellRate(405))
      await waitFor(() => expect(screen.getByTestId('current-sell')).not.toHaveTextContent(''))

      localStorage.setItem(
        'arfolyamkeszito.mainSheet.v1',
        JSON.stringify([{ currency: 'EUR', weakMultiSell: 0 }]),
      )
      await refreshAndReopenEditor()
      await waitFor(() =>
        expect(screen.getByTestId('cell-errors')).toHaveTextContent(
          'Nincs érték a 0-s lap F oszlopában',
        ),
      )
      const sellAfterFirstRefresh = screen.getByTestId('current-sell').textContent

      await refreshAndReopenEditor()

      await waitFor(() =>
        expect(screen.getByTestId('cell-errors')).toHaveTextContent(
          'Nincs érték a 0-s lap F oszlopában',
        ),
      )
      expect(screen.getByTestId('current-sell')).toHaveTextContent(sellAfterFirstRefresh!)
    })

    it('weakMultiSell=0 képlethibánál megtartja a pozitív baseline-t, de nem küldi szét', async () => {
      localStorage.setItem(
        'arfolyamkeszito.mainSheet.v1',
        JSON.stringify([{ currency: 'EUR', weakMultiSell: 405 }]),
      )
      saveGroupFormulas('wg-1', { '1.sellRate': 'F' })
      await renderEditor(false, overviewWithSellRate(405))
      await waitFor(() => expect(screen.getByTestId('current-sell')).toHaveTextContent('405'))

      localStorage.setItem(
        'arfolyamkeszito.mainSheet.v1',
        JSON.stringify([{ currency: 'EUR', weakMultiSell: 0 }]),
      )
      await refreshAndReopenEditor()
      await waitFor(() =>
        expect(screen.getByTestId('cell-errors')).toHaveTextContent(
          'Nincs érték a 0-s lap F oszlopában',
        ),
      )
      expect(screen.getByTestId('current-sell')).toHaveTextContent('405')

      fireEvent.click(screen.getByRole('button', { name: 'rates.arfolyamokSzetkuldese' }))

      expect(publishMocks.publishAllWorkgroups).not.toHaveBeenCalled()
      expect(toastMocks.error).toHaveBeenCalledWith(
        'Nem küldhető szét',
        'Hibás árfolyam-képlet cella(k) van(nak) a lapon — előbb javítsa a hibás képleteket.',
      )
    })
  })
})
