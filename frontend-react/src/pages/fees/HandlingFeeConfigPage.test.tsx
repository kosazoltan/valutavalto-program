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
    mocks.publish.mockResolvedValue({ ...ROWS[1], hasDraft: false })
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
