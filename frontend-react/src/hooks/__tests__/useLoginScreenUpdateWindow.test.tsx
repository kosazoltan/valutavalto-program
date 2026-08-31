/**
 * useLoginScreenUpdateWindow — a belépőképernyő telepítési-ablak hookjának tesztjei
 * (Google-OTP hurok, 2026-08-30).
 *
 * A hook az egyetlen hely, amely IDLE_BEFORE_OPEN-t jelenthet a belépőképernyőről —
 * és ezt is CSAK mért idle-timeout után. Interakció / bármely belépési lépés /
 * unmount alatt mindig ACTIVE-t jelent (fail-closed).
 */
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { renderHook, act } from '@testing-library/react'
import type { AppMode } from '../../types/appMode'

// A mock realisztikusan képezi az aktivitást műszak-állapotra: az IDLE_TIMEOUT
// ágból IDLE_BEFORE_OPEN lesz (cashier mód + penztar marker + nincs auth/nyitott
// nap), minden másból SHIFT_OPEN — így a hook deduplikáló logikája is életszerűen fut.
const reportMock = vi.hoisted(() =>
  vi.fn(async (...args: unknown[]) =>
    args[4] === 'IDLE_TIMEOUT' ? 'IDLE_BEFORE_OPEN' : 'SHIFT_OPEN',
  ),
)

vi.mock('../reportLoginScreenIdleForUpdate', () => ({
  reportLoginScreenIdleForUpdate: (...args: unknown[]) => reportMock(...args),
}))

const { useLoginScreenUpdateWindow, LOGIN_IDLE_TIMEOUT_MS } =
  await import('../useLoginScreenUpdateWindow')

describe('useLoginScreenUpdateWindow — activity-gated telepítési ablak', () => {
  beforeEach(() => {
    reportMock.mockClear()
    sessionStorage.clear()
    localStorage.clear()
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  const baseParams = {
    appMode: 'penztar' as AppMode,
    appModeLoading: false,
    interactionInFlight: false,
  }

  it('G2: futó Google OAuth alatt SOHA nem IDLE_TIMEOUT (az élő lockout-forgatókönyv)', async () => {
    renderHook(() => useLoginScreenUpdateWindow({ ...baseParams, interactionInFlight: true }))
    await act(async () => {
      await vi.advanceTimersByTimeAsync(180_000)
    })
    const activities = reportMock.mock.calls.map((c) => c[4])
    expect(activities).not.toContain('IDLE_TIMEOUT')
    expect(activities[activities.length - 1]).toBe('ACTIVE')
  })

  it('G4: felhasználói bevitel nullázza az idle-időzítőt (nincs korai IDLE)', async () => {
    renderHook(() => useLoginScreenUpdateWindow(baseParams))
    await act(async () => {
      await vi.advanceTimersByTimeAsync(119_000)
    })
    await act(async () => {
      window.dispatchEvent(new KeyboardEvent('keydown'))
    })
    await act(async () => {
      await vi.advanceTimersByTimeAsync(119_000)
    })
    const activities = reportMock.mock.calls.map((c) => c[4])
    expect(activities).not.toContain('IDLE_TIMEOUT')
  })

  it('G9: mért idle után unmount -> ACTIVE (a sikeres belépés bezárja az ablakot)', async () => {
    const { unmount } = renderHook(() => useLoginScreenUpdateWindow(baseParams))
    await act(async () => {
      await vi.advanceTimersByTimeAsync(LOGIN_IDLE_TIMEOUT_MS)
    })
    expect(reportMock.mock.calls.map((c) => c[4])).toContain('IDLE_TIMEOUT')
    await act(async () => {
      unmount()
    })
    const activities = reportMock.mock.calls.map((c) => c[4])
    expect(activities[activities.length - 1]).toBe('ACTIVE')
  })

  it('G14: IDLE után interactionInFlight=true -> ACTIVE (a felhasználó visszatért / későn kattintott Google-ra)', async () => {
    const { rerender } = renderHook(
      ({ interactionInFlight }: { interactionInFlight: boolean }) =>
        useLoginScreenUpdateWindow({ ...baseParams, interactionInFlight }),
      { initialProps: { interactionInFlight: false } },
    )
    await act(async () => {
      await vi.advanceTimersByTimeAsync(LOGIN_IDLE_TIMEOUT_MS)
    })
    expect(reportMock.mock.calls.map((c) => c[4])).toContain('IDLE_TIMEOUT')
    rerender({ interactionInFlight: true })
    const activities = reportMock.mock.calls.map((c) => c[4])
    expect(activities[activities.length - 1]).toBe('ACTIVE')
  })

  it('G15: appModeLoading=true -> SEMMILYEN jelentés (FKH-041 D8 guard preserved)', async () => {
    renderHook(() => useLoginScreenUpdateWindow({ ...baseParams, appModeLoading: true }))
    await act(async () => {
      await vi.advanceTimersByTimeAsync(300_000)
    })
    expect(reportMock).not.toHaveBeenCalled()
  })

  it('G19: pontosan LOGIN_IDLE_TIMEOUT_MS tétlenség után egyszer IDLE_TIMEOUT, appMode továbbadva', async () => {
    renderHook(() => useLoginScreenUpdateWindow(baseParams))
    await act(async () => {
      await vi.advanceTimersByTimeAsync(LOGIN_IDLE_TIMEOUT_MS)
    })
    const idleCalls = reportMock.mock.calls.filter((c) => c[4] === 'IDLE_TIMEOUT')
    expect(idleCalls).toHaveLength(1)
    const firstIdleCall = idleCalls[0]
    expect(firstIdleCall?.[2]).toBe('penztar')
  })
})
