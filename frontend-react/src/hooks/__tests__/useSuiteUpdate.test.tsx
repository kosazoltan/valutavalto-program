/**
 * useSuiteUpdate — a műszak-állapot jelentésének tesztjei.
 *
 * MIÉRT KELL: ez az állapot dönti el, hogy a pénztárgépen elindulhat-e a
 * suite-telepítő. Egy hibás leképezés vagy egy elnyelt hiba munka közbeni
 * telepítést okozhatna (nyitott kassza, folyamatban lévő napzárás), ezért a
 * fail-safe viselkedést gépileg rögzítjük.
 *
 * Szerződés: `docs/auto-update-terv-es-vegrehajtas.md` 3.6 szakasz.
 */

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { renderHook, waitFor } from '@testing-library/react'
import type { AppMode } from '../../types/appMode'
import {
  OPEN_DAY_OBSERVED_KEY,
  rememberOpenDayObservation,
  hasOpenDayObservedToday,
} from '../../utils/openDayMarker'

const isOpenMock = vi.fn()
// kanban #4 (FR-3): a napzaras UTANI ablak allapotforrasa a GET /daily-sessions/today.
const getTodaySessionMock = vi.fn()
const previewMock = vi.fn()
const setShiftStateMock = vi.fn((_state: string) =>
  Promise.resolve({ accepted: true, shiftState: _state }),
)
type SuiteStatus = {
  state: string
  shiftState: string
  readyVersion: string | null
  mandatory: boolean
}
const statusMock = vi.fn(
  (): Promise<SuiteStatus> =>
    Promise.resolve({
      state: 'IDLE',
      shiftState: 'SHIFT_OPEN',
      readyVersion: null,
      mandatory: false,
    }),
)
let readyCallback: ((payload: unknown) => void) | null = null
const onReadyMock = vi.fn((cb: (payload: unknown) => void) => {
  readyCallback = cb
  return () => {
    readyCallback = null
  }
})
let installFailedCallback: ((payload: unknown) => void) | null = null
const onInstallFailedMock = vi.fn((cb: (payload: unknown) => void) => {
  installFailedCallback = cb
  return () => {
    installFailedCallback = null
  }
})

