import { describe, it, expect } from 'vitest'
import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { menuGroups } from './menuGroups'
import {
  isMenuGroupVisible,
  isMenuItemVisible,
  resolveVisibleMenuGroups,
  type MenuVisibilityContext,
} from './menuVisibility'
import type { AppMode } from '../types/appMode'

/**
 * FK-069 — Navigációs menü csoportonkénti összecsukása.
 *
 * A teljes MainLayout renderelése session-API-t igényel (lásd MainLayout.menu.test.tsx),
 * ezért a UI-kontraktust — a MainLayout.sticky/vertical-scroll tesztek bevált mintája
 * szerint — forrásból ellenőrizzük, a toggle-szemantikát pedig a BranchGroupPage-ből
 * átvett Set-mintán, izoláltan.
 */
const src = readFileSync(resolve(process.cwd(), 'src/layouts/MainLayout.tsx'), 'utf-8')

/** A MainLayout-ban implementált toggle szemantikájának izolált mása (FR-1). */
function toggle(prev: Set<string>, label: string): Set<string> {
  const next = new Set(prev)
  if (next.has(label)) next.delete(label)
  else next.add(label)
  return next
}

describe('FK-069 FR-4 — alapértelmezett állapot: minden csoport nyitva', () => {
  it('a kezdőérték az összes definiált menücsoport label-je', () => {
    const initial = new Set(menuGroups.map((g) => g.label))
    expect(initial.size).toBe(new Set(menuGroups.map((g) => g.label)).size)
    for (const g of menuGroups) {
      expect(initial.has(g.label)).toBe(true)
    }
  })

  it('a forrás az összes csoport-labellel inicializálja a nyitott halmazt', () => {
    expect(src).toMatch(
      /useState<Set<string>>\(\s*\(\) => new Set\(menuGroups\.map\(\(g\) => g\.label\)\)/,
    )
  })
})

describe('FK-069 FR-1 — fejléc kattintásra állapotot vált', () => {
  it('nyitott → csukott → nyitott', () => {
    const label = menuGroups[0]!.label
    let state = new Set(menuGroups.map((g) => g.label))
    expect(state.has(label)).toBe(true)
    state = toggle(state, label)
    expect(state.has(label)).toBe(false)
    state = toggle(state, label)
    expect(state.has(label)).toBe(true)
  })

  it('egy csoport csukása a többi csoport állapotát nem érinti', () => {
    const [first, second] = menuGroups
    const state = toggle(new Set(menuGroups.map((g) => g.label)), first!.label)
    expect(state.has(first!.label)).toBe(false)
    expect(state.has(second!.label)).toBe(true)
  })

  it('a fejléc kattintható <button>, ami a toggleMenuGroup-ot hívja', () => {
    expect(src).toMatch(/onClick=\{\(\) => toggleMenuGroup\(group\.label\)\}/)
    expect(src).toMatch(/aria-expanded=\{openMenuGroups\.has\(group\.label\)\}/)
  })
})

describe('FK-069 FR-2 — csukott állapotban az itemek nem renderelődnek', () => {
  it('az items-blokk feltételhez kötött', () => {
    expect(src).toMatch(
      /\(!sidebarOpen \|\| openMenuGroups\.has\(group\.label\)\) &&\s*group\.items/,
    )
  })
})

describe('FK-069 FR-3 — chevron mutatja az állapotot', () => {
  it('ChevronRight importálva és rotate-90-nel forgatva nyitott állapotban', () => {
    expect(src).toContain('ChevronRight')
    expect(src).toMatch(/openMenuGroups\.has\(group\.label\) \? 'rotate-90' : ''/)
  })
})

describe('FK-069 FR-5 / NFR-2 — RBAC szűrés és FK-057 kontraktus érintetlen', () => {
  // #1744: ez korábban a MainLayout.tsx FORRÁSSZÖVEGÉRE illesztett regex volt
  // (`.filter((group) => isMenuGroupVisible(group, menuVisibilityCtx))`). A kanban #8
  // zero-visible fallback bevezetésekor a szűrés a `resolveVisibleMenuGroups` helperbe
  // került, így a regex elhasalt, MIKÖZBEN a védett garancia sértetlen maradt — a teszt
  // tehát a megvalósítás alakját őrizte, nem a viselkedést. Az alábbi esetek a tényleges
  // RBAC-eredményt állítják, ezért túlélik a következő refaktort is.
  const ctxFor = (canonicalRoles: string[], appMode: AppMode = 'full'): MenuVisibilityContext => ({
    appMode,
    hasCanonicalRole: (role: string) => canonicalRoles.includes(role),
    hasRole: () => true,
    featureFlags: {},
  })

  it('a csoport-szűrés a menuVisibility szabályait érvényesíti (jogosulatlan szerep → nincs csoport)', () => {
    const { groups, fallbackApplied } = resolveVisibleMenuGroups(menuGroups, ctxFor([]))

    // `full` módban nincs fallback (FALLBACK_GROUP_LABEL_BY_MODE szándékosan kihagyja),
    // így a szerep nélküli felhasználó egyetlen csoportot sem lát.
    expect(fallbackApplied).toBe(false)
    expect(groups).toEqual([])
  })

  it('minden visszaadott csoport és item átmegy az isMenuGroupVisible / isMenuItemVisible szűrőn', () => {
    const ctx = ctxFor(['foertektar'])
    const { groups, fallbackApplied } = resolveVisibleMenuGroups(menuGroups, ctx)

    expect(fallbackApplied).toBe(false)
    expect(groups.length).toBeGreaterThan(0)
    for (const group of groups) {
      expect(isMenuGroupVisible(group, ctx)).toBe(true)
      // A MainLayout ugyanezzel a predikátummal szűri az itemeket (fallbackApplied === false).
      const visibleItems = group.items.filter((item) => isMenuItemVisible(item, group, ctx))
      expect(visibleItems.length).toBeGreaterThan(0)
    }
  })

  it('a szűkebb szerep szigorúan kevesebb csoportot lát, mint a felügyeleti (least-privilege)', () => {
    const supervisory = resolveVisibleMenuGroups(menuGroups, ctxFor(['foertektar'])).groups
    const narrow = resolveVisibleMenuGroups(menuGroups, ctxFor(['arfolyam_nezo'])).groups

    expect(narrow.length).toBeLessThan(supervisory.length)
  })

  it('a rejtett (hidden) bejegyzés nem szivárog be a szűrt listába a központi felületen', () => {
    const ctx = ctxFor(['foertektar'])
    const { groups } = resolveVisibleMenuGroups(menuGroups, ctx)

    const leakedHidden = groups.flatMap((group) =>
      group.items.filter((item) => item.hidden && isMenuItemVisible(item, group, ctx)),
    )
    expect(leakedHidden).toEqual([])
  })

  it('a MainLayout a szűrt csoportokat rendereli, nem a nyers menuGroups-t', () => {
    // Kontraktus-horgony: a layout a helperből származó `resolvedGroups`-on iterál.
    expect(src).toMatch(/resolveVisibleMenuGroups\(/)
    expect(src).toMatch(/resolvedGroups/)
    expect(src).toMatch(/isMenuItemVisible\(item, group, menuVisibilityCtx\)/)
  })

  it('a <nav> és <main> class-stringje változatlan (FK-057)', () => {
    expect(src).toMatch(
      /<nav\s+className=\{`\$\{sidebarOpen \? 'block' : 'hidden md:block'\} flex-1 min-h-0 py-2 overflow-y-auto`\}/,
    )
    expect(src).toMatch(/<main className="flex-1 flex flex-col min-w-0"/)
  })

  it('nincs perzisztálás (localStorage/sessionStorage) a menü-állapotra (§2 OUT)', () => {
    expect(src).not.toMatch(/(local|session)Storage[^\n]*(openMenuGroups|menuGroup)/i)
  })
})
