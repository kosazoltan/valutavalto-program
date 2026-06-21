import { render, screen, waitFor, within } from '@testing-library/react'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import CashierStocksPage from './CashierStocksPage'

// FK-007/008: az Országos készlet kártyák a valutanem-TÖRZSBŐL épülnek (aktív + display_order),
// a branch-egyenlegekkel merge-elve. Így az értéktár-kártyák is a teljes listát mutatják (0-val is),
// az ismeretlen 0-s sorok nem jelennek meg, de a nem-nulla árva készlet nem veszhet el.
const mocks = vi.hoisted(() => ({
  apiGet: vi.fn(),
  branchListActive: vi.fn(),
  currencyList: vi.fn(),
  exchangeRateList: vi.fn(),
  logger: { error: vi.fn(), info: vi.fn(), warn: vi.fn(), debug: vi.fn() },
}))

vi.mock('../../services/api/index', () => ({
  api: { get: mocks.apiGet },
  branchApi: { listActive: mocks.branchListActive },
  currencyApi: { list: mocks.currencyList },
  exchangeRateApi: { list: mocks.exchangeRateList },
}))

vi.mock('../../utils/logger', () => ({ logger: mocks.logger }))

// Aktív valutanem-törzs (display_order szerint): HUF, AUD, EUR. NINCS TST/DKK/NOK/SEK.
const MASTER_CURRENCIES = [
  { id: 1, code: 'HUF', name: 'Magyar forint', decimals: 0, displayOrder: 0, active: true },
  { id: 2, code: 'AUD', name: 'Ausztrál dollár', decimals: 2, displayOrder: 1, active: true },
  { id: 3, code: 'EUR', name: 'Euró', decimals: 2, displayOrder: 8, active: true },
]

// Stock: Baja Tesco-nak van EUR egyenlege + egy ISMERETLEN 'TST' sor (FK-007). Az értéktárnak EGYETLEN
// sora van (HUF) — a scope-szűrt /inventory/stock-ban szerepel, így megjelenik; a többi aktív valutát
// a törzsből kapja meg 0-val (FK-008). A branch-univerzum KIZÁRÓLAG a stock soraiból jön (scope-helyes).
const STOCK = [
  { id: 's1', branchId: 'branch-baja', branchName: 'Baja Tesco', currencyCode: 'EUR', currentBalance: 1910 },
  { id: 's2', branchId: 'branch-baja', branchName: 'Baja Tesco', currencyCode: 'TST', currentBalance: 0 },
  // Árva, NEM-nulla egyenleg egy inaktív valutában (pl. korábbi DKK-készlet a deaktiválás előtt).
  { id: 's3', branchId: 'branch-baja', branchName: 'Baja Tesco', currencyCode: 'DKK', currentBalance: 4200 },
  // Értéktár: csak HUF sora van — a többi aktív valutát (AUD/EUR) a törzsből kapja 0-val.
  { id: 's4', branchId: 'branch-vault', branchName: 'Szekszard Ertektar', currencyCode: 'HUF', currentBalance: 0 },
]

const BRANCHES = [
  { id: 'branch-baja', name: 'Baja Tesco', region: 'SZEKSZARD', isVault: false },
  { id: 'branch-vault', name: 'Szekszard Ertektar', region: 'SZEKSZARD', isVault: true, vaultTerritoryId: 1 },
]

