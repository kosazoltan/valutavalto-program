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
const itemByPath = (group: MenuGroup, path: string) => group.items.find((i) => i.path === path)!

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

  it('FK-041/II: arfolyam_nezo (full): NEM látja a belső "Árfolyamok (nézet)" csoportot', () => {
    const rates = groupByLabel('Árfolyamok (nézet)')
    expect(isMenuGroupVisible(rates, ctxFor(['arfolyam_nezo'], 'full'))).toBe(false)
  })

  it('FK-041/II: arfolyam_nezo (full): a saját "Versenytárs-árfolyam" beíró csoportját látja', () => {
    const competitor = groupByLabel('Versenytárs-árfolyam')
    expect(isMenuGroupVisible(competitor, ctxFor(['arfolyam_nezo'], 'full'))).toBe(true)
  })

  it('FK-041/II: arfolyam_nezo (full): NEM látja a "Központ" csoportot (nincs a SZERVER_ROLES-ban)', () => {
    expect(isMenuGroupVisible(groupByLabel('Központ'), ctxFor(['arfolyam_nezo'], 'full'))).toBe(
      false,
    )
  })

  it('FK-041/II: arfolyam_nezo (full): NEM látja a "Főoldal" (Irányítópult) csoportot', () => {
    expect(isMenuGroupVisible(groupByLabel('Főoldal'), ctxFor(['arfolyam_nezo'], 'full'))).toBe(
      false,
    )
  })

  it('FK-041/II: arfolyam_nezo (full) KIZÁRÓLAG a "Versenytárs-árfolyam" csoportot látja — SEMMILYEN belső csoportot', () => {
    const ctx = ctxFor(['arfolyam_nezo'], 'full')
    const visibleLabels = menuGroups.filter((g) => isMenuGroupVisible(g, ctx)).map((g) => g.label)
    expect(visibleLabels).toEqual(['Versenytárs-árfolyam'])
  })

  it('FK-041/II regresszió: a foertektar TOVÁBBRA is látja a "Központ" és "Főoldal" csoportot', () => {
    const ctx = ctxFor(['foertektar'], 'full')
    expect(isMenuGroupVisible(groupByLabel('Központ'), ctx)).toBe(true)
    expect(isMenuGroupVisible(groupByLabel('Főoldal'), ctx)).toBe(true)
  })

  it('FK-041/II: foertektar (full): a belső "Árfolyamok (nézet)" csoportot továbbra is látja', () => {
    const rates = groupByLabel('Árfolyamok (nézet)')
    expect(isMenuGroupVisible(rates, ctxFor(['foertektar'], 'full'))).toBe(true)
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
    expect(
      isMenuItemVisible(itemByPath(admin, '/workers'), admin, ctxFor(['ugyvezeto'], 'full')),
    ).toBe(true)
  })

  it('penztar (full): semmilyen felügyeleti csoportot nem lát', () => {
    const admin = groupByLabel('Adminisztráció')
    const aml = groupByLabel('AML / Compliance')
    // 'penztar' a VALÓS kanonikus pénztáros szerepkör (PENZTAR_ROLES), nem 'penztaros'.
    expect(isMenuGroupVisible(admin, ctxFor(['penztar'], 'full'))).toBe(false)
    expect(isMenuGroupVisible(aml, ctxFor(['penztar'], 'full'))).toBe(false)
  })

  // FK-049: az "Átlag árfolyam" menüpont saját canonicalRoles-a [foertektar, ugyvezeto, belso_ellenor].
  it('FK-049: irodavezeto (full) NEM látja az "Átlag árfolyam" itemet, a többi Riportok-itemet igen', () => {
    const riportok = groupByLabel('Riportok')
    const ctx = ctxFor(['irodavezeto'], 'full')
    expect(isMenuItemVisible(itemByPath(riportok, '/reports/average-rate'), riportok, ctx)).toBe(
      false,
    )
    // egy örökölt (item-szintű roles nélküli) Riportok-item viszont látszik neki (csoport örökli)
    expect(isMenuItemVisible(itemByPath(riportok, '/reports'), riportok, ctx)).toBe(true)
  })

  it('FK-049: foertektar / ugyvezeto / belso_ellenor (full) LÁTJA az "Átlag árfolyam" itemet', () => {
    const riportok = groupByLabel('Riportok')
    for (const role of ['foertektar', 'ugyvezeto', 'belso_ellenor']) {
      const ctx = ctxFor([role], 'full')
      expect(
        isMenuItemVisible(itemByPath(riportok, '/reports/average-rate'), riportok, ctx),
        `nem látja: ${role}`,
      ).toBe(true)
    }
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

describe('ELLENŐRZÉS — pénztár/értéktár (lokál) modul menüi megfelelően elérhetők', () => {
  // A central admin szigorítás (PR #1059) NEM érintheti a lokál operatív menük elérhetőségét.
  // Ez a blokk garantálja, hogy a lokál módban az operatív szerepkör a SAJÁT teljes menüjét látja,
  // és hogy egyetlen lokál operatív route sincs a central RoleGate-tel szűkített admin-route-ok közt.

  const LOCAL_CASES: Array<{
    mode: MenuVisibilityContext['appMode']
    role: string
    groupLabel: string
  }> = [
    { mode: 'penztar', role: 'penztar', groupLabel: 'Pénztár (Valutaváltó)' },
    { mode: 'ertektar', role: 'ertektar', groupLabel: 'Értéktár (lokál)' },
    { mode: 'ertekszallito', role: 'ertekszallito', groupLabel: 'Értékszállító' },
    { mode: 'rate-maker', role: 'foertektar', groupLabel: 'Árfolyamkészítés' },
  ]

  for (const { mode, role, groupLabel } of LOCAL_CASES) {
    it(`${mode} mód / ${role}: a "${groupLabel}" csoport ÉS minden itemje látható`, () => {
      const group = groupByLabel(groupLabel)
      const ctx = ctxFor([role], mode)
      expect(isMenuGroupVisible(group, ctx), `csoport rejtve: ${groupLabel}`).toBe(true)
      for (const item of group.items) {
        expect(isMenuItemVisible(item, group, ctx), `item rejtve: ${item.path}`).toBe(true)
      }
    })
  }

  it('egyetlen lokál operatív route sincs a central MenuRoleGate-tel szűkített admin-route-ok közt', () => {
    // A central admin-route-ok (App.tsx MenuRoleGate) — ezek operatív userre redirectelnének.
    // (A /workers SZÁNDÉKOSAN nincs köztük: a backend SecurityConfig HTTP-matchere védi — Codex #1059.)
    // Megj. (Batch2-B 2026-06-12): a /handling-fee-config SZÁNDÉKOSAN nincs már a listában —
    // kettős listázású route lett (Adminisztráció + Pénztár-csoport), a route-gate uniója
    // (effectiveCanonicalRolesForPath) a pénztárost is átengedi (read-only nézet, a PUT
    // szerver-oldalon vezetői jog marad).
    const gatedAdminPaths = new Set([
      '/employees',
      '/attendance',
      '/licenses',
      '/settings',
      '/settings/permission-matrix',
      '/scheduler',
      '/email-settings',
      '/audit-log',
      '/admin/error-monitor',
      '/admin/audit-diagnostics',
      '/sanction',
      '/compliance',
      '/police-requests',
      '/seal-tracking',
      '/admin/branches',
    ])
    const localModes = new Set(['penztar', 'ertektar', 'ertekszallito', 'rate-maker'])
    const localItemPaths = new Set<string>()
    for (const group of menuGroups) {
      if (!group.modes || !group.modes.some((m) => localModes.has(m))) continue
      for (const item of group.items) localItemPaths.add(item.path)
    }
    for (const p of localItemPaths) {
      expect(gatedAdminPaths.has(p), `lokál operatív route tévesen admin-gatelt: ${p}`).toBe(false)
    }
  })
})

describe('effectiveCanonicalRolesForPath — single source of truth a RoleGate-hez', () => {
  it('/admin/branches → item-szintű [foertektar, belso_ellenor, ugyvezeto]', () => {
    expect(
      [...(effectiveCanonicalRolesForPath(menuGroups, '/admin/branches') ?? [])].sort(),
    ).toEqual(['belso_ellenor', 'foertektar', 'ugyvezeto'])
  })

  it('/workers → örökölt Adminisztráció-csoport [ugyvezeto, irodavezeto, irodai_dolgozo]', () => {
    expect([...(effectiveCanonicalRolesForPath(menuGroups, '/workers') ?? [])].sort()).toEqual([
      'irodai_dolgozo',
      'irodavezeto',
      'ugyvezeto',
    ])
  })

  it('/settings → item-szintű [ugyvezeto]', () => {
    expect(effectiveCanonicalRolesForPath(menuGroups, '/settings')).toEqual(['ugyvezeto'])
  })

  it('ismeretlen útvonal → undefined', () => {
    expect(effectiveCanonicalRolesForPath(menuGroups, '/nincs-ilyen')).toBeUndefined()
  })

  // FK-049: az "Átlag árfolyam" menüpont saját canonicalRoles-t kapott, felülírva a Riportok
  // csoport örökölt listáját. A route-gate (effectiveCanonicalRolesForPath) ugyanezt tükrözi.
  it('FK-049: /reports/average-rate → item-szintű [belso_ellenor, foertektar, ugyvezeto]', () => {
    expect(
      [...(effectiveCanonicalRolesForPath(menuGroups, '/reports/average-rate') ?? [])].sort(),
    ).toEqual(['belso_ellenor', 'foertektar', 'ugyvezeto'])
  })

  it('FK-028: /mnb-settlement-rates → item-szintű [belso_ellenor, foertektar, ugyvezeto]', () => {
    expect(
      [...(effectiveCanonicalRolesForPath(menuGroups, '/mnb-settlement-rates') ?? [])].sort(),
    ).toEqual(['belso_ellenor', 'foertektar', 'ugyvezeto'])
  })

  // Fail-safe: a MenuRoleGate fail-open, ha az útvonalnak nincs menü-szerepköre. Ez a teszt
  // garantálja, hogy MINDEN App.tsx-ben MenuRoleGate-tel védett admin-route-nak van definiált
  // (nem undefined, nem üres) szerepkör-megszorítása — különben a route csendben védtelen lenne.
  it('minden MenuRoleGate-tel védett admin-route-nak van nem-üres menü-szerepköre', () => {
    const gatedPaths = [
      '/employees',
      '/attendance',
      '/licenses',
      '/settings',
      '/settings/permission-matrix',
      '/scheduler',
      '/email-settings',
      '/handling-fee-config',
      '/audit-log',
      '/admin/error-monitor',
      '/admin/audit-diagnostics',
      '/sanction',
      '/compliance',
      '/police-requests',
      '/seal-tracking',
      '/admin/branches',
      '/mnb-settlement-rates',
    ]
    for (const path of gatedPaths) {
      const roles = effectiveCanonicalRolesForPath(menuGroups, path)
      expect(roles, `hiányzó menü-szerepkör: ${path}`).toBeDefined()
      expect((roles ?? []).length, `üres szerepkör-lista: ${path}`).toBeGreaterThan(0)
    }
  })
})
