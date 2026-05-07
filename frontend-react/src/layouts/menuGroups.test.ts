import { describe, expect, it } from 'vitest'
import { getDefaultRouteForRoles, menuGroups } from './menuGroups'

function visibleMenuLabels(appMode: string): string[] {
  return menuGroups
    .filter((group) => !group.modes || (group.modes as readonly string[]).includes(appMode))
    .flatMap((group) => [
      group.label,
      ...group.items
        .filter((item) => !item.modes || (item.modes as readonly string[]).includes(appMode))
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
})
