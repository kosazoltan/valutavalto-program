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

const isOpenMock = vi.fn()
const getCurrentMock = vi.fn()
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

vi.mock('../../services/api/index', () => ({
  dailySessionApi: {
    isOpen: () => isOpenMock(),
    getCurrent: () => getCurrentMock(),
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

const { useSuiteUpdate, mapSessionToShiftState } = await import('../useSuiteUpdate')

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
    getCurrentMock.mockReset()
    setShiftStateMock.mockClear()
    statusMock.mockClear()
    onReadyMock.mockClear()
    isElectronMock.mockReturnValue(true)
    appModeMock.mockReset()
    appModeMock.mockReturnValue({ mode: 'penztar' as const, isLoading: false })
    readyCallback = null
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('nyitott munkamenet -> SHIFT_OPEN jelentés', async () => {
    isOpenMock.mockResolvedValue(true)
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
  })

  it('lezárt napzárás -> CLOSED_AFTER_DAY_END jelentés', async () => {
    isOpenMock.mockResolvedValue(false)
    getCurrentMock.mockResolvedValue({ status: 'CLOSED', closedAt: '2026-08-12T18:00:00Z' })
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('CLOSED_AFTER_DAY_END'))
  })

  it('nincs mai munkamenet -> IDLE_BEFORE_OPEN jelentés', async () => {
    isOpenMock.mockResolvedValue(false)
    getCurrentMock.mockRejectedValue(new Error('404'))
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('IDLE_BEFORE_OPEN'))
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
    getCurrentMock.mockReset()
    setShiftStateMock.mockClear()
    statusMock.mockClear()
    onReadyMock.mockClear()
    isElectronMock.mockReturnValue(true)
    appModeMock.mockReset()
    appModeMock.mockReturnValue({ mode: 'penztar' as const, isLoading: false })
    readyCallback = null
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('C1: ertektar mod + nincs nyitott session + getCurrent hibazik -> SHIFT_OPEN, soha IDLE_BEFORE_OPEN', async () => {
    appModeMock.mockReturnValue({ mode: 'ertektar' as const, isLoading: false })
    isOpenMock.mockResolvedValue(false)
    getCurrentMock.mockRejectedValue(new Error('404'))
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
    expect(setShiftStateMock).not.toHaveBeenCalledWith('IDLE_BEFORE_OPEN')
  })

  it('C2: ertektar mod + CLOSED session -> SHIFT_OPEN (soha CLOSED_AFTER_DAY_END)', async () => {
    appModeMock.mockReturnValue({ mode: 'ertektar' as const, isLoading: false })
    isOpenMock.mockResolvedValue(false)
    getCurrentMock.mockResolvedValue({ status: 'CLOSED', closedAt: '2026-08-12T18:00:00Z' })
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
    expect(setShiftStateMock).not.toHaveBeenCalledWith('CLOSED_AFTER_DAY_END')
  })

  it('C3: ertektar modban a napi-session API-t NEM hivjuk (felesleges backend-kör nem kell)', async () => {
    appModeMock.mockReturnValue({ mode: 'ertektar' as const, isLoading: false })
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
    expect(isOpenMock).not.toHaveBeenCalled()
    expect(getCurrentMock).not.toHaveBeenCalled()
  })

  it('C4: ertektar mod + isOpen hibazik -> SHIFT_OPEN (fail-safe valtozatlan)', async () => {
    appModeMock.mockReturnValue({ mode: 'ertektar' as const, isLoading: false })
    isOpenMock.mockRejectedValue(new Error('serverUnreachable'))
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
  })

  it('C5: full mod -> SHIFT_OPEN', async () => {
    appModeMock.mockReturnValue({ mode: 'full' as const, isLoading: false })
    isOpenMock.mockResolvedValue(false)
    getCurrentMock.mockRejectedValue(new Error('404'))
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
  })

  it('C6: rate-maker mod -> SHIFT_OPEN', async () => {
    appModeMock.mockReturnValue({ mode: 'rate-maker' as const, isLoading: false })
    isOpenMock.mockResolvedValue(false)
    getCurrentMock.mockRejectedValue(new Error('404'))
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
  })

  it('C7: penztar mod + nincs session + getCurrent hibazik -> IDLE_BEFORE_OPEN (penztar valtozatlan)', async () => {
    appModeMock.mockReturnValue({ mode: 'penztar' as const, isLoading: false })
    isOpenMock.mockResolvedValue(false)
    getCurrentMock.mockRejectedValue(new Error('404'))
    renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('IDLE_BEFORE_OPEN'))
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

  it('R3: appMode atmenet penztar -> ertektar -> ujra-jelentes SHIFT_OPEN-nal (korrekciós mechanizmus, D6)', async () => {
    // Indulas: penztar mod, nincs nyitott session -> IDLE_BEFORE_OPEN.
    appModeMock.mockReturnValue({ mode: 'penztar' as const, isLoading: false })
    isOpenMock.mockResolvedValue(false)
    getCurrentMock.mockRejectedValue(new Error('404'))
    const { rerender } = renderHook(() => useSuiteUpdate())
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('IDLE_BEFORE_OPEN'))

    // Az SQLite app_mode feloldas utan a terminal ertektar modra valt:
    // a hooknak ujra kell jelentenie, es a SHIFT_OPEN felulirja az IDLE-t.
    appModeMock.mockReturnValue({ mode: 'ertektar' as const, isLoading: false })
    rerender()
    await waitFor(() => expect(setShiftStateMock).toHaveBeenCalledWith('SHIFT_OPEN'))
    expect(setShiftStateMock).toHaveBeenLastCalledWith('SHIFT_OPEN')
  })
})
