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
    ]

    for (const [appMode, expected] of expectations) {
      expect(shouldRequireDailySession(appMode)).toBe(expected)
    }
  })
})

describe('MainLayout daily session gate — role-aware (FKH-041 FR-2)', () => {
  it('B1: penztar mod + ertektar aktiv szerep -> NINCS napnyitas-kapu', () => {
    expect(shouldRequireDailySession('penztar', 'ertektar')).toBe(false)
  })

  it('B2: penztar mod + penztar aktiv szerep -> kapu él', () => {
    expect(shouldRequireDailySession('penztar', 'penztar')).toBe(true)
  })

  it('B3: penztar mod + foertektar aktiv szerep -> NINCS kapu', () => {
    expect(shouldRequireDailySession('penztar', 'foertektar')).toBe(false)
  })

  it('B4: penztar mod + ertekszallito aktiv szerep -> NINCS kapu', () => {
    expect(shouldRequireDailySession('penztar', 'ertekszallito')).toBe(false)
  })

  it('B5: penztar mod + CASHIER legacy szerep -> kapu él (kanonizacio: penztar)', () => {
    expect(shouldRequireDailySession('penztar', 'CASHIER')).toBe(true)
  })

  it('B6: penztar mod + TREASURY_MANAGER legacy szerep -> NINCS kapu (kanonizacio: ertektar)', () => {
    expect(shouldRequireDailySession('penztar', 'TREASURY_MANAGER')).toBe(false)
  })

  it('B7: penztar mod, null szerep -> kapu él (ismeretlen => nem gyengitunk)', () => {
    expect(shouldRequireDailySession('penztar', null)).toBe(true)
  })

  it('B8: penztar mod, undefined szerep -> kapu él', () => {
    expect(shouldRequireDailySession('penztar', undefined)).toBe(true)
  })

  it('B9: penztar mod, ures string szerep -> kapu él', () => {
    expect(shouldRequireDailySession('penztar', '')).toBe(true)
  })

  it('B10: penztar mod, whitespace szerep -> kapu él (trim -> ures)', () => {
    expect(shouldRequireDailySession('penztar', '  ')).toBe(true)
  })

  it('B11: ertektar mod + penztar szerep -> NINCS kapu (a mod-kapu nyer)', () => {
    expect(shouldRequireDailySession('ertektar', 'penztar')).toBe(false)
  })

  it('B12: ertektar mod + ertektar szerep -> NINCS kapu', () => {
    expect(shouldRequireDailySession('ertektar', 'ertektar')).toBe(false)
  })

  it('B13: full mod + penztar szerep -> NINCS kapu', () => {
    expect(shouldRequireDailySession('full', 'penztar')).toBe(false)
  })

  it('B14: rate-maker mod + foertektar szerep -> NINCS kapu', () => {
    expect(shouldRequireDailySession('rate-maker', 'foertektar')).toBe(false)
  })

  it('B15: egyargumentumu visszamenoleges kompatibilitas: penztar -> kapu él', () => {
    expect(shouldRequireDailySession('penztar')).toBe(true)
  })

  it('B16: egyargumentumu visszamenoleges kompatibilitas: ertektar -> NINCS kapu', () => {
    expect(shouldRequireDailySession('ertektar')).toBe(false)
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
