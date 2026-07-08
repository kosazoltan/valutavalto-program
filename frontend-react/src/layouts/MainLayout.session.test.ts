import { describe, expect, it, vi } from 'vitest'
import type { AppMode } from '../types/appMode'
import { CASHIER_APP_MODE } from '../types/appMode'
import { performBackendAwareLogout, shouldRequireDailySession } from './MainLayout'

describe('MainLayout daily session gate', () => {
  it('requires day-open session only in cashier app mode', () => {
    const expectations: Array<[AppMode, boolean]> = [
      [CASHIER_APP_MODE, true],
      ['full', false],
      ['ertektar', false],
      ['ertekszallito', false],
    ]

    for (const [appMode, expected] of expectations) {
      expect(shouldRequireDailySession(appMode)).toBe(expected)
    }
  })
})

describe('MainLayout logout', () => {
  it('calls backend logout before local logout and login navigation', async () => {
    const calls: string[] = []
    const remoteLogout = vi.fn(async () => {
      calls.push('remote')
    })
    const localLogout = vi.fn(() => {
      calls.push('local')
    })
    const navigateToLogin = vi.fn(() => {
      calls.push('navigate')
    })
    const warn = vi.fn()

    await performBackendAwareLogout(remoteLogout, localLogout, navigateToLogin, warn)

    expect(remoteLogout).toHaveBeenCalledOnce()
    expect(localLogout).toHaveBeenCalledOnce()
    expect(navigateToLogin).toHaveBeenCalledOnce()
    expect(warn).not.toHaveBeenCalled()
    expect(calls).toEqual(['remote', 'local', 'navigate'])
  })

  it('continues local logout and login navigation when backend logout fails', async () => {
    const error = new Error('network')
    const remoteLogout = vi.fn(async () => {
      throw error
    })
    const localLogout = vi.fn()
    const navigateToLogin = vi.fn()
    const warn = vi.fn()

    await performBackendAwareLogout(remoteLogout, localLogout, navigateToLogin, warn)

    expect(remoteLogout).toHaveBeenCalledOnce()
    expect(warn).toHaveBeenCalledWith(error)
    expect(localLogout).toHaveBeenCalledOnce()
    expect(navigateToLogin).toHaveBeenCalledOnce()
  })
})
