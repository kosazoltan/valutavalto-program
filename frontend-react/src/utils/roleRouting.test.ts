import { describe, it, expect } from 'vitest'
import { getDefaultRouteForRoles } from '../layouts/menuGroups'
import { isRoleSelectableForAppMode } from './appModeRoles'

/**
 * Role-alapú routing tesztek.
 *
 * A role-alapu default route es szerver whitelist logika edge case-ei.
 */

function getDefaultRouteForRole(role?: string | null): string {
  return getDefaultRouteForRoles(role ? [role] : undefined, role)
}

describe('getDefaultRouteForRole', () => {
  it.each([
    ['CASHIER', '/cashier'],
    ['MANAGER', '/treasury'],
    ['TREASURY_MANAGER', '/treasury'],
    ['COURIER', '/transfers'],
    ['SUPERVISOR', '/dashboard'],
    ['ADMIN', '/dashboard'],
    ['INTERN', '/dashboard'],
    ['VIEWER', '/dashboard'],
  ])('role=%s → route=%s', (role, expected) => {
    expect(getDefaultRouteForRole(role)).toBe(expected)
  })

  it('undefined role → /dashboard', () => {
    expect(getDefaultRouteForRole(undefined)).toBe('/dashboard')
  })

  it('null role → /dashboard', () => {
    expect(getDefaultRouteForRole(null)).toBe('/dashboard')
  })

  it('üres string role → /dashboard', () => {
    expect(getDefaultRouteForRole('')).toBe('/dashboard')
  })

  it('ismeretlen role → /dashboard (default)', () => {
    expect(getDefaultRouteForRole('UNKNOWN_ROLE_XYZ')).toBe('/dashboard')
  })
})

describe('SERVER_ALLOWED_ROLES whitelist', () => {
  it('SUPERVISOR engedélyezett', () => {
    expect(isRoleSelectableForAppMode('SUPERVISOR', 'full')).toBe(true)
  })

  it('MANAGER engedélyezett', () => {
    expect(isRoleSelectableForAppMode('MANAGER', 'full')).toBe(true)
  })

  it('ADMIN engedélyezett', () => {
    expect(isRoleSelectableForAppMode('ADMIN', 'full')).toBe(true)
  })

  it('CASHIER NEM engedélyezett', () => {
    expect(isRoleSelectableForAppMode('CASHIER', 'full')).toBe(false)
  })

  it('TREASURY_MANAGER NEM engedélyezett', () => {
    expect(isRoleSelectableForAppMode('TREASURY_MANAGER', 'full')).toBe(false)
  })

  it('INTERN NEM engedélyezett', () => {
    expect(isRoleSelectableForAppMode('INTERN', 'full')).toBe(false)
  })

  it('kisbetus "admin" role-t is normalizalva engedi', () => {
    expect(isRoleSelectableForAppMode('admin', 'full')).toBe(true)
  })

  it('mixed case "Supervisor" role-t is normalizalva engedi', () => {
    expect(isRoleSelectableForAppMode('Supervisor', 'full')).toBe(true)
  })
})

describe('RBAC + Routing kombináció', () => {
  it.each([
    ['SUPERVISOR', true, '/dashboard'],
    ['MANAGER', true, '/treasury'],
    ['ADMIN', true, '/dashboard'],
    ['CASHIER', false, '/cashier'],
    ['TREASURY_MANAGER', false, '/treasury'],
    ['COURIER', false, '/transfers'],
    ['INTERN', false, '/dashboard'],
  ])('%s → allowed=%s, route=%s', (role, expectedAllowed, expectedRoute) => {
    const allowed = isRoleSelectableForAppMode(role, 'full')
    const route = getDefaultRouteForRole(role)
    expect(allowed).toBe(expectedAllowed)
    expect(route).toBe(expectedRoute)
  })
})
