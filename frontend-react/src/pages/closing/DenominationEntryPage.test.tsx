import { cleanup, render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import DenominationEntryPage from './DenominationEntryPage'

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

    await waitFor(() => expect(mocks.balancesSelfCheck).toHaveBeenCalledTimes(1))
    expect(mocks.balancesSelfCheck).toHaveBeenCalledWith('branch-1', 'EVENING')
  })
})