describe('CashierStocksPage (FK-007/008)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.apiGet.mockImplementation((path: string) => {
      if (path === '/inventory/stock') return Promise.resolve({ data: STOCK })
      if (path === '/inventory/vault-stock') return Promise.resolve({ data: [] })
      if (path === '/inventory-movements/movement-log') return Promise.resolve({ data: [] })
      return Promise.resolve({ data: [] })
    })
    mocks.currencyList.mockResolvedValue(MASTER_CURRENCIES)
    mocks.branchListActive.mockResolvedValue(BRANCHES)
    mocks.exchangeRateList.mockResolvedValue([])
  })

  it('FK-007: az ismeretlen TST valutanem NEM jelenik meg egyetlen kártyán sem', async () => {
    render(<CashierStocksPage />)
    // A merge utáni állapotra várunk: AUD CSAK a törzsből jöhet (nincs stock-sora), így ennek
    // megjelenése bizonyítja, hogy a master-mátrix alkalmazva van (nem a nyers /stock fallback).
    await waitFor(() => {
      expect(screen.getAllByText('AUD').length).toBeGreaterThan(0)
    })
    expect(screen.queryByText('TST')).not.toBeInTheDocument()
  })

  it('FK-008: az értéktár-kártya a teljes aktív valutalistát mutatja (0 egyenleggel is)', async () => {
    render(<CashierStocksPage />)
    // A vault branch megjelenik (csak HUF-sora van, mégis a teljes aktív listát kapja a törzsből).
    await waitFor(() => {
      expect(screen.getByText('Szekszard Ertektar')).toBeInTheDocument()
    })
    // Minden aktív valuta megjelenik (HUF, AUD, EUR) — több kártyán is, ezért getAllByText.
    expect(screen.getAllByText('HUF').length).toBeGreaterThan(0)
    expect(screen.getAllByText('AUD').length).toBeGreaterThan(0)
    expect(screen.getAllByText('EUR').length).toBeGreaterThan(0)
  })

  it('P1: árva, NEM-nulla egyenleg inaktív valutában NEM tűnik el (néma adatvesztés ellen)', async () => {
    render(<CashierStocksPage />)
    await waitFor(() => {
      expect(screen.getAllByText('Baja Tesco').length).toBeGreaterThan(0)
    })
    // A DKK nincs az aktív törzsben, de van nem-nulla egyenlege → megjelenik.
    expect(screen.getAllByText('DKK').length).toBeGreaterThan(0)
    expect(screen.getAllByText(/4[\s ]?200/).length).toBeGreaterThan(0)
  })

  it('FK-008: a pénztárkártya a teljes aktív listát mutatja, az egyenleg a megfelelő valutasorban', async () => {
    render(<CashierStocksPage />)
    await waitFor(() => {
      expect(screen.getAllByText('Baja Tesco').length).toBeGreaterThan(0)
    })
    const card = screen.getAllByText('Baja Tesco')
      .map((element) => element.closest('[data-testid="branch-card"]'))
      .find(Boolean) as HTMLElement
    const scope = within(card)
    // A pénztárkártya is a master-mátrixból épül: HUF és AUD (nincs stock-soruk) 0-val megjelenik,
    // az EUR-soron a tényleges egyenleg (1910 → hu-HU "1 910").
    expect(scope.getByText('HUF')).toBeInTheDocument()
    expect(scope.getByText('AUD')).toBeInTheDocument()
    expect(scope.getByText('EUR')).toBeInTheDocument()
    expect(scope.getByText(/1[\s ]?910/)).toBeInTheDocument()
  })

  it('FK-007: a KÉSZLETSOR NÉLKÜLI értéktár-kártya is a teljes aktív valutalistát mutatja (nem "0 valuta")', async () => {
    // Az értéktárnak EGYETLEN /inventory/stock sora SINCS — csak a BRANCHES-ben szerepel isVault:true-val.
    // Korábban üres ("0 valuta") kártyaként jelent meg; mostantól a központi törzsből kapja a 0-soros listát.
    mocks.apiGet.mockImplementation((path: string) => {
      if (path === '/inventory/stock') return Promise.resolve({
        data: [{ id: 's1', branchId: 'branch-baja', branchName: 'Baja Tesco', currencyCode: 'EUR', currentBalance: 1910 }],
      })
      if (path === '/inventory/vault-stock') return Promise.resolve({ data: [] })
      if (path === '/inventory-movements/movement-log') return Promise.resolve({ data: [] })
      return Promise.resolve({ data: [] })
    })
    mocks.branchListActive.mockResolvedValue([
      { id: 'branch-baja', name: 'Baja Tesco', region: 'SZEKSZARD', isVault: false },
      { id: 'branch-vault', name: 'Szekszard Ertektar', region: 'SZEKSZARD', isVault: true },
    ])

    render(<CashierStocksPage />)

    // A fix után a vault-kártya CSAK akkor kerül be, ha a /currencies törzs betöltött (különben nincs
    // injektált sor) — így a vault NEVÉNEK megjelenése már garantálja a feltöltött kártyát (Copilot).
    await waitFor(() => {
      expect(screen.getByText('Szekszard Ertektar')).toBeInTheDocument()
    })

    const card = screen.getByText('Szekszard Ertektar').closest('[data-testid="branch-card"]') as HTMLElement
    const scope = within(card)
    // Mind a 3 aktív valuta megjelenik a kártyán 0-val, és a fejléc a darabszámot (3) mutatja, nem 0-t.
    expect(scope.getByText('HUF')).toBeInTheDocument()
    expect(scope.getByText('AUD')).toBeInTheDocument()
    expect(scope.getByText('EUR')).toBeInTheDocument()
    expect(scope.getByText(`${MASTER_CURRENCIES.length} valuta`)).toBeInTheDocument()
  })
})
