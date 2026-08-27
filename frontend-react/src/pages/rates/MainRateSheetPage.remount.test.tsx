import { render, screen, act, fireEvent, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'

// FK07-fix — Főlap remount-kori felülírás (ONLINE ág): a mount-kori szerver-szinkron
// NEM írhatja felül a frissen mentett, de még ki nem küldött helyi módosítást.
// FONTOS (NFR-1): ez a teszt NEM mockolja offline-ra a katalógust — a valós online
// merge-ágat futtatja (listActivePublished + MNB list), realisztikus mockokkal.

const STORAGE_KEY = 'arfolyamkeszito.mainSheet.v1'
const LOCAL_EDIT_STORAGE_KEY = 'arfolyamkeszito.mainSheet.localEdits.v1'

const mocks = vi.hoisted(() => ({
  hasRole: vi.fn(() => true),
  hasCanonicalRole: vi.fn(() => true),
  // ONLINE katalógus: EUR az egyetlen valuta (stabil, determinisztikus sorlista)
  catalog: {
    loading: false,
    error: false,
    all: [{ id: 1, code: 'EUR', active: true }] as unknown[],
    currencies: [{ code: 'EUR' }] as unknown[],
    reload: vi.fn(),
  },
  // Szerver publikált master ráta: A=400, E=390, F=410 — a merge ezekkel írna felül
  listActivePublished: vi.fn(() =>
    Promise.resolve([
      {
        currencyCode: 'EUR',
        currencyId: 1,
        officialRate: 400,
        baseBuyRate: 390,
        baseSellRate: 410,
      },
    ]),
  ),
  mnbList: vi.fn(() => Promise.resolve([])),
  publishAllWorkgroups: vi.fn(() => Promise.resolve({ published: 1, total: 1, failures: [] })),
  summarizePublishAll: vi.fn(() => ({ ok: true, title: 'Kiküldve', detail: 'OK' })),
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (k: string) => k }),
}))
vi.mock('../../utils/logger', () => ({
  logger: { error: vi.fn(), info: vi.fn(), warn: vi.fn(), debug: vi.fn() },
}))
vi.mock('../../components/ui/toaster', () => ({
  toast: { success: vi.fn(), error: vi.fn(), warning: vi.fn(), info: vi.fn() },
}))
vi.mock('react-router-dom', () => ({ useNavigate: () => vi.fn() }))
vi.mock('../../stores/authStore', () => ({
  useAuthStore: Object.assign(
    (selector: (s: unknown) => unknown) =>
      selector({ hasRole: mocks.hasRole, hasCanonicalRole: mocks.hasCanonicalRole }),
    { getState: () => ({ logout: vi.fn() }) },
  ),
}))
vi.mock('../../hooks/useCurrencyCatalog', () => ({
  useCurrencyCatalog: () => mocks.catalog,
  getCrossBase: () => null,
}))
vi.mock('./publishAllWorkgroups', () => ({
  publishAllWorkgroups: mocks.publishAllWorkgroups,
  summarizePublishAll: mocks.summarizePublishAll,
}))
vi.mock('../../services/api/exchangeRateMaster', () => ({
  exchangeRateMasterApi: { listActivePublished: mocks.listActivePublished },
}))
vi.mock('../../services/api/exchange-rates', () => ({
  exchangeRateApi: { list: mocks.mnbList },
}))
vi.mock('../../services/api/arfolyamInternetLinks', () => ({
  arfolyamInternetLinkApi: { list: vi.fn(() => Promise.resolve([])) },
}))

const EUR_ROW = {
  currency: 'EUR',
  settlement: 400,
  otp: 0,
  helper: 0,
  weakMultiBuy: 395,
  weakMultiSell: 405,
  crossRate: 0,
  wholesale: 0,
  crossBase: null,
  crossSettlement: 0,
  settlementManual: false,
}

function seedStorage(rows: unknown[]) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(rows))
}

async function importPage() {
  const mod = await import('./MainRateSheetPage')
  return mod.default
}

// Kétállapotú cella: Enter (startEdit) → F2 → change → Enter (commit)
async function editCell(cellId: string, value: string) {
  const cell = document.getElementById(cellId) as HTMLInputElement
  await act(async () => {
    fireEvent.keyDown(cell, { key: 'Enter' })
  })
  await act(async () => {
    fireEvent.keyDown(cell, { key: 'F2' })
  })
  await act(async () => {
    fireEvent.change(cell, { target: { value } })
  })
  await act(async () => {
    fireEvent.keyDown(cell, { key: 'Enter' })
  })
}

