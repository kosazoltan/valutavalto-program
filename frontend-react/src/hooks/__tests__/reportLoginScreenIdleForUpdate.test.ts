import { describe, it, expect, vi } from 'vitest'
import { reportLoginScreenIdleForUpdate } from '../reportLoginScreenIdleForUpdate'

describe('reportLoginScreenIdleForUpdate', () => {
  it('Electron nélkül no-op (false)', async () => {
    await expect(reportLoginScreenIdleForUpdate(null)).resolves.toBe(false)
  })

  it('suiteUpdate hiányában no-op (false)', async () => {
    await expect(reportLoginScreenIdleForUpdate({})).resolves.toBe(false)
  })

  it('belépőképernyőn IDLE_BEFORE_OPEN-t jelent — belépés nélkül is telepíthető', async () => {
    const setShiftState = vi.fn().mockResolvedValue({ accepted: true })
    await expect(reportLoginScreenIdleForUpdate({ suiteUpdate: { setShiftState } })).resolves.toBe(
      true,
    )
    expect(setShiftState).toHaveBeenCalledWith('IDLE_BEFORE_OPEN')
  })

  it('IPC hiba nem dob, false-t ad', async () => {
    const setShiftState = vi.fn().mockRejectedValue(new Error('ipc'))
    await expect(reportLoginScreenIdleForUpdate({ suiteUpdate: { setShiftState } })).resolves.toBe(
      false,
    )
  })
})
