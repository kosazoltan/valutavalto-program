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
})
