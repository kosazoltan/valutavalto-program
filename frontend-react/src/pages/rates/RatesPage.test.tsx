import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import RatesPage from './RatesPage'

const mocks = vi.hoisted(() => ({
  exchangeRateApiList: vi.fn(),
  exchangeRateApiCreate: vi.fn(),
  exchangeRateApiUploadRateFile: vi.fn(),
  exchangeRateApiImportRateFile: vi.fn(),
  rateApprovalRequest: vi.fn(),
  currencyApiList: vi.fn(),
  calculatorMatrix: vi.fn(),
  calculatorConvert: vi.fn(),
  calculatorReverse: vi.fn(),
  pollingStatus: vi.fn(),
  pollingSources: vi.fn(),
  pollingEcbRates: vi.fn(),
  pollingTrigger: vi.fn(),
  pollingApplyMargins: vi.fn(),
  pollingUpdateSource: vi.fn(),
  bankRates: vi.fn(),
  competitorRates: vi.fn(),
  territoryWorkgroupRates: vi.fn(),
  roundingRulesList: vi.fn(),
  roundingRuleGet: vi.fn(),
  roundingRuleRound: vi.fn(),
  recordLocalAuditEvent: vi.fn(),
  logger: {
    error: vi.fn(),
    info: vi.fn(),
    warn: vi.fn(),
    debug: vi.fn(),
  },
  useAuthStore: vi.fn(),
  useAppMode: vi.fn(),
}))

vi.mock('../../services/api/index', () => ({
  exchangeRateApi: {
    list: mocks.exchangeRateApiList,
    create: mocks.exchangeRateApiCreate,
    uploadRateFile: mocks.exchangeRateApiUploadRateFile,
    importRateFile: mocks.exchangeRateApiImportRateFile,
  },
  rateApprovalApi: {
    request: mocks.rateApprovalRequest,
  },
  currencyApi: {
    list: mocks.currencyApiList,
  },
  currencyCalculatorApi: {
    matrix: mocks.calculatorMatrix,
    convert: mocks.calculatorConvert,
    reverse: mocks.calculatorReverse,
  },
  exchangeRatePollingApi: {
    status: mocks.pollingStatus,
    sources: mocks.pollingSources,
    ecbRates: mocks.pollingEcbRates,
    trigger: mocks.pollingTrigger,
    applyMargins: mocks.pollingApplyMargins,
    updateSource: mocks.pollingUpdateSource,
  },
  rateCreationApi: {
    getBankRates: mocks.bankRates,
    getCompetitorRates: mocks.competitorRates,
    getTerritoryWorkgroupRates: mocks.territoryWorkgroupRates,
  },
  roundingRuleApi: {
    list: mocks.roundingRulesList,
    getByCurrencyCode: mocks.roundingRuleGet,
    round: mocks.roundingRuleRound,
  },
}))

vi.mock('../../utils/electronTransactions', () => ({
  recordLocalAuditEvent: mocks.recordLocalAuditEvent,
}))

vi.mock('../../utils/logger', () => ({
  logger: mocks.logger,
}))

// 2026-04-29 v2.3.10 (B2 fix): a /rates oldal mode='full' + foertektar/ugyvezeto role
// esetén szerkeszthető. A tesztek default mockja: full mode + foertektar role, így a
// "Szerkesztés" gomb és "MNB letöltés" gomb látszik.
vi.mock('../../stores/authStore', () => ({
  useAuthStore: mocks.useAuthStore,
}))

vi.mock('../../hooks/useAppMode', () => ({
  useAppMode: mocks.useAppMode,
}))

const mockRates = [
  {
    id: 1,
    currencyCode: 'EUR',
    currencyName: 'Euró',
    baseBuyRate: 391.5,
    baseSellRate: 398.5,
    officialRate: 391.25,
    validTime: '10:30',
    currencyId: 1,
    createdAt: new Date().toISOString(),
  },
  {
    id: 2,
    currencyCode: 'USD',
    currencyName: 'US Dollár',
    baseBuyRate: 358.2,
    baseSellRate: 365.8,
    officialRate: 358.15,
    validTime: '10:30',
    currencyId: 2,
    createdAt: new Date().toISOString(),
  },
]