describe('FK07-fix — Főlap remount-kori felülírás ONLINE módban', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
    mocks.hasRole.mockReturnValue(true)
    mocks.hasCanonicalRole.mockReturnValue(true)
    vi.spyOn(window, 'confirm').mockReturnValue(true)
  })

  it('online_remount_preserves_unsent_local_edit: commit → unmount → remount → a helyi érték marad (FR-1, FR-2, FR-5)', async () => {
    seedStorage([EUR_ROW])
    const Page = await importPage()

    // 1. mount: online sync lefut, a szerver E=390-re állít
    const first = render(<Page />)
    expect(await screen.findByDisplayValue('390.00')).toBeInTheDocument()

    // 2. helyi commit: E = 396 (ki nem küldött módosítás)
    await editCell('cell-0-weakMultiBuy', '396')
    await waitFor(() => {
      const saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]')
      expect(saved.find((r: { currency: string }) => r.currency === 'EUR').weakMultiBuy).toBe(396)
    })

    // 3. lapváltás: unmount → remount (a dirtyRef in-memory védelem itt elveszik)
    first.unmount()
    render(<Page />)

    // 4. a mount-kori szerver-szinkron lefut — előbb a sync lefutását várjuk be
    //    (F=410 szerver-érték megjelenése), utána assertáljuk a helyi 396 megmaradását
    //    (a bug: a merge visszaírta a szerver 390-ét)
    expect(await screen.findByDisplayValue('410.00')).toBeInTheDocument()
    expect(screen.getByDisplayValue('396.00')).toBeInTheDocument()
    expect(screen.queryByDisplayValue('390.00')).not.toBeInTheDocument()
  })

  it('online_remount_still_applies_server_value_when_no_local_edit: jelző nélkül a szerver-érték érvényesül (NFR-2)', async () => {
    seedStorage([EUR_ROW]) // cache: E=395, de NINCS helyi-módosítás jelző
    const Page = await importPage()
    render(<Page />)
    // a szerver 390-e felülírja a cache 395-öt — a normál működés nem törik el
    expect(await screen.findByDisplayValue('390.00')).toBeInTheDocument()
  })

  it('only_edited_cell_is_protected: két cella közül csak a szerkesztett védett (edge case)', async () => {
    seedStorage([EUR_ROW])
    const Page = await importPage()
    const first = render(<Page />)
    expect(await screen.findByDisplayValue('390.00')).toBeInTheDocument()

    // csak az E (vétel) cellát szerkesztjük; az F (eladás) marad szerver-vezérelt
    await editCell('cell-0-weakMultiBuy', '396')
    await waitFor(() => {
      const saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]')
      expect(saved.find((r: { currency: string }) => r.currency === 'EUR').weakMultiBuy).toBe(396)
    })
    first.unmount()
    render(<Page />)

    // ELŐBB a szerver-sync lefutását várjuk be (F=410 a szerver-érték megjelenése jelzi),
    // és CSAK UTÁNA assertáljuk az E védettségét — különben a cache-es 396 a sync ELŐTT
    // is megtalálható lenne (hamis zöld).
    expect(await screen.findByDisplayValue('410.00')).toBeInTheDocument() // F: szerver-érték (sync kész)
    expect(screen.getByDisplayValue('396.00')).toBeInTheDocument() // E: helyi, védett
    expect(screen.queryByDisplayValue('390.00')).not.toBeInTheDocument()
  })

  it('local_edit_flag_cleared_after_successful_dispatch: sikeres szétküldés után a jelző törlődik (FR-3)', async () => {
    seedStorage([EUR_ROW])
    const Page = await importPage()
    const first = render(<Page />)
    expect(await screen.findByDisplayValue('390.00')).toBeInTheDocument()

    await editCell('cell-0-weakMultiBuy', '396')
    // a commit perzisztált jelzőt írt
    await waitFor(() => {
      const flags = JSON.parse(localStorage.getItem(LOCAL_EDIT_STORAGE_KEY) || '{}')
      expect(Object.keys(flags).length).toBeGreaterThan(0)
    })

    // sikeres szétküldés (publishAllWorkgroups teljes siker)
    const btn = screen.getByTestId('dispatch-rates-button')
    await act(async () => {
      fireEvent.click(btn)
    })
    await waitFor(() => {
      expect(mocks.publishAllWorkgroups).toHaveBeenCalled()
      const flags = JSON.parse(localStorage.getItem(LOCAL_EDIT_STORAGE_KEY) || '{}')
      expect(Object.keys(flags)).toEqual([])
    })

    // a következő remountnál a szerver értéke már felülírhat (nincs beragadt felülbírálás)
    first.unmount()
    render(<Page />)
    expect(await screen.findByDisplayValue('390.00')).toBeInTheDocument()
  })
})
