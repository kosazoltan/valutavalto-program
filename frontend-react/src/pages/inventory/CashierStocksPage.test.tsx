import { render, screen, waitFor, within } from '@testing-library/react'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import CashierStocksPage from './CashierStocksPage'

// FK-007/008: az Országos készlet kártyák a valutanem-TÖRZSBŐL épülnek (aktív + display_order),
// a branch-egyenlegekkel merge-elve. Így az értéktár-kártyák is a teljes listát mutatják (0-val is),
// az ismeretlen 0-s sorok nem jelennek meg, de a nem-nulla árva készlet nem veszhet el.
const mocks = vi.hoisted(() => ({
  apiGet: vi.fn(),
  branchListActive: vi.fn(),
  branchListMyTerritory: vi.fn(),
  currencyList: vi.fn(),
  exchangeRateList: vi.fn(),
  appMode: vi.fn(),
  vaultTurnoverDaily: vi.fn(),
  logger: { error: vi.fn(), info: vi.fn(), warn: vi.fn(), debug: vi.fn() },
}))

vi.mock('../../services/api/index', () => ({
  api: { get: mocks.apiGet },
  branchApi: { listActive: mocks.branchListActive, listMyTerritory: mocks.branchListMyTerritory },
  currencyApi: { list: mocks.currencyList },
  exchangeRateApi: { list: mocks.exchangeRateList },
}))

// FKH-066: the turnover columns now come from the vault-daily turnover endpoint, not movement-log.
vi.mock('../../services/api/vault-turnover', () => ({
  vaultTurnoverApi: { daily: (...args: unknown[]) => mocks.vaultTurnoverDaily(...args) },
}))

vi.mock('../../hooks/useAppMode', () => ({ useAppMode: () => ({ mode: mocks.appMode() }) }))

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
  {
    id: 's1',
    branchId: 'branch-baja',
    branchName: 'Baja Tesco',
    currencyCode: 'EUR',
    currentBalance: 1910,
  },
  {
    id: 's2',
    branchId: 'branch-baja',
    branchName: 'Baja Tesco',
    currencyCode: 'TST',
    currentBalance: 0,
  },
  // Árva, NEM-nulla egyenleg egy inaktív valutában (pl. korábbi DKK-készlet a deaktiválás előtt).
  {
    id: 's3',
    branchId: 'branch-baja',
    branchName: 'Baja Tesco',
    currencyCode: 'DKK',
    currentBalance: 4200,
  },
  // Értéktár: csak HUF sora van — a többi aktív valutát (AUD/EUR) a törzsből kapja 0-val.
  {
    id: 's4',
    branchId: 'branch-vault',
    branchName: 'Szekszard Ertektar',
    currencyCode: 'HUF',
    currentBalance: 0,
  },
]

