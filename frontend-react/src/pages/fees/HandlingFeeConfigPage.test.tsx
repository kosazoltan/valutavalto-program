import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import HandlingFeeConfigPage from './HandlingFeeConfigPage'

/**
 * FK-096 WU-10 — a TARTALOM CSERÉJE: a régi teszt a törölt probe-panel UI-t assertálta,
 * ezért a csomag RESZLETESEN újraírt (replacement, nem weakening — a commit-body jelzi).
 * Új lefedettség: összefoglaló kártyák, régió-szűrő, modal-nyitás, Mentés nem érinti a
 * LIVE oszlopot (FR-8), Küldés csak megerősítéssel (FR-9), pénztár mód = csak saját kártya (FR-14).
 */

const mocks = vi.hoisted(() => ({
  list: vi.fn(),
  saveDraft: vi.fn(),
  publish: vi.fn(),
  own: vi.fn(),
  loggerError: vi.fn(),
  appMode: { value: 'full' as string },
  roles: { value: ['ugyvezeto', 'foertektar', 'admin'] as string[] },
}))

vi.mock('../../hooks/useAppMode', () => ({
  useAppMode: () => ({ mode: mocks.appMode.value, isLoading: false }),
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: unknown) => unknown) =>
    selector({
      hasCanonicalRole: (roles: string[]) => roles.some((r) => mocks.roles.value.includes(r)),
    }),
}))

