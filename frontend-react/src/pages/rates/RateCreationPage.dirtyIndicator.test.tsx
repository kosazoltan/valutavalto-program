import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { loadGroupRateValues, persistGroupRateValues } from './workgroupSheetStorage'

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
vi.mock('../../components/ui/toaster', () => ({ toast: toastMocks }))
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
  }: {
    onCommitCell?: (index: number, field: 'buyRate', raw: string) => void
    rates?: Array<{ buyRate: string; modified: boolean }>
  }) => (
    <div data-testid="rate-grid-stub">
      <button type="button" onClick={() => onCommitCell?.(0, 'buyRate', '405')}>
        EUR vétel commit
      </button>
      <button type="button" onClick={() => onCommitCell?.(0, 'buyRate', '395')}>
        EUR vétel szerverérték commit
      </button>
      <button type="button" onClick={() => onCommitCell?.(0, 'buyRate', 'J*1.01')}>
        EUR vétel képlet commit
      </button>
      <div data-testid="current-buy">{rates[0]?.buyRate}</div>
      <div data-testid="row-modified">{String(rates[0]?.modified)}</div>
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

function workgroup(id: string, code: string, name: string, legacyGroupNumber: number) {
  return {
    id,
    code,
    name,
    legacyGroupNumber,
    active: true,
    branches: [],
    limit1Boundary: 50000,
    limit2Boundary: 300000,
    limit3Boundary: 1000000,
    tileColor: 'sky',
    protectionEnabled: false,
  }
}

const workgroups = [
  workgroup('wg-1', 'WG01', 'Budapest központ', 1),
  workgroup('wg-2', 'WG02', 'Debrecen központ', 2),
]

async function renderPage() {
  const Page = (await import('./RateCreationPage')).default
  return render(<Page />)
}

async function openEditor(name = 'Budapest központ') {
  fireEvent.click(
    await screen.findByRole('button', {
      name: new RegExp(`${name}.*árfolyamlap megnyitása`, 'i'),
    }),
  )
  await screen.findByTestId('rate-grid-stub')
}

async function commitDirty() {
  fireEvent.click(screen.getByRole('button', { name: 'EUR vétel commit' }))
  await waitFor(() => expect(screen.getByTestId('current-buy')).toHaveTextContent('405'))
}

async function refreshAndReopenEditor() {
  fireEvent.click(screen.getByRole('button', { name: 'Csempés nézet' }))
  const refreshButton = await screen.findByTitle('Frissítés')
  fireEvent.click(refreshButton)
  await waitFor(() => expect(refreshButton).not.toBeDisabled())
  await openEditor()
}

describe('FK11 — tartós munkacsoport dirty-jelző', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.stubEnv('VITE_APP_FLAVOR', 'rate-maker')
    localStorage.clear()
    apiMocks.getLocalRateMakerBootstrap.mockResolvedValue({ overview, workgroups })
    apiMocks.getLocalRateMakerSheet.mockResolvedValue(null)
    apiMocks.putLocalRateMakerSheet.mockResolvedValue({ version: 1 })
    publishMocks.publishAllWorkgroups.mockResolvedValue([])
    publishMocks.summarizePublishAll.mockReturnValue({
      ok: true,
      title: 'Kész',
      detail: 'Publikálva',
    })
  })

  it('G1: fix cella commit után megjelenik a dirty-jelző és a sor módosított', async () => {
    await renderPage()
    await openEditor()

    await commitDirty()

    expect(screen.getByTestId('wg-dirty-indicator')).toHaveTextContent('1 rates.mod')
    expect(screen.getByTestId('row-modified')).toHaveTextContent('true')
  })

  it('G2: remount után az overlayből visszaáll az érték és a dirty-jelző', async () => {
    const first = await renderPage()
    await openEditor()
    await commitDirty()
    first.unmount()

    await renderPage()
    await openEditor()

    await waitFor(() => expect(screen.getByTestId('current-buy')).toHaveTextContent('405'))
    expect(screen.getByTestId('wg-dirty-indicator')).toHaveTextContent('1 rates.mod')
    expect(screen.getByTestId('row-modified')).toHaveTextContent('true')
  })

  it('G2: csempés Frissítés után is visszaáll a dirty-jelző', async () => {
    await renderPage()
    await openEditor()
    await commitDirty()

    await refreshAndReopenEditor()

    await waitFor(() => expect(screen.getByTestId('current-buy')).toHaveTextContent('405'))
    expect(screen.getByTestId('wg-dirty-indicator')).toBeInTheDocument()
    expect(screen.getByTestId('row-modified')).toHaveTextContent('true')
  })

  it('G3: sikeres publikálás overlay-törlése után eltűnik a dirty-jelző', async () => {
    publishMocks.publishAllWorkgroups.mockImplementation(async () => {
      persistGroupRateValues('wg-1', {})
      return []
    })
    await renderPage()
    await openEditor()
    await commitDirty()

    fireEvent.click(screen.getByRole('button', { name: 'rates.arfolyamokSzetkuldese' }))

    await waitFor(() => expect(publishMocks.publishAllWorkgroups).toHaveBeenCalledTimes(1))
    await waitFor(() => expect(screen.queryByTestId('wg-dirty-indicator')).not.toBeInTheDocument())
    expect(screen.getByTestId('row-modified')).toHaveTextContent('false')
  })

  it('G3: sikertelen csoportpublikálás megmaradó overlaye megtartja a dirty-jelzőt', async () => {
    publishMocks.summarizePublishAll.mockReturnValue({
      ok: false,
      title: 'Részleges hiba',
      detail: 'Nem publikálva',
    })
    await renderPage()
    await openEditor()
    await commitDirty()

    fireEvent.click(screen.getByRole('button', { name: 'rates.arfolyamokSzetkuldese' }))

    await waitFor(() => expect(publishMocks.publishAllWorkgroups).toHaveBeenCalledTimes(1))
    // Flaky-fix (CI 2026-07-24/27): a current-buy '405' a publish ELŐTT is igaz, ezért önmagában
    // nem bizonyítja a reload lefutását — előbb a publish utáni loadData() bootstrap-újrahívását
    // várjuk (diszkrimináló jel), a záró assertionöket pedig waitFor hidalja át a szerver-baseline
    // → overlay-visszaírás közti tranziens commiton (ott a dirty-jelző egy effekt-ciklusra eltűnik).
    await waitFor(() => expect(apiMocks.getLocalRateMakerBootstrap).toHaveBeenCalledTimes(2))
    await waitFor(() => expect(screen.getByTestId('current-buy')).toHaveTextContent('405'))
    await waitFor(() => {
      expect(screen.getByTestId('wg-dirty-indicator')).toBeInTheDocument()
      expect(screen.getByTestId('row-modified')).toHaveTextContent('true')
    })
  })

  it('G4: szerverértékre visszaállító commit törli a dirty-jelzőt publikálás nélkül', async () => {
    await renderPage()
    await openEditor()
    await commitDirty()

    fireEvent.click(screen.getByRole('button', { name: 'EUR vétel szerverérték commit' }))

    await waitFor(() => expect(screen.getByTestId('current-buy')).toHaveTextContent('395'))
    expect(screen.queryByTestId('wg-dirty-indicator')).not.toBeInTheDocument()
    expect(screen.getByTestId('row-modified')).toHaveTextContent('false')
  })

  it('munkacsoportonként izolálja a dirty-jelzőt', async () => {
    await renderPage()
    await openEditor()
    await commitDirty()

    fireEvent.click(screen.getByRole('button', { name: 'Csempés nézet' }))
    await openEditor('Debrecen központ')
    await waitFor(() => expect(screen.queryByTestId('wg-dirty-indicator')).not.toBeInTheDocument())
    expect(screen.getByTestId('row-modified')).toHaveTextContent('false')

    fireEvent.click(screen.getByRole('button', { name: 'Csempés nézet' }))
    await openEditor()
    await waitFor(() => expect(screen.getByTestId('wg-dirty-indicator')).toBeInTheDocument())
    expect(screen.getByTestId('row-modified')).toHaveTextContent('true')
  })

  it('a képletet perzisztált konfigurációként kezeli, nem fixed-value dirty overlayként', async () => {
    await renderPage()
    await openEditor()

    fireEvent.click(screen.getByRole('button', { name: 'EUR vétel képlet commit' }))

    await waitFor(() =>
      expect(localStorage.getItem('arfolyamkeszito.workgroupSheet.formulas.v1.wg-1')).toContain(
        'J*1.01',
      ),
    )
    expect(loadGroupRateValues('wg-1')).toEqual({})
    expect(screen.queryByTestId('wg-dirty-indicator')).not.toBeInTheDocument()
    expect(screen.getByTestId('row-modified')).toHaveTextContent('false')
  })

  it('hibás overlay JSON esetén renderel és tiszta marad', async () => {
    localStorage.setItem('arfolyamkeszito.workgroupSheet.rates.v1.wg-1', '{oops')

    await renderPage()
    await openEditor()

    expect(screen.getByTestId('current-buy')).toHaveTextContent('395')
    expect(screen.queryByTestId('wg-dirty-indicator')).not.toBeInTheDocument()
    expect(screen.getByTestId('row-modified')).toHaveTextContent('false')
  })

  it('a hozzáférhető elvetés visszaállítja a szerverértéket és csak az aktuális overlayt törli', async () => {
    persistGroupRateValues('wg-2', { '1.buyRate': '410' })
    await renderPage()
    await openEditor()
    await commitDirty()

    expect(screen.getByTestId('wg-dirty-indicator')).toHaveAttribute('role', 'status')
    fireEvent.click(screen.getByRole('button', { name: 'Eltérések elvetése' }))
    fireEvent.click(await screen.findByRole('button', { name: 'Igen' }))

    await waitFor(() => expect(screen.getByTestId('current-buy')).toHaveTextContent('395'))
    expect(screen.queryByTestId('wg-dirty-indicator')).not.toBeInTheDocument()
    expect(loadGroupRateValues('wg-1')).toEqual({})
    expect(loadGroupRateValues('wg-2')).toEqual({ '1.buyRate': '410' })
  })
})
