import { cleanup, render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import DenominationEntryPage from './DenominationEntryPage'
import { formatDecimal } from '../../utils/numberFormat'

/**
 * FK-078 — kozos, kategoria-tudatos becimletezo oldal.
 *
 *  FR-2: szabad, ismetelt mentes zarasi munkamenet inditasa nelkul.
 *  FR-3: a mentes a helyes kategoriat kuldi (EVENING / HANDLING_FEE).
 *  FR-4: mentes utan penznemenkenti zold/piros egyezes-jelzes — KIZAROLAG EVENING-en,
 *        es nem blokkolo.
 *  FR-5: „Napi zárás végrehajtása” gomb — ez, es csak ez viszi a zaras-varazslora.
 *
 *  Atvett lefedettseg a torolt DenominationPage.fk072 / fk077-fk079 tesztekbol
 *  (spec 9.4 Fazis 2 kotelezo eloiras): tort (1 alatti) nevertekű cimlethez az UJ oldalon
 *  sem a tablazatban, sem az osszegzesben, sem a mentes-payloadban nem kerulhet ertek.
 */

const mocks = vi.hoisted(() => ({
  currencyGetActive: vi.fn(),
  denominationGetByCurrencyId: vi.fn(),
  balancesGetByCurrency: vi.fn(),
  balancesSetQuantities: vi.fn(),
  balancesSelfCheck: vi.fn(),
  navigate: vi.fn(),
  toastSuccess: vi.fn(),
  toastWarning: vi.fn(),
  toastError: vi.fn(),
  hasCanonicalRole: vi.fn((_roles: string | string[]) => false),
}))

let categoryParam = 'EVENING'

// FKH-036 FR-4: a useSearchParams mockja — a returnTo query-paraméter vezérli a Kilépés célját.
let searchParamsValue = new URLSearchParams()

vi.mock('react-router-dom', () => ({
  useNavigate: () => mocks.navigate,
  useParams: () => ({ category: categoryParam }),
  useSearchParams: () => [searchParamsValue, vi.fn()],
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: unknown) => unknown) =>
    selector({
      worker: { id: 'worker-1', branchId: 'branch-1', role: 'CASHIER' },
      activeRole: 'CASHIER',
      hasCanonicalRole: mocks.hasCanonicalRole,
    }),
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: {
    success: mocks.toastSuccess,
    warning: mocks.toastWarning,
    error: mocks.toastError,
  },
}))

