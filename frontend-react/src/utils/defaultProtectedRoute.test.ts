/**
 * FKH-041 FR-1 — lokál terminál belépés utáni kezdő útvonala SZEREPKÖR-alapú.
 *
 * `resolveDefaultProtectedRoute` tiszta függvény: flavor/appMode/roles/activeRole
 * paramétereket kap (NEM olvassa közvetlenül az `import.meta.env`-et), így
 * flavoronként unit-tesztelhető. A route-precedencia egyetlen forrása a
 * `getDefaultRouteForRoles` (menuGroups.ts) marad.
 */
import { describe, expect, it } from 'vitest'
import type { AppFlavor } from './clientEnv'
import type { AppMode } from '../types/appMode'
import { resolveDefaultProtectedRoute } from './defaultProtectedRoute'

describe('resolveDefaultProtectedRoute — FKH-041 FR-1', () => {
  function route(params: {
    flavor: AppFlavor
    appMode: AppMode
    roles?: readonly string[] | null
    activeRole?: string | null
  }): string {
    return resolveDefaultProtectedRoute(params)
  }

  it('A1: lokál terminál penztar módban ertektar szereppel -> /treasury (a javított defekt)', () => {
    expect(
      route({ flavor: '', appMode: 'penztar', roles: ['ertektar'], activeRole: 'ertektar' }),
    ).toBe('/treasury')
  })

  it('A2: penztar szerep -> /cashier', () => {
    expect(
      route({ flavor: '', appMode: 'penztar', roles: ['penztar'], activeRole: 'penztar' }),
    ).toBe('/cashier')
  })

  it('A3: ertektar appMode + ertektar szerep -> /treasury', () => {
    expect(
      route({ flavor: '', appMode: 'ertektar', roles: ['ertektar'], activeRole: 'ertektar' }),
    ).toBe('/treasury')
  })

  it('A4: penztar + ertektar multiszerep, aktiv penztar -> /cashier (penztar precedencia)', () => {
    expect(
      route({
        flavor: '',
        appMode: 'penztar',
        roles: ['penztar', 'ertektar'],
        activeRole: 'penztar',
      }),
    ).toBe('/cashier')
  })

  it('A5: ertekszallito -> /transfers', () => {
    expect(
      route({
        flavor: '',
        appMode: 'penztar',
        roles: ['ertekszallito'],
        activeRole: 'ertekszallito',
      }),
    ).toBe('/transfers')
  })

  it('A6: TREASURY_MANAGER legacy role -> /treasury (kanonizacio)', () => {
    expect(
      route({
        flavor: '',
        appMode: 'penztar',
        roles: ['TREASURY_MANAGER'],
        activeRole: 'TREASURY_MANAGER',
      }),
    ).toBe('/treasury')
  })

  it('A7: ures role-halmaz -> /dashboard (restore elotti allapot, nincs regresszio)', () => {
    expect(route({ flavor: '', appMode: 'penztar', roles: [], activeRole: null })).toBe(
      '/dashboard',
    )
  })

  it('A8: null/undefined role-bemenet -> /dashboard', () => {
    expect(route({ flavor: '', appMode: 'penztar', roles: null, activeRole: undefined })).toBe(
      '/dashboard',
    )
  })

  it('A9: full appMode -> /central-workstation', () => {
    expect(
      route({ flavor: '', appMode: 'full', roles: ['ugyvezeto'], activeRole: 'ugyvezeto' }),
    ).toBe('/central-workstation')
  })

  it('A10: central-workstation flavor felulirja az appMode-ot', () => {
    expect(
      route({
        flavor: 'central-workstation',
        appMode: 'penztar',
        roles: ['ertektar'],
        activeRole: 'ertektar',
      }),
    ).toBe('/central-workstation')
  })

  it('A11: rate-maker flavor felulirja az appMode-ot', () => {
    expect(
      route({
        flavor: 'rate-maker',
        appMode: 'penztar',
        roles: ['ertektar'],
        activeRole: 'ertektar',
      }),
    ).toBe('/rates/main')
  })

  it('A12: rate-maker appMode -> /rates/main', () => {
    expect(
      route({ flavor: '', appMode: 'rate-maker', roles: ['foertektar'], activeRole: 'foertektar' }),
    ).toBe('/rates/main')
  })

  it('A13: foertektar lokál terminalon -> /dashboard (pitfall 5, szandekosan rogzitve)', () => {
    expect(
      route({ flavor: '', appMode: 'penztar', roles: ['foertektar'], activeRole: 'foertektar' }),
    ).toBe('/dashboard')
  })

  it('A14: ertektar + arfolyam_nezo -> /treasury (a watcher sosem nyer az operativ szereppel szemben)', () => {
    expect(
      route({
        flavor: '',
        appMode: 'penztar',
        roles: ['ertektar', 'arfolyam_nezo'],
        activeRole: 'ertektar',
      }),
    ).toBe('/treasury')
  })
})
