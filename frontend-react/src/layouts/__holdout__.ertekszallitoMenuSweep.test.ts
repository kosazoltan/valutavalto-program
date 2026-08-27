/**
 * HOLDOUT H3 (a coder NEM látta) — ertekszallito (futár) TELJES menü-univerzum-söprés +
 * a legacy COURIER-fallback érintetlenségének pinje.
 *
 * A publikus terv tesztjei a nevesített route-okat (transfers/new stb.) ellenőrzik. Ez a próba
 * az EGÉSZ menuGroups-univerzumot söpri: egy bárhol felejtett vagy újonnan bevezetett
 * 'ertekszallito' grant, illetve egy csendben eltört COURIER→/transfers landolási fallback itt
 * bukik ki. A user-döntés (2026-07-14): a futár tiszta dokumentáció — nincs login, nincs menü.
 */
import { describe, it, expect, vi } from 'vitest'
import { menuGroups, getDefaultRouteForRoles } from './menuGroups'
import { isMenuGroupVisible, isMenuItemVisible, type MenuVisibilityContext } from './menuVisibility'
import { canonicalizeRoleForAppMode } from '../utils/appModeRoles'

vi.mock('../services/api/index', () => ({
  persistToken: vi.fn().mockResolvedValue(undefined),
  clearPersistedToken: vi.fn().mockResolvedValue(undefined),
}))

const ALL_APP_MODES: MenuVisibilityContext['appMode'][] = [
  'full',
  'penztar',
  'ertektar',
  'rate-maker',
]

function courierCtx(appMode: MenuVisibilityContext['appMode']): MenuVisibilityContext {
  return {
    appMode,
    hasCanonicalRole: (r: string) => r === 'ertekszallito',
    hasRole: () => true,
    featureFlags: {},
  }
}

describe('HOLDOUT H3 — ertekszallito menü-univerzum söprés + legacy fallback pin', () => {
  it('1) SEMMILYEN menü-csoport és -item canonicalRoles-a nem tartalmaz ertekszallito-t', () => {
    const offendingGroups = menuGroups
      .filter((g) => (g.canonicalRoles ?? []).includes('ertekszallito'))
      .map((g) => g.label)
    const offendingItems = menuGroups
      .flatMap((g) => g.items)
      .filter((i) => (i.canonicalRoles ?? []).includes('ertekszallito'))
      .map((i) => i.path)
    expect(offendingGroups).toEqual([])
    expect(offendingItems).toEqual([])
  })

  it('2) courier-only user MIND A 4 appMode-ban 0 látható (csoport, item) párt kap', () => {
    for (const mode of ALL_APP_MODES) {
      const ctx = courierCtx(mode)
      const visibleGroups = menuGroups.filter((g) => isMenuGroupVisible(g, ctx))
      expect(visibleGroups, `csoport-láthatóság mode=${mode}`).toEqual([])
      const visibleItems = menuGroups.flatMap((g) =>
        g.items.filter((i) => isMenuItemVisible(i, g, ctx)),
      )
      expect(
        visibleItems.map((i) => i.path),
        `item-láthatóság mode=${mode}`,
      ).toEqual([])
    }
  })

  it('3) legacy COURIER role-leképezés és /transfers landolási fallback VÁLTOZATLAN', () => {
    // A kivezetés a MENÜT érinti — a legacy role-canonicalizálás és a belépési landolás nem.
    expect(canonicalizeRoleForAppMode('COURIER')).toBe('ertekszallito')
    expect(getDefaultRouteForRoles(['COURIER'], 'COURIER')).toBe('/transfers')
    expect(getDefaultRouteForRoles(['ertekszallito'], 'ertekszallito')).toBe('/transfers')
  })
})
