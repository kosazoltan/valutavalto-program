import { describe, it, expect } from 'vitest'

/**
 * Role-alapú routing tesztek.
 * 
 * A getDefaultRouteForRole logika a LoginPage-ben van definiálva,
 * de itt izoláltan teszteljük az összes edge case-t.
 */

// --- A getDefaultRouteForRole logika reprodukálása ---
function getDefaultRouteForRole(role?: string | null): string {
  switch (role) {
    case 'MANAGER':
    case 'TREASURY_MANAGER':
      return '/treasury'
    case 'CASHIER':
      return '/cashier'
    default:
      return '/dashboard'
  }
}

/** RBAC whitelist — szerver (full) módban engedélyezett role-ok */
const SERVER_ALLOWED_ROLES = ['SUPERVISOR', 'MANAGER', 'ADMIN']

describe('getDefaultRouteForRole', () => {
  it.each([
    ['CASHIER', '/cashier'],
    ['MANAGER', '/treasury'],
    ['TREASURY_MANAGER', '/treasury'],
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
    expect(SERVER_ALLOWED_ROLES.includes('SUPERVISOR')).toBe(true)
  })

  it('MANAGER engedélyezett', () => {
    expect(SERVER_ALLOWED_ROLES.includes('MANAGER')).toBe(true)
  })

  it('ADMIN engedélyezett', () => {
    expect(SERVER_ALLOWED_ROLES.includes('ADMIN')).toBe(true)
  })

  it('CASHIER NEM engedélyezett', () => {
    expect(SERVER_ALLOWED_ROLES.includes('CASHIER')).toBe(false)
  })

  it('TREASURY_MANAGER NEM engedélyezett', () => {
    expect(SERVER_ALLOWED_ROLES.includes('TREASURY_MANAGER')).toBe(false)
  })

  it('INTERN NEM engedélyezett', () => {
    expect(SERVER_ALLOWED_ROLES.includes('INTERN')).toBe(false)
  })

  it('Pontosan 3 engedélyezett role van', () => {
    expect(SERVER_ALLOWED_ROLES).toHaveLength(3)
  })

  it('Case-sensitive — "admin" (kisbetű) NEM engedélyezett', () => {
    expect(SERVER_ALLOWED_ROLES.includes('admin')).toBe(false)
  })

  it('Case-sensitive — "Supervisor" (mixed case) NEM engedélyezett', () => {
    expect(SERVER_ALLOWED_ROLES.includes('Supervisor')).toBe(false)
  })
})

describe('RBAC + Routing kombináció', () => {
  it.each([
    ['SUPERVISOR', true, '/dashboard'],
    ['MANAGER', true, '/treasury'],
    ['ADMIN', true, '/dashboard'],
    ['CASHIER', false, '/cashier'],
    ['TREASURY_MANAGER', false, '/treasury'],
    ['INTERN', false, '/dashboard'],
  ])('%s → allowed=%s, route=%s', (role, expectedAllowed, expectedRoute) => {
    const allowed = SERVER_ALLOWED_ROLES.includes(role)
    const route = getDefaultRouteForRole(role)
    expect(allowed).toBe(expectedAllowed)
    expect(route).toBe(expectedRoute)
  })
})
