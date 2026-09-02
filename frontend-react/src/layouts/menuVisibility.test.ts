/**
 * RBAC-audit (2026-06-05) — menü-láthatóság szigorú modell tesztjei a VALÓDI menuGroups ellen.
 * Fedi: full-módú least-privilege, lokál oversight-bypass, item-öröklés, csoport-ha-van-látható-item,
 * és az effectiveCanonicalRolesForPath single-source-of-truth leképzést.
 */
import { describe, it, expect, vi } from 'vitest'
import { menuGroups, type MenuGroup } from './menuGroups'
import {
  isMenuItemVisible,
  isMenuGroupVisible,
  effectiveCanonicalRolesForPath,
  resolveVisibleMenuGroups,
  type MenuVisibilityContext,
} from './menuVisibility'

vi.mock('../services/api/index', () => ({
  persistToken: vi.fn().mockResolvedValue(undefined),
  clearPersistedToken: vi.fn().mockResolvedValue(undefined),
}))

import { useAuthStore, type Worker } from '../stores/authStore'

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
  it('FK-061 → FKH-036 FR-9: a "Napzárás" (/closing/wizard) bejegyzés MEGMARAD az Értéktár csoportban, de az értéktáros elől rejtett', () => {
    // FKH-036 FR-9 felülírja az FK-061 "látható" kikötését: a bejegyzés törlés
    // HELYETT hidden: true lett (FKH-026 v3 precedens) — a route-gate uniója és a
    // felügyeleti bypass változatlan. A jelenlét- és címke-assertok változatlanok;
    // a láthatóság-assert az új szerződés szerint fordított.
    const ctx = ctxFor(['ertektar'], 'ertektar')
    const group = groupByLabel('Értéktár (lokál)')
    const item = itemByPath(group, '/closing/wizard')
    expect(item).toBeDefined()
    expect(item.label).toBe('Napzárás')
    expect(isMenuItemVisible(item, group, ctx)).toBe(false)
    // Őr: a felügyeleti bypass (SZERVER_ROLES) továbbra is látja (menuVisibility.ts:50).
    expect(isMenuItemVisible(item, group, ctxFor(['foertektar'], 'ertektar'))).toBe(true)
  })

  it('FK-061 paritás: a "Napzárás" (/closing/wizard) a Pénztár és az Értéktár csoportban is szerepel', () => {
    const penztar = groupByLabel('Pénztár (Valutaváltó)')
    const ertektar = groupByLabel('Értéktár (lokál)')
    expect(itemByPath(penztar, '/closing/wizard')).toBeDefined()
    expect(itemByPath(ertektar, '/closing/wizard')).toBeDefined()
  })

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
    { mode: 'rate-maker', role: 'foertektar', groupLabel: 'Árfolyamkészítés' },
  ]

  // FKH-026 v3 (jóváhagyott spec-változás, GREEN-fázis 2026-07-30): a lokál operatív
  // menü teljes láthatósága alól kivétel a `hidden: true` bejegyzés-készlet
  // (FR-1/FR-3/FR-5/FR-6) — ezek szándékosan rejtettek az operatív szerepkör elől
  // (a felügyeleti bypass továbbra is látja őket, ld. menuGroups.test.ts FKH-026
  // őr-tesztjei). A söprés a NEM-rejtett itemekre fut, a rejtett készletet pedig
  // csoportonként PONTOSAN pineljük, hogy a kivétel ne tágulhasson csendben.
  const FKH026_HIDDEN_PATHS: Record<string, string[]> = {
    'Pénztár (Valutaváltó)': ['/transit', '/transfers/new'],
    // FKH-036 FR-9: a /closing/wizard az Értéktár-csoportban is rejtett lett —
    // az item-sorrend szerinti utolsó rejtett bejegyzés.
    'Értéktár (lokál)': [
      '/trades',
      '/transfers/new',
      '/transfer-documents',
      '/transit',
      '/closing/wizard',
    ],
    Árfolyamkészítés: [],
  }

  for (const { mode, role, groupLabel } of LOCAL_CASES) {
    it(`${mode} mód / ${role}: a "${groupLabel}" csoport ÉS minden nem-rejtett itemje látható`, () => {
      const group = groupByLabel(groupLabel)
      const ctx = ctxFor([role], mode)
      expect(isMenuGroupVisible(group, ctx), `csoport rejtve: ${groupLabel}`).toBe(true)
      expect(
        group.items.filter((i) => i.hidden).map((i) => i.path),
        `FKH-026 rejtett készlet eltér: ${groupLabel}`,
      ).toEqual(FKH026_HIDDEN_PATHS[groupLabel])
      for (const item of group.items.filter((i) => !i.hidden)) {
        expect(isMenuItemVisible(item, group, ctx), `item rejtve: ${item.path}`).toBe(true)
      }
    })
  }

  // SPEC-CHANGE 2026-07-14 (user-döntés): a futár tiszta dokumentáció — nincs login, nincs menü.
  // A korábbi teszt a courier menü-LÁTHATÓSÁGÁT pinelte; az új kontraktus a láthatatlanság.
  it('courier-only dolgozó penztar módban SEMMILYEN menücsoportot nem lát', () => {
    const ctx = ctxFor(['ertekszallito'], 'penztar')
    const visible = menuGroups.filter((g) => isMenuGroupVisible(g, ctx)).map((g) => g.label)
    expect(visible).toEqual([])
  })

  it('courier-only dolgozó ertektar módban SEMMILYEN menücsoportot nem lát', () => {
    const ctx = ctxFor(['ertekszallito'], 'ertektar')
    const visible = menuGroups.filter((g) => isMenuGroupVisible(g, ctx)).map((g) => g.label)
    expect(visible).toEqual([])
  })

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
    const localModes = new Set(['penztar', 'ertektar', 'rate-maker'])
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

  it('/transfers → a Pénztár és Értéktár bejegyzések szerepkör-uniója', () => {
    // SPEC-CHANGE 2026-07-14: az ertekszallito kikerült a menü-RBAC-ból.
    expect([...(effectiveCanonicalRolesForPath(menuGroups, '/transfers') ?? [])].sort()).toEqual([
      'ertektar',
      'penztar',
    ])
  })

  it('/transfers/new → a Pénztár és Értéktár bejegyzések szerepkör-uniója', () => {
    // SPEC-CHANGE 2026-07-14: az ertekszallito kikerült a menü-RBAC-ból.
    expect(
      [...(effectiveCanonicalRolesForPath(menuGroups, '/transfers/new') ?? [])].sort(),
    ).toEqual(['ertektar', 'penztar'])
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

describe('FS11-MENU-ROLE-MISMATCH — menü ⊆ backend compliance role-halmaz (pin)', () => {
  it('az AML/Compliance csoport canonicalRoles-a pontosan a backend-engedett canonical trió', () => {
    // Backend-oldali pár: Compliance*Controller + SuspiciousCustomerController
    // hasAnyRole(...,'BELSO_ELLENOR','BIZTONSAGI_VEZETO','UGYVEZETO').
    // Ha a backend-halmaz szűkül, ezt a pint és a menüt EGYÜTT kell módosítani.
    const aml = groupByLabel('AML / Compliance')
    expect([...(aml.canonicalRoles ?? [])].sort()).toEqual([
      'belso_ellenor',
      'biztonsagi_vezeto',
      'ugyvezeto',
    ])
  })
})

describe('MENU-LEGACY-ROLE-INVISIBLE: legacy-orphan MANAGER a VALODI authStore-on at (full mod)', () => {
  const legacyWorker: Worker = {
    id: 99,
    workerCode: 'W099',
    firstName: 'Legacy',
    lastName: 'Manager',
    fullName: 'Legacy Manager',
    role: 'MANAGER',
    branchId: 'b1',
    branchCode: '001',
    branchName: 'Pécs',
    companyId: 'c1',
    companyCode: 'EBC',
    companyName: 'EBC Zrt.',
  }

  const storeCtx = (appMode: MenuVisibilityContext['appMode']): MenuVisibilityContext => {
    const s = useAuthStore.getState()
    return {
      appMode,
      hasCanonicalRole: (r: string) => s.hasCanonicalRole(r),
      hasRole: (r: string) => s.hasRole(r),
      featureFlags: {},
    }
  }

  it('orphan MANAGER (0 canonical assignment): LATJA az "AML / Compliance" csoportot full modban', () => {
    useAuthStore.getState().login(legacyWorker, 'tok', 'Bearer', '', null, [], [])
    const aml = groupByLabel('AML / Compliance')
    expect(isMenuGroupVisible(aml, storeCtx('full'))).toBe(true)
    expect(isMenuItemVisible(itemByPath(aml, '/admin/error-monitor'), aml, storeCtx('full'))).toBe(
      true,
    )
    expect(isMenuItemVisible(itemByPath(aml, '/compliance'), aml, storeCtx('full'))).toBe(true)
    useAuthStore.getState().logout()
  })

  it('regresszio: canonical assignmentes (foertektar primary) worker AML-lathatosaga VALTOZATLAN (false)', () => {
    useAuthStore
      .getState()
      .login(
        { ...legacyWorker, role: 'MANAGER' },
        'tok',
        'Bearer',
        '',
        'foertektar',
        [],
        ['foertektar'],
      )
    const aml = groupByLabel('AML / Compliance')
    expect(isMenuGroupVisible(aml, storeCtx('full'))).toBe(false)
    expect(isMenuGroupVisible(groupByLabel('Központ'), storeCtx('full'))).toBe(true)
    useAuthStore.getState().logout()
  })
})

describe('FK-086 — teruleti_vezeto nem látja a /daily-check menüpontot', () => {
  // Fontos: full mód — nem-full módban a felügyeleti bypass (SZERVER_ROLES)
  // láthatóvá tenné az itemet, ami hamis pozitív lenne (menuVisibility.ts:31-33).
  it('teruleti_vezeto (full): SEMELYIK csoportban nem látja a /daily-check itemet', () => {
    const ctx = ctxFor(['teruleti_vezeto'], 'full')
    const visible = menuGroups.flatMap((g) =>
      g.items.filter((i) => i.path === '/daily-check' && isMenuItemVisible(i, g, ctx)),
    )
    expect(visible).toEqual([])
  })

  it('foertektar / ugyvezeto / belso_ellenor (full): látja a /daily-check itemet a Központ csoportban', () => {
    for (const role of ['foertektar', 'ugyvezeto', 'belso_ellenor']) {
      const kozpont = groupByLabel('Központ')
      expect(
        isMenuItemVisible(itemByPath(kozpont, '/daily-check'), kozpont, ctxFor([role], 'full')),
      ).toBe(true)
    }
  })
})

describe('menuVisibility — FK-096 FR-12: kezelési díj konfiguráció RBAC-szűkítése', () => {
  it('irodavezeto full modban nem latja a /handling-fee-config bejegyzest (strict least-privilege)', () => {
    const ctx = ctxFor(['irodavezeto'], 'full')
    const visible = menuGroups.flatMap((g) =>
      g.items.filter((i) => i.path === '/handling-fee-config' && isMenuItemVisible(i, g, ctx)),
    )
    expect(visible, 'irodavezeto full modban nem lathatja').toEqual([])
  })

  it('belso_ellenor full modban nem latja a /handling-fee-config bejegyzest (strict least-privilege)', () => {
    const ctx = ctxFor(['belso_ellenor'], 'full')
    const visible = menuGroups.flatMap((g) =>
      g.items.filter((i) => i.path === '/handling-fee-config' && isMenuItemVisible(i, g, ctx)),
    )
    expect(visible, 'belso_ellenor full modban nem lathatja').toEqual([])
  })

  it('penztar modban a felugyeleti (SZERVER_ROLES) irodavezeto az oversight-bypass miatt latja (szandekos)', () => {
    // Or: a lokal kliensek felugyeleti userei SZANDÉKOSAN latjak a teljes menut
    // (isSupervisoryMenuBypass, menuVisibility.ts) — a route-gate viszont bypass NELKUL,
    // szigoruan ervenyesul, igy a config-kepernyo hozzaferese tovabbra is tiltott (FR-12).
    const ctx = ctxFor(['irodavezeto'], 'penztar')
    const visible = menuGroups.flatMap((g) =>
      g.items.filter((i) => i.path === '/handling-fee-config' && isMenuItemVisible(i, g, ctx)),
    )
    expect(visible.length).toBeGreaterThan(0)
  })

  it('foertektar full modban latja a /handling-fee-config bejegyzest', () => {
    const ctx = ctxFor(['foertektar'], 'full')
    const visible = menuGroups.flatMap((g) =>
      g.items.filter((i) => i.path === '/handling-fee-config' && isMenuItemVisible(i, g, ctx)),
    )
    expect(visible.length).toBeGreaterThan(0)
  })

  it('penztar modban a penztaros read-only kartya miatt tovabbra is latja a bejegyzest', () => {
    const ctx = ctxFor(['penztar'], 'penztar')
    const visible = menuGroups.flatMap((g) =>
      g.items.filter((i) => i.path === '/handling-fee-config' && isMenuItemVisible(i, g, ctx)),
    )
    expect(visible.length).toBeGreaterThan(0)
  })

  it('a route-gate unioja (effectiveCanonicalRolesForPath) sem engedi at az irodavezetot', () => {
    const roles = effectiveCanonicalRolesForPath(menuGroups, '/handling-fee-config')
    expect(roles).toBeDefined()
    expect(roles).not.toContain('irodavezeto')
    expect(roles).not.toContain('belso_ellenor')
    expect(roles).toContain('ugyvezeto')
    expect(roles).toContain('foertektar')
    // Pénztáros read-only nézet: a penztar mód továbbra is átenged (pitfall #14).
    expect(roles).toContain('penztar')
  })
})

describe('menuVisibility — FK-099: tranzakciós illeték riport + ráta-beállítások RBAC', () => {
  // F12: irodavezeto a riportot látja (az item canonicalRoles-ban van), de a
  // ráta-beállításokat NEM (szándékosan nincs a listában).
  it('FK-099/F12: irodavezeto (full) látja a riport-itemet, NEM látja a ráta-itemet', () => {
    const riportok = groupByLabel('Riportok')
    const ctx = ctxFor(['irodavezeto'], 'full')
    expect(
      isMenuItemVisible(itemByPath(riportok, '/reports/transaction-levy'), riportok, ctx),
    ).toBe(true)
    expect(
      isMenuItemVisible(itemByPath(riportok, '/reports/transaction-levy-rates'), riportok, ctx),
    ).toBe(false)
  })

  // F13: foertektar / ugyvezeto / belso_ellenor MINDKETTŐT látja.
  it('FK-099/F13: foertektar / ugyvezeto / belso_ellenor (full) MINDKÉT itemet látja', () => {
    const riportok = groupByLabel('Riportok')
    for (const role of ['foertektar', 'ugyvezeto', 'belso_ellenor']) {
      const ctx = ctxFor([role], 'full')
      expect(
        isMenuItemVisible(itemByPath(riportok, '/reports/transaction-levy'), riportok, ctx),
        `riport-item rejtve: ${role}`,
      ).toBe(true)
      expect(
        isMenuItemVisible(itemByPath(riportok, '/reports/transaction-levy-rates'), riportok, ctx),
        `rata-item rejtve: ${role}`,
      ).toBe(true)
    }
  })

  // F14: penztar(full módban a felügyeleti bypass nem él) egyiket sem látja, és a
  // route-gate uniója pontosan a három íráshoz is jogosult szerep.
  it('FK-099/F14: penztaros egyiket sem látja; a route-gate uniója [foertektar, ugyvezeto, belso_ellenor]', () => {
    const riportok = groupByLabel('Riportok')
    const ctx = ctxFor(['penztar'], 'full')
    expect(
      isMenuItemVisible(itemByPath(riportok, '/reports/transaction-levy'), riportok, ctx),
    ).toBe(false)
    expect(
      isMenuItemVisible(itemByPath(riportok, '/reports/transaction-levy-rates'), riportok, ctx),
    ).toBe(false)

    expect(
      [
        ...(effectiveCanonicalRolesForPath(menuGroups, '/reports/transaction-levy-rates') ?? []),
      ].sort(),
    ).toEqual(['belso_ellenor', 'foertektar', 'ugyvezeto'])
  })
})

describe('resolveVisibleMenuGroups — zero-visible-group fallback (kanban #8)', () => {
  // The authenticated BALI-like user (cashier + supervisor) sees the normal groups.
  it('penztar+foertektar roles, penztar mode -> no fallback, normal groups', () => {
    const ctx = ctxFor(['penztar', 'foertektar'], 'penztar')
    const resolved = resolveVisibleMenuGroups(menuGroups, ctx)
    expect(resolved.fallbackApplied).toBe(false)
    expect(resolved.groups.map((g) => g.label)).toContain('Pénztár (Valutaváltó)')
  })

  it('no roles at all, penztar mode -> fallback to the app-mode default group', () => {
    const ctx: MenuVisibilityContext = {
      appMode: 'penztar',
      hasCanonicalRole: () => false,
      hasRole: () => false,
      featureFlags: {},
    }
    const resolved = resolveVisibleMenuGroups(menuGroups, ctx)
    expect(resolved.fallbackApplied).toBe(true)
    expect(resolved.groups.map((g) => g.label)).toEqual(['Pénztár (Valutaváltó)'])
    const firstGroup = resolved.groups[0]
    expect(firstGroup).toBeDefined()
    expect(firstGroup?.items.length ?? 0).toBeGreaterThan(0)
  })

  it('no roles at all, ertektar mode -> fallback to the ertektar default group', () => {
    const ctx: MenuVisibilityContext = {
      appMode: 'ertektar',
      hasCanonicalRole: () => false,
      hasRole: () => false,
      featureFlags: {},
    }
    const resolved = resolveVisibleMenuGroups(menuGroups, ctx)
    expect(resolved.fallbackApplied).toBe(true)
    expect(resolved.groups.map((g) => g.label)).toEqual(['Értéktár (lokál)'])
  })

  it('no roles at all, full mode -> NO fallback (admin surface keeps least-privilege)', () => {
    const ctx: MenuVisibilityContext = {
      appMode: 'full',
      hasCanonicalRole: () => false,
      hasRole: () => false,
      featureFlags: {},
    }
    const resolved = resolveVisibleMenuGroups(menuGroups, ctx)
    expect(resolved.fallbackApplied).toBe(false)
    expect(resolved.groups.length).toBe(0)
  })
})