vi.mock('../../services/api/index', () => ({
  currencyApi: { getActive: mocks.currencyGetActive },
  denominationApi: { getByCurrencyId: mocks.denominationGetByCurrencyId },
  denominationBalanceApi: {
    getCashDeskDenominationsByCurrency: mocks.balancesGetByCurrency,
    setDenominationQuantities: mocks.balancesSetQuantities,
    selfCheck: mocks.balancesSelfCheck,
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

/** FKH-042 T3b: kétvalutás törzs — a valuta-váltás a már lekért tömböt szűri, nem hív újra. */
const TWO_CURRENCIES = [
  { id: 1, code: 'EUR', name: 'Euró' },
  { id: 2, code: 'HUF', name: 'Forint' },
]
const SELF_CHECK_TWO = [
  {
    currencyCode: 'EUR',
    currencyId: 1,
    denominatedAmount: 0,
    expectedBalance: 150,
    difference: -150,
    matches: false,
  },
  {
    currencyCode: 'HUF',
    currencyId: 2,
    denominatedAmount: 0,
    expectedBalance: 5000,
    difference: -5000,
    matches: false,
  },
]

/**
 * FKH-042 P1: a `formatDecimal` hu-HU lokalizációja U+00A0 (NBSP) ezreselválasztót ad
 * ≥ 10 000 esetén — az ASCII-szóközös assert tévesen bukmna. Ez a normalizáló minden
 * összeg-assert előtt összecsukja a törhetetlen szóközöket.
 */
const normalizeAmount = (el: HTMLElement) => (el.textContent ?? '').replace(/[\u00a0\u202f]/g, ' ')

function renderPage() {
  return render(<DenominationEntryPage />)
}

beforeEach(() => {
  vi.clearAllMocks()
  categoryParam = 'EVENING'
  searchParamsValue = new URLSearchParams()
  mocks.hasCanonicalRole.mockReturnValue(false)
  mocks.currencyGetActive.mockResolvedValue([{ id: 1, code: 'EUR', name: 'Euró' }])
  mocks.denominationGetByCurrencyId.mockResolvedValue(EUR_DENOMINATIONS)
  mocks.balancesGetByCurrency.mockResolvedValue([])
  mocks.balancesSetQuantities.mockResolvedValue([])
  mocks.balancesSelfCheck.mockResolvedValue([])
})

describe('DenominationEntryPage — FK-078', () => {
  it('FR-1: EVENING kategóriával az esti zárás címletezése nyílik meg', async () => {
    renderPage()
    expect(await screen.findByTestId('denomination-entry-title')).toHaveTextContent(
      'Esti zárás címletezése',
    )
  })

  it('FR-1: HANDLING_FEE kategóriával a kezelési díj címletezése nyílik meg', async () => {
    categoryParam = 'HANDLING_FEE'
    renderPage()
    expect(await screen.findByTestId('denomination-entry-title')).toHaveTextContent(
      'Kezelési díj címletezése',
    )
  })

  it('FR-2/FR-3: a mentés EVENING kategóriát küld, és nem navigál el (ismételhető)', async () => {
    const user = userEvent.setup()
    renderPage()

    await user.type(await screen.findByTestId('denomination-entry-qty-10'), '3')
    await user.click(screen.getByTestId('denomination-entry-save'))

    await waitFor(() => expect(mocks.balancesSetQuantities).toHaveBeenCalledTimes(1))
    const call = mocks.balancesSetQuantities.mock.calls[0]!
    const [cashDeskId, updates, category] = call
    expect(cashDeskId).toBe('branch-1')
    expect(category).toBe('EVENING')
    expect(updates).toContainEqual({ denominationId: '10', quantity: 3 })
    // FR-2: a szabad mentés nem indít zárási munkamenetet és nem navigál el.
    expect(mocks.navigate).not.toHaveBeenCalled()
  })

  it('FR-3: a Kezelési díj felületről mentve HANDLING_FEE a kategória', async () => {
    categoryParam = 'HANDLING_FEE'
    const user = userEvent.setup()
    renderPage()

    await user.type(await screen.findByTestId('denomination-entry-qty-10'), '1')
    await user.click(screen.getByTestId('denomination-entry-save'))

    await waitFor(() => expect(mocks.balancesSetQuantities).toHaveBeenCalledTimes(1))
    expect(mocks.balancesSetQuantities.mock.calls[0]![2]).toBe('HANDLING_FEE')
  })

  it('FR-2: a „Mentés és visszalépés” a Címletezés – zárások oldalra visz', async () => {
    const user = userEvent.setup()
    renderPage()

    await user.click(await screen.findByTestId('denomination-entry-save-and-return'))

    await waitFor(() => expect(mocks.balancesSetQuantities).toHaveBeenCalledTimes(1))
    expect(mocks.navigate).toHaveBeenCalledWith('/closing/denominations-menu')
  })

  it('FR-4: egyezésnél zöld „Egyezik” jelzés jelenik meg pénznemenként', async () => {
    mocks.balancesSelfCheck.mockResolvedValue([
      {
        currencyCode: 'EUR',
        currencyId: 1,
        denominatedAmount: 150,
        expectedBalance: 150,
        difference: 0,
        matches: true,
      },
    ])
    const user = userEvent.setup()
    renderPage()

    await user.click(await screen.findByTestId('denomination-entry-save'))

    const row = await screen.findByTestId('denomination-entry-selfcheck-EUR')
    expect(row).toHaveTextContent('Egyezik')
    expect(row).toHaveTextContent('elvárt')
    expect(row.className).toContain('green')
  })

  it('FR-4: eltérésnél piros „Nem egyezik” jelzés a konkrét eltéréssel — de a mentés sikeres', async () => {
    mocks.balancesSelfCheck.mockResolvedValue([
      {
        currencyCode: 'EUR',
        currencyId: 1,
        denominatedAmount: 100,
        expectedBalance: 150,
        difference: -50,
        matches: false,
      },
    ])
    const user = userEvent.setup()
    renderPage()

    await user.click(await screen.findByTestId('denomination-entry-save'))

    const row = await screen.findByTestId('denomination-entry-selfcheck-EUR')
    expect(row).toHaveTextContent('Nem egyezik')
    expect(row).toHaveTextContent('-50')
    expect(row).toHaveTextContent('elvárt')
    expect(row.className).toContain('red')
    // Nem blokkoló: a mentés lefutott és sikerről szólt.
    expect(mocks.toastSuccess).toHaveBeenCalled()
  })

  it('FKH-039 FR-8/FR-9: HANDLING_FEE kategóriánál is fut az önellenőrzés, explicit elvárt összeggel', async () => {
    categoryParam = 'HANDLING_FEE'
    mocks.balancesSelfCheck.mockResolvedValue([
      {
        currencyCode: 'HUF',
        currencyId: 2,
        denominatedAmount: 5000,
        expectedBalance: 5000,
        difference: 0,
        matches: true,
      },
    ])
    const user = userEvent.setup()
    renderPage()

    await user.click(await screen.findByTestId('denomination-entry-save'))

    await waitFor(() =>
      expect(mocks.balancesSelfCheck).toHaveBeenCalledWith('branch-1', 'HANDLING_FEE'),
    )
    const row = await screen.findByTestId('denomination-entry-selfcheck-HUF')
    expect(row).toHaveTextContent('Egyezik')
    expect(row).toHaveTextContent('elvárt')
    expect(row).toHaveTextContent('5000')
    expect(row.className).toContain('green')
  })

  it('FKH-040: VAT kategóriánál is fut az önellenőrzés', async () => {
    categoryParam = 'VAT'
    mocks.balancesSelfCheck.mockResolvedValue([
      {
        currencyCode: 'HUF',
        currencyId: 2,
        denominatedAmount: 10000,
        expectedBalance: 10000,
        difference: 0,
        matches: true,
      },
    ])
    const user = userEvent.setup()
    renderPage()

    expect(await screen.findByTestId('denomination-entry-title')).toHaveTextContent(
      'ÁFA átadás-átvétel címletezése',
    )

    await user.click(await screen.findByTestId('denomination-entry-save'))

    await waitFor(() => expect(mocks.balancesSelfCheck).toHaveBeenCalledWith('branch-1', 'VAT'))
    const row = await screen.findByTestId('denomination-entry-selfcheck-HUF')
    expect(row).toHaveTextContent('Egyezik')
  })

  it('FKH-039 FR-2: vault kontextusban nincs „Mentés és visszalépés” gomb', async () => {
    mocks.hasCanonicalRole.mockImplementation((roles: string | string[]) => {
      const list = Array.isArray(roles) ? roles : [roles]
      return list.includes('ertektar') || list.includes('foertektar')
    })
    renderPage()

    expect(await screen.findByTestId('denomination-entry-exit')).toBeInTheDocument()
    expect(screen.queryByTestId('denomination-entry-save-and-return')).toBeNull()
  })

  it('FKH-039 FR-3: pénztári kontextusban mindkét gomb látható', async () => {
    renderPage()

    expect(await screen.findByTestId('denomination-entry-exit')).toBeInTheDocument()
    expect(screen.getByTestId('denomination-entry-save-and-return')).toBeInTheDocument()
  })

  it('FKH-039 FR-1: vault Kilépés ment, majd navigál', async () => {
    mocks.hasCanonicalRole.mockImplementation((roles: string | string[]) => {
      const list = Array.isArray(roles) ? roles : [roles]
      return list.includes('ertektar') || list.includes('foertektar')
    })
    searchParamsValue = new URLSearchParams('returnTo=/evening-closing')
    const user = userEvent.setup()
    renderPage()

    await user.click(await screen.findByTestId('denomination-entry-exit'))

    await waitFor(() => expect(mocks.balancesSetQuantities).toHaveBeenCalledTimes(1))
    expect(mocks.navigate).toHaveBeenCalledWith('/evening-closing')
  })

  it('FKH-039 FR-4: vault returnTo nélkül a Kilépés (mentés után) /evening-closing-re esik', async () => {
    mocks.hasCanonicalRole.mockImplementation((roles: string | string[]) => {
      const list = Array.isArray(roles) ? roles : [roles]
      return list.includes('ertektar') || list.includes('foertektar')
    })
    const user = userEvent.setup()
    renderPage()

    await user.click(await screen.findByTestId('denomination-entry-exit'))

    await waitFor(() => expect(mocks.balancesSetQuantities).toHaveBeenCalledTimes(1))
    expect(mocks.navigate).toHaveBeenCalledWith('/evening-closing')
    expect(mocks.navigate).not.toHaveBeenCalledWith('/cashier')
  })

  it('FR-4: az önellenőrzés hibája nem rontja el a sikeres mentést', async () => {
    mocks.balancesSelfCheck.mockRejectedValue(new Error('self-check 500'))
    const user = userEvent.setup()
    renderPage()

    await user.click(await screen.findByTestId('denomination-entry-save'))

    await waitFor(() => expect(mocks.toastSuccess).toHaveBeenCalled())
    expect(mocks.toastError).not.toHaveBeenCalled()
  })

  // FR-12 (FKH-036 kieg. #2): returnTo NÉLKÜL a viselkedés VÁLTOZATLAN — a beforeEach
  // üres URLSearchParams-e garantálja a pénztári kontextust (ticket C8).
  it('FR-5 / FR-12 (FKH-036 kieg. #2): a „Napi zárás végrehajtása” gomb returnTo nélkül a zárás-varázslóra visz', async () => {
    const user = userEvent.setup()
    renderPage()

    await user.click(await screen.findByTestId('denomination-entry-start-closing'))

    expect(mocks.navigate).toHaveBeenCalledWith('/closing/wizard')
    // FR-2/FR-5 elhatárolás: a zárás indítása nem mentés.
    expect(mocks.balancesSetQuantities).not.toHaveBeenCalled()
  })

  // ——— FKH-036 kieg. #2 FR-11: vault-kontextusú „Napi zárás végrehajtása” ———
  // A „küldés nélkül" assert strukturális: az oldal soha nem importál eveningClosingApi-t —
  // a vi.mock-blokk (:59-67) a három ismert API-n kívül mást nem mockol, és a navigate-mock
  // hívásain kívül semmilyen zárás-küldés nem figyelhető.

  it('FKH-036 kieg. #2 FR-11: vault returnTo esetén a „Napi zárás végrehajtása” a Napi zárás oldalra visz, küldés nélkül', async () => {
    searchParamsValue = new URLSearchParams('returnTo=/evening-closing')
    const user = userEvent.setup()
    renderPage()

    await user.click(await screen.findByTestId('denomination-entry-start-closing'))

    expect(mocks.navigate).toHaveBeenCalledWith('/evening-closing')
    expect(mocks.navigate).not.toHaveBeenCalledWith('/closing/wizard')
    expect(mocks.balancesSetQuantities).not.toHaveBeenCalled()
  })

  it('FKH-036 kieg. #2 FR-11: vault kontextusban a két gomb ugyanoda visz (Kilépés === Napi zárás végrehajtása)', async () => {
    mocks.hasCanonicalRole.mockImplementation((roles: string | string[]) => {
      const list = Array.isArray(roles) ? roles : [roles]
      return list.includes('ertektar') || list.includes('foertektar')
    })
    searchParamsValue = new URLSearchParams('returnTo=/evening-closing')
    const user = userEvent.setup()
    renderPage()

    await user.click(await screen.findByTestId('denomination-entry-start-closing'))
    await user.click(await screen.findByTestId('denomination-entry-exit'))

    expect(mocks.navigate).toHaveBeenNthCalledWith(1, '/evening-closing')
    await waitFor(() => expect(mocks.balancesSetQuantities).toHaveBeenCalled())
    expect(mocks.navigate).toHaveBeenCalledWith('/evening-closing')
  })

  it('FKH-036 kieg. #2 FR-11 biztonság: protokoll-relatív returnTo esetén a gomb a pénztári varázslóra esik vissza', async () => {
    searchParamsValue = new URLSearchParams('returnTo=//evil.example')
    const user = userEvent.setup()
    renderPage()

    await user.click(await screen.findByTestId('denomination-entry-start-closing'))

    expect(mocks.navigate).toHaveBeenCalledWith('/closing/wizard')
  })

  // ——— Átvett lefedettség a törölt DenominationPage.fk072 / fk077-fk079 tesztekből ———

  it('FK-079 örökség: tört névértékű címlet sora meg sem jelenik a táblázatban', async () => {
    renderPage()

    // Egész névértékek (50, 2, 1 — az EUR 1 és 2 is) jelen vannak.
    expect(await screen.findByTestId('denomination-entry-qty-10')).toBeInTheDocument()
    expect(screen.getByTestId('denomination-entry-qty-11')).toBeInTheDocument()
    expect(screen.getByTestId('denomination-entry-qty-12')).toBeInTheDocument()
    // A tört sorok (0,5 és 0,2) egyáltalán nincsenek a DOM-ban.
    expect(screen.queryByTestId('denomination-entry-qty-13')).toBeNull()
    expect(screen.queryByTestId('denomination-entry-qty-14')).toBeNull()
  })

  it('FK-079 örökség: a mentés payloadja tört névértékű sort nem tartalmaz', async () => {
    // Még ha egy korábbi mentés vissza is adna tört sorra mennyiséget, a payloadból kimarad.
    mocks.balancesGetByCurrency.mockResolvedValue([
      { denominationId: '13', quantity: 7 },
      { denominationId: '10', quantity: 2 },
    ])
    const user = userEvent.setup()
    renderPage()

    await user.click(await screen.findByTestId('denomination-entry-save'))

    await waitFor(() => expect(mocks.balancesSetQuantities).toHaveBeenCalledTimes(1))
    const updates = mocks.balancesSetQuantities.mock.calls[0]![1] as Array<{
      denominationId: string
    }>
    expect(updates.map((u) => u.denominationId)).not.toContain('13')
    expect(updates.map((u) => u.denominationId)).not.toContain('14')
    expect(updates.map((u) => u.denominationId)).toContain('10')
  })

  it('FK-079 örökség: a számított összeg a tört sorokat nem tartalmazza', async () => {
    // 13-as (0,5 EUR) sorra 10 db a szerverről: a tört sor nem növelheti az összeget.
    mocks.balancesGetByCurrency.mockResolvedValue([
      { denominationId: '13', quantity: 10 },
      { denominationId: '12', quantity: 6 },
    ])
    renderPage()

    // 6 x 1 EUR = 6,00 — a 10 x 0,5 EUR (5,00) NEM adódik hozzá.
    await waitFor(() =>
      expect(screen.getByTestId('denomination-entry-total')).toHaveTextContent('6,00'),
    )
  })

  it('FK-077 örökség: részleges betöltési hiba látható magyar üzenetet ad, nem üres képernyőt', async () => {
    mocks.balancesGetByCurrency.mockRejectedValue(new Error('404 requireOwnCashDesk'))
    renderPage()

    const alert = await screen.findByTestId('denomination-entry-load-error')
    expect(alert).toHaveTextContent('nem tölthető be')
    // A sikeres részeredmény (a címlettörzs) ettől még megjelenik.
    expect(screen.getByTestId('denomination-entry-qty-10')).toBeInTheDocument()
  })

  // ——— FKH-036 FR-4: kontextus-érzékeny Kilépés útvonal ———

  it('FKH-036 FR-4: returnTo paraméterrel a Kilépés az Értéktár Napi zárás oldalra visz', async () => {
    // Pénztári szerep + returnTo: mentés nélkül navigál (FKH-039 FR-3 — pénztár exit változatlan).
    searchParamsValue = new URLSearchParams('returnTo=/evening-closing')
    const user = userEvent.setup()
    renderPage()

    await user.click(await screen.findByTestId('denomination-entry-exit'))

    expect(mocks.navigate).toHaveBeenCalledWith('/evening-closing')
    expect(mocks.balancesSetQuantities).not.toHaveBeenCalled()
  })

  it('FKH-036 FR-4: returnTo nélkül a Kilépés változatlanul a /cashier-re visz', async () => {
    const user = userEvent.setup()
    renderPage()

    await user.click(await screen.findByTestId('denomination-entry-exit'))

    expect(mocks.navigate).toHaveBeenCalledWith('/cashier')
    expect(mocks.balancesSetQuantities).not.toHaveBeenCalled()
  })

  it('FKH-036 FR-4 biztonság: abszolút/protokoll-relatív returnTo elutasítva', async () => {
    const user = userEvent.setup()

    searchParamsValue = new URLSearchParams('returnTo=https://evil.example')
    renderPage()
    await user.click(await screen.findByTestId('denomination-entry-exit'))
    expect(mocks.navigate).toHaveBeenLastCalledWith('/cashier')

    cleanup()
    searchParamsValue = new URLSearchParams('returnTo=//evil.example')
    renderPage()
    await user.click(await screen.findByTestId('denomination-entry-exit'))
    expect(mocks.navigate).toHaveBeenLastCalledWith('/cashier')
  })

  // ——— FKH-038: kategória-tudatos betöltés (EVENING / HANDLING_FEE ne mosódjon össze) ———

  it('FKH-038 FR-3: HANDLING_FEE oldal a betöltő hívásban a HANDLING_FEE kategóriát küldi', async () => {
    categoryParam = 'HANDLING_FEE'
    renderPage()

    await waitFor(() =>
      expect(mocks.balancesGetByCurrency).toHaveBeenCalledWith('branch-1', '1', 'HANDLING_FEE'),
    )
  })

  it('FKH-038 FR-3: HANDLING_FEE oldalon a mennyiség-mező üres, ha nincs HANDLING_FEE sor', async () => {
    categoryParam = 'HANDLING_FEE'
    mocks.balancesGetByCurrency.mockResolvedValue([])
    renderPage()

    const qty = await screen.findByTestId('denomination-entry-qty-10')
    expect(qty).toHaveValue('')
  })

  it('FKH-038 FR-4: EVENING oldal a saját mennyiséget tölti be, HANDLING_FEE kategória nélkül', async () => {
    mocks.balancesGetByCurrency.mockResolvedValue([{ denominationId: '10', quantity: 4 }])
    renderPage()

    await waitFor(() =>
      expect(mocks.balancesGetByCurrency).toHaveBeenCalledWith('branch-1', '1', 'EVENING'),
    )
    await waitFor(() => expect(screen.getByTestId('denomination-entry-qty-10')).toHaveValue('4'))
    expect(mocks.balancesGetByCurrency).not.toHaveBeenCalledWith('branch-1', '1', 'HANDLING_FEE')
  })

  it('FKH-038 regresszió: EVENING mentés után az önellenőrzés továbbra is EVENING kategóriával fut', async () => {
    const user = userEvent.setup()
    renderPage()

    await user.click(await screen.findByTestId('denomination-entry-save'))

    // FKH-042 D13 (deklarált kontraktus-frissítés, nem tesztgyengítés): a mountkori
    // self-check (FR-1) új, szándékos viselkedés — így a mentés utáni hívással együtt
    // 2 hívás várható, és MINDKETTŐ a helyes EVENING kategóriával kell menjen
    // (FKH-038 regresszióőr — a kategória-assert sosem törlődik).
    await waitFor(() => expect(mocks.balancesSelfCheck).toHaveBeenCalledTimes(2))
    expect(
      mocks.balancesSelfCheck.mock.calls.every((c) => c[0] === 'branch-1' && c[1] === 'EVENING'),
    ).toBe(true)
  })
})

// ─────────────────────────────────────────────────────────────────────────────
// FKH-042 — Élő célösszeg („Elvárt készlet") a címlettáblázat FELETT (RED:
// a tesztek a még nem implementált viselkedést rögzítik).
//
//  FR-1: mountkor self-check hívás Mentés nélkül; a táblázat felett megjelenik
//        az „Elvárt készlet: X <CODE>".
//  FR-2: minden Darab-változás kliens-oldalon (0 extra API-hívás) frissíti az
//        eltérést: expectedBalance − calculatedTotal (pozitív = még hiányzik).
//  FR-3: EVENING / HANDLING_FEE / VAT — ugyanaz a komponens, nincs klón.
//  FR-4: a lap alji Önellenőrzés blokk megmarad (T5).
//  FR-5: az elvárt érték KIZÁRÓLAG a meglévő DTO expectedBalance-e (T6).
//
//  P1: az összeg-assertek a normalizeAmount() helperrel futnak (NBSP-elválasztó).
// ─────────────────────────────────────────────────────────────────────────────
describe('DenominationEntryPage — FKH-042 élő célösszeg', () => {
  const SELF_CHECK_EUR_150 = [
    {
      currencyCode: 'EUR',
      currencyId: 1,
      denominatedAmount: 0,
      expectedBalance: 150,
      difference: -150,
      matches: false,
    },
  ]

  it('T1 (FR-1): mountkor — Mentés nélkül — lefut a self-check, és az „Elvárt készlet" a táblázat fölé kerül', async () => {
    mocks.balancesSelfCheck.mockResolvedValue(SELF_CHECK_EUR_150)
    renderPage()

    await waitFor(() => expect(mocks.balancesSelfCheck).toHaveBeenCalledWith('branch-1', 'EVENING'))
    expect(mocks.balancesSelfCheck).toHaveBeenCalledTimes(1)

    expect(screen.getByTestId('denomination-entry-expected-panel')).toBeInTheDocument()
    const expected = normalizeAmount(await screen.findByTestId('denomination-entry-expected'))
    expect(expected).toContain('150,00')
    expect(expected).toContain('EUR')

    // FR-1: mindez Mentés nélkül — a payload-API nem hívódhat.
    expect(mocks.balancesSetQuantities).not.toHaveBeenCalled()
  })

  it('T1b (AC-2): az elvártkészlet-panel DOM-sorrendben a táblázat Összesen sora ELŐTT áll', async () => {
    mocks.balancesSelfCheck.mockResolvedValue(SELF_CHECK_EUR_150)
    renderPage()

    const panel = await screen.findByTestId('denomination-entry-expected-panel')
    const total = await screen.findByTestId('denomination-entry-total')
    // eslint-disable-next-line no-bitwise
    expect(panel.compareDocumentPosition(total) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy()
  })

  it('T2 (FR-2/AC-3): Darab-beírás az eltérést kliens-oldalon frissíti — nulla extra self-check hívás', async () => {
    mocks.balancesSelfCheck.mockResolvedValue([
      {
        currencyCode: 'EUR',
        currencyId: 1,
        denominatedAmount: 0,
        expectedBalance: 100,
        difference: -100,
        matches: false,
      },
    ])
    const user = userEvent.setup()
    renderPage()

    const qty = await screen.findByTestId('denomination-entry-qty-10')
    await user.type(qty, '2') // 2 × 50 EUR = 100

    await waitFor(() =>
      expect(normalizeAmount(screen.getByTestId('denomination-entry-total'))).toContain('100,00'),
    )
    await waitFor(() =>
      expect(normalizeAmount(screen.getByTestId('denomination-entry-diff'))).toContain('0,00'),
    )
    // AC-3: pontosan egy (mountkori) hívás — a Darab onChange sosem hív API-t.
    expect(mocks.balancesSelfCheck).toHaveBeenCalledTimes(1)
    expect(mocks.balancesSetQuantities).not.toHaveBeenCalled()
  })

  it('T3 (FR-2/D2): az élő eltérés előjele helyes — pozitív = még hiányzik, negatív = többlet', async () => {
    mocks.balancesSelfCheck.mockResolvedValue(SELF_CHECK_EUR_150)
    const user = userEvent.setup()
    renderPage()

    const qty = await screen.findByTestId('denomination-entry-qty-10')
    await user.type(qty, '1') // 1 × 50 = 50 → eltérés = 150 − 50 = +100

    await waitFor(() => {
      const diff = normalizeAmount(screen.getByTestId('denomination-entry-diff'))
      expect(diff).toContain('100,00')
      expect(diff).not.toContain('-')
    })

    await user.type(qty, '{backspace}4') // 4 × 50 = 200 → eltérés = 150 − 200 = −50
    await waitFor(() =>
      expect(normalizeAmount(screen.getByTestId('denomination-entry-diff'))).toContain('-50,00'),
    )
    expect(mocks.balancesSelfCheck).toHaveBeenCalledTimes(1)
  })

  it('T3b (D4): valuta-váltás a már lekért self-check tömböt szűri — nincs újrakérés', async () => {
    mocks.currencyGetActive.mockResolvedValue(TWO_CURRENCIES)
    mocks.balancesSelfCheck.mockResolvedValue(SELF_CHECK_TWO)
    const user = userEvent.setup()
    renderPage()

    const expectedBefore = normalizeAmount(await screen.findByTestId('denomination-entry-expected'))
    expect(expectedBefore).toContain('150,00')
    expect(expectedBefore).toContain('EUR')

    await user.selectOptions(await screen.findByTestId('denomination-entry-currency'), '2')

    await waitFor(() => {
      const expectedAfter = normalizeAmount(screen.getByTestId('denomination-entry-expected'))
      expect(expectedAfter).toContain('5000,00')
      expect(expectedAfter).toContain('HUF')
    })
    // D4: currency change does NOT refetch.
    expect(mocks.balancesSelfCheck).toHaveBeenCalledTimes(1)
  })

  it.each(['HANDLING_FEE', 'VAT'] as const)(
    'T4 (FR-3): %s kategórián ugyanaz a komponens adja a fejlécet, a helyes kategóriával hívva',
    async (category) => {
      categoryParam = category
      mocks.balancesSelfCheck.mockResolvedValue([
        {
          currencyCode: 'EUR',
          currencyId: 1,
          denominatedAmount: 0,
          expectedBalance: 9000,
          difference: -9000,
          matches: false,
        },
      ])
      renderPage()

      await waitFor(() =>
        expect(mocks.balancesSelfCheck).toHaveBeenCalledWith('branch-1', category),
      )
      const expected = normalizeAmount(await screen.findByTestId('denomination-entry-expected'))
      expect(expected).toContain('9000,00')
    },
  )

  it('T5 (FR-4 pin): Mentés után az alji Önellenőrzés blokk továbbra is megjelenik', async () => {
    mocks.balancesSelfCheck.mockResolvedValue(SELF_CHECK_EUR_150)
    const user = userEvent.setup()
    renderPage()

    await user.click(await screen.findByTestId('denomination-entry-save'))

    expect(await screen.findByTestId('denomination-entry-selfcheck')).toBeInTheDocument()
    expect(screen.getByTestId('denomination-entry-selfcheck-EUR')).toBeInTheDocument()
  })

  it('T6 (FR-5/AC-6): a fejléc és az alji blokk UGYANAZT a számot mutatja — egy API, nincs második formula', async () => {
    const shared = SELF_CHECK_EUR_150
    mocks.balancesSelfCheck.mockResolvedValue(shared)
    const user = userEvent.setup()
    renderPage()

    const headerBefore = normalizeAmount(await screen.findByTestId('denomination-entry-expected'))
    expect(headerBefore).toContain(formatDecimal(150, 2, 2))

    await user.click(await screen.findByTestId('denomination-entry-save'))

    await waitFor(() => expect(mocks.balancesSelfCheck).toHaveBeenCalledTimes(2))
    // Egy API, egy szám: a fejléc és a mentés utáni alji sor ugyanazt a 150,00-t mutatja.
    expect(normalizeAmount(screen.getByTestId('denomination-entry-expected'))).toContain(
      formatDecimal(150, 2, 2),
    )
    const bottomRow = screen.getByTestId('denomination-entry-selfcheck-EUR')
    expect(normalizeAmount(bottomRow)).toContain('150,00')
    // Mindkét hívás (mount + mentés) EVENING kategóriával ment.
    expect(mocks.balancesSelfCheck.mock.calls.map((c) => c[1])).toEqual(['EVENING', 'EVENING'])
  })

  it('T8 (FK-079 pin): a tört névértékű sor sem az összegbe, sem az élő eltérésbe nem szivárog', async () => {
    mocks.balancesGetByCurrency.mockResolvedValue([
      { denominationId: '13', quantity: 10 }, // 0,5 EUR × 10 — ki kell esnie
      { denominationId: '12', quantity: 6 }, // 1 EUR × 6 = 6,00
    ])
    mocks.balancesSelfCheck.mockResolvedValue([
      {
        currencyCode: 'EUR',
        currencyId: 1,
        denominatedAmount: 6,
        expectedBalance: 10,
        difference: -4,
        matches: false,
      },
    ])
    renderPage()

    await waitFor(() =>
      expect(normalizeAmount(screen.getByTestId('denomination-entry-total'))).toContain('6,00'),
    )
    // 10 − 6 = 4,00: a tört sor az élő eltérésbe sem folyik bele.
    await waitFor(() =>
      expect(normalizeAmount(screen.getByTestId('denomination-entry-diff'))).toContain('4,00'),
    )
  })

  it('E1 (D6): a mountkori self-check hiba néma — nincs toast, a táblázat nem ürül ki', async () => {
    mocks.balancesSelfCheck.mockRejectedValue(new Error('self-check 500'))
    renderPage()

    const expected = await screen.findByTestId('denomination-entry-expected')
    await waitFor(() => expect(expected.textContent).toBe('—'))
    // A táblázat (loadAll) ettől függetlenül renderel.
    expect(await screen.findByTestId('denomination-entry-qty-10')).toBeInTheDocument()
    expect(mocks.toastWarning).not.toHaveBeenCalled()
    expect(mocks.toastError).not.toHaveBeenCalled()
    expect(screen.queryByTestId('denomination-entry-load-error')).toBeNull()
  })

  it('E2 (D3/P6): ha a kiválasztott valutához nincs self-check sor, em-dash jelenik meg — sosem 0,00', async () => {
    mocks.balancesSelfCheck.mockResolvedValue([
      {
        currencyCode: 'USD',
        currencyId: 9,
        denominatedAmount: 0,
        expectedBalance: 7000,
        difference: -7000,
        matches: false,
      },
    ])
    renderPage()

    await waitFor(() =>
      expect(screen.getByTestId('denomination-entry-expected').textContent).toBe('—'),
    )
    expect(screen.getByTestId('denomination-entry-diff').textContent).toBe('—')
  })

  it('E3 (D3): currencyId-drift esetén a currencyCode fallback dönt', async () => {
    mocks.balancesSelfCheck.mockResolvedValue([
      {
        currencyCode: 'EUR',
        currencyId: 999, // id-drift: a kiválasztott EUR id=1, de a kód egyezik
        denominatedAmount: 0,
        expectedBalance: 150,
        difference: -150,
        matches: false,
      },
    ])
    renderPage()

    const expected = normalizeAmount(await screen.findByTestId('denomination-entry-expected'))
    expect(expected).toContain('150,00')
  })
})
