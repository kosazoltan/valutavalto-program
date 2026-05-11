import { describe, expect, it } from 'vitest'
import { canonicalizeRoleForAppMode, isRoleSelectableForAppMode } from './appModeRoles'

describe('isRoleSelectableForAppMode', () => {
  it('lokalis role-t barmely lokalis appMode-ban enged (kis iroda flexibilitas)', () => {
    // Sajat modban: igen
    expect(isRoleSelectableForAppMode('penztar', 'penztar')).toBe(true)
    expect(isRoleSelectableForAppMode('ertektar', 'ertektar')).toBe(true)
    expect(isRoleSelectableForAppMode('ertekszallito', 'ertekszallito')).toBe(true)
    // Keresztbe: szinten igen (kis irodakban egy dolgozo tobb modban dolgozhat)
    expect(isRoleSelectableForAppMode('ertektar', 'penztar')).toBe(true)
    expect(isRoleSelectableForAppMode('penztar', 'ertektar')).toBe(true)
    expect(isRoleSelectableForAppMode('ertekszallito', 'penztar')).toBe(true)
    expect(isRoleSelectableForAppMode('penztar', 'ertekszallito')).toBe(true)
  })

  it('lokalis role-t full (szerver/browser) modban NEM enged', () => {
    expect(isRoleSelectableForAppMode('penztar', 'full')).toBe(false)
    expect(isRoleSelectableForAppMode('ertektar', 'full')).toBe(false)
    expect(isRoleSelectableForAppMode('ertekszallito', 'full')).toBe(false)
  })

  it('server role-t full es lokalis felugyeleti belepeshez is enged', () => {
    expect(isRoleSelectableForAppMode('foertektar', 'full')).toBe(true)
    expect(isRoleSelectableForAppMode('foertektar', 'penztar')).toBe(true)
    expect(isRoleSelectableForAppMode('ADMIN', 'ertektar')).toBe(true)
    expect(isRoleSelectableForAppMode('ugyvezeto', 'ertekszallito')).toBe(true)
  })

  it('legacy courier role-t barmely lokalis modban enged', () => {
    expect(isRoleSelectableForAppMode('COURIER', 'ertekszallito')).toBe(true)
    expect(isRoleSelectableForAppMode('COURIER', 'penztar')).toBe(true)
    expect(isRoleSelectableForAppMode('COURIER', 'ertektar')).toBe(true)
    expect(isRoleSelectableForAppMode('COURIER', 'full')).toBe(false)
    expect(canonicalizeRoleForAppMode('COURIER')).toBe('ertekszallito')
  })

  it('legacy penztar role-t barmely lokalis modban enged', () => {
    expect(isRoleSelectableForAppMode('CASHIER', 'penztar')).toBe(true)
    expect(isRoleSelectableForAppMode('CASHIER', 'ertektar')).toBe(true)
    expect(isRoleSelectableForAppMode('CASHIER', 'ertekszallito')).toBe(true)
    expect(isRoleSelectableForAppMode('CASHIER', 'full')).toBe(false)
  })

  it('legacy ertektar role-t barmely lokalis modban enged', () => {
    expect(isRoleSelectableForAppMode('TREASURY_MANAGER', 'ertektar')).toBe(true)
    expect(isRoleSelectableForAppMode('TREASURY_MANAGER', 'penztar')).toBe(true)
    expect(isRoleSelectableForAppMode('TREASURY_MANAGER', 'ertekszallito')).toBe(true)
    expect(isRoleSelectableForAppMode('TREASURY_MANAGER', 'full')).toBe(false)
  })

  it('hianyzo role-t minden appMode-ban elutasit', () => {
    expect(isRoleSelectableForAppMode(null, 'penztar')).toBe(false)
    expect(isRoleSelectableForAppMode(undefined, 'ertektar')).toBe(false)
  })
})
