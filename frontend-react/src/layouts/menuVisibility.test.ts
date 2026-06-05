/**
 * RBAC-audit (2026-06-05) — menü-láthatóság szigorú modell tesztjei a VALÓDI menuGroups ellen.
 * Fedi: full-módú least-privilege, lokál oversight-bypass, item-öröklés, csoport-ha-van-látható-item,
 * és az effectiveCanonicalRolesForPath single-source-of-truth leképzést.
 */
import { describe, it, expect } from 'vitest'
import { menuGroups, type MenuGroup } from './menuGroups'
import {
  isMenuItemVisible,
  isMenuGroupVisible,
  effectiveCanonicalRolesForPath,
  type MenuVisibilityContext,
} from './menuVisibility'

const groupByLabel = (label: string): MenuGroup =>
  menuGroups.find((g) => g.label === label) as MenuGroup
const itemByPath = (group: MenuGroup, path: string) =>
  group.items.find((i) => i.path === path)!

/** Kontextus-gyár: a megadott kanonikus szerepkörökkel rendelkező user. */
function ctxFor(roles: string[], appMode: MenuVisibilityContext['appMode']): MenuVisibilityContext {
  const set = new Set(roles)
  return {
    appMode,
    hasCanonicalRole: (r: string) => set.has(r),
    hasRole: () => true,
    featureFlags: {},
  }
}

describe('menuVisibility — konzisztens szigorítás (full mód)', () => {
  it('arfolyam_nezo (full): NEM látja az AML/Compliance csoportot (nincs benne a roles-ban)', () => {
    const aml = groupByLabel('AML / Compliance')
    expect(isMenuGroupVisible(aml, ctxFor(['arfolyam_nezo'], 'full'))).toBe(false)
  })

  it('arfolyam_nezo (full): a saját "Árfolyamok (nézet)" csoportját látja', () => {
    const rates = groupByLabel('Árfolyamok (nézet)')
    expect(isMenuGroupVisible(rates, ctxFor(['arfolyam_nezo'], 'full'))).toBe(true)
  })

  it('foertektar (full): látja az Adminisztráció-csoportot a /admin/branches item miatt, de a /workers itemet NEM', () => {
    const admin = groupByLabel('Adminisztráció')
    const ctx = ctxFor(['foertektar'], 'full')
    expect(isMenuGroupVisible(admin, ctx)).toBe(true)
    expect(isMenuItemVisible(itemByPath(admin, '/admin/branches'), admin, ctx)).toBe(true)
    // /workers item nincs saját canonicalRoles-a → örökli a csoportot [ugyvezeto, irodavezeto, irodai_dolgozo]
    expect(isMenuItemVisible(itemByPath(admin, '/workers'), admin, ctx)).toBe(false)
  })

  it('ugyvezeto (full): az Adminisztráció /workers itemét látja (öröklött csoport-roles)', () => {
    const admin = groupByLabel('Adminisztráció')
    expect(isMenuItemVisible(itemByPath(admin, '/workers'), admin, ctxFor(['ugyvezeto'], 'full'))).toBe(true)
  })

  it('penztaros (full): semmilyen felügyeleti csoportot nem lát', () => {
    const admin = groupByLabel('Adminisztráció')
    const aml = groupByLabel('AML / Compliance')
    expect(isMenuGroupVisible(admin, ctxFor(['penztaros'], 'full'))).toBe(false)
    expect(isMenuGroupVisible(aml, ctxFor(['penztaros'], 'full'))).toBe(false)
  })
})

describe('menuVisibility — lokál oversight-bypass (penztar/ertektar)', () => {
  // Megj.: minden admin-csoport modes:["full"], a mód-szűrés a bypass-tól FÜGGETLENÜL érvényes.
  // A bypass lényege: a felügyeleti user a lokál kliensben lássa a lokál (penztar/ertektar)
  // csoportot oversighthoz, holott nem tagja annak a szerepkörnek.
  it('foertektar (penztar): a bypass miatt látja a "Pénztár (Valutaváltó)" csoportot, holott nem PENZTAR_ROLES-tag', () => {
    const penztar = groupByLabel('Pénztár (Valutaváltó)')
    expect(isMenuGroupVisible(penztar, ctxFor(['foertektar'], 'penztar'))).toBe(true)
  })

  it('foertektar (full): a Pénztár-csoportot NEM látja (mód-szűrés a bypass-tól függetlenül érvényes)', () => {
    const penztar = groupByLabel('Pénztár (Valutaváltó)')
    expect(isMenuGroupVisible(penztar, ctxFor(['foertektar'], 'full'))).toBe(false)
  })

  it('penztaros (penztar): a Pénztár-csoportot szerepkör-tagság alapján látja (nem bypass)', () => {
    const penztar = groupByLabel('Pénztár (Valutaváltó)')
    expect(isMenuGroupVisible(penztar, ctxFor(['penztar'], 'penztar'))).toBe(true)
  })
})

describe('effectiveCanonicalRolesForPath — single source of truth a RoleGate-hez', () => {
  it('/admin/branches → item-szintű [foertektar, belso_ellenor, ugyvezeto]', () => {
    expect([...(effectiveCanonicalRolesForPath(menuGroups, '/admin/branches') ?? [])].sort())
      .toEqual(['belso_ellenor', 'foertektar', 'ugyvezeto'])
  })

  it('/workers → örökölt Adminisztráció-csoport [ugyvezeto, irodavezeto, irodai_dolgozo]', () => {
    expect([...(effectiveCanonicalRolesForPath(menuGroups, '/workers') ?? [])].sort())
      .toEqual(['irodai_dolgozo', 'irodavezeto', 'ugyvezeto'])
  })

  it('/settings → item-szintű [ugyvezeto]', () => {
    expect(effectiveCanonicalRolesForPath(menuGroups, '/settings')).toEqual(['ugyvezeto'])
  })

  it('ismeretlen útvonal → undefined', () => {
    expect(effectiveCanonicalRolesForPath(menuGroups, '/nincs-ilyen')).toBeUndefined()
  })

  // Fail-safe: a MenuRoleGate fail-open, ha az útvonalnak nincs menü-szerepköre. Ez a teszt
  // garantálja, hogy MINDEN App.tsx-ben MenuRoleGate-tel védett admin-route-nak van definiált
  // (nem undefined, nem üres) szerepkör-megszorítása — különben a route csendben védtelen lenne.
  it('minden MenuRoleGate-tel védett admin-route-nak van nem-üres menü-szerepköre', () => {
    const gatedPaths = [
      '/workers', '/employees', '/attendance', '/licenses', '/settings',
      '/settings/permission-matrix', '/scheduler', '/email-settings', '/handling-fee-config',
      '/audit-log', '/admin/error-monitor', '/admin/audit-diagnostics',
      '/sanction', '/compliance', '/police-requests', '/seal-tracking', '/admin/branches',
    ]
    for (const path of gatedPaths) {
      const roles = effectiveCanonicalRolesForPath(menuGroups, path)
      expect(roles, `hiányzó menü-szerepkör: ${path}`).toBeDefined()
      expect((roles ?? []).length, `üres szerepkör-lista: ${path}`).toBeGreaterThan(0)
    }
  })
})
