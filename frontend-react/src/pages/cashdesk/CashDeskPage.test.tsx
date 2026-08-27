import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import CashDeskPage from './CashDeskPage'

const mocks = vi.hoisted(() => ({
  balanceList: vi.fn(),
  getSummary: vi.fn(),
  getByCurrencyId: vi.fn(),
  getByCurrencyCode: vi.fn(),
  getTodayStats: vi.fn(),
  getCurrentSession: vi.fn(),
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({
    t: (key: string) => key,
  }),
}))

vi.mock('../../services/api/index', () => ({
  cashBalanceApi: {
    list: mocks.balanceList,
    getSummary: mocks.getSummary,
    getByCurrencyId: mocks.getByCurrencyId,
    getByCurrencyCode: mocks.getByCurrencyCode,
    getTodayStats: mocks.getTodayStats,
  },
  dailySessionApi: {
    getCurrent: mocks.getCurrentSession,
  },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: {
    error: vi.fn(),
    success: vi.fn(),
    warning: vi.fn(),
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: {
    error: vi.fn(),
  },
}))

function renderPage() {
  render(
    <MemoryRouter>
      <CashDeskPage />
    </MemoryRouter>,
  )
}

describe('CashDeskPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.balanceList.mockResolvedValue([
      {
        id: 1,
        branchId: 'branch-1',
        branchName: 'Szeged',
        currencyId: 1,
        currencyCode: 'EUR',
        currencyName: 'Euró',
        currentBalance: 1200,
        openingBalance: 1000,
        dailyChange: 200,
        minBalance: 100,
        maxBalance: 5000,
        createdAt: '2026-06-19T08:00:00',
      },
      {
        id: 2,
        branchId: 'branch-1',
        branchName: 'Szeged',
        currencyId: 2,
        currencyCode: 'HUF',
        currencyName: 'Magyar forint',
        currentBalance: 250000,
        openingBalance: 200000,
        dailyChange: 50000,
        minBalance: 10000,
        maxBalance: 1000000,
        createdAt: '2026-06-19T08:00:00',
      },
    ])
    mocks.getSummary.mockResolvedValue({
      totalCurrencies: 2,
      hufBalance: 250000,
      lowBalanceAlerts: 1,
      highBalanceAlerts: 0,
      balances: [],
    })
    // FK-075 FR-5: a daily session mostantól CSAK a nyitva/zárva állapothoz kell —
    // szándékosan eltérő számlálókat adunk, hogy bizonyítsuk: a Mai statisztika
    // NEM innen, hanem az új today-stats végpontból jön.
    mocks.getCurrentSession.mockResolvedValue({
      status: 'OPEN',
      openedAt: '2026-06-19T08:00:00',
      openedByWorkerName: 'Teszt Elek',
      transactionCount: 99,
      buyTurnoverHuf: 111111,
      sellTurnoverHuf: 222222,
      handlingFeeTotal: 333333,
    })
    // FK-075 FR-5/FR-6: új, dedikált GET /cash-balances/today-stats végpont.
    mocks.getTodayStats.mockResolvedValue({
      transactions: 3,
      buyTotal: 100000,
      sellTotal: 90000,
      handlingFee: 2500,
    })
    const detail = {
      id: 1,
      branchId: 'branch-1',
      branchName: 'Szeged',
      currencyId: 1,
      currencyCode: 'EUR',
      currencyName: 'Euró',
      currentBalance: 1200,
      openingBalance: 1000,
      dailyChange: 200,
      minBalance: 100,
      maxBalance: 5000,
      createdAt: '2026-06-19T08:00:00',
    }
    mocks.getByCurrencyId.mockResolvedValue(detail)
    mocks.getByCurrencyCode.mockResolvedValue(detail)
  })

  it('megjeleníti a branch summary választ és sor-kattintásra részletező hívást indít valuta ID/kód alapján', async () => {
    const user = userEvent.setup()
    renderPage()

    await waitFor(() => expect(mocks.getSummary).toHaveBeenCalled())
    expect(await screen.findByText('250 000 common.ft')).toBeInTheDocument()

    // FK-075 FR-3: nincs külön (i) info-gomb, a teljes sor kattintható.
    await user.click(screen.getByRole('row', { name: /EUR/ }))

    await waitFor(() => {
      expect(mocks.getByCurrencyId).toHaveBeenCalledWith(1)
      expect(mocks.getByCurrencyCode).toHaveBeenCalledWith('EUR')
    })
    expect(await screen.findByText('EUR pénzkészlet részletek')).toBeInTheDocument()
    expect(screen.getByText('ID és kód egyezik')).toBeInTheDocument()
  })

  it('FK-075 FR-1/FR-2/FR-7/FR-8: nincs Bevét/Kivét gomb, jelzés-csempe, Címletek rács és pénztár nyitás/zárás gomb', async () => {
    renderPage()

    await waitFor(() => expect(mocks.balanceList).toHaveBeenCalled())
    await screen.findByText('250 000 common.ft')

    // FR-1: kézi pénzmozgatás gombjai eltávolítva
    expect(screen.queryByText('cashdesk.bevet')).not.toBeInTheDocument()
    expect(screen.queryByText('cashdesk.kivet')).not.toBeInTheDocument()
    // FR-2: Alacsony/Magas jelzés KPI-csempék eltávolítva
    expect(screen.queryByText('Alacsony jelzés')).not.toBeInTheDocument()
    expect(screen.queryByText('Magas jelzés')).not.toBeInTheDocument()
    // FR-7: Címletek (HUF) rács eltávolítva
    expect(screen.queryByText('cashdesk.cimletekHuf')).not.toBeInTheDocument()
    // FR-8: Pénztár zárás/nyitás eltávolítva, Napi zárás megmarad
    expect(screen.queryByText('cashdesk.penztarZaras')).not.toBeInTheDocument()
    expect(screen.queryByText('cashdesk.penztarNyitas')).not.toBeInTheDocument()
    expect(screen.getByText('misc.napiZaras')).toBeInTheDocument()
  })

  it('FK-075 FR-9: az oldal H1 címe az új cashdesk.pageTitle kulcsot használja', async () => {
    renderPage()

    await waitFor(() => expect(mocks.balanceList).toHaveBeenCalled())
    // A mock t(key) = key: az új dedikált kulcs jelenik meg, NEM a megosztott branch.branch.
    expect(await screen.findByText('cashdesk.pageTitle')).toBeInTheDocument()
    expect(screen.queryByText('branch.branch')).not.toBeInTheDocument()
  })

  it('FK-075 FR-5/FR-6: a Mai statisztika az új today-stats végpont értékeit mutatja (nem a session számlálóit)', async () => {
    renderPage()

    await waitFor(() => expect(mocks.getTodayStats).toHaveBeenCalled())

    // A today-stats mock értékei jelennek meg...
    expect(await screen.findByText('3')).toBeInTheDocument()
    expect(screen.getByText('100 000 common.ft')).toBeInTheDocument()
    expect(screen.getByText('90 000 common.ft')).toBeInTheDocument()
    // FR-6: "Beszedett kezelési díj" felirat + élő handlingFee érték
    // (hu-HU: minimumGroupingDigits=2 miatt a 4 jegyű 2500 nincs csoportosítva)
    expect(screen.getByText('cashdesk.beszedettKezelesiDij')).toBeInTheDocument()
    expect(screen.getByText('2500 common.ft')).toBeInTheDocument()

    // ...és a session eltérő számlálói NEM jelennek meg (adatforrás-csere bizonyítva).
    expect(screen.queryByText('99')).not.toBeInTheDocument()
    expect(screen.queryByText('cashdesk.napiEredmeny')).not.toBeInTheDocument()
  })

  it('FK-075 FR-3/FR-4: sor-kattintás részletek panelt nyit "Limit" mező nélkül', async () => {
    const user = userEvent.setup()
    renderPage()

    await waitFor(() => expect(mocks.balanceList).toHaveBeenCalled())
    await user.click(await screen.findByRole('row', { name: /EUR/ }))

    expect(await screen.findByText('EUR pénzkészlet részletek')).toBeInTheDocument()
    // FR-4: a panel mezői — Limit NINCS
    expect(screen.getByText('Aktuális')).toBeInTheDocument()
    expect(screen.getByText('Nyitó')).toBeInTheDocument()
    expect(screen.getByText('Napi változás')).toBeInTheDocument()
    expect(screen.getByText('Kód ellenőrzés')).toBeInTheDocument()
    expect(screen.queryByText('Limit')).not.toBeInTheDocument()
  })

  it('FK-075 TBD-3: a nyitott részletpanel követi a pollingot — lista-frissülésre a részletek CSENDben újratöltődnek', async () => {
    const user = userEvent.setup()
    renderPage()

    await waitFor(() => expect(mocks.balanceList).toHaveBeenCalled())
    await user.click(await screen.findByRole('row', { name: /EUR/ }))
    expect(await screen.findByText('EUR pénzkészlet részletek')).toBeInTheDocument()
    // A panelnyitás EGY fetch-párt indít — a frissítő effect első futása kihagyott
    // (nincs duplikált hívás a kattintáskori fetch mellé).
    expect(mocks.getByCurrencyId).toHaveBeenCalledTimes(1)
    // A panel a kattintáskori értéket mutatja (a listában is ott van — 2 előfordulás).
    expect(screen.getAllByText('1200').length).toBeGreaterThanOrEqual(2)

    // Polling-ciklus szimulálása: a 30 mp-es interval és a visibility-change is ugyanazt
    // a loadData-t hívja; a fő lista frissülése a részletpanelt is újratölti.
    mocks.getByCurrencyId.mockResolvedValueOnce({
      id: 1,
      branchId: 'branch-1',
      branchName: 'Szeged',
      currencyId: 1,
      currencyCode: 'EUR',
      currencyName: 'Euró',
      currentBalance: 1500,
      openingBalance: 1000,
      dailyChange: 500,
      minBalance: 100,
      maxBalance: 5000,
      createdAt: '2026-06-19T08:00:00',
    })
    mocks.getByCurrencyCode.mockResolvedValueOnce({
      id: 1,
      branchId: 'branch-1',
      branchName: 'Szeged',
      currencyId: 1,
      currencyCode: 'EUR',
      currencyName: 'Euró',
      currentBalance: 1500,
      openingBalance: 1000,
      dailyChange: 500,
      minBalance: 100,
      maxBalance: 5000,
      createdAt: '2026-06-19T08:00:00',
    })
    fireEvent(document, new Event('visibilitychange'))

    // A második fetch-pár megjött, és a panel az ÚJ értéket mutatja (nem a befagyottat).
    await waitFor(() => expect(mocks.getByCurrencyId).toHaveBeenCalledTimes(2))
    expect(await screen.findByText('1500')).toBeInTheDocument()
    // A polling-frissítés CSENDben történik: nincs hibaüzenet, nincs toast-meghívás.
    expect(screen.queryByText(/részletek betöltése sikertelen/)).not.toBeInTheDocument()
  })

  it('FK-075 TBD-3: a panel bezárása után a lista-frissítés NEM indít többé részletes fetch-et', async () => {
    const user = userEvent.setup()
    renderPage()

    await waitFor(() => expect(mocks.balanceList).toHaveBeenCalled())
    await user.click(await screen.findByRole('row', { name: /EUR/ }))
    expect(await screen.findByText('EUR pénzkészlet részletek')).toBeInTheDocument()

    await user.click(screen.getByRole('button', { name: 'Részletek bezárása' }))
    expect(screen.queryByText('EUR pénzkészlet részletek')).not.toBeInTheDocument()

    const callsBeforeRefresh = mocks.getByCurrencyId.mock.calls.length
    fireEvent(document, new Event('visibilitychange'))
    await waitFor(() => expect(mocks.balanceList).toHaveBeenCalledTimes(2))
    // A bezárt panelre nem fut részletes fetch.
    expect(mocks.getByCurrencyId).toHaveBeenCalledTimes(callsBeforeRefresh)
  })

  it('FK-075 TBD-3: sikertelen nyitás után a polling sikeres frissítése TÖRLI a hibaüzenetet', async () => {
    const user = userEvent.setup()
    renderPage()

    await waitFor(() => expect(mocks.balanceList).toHaveBeenCalled())
    // Az első betöltés hibára fut → a hibaüzenet megjelenik.
    mocks.getByCurrencyId.mockRejectedValueOnce(new Error('network'))
    mocks.getByCurrencyCode.mockRejectedValueOnce(new Error('network'))
    await user.click(await screen.findByRole('row', { name: /EUR/ }))
    expect(await screen.findByText('EUR részletek betöltése sikertelen')).toBeInTheDocument()

    // A következő polling-kör már sikeres → a részletek betöltődnek, és a korábbi
    // hibaüzenet törlődik (nem maradhat a friss adatok mellett — ellenor1 review).
    fireEvent(document, new Event('visibilitychange'))
    await waitFor(() => expect(mocks.getByCurrencyId).toHaveBeenCalledTimes(2))
    expect(await screen.findByText('EUR pénzkészlet részletek')).toBeInTheDocument()
    await waitFor(() =>
      expect(screen.queryByText(/részletek betöltése sikertelen/)).not.toBeInTheDocument(),
    )
  })
})