vi.mock('../../services/api/index', () => ({
  dailySessionApi: {
    isOpen: () => isOpenMock(),
    getCurrent: () => getTodaySessionMock(),
    getTodaySession: () => getTodaySessionMock(),
  },
  eveningClosingApi: {
    preview: (...args: unknown[]) => previewMock(...args),
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: { info: vi.fn(), warn: vi.fn(), error: vi.fn() },
}))

const isElectronMock = vi.fn(() => true)
vi.mock('../../utils/electron', () => ({
  isElectron: () => isElectronMock(),
  getElectronAPI: () => ({
    suiteUpdate: {
      setShiftState: (state: string) => setShiftStateMock(state),
      status: () => statusMock(),
      onReady: (cb: (payload: unknown) => void) => onReadyMock(cb),
      onInstallFailed: (cb: (payload: unknown) => void) => onInstallFailedMock(cb),
      onProgress: () => () => {},
    },
  }),
}))

// FKH-041: a hook appMode-tudatos — a teszt az alapértelmezett penztar módban
// futtatja a meglévő eseteket (viselkedésük változatlan), az appMode-ágakat
// pedig külön, átírt mockkal vizsgálja.
const appModeMock = vi.fn((): { mode: AppMode; isLoading: boolean } => ({
  mode: 'penztar',
  isLoading: false,
}))
vi.mock('../useAppMode', () => ({
  useAppMode: () => appModeMock(),
}))

// FKH-041 round 2 (D6): a hook a kanonikus szerepet az auth store-ból olvassa
// (zéró-argumentumú hook, nem-selector destrukturálás). Alapértelmezés: penztár
// szerep, így a meglévő esetek BIZONYÍTOTT pénztáros munkamenetben futnak.
const authMock = vi.fn(
  (): {
    activeRole: string | null
    user: { role: string } | null
    worker: { branchId: string } | null
  } => ({
    activeRole: 'penztar',
    user: { role: 'penztar' },
    worker: { branchId: '1' },
  }),
)
vi.mock('../../stores/authStore', () => ({
  useAuthStore: () => authMock(),
}))

const { useSuiteUpdate, mapSessionToShiftState, clampIdleForAuthenticatedCashier } =
  await import('../useSuiteUpdate')

describe('mapSessionToShiftState — fail-safe leképezés', () => {
  it('nincs mai munkamenet -> napnyitás előtt (telepíthető)', () => {
    expect(mapSessionToShiftState(null)).toBe('IDLE_BEFORE_OPEN')
  })

  it('CLOSED status -> napzárás után (telepíthető)', () => {
    expect(mapSessionToShiftState({ status: 'CLOSED', closedAt: '2026-08-12T18:00:00Z' })).toBe(
      'CLOSED_AFTER_DAY_END',
    )
  })

  it('OPEN status -> nyitott műszak (NEM telepíthető)', () => {
    expect(mapSessionToShiftState({ status: 'OPEN' })).toBe('SHIFT_OPEN')
  })

  it('ismeretlen status -> konzervatívan nyitott műszak', () => {
    expect(mapSessionToShiftState({} as { status?: 'OPEN' | 'CLOSED' })).toBe('SHIFT_OPEN')
    expect(
      mapSessionToShiftState({ status: 'SZEMET' } as unknown as { status?: 'OPEN' | 'CLOSED' }),
    ).toBe('SHIFT_OPEN')
  })
})

describe('useSuiteUpdate — jelentés a main processnek', () => {
  beforeEach(() => {
    isOpenMock.mockReset()
    getTodaySessionMock.mockReset()
    previewMock.mockReset()
    previewMock.mockResolvedValue({ status: 'NOT_STARTED' })
    setShiftStateMock.mockClear()
    statusMock.mockClear()
    onReadyMock.mockClear()
    isElectronMock.mockReturnValue(true)
    appModeMock.mockReset()
    appModeMock.mockReturnValue({ mode: 'penztar' as const, isLoading: false })
    authMock.mockReset()
    authMock.mockReturnValue({
      activeRole: 'penztar',
      user: { role: 'penztar' },
      worker: { branchId: '1' },
    })
    readyCallback = null
    localStorage.clear()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('nyitott munkamenet -> SHIFT_OPEN jelentés', async () => {
    isOpenMock.mockResolvedValue(true)
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
  })

  it('G8b: nyitott munkamenet -> a nyitottnap-marker a mai napra íródik (C3)', async () => {
    isOpenMock.mockResolvedValue(true)
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
    expect(hasOpenDayObservedToday()).toBe(true)
  })

  it('lezárt napzárás -> CLOSED_AFTER_DAY_END jelentés', async () => {
    isOpenMock.mockResolvedValue(false)
    getTodaySessionMock.mockResolvedValue({ status: 'CLOSED', closedAt: '2026-08-12T18:00:00Z' })
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('CLOSED_AFTER_DAY_END'))
  })

  it('nincs mai munkamenet -> SHIFT_OPEN jelentés (hitelesített pénztáros soha nem IDLE)', async () => {
    // 2026-09-01 kanban #3: hitelesített pénztáros munkamenet SOHA nem nyithat
    // telepítési ablakot — a korábbi IDLE_BEFORE_OPEN várakozás hibás volt
    // (nap közbeni csendes telepítés + app.quit()).
    isOpenMock.mockResolvedValue(false)
    getTodaySessionMock.mockRejectedValue(new Error('404'))
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
    expect(setShiftStateMock).not.toHaveBeenCalledWith('IDLE_BEFORE_OPEN')
  })

  it('BACKEND HIBA -> SHIFT_OPEN (fail-safe: nem telepítünk)', async () => {
    // Ez a legfontosabb eset: egy hálózati hiba SOSEM vezethet munka közbeni
    // telepítéshez. Ha az állapot nem megállapítható, nyitott műszakot jelentünk.
    isOpenMock.mockRejectedValue(new Error('serverUnreachable'))
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
  })

  it('nem-Electron környezetben NEM jelent semmit', async () => {
    isElectronMock.mockReturnValue(false)
    isOpenMock.mockResolvedValue(true)
    renderHook(() => useSuiteUpdate())
    await new Promise((resolve) => setTimeout(resolve, 20))
    expect(setShiftStateMock).not.toHaveBeenCalled()
  })

  it('változatlan állapotot nem jelent újra (nincs IPC-zaj)', async () => {
    isOpenMock.mockResolvedValue(true)
    const { rerender } = renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledTimes(1))
    rerender()
    await new Promise((resolve) => setTimeout(resolve, 20))
    expect(setShiftStateMock).toHaveBeenCalledTimes(1)
  })

  it('az onReady jelzés megjelenik a visszatérési értékben', async () => {
    isOpenMock.mockResolvedValue(true)
    const { result } = renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(readyCallback).not.toBeNull())
    readyCallback?.({ version: '2.28.79', mandatory: false, notes: null, installableNow: false })
    await waitFor(() => expect(result.current.readyUpdate?.version).toBe('2.28.79'))
  })

  it('induláskori status() is felderíti a már készen álló frissítést', async () => {
    isOpenMock.mockResolvedValue(true)
    statusMock.mockResolvedValue({
      state: 'READY',
      shiftState: 'SHIFT_OPEN',
      readyVersion: '2.28.80',
      mandatory: true,
    })
    const { result } = renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(result.current.readyUpdate?.version).toBe('2.28.80'))
    // Nyitott műszak alatt nem telepíthető.
    expect(result.current.readyUpdate?.installableNow).toBe(false)
  })
})

