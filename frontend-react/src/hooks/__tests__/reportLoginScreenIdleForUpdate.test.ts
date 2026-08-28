import { describe, it, expect, vi, beforeEach } from 'vitest'
import {
  reportLoginScreenIdleForUpdate,
  markAuthenticatedSession,
  HAD_AUTH_SESSION_KEY,
} from '../reportLoginScreenIdleForUpdate'
import type { ShiftState } from '../useSuiteUpdate'

describe('reportLoginScreenIdleForUpdate', () => {
  beforeEach(() => {
    sessionStorage.clear()
  })

  it('Electron nélkül no-op (null)', async () => {
    await expect(reportLoginScreenIdleForUpdate(null)).resolves.toBeNull()
  })

  it('suiteUpdate hiányában no-op (null)', async () => {
    await expect(reportLoginScreenIdleForUpdate({})).resolves.toBeNull()
  })

  it('hideg indítás: IDLE_BEFORE_OPEN — belépés nélkül is telepíthető', async () => {
    const setShiftState = vi.fn().mockResolvedValue({ accepted: true })
    await expect(reportLoginScreenIdleForUpdate({ suiteUpdate: { setShiftState } })).resolves.toBe(
      'IDLE_BEFORE_OPEN',
    )
    expect(setShiftState).toHaveBeenCalledWith('IDLE_BEFORE_OPEN')
  })

  it('logout után (már volt belépés): SHIFT_OPEN — ne telepítsen nyitott nap közben', async () => {
    markAuthenticatedSession()
    expect(sessionStorage.getItem(HAD_AUTH_SESSION_KEY)).toBe('1')
    const setShiftState = vi.fn().mockResolvedValue({ accepted: true })
    await expect(reportLoginScreenIdleForUpdate({ suiteUpdate: { setShiftState } })).resolves.toBe(
      'SHIFT_OPEN',
    )
    expect(setShiftState).toHaveBeenCalledWith('SHIFT_OPEN')
  })

  it('IPC hiba nem dob, null-t ad', async () => {
    const setShiftState = vi.fn().mockRejectedValue(new Error('ipc'))
    await expect(
      reportLoginScreenIdleForUpdate({ suiteUpdate: { setShiftState } }),
    ).resolves.toBeNull()
  })
})

describe('reportLoginScreenIdleForUpdate — appMode-tudatos (FKH-041 FR-3 / C6)', () => {
  beforeEach(() => {
    sessionStorage.clear()
  })

  function makeApi(setShiftState: (state: ShiftState) => Promise<unknown>) {
    return { suiteUpdate: { setShiftState } }
  }

  function okShiftStateMock() {
    return vi.fn(async (_state: ShiftState): Promise<unknown> => ({ accepted: true }))
  }

  it('D1: hideg inditas ertektar modban -> SHIFT_OPEN (soha nem telepitheto)', async () => {
    const setShiftState = okShiftStateMock()
    await expect(
      reportLoginScreenIdleForUpdate(makeApi(setShiftState), false, 'ertektar'),
    ).resolves.toBe('SHIFT_OPEN')
    expect(setShiftState).toHaveBeenCalledWith('SHIFT_OPEN')
  })

  it('D2: hideg inditas penztar modban -> IDLE_BEFORE_OPEN (valtozatlan)', async () => {
    const setShiftState = okShiftStateMock()
    await expect(
      reportLoginScreenIdleForUpdate(makeApi(setShiftState), false, 'penztar'),
    ).resolves.toBe('IDLE_BEFORE_OPEN')
    expect(setShiftState).toHaveBeenCalledWith('IDLE_BEFORE_OPEN')
  })

  it('D3: logout utan penztar modban -> SHIFT_OPEN (valtozatlan)', async () => {
    const setShiftState = okShiftStateMock()
    await expect(
      reportLoginScreenIdleForUpdate(makeApi(setShiftState), true, 'penztar'),
    ).resolves.toBe('SHIFT_OPEN')
  })

  it('D4: logout utan ertektar modban -> SHIFT_OPEN', async () => {
    const setShiftState = okShiftStateMock()
    await expect(
      reportLoginScreenIdleForUpdate(makeApi(setShiftState), true, 'ertektar'),
    ).resolves.toBe('SHIFT_OPEN')
  })

  it('D5: hideg inditas full modban -> SHIFT_OPEN', async () => {
    const setShiftState = okShiftStateMock()
    await expect(reportLoginScreenIdleForUpdate(makeApi(setShiftState), false, 'full')).resolves.toBe(
      'SHIFT_OPEN',
    )
  })

  it('D6: hideg inditas rate-maker modban -> SHIFT_OPEN', async () => {
    const setShiftState = okShiftStateMock()
    await expect(
      reportLoginScreenIdleForUpdate(makeApi(setShiftState), false, 'rate-maker'),
    ).resolves.toBe('SHIFT_OPEN')
  })

  it('D7: appMode = null -> hadAuth ternary valtozatlanul él (back-compat)', async () => {
    const setShiftState = okShiftStateMock()
    await expect(reportLoginScreenIdleForUpdate(makeApi(setShiftState), false, null)).resolves.toBe(
      'IDLE_BEFORE_OPEN',
    )
  })

  it('D8: api = null, ertektar mod -> null, nem dob', async () => {
    await expect(reportLoginScreenIdleForUpdate(null, false, 'ertektar')).resolves.toBeNull()
  })

  it('D9: setShiftState hibazik, ertektar mod -> null, nem dob', async () => {
    const setShiftState = vi.fn(async (_state: ShiftState): Promise<unknown> => {
      throw new Error('ipc')
    })
    await expect(
      reportLoginScreenIdleForUpdate(makeApi(setShiftState), false, 'ertektar'),
    ).resolves.toBeNull()
  })
})
