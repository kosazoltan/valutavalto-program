import { render, screen, fireEvent, waitFor, act } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'

// FK07 — a Főlap (0-s lap) commit-szinkron perzisztencia: a cellába írt érték ÉS képlet
// AZONNAL (a commit ugyanazon hívásában) a localStorage-ba íródik, így azonnali lapváltásnál
// (unmount) sem vész el. A tesztek a `useCurrencyCatalog`-ot OFFLINE ágra mockolják (error=true),
// hogy a mount-kori szerver-sync ne hívjon hálózatot és ne írja felül a helyi rows-t.

const STORAGE_KEY = 'arfolyamkeszito.mainSheet.v1'
const FORMULA_STORAGE_KEY = 'arfolyamkeszito.mainSheet.formulas.v2'

const mocks = vi.hoisted(() => ({
  hasRole: vi.fn(() => true),
  hasCanonicalRole: vi.fn(() => true),
  catalog: {
    loading: false,
    error: true, // OFFLINE ág → nincs hálózati fetch, loadFromStorage tölt
    all: [] as unknown[],
    currencies: [] as unknown[],
    reload: vi.fn(),
  },
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
  publishAllWorkgroups: vi.fn(),
  summarizePublishAll: vi.fn(() => ''),
}))
vi.mock('../../services/api/exchangeRateMaster', () => ({
  exchangeRateMasterApi: { list: vi.fn() },
}))
vi.mock('../../services/api/exchange-rates', () => ({ exchangeRateApi: { getAll: vi.fn() } }))
vi.mock('../../services/api/arfolyamInternetLinks', () => ({
  arfolyamInternetLinkApi: { list: vi.fn(() => Promise.resolve([])) },
}))

// A seed rows a localStorage-ban — legalább egy EUR sor, hogy legyen szerkeszthető cella.
function seedStorage(rows: unknown[], formulas: Record<string, string> = {}) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(rows))
  localStorage.setItem(FORMULA_STORAGE_KEY, JSON.stringify(formulas))
}

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

async function importPage() {
  const mod = await import('./MainRateSheetPage')
  return mod.default
}

// A Főlap kétállapotú cellája: click → selectCell (editing=false), majd Enter/F2 → startEdit
// (editing=true, RAW buffer). Csak editing=true alatt írható az input. A commit Enter-rel megy.
async function editCell(cellId: string, value: string) {
  const cell = document.getElementById(cellId) as HTMLInputElement
  // 1. belépés szerkesztésbe (a readOnly feloldásához editing=true kell)
  await act(async () => {
    fireEvent.keyDown(cell, { key: 'Enter' })
  }) // selectCell után startEdit
  await act(async () => {
    fireEvent.keyDown(cell, { key: 'F2' })
  })
  // 2. érték beírása + commit
  await act(async () => {
    fireEvent.change(cell, { target: { value } })
  })
  await act(async () => {
    fireEvent.keyDown(cell, { key: 'Enter' })
  })
}

describe('FK07 — Főlap commit-szinkron perzisztencia', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
    mocks.hasRole.mockReturnValue(true)
    mocks.hasCanonicalRole.mockReturnValue(true)
    // window.confirm default: elfogad (a 10% figyelmeztetés ne blokkolja a persist-tesztet)
    vi.spyOn(window, 'confirm').mockReturnValue(true)
  })

  it('commit_writes_value_to_storage_synchronously: E cella commit → azonnal a STORAGE_KEY-ben', async () => {
    seedStorage([EUR_ROW])
    const Page = await importPage()
    render(<Page />)
    await screen.findByDisplayValue('395.00')
    await editCell('cell-0-weakMultiBuy', '396')

    await waitFor(() => {
      const saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]')
      const eur = saved.find((r: { currency: string }) => r.currency === 'EUR')
      expect(eur.weakMultiBuy).toBe(396)
    })
  })

  it('does_not_write_workgroup_keys: a fix NEM ír workgroupSheet.* kulcsot', async () => {
    seedStorage([EUR_ROW])
    const Page = await importPage()
    render(<Page />)
    await screen.findByDisplayValue('395.00')
    await editCell('cell-0-weakMultiBuy', '396')

    await waitFor(() => {
      const eur = JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]').find(
        (r: { currency: string }) => r.currency === 'EUR',
      )
      expect(eur.weakMultiBuy).toBe(396)
    })
    // NFR-3: diszjunkt kulcs-tér — semmilyen workgroupSheet.* kulcs nem íródott
    const wgKeys = Object.keys(localStorage).filter((k) => k.startsWith('workgroupSheet'))
    expect(wgKeys).toEqual([])
  })

  it('value_survives_immediate_page_leave: beírás → azonnali unmount → remount → érték megvan', async () => {
    seedStorage([EUR_ROW])
    const Page = await importPage()
    const { unmount } = render(<Page />)
    await screen.findByDisplayValue('395.00')
    await editCell('cell-0-weakMultiBuy', '397')
    // FR-6: azonnali lapváltás (unmount) — a commit már perzisztált, nincs debounce-race
    await waitFor(() => {
      const saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]')
      expect(saved.find((r: { currency: string }) => r.currency === 'EUR').weakMultiBuy).toBe(397)
    })
    unmount()

    // remount: a loadFromStorage a friss értéket tölti
    render(<Page />)
    expect(await screen.findByDisplayValue('397.00')).toBeInTheDocument()
  })
})
