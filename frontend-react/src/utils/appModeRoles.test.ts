import { describe, expect, it } from 'vitest'
import { canonicalizeRoleForAppMode, isRoleSelectableForAppMode } from './appModeRoles'

describe('isRoleSelectableForAppMode', () => {
  it('lokalis role-t csak a sajat appMode-jaban enged', () => {
    expect(isRoleSelectableForAppMode('penztar', 'penztar')).toBe(true)
    expect(isRoleSelectableForAppMode('penztar', 'ertektar')).toBe(false)
    expect(isRoleSelectableForAppMode('ertektar', 'ertektar')).toBe(true)
    expect(isRoleSelectableForAppMode('ertektar', 'penztar')).toBe(false)
    expect(isRoleSelectableForAppMode('ertekszallito', 'ertekszallito')).toBe(true)
    expect(isRoleSelectableForAppMode('ertekszallito', 'penztar')).toBe(false)
  })

  it('server role-t full es lokalis felugyeleti belepeshez is enged', () => {
    expect(isRoleSelectableForAppMode('foertektar', 'full')).toBe(true)
    expect(isRoleSelectableForAppMode('foertektar', 'penztar')).toBe(true)
    expect(isRoleSelectableForAppMode('ADMIN', 'ertektar')).toBe(true)
    expect(isRoleSelectableForAppMode('ugyvezeto', 'ertekszallito')).toBe(true)
  })

  it('legacy courier role-t ertekszallito appMode-ban enged', () => {
    expect(isRoleSelectableForAppMode('COURIER', 'ertekszallito')).toBe(true)
    expect(isRoleSelectableForAppMode('COURIER', 'ertektar')).toBe(false)
    expect(canonicalizeRoleForAppMode('COURIER')).toBe('ertekszallito')
  })
})
