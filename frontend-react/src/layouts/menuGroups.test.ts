import { describe, expect, it } from 'vitest'
import { getDefaultRouteForRoles, menuGroups } from './menuGroups'
import type { AppMode } from '../types/appMode'

function visibleMenuLabels(appMode: AppMode): string[] {
  return menuGroups
    .filter((group) => !group.modes || group.modes.includes(appMode))
    .flatMap((group) => [
      group.label,
      ...group.items
        .filter((item) => !item.modes || item.modes.includes(appMode))
        .map((item) => item.label),
    ])
}

describe('menuGroups ertekszallito appMode', () => {
  it('ertekszallito modban van hasznalhato atadas-atveteli menu', () => {
    const labels = visibleMenuLabels('ertekszallito')

    expect(labels).toContain('Értékszállító')
    expect(labels).toContain('Átadás-átvétel aláírás')
    expect(labels).toContain('Szállítólevelek')
    expect(labels).not.toContain('Pénztáros főmenü')
    expect(labels).not.toContain('Értéktári dashboard')
  })

  it('ertekszallito role alapertelmezett route-ja a transfers oldal', () => {
    expect(getDefaultRouteForRoles(['ertekszallito'], 'ertekszallito')).toBe('/transfers')
  })

  it('legacy COURIER role alapertelmezett route-ja is a transfers oldal', () => {
    expect(getDefaultRouteForRoles(['COURIER'], 'COURIER')).toBe('/transfers')
  })

  it('FK-041/II: arfolyam_nezo alapertelmezett route-ja a versenytars-arfolyam bevitel', () => {
    expect(getDefaultRouteForRoles(['arfolyam_nezo'], 'arfolyam_nezo')).toBe('/competitor-rates')
  })

  it('FK-041/II: ha az arfolyam_nezo magasabb jogu szerepkorrel is rendelkezik, NEM a beiro oldalra megy', () => {
    expect(getDefaultRouteForRoles(['arfolyam_nezo', 'foertektar'], 'foertektar')).toBe(
      '/dashboard',
    )
  })

  // FK-041/II RateWatcherGuard-regresszió: a route-szintű néző-izoláció feltétele
  // `getDefaultRouteForRoles(...) === '/competitor-rates'`. Ezért bizonyítani kell, hogy MINDEN
  // operatív multirole-kombináció a SAJÁT oldalára megy, NEM a néző-beíróra — különben a guard
  // tévesen oda zárná (pl. egy pénztáros+néző usert elvágna a /cashier-től).
  it('FK-041/II: penztaros+arfolyam_nezo a penztar oldalra megy (guard NEM zarja a beiroba)', () => {
    expect(getDefaultRouteForRoles(['penztar', 'arfolyam_nezo'], 'penztar')).toBe('/cashier')
    // aktiv nezo-szerep mellett is a magasabb prioritasu penztar nyer (multirole forrasigazsag)
    expect(getDefaultRouteForRoles(['penztar', 'arfolyam_nezo'], 'arfolyam_nezo')).toBe('/cashier')
  })

  it('FK-041/II: ertektaros+arfolyam_nezo a treasury oldalra megy (guard NEM zarja a beiroba)', () => {
    expect(getDefaultRouteForRoles(['ertektar', 'arfolyam_nezo'], 'ertektar')).toBe('/treasury')
  })

  it('FK-041/II: ertekszallito+arfolyam_nezo a transfers oldalra megy (guard NEM zarja a beiroba)', () => {
    expect(getDefaultRouteForRoles(['ertekszallito', 'arfolyam_nezo'], 'ertekszallito')).toBe(
      '/transfers',
    )
  })

  it('FK-041/II: ugyvezeto+arfolyam_nezo a dashboardra megy (guard NEM zarja a beiroba)', () => {
    expect(getDefaultRouteForRoles(['arfolyam_nezo', 'ugyvezeto'], 'ugyvezeto')).toBe('/dashboard')
  })

  it('FK-041/II: KIZAROLAG arfolyam_nezo eseten a beiro oldal (a guard ekkor zar)', () => {
    expect(getDefaultRouteForRoles(['arfolyam_nezo'], 'arfolyam_nezo')).toBe('/competitor-rates')
    expect(getDefaultRouteForRoles(['arfolyam_nezo'], null)).toBe('/competitor-rates')
  })
})
