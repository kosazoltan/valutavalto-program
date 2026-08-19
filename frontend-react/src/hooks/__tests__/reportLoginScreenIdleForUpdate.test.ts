import { describe, it, expect, vi, beforeEach } from 'vitest'
import {
  reportLoginScreenIdleForUpdate,
  markAuthenticatedSession,
  HAD_AUTH_SESSION_KEY,
} from '../reportLoginScreenIdleForUpdate'

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
