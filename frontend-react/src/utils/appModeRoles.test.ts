import { describe, expect, it } from 'vitest'
import { isRoleSelectableForAppMode } from './appModeRoles'

describe('isRoleSelectableForAppMode', () => {
  it('lokalis role-t csak a sajat appMode-jaban enged', () => {
    expect(isRoleSelectableForAppMode('penztar', 'penztar')).toBe(true)
    expect(isRoleSelectableForAppMode('penztar', 'ertektar')).toBe(false)
    expect(isRoleSelectableForAppMode('ertektar', 'ertektar')).toBe(true)
    expect(isRoleSelectableForAppMode('ertektar', 'penztar')).toBe(false)
  })

  it('server role-t full es lokalis felugyeleti belepeshez is enged', () => {
    expect(isRoleSelectableForAppMode('foertektar', 'full')).toBe(true)
    expect(isRoleSelectableForAppMode('foertektar', 'penztar')).toBe(true)
    expect(isRoleSelectableForAppMode('ADMIN', 'ertektar')).toBe(true)
  })

  it('legacy penztar role-t csak penztar modban enged', () => {
    expect(isRoleSelectableForAppMode('CASHIER', 'penztar')).toBe(true)
    expect(isRoleSelectableForAppMode('CASHIER', 'ertektar')).toBe(false)
    expect(isRoleSelectableForAppMode('CASHIER', 'full')).toBe(false)
  })

  it('legacy ertektar role-t csak ertektar vagy felugyeleti modban enged', () => {
    expect(isRoleSelectableForAppMode('TREASURY_MANAGER', 'ertektar')).toBe(true)
    expect(isRoleSelectableForAppMode('TREASURY_MANAGER', 'penztar')).toBe(false)
    expect(isRoleSelectableForAppMode('TREASURY_MANAGER', 'full')).toBe(false)
  })

  it('hianyzo role-t minden appMode-ban elutasit', () => {
    expect(isRoleSelectableForAppMode(null, 'penztar')).toBe(false)
    expect(isRoleSelectableForAppMode(undefined, 'ertektar')).toBe(false)
  })
})