// FK-006: a tábla a valutanem-törzsből épül (aktív + display_order), az árfolyamok külön jönnek.
const mockCurrencies = [
  { id: 1, code: 'EUR', name: 'Euró', decimals: 2, displayOrder: 8, active: true },
  { id: 2, code: 'USD', name: 'US Dollár', decimals: 2, displayOrder: 21, active: true },
]

describe('RatesPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.exchangeRateApiList.mockResolvedValue(mockRates)
    mocks.exchangeRateApiUploadRateFile.mockResolvedValue({
      rates: [
        {
          currencyCode: 'EUR',
          buyRate: 390,
          sellRate: 399,
          mnbRate: 394,
          discountBuy: 391,
          discountSell: 398,
        },
      ],
      parsedAt: '2026-06-18T10:00:00',
      parsedLineCount: 1,
      skippedLineCount: 0,
    })
    mocks.exchangeRateApiImportRateFile.mockResolvedValue(mockRates)
    mocks.rateApprovalRequest.mockResolvedValue({
      id: 'approval-1',
      branchId: 'branch-1',
      currencyCode: 'EUR',
      newBuyRate: 391.5,
      newSellRate: 398.5,
      status: 'PENDING',
    })
    mocks.currencyApiList.mockResolvedValue(mockCurrencies)
    mocks.calculatorMatrix.mockResolvedValue({
      EUR: { USD: 1.07 },
      USD: { EUR: 0.93 },
    })
    mocks.calculatorConvert.mockResolvedValue({
      fromCurrency: 'EUR',
      toCurrency: 'HUF',
      fromAmount: 100,
      toAmount: 39150,
      appliedRate: 391.5,
      spread: 7,
      commission: 500,
      direction: 'BUY',
      roundingInfo: 'Kerekítés: EUR szabály alkalmazva',
    })
    mocks.calculatorReverse.mockResolvedValue({
      currency: 'EUR',
      hufAmount: 100000,
      foreignAmount: 251.25,
    })
    mocks.pollingStatus.mockResolvedValue({
      lastPollTime: '2026-06-18T08:00:00',
      lastPollSuccess: true,
      lastPollError: null,
      lastPollUpdatedCount: 12,
      lastPollSource: 'MNB',
    })
    mocks.pollingSources.mockResolvedValue([
      { id: 1, name: 'MNB', active: true, pollIntervalMinutes: 60 },
      { id: 2, name: 'ECB', active: false, pollIntervalMinutes: 1440 },
    ])
    mocks.pollingEcbRates.mockResolvedValue({
      USD: 358.2,
      CHF: 412.4,
      GBP: 466.8,
    })
    mocks.pollingTrigger.mockResolvedValue({ message: 'MNB árfolyam polling elindítva' })
    mocks.pollingApplyMargins.mockResolvedValue({ message: 'Margin sikeresen alkalmazva' })
    mocks.pollingUpdateSource.mockImplementation(
      (id: number, data: { active?: boolean; pollIntervalMinutes?: number }) =>
        Promise.resolve({
          id,
          name: id === 1 ? 'MNB' : 'ECB',
          active: data.active ?? true,
          pollIntervalMinutes: data.pollIntervalMinutes ?? 60,
        }),
    )
    mocks.bankRates.mockResolvedValue([
      {
        id: 'bank-rate-1',
        bankId: 'bank-1',
        bankCode: 'EBC',
        bankName: 'EBC',
        currencyId: '1',
        currencyCode: 'EUR',
        currencyName: 'Euró',
        buyRate: 390.5,
        sellRate: 399.5,
        middleRate: 395,
        validFrom: '2026-06-18T08:00:00',
        isCurrent: true,
        source: 'MNB',
      },
    ])
    mocks.competitorRates.mockResolvedValue([
      {
        id: 'competitor-rate-1',
        competitorId: 'competitor-1',
        competitorCode: 'RIV',
        competitorName: 'Rivális Change',
        currencyId: '1',
        currencyCode: 'EUR',
        currencyName: 'Euró',
        buyRate: 391,
        sellRate: 400,
        middleRate: 395.5,
        recordedAt: '2026-06-18T08:05:00',
        source: 'WEBSITE',
      },
    ])
    // FK-041: default üres → a read-only nézet a fallback (sima) táblát mutatja, hacsak a teszt nem
    // ad meg munkacsoport-variánsokat.
    mocks.territoryWorkgroupRates.mockResolvedValue([])
    mocks.roundingRulesList.mockResolvedValue([
      {
        id: 1,
        currencyCode: 'EUR',
        precisionValue: 0.01,
        smallThreshold: 100,
        largeThreshold: 10000,
        smallRounding: 'UP',
        largeRounding: 'DOWN',
      },
      {
        id: 2,
        currencyCode: 'USD',
        precisionValue: 0.01,
        smallThreshold: 100,
        largeThreshold: 10000,
        smallRounding: 'UP',
        largeRounding: 'DOWN',
      },
    ])
    mocks.roundingRuleGet.mockResolvedValue({
      id: 1,
      currencyCode: 'EUR',
      precisionValue: 0.01,
      smallThreshold: 100,
      largeThreshold: 10000,
      smallRounding: 'UP',
      largeRounding: 'DOWN',
    })
    mocks.roundingRuleRound.mockResolvedValue({
      original: 123.456,
      rounded: 123.46,
    })
    // Default: full mode + foertektar role (canEdit=true, MNB + Edit gombok látszanak)
    mocks.useAppMode.mockReturnValue({ mode: 'full' })
    mocks.useAuthStore.mockImplementation((selector: any) =>
      selector({
        hasCanonicalRole: (roles: readonly string[]) =>
          roles.includes('foertektar') || roles.includes('ugyvezeto'),
        worker: {
          id: 77,
          branchId: 'branch-1',
          workerCode: 'ADMIN',
          firstName: 'Admin',
          lastName: 'Teszt',
          fullName: 'Admin Teszt',
          role: 'ADMIN',
          branchCode: 'BUD01',
          branchName: 'Budapest 01',
          companyId: 'company-1',
          companyCode: 'EBC',
          companyName: 'Exclusive Best Change',
        },
      }),
    )
  })

  it('oldal renderelésének ellenőrzése', async () => {
    render(<RatesPage />)
    await waitFor(() => {
      expect(screen.getByText('Árfolyamok')).toBeInTheDocument()
    })
  })

  it('árfolyam API-t betöltéskor meghívja', async () => {
    render(<RatesPage />)
    await waitFor(() => {
      expect(mocks.exchangeRateApiList).toHaveBeenCalled()
    })
  })

  it('betöltés közben loading state mutatódik', () => {
    mocks.exchangeRateApiList.mockImplementation(
      () => new Promise((resolve) => setTimeout(() => resolve(mockRates), 100)),
    )
    render(<RatesPage />)
    // Loading indikátor megjelenhet, de gyorsan eltűnik
    expect(mocks.exchangeRateApiList).toHaveBeenCalled()
  })

  it('árfolyamok táblázatban megjelenítése', async () => {
    render(<RatesPage />)
    await waitFor(() => {
      expect(screen.getAllByText('EUR').length).toBeGreaterThan(0)
      expect(screen.getAllByText('USD').length).toBeGreaterThan(0)
      // Currency names are in tooltip (title attribute on both <tr> and <span>)
      expect(screen.getAllByTitle(/Euró/).length).toBeGreaterThanOrEqual(1)
      expect(screen.getAllByTitle(/US Dollár/).length).toBeGreaterThanOrEqual(1)
    })
  })

  it('árfolyam értékek helyesen jelennek meg', async () => {
    render(<RatesPage />)
    await waitFor(() => {
      // Values are formatted with Hungarian comma (391,50)
      expect(screen.getAllByText(/391[.,]50/).length).toBeGreaterThan(0)
      expect(screen.getAllByText(/398[.,]50/).length).toBeGreaterThan(0)
      expect(screen.getAllByText(/358[.,]20/).length).toBeGreaterThan(0)
    })
  })

  it('betöltéskor megjeleníti a polling státuszt és forrásokat', async () => {
    render(<RatesPage />)
    await waitFor(() => {
      expect(mocks.pollingStatus).toHaveBeenCalled()
      expect(mocks.pollingSources).toHaveBeenCalled()
      expect(mocks.pollingEcbRates).toHaveBeenCalled()
      expect(screen.getByText('Polling státusz')).toBeInTheDocument()
      expect(screen.getByText('Frissített tételek')).toBeInTheDocument()
      expect(screen.getByText('Árfolyam források')).toBeInTheDocument()
      expect(screen.getByText('ECB snapshot')).toBeInTheDocument()
      expect(screen.getByText('12')).toBeInTheDocument()
      expect(screen.getAllByText('MNB').length).toBeGreaterThan(0)
      expect(screen.getByText('1 / 2')).toBeInTheDocument()
      expect(screen.getAllByText('USD').length).toBeGreaterThan(0)
      expect(screen.getAllByText(/358[.,]20/).length).toBeGreaterThan(0)
    })
  })

  it('a polling vezérlő a trigger, margin és source update backend szerződéseket használja', async () => {
    const user = userEvent.setup()
    render(<RatesPage />)

    const panel = await screen.findByTestId('rate-polling-control-panel')
    expect(within(panel).getByText('Árfolyam polling vezérlés')).toBeInTheDocument()

    await user.click(within(panel).getByRole('button', { name: 'MNB polling indítása' }))
    await waitFor(() => {
      expect(mocks.pollingTrigger).toHaveBeenCalled()
      expect(screen.getByText('MNB árfolyam polling elindítva')).toBeInTheDocument()
    })

    await user.clear(within(panel).getByLabelText('Spread'))
    await user.type(within(panel).getByLabelText('Spread'), '3,5')
    await user.click(within(panel).getByRole('button', { name: 'Alkalmaz' }))
    await waitFor(() => {
      expect(mocks.pollingApplyMargins).toHaveBeenCalledWith({ currencyId: 1, spread: 3.5 })
      expect(screen.getByText('Margin sikeresen alkalmazva')).toBeInTheDocument()
    })

    await user.click(within(panel).getAllByRole('checkbox')[1]!)
    await waitFor(() => {
      expect(mocks.pollingUpdateSource).toHaveBeenCalledWith(2, { active: true })
    })

    await user.selectOptions(within(panel).getByLabelText('ECB polling intervallum'), '60')
    await waitFor(() => {
      expect(mocks.pollingUpdateSource).toHaveBeenCalledWith(2, { pollIntervalMinutes: 60 })
    })
  })

  it('betöltéskor megjeleníti a banki és versenytárs piaci árfolyam snapshotot', async () => {
    render(<RatesPage />)
    await waitFor(() => {
      expect(mocks.bankRates).toHaveBeenCalled()
      expect(mocks.competitorRates).toHaveBeenCalled()
      expect(screen.getByText('Piaci összehasonlítás')).toBeInTheDocument()
      expect(screen.getByText('Bank ráták')).toBeInTheDocument()
      expect(screen.getByText('Versenytárs')).toBeInTheDocument()
      expect(screen.getByText(/EBC EUR/)).toBeInTheDocument()
      expect(screen.getByText(/RIV EUR/)).toBeInTheDocument()
    })
  })

  it('betöltéskor megjeleníti a kerekítési szabálykártyákat és a próba backend végpontokat használja', async () => {
    const user = userEvent.setup()
    render(<RatesPage />)

    await waitFor(() => {
      expect(mocks.roundingRulesList).toHaveBeenCalled()
      expect(screen.getByText('Kerekítési szabályok')).toBeInTheDocument()
      expect(screen.getAllByTestId('rounding-rule-mobile-card').length).toBeGreaterThan(0)
    })

    await user.click(screen.getByRole('button', { name: 'Kerekítés próba' }))

    await waitFor(() => {
      expect(mocks.roundingRuleGet).toHaveBeenCalledWith('EUR', 123.456)
      expect(mocks.roundingRuleRound).toHaveBeenCalledWith('EUR', 123.456, 'BUY')
      expect(screen.getByText('Kerekített eredmény')).toBeInTheDocument()
    })
  })

  it('szerkesztés gomb megosztódik minden sorra', async () => {
    render(<RatesPage />)
    await waitFor(() => {
      const editButtons = screen.getAllByTitle('Szerkesztés')
      expect(editButtons.length).toBeGreaterThan(0)
    })
  })

  it('árfolyam jóváhagyási kérelmet küld a bejelentkezett iroda branchId-jával', async () => {
    const user = userEvent.setup()
    render(<RatesPage />)

    const editButtons = await screen.findAllByTitle('Szerkesztés')
    await user.click(editButtons[0]!)
    await user.click(await screen.findByTitle('Jóváhagyás kérés'))

    await waitFor(() => {
      expect(mocks.rateApprovalRequest).toHaveBeenCalledWith({
        branchId: 'branch-1',
        currencyCode: 'EUR',
        newBuyRate: 391.5,
        newSellRate: 398.5,
        reason: 'Árfolyam módosítási kérelem: EUR',
      })
      expect(screen.getByText('EUR jóváhagyási kérelem elküldve (PENDING).')).toBeInTheDocument()
    })
  })

  it('frissítés gomb újra betölti az árfolyamokat', async () => {
    render(<RatesPage />)
    await waitFor(() => {
      expect(screen.getAllByText('EUR').length).toBeGreaterThan(0)
    })

    const user = userEvent.setup()
    const refreshButton = screen.getByRole('button', { name: /Frissítés/i })
    await user.click(refreshButton)

    await waitFor(() => {
      expect(mocks.exchangeRateApiList).toHaveBeenCalledTimes(2)
    })
  })

  it('API hiba során error üzenetet jelenít meg', async () => {
    mocks.exchangeRateApiList.mockRejectedValue(new Error('API hiba'))
    render(<RatesPage />)

    await waitFor(() => {
      expect(screen.getByText(/Hiba az árfolyamok betöltésekor/)).toBeInTheDocument()
    })
  })

  it('utolsó frissítés ideje megjelenítésre kerül', async () => {
    render(<RatesPage />)
    await waitFor(() => {
      expect(screen.getByText(/Utolsó frissítés:/)).toBeInTheDocument()
    })
  })

  it('download gomb letöltési funktionalitást biztosít', async () => {
    render(<RatesPage />)
    await waitFor(() => {
      expect(screen.getAllByText('EUR').length).toBeGreaterThan(0)
    })

    const downloadButton = screen.getByRole('button', { name: /MNB letöltés/i })
    expect(downloadButton).toBeInTheDocument()
  })

  it('FK-006: aktív, árfolyam nélküli valuta üres sorként jelenik meg; HUF nincs a táblában', async () => {
    // Törzs: HUF (bázis), EUR (van árfolyama), BAM (aktív, DE nincs árfolyama) — display_order szerint.
    mocks.currencyApiList.mockResolvedValue([
      { id: 10, code: 'HUF', name: 'Magyar forint', decimals: 0, displayOrder: 0, active: true },
      { id: 1, code: 'EUR', name: 'Euró', decimals: 2, displayOrder: 8, active: true },
      {
        id: 3,
        code: 'BAM',
        name: 'Bosnyák konvertibilis márka',
        decimals: 2,
        displayOrder: 2,
        active: true,
      },
    ])
    // Csak az EUR-nak van árfolyama.
    mocks.exchangeRateApiList.mockResolvedValue([mockRates[0]])

    render(<RatesPage />)
    await waitFor(() => {
      expect(screen.getAllByText('EUR').length).toBeGreaterThan(0)
    })
    // BAM (árfolyam nélküli aktív) megjelenik a táblában (üres sorként).
    expect(screen.getByText('BAM')).toBeInTheDocument()
    // HUF bázisdeviza NEM jelenik meg a rátatáblában.
    expect(screen.queryByText('HUF')).not.toBeInTheDocument()
  })

  it('a deviza kalkulátor backend convert, reverse és matrix végpontokat használja', async () => {
    const user = userEvent.setup()
    render(<RatesPage />)

    await waitFor(() => {
      expect(screen.getByText('Árfolyam kalkulátor')).toBeInTheDocument()
      expect(mocks.calculatorMatrix).toHaveBeenCalled()
    })

    await user.click(screen.getByRole('button', { name: 'Számol' }))
    await waitFor(() => {
      expect(mocks.calculatorConvert).toHaveBeenCalledWith({
        fromCurrency: 'EUR',
        toCurrency: 'HUF',
        amount: 100,
        direction: 'BUY',
      })
      expect(screen.getByText('Átváltás eredménye')).toBeInTheDocument()
    })

    await user.click(screen.getByRole('button', { name: 'Fordított' }))
    await waitFor(() => {
      expect(mocks.calculatorReverse).toHaveBeenCalledWith({
        currency: 'EUR',
        hufAmount: 100000,
      })
      expect(screen.getByText('Fordított kalkuláció')).toBeInTheDocument()
    })
  })

  it('a GETARF árfolyamfájl előnézetet és importot backend wrapperen keresztül hívja', async () => {
    const user = userEvent.setup()
    render(<RatesPage />)

    const panel = await screen.findByTestId('rate-file-import-panel')
    const file = new File(['GETARF'], 'GETARF.DAT', { type: 'text/plain' })
    await user.upload(within(panel).getByTestId('rate-file-input'), file)
    await user.click(within(panel).getByRole('button', { name: /Előnézet/i }))

    await waitFor(() => {
      expect(mocks.exchangeRateApiUploadRateFile).toHaveBeenCalledWith(file)
      expect(within(panel).getByText('1 feldolgozott sor, 0 kihagyott sor.')).toBeInTheDocument()
      expect(within(panel).getByText('EUR')).toBeInTheDocument()
    })

    await user.click(within(panel).getByRole('button', { name: /Import/i }))

    await waitFor(() => {
      expect(mocks.exchangeRateApiImportRateFile).toHaveBeenCalledWith(file)
      expect(within(panel).getByText('2 árfolyam importálva.')).toBeInTheDocument()
    })
  })

  it('FK-041: read-only (értéktár) nézet — tiszta árfolyam-tábla, metrika-kártyák/kalkulátor nélkül', async () => {
    // ertektar mód -> canEdit=false: a szerkesztő-eszközök NEM jelennek meg, csak a tiszta tábla.
    mocks.useAppMode.mockReturnValue({ mode: 'ertektar' })
    render(<RatesPage />)

    // A tiszta read-only árfolyam-táblázat megjelenik, az árfolyamokkal.
    const table = await screen.findByTestId('rates-readonly-table')
    expect(within(table).getByText('EUR')).toBeInTheDocument()
    expect(within(table).getByText('USD')).toBeInTheDocument()
    expect(within(table).getAllByText(/391[.,]50/).length).toBeGreaterThan(0)
    expect(within(table).getAllByText(/398[.,]50/).length).toBeGreaterThan(0)
    expect(within(table).getAllByText(/358[.,]20/).length).toBeGreaterThan(0)

    // Az editor-only metrika-kártyák, kalkulátor és vezérlés NEM jelennek meg.
    expect(screen.queryByText('Polling státusz')).not.toBeInTheDocument()
    expect(screen.queryByText('ECB snapshot')).not.toBeInTheDocument()
    expect(screen.queryByText('Piaci összehasonlítás')).not.toBeInTheDocument()
    expect(screen.queryByText('Árfolyam kalkulátor')).not.toBeInTheDocument()
    expect(screen.queryByTestId('rate-polling-control-panel')).not.toBeInTheDocument()
    expect(screen.queryAllByTitle('Szerkesztés')).toHaveLength(0)

    // A read-only nézet a területi munkacsoport-árfolyamokat kéri (itt üres → fallback tábla).
    expect(mocks.territoryWorkgroupRates).toHaveBeenCalled()
    // Read-only módban az editor-only háttér-hívások NEM futnak (lean betöltés).
    expect(mocks.pollingStatus).not.toHaveBeenCalled()
    expect(mocks.bankRates).not.toHaveBeenCalled()
    expect(mocks.calculatorMatrix).not.toHaveBeenCalled()
    expect(mocks.roundingRulesList).not.toHaveBeenCalled()
  })

  it('FK-041: read-only TERÜLETI nézet — munkacsoportonkénti variánsok a pénztárnevekkel', async () => {
    mocks.useAppMode.mockReturnValue({ mode: 'ertektar' })
    mocks.territoryWorkgroupRates.mockResolvedValue([
      {
        workgroupId: 'wg-belvaros',
        workgroupCode: 'WG01',
        workgroupName: 'Belváros',
        tileColor: 'blue',
        branchNames: ['Tisza Sarok', 'Árkád'],
        limit1Boundary: 50000,
        limit2Boundary: 300000,
        limit3Boundary: 1000000,
        currencies: [
          {
            currencyId: 1,
            currencyCode: 'EUR',
            currencyName: 'Euró',
            hasRate: true,
            baseBuyRate: 343.0,
            baseSellRate: 362.99,
            officialRate: 352.68,
            limit1Amount: 50000,
            limit1BuyRate: 343.5,
            limit1SellRate: 362.49,
            limit2Amount: null,
            limit2BuyRate: null,
            limit2SellRate: null,
            limit3Amount: null,
            limit3BuyRate: null,
            limit3SellRate: null,
            validTime: '15:12',
          },
        ],
      },
      {
        workgroupId: 'wg-plazak',
        workgroupCode: 'WG02',
        workgroupName: 'Plázák',
        tileColor: 'amber',
        branchNames: ['Tesco', 'Móra'],
        limit1Boundary: 50000,
        limit2Boundary: 300000,
        limit3Boundary: 1000000,
        currencies: [
          {
            currencyId: 1,
            currencyCode: 'EUR',
            currencyName: 'Euró',
            hasRate: true,
            baseBuyRate: 341.5,
            baseSellRate: 364.5,
            officialRate: 352.68,
            limit1Amount: null,
            limit1BuyRate: null,
            limit1SellRate: null,
            limit2Amount: null,
            limit2BuyRate: null,
            limit2SellRate: null,
            limit3Amount: null,
            limit3BuyRate: null,
            limit3SellRate: null,
            validTime: '15:12',
          },
        ],
      },
    ])
    render(<RatesPage />)

    const table = await screen.findByTestId('rates-territory-table')
    expect(mocks.territoryWorkgroupRates).toHaveBeenCalled()
    // Munkacsoport-variánsok a címsorban + a hozzájuk tartozó pénztárnevek.
    expect(within(table).getByText('Belváros')).toBeInTheDocument()
    expect(within(table).getByText('Plázák')).toBeInTheDocument()
    expect(within(table).getByText(/Tisza Sarok/)).toBeInTheDocument()
    expect(within(table).getByText(/Tesco/)).toBeInTheDocument()
    // A két variáns ELTÉRŐ alap árfolyama egy sorban (EUR).
    expect(within(table).getAllByText(/343[.,]00/).length).toBeGreaterThan(0)
    expect(within(table).getAllByText(/341[.,]50/).length).toBeGreaterThan(0)
    // FK-041 review: a kedvezmény-sáv (limit1 vétel 343,50) és a cellánkénti frissítési idő is látszik.
    expect(within(table).getAllByText(/343[.,]50/).length).toBeGreaterThan(0)
    expect(within(table).getAllByText(/frissítve 15:12/).length).toBeGreaterThan(0)
    // Van területi adat → a sima fallback tábla NEM jelenik meg.
    expect(screen.queryByTestId('rates-readonly-table')).not.toBeInTheDocument()
    // Szerkesztő-eszközök sincsenek.
    expect(screen.queryByText('Árfolyam kalkulátor')).not.toBeInTheDocument()
    expect(screen.queryByTestId('rate-polling-control-panel')).not.toBeInTheDocument()
  })
})