const BRANCHES = [
  { id: 'branch-baja', name: 'Baja Tesco', region: 'SZEKSZARD', isVault: false },
  {
    id: 'branch-vault',
    name: 'Szekszard Ertektar',
    region: 'SZEKSZARD',
    isVault: true,
    vaultTerritoryId: 1,
  },
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
    // FK-1: a legördülő forrása a my-territory lista (a pénztárak + az értéktár — utóbbi kiszűrve).
    mocks.branchListMyTerritory.mockResolvedValue(BRANCHES)
    mocks.vaultTurnoverDaily.mockResolvedValue({ byCurrency: [] })
    // FK-040: alapértelmezésben értéktáros (ertektar) mód — a teljes nézet (felső táblázat + kártyák).
    mocks.appMode.mockReturnValue('ertektar')
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
    const card = screen
      .getAllByText('Baja Tesco')
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
      if (path === '/inventory/stock')
        return Promise.resolve({
          data: [
            {
              id: 's1',
              branchId: 'branch-baja',
              branchName: 'Baja Tesco',
              currencyCode: 'EUR',
              currentBalance: 1910,
            },
          ],
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

    const card = screen
      .getByText('Szekszard Ertektar')
      .closest('[data-testid="branch-card"]') as HTMLElement
    const scope = within(card)
    // Mind a 3 aktív valuta megjelenik a kártyán 0-val, és a fejléc a darabszámot (3) mutatja, nem 0-t.
    expect(scope.getByText('HUF')).toBeInTheDocument()
    expect(scope.getByText('AUD')).toBeInTheDocument()
    expect(scope.getByText('EUR')).toBeInTheDocument()
    expect(scope.getByText(`${MASTER_CURRENCIES.length} valuta`)).toBeInTheDocument()
  })

  it('FK-1: a pénztárválasztó legördülő a my-territory listából épül (értéktár kiszűrve, scope-helyes)', async () => {
    render(<CashierStocksPage />)
    const select = screen.getByRole('combobox')
    await within(select).findByRole('option', { name: 'Baja Tesco' })
    expect(mocks.branchListMyTerritory).toHaveBeenCalled()
    const options = within(select)
      .getAllByRole('option')
      .map((o) => o.textContent)
    expect(options).toContain('Körzet összesen')
    expect(options).toContain('Baja Tesco')
    // Az értéktár (isVault) NEM pénztár → nem szerepel a legördülőben (és más territory sem szivároghat be).
    expect(options).not.toContain('Szekszard Ertektar')
  })

  it('FK-040: full (főértéktár) módban a felső táblázat NEM renderelődik, az összesítő sáv és a kártyák IGEN', async () => {
    mocks.appMode.mockReturnValue('full')
    render(<CashierStocksPage />)
    await waitFor(() => expect(screen.getAllByText('Baja Tesco').length).toBeGreaterThan(0))
    // FR-1: a felső táblázatos rész (fejléc + legördülő) rejtve
    expect(screen.queryByText('Részletes pénztári készlet')).not.toBeInTheDocument()
    expect(screen.queryByText('Körzet összesen')).not.toBeInTheDocument()
    // FR-2 + FR-3: az összesítő sáv és a kártyás nézet látható
    expect(screen.getByTestId('inventory-summary-bar')).toBeInTheDocument()
    expect(screen.getAllByTestId('branch-card').length).toBeGreaterThan(0)
  })

  it('FK-040: full módban a /exchange-rates, /movement-log és /branches/my-territory NEM hívódik (NFR-1)', async () => {
    mocks.appMode.mockReturnValue('full')
    render(<CashierStocksPage />)
    await waitFor(() => expect(mocks.apiGet).toHaveBeenCalledWith('/inventory/stock'))
    expect(mocks.exchangeRateList).not.toHaveBeenCalled()
    expect(mocks.branchListMyTerritory).not.toHaveBeenCalled()
    expect(mocks.apiGet).not.toHaveBeenCalledWith(
      '/inventory-movements/movement-log',
      expect.anything(),
    )
    // A szükséges hívások viszont lefutnak (FR-4)
    expect(mocks.currencyList).toHaveBeenCalled()
    expect(mocks.apiGet).toHaveBeenCalledWith('/inventory/vault-stock')
  })

  it('FK-040: ertektar módban a felső táblázat renderelődik és minden API hívás lefut (regresszió, FR-5)', async () => {
    render(<CashierStocksPage />) // default: ertektar
    await waitFor(() => expect(screen.getByText('Részletes pénztári készlet')).toBeInTheDocument())
    expect(screen.getByText('Körzet összesen')).toBeInTheDocument()
    expect(mocks.exchangeRateList).toHaveBeenCalled()
    // FKH-066: coverage inherited from the movement-log assertion - the turnover data is still
    // fetched in ertektar mode, only its SOURCE changed to the actual BUY/SELL turnover.
    await waitFor(() => expect(mocks.vaultTurnoverDaily).toHaveBeenCalled())
    expect(mocks.apiGet).not.toHaveBeenCalledWith(
      '/inventory-movements/movement-log',
      expect.anything(),
    )
  })

  it('FK-040 edge: ismeretlen appMode → értéktáros-viselkedés (felső táblázat látszik), nem dob hibát', async () => {
    mocks.appMode.mockReturnValue(undefined as unknown as string)
    render(<CashierStocksPage />)
    await waitFor(() => expect(screen.getByText('Részletes pénztári készlet')).toBeInTheDocument())
  })

  // --- FKH-066: actual buy/sell turnover + handling fee ---

  it('FKH-066 FR-3: a Forgalom oszlopok a tényleges BUY/SELL forgalmat mutatják, nem banki mozgást', async () => {
    mocks.vaultTurnoverDaily.mockResolvedValue({
      byCurrency: [{ currencyCode: 'EUR', buyHuf: 1234567, sellHuf: 890123, fee: 4500 }],
    })
    render(<CashierStocksPage />)

    await waitFor(() => expect(mocks.vaultTurnoverDaily).toHaveBeenCalled())
    // The movement-log source is gone from this view entirely (spec: "must not remain in any form").
    expect(mocks.apiGet).not.toHaveBeenCalledWith(
      '/inventory-movements/movement-log',
      expect.anything(),
    )
    const table = await screen.findByText('Részletes pénztári készlet')
    expect(table).toBeInTheDocument()
    await waitFor(() => expect(screen.getByTestId('cashier-stock-fee-EUR')).toBeInTheDocument())
  })

  it('FKH-066 FR-4: a Kezelési díj oszlop a válasz fee mezőjéből, HUF-ra kerekítve jelenik meg', async () => {
    mocks.vaultTurnoverDaily.mockResolvedValue({
      byCurrency: [{ currencyCode: 'EUR', buyHuf: 0, sellHuf: 0, fee: 4503 }],
    })
    render(<CashierStocksPage />)

    // roundHuf: statutory 5 Ft rounding (4503 -> 4505), the repo's money invariant.
    await waitFor(() =>
      expect(screen.getByTestId('cashier-stock-fee-EUR')).toHaveTextContent('4505'),
    )
  })

  // --- FKH-068: the turnover columns switch from HUF-equivalent to CURRENCY UNITS ---
  // Deliberate spec reversal of FKH-066 FR-3 (which prescribed buyHuf/sellHuf): the stock and
  // rate columns of the same table work in currency units, so the turnover must too.

  it('FKH-068 FR-1: a Forgalom oszlopok a válasz buyVolume/sellVolume (valuta-egység) mezőjét mutatják, nem a HUF-egyenértéket', async () => {
    // 100 EUR bought (34 205 HUF), 250.5 EUR sold (86 500 HUF). Distinct values so that a
    // buy/sell swap or a fallback to the HUF field cannot pass.
    mocks.vaultTurnoverDaily.mockResolvedValue({
      byCurrency: [
        {
          currencyCode: 'EUR',
          buyVolume: 100,
          sellVolume: 250.5,
          buyHuf: 34205,
          sellHuf: 86500,
          fee: 0,
        },
      ],
    })
    render(<CashierStocksPage />)

    await waitFor(() =>
      expect(screen.getByTestId('cashier-stock-buy-EUR')).toHaveTextContent('100,00'),
    )
    expect(screen.getByTestId('cashier-stock-sell-EUR')).toHaveTextContent('250,50')
    expect(screen.getByTestId('cashier-stock-buy-EUR')).not.toHaveTextContent(/34[\s ]?205/)
    expect(screen.getByTestId('cashier-stock-sell-EUR')).not.toHaveTextContent(/86[\s ]?500/)
  })

  it('FKH-068 FR-2: JPY forgalom 0 tizedesjeggyel jelenik meg (pénznemenkénti formázás, a Készlet oszloppal konzisztensen)', async () => {
    mocks.vaultTurnoverDaily.mockResolvedValue({
      byCurrency: [{ currencyCode: 'JPY', buyVolume: 12345.4, sellVolume: 6789.6, fee: 0 }],
    })
    render(<CashierStocksPage />)

    // hu-HU grouping: "12 345" (no decimals, NOT "12 345,40"); JPY is not 5-rounded (HUF-only rule).
    await waitFor(() =>
      expect(screen.getByTestId('cashier-stock-buy-JPY')).toHaveTextContent(/^12[\s ]?345$/),
    )
    expect(screen.getByTestId('cashier-stock-sell-JPY')).toHaveTextContent(/^6[\s ]?790$/)
  })

  it('FKH-068 FR-3: a Kezelési díj oszlop változatlanul HUF-ban, 5 Ft-ra kerekítve marad a valuta-egységes Forgalom mellett', async () => {
    mocks.vaultTurnoverDaily.mockResolvedValue({
      byCurrency: [{ currencyCode: 'EUR', buyVolume: 100, sellVolume: 50, fee: 4503 }],
    })
    render(<CashierStocksPage />)

    await waitFor(() =>
      expect(screen.getByTestId('cashier-stock-buy-EUR')).toHaveTextContent('100,00'),
    )
    // The fee is HUF regardless of the row currency: roundHuf (4503 -> 4505), no decimals.
    expect(screen.getByTestId('cashier-stock-fee-EUR')).toHaveTextContent(/^4[\s ]?505$/)
  })

  it('FKH-068 FR-4: "Körzet összesen" a pénztárak valuta-egységes forgalmát devizánként adja össze (EUR az EUR-hoz)', async () => {
    const SECOND = {
      id: 'branch-szekszard',
      name: 'Szekszard Tesco',
      region: 'SZEKSZARD',
      isVault: false,
    }
    mocks.branchListActive.mockResolvedValue([...BRANCHES, SECOND])
    mocks.branchListMyTerritory.mockResolvedValue([...BRANCHES, SECOND])
    mocks.apiGet.mockImplementation((path: string) => {
      if (path === '/inventory/stock')
        return Promise.resolve({
          data: [
            ...STOCK,
            {
              id: 's5',
              branchId: 'branch-szekszard',
              branchName: 'Szekszard Tesco',
              currencyCode: 'EUR',
              currentBalance: 500,
            },
          ],
        })
      return Promise.resolve({ data: [] })
    })
    // Two desks: EUR 100 + 250.25 = 350.25; USD only at the second desk. HUF fields are
    // deliberately non-additive in currency terms so a HUF-based sum would not match.
    mocks.vaultTurnoverDaily.mockImplementation((branchId: string) => {
      if (branchId === 'branch-baja')
        return Promise.resolve({
          byCurrency: [
            { currencyCode: 'EUR', buyVolume: 100, sellVolume: 10, buyHuf: 34205, fee: 100 },
          ],
        })
      if (branchId === 'branch-szekszard')
        return Promise.resolve({
          byCurrency: [
            { currencyCode: 'EUR', buyVolume: 250.25, sellVolume: 20, buyHuf: 85610, fee: 200 },
            { currencyCode: 'USD', buyVolume: 40, sellVolume: 0, buyHuf: 15000, fee: 0 },
          ],
        })
      return Promise.resolve({ byCurrency: [] })
    })
    render(<CashierStocksPage />) // default selection: 'ALL' = Körzet összesen

    await waitFor(() =>
      expect(screen.getByTestId('cashier-stock-buy-EUR')).toHaveTextContent(/^350,25$/),
    )
    expect(screen.getByTestId('cashier-stock-sell-EUR')).toHaveTextContent(/^30,00$/)
    // USD is not folded into EUR: it keeps its own row with its own figure.
    expect(screen.getByTestId('cashier-stock-buy-USD')).toHaveTextContent(/^40,00$/)
    // FKH-066 FR-5 kept: the fee column still sums across the desks, in HUF.
    expect(screen.getByTestId('cashier-stock-fee-EUR')).toHaveTextContent(/^300$/)
  })

  it('FKH-072 FR-1/FR-2: a HUF sor Forgalom vétel/eladás a vault-daily totalBuy/totalSell forint-összeg', async () => {
    mocks.vaultTurnoverDaily.mockResolvedValue({
      totalBuy: 45000,
      totalSell: 12000,
      byCurrency: [
        {
          currencyCode: 'EUR',
          buyVolume: 100,
          sellVolume: 10,
          buyHuf: 34205,
          sellHuf: 8000,
          fee: 0,
        },
      ],
    })
    render(<CashierStocksPage />)

    await waitFor(() =>
      expect(screen.getByTestId('cashier-stock-buy-HUF')).toHaveTextContent(/45[\s\u00a0]?000/),
    )
    expect(screen.getByTestId('cashier-stock-sell-HUF')).toHaveTextContent(/12[\s\u00a0]?000/)
    expect(screen.getByTestId('cashier-stock-buy-HUF')).not.toHaveTextContent(/100,00/)
  })

  it('FKH-072 FR-3: Körzet összesen a HUF sorban a fiókok forint-forgalmát összegzi', async () => {
    const SECOND = {
      id: 'branch-szekszard',
      name: 'Szekszard Tesco',
      region: 'SZEKSZARD',
      isVault: false,
    }
    mocks.branchListActive.mockResolvedValue([...BRANCHES, SECOND])
    mocks.branchListMyTerritory.mockResolvedValue([...BRANCHES, SECOND])
    mocks.apiGet.mockImplementation((path: string) => {
      if (path === '/inventory/stock')
        return Promise.resolve({
          data: [
            ...STOCK,
            {
              id: 's5',
              branchId: 'branch-szekszard',
              branchName: 'Szekszard Tesco',
              currencyCode: 'EUR',
              currentBalance: 500,
            },
          ],
        })
      return Promise.resolve({ data: [] })
    })
    mocks.vaultTurnoverDaily.mockImplementation((branchId: string) => {
      if (branchId === 'branch-baja')
        return Promise.resolve({ totalBuy: 45000, totalSell: 10000, byCurrency: [] })
      if (branchId === 'branch-szekszard')
        return Promise.resolve({ totalBuy: 15000, totalSell: 5000, byCurrency: [] })
      return Promise.resolve({ byCurrency: [] })
    })
    render(<CashierStocksPage />)

    await waitFor(() =>
      expect(screen.getByTestId('cashier-stock-buy-HUF')).toHaveTextContent(/60[\s\u00a0]?000/),
    )
    expect(screen.getByTestId('cashier-stock-sell-HUF')).toHaveTextContent(/15[\s\u00a0]?000/)
  })

  it('FKH-072 FR-5: a devizás sorok Forgalom oszlopai valuta-egységben maradnak', async () => {
    mocks.vaultTurnoverDaily.mockResolvedValue({
      totalBuy: 34205,
      totalSell: 86500,
      byCurrency: [
        {
          currencyCode: 'EUR',
          buyVolume: 100,
          sellVolume: 250.5,
          buyHuf: 34205,
          sellHuf: 86500,
          fee: 0,
        },
      ],
    })
    render(<CashierStocksPage />)

    await waitFor(() =>
      expect(screen.getByTestId('cashier-stock-buy-EUR')).toHaveTextContent('100,00'),
    )
    expect(screen.getByTestId('cashier-stock-sell-EUR')).toHaveTextContent('250,50')
  })

  it('FKH-072 FR-6/FR-7: páratlan indexű sor bg-gray-50, a border-b megmarad', async () => {
    render(<CashierStocksPage />)
    await waitFor(() => expect(screen.getByTestId('cashier-stock-buy-HUF')).toBeInTheDocument())
    const table = screen.getByTestId('cashier-stock-buy-HUF').closest('table')
    expect(table).toBeTruthy()
    const bodyRows = table!.querySelectorAll('tbody tr')
    expect(bodyRows.length).toBeGreaterThan(1)
    expect(bodyRows[0].className).toMatch(/border-b/)
    expect(bodyRows[0].className).not.toMatch(/bg-gray-50/)
    expect(bodyRows[1].className).toMatch(/bg-gray-50/)
    expect(bodyRows[1].className).toMatch(/border-b/)
  })

  it('FKH-066 NFR-1: bukó forgalom-lekérdezés NEM jelenhet meg nullaként, a cella ismeretlent jelöl', async () => {
    // Reviewer finding (money data): an unavailable lookup rendered as a legitimate
    // zero, which also corrupted the territory total.
    mocks.vaultTurnoverDaily.mockRejectedValue(new Error('territory 404'))
    render(<CashierStocksPage />)

    await waitFor(() => expect(screen.getByText('Részletes pénztári készlet')).toBeInTheDocument())
    expect(screen.getByTestId('cashier-stock-fee-EUR')).toHaveTextContent('n.a.')
    expect(screen.getByTestId('cashier-stock-buy-EUR')).toHaveTextContent('n.a.')
    expect(screen.getByTestId('cashier-stock-sell-EUR')).toHaveTextContent('n.a.')
    expect(screen.getByTestId('cashier-stock-fee-EUR')).not.toHaveTextContent('0')
  })
})