vi.mock('../../services/api/settings', () => ({
  branchFeeConfigApi: {
    list: mocks.list,
    saveDraft: mocks.saveDraft,
    publish: mocks.publish,
    own: mocks.own,
  },
  handlingFeeBracketApi: {
    get: vi.fn().mockResolvedValue({ live: [], draft: [] }),
    saveDraft: vi.fn(),
    publish: vi.fn(),
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: { error: mocks.loggerError },
}))

const ROWS = [
  {
    branchId: 'b1',
    branchCode: 'B01',
    branchName: 'Budapest 1',
    region: 'BUDAPEST',
    liveFeeMode: 'PER_MILLE',
    livePerMilleRate: 3.5,
    livePerMilleCap: 2000,
    hasDraft: false,
    draftFeeMode: null,
    draftPerMilleRate: null,
    draftPerMilleCap: null,
    version: 0,
  },
  {
    branchId: 'b2',
    branchCode: 'D01',
    branchName: 'Debrecen 1',
    region: 'DEBRECEN',
    liveFeeMode: 'BRACKET',
    livePerMilleRate: null,
    livePerMilleCap: null,
    hasDraft: true,
    draftFeeMode: 'PER_MILLE',
    draftPerMilleRate: 5,
    draftPerMilleCap: 1000,
    version: 2,
  },
]

const SUMMARY = { totalBranches: 2, configuredBranches: 2, bracketBranches: 1, perMilleBranches: 1 }

function renderPage() {
  render(<HandlingFeeConfigPage />)
}

describe('HandlingFeeConfigPage — admin nézet', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.appMode.value = 'full'
    mocks.roles.value = ['ugyvezeto', 'foertektar', 'admin']
    mocks.list.mockResolvedValue({ summary: SUMMARY, rows: ROWS })
  })

  it('megjeleníti a 4 összefoglaló kártyát', async () => {
    renderPage()
    expect(await screen.findByText('Összes pénztár')).toBeInTheDocument()
    expect(screen.getByText('KK beállítva')).toBeInTheDocument()
    // A 'Sávos'/'Ezrelékes' a táblában is megjelenik (KK típus oszlop) — getAllByText.
    expect(screen.getAllByText('Sávos').length).toBeGreaterThanOrEqual(1)
    expect(screen.getAllByText('Ezrelékes').length).toBeGreaterThanOrEqual(1)
  })

  it('a régió-szűrő leszűkíti a sorokat', async () => {
    const user = userEvent.setup()
    renderPage()
    await screen.findByText('B01')
    expect(screen.getByText('D01')).toBeInTheDocument()

    await user.selectOptions(screen.getByLabelText('Terület'), 'BUDAPEST')

    expect(screen.getByText('B01')).toBeInTheDocument()
    expect(screen.queryByText('D01')).not.toBeInTheDocument()
  })

  it('sor-kattintás megnyitja a modal-t', async () => {
    const user = userEvent.setup()
    renderPage()
    await screen.findByText('B01')

    await user.click(screen.getAllByText('B01')[0]!)

    expect(await screen.findByText(/Kezelési díj — B01/)).toBeInTheDocument()
  })

  it('a Küldés megerősítés NÉLKÜL nem hív publish-t', async () => {
    const user = userEvent.setup()
    renderPage()
    await screen.findByText('B01')
    await user.click(screen.getAllByText('B01')[0]!)

    // A modal-on belüli Küldés gomb (a bracket-szerkesztőnek is van Küldés gombja)
    const modalEl = (await screen.findByText(/Kezelési díj — B01/)).closest('.max-w-lg')
    const modal = modalEl as HTMLElement
    await user.click(within(modal).getByRole('button', { name: 'Küldés' }))

    // A megerősítő párbeszéd megjelenik, de publish még nem történik
    expect(await screen.findByRole('alertdialog')).toBeInTheDocument()
    expect(mocks.publish).not.toHaveBeenCalled()
  })

  it('a Küldés megerősítéssel pontosan egyszer hív publish-t a sor verziójával (FR-9)', async () => {
    const user = userEvent.setup()
    // ITEM 5 (R2-WU-9): a mock a VALÓS controller JSON-t adja — a publish válasz
    // BranchFeeConfigRowDto (sor-alakú): a LIVE oszlopok a publikált értéket hordozzák,
    // a DRAFT oszlopok kiürülnek, a verzió a publish utáni sor verziója.
    mocks.publish.mockResolvedValue({
      ...ROWS[1],
      liveFeeMode: 'PER_MILLE',
      livePerMilleRate: 5,
      livePerMilleCap: 1000,
      hasDraft: false,
      draftFeeMode: null,
      draftPerMilleRate: null,
      draftPerMilleCap: null,
      version: 3,
    })
    renderPage()
    await screen.findByText('D01')
    await user.click(screen.getAllByText('D01')[0]!)

    const modalEl = (await screen.findByText(/Kezelési díj — D01/)).closest('.max-w-lg')
    const modal = modalEl as HTMLElement
    await user.click(within(modal).getByRole('button', { name: 'Küldés' }))
    const dialog = await screen.findByRole('alertdialog')
    await user.click(within(dialog).getByRole('button', { name: 'Küldés megerősítése' }))

    await waitFor(() => {
      expect(mocks.publish).toHaveBeenCalledTimes(1)
    })
    // B2/N11: a verzió a sorból jön (itt 2), a törzsben utazik
    expect(mocks.publish).toHaveBeenCalledWith('b2', 2)
  })

  it('a publikálás után a LIVE oszlop frissül teljes újratöltés nélkül (ITEM 5)', async () => {
    const user = userEvent.setup()
    mocks.publish.mockResolvedValue({
      ...ROWS[1],
      liveFeeMode: 'PER_MILLE',
      livePerMilleRate: 5,
      livePerMilleCap: 1000,
      hasDraft: false,
      draftFeeMode: null,
      draftPerMilleRate: null,
      draftPerMilleCap: null,
      version: 3,
    })
    renderPage()
    await screen.findByText('D01')
    await user.click(screen.getAllByText('D01')[0]!)

    const modalEl = (await screen.findByText(/Kezelési díj — D01/)).closest('.max-w-lg')
    const modal = modalEl as HTMLElement
    await user.click(within(modal).getByRole('button', { name: 'Küldés' }))
    const dialog = await screen.findByRole('alertdialog')
    await user.click(within(dialog).getByRole('button', { name: 'Küldés megerősítése' }))

    // A sor-alakú válasz {...row, ...updated} merge-je a LIVE oszlopokat frissíti:
    // 3‰/Sávos helyett 5‰ + 1 000 Ft + Ezrelékes, a piszkozat-cella üres — mindez
    // a publish válaszából, lista-refetch NÉLKÜL.
    // (A Ft-formázást a komponens formatHuf-jával azonosan toLocaleString-gel építjük —
    // a hu-HU elválasztó whitespace-kódja környezetfüggő.)
    const tableRow = await screen.findByRole('row', { name: /D01/ })
    await waitFor(() => {
      expect(within(tableRow).getByText('5 ‰')).toBeInTheDocument()
    })
    expect(within(tableRow).getByText(`${(1000).toLocaleString('hu-HU')} Ft`)).toBeInTheDocument()
    expect(within(tableRow).getByText('Ezrelékes')).toBeInTheDocument()
    expect(within(tableRow).queryByText('Sávos')).not.toBeInTheDocument()
    expect(within(tableRow).queryByText('✎ van')).not.toBeInTheDocument()
    // Nincs refetch: a lista egyetlen betöltése a mount-kor történt.
    expect(mocks.list).toHaveBeenCalledTimes(1)
  })

  it('a saveDraft valasza sor-alaku es a LIVE oszlop VALTOZATLAN marad (FR-8)', async () => {
    const user = userEvent.setup()
    // ITEM 5 + FR-8: a saveDraft válasz a VALÓS sor-alakú DTO — a LIVE oszlopok
    // az ÉRINTETLEN értékeket hordozzák, csak a DRAFT oszlopok újak.
    mocks.saveDraft.mockResolvedValue({
      ...ROWS[1],
      liveFeeMode: 'BRACKET',
      livePerMilleRate: null,
      livePerMilleCap: null,
      hasDraft: true,
      draftFeeMode: 'PER_MILLE',
      draftPerMilleRate: 5,
      draftPerMilleCap: 1000,
      version: 3,
    })
    renderPage()
    await screen.findByText('D01')
    await user.click(screen.getAllByText('D01')[0]!)

    const modalEl = (await screen.findByText(/Kezelési díj — D01/)).closest('.max-w-lg')
    const modal = modalEl as HTMLElement
    await user.click(within(modal).getByRole('button', { name: 'Mentés (piszkozat)' }))

    await waitFor(() => {
      expect(mocks.saveDraft).toHaveBeenCalledTimes(1)
    })
    // FR-8: a LIVE oszlop változatlan (Sávos mód, '—' mérték), a piszkozat-jelölő megjelenik.
    const tableRow = await screen.findByRole('row', { name: /D01/ })
    expect(within(tableRow).getByText('Sávos')).toBeInTheDocument()
    expect(within(tableRow).getAllByText('—').length).toBeGreaterThanOrEqual(1)
    expect(within(tableRow).getByText('✎ van')).toBeInTheDocument()
    expect(mocks.list).toHaveBeenCalledTimes(1)
  })
})

describe('HandlingFeeConfigPage — pénztár mód (FR-14)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.appMode.value = 'penztar'
    mocks.roles.value = ['penztar']
    mocks.own.mockResolvedValue({
      branchId: 'b1',
      branchCode: 'B01',
      feeMode: 'PER_MILLE',
      perMilleRate: 3.5,
      perMilleCap: null,
      validFrom: '2026-08-26',
      brackets: [],
    })
  })

  it('pénztár módban CSAK a saját-iroda kártya jelenik meg (FR-14)', async () => {
    renderPage()

    expect(await screen.findByText(/Kezelési díj — B01 iroda \(read-only\)/)).toBeInTheDocument()
    // Admin vezérlők nem jelenhetnek meg
    expect(screen.queryByText('Összes pénztár')).not.toBeInTheDocument()
    expect(screen.queryByText('Közös kezelési díj sávok')).not.toBeInTheDocument()
    // És az admin lista-végpont sincs meghívva
    expect(mocks.list).not.toHaveBeenCalled()
  })
})
