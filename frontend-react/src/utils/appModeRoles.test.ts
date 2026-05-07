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
})
