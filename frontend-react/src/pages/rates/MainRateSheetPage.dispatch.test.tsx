import { AxiosError } from 'axios'
import { act, fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const STORAGE_KEY = 'arfolyamkeszito.mainSheet.v1'

const mocks = vi.hoisted(() => ({
  hasRole: vi.fn(() => true),
  hasCanonicalRole: vi.fn(() => true),
  publishAllWorkgroups: vi.fn(),
  summarizePublishAll: vi.fn(),
  listActivePublished: vi.fn(() => Promise.resolve([])),
  listExchangeRates: vi.fn(() => Promise.resolve([])),
  toast: {
    success: vi.fn(),
    error: vi.fn(),
    warning: vi.fn(),
    info: vi.fn(),
  },
  catalog: {
    loading: false,
    error: null as Error | null,
    all: [
      {
        id: 1,
        code: 'EUR',
        name: 'Euró',
        symbol: '€',
        decimals: 2,
        displayOrder: 1,
        active: true,
      },
    ],
    currencies: [
      {
        id: 1,
        code: 'EUR',
        name: 'Euró',
        symbol: '€',
        decimals: 2,
        displayOrder: 1,
        active: true,
      },
    ],
    reload: vi.fn(),
  },
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))
vi.mock('../../utils/logger', () => ({
  logger: { error: vi.fn(), info: vi.fn(), warn: vi.fn(), debug: vi.fn() },
}))
vi.mock('../../components/ui/toaster', () => ({ toast: mocks.toast }))
vi.mock('react-router-dom', () => ({ useNavigate: () => vi.fn() }))
vi.mock('../../stores/authStore', () => ({
  useAuthStore: Object.assign(
    (selector: (state: unknown) => unknown) =>
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
  exchangeRateApi: { list: mocks.listExchangeRates },
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

type FailureKind = 'business' | 'transport'

const failed = (groupId: string, failureKind: FailureKind) => ({
  groupId,
  code: groupId.toUpperCase(),
  name: `${groupId}. csoport`,
  status: 'failed' as const,
  message: `${failureKind} hiba`,
  failureKind,
})

const result = (total: number, published: number, outcomes: Array<ReturnType<typeof failed>>) => ({
  total,
  published,
  outcomes,
})

function seedStorage(row = EUR_ROW) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify([row]))
}

async function importPage() {
  const module = await import('./MainRateSheetPage')
  return module.default
}

async function renderOnline(row = EUR_ROW) {
  seedStorage(row)
  const Page = await importPage()
  render(<Page />)
  await screen.findByText(/Online \(kp\. szerver\)/)
  return screen.getByTestId('dispatch-rates-button')
}

async function clickDispatch(button: HTMLElement) {
  await act(async () => {
    fireEvent.click(button)
  })
}

async function editCell(cellId: string, value: string) {
  const cell = document.getElementById(cellId) as HTMLInputElement
  await act(async () => fireEvent.keyDown(cell, { key: 'Enter' }))
  await act(async () => fireEvent.keyDown(cell, { key: 'F2' }))
  await act(async () => fireEvent.change(cell, { target: { value } }))
  await act(async () => fireEvent.keyDown(cell, { key: 'Enter' }))
}

describe('FK09 — MainRateSheetPage dispatch állapotkezelés', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
    mocks.hasRole.mockReturnValue(true)
    mocks.hasCanonicalRole.mockReturnValue(true)
    mocks.listActivePublished.mockResolvedValue([])
    mocks.listExchangeRates.mockResolvedValue([])
    mocks.summarizePublishAll.mockImplementation((publishResult) => {
      const failedCount = publishResult.outcomes.filter(
        (outcome: { status: string }) => outcome.status === 'failed',
      ).length
      return {
        title: failedCount === 0 ? 'Szétküldve' : 'Részben sikeres szétküldés',
        detail: `${publishResult.published}/${publishResult.total} munkacsoport elküldve`,
        ok: failedCount === 0,
      }
    })
    vi.spyOn(window, 'confirm').mockReturnValue(true)
  })

  it('FR-1/FR-5: 0 siker és csak business outcome után Online marad és azonnal újrapróbálható', async () => {
    mocks.publishAllWorkgroups.mockResolvedValue(
      result(2, 0, [failed('g1', 'business'), failed('g2', 'business')]),
    )
    const button = await renderOnline()

    await clickDispatch(button)

    await waitFor(() => expect(screen.getByText(/Online \(kp\. szerver\)/)).toBeVisible())
    expect(screen.queryByText(/Offline — helyi cache/)).not.toBeInTheDocument()
    expect(mocks.toast.error).toHaveBeenCalled()
    expect(button).toBeEnabled()
  })

  it('FR-2: 0 siker és transport outcome után Offline állapotba vált', async () => {
    mocks.publishAllWorkgroups.mockResolvedValue(result(2, 0, [failed('g1', 'transport')]))
    const button = await renderOnline()

    await clickDispatch(button)

    expect(await screen.findByText(/Offline — helyi cache/)).toBeVisible()
  })

  it('FR-2: eldobott network AxiosError után Offline állapotba vált', async () => {
    const error = new AxiosError('Network Error')
    error.code = 'ERR_NETWORK'
    mocks.publishAllWorkgroups.mockRejectedValue(error)
    const button = await renderOnline()

    await clickDispatch(button)

    expect(await screen.findByText(/Offline — helyi cache/)).toBeVisible()
  })

  it('FR-1: eldobott 403 AxiosError után Online marad és üzleti hibatoast jelenik meg', async () => {
    const error = new AxiosError('Request failed with status code 403')
    error.response = {
      status: 403,
      data: { message: 'Nincs jogosultság' },
    } as AxiosError['response']
    mocks.publishAllWorkgroups.mockRejectedValue(error)
    const button = await renderOnline()

    await clickDispatch(button)

    await waitFor(() => expect(screen.getByText(/Online \(kp\. szerver\)/)).toBeVisible())
    expect(screen.queryByText(/Offline — helyi cache/)).not.toBeInTheDocument()
    expect(mocks.toast.error).toHaveBeenCalledWith('Szétküldési hiba', expect.any(String))
    expect(button).toBeEnabled()
  })

  it('FR-3: 0 sikerű business hiba nem törli a módosítva jelzőt', async () => {
    mocks.publishAllWorkgroups.mockResolvedValue(result(1, 0, [failed('g1', 'business')]))
    const button = await renderOnline()
    await editCell('cell-0-weakMultiBuy', '396')
    expect(screen.getByText('● módosítva')).toBeVisible()

    await clickDispatch(button)

    expect(screen.getByText('● módosítva')).toBeVisible()
  })

  it('részleges siker Online marad, warningot ad és törli a módosítva jelzőt', async () => {
    mocks.publishAllWorkgroups.mockResolvedValue(result(5, 3, [failed('g4', 'business')]))
    const button = await renderOnline()
    await editCell('cell-0-weakMultiBuy', '396')
    expect(screen.getByText('● módosítva')).toBeVisible()

    await clickDispatch(button)

    await waitFor(() => expect(screen.queryByText('● módosítva')).not.toBeInTheDocument())
    expect(screen.getByText(/Online \(kp\. szerver\)/)).toBeVisible()
    expect(mocks.toast.warning).toHaveBeenCalled()
  })

  it('FR-4: confirm kivételnél a publishing finally visszaengedi a Szétküldés gombot', async () => {
    vi.mocked(window.confirm).mockImplementation(() => {
      throw new Error('confirm crash')
    })
    const button = await renderOnline({ ...EUR_ROW, weakMultiSell: 390 })

    fireEvent.click(button)

    await waitFor(() => expect(button).toBeEnabled())
    expect(screen.getByText(/Online \(kp\. szerver\)/)).toBeVisible()
  })
})
