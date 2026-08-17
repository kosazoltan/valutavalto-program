import { describe, expect, it } from 'vitest'
import { getDefaultRouteForRoles, menuGroups } from './menuGroups'
import {
  effectiveCanonicalRolesForPath,
  isMenuGroupVisible,
  isMenuItemVisible,
} from './menuVisibility'
import type { MenuVisibilityContext } from './menuVisibility'
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

describe('menuGroups ertekszallito role', () => {
  it('penztar modban a courier atadas-atveteli menuje elerheto', () => {
    const labels = visibleMenuLabels('penztar')
    expect(labels).toContain('Átadás-átvétel visszaigazolás (aláírás)')
  })

  it('ertektar modban a courier atadas-atveteli menuje elerheto', () => {
    const labels = visibleMenuLabels('ertektar')
    expect(labels).toContain('Átadás-átvétel visszaigazolás (aláírás)')
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

describe('transfers menü-szétválasztás (2026-07-14)', () => {
  it('nincs többé egybemosott "Átadás-átvétel aláírás" bejegyzés', () => {
    const all = menuGroups.flatMap((g) => g.items)
    expect(all.filter((i) => i.label === 'Átadás-átvétel aláírás')).toHaveLength(0)
  })

  it('a /transfers a visszaigazolás címkét viseli a Pénztár ÉS az Értéktár csoportban', () => {
    const entries = menuGroups.flatMap((g) => g.items).filter((i) => i.path === '/transfers')
    expect(entries).toHaveLength(2)
    for (const e of entries) expect(e.label).toBe('Átadás-átvétel visszaigazolás (aláírás)')
  })

  it('a /transfers/new a létrehozás címkét viseli mindkét csoportban — futár (ertekszallito) NÉLKÜL (user-döntés 2026-07-14: a futár tiszta dokumentáció, nincs create-jog)', () => {
    const entries = menuGroups.flatMap((g) => g.items).filter((i) => i.path === '/transfers/new')
    expect(entries).toHaveLength(2)
    for (const e of entries) expect(e.label).toBe('Új átadás-átvétel rögzítése')
    expect(entries.map((e) => [...(e.canonicalRoles ?? [])].sort())).toEqual(
      expect.arrayContaining([['penztar'], ['ertektar']]),
    )
  })

  it('ertekszallito SEMMILYEN menü-route canonicalRoles-ában nem szerepel (2026-07-14)', () => {
    const offenders = menuGroups.flatMap((g) =>
      g.items.filter((i) => (i.canonicalRoles ?? []).includes('ertekszallito')),
    )
    expect(offenders.map((i) => i.path)).toEqual([])
  })
})

// ─────────────────────────────────────────────────────────────────────────────
// FKH-026 — Menürendszer egyszerűsítése (RED-fázis, 2026-07-30; v3-ra frissítve
// a 2. körben — dokumentált spec-változás: fejlesztesi-keres-...-v2.md, v3 tartalom).
//
// A tesztek az ELVÁRT (még nem implementált) menü-állapotot rögzítik, ezért az
// elrejtés-tesztek a jelenlegi kód ellenében szándékosan buknak. Implementáció-
// agnosztikusak: a VALÓS láthatósági logikán (isMenuGroupVisible/isMenuItemVisible)
// keresztül nézik a menüt, így bejegyzés-törlés ÉS szűrés-alapú elrejtés esetén
// is helyesen ítélnek.
//
// v3 (TBD-3 + kritikai review 1. kör): a Főértéktáros(-helyettes) a meglévő
// SZERVER_ROLES bypass (menuVisibility.ts:50) révén VÁLTOZATLANUL lát mindent —
// az 1. körös foertektar-elrejtés variánsok ŐR-tesztekké fordultak (ma is
// zöldek), amelyek kizárják a naiv teljes-törlés implementációt (FK v3 §9.2 F1:
// "explicit tesztben is rögzíteni, ne csak a bypass-ra hagyatkozva").
//
// "Helyettes" szerepkörök: a frontend menü-rétegben NINCS külön helyettes
// role-kód — az Értéktáros/Főértéktáros helyettes ugyanazzal a kanonikus
// ('ertektar'/'foertektar') szerepkörrel fut, így a tesztek ezt fedik le.
// ─────────────────────────────────────────────────────────────────────────────
function fkh026VisibleItemLabels(appMode: AppMode, canonicalRoles: readonly string[]): string[] {
  const ctx: MenuVisibilityContext = {
    appMode,
    hasCanonicalRole: (role) => canonicalRoles.includes(role),
    hasRole: () => false,
    featureFlags: {},
  }
  return menuGroups
    .filter((group) => isMenuGroupVisible(group, ctx))
    .flatMap((group) =>
      group.items.filter((item) => isMenuItemVisible(item, group, ctx)).map((item) => item.label),
    )
}

describe('FKH-026 v3 — menü-egyszerűsítés az érintett szerepköröknél (FR-1, FR-2, FR-3, FR-5, FR-6)', () => {
  it('FR-1: ertektar módban (ertektar szerepkör, helyettesre is érvényes) az "Irodaközi trade" NEM jelenik meg', () => {
    expect(fkh026VisibleItemLabels('ertektar', ['ertektar'])).not.toContain('Irodaközi trade')
  })

  it('FR-2: penztar módban az "Irodaközi trade" VÁLTOZATLANUL megjelenik', () => {
    expect(fkh026VisibleItemLabels('penztar', ['penztar'])).toContain('Irodaközi trade')
  })

  it.each([
    ['penztar', 'penztar'],
    ['ertektar', 'ertektar'],
  ])('FR-3: %s módban (%s szerepkör) az "Úton lévő csomagok" NEM jelenik meg', (mode, role) => {
    expect(fkh026VisibleItemLabels(mode as AppMode, [role])).not.toContain('Úton lévő csomagok')
  })

  it('FR-5: ertektar módban (ertektar szerepkör) a "Szállítólevelek" NEM jelenik meg', () => {
    expect(fkh026VisibleItemLabels('ertektar', ['ertektar'])).not.toContain('Szállítólevelek')
  })

  it.each([
    ['penztar', 'penztar'],
    ['ertektar', 'ertektar'],
  ])(
    'FR-6: %s módban (%s szerepkör) az "Új átadás-átvétel rögzítése" önálló menüpontként NEM jelenik meg',
    (mode, role) => {
      expect(fkh026VisibleItemLabels(mode as AppMode, [role])).not.toContain(
        'Új átadás-átvétel rögzítése',
      )
    },
  )
})

describe('FKH-026 v3 — Főértéktáros(-helyettes) kivétel: a 4 érintett menüpont VÁLTOZATLANUL látszik (őr, ma is zöld)', () => {
  // FK v3 §3 + §8: a SZERVER_ROLES bypass (menuVisibility.ts:50) szándékosan marad.
  // Ezek a tesztek MA IS zöldek; céljuk, hogy a GREEN-fázisban kizárják a naiv
  // teljes-törlés implementációt (annál a foertektar sem látná a bejegyzéseket).
  it.each([
    ['ertektar', 'Irodaközi trade'],
    ['ertektar', 'Úton lévő csomagok'],
    ['ertektar', 'Szállítólevelek'],
    ['ertektar', 'Új átadás-átvétel rögzítése'],
    ['penztar', 'Irodaközi trade'],
    ['penztar', 'Úton lévő csomagok'],
    ['penztar', 'Új átadás-átvétel rögzítése'],
    // "Szállítólevelek" penztar módban eddig sem volt (FK §3: "– (eddig sem volt)").
  ])('FR-kiegészítés: %s módban a foertektar látja: "%s"', (mode, label) => {
    expect(fkh026VisibleItemLabels(mode as AppMode, ['foertektar'])).toContain(label)
  })
})

describe('FKH-026 — NFR-1 regresszió-őr: a nem érintett menüpontok változatlan sorrendben', () => {
  // A várt listák a Fázis 0-ban felderített TÉNYLEGES menüGroups-ból származnak
  // (nem az FK példálózó felsorolásából — "Készlet Mátrix"/"Mozgások"/"Jelentések"
  // nevű menüpont NEM létezik), a 4 érintett bejegyzés elhagyásával, sorrendtartóan.
  it('NFR-1: penztar módban PONTOSAN a nem érintett menüpontok maradnak, változatlan sorrendben', () => {
    expect(fkh026VisibleItemLabels('penztar', ['penztar'])).toEqual([
      'Pénztáros főmenü',
      'Napnyitás',
      'Valuta vétel / eladás',
      'Konverzió',
      'Irodaközi trade',
      'Kassza / készlet',
      'Címletezés – zárások',
      'Címletképek (valuta)',
      'Ügyfelek',
      'Átadás-átvétel visszaigazolás (aláírás)',
      'Napzárás',
      'Árfolyamok (nézet)',
      'Tranzakciólista',
      'Egyéb feladatok',
      'Kezelési költség beállítások',
    ])
  })

  it('NFR-1: ertektar módban PONTOSAN a nem érintett menüpontok maradnak, változatlan sorrendben', () => {
    expect(fkh026VisibleItemLabels('ertektar', ['ertektar'])).toEqual([
      'Értéktári dashboard',
      'Átadás-átvétel',
      'Átadás-átvétel visszaigazolás (aláírás)',
      'Értéktári készlet',
      'Pénztári készletek',
      'Új pénztár felrögzítése',
      'Új munkatárs felvétele',
      'Naplókönyv',
      // FKH-030 FR-1: uj menupont a Naplokonyv mellett (Penzforgalom riport).
      'Pénzforgalom riport',
      'Napi zárás',
      // FKH-036 FR-9: a „Napzárás” bejegyzés rejtett lett az értéktáros elől
      // (hidden: true) — ezért a látható listából kikerül; a foertektar-bypass
      // lista (lent) VÁLTOZATLANUL tartalmazza.
      'Havi zárás',
      'Ügyfelek',
      'Árfolyamok (nézet)',
    ])
  })

  // v3: a foertektar(-helyettes) TELJES listája változatlan — a 4 érintett
  // bejegyzés a "változatlan" oldalon szerepel (ma is zöld őr-tesztek).
  it('NFR-1 (v3, foertektar): penztar módban a TELJES lista változatlan, sorrendtartóan', () => {
    expect(fkh026VisibleItemLabels('penztar', ['foertektar'])).toEqual([
      'Pénztáros főmenü',
      'Napnyitás',
      'Valuta vétel / eladás',
      'Konverzió',
      'Irodaközi trade',
      'Kassza / készlet',
      'Címletezés – zárások',
      'Címletképek (valuta)',
      'Ügyfelek',
      'Úton lévő csomagok',
      'Átadás-átvétel visszaigazolás (aláírás)',
      'Új átadás-átvétel rögzítése',
      'Napzárás',
      'Árfolyamok (nézet)',
      'Tranzakciólista',
      'Egyéb feladatok',
      'Kezelési költség beállítások',
    ])
  })

  it('NFR-1 (v3, foertektar): ertektar módban a TELJES lista változatlan, sorrendtartóan', () => {
    expect(fkh026VisibleItemLabels('ertektar', ['foertektar'])).toEqual([
      'Értéktári dashboard',
      'Átadás-átvétel',
      'Irodaközi trade',
      'Átadás-átvétel visszaigazolás (aláírás)',
      'Új átadás-átvétel rögzítése',
      'Szállítólevelek',
      'Úton lévő csomagok',
      'Értéktári készlet',
      'Pénztári készletek',
      'Új pénztár felrögzítése',
      'Új munkatárs felvétele',
      'Naplókönyv',
      // FKH-030 FR-1: uj menupont a Naplokonyv mellett (Penzforgalom riport).
      'Pénzforgalom riport',
      'Napi zárás',
      'Napzárás',
      'Havi zárás',
      'Ügyfelek',
      'Árfolyamok (nézet)',
    ])
  })
})

describe('FKH-030 FR-1 — Pénzforgalom riport a Riportok menücsoportban', () => {
  it('FR-1: a Riportok csoport tartalmazza a „Pénzforgalom riport” menüpontot', () => {
    const reports = menuGroups.find((g) => g.label === 'Riportok')
    expect(reports).toBeDefined()
    expect(reports!.items.map((i) => i.path)).toContain('/reports/cash-flow')
  })

  it('FR-1: az oversight-szerepkörök a menüből is elérik (a backend RBAC-kal összhangban)', () => {
    // A CashFlowReportController @PreAuthorize ezeket engedélyezi — korábban az „Értéktár
    // (lokál)” csoportba zárva a menüből egyikük sem érte el a riportot.
    for (const role of [
      'irodavezeto',
      'belso_ellenor',
      'teruleti_vezeto',
      'penzugyi_vezeto',
      'ugyvezeto',
      'foertektar',
    ]) {
      expect(fkh026VisibleItemLabels('full', [role])).toContain('Pénzforgalom riport')
    }
  })

  it('FR-1: az értéktári elérés változatlanul megmarad (nem áthelyezés, hanem kiterjesztés)', () => {
    expect(fkh026VisibleItemLabels('ertektar', ['ertektar'])).toContain('Pénzforgalom riport')
  })

  it('jogosulatlan szerepkör (penztaros) továbbra sem látja', () => {
    expect(fkh026VisibleItemLabels('full', ['penztaros'])).not.toContain('Pénzforgalom riport')
  })
})

describe('FKH-036 FR-9/FR-10 — „Napzárás” rejtése az Értéktár-csoportban', () => {
  it('FR-9: ertektar módban az értéktáros NEM látja a "Napzárás" bejegyzést', () => {
    expect(fkh026VisibleItemLabels('ertektar', ['ertektar'])).not.toContain('Napzárás')
  })

  it('FR-9 őr: a foertektar bypass VÁLTOZATLANUL látja', () => {
    expect(fkh026VisibleItemLabels('ertektar', ['foertektar'])).toContain('Napzárás')
  })

  it('FR-10 őr: penztar módban a "Napzárás" VÁLTOZATLANUL látszik', () => {
    expect(fkh026VisibleItemLabels('penztar', ['penztar'])).toContain('Napzárás')
  })

  it('FR-10 őr: a /closing/wizard route-gate szerepkör-uniója változatlan', () => {
    // A bejegyzés MINDKÉT csoportban korlátlan item-szinten, de a csoportszintű
    // canonicalRoles (PENZTAR_ROLES / ERTEKTAR_ROLES) érvényesül — az unió
    // változatlansága bizonyítja, hogy a route-hozzáférés nem módosult.
    // (PLAN GAP: a terv undefined-et várt "korlátlan bejegyzések" indokkal; a
    // valós csoportszintű szerepkörök miatt a függvény az uniót adja — a lényeg
    // a változatlanság, amit ez a pin rögzít.)
    expect([...(effectiveCanonicalRolesForPath(menuGroups, '/closing/wizard') ?? [])].sort()).toEqual(
      ['ertektar', 'penztar'],
    )
  })
})