describe('useSuiteUpdate — appMode-tudatos jelentés (FKH-041 FR-3)', () => {
  beforeEach(() => {
    isOpenMock.mockReset()
    getTodaySessionMock.mockReset()
    previewMock.mockReset()
    previewMock.mockResolvedValue({ status: 'NOT_STARTED' })
    setShiftStateMock.mockClear()
    statusMock.mockClear()
    onReadyMock.mockClear()
    isElectronMock.mockReturnValue(true)
    appModeMock.mockReset()
    appModeMock.mockReturnValue({ mode: 'penztar' as const, isLoading: false })
    authMock.mockReset()
    authMock.mockReturnValue({
      activeRole: 'penztar',
      user: { role: 'penztar' },
      worker: { branchId: '1' },
    })
    readyCallback = null
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('C1: ertektar mod + preview rejects -> SHIFT_OPEN, soha IDLE_BEFORE_OPEN (T-work-vault)', async () => {
    appModeMock.mockReturnValue({ mode: 'ertektar' as const, isLoading: false })
    previewMock.mockRejectedValue(new Error('serverUnreachable'))
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
    expect(setShiftStateMock).not.toHaveBeenCalledWith('IDLE_BEFORE_OPEN')
    expect(isOpenMock).not.toHaveBeenCalled()
    expect(getTodaySessionMock).not.toHaveBeenCalled()
  })

  it('C2: ertektar mod + preview SENT -> CLOSED_AFTER_DAY_END (T-auto-vault)', async () => {
    appModeMock.mockReturnValue({ mode: 'ertektar' as const, isLoading: false })
    previewMock.mockResolvedValue({ status: 'SENT' })
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('CLOSED_AFTER_DAY_END'))
    expect(isOpenMock).not.toHaveBeenCalled()
    expect(getTodaySessionMock).not.toHaveBeenCalled()
  })

  it('C3: ertektar modban a napi-session API-t NEM hivjuk (felesleges backend-kör nem kell)', async () => {
    appModeMock.mockReturnValue({ mode: 'ertektar' as const, isLoading: false })
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
    expect(isOpenMock).not.toHaveBeenCalled()
    expect(getTodaySessionMock).not.toHaveBeenCalled()
  })

  it('C4: ertektar mod + preview PREVIEW -> SHIFT_OPEN (T-work-vault)', async () => {
    appModeMock.mockReturnValue({ mode: 'ertektar' as const, isLoading: false })
    previewMock.mockResolvedValue({ status: 'PREVIEW' })
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
    expect(setShiftStateMock).not.toHaveBeenCalledWith('IDLE_BEFORE_OPEN')
    expect(isOpenMock).not.toHaveBeenCalled()
  })

  it('C5: full mod -> SHIFT_OPEN', async () => {
    appModeMock.mockReturnValue({ mode: 'full' as const, isLoading: false })
    isOpenMock.mockResolvedValue(false)
    getTodaySessionMock.mockRejectedValue(new Error('404'))
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
  })

  it('C6: rate-maker mod -> SHIFT_OPEN', async () => {
    appModeMock.mockReturnValue({ mode: 'rate-maker' as const, isLoading: false })
    isOpenMock.mockResolvedValue(false)
    getTodaySessionMock.mockRejectedValue(new Error('404'))
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
  })

  it('C7: penztar mod + penztar szerep + nincs session + getCurrent hibazik -> SHIFT_OPEN (hitelesitett penztaros soha nem IDLE)', async () => {
    // 2026-09-01 kanban #3: a hitelesitett penztaros kepernyo SOHA nem nyithat
    // telepitesi ablakot — a korabbi IDLE_BEFORE_OPEN varakozast a ticket felulirja.
    appModeMock.mockReturnValue({ mode: 'penztar' as const, isLoading: false })
    authMock.mockReturnValue({
      activeRole: 'penztar',
      user: { role: 'penztar' },
      worker: { branchId: '1' },
    })
    isOpenMock.mockResolvedValue(false)
    getTodaySessionMock.mockRejectedValue(new Error('404'))
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
    expect(setShiftStateMock).not.toHaveBeenCalledWith('IDLE_BEFORE_OPEN')
  })

  it('C8: penztar mod + nyitott session -> SHIFT_OPEN (valtozatlan)', async () => {
    appModeMock.mockReturnValue({ mode: 'penztar' as const, isLoading: false })
    isOpenMock.mockResolvedValue(true)
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
  })

  it('C9: ertektar mod nem-Electron kornyezetben -> NEM jelent', async () => {
    appModeMock.mockReturnValue({ mode: 'ertektar' as const, isLoading: false })
    isElectronMock.mockReturnValue(false)
    renderHook(() => useSuiteUpdate())
    await new Promise((resolve) => setTimeout(resolve, 20))
    expect(setShiftStateMock).not.toHaveBeenCalled()
  })

  it('R3: appMode atmenet penztar -> ertektar -> SHIFT_OPEN jelentes mindket allapotban (korrekciós mechanizmus, D6)', async () => {
    // 2026-09-01 kanban #3: indulas penztar modban is SHIFT_OPEN-nal tortenik
    // (hitelesitett penztaros soha nem IDLE); a modatmenet utan is SHIFT_OPEN marad.
    appModeMock.mockReturnValue({ mode: 'penztar' as const, isLoading: false })
    isOpenMock.mockResolvedValue(false)
    getTodaySessionMock.mockRejectedValue(new Error('404'))
    const { rerender } = renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
    expect(setShiftStateMock).not.toHaveBeenCalledWith('IDLE_BEFORE_OPEN')

    // Az SQLite app_mode feloldas utan a terminal ertektar modra valt:
    // a hook ujra-jelentese SHIFT_OPEN-t ad, IDLE sosem jelenik meg.
    appModeMock.mockReturnValue({ mode: 'ertektar' as const, isLoading: false })
    rerender()
    await waitFor(() => expect(setShiftStateMock).toHaveBeenLastCalledWith('SHIFT_OPEN'))
    expect(setShiftStateMock).not.toHaveBeenCalledWith('IDLE_BEFORE_OPEN')
  })
})

describe('useSuiteUpdate — ROLE-ELSŐ telepítési ablak (FKH-041 round 2, D5/D6/D8)', () => {
  beforeEach(() => {
    isOpenMock.mockReset()
    getTodaySessionMock.mockReset()
    previewMock.mockReset()
    previewMock.mockResolvedValue({ status: 'NOT_STARTED' })
    setShiftStateMock.mockClear()
    statusMock.mockClear()
    onReadyMock.mockClear()
    isElectronMock.mockReturnValue(true)
    appModeMock.mockReset()
    appModeMock.mockReturnValue({ mode: 'penztar' as const, isLoading: false })
    authMock.mockReset()
    authMock.mockReturnValue({
      activeRole: 'penztar',
      user: { role: 'penztar' },
      worker: { branchId: '1' },
    })
    readyCallback = null
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('C10: penztar mod + ertektar szerep -> SHIFT_OPEN (soha IDLE_BEFORE_OPEN)', async () => {
    appModeMock.mockReturnValue({ mode: 'penztar' as const, isLoading: false })
    authMock.mockReturnValue({
      activeRole: 'ertektar',
      user: { role: 'ertektar' },
      worker: { branchId: '1' },
    })
    isOpenMock.mockResolvedValue(false)
    getTodaySessionMock.mockRejectedValue(new Error('404'))
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
    expect(setShiftStateMock).not.toHaveBeenCalledWith('IDLE_BEFORE_OPEN')
  })

  it('C11: penztar mod + foertektar szerep + CLOSED session -> SHIFT_OPEN (soha CLOSED_AFTER_DAY_END)', async () => {
    appModeMock.mockReturnValue({ mode: 'penztar' as const, isLoading: false })
    authMock.mockReturnValue({
      activeRole: 'foertektar',
      user: { role: 'foertektar' },
      worker: { branchId: '1' },
    })
    isOpenMock.mockResolvedValue(false)
    getTodaySessionMock.mockResolvedValue({ status: 'CLOSED', closedAt: '2026-08-12T18:00:00Z' })
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
    expect(setShiftStateMock).not.toHaveBeenCalledWith('CLOSED_AFTER_DAY_END')
  })

  it('C12: penztar mod + TREASURY_MANAGER (legacy -> ertektar) -> SHIFT_OPEN (soha IDLE_BEFORE_OPEN)', async () => {
    appModeMock.mockReturnValue({ mode: 'penztar' as const, isLoading: false })
    authMock.mockReturnValue({
      activeRole: 'TREASURY_MANAGER',
      user: null,
      worker: { branchId: '1' },
    })
    isOpenMock.mockResolvedValue(false)
    getTodaySessionMock.mockRejectedValue(new Error('404'))
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
    expect(setShiftStateMock).not.toHaveBeenCalledWith('IDLE_BEFORE_OPEN')
  })

  it('C13: penztar mod + ismeretlen/hiányzó szerep (activeRole=null, user=null) -> SHIFT_OPEN (fail closed)', async () => {
    appModeMock.mockReturnValue({ mode: 'penztar' as const, isLoading: false })
    authMock.mockReturnValue({ activeRole: null, user: null, worker: { branchId: '1' } })
    isOpenMock.mockResolvedValue(false)
    getTodaySessionMock.mockRejectedValue(new Error('404'))
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
    expect(setShiftStateMock).not.toHaveBeenCalledWith('IDLE_BEFORE_OPEN')
  })

  it('C14: penztar mod + activeRole=null, user.role=CASHIER -> SHIFT_OPEN (legacy kanonizáció + user.role fallback: penztaros soha nem IDLE)', async () => {
    // 2026-09-01 kanban #3: a szerep-fallback penztar-ra oldodik, ezert a
    // napi-session API hivodik, de a hitelesitett penztaros ablak SOHA nem IDLE.
    appModeMock.mockReturnValue({ mode: 'penztar' as const, isLoading: false })
    authMock.mockReturnValue({
      activeRole: null,
      user: { role: 'CASHIER' },
      worker: { branchId: '1' },
    })
    isOpenMock.mockResolvedValue(false)
    getTodaySessionMock.mockRejectedValue(new Error('404'))
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
    expect(setShiftStateMock).not.toHaveBeenCalledWith('IDLE_BEFORE_OPEN')
  })

  it('C15: penztar mod + ertektar szerep -> a napi-session API-t NEM hívjuk (backend-kör nélkül)', async () => {
    appModeMock.mockReturnValue({ mode: 'penztar' as const, isLoading: false })
    authMock.mockReturnValue({
      activeRole: 'ertektar',
      user: { role: 'ertektar' },
      worker: { branchId: '1' },
    })
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
    expect(isOpenMock).not.toHaveBeenCalled()
    expect(getTodaySessionMock).not.toHaveBeenCalled()
  })

  it('C16: amíg az appMode isLoading=true, SEMMIT nem jelent (D8, ITEM 1c)', async () => {
    appModeMock.mockReturnValue({ mode: 'penztar' as const, isLoading: true })
    authMock.mockReturnValue({
      activeRole: 'penztar',
      user: { role: 'penztar' },
      worker: { branchId: '1' },
    })
    isOpenMock.mockResolvedValue(false)
    renderHook(() => useSuiteUpdate())
    await new Promise((resolve) => setTimeout(resolve, 20))
    expect(setShiftStateMock).not.toHaveBeenCalled()
  })

  it('C17: isLoading=true -> false átmenet után jelent (a guard késleltet, nem nyom el)', async () => {
    appModeMock.mockReturnValue({ mode: 'penztar' as const, isLoading: true })
    authMock.mockReturnValue({
      activeRole: 'penztar',
      user: { role: 'penztar' },
      worker: { branchId: '1' },
    })
    isOpenMock.mockResolvedValue(true)
    const { rerender } = renderHook(() => useSuiteUpdate())
    await new Promise((resolve) => setTimeout(resolve, 20))
    expect(setShiftStateMock).not.toHaveBeenCalled()

    // Az SQLite app_mode feloldódott -> isLoading=false, jelentés indulhat.
    appModeMock.mockReturnValue({ mode: 'penztar' as const, isLoading: false })
    rerender()
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
  })

  it('C18: ertektar mod + penztar szerep + preview SENT -> CLOSED_AFTER_DAY_END (mode-first, preview-driven)', async () => {
    appModeMock.mockReturnValue({ mode: 'ertektar' as const, isLoading: false })
    authMock.mockReturnValue({
      activeRole: 'penztar',
      user: { role: 'penztar' },
      worker: { branchId: '1' },
    })
    previewMock.mockResolvedValue({ status: 'SENT' })
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('CLOSED_AFTER_DAY_END'))
    expect(isOpenMock).not.toHaveBeenCalled()
  })
})

describe('useSuiteUpdate — nyitottnap-marker életciklus (Google-OTP hurok, C3)', () => {
  beforeEach(() => {
    isOpenMock.mockReset()
    getTodaySessionMock.mockReset()
    previewMock.mockReset()
    previewMock.mockResolvedValue({ status: 'NOT_STARTED' })
    setShiftStateMock.mockClear()
    statusMock.mockClear()
    onReadyMock.mockClear()
    isElectronMock.mockReturnValue(true)
    appModeMock.mockReset()
    appModeMock.mockReturnValue({ mode: 'penztar' as const, isLoading: false })
    authMock.mockReset()
    authMock.mockReturnValue({
      activeRole: 'penztar',
      user: { role: 'penztar' },
      worker: { branchId: '1' },
    })
    readyCallback = null
    localStorage.clear()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('G12a: isOpen()===false + getCurrent hibazik -> SHIFT_OPEN ÉS marker törlése (pozitív bizonyíték a nem-nyitott napról)', async () => {
    // 2026-09-01 kanban #3: a marker torlese valtozatlanul megmarad, de a
    // jelentett allapot SHIFT_OPEN (hitelesitett penztaros soha nem IDLE).
    rememberOpenDayObservation()
    isOpenMock.mockResolvedValue(false)
    getTodaySessionMock.mockRejectedValue(new Error('404'))
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
    expect(hasOpenDayObservedToday()).toBe(false)
    expect(setShiftStateMock).not.toHaveBeenCalledWith('IDLE_BEFORE_OPEN')
  })

  it('G12b: isOpen() hibazik (halozat) -> SHIFT_OPEN ÉS marker ÉRINTETLEN (hiba nem gyarthat ablakot)', async () => {
    rememberOpenDayObservation()
    isOpenMock.mockRejectedValue(new Error('serverUnreachable'))
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
    expect(hasOpenDayObservedToday()).toBe(true)
  })

  it('G12c: ertektar + NOT_STARTED -> SHIFT_OPEN, isOpen NEM hivodik, marker ERINTETLEN', async () => {
    appModeMock.mockReturnValue({ mode: 'ertektar' as const, isLoading: false })
    previewMock.mockResolvedValue({ status: 'NOT_STARTED' })
    rememberOpenDayObservation()
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
    expect(isOpenMock).not.toHaveBeenCalled()
    expect(hasOpenDayObservedToday()).toBe(true)
    expect(localStorage.getItem(OPEN_DAY_OBSERVED_KEY)).not.toBeNull()
  })
})

describe('useSuiteUpdate — hitelesített pénztáros SOHA nem IDLE (kanban #3)', () => {
  beforeEach(() => {
    isOpenMock.mockReset()
    getTodaySessionMock.mockReset()
    previewMock.mockReset()
    previewMock.mockResolvedValue({ status: 'NOT_STARTED' })
    setShiftStateMock.mockClear()
    statusMock.mockClear()
    onReadyMock.mockClear()
    isElectronMock.mockReturnValue(true)
    appModeMock.mockReset()
    appModeMock.mockReturnValue({ mode: 'penztar' as const, isLoading: false })
    authMock.mockReset()
    authMock.mockReturnValue({
      activeRole: 'penztar',
      user: { role: 'penztar' },
      worker: { branchId: '1' },
    })
    readyCallback = null
    localStorage.clear()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('N1: hitelesitett penztar + isOpen=false + getCurrent=null -> SHIFT_OPEN (soha IDLE_BEFORE_OPEN)', async () => {
    isOpenMock.mockResolvedValue(false)
    getTodaySessionMock.mockResolvedValue(null)
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
    expect(setShiftStateMock).not.toHaveBeenCalledWith('IDLE_BEFORE_OPEN')
  })

  it('N2: hitelesitett penztar + isOpen=false + getCurrent hibazik -> SHIFT_OPEN (soha IDLE_BEFORE_OPEN)', async () => {
    isOpenMock.mockResolvedValue(false)
    getTodaySessionMock.mockRejectedValue(new Error('404'))
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
    expect(setShiftStateMock).not.toHaveBeenCalledWith('IDLE_BEFORE_OPEN')
  })

  it('N2b: N2 + preset nyitottnap-marker -> SHIFT_OPEN ES a marker torlodik (G12a spec)', async () => {
    rememberOpenDayObservation()
    isOpenMock.mockResolvedValue(false)
    getTodaySessionMock.mockRejectedValue(new Error('404'))
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
    expect(hasOpenDayObservedToday()).toBe(false)
    expect(setShiftStateMock).not.toHaveBeenCalledWith('IDLE_BEFORE_OPEN')
  })

  it('N2c: clampIdleForAuthenticatedCashier tiszta fuggveny (IDLE->SHIFT_OPEN, mas allapot valtozatlan)', () => {
    expect(clampIdleForAuthenticatedCashier('IDLE_BEFORE_OPEN')).toBe('SHIFT_OPEN')
    expect(clampIdleForAuthenticatedCashier('SHIFT_OPEN')).toBe('SHIFT_OPEN')
    expect(clampIdleForAuthenticatedCashier('CLOSED_AFTER_DAY_END')).toBe('CLOSED_AFTER_DAY_END')
  })
})

describe('useSuiteUpdate — napzaras utani telepitesi ablak a /today-bol (kanban #4, FR-3)', () => {
  beforeEach(() => {
    isOpenMock.mockReset()
    getTodaySessionMock.mockReset()
    previewMock.mockReset()
    previewMock.mockResolvedValue({ status: 'NOT_STARTED' })
    setShiftStateMock.mockClear()
    statusMock.mockClear()
    onReadyMock.mockClear()
    isElectronMock.mockReturnValue(true)
    appModeMock.mockReset()
    appModeMock.mockReturnValue({ mode: 'penztar' as const, isLoading: false })
    authMock.mockReset()
    authMock.mockReturnValue({
      activeRole: 'penztar',
      user: { role: 'penztar' },
      worker: { branchId: '1' },
    })
    readyCallback = null
    localStorage.clear()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('T6: penztar mod + penztar szerep + isOpen=false + /today CLOSED -> CLOSED_AFTER_DAY_END (FR-3: az egyetlen viselkedesvaltozas)', async () => {
    isOpenMock.mockResolvedValue(false)
    getTodaySessionMock.mockResolvedValue({ status: 'CLOSED', closedAt: '2026-09-01T18:00:00Z' })
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('CLOSED_AFTER_DAY_END'))
  })

  it('T7: penztar mod + isOpen=false + /today null -> SHIFT_OPEN, soha IDLE_BEFORE_OPEN (FR-2/FR-4: a clamp tovabbra is aktiv)', async () => {
    isOpenMock.mockResolvedValue(false)
    getTodaySessionMock.mockResolvedValue(null)
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
    expect(setShiftStateMock).not.toHaveBeenCalledWith('IDLE_BEFORE_OPEN')
  })

  it('T8: penztar mod + isOpen=false + /today halozati hiba -> SHIFT_OPEN (AC-3 fail-safe: a meglevo kulso catch-ág)', async () => {
    isOpenMock.mockResolvedValue(false)
    getTodaySessionMock.mockRejectedValue(new Error('serverUnreachable'))
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
  })

  it('T9: ertektar mod + preview CONFIRMED -> CLOSED_AFTER_DAY_END, /today NEM hivodik (T-auto-vault)', async () => {
    appModeMock.mockReturnValue({ mode: 'ertektar' as const, isLoading: false })
    previewMock.mockResolvedValue({ status: 'CONFIRMED' })
    getTodaySessionMock.mockResolvedValue({ status: 'CLOSED', closedAt: '2026-09-01T18:00:00Z' })
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('CLOSED_AFTER_DAY_END'))
    expect(getTodaySessionMock).not.toHaveBeenCalled()
    expect(isOpenMock).not.toHaveBeenCalled()
  })
})

describe('useSuiteUpdate — treasury evening-closing window (kanban #7)', () => {
  beforeEach(() => {
    isOpenMock.mockReset()
    getTodaySessionMock.mockReset()
    previewMock.mockReset()
    previewMock.mockResolvedValue({ status: 'NOT_STARTED' })
    setShiftStateMock.mockClear()
    statusMock.mockClear()
    onReadyMock.mockClear()
    isElectronMock.mockReturnValue(true)
    appModeMock.mockReset()
    appModeMock.mockReturnValue({ mode: 'ertektar' as const, isLoading: false })
    authMock.mockReset()
    authMock.mockReturnValue({
      activeRole: 'ertektar',
      user: { role: 'ertektar' },
      worker: { branchId: '1' },
    })
    readyCallback = null
    localStorage.clear()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('T-work-vault: preview null / empty / NOT_STARTED never IDLE', async () => {
    for (const preview of [null, {}, { status: 'NOT_STARTED' }]) {
      setShiftStateMock.mockClear()
      previewMock.mockResolvedValue(preview)
      const { unmount } = renderHook(() => useSuiteUpdate())
      await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
      expect(setShiftStateMock).not.toHaveBeenCalledWith('IDLE_BEFORE_OPEN')
      unmount()
    }
  })

  it('T-vault-no-branch: worker null -> SHIFT_OPEN, preview not called', async () => {
    authMock.mockReturnValue({ activeRole: 'ertektar', user: { role: 'ertektar' }, worker: null })
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
    expect(previewMock).not.toHaveBeenCalled()
    expect(setShiftStateMock).not.toHaveBeenCalledWith('IDLE_BEFORE_OPEN')
  })

  it('T-no-reopen-hole: C10/C11 preview not used in penztar mode', async () => {
    appModeMock.mockReturnValue({ mode: 'penztar' as const, isLoading: false })
    authMock.mockReturnValue({
      activeRole: 'ertektar',
      user: { role: 'ertektar' },
      worker: { branchId: '1' },
    })
    previewMock.mockResolvedValue({ status: 'SENT' })
    isOpenMock.mockResolvedValue(false)
    getTodaySessionMock.mockResolvedValue({ status: 'CLOSED' })
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
    expect(previewMock).not.toHaveBeenCalled()
  })

  it('T-close-prompt: refresh after SENT without waiting 60s', async () => {
    previewMock
      .mockResolvedValueOnce({ status: 'PREVIEW' })
      .mockResolvedValueOnce({ status: 'SENT' })
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
    const { requestShiftStateRefresh } = await import('../../utils/suiteUpdateSignal')
    requestShiftStateRefresh()
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('CLOSED_AFTER_DAY_END'))
  })

  it('mapper unit: SENT/CONFIRMED vs fail-safe', async () => {
    const { mapEveningClosingToShiftState } = await import('../useSuiteUpdate')
    expect(mapEveningClosingToShiftState({ status: 'SENT' })).toBe('CLOSED_AFTER_DAY_END')
    expect(mapEveningClosingToShiftState({ status: 'CONFIRMED' })).toBe('CLOSED_AFTER_DAY_END')
    expect(mapEveningClosingToShiftState({ status: 'NOT_STARTED' })).toBe('SHIFT_OPEN')
    expect(mapEveningClosingToShiftState({ status: 'PREVIEW' })).toBe('SHIFT_OPEN')
    expect(mapEveningClosingToShiftState(undefined)).toBe('SHIFT_OPEN')
    expect(mapEveningClosingToShiftState(null)).toBe('SHIFT_OPEN')
    expect(mapEveningClosingToShiftState({ status: 'GARBAGE' })).toBe('SHIFT_OPEN')
  })
})

describe('useSuiteUpdate — installFailure surface (kanban #8)', () => {
  beforeEach(() => {
    isOpenMock.mockReset()
    getTodaySessionMock.mockReset()
    previewMock.mockReset()
    previewMock.mockResolvedValue({ status: 'NOT_STARTED' })
    setShiftStateMock.mockClear()
    statusMock.mockClear()
    onReadyMock.mockClear()
    onInstallFailedMock.mockClear()
    isElectronMock.mockReturnValue(true)
    appModeMock.mockReset()
    appModeMock.mockReturnValue({ mode: 'penztar' as const, isLoading: false })
    authMock.mockReset()
    authMock.mockReturnValue({
      activeRole: 'penztar',
      user: { role: 'penztar' },
      worker: { branchId: '1' },
    })
    readyCallback = null
    installFailedCallback = null
    localStorage.clear()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('F1: installFailure starts null', async () => {
    isOpenMock.mockResolvedValue(true)
    const { result } = renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(installFailedCallback).not.toBeNull())
    expect(result.current.installFailure).toBeNull()
  })

  it('F2: suiteUpdate:installFailed event surfaces version/reason/installerPath', async () => {
    isOpenMock.mockResolvedValue(true)
    const { result } = renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(installFailedCallback).not.toBeNull())
    installFailedCallback?.({
      version: '2.28.96',
      reason: 'ELEVATION_REFUSED',
      installerPath: 'C:\\cache\\Penztar-Setup-2.28.96.exe',
    })
    await waitFor(() => expect(result.current.installFailure?.version).toBe('2.28.96'))
    expect(result.current.installFailure?.reason).toBe('ELEVATION_REFUSED')
    expect(result.current.installFailure?.installerPath).toBe('C:\\cache\\Penztar-Setup-2.28.96.exe')
  })

  it('F3: a new suiteUpdate:ready clears the failure (fresh attempt possible)', async () => {
    isOpenMock.mockResolvedValue(true)
    const { result } = renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(installFailedCallback).not.toBeNull())
    installFailedCallback?.({
      version: '2.28.96',
      reason: 'LAUNCH_FAILED',
      installerPath: 'C:\\cache\\Penztar-Setup-2.28.96.exe',
    })
    await waitFor(() => expect(result.current.installFailure?.version).toBe('2.28.96'))
    readyCallback?.({ version: '2.28.96', mandatory: false, notes: null, installableNow: true })
    await waitFor(() => expect(result.current.installFailure).toBeNull())
  })
})
