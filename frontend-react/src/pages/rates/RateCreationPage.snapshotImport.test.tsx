import { render, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { importRateMakerSheetSnapshot } from './workgroupSheetStorage'

const MAIN_SHEET_KEY = 'arfolyamkeszito.mainSheet.v1'
const LOCAL_EDITS_KEY = 'arfolyamkeszito.mainSheet.localEdits.v1'
const SERVER_SAVED_AT = '2026-07-15T10:00:00.000Z'

const apiMocks = vi.hoisted(() => ({
  getLocalRateMakerBootstrap: vi.fn(),
  getLocalRateMakerSheet: vi.fn(),
  putLocalRateMakerSheet: vi.fn(),
}))

const storageSpies = vi.hoisted(() => ({ calls: [] as string[] }))

vi.mock('./workgroupSheetStorage', async (importOriginal) => {
  const real = await importOriginal<typeof import('./workgroupSheetStorage')>()
  return {
    ...real,
    exportRateMakerSheetSnapshot: vi.fn(
      (...args: Parameters<typeof real.exportRateMakerSheetSnapshot>) => {
        storageSpies.calls.push('export')
        return real.exportRateMakerSheetSnapshot(...args)
      },
    ),
    importRateMakerSheetSnapshot: vi.fn(
      (...args: Parameters<typeof real.importRateMakerSheetSnapshot>) => {
        storageSpies.calls.push('import')
        return real.importRateMakerSheetSnapshot(...args)
      },
    ),
  }
})

vi.mock('../../services/api/index', () => ({
  rateCreationApi: {
    getLocalRateMakerBootstrap: apiMocks.getLocalRateMakerBootstrap,
    getLocalRateMakerSheet: apiMocks.getLocalRateMakerSheet,
    putLocalRateMakerSheet: apiMocks.putLocalRateMakerSheet,
    getOverview: vi.fn(),
    getWorkgroupDetails: vi.fn(),
    prepareRateCreation: vi.fn(),
    prepareAllCurrencies: vi.fn(),
    updateWorkgroupLimits: vi.fn(),
    getBranches: vi.fn(),
    updateWorkgroupBranches: vi.fn(),
  },
  rateWorkgroupApi: {
    create: vi.fn(),
    update: vi.fn(),
    remove: vi.fn(),
  },
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))
vi.mock('react-router-dom', () => ({ useNavigate: () => vi.fn() }))
vi.mock('../../stores/authStore', () => ({
  useAuthStore: Object.assign(
    (selector: (state: unknown) => unknown) =>
      selector({ hasRole: vi.fn(() => true), hasCanonicalRole: vi.fn(() => true) }),
    { getState: () => ({ logout: vi.fn() }) },
  ),
}))
vi.mock('../../components/ui/toaster', () => ({
  toast: { success: vi.fn(), error: vi.fn(), warning: vi.fn(), info: vi.fn() },
}))
vi.mock('../../utils/logger', () => ({
  logger: { error: vi.fn(), info: vi.fn(), warn: vi.fn(), debug: vi.fn() },
}))
vi.mock('./publishAllWorkgroups', () => ({
  publishAllWorkgroups: vi.fn(),
  summarizePublishAll: vi.fn(),
}))
vi.mock('./components/RateGrid', () => ({ default: () => <div data-testid="rate-grid-stub" /> }))
vi.mock('./components/BranchPickerModal', () => ({ default: () => null }))

const localEurRow = {
  currency: 'EUR',
  settlement: 400,
  otp: 0,
  helper: 0,
  weakMultiBuy: 396,
  weakMultiSell: 405,
  crossSettlement: 0,
  crossRate: 0,
  wholesale: 0,
  crossBase: null,
}

const serverEurRow = { ...localEurRow, weakMultiBuy: 390, weakMultiSell: 410 }

function serverSheetJson(): string {
  return JSON.stringify({
    version: 1,
    savedAt: SERVER_SAVED_AT,
    entries: { [MAIN_SHEET_KEY]: JSON.stringify([serverEurRow]) },
  })
}

function seedLocalMainSheet(): { mainSheet: string; marker: string } {
  const mainSheet = JSON.stringify([localEurRow])
  const marker = JSON.stringify({
    'EUR.weakMultiBuy': Date.parse(SERVER_SAVED_AT) + 24 * 60 * 60 * 1000,
  })
  localStorage.setItem(MAIN_SHEET_KEY, mainSheet)
  localStorage.setItem(LOCAL_EDITS_KEY, marker)
  return { mainSheet, marker }
}

async function importPage() {
  const mod = await import('./RateCreationPage')
  return mod.default
}

describe('FK07-fix-2 — RateCreationPage snapshot-import baseline', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.stubEnv('VITE_APP_FLAVOR', 'rate-maker')
    localStorage.clear()
    storageSpies.calls.length = 0
    apiMocks.getLocalRateMakerBootstrap.mockResolvedValue({
      overview: { generatedAt: '2026-07-16T10:00:00.000Z', currencies: [] },
      workgroups: [],
    })
    apiMocks.getLocalRateMakerSheet.mockResolvedValue({ sheetJson: serverSheetJson(), version: 1 })
    apiMocks.putLocalRateMakerSheet.mockResolvedValue({ version: 2 })
  })

  it('az első await előtt exportált baseline-t adja át az importnak', async () => {
    const { mainSheet, marker } = seedLocalMainSheet()
    const Page = await importPage()

    render(<Page />)

    await waitFor(() => expect(importRateMakerSheetSnapshot).toHaveBeenCalledOnce())
    expect(storageSpies.calls.indexOf('export')).toBeGreaterThanOrEqual(0)
    expect(storageSpies.calls.indexOf('export')).toBeLessThan(storageSpies.calls.indexOf('import'))
    const baseline = vi.mocked(importRateMakerSheetSnapshot).mock.calls[0]?.[2]
    expect(baseline?.entries[MAIN_SHEET_KEY]).toBe(mainSheet)
    expect(baseline?.entries[LOCAL_EDITS_KEY]).toBe(marker)
  })

  it('a mount utáni storage-ban a védett lokális és a védetlen szerver-cella marad', async () => {
    const { marker } = seedLocalMainSheet()
    const Page = await importPage()

    render(<Page />)

    await waitFor(() => expect(importRateMakerSheetSnapshot).toHaveBeenCalledOnce())
    expect(JSON.parse(localStorage.getItem(MAIN_SHEET_KEY)!)[0]).toMatchObject({
      weakMultiBuy: 396,
      weakMultiSell: 410,
    })
    expect(localStorage.getItem(LOCAL_EDITS_KEY)).toBe(marker)
  })

  it('sikertelen szerver GET esetén nem importál és változatlanul hagyja a lokális állapotot', async () => {
    const { mainSheet, marker } = seedLocalMainSheet()
    apiMocks.getLocalRateMakerSheet.mockRejectedValue(new Error('502'))
    const Page = await importPage()

    render(<Page />)

    await waitFor(() => expect(apiMocks.getLocalRateMakerSheet).toHaveBeenCalledOnce())
    await waitFor(() => expect(apiMocks.getLocalRateMakerBootstrap).toHaveBeenCalledOnce())
    expect(importRateMakerSheetSnapshot).not.toHaveBeenCalled()
    expect(localStorage.getItem(MAIN_SHEET_KEY)).toBe(mainSheet)
    expect(localStorage.getItem(LOCAL_EDITS_KEY)).toBe(marker)
  })
})
