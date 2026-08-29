import { describe, it, expect, vi, beforeEach } from 'vitest'
import {
  reportLoginScreenIdleForUpdate,
  markAuthenticatedSession,
  HAD_AUTH_SESSION_KEY,
  LAST_INSTALL_WINDOW_ROLE_KEY,
  rememberInstallWindowRole,
  readInstallWindowRole,
} from '../reportLoginScreenIdleForUpdate'
import type { ShiftState } from '../useSuiteUpdate'

describe('reportLoginScreenIdleForUpdate', () => {
  beforeEach(() => {
    sessionStorage.clear()
    localStorage.clear()
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
    localStorage.clear()
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

  it('D2 (REWRITTEN): hideg inditas penztar modban, marker NELKUL -> SHIFT_OPEN (fail closed, soha IDLE_BEFORE_OPEN)', async () => {
    const setShiftState = okShiftStateMock()
    await expect(
      reportLoginScreenIdleForUpdate(makeApi(setShiftState), false, 'penztar'),
    ).resolves.toBe('SHIFT_OPEN')
    expect(setShiftState).toHaveBeenCalledWith('SHIFT_OPEN')
    expect(setShiftState).not.toHaveBeenCalledWith('IDLE_BEFORE_OPEN')
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
    await expect(
      reportLoginScreenIdleForUpdate(makeApi(setShiftState), false, 'full'),
    ).resolves.toBe('SHIFT_OPEN')
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

  it('D10: hideg inditas penztar modban, explicit ures marker -> SHIFT_OPEN (fail closed)', async () => {
    const setShiftState = okShiftStateMock()
    await expect(
      reportLoginScreenIdleForUpdate(makeApi(setShiftState), false, 'penztar', ''),
    ).resolves.toBe('SHIFT_OPEN')
    expect(setShiftState).toHaveBeenCalledWith('SHIFT_OPEN')
  })

  it('D11: hideg inditas penztar modban, penztar marker -> IDLE_BEFORE_OPEN (bizonyitott penztaros gep, regresszió-pin)', async () => {
    const setShiftState = okShiftStateMock()
    await expect(
      reportLoginScreenIdleForUpdate(makeApi(setShiftState), false, 'penztar', 'penztar'),
    ).resolves.toBe('IDLE_BEFORE_OPEN')
    expect(setShiftState).toHaveBeenCalledWith('IDLE_BEFORE_OPEN')
  })

  it('D12: hideg inditas penztar modban, ertektar marker -> SHIFT_OPEN', async () => {
    const setShiftState = okShiftStateMock()
    await expect(
      reportLoginScreenIdleForUpdate(makeApi(setShiftState), false, 'penztar', 'ertektar'),
    ).resolves.toBe('SHIFT_OPEN')
    expect(setShiftState).toHaveBeenCalledWith('SHIFT_OPEN')
    expect(setShiftState).not.toHaveBeenCalledWith('IDLE_BEFORE_OPEN')
  })

  it('D13: hideg inditas penztar modban, CASHIER marker (legacy -> penztar kanonizacio) -> IDLE_BEFORE_OPEN (regresszió-pin)', async () => {
    const setShiftState = okShiftStateMock()
    await expect(
      reportLoginScreenIdleForUpdate(makeApi(setShiftState), false, 'penztar', 'CASHIER'),
    ).resolves.toBe('IDLE_BEFORE_OPEN')
  })

  it('D14: logout utan penztar modban, penztar marker -> SHIFT_OPEN (hadAuth tovabbra is nyer, regresszió-pin)', async () => {
    const setShiftState = okShiftStateMock()
    await expect(
      reportLoginScreenIdleForUpdate(makeApi(setShiftState), true, 'penztar', 'penztar'),
    ).resolves.toBe('SHIFT_OPEN')
  })

  it('D15: appMode = null + ertektar marker -> IDLE_BEFORE_OPEN (back-compat: a marker csak adott modnal él)', async () => {
    const setShiftState = okShiftStateMock()
    await expect(
      reportLoginScreenIdleForUpdate(makeApi(setShiftState), false, null, 'ertektar'),
    ).resolves.toBe('IDLE_BEFORE_OPEN')
  })
})

describe('reportLoginScreenIdleForUpdate — install-window role marker (FKH-041 round 2, D7/D8b)', () => {
  beforeEach(() => {
    sessionStorage.clear()
    localStorage.clear()
  })

  it('E1: rememberInstallWindowRole(CASHIER) -> penztar kanonizalva tarolva', () => {
    rememberInstallWindowRole('CASHIER')
    expect(readInstallWindowRole()).toBe('penztar')
    expect(localStorage.getItem(LAST_INSTALL_WINDOW_ROLE_KEY)).toBe('penztar')
  })

  it('E2: rememberInstallWindowRole(ertektar) -> ertektar tarolva', () => {
    rememberInstallWindowRole('ertektar')
    expect(readInstallWindowRole()).toBe('ertektar')
  })

  it('E3: ures/blank szerep TORLI a markert (elavult penztar marker nem maradhat)', () => {
    rememberInstallWindowRole('penztar')
    expect(readInstallWindowRole()).toBe('penztar')
    rememberInstallWindowRole('  ')
    expect(readInstallWindowRole()).toBe('')
    expect(localStorage.getItem(LAST_INSTALL_WINDOW_ROLE_KEY)).toBeNull()
  })

  it('E4: iras nelkul a marker ures', () => {
    expect(readInstallWindowRole()).toBe('')
  })
})
