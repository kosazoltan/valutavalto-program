import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import {
  reportLoginScreenIdleForUpdate,
  decideLoginScreenShiftState,
  markAuthenticatedSession,
  HAD_AUTH_SESSION_KEY,
  LAST_INSTALL_WINDOW_ROLE_KEY,
  rememberInstallWindowRole,
  readInstallWindowRole,
} from '../reportLoginScreenIdleForUpdate'
import { OPEN_DAY_OBSERVED_KEY } from '../../utils/openDayMarker'
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

  it('hideg indítás, aktív belépőképernyő -> SHIFT_OPEN (fail-closed default)', async () => {
    const setShiftState = vi.fn().mockResolvedValue({ accepted: true })
    await expect(reportLoginScreenIdleForUpdate({ suiteUpdate: { setShiftState } })).resolves.toBe(
      'SHIFT_OPEN',
    )
    expect(setShiftState).not.toHaveBeenCalledWith('IDLE_BEFORE_OPEN')
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

  it('D7: appMode = null -> activity default SHIFT_OPEN; explicit IDLE_TIMEOUT esetén a hadAuth ternary él (back-compat)', async () => {
    const setShiftState = okShiftStateMock()
    await expect(reportLoginScreenIdleForUpdate(makeApi(setShiftState), false, null)).resolves.toBe(
      'SHIFT_OPEN',
    )
    await expect(
      reportLoginScreenIdleForUpdate(
        makeApi(setShiftState),
        false,
        null,
        '',
        'IDLE_TIMEOUT',
        false,
      ),
    ).resolves.toBe('IDLE_BEFORE_OPEN')
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

  it('D11 (REWRITTEN = G1): penztar mod + penztar marker -> mount/ACTIVE: SHIFT_OPEN (a Google-OTP hurok bug-pinje); mért IDLE_TIMEOUT + nyitottnap-marker nélkül: IDLE_BEFORE_OPEN', async () => {
    const setShiftState = okShiftStateMock()
    // Mount (default activity = ACTIVE): SOHA nem telepíthető a belépőképernyőn.
    await expect(
      reportLoginScreenIdleForUpdate(makeApi(setShiftState), false, 'penztar', 'penztar'),
    ).resolves.toBe('SHIFT_OPEN')
    expect(setShiftState).not.toHaveBeenCalledWith('IDLE_BEFORE_OPEN')
    // Mért idle + nincs nyitott nap: a bizonyított pénztáros gép továbbra is telepíthető.
    await expect(
      reportLoginScreenIdleForUpdate(
        makeApi(setShiftState),
        false,
        'penztar',
        'penztar',
        'IDLE_TIMEOUT',
        false,
      ),
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

  it('D13 (REWRITTEN = G13): penztar mod + CASHIER marker (legacy -> penztar kanonizacio) -> ACTIVE: SHIFT_OPEN; IDLE_TIMEOUT + marker nélkül: IDLE_BEFORE_OPEN', async () => {
    const setShiftState = okShiftStateMock()
    await expect(
      reportLoginScreenIdleForUpdate(makeApi(setShiftState), false, 'penztar', 'CASHIER'),
    ).resolves.toBe('SHIFT_OPEN')
    await expect(
      reportLoginScreenIdleForUpdate(
        makeApi(setShiftState),
        false,
        'penztar',
        'CASHIER',
        'IDLE_TIMEOUT',
        false,
      ),
    ).resolves.toBe('IDLE_BEFORE_OPEN')
  })

  it('D14: logout utan penztar modban, penztar marker -> SHIFT_OPEN (hadAuth tovabbra is nyer, regresszió-pin)', async () => {
    const setShiftState = okShiftStateMock()
    await expect(
      reportLoginScreenIdleForUpdate(makeApi(setShiftState), true, 'penztar', 'penztar'),
    ).resolves.toBe('SHIFT_OPEN')
  })

  it('D15 (REWRITTEN): appMode = null + ertektar marker -> ACTIVE: SHIFT_OPEN; IDLE_TIMEOUT: IDLE_BEFORE_OPEN (back-compat: a marker csak adott modnál él)', async () => {
    const setShiftState = okShiftStateMock()
    await expect(
      reportLoginScreenIdleForUpdate(makeApi(setShiftState), false, null, 'ertektar'),
    ).resolves.toBe('SHIFT_OPEN')
    await expect(
      reportLoginScreenIdleForUpdate(
        makeApi(setShiftState),
        false,
        null,
        'ertektar',
        'IDLE_TIMEOUT',
        false,
      ),
    ).resolves.toBe('IDLE_BEFORE_OPEN')
  })
})

describe('reportLoginScreenIdleForUpdate — activity-tudatos döntés + nyitott nap (Google-OTP hurok, 2026-08-30)', () => {
  beforeEach(() => {
    sessionStorage.clear()
    localStorage.clear()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  function makeApi(setShiftState: (state: ShiftState) => Promise<unknown>) {
    return { suiteUpdate: { setShiftState } }
  }

  function okShiftStateMock() {
    return vi.fn(async (_state: ShiftState): Promise<unknown> => ({ accepted: true }))
  }

  it('G2b: explicit ACTIVE -> SHIFT_OPEN (a mount soha nem telepíthető)', async () => {
    const setShiftState = okShiftStateMock()
    await expect(
      reportLoginScreenIdleForUpdate(makeApi(setShiftState), false, 'penztar', 'penztar', 'ACTIVE'),
    ).resolves.toBe('SHIFT_OPEN')
  })

  it('G3: IDLE_TIMEOUT + nincs nyitott nap -> IDLE_BEFORE_OPEN (a felügyelet nélküli éjszakai gép továbbra is frissül)', async () => {
    const setShiftState = okShiftStateMock()
    await expect(
      reportLoginScreenIdleForUpdate(
        makeApi(setShiftState),
        false,
        'penztar',
        'penztar',
        'IDLE_TIMEOUT',
        false,
      ),
    ).resolves.toBe('IDLE_BEFORE_OPEN')
  })

  it('G5: IDLE_TIMEOUT + hadAuth -> SHIFT_OPEN (a logout-ternár továbbra is nyer, D14 preserved)', async () => {
    const setShiftState = okShiftStateMock()
    await expect(
      reportLoginScreenIdleForUpdate(
        makeApi(setShiftState),
        true,
        'penztar',
        'penztar',
        'IDLE_TIMEOUT',
        false,
      ),
    ).resolves.toBe('SHIFT_OPEN')
  })

  it('G6: ertektar appMode + IDLE_TIMEOUT -> SHIFT_OPEN, soha IDLE_BEFORE_OPEN (FKH-041 FR-3)', async () => {
    const setShiftState = okShiftStateMock()
    await expect(
      reportLoginScreenIdleForUpdate(
        makeApi(setShiftState),
        false,
        'ertektar',
        'penztar',
        'IDLE_TIMEOUT',
        false,
      ),
    ).resolves.toBe('SHIFT_OPEN')
    expect(setShiftState).not.toHaveBeenCalledWith('IDLE_BEFORE_OPEN')
  })

  it('G7: penztar appMode + üres marker + IDLE_TIMEOUT -> SHIFT_OPEN (fail-closed, bizonyítatlan gép)', async () => {
    const setShiftState = okShiftStateMock()
    await expect(
      reportLoginScreenIdleForUpdate(
        makeApi(setShiftState),
        false,
        'penztar',
        '',
        'IDLE_TIMEOUT',
        false,
      ),
    ).resolves.toBe('SHIFT_OPEN')
  })

  it('G10: IDLE_TIMEOUT + nyitott nap ma megfigyelve -> SHIFT_OPEN (C3: nincs „a nap még nem indult el" hazugság)', async () => {
    const setShiftState = okShiftStateMock()
    await expect(
      reportLoginScreenIdleForUpdate(
        makeApi(setShiftState),
        false,
        'penztar',
        'penztar',
        'IDLE_TIMEOUT',
        true,
      ),
    ).resolves.toBe('SHIFT_OPEN')
  })

  it('G11: elavult (tegnapi) marker nem blokkolja az éjszakai ablakot (AC-4)', async () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(2026, 7, 30, 3, 0))
    localStorage.setItem(OPEN_DAY_OBSERVED_KEY, '2026-08-29')
    const setShiftState = okShiftStateMock()
    await expect(
      reportLoginScreenIdleForUpdate(
        makeApi(setShiftState),
        false,
        'penztar',
        'penztar',
        'IDLE_TIMEOUT',
      ),
    ).resolves.toBe('IDLE_BEFORE_OPEN')
  })

  it('G16: appMode = null + üres marker + IDLE_TIMEOUT -> IDLE_BEFORE_OPEN (D7/D15 back-compat fele)', async () => {
    const setShiftState = okShiftStateMock()
    await expect(
      reportLoginScreenIdleForUpdate(
        makeApi(setShiftState),
        false,
        null,
        '',
        'IDLE_TIMEOUT',
        false,
      ),
    ).resolves.toBe('IDLE_BEFORE_OPEN')
  })

  it('G18: decideLoginScreenShiftState tiszta függvény IPC nélkül -> SHIFT_OPEN', () => {
    expect(
      decideLoginScreenShiftState({
        hadAuth: false,
        appMode: 'penztar',
        lastInstallWindowRole: 'penztar',
        activity: 'ACTIVE',
        openDayObservedToday: false,
      }),
    ).toBe('SHIFT_OPEN')
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
